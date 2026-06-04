---
phase: 12-design-system-component-layer
verified: 2026-06-04T18:30:00Z
status: passed
score: 13/13 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 12: Design-System Component Layer Verification Report

**Phase Goal:** Expose `ui.ex` table/drawer/modal/form/notebook/skeleton/toast components, fix `flash_group`, add executable raw-color drift guard. The enforced token gateway.
**Verified:** 2026-06-04T18:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `ui.ex` has zero raw palette occurrences (the gateway is self-consistent) | VERIFIED | `grep -cE` returns 0; DS-06 ui.ex-zero test passes (2 tests, 0 failures) |
| 2 | `flash_group` renders semantic `scoria-flash--{tone}` classes keyed by the STRING flash kind (not atom) | VERIFIED | `defp flash_modifier("error")`, `flash_modifier("info")`, `flash_modifier("success")`, fallback `_kind` → `"scoria-flash--warn"` confirmed in ui.ex lines 682-685; `flash_tone_class/1` deleted |
| 3 | `flash_group` items carry `role="alert"` | VERIFIED | ui.ex line 673: `role="alert"` in flash_group template |
| 4 | `<.table>` with a `key`-bearing `<:col>` emits `phx-value-by` with that key | VERIFIED | ui.ex line 579: `phx-value-by={Map.get(column, :key)}`; 45 unit tests pass including `phx-value-by` assertion |
| 5 | Density modifier applied: `:compact` → `scoria-table--compact`, `:default` → no modifier | VERIFIED | `density_class/1` at ui.ex lines 658-660; test confirms `scoria-table--compact` present for `:compact`, absent for `:default` |
| 6 | `<.modal>` and `<.drawer>` render nothing when `show={false}`, and render the panel with `role="dialog"` when `show={true}` | VERIFIED | Both use `:if={@show}` on outer wrapper (ui.ex lines 201, 248); `role="dialog" aria-modal="true"` confirmed on modal line 203 and drawer line 256 |
| 7 | Overlays have the triple dismiss contract (close button + scrim + Escape) | VERIFIED | `phx-window-keydown={@on_dismiss} phx-key="Escape"` on modal (line 201) and scrim (drawer lines 252-253); close buttons with `aria-label="Close dialog"` (line 213) and "Close drawer" text (line 269); scrim `phx-click={@on_dismiss}` on both |
| 8 | `<.field>` renders label/help/icon-bearing error with required a11y affordances | VERIFIED | ui.ex lines 298-316: `<label for={@id}>`, error SVG at line 309, `aria-hidden="true"` asterisk + `sr-only` "(required)" span confirmed |
| 9 | `<.notebook>` renders `role="tablist"` with one `role="tab"` per tab, active tab `aria-selected="true"`, and emits `phx-value-tab` | VERIFIED | ui.ex lines 481-503: `role="tablist"`, `role="tab"`, `aria-selected={to_string(tab.key == @selected_tab)}`, `phx-value-tab={tab.key}`; `aria-labelledby` on panel (line 498) |
| 10 | `<.skeleton>` renders `aria-label="Loading…"` with `role="status"` and stacked rows | VERIFIED | ui.ex lines 347-351: `aria-label="Loading…"`, `role="status"`, `:for={_ <- 1..@rows}` |
| 11 | `<.toast>` renders `scoria-toast--{tone}`, `role="status"`, `phx-mounted` auto-dismiss, and a manual dismiss button | VERIFIED | ui.ex lines 363-383: tone class interpolation, `role="status"`, `phx-mounted={JS.hide(...)}` without `to:`, dismiss button with `aria-label="Dismiss"` |
| 12 | DS-06 drift guard is active with baseline committed, `File.exists?` guard removed, `:ui_ex_zero` tag dropped | VERIFIED | `ds06_drift_guard_test.exs` has no `File.exists?` and no `:ui_ex_zero` tag; `test/support/ds06_baseline.txt` exists (21 entries); `mix test test/scoria_web/ds06_drift_guard_test.exs` exits 0 (2 tests, 0 failures) |
| 13 | One real toast, one real skeleton, and one notebook adapter wired into live screens | VERIFIED | `approvals_live/index.ex`: `import ScoriaWeb.UI, only: [flash_group: 1, toast: 1]`, `put_toast/2`, `scoria-toast-region`, toast-region after flash_group; `workflow_live/show.ex`: `import ScoriaWeb.UI, only: [skeleton: 1]`, `<.skeleton rows={3} class="mt-6">` in `<:loading>` slot; `remote_invocation_evidence_component.ex`: `import ScoriaWeb.UI, only: [notebook: 1]`, `<.notebook>` shell at zero raw palette |

**Score:** 13/13 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/scoria_web/ui.ex` | All 9 component functions + flash_group fix | VERIFIED | All 9 `def` declarations confirmed: table, drawer, modal, field, form_section, notebook, raw_evidence, skeleton, toast; flash_group rewritten; `alias Phoenix.LiveView.JS` present |
| `assets/css/04-components.css` | All net-new component CSS classes | VERIFIED | `.scoria-flash--fail`, `.scoria-skeleton`, `.scoria-toast--pass`, `.scoria-notebook__tab`, `.scoria-table--compact`, `.scoria-field__error` all confirmed present |
| `assets/css/05-motion.css` | `scoria-skeleton-pulse` keyframe | VERIFIED | Confirmed present in `@layer scoria.components` |
| `test/scoria_web/ds06_drift_guard_test.exs` | DS-06 ratchet guard module | VERIFIED | `defmodule ScoriaWeb.DS06DriftGuardTest`, correct `@palette_regex`, `@excluded`, `Path.wildcard("lib/scoria_web/**/*.{ex,heex}")`, 2 tests run unconditionally |
| `test/support/ds06_baseline.txt` | Committed path:count baseline | VERIFIED | 21 entries; contains `lib/scoria_web/live/review_queue_live.ex:76`; does NOT contain `ui.ex` or `remote_invocation` |
| `test/scoria_web/ui_component_test.exs` | 45 render_component assertions | VERIFIED | 45 tests confirmed passing; contains assertions for flash_group, table, modal, drawer, field, form_section, notebook, skeleton, toast |
| `lib/scoria_web/components/remote_invocation_evidence_component.ex` | Notebook adapter at zero palette | VERIFIED | Imports `notebook: 1`, uses `<.notebook>` shell; `grep -cE` returns 0 |
| `lib/scoria_web/live/approvals_live/index.ex` | Toast wiring | VERIFIED | `import ScoriaWeb.UI, only: [flash_group: 1, toast: 1]`, `put_toast/2`, `scoria-toast-region`, `<.toast :for={t <- @toasts}>` confirmed |
| `lib/scoria_web/live/workflow_live/show.ex` | Skeleton wiring | VERIFIED | `import ScoriaWeb.UI, only: [skeleton: 1]`, `<.skeleton rows={3}>` confirmed at line 213 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ds06_drift_guard_test.exs` | `test/support/ds06_baseline.txt` | `File.read!(@baseline_path)` in `load_baseline/0` | WIRED | Baseline path `"test/support/ds06_baseline.txt"` hardcoded at line 30; `load_baseline/0` uses `File.read!` (no guard); baseline file confirmed present |
| `flash_group/1` | `.scoria-flash--{tone}` CSS | `flash_modifier/1` string-keyed clauses | WIRED | `flash_modifier("error") → "scoria-flash--fail"` routes to CSS class confirmed in 04-components.css |
| `table/1 :col header` | parent LiveView sort handler | `phx-click={Map.get(column, :key) && "sort"} phx-value-by={Map.get(column, :key)}` | WIRED | Pattern confirmed at ui.ex lines 578-579 |
| `modal/1` | parent LiveView dismiss handler | `phx-window-keydown={@on_dismiss} phx-key="Escape"` | WIRED | Confirmed at ui.ex line 201 |
| `approvals_live record_approval_decision` | `<.toast>` render region | `put_toast/2 → update(:toasts)` | WIRED | `put_toast` called in both success (line 195) and error (line 200) branches; `<.toast :for={t <- @toasts}>` at line 107 |
| `notebook/1 tab button` | parent LiveView selected_tab | `phx-click={@on_tab_change} phx-value-tab={tab.key}` | WIRED | Confirmed at ui.ex lines 488-489 |
| `toast/1` | auto-dismiss | `phx-mounted={JS.hide(transition: ..., time: @duration_ms)}` without `to:` | WIRED | Confirmed at ui.ex line 369; no `to:` option present (self-targeting per Pitfall 3) |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `approvals_live/index.ex` toast region | `@toasts` | `put_toast/2` called from `record_approval_decision/2` on real user actions | Yes — `System.unique_integer` ID + real error message from `approval_error_message/2` | FLOWING |
| `workflow_live/show.ex` skeleton | Server-side `assign_async` pending state | `assign_async` call populates the `<:loading>` slot during pending state | Yes — loading state driven by real async assign lifecycle | FLOWING |
| `remote_invocation_evidence_component.ex` notebook | `@evidence` map | Passed in from caller LiveView with real evidence data | Yes — renders existing approval data via `approval_value/2` | FLOWING |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| DS-06 guard runs unconditionally and passes | `mix test test/scoria_web/ds06_drift_guard_test.exs` | 2 tests, 0 failures | PASS |
| All component unit tests pass (45 assertions) | `mix test test/scoria_web/ui_component_test.exs` | 45 tests, 0 failures | PASS |
| `ui.ex` raw palette count is zero | `grep -cE '\b(stone\|rose\|...\|fuchsia)-[0-9]' lib/scoria_web/ui.ex` | returns 0 | PASS |
| `remote_invocation_evidence_component.ex` raw palette count is zero | same grep on component file | returns 0 | PASS |
| `test/support/ds06_baseline.txt` contains grandfathered entries but NOT excluded files | file existence + grep check | 21 entries, no `ui.ex`, no `remote_invocation` | PASS |

---

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DS-01 | 12-02 | Shared `<.table>` with sort, filter, pagination, density toggle, empty state | SATISFIED | `def table(` confirmed; all attrs/slots verified; density_class/1; pagination nav; 5 unit tests |
| DS-02 | 12-03 | Shared drawer/modal shells with consistent open/dismiss | SATISFIED | `def drawer(` and `def modal(` confirmed; triple dismiss contract wired; show/hide conditional rendering |
| DS-03 | 12-03 | Shared form control set with labelling + validation | SATISFIED | `def field(` and `def form_section(` confirmed; required a11y, icon error, inner_block slot |
| DS-04 | 12-04, 12-05 | Evidence panels through unified notebook shell | SATISFIED | `def notebook(` with typed :tab slots; RemoteInvocationEvidenceComponent notebook adapter at zero palette |
| DS-05 | 12-02, 12-04, 12-05 | Skeleton, toast, fixed flash_group | SATISFIED | All three present; real wiring in approvals (toast) and workflow_live (skeleton); flash_group string-keyed |
| DS-06 | 12-01, 12-05 | Executable drift guard fails build on raw palette growth | SATISFIED | Guard active, baseline committed, `File.exists?` guard removed, `:ui_ex_zero` tag removed, 2 tests pass unconditionally |

---

### Anti-Patterns Found

The code review (12-REVIEW.md) already identified the following issues, which are carried forward verbatim for traceability. None prevent goal achievement (all component contracts are exposed and wired), but several should be resolved before Phase 14/15 begin consuming these components at scale.

| File | Location | Pattern | Severity | Impact on Goal |
|------|----------|---------|----------|----------------|
| `assets/css/04-components.css` | lines 559-591 | **CR-01**: `.scoria-toast` has `position: fixed` while `.scoria-toast-region` also has `position: fixed` — fixed children inside a fixed parent collapse to zero height. All toasts after the first stack at identical viewport coordinates. | WARNING — visible defect in multi-toast scenarios | Does NOT block goal. Single toast works. Contract (tones/role/phx-mounted/dismiss) is correct. |
| `lib/scoria_web/ui.ex` | line 349 | **WR-01**: `<div :for={_ <- 1..@rows}` — `1..0` in Elixir 1.12+ is a decreasing range `[1, 0]`, so `rows=0` renders 2 skeleton rows instead of 0. Compiler warning emitted. | WARNING — edge-case behavioral bug | Does NOT block goal. No current caller passes `rows=0`. |
| `lib/scoria_web/ui.ex` | lines 203, 256 | **WR-02**: `modal/1` and `drawer/1` render `role="dialog" aria-modal="true"` without `aria-labelledby`. Screen readers announce "dialog" with no accessible name. | WARNING — a11y gap | Does NOT block goal. Dialog contract (show/dismiss/role) is correct. WCAG AA strictness deferred to Phase 16 (MOTION-02). |
| `assets/css/04-components.css` | line 319 | **WR-03**: `.scoria-drawer` has no `position: fixed/absolute`, no z-index, no width. `.scoria-drawer-shell` has no CSS definition at all. Drawer renders inline in document flow, not as a floating side panel. | WARNING — visual layout defect | Does NOT block goal. Dismiss contract and HEEx wiring are correct. |
| `test/scoria_web/ds06_drift_guard_test.exs` | lines 41-43 | **WR-04**: `cond` branch `baseline_count == 0 and count > 0 → :new_violation` is dead code — the prior `count > baseline_count` clause fires first when `baseline_count == 0`. Violations are still caught (via `:regression`); error messages are less informative. | WARNING — misleading error messages | Does NOT block goal. Guard catches all violations. |
| `lib/scoria_web/ui.ex` | lines 544, 631-651 | **WR-05**: `on_page_change` defaults to `nil`; pagination renders with `phx-click={nil}` (silent no-op) when `total_pages > 1` but `on_page_change` is unset. | WARNING — silent UX failure potential | Does NOT block goal. Pagination only renders when caller sets `total_pages > 1`. |
| `lib/scoria_web/ui.ex` | line 487 | **IN-01**: `"scoria-notebook__tab--active"` class emitted but has no CSS definition; active styling relies solely on `[aria-selected="true"]` | Info | No visual impact as aria-selected rule covers it |
| `assets/css/04-components.css` | multiple | **IN-02**: Several structural classes emitted by components have no CSS rules: `scoria-drawer-shell`, `scoria-drawer__body`, `scoria-drawer__header-text`, `scoria-drawer__header-actions`, `scoria-modal__body`, `scoria-notebook__header`, `scoria-notebook__title`, `scoria-skeleton-group`, `scoria-table-shell`, `scoria-table__filter`, `scoria-table__density-toggle`, `scoria-table__pagination`, `scoria-table__page-label`, `scoria-table__td--actions` | Info | Default browser styling (block display); most have no severe rendering gap |
| `lib/scoria_web/ui.ex` | lines 369, 374 | **IN-03**: `JS.hide` transition classes `{"scoria-fade", "opacity-100", "opacity-0"}` — `opacity-100`/`opacity-0` are Tailwind utility classes not defined in library CSS. Host apps without Tailwind get instant hide instead of fade. | Info | Functionally correct; animation degraded in non-Tailwind hosts |
| `test/scoria_web/live/approvals_live_test.exs` | line 60 | **IN-04**: `secret_key_base` is exactly 64 chars — at minimum per MEMORY.md note (boundary, not above it) | Info | Tests pass; fragile if truncated |

---

### Human Verification Required

None. All must-haves are verifiable programmatically and confirmed. The code review warnings (CSS layout, a11y) are documented above. Phase 16 (MOTION-02) owns the a11y bar; Phase 14/15 own screen-level polish. The review issues are pre-registered for those phases, not blockers here.

---

### Gaps Summary

No gaps blocking phase goal achievement. All 13 truths are VERIFIED. DS-01 through DS-06 are all SATISFIED.

The code review (12-REVIEW.md) found 5 warnings and 4 info items, all carried forward as pre-registered technical debt:

- **CR-01** (toast overlap CSS) — fix before Phase 15 high-traffic screens consume `<.toast>` at scale
- **WR-01** (skeleton `rows=0` range) — add `//1` step or guard before any caller passes 0
- **WR-02** (missing `aria-labelledby` on dialogs) — fix before MOTION-02 a11y pass
- **WR-03** (drawer not positioned) — critical UX fix before Phase 14/15 drawer conversions
- **WR-04** (`:new_violation` dead code) — cosmetic; fix cond ordering for better error messages

These are queued for the next planning pass. They do not alter the phase-12 verdict.

---

## Remediation (clean-state pass, 2026-06-04)

A follow-up clean-state pass resolved the open anti-patterns above (verified by
`mix test` unit assertions and the Tier 2 Playwright e2e lane):

| ID | Resolution |
|----|------------|
| CR-01 | Removed `position: fixed` from `.scoria-toast`; the fixed `.scoria-toast-region` (flex column) owns stacking. E2e asserts a toast's computed `position` is not `fixed`. |
| WR-01 | Skeleton `1..@rows` → `1..@rows//1` (rows=0 → 0 rows; cleared the decreasing-range warning). Unit test for rows=0. |
| WR-02 | `modal/1` + `drawer/1` now set `aria-labelledby` → the titled `<h2 id="#{@id}-title">`. Unit tests added. |
| WR-03 + IN-02 | `.scoria-drawer-shell` (fixed, right-anchored) + `.scoria-drawer` (full height, width, z-index, scroll) added; the previously rule-less structural classes (drawer/modal/notebook/table/skeleton) given token-bound layout defaults. |
| WR-04 | DS-06 `cond` reordered so the `:new_violation` branch is reachable (informative messages). |
| WR-05 | `table/1` now raises when `total_pages > 1` and `on_page_change` is nil (matches the `<.notebook>` guard) instead of emitting `phx-click={nil}`. Unit test for the raise. |
| IN-04 | Test-endpoint `secret_key_base` padded well past the 64-char minimum across all dashboard LiveView test endpoints. |

Also fixed (found by the browser e2e, not in the original list): the toast manual-dismiss
button used a bare `JS.hide()` that hid the button instead of the toast — now targets the
toast by id (`to: "##{@id}"`). And the keystone enabling all of the above: `dev_seed.exs` now
seeds reachable pending approvals synchronously (previously the queued approval step was never
executed, so the inbox was empty — the same root cause behind Phase 11's skipped approvals overlay).

Still deferred (need future-phase screen wiring / un-stubbed data, tracked in STATE.md): the
WR-03 drawer-float, escape-dismiss, and notebook tab-switch **e2e specs** remain `test.fixme`
until a screen consumes `<.modal>`/`<.drawer>` and `SRE.remote_invocation_evidence/1` returns
real data.

---

_Verified: 2026-06-04T18:30:00Z_
_Verifier: Claude (gsd-verifier)_
_Remediated: 2026-06-04 (clean-state pass)_
