# Phase 45: Compatibility and invalidation engine - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Make semantic reuse conservative and explainable by adding compatibility gating and invalidation semantics on top of the Phase 44 semantic cache contract.

Phase 45 owns lookup compatibility, stale handling, and invalidation truth for prompt, policy, and source evolution. It does not widen the public lane contract from Phase 44, and it does not yet own operator-surface projection or final verification lanes from Phase 46.

</domain>

<decisions>
## Implementation Decisions

### Similarity posture
- **D-01:** Phase 45 should keep exact-text lookup as the safest first hit path, then add a semantic fallback only after tenant, lane, scope, status, freshness, prompt, policy, and source filters have already reduced the candidate set.
- **D-02:** Semantic lookup should remain exact-first `pgvector` search inside Postgres/Ecto rather than ANN-first retrieval. Recall and explainability are more important than hit rate in `v2.1`.
- **D-03:** Similarity is the last compatibility gate, not the first. A candidate must already be partition-compatible and compatibility-compatible before similarity is considered.
- **D-04:** The default posture for this milestone is false negatives over false positives. Missing a reusable answer is acceptable; serving a wrong cached answer is not.
- **D-05:** Session continuity is not a semantic reuse boundary. Reuse remains tenant-rooted and may narrow to actor scope, but never widens from actor-scoped history into tenant-shared reuse.

### Compatibility contract
- **D-06:** Lookup outcomes must become stage-separated and support-friendly: eligibility bypass, lookup miss, lookup reject, or hit. Scoria should stop collapsing true compatibility failures into plain misses.
- **D-07:** `eligibility_reason_code` remains reserved for pre-lookup bypasses such as `lane_not_registered`, `tenant_scope_missing`, `approval_required`, `write_side_step_present`, `personalized_tool`, and `query_text_missing`.
- **D-08:** `lookup_reason_code` should only describe post-candidate compatibility rejection, with stable codes such as `prompt_version_mismatch`, `policy_mismatch`, `source_fingerprint_mismatch`, `scope_mismatch`, `entry_stale`, and `entry_invalidated`.
- **D-09:** `lookup_status=miss` means no reusable compatible candidate existed. It should not be overloaded to hide stale or incompatible candidates.
- **D-10:** Scoria may derive an internal compatibility fingerprint for efficient matching and fan-out, but that fingerprint is an implementation detail, not the primary external explanation surface.

### Invalidation and freshness
- **D-11:** Phase 45 should use a hybrid model: hard invalidation for provable incompatibility plus a conservative soft freshness window for age-based decay.
- **D-12:** Persisted entry lifecycle states for this phase should be `active`, `stale`, `invalidated`, and existing `writeback_rejected`. `stale` and `invalidated` are both non-reusable and fall through to the normal runtime path.
- **D-13:** Hard invalidation must be explicit and reason-coded when prompt version changes, policy compatibility changes, source fingerprint changes, or an operator explicitly revokes an entry.
- **D-14:** Freshness expiry should transition entries to `stale` with a stable reason such as `freshness_window_elapsed`, not silently disappear into a generic miss.
- **D-15:** `invalidated` is reserved for provable incompatibility, not mere age. Age-based decay and semantic incompatibility are distinct truths and must stay distinct in persisted state.

### Compatibility inputs
- **D-16:** `source_fingerprint` must be derived from durable source-version and source-digest truth, not ad hoc text snapshots or lossy heuristics.
- **D-17:** Policy compatibility should be stronger than `policy_key` alone. Phase 45 should persist and compare a stable policy fingerprint or equivalent compatibility snapshot so silent policy-semantic drift does not leave old answers reusable.
- **D-18:** Prompt compatibility should fence on explicit prompt identity and version, reusing the normalized runtime metadata surfaces already present in Scoria.
- **D-19:** Similarity thresholds should default conservatively and stay shift-left inside Scoria/GSD. Threshold tuning, rerankers, and lane-specific controls are deferred unless they materially change product behavior or blast radius.

### Product posture and defaults
- **D-20:** Low-impact cache mechanics should be shifted left into Scoria and future GSD flows. Later discuss/planning steps should not re-ask about ANN, stale-while-revalidate, per-lane tuning UI, or background refresh unless the choice changes product shape, security, durable truth, tenant blast radius, or major operator UX.
- **D-21:** Phase 45 should preserve the embedded-library shape: one boring Ecto/Postgres truth path, explicit reason codes, explicit fallback, and no hosted cache tier or invisible middleware semantics.

### the agent's Discretion
- Exact schema field names for policy compatibility snapshot/fingerprint as long as the stronger-than-`policy_key` contract remains intact.
- Exact freshness window defaults per lane, provided they remain conservative and fail closed.
- Exact internal query/ranking implementation for the semantic fallback, provided it stays exact-first, filter-first, and explainable.
- Exact internal representation of stage-separated outcomes in Elixir structs/tuples, provided persisted/operator-facing reason codes remain stable.

</decisions>

<specifics>
## Specific Ideas

- The desired operator story is: “Scoria checked the lane, scope, prompt, policy, source, freshness, then similarity; it either hit or explained exactly why it fell through.”
- This should feel like a calm field-engineer tool, not a magical cache. Wrong reuse is worse than low hit rate.
- The semantic path should stay boring for Phoenix teams: explicit runtime opt-in, explicit Postgres truth, explicit fallback, explicit reasons.
- Shift-left preference is active here: future GSD flows should auto-pick Scoria’s conservative defaults for similarity posture, freshness posture, and reason taxonomy unless a later phase introduces a materially impactful tradeoff.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase And Requirement Contract
- `.planning/ROADMAP.md` — Phase 45 scope, success criteria, and Phase 46 boundary.
- `.planning/PROJECT.md` — milestone product posture: embedded, Phoenix-first, tenant-partitioned, operator-visible, evidence-first.
- `.planning/REQUIREMENTS.md` — authoritative wording for `LOOK-01`, `LOOK-02`, `INVD-01`, and `INVD-02`.
- `.planning/STATE.md` — active milestone state and current focus.
- `.planning/METHODOLOGY.md` — decisive-defaults lens; low-impact cache mechanics should be shifted left unless strategically consequential.

### Prior Phase Contract
- `.planning/phases/44-semantic-cache-contract-and-persistence/44-CONTEXT.md` — locked lane/scope/public-contract decisions from Phase 44 that Phase 45 must extend, not revisit.
- `.planning/phases/44-semantic-cache-contract-and-persistence/44-RESEARCH.md` — Phase 44 research boundary showing similarity/invalidation work was intentionally deferred here.

### Milestone Research
- `.planning/research/SUMMARY.md` — milestone recommendation for Scoria-owned, exact-first semantic cache posture.
- `.planning/research/STACK.md` — stack guidance for `pgvector`, strong filter keys, and dedicated helper modules.
- `.planning/research/ARCHITECTURE.md` — proposed runtime flow and compatibility/invalidation role in the overall architecture.
- `.planning/research/PITFALLS.md` — key risks: false-positive hits, weak invalidation, prompt-cache confusion, and unsafe reuse.
- `.planning/research/elixir-ai-ecosystem.md` — ecosystem fit and operator-first product-shape constraints.
- `.planning/research/agentcore-lessons.md` — reminder to preserve embedded control-plane posture and explicit governed state.

### Product Philosophy
- `prompts/phoenix-ai-lib-deep-research.md` — broader ecosystem lessons about Phoenix-native AI ops, durable truth, and observability-first product design.
- `prompts/scoria-brand-book-deep-research.md` — brand and UX posture: calm, evidence-based, operator-grade, not magical.
- `prompts/scoria-gsd-kickoff.md` — Scoria vision and GSD alignment.
- `prompts/sztheory-elixir-dna.md` — batteries-included but composable, Ecto-native, operator-first architectural DNA.

### Existing Code Surfaces
- `lib/scoria/semantic_cache.ex` — current exact-match lookup, lifecycle writes, and event model to extend.
- `lib/scoria/semantic_cache/eligibility.ex` — current explicit bypass contract and scope derivation.
- `lib/scoria/semantic_lane.ex` — locked lane noun and scope defaults from Phase 44.
- `lib/scoria/workflows/runtime.ex` — current fast-path lookup/write-back seam and runtime metadata projection.
- `lib/scoria/knowledge/source.ex` — durable source version/digest truth relevant to source fingerprint derivation.
- `lib/scoria/runtime/params.ex` — runtime metadata normalization surface that already carries semantic lane metadata.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.SemanticCache`: already owns entry/event persistence and should remain the single context for compatibility lookup and invalidation logic.
- `Scoria.SemanticCache.Eligibility`: already gives Scoria a clean pre-lookup bypass stage with stable reason codes.
- `Scoria.Workflows.Runtime.prepare_semantic_fast_path/1`: already projects semantic state into runtime metadata and is the correct seam for stage-separated lookup results.
- `Scoria.Knowledge.Source`: already persists versioned source truth with `digest` and `version`, giving Phase 45 a durable base for source fingerprints.
- Existing workflow/eval/knowledge modules: already show Scoria’s preferred explicit-status + append-only-evidence style.

### Established Patterns
- Explicit tagged outcomes over booleans or hidden middleware behavior.
- Durable Ecto truth over process-local or external cache state.
- Stable reason codes instead of prose explanations.
- Versioned prompt/policy/source facts as inspectable runtime metadata and persistent compatibility fences.
- Embedded-library ergonomics: one obvious Postgres/Ecto default path, with optional sophistication deferred until proven necessary.

### Integration Points
- Lookup path: `Scoria.Workflows.Runtime.prepare_semantic_fast_path/1` should evolve from exact-text-only lookup into filter-first compatibility plus semantic fallback.
- Write-back path: `maybe_attach_semantic_writeback/3` already persists entries after normal execution and will need Phase 45 compatibility fields/status semantics to stay aligned.
- Invalidation hooks: prompt, policy, and source evolution should invalidate semantic entries through Scoria-owned state transitions and append-only events, not by silent disappearance.
- Phase 46 projection: runtime/workflow DTOs can later expose the reason codes and status truth created here without inventing a second model.

</code_context>

<deferred>
## Deferred Ideas

- ANN indexes, HNSW/IVFFlat tuning, and broad scaling controls.
- Per-lane threshold tuning UI or public advanced similarity controls.
- Stale-while-revalidate serving, background refresh workers, and asynchronous refresh orchestration.
- Persisted miss/reject ledgers for every lookup and richer analytics-heavy cache dashboards.
- External cache backends, hosted cache services, or cross-runtime cache federation.
- Bulk epoch/generation invalidation machinery unless later phases prove that simple explicit invalidation is operationally insufficient.

</deferred>

---

*Phase: 45-compatibility-and-invalidation-engine*
*Context gathered: 2026-05-25*
