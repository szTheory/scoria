defmodule Scoria.Observe.Redactor do
  @moduledoc """
  Utility for scrubbing sensitive data (PII, secrets, API keys) from telemetry events.
  """

  @default_deny_list ["password", "api_key", "token", "secret", :password, :api_key, :token, :secret]

  def redact(data) do
    config = Application.get_env(:scoria, __MODULE__, [])

    case Keyword.get(config, :mfa) do
      {mod, fun, args} -> apply(mod, fun, [data | args])
      nil -> do_redact(data, build_deny_list(config))
    end
  end

  defp build_deny_list(config) do
    custom = Keyword.get(config, :deny_list, [])
    MapSet.new(@default_deny_list ++ custom)
  end

  defp do_redact(map, deny_list) when is_map(map) and not is_struct(map) do
    Map.new(map, fn {k, v} ->
      if MapSet.member?(deny_list, k) do
        {k, "[REDACTED]"}
      else
        {k, do_redact(v, deny_list)}
      end
    end)
  end

  defp do_redact(list, deny_list) when is_list(list) do
    Enum.map(list, &do_redact(&1, deny_list))
  end

  defp do_redact(other, _deny_list), do: other
end