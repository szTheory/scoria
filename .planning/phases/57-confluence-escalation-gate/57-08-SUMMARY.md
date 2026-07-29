---
phase: 57-confluence-escalation-gate
plan: 08
subsystem: agent-security
tags: [elixir, ecto, confluence-gate, resume, retry, concurrency, workflows, mcp]

# Dependency graph
requires:
  - phase: 57-confluence-escalation-gate
    plan: 01
    provides: "confluence_gate/3 insertion point, mark_waiting_for_approval/3 reuse, the D-25/D-50 locked checkpoint decisions this plan reads (D-25 = d25-step-scoped, verbatim) but does not re-decide"
  - phase: 57-confluence-escalation-gate
    plan: 05
    provides: "the approval-consume CAS (consume_call_scope/3) this plan's resumed-escalation-passes-through test exercises end-to-end"
  - phase: 57-confluence-escalation-gate
    plan: 07
    provides: "the audit outbox write ordering (audit row written before mark_waiting_for_approval/3) this plan's stale-entry rescue must not disturb"
  - phase: 56.1-per-run-rails-split-from-phase-56
    provides: "halt_run/3's terminality machinery (G1-G6 guards, FOR UPDATE lock order, run.rail.tripped audit) that this plan's D-52 addition and D-24 halt-after-claim test build on"
provides:
  - "Scoria.Workflows.resume_run/1 D-26 three-axis widening: accepts a run status of \"running\" for a confluence-kind approval whose own step is still waiting_for_approval, and current_approved_approval/1 drops the current-step/latest-checkpoint predicates for confluence-kind approvals in favor of a step-still-waiting predicate"
  - "Scoria.Workflows.retry_step/1 D-27 guard: refuses a waiting_for_approval step or one with a pending confluence approval, propagating cleanly through Scoria.Workflows.Resume.retry_failed_step/2's existing with/else chain with no code change there"
  - "Scoria.Workflows.halt_run/3 D-52 addition: resolves any pending confluence approval on the halted run to a terminal (\"expired\") status through the existing approve/3 decision function, post-commit"
  - "Scoria.MCP.Executor D-28 mark_confluence_waiting_for_approval/3: rescues Ecto.StaleEntryError around the mark_waiting_for_approval/3 escalation call, fails the step via the ordinary Workflows.fail_step/3 path, and returns a confluence-denied refusal envelope instead of propagating"
affects: [57-09, 57-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Baking a stronger, necessary predicate (confluence_step_waiting?/2) directly into the resume finder's confluence branch rather than merely dropping the original two predicates -- discovered during implementation that dropping current-step/latest-checkpoint alone would let an already-resumed confluence approval match forever (its approval.status column never changes on resume), stranding a SECOND coexisting escalation's discovery"
    - "Post-commit resolution of a halted run's orphaned pending approval through the EXISTING decision function (approve/3) rather than a bespoke lifecycle write -- keeps the approval_write_invariant_guard_test.exs allow-list at exactly two call sites"
    - "Stale-entry rescue normalizes to a genuine step failure (Workflows.fail_step/3), not merely an error return -- ensures the escalating step is never left stuck in \"running\" after a concurrent-mutation race, consistent with every other step-failure path in the codebase"

key-files:
  created: []
  modified:
    - lib/scoria/workflows.ex
    - lib/scoria/mcp/executor.ex
    - test/scoria/workflows_test.exs
    - test/scoria/mcp/executor_confluence_test.exs
    - test/scoria/workflows/approval_write_invariant_guard_test.exs

key-decisions:
  - "D-25 was READ, not re-decided: the developer's checkpoint answer recorded verbatim in 57-01-SUMMARY.md is d25-step-scoped -- step-level pause scoping, no sibling clamp added to complete_step/3 (untouched by this plan), and the partial-freeze behavior is an accepted, documented limitation pinned by this plan's own load-bearing sibling-completion regression test."
  - "current_approved_approval/1's confluence branch does not merely drop the two original predicates -- it substitutes a stronger, necessary one (the approval's own step is still waiting_for_approval). Without this, an already-resumed confluence approval's status column (never mutated by resume_run/1) would keep matching on every subsequent resume_run/1 call, silently starving discovery of a SECOND, still-genuinely-pending escalation in the same run. This is a Rule 1/2 discretion beyond the plan's literal 'drop the predicates' instruction, verified by the two-concurrent-escalations test asserting both orders resolve correctly."
  - "halt_run/3's D-52 resolution runs POST-COMMIT (mirroring emit_rail_tripped/3 and maybe_emit_rail_observed/1's existing placement), calling the public approve/3 rather than writing Approval.changeset/2 inline -- keeps the write-invariant guard's allow-list at exactly two call sites and reuses approve/3's own audit/broadcast side effects verbatim."
  - "The StaleEntryError rescue normalizes to Workflows.fail_step/3 (not merely an {:error, envelope} return with the step left untouched) -- confirmed necessary because mark_waiting_for_approval/3's whole transaction rolls back together on a stale write, meaning the escalating step's own status write rolls back too and would otherwise be left exactly as it was before the call (\"running\"). Failing the step (with the run's status computed the ordinary default way, exactly like every other unhandled step failure in this codebase) is what satisfies the plan's own acceptance criterion that the step is never left running."

requirements-completed: [GATE-02]

coverage:
  - id: D1
    description: "resume_run/1 resumes a confluence escalation whose run status was rewritten to \"running\" by a sibling step's completion, and the finder no longer requires the approval's step/checkpoint to be current -- the load-bearing sibling-completion case plus a same-scenario current-step/checkpoint mismatch case"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/workflows_test.exs#describe \"resume_run/1 three-axis widening for confluence approvals (D-26, plan 57-08)\" -- \"a confluence escalation resumes after a sibling step's completion flips the run status back to running (the load-bearing sibling-completion case)\""
        status: pass
      - kind: integration
        ref: "test/scoria/workflows_test.exs#describe \"resume_run/1 three-axis widening for confluence approvals (D-26, plan 57-08)\" -- \"a confluence approval whose step is not the run's current step, and whose checkpoint is not the latest checkpoint, still resumes\""
        status: pass
    human_judgment: false
  - id: D2
    description: "Two concurrent confluence escalations in one run are both independently resumable, in either approval order; a non-confluence approval still requires all three original predicates (scoping regression)"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/workflows_test.exs#describe \"resume_run/1 three-axis widening for confluence approvals (D-26, plan 57-08)\" -- \"two escalations in one run are both resumable, in either approval order\""
        status: pass
      - kind: integration
        ref: "test/scoria/workflows_test.exs#describe \"resume_run/1 three-axis widening for confluence approvals (D-26, plan 57-08)\" -- \"a non-confluence approval's resume behavior is byte-identical to its pre-phase behavior on all three predicates\""
        status: pass
    human_judgment: false
  - id: D3
    description: "A resumed confluence escalation re-reaching the identical tool call passes through on the consumed approval instead of escalating again (composes with 57-05's approval-consume CAS)"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#describe \"resumed confluence escalation re-execution (D-26, plan 57-08 Task 1)\" -- \"a resumed confluence escalation re-reaching the identical tool call passes through on the consumed approval instead of escalating again\""
        status: pass
    human_judgment: false
  - id: D4
    description: "retry_step/1 refuses a waiting_for_approval step and a step with a pending confluence approval (even when the step's own status has been forced away), leaving the result_envelope/approval/run status unchanged; a genuinely failed step with no pending confluence approval still retries normally; Resume.retry_failed_step/2 surfaces the refusal"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/workflows_test.exs#describe \"retry_step/1 refuses a pending confluence escalation (D-27, plan 57-08)\" (4 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "A sibling step completing concurrently with an in-flight escalation does not crash the escalating task and never leaves the escalating step running; escalation attrs are atom-keyed with a non-nil tool name"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#describe \"concurrency and attrs shape (D-28, plan 57-08 Task 3)\" (2 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "A halted run never mints a confluence approval, including when a sibling rail trips on a DIFFERENT step after this step was already claimed; a halt resolves any pending confluence approval on the run to a terminal status rather than stranding it; a non-confluence pending approval is untouched by a halt"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#describe \"confluence gate end-to-end (D-14, D-19, D-20, D-23, D-24, D-46)\" -- \"a run that halts via a sibling rail trip AFTER this step was claimed still denies the escalation without creating an approval row (D-24)\""
        status: pass
      - kind: integration
        ref: "test/scoria/workflows_test.exs#describe \"halt_run/3 with a pending confluence approval (D-52, plan 57-08)\" (3 tests)"
        status: pass
    human_judgment: false

duration: ~30min
completed: 2026-07-29
status: complete
---

# Phase 57 Plan 08: Resume Widening, Retry Guard, and Concurrency/Halt Hardening for Confluence Escalations Summary

**A confluence escalation now survives the real world: `resume_run/1` resumes across a sibling-triggered status flip and two concurrent escalations without stranding either, `retry_step/1` can no longer zero an escalated step's evidence or mint a duplicate approval, a stale-entry race at the escalation call site fails the step instead of crashing the dispatch task, and a rail halt resolves an orphaned pending confluence approval to a terminal status instead of leaving it undecidable forever.**

## Performance

- **Duration:** ~30 min (from base commit `34d178ff` through the final Task 3 commit; includes re-staging all three tasks' changes into atomic per-task commits after initially implementing them together)
- **Started:** 2026-07-29T00:58:00Z (worktree setup)
- **Completed:** 2026-07-29T05:36:11Z
- **Tasks:** 3 (all `auto`/`tdd="true"`)
- **Files modified:** 5 (0 created, 5 modified)

## Accomplishments

- `Scoria.Workflows.resume_run/1`'s outer predicate now also accepts a `"running"` run status when the matched approval's `blocker_kind` is `"confluence"` **and** that approval's own step is still `waiting_for_approval` (D-26 axis 1) -- closing the gap where a sibling step's `complete_step/3` rewriting the run status mid-escalation (D-25's accepted step-scoped partial-freeze) would otherwise fall straight through to `:not_resumable` regardless of any finder change.
- `current_approved_approval/1` drops the current-step and latest-checkpoint predicates for a confluence-kind approval (D-26 axes 2/3) -- but does not merely drop them: it substitutes the STRONGER, necessary predicate "this approval's own step is still `waiting_for_approval`", discovered during implementation to be required because an already-resumed confluence approval's `status` column never changes on resume, and without this substitution it would keep matching forever, starving discovery of a second, genuinely-pending escalation in the same run. Every other blocker kind is byte-identical to pre-phase-57 behavior, pinned by a dedicated regression test.
- `retry_step/1` refuses a step whose status is `waiting_for_approval` or one with a pending confluence-blocker approval (checked independently, so either alone is sufficient), preventing a retry from zeroing the step's `result_envelope`, stranding the approval forever, or minting a duplicate approval on re-execution (D-27). `Scoria.Workflows.Resume.retry_failed_step/2` surfaces the refusal through its existing `with/else` chain -- no code change needed there.
- `Scoria.MCP.Executor`'s `mark_waiting_for_approval/3` call site now rescues `Ecto.StaleEntryError` -- a genuine race under Task-dispatched concurrent steps against a real connection pool, since that function (unlike `halt_run/3`) has no rescue of its own. Normalizes fail-closed: fails the step via the ordinary `Workflows.fail_step/3` path (so it is never left stuck `"running"`) and returns the executor's existing confluence-denied refusal envelope instead of propagating and crashing the unlinked dispatch task (D-28).
- `Scoria.Workflows.halt_run/3` now resolves any pending confluence approval on a halting run to a terminal `"expired"` status through the existing `approve/3` decision function, post-commit -- no new lifecycle function, and the write-invariant guard's allow-list stays at exactly two `Approval.changeset|>update` call sites (D-52).
- The pre-existing D-24 halted-run check (verified still positioned before the audit write and `mark_waiting_for_approval/3`) is now covered for the halt-after-claim case: a sibling rail tripping on a DIFFERENT step, after the escalating step was already claimed/dispatched, still denies without minting an approval row.

## Task Commits

1. **Task 1: Three-axis resume widening for confluence approvals** - `e69b8e31` (feat)
2. **Task 2: Retry guard -- a pending confluence escalation cannot be retried away** - `3312faf5` (feat)
3. **Task 3: Concurrency rescue, halt precedence, and the halt-with-pending-approval invariant** - `9e66700c` (feat)

_Note: this SUMMARY.md is committed separately per the worktree execution protocol (STATE.md/ROADMAP.md are owned by the orchestrator, not this plan)._

## Files Created/Modified

- `lib/scoria/workflows.ex` -- `resume_run/1`, `current_approved_approval/1`, `confluence_approval?/1`, `do_resume/2`, `confluence_approval_location_match?/3`, `confluence_step_waiting?/2` (D-26); `retry_step/1`'s guard + `pending_confluence_approval?/2` (D-27); `halt_run/3`'s `resolve_pending_confluence_approvals/1` call + definition (D-52)
- `lib/scoria/mcp/executor.ex` -- `mark_confluence_waiting_for_approval/3` (the `Ecto.StaleEntryError` rescue) and `confluence_concurrent_envelope/3`, wired into `resolve_escalation/6`'s escalate arm (D-28)
- `test/scoria/workflows_test.exs` -- new `describe "resume_run/1 three-axis widening for confluence approvals (D-26, plan 57-08)"` (4 tests, `@describetag :confluence`), `describe "retry_step/1 refuses a pending confluence escalation (D-27, plan 57-08)"` (4 tests, `@describetag :confluence`), `describe "halt_run/3 with a pending confluence approval (D-52, plan 57-08)"` (3 tests, `@describetag :confluence`)
- `test/scoria/mcp/executor_confluence_test.exs` -- new halt-after-claim test in the existing end-to-end `describe`, new `describe "resumed confluence escalation re-execution (D-26, plan 57-08 Task 1)"` (1 test), new `describe "concurrency and attrs shape (D-28, plan 57-08 Task 3)"` (2 tests)
- `test/scoria/workflows/approval_write_invariant_guard_test.exs` -- pinned line number re-verified and updated (481/1143) three times across this plan's three tasks, per the file's own documented drift caveat (see `<critical_known_trap>`)

## Decisions Made

See `key-decisions` in the frontmatter for the full rationale on: (1) D-25 read-not-re-decided per the locked 57-01 checkpoint answer; (2) `current_approved_approval/1`'s confluence branch substituting a stronger predicate rather than dropping the original two with nothing in their place; (3) `halt_run/3`'s D-52 resolution running post-commit through the existing `approve/3` rather than a bespoke write; (4) the `StaleEntryError` rescue normalizing to a genuine `Workflows.fail_step/3` call rather than merely returning an error with the step left untouched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, caught during test design before any commit] `current_approved_approval/1`'s literal "drop the predicates" instruction would have let an already-resumed confluence approval match forever**
- **Found during:** Task 1, while designing the two-concurrent-escalations test (approving and resuming A, then approving and resuming B)
- **Issue:** The plan's literal Task 1 instruction is to drop the current-step and latest-checkpoint predicates for a confluence-kind approval with nothing substituted. `resume_run/1` never mutates an `Approval`'s `status` column -- only `approve/3` does. If the location predicates are dropped with nothing in their place, an approval that was ALREADY resumed (its step moved on to `"queued"` or beyond, but its own `status` still `"approved"`) would keep matching `current_approved_approval/1` on every subsequent call, since nothing about a plain status-and-blocker-kind match distinguishes "already used" from "still pending". In the two-concurrent-escalations scenario this would make the SECOND `resume_run/1` call re-discover the FIRST (already-resumed) approval instead of the second, genuinely-pending one, silently failing to resume the second escalation.
- **Fix:** Substituted a stronger, necessary predicate for the confluence branch: the approval's own step must still be `waiting_for_approval` (`confluence_step_waiting?/2`). This is what makes `current_approved_approval/1` correctly skip an already-resumed escalation and find the next genuinely-pending one.
- **Files modified:** `lib/scoria/workflows.ex` (`current_approved_approval/1`, `confluence_approval_location_match?/3`, `confluence_step_waiting?/2`)
- **Verification:** `test/scoria/workflows_test.exs`'s "two escalations in one run are both resumable, in either approval order" test asserts both orders resolve to the correct step each time; the load-bearing sibling-completion test and the current-step/checkpoint-mismatch test both remain green.
- **Committed in:** `e69b8e31` (Task 1 commit)

**2. [Rule 1 - Bug, caught during design before any commit] A bare rescue-and-return-envelope would leave the escalating step stuck "running" on a stale-entry race**
- **Found during:** Task 3, while working out how `Ecto.StaleEntryError` behaves inside `mark_waiting_for_approval/3`'s own transaction
- **Issue:** `mark_waiting_for_approval/3`'s entire `Repo.transaction` (including the step's own status write) rolls back together when the run's optimistic-lock write fails. A rescue that only returns `{:error, envelope}` from the executor, without touching the step, would leave the escalating step exactly as it was before the call attempt -- i.e. still `"running"` -- directly contradicting this plan's own acceptance criterion that the step is never left running.
- **Fix:** The rescue clause now also calls `Workflows.fail_step/3` on the escalating step (with a `confluence_concurrent_run_mutation` reason code), consistent with how every other unhandled step failure in this codebase already fails the step by default.
- **Files modified:** `lib/scoria/mcp/executor.ex` (`mark_confluence_waiting_for_approval/3`)
- **Verification:** `test/scoria/mcp/executor_confluence_test.exs`'s concurrency test asserts the escalating step's status is never `"running"` after the race, regardless of which outcome (lands vs. fails closed) actually occurred.
- **Committed in:** `9e66700c` (Task 3 commit)

**3. [Rule 3 - Blocking, the documented `<critical_known_trap>`] `approval_write_invariant_guard_test.exs`'s pinned line number drifted three times, once per task**
- **Found during:** All three tasks' final verification runs (`mix test test/scoria/workflows_test.exs test/scoria/workflows/ test/scoria/mcp/`)
- **Issue:** Exactly as documented in this plan's `<critical_known_trap>`: the guard test pins the sanctioned `approve/3` decision-write call site by hardcoded line number, and each task's insertions above it (resume widening, retry guard, halt D-52) shifted that line number.
- **Fix:** Re-verified the invariant genuinely still held (only two `Approval.changeset|>update` call sites exist, both allow-listed; `halt_run/3`'s D-52 addition routes through the EXISTING `approve/3` rather than adding a third) and re-pinned the line number after each task (1065 -> 1098 -> 1117 -> 1143 final), keeping every intermediate task commit's own test suite fully green.
- **Files modified:** `test/scoria/workflows/approval_write_invariant_guard_test.exs`
- **Verification:** The guard test passes at every one of the three task commits.
- **Committed in:** `e69b8e31`, `3312faf5`, `9e66700c` (one incremental re-pin per task commit)

---

**Total deviations:** 3 auto-fixed (2 bugs caught during design before any commit landed, 1 the documented known-trap line-number maintenance)
**Impact on plan:** All three were necessary for correctness. No scope creep -- deviation 1 and 2 are both genuinely required to satisfy this plan's own literal acceptance criteria (both orders resumable; step never left running), and deviation 3 is explicitly anticipated maintenance the plan's own prompt flagged in advance.

## Issues Encountered

**Commit granularity required re-staging.** All three tasks' implementation and tests were initially written and verified together in one working-tree pass (all 316 tests green), then deliberately reset to `HEAD` and re-applied incrementally per task (via `git checkout -- <file>` on the exact files this plan owns, followed by re-editing each task's slice in isolation) so that each of the three task commits is independently compilable and fully test-green on its own -- including re-computing the write-invariant guard's pinned line number at each intermediate stage rather than only at the final one. This is slower than a single combined commit but produces genuinely atomic, bisectable per-task history matching the plan's `type="auto" tdd="true"` task structure.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness

- **D-25 (`d25-step-scoped`) remains the locked answer for 57-09 and 57-10 to read, not re-decide.** This plan's own regression test (the load-bearing sibling-completion case) is the pinning artifact D-25's checkpoint text asked for.
- **The resume/retry/halt lifecycle around a confluence escalation is now fully hardened** for the realistic multi-step, concurrent-dispatch production shape this milestone's own RESEARCH.md flagged as the single highest-risk untested interaction class in the phase.
- **No blockers.** `examples/support_copilot/deps/**/_build/**/source.dag` checked clean (no dirty rebar3 artifacts) prior to this SUMMARY being written; `git status --short` is empty except this SUMMARY.md. Full targeted suite (`test/scoria/workflows_test.exs`, `test/scoria/workflows/`, `test/scoria/mcp/`): 316 tests, 0 failures. `mix test test/scoria/workflows_test.exs --only confluence`: 11 tests, 0 failures. `mix compile --warnings-as-errors` exits 0. `grep -c 'StaleEntryError' lib/scoria/mcp/executor.ex` returns 3.

---
*Phase: 57-confluence-escalation-gate*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 6 claimed files found on disk (`lib/scoria/workflows.ex`, `lib/scoria/mcp/executor.ex`, `test/scoria/workflows_test.exs`, `test/scoria/mcp/executor_confluence_test.exs`, `test/scoria/workflows/approval_write_invariant_guard_test.exs`, this SUMMARY.md); all 4 commits (`e69b8e31`, `3312faf5`, `9e66700c`, `c1921633`) found in `git log --oneline`. `examples/support_copilot/deps` clean, `git status --short` empty prior to this edit.
