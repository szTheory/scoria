# Project Research Summary

**Project:** Scoria — v3.6 Trace Foundation (SEED-007: OTel-GenAI / OpenInference Interop)
**Domain:** Internal integration architecture — trace/span attribute naming convention for an embedded, shipped Phoenix/Elixir AI-governance library
**Researched:** 2026-07-11
**Confidence:** HIGH

## Executive Summary

SEED-007 is not a build-from-scratch feature — it is finishing a subsystem Scoria already half-built. All three trace tables (`ai_traces`, `ai_spans`, `ai_span_events`) and their Ecto schemas have existed and been migrated since `0.1.0`; the two live adapters (`req_llm.ex`, `jido.ex`) already flow spans through `Telemetry`→`Redactor`→`Buffer`→Postgres. What's missing is almost entirely naming discipline and wiring: adopting `gen_ai.*` (OTel-GenAI) and `openinference.span.kind` (OpenInference) as **conventional string keys inside the existing `attributes` jsonb map** — no new tables, no typed columns, and critically, **no new runtime dependency**. The already-locked `req_llm 1.13.0` peer ships `ReqLLM.OpenTelemetry.Attributes.start/1`/`.terminal/1`, a dependency-free function that builds the exact `gen_ai.*` map Scoria needs directly from telemetry metadata the adapter already receives. Most of the milestone's "model config capture" and "key convention" work collapses to "call this existing function and merge the result."

The recommended approach: (1) fix a pre-existing correctness bug — no production code path ever inserts an `ai_traces` row, so every `ai_spans` insert should be failing its `null: false` FK constraint, silently swallowed by a `rescue` in `Buffer.flush_spans/1`. This must be fixed before anything else in this milestone can be proven to actually persist. In the same phase, wire `ReqLLM.OpenTelemetry.Attributes` into the adapter and fix `span_kind` (both adapters currently emit non-conventional/mismatched literals — `"LLM"`/`"INTERNAL"` — against two already-drifted UI whitelists that silently default unmatched kinds to `"agent"`). (2) Add the `RETRIEVER` span at the single existing `Knowledge.retrieve/2` call site, dual-writing alongside `ai_retrieval_runs` (kept as system-of-record per doctrine), plus host-declared attribute conventions (zero technical dependency, can run in parallel). (3) Resurrect `ai_span_events` — a zero-migration but genuinely new-instrumentation task requiring new call sites for `prompt_rendered`/`guardrail_triggered`/`user_feedback_received`, none of which exist today. A parallel, equally load-bearing workstream: the docs-accuracy fix ("OpenInference-compatible") is gated by two existing contract-test files (`adopter_doc_contract.ex`, `ai_doc_contract.ex`) that currently **ban** the exact phrase this milestone wants to make true — updating those banned-phrase lists is in-scope build work, not a docs afterthought.

Key risks: (a) convention-vs-columns churn under "it'd be easier to query" pressure — mitigate with a GIN index + query helpers, not typed columns; (b) baking in today's Experimental/Development-status `gen_ai.*` key names without a version-pinned internal mapping module — a rename has already happened once (`gen_ai.system`→`gen_ai.provider.name`, `prompt_tokens`/`completion_tokens`→`input_tokens`/`output_tokens`); (c) redaction is key-name-only (flat deny-list) — new convention keys pass through safely by construction, but raw prompt/completion text or free-text host-declared values (`intent`, context-pack composition) could leak PII if captured as text instead of IDs/counts; (d) claiming "OpenInference-compatible" without a falsifiable conformance check recreates the exact overclaim problem this milestone exists to fix.

## Key Findings

### Recommended Stack

No new runtime dependency. `mix.exs` stays unchanged. `req_llm ~> 1.13` (locked `1.13.0`) already ships `ReqLLM.OpenTelemetry.Attributes.start/1` and `.terminal/1` — pure, dependency-free `Map`-building functions with zero calls into any OTel SDK — that build the full current `gen_ai.request.*`/`gen_ai.usage.*`/`gen_ai.response.*` attribute set from telemetry metadata the adapter's existing `[:req_llm, :request, :stop]` handler already receives. `openinference.span.kind` has no Elixir library anywhere (OpenInference ships only JS/Python/Rust) — it is a bare string literal Scoria writes itself from its own already-existing 8-value UI span-kind vocabulary, confirming the seed's "convention, not dependency" thesis for both halves of the interop surface.

**Core technologies:**
- `req_llm 1.13.0` (already locked, zero version bump needed) — supplies the `gen_ai.*` attribute builder and normalized `request_options` map (temp/top_p/top_k/max_tokens/seed/stop_sequences/etc.), already present in telemetry metadata on every request today
- OTel-GenAI semconv key names (plain strings, schema `1.37.0`) — naming convention only, all attributes tagged `Development` stability upstream, confirming string-keys-in-jsonb over typed columns is correct, not premature caution
- OpenInference span-kind taxonomy (plain strings) — 10-value enum (`LLM, CHAIN, TOOL, RETRIEVER, RERANKER, EMBEDDING, AGENT, GUARDRAIL, EVALUATOR, PROMPT`), no package needed, just an internal mapping table from Scoria's own 8-value vocabulary

**Explicitly not added:** `opentelemetry`/`opentelemetry_api` (SDK is for *export*, host-owned, opt-in — never a Scoria runtime dependency per P5/P6), `opentelemetry_semantic_conventions` (a convenience Hex package for hosts hand-writing exporter code; worth a docs mention only), any typed Ecto columns for `gen_ai.*` fields.

### Expected Features

**Must have (table stakes / launch with v3.6):**
- Correct 8-value `span_kind` enum on every span (fixing both adapters' current single hardcoded literals) + `openinference.span.kind` portability attribute with an `mcp`→`"TOOL"` translation for the one non-clean-1:1 kind
- `gen_ai.request.*` (temperature/top_p/max_tokens/seed) + `gen_ai.usage.*`/`gen_ai.response.*` on every LLM span — all four config params shipped together, not incrementally (a half-done capture creates false replay-fidelity confidence)
- `tool`/`prompt`/`retrieval`/`guardrail` emitted as real child **spans** (duration/failure-bearing), not events — validated as correct against both OTel-GenAI and OpenInference peer precedent
- `ai_span_events` resurrected, scoped to exactly 3 point-events: `prompt_rendered`, `guardrail_triggered`, `user_feedback_received` — content-bearing/instantaneous signals only
- `RETRIEVER` span dual-written alongside `ai_retrieval_runs` (kept as system-of-record) + `embedding_model`/`index_version`/`reranker` fields (as convention keys in existing jsonb, no migration)
- Host-declared `feature`/`route`/`archetype`/`intent` reserved keys, documented — Scoria never infers, only reserves and passes through
- README accuracy fix ("OpenInference-style" → "OpenInference-compatible"), gated on the span_kind fix actually landing and a conformance check existing to cite

**Should have (differentiator, P2 — add if time allows):**
- Context-pack / token-budget composition keys (chunk IDs + per-source token counts, not raw text) on the `PROMPT` span — no peer (OTel-GenAI or OpenInference) has standardized this; it's the single highest-leverage attribute for the milestone's actual "attribute a quality delta to what the model saw" goal, but not launch-blocking

**Defer (v3.7+):**
- `EMBEDDING` and `RERANKER` span kinds — stay as fields on the `RETRIEVER` span until a concrete independent-attribution need appears
- `CHAIN` span kind — intentional non-gap, Scoria's `ai_traces`/workflow-run model already fills this role; do not add

**Anti-features (explicitly rejected):** auto-inferred `archetype`/`intent` classifiers (violates host-declares doctrine), typed columns per semconv attribute, forcing all span kinds through `ai_span_events`, collapsing `ai_retrieval_runs` into a generic span, a metrics/analytics warehouse inside Scoria, always-on unredacted full prompt/completion text on span attributes.

### Architecture Approach

The write path is fully traced and requires no new pipeline stages, only new writers: **adapter → `:telemetry.execute([:scoria,:observe,:span,:stop])` → `Telemetry.handle_event/4` (redacts, routes) → `Buffer.cast_span/2` (in-memory) → periodic `Repo.insert_all`**. `Telemetry` and `Buffer` are pass-through today — they do zero naming/classification of their own — so all convention-key and `span_kind` work belongs entirely at the adapter layer (`req_llm.ex`, `jido.ex`), not in the pipeline itself.

**Major components:**
1. `req_llm.ex` / `jido.ex` adapters — MODIFY: merge `ReqLLM.OpenTelemetry.Attributes.start/1`+`.terminal/1` output into `attributes`; compute real `span_kind` from metadata instead of hardcoded literals; mirror into `openinference.span.kind`
2. `Scoria.Observe.Telemetry` + `Buffer` — MODIFY (new, not rewired): add a point-event ingest clause/list mirroring the existing span path exactly (same `Redactor.redact/1` call site), plus a trace-row-upsert step ordered before span insert to close the FK gap
3. `Scoria.Knowledge.retrieve/2` — MODIFY: single call site, add `:telemetry.execute` for a `RETRIEVER` span reusing the trace_id/span_id/latency it already computes; `ai_retrieval_runs` stays system-of-record, no collapse
4. New instrumentation call sites (do not exist today) — for `prompt_rendered`/`guardrail_triggered`/`user_feedback_received`, in runtime/workflow code paths that currently never call into Observe at all — genuinely new effort, not "wire the dead schema"
5. Shared `span_kind` whitelist module — currently two independently-hardcoded, already-drifted lists (`WorkflowTreeComponent` 8 kinds, `TraceTreeComponent` 9 kinds incl. `"error"`) both silently defaulting unmatched values to `"agent"`; needs one canonical source before new kinds are emitted

### Critical Pitfalls

1. **Convention-vs-columns churn** — under "easier to query" pressure someone adds typed columns for `gen_ai.*` fields on `ai_spans`. Avoid: hard rule that only `ai_retrieval_runs`'s `embedding_model`/`index_version`/`reranker` get typed columns (system-of-record table); everything else is a jsonb string key, backed by a GIN index + query-helper module for queryability.
2. **Baking in a soon-stale experimental semconv key set** — OTel-GenAI is Development-stability and has already renamed twice. Avoid: centralize every key string behind one internal mapping module (e.g. `Scoria.Observe.Semconv`) with a version-pin comment, so a future rename is a one-module diff, not a grep-and-replace.
3. **Breaking the 2 existing adapters/UI span-kind rendering** — both UI whitelists have already drifted from each other and silently swallow unmatched kinds into generic "agent" styling (a silent regression, not a crash). Avoid: extract one shared whitelist before changing what gets emitted, add a drift-guard test, update hardcoded test fixtures in the same PR.
4. **PII / cardinality in attributes** — `Redactor` is key-name-only; raw prompt/completion text or free-text host-declared values sail through untouched by shape. Avoid: capture IDs/counts, never raw text, in context-pack and prompt_rendered payloads; cap attribute size at write time.
5. **Portability false-promise** — two existing contract-test files currently *ban* the phrase "OpenInference-compatible export"; flipping the README claim without updating them either fails the build or (worse) invites weakening the guard under deadline pressure. Avoid: update `adopter_doc_contract.ex`/`ai_doc_contract.ex` in the same PR as any claim-language change, and back the new claim with an executable conformance check, not just an adjective.

## Implications for Roadmap

Based on combined research, the four-file convergent build order is:

### Phase 1: Foundation Fix + Key Convention + Span-Kind Taxonomy
**Rationale:** Everything downstream writes through the same `Buffer`/FK path and the same two adapters; a correctness bug here (missing trace-row upsert, silently swallowed by `rescue`) means nothing else in the milestone actually persists until fixed. This is also the highest-leverage phase — mostly "call an existing function" (`ReqLLM.OpenTelemetry.Attributes`) plus fixing one bug.
**Delivers:** Trace-upsert-on-flush closing the FK gap; `req_llm.ex` merges `ReqLLM.OpenTelemetry.Attributes.start/1`+`.terminal/1` output into `attributes` (gets `gen_ai.request.*`/`.usage.*`/`.response.*` — including all four model-config params together — essentially "for free"); both adapters compute real `span_kind` instead of hardcoded literals; `openinference.span.kind` mirrored at the same call site with `mcp`→`"TOOL"` translation; one shared `span_kind` whitelist module extracted and consumed by both UI components; internal `Semconv`-style mapping module with a version-pin comment.
**Addresses:** Correct span-kind enum, `gen_ai.request.*`/`usage.*`/`response.*` model config capture (FEATURES.md P1 items)
**Avoids:** Pitfall 1 (columns churn), Pitfall 2 (stale key set), Pitfall 3 (UI whitelist drift), Pitfall 7 (silently-broken replay from partial config capture)

### Phase 2: RETRIEVER Span + Host-Declared Attribute Convention
**Rationale:** Depends on Phase 1's span-emission/trace-upsert path being solid but is otherwise well-bounded — single existing call site (`Knowledge.retrieve/2`) for the span, zero technical dependency for the host-tag convention, so these can run in parallel within the phase.
**Delivers:** `RETRIEVER` span dual-written alongside `ai_retrieval_runs` (kept as system-of-record), reusing already-computed trace_id/span_id/latency; `embedding_model`/`index_version`/`reranker` as convention keys (no migration) mirrored into both the span and `ai_retrieval_runs.metadata`; host-declared `feature`/`route`/`archetype`/`intent` reserved keys, documented, threaded through the existing tenant_id/workflow_run_id metadata precedent.
**Uses:** `req_llm 1.13.0` attribute builder pattern from Phase 1; convention-over-columns discipline
**Implements:** Dual-write pattern (span for visibility, table for detail) per architecture research
**Avoids:** Pitfall 8 (dual-write divergence — single ID-generation site, single consistency-check task), Pitfall 4 (PII/cardinality — host-declared values still route through redaction)

### Phase 3: Structured Child Spans + `ai_span_events` Resurrection
**Rationale:** Highest-effort, most open-ended item — requires genuinely new instrumentation call sites (`prompt_rendered`, `guardrail_triggered`, `user_feedback_received`) that don't exist anywhere in runtime/workflow code today, unlike Phases 1-2 which wire up flows that already exist. Sequenced last so the span-before-event flush ordering discipline from Phase 1 is already in place.
**Delivers:** `tool`/`prompt`/`retrieval`/`guardrail` emitted as real child spans with `parent_id` linkage; new `[:scoria, :observe, :event, :emit]` telemetry clause + `emit_event/1` public API routing through the identical `Redactor.redact/1` call site spans use; `Buffer` event list + ordered flush (traces → spans → events); name-allowlist enforced at emission (exactly 3 event types).
**Addresses:** Structural steps as spans, content-bearing/instantaneous signals as events (FEATURES.md "Spans vs Events" validated verdict)
**Avoids:** Pitfall 5 (dead-schema resurrection footguns — redaction bypass risk, vocabulary over-stuffing), Pitfall 4 (PII in event payloads — capture composition metadata not raw text)

### Phase 4 (or riding alongside earlier phases): Docs Accuracy + Conformance Check
**Rationale:** Gated on Phase 1 actually landing (the claim must be true when made) and on a checkable artifact existing to cite — can ship any time after that, doesn't block or get blocked by Phases 2-3.
**Delivers:** README flip to "OpenInference-compatible" naming with a version pin; `adopter_doc_contract.ex`/`ai_doc_contract.ex` banned-phrase lists updated in the same PR; a small conformance check (Mix task or ExUnit test) asserting emitted spans use only allow-listed key names and `span_kind` values match the shared whitelist.
**Delivers:** Testable, falsifiable compatibility claim rather than a re-worded overclaim
**Avoids:** Pitfall 6 (portability false-promise)

### Phase Ordering Rationale

- Phase 1 must come first because it fixes a correctness bug (FK/trace-upsert gap) that silently blocks persistence for every other deliverable in the milestone, and because the shared `span_kind` whitelist must exist before any new kind values are emitted (Phase 3 introduces the most new kinds at once and is the highest-risk consumer of a whitelist that isn't yet unified).
- Phase 2 is sequenced before Phase 3 because it reuses an *existing* call site (low risk, well-bounded) while Phase 3 requires locating/creating entirely new instrumentation points — grouping by "wire what exists" vs. "build what doesn't" keeps the higher-uncertainty work isolated and reviewable on its own.
- Docs/conformance work is deliberately decoupled into its own lane because it is gated on Phase 1's technical claim being true, not on Phases 2-3, and bundling it with a feature phase risks it shipping detached from a real check (the exact Pitfall 6 failure mode).

### Research Flags

Needs deeper research during planning:
- **Phase 3** — no existing call sites for `prompt_rendered`/`guardrail_triggered`/`user_feedback_received`; the exact runtime/workflow module(s) to instrument need discovery during planning, not assumed from this research pass. Also needs explicit design for `user_feedback_received`'s async-arrival FK-resolution problem (feedback may arrive after the span/trace closes).
- **Phase 1's trace-upsert fix** — needs a planning decision on transaction shape (single `Ecto.Multi` wrapping trace-insert-if-missing → span-insert → event-insert vs. three independent calls) since this is new logic, not just a rename.

Standard patterns (skip research-phase):
- **Phase 1's attribute-merge work** — "call `ReqLLM.OpenTelemetry.Attributes.start/1`/`.terminal/1` and merge" is a fully-specified, source-verified pattern with no open design questions.
- **Phase 2's RETRIEVER span** — single call site, well-understood dual-write pattern, no new primitives.
- **Phase 4's docs/contract update** — mechanical: update two existing banned-phrase constant lists in the same PR as the claim change.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Source-code-verified against the vendored `deps/req_llm` checkout at the exact locked version, cross-checked against live OTel-GenAI and OpenInference spec repos |
| Features | HIGH on taxonomy/attribute facts (cross-checked official docs + a real published Elixir hex package); MEDIUM on context-pack composition (inherently forward-looking — the finding itself is "no peer has standardized this yet") |
| Architecture | HIGH | Grounded directly in the real source tree (`lib/scoria/observe/**`, repo schemas, migrations, tests) plus the `req_llm` dependency source at the locked version |
| Pitfalls | HIGH for pitfalls grounded in direct code inspection (cited file:line); MEDIUM for OTel-GenAI semconv stability/rename-history claims (documented versioning history, not a live re-fetch in that pass) |

**Overall confidence:** HIGH

### Gaps to Address

- **`jido.ex`'s target `span_kind` mapping** — architecture research flags that mapping `action_name`/action taxonomy to a real span kind (likely `tool` as default) "needs a planning decision, not fabricated here." Resolve during Phase 1 planning.
- **Exact instrumentation call sites for the 3 point-events (Phase 3)** — no dedicated prompt-render or guardrail module exists today; `lib/scoria/observe/approval.ex` (`ai_approvals`) is the closest existing concept for guardrails but is explicitly out of this milestone's scope per the seed. Needs discovery/design during Phase 3 planning, not assumed.
- **Backward-compat for already-persisted old-shape attribute keys** (`llm.model_name`, `llm.token_count`, `req.url`) — pitfalls research flags a real risk of breaking hosts already querying these directly against their own Postgres if old keys are deleted outright rather than dual-emitted for a deprecation window. Needs an explicit decision in Phase 1 planning.
- **`opentelemetry_semantic_conventions` Hex package** — feature research surfaces it as a real, versioned Elixir package worth referencing (not depending on) for the internal mapping module's key-name source of truth; stack research recommends docs-mention only. Reconcile during Phase 1 planning (likely: use as a reference, not a dependency).

## Sources

### Primary (HIGH confidence)
- `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex`, `open_telemetry.ex`, `telemetry.ex`, `telemetry/request_options.ex`, `CHANGELOG.md` — vendored first-party source at locked version `1.13.0`
- `raw.githubusercontent.com/open-telemetry/semantic-conventions-genai/main/docs/gen-ai/gen-ai-attributes.md` — live-fetched attribute registry with stability badges
- [Arize-ai/openinference spec/semantic_conventions.md](https://github.com/Arize-ai/openinference/blob/main/spec/semantic_conventions.md) — official spec, span-kind enum + attribute tables
- [OpenTelemetry Gen AI attribute registry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/) and [gen-ai-spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/)
- [OpenTelemetry semantic conventions for MCP](https://opentelemetry.io/docs/specs/semconv/gen-ai/mcp/)
- [opentelemetry_semantic_conventions v1.27.0 (HexDocs)](https://hexdocs.pm/opentelemetry_semantic_conventions/gen-ai.html) — real published Elixir package
- Local source: `lib/scoria/observe/**`, `lib/scoria/repo/{span,span_event,trace}.ex`, `lib/scoria/knowledge.ex`, `lib/scoria/knowledge/retrieval_run.ex`, `lib/scoria/observe/approval.ex`, `lib/scoria_web/components/{workflow_tree,trace_tree}_component.ex`, `lib/scoria/{adopter_doc_contract,ai_doc_contract}.ex`, `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs`, `README.md`, `guides/reference/glossary.md`, `guides/scoria-vs-external-llm-ops.md`, test files across `test/scoria/observe/` and `test/scoria/repo/`

### Secondary (MEDIUM confidence)
- [Langfuse: Metadata](https://langfuse.com/docs/observability/features/metadata) / [Tags](https://langfuse.com/docs/observability/features/tags) — host-tagging table-stakes finding
- [OpenTelemetry: Inside the LLM Call — GenAI Observability](https://opentelemetry.io/blog/2026/genai-observability/) — events-vs-spans content-capture model
- [Arize Phoenix OpenInference docs](https://arize.com/docs/phoenix/tracing/concepts-tracing/otel-openinference/semantic-conventions)
- `hex.pm/packages/req_llm/versions` — confirmed Hex latest `1.17.1` vs locked `1.13.0`, no relevant OTel/gen_ai changes between them

### Tertiary (LOW confidence)
- Various RAG-observability blog write-ups (72technologies, dev.to, ragaboutit) on context-window/token-budget instrumentation gaps — used only to corroborate the "context-pack composition is unsolved industry-wide" finding, not as a sole source

---
*Research completed: 2026-07-11*
*Ready for roadmap: yes*
