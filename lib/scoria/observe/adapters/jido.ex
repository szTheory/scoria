defmodule Scoria.Observe.Adapters.Jido do
  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind

  def attach do
    :telemetry.attach_many(
      "scoria-observe-jido",
      [[:jido, :action, :stop]],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:jido, :action, :stop], measurements, metadata, _config) do
    tenant_id = metadata[:tenant_id]
    workflow_run_id = metadata[:workflow_run_id]

    # A generic Jido action is discrete function execution = TOOL semantics;
    # "agent" is reserved for the orchestrating span. Host-declared override
    # only via metadata[:span_kind] -- no action-name inference (D-13).
    span_kind = SpanKind.normalize(metadata[:span_kind] || "tool")

    # D-ATTR01-7: unlike req_llm, this adapter's metadata is host-supplied
    # at the call site, so merge_host_declared/2 here is reachable on real
    # production TOOL-span emissions (not hand-synthesized-only).
    attributes =
      %{
        "jido.action_name" => metadata[:action_name],
        "jido.status" => metadata[:status],
        "duration_ms" => measurements[:duration],
        "tenant_id" => tenant_id,
        "workflow_run_id" => workflow_run_id
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
      |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference(span_kind))
      |> Semconv.merge_host_declared(metadata)

    span = %{
      name: "jido_action",
      span_kind: span_kind,
      start_time: metadata[:start_time] || DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      trace_id: metadata[:trace_id] || Ecto.UUID.generate(),
      parent_id: metadata[:parent_id],
      tenant_id: tenant_id,
      workflow_run_id: workflow_run_id,
      session_id: metadata[:session_id],
      attributes: attributes
    }

    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
  end
end
