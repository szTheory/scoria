# Phase 45: Correctness sweep + fail-closed proof & closeout - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v3.4 P0 trust/security milestone with the remaining correctness fixes and proof. This
phase does not add a new capability family; it fixes the four known fake/misleading measurements
left after Phases 42 and 43, then confirms the scope-doctrine SSOT is cross-linked from the
fail-closed rationale.

This phase delivers FIX-01..04 and DOC-01 only:

1. `Knowledge.Backends.Pgvector.score_chunk/2` stops persisting a fake component-sum similarity and
   records the real cosine similarity that matches pgvector's `cosine_distance` ordering.
2. `Knowledge.Grounding.score_citation_presence/1` becomes label-aware so a labeled unanswerable
   case with no citations is a correct abstention, not a failed citation-presence check.
3. `Chunker.Default` removes the dead `overlap:` option and is documented as section-based and
   non-overlapping.
4. Eval threshold policy `max_latency_ms` uses real recorded score latency instead of metadata that
   is hardcoded to `0`.
5. The P1-P6 scope doctrine is confirmed in `PROJECT.md` and cross-linked from the eval,
   knowledge, dashboard, and closeout rationale.

**Method note:** The user delegated all choices to Claude and requested subagent research for each
decision area. Five advisor researchers covered cosine scoring, citation abstention, chunker
overlap, latency evidence, and doctrine closeout. This context synthesizes those recommendations
with the local code, prior phase context, prompt corpus, and current brand/project doctrine.

**In scope:** correctness fixes, focused tests, narrow docs/proof updates, and closeout rationale.
**Out of scope:** Hex `0.1.3` publish, a full docs/positioning overhaul, semantic/faithfulness RAG
eval depth, a real sliding-window chunker, reranking, UI scope bars, tenant switching, or any live
LLM requirement in CI.

</domain>

<decisions>
## Implementation Decisions

Hard constraints carried forward:

- **Fix + prove only.** This phase still gates the next Hex release but does not cut that release.
- **No live LLM calls in CI/tests.** All proof must be deterministic and key-free.
- **No fake-green or fake measurements.** Unknown/missing measurement must not be laundered into
  `passed`, `0.0`, or harmless-looking default evidence.
- **Scoria owns the verb; host owns the noun.** Scoria fixes recording, gating, filtering,
  scoring, and proof mechanisms; host-owned identity, business truth, policy values, and end-user
  product semantics stay delegated.

### D-01 - Pgvector score: persist raw cosine similarity from the DB metric

- Keep ordering on pgvector's cosine-distance operator and persist `score = 1 - cosine_distance`.
- Treat `RetrievalResult.score` as raw cosine similarity, not a probability. Do not clamp,
  round-for-display, normalize to `0..1`, or convert anti-correlated vectors into prettier values.
- Filter out chunks with nil embeddings before ranking. Do not return nil-embedding rows with a
  fabricated `0.0` score.
- Let invalid query vectors or dimension mismatches fail loudly before retrieval rows are persisted.
- Prefer a DB-projected score over a separate Elixir cosine helper so the stored score and ranking
  metric cannot drift. Keep any helper private unless multiple backends need it in this phase.
- Proof should include backend fixtures and end-to-end `Knowledge.retrieve/2` persistence checks
  that demonstrate stored scores match `1 - cosine_distance`, including exact match, orthogonal
  similarity, and nil/invalid embedding behavior.

Rejected alternatives:

- **Private Elixir cosine helper:** easier to unit-test but duplicates pgvector math and invites
  divergence from the DB ranking operator.
- **Shared `VectorScoring` module:** premature public surface; useful only if another backend needs
  the same metric now.
- **Clamped display score:** friendlier for UI, but misleading as persisted evidence.

### D-02 - Citation presence: minimal `expected_answerable` label awareness

- Add a deterministic, no-schema-change label path to `score_citation_presence/1`.
- Canonical input label: `expected_answerable: true | false`. Accept string keys and the
  compatibility alias `answerable` if cheap; do not invent a broad label taxonomy.
- Behavior:
  - `expected_answerable: true` + one or more citations -> `1.0/"passed"`.
  - `expected_answerable: true` + empty citations -> `0.0/"failed"`.
  - `expected_answerable: false` + empty citations -> `1.0/"passed"`.
  - `expected_answerable: false` + citations -> `0.0/"failed"`.
  - missing label -> preserve legacy citation-presence behavior, so empty citations still fail.
- Keep this scorer about citation expectation only. Do not parse natural-language refusals, add
  semantic abstention scoring, add `not_scored` to grounding scores, or build full RAG eval labels
  here.
- Details should expose simple operator-readable evidence such as citation count and expected
  answerability.
- Tests should cover answerable/no-citation failure, answerable/citation pass,
  unanswerable/no-citation pass, unanswerable/with-citation failure, string-key labels, and
  missing-label legacy behavior.

Rejected alternatives:

- **Strict label-required scoring:** stronger but breaks unlabeled callers and turns this into a
  dataset-contract migration.
- **Require explicit `abstained: true`:** better semantic proof, but no reliable upstream field
  exists and this becomes SEED-009 abstention evaluation.
- **Full retrieval/abstention schema:** valuable, but intentionally deferred.

### D-03 - Chunker default: remove fake overlap, document non-overlap

- Remove `overlap = Keyword.get(opts, :overlap, 24)` and the no-op `max(end - overlap, end)` path
  from `Chunker.Default`.
- Set the next offset directly to `chunk.end_offset`.
- Document `Chunker.Default` as section/paragraph-based and non-overlapping.
- Preserve today's deterministic offsets and chunk digests. Existing callers passing `overlap:`
  should not get new behavior from this default chunker.
- Do not warn or raise on `overlap:` in this patch unless the planner finds a very low-risk source
  guard. Warning keeps the fake option alive and can pollute tests; raising is a more explicit
  breaking change than this P0 closeout needs.
- A real fixed-size/sliding-window chunker belongs in SEED-009 as a separate chunker module because
  overlap affects offsets, digests, citation anchors, and retrieval-eval proof.
- Tests should directly prove monotonic, non-overlapping `start_offset/end_offset` values and repeat
  ingest `chunk_digest` stability.

Rejected alternatives:

- **Accept-and-warn:** migration-friendly but ambiguous and noisy.
- **Raise on `overlap:`:** catches mistaken callers but can break adopters for an option that never
  worked.
- **Build `Chunker.Windowed`:** useful future capability, out of scope here.

### D-04 - Latency gate: real score-level latency, fail closed on missing configured latency

- Record real per-item scorer wall-clock latency in `ai_scores.metadata["latency_ms"]`.
- Use BEAM monotonic time (`System.monotonic_time` + unit conversion), not wall-clock `DateTime`
  deltas.
- `max_latency_ms` remains a score-level threshold consumed by `Scoria.Eval.Verdict.compute/2`.
  Do not switch it to whole-run duration.
- When `max_latency_ms` is configured and a scored item lacks parseable latency metadata, the verdict
  should be `:inconclusive`, not pass by defaulting to `0`.
- A measured `0` is allowed only when it is an actual measured value from the timing seam.
- Also set `EvalRun.duration_ms` from a real whole-run timer for observability, but do not use it for
  the threshold gate.
- Tests must not use sleeps or live providers. Prefer injected clocks/timing helpers or deterministic
  test seams for runner, judge, and online scoring paths.
- Add verdict tests for over-threshold latency and configured-but-missing latency.

Rejected alternatives:

- **Frozen subject trace latency:** likely best product latency signal later, but Phase 42 chose
  sealed replay from captured output; live trace re-reads would violate that doctrine.
- **Whole-run duration as gate input:** useful SLI, wrong policy unit, and dataset-size dependent.
- **Judge-call latency only:** useful for eval infrastructure SLOs, but excludes deterministic
  scorers and changes the meaning of `max_latency_ms`.

### D-05 - Doctrine closeout: targeted cross-links, not a docs/UI expansion

- Confirm the full P1-P6 scope doctrine remains in `.planning/PROJECT.md ## Constraints`.
- Confirm `.planning/PROJECT.md ## Key Decisions` includes the 2026-07-03 audit/doctrine decision
  and the v3.4 fix-and-prove decisions.
- Add short cross-links from eval, knowledge, dashboard, and Phase 45 closeout rationale to the
  doctrine SSOT. The link should explain why each fix is Scoria-owned:
  - Eval: Scoria owns scoring/gating mechanisms.
  - Knowledge: Scoria owns the retrieval query/filtering/storage verb.
  - Dashboard: authz is delegated, but Scoria must ship the host-auth seam and trusted scope record.
  - Phase 45: Scoria must record real measurements and avoid fake evidence.
- Keep adopter docs narrow: if docs are touched, point readers to host-owned tenant/actor/policy
  nouns and Scoria-owned record/gate/filter/surface verbs. Do not write the full owns-vs-delegates
  table here; SEED-005 owns the stable docs front door.
- Do not add a persistent scope bar, tenant switcher, or new UI receipt in Phase 45. SEED-013 owns
  structural operator IA.
- Verification should include a doc/source contract that proves the doctrine exists and the
  closeout rationale links back to it.

Rejected alternatives:

- **Full adopter-facing owns-vs-delegates docs table now:** valuable, but duplicates SEED-005.
- **PROJECT-only checkbox:** too weak; downstream readers need the rationale cross-link.
- **UI scope receipt:** good future UX, wrong phase and potentially confusing without host policy.

### Claude's Discretion

- Exact private function names and query projection shape for pgvector score calculation.
- Exact label normalization helpers for citation presence, provided `expected_answerable` is the
  canonical public label.
- Exact test file placement, as long as coverage is focused and key-free.
- Whether documentation updates land in README, `docs/adoption_lanes.md`, and/or
  `docs/operator_verification.md`; keep them narrow and proof-oriented.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and Roadmap

- `.planning/ROADMAP.md` - Phase 45 goal and FIX-01..04 / DOC-01 success criteria.
- `.planning/REQUIREMENTS.md` - locked FIX and DOC requirement text plus v3.4 out-of-scope table.
- `.planning/PROJECT.md` - v3.4 fix-and-prove boundary, n=1 operator lens, P1-P6 scope doctrine,
  and Key Decisions rows.
- `.planning/seeds/SEED-006-pre-1.0-trust-security-hardening.md` - source analysis for the four
  correctness sweep bugs and doctrine rationale.
- `.planning/seeds/SEED-005-documentation-overhaul.md` - owns-vs-delegates docs doctrine and
  deferred stable docs front door.
- `.planning/seeds/SEED-009-retrieval-eval-depth-and-seams.md` - deferred retrieval metrics,
  abstention scoring, reranker hooks, and real sliding-window chunker.

### Prior Phase Context

- `.planning/phases/42-eval-fails-closed/42-CONTEXT.md` - fail-closed verdict spine, no-live-LLM
  proof constraint, and sealed replay/captured-output doctrine.
- `.planning/phases/43-knowledge-tenant-isolation/43-CONTEXT.md` - explicit knowledge scope,
  fail-closed retrieval, and tenant evidence posture.
- `.planning/phases/44-dashboard-auth-seam/44-CONTEXT.md` - host-owned dashboard scope/authz seam and
  client-param distrust posture.

### Knowledge Code

- `lib/scoria/knowledge/backends/pgvector.ex` - current fake `score_chunk/2` and vector ranking path.
- `lib/scoria/knowledge/grounding.ex` - current citation-presence logic and deterministic grounding
  scorer vocabulary.
- `lib/scoria/knowledge.ex` - ingest/retrieve/score integration points and retrieval-run latency
  precedent.
- `lib/scoria/knowledge/chunker.ex` - current `Chunker.Default` overlap no-op.
- `lib/scoria/knowledge/scope.ex` - fail-closed tenant/actor scope helper from Phase 43.
- `lib/scoria/knowledge/retrieval_result.ex` - persisted score sink for retrieval results.
- `lib/scoria/knowledge/grounding_score.ex` - persisted score sink for grounding checks.

### Eval Code

- `lib/scoria/eval/verdict.ex` - threshold policy computation and `max_latency_ms` gate.
- `lib/scoria/eval/runner.ex` - offline exact-match score path and current `latency_ms: 0` metadata.
- `lib/scoria/eval/judge_runner.ex` - judge score path and current `latency_ms: 0` metadata.
- `lib/scoria/eval/online_scoring.ex` - online deterministic score metadata and verdict integration.
- `lib/scoria/eval.ex` - score aggregation, `avg_latency_ms`, and score metadata extraction.
- `lib/scoria/eval/scorers/exact_match.ex` - Phase 42 deterministic scorer style to preserve.

### Tests and Proof Surfaces

- `test/scoria/knowledge/pgvector_test.exs` - tenant-filtered vector retrieval tests to extend for
  real score persistence.
- `test/scoria/knowledge/retrieval_test.exs` - end-to-end retrieval behavior.
- `test/scoria/knowledge/grounding_test.exs` - grounding scorer tests to extend for
  `expected_answerable`.
- `test/scoria/knowledge_test.exs` - ingest/chunker/retrieval persistence coverage.
- `test/scoria/eval/verdict_test.exs` - latency gate policy tests.
- `test/scoria/eval/offline_runner_test.exs` - offline score metadata proof.
- `test/scoria/eval/judge_runner_test.exs` - injected judge seam proof without live LLM calls.
- `test/scoria/eval/online_scoring_test.exs` - online deterministic score metadata proof.
- `docs/operator_verification.md` - operator-facing proof narrative for knowledge/eval lanes.
- `docs/adoption_lanes.md` - adopter-facing optional lane setup and identity/scope wording.
- `README.md` - only narrow pointer updates if needed; full docs front door belongs to SEED-005.

### Prompt and Brand Corpus

- `prompts/ai-eval-best-practices-deep-research.md` - eval/RAG failure-mode framing and
  "no-error is not correctness" posture.
- `prompts/ai-architectural-patterns-deep-research.md` - RAG/eval separation, citation discipline,
  and architecture ladder guidance.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native library, Ecto, Telemetry, and embedded
  dashboard posture.
- `prompts/scoria-ideal-admin-operator-ui-ux-storyboard-deep-research.md` - future scope-orientation
  UI; treat UI scope surfaces as deferred.
- `brandbook/brand-book.md` - current brand/source of truth for operator-grade copy if docs wording is
  updated.

### External Primary References Consulted

- pgvector official README - cosine distance operator and cosine similarity expression.
- Pgvector.Ecto Query docs - `cosine_distance/2` query helper.
- Elixir `System` docs - monotonic time guidance for elapsed duration measurement.
- SemVer and Hex publish docs - context for avoiding surprise breaking behavior during a patch-style
  pre-1.0 closeout.
- RAG/eval references considered for citation abstention framing: OpenAI eval guidance, Ragas
  metrics, and Arize Phoenix RAG evaluation docs. They inform the SEED-009 boundary; Phase 45 keeps
  only the minimal deterministic fix.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Scoria.Knowledge.Scope` - explicit fail-closed scope normalization; use the same style for
  rejecting missing/invalid inputs instead of match-all or fake defaults.
- `Scoria.Eval.Verdict` - single threshold/gate spine; extend here rather than adding another local
  latency policy function.
- `Scoria.Eval.Score` / `ai_scores` metadata - existing sink for per-item latency without schema
  expansion.
- `Scoria.Knowledge.GroundingScore` - existing sink for deterministic grounding checks; no schema
  change needed for label-aware citation presence.
- `Scoria.KnowledgeCase` and `EvalCase`-style fixtures - focused lane proof without live providers.

### Established Patterns

- Scoria prefers explicit records and deterministic evidence over hidden/global state or fabricated
  defaults.
- Optional knowledge proof lives in the knowledge lane; default adoption proof should not require
  pgvector setup unless the optional lane is explicitly invoked.
- Phase 42 established strict score honesty: `nil`/unknown measurement means not scored or
  inconclusive, not a passing `0`.
- Phase 43 established tenant-filter-first query behavior; Phase 45's pgvector score work must not
  weaken that tenant isolation.
- v3.3 dashboard/design work means no new UI surface should be added for this closeout unless a
  proof requirement cannot be met any other way.

### Integration Points

- `Pgvector.similar_chunks/2` owns DB ranking and score projection before `Knowledge.retrieve/2`
  persists retrieval results.
- `Knowledge.score_grounding/2` composes `Grounding.score_citation_presence/1` into persisted
  grounding scores.
- `Chunker.Default.chunk/2` runs during `Knowledge.ingest_source/2`; offset/digest behavior feeds
  citation anchoring and repeat-ingest stability.
- `Runner`, `JudgeRunner`, and `OnlineScoring` write score metadata that `Verdict.compute/2` reads
  for `max_latency_ms`.
- `docs/operator_verification.md` and `docs/adoption_lanes.md` are the safest narrow docs surfaces
  for proof wording; the broader docs rewrite is SEED-005.

</code_context>

<specifics>
## Specific Ideas

- User asked Claude to pick recommendations automatically and not re-ask decision questions.
- User asked to research each decision through subagents and consider Elixir/Phoenix/Ecto idioms,
  successful cross-ecosystem lessons, DX, SRE/security, JTBD, UI/UX where applicable, prompt corpus,
  brand guidance, and cohesive architecture.
- Five subagent research passes were used:
  - real cosine score persistence
  - label-aware citation presence / abstention
  - chunker overlap cleanup
  - real latency gate
  - scope-doctrine cross-link and closeout proof
- The coherent recommendation is: **record real numbers, preserve fail-closed semantics, keep the
  public surface boring and Phoenix-native, document only the proof boundary, and defer deeper RAG/UI
  work to the already-planted seeds.**

</specifics>

<deferred>
## Deferred Ideas

- **Hex `0.1.3` publish / release cut** - belongs to SEED-005 / backlog 999.2 after this P0 gate is
  fixed and proved.
- **Full owns-vs-delegates adopter docs table** - belongs to SEED-005 docs/positioning overhaul.
- **Semantic abstention, faithfulness, answer relevance, precision/NDCG, reranking, and richer RAG
  eval labels** - belongs to SEED-009.
- **Real sliding-window/fixed-size overlap chunker** - belongs to SEED-009 as a separate chunker
  because it affects offsets, digests, and citation anchors.
- **Frozen subject trace latency as user-facing product latency** - possible future slice if dataset
  promotion snapshots it immutably; do not re-read mutable traces in Phase 45.
- **Persistent operator scope bar, tenant switcher, or new UI receipt** - belongs to SEED-013
  Operator IA Pivot.

### Reviewed Todos (not folded)

- `2026-06-20-add-approval-decision-history.md` - approval history UI follow-up; unrelated to
  correctness sweep and already delivered/stale in later UI work.
- `ci-policy-job-cache-key-mislabel.md` - CI copy/cache-key cleanup; unrelated to correctness sweep.
- `docker-dx-fleet-hardening.md` - fleet/local Docker DX hardening; unrelated to v3.4 fail-closed
  closeout.

</deferred>

---

*Phase: 45-Correctness sweep + fail-closed proof & closeout*
*Context gathered: 2026-07-07*
