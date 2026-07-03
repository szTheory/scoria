---
phase: 39-component-groups-and-operator-flows
plan: 07
subsystem: ui
tags: [phoenix, liveview, heex, approvals, url-state, deep-link, audit-trail, decision-history]

# Dependency graph
requires:
  - phase: 39-component-groups-and-operator-flows
    provides: "decided?/1 positive-whitelist predicate + decision-first drawer redesign (Plan 06); Workflows.list_decided_approvals/1 + ApprovalCopy.decision_receipt/3/decision_outcome/1 (Plan 03)"
provides:
  - "Pending|Decided URL-param scope segment (default Pending) on the single /approvals table/1, with an outcome sub-filter (All/Approved/Denied/Expired) inside Decided rendered via the table's :filter slot"
  - "?approval=<id> deep-linkable drawer selection via push_patch + handle_params, tenant-scoped resolution (T-39-07-I), reconnect-safe"
  - "approval_decision_event/1 + batch-loaded decision_events_by_approval_id/1 (single query, N+1-safe) sourcing decided-at/decider from the decision AuditOutboxEvent"
  - "Decided read-only receipt drawer state: audit-sourced receipt line replaces the forward-looking consequence copy, action buttons replace with a single 'Start a new request' link to the origin run"
affects: [39-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "URL-param scope + outcome sub-filter rendered via table/1's :filter slot as scope-tab <.link patch> pairs + a phx-change outcome <select>, using only existing .scoria-button/.scoria-input classes and the 06-utilities.css utility layer — zero new CSS"
    - "Deep-link resolution falls back from the currently-loaded (already tenant-scoped) inbox list to a tenant-checked Workflows.get_approval_lineage!/1 lookup, so a decided-scope id still opens from a pending-scope URL (or vice versa) but never crosses tenants"
    - "put_active_approval/2 is the single choke point every :active_approval assignment routes through, so the audit-sourced :active_approval_receipt assign can never drift out of sync with which approval is open"
    - "runtime_seeded? one-shot flag prevents the PubSub-focus auto-open from re-firing on every handle_params (e.g. a user's own dismiss), matching the original mount-once semantics now that reload+seed moved from mount into handle_params"

key-files:
  created: []
  modified:
    - lib/scoria_web/live/approvals_live/index.ex
    - lib/scoria_web/components/approval_inbox_component.ex
    - test/scoria_web/live/approvals_live_test.exs

key-decisions:
  - "Task 1's Decision column shows only the outcome badge (no who/when yet); Task 2 adds the audit-sourced receipt text as a second line, so no intermediate commit ever displays an unbacked or approximate decider/time."
  - "The runtime-focused auto-open (?runtime=<id> from the Live Ops handoff) stays a one-shot assign-based seed, not migrated to the URL — only the operator-initiated ?approval=<id> selection became a URL param, matching the plan's D-09 scope (selection, not the PubSub focus mechanism)."
  - "Discovered Workflows.approve/3 (lib/scoria/workflows.ex, out of this plan's files_modified) writes the decision AuditOutboxEvent's actor_ref from the run/approval's IMMUTABLE ROOT identity (the original requester) — the same value the approval.requested event's actor_ref carries — not the deciding operator. The real decision-time actor lives in event.metadata[\"metadata\"][\"decision_actor_id\"]. decider_ref/1 sources that field first, falling back to actor_ref only if absent, entirely within this plan's own file — no workflows.ex change made or needed."
  - "Scope-tab links (Pending/Decided) drop the ?approval= param when switching, closing the drawer; the outcome <select> always targets scope=decided via a fixed hidden param in the push_patch destination rather than a form hidden input."
  - "Deny buttons/tone unchanged from Plan 06 (out of this plan's scope); the new 'Start a new request' link reuses --ghost --sm styling, matching the existing 'View run details' link."

requirements-completed: [FLOW-04, COPY-01]

coverage:
  - id: D1
    description: "Pending|Decided URL-param scope segment (default Pending) on the single /approvals table/1, with an outcome sub-filter (All/Approved/Denied/Expired) inside Decided mapping to the schema status value (Denied -> rejected, D-24d), rendered via the table's :filter slot — same primitive both scopes, no board, no second route"
    requirement: "FLOW-04"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/approvals_live_test.exs (describe \"Pending|Decided URL scope (D-17)\")"
        status: pass
    human_judgment: false
  - id: D2
    description: "@active_approval migrated from a socket-only assign to a deep-linkable ?approval=<id> URL param via push_patch + handle_params, resolved against the tenant-scoped inbox/lineage lookup so a deep-link cannot open an approval outside the operator's tenant (T-39-07-I); ephemeral state (decision_modal, toasts, highlighted id) stays in assigns"
    requirement: "FLOW-04"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/approvals_live_test.exs (describe \"?approval=<id> deep-link (D-09, T-39-07-I)\")"
        status: pass
    human_judgment: false
  - id: D3
    description: "approval_decision_event/1 (single-approval) + decision_events_by_approval_id/1 (batch, N+1-safe) source decided-at/decider from the decision AuditOutboxEvent's inserted_at/metadata-sourced decider, never updated_at or get_approval_lineage!'s requesting actor; missing event renders 'Decided · time unavailable', never a fabricated value or 'unknown'"
    requirement: "FLOW-04"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/approvals_live_test.exs (describe \"decided read-only receipt (D-19, D-20, D-27)\")"
        status: pass
    human_judgment: false
  - id: D4
    description: "Decided approvals open the SAME drawer in a read-only receipt state — the forward-looking consequence copy and Approve/Deny actions are replaced by the audit-sourced receipt line and a single 'Start a new request' link to the origin run; no decision affordance renders once decided (D-18/D-19/D-27)"
    requirement: "COPY-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/approvals_live_test.exs#a decided approval's drawer shows a read-only receipt with no Approve/Deny buttons"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-07-03
status: complete
---

# Phase 39 Plan 07: Component Groups And Operator Flows — Decision History Surface Summary

**One `/approvals` `table/1` now serves Pending and Decided via a URL scope segment with a deep-linkable `?approval=<id>` drawer selection, and the drawer's decided state renders an audit-event-sourced "Approved/Denied by {actor} · {time}" receipt (correcting a discovered upstream attribution bug) instead of the forward-looking approve/deny copy.**

## Performance

- **Duration:** ~50 min
- **Started:** 2026-07-03T10:10:00Z
- **Completed:** 2026-07-03T11:00:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added a `Pending | Decided` URL-param scope segment (default Pending) plus an outcome sub-filter (`All/Approved/Denied/Expired`) to the single `/approvals` `table/1`, rendered via the table's `:filter` slot as scope-tab `<.link patch>` links and a `phx-change` outcome `<select>` — zero new CSS classes (reused the existing `.scoria-button`/`.scoria-input`/`06-utilities.css` layout utilities).
- Decided scope loads via the existing `Workflows.list_decided_approvals/1` (capped + load-more, `load_more_decided` event bumps `:decided_limit`), swaps the `Waiting` column for a `Decision` column (status badge + audit-sourced who/when line), and renders the row action as "View decision" instead of "Inspect approval".
- Migrated `@active_approval` from a socket-only assign to a deep-linkable `?approval=<id>` URL param via `push_patch` + `handle_params`, resolved first against the currently-loaded (tenant-scoped) inbox and falling back to a tenant-checked `Workflows.get_approval_lineage!/1` lookup — a deep-link can never open an approval outside the operator's tenant (T-39-07-I). The runtime-focused PubSub auto-open stays a one-shot assign-based seed (`runtime_seeded?` flag), preventing it from re-firing on a user's own dismiss now that the reload/seed logic moved from `mount` into `handle_params`.
- Added `approval_decision_event/1` (single-approval, mirrors `approval_request_event/1`) and `decision_events_by_approval_id/1` (batch, one query for the whole visible history page) reading the decision `AuditOutboxEvent`'s `inserted_at` for decided-at. Missing event renders `"Decided · time unavailable"`, never a fabricated value.
- Wired the drawer's decided state: the forward-looking `ApprovalCopy.impact/1` consequence line and Approve/Deny buttons are replaced by the audit-sourced receipt (`ApprovalCopy.decision_receipt/3`, D-27-honest — states only the recorded decision) and a single "Start a new request" link to the origin run — no decision affordance is ever emitted once `decided?/1` is true.
- **Discovered and fixed a real attribution bug within this plan's own file scope:** `Workflows.approve/3` writes the decision `AuditOutboxEvent`'s `actor_ref` from the run/approval's immutable root identity (the original requester) rather than the deciding operator — the actual decider is captured separately in `event.metadata["metadata"]["decision_actor_id"]`. Following the plan's literal instruction to read `actor_ref` would have silently misattributed every decision to the requester. `decider_ref/1` sources the metadata field first, falling back to `actor_ref` only if absent.

## Task Commits

Each task was committed atomically:

1. **Task 1: Pending|Decided URL scope + ?approval deep-link + Decision column/outcome filter** - `522b0cb` (feat)
2. **Task 2: Decided read-only receipt drawer + audit-sourced attribution (D-19/D-20/D-27)** - `99ed2a4` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified
- `lib/scoria_web/live/approvals_live/index.ex` - `handle_params/3` (scope/outcome/deep-link resolution), scope-aware `reload_inbox/1`, `approval_decision_event/1` + `decision_events_by_approval_id/1` + `decider_ref/1`, `put_active_approval/2` choke point, `decided_receipt_for/1`, drawer decided-state render branch, `push_patch`-based `select_approval`/`dismiss_approval`/`change_outcome`/`load_more_decided` events
- `lib/scoria_web/components/approval_inbox_component.ex` - scope-tab + outcome-filter `:filter` slot, conditional `Waiting`/`Decision` columns, `decision_receipts` attr rendering the who/when line, scope-aware action label/aria-label/empty-state helpers
- `test/scoria_web/live/approvals_live_test.exs` - existing source-scan assertion updated for the dynamic aria-label; new `describe` blocks for URL scope, deep-link, and decided-receipt behavior (18 new tests); D-10 no-stream source-scan assertions added to the existing shared-contract test

## Decisions Made
- Split the Decision column across the two task commits deliberately: Task 1 renders only the outcome badge (never fabricates a time/actor), Task 2 adds the audit-sourced who/when text — no intermediate commit ever shows an unbacked receipt.
- Kept the PubSub runtime-focus auto-open (`?runtime=<id>`) as an assign-based one-shot seed rather than migrating it to the URL — D-09 scopes the URL migration to the operator-initiated selection, not the Live Ops handoff mechanism.
- Fixed the decider-attribution source within `approvals_live/index.ex` alone (`decider_ref/1`) rather than touching `lib/scoria/workflows.ex`, keeping the fix inside this plan's declared file scope while still satisfying D-20/D-27's honesty requirement.
- Scope-tab links close the drawer when switching (drop `?approval=`); the outcome filter always patches with `scope=decided` explicit even when already in that scope, since the `<select>`'s `phx-change` handler is scope-agnostic by design.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected decision-audit attribution source (`decider_ref/1`)**
- **Found during:** Task 2, first end-to-end test of the decided receipt (`decide_approval(approval, "approved", "ops-lead-1")` followed by asserting `"Approved by ops-lead-1"` in the rendered drawer)
- **Issue:** `Workflows.approve/3` (`lib/scoria/workflows.ex`, not in this plan's `files_modified`) writes the decision `AuditOutboxEvent`'s `actor_ref` from `immutable_identity(run || %Run{}, approval)` — the run/approval's original requesting identity — not the decision-time `attrs.actor_id` passed into `approve/3`. The actual decider is separately recorded as `metadata["decision_actor_id"]`, then nested a second level under the envelope's own `:metadata` key by `SRE.insert_audit_outbox_event/2`'s generic "everything else becomes metadata" behavior, landing at `event.metadata["metadata"]["decision_actor_id"]`. Reading bare `actor_ref` per the plan's literal D-20 instruction would have every decided approval attribute to the original requester, not the deciding operator — the exact repudiation defect T-39-07-R exists to prevent.
- **Fix:** Added `decider_ref/1` in `approvals_live/index.ex`, sourcing `get_in(event.metadata, ["metadata", "decision_actor_id"])` first and falling back to `event.actor_ref` only when that field is absent. No change to `lib/scoria/workflows.ex` — entirely within this plan's declared file scope.
- **Files modified:** lib/scoria_web/live/approvals_live/index.ex
- **Verification:** `mix test test/scoria_web/live/approvals_live_test.exs` — the "attribution comes from the decision event's actor, not the request event" test asserts `"Denied by ops-lead-99"` and refutes `"Denied by operator-live"` (the request-event actor).
- **Committed in:** 99ed2a4 (Task 2)

**2. [Rule 3 - Blocking] Fixed a false-positive test assertion caused by the compiled asset bundle**
- **Found during:** Task 2, writing the outcome-filter test
- **Issue:** `refute html =~ "Approved"` / `refute html =~ "unknown"` failed because every rendered page inlines the full compiled `<style>` (which defines `.scoria-badge--pass`/`--fail` CSS rules unconditionally) and `<script>` (LiveView JS bundle, which contains the literal string `"unknown hook found for..."`) — both make broad substring assertions unreliable regardless of which approval rows are actually present.
- **Fix:** Switched the outcome-filter assertions to the rendered badge class attribute (`"scoria-badge scoria-badge--fail"` / `"scoria-badge scoria-badge--pass"`, which only appears on an actual rendered badge element, not the stylesheet's selector text) and dropped the `refute html =~ "unknown"` assertion (the "no fabricated actor" requirement is already covered by `refute html =~ "Expired by"`).
- **Files modified:** test/scoria_web/live/approvals_live_test.exs
- **Verification:** `mix test test/scoria_web/live/approvals_live_test.exs` — 32/32 passing.
- **Committed in:** 99ed2a4 (Task 2)

**3. [Rule 3 - Blocking] Updated the existing source-scan assertion for the now-dynamic table aria-label**
- **Found during:** Task 1
- **Issue:** The existing "approvals source uses shared table, drawer, and final modal contracts" test asserted the literal source substring `aria-label="Pending approval queue"`, which no longer appears verbatim once the aria-label became `aria-label={table_aria_label(@scope)}`.
- **Fix:** Changed the assertion to check for the retained literal string `"Pending approval queue"` (still present as `table_aria_label/1`'s default-clause return value), preserving the original intent (the pending-scope label text is unchanged) without depending on the exact attribute syntax.
- **Files modified:** test/scoria_web/live/approvals_live_test.exs
- **Verification:** `mix test test/scoria_web/live/approvals_live_test.exs` — passing.
- **Committed in:** 522b0cb (Task 1)

**4. [Rule 1 - Bug] Fixed a self-inflicted drawer-reopen regression from moving reload/seed into `handle_params`**
- **Found during:** Task 1, running `test/scoria_web/live/approvals_live_integration_test.exs` ("dismiss closes modal without approving via producer path")
- **Issue:** Migrating `reload_inbox/1` + `maybe_seed_active_approval/1` from `mount/3` into `handle_params/3` meant the PubSub-runtime-focus auto-open re-evaluated on every `push_patch`, including a user's own `dismiss_approval` — so dismissing a runtime-focused drawer immediately reopened it.
- **Fix:** Added a `runtime_seeded?` one-shot flag (defaults `false` in `mount`, flips to `true` the first time `handle_params` runs the seed check) so the auto-open fires at most once per LiveView process, matching the original mount-only behavior.
- **Files modified:** lib/scoria_web/live/approvals_live/index.ex
- **Verification:** `mix test test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/approvals_live_integration_test.exs` — 40/40 passing.
- **Committed in:** 522b0cb (Task 1)

---

**Total deviations:** 4 auto-fixed (2 Rule 1 - bugs, including one safety-relevant attribution correction; 2 Rule 3 - blocking test fixes)
**Impact on plan:** All four are direct consequences of implementing this plan's own D-09/D-19/D-20 requirements correctly. Deviation 1 is the most consequential: without it, the decided-receipt feature this plan exists to build would have shipped with systematically wrong "who decided" attribution — a real repudiation-class defect, not a cosmetic issue. No scope creep — no new files, no files touched beyond this plan's declared three, no architectural or `workflows.ex` changes.

## Issues Encountered
None beyond the deviations documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Approvals now has one `table/1` serving both Pending and Decided scopes with a deep-linkable drawer in both a decision-first pending state (Plan 06) and a read-only decided-receipt state (this plan) — the Area 3/Area 4 bridge described in the phase's Coherence Spine is complete.
- The `decider_ref/1` correction is scoped to display-time only; `lib/scoria/workflows.ex`'s `actor_ref` write behavior is unchanged and out of this plan's scope. A future phase touching `workflows.ex` could consider writing the decision-time actor directly into `actor_ref` (or a dedicated column) to remove the need for the nested-metadata lookup, but that is an architectural change this plan deliberately did not make.
- No blockers for Plan 08.

---
*Phase: 39-component-groups-and-operator-flows*
*Completed: 2026-07-03*

## Self-Check: PASSED

All 3 modified files exist on disk (`lib/scoria_web/live/approvals_live/index.ex`, `lib/scoria_web/components/approval_inbox_component.ex`, `test/scoria_web/live/approvals_live_test.exs`); both commit hashes (`522b0cb`, `99ed2a4`) exist in `git log --oneline --all`.
