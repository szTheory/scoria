defmodule Scoria.Observe.Adapters.Jido do
  @moduledoc """
  Turns Jido's `[:jido, :action, :stop]` telemetry into a TOOL-kind span.

  **`metadata[:trace_id]`/`metadata[:parent_id]` are the intended path
  (D-03b).** `Scoria.Workflows.Runtime.execute_step/2` threads the run's
  `trace_id` and the step span's id into the handler, and a host handler
  forwards them into the Jido action's telemetry metadata (which, unlike
  `req_llm`'s, IS host-supplied at the call site); the span then joins the
  run's trace as a child of the step span (SC#1).

  The `|| Ecto.UUID.generate()` `trace_id` fallback below is retained
  because a host may run a Jido action entirely outside a workflow — but it
  is a LAST RESORT that produces an **ORPHAN single-span trace** with no run
  join at all. Before plan 53-08 it was the ONLY path.

  The span's `:id` is minted HERE, at emit time — not left to `Buffer`'s
  flush-time `put_new_lazy/2`. A flush-time id is unreferenceable, so no
  future child span could ever name this one as its `parent_id`.
  """

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
      id: metadata[:span_id] || Ecto.UUID.generate(),
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
