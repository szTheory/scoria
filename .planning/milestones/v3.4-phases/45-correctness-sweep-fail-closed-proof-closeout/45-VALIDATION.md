---
phase: 45
slug: correctness-sweep-fail-closed-proof-closeout
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-07
updated: 2026-07-09T18:37:29Z
---

# Phase 45 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix 1.19.5 |
| Config file | `test/test_helper.exs`; knowledge lane uses `Scoria.KnowledgeCase` and pgvector bootstrap helpers |
| Quick run command | `mix test test/scoria/eval/verdict_test.exs test/scoria/eval/offline_runner_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/online_scoring_test.exs --warnings-as-errors` |
| Knowledge run command | `mix test.knowledge --warnings-as-errors` after pgvector readiness check |
| Full suite command | `mix test --warnings-as-errors` plus `mix test.knowledge --warnings-as-errors` |
| Estimated runtime | TBD by executor after first full run |

---

## Sampling Rate

- **After every task commit:** Run the smallest changed-file command from the requirement map below.
- **After every plan wave:** Run `mix test --warnings-as-errors` and `mix test.knowledge --warnings-as-errors`.
- **Before `/gsd:verify-work`:** Pgvector readiness check, full non-knowledge suite, full knowledge lane, and source scans for fake-score/fake-latency leftovers must pass.
- **Max feedback latency:** Prefer under 90 seconds for changed-file checks; record measured runtime if longer.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 45-00-01 | 45-01 | 0 | FIX-01 | T-45-01 | Retrieval ranking preserves Phase 43 tenant isolation while persisting real cosine similarity | integration | `MIX_ENV=test mix test.knowledge test/scoria/knowledge/pgvector_test.exs test/scoria/knowledge/retrieval_test.exs --warnings-as-errors` | yes | green |
| 45-00-02 | 45-02 | 0 | FIX-02 | T-45-02 | Correct explicit abstention is not penalized; missing answerability label keeps legacy fail behavior | unit/integration | `MIX_ENV=test mix test.knowledge test/scoria/knowledge/grounding_test.exs --warnings-as-errors` | yes | green |
| 45-00-03 | 45-02 | 0 | FIX-03 | - | Default chunking is deterministic and non-overlapping; dead overlap no-op is removed | unit/source contract | `MIX_ENV=test mix test.knowledge test/scoria/knowledge_test.exs --warnings-as-errors` | yes | green |
| 45-00-04 | 45-03, 45-04 | 0 | FIX-04 | T-45-03 | Latency gate uses measured latency and fails closed as inconclusive when required latency evidence is missing | unit/integration | `MIX_ENV=test mix test test/scoria/eval/timing_test.exs test/scoria/eval/verdict_test.exs test/scoria/eval/offline_runner_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/online_scoring_test.exs --warnings-as-errors` | yes | green |
| 45-00-05 | 45-05 | 0 | DOC-01 | - | Scope doctrine SSOT remains in PROJECT.md and fix rationale cross-links back to it | source/doc contract | `mix test test/scoria/scope_doctrine_contract_test.exs --warnings-as-errors` | yes | green |

---

## Wave 0 Requirements

- [x] Extend `test/scoria/knowledge/pgvector_test.exs` for exact, orthogonal, nil, and dimension behavior.
- [x] Extend `test/scoria/knowledge/retrieval_test.exs` for persisted score matching backend cosine score.
- [x] Extend `test/scoria/knowledge/grounding_test.exs` for answerability matrix and details.
- [x] Extend `test/scoria/knowledge_test.exs` for non-overlap offset and digest stability.
- [x] Extend `test/scoria/eval/verdict_test.exs` for over-threshold and missing/invalid latency.
- [x] Extend `test/scoria/eval/offline_runner_test.exs`, `test/scoria/eval/judge_runner_test.exs`, and `test/scoria/eval/online_scoring_test.exs` for measured latency and duration persistence through deterministic seams.
- [x] Add `test/scoria/scope_doctrine_contract_test.exs` doc/source contract for DOC-01.
- [x] Add source-scan verification that active code no longer contains component-sum scoring, `score_chunk(nil, _)` fake zero, hardcoded scorer latency `0`, or the chunker no-op expression.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None expected | All | Research found existing automated test surfaces for every phase behavior | Prefer automated ExUnit/source-scan checks in plans |

---

## Validation Audit 2026-07-09

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 5 requirements |
| Escalated | 0 |

Fresh closeout evidence:

- `MIX_ENV=test mix test.knowledge --warnings-as-errors` passed with 54 tests, 0 failures.
- `45-VERIFICATION.md` records focused eval, knowledge, doctrine, source-scan, and residual full-suite evidence.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is recorded if changed-file checks exceed 90 seconds.
- [x] `nyquist_compliant: true` set in frontmatter after Wave 0 is complete and every requirement has automated coverage.

**Approval:** complete
