---
phase: 39-component-groups-and-operator-flows
plan: 03
subsystem: ui
tags: [phoenix, liveview, ecto, elixir, approvals, audit-outbox]

# Dependency graph
requires:
  - phase: 39-component-groups-and-operator-flows (plan 01/02)
    provides: ScoriaWeb.UI status_label/1 additive upgrade + ScoriaWeb.Copy/per-domain copy modules
provides:
  - "ApprovalCopy.status_line/1, eyebrow/1, decision_outcome/1 (\"Denied\", D-24d), impact_lead/1, decision_receipt/3 — the decision-copy SSOT"
  - "Workflows.list_decided_approvals/1 — bounded, filterable decided-approval projection"
  - "dev_seed.exs decided/expired fixtures routed through Workflows.approve/3 (real audit trail)"
  - "test/scoria/workflows/approval_write_invariant_guard_test.exs — D-20 write-invariant guard + projection scope/order/filter tests"
affects: ["39-06 (approval drawer decision-first redesign)", "39-07 (decision-history surface)"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Decision-copy SSOT: ApprovalCopy owns all decision-status strings including the single home for the word \"Denied\" (D-24d) — no other module may re-derive it."
    - "Honest-receipt pattern (D-27): a receipt helper takes decider/decided-at as explicit caller-supplied arguments (never self-sources them) and never asserts side-effect/run-continuation success — only the recorded decision."
    - "Projection bounding: list_decided_approvals/1 mirrors list_pending_approvals/1's where→apply_filters→order_by→Repo.all→Enum.map(&project_approval/1) pipeline, adding a Map.pop(:limit, default) cap."
    - "Write-invariant source-scan guard: bounded lookahead classifies Approval.changeset(...) call sites as :insert vs :update, allow-listing exact {file, line} pairs; comment lines are stripped first so the guard's own doc comments (which quote the patterns it scans for) never self-trigger."

key-files:
  created:
    - test/scoria/workflows/approval_write_invariant_guard_test.exs
  modified:
    - lib/scoria_web/approval_copy.ex
    - lib/scoria/workflows/remote_approval_projection.ex
    - lib/scoria/workflows.ex
    - priv/repo/dev_seed.exs
    - test/scoria_web/approval_copy_test.exs

key-decisions:
  - "decision_receipt/3 reuses decision_outcome/1 internally for the plain-word fallback so \"Denied\" has exactly one literal source in the codebase (D-24d)."
  - "Expired receipts may show a real audit-event time (\"Expired · {time}\") but never a fabricated actor — no operator decides an expiry, so decision_receipt/3 has no \"Expired by {actor}\" clause at all, not even a guarded one."
  - "list_decided_approvals/1 takes an optional :limit filter (default 50) rather than a separate keyword arg, keeping the single-map call signature identical to list_pending_approvals/1; offset/cursor load-more wiring is deferred to Plan 07."
  - "The two update_all cleanup blocks in dev_seed.exs (legacy-tool and stale-seed-version expiry) were both routed through Workflows.approve(id, \"expired\") via a shared expire_via_approve/1 closure that queries matching ids first, then approves each and counts successes — preserving the existing log-message counts."
  - "The D-20 write-invariant guard allow-lists exactly two Approval.changeset(...) → update! call sites by {file, line}: the creation-time audit_outbox_event_id backfill (still \"pending\") and the decision write inside approve/3 (the pending→decided transition itself). A grep across lib/scoria + priv/repo confirmed no other Approval-row writer exists."

patterns-established:
  - "Decision-copy additions to ApprovalCopy always delegate the \"Denied\" string to decision_outcome/1, never re-literal it."
  - "Any new decided/expired seed fixture must route through Workflows.approve/3, never Repo.update_all on the Approval schema — enforced by the write-invariant guard's update_all scan."

requirements-completed: [FLOW-03, FLOW-04, COPY-01]

coverage:
  - id: D1
    description: "ApprovalCopy extended with status_line/1, eyebrow/1, decision_outcome/1 (\"Denied\"), impact_lead/1, and decision_receipt/3; raw status-atom evidence row deleted from evidence_rows/1"
    requirement: "COPY-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/approval_copy_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Workflows.list_decided_approvals/1 — bounded, filterable projection scoping to approved/rejected/expired, ordered desc updated_at/id, reusing apply_filters/project_approval/normalize_filters"
    requirement: "FLOW-04"
    verification:
      - kind: unit
        ref: "test/scoria/workflows/approval_write_invariant_guard_test.exs#list_decided_approvals/1 (bounded projection)"
        status: pass
    human_judgment: false
  - id: D3
    description: "dev_seed.exs decided/expired fixtures route through Workflows.approve/3 instead of Repo.update_all, plus a warning-grade write-invariant guard asserting no unlisted Approval-row write exists"
    requirement: "FLOW-04"
    verification:
      - kind: unit
        ref: "test/scoria/workflows/approval_write_invariant_guard_test.exs#approval write-invariant guard (D-20, warning-grade source scan)"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-03
status: complete
---

# Phase 39 Plan 03: Approval Decision-Copy + History Data Foundation Summary

**Extended `ApprovalCopy` as the decision-copy SSOT with an honest D-27 receipt helper, added `Workflows.list_decided_approvals/1`, and routed dev-seed decided/expired fixtures through the real `approve/3` path guarded by a new write-invariant test.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-03
- **Tasks:** 3
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments

- `ApprovalCopy` now owns `status_line/1`, `eyebrow/1`, `decision_outcome/1` (the single home for "Denied", D-24d), `impact_lead/1`, and `decision_receipt/3` — a decided-receipt helper that states the recorded decision only, never side-effect/run-continuation success, and never fabricates a decider or time for "Expired" absent a real audit event (⚠ SAFETY D-27).
- Deleted the raw `{"Status", field(approval, :status)}` row from `evidence_rows/1` — it duplicated the status badge and leaked a raw atom (D-16/D-23).
- Added `Workflows.list_decided_approvals/1`, mirroring `list_pending_approvals/1` exactly (`where` → `apply_filters` → `order_by` → `Repo.all` → `Enum.map(&project_approval/1)`), scoping to `approved`/`rejected`/`expired`, ordering `desc updated_at, desc id` as a proxy sort only, and bounded via an optional `:limit` filter (default 50) for capped + load-more (D-10/D-20).
- Routed `dev_seed.exs`'s two decided/expired fixture-cleanup blocks through `Workflows.approve(id, "expired")` instead of `Repo.update_all(set: [status: ...])`, so seeded fixtures emit the real decision audit event and bump `updated_at` (D-21).
- Added `test/scoria/workflows/approval_write_invariant_guard_test.exs`: a warning-grade source-scan guard asserting every `Approval.changeset(...)` call site that terminates in an update is on a 2-entry allow-list (the creation-time `audit_outbox_event_id` backfill and the single decision write inside `approve/3`), plus a scan confirming no `update_all(...)` call site anywhere in `lib/scoria` or `priv/repo` references the `Approval` schema (D-20).

## Task Commits

Each task was committed atomically (Tasks 1 and 2 followed the RED→GREEN TDD flow):

1. **Task 1: Extend ApprovalCopy as the decision-copy SSOT and delete the raw status row**
   - `272031e` test(39-03): add failing tests for ApprovalCopy decision-copy SSOT extensions (RED)
   - `89fb198` feat(39-03): extend ApprovalCopy as the decision-copy SSOT (D-16, D-24d, D-27) (GREEN)
2. **Task 2: Add Workflows.list_decided_approvals/1 (bounded projection)**
   - `24bf0ed` test(39-03): add failing test for Workflows.list_decided_approvals/1 (RED)
   - `f64c01e` feat(39-03): add Workflows.list_decided_approvals/1 (bounded projection, D-20) (GREEN)
3. **Task 3: Route decided/expired fixtures through approve/3 and guard the write invariant**
   - `86d35dd` feat(39-03): route decided/expired fixtures through approve/3, guard the write invariant

**Plan metadata:** (this commit)

_Note: Tasks 1 and 2 were marked `tdd="true"` and have separate RED (`test(...)`)/GREEN (`feat(...)`) commits. Task 3 is a plain `auto` task._

## Files Created/Modified

- `lib/scoria_web/approval_copy.ex` - added `status_line/1`, `eyebrow/1`, `decision_outcome/1`, `impact_lead/1`, `decision_receipt/3`; deleted the raw status-atom evidence row
- `test/scoria_web/approval_copy_test.exs` - coverage for all five new functions, including the "Denied" and no-fabrication cases
- `lib/scoria/workflows/remote_approval_projection.ex` - added `list_decided_approvals/1`
- `lib/scoria/workflows.ex` - added the `list_decided_approvals/1` public delegate
- `priv/repo/dev_seed.exs` - replaced both `Repo.update_all(set: [status: "expired"])` fixture blocks with `Workflows.approve(id, "expired")` via a shared `expire_via_approve/1` closure
- `test/scoria/workflows/approval_write_invariant_guard_test.exs` (new) - `list_decided_approvals/1` scope/order/filter/bound tests + the D-20 write-invariant source-scan guard

## Decisions Made

- `decision_receipt/3` reuses `decision_outcome/1` internally for its plain-word fallback so "Denied" has exactly one literal source in the codebase (D-24d single-home rule).
- Expired receipts may show a real audit-event time (`"Expired · {time}"`) but never a fabricated actor — there is no `"Expired by {actor}"` clause at all, since no operator decides an expiry.
- `list_decided_approvals/1` takes filters as a single map (matching `list_pending_approvals/1`'s signature) with an optional `:limit` key rather than a separate arg; offset/cursor "load more" wiring is deferred to the Plan 07 history-surface UI.
- The write-invariant guard's `update_all` scan strips whole-line comments before matching, so its own doc comments (which quote `Repo.update_all(set: [status: ...])` as the pattern being guarded against) never self-trigger a false positive.

## Deviations from Plan

None - plan executed exactly as written. Both TDD tasks followed the RED→GREEN flow; Task 3 required no additional fixes since the codebase already had exactly one legitimate creation-time `Approval` updater to allow-list (verified via a full-repo grep before writing the guard).

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `ApprovalCopy`'s new decision-copy SSOT and `Workflows.list_decided_approvals/1` are ready for Plan 06 (approval drawer decision-first redesign) and Plan 07 (decision-history surface) to compose.
- `decision_receipt/3` expects the caller to source `decider`/`decided_at` from the decision `AuditOutboxEvent` via a new `approval_decision_event/1` lookup (not built in this plan) — Plan 07's job per D-20.
- No `approvals_live/index.ex` edits were made in this plan (by design, to avoid Wave 1 file overlap); the new `ApprovalCopy`/`list_decided_approvals/1` functions are unused until Plans 06/07 wire them in.
- ds06 drift guard and token-contrast guard remain green; full `mix compile --warnings-as-errors` and the `test/scoria/workflows/` + approval-copy + guard test suites (74 tests) all pass.

---
*Phase: 39-component-groups-and-operator-flows*
*Completed: 2026-07-03*

## Self-Check: PASSED

All created/modified files exist on disk and all 5 task commit hashes (`272031e`, `89fb198`, `24bf0ed`, `f64c01e`, `86d35dd`) resolve in `git log`.
