# Phase 12: Design-System Component Layer — Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 9 (6 modified, 3 created)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria_web/ui.ex` | component library | request-response (SSR) | `lib/scoria_web/ui.ex` (existing sections) | self-extension |
| `assets/css/04-components.css` | config/styles | transform | `assets/css/04-components.css` (existing `.scoria-badge--*`) | self-extension |
| `assets/css/05-motion.css` | config/styles | transform | `assets/css/05-motion.css` (existing `scoria-approval-pulse` keyframe) | self-extension |
| `lib/scoria_web/live/approvals_live/index.ex` | controller (LiveView) | request-response | `lib/scoria_web/live/approvals_live/index.ex` (existing `put_flash` + `flash_group`) | self-extension |
| `lib/scoria_web/live/workflow_live/show.ex` | controller (LiveView) | request-response + async | `lib/scoria_web/live/workflow_live/show.ex` (existing `assign_async` + `<.async_result>`) | self-extension |
| `lib/scoria_web/components/remote_invocation_evidence_component.ex` | component | request-response | `lib/scoria_web/components/remote_invocation_evidence_component.ex` (existing shell) | self-extension |
| `test/scoria_web/ui_component_test.exs` | test | request-response | `test/scoria_web/components/memory_notebook_component_test.exs` | exact |
| `test/scoria_web/ds06_drift_guard_test.exs` | test (lint guard) | batch (file-walk) | `test/scoria_web/ui_drift_guard_test.exs` | exact |
| `test/support/ds06_baseline.txt` | config (data file) | — | generated artifact; no code analog | n/a |

---

## Pattern Assignments

### `lib/scoria_web/ui.ex` — add 8 new components + fix `flash_group`

**Analog:** Self — extend existing file at `/Users/jon/projects/scoria/lib/scoria_web/ui.ex`

---

#### Module header pattern (lines 1–13): copy `use` + module structure

```elixir
defmodule ScoriaWeb.UI do
  use Phoenix.Component
  # ADD: alias Phoenix.LiveView.JS   ← required for JS.hide in new components
```

The `alias Phoenix.LiveView.JS` must be added immediately after `use Phoenix.Component`. It is absent in the current file because existing components do not call `JS.*`. All new overlay/toast components do.

---

#### `attr` + `slot` + `render_slot` pattern (lines 59–131): copy from `badge`, `button`, `panel`

**`badge/1` pattern (lines 59–73) — simplest `attr` + `slot` + conditional class list:**

```elixir
attr(:tone, :atom, default: :neutral)
attr(:label, :string, default: nil)
attr(:dot, :boolean, default: true)
attr(:class, :string, default: nil)
attr(:rest, :global)
slot(:inner_block)

def badge(assigns) do
  ~H"""
  <span class={["scoria-badge", "scoria-badge--#{@tone}", not @dot && "scoria-badge--bare", @class]} {@rest}>
    {@label}{render_slot(@inner_block)}
  </span>
  """
end
```

Copy this `class={[...]}` list pattern for every new component class assembly (`scoria-toast--#{@tone}`, `scoria-table--#{density_class(@density)}`, etc.).

---

#### Named multi-slot pattern (lines 110–132): copy from `panel/1`

**`panel/1` (lines 110–132) — named optional slots + `:if` guard on slot presence:**

```elixir
attr(:variant, :atom, default: :flat, values: [:flat, :raised])
attr(:class, :string, default: nil)
attr(:rest, :global)
slot(:eyebrow)
slot(:title)
slot(:actions)
slot(:inner_block, required: true)

def panel(assigns) do
  ~H"""
  <section class={["scoria-panel", @variant == :raised && "scoria-panel--raised", @class]} {@rest}>
    <div :if={@eyebrow != [] or @title != [] or @actions != []} class="scoria-panel__header">
      <div>
        <p :if={@eyebrow != []} class="scoria-eyebrow">{render_slot(@eyebrow)}</p>
        <h2 :if={@title != []}>{render_slot(@title)}</h2>
      </div>
      <div :if={@actions != []} class="flex items-center gap-2">{render_slot(@actions)}</div>
    </div>
    {render_slot(@inner_block)}
  </section>
  """
end
```

Copy the `slot(:eyebrow)` + `slot(:title)` + `slot(:actions)` + `<div :if={@slot != []}>` guard pattern verbatim for `<.drawer>` and `<.modal>`.

---

#### `flash_group` fix — the function to rewrite (lines 183–197)

**Current broken implementation to replace (lines 183–197):**

```elixir
# CURRENT — raw palette, string-key bug on flash_tone_class
attr(:flash, :map, default: %{})

def flash_group(assigns) do
  ~H"""
  <div
    :for={{kind, message} <- @flash}
    id={"flash-#{kind}"}
    class={["mb-4 rounded-lg border px-4 py-3 text-sm", flash_tone_class(kind)]}
  >
    {message}
  </div>
  """
end

defp flash_tone_class(:error), do: "border-rose-200 bg-rose-50 text-rose-900"
defp flash_tone_class(:info), do: "border-sky-200 bg-sky-50 text-sky-900"
defp flash_tone_class(_kind), do: "border-stone-200 bg-stone-50 text-stone-900"
```

**Required replacement — string-keyed clauses, semantic modifier classes:**

```elixir
# REPLACEMENT — semantic BEM modifiers, string keys (Phoenix @flash uses string keys)
attr(:flash, :map, default: %{})

def flash_group(assigns) do
  ~H"""
  <div
    :for={{kind, message} <- @flash}
    id={"flash-#{kind}"}
    role="alert"
    class={["scoria-flash", flash_modifier(kind)]}
  >
    {flash_icon(kind)}
    {message}
  </div>
  """
end

defp flash_modifier("error"), do: "scoria-flash--fail"
defp flash_modifier("info"), do: "scoria-flash--info"
defp flash_modifier("success"), do: "scoria-flash--pass"
defp flash_modifier(_kind), do: "scoria-flash--warn"
```

Key bug: the loop yields string keys (`"error"`, `"info"`) — the old `:error` atom clauses never matched. All replacements use string pattern matching.

---

#### `slot/3` with typed attrs — table columns and notebook tabs

This pattern is NOT yet in `ui.ex` but is confirmed in Phoenix LiveView 1.1.30. The closest in-project shape is `panel/1`'s unnamed optional slots. The new `<.table>` and `<.notebook>` require slots with declared attrs (slot-level metadata):

```elixir
# Copy this slot-with-attrs pattern for <.table> :col and <.notebook> :tab
slot :col, doc: "Table column" do
  attr :label, :string, required: true
  attr :key, :atom, default: nil        # nil = not sortable
  attr :class, :string, default: nil
end

# Iteration pattern (use descriptive loop variable to avoid shadowing):
<th :for={column <- @col}
    phx-click={column.key && "sort"}
    phx-value-by={column.key}>
  {column.label}
</th>
<tr :for={row <- @rows}>
  <td :for={column <- @col}>{render_slot(column, row)}</td>
</tr>
```

---

#### `empty_state/1` pattern (lines 164–178): copy for `<:empty>` slot guard in table

```elixir
def empty_state(assigns) do
  ~H"""
  <div class={["scoria-empty", @class]}>
    <p class="scoria-empty__title">{@title}</p>
    <div :if={@inner_block != []}>{render_slot(@inner_block)}</div>
    <div :if={@action != []} class="mt-4 flex justify-center">{render_slot(@action)}</div>
  </div>
  """
end
```

For `<.table>`, render `<.empty_state>` inside `<tbody><tr><td colspan={length(@col)}>` when `@rows == []` and `@empty == []`. When `@empty != []`, render `render_slot(@empty)` inside that same `<td>`.

---

### `assets/css/04-components.css` — add net-new classes

**Analog:** Self — extend existing file at `/Users/jon/projects/scoria/assets/css/04-components.css`

---

#### Tone modifier pattern (lines 226–232): copy for `.scoria-flash--*`, `.scoria-toast--*`

```css
/* Existing badge tone modifiers — exact pattern to copy for flash and toast */
.scoria-badge--neutral { color: var(--scoria-tone-neutral-fg); background: var(--scoria-tone-neutral-bg); border-color: var(--scoria-tone-neutral-border); }
.scoria-badge--pass    { color: var(--scoria-tone-pass-fg);    background: var(--scoria-tone-pass-bg);    border-color: var(--scoria-tone-pass-border); }
.scoria-badge--info    { color: var(--scoria-tone-info-fg);    background: var(--scoria-tone-info-bg);    border-color: var(--scoria-tone-info-border); }
.scoria-badge--warn    { color: var(--scoria-tone-warn-fg);    background: var(--scoria-tone-warn-bg);    border-color: var(--scoria-tone-warn-border); }
.scoria-badge--fail    { color: var(--scoria-tone-fail-fg);    background: var(--scoria-tone-fail-bg);    border-color: var(--scoria-tone-fail-border); }
```

Copy this exact three-property pattern (`color` / `background` / `border-color`) using the tone token triplets for each `.scoria-flash--{tone}` and `.scoria-toast--{tone}` modifier.

---

#### `.scoria-flash` base class — add after `.scoria-table` block

Exact CSS to add (from UI-SPEC DS-05):

```css
/* ---------- Flash banners ---------- */
.scoria-flash {
  border: 1px solid var(--scoria-tone-neutral-border);
  background: var(--scoria-tone-neutral-bg);
  color: var(--scoria-tone-neutral-fg);
  border-radius: var(--scoria-radius-md);
  padding: var(--scoria-space-2) var(--scoria-space-4);
  font-size: var(--scoria-fs-body);
  margin-bottom: var(--scoria-space-4);
  display: flex;
  align-items: flex-start;
  gap: var(--scoria-space-2);
}
.scoria-flash--fail { border-color: var(--scoria-tone-fail-border); background: var(--scoria-tone-fail-bg); color: var(--scoria-tone-fail-fg); }
.scoria-flash--info { border-color: var(--scoria-tone-info-border); background: var(--scoria-tone-info-bg); color: var(--scoria-tone-info-fg); }
.scoria-flash--warn { border-color: var(--scoria-tone-warn-border); background: var(--scoria-tone-warn-bg); color: var(--scoria-tone-warn-fg); }
.scoria-flash--pass { border-color: var(--scoria-tone-pass-border); background: var(--scoria-tone-pass-bg); color: var(--scoria-tone-pass-fg); }
```

---

#### `.scoria-drawer` existing (lines 319–325): add `.scoria-drawer__header` beside it

```css
/* Existing (lines 319–325) — reference for scoria-drawer */
.scoria-drawer {
  border: 1px solid var(--scoria-border);
  border-radius: var(--scoria-radius-lg);
  background: var(--scoria-surface-panel-raised);
  padding: var(--scoria-space-4);
  animation: scoria-slide var(--scoria-dur-slow) var(--scoria-ease-out);
}

/* Add immediately after: */
.scoria-drawer__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--scoria-space-3);
  margin-bottom: var(--scoria-space-4);
}
```

---

#### `.scoria-modal__panel` existing (lines 308–318): add `.scoria-modal__header` and `.scoria-modal__footer` beside it

```css
/* Existing modal__panel (lines 308–318) — reference for modal header/footer */
.scoria-modal__panel {
  background: var(--scoria-surface-panel-raised);
  border: 1px solid var(--scoria-border-strong);
  border-radius: var(--scoria-radius-lg);
  box-shadow: var(--scoria-shadow-raised);
  width: min(560px, 100%);
  max-height: 85vh;
  overflow-y: auto;
  padding: var(--scoria-space-5);
  animation: scoria-pop var(--scoria-dur-mid) var(--scoria-ease-out);
}

/* Add immediately after: */
.scoria-modal__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--scoria-space-3);
  margin-bottom: var(--scoria-space-4);
}
.scoria-modal__footer {
  display: flex;
  justify-content: flex-end;
  gap: var(--scoria-space-2);
  margin-top: var(--scoria-space-4);
}
```

---

#### `.scoria-table` density modifiers — add after the existing table block (lines 271–290)

```css
/* Existing (lines 271–290) */
.scoria-table { font-size: var(--scoria-fs-body); }
.scoria-table thead th { ... padding: var(--scoria-space-2) var(--scoria-space-3); ... }
.scoria-table tbody td { padding: var(--scoria-space-3); ... }

/* Add immediately after existing table block: */
.scoria-table--compact tbody td  { padding: var(--scoria-space-2); }
.scoria-table--comfortable tbody td { padding: var(--scoria-space-4); }
```

---

### `assets/css/05-motion.css` — add `scoria-skeleton-pulse` keyframe

**Analog:** Self — extend `/Users/jon/projects/scoria/assets/css/05-motion.css`

**Existing `scoria-approval-pulse` keyframe (lines 19–22): exact shape to copy for skeleton pulse:**

```css
/* Existing approval pulse (lines 19–22) — copy shape, change property */
@keyframes scoria-approval-pulse {
  0%, 100% { border-color: var(--scoria-tone-warn-border); }
  50%       { border-color: var(--scoria-tone-warn-fg); }
}

/* Add inside the @layer scoria.components block, after scoria-approval-pulse: */
@keyframes scoria-skeleton-pulse {
  0%, 100% { opacity: 0.4; }
  50%       { opacity: 0.8; }
}
```

Note: the `prefers-reduced-motion` block at lines 37–46 is unlayered and already covers all `.scoria-root *` animations — no new media query needed. The skeleton pulse animation is automatically suppressed.

---

### `lib/scoria_web/live/approvals_live/index.ex` — add `@toasts` + `put_toast/2`

**Analog:** Self — extend `/Users/jon/projects/scoria/lib/scoria_web/live/approvals_live/index.ex`

---

#### `put_flash` pattern (lines 177–194): model for `put_toast/2`

```elixir
# Existing put_flash call (line 192) — the model for put_toast
{:error, reason} ->
  put_flash(socket, :error, approval_error_message(status, reason))
```

`put_toast/2` replaces this call in the error branch AND is added to the success branch of `record_approval_decision/2`. Mirror the structure:

```elixir
# ADD to mount/3 (alongside existing assigns):
|> assign(:toasts, [])

# ADD private helper (end of file, before closing `end`):
defp put_toast(socket, opts) do
  toast = %{
    id: "toast-#{System.unique_integer([:positive])}",
    tone: Keyword.get(opts, :tone, :neutral),
    message: Keyword.fetch!(opts, :message),
    duration_ms: Keyword.get(opts, :duration_ms, 4000)
  }
  update(socket, :toasts, fn toasts -> [toast | toasts] end)
end
```

---

#### `import` line (line 9): add `toast/1` to import

```elixir
# Existing (line 9):
import ScoriaWeb.UI, only: [flash_group: 1]

# Replace with:
import ScoriaWeb.UI, only: [flash_group: 1, toast: 1]
```

---

#### Modal pattern in `render/1` (lines 112–150): model for toast render region

```elixir
# Existing inline modal render (lines 112–150) — shows the pattern for
# a conditional render block driven by a socket assign.
# The toast region follows the same principle but iterates @toasts:

# ADD inside render/1, after <.flash_group flash={@flash} />:
<div id="toast-region" class="scoria-toast-region">
  <.toast :for={t <- @toasts}
    id={t.id} tone={t.tone} message={t.message} duration_ms={t.duration_ms} />
</div>
```

---

### `lib/scoria_web/live/workflow_live/show.ex` — replace bespoke `<:loading>` with `<.skeleton>`

**Analog:** Self — extend `/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex`

---

#### `assign_async` + `<.async_result>` + `<:loading>` pattern (lines 30–32, 210–222)

```elixir
# Existing assign_async in mount/3 (lines 30–32):
|> assign_async(:compacted_memories, fn ->
  {:ok, %{compacted_memories: Runtime.list_compacted_memories_for_run(run_id)}}
end)

# Existing <.async_result> with bespoke <:loading> content (lines 210–222):
<.async_result :let={memories} assign={@compacted_memories}>
  <:loading>
    <div class="mt-6 flex items-center justify-center rounded-2xl border border-stone-200 bg-white p-8 shadow-sm">
      <p class="text-sm text-stone-500">Loading compacted memories...</p>
    </div>
  </:loading>
  <:failed :let={_failure}>
    <div class="mt-6 flex items-center justify-center rounded-2xl border border-red-200 bg-red-50 p-8 shadow-sm">
      <p class="text-sm text-red-600">Failed to load memories.</p>
    </div>
  </:failed>
  <MemoryNotebookComponent.render :if={memories != []} memories={memories} ... />
</.async_result>
```

**Replace only the `<:loading>` slot content (not the async structure):**

```elixir
# AFTER Phase 12 — replace bespoke <:loading> with <.skeleton>:
<.async_result :let={memories} assign={@compacted_memories}>
  <:loading><.skeleton rows={3} class="mt-6" /></:loading>
  <:failed :let={_failure}>
    <!-- keep existing failed markup or convert to scoria-flash--fail -->
  </:failed>
  <MemoryNotebookComponent.render :if={memories != []} memories={memories} ... />
</.async_result>
```

The `assign_async` call in `mount/3` is unchanged. Only the `<:loading>` inner content is swapped.

---

### `lib/scoria_web/components/remote_invocation_evidence_component.ex` — wrap in `<.notebook>`

**Analog:** Self — extend `/Users/jon/projects/scoria/lib/scoria_web/components/remote_invocation_evidence_component.ex`

---

#### Current shell pattern (lines 1–43): outer `<section>` replaced by `<.notebook>`

```elixir
# Existing file (lines 1–43):
defmodule ScoriaWeb.RemoteInvocationEvidenceComponent do
  use Phoenix.Component

  attr :evidence, :map, required: true

  def render(assigns) do
    assigns = assign(assigns, :approvals, Map.get(assigns.evidence || %{}, :approvals, []))

    ~H"""
    <section class="mt-6 rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
      <div class="flex items-center justify-between gap-3">
        <div>
          <p class="text-xs uppercase tracking-[0.24em] text-stone-500">Remote evidence notebook</p>
          <h2 class="mt-1 text-lg font-semibold text-stone-900">Remote invocation evidence</h2>
        </div>
        ...
      </div>
      <div class="mt-4 space-y-3">
        <article :for={approval <- @approvals} class="rounded-xl border border-stone-200 ...">
          ...
        </article>
      </div>
    </section>
    """
  end
```

**Required change — replace the outer `<section>` shell with `<.notebook>`, keep inner `<article>` content unchanged:**

```elixir
# AFTER Phase 12 — outer shell replaced, internals untouched:
defmodule ScoriaWeb.RemoteInvocationEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI, only: [notebook: 1]

  attr :evidence, :map, required: true
  attr :selected_tab, :string, default: "remote_invocation"
  attr :on_tab_change, :string, default: nil

  def render(assigns) do
    assigns = assign(assigns, :approvals, Map.get(assigns.evidence || %{}, :approvals, []))

    ~H"""
    <.notebook
      id="remote-invocation-notebook"
      title="Remote invocation evidence"
      eyebrow="Remote evidence notebook"
      selected_tab={@selected_tab}
      on_tab_change={@on_tab_change}
    >
      <:tab key="remote_invocation" label="Remote">
        <div class="space-y-3">
          <article
            :for={approval <- @approvals}
            class="rounded-xl border border-stone-200 bg-stone-50 px-4 py-3 text-sm text-stone-700"
          >
            <!-- existing approval rendering unchanged -->
          </article>
        </div>
      </:tab>
    </.notebook>
    """
  end
```

The raw-palette classes inside the `<article>` blocks may remain in Phase 12 (the DS-06 baseline entry for this file is zeroed out only if all 8 palette occurrences are removed). The simplest approach: zero the outer shell only (the `<section>` and header divs), which removes ~5 of 8 occurrences. The remaining `<article>` interior raw classes are minor and should be zeroed to keep this file fully excluded from the baseline.

---

### `test/scoria_web/ui_component_test.exs` (new file)

**Analog:** `test/scoria_web/components/memory_notebook_component_test.exs`

---

#### Module header + `render_component` unit test pattern (lines 1–40 of analog)

```elixir
# Analog: test/scoria_web/components/memory_notebook_component_test.exs (lines 1–40)

defmodule ScoriaWeb.MemoryNotebookComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias ScoriaWeb.MemoryNotebookComponent

  test "renders sequence ranges and summary text for a memory block" do
    memories = [...]

    html = render_component(&MemoryNotebookComponent.render/1,
      memories: memories,
      runtime_instance_id: "runtime-123"
    )

    assert html =~ "Sequences 1 - 10"
    assert html =~ "Session started and user authenticated."
  end
end
```

Copy this structure for `ui_component_test.exs`. Key differences:
- Import `ScoriaWeb.UI` functions directly (they are function components, not a module with a `.render/1` function)
- Use `render_component(&ScoriaWeb.UI.table/1, ...)` or `render_component(fn a -> ScoriaWeb.UI.table(a) end, ...)`
- The analog uses `&Module.render/1` — apply the same arity-capture form

**Test module structure to follow:**

```elixir
defmodule ScoriaWeb.UIComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  # DS-01 table tests
  test "<.table> renders column headers" do
    html = render_component(&ScoriaWeb.UI.table/1,
      id: "test-table",
      rows: [%{name: "Alice", status: "pass"}],
      sort_by: nil,
      sort_dir: :asc,
      density: :default
      # col slots cannot be passed via render_component; use Phoenix.Component.to_form or
      # wrap in a parent render function. See trace_tree_component_test.exs for module form.
    )
    assert html =~ "scoria-table"
  end
```

Note: for components with slots, the `render_component(Module, assigns)` form (module reference, not function capture) supports passing slot content. See `trace_tree_component_test.exs` line 15 for the module-reference form: `render_component(ScoriaWeb.TraceTreeComponent, assigns)`.

---

#### `render_component` with module reference (trace_tree_component_test.exs line 15)

```elixir
# Analog: test/scoria_web/components/trace_tree_component_test.exs (line 15)
html = render_component(ScoriaWeb.TraceTreeComponent, assigns)
```

Use this form (module, not `&fun/arity`) when the component has slots. For pure `attr`-only components (skeleton, toast, field), the function-capture form works fine.

---

#### Integration test assertion pattern (approvals_live_test.exs line 248)

```elixir
# Analog: test/scoria_web/live/approvals_live_test.exs (lines 231–249)
# Pattern for assert render(view) =~ string — copy for toast wiring test

test "stale approval decision surfaces friendly flash" do
  {:ok, view, _html} = live(session_conn(...), "/scoria/approvals")
  ...
  render_click(view, "approve", %{})
  assert render(view) =~ "already decided by another operator"
end
```

Copy this `render(view) =~` assertion form for the real toast wiring test. The integration test file already exists; add a new `test` block asserting `render(view) =~ "scoria-toast"` after a toast-triggering action.

---

### `test/scoria_web/ds06_drift_guard_test.exs` (new file)

**Analog:** `test/scoria_web/ui_drift_guard_test.exs` — exact match on role and data flow

---

#### File-walk + pattern-match + assert structure (lines 1–41 of analog)

```elixir
# Analog: test/scoria_web/ui_drift_guard_test.exs (lines 1–41) — FULL FILE

defmodule ScoriaWeb.UIDriftGuardTest do
  use ExUnit.Case, async: true

  @forbidden ~w(badge_class status_color trace_badge_class flash_kind_class)

  test "no re-introduced per-component status→color helpers in lib/scoria_web" do
    offenders =
      "lib/scoria_web/**/*.ex"
      |> Path.wildcard()
      |> Enum.flat_map(fn path ->
        source = File.read!(path)

        for name <- @forbidden,
            Regex.match?(~r/\bdefp?\s+#{name}\b/, source),
            do: "#{path}: defp #{name}"
      end)

    assert offenders == [],
           """
           Re-introduced per-component status→color helper(s). ...
           #{Enum.join(offenders, "\n")}
           """
  end
end
```

Copy this module structure verbatim for `ds06_drift_guard_test.exs`. Replace:
- `@forbidden` list with `@palette_regex`
- single `Regex.match?` with `Regex.scan` + count
- `assert offenders == []` with ratchet comparison against baseline

**New DS-06 guard structure:**

```elixir
defmodule ScoriaWeb.DS06DriftGuardTest do
  use ExUnit.Case, async: true

  @palette_regex ~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/

  # Files zeroed in Phase 12 are excluded from the baseline entirely
  @excluded ~w(lib/scoria_web/ui.ex
               lib/scoria_web/components/remote_invocation_evidence_component.ex)

  test "raw palette count never regresses (DS-06 ratchet)" do
    baseline = load_baseline()

    violations =
      for path <- Path.wildcard("lib/scoria_web/**/*.{ex,heex}"),
          path not in @excluded do
        count = path |> File.read!() |> then(&length(Regex.scan(@palette_regex, &1)))
        baseline_count = Map.get(baseline, path, 0)

        cond do
          count > baseline_count -> {path, count, baseline_count, :regression}
          baseline_count == 0 and count > 0 -> {path, count, 0, :new_violation}
          true -> nil
        end
      end
      |> Enum.reject(&is_nil/1)

    assert violations == [], format_failure(violations)
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
    lines = Enum.map(violations, fn {path, count, baseline, reason} ->
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

Note: use `"lib/scoria_web/**/*.{ex,heex}"` in `Path.wildcard/1` (brace expansion). The analog uses only `"lib/scoria_web/**/*.ex"` — the DS-06 guard must also cover `.heex` template files.

---

### `test/support/ds06_baseline.txt` (new file)

**Analog:** No code analog — generated data file.

**Generation procedure:** Run the scanner once against the current codebase, excluding the zeroed files, and write the output:

```bash
# In IEx / mix run — generate baseline content:
regex = ~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/
excluded = ~w(lib/scoria_web/ui.ex lib/scoria_web/components/remote_invocation_evidence_component.ex)

"lib/scoria_web/**/*.{ex,heex}"
|> Path.wildcard()
|> Enum.reject(& &1 in excluded)
|> Enum.filter(fn path ->
  count = path |> File.read!() |> then(&length(Regex.scan(regex, &1)))
  count > 0
end)
|> Enum.map(fn path ->
  count = path |> File.read!() |> then(&length(Regex.scan(regex, &1)))
  "#{path}:#{count}"
end)
|> Enum.join("\n")
```

**Format** (`path:count`, one per line, no spaces around `:`):

```
lib/scoria_web/live/review_queue_live.ex:76
lib/scoria_web/components/incident_evidence_component.ex:69
lib/scoria_web/live/dataset_live/promote_component.ex:68
lib/scoria_web/live/workflow_live/show.ex:45
...
```

Files Phase 12 also touches (toast wiring in `approvals_live/index.ex`, skeleton in `workflow_live/show.ex`) should be zeroed and excluded from the baseline rather than listed with their pre-Phase-12 counts — the baseline entry would immediately fail on commit. For `workflow_live/show.ex`, if only the `<:loading>` slot is changed and raw palette remains elsewhere in the file, update the baseline count to reflect the post-change count rather than excluding the file.

---

## Shared Patterns

### `use Phoenix.Component` (module declaration)

**Source:** `lib/scoria_web/ui.ex` line 12
**Apply to:** `lib/scoria_web/components/remote_invocation_evidence_component.ex` already uses this. All new components in `ui.ex` inherit it from the module-level `use`.

```elixir
use Phoenix.Component
# ALSO ADD (new for Phase 12):
alias Phoenix.LiveView.JS
```

---

### `attr(:rest, :global)` + `{@rest}` spread

**Source:** `lib/scoria_web/ui.ex` lines 63–64, 80–83 (badge, button)
**Apply to:** `<.table>`, `<.drawer>`, `<.modal>` — any component that wraps a single root element and should forward data attributes or `phx-*` bindings the caller adds.

```elixir
attr(:rest, :global)
# In template:
<div class={...} {@rest}>
```

---

### Optional slot guard: `:if={@slot != []}`

**Source:** `lib/scoria_web/ui.ex` lines 122–128 (`panel/1`)
**Apply to:** All new multi-slot components — drawer (`<:eyebrow>`, `<:title>`, `<:actions>`), modal (`<:footer>`), notebook (`<:empty>`), table (`<:empty>`, `<:action>`, `<:filter>`).

```elixir
<div :if={@eyebrow != [] or @title != [] or @actions != []} class="scoria-panel__header">
  <p :if={@eyebrow != []}>{render_slot(@eyebrow)}</p>
  <h2 :if={@title != []}>{render_slot(@title)}</h2>
  <div :if={@actions != []}>{render_slot(@actions)}</div>
</div>
```

---

### `phx-window-keydown` + `phx-key="Escape"` keyboard dismiss

**Source:** `lib/scoria_web/live/workflow_live/show.ex` line 239 (existing inline modal)
**Apply to:** `<.drawer>` and `<.modal>` components in `ui.ex`.

```elixir
# Existing inline modal in workflow_live/show.ex (line 239):
<div id="promote-modal" class="fixed inset-0 z-50 ..."
     phx-window-keydown="close_modal" phx-key="escape">
```

In the new function components, use `@on_dismiss` instead of a hardcoded event name:

```elixir
<div :if={@show} id={@id} class="scoria-modal"
     phx-window-keydown={@on_dismiss} phx-key="Escape">
```

Note: the existing code uses lowercase `"escape"` — use uppercase `"Escape"` (the standard DOM key value per MDN).

---

### `ExUnit.Case, async: true` + `import Phoenix.LiveViewTest` test header

**Source:** `test/scoria_web/components/memory_notebook_component_test.exs` lines 1–3; `test/scoria_web/ui_drift_guard_test.exs` lines 1–2
**Apply to:** `test/scoria_web/ui_component_test.exs`, `test/scoria_web/ds06_drift_guard_test.exs`

```elixir
defmodule ScoriaWeb.UIComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  ...
end
```

The drift guard does NOT need `import Phoenix.LiveViewTest` — it uses only `ExUnit.Case`.

---

### `Path.wildcard` file-walk pattern

**Source:** `test/scoria_web/ui_drift_guard_test.exs` lines 20–29
**Apply to:** `test/scoria_web/ds06_drift_guard_test.exs`

```elixir
"lib/scoria_web/**/*.ex"
|> Path.wildcard()
|> Enum.flat_map(fn path ->
  source = File.read!(path)
  ...
end)
```

Extend to `*.{ex,heex}` for DS-06 (the original guard only scans `.ex`).

---

### Endpoint boilerplate for integration tests

**Source:** `test/scoria_web/live/approvals_live_test.exs` lines 1–76 (Router + Endpoint + `setup_all`)
**Apply to:** Any new integration test for toast real-path wiring. The approvals test already exists; add a new `test` block inside `ScoriaWeb.ApprovalsLiveTest` rather than creating a new endpoint.

```elixir
# Existing Endpoint (lines 16–26):
defmodule ScoriaWeb.ApprovalsLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria
  plug(Plug.Session, store: :cookie, key: "_scoria_approvals_key", signing_salt: "scoria_approvals_salt")
  plug(ScoriaWeb.ApprovalsLiveTest.Router)
end

# setup_all (lines 58–67) — secret_key_base ≥ 64 chars required or 500:
Application.put_env(:scoria, ScoriaWeb.ApprovalsLiveTest.Endpoint,
  secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
  pubsub_server: Scoria.PubSub,
  live_view: [signing_salt: "112345678"],
  debug_errors: true
)
```

---

## No Analog Found

No files in Phase 12 are without some analog. The DS-06 baseline text file is a generated data artifact with no code analog, but its format is fully specified in RESEARCH.md Pattern 4.

---

## Metadata

**Analog search scope:** `lib/scoria_web/`, `test/scoria_web/`, `assets/css/`
**Files read:** 12 source files + 2 CSS files + 1 test helper
**Pattern extraction date:** 2026-06-04
