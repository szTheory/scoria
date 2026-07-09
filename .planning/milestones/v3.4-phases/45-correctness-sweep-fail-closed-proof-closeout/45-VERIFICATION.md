---
phase: 45-correctness-sweep-fail-closed-proof-closeout
verified: 2026-07-07
status: passed
score: FIX-01..04 and DOC-01 focused proofs passed
behavior_unverified: 0 for Phase 45 scoped behavior
overrides_applied: 0
---

# Phase 45: Correctness Sweep + Fail-Closed Proof Verification Report

**Phase Goal:** Repair the remaining correctness sweep issues: real pgvector cosine score evidence, label-aware citation presence, non-overlapping default chunking, real eval latency evidence, and scope-doctrine cross-links.
**Verified:** 2026-07-07
**Status:** focused passed; full non-knowledge suite has unrelated residual failures recorded below.

## Goal Achievement

### Observable Truths

| Requirement | Truth | Status | Evidence |
|---|---|---|---|
| FIX-01 | Pgvector retrieval persists raw cosine similarity as `score = 1 - cosine_distance`. | VERIFIED | `lib/scoria/knowledge/backends/pgvector.ex` projects `1.0 - cosine_distance(chunk.embedding, ^query_vector)` and focused knowledge tests passed. |
| FIX-01 | Tenant visibility remains before source filters, vector ordering, and result limiting. | VERIFIED | Source scan found `Scope.visible_to(scope)` before nil-embedding filter and `cosine_distance` ordering. |
| FIX-01 | Nil-embedding chunks are not returned with fabricated score evidence. | VERIFIED | Source scan found `not is_nil(chunk.embedding)`; pgvector tests prove nil rows are excluded. |
| FIX-02 | Citation presence respects explicit answerability labels. | VERIFIED | `test/scoria/knowledge/grounding_test.exs` covers answerable/unanswerable matrix, string keys, alias, and missing-label behavior. |
| FIX-03 | `Chunker.Default` is non-overlapping and no fake overlap path remains. | VERIFIED | `lib/scoria/knowledge/chunker.ex` advances to `chunk.end_offset`; source scan found no active `:overlap` read in implementation. |
| FIX-04 | `max_latency_ms` uses recorded score metadata and fails closed on missing configured latency. | VERIFIED | `test/scoria/eval/verdict_test.exs` covers over-threshold, missing, invalid, and absent latency-policy cases. |
| FIX-04 | Offline, judge, and online score paths record measured latency metadata and measured run duration. | VERIFIED | `Scoria.Eval.Timing` is used by offline, judge, and online scoring paths; focused eval tests passed. |
| DOC-01 | Scope doctrine SSOT exists and docs cross-link eval, knowledge, dashboard, and closeout seams. | VERIFIED | `test/scoria/scope_doctrine_contract_test.exs` reads `.planning/PROJECT.md`, README, adoption lanes, operator verification, and active source paths. |

### Requirement Coverage

| Requirement | Description | Status | Evidence |
|---|---|---|---|
| FIX-01 | Replace fabricated pgvector component-sum score with real cosine evidence. | SATISFIED | Commit `b36953d5`; focused knowledge command passed, 26 tests overall for final focused knowledge set. |
| FIX-02 | Make citation presence answerability-label aware. | SATISFIED | Commit `03d9bef8`; grounding matrix covered by focused knowledge lane. |
| FIX-03 | Remove default chunker fake overlap behavior. | SATISFIED | Commit `03d9bef8`; chunker tests prove non-overlap and digest/offset stability. |
| FIX-04 | Replace hardcoded eval latency/duration zeroes with measured evidence and fail-closed verdict policy. | SATISFIED | Commits `1de6ea0d` and `57ad7336`; focused eval command passed, 28 tests. |
| DOC-01 | Cross-link P1-P6 scope doctrine SSOT from proof docs. | SATISFIED | `Scoria.ScopeDoctrineContractTest` passed, 3 tests. |

### Prohibition Checks

| Prohibition | Status | Evidence |
|---|---|---|
| Fabricated component-sum retrieval score must not remain in pgvector retrieval. | VERIFIED | Source scan for `score_chunk` and pgvector `Enum.sum` found no active pgvector hits. |
| Nil embedding must not become fake zero retrieval evidence. | VERIFIED | Active pgvector query filters `not is_nil(chunk.embedding)` before ordering and projection. |
| Missing configured latency must not be treated as zero. | VERIFIED | `Verdict.compute/2` returns `:inconclusive` for missing/invalid score latency when `max_latency_ms` is configured. |
| Hardcoded score latency zero must not remain in repaired active score paths. | VERIFIED | Source scan found no `latency_ms" => 0`, `latency_ms: 0`, or `duration_ms: 0` in repaired runner/judge/online paths. Measured latency can legitimately evaluate to `0` ms for fast local operations. |
| Default chunker overlap behavior must not remain. | VERIFIED | Source scan found `overlap` only in tests that prove ignored caller options; implementation docs state non-overlapping behavior. |

### Source Scan Results

| Scan | Result | Notes |
|---|---|---|
| `rg "Enum\\.sum|score_chunk|latency_ms\"\\s*=>\\s*0|duration_ms:\\s*0|:overlap|max\\(chunk\\.end_offset" ...` | PASS with unrelated hits | Only `average_score/1` and mean-score aggregation in eval verdict matched `Enum.sum`; neither is pgvector score fabrication. |
| `rg "Scope\\.visible_to|not is_nil\\(chunk\\.embedding\\)|cosine_distance|query_vector" lib/scoria/knowledge/backends/pgvector.ex -n` | PASS | Confirmed query vector, tenant scope, nil-embedding exclusion, cosine ordering, and cosine projection. |
| `rg "non-overlapping|overlap" lib/scoria/knowledge/chunker.ex test/scoria/knowledge_test.exs -n` | PASS | Implementation docs state non-overlapping; overlap appears only in regression tests. |
| `rg "Timing\\.measure|Timing\\.elapsed_ms|Timing\\.mark|max_latency_ms|parse_latency|latency_policy" lib/scoria/eval test/scoria/eval -n` | PASS | Confirmed timing helper use and fail-closed latency policy. |

## Commands Run

| Command | Result | Status |
|---|---|---|
| `mix test test/scoria/scope_doctrine_contract_test.exs --warnings-as-errors` before docs patch | 3 tests, 1 failure: expected missing README doctrine fragment. | EXPECTED RED |
| `mix test test/scoria/scope_doctrine_contract_test.exs --warnings-as-errors` | 3 tests, 0 failures. | PASS |
| `MIX_ENV=test mix test test/scoria/eval/timing_test.exs test/scoria/eval/verdict_test.exs test/scoria/eval/offline_runner_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/online_scoring_test.exs --warnings-as-errors` | 28 tests, 0 failures. | PASS |
| `MIX_ENV=test mix test.knowledge test/scoria/knowledge/pgvector_test.exs test/scoria/knowledge/retrieval_test.exs test/scoria/knowledge/grounding_test.exs test/scoria/knowledge_test.exs --warnings-as-errors` | 26 tests, 0 failures. | PASS |
| `mix test --warnings-as-errors` | 3 doctests, 1039 tests, 20 failures, 56 excluded. | FAIL - residual outside Phase 45 scope |
| `MIX_ENV=test mix test.knowledge --warnings-as-errors` | 54 tests, 0 failures, 1044 excluded. | PASS |
| `git diff --check` | No whitespace errors. | PASS |

The plan listed a direct `MIX_ENV=test mix test --include knowledge ...` command for focused knowledge. That path does not apply this repository's separate knowledge migrations and failed before Phase 45 tests could run. The final focused and full knowledge proofs used the repository's canonical `mix test.knowledge` lane.

## Residual Full-Suite Failures

The full non-knowledge suite failure is not introduced by the Phase 45 touched code paths. The retained output shows these unrelated categories:

| Area | Observed Failure | Phase 45 Impact |
|---|---|---|
| Dev Lab boundary contract | `test/scoria_web/dev_lab_boundary_test.exs` cannot read `.planning/phases/36-baseline-and-inventory/36-inventory.json`. | None; Phase 45 did not touch dev lab inventory or Phase 36 artifacts. |
| CI policy planning ledger | `test/scoria/ci_policy_contract_test.exs` expected `.planning/ROADMAP.md` to contain `v2.15`. | None; Phase 45 did not edit roadmap ledger history. |
| Coming-soon LiveView tests | `test/scoria_web/live/coming_soon_live_test.exs` default dashboard scope hook halts without redirect/session in several tests. | None; Phase 45 did not touch router, dashboard scope, or coming-soon LiveViews. |
| Remaining full-suite failures | Output was truncated by the runner after the completed summary. | Needs separate full-suite triage outside Phase 45; focused Phase 45 gates passed. |

## Human Verification Required

None for Phase 45 scoped behavior. A separate repo-health pass is required before claiming `mix test --warnings-as-errors` green.

## Gaps Summary

No Phase 45 FIX-01 through DOC-01 behavior gaps remain. The only verification gap is the unrelated broad non-knowledge suite residual recorded above.

---
_Verified: 2026-07-07_
_Verifier: Codex_
