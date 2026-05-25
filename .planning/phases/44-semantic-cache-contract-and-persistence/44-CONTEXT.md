# Phase 44: Semantic cache contract and persistence - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the Scoria-owned semantic cache contract for explicitly safe read-only runtime lanes, including the public eligibility surface, tenant-rooted partitioning model, durable persistence primitives, and guaranteed fallback to the normal runtime path on miss or ineligible requests.

Phase 44 establishes the contract and storage truth. It does not yet own full compatibility scoring, broad invalidation semantics, operator UI projection, or verification lanes from Phases 45 and 46.

</domain>

<decisions>
## Implementation Decisions

### Eligibility API
- **D-01:** Semantic fast-path admission is opt-in through an explicit lane/module contract, not a boolean runtime flag and not prompt-policy-only classification.
- **D-02:** The public runtime surface should accept a semantic cache lane reference, for example `semantic_cache: [lane: MyApp.ScoriaLanes.AccountFAQ]`, so the safe reusable lane is explicit at the call site and greppable in host apps.
- **D-03:** Scoria should introduce a dedicated semantic lane noun such as `Scoria.SemanticLane` or equivalent behaviour/DSL that declares lane metadata once: stable `lane_key`, default scope, and read-only/safe semantics.
- **D-04:** Prompt policy remains a subordinate compatibility and governance input. It may narrow or veto eligibility, but it is not the primary public admission switch.
- **D-05:** Tool or handler annotations may enrich or veto eligibility, especially for personalized-tool-backed or approval-sensitive flows, but they cannot independently opt a run into semantic reuse.
- **D-06:** If no semantic cache lane is supplied, Scoria performs no semantic fast-path evaluation and continues through the normal durable runtime path.
- **D-07:** Rejection and bypass reasons must be explicit, stable reason codes rather than prose, e.g. `lane_not_registered`, `approval_required`, `write_side_step_present`, `personalized_tool`, `tenant_scope_missing`.

### Partition Scope
- **D-08:** `tenant_id` is the mandatory root partition on every semantic cache read and write. Semantic reuse without `tenant_id` is ineligible.
- **D-09:** Partition scope is a two-stage contract: eligibility first, then scope derivation.
- **D-10:** The default useful contract for v2.1 is hybrid scope: tenant-rooted by default, with escalation to actor scope only when the lane or runtime evidence is personalized.
- **D-11:** Persisted scope must be explicit, using a stable enum such as `scope_kind: :tenant_shared | :actor_scoped` plus a stable `scope_reason`.
- **D-12:** `actor_id` is nullable and only participates in lookup when `scope_kind == :actor_scoped`.
- **D-13:** `session_id` is not part of the default partition contract. In Scoria it remains a continuity key, not the semantic reuse boundary.
- **D-14:** `policy_key`, `prompt_ref`, `prompt_version`, and source fingerprint are compatibility fences, not primary namespace keys.
- **D-15:** Scope may narrow from tenant to actor based on explicit lane configuration, actor-specific defaults, actor-private sources, or personalized tool evidence. Historical rows are never widened from actor-scoped to tenant-shared.

### Persisted Truth
- **D-16:** Scoria should use dedicated semantic cache persistence, not overloaded retrieval tables, workflow metadata, or compacted memory rows.
- **D-17:** The durable shape for Phase 44 is two tables:
  `ai_semantic_cache_entries` for current reusable entry state and `ai_semantic_cache_entry_events` for append-only lifecycle lineage.
- **D-18:** The entry row should persist identity/scope fields, lane identity, compatibility snapshot, query embedding, answer payload, evidence references, origin run/span/retrieval refs, lifecycle fields, and metadata needed for later invalidation and operator evidence.
- **D-19:** The event table should record append-only lifecycle events such as `admitted`, `reused`, `invalidated`, `expired`, and `writeback_rejected`, each with stable reason codes and workflow/span lineage.
- **D-20:** Misses and bypasses do not need dedicated cache-owned rows in Phase 44. They should remain runtime/workflow evidence until Phase 46 projects richer operator diagnostics.
- **D-21:** The service API should return explicit outcomes such as `{:hit, hit}`, `:miss`, and `{:bypass, reason_code}` instead of booleans.
- **D-22:** Lookup starts exact-first and tenant-filtered. ANN tuning, broader analytics, and heavier miss accounting stay deferred until trust instrumentation is proven.

### Product Posture And Defaults
- **D-23:** Shift low-impact semantic-cache defaults left inside Scoria and GSD. Host apps should get one obvious happy path instead of composing flags, policy keys, and ad hoc cache keys themselves.
- **D-24:** Only materially impactful decisions should remain user-facing in later work: changes to product shape, security/policy boundaries, durable truth, tenant blast radius, or major operator UX/spend semantics.
- **D-25:** False negatives are preferable to false positives in the first release. Phase 44 should optimize for trust and support truth before hit rate.

### the agent's Discretion
- Exact naming of the semantic lane behaviour/DSL and helper modules.
- Exact Ecto schema field names where the contract above remains intact.
- Exact embedding model selection and query threshold tuning for the initial exact-first path.
- Exact TTL defaults, as long as they remain conservative and compatible with later invalidation work.
- Exact index definitions beyond the core tenant/scope/compatibility/vector needs established here.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase And Requirement Contract
- `.planning/ROADMAP.md` — Phase 44 boundary plus adjacent Phase 45 and 46 splits; defines what belongs in this phase versus later compatibility, invalidation, and operator evidence work.
- `.planning/PROJECT.md` — milestone vision, product-shape constraints, and the active decision that semantic caching remains Scoria-owned, tenant-partitioned, and evidence-first.
- `.planning/REQUIREMENTS.md` — authoritative FAST-01, SAFE-01, and FAST-02 requirement wording plus out-of-scope items FAST-03 and FAST-04.
- `.planning/STATE.md` — active milestone/session state and current project posture for Phase 44 kickoff.

### Milestone Research
- `.planning/research/SUMMARY.md` — top-level recommended direction for v2.1 semantic fast path.
- `.planning/research/STACK.md` — recommended schema/service additions and exact-first pgvector posture.
- `.planning/research/ARCHITECTURE.md` — proposed runtime flow and phase split across contract, compatibility, invalidation, and operator evidence.
- `.planning/research/FEATURES.md` — table-stakes vs differentiator framing for eligibility, lookup, invalidation, and operator diagnostics.
- `.planning/research/PITFALLS.md` — key failure modes to avoid, especially prompt-cache confusion, cross-tenant reuse, weak invalidation, and unsafe write-side caching.

### Product Vision And Prompt Research
- `prompts/phoenix-ai-lib-deep-research.md` — ecosystem lessons and product-shape guidance for a Phoenix-native AI ops layer.
- `prompts/scoria-brand-book-deep-research.md` — brand and operator-trust posture reinforcing evidence-first, non-magical semantics.
- `prompts/scoria-gsd-kickoff.md` — Scoria vision and GSD objective alignment.
- `prompts/sztheory-elixir-dna.md` — batteries-included, composable, operator-first, Ecto-native architectural DNA.

### Existing Runtime And Identity Surfaces
- `lib/scoria/identity.ex` — canonical runtime identity nouns (`tenant_id`, `actor_id`, `session_id`).
- `lib/scoria/runtime.ex` — public runtime lifecycle surface that Phase 44 should extend rather than bypass.
- `lib/scoria/runtime/params.ex` — normalized runtime input contract and metadata shaping for public start paths.
- `lib/scoria/runtime/defaults.ex` — normalized provider/model/prompt-policy defaults and runtime metadata projection.
- `lib/scoria/prompt_policy.ex` — durable prompt policy noun whose fields inform compatibility but should not become the sole eligibility switch.
- `lib/scoria/workflows/runtime.ex` — runtime execution seam, approval waiting states, and outcome handling that semantic caching must not bypass unsafely.
- `lib/scoria/workflows/run.ex` — durable run state shape and metadata carrier for origin/runtime linkage.

### Existing Durable Data Patterns
- `lib/scoria/knowledge/source.ex` — versioned knowledge source pattern relevant to source fingerprint and invalidation readiness.
- `lib/scoria/knowledge/retrieval_run.ex` — retrieval-run durable noun that should remain distinct from reusable-answer cache truth.
- `lib/scoria/eval/eval_run.ex` — explicit versioned eval persistence pattern that reinforces separate durable nouns over metadata soup.
- `priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs` — current knowledge pgvector persistence pattern.
- `priv/repo/migrations/20260519010100_create_ai_compacted_memories.exs` — prior explicit durable state pattern and binary embedding compatibility choice.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Runtime` and `Scoria.Runtime.Params`: already define the stable public runtime start/resume contract and are the correct entry points for semantic fast-path opt-in.
- `Scoria.Runtime.Defaults` and `Scoria.PromptPolicy`: already normalize provider/model/prompt-policy metadata and should feed semantic compatibility state without owning the admission boundary.
- `Scoria.Identity`: already defines canonical `tenant_id`, `actor_id`, and `session_id` semantics, so semantic cache partitioning should reuse these nouns directly.
- `Scoria.Knowledge.Source` and `Scoria.Knowledge.RetrievalRun`: provide existing source-version and retrieval lineage surfaces that semantic cache rows can reference instead of duplicating evidence concepts loosely.
- Existing Ecto schema + migration patterns in workflows, eval, and knowledge: establish how Scoria prefers explicit durable tables and versioned truth.

### Established Patterns
- Explicit public nouns over hidden middleware behavior.
- Durable Ecto truth over process-local or projection-only state.
- Prompt/version/policy metadata carried as inspectable runtime metadata.
- Separation of related but distinct concerns into separate schemas instead of collapsing everything into one generic table.
- Runtime/workflow seams preserve approvals and audit lineage explicitly; semantic caching must compose with those seams rather than short-circuit them invisibly.

### Integration Points
- Public runtime admission: `Scoria.start_run/2` and related parameter normalization.
- Runtime metadata projection: `Scoria.Runtime.Defaults.to_metadata/1`.
- Durable origin linkage: workflow run ids, spans, and retrieval runs already persisted elsewhere in Scoria.
- Later compatibility/invalidation work: Phase 45 should extend the semantic cache service and event model rather than revisiting the public lane/scope contract.
- Later operator UX: Phase 46 should project the entry/event truth into runtime/workflow detail surfaces without inventing a second evidence model.

</code_context>

<specifics>
## Specific Ideas

- The semantic cache happy path should feel like one explicit host-app noun: a safe semantic lane module registered once and passed clearly at runtime entry.
- The operator story should read like: “lane X was requested, Scoria admitted or rejected it for reason Y, scope resolved to tenant or actor for reason Z, and the origin run/source/prompt lineage is visible.”
- Low-impact defaults should be shifted left into Scoria and future GSD planning flows. Only high-impact boundary decisions should interrupt the user.
- Phase 44 should preserve a calm, non-magical operator experience: no invisible middleware cache, no hidden global reuse, no support-unfriendly guesswork.

</specifics>

<deferred>
## Deferred Ideas

- Similarity thresholds, rich compatibility evaluator, prompt/source/policy invalidation engine, and active/stale/invalidated taxonomy refinement belong primarily to Phase 45.
- Runtime/workflow UI projection, per-lookup miss analytics, suspicious-hit review affordances, and checked milestone verification belong primarily to Phase 46.
- ANN tuning, external cache backends, broad cache analytics, and provider-prompt-cache-centric productization remain out of scope for this milestone slice.

</deferred>

---

*Phase: 44-semantic-cache-contract-and-persistence*
*Context gathered: 2026-05-25*
