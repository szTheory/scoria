# Phase 52: RETRIEVER Span + Host-Declared Attributes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-12
**Phase:** 52-retriever-span-host-declared-attributes
**Areas discussed:** RETRIEVER span emission mechanics, retrieval config fields + consistency guard, host-declared attribute threading, PROMPT-span context-pack composition
**Method:** research + red-team (per user's locked discuss preference — no interactive Q&A). 4 parallel research subagents (one per requirement, cross-aware) + 1 adversarial red-team pass, all verified against real code.

---

## RETRIEVER span emission mechanics (RETR-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Synchronous `Repo.insert` of the span in `retrieve/2` | Row exists the instant retrieve returns; join immediately non-empty | |
| Async telemetry path, span_id pinned synchronously | Reuse Phase-51 pipeline (redaction/broadcast/FK-safe upsert); mint span_id up-front onto run + span map `:id` | ✓ |

**Choice:** Async emit, IDs pinned synchronously (D-R1/D-R2). Synchronous insert rejected — re-opens the FK footgun Phase 51 fixed, skips redaction/broadcast, taxes the product hot path. "Join never empty" is a linkage-correctness criterion, satisfied by pinning span_id on both sides; test uses `Buffer.flush_now/1`.
**Notes (red-team REVISE):** `opts[:span_id]` semantically redefined from "parent reference" to "this retrieval's own id" → PK-collision risk (span `insert_all` has no `on_conflict`) + a **mandatory** existing-test migration (`retrieval_test.exs` span_id→parent_id, D-R2b). Wall-clock start captured separately from monotonic latency (D-R4). Emit after the `with`, `try/rescue → :ok`, success-path only (D-R6).

---

## Retrieval config fields + span↔table consistency guard (RETR-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Compute values twice (once per sink) | Simple but is the exact divergence class the requirement forbids | |
| Single canonical map + one Semconv projection → both sinks | Structural single-origin; guard = `Map.take` equality test | ✓ |

**Choice:** Structural single-origin via one `%{embedding_model:, index_version:, reranker:}` map + `Semconv.retrieval_config_attributes/1` feeding span attrs and `run.metadata` identically (D-RETR02-1/3). Namespace `scoria.retrieval.*`; sentinel `"none"` for absent (never nil/omit); no migration. Guard = canary + real-Postgres equality + anti-inline grep (D-RETR02-7).
**Notes:** Verified no reranker exists in `lib/`, HNSW index has no version, embedder is a behaviour needing a `model_name/0`. Red-team REVISE: `model_name/0` must be `@optional_callbacks` + `function_exported?`-guarded, and `retrieve/2` needs `:embedder` resolution it lacks today (D-RETR02-2/5).

---

## Host-declared attribute threading (ATTR-01)

| Option | Description | Selected |
|--------|-------------|----------|
| `scoria.*`/`app.*` prefixed keys | Namespaced but implies Scoria ownership of host vocabulary | |
| Bare keys `feature`/`route`/`archetype`/`intent` via one shared seam | Extends the bare `tenant_id`/`workflow_run_id` precedent | ✓ |

**Choice:** Bare keys via `Semconv.host_declared_keys/0` + `merge_host_declared/2` (one seam for both adapters + RETRIEVER + prompt span), keys land in `attributes`, absent-if-omitted, verbatim (D-ATTR01-1/2). No Phase-52 value hygiene (Redactor already runs; size bound is SEC-01/Phase 53). Never-infer proven by sentinel pass-through + empty-absent + anti-inline guards (D-ATTR01-6).
**Notes:** Red-team resolved the `scoria.retrieval.*`-vs-bare contradiction with the "prefix = vocabulary owner" rule (D-00b) and struck the "doctrine lie" rationale. Keyword-vs-map `BadMapError` fixed by normalizing `opts`→map (D-ATTR01-3). **BLOCKER surfaced:** req_llm does not forward host metadata → host-declared keys can't reach the LLM span in production via the native event (D-ATTR01-7); RETRIEVER span unaffected.

---

## PROMPT-span context-pack composition (ATTR-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Emit a new PROMPT span in Phase 52 | Matches SC#4 wording but does Phase-53/EVENT-01 structural work (scope creep) | |
| Attach composition attrs to the existing LLM/composition span now | Define Semconv contract + redaction-safe shape; Phase 53 relocates onto real PROMPT child span | ✓ |

**Choice:** Attach to the LLM/composition span (D-ATTR02-1); host-declared `context_pack` (Scoria doesn't assemble prompts — verified); single nested key `"scoria.prompt.context"` with IDs+ints only (no passthrough → structurally text-free), guard test + ≤100 cap; per-source tokens host-supplied, no sum==input_tokens guard (D-ATTR02-3/4/5/6).
**Notes:** Confirmed `gen_ai.usage.input_tokens` key name (`attributes.ex:221`) and that it can be absent. Red-team REVISE: SC#4's literal "PROMPT span" is reinterpreted (attrs ride the composition span in 52; child span in 53) — must be stated in planning. Reaching this span in production is gated on the D-ATTR01-7 mechanism.

---

## Claude's Discretion

- The exact D-ATTR01-7 host-facing injection seam for host-declared keys + context_pack on the LLM/prompt span (recommended: a Scoria-owned `emit_*` helper symmetric with `emit_retriever_span/1`), bounded against Phase 53 creep.
- Single generic projection vs. three sibling Semconv functions for the new key families.
- Trace-tree UI surfacing of the RETRIEVER span + config attrs.

## Deferred Ideas

Real child spans + `ai_span_events`/`emit_event/1` + uniform SEC-01 size bound (Phase 53); `EMBEDDING`/`RERANKER` first-class kinds (v3.7+); auto-inferred archetype/intent classifiers (out of scope); ERROR-status RETRIEVER span (v3.6 success-path only); "OpenInference-compatible" claim + conformance check (Phase 54).
