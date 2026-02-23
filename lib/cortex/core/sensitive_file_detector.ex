defmodule Cortex.Core.SensitiveFileDetector do
  @moduledoc """
  识别敏感文件类型，决定脱敏策略。
  返回 :full_redact | :value_redact | :none
  """

  @full_redact_basenames ~w(.env .env.local .env.production .env.staging .env.development)

  @full_redact_extensions ~w(.pem .key .p12 .pfx .jks .keystore)

  @value_redact_patterns [
    ~r/\.env\.[^.]+$/,
    ~r/secrets?\.(ya?ml|json|toml|exs?)$/i,
    ~r/credentials?\.(ya?ml|json|toml|exs?)$/i,
    ~r/config\/runtime\.exs$/,
    ~r/config\/prod\.exs$/
  ]

  @whitelist_basenames ~w(.env.example .env.sample .env.template)

  @spec detect(String.t()) :: :full_redact | :value_redact | :none
  def detect(path) do
    basename = Path.basename(path)
    ext = Path.extname(path)

    cond do
      basename in @whitelist_basenames -> :none
      basename in @full_redact_basenames -> :full_redact
      ext in @full_redact_extensions -> :full_redact
      Enum.any?(@value_redact_patterns, &Regex.match?(&1, path)) -> :value_redact
      true -> :none
    end
  end
end
