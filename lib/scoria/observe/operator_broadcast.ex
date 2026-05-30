defmodule Scoria.Observe.OperatorBroadcast do
  @moduledoc """
  Tenant-scoped PubSub fan-out for operator dashboard live events.

  Publishes incremental trace deltas to `scoria:runs:{tenant_id}`. Tracks seen
  `trace_id` values per BEAM node in ETS (`:scoria_observe_operator_broadcast_trace_seen`)
  so `{:trace_opened, _}` is emitted only on the first span stop for a trace on
  this node.

  Missing `tenant_id` drops broadcast (fail closed) with a debug log — no global
  topic fallback.
  """

  require Logger

  alias Scoria.Observe.TraceProjection

  @topic_prefix "scoria:runs:"
  @trace_seen_table :scoria_observe_operator_broadcast_trace_seen

  def tenant_topic(tenant_id), do: @topic_prefix <> tenant_id

  def broadcast(tenant_id, message) when is_binary(tenant_id) do
    Phoenix.PubSub.broadcast(Scoria.PubSub, tenant_topic(tenant_id), message)
  end

  def span_stopped(metadata) when is_map(metadata) do
    case Map.get(metadata, :tenant_id) do
      tenant_id when is_binary(tenant_id) and tenant_id != "" ->
        trace_id = Map.get(metadata, :trace_id)

        if trace_id && first_span_for_trace?(trace_id) do
          broadcast(tenant_id, {:trace_opened, TraceProjection.trace_header(metadata)})
        end

        if trace_id do
          broadcast(tenant_id, {:trace_span, trace_id, TraceProjection.span_view(metadata)})
        end

        :ok

      _ ->
        Logger.debug("OperatorBroadcast.span_stopped/1 dropped: missing tenant_id")
        :dropped
    end
  end

  def span_delta(%{tenant_id: tenant_id, trace_id: trace_id, span_id: span_id, chunk: chunk})
      when is_binary(tenant_id) and tenant_id != "" do
    broadcast(tenant_id, {:trace_delta, %{trace_id: trace_id, span_id: span_id, chunk: chunk}})
    :ok
  end

  def span_delta(_metadata) do
    Logger.debug("OperatorBroadcast.span_delta/1 dropped: missing tenant_id")
    :dropped
  end

  def hitl_request(tenant_id, projection_map) when is_binary(tenant_id) and tenant_id != "" do
    broadcast(tenant_id, {:hitl_request, projection_map})
    :ok
  end

  def hitl_request(_tenant_id, _projection_map) do
    Logger.debug("OperatorBroadcast.hitl_request/2 dropped: missing tenant_id")
    :dropped
  end

  def approval_decided(tenant_id, approval_id, status)
      when is_binary(tenant_id) and tenant_id != "" do
    broadcast(tenant_id, {:approval_decided, approval_id, status})
    :ok
  end

  def approval_decided(_tenant_id, _approval_id, _status) do
    Logger.debug("OperatorBroadcast.approval_decided/3 dropped: missing tenant_id")
    :dropped
  end

  def reset_trace_seen! do
    ensure_trace_seen_table()

    :ets.delete_all_objects(@trace_seen_table)
    :ok
  end

  defp first_span_for_trace?(trace_id) do
    ensure_trace_seen_table()
    :ets.insert_new(@trace_seen_table, {trace_id, true})
  end

  defp ensure_trace_seen_table do
    case :ets.whereis(@trace_seen_table) do
      :undefined ->
        :ets.new(@trace_seen_table, [:named_table, :set, :public, read_concurrency: true])

      _table ->
        :ok
    end
  end
end
