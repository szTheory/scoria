---
phase: 42
slug: eval-fails-closed
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-09
updated: 2026-07-09T18:37:29Z
---

# Phase 42 - Validation Strategy

Retrospective Nyquist validation ledger reconstructed from Phase 42 plans, summaries, and `42-VERIFICATION.md`.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix |
| Config file | `test/test_helper.exs`, `config/test.exs` |
| Quick run command | `mix test test/scoria/eval/verdict_test.exs test/scoria/eval/score_changeset_test.exs test/scoria_web/eval_vocabulary_test.exs --warnings-as-errors` |
| Full focused command | `mix test test/scoria/eval/verdict_test.exs test/scoria/eval/score_changeset_test.exs test/scoria_web/eval_vocabulary_test.exs test/scoria/eval/subject_output_test.exs test/scoria/eval/dataset_promotion_test.exs test/scoria/eval/scorers/exact_match_test.exs test/scoria/eval/offline_runner_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/online_scoring_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/runtime/release_gate_test.exs --warnings-as-errors` |
| Verified result | 63 tests, 0 failures recorded in `42-VERIFICATION.md` |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 42-01 | 42-01 | 1 | EVAL-03 | Verdict spine treats empty/all-unscored results as inconclusive and supports `not_scored`. | unit | `mix test test/scoria/eval/verdict_test.exs test/scoria/eval/score_changeset_test.exs test/scoria_web/eval_vocabulary_test.exs --warnings-as-errors` | yes | green |
| 42-02 | 42-02 | 1 | EVAL-01 | Dataset promotion captures real subject output and `SubjectOutput.resolve/2` refuses expected-output fallback. | unit/integration | `mix test test/scoria/eval/subject_output_test.exs test/scoria/eval/dataset_promotion_test.exs --warnings-as-errors` | yes | green |
| 42-03 | 42-03 | 1 | EVAL-02 | ExactMatch compares actual output with expectation and emits not-scored when it cannot compare. | unit | `mix test test/scoria/eval/scorers/exact_match_test.exs --warnings-as-errors` | yes | green |
| 42-04 | 42-04 | 2 | EVAL-01, EVAL-02, EVAL-03 | Offline runner dispatches real scorers, persists Score rows, and computes fail-closed verdicts. | integration | `mix test test/scoria/eval/offline_runner_test.exs test/scoria/eval/scorers/exact_match_test.exs test/scoria/eval/verdict_test.exs test/scoria/eval/score_changeset_test.exs --warnings-as-errors` | yes | green |
| 42-05 | 42-05 | 2 | EVAL-01, EVAL-03 | Judge runner uses captured Actual output and skips/not-scores empty capture instead of self-grading. | integration | `mix test test/scoria/eval/judge_runner_test.exs test/scoria/eval/subject_output_test.exs test/scoria/eval/verdict_test.exs --warnings-as-errors` | yes | green |
| 42-06 | 42-06 | 3 | EVAL-05 | Online scoring emits deterministic negatives only and never fabricates clean-trace pass rows. | integration | `mix test test/scoria/eval/online_scoring_test.exs test/scoria/eval/campaign_worker_test.exs --warnings-as-errors` | yes | green |
| 42-07 | 42-07 | 3 | EVAL-04 | ReleaseGate consults latest completed `threshold_verdict` and blocks failed/inconclusive/unknown verdicts. | integration | `mix test test/scoria/runtime/release_gate_test.exs --warnings-as-errors` | yes | green |

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | All | Every Phase 42 milestone requirement has deterministic ExUnit coverage and a passed verification report. | Not applicable |

## Validation Audit 2026-07-09

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 5 requirements |
| Escalated | 0 |

## Validation Sign-Off

- [x] All tasks have automated verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 coverage exists retrospectively through the Phase 42 focused behavior gate.
- [x] No watch-mode flags.
- [x] Feedback latency stayed inside normal focused ExUnit bounds.
- [x] `nyquist_compliant: true` set in frontmatter after all requirement coverage was verified.

**Approval:** complete
