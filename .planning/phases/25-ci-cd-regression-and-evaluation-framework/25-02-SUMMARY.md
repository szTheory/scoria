---
phase: 25-ci-cd-regression-and-evaluation-framework
plan: 02
subsystem: testing
tags: [exunit, req, req-cassette, bypass, evals]
requires:
  - phase: 25-ci-cd-regression-and-evaluation-framework
    provides: canonical EvalSpec, EvalRun, and Score persistence APIs
provides:
  - replay-only offline eval runner for sealed datasets
  - explicit fixture refresh task and cassette contract
  - immutable fixture key builder and committed canonical cassette
affects: [phase-25-03, ci, evals]
tech-stack:
  added: [req_llm, req, req_cassette, bypass]
  patterns: [replay-only ExUnit evals, committed cassette contract, explicit refresh-only maintenance lane]
key-files:
  created: [lib/scoria/eval/fixture_key.ex, lib/scoria/eval/runner.ex, lib/scoria/eval/refresh.ex, lib/mix/tasks/scoria.eval.refresh.ex, test/scoria/eval/offline_runner_test.exs, test/scoria/eval/replay_contract_test.exs, test/mix/tasks/scoria.eval.refresh_test.exs, test/fixtures/cassettes/eval/scoria_eval_fixture_prompt-v1_dataset-v1_eval-spec-v1_openai-gpt-4o-mini.json]
  modified: [mix.exs, test/support/eval_case.ex]
key-decisions:
  - "Kept `mix test` hard-wired to ReqCassette replay mode with no implicit record fallback."
  - "Stored fixture identity as a versioned key derived from prompt, dataset, eval spec, provider, and model."
  - "Made refresh a separate Mix task that rewrites cassettes explicitly instead of weakening CI determinism."
patterns-established:
  - "Offline replay runs persist EvalRun and Score rows by default."
  - "Committed cassettes may use `<dynamic>` placeholders for row IDs while still enforcing versioned contract fields."
requirements-completed: [EVAL-01, EVAL-02]
duration: 40m
completed: 2026-05-19
---

# Phase 25: CI/CD Regression & Evaluation Framework Summary

**Offline eval regressions now run as replay-only ExUnit flows with immutable fixture keys, a committed canonical cassette, and an explicit refresh task for maintainers.**

## Performance

- **Duration:** 40 min
- **Started:** 2026-05-19T13:30:00Z
- **Completed:** 2026-05-19T14:10:28Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Added direct `Req`/`ReqCassette`/`Bypass` dependency support plus replay helpers in `Scoria.EvalCase`.
- Implemented `Scoria.Eval.FixtureKey`, `Scoria.Eval.Runner`, and `Scoria.Eval.Refresh` so offline evals replay committed fixtures and persist run evidence.
- Added `mix scoria.eval.refresh`, a committed canonical cassette, and tests proving replay-only failure behavior, offline runner persistence, and refresh-to-runner compatibility.

## Task Commits

1. **Task 1: Install the Phase 25 eval dependency substrate and harden `Scoria.EvalCase`** - completed in the working tree during Wave 2 execution
2. **Task 2: Build the immutable cassette key and offline dataset runner** - completed in the working tree during Wave 2 execution
3. **Task 3: Add the explicit maintainer-only refresh workflow** - completed in the working tree during Wave 2 execution

## Files Created/Modified
- `mix.exs` - adds the replay and live-lane dependency substrate.
- `test/support/eval_case.ex` - exposes replay-only cassette helpers for eval-tagged tests.
- `lib/scoria/eval/fixture_key.ex` - immutable cassette identity builder and path resolver.
- `lib/scoria/eval/runner.ex` - offline replay runner that validates cassette contracts and persists run evidence.
- `lib/scoria/eval/refresh.ex` - explicit cassette refresh writer with top-level contract metadata.
- `lib/mix/tasks/scoria.eval.refresh.ex` - maintainer-only Mix task for fixture refresh.
- `test/scoria/eval/replay_contract_test.exs` - replay-only contract coverage.
- `test/scoria/eval/offline_runner_test.exs` - committed-cassette replay and persistence coverage.
- `test/mix/tasks/scoria.eval.refresh_test.exs` - refresh output compatibility coverage.
- `test/fixtures/cassettes/eval/scoria_eval_fixture_prompt-v1_dataset-v1_eval-spec-v1_openai-gpt-4o-mini.json` - canonical committed replay artifact.

## Decisions Made

- Used ReqCassette as the only offline replay mechanism instead of hand-rolled fixture matching.
- Kept the replay contract top-level metadata alongside valid ReqCassette interactions so the runner can validate versioned identity fields before replay starts.
- Allowed `<dynamic>` placeholders for runtime-generated row IDs in committed fixtures while still enforcing prompt/dataset/spec version and provider/model identity.

## Deviations from Plan

### Auto-fixed Issues

**1. Dependency scope conflict for `req`**
- **Found during:** Task 1 verification
- **Issue:** `req` could not be marked `only: :test` because `req_llm` and `llm_db` already depend on it in the runtime graph.
- **Fix:** Promoted `req` and `req_llm` to direct runtime deps while keeping `req_cassette` and `bypass` test-only.
- **Files modified:** `mix.exs`
- **Verification:** `mix deps.tree`, targeted replay test lane

**2. Canonical fixture mismatch with Req default headers**
- **Found during:** Task 2 verification
- **Issue:** The hand-authored canonical cassette did not include Req’s default request headers, so replay matching failed.
- **Fix:** Updated the committed cassette request headers to match Req’s actual replay shape.
- **Files modified:** `test/fixtures/cassettes/eval/scoria_eval_fixture_prompt-v1_dataset-v1_eval-spec-v1_openai-gpt-4o-mini.json`
- **Verification:** `mix test test/scoria/eval/replay_contract_test.exs test/scoria/eval/offline_runner_test.exs test/mix/tasks/scoria.eval.refresh_test.exs`

---

**Total deviations:** 2 auto-fixed
**Impact on plan:** Necessary for correctness and deterministic replay. No scope creep.

## Issues Encountered

- The first Wave 2 executor attempt stalled after partial dependency edits, so the replay lane was completed inline from the local plan and installed dependency sources.

## User Setup Required

None - no external service configuration required for the offline lane.

## Next Phase Readiness

- Plan `25-03` can now reuse `req_llm`, the explicit fixture identity model, and the shared run persistence APIs for live judge execution.
- The offline lane now provides deterministic fixtures and durable run evidence that future release-comparison work can consume directly.

---
*Phase: 25-ci-cd-regression-and-evaluation-framework*
*Completed: 2026-05-19*
