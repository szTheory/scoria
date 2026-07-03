---
phase: 39-component-groups-and-operator-flows
plan: 06
subsystem: ui
tags: [phoenix, liveview, heex, approvals, drawer, modal, page_header, design-system, decision-first]

# Dependency graph
requires:
  - phase: 39-component-groups-and-operator-flows
    provides: "page_header/1 (Plan 01), ApprovalCopy.status_line/1 + eyebrow/1 + impact_lead/1 (Plan 03)"
provides:
  - "approvals_live/index.ex drawer render subtree restructured into the D-12 decision-first order: eyebrow+title, single status_line/1 badge, plain-language impact/1 consequence, Deny/Approve actions directly under the consequence, always-visible evidence_section facts, two native <details> disclosures, view-run link"
  - "uppercase warn banner (.scoria-approval-summary__label) and its warn-bordered/gradient card (.scoria-approval-summary) deleted; drawer audit line removed; decision copy deduped to one status_line/1 badge (D-13/D-16)"
  - "bespoke .scoria-approval-details tech-grid replaced by a plain native <details>\"Identifiers\" block (<.id>+<.time> rows); the payload raw_evidence disclosure is collapsed (open={false}) with a stable per-approval DOM id, guarded by a LiveViewTest open-state regression (D-14)"
  - "confirm modal (approve and deny) leads with ApprovalCopy.impact_lead/1 magnitude copy instead of a title restate; Deny switches from --danger to neutral --ghost in both the drawer and the modal footer (D-15)"
  - "decided?/1 positive-whitelist predicate (approved/rejected/expired, fails safe) gates the action section + confirm modal so reversal affordances are structurally absent once an approval is decided (D-19/D-27)"
  - "approvals page header migrated to page_header/1; three approval-alarm CSS blocks deleted/stripped in 04-components.css (warn card, sticky-top actions bar now sticky-bottom, tech-grid) plus the now-orphaned .scoria-approval-decision__audit rule"
affects: [39-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "D-12 decision-first drawer sequencing: eyebrow+title -> single status badge -> plain-language consequence -> actions -> always-visible facts -> collapsed disclosures -> view-run link, restructured in place with zero drawer/1 primitive change"
    - "D-14 stable per-approval DOM id on a collapsed native <details> (id derived from @active_approval.id) so a different approval mounts a fresh collapsed node while an unrelated broadcast that doesn't touch @active_approval leaves the id (and therefore the client's open state) untouched"
    - "D-19 positive-whitelist decided?/1 predicate mirroring the server's :not_pending/StaleEntryError guard — gates reversal-implying UI structurally rather than via a negative/exclusion check"
    - "D-15 risk-gradient button tone: the irreversible action (Approve) carries --primary; the safe reversible hold (Deny) stays neutral --ghost, with a code comment documenting the rationale since the locked button vocabulary (primary/ghost/danger) has no dedicated middle tone"

key-files:
  created: []
  modified:
    - lib/scoria_web/live/approvals_live/index.ex
    - assets/css/04-components.css
    - priv/static/scoria/app.css
    - test/scoria_web/live/approvals_live_test.exs
    - test/scoria_web/live/approvals_live_integration_test.exs

key-decisions:
  - "Deny buttons (drawer action row + confirm-modal footer) switch from scoria-button--danger to scoria-button--ghost rather than inventing a new tone — the locked button vocabulary (primary/ghost/danger) has no dedicated neutral-but-not-dismiss tone; documented the risk-gradient rationale in a code comment per the plan's own fallback instruction."
  - "The confirm-modal magnitude copy is composed in index.ex (decision_confirm_copy/2: ApprovalCopy.impact_lead/1 + a fixed continuation clause) rather than added to ApprovalCopy, since approval_copy.ex was outside this plan's files_modified scope."
  - "Added a stable DOM id to the Identifiers <details> (approval-identifiers-<id>) in addition to the plan-required payload <details> id — same open-state-loss hazard class, low-cost symmetry; only the payload disclosure's stability is covered by the LiveViewTest regression per the plan's literal requirement."
  - "The open-state LiveViewTest regression asserts the server-renderable half only (the payload <details> DOM id and @active_approval stay unchanged across an unrelated {:hitl_request} broadcast) — native <details> open/closed state has no phx event and is invisible to LiveViewTest's server-rendered HTML; the browser-observable half is documented as the Tier 2 Playwright lane's responsibility, matching the existing UAT-2/UAT-3 split convention in this test file."
  - "Deleted the now-orphaned .scoria-approval-decision__audit CSS rule (its last markup consumer was removed in Task 1's D-16 dedup) even though it wasn't individually named in Task 3's CSS deletion list, to avoid leaving dead CSS behind the markup change."

requirements-completed: [FLOW-03, COPY-01]

coverage:
  - id: D1
    description: "Pending drawer re-sequenced into D-12 decision-first order (eyebrow/title -> single status badge -> plain-language consequence -> Deny/Approve actions -> facts -> disclosures -> view-run link); uppercase warn banner and drawer audit line deleted; decision copy deduped to one status_line/1 badge; approvals page header migrated to page_header/1"
    requirement: "FLOW-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/approvals_live_test.exs"
        status: pass
      - kind: integration
        ref: "test/scoria_web/live/approvals_live_integration_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Bespoke .scoria-approval-details tech-grid replaced by a plain native <details>\"Identifiers\" block plus a collapsed (open=false), stably-DOM-id'd \"Request payload\" raw_evidence disclosure; LiveViewTest regression proves an unrelated {:hitl_request} broadcast leaves the payload details' DOM id and the active approval untouched"
    requirement: "FLOW-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/approvals_live_test.exs#unrelated hitl_request broadcast preserves the payload details stable DOM id"
        status: pass
    human_judgment: false
  - id: D3
    description: "Confirm modal (both approve and deny) leads with ApprovalCopy.impact_lead/1 magnitude copy instead of a title restate; Deny is neutral --ghost (not --danger) in both the drawer and the modal footer; decided?/1 positive-whitelist predicate gates the action section + confirm modal so they render only when pending; three approval-alarm CSS blocks deleted/stripped"
    requirement: "COPY-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/approvals_live_test.exs, test/scoria_web/ds06_drift_guard_test.exs, test/scoria_web/token_contrast_guard_test.exs"
        status: pass
      - kind: integration
        ref: "test/scoria_web/live/approvals_live_integration_test.exs"
        status: pass
    human_judgment: false

duration: ~20min
completed: 2026-07-03
status: complete
---

# Phase 39 Plan 06: Component Groups And Operator Flows — Approval Drawer Decision-First Redesign Summary

**Restructured the approvals drawer into a decision-first, de-alarmed layout (single status badge, actions directly under the plain-language consequence, two native disclosures with a stable DOM id, and a magnitude-led confirm modal with neutral Deny), gated by a positive-whitelist `decided?/1` predicate so reversal affordances are structurally absent once an approval is decided.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-03T09:44:00Z
- **Completed:** 2026-07-03T09:54:09Z
- **Tasks:** 3
- **Files modified:** 5 (2 LiveView/CSS source files, 1 generated CSS asset, 2 test files)

## Accomplishments
- Re-sequenced `approvals_live/index.ex`'s pending-drawer render subtree into the D-12 decision-first order: `ApprovalCopy.eyebrow/1` + title header, a single `ApprovalCopy.status_line/1` badge, the plain-language `ApprovalCopy.impact/1` consequence, Deny/Approve actions directly under it, an always-visible `evidence_section` of facts, two collapsed disclosures, and the view-run link — restructured in place with zero `drawer/1` primitive change.
- Deleted the uppercase warn banner (`.scoria-approval-summary__label`) and its warn-bordered/gradient wrapper card (`.scoria-approval-summary`); removed the drawer audit line; migrated the approvals page header to `page_header/1` (D-13/D-16 de-alarm/dedup).
- Replaced the bespoke `.scoria-approval-details` tech-grid with a plain native `<details>`/`<summary>"Identifiers"` block (`<.id>`+`<.time>` rows for approval/run/session/trace + requested-at); collapsed the "Request payload" `raw_evidence` disclosure (`open={false}`) and gave it a stable per-approval DOM id (`approval-raw-<id>`); added a LiveViewTest regression proving an unrelated `{:hitl_request}` broadcast leaves the payload details' DOM id and `@active_approval` untouched (D-14).
- Made the confirm modal (kept for both approve and deny, still two-step, still no-auto-focus on the action) lead with the concrete irreversible-effect magnitude via `ApprovalCopy.impact_lead/1` instead of restating the title; switched Deny from `--danger` to neutral `--ghost` in both the drawer action row and the modal footer, with a code comment documenting the risk-gradient rationale (D-15).
- Added a positive-whitelist `decided?/1` predicate (`approved`/`rejected`/`expired`, fails safe) mirroring the server's `:not_pending`/`StaleEntryError` guard, and gated the action `<section>` + confirm modal on it so they render only when pending — reversal affordances are structurally absent once decided (D-19); the view-run link remains the honest execution-truth pointer while the decided-at/decider receipt wiring is deferred to Plan 07 as the plan's objective specifies.
- Deleted/stripped the three approval-alarm CSS blocks in `04-components.css` (`.scoria-approval-summary`+`__label`, `.scoria-approval-actions` sticky-top gradient now sticky-bottom, `.scoria-approval-details`/tech-grid), plus the now-orphaned `.scoria-approval-decision__audit` rule; regenerated `priv/static/scoria/app.css` via `mix scoria.assets.build`.
- Grep-confirmed: zero remaining references to `scoria-approval-summary__label`, `scoria-approval-decision__audit`, `scoria-approval-details`, or `scoria-approval-tech-grid` anywhere in `lib/` or `assets/css/`; zero `scoria-button--danger` remaining in `approvals_live/index.ex`; a single `<.badge>` remains in the drawer header.

## Task Commits

Each task was committed atomically:

1. **Task 1: Re-sequence the pending drawer decision-first + de-alarm + dedup copy** - `ce86c88` (feat)
2. **Task 2: Two native `<details>` disclosures + stable DOM id + open-state regression** - `22f9e16` (feat)
3. **Task 3: Confirm modal earns friction + Deny neutral + decided gate + CSS chrome removal** - `2efcbe2` (feat)
4. **Deviation fix: integration test copy update** - `b2f846b` (test)

**Plan metadata:** (this commit)

_Note: Task 4 is a Rule 3 blocking-issue fix for a test file outside this plan's declared `files_modified` scope — see Deviations below._

## Files Created/Modified
- `lib/scoria_web/live/approvals_live/index.ex` - Drawer subtree re-sequenced into D-12 order; `decided?/1` and `decision_confirm_copy/2` private helpers added; page header migrated to `page_header/1`; Deny buttons switched to `--ghost`
- `assets/css/04-components.css` - Three approval-alarm blocks deleted/stripped (warn card, sticky-top actions bar, tech-grid), plus the orphaned audit-line rule
- `priv/static/scoria/app.css` - Regenerated via `mix scoria.assets.build` (compile-time-inlined asset, not automatic on `mix compile`)
- `test/scoria_web/live/approvals_live_test.exs` - Assertions updated for the new tool-specific eyebrow text, removed audit line, "Identifiers" disclosure, collapsed payload details; added the open-state DOM-id regression test
- `test/scoria_web/live/approvals_live_integration_test.exs` - Assertions updated for the new eyebrow text and the new magnitude-led deny confirm copy (Rule 3 deviation, see below)

## Decisions Made
- **Deny buttons use `--ghost`, not a new tone.** The locked button vocabulary (primary/ghost/danger) has no dedicated neutral-but-not-dismiss tone; per the plan's own fallback instruction, switched Deny to `--ghost` and documented the risk-gradient rationale in a code comment at both call sites rather than inventing a new CSS class.
- **Confirm-modal magnitude copy composed in index.ex.** `decision_confirm_copy/2` combines `ApprovalCopy.impact_lead/1` with a fixed continuation clause per decision type, kept out of `approval_copy.ex` since that module was outside this plan's `files_modified` scope.
- **Added a stable DOM id to the Identifiers disclosure too**, beyond the plan's literal requirement (which only named the payload disclosure) — same open-state-loss hazard class, low marginal cost; the LiveViewTest regression covers only the payload disclosure per the plan's acceptance criteria.
- **Open-state regression tests the server-renderable half only.** Native `<details>` open/closed state has no `phx-*` event and is invisible to LiveViewTest's server-rendered HTML snapshots; the test asserts the payload `<details>`'s DOM id and `@active_approval` survive an unrelated broadcast (the server-side guarantee that makes browser-side state preservation possible), and documents the Tier 2 Playwright lane as the JS-observable half, matching this test file's existing UAT-2/UAT-3 split convention.
- **Deleted the orphaned `.scoria-approval-decision__audit` CSS rule** even though Task 3's CSS deletion list named only three blocks — its last markup consumer was removed by Task 1's D-16 dedup, so the rule was already dead.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated `approvals_live_test.exs` assertions for Task 1/2/3 copy and structure changes**
- **Found during:** Task 1 (and extended in Tasks 2/3)
- **Issue:** Each task's own `<verify>` command (`mix test test/scoria_web/live/approvals_live_test.exs --warnings-as-errors`) requires the existing test suite to pass, but the plan's copy/structure changes (tool-specific eyebrow text replacing the generic "Approval request", removal of the drawer audit line, "Identifiers" replacing "Technical details", the payload `<details>` collapsing by default) broke 8+ existing assertions.
- **Fix:** Updated assertions to match the new eyebrow text (`"test_tool approval"` etc.), refuted the removed audit-line text, updated the disclosure summary text, and inverted the payload-details `open` regex to a refute.
- **Files modified:** test/scoria_web/live/approvals_live_test.exs
- **Verification:** `mix test test/scoria_web/live/approvals_live_test.exs --warnings-as-errors` — 16 tests, 0 failures after Task 2 fixes.
- **Committed in:** ce86c88 (Task 1), 22f9e16 (Task 2)

**2. [Rule 3 - Blocking] Updated `approvals_live_integration_test.exs`, a test file outside this plan's declared `files_modified` scope**
- **Found during:** Post-Task-3 broader test sweep
- **Issue:** This integration test file (not in the plan's `files_modified` list) directly exercises the drawer eyebrow text and the confirm-modal decision copy this plan changes. All 7 tests in the file failed after Task 3's changes: 6 on the generic `"Approval request"` string (now tool-specific `"publish approval"`), and 1 on the literal old `decision_copy/2` string `"Denying records your decision"` (replaced by `decision_confirm_copy/2`'s magnitude-led copy).
- **Fix:** Replaced `"Approval request"` with `"publish approval"` throughout (all fixtures in this file use `tool_name: "publish"`); replaced the stale copy assertion with `"Scoria records the decision; the run stays paused until approved."`.
- **Files modified:** test/scoria_web/live/approvals_live_integration_test.exs
- **Verification:** `mix test test/scoria_web/live/approvals_live_integration_test.exs --warnings-as-errors` — 8 tests, 0 failures.
- **Committed in:** b2f846b

**3. [Rule 1 - Bug/cleanup] Deleted the orphaned `.scoria-approval-decision__audit` CSS rule**
- **Found during:** Task 3 (CSS chrome removal)
- **Issue:** Task 1's D-16 dedup removed the `<p class="scoria-approval-decision__audit">` markup, leaving its CSS rule in `04-components.css` with no consumer. Task 3's CSS deletion list named only three blocks and didn't individually call this one out.
- **Fix:** Deleted the dead `.scoria-approval-decision__audit` rule alongside the three named deletions.
- **Files modified:** assets/css/04-components.css
- **Verification:** No test asserts this class exists; `mix test test/scoria_web/ds06_drift_guard_test.exs` unaffected (no dead-class check in that guard).
- **Committed in:** 2efcbe2

---

**Total deviations:** 3 auto-fixed (2 Rule 3 - blocking test breakage from in-scope copy/structure changes, 1 Rule 1 - dead CSS cleanup)
**Impact on plan:** All three are direct, necessary consequences of the plan's own required changes (new eyebrow/badge/copy text breaking existing assertions in both the declared and an adjacent undeclared test file; a CSS rule made dead by the plan's own markup deletion). No scope creep — no new files, no architectural changes, no files touched beyond what the plan's changes directly broke.

## Issues Encountered
None beyond the deviations documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The `decided?/1` predicate and the D-27 honest-receipt structure (badge + view-run link, no resume/side-effect success claims) are in place for Plan 07 to build the full decided read-only history surface on top of, per this plan's stated scope boundary ("wired fully in Plan 07").
- The two-disclosure pattern (native `<details>` "Identifiers" + collapsed `raw_evidence` "Request payload" with a stable per-approval DOM id) is grep-clean of the deleted bespoke tech-grid CSS and ready to serve as the reference pattern if Plan 07's decision-history rows need similar disclosures.
- No blockers.

---
*Phase: 39-component-groups-and-operator-flows*
*Completed: 2026-07-03*

## Self-Check: PASSED

All 5 modified files exist on disk (`lib/scoria_web/live/approvals_live/index.ex`, `assets/css/04-components.css`, `priv/static/scoria/app.css`, `test/scoria_web/live/approvals_live_test.exs`, `test/scoria_web/live/approvals_live_integration_test.exs`); all 4 commit hashes (`ce86c88`, `22f9e16`, `2efcbe2`, `b2f846b`) exist in `git log --oneline --all`.
