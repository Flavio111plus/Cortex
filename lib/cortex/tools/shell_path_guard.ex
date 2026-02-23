defmodule Cortex.Tools.ShellPathGuard do
  @moduledoc """
  Shell 命令路径提取与授权检查。
  从 shell 命令中提取文件路径，验证是否在授权目录内。
  """

  alias Cortex.Core.Security

  @file_commands %{
    "cat" => :all_args,
    "less" => :all_args,
    "more" => :all_args,
    "head" => :last_arg,
    "tail" => :last_arg,
    "ls" => :all_args,
    "cp" => :all_args,
    "mv" => :all_args,
    "ln" => :all_args,
    "touch" => :all_args,
    "mkdir" => :all_args,
    "rmdir" => :all_args,
    "chmod" => :last_arg,
    "chown" => :last_arg,
    "stat" => :all_args,
    "file" => :all_args,
    "wc" => :all_args,
    "sort" => :all_args,
    "diff" => :all_args,
    "find" => :first_arg,
    "grep" => :last_arg,
    "sed" => :last_arg,
    "awk" => :last_arg
  }

  @spec check(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def check(command, project_root, opts \\ []) do
    agent_id = Keyword.get(opts, :agent_id)

    with :ok <- check_path_traversal(command),
         :ok <- check_redirect_paths(command, project_root, agent_id),
         paths <- extract_paths(command),
         :ok <- validate_paths(paths, project_root, agent_id) do
      :ok
    end
  end

  defp check_path_traversal(command) do
    if Regex.match?(~r/\.\.\/|\.\.\\/, command) do
      {:error, {:permission_denied, "Path traversal detected in shell command"}}
    else
      :ok
    end
  end

  defp check_redirect_paths(command, project_root, agent_id) do
    case Regex.run(~r/>{1,2}\s*(\S+)/, command) do
      [_, path] ->
        case Security.validate_path_with_folders(path, project_root, agent_id: agent_id) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, {:permission_denied, "Redirect target not authorized: #{path} (#{reason})"}}
        end

      nil ->
        :ok
    end
  end

  @doc "Extract file paths from a shell command"
  def extract_paths(command) do
    first_cmd = command |> String.split("|") |> List.first() |> String.trim()
    parts = OptionParser.split(first_cmd)

    case parts do
      [cmd_name | args] ->
        cmd = Path.basename(cmd_name)
        extract_by_command(cmd, args)

      _ ->
        []
    end
  end

  defp extract_by_command(cmd, args) do
    case Map.get(@file_commands, cmd) do
      :all_args -> filter_non_flags(args)
      :last_arg -> if args != [], do: [List.last(args)], else: []
      :first_arg -> if args != [], do: [List.first(args)], else: []
      _ -> []
    end
  end

  defp filter_non_flags(args) do
    Enum.reject(args, &String.starts_with?(&1, "-"))
  end

  defp validate_paths([], _root, _agent_id), do: :ok

  defp validate_paths(paths, project_root, agent_id) do
    Enum.reduce_while(paths, :ok, fn path, :ok ->
      case Security.validate_path_with_folders(path, project_root, agent_id: agent_id) do
        {:ok, _} -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:permission_denied, "Path not authorized: #{path} (#{reason})"}}}
      end
    end)
  end
end
