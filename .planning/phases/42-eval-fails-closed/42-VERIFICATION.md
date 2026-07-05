---
phase: 42-eval-fails-closed
verified: 2026-07-05T00:08:04Z
status: passed
score: 31/31 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 42: Eval fails closed Verification Report

**Phase Goal:** Scoria's eval engine fails CLOSED - no run is ever reported green without a real subject output scored by a real deterministic scorer, and the release gate consults the verdict instead of the prompt's draft flag.
**Verified:** 2026-07-05T00:08:04Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Offline/judge eval executes or replays real subject output; mismatches yield failed/not_scored, never passed. | VERIFIED | `DatasetPromotion` captures `Workflows.Step.result_envelope["output"]` (`lib/scoria/eval/dataset_promotion.ex:99`), `SubjectOutput.resolve/2` returns only non-empty capture (`lib/scoria/eval/subject_output.ex:16`), offline mismatch fails (`test/scoria/eval/offline_runner_test.exs:35`), judge Actual uses capture not expectation (`test/scoria/eval/judge_runner_test.exs:24`). |
| 2 | At least one real deterministic scorer compares actual vs expected output through the existing Score sink. | VERIFIED | `ExactMatch.score/3` returns binary pass/fail or `{:not_scored, reason}` (`lib/scoria/eval/scorers/exact_match.ex:7`), offline runner dispatches `exact_match` to that scorer (`lib/scoria/eval/runner.ex:133`), scores persist via `Score.changeset` (`lib/scoria/eval.ex:588`). |
| 3 | No real scorer/no score emits `not_scored`; verdict and gate fail closed instead of green by default. | VERIFIED | `Verdict.compute/2` returns `:inconclusive` for empty/all-unscored/strict coverage gaps (`lib/scoria/eval/verdict.ex:8`), `Score.changeset/2` permits nil score only for `not_scored` (`lib/scoria/eval/score.ex:46`), offline/judge empty capture tests assert `inconclusive` (`test/scoria/eval/offline_runner_test.exs:48`, `test/scoria/eval/judge_runner_test.exs:62`). |
| 4 | `Runtime.ReleaseGate` blocks when `threshold_verdict` is not passing. | VERIFIED | `ReleaseGate.check/1` looks up latest completed eval run and calls `Verdict.blocks_release?/1` (`lib/scoria/runtime/release_gate.ex:22`), tests cover passed allow, failed/inconclusive/unknown block, strict no-verdict mode, online exclusion, offline inclusion, and DB error propagation (`test/scoria/runtime/release_gate_test.exs:36`). |
| 5 | Online scoring no longer fabricates pass/fail from `sample_reason == "policy_trigger"` alone. | VERIFIED | Online deterministic scoring emits only negatives or `[]` (`lib/scoria/eval/online_scoring.ex:239`), inspects span ERROR and step output (`lib/scoria/eval/online_scoring.ex:410`), routes verdict through `Verdict.compute/2` (`lib/scoria/eval/online_scoring.ex:397`), and tests prove clean traces persist no deterministic pass row (`test/scoria/eval/online_scoring_test.exs:87`). |

**Score:** 31/31 must-haves verified, including 5 roadmap success criteria and 26 plan-frontmatter truths. Behavior-unverified: 0.

### Plan Truth Rollup

| Plan | Truths | Status | Evidence |
|---|---:|---|---|
| 42-01 Verdict spine | 5 | VERIFIED | `VerdictTest`, `ScoreChangesetTest`, `EvalVocabularyTest`; direct code check of `Verdict`, `Score`, UI tone/copy. |
| 42-02 Subject output capture | 3 | VERIFIED | `DatasetPromotionTest`, `SubjectOutputTest`; direct code check of migration, schema, capture source, sealed guard. |
| 42-03 ExactMatch scorer | 3 | VERIFIED | `ExactMatchTest`; direct code check found binary exact-match behavior and no fuzzy/semantic implementation. |
| 42-04 Offline runner | 3 | VERIFIED | `OfflineRunnerTest`; direct code check of `SubjectOutput`, `ExactMatch`, `Verdict.compute`, and `not_scored` fallback wiring. |
| 42-05 Judge runner | 3 | VERIFIED | `JudgeRunnerTest`; direct code check confirmed self-grade helper deleted and judge prompt Actual comes from capture. |
| 42-06 Online scoring | 4 | VERIFIED | `OnlineScoringTest`, `CampaignWorkerTest`; direct code check of negative-signal detector, Step/span loads, no deterministic pass fabrication. |
| 42-07 ReleaseGate | 5 | VERIFIED | `ReleaseGateTest`; direct code check of verdict lookup, allowlist, telemetry, strict mode, online exclusion, and index migration. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/scoria/eval/verdict.ex` | Central fail-closed verdict spine. | VERIFIED | 79 substantive lines; `compute/2`, `blocks_release?/1`, `item_scored?/1`, nil-safe scored subset math. |
| `lib/scoria/eval/score.ex` | `not_scored` permits nil score; other statuses require score. | VERIFIED | Conditional `require_score_unless_not_scored/1` at lines 52-58; behavior tested. |
| `lib/scoria_web/ui.ex`, `lib/scoria_web/copy.ex` | Amber tone and curated labels for `not_scored`/`inconclusive`. | VERIFIED | UI tone lines 24-48; copy labels lines 42-48; behavior tested. |
| `lib/scoria/eval/dataset_item.ex` and capture migration | Capture columns on dataset items. | VERIFIED | Schema fields and cast list at lines 10-27; migration `20260704221053_add_dataset_item_captured_output.exs`. |
| `lib/scoria/eval/dataset_promotion.ex` | Promotion-time capture from `Workflows.Step.result_envelope["output"]`. | VERIFIED | `Repo.get(Step, workflow_step_id)` and output extraction at lines 99-134; tests assert not from checkpoint/recorded outcome. |
| `lib/scoria/eval/subject_output.ex` | Single resolver for offline and judge modes. | VERIFIED | `:offline_replay` and `:live_judge` both delegate to frozen capture; empty capture returns `{:not_scored, :empty_capture}`. |
| `lib/scoria/eval/scorers/exact_match.ex` | Deterministic exact-match scorer. | VERIFIED | Binary pass/fail and explicit not_scored paths; no Grounding warning bands or fuzzy matching. |
| `lib/scoria/eval/runner.ex` | Offline runner scorer dispatch and verdict wiring. | VERIFIED | `SubjectOutput.resolve`, `ExactMatch.score`, unknown scorer not_scored, `Verdict.compute`; no hardcoded pass rows. |
| `lib/scoria/eval/judge_runner.ex` | Judge runner capture Actual and verdict wiring. | VERIFIED | Uses `SubjectOutput.resolve`; skips judge on empty capture; persists `Verdict.compute`; no `build_subject_output` self-grade helper. |
| `lib/scoria/eval/online_scoring.ex` | Online negative-signal detector and Verdict-backed summary. | VERIFIED | Preloads spans, loads Step output, emits failed negatives or empty base scores, uses `Verdict.compute`, promotion requires non-empty all-passed scores. |
| `lib/scoria/runtime/release_gate.ex`, config, index migration | Verdict-consulting release gate. | VERIFIED | `Verdict.blocks_release?/1`, no-verdict telemetry/strict mode, online metadata exclusion, index `[:prompt_template_id, :status, "inserted_at DESC"]`. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `runner.ex` | `SubjectOutput.resolve/2` | `score_dataset_item/6` | VERIFIED | Offline replay grades frozen capture and converts empty capture to `not_scored`. |
| `runner.ex` | `ExactMatch.score/3` | scorer_kind `"exact_match"` dispatch | VERIFIED | ExactMatch result maps flow into `Eval.record_eval_scores/2`; unknown scorer kinds become `not_scored`. |
| `runner.ex` | `Verdict.compute/2` | eval-run completion | VERIFIED | Completed run `threshold_verdict` is derived from persisted scores. |
| `judge_runner.ex` | `SubjectOutput.resolve/2` | `build_score_attrs/7` | VERIFIED | Actual prompt body is capture JSON; empty capture skips the judge. |
| `judge_runner.ex` | `Verdict.compute/2` | `run_live/1` and `run_existing/2` completion | VERIFIED | No local threshold copy remains. |
| `online_scoring.ex` | `Verdict.compute/2` | `threshold_verdict/2` | VERIFIED | Structured `gsd verify.key-links` confirmed the 42-06 link, 1/1. |
| `release_gate.ex` | `Verdict.blocks_release?/1` | latest completed eval-run lookup | VERIFIED | Gate uses allowlist semantics; tests prove only `"passed"` allows. |
| `release_gate.ex` | `EvalRun`/`EvalCampaign` | query excluding online scoring source | VERIFIED | Left join filters `campaign.metadata["source"] == "online_scoring"`; tests prove online exclusion and offline inclusion. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `DatasetPromotion` | `captured_output` | `Workflows.Step.result_envelope["output"]` via `workflow_step_id` | Yes; non-empty step output is stored with sha/timestamp. | FLOWING |
| `SubjectOutput` | resolved actual output | `DatasetItem.captured_output` | Yes; only non-empty capture returns `{:ok, output}`. | FLOWING |
| `Runner` | exact-match score attrs | `SubjectOutput` actual + `DatasetItem.expected_output` | Yes; mismatch fails and empty capture is `not_scored`. | FLOWING |
| `JudgeRunner` | judge Actual prompt | `SubjectOutput` actual | Yes; capture is JSON-encoded into Actual; expected remains separate. | FLOWING |
| `OnlineScoring` | negative signals and summary | `Trace.spans`, `Workflows.Step.result_envelope["output"]`, optional judge scores | Yes; reference-free checks emit only failed negatives or no base scores. | FLOWING |
| `ReleaseGate` | release decision | Latest completed `EvalRun.threshold_verdict` excluding online campaigns | Yes; only persisted `"passed"` allows release. | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase 42 focused behavior gate | `mix test test/scoria/eval/verdict_test.exs test/scoria/eval/score_changeset_test.exs test/scoria_web/eval_vocabulary_test.exs test/scoria/eval/subject_output_test.exs test/scoria/eval/dataset_promotion_test.exs test/scoria/eval/scorers/exact_match_test.exs test/scoria/eval/offline_runner_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/online_scoring_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/runtime/release_gate_test.exs --warnings-as-errors` | 63 tests, 0 failures. | PASS |
| Build gate | `make build` | Accepted from orchestrator evidence: passed after all Phase 42 plans. | ACCEPTED |
| Structured key-link verifier | `gsd-tools query verify.key-links` over all Phase 42 plans | 42-06 structured key link verified 1/1; other plan links were free-form and verified manually above. | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| Phase 42 probes | Probe discovery in `scripts/**/tests/probe-*.sh` and phase plan/summary references | No phase-declared or conventional probes found for this eval phase. | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| EVAL-01 | 42-02, 42-04, 42-05 | Offline/judge eval uses real subject output; expected-answer shortcut removed. | SATISFIED | Capture source is Step output; `SubjectOutput.resolve/2` refuses expected fallback; offline mismatch fails; judge Actual test refutes expected-as-Actual. |
| EVAL-02 | 42-03, 42-04 | Real deterministic scorer compares actual output vs expectation and writes through Score sink. | SATISFIED | `ExactMatch.score/3` implemented and offline runner dispatches to it; `Eval.record_eval_scores/2` persists through `Score.changeset/2`. |
| EVAL-03 | 42-01, 42-04, 42-05 | No scorer/no score yields not_scored and inconclusive/failing verdicts, never green. | SATISFIED | `Verdict.compute/2` empty/all-unscored/coverage tests; offline unknown scorer and judge empty capture tests persist `not_scored` and `inconclusive`. |
| EVAL-04 | 42-07 | ReleaseGate consults `threshold_verdict`, not only draft status. | SATISFIED | `ReleaseGate.check/1` calls `Verdict.blocks_release?/1`; tests cover passed allow, failed/inconclusive/unknown block, strict mode, telemetry, online exclusion, and DB errors. |
| EVAL-05 | 42-06 | Online scoring stops fabricating pass/fail from policy trigger alone. | SATISFIED | Online scoring inspects policy trigger, ERROR spans, and Step output; clean traces produce no deterministic pass and only real judge scores can promote. |

No orphaned Phase 42 requirements were found in `.planning/REQUIREMENTS.md`; EVAL-01 through EVAL-05 are all claimed by Phase 42 plans and verified above.

### Prohibition Checks

| Prohibition | Status | Evidence |
|---|---|---|
| Empty or all-not-scored score sets must never pass. | VERIFIED | `Verdict.compute/2` returns `:inconclusive`; tests at `verdict_test.exs:7` and `:11`. |
| Missing measurement must not become `0.0`; `not_scored` means `score: nil`. | VERIFIED | `Score.changeset/2` accepts nil score only for `not_scored`; offline/judge/online not_scored attrs set `score: nil`. |
| Capture must not come from `checkpoint_output` or `recorded_outcome`. | VERIFIED | Promotion tests assert captured output differs from those maps; implementation reads Step result envelope. |
| Empty captured output must not read as actual. | VERIFIED | `SubjectOutput.resolve/2` returns `{:not_scored, :empty_capture}` for nil/empty captures. |
| ExactMatch must not use fuzzy/semantic/warning-band scoring. | VERIFIED | Scorer has only normalized exact string and whole-map equality; grep found no fuzzy/semantic/Grounding terms. |
| Offline runner must not hardcode passed/1.0. | VERIFIED | `record_scores` dispatches scorer kinds; grep found no hardcoded pass branch in runner. |
| Judge runner must not self-grade `expected_output["answer"]`. | VERIFIED | `build_subject_output` is absent; prompt Actual is built from `subject_output`. |
| Online scoring must not persist deterministic_rule/passed for a clean trace. | VERIFIED | Clean-trace tests refute deterministic pass rows; implementation returns `[]` for clean deterministic scores. |
| ReleaseGate must not use block-list, prompt_version, runner_mode, or rescue-to-ok. | VERIFIED | Gate calls `Verdict.blocks_release?/1`, has no prompt_version/runner_mode filters, and DB error propagation is tested. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `lib/scoria_web/ui.ex` | 564, 597, 894 | `placeholder` | INFO | Benign command-palette placeholder attr and skeleton docs in pre-existing UI component file; not an eval stub and not user-visible fake data. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in Phase 42 modified files.

### Human Verification Required

None. All behavior-dependent Phase 42 truths are covered by deterministic tests that passed in this verification run.

### Gaps Summary

No gaps found. Phase 42's roadmap success criteria and plan-frontmatter must-haves are implemented, wired, and behaviorally exercised. The phase goal is achieved.

---

_Verified: 2026-07-05T00:08:04Z_
_Verifier: the agent (gsd-verifier)_
