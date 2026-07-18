# LLM and Tool Adapters

Scoria ships two first-party observability adapters that turn upstream telemetry from your existing `req_llm` calls and Jido actions into Scoria spans, with no manual `:telemetry.attach` call in your host app.

Use this guide with [Default Runtime](guides/capabilities/default-runtime.md), [Ownership Boundary](guides/ownership-boundary.md), and [Troubleshooting](guides/troubleshooting.md).

## What auto-attaches at boot

Scoria boots two telemetry handlers automatically, the same way it boots its own internal span pipeline and the MCP adapter:

- The ReqLLM adapter listens on `[:req_llm, :request, :stop]` and turns each event into an LLM-kind span (handler id `"scoria-observe-reqllm"`).
- The Jido adapter listens on `[:jido, :action, :stop]` and turns each event into a TOOL-kind span (handler id `"scoria-observe-jido"`).

Both handlers attach during application start, are tolerant of an already-attached handler (`{:error, :already_exists}` is expected and ignored, never raised), and share the same disable switch as the rest of Scoria's observability pipeline:

```elixir
config :scoria, Scoria.Observe, enabled: false
```

There is no separate per-adapter switch. Turning `Scoria.Observe` off turns off the default span pipeline and both adapters together.

## Persist vs. join: two different guarantees

Once a handler is attached, every matching `req_llm` call or Jido action **persists** a span row to Postgres with zero host wiring — you do not need to write any code to make this happen.

Persisting a span is not the same as that span **joining** the current workflow run's trace. A span only becomes a child of the step span (and shows up nested under that run in the reviewer trace) when the host forwards the run's lineage keys into the call's telemetry metadata. Without that forwarding, the adapter still persists the span — it just lands as a standalone, single-span trace with no parent.

Forwarding is automatic for any LLM/tool call made from inside `Scoria.Workflows.Runtime.execute_step/2` — the runtime threads the run's lineage into the step handler for you. A raw `req_llm` call or Jido action run outside a workflow (a background job, a one-off script, an unrelated LiveView event) has no run to join, so its span persists standalone until your own code supplies the keys.

## Forwarding metadata yourself

The exact metadata keys the adapters read are the moduledocs' contract, not this guide's — read the ReqLLM and Jido adapter moduledocs directly (`lib/scoria/observe/adapters/req_llm.ex` and `lib/scoria/observe/adapters/jido.ex` in the source tree, or their generated module pages) for the authoritative, always-current key set. As of this release the forwarded keys are `trace_id`, `parent_id`, `tenant_id`, `span_id`, and `session_id`.

A `req_llm` call made outside a workflow, joining an existing trace on purpose:

```elixir
ReqLLM.generate_text(model, prompt,
  req_llm_telemetry_metadata: %{
    trace_id: current_trace_id,
    parent_id: current_step_span_id,
    tenant_id: tenant_id
  }
)
```

A Jido action, forwarding the same lineage at the call site:

```elixir
Jido.Action.run(MyApp.Actions.LookupTicket, params,
  telemetry_metadata: %{
    trace_id: current_trace_id,
    parent_id: current_step_span_id,
    tenant_id: tenant_id
  }
)
```

The exact option name each library exposes for attaching custom telemetry metadata is that library's own contract — check `req_llm`'s and Jido's own documentation for the current option name if the calls above do not match your installed version. Scoria only reads whatever ends up in the telemetry event's `metadata` map at `[:req_llm, :request, :stop]` / `[:jido, :action, :stop]`.

## Trace lineage is a host-owned noun

This follows the same [ownership boundary](guides/ownership-boundary.md) as tenant and actor identity: Scoria never infers `trace_id`, `parent_id`, or `tenant_id` from call context, environment, or process dictionary. Your host app is the only party that knows which run a given LLM call or tool action belongs to, so your host app is the only party that can correctly assert it. Scoria supplies the mechanism (the adapters, the join logic, the reviewer trace); your app supplies the lineage.

## The Jido asymmetry

`req_llm` is a hard dependency of Scoria (`mix.exs`), so the ReqLLM adapter's upstream events always exist in a Scoria-installed app. `jido` is not a Scoria dependency at all — Scoria never calls into Jido, and the Jido adapter module references no `Jido.*` code, only the raw telemetry event shape. If your host app does not depend on and run Jido, the Jido handler is attached but simply never fires: one idle telemetry registration with no producer, not an error and not extra overhead.

## Verification

There is no dedicated verification suite for the adapters alone; they are covered by the same default runtime and observability tests that exercise the rest of the span pipeline:

```bash
mix test.adoption
```

If a span you expected to see nested in a run's trace instead shows up as its own standalone trace, see [Troubleshooting](guides/troubleshooting.md) for the persist-vs-join diagnosis.
