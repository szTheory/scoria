---
phase: 12-design-system-component-layer
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - assets/css/04-components.css
  - assets/css/05-motion.css
  - lib/scoria_web/components/remote_invocation_evidence_component.ex
  - lib/scoria_web/live/approvals_live/index.ex
  - lib/scoria_web/live/workflow_live/show.ex
  - lib/scoria_web/ui.ex
  - test/scoria_web/ds06_drift_guard_test.exs
  - test/scoria_web/live/approvals_live_test.exs
  - test/scoria_web/live/workflow_live_test.exs
  - test/scoria_web/ui_component_test.exs
  - test/support/ds06_baseline.txt
findings:
  critical: 1
  warning: 6
  info: 4
  total: 11
status: issues_found
---

# Phase 12: Code Review Report

**Reviewed:** 2026-06-04T00:00:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Phase 12 introduces a shared design-system component vocabulary (`ScoriaWeb.UI`), CSS
component/motion layers, a notebook adapter for remote-invocation evidence, and a DS-06
"ratchet" drift guard plus its committed baseline. The component library is generally well
structured (token-driven, a11y-aware, never-color-alone). However, there is one genuine
LiveView correctness bug in `<.id>` (non-stable DOM id breaking hook patching), several
robustness gaps around the notebook component contract and the approval-decision toast
semantics, and a notable design weakness in the DS-06 drift guard: it is a snapshot-equality
ratchet that silently re-permits palette usage when a file is refactored, and the two
in-scope LiveViews sit exactly at their baseline (53 and 9), so the guard provides no real
headroom and is one line away from breaking unrelated work.

## Critical Issues

### CR-01: `<.id>` regenerates a fresh DOM id + hook on every render (breaks LiveView patching)

**File:** `lib/scoria_web/ui.ex:157-163`
**Issue:** The copyable-id component sets
`id={"id-#{System.unique_integer([:positive])}"}` inside the render body. `System.unique_integer/1`
returns a *different* value on every render pass. In LiveView, the element id is the DOM
patch key — an id that changes on each diff means morphdom treats the element as brand-new,
tearing down and re-mounting the `phx-hook="CopyId"` instance on every parent update. This
causes: (a) the CopyId hook's `mounted/destroyed` lifecycle to thrash, (b) loss of any hook
internal state, (c) wasted DOM churn, and (d) on rapid updates, orphaned hook instances.
The id must be stable across renders for a given logical element. It should be derived from
the value being displayed (or accepted as a required attr from the caller), not a global
monotonic counter evaluated at render time.
**Fix:**
```elixir
attr(:value, :string, required: true)
attr(:copy, :string, default: nil)
attr(:id, :string, default: nil)
attr(:class, :string, default: nil)

def id(assigns) do
  assigns =
    assign_new(assigns, :id, fn ->
      "id-" <> Integer.to_string(:erlang.phash2(assigns.value))
    end)

  ~H"""
  <span class={["scoria-id", @class]} phx-hook="CopyId" id={@id} data-copy={@copy || @value} title="Click to copy">
    {@value}
  </span>
  """
end
```
Prefer a caller-supplied stable id where two identical values can appear on one page.

## Warnings

### WR-01: DS-06 drift guard is an equality-snapshot ratchet that silently re-permits palette on refactor

**File:** `test/scoria_web/ds06_drift_guard_test.exs:32-50`, `test/support/ds06_baseline.txt`
**Issue:** The guard only fails when `count > baseline_count`. It never fails when a file's
count is *below* baseline, and the baseline is a static committed file. Consequence: once a
developer reduces a file's palette usage (the stated Phase 12 goal) but forgets to lower the
baseline, the file silently re-acquires headroom — a future change can add palette classes
back up to the stale baseline with the guard staying green. A ratchet that does not tighten
on improvement freezes the worst-ever state. `workflow_live/show.ex` (baseline 53) and
`approvals_live/index.ex` (baseline 9) currently sit *exactly* at baseline, so the guard
offers zero margin and will fail on the next unrelated one-line palette addition while
providing no protection against re-introducing the 53 classes that were supposed to migrate away.
**Fix:** Either (a) fail when `count != baseline_count` (forces baseline to be re-committed
downward on every improvement), or (b) add a "baseline is not stale" assertion that fails if
any file is now below its baseline, prompting regeneration. Document the regeneration command.

### WR-02: `load_baseline/1` crashes on any malformed baseline line instead of reporting it

**File:** `test/scoria_web/ds06_drift_guard_test.exs:65-73`
**Issue:** `[path, count] = String.split(line, ":", parts: 2)` raises `MatchError` if a line
has no colon, and `String.to_integer(count)` raises `ArgumentError` on non-integer text
(trailing whitespace, a stray `\r`, etc.). A malformed committed baseline entry surfaces as an
opaque crash with no indication of which line is bad rather than a clear drift-guard failure.
A path that itself contains a colon beyond the first (`parts: 2`) puts the remainder into
`count` and crashes.
**Fix:** Trim and validate each field, emitting a descriptive failure naming the offending line.

### WR-03: Approval reject path reports a green ":pass" "Approval decision recorded." toast

**File:** `lib/scoria_web/live/approvals_live/index.ex:182-217`
**Issue:** `record_approval_decision/2` is shared by `approve` and `reject`. On success it
always emits `put_toast(tone: :pass, message: "Approval decision recorded.")`. For a rejection
— which deliberately keeps the workflow *paused* (see copy at lines 150-152) — a `:pass`-tone
"decision recorded" toast communicates a successful, completed-feeling outcome by color and
wording. An operator who rejected gets the same green confirmation as one who approved,
blurring a safety-relevant distinction.
**Fix:** Branch the toast on `status`:
```elixir
toast_opts =
  case status do
    "approved" -> [tone: :pass, message: "Approval granted."]
    "rejected" -> [tone: :warn, message: "Approval rejected — workflow remains paused."]
  end
```

### WR-04: `<.notebook>` renders no panel when `selected_tab` matches no tab key

**File:** `lib/scoria_web/ui.ex:461-506`
**Issue:** The default-tab logic only fires when `selected_tab == nil`. If a caller passes a
non-nil `selected_tab` that matches no `<:tab>` key (stale value after the tab set changes, or
a typo), the tab bar renders with every tab `aria-selected="false"` and the
`for tab <- @tab, tab.key == @selected_tab` comprehension yields nothing — the
`role="tabpanel"` body silently disappears with no error. No uniqueness check on tab keys
exists either; duplicates would render two panels.
**Fix:** Fall back to the first tab whenever `selected_tab` matches nothing:
```elixir
assigns =
  if assigns.tab != [] and not Enum.any?(assigns.tab, &(&1.key == assigns.selected_tab)) do
    assign(assigns, :selected_tab, hd(assigns.tab).key)
  else
    assigns
  end
```

### WR-05: `<.notebook>` tab buttons emit `phx-click={nil}` when `on_tab_change` is unset, yielding inert tabs

**File:** `lib/scoria_web/ui.ex:482-492`, `lib/scoria_web/components/remote_invocation_evidence_component.ex:7,19`
**Issue:** `on_tab_change` defaults to `nil`. When nil, each tab button renders
`phx-click={nil}` (no handler) yet still presents as interactive (`role="tab"`, hover styling).
`RemoteInvocationEvidenceComponent` instantiates the notebook with `on_tab_change={@on_tab_change}`
defaulting to nil and never wires it, and `workflow_live/show.ex:232-235` renders that
component without passing `on_tab_change`. Today the remote notebook has one tab so the dead
click is invisible, but the contract invites a multi-tab caller to ship visibly-broken
non-switching tabs — a control that looks clickable but is inert.
**Fix:** Render a non-button (`<span role="tab">`) when `on_tab_change` is nil and there is one
tab, or raise when `length(@tab) > 1 and is_nil(@on_tab_change)`.

### WR-06: `approval_value/3` collapses present-but-falsy values into the literal "unknown"

**File:** `lib/scoria_web/components/remote_invocation_evidence_component.ex:42-44`
**Issue:** `Map.get(approval, key) || Map.get(approval, to_string(key)) || "unknown"` treats any
falsy value (`nil`, `false`) as missing and substitutes `"unknown"`. A real `nil` (e.g. an
approval id not yet assigned) is rendered to the operator as the word "unknown", indistinguishable
from a genuinely absent key, and a stored `false` under the atom key incorrectly falls through to
the string-key lookup. Use explicit key presence.
**Fix:**
```elixir
defp approval_value(approval, key) do
  cond do
    Map.has_key?(approval, key) -> Map.get(approval, key)
    Map.has_key?(approval, to_string(key)) -> Map.get(approval, to_string(key))
    true -> "unknown"
  end
end
```

## Info

### IN-01: Approval modal in `approvals_live/index.ex` bypasses the new `<.modal>` shell

**File:** `lib/scoria_web/live/approvals_live/index.ex:117-155`
**Issue:** Phase 12 adds a token-driven `<.modal>` (ui.ex:199) with the triple dismiss contract
(close button + scrim + Escape) and semantic surfaces. The approvals page instead hand-rolls a
`fixed inset-0 ... bg-black bg-opacity-50` modal with raw `bg-white` / `text-stone-*` /
`text-blue-700` palette and no Escape/scrim dismissal — the exact drift the design system is
meant to eliminate, keeping the file pinned at its DS-06 baseline of 9.
**Fix:** Replace with `<.modal id="approval-modal" show={...} on_dismiss="dismiss_approval">`.

### IN-02: `workflow_live/show.ex` retains 53 raw-palette classes — the largest drift surface, untouched

**File:** `lib/scoria_web/live/workflow_live/show.ex` (throughout render/1)
**Issue:** This LiveView carries 53 raw palette classes (stone/blue/emerald/amber/red), exactly
matching its DS-06 baseline. It adopts only `<.skeleton>` from the new library while continuing
to hand-roll panels, pill badges (`rounded-full border border-stone-200`), and notices with raw
palette. The design-system goal is only partially realized here.
**Fix:** Incrementally migrate notices/panels/badges to `<.panel>`, `<.badge>`, `<.eyebrow>` and
lower the baseline accordingly.

### IN-03: Test asserts raw palette `ring-2 ring-amber-400` markup (couples test to un-migrated styling)

**File:** `test/scoria_web/live/approvals_live_test.exs:315`
**Issue:** `assert html =~ "ring-2 ring-amber-400"` hard-codes a raw Tailwind palette class as the
highlight signal. This couples the test to styling the design system is meant to replace;
migrating the highlight to a semantic class (e.g. `scoria-attention` from 05-motion.css) would
silently break this assertion.
**Fix:** Add a stable attribute (`data-highlighted` / `aria-current`) to the highlighted row and
assert on that instead of the Tailwind ring class.

### IN-04: `assign_selection/2` reads `selected_step_id` from the pre-pipe socket (latent footgun)

**File:** `lib/scoria_web/live/workflow_live/show.ex:47`
**Issue:** `socket |> assign(:selected_source_variant, source) |> assign_selection(socket.assigns.selected_step_id)`
binds the argument to the *original* socket, not the result of the preceding `assign/3`. Correct
today only because `selected_step_id` is not modified in that pipe; a future edit that also
updates `selected_step_id` would silently use the stale value.
**Fix:** Bind `step_id = socket.assigns.selected_step_id` before the pipe and pass it explicitly.

---

_Reviewed: 2026-06-04T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
