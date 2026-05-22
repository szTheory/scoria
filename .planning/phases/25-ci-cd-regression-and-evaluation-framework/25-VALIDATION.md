---
phase: 25
slug: ci-cd-regression-and-evaluation-framework
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-19
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for deterministic eval persistence, replay-only regression, and explicit live judge execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test --only eval` |
| **Full suite command** | `mix test.adoption && mix test && mix test.knowledge` |
| **Estimated runtime** | ~30 seconds for targeted eval commands; full CI lane remains longer |

---

## Sampling Rate

- **After every task commit:** Run the narrowest targeted `mix test` command listed below for the touched plan.
- **After every plan wave:** Run `mix test`.
- **Before `$gsd-verify-work`:** `mix test.adoption && mix test && mix test.knowledge` must be green.
- **Max feedback latency:** 30 seconds for targeted eval commands.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | EVAL-04 | T-25-01 / T-25-02 / T-25-03 | Eval runs and score rows attach only to the canonical `ai_eval_datasets` lineage and store explicit run/evidence facts. | integration | `mix test test/scoria/eval/eval_run_persistence_test.exs` | ❌ W0 | ⬜ pending |
| 25-01-02 | 01 | 1 | EVAL-04 | T-25-02 | `EvalSpec` persists typed subject/scorer/threshold fields and immutable version truth without mutable aliases. | unit | `mix test test/scoria/eval/eval_run_persistence_test.exs` | ❌ W0 | ⬜ pending |
| 25-01-03 | 01 | 1 | EVAL-04 | T-25-02 / T-25-03 | Run headers and per-item evidence rows persist explicit provider, cassette, verdict, and explanation fields without chain-of-thought blobs. | integration | `mix test test/scoria/eval/eval_run_persistence_test.exs` | ❌ W0 | ⬜ pending |
| 25-02-01 | 02 | 2 | EVAL-01 / EVAL-02 | T-25-04 | `Scoria.EvalCase` keeps eval-tagged tests replay-only and rejects hidden live network paths. | unit | `mix test test/scoria/eval/replay_contract_test.exs` | ❌ W0 | ⬜ pending |
| 25-02-02 | 02 | 2 | EVAL-01 / EVAL-02 / EVAL-04 | T-25-04 / T-25-05 | Offline runner requires sealed datasets, derives immutable fixture keys, fails on missing fixtures, and persists offline run evidence. | integration | `mix test test/scoria/eval/offline_runner_test.exs` | ❌ W0 | ⬜ pending |
| 25-02-03 | 02 | 2 | EVAL-02 | T-25-05 / T-25-06 | Refresh remains an explicit maintainer-only command and never becomes a fallback path for `mix test`. | unit | `mix test test/mix/tasks/scoria.eval.refresh_test.exs` | ❌ W0 | ⬜ pending |
| 25-03-01 | 03 | 3 | EVAL-03 / EVAL-04 | T-25-07 / T-25-08 / T-25-09 | Live judge execution uses explicit structured verdict fields and persists the same canonical run/evidence truth model. | integration | `mix test test/scoria/eval/judge_runner_test.exs` | ❌ W0 | ⬜ pending |
| 25-03-02 | 03 | 3 | EVAL-03 | T-25-07 | `mix scoria.eval` stays an explicit online lane with required CLI identity flags and no CI/test coupling. | unit | `mix test test/mix/tasks/scoria.eval_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/eval/eval_run_persistence_test.exs` — persistence convergence, typed spec schema, and durable run/evidence row coverage for EVAL-04.
- [ ] `test/scoria/eval/replay_contract_test.exs` — replay-only default contract and missing-cassette failure coverage for EVAL-02.
- [ ] `test/scoria/eval/offline_runner_test.exs` — sealed dataset execution, immutable fixture keying, and persisted offline run coverage for EVAL-01/EVAL-02/EVAL-04.
- [ ] `test/mix/tasks/scoria.eval.refresh_test.exs` — explicit maintainer refresh task surface coverage for EVAL-02.
- [ ] `test/scoria/eval/judge_runner_test.exs` — structured live judge verdict persistence coverage for EVAL-03/EVAL-04.
- [ ] `test/mix/tasks/scoria.eval_test.exs` — explicit online command parsing and identity summary coverage for EVAL-03.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Inspect a refreshed replay artifact for normalized provider payload shape and immutable metadata | EVAL-02 | Repo tests can prove presence and failure behavior, but a maintainer should spot-check that the committed artifact omits transport noise and includes the expected key components. | Run `mix scoria.eval.refresh --dataset <id> --eval-spec <id> --prompt <id> --provider <provider> --model <model>`, then inspect the written fixture metadata for prompt version, dataset version, eval spec version, provider, model, and fixture hash. |
| Confirm the live judge lane is operational only when explicit provider credentials are present | EVAL-03 | CI should not depend on live credentials, so one human-triggered run should validate the non-test path in a controlled environment. | With valid provider configuration, run `mix scoria.eval --dataset <id> --eval-spec <id> --prompt <id> --provider <provider> --model <model>` and confirm the command prints the selected identities and persists a completed `EvalRun`. |

---

## Validation Sign-Off

- [x] All planned tasks have automated verification commands or explicit Wave 0 test files.
- [x] Sampling continuity is preserved across all plans; no execution wave relies on more than two consecutive unchecked tasks.
- [x] Wave 0 coverage exists for every planned Phase 25 test surface.
- [x] No watch-mode flags appear in the verification contract.
- [x] Feedback latency is bounded to targeted ExUnit commands and current CI lanes.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** pending
