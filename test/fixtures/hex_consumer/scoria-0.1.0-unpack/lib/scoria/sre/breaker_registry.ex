defmodule Scoria.SRE.BreakerRegistry do
  @moduledoc """
  Integration-scoped Fuse helpers for external-effect boundaries.
  """

  alias Scoria.SRE

  @fuse_context :sync
  @default_strategy {:standard, 1, 60_000}
  @default_refresh {:reset, 300_000}
  @open_table :scoria_breaker_registry

  def run(context, fun) when is_map(context) and is_function(fun, 0) do
    case resolve_breaker(context) do
      {:ok, breaker} ->
        with :ok <- ensure_installed(breaker.key),
             :ok <- ask_breaker(breaker) do
          case :fuse.run(breaker.key, fn -> wrap_result(fun.()) end, @fuse_context) do
            {:ok, {:ok, value}} ->
              {:ok, value}

            {:ok, {:error, failure}} ->
              trip_now(breaker.key)
              record_trip(breaker, failure, "melted")
              {:error, failure}

            :blown ->
              envelope = open_envelope(breaker)
              record_trip(breaker, envelope, "blocked")
              {:error, envelope}

            {:error, :not_found} ->
              ensure_installed(breaker.key)
              run(context, fun)
          end
        else
          {:error, envelope} -> {:error, envelope}
        end

      :skip ->
        fun.()
    end
  end

  def resolve_key(context) do
    case resolve_breaker(context) do
      {:ok, breaker} -> {:ok, breaker.key}
      :skip -> :skip
    end
  end

  defp resolve_breaker(context) do
    case Map.get(context, :breaker_key) do
      nil -> resolve_from_context(context)
      key -> {:ok, build_breaker(context, key, Map.get(context, :integration_kind, "external"))}
    end
  end

  defp resolve_from_context(context) do
    case Map.get(context, :integration_kind) do
      "provider" ->
        with value when is_binary(value) <- Map.get(context, :provider_ref) do
          {:ok, build_breaker(context, "provider:#{value}", "provider")}
        else
          _ -> :skip
        end

      "remote_mcp" ->
        with value when is_binary(value) <- Map.get(context, :mcp_endpoint) || Map.get(context, :endpoint) do
          {:ok, build_breaker(context, "remote_mcp:#{value}", "remote_mcp")}
        else
          _ -> :skip
        end

      "tool" ->
        if Map.get(context, :external_effect) do
          with value when is_binary(value) <- Map.get(context, :breaker_target) || Map.get(context, :tool_target) || Map.get(context, :tool_ref) do
            {:ok, build_breaker(context, "tool:#{value}", "tool")}
          else
            _ -> :skip
          end
        else
          :skip
        end

      _ ->
        :skip
    end
  end

  defp build_breaker(context, key, integration_kind) do
    %{
      key: key,
      integration_kind: integration_kind,
      tenant_id: Map.get(context, :tenant_id, "system"),
      run_id: Map.get(context, :run_id),
      trace_id: Map.get(context, :trace_id)
    }
  end

  defp ensure_installed(key) do
    ensure_table()

    case :fuse.install(key, {@default_strategy, @default_refresh}) do
      :ok -> :ok
      :reset -> :ok
      {:error, {:already_present, _pid}} -> :ok
      {:error, {:already_installed, _}} -> :ok
      {:error, reason} -> {:error, %{status: :breaker_error, reason_code: "breaker_install_failed", details: inspect(reason), breaker_key: key}}
    end
  end

  defp ask_breaker(breaker) do
    with :ok <- check_open_table(breaker) do
      case :fuse.ask(breaker.key, @fuse_context) do
        :ok ->
          :ok

        :blown ->
          envelope = open_envelope(breaker)
          record_trip(breaker, envelope, "blocked")
          {:error, envelope}

        {:error, :not_found} ->
          ensure_installed(breaker.key)
      end
    end
  end

  defp wrap_result({:ok, _value} = result), do: {:ok, result}
  defp wrap_result({:error, _value} = result), do: {:melt, result}
  defp wrap_result(other), do: {:ok, {:ok, other}}

  defp open_envelope(breaker) do
    %{
      status: :breaker_open,
      state: "open",
      severity: "page",
      reason_code: "breaker_open",
      breaker_key: breaker.key,
      incident_key: incident_key(breaker, "breaker_open"),
      integration_kind: breaker.integration_kind,
      workflow_run_id: breaker.run_id,
      trace_id: breaker.trace_id
    }
  end

  defp record_trip(breaker, failure, transition) do
    failure_map = normalize_failure(failure)
    reason_code = Map.get(failure_map, "reason_code") || "execution_failed"

    _ =
      SRE.record_breaker_trip(%{
        tenant_id: breaker.tenant_id,
        breaker_key: breaker.key,
        integration_kind: breaker.integration_kind,
        reason_code: to_string(reason_code),
        transition: transition,
        state: "open",
        workflow_run_id: breaker.run_id,
        trace_id: breaker.trace_id,
        evidence_refs: %{
          "incident_key" => incident_key(breaker, reason_code),
          "trace_id" => breaker.trace_id,
          "workflow_run_id" => breaker.run_id
        },
        metadata:
          Map.take(failure_map, ["details", "reason", "status", "state", "severity", "kind"])
      })

    :ok
  end

  defp incident_key(breaker, reason_code) do
    [breaker.tenant_id, breaker.integration_kind, breaker.key, reason_code]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(":")
  end

  defp trip_now(key) do
    :ok = :fuse.melt(key)
    ensure_table()
    :ets.insert(@open_table, {key, System.system_time(:millisecond) + refresh_ms()})
    :ok
  end

  defp check_open_table(breaker) do
    ensure_table()
    now = System.system_time(:millisecond)

    case :ets.lookup(@open_table, breaker.key) do
      [{key, until_ms}] ->
        if until_ms > now do
          envelope = open_envelope(breaker)
          record_trip(breaker, envelope, "blocked")
          {:error, envelope}
        else
          :ets.delete(@open_table, key)
          :fuse.reset(key)
          :ok
        end

      [] ->
        :ok
    end
  end

  defp ensure_table do
    case :ets.whereis(@open_table) do
      :undefined -> :ets.new(@open_table, [:named_table, :public, :set, read_concurrency: true])
      _table -> @open_table
    end

    :ok
  end

  defp refresh_ms, do: elem(@default_refresh, 1)

  defp normalize_failure(%{} = failure) do
    Enum.into(failure, %{}, fn {key, value} -> {to_string(key), value} end)
  end

  defp normalize_failure({kind, reason}) do
    %{"kind" => to_string(kind), "reason" => inspect(reason)}
  end

  defp normalize_failure(other) do
    %{"details" => inspect(other)}
  end
end
