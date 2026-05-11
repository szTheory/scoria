defmodule Scoria.SRE.Adapters.Threadline do
  @moduledoc """
  Optional Threadline-facing audit adapter.

  The adapter stays dependency-free by shaping audit envelopes locally and
  delegating delivery only when a dispatcher is configured.
  """

  @behaviour Scoria.SRE.AuditSink

  @impl true
  def publish(envelope) when is_map(envelope) do
    envelope
    |> to_threadline_envelope()
    |> dispatch(:sre_threadline_dispatcher, :threadline)
  end

  defp to_threadline_envelope(envelope) do
    %{
      adapter: :threadline,
      category: "audit",
      tenant_id: value(envelope, :tenant_id),
      event_type: value(envelope, :event_type),
      policy_class: value(envelope, :policy_class),
      dedupe_key: value(envelope, :dedupe_key),
      payload_hash: value(envelope, :payload_hash),
      actor_ref: value(envelope, :actor_ref),
      trace_id: value(envelope, :trace_id),
      workflow_run_id: value(envelope, :workflow_run_id),
      step_id: value(envelope, :step_id),
      redacted_refs: Map.new(value(envelope, :redacted_refs, %{})),
      metadata: Map.new(value(envelope, :metadata, %{}))
    }
  end

  defp dispatch(payload, config_key, adapter) do
    case Application.get_env(:scoria, config_key) do
      nil ->
        {:ok, %{status: :noop, adapter: adapter, envelope: payload}}

      {module, function, extra_args} when is_atom(module) and is_atom(function) and is_list(extra_args) ->
        apply(module, function, extra_args ++ [payload])

      {module, function} when is_atom(module) and is_atom(function) ->
        apply(module, function, [payload])

      fun when is_function(fun, 1) ->
        fun.(payload)

      module when is_atom(module) ->
        apply(module, :publish, [payload])
    end
  end

  defp value(map, key, default \\ nil) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key)) || default
  end
end
