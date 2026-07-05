---
phase: 42-eval-fails-closed
plan: 07
subsystem: eval
tags: [eval, release-gate, verdict, telemetry, ecto]

requires:
  - phase: 42-01
    provides: Scoria.Eval.Verdict passed-only release-blocking semantics
  - phase: 42-06
    provides: online-scoring campaign metadata source marker
provides:
  - ReleaseGate verdict consult using Scoria.Eval.Verdict.blocks_release?/1
  - Ungated release telemetry for prompts without completed eval verdicts
  - Optional require_eval_verdict strict mode
  - Composite latest-completed EvalRun lookup index
  - Deterministic release-gate regression coverage
affects: [phase-42, release-gate, eval-runners, runtime-governance]

tech-stack:
  added: []
  patterns:
    - Latest completed EvalRun lookup by prompt_template_id and status
    - Online scoring exclusion by EvalCampaign metadata source
    - Passed-only verdict allowlist via Scoria.Eval.Verdict

key-files:
  created:
    - priv/repo/migrations/20260704235536_add_eval_runs_verdict_index.exs
  modified:
    - lib/scoria/runtime/release_gate.ex
    - config/config.exs
    - test/scoria/runtime/release_gate_test.exs

key-decisions:
  - "ReleaseGate treats completed nil, unknown, failed, and inconclusive verdicts as blocking because only persisted string \"passed\" is allowed."
  - "The lookup uses a left join to EvalCampaign so standalone and offline campaign eval runs count, while metadata source \"online_scoring\" runs are excluded."
  - "No completed eval verdict remains default-open for adopter compatibility, but emits [:scoria, :release_gate, :ungated] telemetry and can be made strict with require_eval_verdict."

patterns-established:
  - "Runtime release gating consumes Scoria.Eval.Verdict.blocks_release?/1 instead of duplicating verdict policy."
  - "Governance lookups do not rescue Repo errors into :ok; database errors propagate to avoid fake-allow behavior."

requirements-completed: [EVAL-04]

duration: 6 min
completed: 2026-07-04
status: complete
---

# Phase 42 Plan 07: ReleaseGate Verdict Consult Summary

**Runtime ReleaseGate now blocks non-passing completed eval verdicts with passed-only allowlist semantics, online-run exclusion, ungated telemetry, and an indexed lookup.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-04T23:53:17Z
- **Completed:** 2026-07-04T23:59:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added a latest completed `EvalRun` verdict lookup to `Scoria.Runtime.ReleaseGate`, preserving the draft check as the first clause.
- Routed release decisions through `Scoria.Eval.Verdict.blocks_release?/1`, so only `"passed"` allows release and any other completed verdict returns `{:error, {:eval_not_passing, verdict}}`.
- Added default-open no-verdict behavior with `[:scoria, :release_gate, :ungated]` telemetry and opt-in `config :scoria, require_eval_verdict: true` strict mode.
- Excluded online-scoring campaign runs via `campaign.metadata["source"] == "online_scoring"` while still counting standalone and offline campaign eval runs.
- Added the composite `ai_eval_runs (prompt_template_id, status, inserted_at DESC)` index and deterministic release-gate regression coverage.

## Task Commits

Each task was committed atomically:

1. **Task 1: ReleaseGate verdict consult** - `ebdadd68` (feat)
2. **Task 2: Composite index migration** - `5dc694a1` (feat)
3. **Task 3: ReleaseGate tests** - `5c23c09e` (test)

## Files Created/Modified

- `lib/scoria/runtime/release_gate.ex` - Adds the completed-verdict lookup, passed-only decision, online-campaign exclusion, ungated telemetry, and strict-mode branch.
- `config/config.exs` - Documents and defaults `require_eval_verdict: false`.
- `priv/repo/migrations/20260704235536_add_eval_runs_verdict_index.exs` - Adds idempotent create/drop callbacks for the latest-completed lookup index.
- `test/scoria/runtime/release_gate_test.exs` - Covers draft precedence, latest passed verdicts, non-passing verdict errors, no-verdict telemetry, strict mode, online exclusion, offline inclusion, and DB error propagation.

## Decisions Made

- Completed rows with nil or unexpected `threshold_verdict` values block release because selecting a row is distinct from having no completed eval run.
- The campaign join is left-joined so legacy or standalone offline eval runs remain valid release evidence.
- Strict mode is application config, not a runtime metadata flag, keeping the default-open adopter compatibility decision explicit and globally auditable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Handled active PromptTemplate structs without persisted ids**
- **Found during:** Task 1 (ReleaseGate verdict consult)
- **Issue:** Existing tests pass `%PromptTemplate{status: "active"}` without an id. The new lookup attempted `run.prompt_template_id == nil`, which Ecto rejects as an unsafe comparison.
- **Fix:** Added a `latest_completed_eval_run(nil)` branch that treats in-memory templates as having no completed verdict.
- **Files modified:** `lib/scoria/runtime/release_gate.ex`
- **Verification:** `mix test test/scoria/runtime/release_gate_test.exs --warnings-as-errors`
- **Committed in:** `ebdadd68`

---

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** The fix preserves existing in-memory test behavior without weakening persisted prompt gating.

## Issues Encountered

- Task 3 was marked `tdd="true"`, but the plan ordered the implementation tasks before the test task. The tests therefore passed on first run because Tasks 1 and 2 were already implemented. The required coverage was still added and committed separately; no plan-level `type: tdd` gate applies.

## Known Stubs

None.

## Threat Flags

None - new runtime governance lookup, telemetry, and index surfaces were all described in the plan threat model.

## Verification

- `mix test test/scoria/runtime/release_gate_test.exs --warnings-as-errors` - PASS (10 tests, 0 failures)
- `mix ecto.migrate && mix ecto.rollback && mix ecto.migrate` - PASS (index creates, drops, and recreates cleanly)
- `rg -n "prompt_version|runner_mode" lib/scoria/runtime/release_gate.ex` - PASS (no forbidden filters in the gate)
- `rg -n "blocks_release\\?|release_gate, :ungated|require_eval_verdict|online_scoring|inserted_at DESC" ...` - PASS (required implementation hooks present)

## TDD Gate Compliance

- Plan frontmatter is `type: execute`, so plan-level TDD gate ordering does not apply.
- Task 3 had `tdd="true"` but was ordered after implementation; no RED failing-test commit could be produced without rewriting completed task history. The test commit `5c23c09e` records the coverage as a post-implementation regression suite.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 42 is ready for verification and closeout: EVAL-04 is implemented, and the release gate now consumes the fail-closed verdict spine from 42-01 while excluding online-scoring evidence from 42-06.

## Self-Check: PASSED

- Found created file: `priv/repo/migrations/20260704235536_add_eval_runs_verdict_index.exs`
- Found modified files: `lib/scoria/runtime/release_gate.ex`, `config/config.exs`, `test/scoria/runtime/release_gate_test.exs`
- Found summary file: `.planning/phases/42-eval-fails-closed/42-07-SUMMARY.md`
- Found task commits: `ebdadd68`, `5dc694a1`, `5c23c09e`

---
*Phase: 42-eval-fails-closed*
*Completed: 2026-07-04*
