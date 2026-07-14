defmodule Scoria.Observe.Adapters.ReqLLM do
  @moduledoc """
  Turns `req_llm`'s `[:req_llm, :request, :stop]` telemetry into an
  LLM-kind span.

  **`metadata[:trace_id]`/`metadata[:parent_id]` are the intended path
  (D-03b).** `Scoria.Workflows.Runtime.execute_step/2` threads the run's
  `trace_id` and the step span's id into the handler, and a host handler
  forwards them into whatever `req_llm` call it makes; the span then joins
  the run's trace as a child of the step span (SC#1).

  The `|| Ecto.UUID.generate()` `trace_id` fallback below is retained
  because a host may call `req_llm` entirely outside a workflow — but it is
  a LAST RESORT that produces an **ORPHAN single-span trace** with no run
  join at all. Before plan 53-08 it was the ONLY path, so every LLM span in
  a run landed in its own separate trace.

  The span's `:id` is minted HERE, at emit time — not left to `Buffer`'s
  flush-time `put_new_lazy/2`. A flush-time id is unreferenceable, so no
  future child span could ever name this one as its `parent_id`.
  """

  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind

  def attach do
    :telemetry.attach_many(
      "scoria-observe-reqllm",
      [[:req_llm, :request, :stop]],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:req_llm, :request, :stop], _measurements, metadata, _config) do
    tenant_id = metadata[:tenant_id]
    workflow_run_id = metadata[:workflow_run_id]

    base_attributes =
      %{
        "tenant_id" => tenant_id,
        "workflow_run_id" => workflow_run_id
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    # req_llm.ex only ever emits LLM-model-call spans; the span_kind is
    # always "llm" unless a host explicitly overrides it via metadata[:span_kind]
    # (mirrors the Jido adapter's host-override + flat-default convention).
    # metadata[:operation] is req_llm's OWN telemetry vocabulary (:chat,
    # :embedding, :object — see ReqLLM.Telemetry.new_context/3) and is a
    # different taxonomy than Scoria's span_kind; it must not be read here.
    span_kind = SpanKind.normalize(metadata[:span_kind] || "llm")

    # D-ATTR01-7: this stage is correct/harmless (skip-nil reduce) but only
    # takes effect on hand-synthesized test events -- a REAL
    # [:req_llm, :request, :stop] emission has no host-key channel in its
    # metadata. The production carrier for host-declared keys on the
    # LLM/prompt lane is emit_prompt_span/1 (52-03), not this adapter.
    attributes =
      base_attributes
      |> Semconv.merge_req_llm_attributes(metadata)
      |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference(span_kind))
      |> Semconv.merge_host_declared(metadata)

    span = %{
      id: metadata[:span_id] || Ecto.UUID.generate(),
      name: "req_llm_request",
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
