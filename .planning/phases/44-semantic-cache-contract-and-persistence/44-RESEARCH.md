# Phase 44 Research: Semantic cache contract and persistence

**Phase:** `44`
**Date:** `2026-05-25`
**Question:** What does Scoria need to implement in Phase 44 so the semantic fast path is explicit, tenant-partitioned, durable, and safely bypassable?

## Recommendation

Phase 44 should introduce a Scoria-owned semantic cache boundary with three concrete deliverables:

1. A public lane contract that makes semantic reuse opt-in and greppable at runtime call sites.
2. A dedicated durable persistence model for entries and lifecycle events.
3. A conservative runtime integration that only evaluates safe read-only lanes and always falls through cleanly on miss or rejection.

This phase should not attempt rich compatibility scoring, invalidation orchestration, analytics, or operator UI projection. Those belong to Phases 45 and 46.

## Existing Assets To Reuse

- `Scoria.Runtime`, `Scoria.Runtime.Params`, and `Scoria.Runtime.Defaults` already define the public runtime start path and normalized metadata projection.
- `Scoria.Identity` already provides the canonical `tenant_id`, `actor_id`, and `session_id` nouns the cache must reuse directly.
- `Scoria.PromptPolicy` already surfaces `policy_key`, `prompt_ref`, `prompt_version`, `tools_allowed`, and `approval_required`, which should constrain eligibility and persisted compatibility metadata.
- `Scoria.Knowledge` and `Scoria.Knowledge.RetrievalRun` already model durable retrieval lineage and provide the main analog for vector-backed query persistence without overloading workflow rows.
- Existing Ecto migration patterns under `priv/repo/migrations/` and `priv/repo/knowledge_migrations/` show Scoria's preferred `binary_id`, explicit indexes, and append-only truth style.

## Phase Boundary

### In scope

- Explicit semantic lane noun / behaviour / DSL.
- Eligibility engine with stable bypass reason codes.
- Mandatory tenant-root partitioning with optional actor narrowing.
- Dedicated entry and event tables.
- Service API that returns `{:hit, hit}`, `:miss`, or `{:bypass, reason_code}`.
- Runtime integration that preserves the normal path on miss or ineligibility.

### Out of scope for Phase 44

- Similarity threshold tuning beyond conservative exact-first scaffolding.
- Prompt/source/policy invalidation engine.
- Operator dashboard projection.
- Broad miss analytics and suspicious-hit review workflows.
- External cache backends or ANN tuning surfaces.

## Proposed Module Shape

### Public contract

- `Scoria.SemanticLane` — behaviour/DSL for declaring `lane_key`, default scope, and safe semantics.
- `Scoria.SemanticCache` — public context/service entry point.

### Internal cache modules

- `Scoria.SemanticCache.Entry`
- `Scoria.SemanticCache.EntryEvent`
- `Scoria.SemanticCache.Eligibility`
- `Scoria.SemanticCache.Lookup`
- `Scoria.SemanticCache.Writeback`

### Runtime seam

- Extend `Scoria.Runtime.Params` so callers can pass `semantic_cache: [lane: MyLane]`.
- Keep the runtime seam explicit rather than hiding cache lookup in middleware or process state.

## Persistence Recommendation

Use two dedicated tables:

1. `ai_semantic_cache_entries`
2. `ai_semantic_cache_entry_events`

### `ai_semantic_cache_entries`

Persist:

- identity partition fields: `tenant_id`, nullable `actor_id`, `scope_kind`, `scope_reason`
- lane identity: `lane_key`, `lane_module`
- compatibility snapshot: `policy_key`, `prompt_ref`, `prompt_version`, `provider`, `model`, `source_fingerprint`
- query facts: `query_text`, `query_embedding`
- answer facts: `answer_payload`, `evidence_refs`
- lineage: `origin_run_id`, `origin_span_id`, `origin_retrieval_run_id`
- lifecycle: `status`, `last_hit_at`, `hit_count`, `expires_at`, `invalidated_at`
- metadata map for conservative forward compatibility

### `ai_semantic_cache_entry_events`

Persist append-only lifecycle records for:

- `admitted`
- `reused`
- `invalidated`
- `expired`
- `writeback_rejected`

Each event should carry `reason_code`, workflow/span lineage, and any compact metadata needed for later operator projection.

## Eligibility Rules For This Phase

- No `semantic_cache` lane supplied => bypass with `lane_not_registered`.
- Missing `tenant_id` => bypass with `tenant_scope_missing`.
- Approval-sensitive flows => bypass with `approval_required`.
- Write-side steps or mutable side effects => bypass with `write_side_step_present`.
- Personalized tool usage => bypass with `personalized_tool`.
- Prompt policy may narrow or veto eligibility, but never grant it by itself.

The first release should prefer false negatives to false positives.

## Runtime Integration Notes

- Runtime lookup must happen on the Scoria-owned start path, not in host-app ad hoc helpers.
- Misses and bypasses must not create cache-owned durable rows in this phase; only admitted entries and lifecycle events become semantic-cache truth.
- Write-back should happen only after a normal successful response in an eligible lane, and it must record origin lineage so later invalidation and UI work can build on stable facts.

## Risks And Mitigations

### Cross-tenant reuse

Mitigation: require `tenant_id` on every read/write and index around it.

### Unsafe reuse of tool-backed or approval-sensitive outputs

Mitigation: explicit rejection reason codes and a lane contract that cannot be enabled by prompt policy alone.

### Overloading retrieval or workflow tables

Mitigation: dedicated semantic cache tables and modules; store references to retrieval/workflow truth instead of collapsing domains.

### False-positive hits from premature ANN tuning

Mitigation: exact-first lookup posture and explicit deferral of ANN tuning to later milestone work.

## Build Order

1. Durable tables, schemas, and semantic cache context API.
2. Public semantic lane contract and eligibility/scope derivation.
3. Runtime lookup/writeback integration with conservative bypass and fallback semantics.

## Validation Architecture

Phase 44 should validate at three levels:

1. Unit tests for lane normalization, eligibility reason codes, scope derivation, and semantic cache service outcomes.
2. Persistence tests for entry/event writes, tenant partition filtering, and append-only lifecycle rows.
3. Runtime integration tests proving:
   - eligible safe lanes attempt lookup
   - ineligible lanes return explicit bypass reasons
   - misses fall through to normal workflow creation without mutating cache truth
   - admitted completions persist entry + event lineage

Targeted commands should stay in the normal ExUnit lane:

- `mix test test/scoria/semantic_cache_test.exs`
- `mix test test/scoria/runtime/semantic_fast_path_test.exs`

## Planning Implications

- Plan 01 should own migrations, schemas, and the semantic cache service API.
- Plan 02 should own the public lane noun plus eligibility and scope derivation rules.
- Plan 03 should own runtime integration, fallback guarantees, and lifecycle persistence on reuse/write-back.

## Sources

- `.planning/phases/44-semantic-cache-contract-and-persistence/44-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/research/SUMMARY.md`
- `.planning/research/STACK.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/FEATURES.md`
- `.planning/research/PITFALLS.md`
