defmodule Cortex.Core.ContentRedactor do
  @moduledoc """
  内容级敏感数据脱敏引擎。

  支持两种模式：
  - :value_redact — 仅替换 key=value 中的 value 部分
  - :full_redact — 整个文件内容替换为摘要占位符
  """

  @redact_placeholder "[REDACTED]"

  # Match key=value where value is: quoted string OR non-whitespace chars (stops at \n literal too)
  @sensitive_kv_regex ~r/(?i)((?:password|passwd|pwd|secret|secret_key|secret_token|api_key|apikey|api_secret|access_key|access_token|auth_token|private_key|encryption_key|database_url|db_url|db_password|aws_secret|aws_access_key_id|stripe_secret|stripe_key|sendgrid_api_key|mailgun_api_key|jwt_secret|session_secret|client_secret|oauth_secret)\s*[=:]\s*)(?:"[^"]*"|'[^']*'|[^\s"'\\]+)/

  @sensitive_value_patterns [
    # AWS access keys
    ~r/AKIA[0-9A-Z]{16}/,
    # GitHub tokens
    ~r/gh[ps]_[A-Za-z0-9_]{36,}/,
    # Bearer tokens
    ~r/Bearer\s+[A-Za-z0-9\-._~+\/]+=*/,
    # Connection strings with embedded passwords
    ~r/:\/\/[^:]+:[^@\s]+@/
  ]

  @spec redact(String.t(), keyword()) :: {String.t(), boolean()}
  def redact(content, opts \\ []) do
    mode = Keyword.get(opts, :mode, :value_redact)
    path = Keyword.get(opts, :path)

    case mode do
      :full_redact ->
        line_count = content |> String.split("\n") |> length()
        basename = if path, do: Path.basename(path), else: "file"
        {"[REDACTED: #{basename} — sensitive file, #{line_count} lines]", true}

      :value_redact ->
        redact_values(content)
    end
  end

  defp redact_values(content) do
    lines = String.split(content, "\n")

    {redacted_lines, any_changed?} =
      Enum.map_reduce(lines, false, fn line, changed_acc ->
        {new_line, line_changed?} = redact_line(line)
        {new_line, changed_acc or line_changed?}
      end)

    {Enum.join(redacted_lines, "\n"), any_changed?}
  end

  defp redact_line(line) do
    # Step 1: key=value pattern
    {line_after_kv, kv_changed?} =
      case Regex.replace(@sensitive_kv_regex, line, "\\1#{@redact_placeholder}") do
        ^line -> {line, false}
        replaced -> {replaced, true}
      end

    # Step 2: standalone sensitive value patterns
    Enum.reduce(@sensitive_value_patterns, {line_after_kv, kv_changed?}, fn pattern, {current, changed} ->
      case Regex.replace(pattern, current, @redact_placeholder) do
        ^current -> {current, changed}
        replaced -> {replaced, true}
      end
    end)
  end
end
