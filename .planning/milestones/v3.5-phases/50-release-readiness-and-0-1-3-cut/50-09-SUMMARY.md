---
phase: 50-release-readiness-and-0-1-3-cut
plan: 09
subsystem: testing
tags: [elixir, phoenix-liveview, ecto, knowledge-scope, approval-copy, ci-gap-closure]

# Dependency graph
requires:
  - phase: 50-release-readiness-and-0-1-3-cut
    provides: "REL-04 CI gap inventory (50-CI-GAP-INVENTORY.md) — Bucket E enumeration"
provides:
  - "Nested examples/support_copilot gallery suite green (9 tests, 0 failures)"
  - "test/scoria/support_copilot_gallery_test.exs proof passes (deps_get -> gallery_db -> gallery_test)"
affects: [50-10, 50-11, ci-verify-lane]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tenant-scoped Knowledge.ingest_source/2 calls in nested example apps must pass tenant_id explicitly (Scoria.Knowledge.Scope.for_write!/1 raises ArgumentError otherwise) — same shape as SupportCopilot.Connectors.ensure_billing_connector!/0's tenant_id attr."
    - "When approval-copy vocabulary migrates (D-19/D-20/D-25 ApprovalCopy/Copy modules), gallery assertions must repoint to the current rendered aria-label/title text, not raw tool_name/status atoms — those are now translated into human copy and never appear literally."

key-files:
  created: []
  modified:
    - examples/support_copilot/lib/support_copilot/knowledge.ex
    - examples/support_copilot/test/support_copilot_web/orchestrator_producer_test.exs

key-decisions:
  - "Root-caused journey_test:110 to a missing tenant_id in SupportCopilot.Knowledge.ensure_refund_policy_source!/0, not a test-side issue — fixed by passing SupportJourney.tenant_id() into the ingest_source attrs, mirroring the tenant-scoped seeding pattern already used by SupportCopilot.Connectors."
  - "Root-caused orchestrator_producer_test:31's two failures to vocabulary drift from the D-19/D-20/D-25 approval-copy migration (commit d35906fe): the literal '<:title>Approval inbox</:title>' slot no longer exists (replaced by a scope-aware aria-label), and raw tool_name/status strings ('issue_refund' / 'waiting_for_approval') are now translated into ApprovalCopy.title/1 human copy. Repointed both assertions to the current rendered text ('Pending approval queue' aria-label; 'Issue refund for {ticket_id}' title) — these tie directly to the real producer-created approval, tightening rather than loosening the proof."

requirements-completed: [REL-04]

coverage:
  - id: D1
    description: "Nested SupportCopilot.Knowledge.ensure_refund_policy_source!/0 seeds the refund policy with a valid tenant scope; the knowledge-lane journey (journey_test:110) grounds and renders without crashing"
    requirement: "REL-04"
    verification:
      - kind: integration
        ref: "examples/support_copilot/test/support_copilot/journey_test.exs#knowledge lane seeds refund policy and surfaces grounded journey"
        status: pass
    human_judgment: false
  - id: D2
    description: "orchestrator_producer_test:31 approvals page proof repointed to current post-D-19/D-20/D-25 rendered copy ('Pending approval queue' aria-label, 'Issue refund for {ticket_id}' title) without weakening the producer->approval->approvals-page assertion"
    requirement: "REL-04"
    verification:
      - kind: integration
        ref: "examples/support_copilot/test/support_copilot_web/orchestrator_producer_test.exs#approvals page shows approval from producer path on /scoria/approvals"
        status: pass
    human_judgment: false
  - id: D3
    description: "Parent gallery driver test proves the full nested pipeline (deps_get -> gallery_db -> gallery_test) completes with exit 0"
    requirement: "REL-04"
    verification:
      - kind: integration
        ref: "test/scoria/support_copilot_gallery_test.exs#support copilot gallery proves advisory adoption journey"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-07-11
status: complete
---

# Phase 50 Plan 09: SupportCopilot Gallery Journeys (Bucket E) Summary

**Fixed a missing tenant_id in the nested gallery app's knowledge seeding (root cause of the journey_test:110 crash) and repointed two vocabulary-drifted assertions in orchestrator_producer_test:31 to the current D-19/D-20/D-25 approval-copy rendered text — closing all 3 Bucket-E CI failures.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-11T14:52:00Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- `examples/support_copilot/test/support_copilot/journey_test.exs:110` ("knowledge lane seeds refund policy and surfaces grounded journey") now passes — fixed the `ArgumentError: tenant_id is required` crash by passing `tenant_id: SupportJourney.tenant_id()` into `Scoria.Knowledge.ingest_source/2`'s attrs in `SupportCopilot.Knowledge.ensure_refund_policy_source!/0`.
- `examples/support_copilot/test/support_copilot_web/orchestrator_producer_test.exs:31` ("approvals page shows approval from producer path on /scoria/approvals") now passes — repointed two assertions that had drifted from the removed literal `"Approval inbox"` slot (commit `d35906fe`, the D-19/D-20/D-25 approval-copy migration) to the current rendered proof: the table's `"Pending approval queue"` aria-label, and `ApprovalCopy.title/1`'s generated `"Issue refund for {ticket_id}"` text (which only renders once the real producer-created approval is present).
- Full nested `examples/support_copilot` suite: 9 tests, 0 failures.
- `mix test test/scoria/support_copilot_gallery_test.exs` (the "advisory adoption journey" proof, driving `deps_get -> gallery_db -> gallery_test` in the nested project) exits 0 — `proof.steps == [:deps_get, :gallery_db, :gallery_test]`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Repair the knowledge-lane grounded journey and producer-path approvals in the nested gallery app** - `44eda48c` (fix)

## Files Created/Modified
- `examples/support_copilot/lib/support_copilot/knowledge.ex` - `ensure_refund_policy_source!/0` now passes `tenant_id: SupportJourney.tenant_id()` to `Knowledge.ingest_source/2`, satisfying `Scoria.Knowledge.Scope.for_write!/1`'s tenant-scoping requirement (D-08).
- `examples/support_copilot/test/support_copilot_web/orchestrator_producer_test.exs` - repointed the `"Approval inbox"` assertion to `"Pending approval queue"` (the table's current scope-aware aria-label) and the `refund_approval_tool()`/`"waiting_for_approval"` `eventually` check to `"Issue refund for #{ticket_id}"` (the current `ApprovalCopy.title/1` rendered text for the seeded `issue_refund` approval).

## Decisions Made
- Diagnosed both nested-suite failures by running the exact failing tests directly inside `examples/support_copilot` (`mix test test/support_copilot/journey_test.exs:110 test/support_copilot_web/orchestrator_producer_test.exs:31 --trace`) to read the concrete stack traces and assertion diffs before touching any code, per the plan's `<read_first>`/`<action>` guidance.
- For journey_test:110: confirmed via `Scoria.Knowledge.Scope.new!/1` (`lib/scoria/knowledge/scope.ex:25`) that `tenant_id` is a hard requirement for every knowledge write scope, and confirmed the correct tenant value/pattern by reading the sibling `SupportCopilot.Connectors.ensure_billing_connector!/0`, which already seeds `tenant_id: SupportJourney.tenant_id()`. This is a Rule 1 (bug) fix — the seeding call was simply missing a required field, not a design gap.
- For orchestrator_producer_test:31: used `git log -S "Approval inbox"` to find the exact commit (`d35906fe`, "feat(approvals): present operator decisions around run evidence") that deleted the literal `<:title>Approval inbox</:title>` slot and replaced it with `aria-label="Pending approval queue"`/`"Decided approval history"` (scope-dependent), and confirmed via `ScoriaWeb.ApprovalCopy.title/1` that raw `tool_name`/`status` values are now translated into operator-facing copy (D-19/D-20/D-25) and never rendered as literal atoms. Repointed to the exact current rendered strings rather than restoring dead copy or loosening the check — this is a "relocated/reworded canonical SSOT" repoint (same precedent used in 50-05..50-08), not a weakened assertion. If anything the new check (`"Issue refund for #{ticket_id}"`) is *more* specific than the old `A or B` check, since it ties to the concrete producer-created approval's rendered title rather than either of two raw values that no longer surface anywhere in the DOM.

## Deviations from Plan

None - plan executed exactly as written. Both root causes were exactly where `<read_first>` pointed (the nested app's knowledge-seeding call and the vocabulary-drifted test assertions), and no architectural change, new dependency, or approval/grounding bypass was needed.

## Issues Encountered
- Both failing tests initially looked unrelated (a crash vs. a missing-text assertion), but were resolved independently: journey_test:110 was a genuine application bug (missing tenant_id), while orchestrator_producer_test:31 was purely a stale-assertion problem against copy that had already been correctly migrated to the D-19/D-20/D-25 vocabulary. No fix required touching approval semantics, grounding contracts, or bypassing the real producer->approval->approvals-page flow.
- Harmless async-task connection-teardown log noise (`Postgrex.Protocol ... disconnected`, `Ecto.NoResultsError` from `Scoria.Workflows.Reconciler`) appears in the nested suite's output after the test process for async-teardown races unrelated to these fixes; this is pre-existing sandbox-teardown noise (test process exits before a background reconciler task completes) and does not affect the `9 tests, 0 failures` / `1 test, 0 failures` results.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All 3 Bucket-E CI failures (and their connector-tag re-runs) are closed; the nested `examples/support_copilot` gallery suite and the parent `support_copilot_gallery_test` proof are both green.
- Approval semantics (D-10) and grounding contracts (D-08) are preserved — no assertion was deleted or loosened; the producer->approval path and knowledge-lane seeding both flow through their real, non-bypassed code paths.
- Ready for the next gap-closure bucket in the 50-05..50-11 sequence (per `.planning/phases/50-release-readiness-and-0-1-3-cut/50-CI-GAP-INVENTORY.md`).

---
*Phase: 50-release-readiness-and-0-1-3-cut*
*Completed: 2026-07-11*

## Self-Check: PASSED
- FOUND: examples/support_copilot/lib/support_copilot/knowledge.ex
- FOUND: examples/support_copilot/test/support_copilot_web/orchestrator_producer_test.exs
- FOUND: .planning/phases/50-release-readiness-and-0-1-3-cut/50-09-SUMMARY.md
- FOUND commit: 44eda48c
