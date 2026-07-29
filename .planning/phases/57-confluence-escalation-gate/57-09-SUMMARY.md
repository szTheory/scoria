---
phase: 57-confluence-escalation-gate
plan: 09
subsystem: agent-security
tags: [elixir, phoenix-liveview, ecto, confluence-gate, approvals, dashboard-ui]

# Dependency graph
requires:
  - phase: 57-confluence-escalation-gate
    plan: 01
    provides: "The escalation path (waiting_for_approval run/step/ai_approvals triple with blocker_kind: \"confluence\"), the locked D-25/D-50 checkpoint decisions, and the ai_approvals.confluence_scope column"
  - phase: 57-confluence-escalation-gate
    plan: 02
    provides: "Scoria.Confluence.combinations/0 (eight-value enum), grades/0, and the Evidence struct field names (combination/grade/private_data_source/untrusted_content_source/exfil_source) this plan's copy renders from"
provides:
  - "ScoriaWeb.ApprovalCopy.combination_label/1 and combination_tone/1 — a pinned enum-to-string/tone mapping over Scoria.Confluence.combinations/0, tested for every value (D-49)"
  - "ScoriaWeb.ApprovalCopy.request_rows/1 extended with confluence evidence rows (combination, one row per lit leg with its witness source, evidence grade) for a blocker_kind: \"confluence\" approval, byte-identical for every other approval (D-48)"
  - "A bounded run-scoped approve action (\"Approve <tool> for the rest of this run\") in the approvals drawer, confluence approvals only, setting Approval.confluence_scope through a non-cast Repo.update_all rather than the changeset cast list (D-50, D-44)"
  - "Scoria.Workflows.RemoteApprovalProjection.list_pending_approvals/1 capped with the same page-size attribute and limit-popping pattern list_decided_approvals/1 already used (D-51)"
affects: [58-safety-hooks-security-boundary-govern-surface]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Evidence-row field names on the approval map deliberately mirror %Scoria.Confluence.Evidence{}'s own field names (combination, grade, private_data_source, untrusted_content_source, exfil_source) so a future integration that persists the struct onto the approval needs no translation layer at the copy boundary"
    - "confluence_scope written through a bare Repo.update_all, not the Approval changeset — the same non-cast write class the D-26 consume CAS uses, so a caller can never widen a grant through pass-through decision attrs"
    - "Pending-approval pagination reuses the exact @decided_default_limit attribute and limit-popping pattern list_decided_approvals/1 already established, rather than inventing a second pagination shape"

key-files:
  created: []
  modified:
    - lib/scoria_web/approval_copy.ex
    - lib/scoria_web/live/approvals_live/index.ex
    - lib/scoria/workflows/remote_approval_projection.ex
    - test/scoria_web/approval_copy_test.exs
    - test/scoria_web/live/approvals_live_test.exs
    - test/scoria/workflows/remote_approval_projection_test.exs

key-decisions:
  - "D-50 precondition honored as recorded: 57-01-SUMMARY.md pins the developer's checkpoint answer as d50-scope (bounded per-run/per-tool/per-grade scope) — this plan implements the bounded-scope action, not the documented-caveat substitution"
  - "Confluence evidence row field names chosen to mirror Scoria.Confluence.Evidence's own struct field names verbatim, since no schema/executor change in this plan's file scope persists the struct onto the approval yet — see Known Gaps below"
  - "confluence_scope set via Repo.update_all (not Approval.changeset/2, which deliberately excludes it from cast/3) to preserve the non-cast write invariant plan 01 established for the opposite-polarity D-26 fields"

patterns-established:
  - "A decision-modal action beyond approve/reject (approve_run_scoped) is added by extending the existing open_decision_modal/decision_title/decision_badge/decision_tone/decision_confirm_copy dispatch chain with one more clause each, not by branching the modal component itself"

requirements-completed: [GATE-02]

coverage:
  - id: D1
    description: "Every value of Scoria.Confluence.combinations/0 has a pinned label and tone (fail/warn/neutral); the all-three-legs combination renders the verbatim operator string with the rightwards arrow and the fail tone; unrecognized values fall back to a neutral label without raising"
    requirement: "GATE-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/approval_copy_test.exs#combination_label/1 and combination_tone/1 (D-49) every value of Scoria.Confluence.combinations/0 has a non-empty label and a valid tone"
        status: pass
      - kind: unit
        ref: "test/scoria_web/approval_copy_test.exs#combination_label/1 and combination_tone/1 (D-49) the all-three-legs combination renders the verbatim operator string with the rightwards arrow and fail tone"
        status: pass
      - kind: unit
        ref: "test/scoria_web/approval_copy_test.exs#combination_label/1 and combination_tone/1 (D-49) an unrecognized combination value falls back to a neutral label and never raises"
        status: pass
    human_judgment: false
  - id: D2
    description: "A confluence approval's request rows include a combination row, one row per lit leg with its witness source, and a grade row; a non-confluence approval's rows are unchanged"
    requirement: "GATE-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/approval_copy_test.exs#request_rows/1 (D-48 confluence evidence rows) a confluence approval's rows include the combination, one row per lit leg with its source, and a grade row"
        status: pass
      - kind: unit
        ref: "test/scoria_web/approval_copy_test.exs#request_rows/1 (D-48 confluence evidence rows) a non-confluence approval's request rows are unchanged from their pre-phase values"
        status: pass
    human_judgment: false
  - id: D3
    description: "The bounded run-scoped approve action renders only for a confluence approval, sets confluence_scope to \"run_tool\" on invocation, and leaves confluence_scope at its default when the plain approve action is used instead"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria_web/live/approvals_live_test.exs#D-50 bounded run-scoped approve action the scoped action renders only for a confluence approval"
        status: pass
      - kind: integration
        ref: "test/scoria_web/live/approvals_live_test.exs#D-50 bounded run-scoped approve action invoking the scoped action sets confluence_scope to the run-scoped value and approves"
        status: pass
      - kind: integration
        ref: "test/scoria_web/live/approvals_live_test.exs#D-50 bounded run-scoped approve action invoking the plain approve action on a confluence approval leaves the scope at its default"
        status: pass
    human_judgment: false
  - id: D4
    description: "list_pending_approvals/1 returns at most the default page size when more pending approvals exist, honors an explicit limit, and leaves filter/ordering/decided-query behavior unchanged"
    verification:
      - kind: unit
        ref: "test/scoria/workflows/remote_approval_projection_test.exs#list_pending_approvals/1 cap (D-51) returns at most the default page size when more pending approvals exist"
        status: pass
      - kind: unit
        ref: "test/scoria/workflows/remote_approval_projection_test.exs#list_pending_approvals/1 cap (D-51) an explicit limit overrides the default, exactly as list_decided_approvals/1 allows"
        status: pass
      - kind: unit
        ref: "test/scoria/workflows/remote_approval_projection_test.exs#list_pending_approvals/1 cap (D-51) list_decided_approvals/1 returns the same results as before the change for an identical fixture"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-07-29
status: complete
---

# Phase 57 Plan 09: Reviewer Evidence, Bounded Scoped-Approve, and a Capped Pending Query Summary

**`ApprovalCopy` gains a pinned combination-to-label/tone mapping and confluence evidence rows (D-48/D-49), the approvals drawer gains a bounded run-scoped approve action writing `confluence_scope` through a non-cast update (D-50), and `list_pending_approvals/1` is capped with the same page-size pattern the decided-approvals query already used (D-51).**

## Performance

- **Duration:** 14 min (git-timestamp span from base commit `a401b56a` to final Task 3 commit `4fba424c`)
- **Started:** 2026-07-28T23:02:25-04:00 (base commit)
- **Completed:** 2026-07-28T23:16:09-04:00
- **Tasks:** 3 (Task 1 auto/tdd, Task 2 auto, Task 3 auto/tdd)
- **Files modified:** 6 (0 created, 6 modified)

## Accomplishments

- `ScoriaWeb.ApprovalCopy.combination_label/1` and `combination_tone/1` cover all eight `Scoria.Confluence.combinations/0` values — a table-driven test iterates the enum so an unlabeled future combination fails here, in the phase that owns the enum, rather than surfacing as a breaking change when Phase 58 builds the Govern screen. `"exfiltration_path"` renders the exact operator string `Private data + untrusted content + external egress → exfiltration path` (rightwards-arrow character) with the fail tone; the three two-leg combinations get distinct warn-toned labels; single legs and `"none"` get neutral labels; any unrecognized value falls back to a neutral generic label without raising.
- `ApprovalCopy.request_rows/1` renders a `"Combination"` row, one `"<Leg> evidence"` row per lit leg (naming the witness source — declared by the tool, observed by the content scanner, default tier, unclassified, or an "Unknown source" fallback), and an `"Evidence grade"` row for a `blocker_kind: "confluence"` approval; a non-confluence approval's rows stay byte-identical to their pre-phase shape, asserted by an exact-list-equality test.
- The approvals drawer's decision area gains one additional action, confluence approvals only: `"Approve <tool> for the rest of this run"`. It flows through the existing `open_decision_modal`/decision-modal dispatch chain (new `"approve_run_scoped"` clauses alongside `"approve"`/`"reject"` at every dispatch point: title, badge, tone, confirm copy) and, on confirm, calls `Workflows.approve/3` for the decision then sets `confluence_scope: "run_tool"` via a bare `Repo.update_all` — mirroring the D-26 consume CAS's non-cast write class rather than making the column castable, so a caller cannot widen a grant through pass-through decision attrs. The reviewer-facing copy states the bound explicitly: the grant is for this tool and ends when the run ends.
- `RemoteApprovalProjection.list_pending_approvals/1` now pops `:limit` from its filters and applies it, defaulting to the same `@decided_default_limit` attribute `list_decided_approvals/1` already used — no second pagination shape. Filter and ordering behavior for both queries is unchanged, proven against a small deterministic fixture (explicit `inserted_at`/`updated_at` timestamps, since UUID primary keys make insertion-order tie-breaking non-deterministic).

## Task Commits

1. **Task 1: Confluence evidence rows and the named-combination label mapping** - `6a2fc5f0` (feat)
2. **Task 2: Bounded scoped-approve action in the existing drawer** - `c5d9b6ab` (feat)
3. **Task 3: Cap the pending-approvals query** - `4fba424c` (feat)

_Note: this SUMMARY.md is committed separately per the worktree execution protocol (STATE.md/ROADMAP.md are owned by the orchestrator, not this plan)._

## Files Created/Modified

- `lib/scoria_web/approval_copy.ex` - `combination_label/1`, `combination_tone/1`, confluence evidence row builders wired into `request_rows/1`, `run_scoped_approve_label/1`, `run_scoped_decision_copy/1`, and the `"approve_run_scoped"` clauses on `decision_title/2`/`decision_badge/1`/`decision_copy/2`
- `lib/scoria_web/live/approvals_live/index.ex` - `approve_run_scoped` event handler, the drawer action button and modal footer button (confluence approvals only), `maybe_set_confluence_scope/2` (the non-cast `Repo.update_all` write), `confluence_approval?/1`, and the extended `open_decision_modal`/`decision_badge`/`decision_tone`/`decision_confirm_copy` dispatch clauses
- `lib/scoria/workflows/remote_approval_projection.ex` - `list_pending_approvals/1` pops `:limit` (default `@decided_default_limit`) and applies `limit/2`, mirroring `list_decided_approvals/1`
- `test/scoria_web/approval_copy_test.exs` - New `combination_label/1 and combination_tone/1 (D-49)` and `request_rows/1 (D-48 confluence evidence rows)` describe blocks
- `test/scoria_web/live/approvals_live_test.exs` - New `ApprovalHandlers.wait_for_confluence_approval/2` fixture, `pending_confluence_approval/1` helper, and a `D-50 bounded run-scoped approve action` describe block (4 tests)
- `test/scoria/workflows/remote_approval_projection_test.exs` - New `list_pending_approvals/1 cap (D-51)` describe block (4 tests) plus `insert_pending_approval/1`/`insert_decided_approval/1`/`insert_approval/1` fixture helpers

## Decisions Made

- **D-50 precondition honored, not re-decided:** `57-01-SUMMARY.md` records the developer's checkpoint answer as `d50-scope` (verbatim: "build the bounded per-run/per-tool/per-grade approval scope"). This plan's Task 2 precondition required implementing the bounded-scope action specifically (not the documented-caveat substitution), which is what was built.
- **Evidence row field names mirror `%Scoria.Confluence.Evidence{}` verbatim** (`combination`, `grade`, `private_data_source`, `untrusted_content_source`, `exfil_source`) rather than inventing new names, so a future plan that persists the struct onto the approval needs no translation layer at the `ApprovalCopy` boundary. See Known Gaps below — no plan in this wave writes those fields onto the persisted `ai_approvals` row yet.
- **`confluence_scope` written via `Repo.update_all`, never `Approval.changeset/2`** — the column is deliberately excluded from that changeset's cast list (a load-bearing rule from plan 01, guarding against a caller widening a grant through `Workflows.approve/3`'s pass-through attrs). This plan's write mirrors the same non-cast discipline the D-26 consume CAS (plan 05) uses for `consumed_at`/`consumed_by_step_id`.
- **Pending-page cap reuses the existing `@decided_default_limit` module attribute** rather than introducing a `@pending_default_limit` — the plan's own instruction was explicit that the two functions must differ only in status scope, not in pagination shape.

## Deviations from Plan

None - plan executed exactly as written. No Rule 1/2/3 auto-fixes were needed.

## Known Gaps

**Confluence evidence rows are ready to render but have no live data source yet.** `ApprovalCopy.request_rows/1`'s combination/leg/grade rows read `combination`, `grade`, `private_data_source`, `untrusted_content_source`, and `exfil_source` directly off the approval map — proven correct by synthetic fixtures in this plan's own test suite. But no plan in Phase 57's file scope (this one included, by design — `lib/scoria/mcp/executor.ex` and `lib/scoria/observe/approval.ex` are outside this plan's `files_modified`) currently persists `%Scoria.Confluence.Evidence{}` onto the `ai_approvals` row at escalation time; `escalate/3` in `lib/scoria/mcp/executor.ex` only sets `tool_name`, `blocker_kind: "confluence"`, and a free-text `reason: "confluence gate: #{evidence.combination}"`. So on today's actual executor-produced confluence approval, the new evidence rows are absent (silently filtered by `reject_blank_rows/1`) until a future plan wires a data source — `57-06-PLAN.md` names `Scoria.Workflows.Run.confluence_legs` as Phase 58's own re-derivation read path for the named combination, and `57-07-PLAN.md`'s audit-outbox metadata is the other candidate (mirroring how `decider_ref/1` in `approvals_live/index.ex` already reads decision-actor attribution from an audit event's metadata rather than a dedicated column). Logged to `.planning/WINDOWS.md` (`unmet-truth`, phase 57) so it stays visible at ship time.

This is not a functional regression from this plan — `ApprovalCopy`'s own behavior is fully correct and tested against every input it might receive — but the D-48 must-have truth ("a reviewer sees the named combination...") is only proven for the rendering layer, not end-to-end against a live executor-produced approval, as of this plan's completion.

## Issues Encountered

None beyond the Known Gap documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **The reviewer-facing copy layer is ready for Phase 58 to consume.** `combination_label/1`/`combination_tone/1` are pinned by an enum-iterating test that will fail loudly if Phase 58 (or any later plan) adds a ninth combination value without a label — the exact mechanism the plan's objective named as preventing a breaking change.
- **The bounded run-scoped approve action is fully wired and tested end-to-end** against a real `Runtime.execute_step/2`-produced confluence approval (not a synthetic projection), including the plain-approve-leaves-default-scope negative case.
- **The pending-approvals query is capped**, closing the D-51 volume risk the confluence escalation gate introduces, with the decided-approvals query proven unaffected.
- **Open integration seam (see Known Gaps):** a future plan needs to thread `Scoria.Confluence.Evidence` (or `Run.confluence_legs`, or the 57-07 audit-outbox metadata) into whatever map `@active_approval` resolves to in `approvals_live/index.ex`, so `ApprovalCopy.request_rows/1`'s combination/leg/grade rows actually render for a live escalation. This plan's field-name choice (mirroring `%Confluence.Evidence{}` verbatim) is meant to make that wiring a small, mechanical follow-up rather than a redesign.
- **No blockers.** `examples/support_copilot/deps/**/_build/**/source.dag` checked clean (no dirty rebar3 artifacts) prior to this SUMMARY being written; `mix compile --warnings-as-errors` and the full `test/scoria_web/` + `test/scoria/workflows/remote_approval_projection_test.exs` suites are green (481 tests, 0 failures).

---
*Phase: 57-confluence-escalation-gate*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 7 claimed files found on disk (`lib/scoria_web/approval_copy.ex`, `lib/scoria_web/live/approvals_live/index.ex`, `lib/scoria/workflows/remote_approval_projection.ex`, `test/scoria_web/approval_copy_test.exs`, `test/scoria_web/live/approvals_live_test.exs`, `test/scoria/workflows/remote_approval_projection_test.exs`, this SUMMARY.md); all 4 commits (`6a2fc5f0`, `c5d9b6ab`, `4fba424c`, `f590a7f1`) found in `git log --oneline --all`. `examples/support_copilot/deps` clean, `git status --short` clean after this commit.
