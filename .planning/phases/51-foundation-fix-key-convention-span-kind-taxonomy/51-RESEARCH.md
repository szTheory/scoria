# Phase 51: Foundation Fix + Key Convention + Span-Kind Taxonomy - Research

**Researched:** 2026-07-12
**Domain:** Internal Elixir/Phoenix integration — trace/span persistence bug fix + OTel-GenAI/OpenInference naming convention over an existing jsonb attribute map
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**COMPAT-01 — Legacy-key posture: CLEAN REPLACEMENT, loudly documented**
- D-01: Drop legacy keys `llm.model_name`, `llm.token_count`, `req.url` entirely; replace with OTel-GenAI convention keys sourced from `ReqLLM.OpenTelemetry.Attributes`. No dual-emit, no runtime shim, no config flag.
- D-02: Justification is factual: the pre-existing FK bug means every span insert has been failing/dropped — no adopter Postgres has ever persisted these keys, so there is zero legacy data to protect.
- D-03: Ship a CHANGELOG breaking-change entry (`0.1.4` cut) with the literal old→new mapping table, plus one upgrade-guide sentence for adopters with custom `:telemetry` handlers reading old keys in-memory.
- D-04: Treat the FK fix + key rename as one atomic change — do not rename keys while spans still don't persist; do not fix the FK while keeping legacy keys.

**FOUND-01 — Persistence-failure posture: NON-FATAL BUT LOUD**
- D-05: Replace the silent `rescue` in `Buffer.flush_spans/1` with structured, non-fatal surfacing: `Logger.error` (structured — `dropped_count`, `buffer` name, not just `inspect(e)`) AND a telemetry event, then drop the failed batch and continue. Never crash/destabilize the host app.
- D-06: Telemetry event contract: `[:scoria, :observe, :buffer, :flush_error]`; measurements `%{dropped_count: n, system_time: ...}`; metadata `%{error: e, kind: :error, stacktrace: ..., buffer: name, max_size: ...}`. Emit through a thin wrapper in `Scoria.Observe.Telemetry` mirroring the existing `:delta`-event wrapper convention.
- D-07: Add config knob `:on_flush_error` = `:log` (default) | `:raise`, threaded through `start_link` opts into state (like `max_size`/`flush_interval`). Exactly these two atoms — no `fun` variant.
- D-08: Test approach — ship both: (a) primary: `:telemetry_test.attach_event_handlers` on the flush_error event, induce a real Postgrex/constraint failure, assert the event with `dropped_count > 0`; (b) secondary: `:raise` mode + `assert`/`catch_exit`. Add a synchronous `:flush_now` test hook so tests don't race the 5s timer.
- D-09: Footgun gates: (i) `terminate/2` must never reraise even in `:raise` mode — only honor `:raise` from the `handle_info(:flush, ...)` path; (ii) error-storm control — reuse `lib/scoria/observe/circuit_breaker.ex` or minimally log full detail once per consecutive-failure run, but always emit the telemetry event; (iii) `dropped_count` must count attempted `entries`, not post-reset state; (iv) wrap the emit defensively so a bad host telemetry handler can't re-enter the flush path.

**FOUND-02 / SPAN-02 — Span-kind taxonomy shape**
- D-10: Canonical casing = lowercase Scoria-native stored in `ai_spans.span_kind`; derive UPPERCASE `openinference.span.kind` at one seam (`SpanKind.to_openinference/1`).
- D-11: The 8 canonical kinds (native → OpenInference): `agent`→`AGENT`, `llm`→`LLM`, `prompt`→`PROMPT`, `tool`→`TOOL`, `mcp`→`TOOL` (the one non-1:1), `retriever`→`RETRIEVER`, `guardrail`→`GUARDRAIL`, `eval`→`EVALUATOR` (rename). `EMBEDDING`/`RERANKER` deferred as attrs on RETRIEVER; `CHAIN` deliberately absent.
- D-12: `error` is a STATUS, not a kind — REMOVE from the whitelist (9→8). `ai_spans.status_code` is the error signal. Render errored spans as their real kind's rail + a status overlay. Repurpose CSS `.scoria-span--error` → `.scoria-span--status-error`. No data migration needed.
- D-13: Jido default `"tool"` (replaces `"INTERNAL"`). Rule: `span_kind = SpanKind.normalize(metadata[:span_kind] || "tool")` — host-declared override only, no action-name inference.
- D-14: Shared module `Scoria.Observe.SpanKind` — plain compile-time-constant module, NOT `Ecto.Enum`. API: `kinds/0`, `kind?/1`, `normalize/2` (default `\\ "agent"`, coerces + logs + emits telemetry on fallback), `to_openinference/1`. Consumers: both UI components, both adapters, the conformance test.
- D-15: Drift-guard test (mandatory): (1) canary asserting the exact 8-kind list; (2) exhaustiveness — every kind has a non-raising `to_openinference/1` clause; (3) CSS coherence — assert `scoria-span--#{k}` rail exists for every kind; (4) anti-inline guard — grep both component sources for stray `~w(...)` span-kind literals.

**FOUND-03 — sequencing note**
- D-16: The version-pinned `Scoria.Observe.Semconv` module must exist before/with the adapter edits, because SPAN-02's mirrored `openinference.span.kind` key and SPAN-01's `gen_ai.*` keys must come from `Semconv`, not literals. Pin the OpenInference enum version in a moduledoc.

### Claude's Discretion

- **Trace-upsert transaction shape** for FOUND-01: single `Ecto.Multi` (trace-insert-if-missing → span-insert) vs independent upsert-then-insert. Constraint: ordered flush discipline (traces → spans → [events, Phase 53]) must be respected. **Resolved by this research — see Architecture Patterns below.**
- **Exact `gen_ai.*` key set** produced by `ReqLLM.OpenTelemetry.Attributes.start/1`+`.terminal/1`. **Resolved by this research — see Standard Stack / Code Examples.**
- **Whether to add a GIN index** on `ai_spans.attributes` now vs later. **Resolved by this research — already exists, see below; this is now a non-issue for Phase 51.**

### Deferred Ideas (OUT OF SCOPE)

- `EMBEDDING` / `RERANKER` first-class span kinds — stay as fields on the `RETRIEVER` span (v3.7+).
- `CHAIN` span kind — deliberate non-gap; `ai_traces`/workflow-run model fills it.
- `gen_ai.system` → `gen_ai.provider.name` adoption note (SEM-01, already-current per this research; see State of the Art) — no action needed since `req_llm` already emits the current name.
- Retry-with-backoff / dead-letter for flush failures (FOUND-01 Option D) — out of scope this phase.
- Full GIN-index + query-helper module for `attributes` queryability — see below, index already exists; query-helper module timing is still planner's call but is not blocking.
- RETRIEVER span, host-declared `feature`/`route`/`archetype`/`intent`, structured child spans + `ai_span_events`, docs conformance check — Phases 52–54.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOUND-01 | Trace rows upserted before span insert (closing `ai_spans.trace_id null:false` FK gap); silent `rescue` in `Buffer.flush_spans/1` no longer hides persistence failures | See Architecture Patterns §Trace-Upsert Transaction Shape; Buffer/Telemetry code read at `lib/scoria/observe/buffer.ex`, `lib/scoria/observe/telemetry.ex`; test scaffolding at `test/scoria/observe/buffer_test.exs` |
| FOUND-02 | One shared `span_kind` whitelist module consumed by both `WorkflowTreeComponent`/`TraceTreeComponent`, drift-guard test | See Architecture Patterns §SpanKind Module; current whitelists read at `lib/scoria_web/components/{workflow_tree,trace_tree}_component.ex` |
| FOUND-03 | Version-pinned internal semconv mapping module (`Scoria.Observe.Semconv`) as single source for every `gen_ai.*`/`openinference.*` key string | See Architecture Patterns §Semconv Module — recommends a *delegating* module, not a hand-duplicated constant list, given `ReqLLM.OpenTelemetry.Attributes` already owns the `gen_ai.*` key strings |
| SPAN-01 | Every LLM span carries `gen_ai.request.model/temperature/top_p/max_tokens/seed` + `gen_ai.usage.*` together, sourced via `ReqLLM.OpenTelemetry.Attributes` | Exact key set enumerated in Code Examples from direct read of `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` |
| SPAN-02 | Every span carries a correct `span_kind` from the 8-value taxonomy + mirrored `openinference.span.kind`, `mcp`→`"TOOL"` | See Architecture Patterns §SpanKind Module + Common Pitfalls §Casing Bug |
| COMPAT-01 | Legacy keys handled by explicit documented decision (clean replacement, CHANGELOG mapping table) | See Code Examples §CHANGELOG Mapping Table |

</phase_requirements>

## Summary

Phase 51 fixes one real correctness bug and finishes wiring three "half-built" conventions — it is not greenfield design. Direct code inspection (not just the milestone research base) surfaced two additional concrete findings beyond what CONTEXT.md and the prior research pass already knew, both load-bearing for planning:

1. **The migration already ships GIN indexes** on `ai_traces.attributes`, `ai_spans.attributes`, and `ai_span_events.attributes` (`priv/repo/migrations/20260510015813_create_ai_observability_tables.exs:14,37,52`). The "Claude's Discretion — GIN index timing" item in CONTEXT.md is **moot**: there is nothing to add. Do not re-verify this as an open question in planning; it is resolved.
2. **`metadata[:model]` in the current `req_llm.ex` adapter is a raw `%LLMDB.Model{}` struct**, not a string — `"llm.model_name" => metadata[:model]` stuffs a `@derive Jason.Encoder`-tagged struct (with `pricing`/`capabilities`/`modalities`/etc. fields) into the jsonb `attributes` map instead of a clean model-id string. This bug has never actually executed against Postgres (masked by the FK bug), and the existing adapter test (`test/scoria/observe/adapters/req_llm_test.exs`) uses an unrealistic `model: "gpt-4"` string fixture that doesn't reflect production `%LLMDB.Model{}` shape — so this has never been caught. Fixing SPAN-01 via `ReqLLM.OpenTelemetry.Attributes.request_model/1` (which extracts `.id`) fixes this incidentally, but the planner should know it's a real second bug, not cosmetic churn.

**Primary recommendation:** Fix the FK/persistence bug and adopter-visible key convention as one atomic `Ecto.Multi`-based Buffer flush that (a) upserts distinct trace ids via `insert_all(Trace, ..., on_conflict: :nothing, conflict_target: [:id])` before inserting spans, (b) surfaces failures via `Logger.error` + a new `[:scoria, :observe, :buffer, :flush_error]` telemetry event instead of a silent rescue, while both adapters merge `ReqLLM.OpenTelemetry.Attributes.start/1`+`.terminal/1` output (verbatim, do not hand-derive) and compute `span_kind` through one new `Scoria.Observe.SpanKind` module instead of hardcoded literals.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Trace/span persistence (FK fix, flush-error surfacing) | Backend / Observe pipeline (GenServer + Ecto) | Database (Postgres FK enforcement) | `Scoria.Observe.Buffer` is a GenServer writing through `Scoria.Repo`; the FK constraint itself lives in Postgres and is the actual enforcement mechanism being fixed |
| `gen_ai.*` / `openinference.*` attribute convention | Backend / Adapter layer (`req_llm.ex`, `jido.ex`) | — | Confirmed pass-through: `Telemetry`/`Buffer` do zero naming logic; all convention-key work belongs at the two adapter modules |
| `span_kind` taxonomy + CSS rail rendering | Backend (`Scoria.Observe.SpanKind`, source of truth) | Frontend/LiveView (`WorkflowTreeComponent`, `TraceTreeComponent` — consumers only) | The canonical whitelist and normalization logic must live in one backend module; UI components delegate, they don't decide |
| Legacy-key CHANGELOG/compat decision | Docs / Backend (adapter key set) | — | No runtime shim tier is in play (D-01 rejects dual-emit); this is a one-time backend key rename plus a docs artifact |
| Circuit-breaker / error-storm control for flush errors | Backend (`Scoria.Observe.CircuitBreaker`, reused or adapted) | — | Existing ETS-backed breaker; per-key (not model-id-only) so it is reusable for a fixed `:buffer_flush` key — see Common Pitfalls |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `req_llm` | `1.13.0` (locked, `mix.lock` confirmed; `mix.exs:98` pins `~> 1.13`) | Ships `ReqLLM.OpenTelemetry.Attributes.start/1`/`.terminal/1` — the `gen_ai.*` attribute builder | Already a declared peer dependency; zero-dependency, pure `Map`-building code (verified: no `:otel_tracer`/`:otel_span` calls in `attributes.ex`) `[VERIFIED: mix.lock + direct source read]` |
| OTel-GenAI semconv key names | schema `1.37.0` (confirmed at `deps/req_llm/lib/req_llm/open_telemetry.ex:112` — `@otel_schema_url "https://opentelemetry.io/schemas/1.37.0"`) | Naming convention for the `gen_ai.*` keys `req_llm` already emits | `[VERIFIED: deps/req_llm source]` — matches CONTEXT.md D-16's claim exactly |
| OpenInference span-kind taxonomy | no formal version scheme upstream (spec lives at `Arize-ai/openinference` `spec/semantic_conventions.md`, tracked by git history, not a semver tag) | Naming convention for `openinference.span.kind` values | `[CITED: milestone research STACK.md/FEATURES.md, fetched 2026-07-11]` — this session did not re-fetch; see Assumptions Log |

**No new runtime dependency this phase.** `mix.exs` is unchanged — confirmed no calls anywhere in `lib/` to `ReqLLM.OpenTelemetry.attach/2` or the OTel SDK; Scoria only needs the dependency-free `Attributes` module.

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Ecto.Multi` | ships with `ecto` (already a dependency; already used elsewhere: `lib/scoria/workflows/batch_enqueue.ex`, `lib/scoria/knowledge.ex`, `lib/scoria/eval.ex`) | Wraps the trace-upsert + span-insert as one atomic flush step | Recommended transaction shape for FOUND-01 — see Architecture Patterns |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Ecto.Multi` wrapping trace-upsert + span-insert | Two independent `Repo.insert_all` calls (upsert-then-insert, not transactional) | Simpler code, but a crash between the two calls could leave spans referencing traces inconsistently under concurrent Buffer instances (multiple named buffers, or clustered BEAM nodes) — `Multi` costs nothing extra here since both statements already run in the same `flush_spans/1` callback |
| Hand-deriving `gen_ai.*` keys from `metadata[:request_options]` | Calling `ReqLLM.OpenTelemetry.Attributes.start/1`/`.terminal/1` | Hand-deriving would duplicate ~15 already-correct keys and risks drifting from `req_llm`'s own vocabulary; **not recommended** — always call the builder |
| Reusing `Scoria.Observe.CircuitBreaker` as-is (D-09's first suggestion) | A dedicated, simpler consecutive-failure counter local to `Buffer` state | `CircuitBreaker` is model_id-keyed ETS storage designed for LLM-request retry backoff (`open?/1`, `record_failure/2`, half-open sweep) — it *can* be reused generically with a fixed key like `:buffer_flush_storm`, but its `open?/1`/half-open semantics (designed to gate future *calls*) don't map cleanly onto "log full detail once per consecutive-failure run." Recommend the simpler local counter unless the planner wants the exact same ETS-backed observability surface for consistency. |

**Installation:** No new packages. No `mix.exs` change required for this phase.

**Version verification:**
```bash
$ grep -A1 '"req_llm"' mix.lock
"req_llm": {:hex, :req_llm, "1.13.0", ...}
```
Confirmed locked at `1.13.0`; Hex latest is `1.17.1` per prior milestone research — no relevant OTel/`gen_ai` changes between them (already verified at STACK.md research pass; not re-verified this session, tagged `[CITED: .planning/research/STACK.md]`).

## Package Legitimacy Audit

**Not applicable this phase.** No new packages are installed — `mix.exs` remains unchanged; Phase 51 exclusively consumes the already-locked `req_llm 1.13.0` dependency's existing public API (`ReqLLM.OpenTelemetry.Attributes`). The Package Legitimacy Gate protocol is skipped per its own trigger condition ("whenever this phase installs external packages").

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│ ADAPTERS (telemetry-attached, host must .attach() — see Pitfall     │
│ "Unwired Supervision Tree" below)                                    │
│                                                                       │
│  Scoria.Observe.Adapters.ReqLLM                                      │
│   listens: [:req_llm, :request, :stop]                              │
│   NEW: calls Semconv.merge_req_llm_attributes(metadata)              │
│        -> ReqLLM.OpenTelemetry.Attributes.start/1 + .terminal/1      │
│   NEW: span_kind = SpanKind.normalize(metadata[:operation] || "llm") │
│   NEW: attributes["openinference.span.kind"]                        │
│        = SpanKind.to_openinference(span_kind)                       │
│                                                                       │
│  Scoria.Observe.Adapters.Jido                                        │
│   listens: [:jido, :action, :stop]                                   │
│   NEW: span_kind = SpanKind.normalize(metadata[:span_kind] || "tool")│
└───────────────────────────┬───────────────────────────────────────────┘
                            │ :telemetry.execute([:scoria,:observe,:span,:stop], %{}, span_map)
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Scoria.Observe.Telemetry  (UNCHANGED pass-through for span path;     │
│ NEW: emit_flush_error/1 wrapper added beside emit_span_delta/1)      │
│  -> Redactor.redact/1  (safe by construction — key-exact-match,      │
│     no gen_ai.*/openinference.* key collides with the deny-list)     │
│  -> ReviewerBroadcast.span_stopped/1                                 │
│  -> Buffer.cast_span(Map.take(redacted, @span_buffer_fields))        │
└───────────────────────────┬───────────────────────────────────────────┘
                            │ GenServer.cast
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Scoria.Observe.Buffer  (GenServer, in-memory list, flush timer)      │
│  NEW opt: :on_flush_error (:log default | :raise), start_link opt   │
│  NEW: handle_call(:flush_now, ...) — synchronous test hook           │
│  MODIFIED flush_spans/1 (now an Ecto.Multi, see below):              │
│   1. distinct trace_ids from buffered spans                          │
│   2. Multi.insert_all(:traces, Trace, trace_stub_entries,             │
│        on_conflict: :nothing, conflict_target: [:id])                │
│   3. Multi.insert_all(:spans, Span, span_entries)                    │
│   4. Repo.transaction(multi)                                         │
│   5. on {:error, ...} -> Logger.error(structured) +                  │
│        Telemetry.emit_flush_error(%{dropped_count: ..., ...})        │
│  terminate/2: NEVER honors :raise (always :log-equivalent path)       │
└───────────────────────────┬───────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Postgres: ai_traces (upserted) ←FK← ai_spans (span_kind, attributes) │
│  Both attributes columns already GIN-indexed (migration 20260510)    │
└─────────────────────────────────────────────────────────────────────┘

Read path (UNCHANGED components, NEW shared source):
  WorkflowTreeComponent.span_kind/1 ──┐
                                       ├──> Scoria.Observe.SpanKind.normalize/2 (NEW, shared)
  TraceTreeComponent.span_kind/1   ───┘         + kinds/0, kind?/1, to_openinference/1
```

A reader can trace the primary use case (an LLM call producing a persisted, correctly-kinded span) start to finish: adapter → telemetry → redaction → buffer → transactional flush → Postgres, then back out through the two UI components reading `ai_spans.span_kind` via the same shared module that wrote it.

### Recommended Project Structure

```
lib/scoria/observe/
├── semconv.ex          # NEW — Semconv module (FOUND-03)
├── span_kind.ex         # NEW — SpanKind module (FOUND-02/SPAN-02, D-14)
├── buffer.ex            # MODIFIED — Ecto.Multi flush, :on_flush_error, :flush_now
├── telemetry.ex         # MODIFIED — + emit_flush_error/1 wrapper
├── circuit_breaker.ex    # REUSED (optionally, for storm control) or left untouched
├── adapters/
│   ├── req_llm.ex        # MODIFIED — Semconv + SpanKind wiring, drop legacy keys
│   └── jido.ex           # MODIFIED — SpanKind wiring
lib/scoria_web/components/
├── workflow_tree_component.ex  # MODIFIED — delegate to SpanKind
└── trace_tree_component.ex     # MODIFIED — delegate to SpanKind
assets/css/04-components.css    # MODIFIED — --error -> --status-error rail rename
```

### Pattern 1: Trace-Upsert Transaction Shape (resolves Claude's Discretion)

**What:** Wrap "ensure trace row(s) exist" + "insert span rows" as a single `Ecto.Multi`, executed inside `Buffer.flush_spans/1`.

**When to use:** Every buffer flush cycle (timer-driven, `:flush_now` test-driven, or `terminate/2`-driven).

**Why this shape over three independent calls:** `Buffer` already batches N spans per flush; those N spans can reference any number of distinct `trace_id`s (today, since nothing threads Scoria's own trace/tenant context through a real `ReqLLM` call — see Open Questions — every span in practice gets its own fresh `Ecto.UUID.generate()`'d trace_id, so a flush batch is effectively N spans → up to N distinct trace_ids). Deduplicating and upserting all of them in one `insert_all` (rather than one `Repo.get_or_insert` per span) avoids N round-trips and is safe under `ON CONFLICT DO NOTHING` if two Buffer instances (or two BEAM nodes) ever race on the same `trace_id`.

```elixir
# Source: derived from the existing Ecto.Multi convention already used in
# lib/scoria/workflows/batch_enqueue.ex and lib/scoria/knowledge.ex — this is
# not a new pattern for the codebase, just a new call site.
defp flush_spans([]), do: :ok

defp flush_spans(spans, opts) do
  now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

  span_entries =
    Enum.map(spans, fn span ->
      span
      |> Map.put_new_lazy(:id, fn -> Ecto.UUID.generate() end)
      |> Map.put_new(:inserted_at, now)
      |> Map.put_new(:updated_at, now)
    end)

  trace_entries =
    span_entries
    |> Enum.map(& &1.trace_id)
    |> Enum.uniq()
    |> Enum.map(&%{id: &1, inserted_at: now, updated_at: now})

  multi =
    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(:traces, Scoria.Repo.Trace, trace_entries,
      on_conflict: :nothing,
      conflict_target: [:id]
    )
    |> Ecto.Multi.insert_all(:spans, Scoria.Repo.Span, span_entries)

  case Scoria.Repo.transaction(multi) do
    {:ok, _changes} ->
      :ok

    {:error, failed_op, failed_value, _changes_so_far} ->
      dropped_count = length(span_entries)

      Logger.error(
        "Scoria.Observe.Buffer failed to flush #{dropped_count} span(s) " <>
          "(op=#{failed_op}): #{inspect(failed_value)}"
      )

      Scoria.Observe.Telemetry.emit_flush_error(%{
        dropped_count: dropped_count,
        buffer: opts[:name],
        max_size: opts[:max_size],
        kind: :error,
        error: failed_value
      })

      if opts[:on_flush_error] == :raise and opts[:from_timer?] do
        raise "Scoria.Observe.Buffer flush failed: #{inspect(failed_value)}"
      end

      :ok
  end
end
```

Note: `Ecto.Multi.insert_all/4` returns `{:ok, {count, nil_or_returned}}` per step on success and `{:error, failed_op, failed_value, changes_so_far}` on failure — but `insert_all` inside a `Multi` does not itself raise on a constraint violation the way `Repo.insert!` would; a raw Postgrex FK/constraint error from `insert_all` surfaces as an exception during `Repo.transaction/1`, which should still be caught with a `try/rescue` around the `Repo.transaction(multi)` call (not relied upon as an `{:error, ...}` tuple) since `insert_all` bypasses changesets and does not validate before hitting Postgres. **Recommend wrapping the whole `Repo.transaction(multi)` call in `try/rescue` in addition to matching on `{:error, ...}`,** so both changeset-shaped Multi failures and raw Postgrex exceptions are caught identically. This preserves D-05's "never crash the host app" guarantee even for failure modes `Ecto.Multi` itself doesn't turn into a tuple.

### Pattern 2: SpanKind Module (D-14)

**What:** A plain module with compile-time constant lists — not `Ecto.Enum` (would reject drifted/legacy rows and hardcode casing into the schema, per D-14's explicit rejection).

**When to use:** Every write site (both adapters) and every read site (both UI components).

```elixir
# Source: derived directly from CONTEXT.md D-11/D-14 + confirmed against
# lib/scoria_web/components/workflow_tree_component.ex:38 and
# lib/scoria_web/components/trace_tree_component.ex:86-95 (current drifted lists)
defmodule Scoria.Observe.SpanKind do
  @moduledoc """
  Canonical span_kind taxonomy — single source of truth for both write sites
  (adapters) and read sites (UI components). Native casing is lowercase;
  `to_openinference/1` derives the UPPERCASE OpenInference portability value.

  Pinned against the OpenInference span-kind enum as documented at
  github.com/Arize-ai/openinference/blob/main/spec/semantic_conventions.md
  (no formal version scheme upstream; pinned by fetch date 2026-07-11 per
  milestone research — re-verify if OpenInference publishes a versioned spec).
  """

  @kinds ~w(agent llm prompt tool mcp retriever guardrail eval)

  @openinference_map %{
    "agent" => "AGENT",
    "llm" => "LLM",
    "prompt" => "PROMPT",
    "tool" => "TOOL",
    "mcp" => "TOOL",
    "retriever" => "RETRIEVER",
    "guardrail" => "GUARDRAIL",
    "eval" => "EVALUATOR"
  }

  @spec kinds() :: [String.t()]
  def kinds, do: @kinds

  @spec kind?(term()) :: boolean()
  def kind?(value), do: to_string(value) |> String.downcase() in @kinds

  @doc """
  Normalizes any host/adapter-supplied value to a canonical kind. Falls back
  to `default` (default: "agent") on an unrecognized value — and unlike the
  silent `_ -> "agent"` this replaces, LOGS + EMITS TELEMETRY on fallback
  (coheres with FOUND-01's "observable, not silent" principle).
  """
  @spec normalize(term(), String.t()) :: String.t()
  def normalize(value, default \\ "agent") do
    normalized = value |> to_string() |> String.downcase()

    if normalized in @kinds do
      normalized
    else
      Logger.warning("Unrecognized span_kind #{inspect(value)}, defaulting to #{default}")
      :telemetry.execute([:scoria, :observe, :span_kind, :fallback], %{}, %{
        value: value,
        default: default
      })
      default
    end
  end

  @spec to_openinference(String.t()) :: String.t()
  def to_openinference(kind) when kind in @kinds, do: Map.fetch!(@openinference_map, kind)
end
```

Note: `normalize/2`'s telemetry event name (`[:scoria, :observe, :span_kind, :fallback]`) is **not specified by CONTEXT.md** — D-14 only says "logs + emits telemetry," it does not name the event. Flag to the planner as a naming decision to make explicitly (not a research gap, just needs a name picked and documented alongside the `flush_error` event).

### Pattern 3: Semconv Module — Delegate, Don't Duplicate (D-16, resolves FOUND-03 scope)

**Critical scoping clarification for the planner:** the milestone-level Pitfalls research (written before this phase's own code-level pass) recommended `Semconv.request_model/0 -> "gen_ai.request.model"`-style per-key constant functions. **After reading `ReqLLM.OpenTelemetry.Attributes` directly, this is the wrong shape for the `gen_ai.*` half.** Those ~20 key strings are already defined, version-pinned (implicitly, via the `req_llm ~> 1.13` dependency constraint + `mix.lock` hash), and correctly built inside `req_llm`'s own vendored source — Scoria's adapter should call the builder wholesale (`Attributes.start/1` + `.terminal/1`), not re-declare each key name as a second, parallel constant that could drift from what `req_llm` actually emits.

`Semconv`'s real job for Phase 51 is narrower and still satisfies FOUND-03's success criterion #4 ("every `gen_ai.*`/`openinference.*` key string ... traces back to one version-pinned mapping module, not inline literals at multiple call sites"):

```elixir
defmodule Scoria.Observe.Semconv do
  @moduledoc """
  Single source for every semconv key Scoria itself defines, plus the one
  call site that merges the req_llm-owned gen_ai.* attribute set.

  gen_ai.* key STRINGS are owned and version-pinned by the `req_llm ~> 1.13`
  dependency (ReqLLM.OpenTelemetry.Attributes, OTel-GenAI schema 1.37.0 —
  see deps/req_llm/lib/req_llm/open_telemetry.ex @otel_schema_url). Do not
  hand-duplicate those key names here; call the builder.

  This module owns:
  - the one key Scoria itself writes: "openinference.span.kind"
  - (Phase 52+) reserved host-declared keys: feature/route/archetype/intent
  """

  @openinference_span_kind_key "openinference.span.kind"

  @spec openinference_span_kind_key() :: String.t()
  def openinference_span_kind_key, do: @openinference_span_kind_key

  @doc """
  Merges the req_llm-owned gen_ai.* attribute set for a request/response
  telemetry metadata map. Sole call site for ReqLLM.OpenTelemetry.Attributes
  so adapters never inline gen_ai.* strings directly.
  """
  @spec merge_req_llm_attributes(map(), map()) :: map()
  def merge_req_llm_attributes(attributes, metadata) do
    attributes
    |> Map.merge(ReqLLM.OpenTelemetry.Attributes.start(metadata))
    |> Map.merge(ReqLLM.OpenTelemetry.Attributes.terminal(metadata))
  end
end
```

This means `req_llm.ex`'s adapter body shrinks to calling `Semconv.merge_req_llm_attributes/2` + `Semconv.openinference_span_kind_key/0`, never writing a `"gen_ai.*"` or `"openinference.*"` string literal itself — satisfying the letter of FOUND-03 without inventing a second, driftable copy of `req_llm`'s own key vocabulary.

### Anti-Patterns to Avoid

- **Re-deriving `gen_ai.*` key names by hand inside `Semconv` or the adapter**: duplicates ~20 already-correct lines and risks drift from what `req_llm`'s own live OTel bridge would emit — call `ReqLLM.OpenTelemetry.Attributes.start/1`/`.terminal/1` verbatim.
- **Reading `metadata[:model]` directly as a string** in the adapter (current bug): it is an `%LLMDB.Model{}` struct at runtime; use `ReqLLM.OpenTelemetry.Attributes.request_model/1` (extracts `.id`) instead of a raw literal assignment.
- **`Ecto.Enum` for `span_kind`**: rejected explicitly by D-14 — would reject any already-drifted/legacy row on load and bind casing assumptions into the schema itself.
- **Typed columns for any `gen_ai.*`/`openinference.*` field on `ai_spans`**: locked discipline (convention-over-columns); the GIN index already exists (see Summary) so there is no queryability argument left for typed columns this phase.
- **Trusting `{:error, ...}` pattern-matching alone on `Repo.transaction(multi)`**: `insert_all` inside a `Multi` can raise a raw Postgrex exception rather than returning an error tuple (no changeset validation happens before the SQL round-trip) — wrap in `try/rescue` too (see Pattern 1).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Building the `gen_ai.*` attribute map from ReqLLM telemetry metadata | A hand-written key-by-key mapper in `req_llm.ex` | `ReqLLM.OpenTelemetry.Attributes.start/1` + `.terminal/1` (already a dependency, already correct, already version-pinned by `req_llm ~> 1.13`) | Would duplicate ~20 lines of already-correct code and risk future drift from `req_llm`'s own OTel bridge |
| Trace-upsert-before-span-insert coordination | A hand-rolled `Repo.get_or_insert` loop per span, or a raw SQL `INSERT ... ON CONFLICT` string | `Ecto.Multi.insert_all/4` with `on_conflict: :nothing, conflict_target: [:id]` — already the codebase's established pattern (`lib/scoria/workflows/batch_enqueue.ex`, `lib/scoria/knowledge.ex`) | One transactional round-trip per flush batch instead of N; matches existing project idiom, no new primitive |
| Error-storm rate limiting for repeated flush failures | A brand-new ETS-backed rate limiter | Either the existing `Scoria.Observe.CircuitBreaker` (generic by ETS key, not model-id-specific — usable with a fixed key like `:buffer_flush_storm`) or a simple counter in `Buffer`'s own GenServer state | D-09 explicitly names `CircuitBreaker` as reusable; a bespoke rate-limiter would duplicate its ETS-table lifecycle machinery |

**Key insight:** every "don't hand-roll" item in this phase already has an existing, working implementation somewhere in the dependency tree or the codebase itself — this phase is disproportionately about *wiring existing correct machinery together* rather than writing new algorithms.

## Common Pitfalls

### Pitfall 1: `metadata[:model]` Is a Struct, Not a String (newly confirmed this session)

**What goes wrong:** `lib/scoria/observe/adapters/req_llm.ex:17` currently does `"llm.model_name" => metadata[:model]`. At a real `[:req_llm, :request, :stop]` telemetry event, `metadata[:model]` is populated from `context.model`, an `%LLMDB.Model{}` struct (confirmed: `deps/req_llm/lib/req_llm/telemetry.ex:491`, `request_metadata/2`'s `base` map sets `model: context.model`). `LLMDB.Model` does `@derive {Jason.Encoder, only: [:id, :model, :provider, ..., :pricing, :capabilities, :modalities, ...]}` (`deps/llm_db/lib/llm_db/model.ex:198`), so this doesn't crash Jason encoding — it silently serializes a large nested JSON object under `attributes["llm.model_name"]` instead of a clean model-id string.

**Why it happens:** The existing adapter test (`test/scoria/observe/adapters/req_llm_test.exs:26`) fixtures `model: "gpt-4"` — a plain string — which is not the real production shape, so this bug has never been exercised by any test, and (separately) has never reached Postgres due to the FK bug. Two independent masking bugs hid one real bug.

**How to avoid:** Use `ReqLLM.OpenTelemetry.Attributes.request_model/1` (calls the private `request_model_for/1` which pattern-matches `%LLMDB.Model{id: id}` and extracts `.id`) rather than any raw `metadata[:model]` literal assignment. This is naturally fixed once SPAN-01 wires in `Attributes.start/1` (which already computes `"gen_ai.request.model" => request_model(metadata)` correctly) — but the planner/executor should know this is a real second bug being fixed, not incidental churn, and should update the existing adapter test's fixture to use a real (or realistic mock) `%LLMDB.Model{}` so this class of bug can't recur silently.

**Warning signs:** Any test fixture for `[:req_llm, :request, :stop]` that sets `model:` to a bare string instead of an `%LLMDB.Model{}` (or a map with the same shape) is testing an unrealistic path.

### Pitfall 2: `span_kind` Casing Bug (confirmed root cause)

**What goes wrong:** Both adapters currently emit uppercase literals (`"LLM"`, `"INTERNAL"` — `req_llm.ex:28`, `jido.ex:28`). Both UI whitelists match against **lowercase** strings after `String.downcase/1` (`trace_tree_component.ex:89-90`) or exact lowercase list membership with no downcase at all (`workflow_tree_component.ex:38`, which would never match `"LLM"` either). Net effect: every span in production today silently renders as generic `"agent"` styling. `"INTERNAL"` isn't in either whitelist regardless of case.

**How to avoid:** `SpanKind.normalize/2` fixes this at the single write seam (D-10's decision: canonical casing is lowercase-native, stored as-is in the `span_kind` column) — adapters must call `SpanKind.normalize(...)` rather than assigning a literal, and the UI components must delegate to `SpanKind.kind?/1`/`normalize/2` rather than keeping their own inline `~w(...)` lists (D-15's anti-inline guard test enforces this structurally).

**Warning signs:** Any `span_kind:` assignment in an adapter that is a bare string literal instead of `SpanKind.normalize(...)`.

### Pitfall 3: `Ecto.Multi.insert_all` Failure Shape Mismatch

**What goes wrong:** `insert_all` inside an `Ecto.Multi` skips changeset validation and goes straight to SQL — a constraint violation (e.g., the `ai_spans.trace_id` FK, or a `name`/`start_time` `NOT NULL` violation) raises a `Postgrex.Error`/`Ecto.ConstraintError` during `Repo.transaction/1`, it does **not** come back as a tidy `{:error, failed_op, failed_value, changes_so_far}` tuple the way a `Multi.insert` (singular, changeset-based) failure would. If the flush code only pattern-matches on `{:error, ...}`, a raw exception will propagate uncaught out of `handle_info(:flush, state)` and crash the `Buffer` GenServer — reintroducing exactly the instability D-05 explicitly forbids ("Scoria must never crash/destabilize the host app").

**How to avoid:** Wrap `Repo.transaction(multi)` itself in `try/rescue` (see Pattern 1's code example) in addition to matching `{:error, ...}` — both failure shapes must route to the same `Logger.error` + `Telemetry.emit_flush_error/1` path.

**Warning signs:** A test that induces a real Postgrex constraint failure (per D-08's primary test approach) and observes the `Buffer` process crash/restart instead of surfacing the telemetry event is the exact failure mode this pitfall predicts.

### Pitfall 4: `CircuitBreaker` Is Model-ID-Keyed, Not Generically "Storm Control"-Shaped

**What goes wrong:** `Scoria.Observe.CircuitBreaker` (`lib/scoria/observe/circuit_breaker.ex`) is designed around LLM-request retry backoff: `open?(model_id)`, `record_failure(model_id, opts)`, a half-open sweep on a timer (`Scoria.Observe.CircuitBreaker.Manager`, also not currently started anywhere in `lib/scoria/application.ex` — see Environment Availability). Its semantics ("is this model currently circuit-broken for new calls?") don't map 1:1 onto "should this particular flush-error log line be suppressed because we've already logged N in a row?" — reusing it verbatim per D-09's first suggestion is architecturally awkward (there's no "call" being gated, just a log-verbosity decision).

**How to avoid:** Either (a) call `CircuitBreaker.record_failure(:buffer_flush_storm, opts)`/`open?(:buffer_flush_storm)` purely for the ETS-backed counting/half-open-reset mechanics, ignoring the "open = block calls" semantics (there's nothing to block), or (b) implement a simple consecutive-failure counter directly in `Buffer`'s own GenServer state (simpler, no dependency on a module designed for a different purpose). D-09 explicitly allows the second, simpler option ("or minimally: log full detail once per consecutive-failure run"). **Recommend (b)** given the semantic mismatch, unless the planner specifically wants storm-control machinery consistent across both subsystems.

### Pitfall 5: Unwired Observe Pipeline (confirmed — not a Phase 51 blocker, but a scoping fact)

**What goes wrong:** `Scoria.Observe.Buffer`, `Scoria.Observe.Telemetry.attach/1`, `Scoria.Observe.Adapters.ReqLLM.attach/0`, `Scoria.Observe.Adapters.Jido.attach/0`, and `Scoria.Observe.CircuitBreaker.Manager` are **not started or attached anywhere in `lib/scoria/application.ex`** (grep-confirmed: zero non-test call sites for any of `Buffer.start_link`, `Observe.Telemetry.attach`, `Adapters.ReqLLM.attach`, `Adapters.Jido.attach`). They are also **not documented anywhere in `guides/`** as something a host app must wire into its own supervision tree. Only test files (`test/scoria/observe/buffer_test.exs`, `test/scoria/observe/adapters/{req_llm,jido}_test.exs`, `test/scoria_web/live/orchestrator_live_integration_test.exs`) call these directly.

**Why this matters for Phase 51 planning:** ROADMAP Success Criterion #1 ("A span emitted through the real adapter path ... persists as a row in `ai_spans` ... verifiable against a real Postgres") must be read in light of this: there is no existing "real adapter path" running end-to-end in production today, because nothing starts the pipeline. The existing test convention (`buffer_test.exs`: `start_supervised!({Buffer, [...]})`; `req_llm_test.exs`: `Scoria.Observe.Adapters.ReqLLM.attach()` in `setup`) is the correct and sufficient verification pattern for this phase — a test that wires up `Buffer` + `Telemetry.attach` + `Adapters.ReqLLM.attach`/`Adapters.Jido.attach` in its own `setup`, fires a synthetic `:telemetry.execute([:req_llm, :request, :stop], ...)` or `[:jido, :action, :stop]`, waits for (or forces via `:flush_now`) a flush, then asserts real Postgres rows. **Do not read Success Criterion #1 as requiring Scoria to add these to `Application.start/2`** — that would be new scope (host-supervision-tree wiring) not named in FOUND-01/02/03/SPAN-01/02/COMPAT-01. Flag to the planner as an explicit scoping decision to confirm, not assume.

### Pitfall 6: `metadata[:trace_id]`/`tenant_id`/`workflow_run_id`/`parent_id`/`session_id` Have No Real Producer (confirmed — informs verification scope, not a blocker)

**What goes wrong:** `ReqLLM.Telemetry.request_metadata/2` (`deps/req_llm/lib/req_llm/telemetry.ex:484-514`) builds its metadata map from exactly these keys: `request_id, operation, mode, provider, model, transport, reasoning, request_options, server, request_started_system_time, request_summary, response_summary, http_status, finish_reason, usage` (+ conditionally `streaming, request_payload, response_payload, error, builtin_tool_timing`). **There is no `trace_id`, `tenant_id`, `workflow_run_id`, `parent_id`, or `session_id` key anywhere in `req_llm`'s own telemetry context** — these are pure Scoria-domain concepts `req_llm` has no knowledge of, and no code in `lib/scoria/**` today calls `ReqLLM.Generation.generate_text/3` (or similar) with any mechanism that would thread these back into the telemetry metadata. Concretely, this means `metadata[:trace_id] || Ecto.UUID.generate()` (`req_llm.ex:31`) will fire its fallback on literally every real production span today, so even after the FK fix, every LLM span in real usage gets its own singleton trace (never grouped with sibling spans of the same logical request) until some future phase adds a trace-context-threading mechanism.

**Why this doesn't block Phase 51:** none of FOUND-01/02/03/SPAN-01/02/COMPAT-01 name "thread trace context through a real ReqLLM call" as a deliverable — this is implicitly Phase 52+/future scope (or an existing gap nobody has named yet). The existing adapter tests already test the adapter's transform logic by firing a synthetic telemetry event with an explicit `trace_id:` key present in the metadata map (bypassing the question of where a real call would get one) — this is the correct test shape for Phase 51 too.

**How to avoid scope confusion:** Document this explicitly as an Open Question (below) rather than silently assuming it's solved; do not let it expand Phase 51's scope.

## Code Examples

### Exact `gen_ai.*` Key Set — `ReqLLM.OpenTelemetry.Attributes.start/1`

Source: `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` (read directly, this session).

```elixir
# start/1 output (keys present when the underlying metadata field is non-nil;
# nil/empty-list values are dropped by compact/1):
%{
  "gen_ai.provider.name" => "openai",              # from metadata[:provider] or model.provider
  "gen_ai.operation.name" => "chat",                # from metadata[:operation]
  "gen_ai.request.model" => "gpt-5",                # from metadata[:model].id (struct-safe)
  "gen_ai.output.type" => "text",                   # derived from operation
  "req_llm.request_id" => "2184",

  # from metadata[:request_options] (all optional, dropped if nil):
  "gen_ai.request.temperature" => 0.7,
  "gen_ai.request.top_p" => ...,
  "gen_ai.request.top_k" => ...,
  "gen_ai.request.max_tokens" => ...,
  "gen_ai.request.frequency_penalty" => ...,
  "gen_ai.request.presence_penalty" => ...,
  "gen_ai.request.stop_sequences" => ...,
  "gen_ai.request.seed" => ...,
  "gen_ai.request.choice.count" => ...,
  "gen_ai.request.stream" => ...,
  "gen_ai.request.encoding_formats" => ...,
  "gen_ai.conversation.id" => ...,

  # from metadata[:reasoning] (optional):
  "gen_ai.request.reasoning.effort" => ...,
  "gen_ai.request.reasoning.budget_tokens" => ...,

  # from metadata[:server] (optional):
  "server.address" => "api.openai.com",
  "server.port" => 443,

  # only if provider in [:openai, :openai_codex, :azure]:
  "openai.api.type" => ...,
  "openai.request.service_tier" => ...
}
```

### Exact `gen_ai.*` Key Set — `.terminal/1`

```elixir
%{
  "gen_ai.response.finish_reasons" => ["stop"],
  "gen_ai.response.time_to_first_chunk" => 0.42,     # streaming only

  # from metadata[:usage]:
  "gen_ai.usage.input_tokens" => 150,
  "gen_ai.usage.output_tokens" => 42,
  "gen_ai.usage.cache_read.input_tokens" => ...,
  "gen_ai.usage.cache_creation.input_tokens" => ...,
  "gen_ai.usage.reasoning.output_tokens" => ...,
  "gen_ai.usage.cost" => ...,

  # from metadata[:response_payload] / metadata[:model]:
  "gen_ai.response.id" => "chatcmpl-...",
  "gen_ai.response.model" => "gpt-5-2026-01-01",     # ACTUAL model used, may differ from request.model

  # embeddings only (metadata[:operation] == :embedding):
  "gen_ai.embeddings.dimension.count" => ...,

  # only if provider in [:openai, :openai_codex, :azure]:
  "openai.response.service_tier" => ...,
  "openai.response.system_fingerprint" => ...,

  # only if http_status >= 400:
  "error.type" => "429"
}
```

**Directly answers SPAN-01's requirement:** `gen_ai.request.model`, `.temperature`, `.top_p`, `.max_tokens`, `.seed`, and `gen_ai.usage.*` are all present in this exact set — confirming ROADMAP Success Criterion #2 ("all four model-config params present on the same span... never a partial subset") is satisfiable by a single call to both functions, with zero hand-mapping.

**Replay-fidelity nuance (relevant to Pitfall 7 in the milestone research base):** `gen_ai.request.model` (what was asked for) and `gen_ai.response.model` (what was actually used) are two different keys sourced from two different points in the lifecycle — worth calling out in any doc-delta since some providers silently substitute/route to a different underlying model than requested.

### CHANGELOG Old→New Key Mapping Table (COMPAT-01, D-03)

| Old key (current adapter) | New key(s) | Note |
|---|---|---|
| `llm.model_name` | `gen_ai.request.model` (requested) / `gen_ai.response.model` (actually used) | Was a single string; now split into request-vs-response semantics — an intentional precision gain, call this out explicitly since it's not a pure 1:1 rename |
| `llm.token_count` | `gen_ai.usage.input_tokens` + `gen_ai.usage.output_tokens` | Was a single total; now split input/output — the old total is `input_tokens + output_tokens` if an adopter needs to reconstruct it |
| `req.url` | `server.address` + `server.port` | **Lossy**: old key held (a presumed) full request URL string; new keys hold only host+port, not path. Combined with `gen_ai.operation.name` (e.g. `"chat"`) this covers "what kind of call, to what host" but not the literal path — call this asymmetry out explicitly in the CHANGELOG so adopters don't assume path-level detail survived |

### Buffer Test Scaffolding Pattern (existing convention to extend, not replace)

```elixir
# Source: test/scoria/observe/buffer_test.exs (existing pattern, confirmed)
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  pid = start_supervised!({Buffer, [name: :test_buffer, flush_interval: 10, max_size: 5, on_flush_error: :raise]})
  %{buffer_pid: pid}
end
```
Note: the existing `buffer_test.exs` setup **pre-inserts a `%Trace{}` row manually** before testing span flush (`{:ok, trace} = Repo.insert(%Trace{id: Ecto.UUID.generate()})`) — this is precisely the "hand-inserts the trace first" pattern ROADMAP Success Criterion #1 explicitly says the *new* verification must NOT rely on. Existing tests using this setup should be either updated to remove the manual pre-insert (proving the new auto-upsert works) or explicitly kept as a *regression* test for the already-has-a-trace case, with a new test added that omits the pre-insert and asserts the trace row is created automatically.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `gen_ai.system` | `gen_ai.provider.name` | Already current in `req_llm 1.13.0`'s output — confirmed no occurrence of `gen_ai.system` anywhere in `attributes.ex` | No action needed this phase; SEM-01 (deferred) only matters if Scoria ever hand-wrote this key, which it doesn't |
| `gen_ai.usage.prompt_tokens`/`completion_tokens` | `gen_ai.usage.input_tokens`/`output_tokens` | Already current in `req_llm`'s `usage/1` builder | No action needed; confirmed by direct source read this session |
| Scoria's own `"llm.model_name"`/`"llm.token_count"`/`"req.url"` | `gen_ai.*`/`server.*` | This phase (COMPAT-01) | The actual rename this phase performs — everything else in the table above is already-done upstream work Scoria merely inherits by calling the builder |

**Deprecated/outdated:** None beyond what COMPAT-01 already targets. The OTel-GenAI semconv namespace remains entirely `Development`-stability upstream (per milestone STACK.md research, fetched 2026-07-11) — this is why convention-over-columns remains the correct discipline, not a stale caveat.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | OpenInference span-kind enum has no formal version/semver scheme upstream (pin by fetch-date only) | Standard Stack, Architecture Patterns §SpanKind Module | Low — if OpenInference does publish a version tag, the moduledoc comment is just less precise than it could be; doesn't affect functional correctness of the 8-kind mapping, which was independently cross-checked against the spec content itself (not re-fetched this session, `[CITED: milestone FEATURES.md]`) |
| A2 | `req_llm` Hex latest (`1.17.1`) has no relevant `gen_ai`/OTel changes vs the locked `1.13.0` | Standard Stack | Low-Medium — this was verified by the prior milestone research pass (STACK.md), not re-verified this session; if wrong, a `mix deps.update req_llm` could change the exact key set. Recommend the planner re-run `mix hex.outdated req_llm` as a cheap pre-flight check before finalizing the key list in a test |
| A3 | No code in `lib/scoria/**` currently threads `trace_id`/`tenant_id`/`workflow_run_id` through a real `ReqLLM.Generation` call (Pitfall 6) | Common Pitfalls | Medium — grounded in a full-repo grep for `ReqLLM.\(generate_text\|stream_text\|generate_object\)` outside tests returning zero hits; if a call site exists that this grep pattern missed (e.g., a different function name), the "every span gets a singleton trace" claim would be wrong for that call site specifically. Recommend the planner re-grep before writing the Phase 51 verification test if this matters to the test's realism |

**If this table is empty:** N/A — three assumptions logged above, all low-to-medium risk and independently re-checkable with a single command each.

## Open Questions (RESOLVED)

1. **Is "real adapter path" verification (ROADMAP Success Criterion #1) satisfied by a test that wires up `Buffer`/`Telemetry.attach`/`Adapters.*.attach` in its own `setup` block and fires a synthetic `:telemetry.execute`, or does it require the Observe pipeline to be added to `Scoria.Application.start/2`?**
   - What we know: nothing in `lib/scoria/application.ex` starts any Observe component today (Pitfall 5); only tests wire it manually; no guide documents host-side wiring either.
   - What's unclear: whether this gap is itself in-scope for Phase 51 (a 4th correctness bug alongside the FK bug) or a pre-existing, intentionally host-owned integration contract that's simply undocumented.
   - Recommendation: treat it as out of scope for Phase 51 (none of FOUND-01/02/03/SPAN-01/02/COMPAT-01 name supervision-tree wiring) and use the existing test convention (`start_supervised!`/`.attach()` in `setup`) for verification — but flag this explicitly to the user/planner as a confirmed scoping choice, since ROADMAP's literal wording ("real adapter path... persists... verifiable against a real Postgres") could be read either way.
   - RESOLVED: Supervision-tree wiring is NOT added in Phase 51. Verification uses the existing `start_supervised!`/`.attach()` + Ecto SQL-sandbox test convention in each test's `setup` block (see 51-03 buffer_test, 51-04 req_llm_test, 51-05 jido_test); no change to `Scoria.Application.start/2`.

2. **Does `metadata[:span_kind]` (the host-override key D-13 expects for Jido: `metadata[:span_kind] || "tool"`) have any existing producer today?**
   - What we know: `Scoria.Observe.Adapters.Jido.handle_event/4` reads from a plain telemetry `metadata` map (`[:jido, :action, :stop]`), which is under the host's/Jido's control, not `req_llm`'s.
   - What's unclear: whether any current Jido action call site in this codebase or in adopter code already passes a `:span_kind` telemetry metadata key, or whether this is a net-new host-facing contract this phase introduces (documentation-worthy for Phase 54, but the mechanism itself ships in Phase 51 per D-13).
   - Recommendation: grep the Jido action call sites in this codebase for any existing `:span_kind` telemetry metadata usage before assuming it's 100% new; if genuinely new, note it as a host-facing contract addition in the Phase 51 plan's own changelog note (separate from COMPAT-01's legacy-key CHANGELOG entry).
   - RESOLVED: Plans proceed with the host-declared override `metadata[:span_kind] || "tool"` (51-05, D-13) unconditionally — no grep-gate precondition. `SpanKind.normalize/2` fails closed for any unlisted/absent value, so a pre-existing or net-new host `:span_kind` producer is handled identically; no action-name inference.

3. **What telemetry event name should `SpanKind.normalize/2`'s fallback path emit?**
   - What we know: D-14 mandates "logs + emits telemetry" on fallback but does not name the event (unlike D-06, which names `[:scoria, :observe, :buffer, :flush_error]` explicitly for the flush-error case).
   - What's unclear: the exact atom-list event name and its measurement/metadata contract.
   - Recommendation: `[:scoria, :observe, :span_kind, :fallback]` with metadata `%{value: value, default: default}` is a reasonable default proposed in this research (Architecture Patterns §Pattern 2) — the planner should treat this as a naming decision to finalize, not re-litigate the underlying "must be observable" requirement.
   - RESOLVED: Adopted `[:scoria, :observe, :span_kind, :fallback]` with metadata `%{value: value, default: default}` in 51-01; the name is pinned in the `SpanKind` moduledoc and asserted by the drift-guard suite's fallback-observability test.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | `ai_traces`/`ai_spans` persistence, FK enforcement, GIN indexes | Assumed ✓ (existing project dependency, unchanged by this phase) | Whatever the project's existing dev/CI Postgres is | — (already a hard project dependency; Phase 51 does not add a new one) |
| `req_llm` (Hex, locked) | `Semconv.merge_req_llm_attributes/2` | ✓ | `1.13.0` (`mix.lock`-confirmed) | — |
| `Ecto.Multi` | Trace-upsert transaction | ✓ (ships with `ecto`, already a dependency, already used elsewhere in this codebase) | — | — |

**Missing dependencies with no fallback:** none — this phase introduces no new external dependency.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (standard for this Elixir/Phoenix project) |
| Config file | `mix.exs` (test env config), `config/test.exs` |
| Quick run command | `mix test test/scoria/observe/ test/scoria_web/components/workflow_tree_component_test.exs test/scoria_web/components/trace_tree_component_test.exs` |
| Full suite command | `mix test` (or `mix test --warnings-as-errors` per this project's CI convention, confirmed via `mix.exs` aliases referencing `scoria.ci`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOUND-01 | Real Postgrex FK/constraint failure surfaces via `Logger.error` + `[:scoria, :observe, :buffer, :flush_error]` telemetry, buffer process survives | integration (async: false, real Sandbox) | `mix test test/scoria/observe/buffer_test.exs` | ✅ exists, needs new test cases added (D-08) |
| FOUND-01 | Trace row auto-created before span insert, no manual pre-insert | integration | `mix test test/scoria/observe/buffer_test.exs` | ✅ exists — needs a new test that omits the existing manual `Repo.insert(%Trace{...})` pre-insert |
| FOUND-01 | `:on_flush_error` config knob threads through `start_link` opts; `:raise` mode raises only from the timer path, never from `terminate/2` | unit | `mix test test/scoria/observe/buffer_test.exs` | ❌ new test cases needed |
| FOUND-02 | Drift-guard: canary kind list, exhaustiveness, CSS coherence, anti-inline guard | unit (source-scan style, mirrors existing `ds06_drift_guard_test.exs`/`single_header_guard_test.exs` conventions) | `mix test test/scoria/observe/span_kind_test.exs` | ❌ new file needed |
| FOUND-03 | Every `gen_ai.*`/`openinference.*` key traces to `Semconv` | unit + source-scan | `mix test test/scoria/observe/semconv_test.exs` | ❌ new file needed |
| SPAN-01 | All four model-config params (`temperature`/`top_p`/`max_tokens`/`seed`) + `gen_ai.usage.*` present together on a real LLM span | integration | `mix test test/scoria/observe/adapters/req_llm_test.exs` | ✅ exists — needs realistic `%LLMDB.Model{}`-shaped fixture + `request_options` map (see Pitfall 1) |
| SPAN-02 | `span_kind` correct + `openinference.span.kind` mirrored, `mcp`→`"TOOL"` | unit + integration | `mix test test/scoria/observe/adapters/req_llm_test.exs test/scoria/observe/adapters/jido_test.exs` | ✅ exist — need updated assertions (current fixtures assert old `"LLM"`/`"INTERNAL"` literals) |
| COMPAT-01 | Legacy keys absent from new spans; CHANGELOG entry present | unit (attribute assertion) + docs check | `mix test test/scoria/observe/adapters/req_llm_test.exs` | ✅ exists — needs updated assertions (`refute Map.has_key?(span.attributes, "llm.model_name")` etc.) |

### Sampling Rate

- **Per task commit:** `mix test test/scoria/observe/ test/scoria_web/components/{workflow_tree,trace_tree}_component_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/scoria/observe/span_kind_test.exs` — covers FOUND-02 drift-guard (D-15)
- [ ] `test/scoria/observe/semconv_test.exs` — covers FOUND-03
- [ ] Update `test/scoria/observe/adapters/req_llm_test.exs` fixture to a realistic `%LLMDB.Model{}`-shaped `metadata[:model]` + populated `metadata[:request_options]`/`metadata[:usage]` (currently unrealistic `model: "gpt-4"` string, no request_options/usage keys at all)
- [ ] Update `test/scoria_web/components/trace_tree_component_test.exs` (asserts `span_kind: "LLM"` literal today) and any `workflow_tree_component_test.exs` equivalents for the new lowercase-native + `SpanKind`-delegated behavior
- [ ] No new test framework install needed — ExUnit + existing `Ecto.Adapters.SQL.Sandbox` conventions cover this phase

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | Out of scope — no auth surface touched this phase |
| V3 Session Management | No | Out of scope |
| V4 Access Control | No | Out of scope — no tenant/authz logic changes |
| V5 Input Validation | Yes (narrow) | `SpanKind.normalize/2` is itself the input-validation boundary for host/adapter-supplied `span_kind` values — already designed to fail closed to a safe default (`"agent"`) rather than reject/crash |
| V6 Cryptography | No | Not applicable |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| PII/secret leakage via new `gen_ai.*`/`openinference.*` attribute keys | Information Disclosure | Already covered — `Scoria.Observe.Redactor.redact/1` is exact-key-match against a deny-list (`password`, `api_key`, `token`, `secret`); confirmed none of the new dotted keys (`gen_ai.usage.output_tokens`, etc.) can collide with the deny-list since matching is on the whole key, not substring. No redactor changes needed this phase (all new keys are scalar/categorical, not free text) — `[VERIFIED: lib/scoria/observe/redactor.ex direct read]` |
| Telemetry-handler re-entrancy from a bad host `:on_flush_error`/fallback telemetry consumer | Denial of Service | D-09(iv) explicitly requires wrapping the new telemetry emits defensively so a misbehaving host handler attached to `[:scoria, :observe, :buffer, :flush_error]` can't re-enter/loop the flush path — apply the same defensive-wrap discipline to `SpanKind.normalize/2`'s fallback telemetry emit |
| Buffer GenServer crash-loop from an uncaught `Ecto.Multi`/Postgrex exception (Pitfall 3) | Denial of Service | `try/rescue` around `Repo.transaction(multi)` in addition to `{:error, ...}` pattern matching — see Architecture Patterns Pattern 1 |

## Sources

### Primary (HIGH confidence)

- Direct source read, this session: `lib/scoria/observe/buffer.ex`, `lib/scoria/observe/telemetry.ex`, `lib/scoria/observe/circuit_breaker.ex`, `lib/scoria/observe/circuit_breaker/manager.ex`, `lib/scoria/observe/redactor.ex`, `lib/scoria/observe/trace_projection.ex`, `lib/scoria/observe/adapters/req_llm.ex`, `lib/scoria/observe/adapters/jido.ex`, `lib/scoria/repo/{span,trace,span_event}.ex`, `lib/scoria_web/components/{workflow_tree,trace_tree}_component.ex`, `assets/css/04-components.css:1066-1092`, `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs`, `lib/scoria/application.ex`, `lib/scoria/eval/online_scoring.ex:453`, `mix.exs`, `mix.lock`
- Direct source read, this session: `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` (full file), `deps/req_llm/lib/req_llm/telemetry.ex` (lines 130-210, 470-520), `deps/req_llm/lib/req_llm/open_telemetry.ex` (schema URL pin), `deps/llm_db/lib/llm_db/model.ex` (lines 190-220, `@derive Jason.Encoder`)
- Test files read directly: `test/scoria/observe/buffer_test.exs`, `test/scoria/observe/adapters/req_llm_test.exs`, `test/scoria_web/components/trace_tree_component_test.exs`
- `.planning/phases/51-foundation-fix-key-convention-span-kind-taxonomy/51-CONTEXT.md` — locked decisions D-01 through D-16

### Secondary (MEDIUM confidence)

- `.planning/research/SUMMARY.md`, `.planning/research/PITFALLS.md`, `.planning/research/ARCHITECTURE.md`, `.planning/research/STACK.md`, `.planning/research/FEATURES.md` — milestone-level research pass, 2026-07-11, HIGH confidence in its own right (live-fetched official OTel-GenAI/OpenInference specs) but not re-fetched this session; treated here as CITED, not re-verified
- `.planning/seeds/SEED-007-trace-foundation-otel-openinference.md` — origin seed

### Tertiary (LOW confidence)

- None used directly this session beyond what the milestone research already flagged as MEDIUM/LOW

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — direct source read of the exact locked `req_llm 1.13.0` dependency, not documentation
- Architecture (transaction shape, SpanKind/Semconv module design): HIGH — grounded in existing codebase idioms (`Ecto.Multi` precedent) and direct code inspection of every component in the write/read path
- Pitfalls: HIGH for the two newly-confirmed findings this session (struct-in-jsonb bug, unwired supervision tree, missing trace-context producer) — all three are grounded in direct grep/read, not inference
- OpenInference version-pin scheme: MEDIUM — no formal upstream version number exists to cite; pin-by-date is the best available discipline

**Research date:** 2026-07-12
**Valid until:** 30 days (stable — no new external dependency; the only volatility source is a future `req_llm` minor bump, which the planner can pre-check with `mix hex.outdated req_llm`)
