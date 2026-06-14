---
phase: 12-design-system-component-layer
plan: "05"
subsystem: ui
tags: [elixir, phoenix-liveview, design-system, components, toast, skeleton, notebook, drift-guard, tdd]

# Dependency graph
requires: ["12-04"]
provides:
  - toast wiring (DS-05): @toasts assign + put_toast/2 + toast render region in approvals_live
  - skeleton wiring (DS-05): <.skeleton rows={3}> replaces bespoke async loading in workflow_live/show
  - notebook adapter (DS-04): RemoteInvocationEvidenceComponent converted to <.notebook> shell at zero raw palette
  - DS-06 baseline committed: test/support/ds06_baseline.txt (21 grandfathered files)
  - DS-06 ratchet guard active: File.exists? guard removed, :ui_ex_zero tag dropped, guard runs by default
affects: [14-least-iterated-screens, 15-high-traffic-screens, 17-consistency-sweep-proof]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "put_toast/2 builds toast map (id via System.unique_integer, tone, message, duration_ms) and update via Phoenix.Component.update/3 (qualified to resolve Ecto.Query import ambiguity)"
    - "Toast render region placed after flash_group in approvals view (not shared layout)"
    - "<.skeleton rows={3} class=mt-6> replaces bespoke <:loading> slot content only; assign_async unchanged"
    - "RemoteInvocationEvidenceComponent: outer <section> replaced with <.notebook>; interior styles use CSS-variable style= attrs (not class strings)"
    - "DS-06 baseline generated via Regex.scan (counts all occurrences per file, not lines); sorted alphabetically"
    - "render_component(&Module.render/1, assigns) form for Phoenix.Component defmodule components"

key-files:
  created:
    - test/support/ds06_baseline.txt
  modified:
    - lib/scoria_web/live/approvals_live/index.ex
    - lib/scoria_web/live/workflow_live/show.ex
    - lib/scoria_web/components/remote_invocation_evidence_component.ex
    - test/scoria_web/live/approvals_live_test.exs
    - test/scoria_web/live/workflow_live_test.exs
    - test/scoria_web/ui_component_test.exs
    - test/scoria_web/ds06_drift_guard_test.exs

key-decisions:
  - "Phoenix.Component.update/3 must be fully qualified in approvals_live/index.ex — import Ecto.Query creates ambiguity with Phoenix.Component.update/3"
  - "RemoteInvocationEvidenceComponent interior styles use CSS-variable style= attributes (not raw Tailwind classes) to reach zero palette without introducing non-existent CSS class names"
  - "DS-06 baseline uses Regex.scan count (all occurrences per file), not grep -c (lines with at least one match) — the guard and baseline use the same counting function"
  - "workflow_live/show.ex retained at 43 raw palette occurrences in baseline (not excluded) — only the <:loading> block was in scope; the rest stays for Phase 14/15/17"

requirements-completed: [DS-04, DS-05, DS-06]

# Metrics
duration: 17min
completed: 2026-06-04
---

# Phase 12 Plan 05: Real Component Wiring + DS-06 Baseline Summary

**Toast wired into approvals decision handler, skeleton replaces bespoke async loading, RemoteInvocationEvidenceComponent converted to notebook adapter at zero palette, DS-06 ratchet baseline committed and guard activated — raw palette cannot grow or return**

## Performance

- **Duration:** ~17 min
- **Started:** 2026-06-04T16:43:00Z
- **Completed:** 2026-06-04T17:00:04Z
- **Tasks:** 3
- **Files modified:** 7 (1 created)

## Accomplishments

- **Task 1 (TDD — toast + skeleton):** Added `import ScoriaWeb.UI, only: [flash_group: 1, toast: 1]` to `approvals_live/index.ex`. Added `|> assign(:toasts, [])` in `mount/3`. Added `put_toast/2` private helper. Wired `put_toast` in both success (`:pass`) and error (`:fail`) branches of `record_approval_decision/2`. Added `<div id="toast-region" class="scoria-toast-region">` with `<.toast :for={t <- @toasts}>` after `<.flash_group>` in `render/1`. In `workflow_live/show.ex`, added `import ScoriaWeb.UI, only: [skeleton: 1]` and replaced the bespoke `<:loading>` slot (border-stone-200/text-stone-500 markup) with `<:loading><.skeleton rows={3} class="mt-6" /></:loading>`. Both integration tests pass; 22 tests in that file, 0 failures.

- **Task 2 (notebook adapter proof):** Converted `RemoteInvocationEvidenceComponent` from a raw `<section>` shell to a `<.notebook>` adapter. Added `import ScoriaWeb.UI, only: [notebook: 1]`, `attr :selected_tab` and `attr :on_tab_change`. Replaced outer section/header divs with `<.notebook id=remote-invocation-notebook>` wrapping `<:tab key=remote_invocation label=Remote>`. Converted all 8 interior raw palette class strings to CSS-variable `style=` attributes using `--scoria-text`, `--scoria-text-muted`, `--scoria-font-mono`, `--scoria-fs-badge`, `--scoria-space-*`. File scans to zero raw palette. Added 3 DS-04 proof tests in `ui_component_test.exs` using `render_component(&Module.render/1, ...)` form; 45 tests pass.

- **Task 3 (baseline + guard activation):** Generated `test/support/ds06_baseline.txt` via `mix run -e` scanner (Path.wildcard with brace expansion, Regex.scan count, sorted). 21 files with grandfathered raw palette. Excluded `ui.ex` and `remote_invocation_evidence_component.ex` (zeroed in Phase 12). Removed `File.exists?` guard from ratchet test and `:ui_ex_zero` tag from ui.ex-zero test. Updated moduledoc. Both assertions run unconditionally in default `mix test`. Full suite: **624 tests, 0 failures**.

## Task Commits

1. **Task 1 RED: Failing tests for toast and skeleton wiring** — `2d8ac2f` (test)
2. **Task 1 GREEN: Wire real toast into approvals and skeleton into workflow show** — `33d8e7b` (feat)
3. **Task 2: Convert RemoteInvocationEvidenceComponent to notebook adapter DS-04** — `bdd1e8a` (feat)
4. **Task 3: Generate DS-06 baseline and activate full ratchet guard** — `6a5bc58` (feat)

## Files Created/Modified

- `lib/scoria_web/live/approvals_live/index.ex` — Import toast: 1, @toasts assign, put_toast/2, toast render region, success/error put_toast calls in record_approval_decision/2
- `lib/scoria_web/live/workflow_live/show.ex` — Import skeleton: 1, replace bespoke <:loading> with <.skeleton rows={3} class="mt-6" />
- `lib/scoria_web/components/remote_invocation_evidence_component.ex` — Full notebook adapter conversion: <.notebook> shell, :tab slot, zero raw palette
- `test/scoria_web/live/approvals_live_test.exs` — Added toast integration test (render(view) =~ "scoria-toast" after approval decision)
- `test/scoria_web/live/workflow_live_test.exs` — Added skeleton loading state test (html =~ "scoria-skeleton" before async resolves)
- `test/scoria_web/ui_component_test.exs` — Added 3 DS-04 proof tests for RemoteInvocationEvidenceComponent notebook adapter
- `test/scoria_web/ds06_drift_guard_test.exs` — Remove File.exists? guard, remove :ui_ex_zero tag, update moduledoc
- `test/support/ds06_baseline.txt` — Committed DS-06 baseline (21 entries, sorted)

## Decisions Made

- `Phoenix.Component.update/3` must be fully qualified in `approvals_live/index.ex` because `import Ecto.Query, warn: false` at line 11 also imports `update/3`, creating a compile-time ambiguity. Qualifying with the module name resolves it cleanly.
- Interior styles in `RemoteInvocationEvidenceComponent` use `style=` attributes with CSS variables (`--scoria-text`, `--scoria-text-muted`, `--scoria-font-mono`, etc.) rather than inventing non-existent utility classes. This achieves zero raw palette without requiring new CSS class definitions.
- DS-06 baseline counts are Regex.scan occurrences (all per-file), not grep -c line counts — these differ when lines contain multiple matches. The guard and baseline must use the same counting method (both use Regex.scan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Phoenix.Component.update/3 ambiguous with Ecto.Query.update/3**
- **Found during:** Task 1 GREEN compile
- **Issue:** `approvals_live/index.ex` has `import Ecto.Query, warn: false` which also exports `update/3`. `put_toast/2` calling bare `update/3` caused a compile error: "function update/3 imported from both Phoenix.Component and Ecto.Query, call is ambiguous".
- **Fix:** Changed `update(socket, :toasts, ...)` to `Phoenix.Component.update(socket, :toasts, ...)`.
- **Files modified:** `lib/scoria_web/live/approvals_live/index.ex`
- **Commit:** `33d8e7b` (GREEN commit for Task 1)

## DS-06 Baseline

The committed baseline (`test/support/ds06_baseline.txt`) contains 21 entries:

```
lib/scoria_web/components/approval_inbox_component.ex:12
lib/scoria_web/components/citation_evidence_component.ex:18
lib/scoria_web/components/connector_detail_drawer_component.ex:9
lib/scoria_web/components/delegated_evidence_component.ex:46
lib/scoria_web/components/incident_evidence_component.ex:69
lib/scoria_web/components/memory_notebook_component.ex:19
lib/scoria_web/components/replay_evidence_notebook_component.ex:24
lib/scoria_web/components/runtime_detail_drawer_component.ex:38
lib/scoria_web/components/semantic_evidence_notebook_component.ex:27
lib/scoria_web/components/trace_tree_component.ex:7
lib/scoria_web/components/workflow_detail_panel_component.ex:12
lib/scoria_web/components/workflow_tree_component.ex:1
lib/scoria_web/live/approvals_live/index.ex:9
lib/scoria_web/live/connectors_live/index.ex:20
lib/scoria_web/live/dataset_live/promote_component.ex:68
lib/scoria_web/live/incidents_live/index.ex:10
lib/scoria_web/live/orchestrator_live.ex:36
lib/scoria_web/live/prompt_live/release_workbench_live.ex:42
lib/scoria_web/live/review_queue_live.ex:76
lib/scoria_web/live/workflow_live/index.ex:4
lib/scoria_web/live/workflow_live/show.ex:53
```

Excluded (zeroed in Phase 12): `lib/scoria_web/ui.ex`, `lib/scoria_web/components/remote_invocation_evidence_component.ex`.

## Known Stubs

None — all components are fully wired. `put_toast/2` builds real toast maps with `System.unique_integer`-based IDs. The notebook adapter renders real approval data from the evidence map.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes.

- T-12-13 mitigated: Toast `message` in `put_toast/2` derives from `approval_error_message/2` (already safe, already used by `put_flash`). Success message is a literal string "Approval decision recorded." No `raw/1` used.
- T-12-14 mitigated: DS-06 baseline generated mechanically by scanner (not hand-written); guard scans `.ex` + `.heex`; runs in default `mix test`; asserts ui.ex at zero.
- T-12-15 accepted: Toast is purely presentational; authorization logic unchanged.
- `RemoteInvocationEvidenceComponent` approval data (`approval_value/2`) renders via HEEx `{...}` auto-escaping — no XSS surface introduced.

## Self-Check: PASSED

- `lib/scoria_web/live/approvals_live/index.ex` contains `put_toast` — FOUND
- `lib/scoria_web/live/approvals_live/index.ex` contains `import ScoriaWeb.UI, only: [flash_group: 1, toast: 1]` — FOUND
- `lib/scoria_web/live/approvals_live/index.ex` contains `scoria-toast-region` — FOUND
- `lib/scoria_web/live/workflow_live/show.ex` contains `<.skeleton` — FOUND
- `lib/scoria_web/live/workflow_live/show.ex` does NOT contain `Loading compacted memories...` — VERIFIED
- `lib/scoria_web/components/remote_invocation_evidence_component.ex` contains `<.notebook` — FOUND
- `grep -cE` raw palette count on `remote_invocation_evidence_component.ex` = 0 — PASSED
- `test/support/ds06_baseline.txt` exists and contains `lib/scoria_web/live/review_queue_live.ex:76` — FOUND
- `test/support/ds06_baseline.txt` does NOT contain `ui.ex` or `remote_invocation` — VERIFIED
- `ds06_drift_guard_test.exs` does NOT contain `File.exists?` guard — VERIFIED
- `ds06_drift_guard_test.exs` does NOT contain `:ui_ex_zero` tag — VERIFIED
- Commits `2d8ac2f`, `33d8e7b`, `bdd1e8a`, `6a5bc58` present — VERIFIED
- `mix test test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/workflow_live_test.exs` exits 0 — PASSED (22 tests)
- `mix test test/scoria_web/ui_component_test.exs` exits 0 — PASSED (45 tests)
- `mix test test/scoria_web/ds06_drift_guard_test.exs` exits 0 — PASSED (2 tests)
- `mix test` exits 0 — PASSED (624 tests, 0 failures)

---
*Phase: 12-design-system-component-layer*
*Completed: 2026-06-04*
