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

  @doc """
  Scrubs deny-list key=value patterns from free-form text (e.g. streaming chunks).
  """
  def scrub_text(text) when is_binary(text) do
    config = Application.get_env(:scoria, __MODULE__, [])
    scrub_text_with_deny_list(text, build_deny_list(config))
  end

  def scrub_text(other), do: other

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

  defp scrub_text_with_deny_list(text, deny_list) do
    Enum.reduce(deny_list, text, fn key, acc ->
      key_str = Regex.escape(to_string(key))

      Regex.replace(~r/(#{key_str})=([^\s]+)/iu, acc, "\\1=[REDACTED]")
    end)
  end
end