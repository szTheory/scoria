---
phase: 38-replay-safe-execution-tool-modes
plan: 01
subsystem: database
tags: [replay, workflows, ecto, approvals, audit]
requires:
  - phase: 37-replay-lineage-branch-model
    provides: replay branch lineage fields and durable replay run creation semantics
provides:
  - seam-level replay disposition resolver contract
  - replay-safe run intent and approval authority columns
  - typed replay evidence columns on checkpoints, workflow events, and audit outbox rows
affects: [38-02 runtime enforcement, 38-03 operator projection, replay provenance]
tech-stack:
  added: [req, req_llm]
  patterns: [fail-closed replay seam resolution, typed replay evidence columns, replay idempotency storage]
key-files:
  created:
    - lib/scoria/workflows/replay_disposition.ex
    - test/scoria/workflows/replay_disposition_test.exs
    - priv/repo/migrations/20260523000100_add_replay_safe_execution_truth.exs
  modified:
    - mix.exs
    - mix.lock
    - lib/scoria/workflows/run.ex
    - lib/scoria/observe/approval.ex
    - lib/scoria/workflows/checkpoint.ex
    - lib/scoria/workflows/event.ex
    - lib/scoria/sre/audit_outbox_event.ex
key-decisions:
  - "Replay run intent stays on the run row as `live | replay`, while seam outcomes use `execute_live | historical_stub | blocked`."
  - "Replay evidence is stored in first-class columns on approvals, checkpoints, workflow events, and audit rows instead of metadata-only blobs."
  - "Local seam classification outranks remote replay hints, and exact-match source evidence is required before a replay may historical-stub an effectful seam."
patterns-established:
  - "ReplayDisposition.resolve/5 is the shared seam gate for replay decisions and evidence assembly."
  - "Replay-live retries carry a durable replay idempotency key rather than ambient replay state."
requirements-completed: [RPLY-02]
duration: 8min
completed: 2026-05-23
---

# Phase 38 Plan 01: Replay-Safe Execution Truth Summary

**Replay-safe seam resolution with typed approval, checkpoint, event, and audit evidence plus replay-only run intent**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-23T09:23:24Z
- **Completed:** 2026-05-23T09:31:25Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Added a TDD-backed `Scoria.Workflows.ReplayDisposition` contract that resolves `:execute_live`, `:historical_stub`, and `:blocked` from local seam classification, source lineage, approvals, and replay overrides.
- Narrowed workflow run replay intent to `live | replay` and added explicit replay authority, lineage, and dedupe fields on approvals.
- Extended checkpoints, workflow events, and audit outbox rows with typed replay evidence so later runtime enforcement and operator projection phases can read durable truth directly.

## Task Commits

Each task was committed atomically:

1. **Task 1: Define replay disposition contract and decision table** - `9f67c02` (test), `819c0e3` (feat)
2. **Task 2: Add migration and schema fields for run intent and replay authority** - `e2e8e29` (feat)
3. **Task 3: Add typed replay evidence columns to checkpoints, events, and audit rows** - `591ee5a` (feat)

**Supporting deviation commit:** `8ec6ad0` (chore)

## Files Created/Modified

- `lib/scoria/workflows/replay_disposition.ex` - shared replay seam decision resolver and typed evidence builder
- `test/scoria/workflows/replay_disposition_test.exs` - red/green replay contract coverage for live, stubbed, blocked, and override cases
- `priv/repo/migrations/20260523000100_add_replay_safe_execution_truth.exs` - reversible schema migration for replay intent, authority, lineage, and dedupe columns
- `lib/scoria/workflows/run.ex` - run-level replay intent and override fields with narrowed execution mode validation
- `lib/scoria/observe/approval.ex` - replay authority, lineage, dedupe, and remote-approval evidence fields
- `lib/scoria/workflows/checkpoint.ex` - typed replay disposition and reason fields
- `lib/scoria/workflows/event.ex` - typed replay disposition and reason fields
- `lib/scoria/sre/audit_outbox_event.ex` - replay lineage and idempotency fields on audit rows
- `mix.exs` and `mix.lock` - direct `req` and `req_llm` runtime dependency declaration for existing compile paths

## Decisions Made

- Kept replay-safe reasoning in a standalone resolver module so later runtime and connector seams can consume one contract instead of re-deriving replay rules.
- Stored replay truth in schema columns across operator-trusted tables, leaving payload and metadata maps as supplementary evidence only.
- Preserved the legacy `historical_stubbed` string only as migration compatibility input; the durable contract going forward is run intent `replay` plus seam-level disposition evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Declared missing runtime deps already used by the app**
- **Found during:** Task 1 (Define replay disposition contract and decision table)
- **Issue:** `mix test` could not compile existing `Req` and `ReqLLM` call sites because `mix.exs` did not declare those direct dependencies.
- **Fix:** Added `req` and `req_llm` to `mix.exs` and refreshed `mix.lock`.
- **Files modified:** `mix.exs`, `mix.lock`
- **Verification:** `mix test test/scoria/workflows/replay_disposition_test.exs`
- **Committed in:** `8ec6ad0`

**2. [Rule 2 - Missing Critical] Persisted existing remote-approval evidence fields alongside replay authority**
- **Found during:** Task 2 (Add migration and schema fields for run intent and replay authority)
- **Issue:** Current workflow and connector code already emit blocker, grant, connector, and audit lineage attributes that were not durable in `ai_approvals`.
- **Fix:** Added the missing remote-approval evidence columns and schema fields together with the new replay authority contract.
- **Files modified:** `priv/repo/migrations/20260523000100_add_replay_safe_execution_truth.exs`, `lib/scoria/observe/approval.ex`
- **Verification:** `mix ecto.migrate && mix ecto.rollback --step 1 && mix ecto.migrate`
- **Committed in:** `e2e8e29`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing critical)
**Impact on plan:** Both fixes were required to make the plan executable and to keep replay authority durable in the current branch without scope drift.

## Issues Encountered

- The branch carried unrelated compile warnings for missing modules and an `EvalSpec.dataset_id` type warning, but they did not block this plan’s migration or focused test lanes.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Replay disposition truth is now durable enough for runtime seam enforcement and operator projection work in later phase-38 plans.
- Approval, checkpoint, event, and audit records now expose stable source lineage and replay idempotency fields for downstream enforcement and UI reads.

## Self-Check: PASSED

- Found summary file: `.planning/phases/38-replay-safe-execution-tool-modes/38-01-SUMMARY.md`
- Found commits: `8ec6ad0`, `9f67c02`, `819c0e3`, `e2e8e29`, `591ee5a`
