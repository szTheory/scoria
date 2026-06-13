---
phase: 16-motion-responsive-theme-parity
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - lib/scoria_web/ui.ex
  - lib/scoria_web/components/layouts/app.html.heex
  - lib/scoria_web/components/incident_evidence_component.ex
  - lib/scoria_web/components/replay_evidence_notebook_component.ex
  - lib/scoria_web/components/semantic_evidence_notebook_component.ex
  - lib/scoria_web/components/workflow_tree_component.ex
  - lib/scoria_web/live/connectors_live/index.ex
  - lib/scoria_web/live/dataset_live/index.ex
  - lib/scoria_web/live/incidents_live/index.ex
  - lib/scoria_web/live/review_queue_live.ex
  - lib/scoria_web/live/workflow_live/index.ex
  - lib/scoria_web/live/workflow_live/show.ex
  - assets/css/04-components.css
  - assets/css/05-motion.css
  - assets/js/scoria.js
  - priv/dev/e2e/phase16_parity.spec.mjs
  - test/scoria_web/ui_component_test.exs
  - test/scoria_web/token_contrast_guard_test.exs
  - test/scoria_web/live/connectors_live_test.exs
  - test/scoria_web/live/dataset_live/index_test.exs
  - test/scoria_web/live/review_queue_live_test.exs
  - test/scoria_web/live/workflow_live_test.exs
findings:
  critical: 1
  warning: 6
  info: 5
  total: 12
status: issues_found
---

# Phase 16: Code Review Report

**Reviewed:** 2026-06-13
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Phase 16 hardens the dashboard for mobile/responsive/motion/theme parity: a mobile
topbar + off-canvas nav drawer (Hooks.MobileNav), a responsive `table/1` with an
overflow viewport and opt-in `mobile_summary` slot, named responsive grid utilities,
and focus/status/motion hardening. Token discipline is clean — no raw hex/rgb or
palette classes were introduced in `lib/scoria_web/`, and the evidence/motion/contrast
guards are well-constructed.

The headline defect is that the central Phase 16 deliverable — the mobile summary
cards — ships with **no CSS for the `.scoria-mobile-summary*` class family**. All four
scan tables (Runs, Connectors, Dataset Builder, Review Queue) emit these classes, but
04-components.css defines only the outer `.scoria-table__mobile-summaries` container.
Below 768px the summaries render as unstyled stacked divs with no layout, spacing, or
status hierarchy — directly contradicting the UI-SPEC focal-hierarchy and summary-card
contract (UI-SPEC §"Opt-in mobile summaries"). This is BLOCKER because the mobile
experience this phase exists to deliver is visually broken at the target viewport.

Secondary issues: the motion-layer documentation drifted from the code (drawer timing),
JS hidden-delay/transition comments are stale, and several callsites mix raw layout
utilities where the phase intended named DS classes. No security issues were found
(client JS uses `navigator.clipboard`/`localStorage` defensively with try/catch; HEEx
auto-escapes; the contrast/drift guards are sound).

Note on scope: two latent LiveView crash paths in `review_queue_live.ex` and
`workflow_live/show.ex` exist but were verified **unchanged** since the pre-phase commit
e4b6c38, so they are recorded under Out-of-Scope Observations rather than as Phase 16
findings.

## Critical Issues

### CR-01: Mobile summary cards have no CSS — core deliverable renders unstyled at <768px

**File:** `assets/css/04-components.css:1174` (container only); class family undefined repo-wide
**Also affects:**
- `lib/scoria_web/live/workflow_live/index.ex:71-86`
- `lib/scoria_web/live/connectors_live/index.ex:160-180`
- `lib/scoria_web/live/dataset_live/index.ex:126-142`
- `lib/scoria_web/live/review_queue_live.ex:135-153`

**Issue:** Every `:mobile_summary` slot emits markup like:
```heex
<div class="scoria-mobile-summary">
  <div class="scoria-mobile-summary__label">…</div>
  <div class="scoria-mobile-summary__status">…</div>
  <div class="scoria-mobile-summary__meta">…</div>
  <div class="scoria-mobile-summary__action">…</div>
</div>
```
`04-components.css` defines `.scoria-table__mobile-summaries` (the outer flex column,
line 1174) but there is **no rule anywhere** for `.scoria-mobile-summary`,
`__label`, `__status`, `__meta`, or `__action` (confirmed: `grep -rn
"scoria-mobile-summary" assets/` returns nothing). These classes were introduced
this phase (0 occurrences at e4b6c38, 5 in workflow index alone now). Below 768px the
summary cards therefore have no card border, padding, internal layout, or label/status
hierarchy — they collapse to bare browser-default block divs. This breaks the UI-SPEC
contract that summary cards "expose object label, status badge text, one key
scalar/time, and a primary action" as a coherent card, and the mobile focal-hierarchy
requirement that the active work region read as structured cards.

**Fix:** Add a token-bound card rule family to the components layer, e.g.:
```css
.scoria-mobile-summary {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: var(--scoria-space-2);
  padding: var(--scoria-space-4);
  border: 1px solid var(--scoria-border);
  border-radius: var(--scoria-radius-md);
  background: var(--scoria-surface-panel);
}
.scoria-mobile-summary__label { min-width: 0; font-weight: 600; color: var(--scoria-text); }
.scoria-mobile-summary__status { justify-self: end; }
.scoria-mobile-summary__meta { grid-column: 1 / -1; color: var(--scoria-text-muted); font-size: var(--scoria-fs-label); }
.scoria-mobile-summary__action { grid-column: 1 / -1; }
.scoria-mobile-summary__action .scoria-button { min-height: 44px; }
```
Tune the grid to the intended card layout, then add a render-time or test assertion
that the class family is present in CSS so it cannot regress.

## Warnings

### WR-01: Motion-layer header comment misstates the drawer slide duration

**File:** `assets/css/05-motion.css:8`
**Issue:** The header comment claims `scoria-slide (drawer): opacity+translateX at 200ms
(dur-slow ≤ cap). D-15 ✓`. The desktop `.scoria-drawer` does use `--scoria-dur-slow`
(200ms, 04-components.css:762), but the **mobile** nav drawer
`.scoria-mobile-drawer` transition uses `--scoria-dur-mid` (150ms,
04-components.css:151-152). The doc block in the file that is supposed to be the motion
source of truth does not describe the mobile drawer it now governs, and a reader auditing
"is the mobile drawer ≤200ms?" gets a misleading 200ms answer for a 150ms transition.
**Fix:** Add a line to the header documenting the mobile drawer slide at `dur-mid`
(150ms), or align it to `dur-slow` if 200ms is the intended spec value (UI-SPEC lists
"drawer slide/fade 200ms" as the preferred drawer duration).

### WR-02: MobileNav close-delay comment and value disagree (200ms vs "~120ms")

**File:** `assets/js/scoria.js:538,542`
**Issue:** The comment reads `// Delay hidden so the CSS fade/slide can run (~120ms per
D-19)` but the timeout is `200` ms. The CommandPalette and shortcuts use 120ms
(lines 264, 480); the mobile drawer uses 200ms. The mismatch makes it unclear whether
200 is intentional (it must be ≥ the 150ms drawer transition, so 200 is correct) or a
copy-paste leftover. Stale timing comments cause future maintainers to "fix" the value
back to 120 and clip the close animation.
**Fix:** Update the comment to `(200ms ≥ the 150ms dur-mid drawer transition)`.

### WR-03: Phase intended named DS grid classes but six callsites still emit raw `md:/lg:grid-cols-*`

**File:** `lib/scoria_web/live/connectors_live/index.ex:82` (`grid gap-6 lg:grid-cols-2`)
**Also:** `dataset_live/index.ex:74`, `incidents_live/index.ex:67`,
`review_queue_live.ex:61` and `:79`, `incident_evidence_component.ex:28`
(`lg:grid-cols-5`)
**Issue:** UI-SPEC §"Workflow and evidence mobile layout" states unsupported utilities
"must be replaced with named Scoria component classes … or added as general token-backed
utilities only when broadly reusable." The phase added named DS classes
(`.scoria-evidence-split`, `.scoria-page-split`, `.scoria-page-split--xl-reverse`) and a
breakpoint utility table in 06-utilities.css. These six callsites still rely on the raw
`md:/lg:grid-cols-*` utilities. The utilities ARE defined (06-utilities.css:168-184) so
the layouts render, but `incident_evidence_component.ex:28` uses `lg:grid-cols-5` inside
a component whose siblings were migrated to `.scoria-evidence-split`, leaving an
inconsistent split idiom in the same file. This is a consistency/maintainability defect
the DS-06 drift guard does not catch (it flags raw color, not layout utilities).
**Fix:** Either migrate these to the named DS split classes for consistency, or document
in the phase summary that the `md:/lg:grid-cols-*` token-backed utilities are the
sanctioned primitive for metric strips and explicitly exempt them.

### WR-04: `connectors_live` density toggle silently coerces unknown values to `:default`

**File:** `lib/scoria_web/live/connectors_live/index.ex:60-69`
**Issue:** `set_density` only matches `"compact"`/`"comfortable"` and routes everything
else (including `"default"`) to `:default`. That is functionally fine, but the table
emits three density buttons (`compact`/`default`/`comfortable`, ui.ex:929) and the
"default" button posts `phx-value-density="default"`, which falls through the `_ ->
:default` clause. This works by accident. More importantly, both connector tables share
one `@connector_table_density` assign while each renders its own density toggle — clicking
density on the runtimes table also re-renders the connectors table's active state, which
can confuse an operator (two toggles, one source of truth, no visual indication they are
linked).
**Fix:** Either give each table its own density assign, or render a single shared density
control above both tables so the coupled state is visible.

### WR-05: Incidents history button uses `aria-current="true"` instead of a standard token

**File:** `lib/scoria_web/live/incidents_live/index.ex:92`
**Issue:** `aria-current={incident.id == @selected_incident_id && "true"}`. `aria-current`
takes enumerated tokens (`page`, `step`, `location`, `date`, `time`, `true`, `false`).
`"true"` is technically valid, but for a selected item in a list the semantically correct
token is `aria-current="true"` only when there is no better match; here the buttons form a
selectable list, so `aria-current="true"` reads to AT as "this is the current item" without
conveying that the partner detail panel updated. The same `&& "true"` pattern appears in
`workflow_tree_component.ex:17` and `review_queue_live.ex:129`. Not wrong, but the phase's
own contract (UI-SPEC §Status: "Selected list/table/options use `aria-selected` … where
appropriate") suggests `aria-selected` would be the more accurate semantic for a
single-select list of buttons.
**Fix:** Where the buttons are a single-select list driving a detail rail, prefer
`aria-selected={...}` (or `aria-pressed` for toggle semantics). Keep `aria-current="page"`
for nav.

### WR-06: `dataset_live` `last_promoted_at/1` can crash on all-nil timestamps

**File:** `lib/scoria_web/live/dataset_live/index.ex:347-352`
**Issue:**
```elixir
defp last_promoted_at(items) do
  items
  |> Enum.map(&(&1.inserted_at || &1.updated_at))
  |> Enum.reject(&is_nil/1)
  |> Enum.max(DateTime)
end
```
If every item has both `inserted_at` and `updated_at` nil, `Enum.reject` yields `[]` and
`Enum.max([], DateTime)` raises `Enum.EmptyError`, crashing dataset row construction. The
`dataset_rows/0` caller has a `rescue _ -> []` (line 284-285), so the whole dataset list
would be silently swallowed to empty rather than crashing the page — meaning a single
malformed item makes ALL datasets disappear with no error surfaced. The `[]` clause at
line 345 only guards the empty-items case, not the all-nil-timestamps case.
**Fix:** Provide an empty fallback to `Enum.max`:
```elixir
|> Enum.reject(&is_nil/1)
|> case do
  [] -> nil
  stamps -> Enum.max(stamps, DateTime)
end
```

## Info

### IN-01: `refresh_queue/2` `reset_selection` parameter is dead code

**File:** `lib/scoria_web/live/review_queue_live.ex:219`
**Issue:** `defp refresh_queue(socket, reset_selection \\ true)` — every call site
(`mount`, `change_filters`, `dismiss_candidate`) invokes the 1-arity form, so
`reset_selection` is always `true` and the `else` branch (lines 226-227) is unreachable.
**Fix:** Drop the parameter and the unused branch, or wire `change_filters` to pass
`false` if filter changes should preserve the current selection.

### IN-02: `connectors_live` `set_density` does not also re-fetch — fine, but `format_ts` arms differ from siblings

**File:** `lib/scoria_web/live/connectors_live/index.ex:217-219` vs
`workflow_live/index.ex:112-114`, `dataset_live/index.ex:377-379`
**Issue:** Three nearly identical `format_ts/1` helpers exist across the changed
LiveViews with slightly different nil copy (`"Not recorded"` vs `"—"` vs `"Never"`).
Duplication invites drift; the empty-state copy differs per screen for the same concept.
**Fix:** Consider a shared `ScoriaWeb.UI`/format helper, or accept per-domain copy and
document it.

### IN-03: `incident_evidence_component` mixes `space-y-*`/`mt-3` utilities with DS split classes

**File:** `lib/scoria_web/components/incident_evidence_component.ex:16,28,57,76,100`
**Issue:** The component now uses `.scoria-evidence-split` (line 57) alongside ad-hoc
`space-y-4`, `mt-3`, `grid gap-3 lg:grid-cols-5` utilities. The phase moved evidence
splits to named classes; the residual utility soup in the same file is a readability/
consistency nit.
**Fix:** Optional cleanup pass to named classes when next editing this file.

### IN-04: `MobileNav` aria-expanded targeting assumes a single open button

**File:** `assets/js/scoria.js:527,536`
**Issue:** `document.querySelector("[data-mobile-nav-open]")` grabs the first matching
button to flip `aria-expanded`. Today there is exactly one (app.html.heex:33), so this is
correct, but if a second mobile-nav-open affordance is ever added, only the first will get
its `aria-expanded` synced.
**Fix:** Iterate all `[data-mobile-nav-open]` elements when setting `aria-expanded`, or
store the actual opener element passed to `openNav`.

### IN-05: `token_contrast_guard` `parse_hex/1` only accepts 6-digit hex

**File:** `test/scoria_web/token_contrast_guard_test.exs:236`
**Issue:** `parse_hex("#" <> hex) when byte_size(hex) == 6` has no clause for 3- or
8-digit hex. If a token is ever authored as `#fff` or `#rrggbbaa`, the guard raises
`FunctionClauseError` instead of a clear "unsupported hex form" message.
**Fix:** Add a fallback clause that flunks with a descriptive message for non-6-digit hex,
or normalize 3-digit to 6-digit before parsing.

---

## Out-of-Scope Observations (pre-existing, unchanged since e4b6c38 — not Phase 16 findings)

These were verified against the pre-phase commit and are NOT introduced by Phase 16.
Recorded for visibility only; do not gate this phase on them.

- **`review_queue_live.ex:36-46` — `dismiss_candidate` `with` has no `else`.** If
  `socket.assigns.selected_candidate` is not a map (e.g. `nil`) or
  `Eval.dismiss_review_candidate/1` returns `{:error, _}`, the `with` returns the
  non-`{:noreply, _}` value and the handler crashes. Pre-existing.
- **`workflow_live/show.ex:381-407` — `promotion_context/1` strict map match.** The
  `%{workflow_run_id: …, source_checkpoint_id: …, replay_disposition: …,
  replay_reason_code: …} = provenance` will raise `MatchError` on step selection if
  provenance lacks any of those keys (contrast with the defensive `with` used in
  `dataset_live/index.ex:259-278`). Pre-existing.
- **`review_queue_live.ex:58` — hardcoded `href="/scoria"`** ignores `@scoria_base`,
  unlike every other link on the page which uses `assigns[:scoria_base]`. Pre-existing.
- **`.scoria-input` referenced but undefined.** `review_queue_live.ex:81,88,96` use
  `class="scoria-input"` on `<select>`; no CSS defines it (`grep -rn "scoria-input"
  assets/` is empty). Pre-existing (3 occurrences at e4b6c38, 3 now).

---

_Reviewed: 2026-06-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
