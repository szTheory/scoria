---
phase: 45
slug: correctness-sweep-fail-closed-proof-closeout
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-07
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
| 45-00-01 | TBD | 0 | FIX-01 | T-45-01 | Retrieval ranking preserves Phase 43 tenant isolation while persisting real cosine similarity | integration | `SCORIA_TEST_INCLUDE_KNOWLEDGE=true mix test test/scoria/knowledge/pgvector_test.exs test/scoria/knowledge/retrieval_test.exs --warnings-as-errors` | yes; new cases needed | pending |
| 45-00-02 | TBD | 0 | FIX-02 | T-45-02 | Correct explicit abstention is not penalized; missing answerability label keeps legacy fail behavior | unit/integration | `mix test test/scoria/knowledge/grounding_test.exs --warnings-as-errors` | yes; new cases needed | pending |
| 45-00-03 | TBD | 0 | FIX-03 | - | Default chunking is deterministic and non-overlapping; dead overlap no-op is removed | unit/source contract | `mix test test/scoria/knowledge_test.exs --warnings-as-errors` | yes; new cases needed | pending |
| 45-00-04 | TBD | 0 | FIX-04 | T-45-03 | Latency gate uses measured latency and fails closed as inconclusive when required latency evidence is missing | unit/integration | `mix test test/scoria/eval/verdict_test.exs test/scoria/eval/offline_runner_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/online_scoring_test.exs --warnings-as-errors` | yes; new cases needed | pending |
| 45-00-05 | TBD | 0 | DOC-01 | - | Scope doctrine SSOT remains in PROJECT.md and fix rationale cross-links back to it | source/doc contract | `mix test test/scoria/scope_doctrine_contract_test.exs --warnings-as-errors` | no; create in Wave 0 if planner chooses test contract | pending |

---

## Wave 0 Requirements

- [ ] Extend `test/scoria/knowledge/pgvector_test.exs` for exact, orthogonal, nil, and dimension behavior.
- [ ] Extend `test/scoria/knowledge/retrieval_test.exs` for persisted score matching backend cosine score.
- [ ] Extend `test/scoria/knowledge/grounding_test.exs` for answerability matrix and details.
- [ ] Extend `test/scoria/knowledge_test.exs` for non-overlap offset and digest stability.
- [ ] Extend `test/scoria/eval/verdict_test.exs` for over-threshold and missing/invalid latency.
- [ ] Extend `test/scoria/eval/offline_runner_test.exs`, `test/scoria/eval/judge_runner_test.exs`, and `test/scoria/eval/online_scoring_test.exs` for measured latency and duration persistence through deterministic seams.
- [ ] Add `test/scoria/scope_doctrine_contract_test.exs` or equivalent doc/source contract for DOC-01.
- [ ] Add source-scan verification that active code no longer contains component-sum scoring, `score_chunk(nil, _)` fake zero, hardcoded scorer latency `0`, or the chunker no-op expression.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None expected | All | Research found existing automated test surfaces for every phase behavior | Prefer automated ExUnit/source-scan checks in plans |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is recorded if changed-file checks exceed 90 seconds.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 is complete and every requirement has automated coverage.

**Approval:** pending
