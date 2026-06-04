# Phase 12: Design-System Component Layer - Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView HEEx function components, slot-based shells, JS-driven animation, ExUnit drift guard
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**GA1 — Drift-guard activation & migration scope (DS-06)**
- **D-01:** DS-06 ships as a **ratchet baseline guard**. Implement `test/scoria_web/ds06_drift_guard_test.exs` (ExUnit, LiveViewTest-only posture) that scans `.ex`/`.heex` under `lib/scoria_web/` for raw palette classes (`~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/`).
- **D-02:** Commit `test/support/ds06_baseline.txt` of `path:count` pairs. Fails if: any baselined file's count exceeds its baseline, OR any non-baselined file has a nonzero count.
- **D-03:** `lib/scoria_web/ui.ex` is swept to zero immediately and excluded from baseline. Any other file Phase 12 touches drops to zero and is excluded too.
- **D-04:** Phases 14/15 shrink baseline; Phase 17 deletes baseline file and flips to strict zero-tolerance.
- **D-05:** Phase 12 success criterion #5 ("build fails if raw palette appears") is satisfied in spirit — the guard exists and is wired into `mix test`, preventing raw palette from returning or growing.

**GA2 — Evidence notebook conversion scope (DS-04)**
- **D-06:** Phase 12 builds the `<.notebook>` shell (tabbed, slot-based, per UI-SPEC DS-04 API). Full conversion of 13 evidence components is Phase 15.
- **D-07:** Prove the shell by converting exactly **one** thinnest evidence component. Planner picks the lightest candidate.

**GA3 — Component adoption / API proof**
- **D-08:** No full-screen migration in Phase 12.
- **D-09:** Component APIs validated via `render_component`/LiveViewTest unit tests for each new component, plus DS-05-mandated real wiring.

**GA4 — Toast & skeleton wiring (DS-05)**
- **D-10:** `<.toast>` driven by server-held `@toasts` assign list + `put_toast/2` helper mirroring `put_flash/3` + `flash_group` pattern. NOT `push_event` + JS hook.
- **D-11:** Auto-dismiss uses pure `Phoenix.LiveView.JS` — `phx-mounted={JS.hide(to: ..., transition: ..., time: duration_ms)}`. Tests assert toast renders; disappear timer is acceptably unasserted.
- **D-12:** Wire one real end-to-end path: a genuine server-triggered toast (approvals/promote/gate action that already calls `put_flash`) and one real `<.skeleton>` loading state on a screen with an async load.

**`flash_group` fix (DS-05)**
- **D-13:** Replace `flash_tone_class/1` in `ui.ex` (lines ~195–197) with semantic BEM modifiers (`scoria-flash--fail/info/warn/pass`) and add `.scoria-flash` CSS to `assets/css/04-components.css` per UI-SPEC DS-05.

### Claude's Discretion
- Exact internal HEEx structure of each component, helper function names, test file organization, and which specific thinnest evidence component / which real toast+skeleton paths to wire.

### Deferred Ideas (OUT OF SCOPE)
- Full raw-palette sweep across all 23 files (Phases 14, 15, 17)
- 13 evidence components as thin `<.notebook>` adapters (Phase 15)
- Screen migrations onto `<.table>`/`<.field>`/`<.drawer>` (Phases 14/15)
- Motion, responsive breakpoints, full light/dark parity audit (Phase 16)
- Final audit loop, before/after contact sheets, `docs/MAINTAINERS.md` catalog (Phase 17)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DS-01 | Shared `<.table>` component: sort, filter/search, pagination, density toggle, empty state | Slot pattern with `<:col>` confirmed in Phoenix 1.1.30 deps. Existing `.scoria-table` CSS already in `04-components.css`. Parent LiveView owns sort/density state; component emits phx-click events. |
| DS-02 | Shared `<.drawer>` and `<.modal>` slot-based shells with consistent open/dismiss | Existing `.scoria-scrim`, `.scoria-modal__panel`, `.scoria-drawer` CSS confirmed. JS.hide/JS.show patterns confirmed in deps. `phx-window-keydown` + `phx-key="Escape"` for keyboard dismiss. |
| DS-03 | Shared form controls (`<.field>`, `<.form_section>`) with labelling and validation display | No existing `scoria-field` or `scoria-input` wrapper component; `.scoria-input` CSS class already exists. `<:inner_block>` slot pattern confirmed for caller-provided `<input>` elements. |
| DS-04 | Unified `<.notebook>` shell for evidence panels | Named slot with attrs pattern confirmed in Phoenix.Component. `<:tab>` slot with `key`/`label` attrs. Lightest evidence component is `RemoteInvocationEvidenceComponent` (8 palette occurrences). |
| DS-05 | Shared skeleton/toast components; `flash_group` routed through token system | `flash_tone_class/1` raw-palette lines confirmed at `ui.ex:195–197`. `assign_async`/`<.async_result>` loading pattern confirmed in `orchestrator_live.ex` and `workflow_live/show.ex`. |
| DS-06 | Executable drift guard that fails mix test if raw palette appears under `lib/scoria_web/` | File-walking pattern confirmed from `ui_drift_guard_test.exs`. 498 total occurrences across 23 files. Regex confirmed. Existing test modelled in `test/scoria_web/ui_drift_guard_test.exs`. |
</phase_requirements>

---

## Summary

Phase 12 exposes the enforced token gateway: eight new shared HEEx function components in `lib/scoria_web/ui.ex` that wrap CSS classes already defined in `assets/css/04-components.css`. The CSS (tables, drawers, modals, inputs, scrim, motion keyframes) is complete and proven — the gap is the Elixir function component layer that standardizes slot/attr contracts and eliminates 23 files' worth of hand-rolled markup.

The project is on Phoenix LiveView 1.1.30 (locked), which provides the full `slot/3` macro with attrs, `attr/3` types, and `Phoenix.LiveView.JS` (JS.hide/JS.show with `transition:` and `time:` opts). No new packages are needed. The pattern for all slot-based shells is already in the codebase in `ui.ex`'s existing `panel/1` (named slots: `:eyebrow`, `:title`, `:actions`, `:inner_block`) — the new shells extend this pattern. The `render_component/2` unit testing pattern is confirmed and used in three existing component test files. The existing `ui_drift_guard_test.exs` provides the exact file-walking and `Path.wildcard` pattern the DS-06 guard should use.

The thinnest evidence component for DS-04 proof-of-API is `RemoteInvocationEvidenceComponent` (8 raw palette occurrences, 43 lines, no `use Phoenix.LiveComponent` — simple `use Phoenix.Component` only, trivially wrappable).

**Primary recommendation:** Implement all eight components in `ui.ex` sequentially, zeroing `ui.ex`'s own raw palette as part of the `flash_group` fix (DS-05 first), then add CSS to `04-components.css`, write `render_component` unit tests, wire the one real toast + one real skeleton path, build the DS-06 guard with baseline, and commit the baseline file in the same wave.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `<.table>` sort/filter/density state | API / Backend (LiveView process) | Browser (phx-click events) | State (sort_by, sort_dir, density) owned in assigns; component emits events, parent handles them |
| `<.drawer>` / `<.modal>` visibility | API / Backend (LiveView process) | Browser (CSS animation on render) | `show` assign drives conditional render; scrim/keyboard dismiss emits to parent via `on_dismiss` |
| `<.field>` / `<.form_section>` | Frontend Server (SSR) | — | Pure render wrapper; error/required state passed as attrs from form changeset in parent |
| `<.notebook>` tab switching | API / Backend (LiveView process) | — | `selected_tab` assign owned by parent LiveView; `on_tab_change` event name threaded to component |
| `<.skeleton>` loading state | Frontend Server (SSR) | API / Backend (assign_async) | `if/else` on loading assign in parent template; skeleton is a pure HEEx component |
| `<.toast>` display | API / Backend (LiveView process) | Browser (JS.hide auto-dismiss) | `@toasts` list assign lives in socket; `put_toast/2` mutates it in action handlers |
| `flash_group` semantic fix | Frontend Server (SSR) | — | CSS class replacement in component function; no state change |
| DS-06 drift guard | CI / Test (ExUnit) | — | File scanner runs at `mix test` time; reads committed baseline |

---

## Standard Stack

### Core (no new packages required)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | 1.1.30 (locked in `mix.lock`) | HEEx components, slot/attr macros, Phoenix.LiveView.JS | Already in project; ships `slot/3` with attrs, JS.hide/show/transition |
| `phoenix` | ~> 1.7 | LiveView integration, `put_flash/3` pattern | Already in project |
| `phoenix_html` | ~> 4.1 | HEEx rendering | Already in project |

[VERIFIED: mix.lock] — `phoenix_live_view 1.1.30` confirmed in project lockfile.

### No New Packages

This phase installs zero external packages. All implementation uses existing project dependencies.

**Installation:**
```bash
# No new packages — mix deps.get not required for this phase
```

---

## Package Legitimacy Audit

> No external packages are installed in this phase. Audit section not applicable.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Parent LiveView (assigns: sort_by, density, show_drawer, @toasts, @flash)
          |
          | import ScoriaWeb.UI
          |
          v
   ScoriaWeb.UI (lib/scoria_web/ui.ex)
   ┌─────────────────────────────────────────────────────────────┐
   │  <.table rows sort_by sort_dir density id>                  │
   │    <:col label key>  <:filter>  <:action>  <:empty>         │
   │  emits: phx-click="sort", phx-click="set_density"          │
   │                                                             │
   │  <.drawer id show on_dismiss title>                         │
   │    <:eyebrow>  <:title>  <:actions>  <:inner_block>         │
   │  emits: phx-click={@on_dismiss} (scrim + close button)     │
   │                                                             │
   │  <.modal id show on_dismiss title max_width>                │
   │    <:title>  <:inner_block>  <:footer>                      │
   │  emits: phx-click={@on_dismiss}                            │
   │                                                             │
   │  <.field id label help error required>                      │
   │    <:inner_block> (caller provides <input>)                 │
   │  <.form_section title description>                          │
   │                                                             │
   │  <.notebook id title eyebrow empty selected_tab             │
   │             on_tab_change>                                  │
   │    <:tab key label>  <:empty>                               │
   │  emits: phx-click={@on_tab_change} phx-value-tab={key}    │
   │                                                             │
   │  <.skeleton class rows> (aria-label="Loading…")            │
   │                                                             │
   │  <.toast id tone message duration_ms>                       │
   │  phx-mounted={JS.hide(transition: ..., time: duration_ms)} │
   │                                                             │
   │  flash_group/1 → scoria-flash--{fail/info/warn/pass}       │
   └─────────────────────────────────────────────────────────────┘
          |
          v
   assets/css/04-components.css
   (existing: .scoria-table, .scoria-modal__panel, .scoria-drawer,
    .scoria-scrim, .scoria-input, .scoria-button*)
   (net-new: .scoria-flash*, .scoria-skeleton*, .scoria-toast*,
    .scoria-notebook*, .scoria-table--compact, .scoria-table--comfortable)
          |
          v
   assets/css/05-motion.css
   (existing: scoria-fade, scoria-pop, scoria-slide keyframes)
```

### Recommended Project Structure

```
lib/scoria_web/
├── ui.ex                          # All 8 new components added here
│                                   # (same file as existing badge/button/panel/etc.)
assets/css/
├── 04-components.css              # Add .scoria-flash*, .scoria-skeleton*,
│                                   # .scoria-toast*, .scoria-notebook*,
│                                   # .scoria-table--compact/--comfortable
test/scoria_web/
├── ds06_drift_guard_test.exs      # New: DS-06 ratchet baseline guard
├── ui_component_test.exs          # New: render_component unit tests for all 8 components
├── live/
│   └── (one existing live test for toast real-path assertion)
test/support/
└── ds06_baseline.txt              # New: path:count pairs, committed
```

### Pattern 1: Named Slot with Typed Attrs (table columns)

**What:** A `slot/3` declaration with a `do` block containing `attr/3` macros declares per-slot attributes. The list of slots is accessible as `@col` in the template; each slot map has the declared attr fields.

**When to use:** Any component that renders a variable set of columns/tabs/panels with metadata per slot.

```elixir
# Source: Phoenix.LiveView.JS deps source (phoenix_component.ex line 422)
slot :col, doc: "Table column" do
  attr :label, :string, required: true
  attr :key, :atom, default: nil       # nil = not sortable
  attr :class, :string, default: nil
end

slot :empty
slot :action
slot :filter

attr :rows, :list, required: true
attr :sort_by, :any, default: nil
attr :sort_dir, :atom, default: :asc, values: [:asc, :desc]
attr :density, :atom, default: :default, values: [:compact, :default, :comfortable]
attr :id, :string, required: true

def table(assigns) do
  ~H"""
  <div class={["scoria-table", density_class(@density)]}>
    <!-- filter region, columns, rows, pagination -->
    <thead>
      <tr>
        <th :for={col <- @col}
            class={["scoria-table__th", col.class]}
            phx-click={col.key && "sort"}
            phx-value-by={col.key}>
          {col.label}
          <!-- sort indicator SVG when @sort_by == col.key -->
        </th>
      </tr>
    </thead>
    <tbody>
      <tr :for={row <- @rows}>
        <td :for={col <- @col}>{render_slot(col, row)}</td>
      </tr>
    </tbody>
  </div>
  """
end
```

### Pattern 2: Conditional Show via Server Assign (drawer/modal)

**What:** Parent LiveView controls `show` assign; component conditionally renders with `:if`. No `JS.show` needed for open — LiveView diff applies the change.

**When to use:** Overlay components where the open state is fully server-owned.

```elixir
# Source: codebase (approvals_live/index.ex modal pattern, lines 113–150)
# Confirmed pattern: show={@active_approval != nil} + on_dismiss="dismiss_approval"
attr :show, :boolean, required: true
attr :on_dismiss, :string, required: true
attr :id, :string, required: true

slot :inner_block, required: true
slot :footer

def modal(assigns) do
  ~H"""
  <div :if={@show} id={@id} class="scoria-modal"
       phx-window-keydown={@on_dismiss} phx-key="Escape">
    <div class="scoria-scrim"
         phx-click={@on_dismiss}
         aria-hidden="true" />
    <div class="scoria-modal__panel" role="dialog" aria-modal="true">
      <div class="scoria-modal__header">
        <button phx-click={@on_dismiss} class="scoria-button scoria-button--ghost scoria-button--sm"
                aria-label="Close dialog" title="Close dialog">
          <!-- X icon SVG 16x16 -->
        </button>
      </div>
      {render_slot(@inner_block)}
      <div :if={@footer != []} class="scoria-modal__footer">{render_slot(@footer)}</div>
    </div>
  </div>
  """
end
```

### Pattern 3: Server-Held Toast List + `put_toast/2`

**What:** `@toasts` is a list of map assigns managed by `put_toast/2` helper (modelled on `put_flash/3`). Auto-dismiss uses `phx-mounted={JS.hide(..., time: duration_ms)}`. The parent LiveView adds a `@toasts` assign at mount and calls `put_toast/2` in action handlers.

**When to use:** Transient success/error notifications that must be testable in LiveViewTest without hooks.

```elixir
# Source: CONTEXT.md D-10, D-11 — server-assign pattern
# put_flash/3 reference pattern confirmed in approvals_live/index.ex line 192

defp put_toast(socket, opts) do
  toast = %{
    id: "toast-#{System.unique_integer([:positive])}",
    tone: Keyword.get(opts, :tone, :neutral),
    message: Keyword.fetch!(opts, :message),
    duration_ms: Keyword.get(opts, :duration_ms, 4000)
  }
  update(socket, :toasts, fn toasts -> [toast | toasts] end)
end

# In mount/3:
|> assign(:toasts, [])

# In template (layout mount point):
<div id="toast-region" class="scoria-toast-region">
  <.toast :for={t <- @toasts}
    id={t.id} tone={t.tone} message={t.message} duration_ms={t.duration_ms} />
</div>
```

```elixir
# <.toast> component with phx-mounted auto-dismiss
attr :id, :string, required: true
attr :tone, :atom, default: :neutral
attr :message, :string, required: true
attr :duration_ms, :integer, default: 4000

def toast(assigns) do
  ~H"""
  <div
    id={@id}
    class={["scoria-toast", "scoria-toast--#{@tone}"]}
    role="status"
    phx-mounted={JS.hide(to: "##{@id}", transition: {"scoria-fade", "opacity-100", "opacity-0"}, time: @duration_ms)}
  >
    {tone_icon(@tone)}
    <p>{@message}</p>
    <button phx-click={JS.hide(to: "##{@id}", transition: {"scoria-fade", "opacity-100", "opacity-0"}, time: 100)}
            class="scoria-button scoria-button--ghost scoria-button--sm"
            aria-label="Dismiss">
      <!-- X icon -->
    </button>
  </div>
  """
end
```

### Pattern 4: DS-06 Ratchet Baseline Guard

**What:** ExUnit test reads baseline file, scans all `.ex`/`.heex` under `lib/scoria_web/`, compares counts. Fails on regression or new violations. Closely modelled on existing `ui_drift_guard_test.exs`.

**When to use:** Linting guard for raw-palette containment.

```elixir
# Source: codebase (test/scoria_web/ui_drift_guard_test.exs — existing file-walk pattern)
# Derived from Path.wildcard pattern used in test/support/scoria/host_install_fixtures.ex

defmodule ScoriaWeb.DS06DriftGuardTest do
  use ExUnit.Case, async: true

  @palette_regex ~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/

  # ui.ex is the gateway — must stay at zero; excluded from baseline
  @excluded ~w(lib/scoria_web/ui.ex)

  test "raw palette count never regresses (DS-06 ratchet)" do
    baseline = load_baseline()

    violations =
      for path <- Path.wildcard("lib/scoria_web/**/*.{ex,heex}"),
          path not in @excluded do
        count =
          path
          |> File.read!()
          |> then(&length(Regex.scan(@palette_regex, &1)))

        baseline_count = Map.get(baseline, path, 0)

        cond do
          count > baseline_count -> {path, count, baseline_count, :regression}
          baseline_count == 0 and count > 0 -> {path, count, 0, :new_violation}
          true -> nil
        end
      end
      |> Enum.reject(&is_nil/1)

    assert violations == [],
           format_failure(violations)
  end

  defp load_baseline do
    "test/support/ds06_baseline.txt"
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.into(%{}, fn line ->
      [path, count] = String.split(line, ":", parts: 2)
      {path, String.to_integer(count)}
    end)
  end

  defp format_failure(violations) do
    lines =
      Enum.map(violations, fn {path, count, baseline, reason} ->
        "  #{path}: found #{count}, baseline #{baseline} (#{reason})"
      end)

    """
    DS-06 drift guard failed: raw palette class found in lib/scoria_web/
    #{Enum.join(lines, "\n")}
      Fix: replace with semantic token class (see 12-UI-SPEC.md DS-05)
    """
  end
end
```

**Baseline file format (`test/support/ds06_baseline.txt`):**
```
lib/scoria_web/components/workflow_tree_component.ex:1
lib/scoria_web/components/trace_tree_component.ex:3
lib/scoria_web/components/remote_invocation_evidence_component.ex:0
lib/scoria_web/live/workflow_live/index.ex:4
...
```
(Files Phase 12 touches are zeroed and excluded, not listed in baseline.)

### Pattern 5: `render_slot/2` with row context (table body)

**What:** `render_slot(col, row)` passes a row map into the slot's `:let` binding. The caller template accesses row fields via the `:let` binding.

```elixir
# Source: Phoenix.LiveView deps (phoenix_component.ex line 445)
# Usage:
<.table rows={@records} id="incidents-table" sort_by={@sort_by} sort_dir={@sort_dir}>
  <:col :let={record} label="Status" key={:status}>
    <.badge tone={UI.tone(record.status)} label={UI.status_label(record.status)} />
  </:col>
  <:col :let={record} label="ID" key={:id}>
    <.id value={record.id} />
  </:col>
</.table>
```

### Anti-Patterns to Avoid

- **Putting `show` state in the component:** Drawer/modal `show` must live in the parent LiveView assign. The component is a pure render function.
- **Using `JS.show` for open animation:** Open is controlled by the `:if` conditional on the server diff — no `JS.show` needed. Only dismiss uses `JS.hide` (optional fade-out).
- **`push_event` + JS hook for toast:** Hooks are no-ops in LiveViewTest. Use `@toasts` assign list instead (D-10).
- **Hardcoding `duration_ms` as a CSS animation directly:** `phx-mounted={JS.hide(... time: duration_ms)}` is the idiomatic pattern; it encodes the delay as a serialized JS command in the markup, visible to LiveViewTest assertions.
- **Using `use Phoenix.LiveComponent` for new UI components:** All new components in `ui.ex` use `use Phoenix.Component` (stateless function components), not LiveComponents. Only `TraceTreeComponent` uses LiveComponent (it has `assign_async` state) — that is an existing exception, not a model.
- **Importing `Phoenix.LiveView.JS` without aliasing:** In `ui.ex` which uses `use Phoenix.Component`, add `alias Phoenix.LiveView.JS` at the top of the module to use `JS.hide/show` in component bodies.
- **Flash toggle: returning `scoria-flash--neutral` for unknown kind:** The `_kind` fallback should map to `scoria-flash--warn` (UI-SPEC DS-05 specifies warning/default → warn).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Slot declarations with typed attrs | Custom validation structs | `slot/3` macro with `do` block + `attr/3` | LV 1.1.30 ships this; compile-time validation |
| Auto-dismiss timer | `setTimeout` in custom JS hook | `phx-mounted={JS.hide(... time: N)}` | Hooks are no-ops in LiveViewTest (D-11) |
| Keyboard dismiss on overlay | Custom keydown hook | `phx-window-keydown={@on_dismiss} phx-key="Escape"` | LV native binding; works in LiveViewTest assertions |
| DOM class toggling for active tab | JS toggle hook | Server assign `selected_tab` + `:if`/`class` conditionals | Server-owned state; no hook required |
| File walking in ExUnit | Custom `Mix.Project` introspection | `Path.wildcard("lib/scoria_web/**/*.{ex,heex}")` | Proven pattern in `ui_drift_guard_test.exs` |
| Raw palette regex | String.contains? per-prefix checks | `Regex.scan(@palette_regex, source)` where regex is `~r/\b(stone|...)-\d/` | Single pass; handles word boundary correctly |
| `<.skeleton>` animation | CSS `@keyframes` in HEEx component body | Add `scoria-skeleton-pulse` keyframe to `05-motion.css`, apply via `.scoria-skeleton` CSS class | Keeps HEEx clean; honors `prefers-reduced-motion` via unlayered media query |

**Key insight:** Phoenix LiveView 1.1.30's native primitives — `slot/3` with attrs, `render_slot/2` with row context, `phx-window-keydown`, and `Phoenix.LiveView.JS` — cover every interaction pattern in this phase without custom JavaScript hooks.

---

## CSS Classes: Existing vs. Net-New

### Already in `assets/css/04-components.css` (VERIFIED by reading the file)

| Class | Status | Notes |
|-------|--------|-------|
| `.scoria-table` | EXISTS | `font-size: var(--scoria-fs-body)` |
| `.scoria-table thead th` | EXISTS | sticky, label-size, uppercase |
| `.scoria-table tbody td` | EXISTS | padding `--scoria-space-3` (12px default) |
| `.scoria-table tbody tr:hover` | EXISTS | neutral-bg hover |
| `.scoria-scrim` | EXISTS | fixed, full overlay |
| `.scoria-modal` | EXISTS | fixed grid, place-items: center |
| `.scoria-modal__panel` | EXISTS | `width: min(560px, 100%)`, pop animation |
| `.scoria-drawer` | EXISTS | slide animation |
| `.scoria-button`, `.scoria-button--primary`, `.scoria-button--ghost`, `.scoria-button--danger`, `.scoria-button--sm` | EXISTS | All variants present |
| `.scoria-badge`, `.scoria-badge--{tone}` | EXISTS | All 7 tones present |
| `.scoria-empty`, `.scoria-empty__title` | EXISTS | Dashed border, centered |
| `.scoria-row-selected` | EXISTS | `background: var(--scoria-tone-brand-bg)` |

### Must Add to `assets/css/04-components.css` (net-new)

| Class | Component | CSS Specification |
|-------|-----------|-------------------|
| `.scoria-table--compact` | `<.table>` | `tbody td { padding: var(--scoria-space-2) }` |
| `.scoria-table--comfortable` | `<.table>` | `tbody td { padding: var(--scoria-space-4) }` |
| `.scoria-modal__header` | `<.modal>` | flex, justify-between, close button alignment |
| `.scoria-modal__footer` | `<.modal>` | `flex justify-end gap-2` |
| `.scoria-drawer__header` | `<.drawer>` | eyebrow + title + close button |
| `.scoria-field` | `<.field>` | stack: label → input slot → error/help |
| `.scoria-field__label` | `<.field>` | `font-size: var(--scoria-fs-label); font-weight: 600` |
| `.scoria-field__error` | `<.field>` | `color: var(--scoria-danger-action); font-size: var(--scoria-fs-label)` |
| `.scoria-field__help` | `<.field>` | `color: var(--scoria-text-subtle); font-size: var(--scoria-fs-label)` |
| `.scoria-form-section` | `<.form_section>` | section heading + description + field stack |
| `.scoria-notebook` | `<.notebook>` | border, radius-lg, surface-panel bg |
| `.scoria-notebook__tabbar` | `<.notebook>` | `nav role="tablist"`, border-bottom |
| `.scoria-notebook__tab` | `<.notebook>` | `button role="tab"`, active: action-border-bottom |
| `.scoria-notebook__panel` | `<.notebook>` | `role="tabpanel"`, surface-panel-raised, space-4 padding |
| `.scoria-flash` | `flash_group` | base: neutral-bg/border, border-radius-md, body-font |
| `.scoria-flash--fail` | `flash_group` | fail tone tokens |
| `.scoria-flash--info` | `flash_group` | info tone tokens |
| `.scoria-flash--warn` | `flash_group` | warn tone tokens |
| `.scoria-flash--pass` | `flash_group` | pass tone tokens |
| `.scoria-skeleton` | `<.skeleton>` | neutral-bg, radius-sm, skeleton-pulse animation |
| `.scoria-skeleton--text` | `<.skeleton>` | `height: 1em` |
| `.scoria-toast` | `<.toast>` | fixed bottom-right, z-toast (60), shadow-raised |
| `.scoria-toast--{tone}` | `<.toast>` | tone token variants (pass/fail/warn/info/neutral) |
| `.scoria-toast-region` | Layout | fixed stacking container for toast list |

### Must Add to `assets/css/05-motion.css`

| Keyframe | Required By | Notes |
|----------|-------------|-------|
| `@keyframes scoria-skeleton-pulse` | `.scoria-skeleton` | `opacity: 0.4 → 0.8 → 0.4`, 1.5s infinite, ease-in-out |

The unlayered `prefers-reduced-motion` block in `05-motion.css` already collapses all `.scoria-root` animations — skeleton pulse is automatically covered. [VERIFIED: reading `05-motion.css`]

---

## DS-06 Baseline Seed (Phase 12 scope)

Raw palette counts confirmed by running grep in the working directory:

| File | Count | Phase 12 Action |
|------|-------|-----------------|
| `lib/scoria_web/ui.ex` | 3 | **Zero out** (D-03); exclude from baseline entirely |
| `lib/scoria_web/components/remote_invocation_evidence_component.ex` | 8 | **Zero out** (proof-of-API notebook adapter, D-07); exclude from baseline |
| All other 21 files | 487 total | **Seed into baseline** unchanged |

Files Phase 12 zeroes and excludes from baseline (minimum):
- `lib/scoria_web/ui.ex` (3 raw palette; zeroed by D-03 / D-13)
- `lib/scoria_web/components/remote_invocation_evidence_component.ex` (8; zeroed by proof-of-API conversion, D-07)

Files Phase 12 may additionally touch (wiring real toast + skeleton, D-12):
- `lib/scoria_web/live/approvals_live/index.ex` (7) — if toast is wired here, zero it and exclude
- `lib/scoria_web/live/workflow_live/show.ex` (45) — if skeleton is wired here, **only zero lines touched**, not the whole file. If the count drops partially, update baseline entry rather than excluding.

**Planner guidance:** The two required wiring targets (D-12) should be selected to minimize collateral zeroing. The approvals live view (7 occurrences) or orchestrator live (30) are natural toast wiring points since they already call `put_flash`. The `workflow_live/show.ex` already uses `assign_async` + `<.async_result>` for memories — the `<:loading>` slot is the natural skeleton insertion point, already containing bespoke loading markup.

---

## Common Pitfalls

### Pitfall 1: `phx-window-keydown` fires globally, not scoped to overlay

**What goes wrong:** Pressing Escape dismisses the drawer/modal even when a different overlay or form is focused.
**Why it happens:** `phx-window-keydown` is document-level. If drawer + modal are rendered simultaneously, both fire.
**How to avoid:** Apply only to the topmost overlay element; use `:if={@show}` so the binding is absent when hidden.
**Warning signs:** Escape dismisses things unexpectedly in test assertions.

### Pitfall 2: `render_slot/2` with row context returns `nil` for optional slots

**What goes wrong:** `render_slot(@empty, row)` when no `<:empty>` slot is provided returns `nil`; template crashes if rendered unconditionally.
**Why it happens:** Optional slots are `[]` by default; calling `render_slot(@empty)` when `@empty == []` returns `nil`.
**How to avoid:** Guard with `:if={@empty != []}` or `render_slot(@empty) || default_content`.
**Warning signs:** `nil` rendered inline, or "cannot render nil" compile error.

### Pitfall 3: `JS.hide` with `to:` selector is evaluated client-side

**What goes wrong:** Using `phx-mounted={JS.hide(to: "##{@id}", time: @duration_ms)}` — the `to:` value is rendered into the HTML attribute. If `@id` is dynamic, it renders correctly. But if the element ID mismatches, the JS command silently no-ops client-side.
**Why it happens:** `JS.hide` opts are serialized into the HTML at render time; no Elixir error if selector is wrong.
**How to avoid:** Omit `to:` when hiding the element the attribute is on (JS.hide defaults to `self`). Use `phx-mounted={JS.hide(transition: ..., time: @duration_ms)}` without `to:`.
**Warning signs:** Toast appears and never disappears; LiveViewTest assertion passes but browser behavior differs.

### Pitfall 4: Baseline file path is relative; `Path.wildcard` requires correct cwd

**What goes wrong:** `Path.wildcard("lib/scoria_web/**/*.{ex,heex}")` works when `mix test` runs from project root, but can fail if CWD is different.
**Why it happens:** `mix test` always runs from project root, so this is safe for CI and local dev. Fails only in exotic test runner configs.
**How to avoid:** No action needed — confirmed safe from existing `ui_drift_guard_test.exs` which uses the same relative-path pattern in production.
**Warning signs:** Zero matches from `Path.wildcard` in test output.

### Pitfall 5: `slot :col` attr names shadow the slot map key iteration

**What goes wrong:** In the table template, `col <- @col` binds the loop variable to `col`; if a slot attr is also named `col` it creates confusion. The slot map always has the declared attr name as a key.
**Why it happens:** The slot list `@col` is a list of maps, each with keys matching the declared attrs (`:label`, `:key`, `:class`) plus `:inner_block`.
**How to avoid:** Use descriptive loop variable names: `:for={column <- @col}` and access `column.label`, `column.key`.
**Warning signs:** `column.label` is nil despite being set; accidentally using `col.col` instead of `col.label`.

### Pitfall 6: `flash_tone_class/1` matched on `:error` atom but flash map uses string keys

**What goes wrong:** `@flash` from Phoenix is a `%{"error" => "message"}` map with string keys; the `for` loop in `flash_group` passes `kind` as a string. The existing `flash_tone_class(:error)` clause uses an atom — it currently only matches the atom `:error`, not the string `"error"`.
**Why it happens:** The current code has a latent bug: `:error` never matches because the loop yields string keys. All flashes fall through to the `_kind` default.
**How to avoid:** When replacing `flash_tone_class/1`, implement the replacement as a private function with string pattern matching: `defp flash_modifier("error"), do: "scoria-flash--fail"` etc. Confirm the loop yields strings before assuming atoms.
**Warning signs:** All flashes render with the same neutral style regardless of kind.

---

## Code Examples

### Verified slot-with-attrs pattern

```elixir
# Source: Phoenix.Component deps (phoenix_component.ex line 422–451)
# Confirmed in Phoenix LiveView 1.1.30 locked in mix.lock

slot :col, doc: "Table column" do
  attr :label, :string, required: true
  attr :key, :atom, default: nil
end

def table(assigns) do
  ~H"""
  <table>
    <tr>
      <th :for={col <- @col}>{col.label}</th>
    </tr>
    <tr :for={row <- @rows}>
      <td :for={col <- @col}>{render_slot(col, row)}</td>
    </tr>
  </table>
  """
end
```

### Verified `Path.wildcard` + `Regex.scan` drift guard pattern

```elixir
# Source: codebase (test/scoria_web/ui_drift_guard_test.exs — proven in production)
offenders =
  "lib/scoria_web/**/*.ex"
  |> Path.wildcard()
  |> Enum.flat_map(fn path ->
    source = File.read!(path)
    Regex.scan(~r/pattern/, source)
    |> Enum.map(fn _ -> path end)
  end)
```

### Verified `assign_async` + `<.async_result>` loading state

```elixir
# Source: codebase (workflow_live/show.ex lines 30, 210–222)
# This is the real wiring point for D-12 skeleton insertion

# In mount:
|> assign_async(:compacted_memories, fn ->
  {:ok, %{compacted_memories: Runtime.list_compacted_memories_for_run(run_id)}}
end)

# In template (before Phase 12 — bespoke loading markup):
<.async_result :let={memories} assign={@compacted_memories}>
  <:loading>
    <div class="mt-6 flex items-center justify-center rounded-2xl border border-stone-200 bg-white p-8 shadow-sm">
      <p class="text-sm text-stone-500">Loading compacted memories...</p>
    </div>
  </:loading>
  ...
</.async_result>

# After Phase 12 — replace bespoke loading with <.skeleton>:
<.async_result :let={memories} assign={@compacted_memories}>
  <:loading><.skeleton rows={3} class="mt-6" /></:loading>
  ...
</.async_result>
```

### Verified `put_flash/3` pattern (reference for `put_toast/2` modelling)

```elixir
# Source: codebase (approvals_live/index.ex line 192)
put_flash(socket, :error, approval_error_message(status, reason))
# put_toast/2 mirrors this exactly, updating @toasts list instead of @flash map
```

---

## Runtime State Inventory

> This is a code-only phase (no rename/refactor/migration). Omit.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / mix | All compilation and test | ✓ | (project already running) | — |
| `phoenix_live_view` | All components | ✓ | 1.1.30 | — |
| `floki` | LiveViewTest HTML parsing in tests | ✓ | ">= 0.30.0" in mix.exs | — |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** none

---

## Validation Architecture

> `workflow.nyquist_validation` key is absent from `.planning/config.json` — treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir) |
| Config file | `test/test_helper.exs` (existing; no new config needed) |
| Quick run command | `mix test test/scoria_web/` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DS-01 | `<.table>` renders column headers, rows, empty state | unit (`render_component`) | `mix test test/scoria_web/ui_component_test.exs` | ❌ Wave 0 |
| DS-01 | Sort indicator present when `sort_by` matches col key | unit | same | ❌ Wave 0 |
| DS-01 | Density class modifier applied to table wrapper | unit | same | ❌ Wave 0 |
| DS-02 | `<.drawer>` renders `scoria-drawer` with inner content | unit | same | ❌ Wave 0 |
| DS-02 | `<.modal>` renders dismiss button with aria-label | unit | same | ❌ Wave 0 |
| DS-02 | Drawer/modal hidden when `show={false}` | unit | same | ❌ Wave 0 |
| DS-03 | `<.field>` renders label + help text + error | unit | same | ❌ Wave 0 |
| DS-03 | Required field includes asterisk and visually-hidden span | unit | same | ❌ Wave 0 |
| DS-04 | `<.notebook>` renders tab bar with active tab indicator | unit | same | ❌ Wave 0 |
| DS-04 | Proof-of-API notebook adapter wraps RemoteInvocationEvidenceComponent | unit | same | ❌ Wave 0 |
| DS-05 | `flash_group` renders `scoria-flash--fail` for `:error` kind | unit | same | ❌ Wave 0 |
| DS-05 | `flash_group` renders `scoria-flash--info` for `"info"` kind | unit | same | ❌ Wave 0 |
| DS-05 | `<.skeleton>` renders `scoria-skeleton` with `aria-label="Loading…"` | unit | same | ❌ Wave 0 |
| DS-05 | `<.toast>` renders `scoria-toast--pass` for tone `:pass` | unit | same | ❌ Wave 0 |
| DS-05 | Real toast wiring: action handler renders toast in view | integration | `mix test test/scoria_web/live/approvals_live_test.exs` | ✅ (add assertion) |
| DS-05 | Real skeleton wiring: async loading shows skeleton | integration | `mix test test/scoria_web/live/workflow_live_test.exs` | ✅ (add assertion) |
| DS-06 | Drift guard: baseline file loads and passes on clean codebase | unit | `mix test test/scoria_web/ds06_drift_guard_test.exs` | ❌ Wave 0 |
| DS-06 | `ui.ex` has zero raw palette occurrences | inline assertion in DS-06 guard | same | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/scoria_web/`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/scoria_web/ui_component_test.exs` — covers DS-01, DS-02, DS-03, DS-04, DS-05 via `render_component`
- [ ] `test/scoria_web/ds06_drift_guard_test.exs` — covers DS-06
- [ ] `test/support/ds06_baseline.txt` — generated by running the scanner once, committed
- [ ] Framework already installed — no install step needed

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw `flash_tone_class/1` returning Tailwind classes | Semantic BEM modifiers via `scoria-flash--{tone}` CSS classes | Phase 12 (this phase) | Removes last raw-palette usage from ui.ex |
| Bespoke `<aside>` in each component (stone-200 borders, white bg) | Shared `<.notebook>` shell with token-driven CSS | Phase 12 (this phase) | Eliminates duplicated evidence panel structure |
| Bespoke loading markup in `<:loading>` slots | `<.skeleton rows={N}>` component | Phase 12 (this phase) | Single animation token, prefers-reduced-motion handled globally |
| `push_event` + custom JS hook for notifications | Server `@toasts` assign + `phx-mounted={JS.hide(...)}` | Phase 12 (this phase) | Testable without Wallaby/browser |

**Deprecated in this phase:**
- `defp flash_tone_class/1` in `ui.ex` — replaced by CSS modifier classes in `flash_group/1`

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `@flash` map in Phoenix LiveView uses string keys (e.g. `"error"`, `"info"`), not atoms, when iterated in the `:for` comprehension | Pitfall 6 / DS-05 | The `flash_tone_class` replacement would need atom pattern matching instead — low impact, easy fix |
| A2 | `phx-window-keydown` + `phx-key` binding works correctly when applied to the scrim `div` element (not just the focused element) | Pattern 2 / DS-02 | If it only fires on the focused element, keyboard dismiss won't work without `phx-window-keydown` on the outer container — low risk since `phx-window-keydown` is documented to be window-level |
| A3 | `test/support/ds06_baseline.txt` file can safely use relative paths matching the `Path.wildcard` pattern | DS-06 / Pattern 4 | If path formats differ (e.g., with `./` prefix), baseline lookup would always return 0 — easily verified when generating the baseline |

**If this table is empty:** All claims in this research were verified or cited. The three assumptions above are low-risk implementation details the implementer should verify during Wave 0.

---

## Open Questions

1. **Which screen for the real toast wiring (D-12)?**
   - What we know: `approvals_live/index.ex` already calls `put_flash(socket, :error, ...)` in `record_approval_decision/2` (line 192) — natural insertion point. The view already has 7 raw palette occurrences to zero.
   - What's unclear: Whether wiring `@toasts` into the approvals layout mount point pulls in layout changes that are out of phase scope.
   - Recommendation: Wire `put_toast/2` as a supplement to `put_flash` in the existing `record_approval_decision/2` clause, add `@toasts` assign to `approvals_live/index.ex` mount, add toast render region in the approvals view (not the shared layout). This avoids layout changes while proving the plumbing.

2. **`<.modal>` focus trap via `autofocus`?**
   - What we know: UI-SPEC says "focus is moved to the first focusable element inside `.scoria-modal__panel` via `phx-mounted` hook or `autofocus` attribute on the close button." Hooks are no-ops in LiveViewTest.
   - What's unclear: Whether a `JS.focus/1` in `phx-mounted` is a better choice than `autofocus` HTML attribute.
   - Recommendation: Use `autofocus` attribute on the close button (pure HTML, no hook). Satisfies a11y without a JS hook. `JS.focus/1` is available but the `autofocus` attr is simpler and tests fine.

---

## Sources

### Primary (HIGH confidence)

- `deps/phoenix_live_view/lib/phoenix_component.ex` (lines 415–473, 1975–2007) — slot/3 with attrs pattern, render_slot/2 with row context
- `deps/phoenix_live_view/lib/phoenix_live_view/js.ex` — JS.hide/show signature, `to:`, `transition:`, `time:` opts
- `lib/scoria_web/ui.ex` (198 lines) — existing component patterns: slot usage, `use Phoenix.Component`, `render_slot`
- `assets/css/04-components.css` — confirmed presence/absence of CSS classes
- `assets/css/05-motion.css` — confirmed keyframe names and prefers-reduced-motion block
- `assets/css/02-tokens.css` — semantic token names, z-index values, spacing scale

### Secondary (MEDIUM confidence)

- `test/scoria_web/ui_drift_guard_test.exs` — file-walking pattern for ExUnit drift guard
- `test/scoria_web/components/memory_notebook_component_test.exs` — `render_component` unit test pattern
- `test/scoria_web/components/trace_tree_component_test.exs` — `render_component` with module reference
- `lib/scoria_web/live/approvals_live/index.ex` — `put_flash` pattern, flash rendering, reference for toast wiring
- `lib/scoria_web/live/orchestrator_live.ex` — `assign_async` + `<.async_result>` loading state pattern
- `lib/scoria_web/live/workflow_live/show.ex` — `assign_async` with `<:loading>` slot (skeleton insertion point)
- `mix.lock` — confirmed `phoenix_live_view 1.1.30`

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Phoenix LiveView 1.1.30 confirmed in mix.lock; all APIs verified in deps source
- Architecture: HIGH — CSS classes verified by reading files; slot pattern verified in deps source
- Pitfalls: HIGH — Pitfall 6 (flash string/atom bug) confirmed by reading the existing code; others derived from LV docs + codebase patterns
- DS-06 baseline counts: HIGH — confirmed by running grep in working directory

**Research date:** 2026-06-04
**Valid until:** 2026-08-04 (stable LV API; CSS not changing until Phase 16)
