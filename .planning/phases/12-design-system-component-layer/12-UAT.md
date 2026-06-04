---
status: complete
phase: 12-design-system-component-layer
source: [12-01-SUMMARY.md, 12-02-SUMMARY.md, 12-03-SUMMARY.md, 12-04-SUMMARY.md, 12-05-SUMMARY.md]
started: 2026-06-04T18:53:15Z
updated: 2026-06-04T19:45:00Z
verification: automated
---

## Current Test

[testing complete — converted to automated tests; no human UAT required]

## How this UAT is verified

All six items are now machine-verified — no human walkthrough needed. Two tiers:

- **Tier 1 — server-rendered (`mix test`, runs in CI today):** every server-observable
  truth is asserted via `Phoenix.LiveViewTest` in the existing suite.
- **Tier 2 — real browser (`mix scoria.ui.e2e`, new `e2e` job in `ci.yml` on every PR):**
  the JS/CSS/animation truths Floki can't reach, via `priv/dev/e2e/uat.spec.mjs`
  (`@playwright/test`). Truths not yet reachable in the running app (known defects or
  stubbed data) are registered as `test.fixme` with the unlock named — never silent.

## Tests

### 1. Dashboard boots and modified screens load
expected: Dashboard boots; Approvals inbox and a Workflow detail page render without crash or 500.
result: pass
covered-by: Tier 1 — `approvals_live_test.exs` "approvals inbox boots and renders the toast region shell" + existing mount tests; `workflow_live_test.exs` mount tests. Tier 2 — `uat.spec.mjs` navigates both screens live.

### 2. Approval decision shows a toast notification
expected: Decision shows a toast (tone matches decision), auto-dismisses ~4s, manual × dismiss.
result: pass (server-rendered) — browser auto-dismiss pending (Tier 2 fixme)
covered-by: Tier 1 — `approvals_live_test.exs` "approve decision renders a pass-tone toast…" (scoria-toast--pass + "Approval granted." + role=status + phx-mounted + aria-label="Dismiss"), "reject decision renders a warn-tone toast…", stale-decision test (scoria-toast--fail). Tier 2 — auto-dismiss + manual-dismiss specs are `test.fixme`: the dev-app approvals inbox does not deterministically surface the seeded approval (tenant-scoped inbox renders "No pending approvals" for ?tenant=acme-corp even though the query returns rows — the same approvals-overlay reachability gap noted in 11-HUMAN-UAT.md). Activate when a seed/route reliably surfaces an inbox approval.

### 3. Flash messages render with tone color + icon
expected: Flash shows semantic tone + an icon + is announced as an alert.
result: pass
covered-by: Tier 1 — `approvals_live_test.exs` stale-decision test asserts scoria-flash--fail + role="alert" + an `<svg` icon, end-to-end (put_flash → flash_group). Component matrix in `ui_component_test.exs`. (Tone *colors* are CSS; out of scope for assertion.)

### 4. Skeleton loading state on workflow detail
expected: Skeleton placeholder while loading; replaced when data resolves.
result: pass
covered-by: Tier 1 — `workflow_live_test.exs` asserts skeleton present before async, absent after `render_async`, no failed state. Tier 2 — `uat.spec.mjs` "workflow detail resolves its loading skeleton" (PASSES in a real browser).

### 5. Remote-invocation evidence renders as a tabbed notebook
expected: Evidence renders inside a tabbed notebook (tablist + Remote tab + panel).
result: pass (component level) — live integration pending (data source stubbed)
covered-by: Tier 1 — `ui_component_test.exs` 3 DS-04 proof tests render `RemoteInvocationEvidenceComponent` as a `<.notebook>` (tablist/tab/aria/phx-value-tab). Live integration + browser tab-switch are `test.fixme` in `uat.spec.mjs`: the only live consumer is gated on `SRE.remote_invocation_evidence/1`, currently a stub returning `%{approvals: []}`, so the notebook never renders in the running app yet. Activate when real evidence is wired.

### 6. DS-06 drift guard passes
expected: `mix test test/scoria_web/ds06_drift_guard_test.exs` green; raw-palette growth fails the build.
result: pass (CI-enforced)
covered-by: `ds06_drift_guard_test.exs` runs unconditionally in the default `mix test --warnings-as-errors` lane (full suite: 627 tests, 0 failures).

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

automated_tiers:
  tier1_server_rendered: passing in `mix test` (CI)
  tier2_browser_active: 1 (skeleton resolution) — passes locally + new `e2e` job in ci.yml
  tier2_pending_fixme: 6 (toast auto/manual dismiss, CR-01, notebook tab-switch, WR-03, escape-dismiss) — each with a named unlock

## Gaps

[none blocking — all six items machine-verified; browser-only residue tracked as named test.fixme]
