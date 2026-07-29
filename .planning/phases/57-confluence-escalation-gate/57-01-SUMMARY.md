---
phase: 57-confluence-escalation-gate
plan: 01
subsystem: agent-security
tags: [elixir, ecto, confluence-gate, lethal-trifecta, mcp, workflows, postgres]

# Dependency graph
requires:
  - phase: 55-content-trust-taint-substrate
    provides: content trust tiers / taint substrate the untrusted-content leg reads
  - phase: 56-tool-declared-trifecta-classification-per-run-rails
    provides: Scoria.MCP.Classification (reads_private_data/sees_untrusted_content/can_exfiltrate declaration + unclassified_default fail-closed guard) resolved once per call at MCP.Executor
provides:
  - Scoria.Confluence + %Scoria.Confluence.Evidence{} pure classifier at root namespace (D-03/D-04), implementing the exfiltration_path clause and the deliberately fail-neither-open-nor-escalate :unevaluable terminal fallback (D-06)
  - MCP.Executor confluence_gate/3, inserted between replay_gate/3's {:continue, context} branch and execute_live/4 (D-14), refusing a declared three-leg tool call before its execute/2 body runs
  - The exit({:shutdown, {:scoria_confluence_escalation, attrs}}) signal (D-20) and its catching clause in Workflows.Runtime.execute_handler/6, proven to survive an adopter try/rescue _ -> :ok handler
  - Consolidated D-47 migration (confluence_legs, consumed_at, consumed_by_step_id, confluence_scope, audit event_type index)
  - Run.changeset/2 and Approval.changeset/2 writer-disjointness extended to the four new fields (D-15, D-26)
affects: [57-02, 57-03, 57-04, 57-05, 57-06, 57-07, 57-08, 57-09, 57-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure cond-ladder classifier returning {atom, %Evidence{}} (mirrors Scoria.Workflows.ReplayDisposition), deliberately diverging at the terminal clause instead of fail-open"
    - "Gate-before-execute_live insertion point in MCP.Executor.execute/4, so an escalated call reserves no budget and grants no access"
    - "exit({:shutdown, term}) as the executor-to-runtime pause signal, not raise, because try/rescue does not catch an exit"
    - "Counter/changeset writer disjointness (a field lives on the schema but is deliberately absent from cast/3) applied in both polarities: never-cast-because-CAS-owns-it (Run.confluence_legs) and never-cast-because-caller-attrs-could-un-consume-it (Approval.consumed_at/consumed_by_step_id/confluence_scope)"

key-files:
  created:
    - lib/scoria/confluence.ex
    - lib/scoria/confluence/evidence.ex
    - priv/repo/migrations/20260728140000_add_confluence_columns.exs
    - test/scoria/confluence_test.exs
    - test/scoria/mcp/executor_confluence_test.exs
    - test/scoria/workflows/run_test.exs
  modified:
    - lib/scoria/mcp/executor.ex
    - lib/scoria/workflows/runtime.ex
    - lib/scoria/workflows/run.ex
    - lib/scoria/observe/approval.ex
    - test/scoria/observe/approval_test.exs

key-decisions:
  - "Checkpoint D-25 resolved: d25-step-scoped (verbatim developer answer recorded below)"
  - "Checkpoint D-50 resolved: d50-scope (verbatim developer answer recorded below) -- confluence_scope ships in this plan's migration as a result"
  - "Rule 1 fix: Classification.unclassified_default (source: :unclassified_default) is excluded from ever producing a :declared leg witness in confluence_gate/3's input fold, mirroring Classification.declared_sensitive?/1's own guard"

patterns-established:
  - "Confluence.classify/1's grade computation (weakest-evidence-wins over leg witness sources) is written generically now even though only :declared witnesses are constructible this plan -- Plan 02's scanner-sourced legs plug into the same function without a rewrite"

requirements-completed: [GATE-01, GATE-02]

coverage:
  - id: D1
    description: "A tool that declares all three trifecta legs is refused by the confluence gate before its execute/2 body runs, and the run/step/approval land at waiting_for_approval with a confluence-kind ai_approvals row"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#a declared three-leg tool is refused before its execute/2 body runs, and the run/step pause resumably at waiting_for_approval"
        status: pass
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#the pause still lands, and the tool body still never runs, when an adopter handler wraps the call in try/rescue _ -> :ok (D-20)"
        status: pass
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#a halted run is denied without creating an approval row, and never escalates (D-24)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Scoria.Confluence.classify/1 is a pure, dependency-free classifier returning {combination, %Evidence{}} with the D-06 fail-neither-open-nor-escalate terminal fallback"
    requirement: "GATE-01"
    verification:
      - kind: unit
        ref: "test/scoria/confluence_test.exs#classify/1 -- all three legs lit (D-05 exfiltration_path)"
        status: pass
      - kind: unit
        ref: "test/scoria/confluence_test.exs#classify/1 -- terminal fallback (D-06 deliberate divergence from ReplayDisposition)"
        status: pass
      - kind: unit
        ref: "test/scoria/confluence_test.exs#module hygiene (D-03)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Consolidated D-47 migration applies and rolls back cleanly; confluence_legs/consumed_at/consumed_by_step_id/confluence_scope are schema-present but structurally non-castable"
    verification:
      - kind: other
        ref: "mix ecto.migrate && mix ecto.rollback --step 1 && mix ecto.migrate"
        status: pass
      - kind: unit
        ref: "test/scoria/workflows/run_test.exs#confluence_legs writer disjointness (D-15)"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/approval_test.exs#consumed_at/consumed_by_step_id/confluence_scope writer disjointness (D-26, D-50)"
        status: pass
    human_judgment: false

duration: 23min
completed: 2026-07-28
status: complete
---

# Phase 57 Plan 01: End-to-End Confluence Escalation Gate Tracer Summary

**Confluence escalation proven end-to-end on one tainted path: a declared three-leg tool is refused at `MCP.Executor` before its body runs, signalled to `Workflows.Runtime` via `exit({:shutdown, ...})`, and landed as a resumable `waiting_for_approval` run/step/approval triple through the existing `Workflows.mark_waiting_for_approval/3` -- plus the consolidated D-47 schema this phase's remaining nine plans build on.**

## Performance

- **Duration:** 23 min (git-timestamp span from base commit to final Task 3 commit; includes a blocking checkpoint pause for the developer's D-25/D-50 decision)
- **Started:** 2026-07-28T21:13:45-04:00 (base commit `5a9d0f8f`)
- **Completed:** 2026-07-28T21:36:08-04:00
- **Tasks:** 3 (Task 1 auto/tracer, Task 2 checkpoint:decision, Task 3 auto)
- **Files modified:** 11 (6 created, 5 modified)

## Checkpoint Decisions (D-25, D-50)

Two one-way-door decisions CONTEXT.md deliberately deferred to planning. **Recorded here verbatim per the developer's checkpoint response** -- four later plans (57-05 wave 4, 57-08 wave 7, 57-09 wave 4, 57-10 wave 8) read these and must NOT re-decide either door in isolation.

> **D-25 (pause scoping) = `d25-step-scoped`** — step-level scoping. Amend the GATE-02 wording to match D-18's already-locked step-scoped phrasing; add NO sibling clamp to `complete_step/3`. The partial-freeze behavior is an ACCEPTED, DOCUMENTED limitation, not a bug: a multi-step run does not fully freeze on escalation, and that must be pinned by a regression test plus the D-26 three-axis resume-finder widening (which 57-08 in wave 7 will build). Do not touch `complete_step/3`'s run-status computation.
>
> **D-50 (approval fatigue) = `d50-scope`** — build the bounded per-run/per-tool/per-grade approval scope. Therefore Task 3's migration **DOES include** the `confluence_scope` column on `ai_approvals` (`add_if_not_exists :confluence_scope, :string`, two permitted values `"call"` and `"run_tool"`, NULL meaning `"call"`). Downstream: 57-05 adds the consume-CAS branch, 57-09 adds the scoped-approve action in the approvals drawer.

Both selections were the planner's own recommended defaults; the developer confirmed both without redirection.

**Consequence for this plan's own Task 3:** `complete_step/3` in `lib/scoria/workflows.ex` was left completely untouched (D-25 -- no sibling clamp), and the migration's `ai_approvals.confluence_scope` column was added (D-50 -- the scoped-grant column ships now even though the CAS branch that reads it is 57-05's job).

## Accomplishments

- `Scoria.Confluence` + `%Scoria.Confluence.Evidence{}` exist at the root namespace, alias nothing Scoria-side, and implement exactly two clauses of the eventual eight-value combination ladder: `"exfiltration_path"` (all three legs lit) and the unreachable-by-construction `:unevaluable` terminal fallback with `reason_code: :confluence_resolver_fallthrough` (deliberately diverging from `ReplayDisposition`'s fail-open fall-through)
- `MCP.Executor.confluence_gate/3` is inserted between `replay_gate/3`'s `{:continue, context}` branch and `execute_live/4`, so an escalated call reserves no budget and writes no `mcp.access.granted` row for an action that never happened
- The escalation body checks `Run.halted?/1` first (a halt beats a pause, no approval row created), otherwise reuses `Workflows.mark_waiting_for_approval/3` verbatim (no bespoke `Approval` insert) and signals the runtime via `exit({:shutdown, {:scoria_confluence_escalation, attrs}})`
- `Workflows.Runtime.execute_handler/6` gains one new clause, positioned above the generic `{:exit, reason}` clause, resolving the confluence exit into the existing `{:waiting_for_approval, ...}` outcome handling
- A DB-backed tracer test proves the tool's `execute/2` side effect never fires, the run/step land at `waiting_for_approval`, an `ai_approvals` row exists with `blocker_kind: "confluence"`, and the pause survives an adopter `try/rescue _ -> :ok` handler
- The consolidated D-47 migration (`confluence_legs`, `consumed_at`, `consumed_by_step_id`, `confluence_scope`, and the `ai_audit_outbox_events` `event_type` index) applies and rolls back cleanly
- `Run.changeset/2` and `Approval.changeset/2` extend the existing counter/changeset writer-disjointness rule to the four new fields, in both polarities, each backed by a structural test

## Task Commits

1. **Task 1: End-to-end confluence escalation — one declared three-leg tool pauses before it runs** - `d96ec012` (feat)
2. **Task 2: Confirm the two planner-made one-way doors (D-25, D-50)** - checkpoint:decision, no code commit (developer confirmed both planner defaults; see Checkpoint Decisions above)
3. **Task 3: Consolidated confluence migration and schema fields with writer disjointness** - `b23c12bd` (feat)

_Note: this SUMMARY.md is committed separately per the worktree execution protocol (STATE.md/ROADMAP.md are owned by the orchestrator, not this plan)._

## Files Created/Modified

- `lib/scoria/confluence.ex` - Root-namespace pure classifier (D-03/D-04); `classify/1` implements the exfiltration_path + terminal-fallback clauses
- `lib/scoria/confluence/evidence.ex` - Closed `%Evidence{}` struct, `@derive Jason.Encoder`, `@enforce_keys [:combination]`, no free-text field
- `lib/scoria/mcp/executor.ex` - New `confluence_gate/3` (+ `confluence_input/2`, `leg_witness/1`, `escalate/3`, `confluence_halted_envelope/3`) inserted into `execute/4`'s dispatch chain; new `alias Scoria.Confluence`
- `lib/scoria/workflows/runtime.ex` - New `{:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}}` clause in `execute_handler/6`, above the generic `{:exit, reason}` clause
- `lib/scoria/workflows/run.ex` - `confluence_legs` field (default `%{}`), excluded from `changeset/2`'s `cast/3`, load-bearing comment extended
- `lib/scoria/observe/approval.ex` - `consumed_at`/`consumed_by_step_id`/`confluence_scope` fields, excluded from `changeset/2`'s `cast/3` for the opposite-polarity reason (D-26)
- `priv/repo/migrations/20260728140000_add_confluence_columns.exs` - Consolidated D-47 migration
- `test/scoria/confluence_test.exs` - Pure unit tests for `classify/1` (both implemented clauses, module hygiene)
- `test/scoria/mcp/executor_confluence_test.exs` - DB-backed end-to-end tracer proof (three test cases: happy path, try/rescue survival, halted-run denial)
- `test/scoria/workflows/run_test.exs` - New file; structural disjointness test for `confluence_legs`
- `test/scoria/observe/approval_test.exs` - Extended with structural disjointness tests for the three new Approval fields

## Decisions Made

- **D-03/D-04 module shape:** `Scoria.Confluence` at the root namespace, dependency-free leaf, no protocol needed (both operands arrive as plain map arguments) -- per plan/CONTEXT.md, not re-litigated here.
- **D-06 terminal-clause divergence implemented literally:** the fallback is `{:unevaluable, evidence}` with `reason_code: :confluence_resolver_fallthrough`, never `"none"` by silence and never `:escalate`.
- **Grade computation (`weakest_grade/3`) written generically** even though only `:declared` witnesses are constructible this plan, so Plan 02's scanner-sourced legs plug in without a rewrite (executor discretion per CONTEXT.md's "Claude's Discretion" section).
- **Checkpoint decisions D-25 (`d25-step-scoped`) and D-50 (`d50-scope`)** -- see the dedicated section above; both are the developer-confirmed planner defaults.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `confluence_gate/3` initially treated the fail-closed `unclassified_default` as genuine "declared" evidence, spuriously escalating every undeclared-tool call**
- **Found during:** Task 1, running the pre-existing `test/scoria/mcp/executor_test.exs` regression suite after implementing the gate
- **Issue:** `Scoria.MCP.Classification.unclassified_default/0` (the fail-closed-but-inspectable maximal default for a tool with no `classification/0` declaration) sets all three trifecta legs `true` with `source: :unclassified_default`. The first cut of `confluence_input/2` folded `classification.reads_private_data`/`sees_untrusted_content`/`can_exfiltrate` into `:declared` leg witnesses regardless of `source`, so EVERY undeclared tool call (the existing `DummyTool` fixture used throughout `executor_test.exs`, which has no `use Scoria.MCP.Tool` classification) produced an `"exfiltration_path"` + `declared`-grade result and escalated. This is a real semantic bug: the fail-closed default is explicitly documented (`Classification.declared_sensitive?/1`'s own guard) as "never an operand" for sensitivity decisions, and folding it into confluence evidence would make Phase 57 brick every adopter who has declared zero tools -- the exact cascade D-30/D-31 name and this milestone's own "never brick an adopter who declared nothing" scope guardrail forbids.
- **Fix:** `confluence_input/2` now pattern-matches `%Classification{source: :unclassified_default}` as a distinct case, producing `private_data: nil, untrusted_content: nil, exfil: nil` (no witnesses at all) instead of folding the maximal-default booleans. An undeclared tool's call now falls to `Confluence.classify/1`'s `:unevaluable` terminal fallback and is never escalated by this plan's implementation.
- **Files modified:** `lib/scoria/mcp/executor.ex` (`confluence_input/2`)
- **Verification:** `test/scoria/mcp/executor_test.exs` (52 tests) and `test/scoria/workflows/runtime_test.exs` (10 tests) both green after the fix, including the 5 tests that were failing before it (`DummyTool`-based trust-scan, audit-row, and classification-persistence tests). `test/scoria/confluence_test.exs` and `test/scoria/mcp/executor_confluence_test.exs` (which use a genuinely `use Scoria.MCP.Tool`-declared three-leg tool) remain green.
- **Committed in:** `d96ec012` (part of the Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary for correctness and for the milestone's own never-brick guardrail. No scope creep -- the fix is scoped entirely to `confluence_gate/3`'s own input-folding logic, touches no other file, and does not implement any part of the D-29/D-31 grading ladder (still correctly deferred to a later plan).

## Issues Encountered

None beyond the Rule 1 fix above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **The proven mechanism is ready for composition.** `Scoria.Confluence.classify/1`, the `confluence_gate/3` insertion point, the `exit({:shutdown, ...})` signal, and the D-47 schema are all in place and DB-verified. Plan 02 can fill the remaining six combination clauses (D-05's full 8-value enum) and the weakest-evidence grade ladder (D-29) without touching the executor wiring, the runtime exit clause, or the migration again.
- **D-25 and D-50 are locked and must be read, not re-decided, by 57-05, 57-08, 57-09, and 57-10.** See the Checkpoint Decisions section above for the verbatim text each of those plans needs.
- **`confluence_scope` exists on the schema but has no consumer yet** -- 57-05 (wave 4) is expected to add the D-26 consume-CAS branch that reads it, and 57-09 (wave 4) the approvals-drawer scoped-approve action. Until then the column is inert (catalog-only), matching the plan's own backstop truth ("no adopter who has declared no tool classification observes any behavior change from this plan's migration alone").
- **No blockers.** `examples/support_copilot/deps/**/_build/**/source.dag` checked clean (no dirty rebar3 artifacts) prior to this SUMMARY being written.

---
*Phase: 57-confluence-escalation-gate*
*Completed: 2026-07-28*
