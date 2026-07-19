# Phase 51: Foundation Fix + Key Convention + Span-Kind Taxonomy - Context

**Gathered:** 2026-07-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Make every span Scoria emits **actually persist** to Postgres, **carry the current OTel-GenAI model-config attributes** (`gen_ai.*`), and report a **correct, canonically-sourced `span_kind`** — closing the pre-existing silent FK gap that has been swallowing every span insert since `0.1.0`.

In scope: FOUND-01 (trace-upsert FK fix + de-silence the `Buffer` rescue), FOUND-02 (one shared `span_kind` whitelist module), FOUND-03 (version-pinned `Semconv` key-mapping module), SPAN-01 (`gen_ai.*` model config via `ReqLLM.OpenTelemetry.Attributes`), SPAN-02 (correct `span_kind` + mirrored `openinference.span.kind`), COMPAT-01 (documented legacy-key decision).

**This phase clarifies HOW to implement the above.** New capabilities (RETRIEVER span, host-declared attrs, structured child spans/events, docs-conformance) belong to Phases 52–54 and are out of scope here.

Requirements are locked by `.planning/REQUIREMENTS.md` (FOUND-01/02/03, SPAN-01/02, COMPAT-01) — the decisions below are the **implementation choices** left open by the requirements + research, resolved via a parallel-research + red-team synthesis pass (per user's preferred discuss method). The three decisions cohere under one meta-principle the phase already embodies: **replace silent/implicit behavior with explicit, observable, test-guarded behavior.**

</domain>

<decisions>
## Implementation Decisions

### COMPAT-01 — Legacy-key posture: CLEAN REPLACEMENT, loudly documented
- **D-01:** **Drop** the legacy keys `llm.model_name`, `llm.token_count`, `req.url` entirely and replace with OTel-GenAI convention keys sourced from `ReqLLM.OpenTelemetry.Attributes`. **No dual-emit, no runtime shim, no config flag.**
- **D-02:** Justification is factual, not stylistic: the pre-existing FK bug (`ai_spans.trace_id null:false` → `ai_traces`, which no prod path ever inserts) means **every span insert has been failing and getting dropped** by the `rescue` in `Buffer.flush_spans/1`. So **no adopter Postgres has ever persisted these keys** — there is provably zero legacy data to protect. Dual-emit would shim data that never existed (cruft + a mild self-contradiction of Scoria's "no overclaiming" brand).
- **D-03:** Ship a **CHANGELOG breaking-change entry** (in the `0.1.4` cut) with the literal old→new mapping table, plus **one upgrade-guide sentence** for any adopter who attached a custom `:telemetry` handler and read the old keys in-memory. That prose is the *entire* defensive cost paid.
- **D-04:** Treat the **FK fix + key rename as one atomic change** — the FK fix is precisely what licenses the clean break; do not rename keys in a release where spans still don't persist, and do not fix the FK while keeping legacy keys. Idiomatic for pre-1.0 (`0.x`) Elixir/Hex (Oban/Ecto/Phoenix break freely + document precisely; deprecation *windows* are for callable APIs where `@deprecated`/`Logger.warning` can fire, not silent jsonb data keys). OTel's own `gen_ai.system`→`gen_ai.provider.name` rename confirms the dual-emit transition is the *regretted* part; Scoria can skip straight to the clean end-state.

### FOUND-01 — Persistence-failure posture: NON-FATAL BUT LOUD (observable + test-provable)
- **D-05:** Replace the silent `rescue` in `Buffer.flush_spans/1` with **structured, non-fatal surfacing**: `Logger.error` (structured — include `dropped_count`, `buffer` name, not just `inspect(e)`) **AND** emit a telemetry event, then drop the failed batch and continue. **Scoria must never crash/destabilize the host app** ("surface" ≠ "raise"; the sin was *silent*, not *non-fatal*).
- **D-06:** Telemetry event contract:
  - event: `[:scoria, :observe, :buffer, :flush_error]`
  - measurements: `%{dropped_count: n, system_time: ...}`
  - metadata: `%{error: e, kind: :error, stacktrace: ..., buffer: name, max_size: ...}`
  - Emit through a thin wrapper in `Scoria.Observe.Telemetry` (mirror the existing `:delta`-event wrapper convention: tests use the wrapper, not raw `:telemetry.execute`). This is the **machine/alerting seam** (Parapet-ready per szTheory DNA); the log is the **human seam**.
- **D-07:** Add a narrow config knob `:on_flush_error` = `:log` (default, incl. prod) | `:raise`, threaded through `start_link` opts into state (like `max_size`/`flush_interval`) so a test can `start_supervised({Buffer, on_flush_error: :raise, ...})` without touching global app env. Set `:raise` in `config/test.exs` (or per-test). **Exactly these two atoms this phase** — no `fun` variant (the telemetry event already gives hosts an arbitrary-callback seam; honors zero-config DNA). This is the **CI fail-fast seam**.
- **D-08:** **Test approach satisfying success-criterion #1 (verifiable against real Postgres) — ship both:** (a) *primary* — `:telemetry_test.attach_event_handlers` on `[:scoria, :observe, :buffer, :flush_error]`, induce a **real** Postgrex/constraint failure, `assert_receive` the event with `dropped_count > 0`; (b) *secondary* — `:raise` mode + `assert`/`catch_exit`. Add a **synchronous-flush test hook** (`handle_call(:flush_now, …)`) so tests don't race the 5s timer.
- **D-09:** Footgun gates: (i) **`terminate/2` must never reraise** even in `:raise` mode (a raise during shutdown is noisy/pointless; only honor `:raise` from the `handle_info(:flush, …)` path — critical given `:trap_exit`); (ii) **error-storm control** — reuse the existing `lib/scoria/observe/circuit_breaker.ex` (or minimally: log full detail once per consecutive-failure run, but **always emit the telemetry event** so alerting math stays accurate); (iii) `dropped_count` must count the attempted `entries`, not `state.spans` post-reset; (iv) wrap the emit defensively so a host's bad telemetry handler can't re-enter the flush path.
- **Peer precedent:** this is `otel_batch_processor` almost verbatim (drop + log + telemetry + never crash the app) — an observability lib should fail the way the ecosystem's canonical tracing pipeline fails. **Rejected** "let it crash" (Option C): it drops the *entire* in-memory buffer on restart (loses strictly *more* data, and silently — a restart isn't a data-loss signal). **Deferred** retry/dead-letter (Option D): out of scope this phase.

### FOUND-02 / SPAN-02 — Span-kind taxonomy shape
- **D-10:** **Canonical casing = lowercase Scoria-native stored in `ai_spans.span_kind`**; derive UPPERCASE `openinference.span.kind` at one seam (`SpanKind.to_openinference/1`). Existing CSS rails (`scoria-span--llm`) and both UI whitelists are already lowercase; uppercase-everywhere would churn 8 CSS classes + both components + every fixture for zero portability gain. Portability stays honest because the *exported* attribute uses the official UPPERCASE enum. This also fixes the **live casing bug** (adapters emit `"LLM"`/`"INTERNAL"`, whitelists match lowercase → every span currently renders as the default `agent`).
- **D-11:** **The 8 canonical kinds** (native → `openinference.span.kind`): `agent`→`AGENT`, `llm`→`LLM`, `prompt`→`PROMPT`, `tool`→`TOOL`, **`mcp`→`TOOL`** (the one non-1:1; MCP is a transport, not an OI kind), `retriever`→`RETRIEVER`, `guardrail`→`GUARDRAIL`, **`eval`→`EVALUATOR`** (rename). `EMBEDDING`/`RERANKER` stay as attrs on the RETRIEVER span (KIND-EMB-01/RRK-01 deferred); `CHAIN` deliberately absent (`ai_traces`/workflow-run fills it). 8 native → 7 distinct OI values (mcp+tool collapse).
- **D-12:** **`error` is a STATUS, not a kind — REMOVE it from the whitelist (9→8).** `ai_spans.status_code` already exists and is already used as the error signal (`trace_projection.ex` defaults `"OK"`; `online_scoring.ex` treats `status_code |> upcase == "ERROR"`). Render an errored span as **its real kind's rail + a status overlay** (an errored LLM reads "LLM + errored", never collapsing to a generic red row). Repurpose CSS `.scoria-span--error` → `.scoria-span--status-error` (left-border + alert icon + visually-hidden/aria "errored" — **not color-only**, WCAG dark/light/system). `redacted` stays a third orthogonal overlay axis. No data migration needed (no adapter ever emitted `"error"` as a kind — consistent with COMPAT-01 clean-replacement).
- **D-13:** **Jido default `"tool"`** (replaces the `"INTERNAL"` category error — `INTERNAL` is an OTel `SpanKind`, a different axis). A generic Jido action = discrete function execution = `TOOL` semantics; reserve `agent` for the orchestrating span. Rule: `span_kind = SpanKind.normalize(metadata[:span_kind] || "tool")` — **host-declared override only, no action-name inference** (auto-classification would violate the "host declares, Scoria never infers" doctrine).
- **D-14:** **Shared module `Scoria.Observe.SpanKind`** — a plain compile-time-constant module, **NOT `Ecto.Enum`** (Ecto.Enum would reject drifted/legacy rows on load and bind casing into the schema). API surface:
  - `kinds/0` → the 8-string list (canonical order == UI order)
  - `kind?/1` → boolean membership
  - `normalize/2` (`normalize(value, default \\ "agent")`) → `to_string |> downcase |> validate`; on fallback it **coerces to `agent` for display BUT logs + emits telemetry** (observable, not silent — coheres with FOUND-01; the current silent `_ -> "agent"` default is exactly the swallow FOUND-01 opposes)
  - `to_openinference/1` → native → UPPERCASE OI enum (one clause per kind)
  - Consumers: both UI components (replace inline `~w(...)`), both adapters (set native literal + mirror via `Semconv.openinference_span_kind()` key — **never hardcode the key string or casing**), the conformance test.
- **D-15:** **Drift-guard test (FOUND-02 mandatory):** (1) canary — `assert SpanKind.kinds() == ~w(agent llm prompt tool mcp retriever guardrail eval)` (forces review of CSS + OI mapping on any change); (2) exhaustiveness — every kind has a non-raising `to_openinference/1` clause and passes `kind?/1`; (3) CSS coherence — assert `scoria-span--#{k}` rail exists for every kind (`assets/css/04-components.css`); (4) anti-inline guard — grep both component sources, assert no `~w(...)` span-kind literal remains (single source of truth enforced structurally).

### FOUND-03 — sequencing note (not a gray area, but load-bearing here)
- **D-16:** The version-pinned `Scoria.Observe.Semconv` module (single source for every `gen_ai.*` / `openinference.*` key string, with a version-pin comment) must exist **before/with** the adapter edits, because SPAN-02's mirrored `openinference.span.kind` key and SPAN-01's `gen_ai.*` keys must come from `Semconv`, not literals. Pin the OpenInference enum version in a moduledoc so a future upstream rename (e.g. SEM-01) is a one-module diff.

### Claude's Discretion (delegated to researcher/planner — genuinely open, not user-gated)
- **Trace-upsert transaction shape** for FOUND-01: single `Ecto.Multi` (trace-insert-if-missing → span-insert) vs independent upsert-then-insert — a pure implementation/correctness choice. Research flagged it for planning; no user preference. Constraint: the ordered flush discipline (traces → spans → [events, Phase 53]) must be respected.
- **Exact `gen_ai.*` key set** produced by `ReqLLM.OpenTelemetry.Attributes.start/1`+`.terminal/1` (the builder determines the precise keys for the `req.url`→`gen_ai.response.*`/server-address mapping row in the CHANGELOG).
- **Whether to add a GIN index** on `ai_spans.attributes` now vs later (research recommends it as the queryability answer that keeps convention-over-columns honest — planner's call on timing).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements & research (authoritative)
- `.planning/REQUIREMENTS.md` — v3.6 locked requirements; Phase 51 owns FOUND-01/02/03, SPAN-01/02, COMPAT-01. Scope doctrine (convention-not-columns, host-declares, keep `ai_retrieval_runs` system-of-record, zero required egress) is held here.
- `.planning/ROADMAP.md` §"Phase 51" — goal + 5 success criteria (the acceptance bar).
- `.planning/research/SUMMARY.md` — HIGH-confidence research base; §Phase 1 build order, §"Gaps to Address", §"Critical Pitfalls" 1–5 all map to Phase 51.
- `.planning/research/PITFALLS.md`, `.planning/research/ARCHITECTURE.md`, `.planning/research/STACK.md`, `.planning/research/FEATURES.md` — deeper detail behind SUMMARY.
- `.planning/seeds/SEED-007-trace-foundation-otel-openinference.md` — origin seed; §"What to build" items 1–2, breadcrumbs.

### Convention sources (reference, NOT dependencies)
- `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` — the `start/1`/`.terminal/1` `gen_ai.*` attribute builder (locked `req_llm 1.13.0`). Source of SPAN-01's keys.
- OTel-GenAI semconv (schema 1.37.0) + OpenInference span-kind enum — plain-string conventions only; `opentelemetry_semantic_conventions` Hex package is a **reference for key-name truth**, not a runtime dep (do NOT add `opentelemetry`/`opentelemetry_api`).

### Project DNA
- `prompts/sztheory-elixir-dna.md` — operator-first DX, Ecto-native durable state (avoid opaque in-memory state), idiomatic OTP, "prepare telemetry hooks for Parapet" (the FOUND-01 telemetry-event decision), batteries-included-but-composable.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/scoria/observe/circuit_breaker.ex` (+ `.../manager.ex`) — existing storm-control primitive; reuse for FOUND-01 error-storm rate-limiting (D-09).
- `Scoria.Observe.Telemetry` (`lib/scoria/observe/telemetry.ex`) — existing span-path wrapper + `Redactor.redact/1` call site; add the `emit_flush_error/1` wrapper here beside the existing `:delta`/`:stop` emitters.
- `ai_spans.status_code` (`lib/scoria/repo/span.ex:10`) — the status axis already exists and is already consumed (`trace_projection.ex:39`, `eval/online_scoring.ex`); D-12 error-as-status builds on it, no schema change.
- CSS span rails (`assets/css/04-components.css:1082-1091`) — already ships 8 kind rails + `error` + `redacted`; D-12 repurposes `--error` → `--status-error`.

### Established Patterns
- Buffer opts-driven `init` (`max_size`, `flush_interval` via `start_link` opts) — extend with `:on_flush_error` (D-07) the same way.
- Adapter → `:telemetry.execute([:scoria,:observe,:span,:stop])` → `Telemetry.handle_event` (redact/route) → `Buffer.cast_span` → periodic `Repo.insert_all`. `Telemetry`/`Buffer` are pass-through; **all convention-key + `span_kind` work lives at the adapter layer** (`req_llm.ex`, `jido.ex`), not the pipeline.
- Test convention: emit via the `Telemetry` wrapper, not raw `:telemetry.execute` (mirror for the new flush-error event).

### Integration Points
- `lib/scoria/observe/adapters/req_llm.ex` — merge `ReqLLM.OpenTelemetry.Attributes` output into `attributes` (SPAN-01); set native lowercase `span_kind` + mirrored `openinference.span.kind` via `Semconv` (SPAN-02); drop legacy keys (COMPAT-01).
- `lib/scoria/observe/adapters/jido.ex` — replace `"INTERNAL"` with `SpanKind.normalize(metadata[:span_kind] || "tool")` (D-13).
- `lib/scoria/observe/buffer.ex` — FOUND-01 flush-error surfacing + `:on_flush_error` opt + `:flush_now` test hook + terminate gate.
- `lib/scoria_web/components/{workflow_tree,trace_tree}_component.ex` — replace inline whitelists with `SpanKind.normalize/2`; note asymmetry (trace_tree already downcases + matches `span_kind`; workflow_tree matches workflow-step `kind` `approval/handoff/answer` — a *different* data source, keep its step-vocab mapping but route through the shared module).
- **New:** `lib/scoria/observe/span_kind.ex` (D-14) and `lib/scoria/observe/semconv.ex` (D-16).
- FK fix: a trace-row upsert must run before span insert (transaction shape = Claude's discretion).

</code_context>

<specifics>
## Specific Ideas

- Method used: three parallel research subagents (COMPAT-01, FOUND-01, FOUND-02/SPAN-02) + a red-team synthesis pass. Red-team caught one real conflict: the COMPAT-01 agent's note to move `span_kind` to the OTel `SpanKind` vocabulary (`CLIENT`) was **rejected** — that conflates OTel `SpanKind` (CLIENT/SERVER/INTERNAL) with OpenInference `span.kind` (LLM/TOOL/…); Scoria's `span_kind` column is the OpenInference semantic kind, per locked requirements. Refinement: dropped the Jido action-name classifier in favor of host-declared override + flat `tool` default (doctrine-cleaner).
- All three decisions share the meta-principle **"replace silent/implicit with explicit/observable/test-guarded"**: clean-replace (no silent shim) ↔ loud flush errors (no silent drop) ↔ drift-guard + normalize-logs-fallback (no silent divergence). CHANGELOG for `0.1.4` should pair the COMPAT-01 key note with the FOUND-01 `[:scoria, :observe, :buffer, :flush_error]` + `:on_flush_error` announcement so operators learn both "your queries may change" and "here's how persistence failures now surface."

</specifics>

<deferred>
## Deferred Ideas

- **`EMBEDDING` / `RERANKER` first-class span kinds** — stay as fields on the `RETRIEVER` span (KIND-EMB-01/RRK-01, v3.7+ per REQUIREMENTS.md).
- **`CHAIN` span kind** — deliberate non-gap; `ai_traces`/workflow-run model fills it. Do not add.
- **`gen_ai.system` → `gen_ai.provider.name` adoption** (SEM-01) — once that OTel field leaves Development stability; FOUND-03's `Semconv` makes it a one-module diff.
- **Retry-with-backoff / dead-letter for flush failures** (FOUND-01 Option D) — out of scope this phase; the loud-drop posture is sufficient for v3.6.
- **Full GIN-index + query-helper module** for `attributes` queryability — planner decides timing; the convention-over-columns answer to "it'd be easier to query."
- **RETRIEVER span, host-declared `feature`/`route`/`archetype`/`intent`, structured child spans + `ai_span_events`, docs "OpenInference-compatible" claim + conformance check** — Phases 52–54, not here.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 51-foundation-fix-key-convention-span-kind-taxonomy*
*Context gathered: 2026-07-11*
