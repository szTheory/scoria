defmodule Scoria.TestSupport.Eventually do
  @moduledoc false

  import ExUnit.Assertions, only: [flunk: 1]

  @default_timeout_ms 5_000
  @default_interval_ms 25

  @doc """
  Polls `fun` until it returns a truthy value or the timeout elapses.

  Options:
    * `:timeout_ms` - max wait (default 5000; override via `SCORIA_TEST_EVENTUALLY_TIMEOUT_MS`)
    * `:interval_ms` - sleep between attempts (default 25)
    * `:message` - custom failure message
  """
  def eventually(fun, opts \\ []) when is_function(fun, 0) do
    timeout_ms = Keyword.get(opts, :timeout_ms, env_timeout_ms())
    interval_ms = Keyword.get(opts, :interval_ms, @default_interval_ms)
    message = Keyword.get(opts, :message)

    case poll(fun, timeout_ms, interval_ms, nil) do
      {:ok, result} ->
        result

      {:error, last} ->
        detail =
          case last do
            nil -> "last observed value: nil"
            other -> "last observed value: #{inspect(other)}"
          end

        base = message || "condition not met before timeout (#{timeout_ms}ms)"
        flunk("#{base}\n#{detail}")
    end
  end

  defp env_timeout_ms do
    case System.get_env("SCORIA_TEST_EVENTUALLY_TIMEOUT_MS") do
      nil -> @default_timeout_ms
      value -> String.to_integer(value)
    end
  end

  defp poll(fun, remaining_ms, _interval_ms, last) when remaining_ms <= 0 do
    case fun.() do
      nil -> {:error, last}
      false -> {:error, last}
      result -> {:ok, result}
    end
  end

  defp poll(fun, remaining_ms, interval_ms, _last) do
    case fun.() do
      nil ->
        Process.sleep(interval_ms)
        poll(fun, remaining_ms - interval_ms, interval_ms, nil)

      false ->
        Process.sleep(interval_ms)
        poll(fun, remaining_ms - interval_ms, interval_ms, false)

      result ->
        {:ok, result}
    end
  end
end
