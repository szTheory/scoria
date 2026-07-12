# Requirements: Scoria — v3.6 Trace Foundation

**Defined:** 2026-07-11
**Milestone:** v3.6 Trace Foundation (SEED-007 · 999.3)
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Milestone goal:** Finish the trace schema Scoria already half-designed — make spans structured and portable (OTel-GenAI / OpenInference **naming convention over the existing `attributes` jsonb map**, not typed columns, not a schema rewrite) so eval, regression detection, and every downstream seed can attribute a quality delta to a prompt version, retrieval config, or model change instead of reading a flat blob.

> **Research basis:** `.planning/research/SUMMARY.md` (+ STACK/FEATURES/ARCHITECTURE/PITFALLS), 2026-07-11. Key corrections it verified against live code: (1) **no new runtime dependency** — `req_llm 1.13.0` already ships `ReqLLM.OpenTelemetry.Attributes.start/1`+`.terminal/1`; (2) `ai_span_events` is **not** a dead schema (exists since 0.1.0 → app-layer wiring, zero migration); (3) a **pre-existing FK bug** (`ai_traces` never inserted; `Buffer.flush_spans/1` swallows the `null:false` FK error) means nothing v3.6 emits persists until fixed — it gates the milestone.
>
> **Scope doctrine (held):** P5 reconstructable in the host's own Postgres, zero required egress (OTel *export* is host-owned, opt-in — never a Scoria runtime dep); P6 BEAM-native; convention-not-columns; keep `ai_retrieval_runs` as system-of-record (dual-write, never collapse); **host declares attributes, Scoria never infers**.

## v1 Requirements

Committed scope for v3.6. Each maps to exactly one phase (see Traceability).

### Foundation & Convention

- [x] **FOUND-01**: Operator's spans actually persist — trace rows are upserted before span insert (closing the `ai_spans.trace_id` `null:false` FK gap), and the silent `rescue` in `Buffer.flush_spans/1` no longer hides persistence failures (failures surface, not swallowed).
- [x] **FOUND-02**: One shared `span_kind` whitelist module is the single canonical source consumed by both UI tree components (`WorkflowTreeComponent`, `TraceTreeComponent`), replacing the two drifted hardcoded lists, with a drift-guard test preventing re-divergence.
- [x] **FOUND-03**: A version-pinned internal semconv mapping module (e.g. `Scoria.Observe.Semconv`) is the single source for every `gen_ai.*` / `openinference.*` key string, so an upstream rename is a one-module diff, not a grep-and-replace.

### Span Convention & Model Config

- [ ] **SPAN-01**: Every LLM span carries the current OTel-GenAI attribute keys (`gen_ai.request.model/temperature/top_p/max_tokens/seed`, `gen_ai.usage.*`, `gen_ai.response.*`) sourced via `ReqLLM.OpenTelemetry.Attributes` — all four model-config params captured together (no partial capture that fakes replay fidelity).
- [x] **SPAN-02**: Every span carries a correct `span_kind` from the canonical 8-value taxonomy (replacing the hardcoded `"LLM"`/`"INTERNAL"` literals in both adapters) plus a mirrored `openinference.span.kind`, with the `mcp`→`"TOOL"` translation for the one non-1:1 kind.

### Retrieval & Host-Declared Attributes

- [ ] **RETR-01**: A `RETRIEVER` span is emitted at the single `Knowledge.retrieve/2` call site, dual-written alongside `ai_retrieval_runs` (kept as system-of-record — not collapsed), reusing the trace_id/span_id/latency it already computes.
- [ ] **RETR-02**: Retrieval config (`embedding_model`, `index_version`, `reranker`) is captured as convention keys (no migration), mirrored into both the `RETRIEVER` span and `ai_retrieval_runs.metadata`, with a span↔table consistency guard against dual-write divergence.
- [ ] **ATTR-01**: Reserved host-declared keys `feature` / `route` / `archetype` / `intent` are threaded through the existing metadata precedent (`tenant_id`/`workflow_run_id`) and documented — Scoria **reserves and passes through, never infers**.
- [ ] **ATTR-02**: Context-pack / token-budget composition is captured on the `PROMPT` span — which chunk IDs + which memory IDs + the per-source token split that entered the assembled prompt (**IDs and counts, never raw text**), alongside `gen_ai.usage.input_tokens`.

### Structured Spans & Events

- [ ] **EVENT-01**: `tool` / `prompt` / `retrieval` / `guardrail` are emitted as real child **spans** (duration/failure-bearing) with `parent_id` linkage, not as events.
- [ ] **EVENT-02**: `ai_span_events` is wired at the application layer via a public `emit_event/1` + a `[:scoria, :observe, :event, :emit]` telemetry clause that routes through the **identical `Redactor.redact/1` call site** spans use (no bypass); `Buffer` gains an event list with an ordered flush (traces → spans → events); emission is allow-listed to a reserved point-event vocabulary — `prompt_rendered`, `guardrail_triggered`, `user_feedback_received`.
- [ ] **EVENT-03**: The synchronous point-events `prompt_rendered` and `guardrail_triggered` are emitted from real instrumentation call sites. (`user_feedback_received` is **reserved in the EVENT-02 vocabulary but not emitted in v3.6** — its capture instrumentation + async-arrival FK resolution is SEED-011 feedback-flywheel work; see v2 Requirements.)

### Docs & Conformance

- [ ] **DOCS-01**: The adopter claim flips to an honest, version-pinned "OpenInference-compatible" (from the v3.5-softened "OpenInference-style"), and the `adopter_doc_contract.ex` / `ai_doc_contract.ex` banned-phrase lists (which currently block that exact phrase) are updated in the **same change**.
- [ ] **DOCS-02**: The compatibility claim is backed by a falsifiable conformance check (Mix task or ExUnit) asserting emitted spans use only allow-listed convention key names and `span_kind` values drawn from the shared whitelist — a testable claim, not an adjective.

### Cross-Cutting Safety & Compatibility

- [ ] **SEC-01**: New attribute and event payloads capture **IDs and counts, never raw prompt/completion text**; event payloads route through the existing `Redactor` path; attribute payload size is bounded at write time (PII + cardinality guard on the flat-deny-list redactor).
- [ ] **COMPAT-01**: Legacy attribute keys already persisted in adopter Postgres (`llm.model_name`, `llm.token_count`, `req.url`) are handled by an **explicit, documented decision** (dual-emit for a deprecation window vs. clean replacement) recorded in CHANGELOG, so hosts querying their own tables aren't silently broken.

## v2 Requirements

Acknowledged, deferred to a future milestone. Moving any of these to v1 requires a roadmap update.

### Deferred span kinds (→ v3.7+)

- **KIND-EMB-01**: First-class `EMBEDDING` span kind (stays as fields on the `RETRIEVER` span in v3.6 until an independent-attribution need appears).
- **KIND-RRK-01**: First-class `RERANKER` span kind (same rationale as `EMBEDDING`).

### Feedback capture (→ SEED-011 Privacy & Feedback Governance)

- **FB-01**: `user_feedback_received` **emission** — capture thumbs/accept/edit/regenerate from the operator surface and resolve the async-arrival FK (feedback landing after the span/trace closes). v3.6 reserves the event name in the vocabulary (EVENT-02); the flywheel capture is SEED-011's end-to-end deliverable.

### Upstream key migration (→ v3.7+, when semconv stabilizes)

- **SEM-01**: Adopt the `gen_ai.system` → `gen_ai.provider.name` rename once that OTel field moves off Development stability (the version-pinned mapping module FOUND-03 makes this a one-module change).

## Out of Scope

Explicitly excluded — anti-features and boundary violations flagged by research.

| Feature | Reason |
|---------|--------|
| Typed Ecto columns per `gen_ai.*` attribute | Convention-over-columns is the locked discipline; typed columns invite pre-1.0 migration churn. Only `ai_retrieval_runs` (system-of-record) gets typed fields. Queryability comes from a GIN index + query helpers. |
| Auto-inferred `archetype` / `intent` classifiers | Violates the host-declares doctrine (P1 business-truth / P2 opinion). Scoria reserves and segments by these keys; the host declares them. |
| Collapsing `ai_retrieval_runs` into a generic span | The table is richer than a span (grounding scores, typed results) and is the system-of-record; dual-write span-for-visibility, keep table-for-detail. |
| Forcing the whole span-kind vocabulary through `ai_span_events` | A worse model than every peer; `ai_span_events` is scoped to true point-events only. |
| Adding a `CHAIN` span kind | Deliberate non-gap — Scoria's `ai_traces` / workflow-run model already fills this role. |
| `opentelemetry` / `opentelemetry_api` runtime dependency | The OTel SDK is for *export*, which is host-owned and opt-in per P5/P6 — never a Scoria runtime dependency. |
| A metrics / analytics warehouse inside Scoria | P6 — OTel interop is a hook at the edges; the host exports to its own Langfuse/Datadog/OTel backend. Scoria is not an analytics platform. |
| Always-on unredacted full prompt/completion text on span attributes | PII/cardinality landmine given the key-name-only redactor; capture IDs/counts, gate raw content. |

## Traceability

Phase numbering continues from the previous milestone (v3.5 ended at Phase 50). Phase mapping below is finalized by the roadmapper — it matches the research-converged 4-phase build order exactly (no coverage or dependency problems found that warranted deviation).

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 51 | Complete |
| FOUND-02 | Phase 51 | Complete |
| FOUND-03 | Phase 51 | Complete |
| SPAN-01 | Phase 51 | Pending |
| SPAN-02 | Phase 51 | Complete |
| COMPAT-01 | Phase 51 | Pending |
| RETR-01 | Phase 52 | Pending |
| RETR-02 | Phase 52 | Pending |
| ATTR-01 | Phase 52 | Pending |
| ATTR-02 | Phase 52 | Pending |
| EVENT-01 | Phase 53 | Pending |
| EVENT-02 | Phase 53 | Pending |
| EVENT-03 | Phase 53 | Pending |
| SEC-01 | Phase 53 | Pending |
| DOCS-01 | Phase 54 | Pending |
| DOCS-02 | Phase 54 | Pending |

**Coverage:**
- v1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-11 after v3.6 domain research (SEED-007).*
*Last updated: 2026-07-11 after ROADMAP.md creation (Phases 51-54 finalized, 16/16 requirements mapped, 0 orphans).*
