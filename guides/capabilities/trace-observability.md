# Trace Observability

Scoria records OpenTelemetry-GenAI / OpenInference-compatible convention keys (`gen_ai.*`,
`server.*`, `openinference.span.kind`) in your host Postgres, pinned to OpenTelemetry GenAI
semantic-conventions schema 1.37.0 (via `req_llm ~> 1.13`; these GenAI conventions are still
experimental upstream). Scoria is not an OpenTelemetry exporter — sending these traces onward
to Langfuse, Datadog, or Arize Phoenix is host-owned and opt-in.

Use this guide with [the glossary](guides/reference/glossary.md) and the
[comparison guide](guides/scoria-vs-external-llm-ops.md).

## What is recorded

Every run's spans carry convention-shaped attributes captured at the point Scoria records the
trace:

- `gen_ai.*` — model, request, and response attributes from the OpenTelemetry GenAI semantic
  conventions (for example provider, model name, token usage, and finish reason), sourced from
  `req_llm`'s own telemetry emission.
- `server.*` — the OpenTelemetry generic server/network attributes present on the underlying
  request.
- `openinference.span.kind` — the OpenInference span-kind convention key, used so the span's
  role (LLM call, retriever, tool, agent) is legible to anyone reading the stored
  attributes with OpenInference vocabulary in mind.

These are stored as reviewer-visible trace data inside your host Postgres, alongside the rest
of a run's evidence. They are not sent anywhere by Scoria.

## Schema pin and honesty rider

Scoria pins to the OpenTelemetry GenAI semantic-conventions schema published at
`https://opentelemetry.io/schemas/1.37.0`, matching the schema version `req_llm ~> 1.13` emits.
The upstream GenAI semantic conventions are still marked experimental / Development status by
OpenTelemetry. Scoria records the convention keys as they exist at this pinned schema version;
it does not claim conformance with a stable, finalized spec, because no such stable spec exists
yet upstream.

## Not an exporter

Scoria is not an OpenTelemetry exporter. Recording convention-shaped keys in your host Postgres
is not the same as shipping an OTLP exporter, a collector integration, or a built-in sink to
Langfuse, Datadog, or Arize Phoenix. If you want to forward these traces to one of those
platforms, that integration is host-owned and opt-in — you read the stored attributes back out
of your own database and forward them yourself. Export tooling is deferred, tracked separately
from this convention-keys capability (see [the comparison
guide](guides/scoria-vs-external-llm-ops.md#not-current-scoria-claims)).

## Where this fits

This is a capability of the [default runtime](guides/capabilities/default-runtime.md) and every
other Scoria capability that emits spans (bounded handoffs, semantic cache, connectors) — the
same convention keys apply wherever Scoria records a trace. See the glossary's [Trace
entry](guides/reference/glossary.md) for how "trace" is used across Scoria's docs and dashboard.
