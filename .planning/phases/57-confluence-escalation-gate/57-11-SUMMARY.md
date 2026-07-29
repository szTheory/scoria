---
phase: 57-confluence-escalation-gate
plan: 11
subsystem: workflows
tags: [ecto, phoenix-liveview, confluence-gate, audit-outbox, hitl]

# Dependency graph
requires:
  - phase: 57-07
    provides: "the escalation-time audit outbox row (blocker_audit_outbox_event_id back-link, Confluence.audit_metadata/1's closed key set)"
  - phase: 57-09
    provides: "the reviewer drawer's confluence evidence rows (ApprovalCopy.confluence_rows/1, witness_source_label/1, grade_label/1) with no data source"
provides:
  - "Escalation-time confluence evidence (combination, grade, three leg sources) read into RemoteApprovalProjection.project_approval/2 from the approval's own blocker_audit_outbox_event_id back-link"
  - "The SAME evidence read reaches all three reviewer entry points: get_approval_lineage!/1, list_pending_approvals/1, list_decided_approvals/1"
  - "A closed four-pair string-to-atom map for leg sources, with an :unknown catch-all -- never String.to_atom/1 on persisted JSON"
  - "A batch loader (one query per rendered page, zero when a page has no confluence approvals) proving D-51's no-N+1 property via telemetry query counting"
  - "End-to-end tests driving a real Scoria.MCP.Executor.execute/4 escalation through to rendered HTML in the approvals drawer"
affects: [58-confluence-followups]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Batch-load-by-visible-id-set for a second data source at a list projection call site, mirroring ApprovalsLive.Index.decision_events_by_approval_id/1"
    - "Closed string-to-atom conversion map with an :unknown fallback, never String.to_atom/1 on persisted JSON"
    - "Telemetry-based query-count assertion ([:scoria, :repo, :query] filtered by metadata.source) to prove a no-N+1 property directly instead of asserting it in prose"

key-files:
  created:
    - test/scoria/confluence_reviewer_evidence_test.exs
  modified:
    - lib/scoria/workflows/remote_approval_projection.ex
    - test/scoria/workflows/remote_approval_projection_test.exs
    - test/scoria_web/live/approvals_live_test.exs

key-decisions:
  - "SRE.build_audit_metadata/1 is a DROP-LIST over the whole envelope, not an allowlist keyed on an incoming metadata: field -- a test fixture that wraps evidence fields under metadata: %{...} silently double-nests them under one literal \"metadata\" key. Fixtures must merge evidence fields at the envelope's top level, exactly like Executor.record_confluence_audit/5 does."
  - "Removed the now-unused default value on the private project_approval/2 (all three call sites pass an explicit events-by-id map after Task 2; Task 1's default existed only to keep the single-arg call shape compiling mid-rollout)."
  - "list_pending_approvals/1 and list_decided_approvals/1 each build the confluence audit events-by-id map ONCE per Repo.all() page rather than per-row, so D-51's pagination cap is not undone by an N+1 at the same call site it protects."

requirements-completed: [GATE-02, GATE-03]

coverage:
  - id: D1
    description: "A confluence approval produced by a real Executor.execute/4 escalation renders the named combination through the lineage read (Task 1, prior agent, commit a5eed440)"
    requirement: "GATE-02"
    verification:
      - kind: unit
        ref: "test/scoria/confluence_reviewer_evidence_test.exs#Executor.execute/4 through RemoteApprovalProjection.get_approval_lineage!/1 through ApprovalCopy.request_rows/1 renders the named combination"
        status: pass
    human_judgment: false
  - id: D2
    description: "The same escalation's three leg rows and evidence-grade row render non-blank via both get_approval_lineage!/1 and list_pending_approvals/1"
    requirement: "GATE-02"
    verification:
      - kind: unit
        ref: "test/scoria/confluence_reviewer_evidence_test.exs#get_approval_lineage!/1 and list_pending_approvals/1 both render all three leg rows and the evidence grade, non-blank"
        status: pass
    human_judgment: false
  - id: D3
    description: "list_pending_approvals/1 and list_decided_approvals/1 project confluence evidence for every confluence row on a page via one batch query, and defensive cases (nil, dangling, foreign-run back-link, unrecognized leg source, non-confluence approval) degrade honestly with no fabricated value"
    requirement: "GATE-03"
    verification:
      - kind: unit
        ref: "test/scoria/workflows/remote_approval_projection_test.exs#confluence evidence projection (D-40, D-48)"
        status: pass
      - kind: unit
        ref: "test/scoria/workflows/remote_approval_projection_test.exs#confluence evidence batch query (D-51 no N+1)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A real confluence escalation renders the combination, the leg witness labels, and the evidence grade in the ACTUAL rendered approvals-drawer HTML (not just the row list), and a non-confluence approval's rendered HTML contains none of those strings"
    requirement: "GATE-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/approvals_live_test.exs#a reviewer sees the named combination, the legs with their sources, and the grade"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-07-29
status: complete
---

# Phase 57 Plan 11: Confluence reviewer evidence wiring Summary

**Wires the escalation-time confluence evidence (combination, grade, three leg sources) from the approval's own audit-outbox back-link into all three reviewer entry points -- lineage read, pending list, decided list -- and proves it end-to-end against a real `Scoria.MCP.Executor.execute/4` escalation rendered in the actual approvals drawer, not a hand-built fixture.**

## Performance

- **Duration:** ~25 min (this continuation agent; Task 1 was executed and committed by a prior agent before this session started)
- **Started:** 2026-07-29T14:44Z (approx, this agent's Task 2 start)
- **Completed:** 2026-07-29T15:03Z
- **Tasks:** 3 (Task 1 by prior agent, Tasks 2-3 by this agent)
- **Files modified:** 4 (1 lib file, 3 test files; 1 test file newly created by Task 1)

## Accomplishments

- `RemoteApprovalProjection.project_approval/2` reads `:combination`, `:grade`, `:private_data_source`, `:untrusted_content_source`, `:exfil_source` from the approval's `blocker_audit_outbox_event_id` back-linked `AuditOutboxEvent`, scoped to `event_type == "tool.confluence.escalated"` AND `workflow_run_id` match -- never defaulted, inferred, or synthesized.
- The SAME evidence read now reaches `get_approval_lineage!/1` (Task 1), `list_pending_approvals/1` and `list_decided_approvals/1` (Task 2), each via ONE batch query per rendered page (D-51), proven directly via telemetry query counting rather than asserted in prose.
- The three leg-source values convert through a hardcoded four-pair string-to-atom map (`declared`, `scanner_infra`, `default_tier`, `unclassified`) with an `:unknown` catch-all -- `String.to_atom/1`/`String.to_existing_atom/1` are never called on persisted JSON.
- Defensive cases pinned by test: nil back-link, dangling back-link (random UUID), foreign-run back-link, and an unrecognized leg-source string all degrade to nil/`:unknown` with no fabricated value and no crash; a non-confluence approval's rows stay byte-identical to their pre-phase value.
- End-to-end proof at three levels: (1) a real executor escalation projected through `get_approval_lineage!/1` and `list_pending_approvals/1` renders the combination, all three leg rows, and the grade row via `ApprovalCopy.request_rows/1`; (2) the same escalation, mounted in the actual `ApprovalsLive.Index` LiveView and rendered, shows those same strings in the drawer HTML; (3) a non-confluence approval's rendered HTML contains none of them.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end -- a real escalation's Combination row is non-blank in the drawer's rows** - `a5eed440` (feat) -- executed by a prior agent before this continuation session; independently re-verified by the orchestrator (file diff, test pass, symbol presence) before this agent resumed.
2. **Task 2: Expand to the list paths, all three legs, the grade, and the defensive cases** - `1bb2860b` (test, RED) then `ec549968` (feat, GREEN)
3. **Task 3: The reviewer-facing proof -- a real escalation rendered in the actual approvals drawer** - `d6338175` (test)

_Note: Task 2 carries `tdd="true"` and followed the full RED/GREEN cycle: `1bb2860b` added the list-path assertions and confirmed they failed (list functions still called `project_approval/1` with no events-by-id map), then `ec549968` made them pass._

## Files Created/Modified

- `lib/scoria/workflows/remote_approval_projection.ex` - Adds the confluence audit event-type constant, the closed leg-source map, the batch loader (`confluence_audit_events_by_id/1`), the per-approval evidence resolver (`confluence_evidence_fields/2`), and `project_approval/2`; threads the batch loader through `list_pending_approvals/1` and `list_decided_approvals/1` (Task 2) as well as `get_approval_lineage!/1` (Task 1).
- `test/scoria/confluence_reviewer_evidence_test.exs` - New (Task 1). Extended (Task 2) with a describe block proving the three leg rows and grade row render non-blank via both `get_approval_lineage!/1` and `list_pending_approvals/1` for the same real escalation.
- `test/scoria/workflows/remote_approval_projection_test.exs` - New `confluence evidence projection (D-40, D-48)` describe block (6 tests: real audit row, nil back-link, dangling back-link, foreign-run back-link, unrecognized leg source, non-confluence approval) and `confluence evidence batch query (D-51 no N+1)` describe block (2 tests, telemetry-based query counting).
- `test/scoria_web/live/approvals_live_test.exs` - New `RealConfluenceThreeLegTool` fixture module and `real_confluence_approval/1` helper (distinct from the pre-existing synthetic `pending_confluence_approval/1`, left untouched), plus a describe block rendering the real escalation's drawer HTML and asserting the combination, leg-witness label, and grade label are present, and absent for a non-confluence approval.

## Decisions Made

- `SRE.build_audit_metadata/1` is a DROP-LIST over the whole audit envelope, not an allowlist keyed on an incoming `metadata:` field. A test fixture that wraps evidence fields under `metadata: %{...}` (rather than merging them at the envelope's top level, as `Executor.record_confluence_audit/5` does) silently double-nests them under one literal `"metadata"` key in the persisted row -- this was caught by the RED/GREEN cycle (the "real audit row" test failed with `combination: nil` even after the list-path fix landed) and fixed in the test helper, not the implementation.
- Removed the now-unused default value (`\\ %{}`) on the private `project_approval/2`: after Task 2, all three call sites (`get_approval_lineage!/1`, `list_pending_approvals/1`, `list_decided_approvals/1`) pass an explicit events-by-id map, so the default -- which existed only to keep Task 1's single-arg call shape compiling mid-rollout -- became a compile warning under `--warnings-as-errors`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused default argument on `project_approval/2`**
- **Found during:** Task 2 (batch-loading `list_pending_approvals/1`/`list_decided_approvals/1`)
- **Issue:** After both list functions were changed to pass an explicit events-by-id map, the private `project_approval/2`'s `events_by_id \\ %{}` default became dead code, tripping `mix compile --warnings-as-errors`.
- **Fix:** Dropped the default; the function now requires the second argument, which every call site already supplies.
- **Files modified:** `lib/scoria/workflows/remote_approval_projection.ex`
- **Verification:** `mix compile --warnings-as-errors` exits 0.
- **Committed in:** `ec549968` (Task 2 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 bug/warning cleanup)
**Impact on plan:** No scope creep -- a direct, mechanical consequence of Task 2's own list-path wiring, not a new behavior.

## Issues Encountered

- A transient full-suite run (`mix test --warnings-as-errors`) reported 2 failures on one seed; a clean re-run reported exactly the expected 1 (`Scoria.WarningInventory.CaptureParityTest`, the documented pre-existing baseline from `WINDOWS.md` entry 1, independently reproduced at pre-phase-57 baseline `5a9d0f8f`). The re-run's failure detail matches that baseline test byte-for-byte (same assertion, same injected-warning fixture) -- not a regression from this plan's changes. No `async: false` confluence test in this plan shares mutable process-global state with `CaptureParityTest`, so the discrepancy is attributed to unrelated suite-level flakiness rather than anything touched here.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- GATE-02 (escalation gate reviewer evidence) and GATE-03 (audit/replay contract read side) are now provably closed end-to-end: a real executor escalation's evidence reaches all three reviewer surfaces (lineage, pending list, decided list) and renders in the actual drawer HTML.
- Phase 57's plan 57-12 (gap-closure: requirement bookkeeping) can now mark GATE-02/GATE-03 complete against this plan's proof.
- `.planning/phases/57-confluence-escalation-gate/57-VERIFICATION.md` should be re-run against this plan's artifacts if the phase's gap-closure audit expects a fresh pass.

---
*Phase: 57-confluence-escalation-gate*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 4 modified/created files found on disk; all 4 task commits (`a5eed440`, `1bb2860b`, `ec549968`, `d6338175`) found in git history.
