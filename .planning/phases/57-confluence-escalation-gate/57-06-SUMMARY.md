---
phase: 57-confluence-escalation-gate
plan: 06
subsystem: agent-security
tags: [elixir, ecto, postgres, jsonb, confluence-gate, lethal-trifecta, mcp]

# Dependency graph
requires:
  - phase: 57-confluence-escalation-gate
    plan: 01
    provides: "the D-47 migration's ai_workflow_runs.confluence_legs column (null: false, default: %{}), the writer-disjointness rule on Run.changeset/2, and the D-25/D-50 locked checkpoint decisions"
  - phase: 57-confluence-escalation-gate
    plan: 02
    provides: "Confluence.classify/1's total combination ladder and grade/1's weakest-evidence-wins ladder, which this plan's fold must stay consistent with (unrecognized leg source fails closed to :unclassified, never :declared)"
  - phase: 57-confluence-escalation-gate
    plan: 05
    provides: "confluence_gate/3's D-26 approval-consume CAS (the fold below only ever runs on :no_match) and the always-on [:scoria, :gate, :confluence, :observed] telemetry this plan's evaluation still emits through unchanged"
provides:
  - "MCP.Executor.fold_confluence_legs/4 (private) + fold_confluence_legs_for_test/4 (@doc false): the strongest-wins, lit-legs-only, single-statement per-run leg accumulator (D-15, D-16, D-17)"
  - "evaluate_confluence/5 now folds this call's own private_data/untrusted_content witnesses into the run's accumulator BEFORE building the classify input, and reads the two exposure legs back from the merged accumulator (not the call's own witnesses) while the exfil leg stays sourced from THIS call alone (D-11)"
  - "[:scoria, :gate, :confluence, :fallback] telemetry event (accumulator write failure, D-16)"
  - "ai_workflow_runs.confluence_legs's value shape (lit/source/reason_code/first_step_id/strongest_source per leg), documented on Scoria.Workflows.Run and named as Phase 58's read path for re-deriving the combination + grade via Confluence.classify/1"
  - "Corrected MCP.Executor comments: the step result_envelope taint/classification merges are NOT durable across a successful completion (complete_step/3 wholesale-replaces result_envelope; retry_step/1 zeroes it) -- confluence_legs is named as the actual durable run-scoped record"
affects: [58]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single-statement strongest-wins jsonb fold: Repo.update_all's update: clause computes a subquery over jsonb_each(candidates)/jsonb_object_agg(...) that reads the run's CURRENT confluence_legs (via repeated r.confluence_legs references, never a separate Repo.one/Repo.get), ranks each candidate's rank against a SQL CASE on the existing witness's stored source, and only replaces a leg when the candidate's rank is STRICTLY greater -- generalizes uniformly to zero, one, or two lit legs in one fragment, no per-count branching"
    - "select: r.confluence_legs (not a returning: opt) is how Repo.update_all/3 reads a value back in the same statement -- Ecto's update_all has no :returning option (unlike insert_all/3); the second {count, results} tuple element is populated only when the update query itself carries select:, mirroring the pre-existing consume_call_scope/3 and Rails.admit_tool_call/2 shape"
    - "@doc false test-only wrapper (fold_confluence_legs_for_test/4) exposing a private primitive for unit testing witness sources not yet constructible through any live call path -- mirrors the pre-existing actual_units/3 precedent in the same file"

key-files:
  created: []
  modified:
    - lib/scoria/mcp/executor.ex
    - lib/scoria/workflows/run.ex
    - test/scoria/mcp/executor_confluence_test.exs
    - test/scoria/workflows/run_test.exs

key-decisions:
  - "A failed accumulator fold (including a run id matching no row, e.g. {0, _}) degrades evaluate_confluence to classifying on THIS CALL'S OWN witnesses alone, rather than either crashing the tool call or silently allowing more than the call itself can prove. This is never weaker than the pre-accumulator tracer (a single tool declaring all three legs still escalates on itself, D-11's floor) and never stronger than what this call's own declaration supports. Fallback telemetry ([:scoria, :gate, :confluence, :fallback]) fires unconditionally on this path (D-16) -- the degradation is signaled, not silent."
  - "Tasks 1 and 2 landed in one commit (2e18d0ee) rather than two. The fold primitive (Task 1) and its wiring into evaluate_confluence (Task 2) are implemented in the same function body -- evaluate_confluence's job IS to fold-then-classify -- and splitting them into separate atomic commits would have required artificially reverting/reapplying hunks with no corresponding gain in reviewability. Mirrors the identical judgment call recorded in 57-05-SUMMARY.md's Task Commits section."
  - "The ordering-independence test (the single load-bearing proof for D-15.1's strongest-wins correction) calls the fold primitive directly via fold_confluence_legs_for_test/4, not through Executor.execute/4's public API. confluence_input/2 only ever constructs source: :declared witnesses in this plan's scope (D-13) -- a :default_tier witness is not yet reachable from any live call path -- so the black-box proof this accumulator's correctness depends on would otherwise be untestable until a later plan wires scanner-sourced legs into confluence_input/2."

requirements-completed: [GATE-01, GATE-02]

coverage:
  - id: D1
    description: "The accumulator keeps the STRONGEST witness per leg (not first-wins); a leg first lit by a default-tier witness and later by a declared witness reports the declared source, and reversing the arrival order produces the identical final accumulator state"
    requirement: "GATE-01"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/executor_confluence_test.exs#confluence leg accumulator (D-15, D-16, D-17)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Only LIT legs are ever written -- a false classification writes nothing (the key stays absent), and a call that lights one leg leaves the accumulator with exactly that one key"
    requirement: "GATE-01"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#confluence leg accumulator (D-15, D-16, D-17)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The merge and the accumulator read are one statement (Repo.update_all reading back via the query's own select:, never a separate Repo.one/Repo.get); two concurrent tool calls in one run, each lighting a different leg, both persist"
    requirement: "GATE-01"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#confluence leg accumulator (D-15, D-16, D-17)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A failed accumulator write (a run id matching no row) emits the [:scoria, :gate, :confluence, :fallback] telemetry event and the tool call does not crash"
    requirement: "GATE-01"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#confluence leg accumulator (D-15, D-16, D-17)"
        status: pass
    human_judgment: false
  - id: D5
    description: "A distributed run (private data on step one, untrusted content on step two, exfil on step three) escalates on step three, whichever step carries the exfil leg, and reordering the two exposure legs still escalates correctly; an exfil-capable tool that ran earlier does not poison a later pure read; a single tool declaring all three legs still escalates on itself; a false leg declaration cannot unlight an already-lit leg; an approval consume leaves every previously-accumulated leg intact"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#confluence gate wiring: exposure legs accumulate, exfil stays per-call (D-11, D-12)"
        status: pass
    human_judgment: false
  - id: D6
    description: "confluence_legs's per-leg witness shape (lit/source/reason_code/first_step_id/strongest_source) is documented on Scoria.Workflows.Run and named as Phase 58's read path; a folded, DB-reloaded leg's stored map is sufficient to reconstruct a valid Confluence.classify/1 input that returns the expected combination"
    requirement: "GATE-01"
    verification:
      - kind: unit
        ref: "test/scoria/workflows/run_test.exs#confluence_legs witness shape re-derivability (plan 57-06, cross-phase obligation 1)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-29
status: complete
---

# Phase 57 Plan 06: Per-Run Confluence Leg Accumulator Summary

**Built the strongest-wins, lit-legs-only, single-statement per-run leg accumulator that lets distributed confluence -- private-data exposure on one step, untrusted-content exposure on another, exfil capability on a third -- escalate on the exfil-carrying call, and wired it into `confluence_gate/3`'s evaluation so the two exposure legs are run-scoped while exfil stays per-call.**

## Performance

- **Duration:** ~25 min (git-timestamp span from base commit `0bf03fc4` to final commit `3a2f9c57`; includes worktree HEAD verification, reading five upstream SUMMARY.md files plus CONTEXT.md/RESEARCH.md for the D-15/D-16/D-17 decisions, one iteration to fix an incorrect `Repo.update_all` `returning:` assumption, and full-suite regression verification)
- **Started:** 2026-07-28T23:54:28-04:00 (base commit)
- **Completed:** 2026-07-29T00:18:32-04:00
- **Tasks:** 3 (Tasks 1-2 `auto`/`tdd="true"`, Task 3 `auto`)
- **Files modified:** 4 (0 created, 4 modified)

## Accomplishments

- `MCP.Executor` gains a private per-run leg accumulator fold. `confluence_leg_candidates/2` builds a jsonb "candidates" map containing ONLY the two EXPOSURE legs (`private_data`, `untrusted_content`) THIS call actually lit (D-15.2 -- a `false` or absent leg is never a candidate, so it never gets written). `fold_confluence_legs/4` issues ONE `Repo.update_all` whose `update:` clause computes, via `jsonb_each(candidates)` / `jsonb_object_agg(...)`, a per-leg `CASE` that reads the leg's CURRENT stored `source` (via a fixed rank `CASE`, absent -> rank `-1`) and only replaces it when the candidate's precomputed rank is STRICTLY greater -- STRONGEST-WINS (D-15.1), not the first-wins a plain `||` concatenation would silently produce. The query's own `select: r.confluence_legs` reads the merged value back in the SAME statement (D-17) -- `Repo.update_all/3` has no `:returning` opt (that was my first, incorrect attempt; Ecto docs confirm the second tuple element is populated only via the query's `select:`, matching the pre-existing `consume_call_scope/3`/`Rails.admit_tool_call/2` shape).
- Each stored leg carries `lit`, `source` (the strongest witness seen), `reason_code`, `first_step_id` (preserved across later re-grades), and `strongest_source` (identical to `source`, present so the map is self-describing) -- rich enough for Phase 58 to re-derive both the named combination and the grade via `Confluence.classify/1` without re-running the executor.
- `evaluate_confluence/5` now folds this call's own witnesses BEFORE classifying: the classify input's `private_data`/`untrusted_content` come from the MERGED accumulator, while `exfil` is always sourced from THIS call's own classification, never accumulated (D-11) -- so an earlier exfil-capable tool call can never poison a later harmless read, while a single tool declaring all three legs still escalates on itself because its own legs fold in before its own evaluation.
- A failed accumulator write (a genuine DB error, or a run id matching no row) is never silently swallowed (D-16, unlike `persist_taint_to_step/4`'s and `persist_classification_to_step/3`'s `rescue _ -> :ok` discipline, which this deliberately does NOT copy): it emits `[:scoria, :gate, :confluence, :fallback]` and degrades `evaluate_confluence/5` to classifying on the call's own witnesses alone, never crashing the call and never silently allowing more than the call itself can prove.
- No clearing/reset/downgrade/untaint primitive exists anywhere in the accumulator section (D-12) -- legs are monotone within a run, and the only reset is a new run. A source-scan test guards this structurally.
- Corrected two comments in `MCP.Executor` that falsely claimed taint is "always ... inspectable via the step's jsonb result_envelope" -- `Workflows.complete_step/3` wholesale-replaces that envelope on every successful step and `Workflows.retry_step/1` zeroes it on retry, so the merge survives only for a step that is NOT currently completed-and-replaced. `ai_workflow_runs.confluence_legs` is named as the actual durable, run-scoped record.
- `Scoria.Workflows.Run`'s `confluence_legs` field now carries a full doc comment describing the witness shape and naming it as Phase 58's read path.

## Task Commits

1. **Tasks 1-2: strongest-wins per-run leg accumulator + gate wiring** - `2e18d0ee` (feat) -- landed together; see Decisions Made for why.
2. **Task 3: witness-shape documentation + corrected durability comment + re-derivability test** - `3a2f9c57` (docs)

_Note: this SUMMARY.md is committed separately per the worktree execution protocol (STATE.md/ROADMAP.md are owned by the orchestrator, not this plan)._

## Files Created/Modified

- `lib/scoria/mcp/executor.ex` -- `fold_confluence_legs/4` (2 clauses: no-run-id passthrough, and the real DB fold), `fold_confluence_legs_for_test/4` (`@doc false`), `confluence_leg_candidates/2` + `maybe_put_confluence_leg_candidate/3`, `confluence_leg_source_rank/1` + `@confluence_leg_source_rank`, `decode_confluence_legs/1` + `decode_confluence_leg/1` + `safe_confluence_leg_source/1` + `safe_confluence_leg_reason_code/1`, `emit_confluence_accumulator_fallback/4`; `evaluate_confluence/5` rewritten to fold-then-classify; two corrected D-08 durability comments (`persist_taint/3`, `persist_taint_to_step/4`)
- `lib/scoria/workflows/run.ex` -- `confluence_legs` field's doc comment extended with the full witness-shape description and Phase 58 read-path pointer
- `test/scoria/mcp/executor_confluence_test.exs` -- new fixtures (`PrivateDataOnlyTool`, `UntrustedContentOnlyTool`, `PureReadTool`); new `describe` blocks: "confluence leg accumulator (D-15, D-16, D-17)" (7 tests) and "confluence gate wiring: exposure legs accumulate, exfil stays per-call (D-11, D-12)" (7 tests)
- `test/scoria/workflows/run_test.exs` -- module gains a DB sandbox `setup`; new `describe "confluence_legs witness shape re-derivability (plan 57-06, cross-phase obligation 1)"` (1 test)

## Decisions Made

- **A failed fold degrades to per-call-only evaluation, not a crash or a silent pass-through.** See `key-decisions`. Fallback telemetry always fires on this path.
- **Tasks 1 and 2 landed in one commit.** See `key-decisions` -- the fold and its wiring are implemented in the same function body; mirrors 57-05's identical precedent.
- **The ordering-independence unit test calls the fold primitive directly**, via a `@doc false` test-only wrapper (`fold_confluence_legs_for_test/4`, mirroring the pre-existing `actual_units/3` precedent in the same file), because a `:default_tier`-sourced witness is not yet constructible through any live call path in this plan's scope (only `:declared` witnesses are reachable via `confluence_input/2` until a later plan wires scanner-sourced legs).
- **`Repo.update_all/3` has no `:returning` opt** -- confirmed by reading `deps/ecto/lib/ecto/repo.ex`'s own doc ("The second element is nil by default unless a select is supplied in the update query"). My first implementation attempt used `returning: [:confluence_legs]`, which silently returned `{count, nil}` and made every fold report a false failure (the DB write itself still succeeded -- only the Elixir-side read-back failed). Fixed by adding `select: r.confluence_legs` to the query and calling `Repo.update_all(query, [])`, matching the pre-existing `consume_call_scope/3`/`Rails.admit_tool_call/2` shape exactly. Caught by the plan's own required tests (5 of 39 failed on the first run); documented here since it directly touches D-17's acceptance criteria.

## Deviations from Plan

### Auto-fixed Issues

None -- no Rule 1/2/3 auto-fixes were required beyond the `returning:` -> `select:` correction above, which was caught and fixed during Task 1's own TDD RED/GREEN cycle before any commit (not a post-hoc bug fix against already-committed code).

---

**Total deviations:** 0 (the `returning:`/`select:` correction was pre-commit TDD iteration, not a deviation from already-shipped behavior)
**Impact on plan:** None -- both commits landed with the plan's own required tests green.

## Issues Encountered

**`Repo.update_all/3`'s `:returning` option does not exist** (see Decisions Made above). CONTEXT.md's own D-17 prose suggested `Repo.update_all(query, [...], returning: [:confluence_legs])`, which does not match this Ecto version's (3.13.6) actual API. Caught immediately by the plan's own required tests rather than shipping silently -- 5 of the first 39 test runs failed with either a `CaseClauseError` (the fold's pattern match on `{1, [%Run{...}]}` never matched the actual `{1, nil}` return) or a cascading `budget_policy_not_found` error (the fold silently "failing" meant `evaluate_confluence/5` fell back to per-call-only witnesses, so the multi-step escalation tests never actually escalated and instead hit `execute_live`'s budget-reservation path unprepared). Fixed at the query level (`select: r.confluence_legs`) rather than working around it at the call site.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness

- **Phase 58's read path for the named combination is `ai_workflow_runs.confluence_legs`, not the step result envelope.** Documented explicitly on `Scoria.Workflows.Run` and proven re-derivable end to end (fold -> DB reload -> `Confluence.classify/1` round-trip) in `run_test.exs`.
- **`.planning/WINDOWS.md` entry 5 (nothing yet persists `Scoria.Confluence.Evidence` onto the `ai_approvals` row) remains open, and this plan does not close it** -- it was explicitly out of this plan's file scope per the wave context. However, `confluence_legs`'s per-leg witness detail (source, reason_code, first_step_id per accumulated leg) is now one of the two named likely read paths (alongside 57-07's audit metadata) for whichever later plan wires the approvals-drawer evidence projection: a reviewer screen could read `run.confluence_legs` directly for the two exposure legs' provenance without needing a new column on `ai_approvals` at all, since the run row already carries it durably. No new plan is required to make this data reachable -- it already is, as of this commit.
- **The `:default_tier`/`:scanner_infra` witness sources are exercised only through the `@doc false` test-only fold entry point today**, because `confluence_input/2` (plan 01/05's leg-witness constructor) only ever produces `source: :declared` witnesses. A later plan wiring scanner-sourced legs into `confluence_input/2` will make the accumulator's strongest-wins ranking reachable through `Executor.execute/4`'s public API for the first time in production; the ranking logic itself needs no changes when that happens (it already handles all four sources).
- **No blockers.** `examples/support_copilot/deps/**/_build/**/source.dag` checked clean (no dirty rebar3 artifacts) prior to this SUMMARY being written; `git status --short` is empty. Full targeted suite: `test/scoria/mcp/` + `test/scoria/workflows/` + `test/scoria/confluence_test.exs` (304 tests, 0 failures) and `test/scoria/observe/` + `test/scoria/connectors/invocation_test.exs` (251 tests, 0 failures) both green; `mix compile --warnings-as-errors` exits 0.

---
*Phase: 57-confluence-escalation-gate*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 4 claimed modified files found on disk (`lib/scoria/mcp/executor.ex`, `lib/scoria/workflows/run.ex`, `test/scoria/mcp/executor_confluence_test.exs`, `test/scoria/workflows/run_test.exs`) plus this SUMMARY.md; both commits (`2e18d0ee`, `3a2f9c57`) found in `git log --oneline --all`. `examples/support_copilot/deps` clean, `git status --short` empty (before adding this SUMMARY.md).
