---
created: 2026-06-20T13:51:23Z
title: Add approval decision history
area: ui
status: completed
completed: 2026-07-04
resolves_phase: 39
files:
  - lib/scoria/workflows/remote_approval_projection.ex:16
  - lib/scoria_web/live/approvals_live/index.ex:253
  - lib/scoria_web/components/approval_inbox_component.ex
  - test/scoria_web/live/approvals_live_test.exs:488
---

## Resolution

Completed in v3.3 Phase 39 / FLOW-04. The approvals page now has a Pending|Decided scope,
decision-history rows for approved/denied/expired approvals, audit-sourced receipts, and tests that
prevent in-place reversal affordances for already-decided approvals.

## Problem

The approvals page is currently a pending-only inbox. After an operator denies a request, the approval is durably updated to `status: "rejected"` and Scoria writes an `approval.rejected` audit event, but the row disappears from `/scoria/approvals` and there is no clear operator-facing way to find the denied decision later.

This is correct for the blocking queue, but it creates a discoverability gap: operators may need to answer "what happened to the request I denied?", review who decided it, inspect the linked run, or understand why the workflow is still waiting for approval. The current workflow API also intentionally rejects re-deciding an already-decided approval with `{:error, :not_pending}`, so the UI should not imply that a rejected approval can be flipped back to approved in place.

## Solution

Add a focused approval decision history surface or history filter that keeps the pending inbox actionable while making decided approvals discoverable.

Implementation direction:

- Keep `/scoria/approvals` pending-first.
- Add a clear "Decision history" or status filter for `approved`, `rejected`, and `expired` approvals.
- Show request summary, status, decision time, request time, decision actor/audit actor when available, linked run, and audit event evidence.
- Treat "approve after deny" as a new/superseding approval request or explicit reversal workflow, not a mutation of the original rejected approval.
- Avoid toast-level undo unless it creates durable superseding audit evidence and is constrained to safe timing.

Acceptance:

- Pending approvals remain easy to scan and decide.
- Rejected approvals are discoverable without querying the DB.
- A rejected approval cannot be approved in place.
- The UI copy explains that a denied request leaves the run waiting for a new/superseding request when appropriate.
- Tests cover a denied approval leaving the inbox but appearing in decision history with linked run and audit evidence.
