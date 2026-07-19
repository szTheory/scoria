# Phase 51: Foundation Fix + Key Convention + Span-Kind Taxonomy - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-11
**Phase:** 51-foundation-fix-key-convention-span-kind-taxonomy
**Areas discussed:** Legacy-key posture (COMPAT-01), Failure-surfacing posture (FOUND-01), span_kind taxonomy shape (FOUND-02/SPAN-02)
**Method:** User requested parallel-research subagents + red-team synthesis (per preferred discuss method) rather than interactive Q&A — "one-shot a perfect, coherent set of recommendations." Three research agents (general-purpose, web + code access) ran concurrently, one per area; findings red-teamed and synthesized by the orchestrator.

---

## Legacy-key posture (COMPAT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Clean replacement (loudly documented) | Drop `llm.model_name`/`llm.token_count`/`req.url`; adopt `gen_ai.*` only; CHANGELOG mapping table + upgrade-guide sentence | ✓ |
| Dual-emit for a deprecation window | Emit both old + new keys for one release cycle | |
| Clean-replace, silent | Drop old keys with no CHANGELOG callout | |

**Selected:** Clean replacement, loudly documented (research confidence HIGH ~0.9).
**Notes:** Decisive fact — the pre-existing FK bug means no adopter Postgres ever persisted any span, so the "legacy data to protect" premise is provably empty; dual-emit would shim nonexistent data. Idiomatic for pre-1.0 `0.x` Elixir/Hex (Oban/Ecto/Phoenix break freely + document precisely; deprecation windows are for callable APIs, not silent jsonb keys). OTel's own `gen_ai.system`→`gen_ai.provider.name` rename shows the dual-emit transition is the regretted part. Frame FK fix + rename as one atomic `0.1.4` change.

---

## Failure-surfacing posture (FOUND-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Non-fatal but loud | Log :error + emit `[:scoria,:observe,:buffer,:flush_error]` telemetry + dropped-count, drop batch, continue; + narrow `:on_flush_error` (`:log`\|`:raise`) test knob | ✓ |
| B — Configurable strict/raise mode as primary | Raise by default in a mode | (folded into A as the `:raise` knob) |
| C — Let it crash | Remove rescue, rely on supervisor restart | |
| D — Retry + dead-letter | Backoff, persist failed batch, then drop | (deferred) |

**Selected:** Option A, hardened into a hybrid (research confidence HIGH ~0.85).
**Notes:** "Surface" ≠ "raise" — the sin was *silent*, not *non-fatal*. An embedded observability lib must never crash the host yet never silently lose data and must let a test prove failures surface; a loud telemetry+log drop satisfies all three. Matches `otel_batch_processor` almost verbatim (the ecosystem's canonical tracing pipeline). C rejected — it drops the entire in-memory buffer on restart (loses strictly more, silently). D deferred. Telemetry event is Parapet-ready per szTheory DNA. Footgun gates: terminate never reraises, reuse existing circuit_breaker for storm control, sync-flush test hook, accurate dropped_count.

---

## span_kind taxonomy shape (FOUND-02 / SPAN-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Lowercase-native storage + derived uppercase OI attr | Store `"llm"`; derive `"LLM"` for `openinference.span.kind` at one seam | ✓ |
| Uppercase-everywhere | Store `"LLM"` in the column too | |
| `error` as a span kind (keep in whitelist) | Retain the 9th `error` kind | |
| `error` as a status (remove from whitelist) | 8 kinds; render kind + status overlay off `status_code` | ✓ |
| Jido default `tool` (host-override only) | Replace `"INTERNAL"`; `metadata[:span_kind] \|\| "tool"`, no name-inference | ✓ |
| Jido default `agent` / name-classifier | Auto-classify by action name | |

**Selected:** lowercase-native storage; `error`-as-status (8-value set); Jido→`tool` with host-declared override only; shared `Scoria.Observe.SpanKind` plain module (not `Ecto.Enum`) + drift-guard test (research confidence HIGH).
**Notes:** Existing CSS rails + UI whitelists are lowercase — uppercase-everywhere is pure churn for zero portability gain; portability lives in the *exported* uppercase `openinference.span.kind`. `ai_spans.status_code` already exists/consumed, so error-as-status is a natural split (errored LLM reads "LLM + errored", not a generic red row). `"INTERNAL"` was an OTel-`SpanKind` category error. Name-classifier dropped to honor the "host declares, Scoria never infers" doctrine. 8 kinds → OI: agent/llm/prompt/tool/(mcp→TOOL)/retriever/guardrail/(eval→EVALUATOR).

---

## Claude's Discretion

- Trace-upsert transaction shape (single `Ecto.Multi` vs independent upsert-then-insert) — pure correctness choice, researcher/planner decides; ordered flush (traces→spans→events) must hold.
- Exact `gen_ai.*` key set emitted by `ReqLLM.OpenTelemetry.Attributes` (determines the `req.url`→`gen_ai.response.*`/server-address CHANGELOG row).
- Whether to add the GIN index on `ai_spans.attributes` now vs a later phase.

## Deferred Ideas

- `EMBEDDING`/`RERANKER` first-class kinds (v3.7+); `CHAIN` deliberate non-gap.
- `gen_ai.system`→`gen_ai.provider.name` (SEM-01) once off Development stability.
- Retry/dead-letter for flush failures (FOUND-01 Option D).
- Full GIN-index + query-helper module for jsonb queryability.
- RETRIEVER span / host-declared attrs / structured child spans+events / docs claim+conformance — Phases 52–54.

## Red-team adjustments (recorded)

- **Rejected:** COMPAT-01 agent's suggestion to move `span_kind` to OTel `SpanKind` (`CLIENT`) — conflates OTel `SpanKind` with OpenInference `span.kind`; Scoria's column is the OpenInference semantic kind (locked by requirements).
- **Refined:** dropped Jido action-name classifier → host-declared override + flat `tool` default (doctrine-consistent).
