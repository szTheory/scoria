defmodule Scoria.SRE.Adapters.Mailglass do
  @moduledoc """
  Optional Mailglass-facing alert adapter.

  The adapter preserves Scoria's local evidence model by accepting already
  redacted alert envelopes and defaulting to a no-op transport.
  """

  @behaviour Scoria.SRE.AlertSink

  @impl true
  def publish(envelope) when is_map(envelope) do
    envelope
    |> to_alert_envelope(:mailglass)
    |> dispatch(:sre_mailglass_dispatcher, :mailglass)
  end

  defp to_alert_envelope(envelope, adapter) do
    %{
      adapter: adapter,
      category: "alert",
      sink_kind: Atom.to_string(adapter),
      tenant_id: value(envelope, :tenant_id),
      routing_key: value(envelope, :routing_key),
      severity: value(envelope, :severity, "warning"),
      routing_class: value(envelope, :routing_class, "review"),
      summary: value(envelope, :summary),
      incident_key: value(envelope, :incident_key),
      reason_code: value(envelope, :reason_code),
      trace_id: value(envelope, :trace_id),
      workflow_run_id: value(envelope, :workflow_run_id),
      payload_hash: value(envelope, :payload_hash),
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
