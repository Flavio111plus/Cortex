# Shell 命令越权访问非授权目录 — 漏洞分析

**日期**: 2026-02-23  
**范围**: 授权目录功能对 Shell 工具的约束缺失分析

---

## 1. 问题概述

当前系统已实现文件夹级授权（`PermissionTracker.folder_authorizations`），文件工具（`read_file`、`write_file`、`edit_file`）均通过 `Security.validate_path_with_folders/3` 进行路径+文件夹双重校验。但 **Shell 工具（`shell`）完全绕过了文件夹授权检查**，Agent 可通过 shell 命令自由读写任何 workspace 内路径，使文件夹授权形同虚设。

---

## 2. 现有安全层级对比

| 安全层 | read_file | write_file | edit_file | shell | 
|--------|-----------|------------|-----------|-------|
| 路径边界验证 (`validate_path`) | ✅ | ✅ | ✅ | ⚠️ 仅 workdir 限制 |
| 文件夹授权 (`validate_path_with_folders`) | ✅ | ✅ | ✅ | ❌ 完全缺失 |
| SandboxHook (`before_tool_call`) | ✅ 检查 `args.path` | ✅ | ✅ | ❌ shell 无 `path` 参数 |
| ShellInterceptor (命令模式匹配) | N/A | N/A | N/A | ⚠️ 仅匹配高危命令名 |
| 危险命令黑名单 | N/A | N/A | N/A | ⚠️ 仅 sudo/rm 等 |

---

## 3. 具体绕过路径分析

### 3.1 Shell 工具执行链路

```
ShellCommand.execute(args, ctx)
  ├── check_command_safety(command)        # 仅检查命令名黑名单 + 危险模式
  ├── ShellInterceptor.check(command)      # 仅检查 npm/git/rm/mv 等需审批模式
  └── Sandbox.execute(command, workdir: project_root)  # 直接执行，无路径授权检查
```

关键问题：**整条链路中没有任何环节检查 `folder_authorizations`**。

### 3.2 SandboxHook 的盲区

```elixir
# SandboxHook.before_tool_call/2
def before_tool_call(agent_state, call_data) do
  args = call_data.args || %{}
  path = Map.get(args, "path") || Map.get(args, :path)  # shell 工具无 path 参数
  if is_binary(path) do
    # 验证路径...
  else
    {:ok, call_data, agent_state}  # ← shell 工具直接放行
  end
end
```

Shell 工具的参数结构是 `%{command: "cat /secret/file"}`，不含 `path` 字段，SandboxHook 直接返回 `:ok`。

### 3.3 可利用的绕过命令示例

假设 Agent 被限制仅访问 `src/` 目录（whitelist 模式）：

| 绕过方式 | 命令 | 效果 |
|----------|------|------|
| 读取非授权文件 | `cat config/secrets.exs` | 读取敏感配置 |
| 写入非授权目录 | `echo "malicious" > .env` | 写入环境变量文件 |
| 复制文件到授权区 | `cp config/secrets.exs src/leak.txt` | 泄露到可读区域 |
| 列举目录结构 | `find . -name "*.key"` | 发现敏感文件 |
| 管道组合 | `cat ../other_project/data.db \| base64` | 跨项目读取 |
| 符号链接绕过 | `ln -s /etc/passwd src/link.txt` | 创建指向外部的链接 |
| 子 shell 切换目录 | `cd config && cat runtime.exs` | 切换到非授权目录 |
| tar 打包 | `tar czf src/dump.tar.gz config/ priv/` | 批量提取非授权内容 |

### 3.4 SystemExec (Jido Shell `sys` 命令) 同样缺失

`Cortex.Shell.Commands.SystemExec` 仅调用 `ShellInterceptor.check/1`，不检查文件夹授权。且 `state.cwd` 可能指向非授权目录，无任何校验。

---

## 4. 根因分析

### 4.1 架构层面

1. **文件工具与 Shell 工具的安全模型不一致**：文件工具通过 `Security.validate_path_with_folders` 实现了细粒度控制，Shell 工具仍停留在"命令名黑名单"的粗粒度模型。
2. **SandboxHook 假设所有工具都有 `path` 参数**：Shell 工具的参数是 `command` 字符串，不适用于基于路径的拦截逻辑。
3. **ShellInterceptor 设计目标不同**：它的职责是拦截"高危操作类型"（如 `git push`、`rm`），而非"路径授权"。

### 4.2 实现层面

1. `ShellCommand.execute/2` 不接收也不传递 `agent_id`，无法查询 `PermissionTracker`。
2. `ToolRunner.execute/3` 传递的 `ctx` 中包含 `session_id` 和 `project_root`，但 **不包含 `agent_id`**（见 `ToolExecution.execute_async/2` 第 196 行）。
3. `Sandbox.Host.execute/2` 仅设置 `{:cd, workdir}`，不对命令内容中的路径做任何解析。

---

## 5. 影响评估

| 维度 | 评级 | 说明 |
|------|------|------|
| 严重性 | **高** | 完全绕过文件夹授权，使该功能失去意义 |
| 利用难度 | **低** | Agent 只需使用 `cat`/`ls`/`cp` 等基础命令 |
| 影响范围 | **广** | workspace 内所有文件均可被 shell 访问 |
| 数据泄露风险 | **高** | 敏感配置、密钥文件、数据库文件均可读取 |
| 数据篡改风险 | **中** | 可写入任意文件，但受 OS 权限限制 |

---

## 6. 修复方案建议

### 6.1 方案 A：Shell 命令路径提取 + 授权检查（推荐）

在 `ShellCommand.execute/2` 中增加路径提取和授权校验层：

```elixir
defmodule Cortex.Tools.ShellPathExtractor do
  @doc "从 shell 命令中提取可能涉及的文件路径"
  
  # 已知文件操作命令的路径参数位置
  @file_commands %{
    "cat" => :all_args,
    "ls" => :all_args,
    "cp" => :all_args,
    "mv" => :all_args,
    "mkdir" => :all_args,
    "touch" => :all_args,
    "head" => :last_arg,
    "tail" => :last_arg,
    "grep" => :last_arg,
    "find" => :first_arg,
    "tar" => :extract_tar_paths,
    "echo" => :redirect_target
  }
  
  def extract_paths(command) do
    # 解析命令，提取涉及的文件路径
    # 处理管道、重定向、子 shell 等情况
  end
end
```

在 `ShellCommand.do_execute/4` 中集成：

```elixir
defp do_execute(command, timeout, project_root, session_id) do
  with :ok <- check_command_safety(command, session_id),
       :ok <- ShellInterceptor.check(command),
       :ok <- check_shell_path_authorization(command, session_id, project_root) do
    # 执行命令...
  end
end

defp check_shell_path_authorization(command, session_id, project_root) do
  paths = ShellPathExtractor.extract_paths(command)
  
  Enum.reduce_while(paths, :ok, fn path, :ok ->
    case Security.validate_path_with_folders(path, project_root, agent_id: session_id) do
      {:ok, _} -> {:cont, :ok}
      {:error, reason} -> {:halt, {:error, {:path_not_authorized, path, reason}}}
    end
  end)
end
```

**优点**：精确拦截，用户体验好  
**缺点**：路径提取不完备（管道、变量展开、子 shell 等难以完全覆盖）

### 6.2 方案 B：Shell 工具 workdir 限制为授权目录

修改 `Sandbox.Host.execute/2`，将 `workdir` 限制为授权目录之一，并禁止命令中出现 `../` 和绝对路径：

```elixir
defp do_execute(command, timeout, project_root, session_id) do
  with :ok <- check_command_safety(command, session_id),
       :ok <- ShellInterceptor.check(command),
       :ok <- check_no_path_escape(command) do
    # workdir 设为第一个授权目录或 project_root
    workdir = resolve_shell_workdir(session_id, project_root)
    execute_command(command, workdir, timeout, session_id)
  end
end

defp check_no_path_escape(command) do
  if Regex.match?(~r/\.\.\/|\.\.\\/, command) do
    {:error, {:permission_denied, "Path traversal in shell command"}}
  else
    :ok
  end
end
```

**优点**：实现简单，覆盖面广  
**缺点**：过于严格，可能误拦合法命令（如 `cd ..` 在授权目录内的子目录中）

### 6.3 方案 C：Shell 命令沙箱化（长期方案）

使用 Linux namespace / seccomp / Docker 容器限制 shell 命令的文件系统可见范围：

```elixir
# 使用 bubblewrap (bwrap) 限制文件系统视图
defp sandboxed_command(command, authorized_paths) do
  bind_mounts = Enum.map(authorized_paths, fn path ->
    "--bind #{path} #{path}"
  end)
  
  "bwrap --ro-bind /usr /usr #{Enum.join(bind_mounts, " ")} -- /bin/sh -c '#{command}'"
end
```

**优点**：OS 级隔离，无法绕过  
**缺点**：依赖外部工具，部署复杂度高，Windows 不支持

### 6.4 方案 D：混合方案（推荐实施路径）

短期（Phase 1）：
- 在 `ShellCommand` 中传递 `agent_id`，增加基础路径提取检查（方案 A 简化版）
- 禁止 shell 命令中的 `../` 模式（方案 B 部分）
- 在 `ToolExecution.execute_async` 中将 `session_id` 作为 `agent_id` 传入 ctx

中期（Phase 2）：
- 完善 `ShellPathExtractor`，覆盖常见命令模式
- 增加重定向（`>`、`>>`）和管道（`|`）的路径提取
- 对无法解析的复杂命令，降级为需要用户审批

长期（Phase 3）：
- 评估 bubblewrap/Docker 沙箱方案
- 实现 OS 级文件系统隔离

---

## 7. 需要修改的文件清单

| 文件 | 修改内容 |
|------|----------|
| `lib/cortex/tools/handlers/shell_command.ex` | 增加路径授权检查，接收 agent_id |
| `lib/cortex/tools/tool_runner.ex` | ctx 中传递 agent_id |
| `lib/cortex/agents/llm_agent/tool_execution.ex` | execute_async 中将 session_id 作为 agent_id 传入 |
| `lib/cortex/tools/shell_interceptor.ex` | 扩展检查逻辑，支持路径模式 |
| `lib/cortex/hooks/sandbox_hook.ex` | 增加对 shell 工具 command 参数的路径提取检查 |
| `lib/cortex/shell/commands/system_exec.ex` | 增加 cwd 授权校验 |
| `lib/cortex/sandbox/host.ex` | 可选：增加 workdir 授权校验 |
| 新增 `lib/cortex/tools/shell_path_extractor.ex` | Shell 命令路径提取模块 |

---

## 8. 总结

文件夹授权功能（`PermissionTracker.folder_authorizations`）已在文件工具层面完整实现，但 Shell 工具存在完全绕过的漏洞。核心原因是 Shell 工具的安全模型仍停留在"命令名黑名单"阶段，未与文件夹授权系统集成。建议采用混合方案（D），短期内通过路径提取+模式匹配堵住主要绕过路径，长期考虑 OS 级沙箱隔离。
