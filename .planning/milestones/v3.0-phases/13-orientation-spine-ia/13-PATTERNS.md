# Phase 13: Orientation Spine (IA) - Pattern Map

**Mapped:** 2026-06-11
**Files analyzed:** 20
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria_web/dashboard_nav.ex` | config/provider | request-response | `lib/scoria_web/dashboard_nav.ex` | exact |
| `lib/scoria_web/router.ex` | route/config | request-response | `lib/scoria_web/router.ex` | exact |
| `lib/scoria_web/live/coming_soon_live.ex` | LiveView | request-response | `lib/scoria_web/live/review_queue_live.ex` | role-match |
| `lib/scoria_web/components/layouts/app.html.heex` | layout/component | request-response + event-driven hook mount | `lib/scoria_web/components/layouts/app.html.heex` | exact |
| `lib/scoria_web/components/layouts.ex` | component/helper | transform | `lib/scoria_web/components/layouts.ex` | exact |
| `lib/scoria_web/ui.ex` | component | transform | `lib/scoria_web/ui.ex` | exact |
| `assets/css/04-components.css` | config/style | transform | `assets/css/04-components.css` | exact |
| `assets/css/05-motion.css` | config/style | event-driven UI state | `assets/css/05-motion.css` | exact |
| `assets/js/scoria.js` | hook/utility | event-driven + localStorage | `assets/js/scoria.js` | exact |
| `lib/scoria_web/live/orchestrator_live.ex` | LiveView | streaming + request-response | `lib/scoria_web/live/orchestrator_live.ex` | exact |
| `lib/scoria_web/operator_surface.ex` | service/read model | CRUD/read-only queries | `lib/scoria_web/operator_surface.ex` | exact |
| `lib/scoria_web/live/workflow_live/show.ex` | LiveView | request-response + event-driven | `lib/scoria_web/live/workflow_live/show.ex` | exact |
| `lib/scoria_web/live/review_queue_live.ex` | LiveView | CRUD + request-response | `lib/scoria_web/live/review_queue_live.ex` | exact |
| `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | LiveView | CRUD + request-response | `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | exact |
| `test/scoria_web/dashboard_nav_test.exs` | test | request-response/transform | `test/scoria_web/router_test.exs` | partial |
| `test/scoria_web/live/coming_soon_live_test.exs` | test | request-response | `test/scoria_web/live/review_queue_live_test.exs` | role-match |
| `test/scoria_web/live/orchestrator_live_test.exs` | test | streaming + request-response | `test/scoria_web/live/orchestrator_live_test.exs` | exact |
| `test/scoria_web/router_test.exs` | test | request-response | `test/scoria_web/router_test.exs` | exact |
| `test/scoria_web/ui_component_test.exs` | test | transform | `test/scoria_web/ui_component_test.exs` | exact |
| `test/scoria_web/live/workflow_live_test.exs` | test | request-response + event-driven | `test/scoria_web/live/workflow_live_test.exs` | exact |

## Pattern Assignments

### `lib/scoria_web/dashboard_nav.ex` (config/provider, request-response)

**Analog:** `lib/scoria_web/dashboard_nav.ex`

**Imports pattern** (lines 10-11):
```elixir
import Phoenix.LiveView, only: [attach_hook: 4]
import Phoenix.Component, only: [assign: 3]
```

**Nav SSOT pattern** (lines 13-31): extend this data shape with `soon?: true`, aliases, and Configure group rather than adding parallel sidebar/palette/stub maps.
```elixir
@groups [
  %{
    label: "Operate",
    items: [
      %{key: :live_ops, label: "Live Ops", path: "/", icon: :pulse},
      %{key: :approvals, label: "Approvals", path: "/approvals", icon: :inbox},
      %{key: :runs, label: "Runs", path: "/workflows", icon: :tree}
    ]
  }
]
```

**Active route map pattern** (lines 34-43): add `ScoriaWeb.WorkflowLive.Index => :runs` and the new coming-soon LiveView mapping.
```elixir
@views %{
  ScoriaWeb.OrchestratorLive => :live_ops,
  ScoriaWeb.ApprovalsLive.Index => :approvals,
  ScoriaWeb.WorkflowLive.Show => :runs,
  ScoriaWeb.ReviewQueueLive => :reviews
}
```

**Embedded mount-base pattern** (lines 56-104): update suffixes and regex for `/coming`.
```elixir
def on_mount(:default, _params, _session, socket) do
  socket =
    socket
    |> assign(:scoria_nav, active_key(socket.view))
    |> attach_hook(:scoria_base, :handle_params, &assign_base/3)

  {:cont, socket}
end

defp strip_known_prefixes(path) do
  path
  |> String.replace(
    ~r{/(workflows|prompts|reviews|eval_specs|approvals|connectors|incidents)(/.*)?$},
    ""
  )
end
```

---

### `lib/scoria_web/router.ex` and `lib/scoria_web/live/coming_soon_live.ex` (route + LiveView, request-response)

**Analog:** `lib/scoria_web/router.ex`, `lib/scoria_web/live/review_queue_live.ex`

**Dashboard route pattern** (`router.ex` lines 20-47): add `live("/coming/:screen", ScoriaWeb.ComingSoonLive, :show)` inside this `live_session`.
```elixir
live_session :scoria_dashboard,
  root_layout: {ScoriaWeb.Layouts, :root},
  on_mount: ScoriaWeb.DashboardNav do
  live("/", ScoriaWeb.OrchestratorLive, :index)
  live("/reviews", ScoriaWeb.ReviewQueueLive, :index)
  live("/workflows", ScoriaWeb.WorkflowLive.Index, :index)
end
```

**LiveView mount/render pattern** (`review_queue_live.ex` lines 6-23, 99-110): use route params, assign page title, render in dashboard layout.
```elixir
use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

def mount(params, _session, socket) do
  filters = %{"review_status" => Map.get(params, "review_status", "pending")}

  {:ok,
   socket
   |> assign(:page_title, "Review Queue")
   |> assign(:filters, filters)
   |> refresh_queue()}
end
```

**Validation pattern:** the new stub LiveView should allowlist `screen` against nav/stub metadata from `DashboardNav`; do not render arbitrary param text.

---

### `lib/scoria_web/components/layouts/app.html.heex` and `layouts.ex` (layout/component, request-response)

**Analog:** `lib/scoria_web/components/layouts/app.html.heex`, `lib/scoria_web/components/layouts.ex`

**Sidebar group rendering pattern** (`app.html.heex` lines 7-18): add Soon badge and palette data from the same `nav_groups()`.
```heex
<nav class="space-y-4" aria-label="Dashboard sections">
  <div :for={group <- nav_groups()} class="scoria-navgroup">
    <p class="scoria-navgroup__label">{group.label}</p>
    <.link
      :for={item <- group.items}
      navigate={(assigns[:scoria_base] || "") <> item.path}
      class="scoria-nav"
      aria-current={if item.key == assigns[:scoria_nav], do: "page"}
    >
      <.icon name={item.icon} />
      <span>{item.label}</span>
    </.link>
  </div>
</nav>
```

**Topbar hook mount pattern** (`app.html.heex` lines 23-40): place `Cmd+K` affordance and hook-owned dialog in this dashboard-only shell.
```heex
<header class="scoria-topbar">
  <div class="scoria-breadcrumbs">
    <span class="scoria-breadcrumbs__sep">Scoria</span>
    <span class="scoria-breadcrumbs__sep">/</span>
    <span style="color: var(--scoria-text);">{assigns[:page_title] || "Dashboard"}</span>
  </div>
  <div class="ml-auto flex items-center gap-3">
    <button type="button" phx-hook="ThemeToggle" id="scoria-theme-toggle">
      <span>Theme</span>
    </button>
  </div>
</header>
```

**Icon/helper pattern** (`layouts.ex` lines 31-65): extend only if fallback is insufficient; keep stroke icons and `nav_groups` passthrough.
```elixir
@doc "Inline stroke icons for nav items (brand book §9: stroke, rounded)."
attr(:name, :atom, required: true)
attr(:class, :string, default: "scoria-nav__icon")

def icon(assigns) do
  ~H"""
  <svg class={@class} viewBox="0 0 24 24" fill="none" stroke="currentColor" ...>
    <%= case @name do %>
      <% :pulse -> %>
        <path d="M3 12h4l2 6 4-14 2 8h6" />
      <% _ -> %>
        <circle cx="12" cy="12" r="8" />
    <% end %>
  </svg>
  """
end

def nav_groups, do: DashboardNav.groups()
```

---

### `lib/scoria_web/ui.ex` (component, transform)

**Analog:** `lib/scoria_web/ui.ex`

**Imports and token-gateway pattern** (lines 1-13):
```elixir
defmodule ScoriaWeb.UI do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
```

**Attribute + slot API pattern** (lines 60-74, 111-132): define `object_header/1`, attention cards, or stub helpers with `attr/slot`; emit semantic classes only.
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

**Copyable ID pattern** (lines 152-174): reuse inside object header for truncated IDs; pass full ID through `data-copy`/`title`.
```elixir
attr(:value, :string, required: true)
attr(:copy, :string, default: nil)
attr(:id, :string, default: nil)

def id(assigns) do
  assigns = assign_new(assigns, :id, fn ->
    "id-" <> Integer.to_string(:erlang.phash2(assigns.value))
  end)

  ~H"""
  <span class={["scoria-id", @class]} phx-hook="CopyId" id={@id} data-copy={@copy || @value} title="Click to copy">
    {@value}
  </span>
  """
end
```

**Accessible dialog precedent** (lines 206-244): palette markup should copy ARIA naming/modal conventions, though filtering remains client-side.
```elixir
<div :if={@show} id={@id} class="scoria-modal" phx-window-keydown={@on_dismiss} phx-key="Escape" {@rest}>
  <div class="scoria-scrim" phx-click={@on_dismiss} aria-hidden="true"></div>
  <div class="scoria-modal__panel" role="dialog" aria-modal="true" aria-labelledby={"#{@id}-title"}>
    ...
  </div>
</div>
```

---

### `assets/js/scoria.js` (hook/utility, event-driven + localStorage)

**Analog:** `assets/js/scoria.js`

**IIFE + hook registry pattern** (lines 1-18):
```javascript
(function () {
  "use strict";

  if (typeof window.Phoenix === "undefined" || typeof window.LiveView === "undefined") {
    console.error("[scoria] Phoenix / LiveView globals missing — dashboard JS not bundled correctly");
    return;
  }

  var Hooks = {};
```

**Copy hook pattern** (lines 19-37): object header and recent-object hooks should use stable DOM IDs and data attributes.
```javascript
Hooks.CopyId = {
  mounted: function () {
    var el = this.el;
    el.addEventListener("click", function () {
      var text = el.getAttribute("data-copy") || el.textContent.trim();
      if (!navigator.clipboard) return;
      navigator.clipboard.writeText(text).then(function () {
        el.classList.add("scoria-id--copied");
      });
    });
  },
};
```

**localStorage pattern** (lines 39-51): command recents should use the same try/catch style with key `scoria:recents:<mount-base>`.
```javascript
var stored = null;
try { stored = localStorage.getItem("scoria-theme"); } catch (e) {}
if (stored) root.setAttribute("data-theme", stored);
...
try { localStorage.setItem("scoria-theme", next); } catch (e) {}
```

**Global listener cleanup pattern** (lines 54-69): command palette, `?`, and `g` chords must bind in `mounted` and remove in `destroyed`.
```javascript
Hooks.Dismissable = {
  mounted: function () {
    var self = this;
    this.handler = function (e) {
      if (e.key === "Escape") {
        var event = self.el.getAttribute("data-scoria-dismiss");
        if (event) self.pushEvent(event, {});
      }
    };
    window.addEventListener("keydown", this.handler);
  },
  destroyed: function () {
    window.removeEventListener("keydown", this.handler);
  },
};
```

---

### `lib/scoria_web/live/orchestrator_live.ex` (LiveView, streaming + request-response)

**Analog:** `lib/scoria_web/live/orchestrator_live.ex`

**Imports/aliases pattern** (lines 1-14):
```elixir
use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}
import Ecto.Query, warn: false
import ScoriaWeb.UI, only: [badge: 1, flash_group: 1]

alias ScoriaWeb.OperatorSurface
```

**Mount + PubSub + stream pattern** (lines 20-48): keep `/` mounted here; change copy/top section only.
```elixir
def mount(params, session, socket) do
  tenant_id = params["tenant"] || session["tenant_id"] || "default"

  socket =
    socket
    |> assign(:page_title, "Live Ops")
    |> assign(:tenant_id, tenant_id)
    |> load_summary()
    |> stream(:traces, [])

  socket =
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
      hydrate_traces(socket, tenant_id)
    else
      socket
    end

  {:ok, socket}
end
```

**Async evidence pattern** (lines 89-125): use for non-blocking count/evidence work if adding review/failing-gate summaries.
```elixir
def handle_event("load_budget_state", params, socket) do
  trace_id = Map.get(params, "id")
  run_id = Map.get(params, "run_id")

  {:noreply,
   socket
   |> refresh_trace_badges(trace_id, run_id)
   |> assign_async(:budget_state, fn ->
     {:ok, %{budget_state: OperatorSurface.load_budget_projection(trace_id, run_id)}}
   end)}
end
```

**Current summary insertion point** (lines 136-206): replace task cards/ops-summary with identity line + nonzero attention strip + unchanged stream.

**Trace stream must remain** (lines 208-219):
```heex
<div id="traces-list" phx-update="stream" class="space-y-4">
  <div :for={{id, trace} <- @streams.traces} id={id} class="bg-white p-4 rounded shadow">
    <.live_component module={ScoriaWeb.TraceTreeComponent} id={"tree-#{id}"} spans={trace.spans} />
  </div>
</div>
```

---

### `lib/scoria_web/operator_surface.ex` (service/read model, CRUD/read-only queries)

**Analog:** `lib/scoria_web/operator_surface.ex`

**Read-model imports/aliases pattern** (lines 1-18):
```elixir
defmodule ScoriaWeb.OperatorSurface do
  import Ecto.Query, warn: false

  alias Scoria.Connectors
  alias Scoria.Repo
  alias Scoria.Runtime
  alias Scoria.Workflows
```

**Summary helper pattern with fallback** (lines 100-134): add only cheap read helpers; rescue to neutral/zero shapes.
```elixir
def pending_approval_count(tenant_id) do
  Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id}) |> length()
rescue
  _error -> 0
end

def incidents_summary(tenant_id) do
  incidents = list_tenant_incidents(tenant_id)

  %{
    open: Enum.count(incidents, &(&1.status == "open")),
    review: Enum.count(incidents, &(&1.routing_class == "review" and &1.status == "open")),
    page: Enum.count(incidents, &(&1.routing_class == "page" and &1.status == "open"))
  }
rescue
  _error -> %{open: 0, review: 0, page: 0}
end
```

**Query pattern** (lines 280-337): compose Ecto queries in helpers and order deterministically.
```elixir
def latest_budget(trace_id, run_id) do
  BudgetReservation
  |> where(^evidence_filter(trace_id, run_id))
  |> order_by([reservation], desc: reservation.inserted_at)
  |> limit(1)
  |> Repo.one()
end
```

---

### `lib/scoria_web/live/workflow_live/show.ex` (LiveView, request-response + event-driven)

**Analog:** `lib/scoria_web/live/workflow_live/show.ex`

**Mount + subscribe + async pattern** (lines 20-36):
```elixir
def mount(%{"id" => run_id} = params, _session, socket) do
  review_candidate_id = Map.get(params, "review_candidate_id")

  if connected?(socket), do: Workflows.subscribe_run(run_id)

  socket =
    socket
    |> load_run(run_id)
    |> assign(:review_candidate, load_review_candidate(run_id, review_candidate_id))
    |> assign_async(:compacted_memories, fn ->
      {:ok, %{compacted_memories: Runtime.list_compacted_memories_for_run(run_id)}}
    end)

  {:ok, socket}
end
```

**Current page header to replace with `object_header/1`** (lines 92-105):
```heex
<header class="mb-6 flex flex-wrap items-center justify-between gap-4">
  <div>
    <p class="text-xs uppercase tracking-[0.3em] text-stone-500">Scoria Workflow</p>
    <h1 class="text-3xl font-semibold">Workflow Run</h1>
    <p class="text-sm text-stone-600">Run <span class="font-mono"><%= @run.id %></span></p>
  </div>
  <div class="rounded-full border border-stone-200 bg-white px-4 py-2 text-sm font-semibold">
    <span class="workflow-run-status"><%= @run.status %></span>
  </div>
</header>
```

**Replay provenance pattern to generalize** (lines 107-149):
```heex
<section :if={@run.execution_mode == "replay" and map_size(@replay_provenance_strip) > 0}>
  <p class="text-xs uppercase tracking-[0.24em] text-blue-700">Replay branch</p>
  <h2 class="mt-1 text-lg font-semibold text-stone-900">Replay provenance strip</h2>
  <span>source run <span class="font-mono"><%= provenance_value(@replay_provenance_strip.source_run_id) %></span></span>
  <span>source checkpoint <span class="font-mono"><%= provenance_value(@replay_provenance_strip.source_checkpoint_id) %></span></span>
</section>
```

**Event/reload pattern** (lines 60-85, 256-278): after events, reload the run and preserve notices.
```elixir
def handle_info({:workflow_updated, run_id}, socket), do: {:noreply, load_run(socket, run_id)}

defp load_run(socket, run_id) do
  run = Workflows.get_run_tree!(run_id)
  detail = Runtime.get_run_detail!(run_id)

  socket
  |> assign(:page_title, "Workflow Run")
  |> assign(:run, run)
  |> assign(:replay_provenance_strip, detail.replay_provenance_strip)
end
```

---

### `lib/scoria_web/live/review_queue_live.ex` and `prompt_live/release_workbench_live.ex` (LiveView, CRUD + request-response)

**Analogs:** `lib/scoria_web/live/review_queue_live.ex`, `lib/scoria_web/live/prompt_live/release_workbench_live.ex`

**Review queue next-step links** (`review_queue_live.ex` lines 223-226): update these to verb language and `?from=review:<id>`.
```heex
<div class="mt-6 flex flex-wrap gap-3">
  <a href={@selected_candidate.workflow_path} class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white">Open workflow</a>
  <a href={@selected_candidate.runtime_path} class="rounded-xl border border-blue-200 px-4 py-2 text-sm font-semibold text-blue-700">View runtime context</a>
</div>
```

**Queue refresh pattern** (`review_queue_live.ex` lines 302-333):
```elixir
defp refresh_queue(socket, reset_selection \\ true) do
  rows = Eval.list_review_queue(socket.assigns.filters)
  summary = Eval.summarize_review_queue(socket.assigns.filters)
  {open_datasets, sealed_datasets} = Eval.list_datasets() |> Enum.split_with(&(&1.state == :open))

  socket
  |> assign(:queue_rows, rows)
  |> assign(:summary, summary)
  |> assign(:open_datasets, open_datasets)
  |> refresh_selection()
end
```

**Release workbench object-page pattern** (`release_workbench_live.ex` lines 12-42, 129-144): candidate for `object_header/1`.
```elixir
def mount(%{"id" => id}, session, socket) do
  actor_id = session["actor_id"] || session["operator_id"] || "operator-fallback"
  tenant_id = session["tenant_id"] || "default"
  draft = PromptRegistry.get_prompt_template!(id)

  socket =
    socket
    |> assign(:actor_id, actor_id)
    |> assign(:tenant_id, tenant_id)
    |> assign(:draft, draft)
    |> assign(:active, active)

  {:ok, socket}
end
```

**Action result handling pattern** (`release_workbench_live.ex` lines 82-108): preserve simple success/failure notices.
```elixir
case PromptRelease.approve(approval.id, "approved", %{actor_id: actor_id}) do
  {:ok, _} ->
    {:noreply, assign(socket, show_approve_modal: false, approval_notice: "Prompt Release Approved.", pending_approval: nil)}
  _ ->
    {:noreply, assign(socket, show_approve_modal: false, rejection_notice: "Failed to approve.")}
end
```

---

### CSS files (config/style, transform + event-driven UI state)

**Analogs:** `assets/css/04-components.css`, `assets/css/05-motion.css`

**Semantic component class pattern** (`04-components.css` lines 1-5, 77-112): add `.scoria-command-*`, `.scoria-object-header-*`, `.scoria-stub-*`, `.scoria-attention-*` here using tokens.
```css
/*
 * Scoria component vocabulary. Emitted by ScoriaWeb.UI function components.
 * All values come from semantic tokens — never raw hex, never a per-component color map.
 */
@layer scoria.components {
  .scoria-nav {
    display: flex;
    align-items: center;
    gap: var(--scoria-space-3);
    color: var(--scoria-text-muted);
    transition: background-color var(--scoria-dur-fast) var(--scoria-ease-out),
      color var(--scoria-dur-fast) var(--scoria-ease-out);
  }
}
```

**Motion pattern** (`05-motion.css` lines 1-18, 40-49): command palette open/close should be opacity-only, <=200ms, reduced-motion safe.
```css
@keyframes scoria-fade {
  from { opacity: 0; }
  to { opacity: 1; }
}

@media (prefers-reduced-motion: reduce) {
  .scoria-root *,
  .scoria-root *::before,
  .scoria-root *::after {
    animation-duration: 0.001ms !important;
    transition-duration: 0.001ms !important;
  }
}
```

---

### Tests (test role, request-response/streaming/transform)

**Router macro pattern:** `test/scoria_web/router_test.exs` lines 1-25.
```elixir
defmodule ScoriaWeb.RouterTest do
  use ExUnit.Case, async: true

  defmodule DummyRouter do
    use Phoenix.Router
    import ScoriaWeb.Router

    scope "/" do
      pipe_through :browser
      scoria_dashboard("/scoria")
    end
  end

  test "scoria_dashboard macro mounts workflow run live view" do
    assert Phoenix.Router.route_info(DummyRouter, "GET", "/scoria/workflows/123", nil).plug == Phoenix.LiveView.Plug
  end
end
```

**Component test pattern:** `test/scoria_web/ui_component_test.exs` lines 57-85 and 96-160.
```elixir
html = render_component(&ScoriaWeb.UI.modal/1,
  id: "test-modal",
  show: true,
  on_dismiss: "close_modal",
  inner_block: slot_block("Modal content")
)

assert html =~ ~s(role="dialog")
assert html =~ ~s(aria-modal="true")
```

**LiveView endpoint harness pattern:** `test/scoria_web/live/orchestrator_live_test.exs` lines 1-39 and 57-75.
```elixir
defmodule ScoriaWeb.OrchestratorLiveTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end
end

@endpoint ScoriaWeb.OrchestratorLiveTest.Endpoint
```

**Streaming LiveView assertion pattern:** `test/scoria_web/live/orchestrator_live_test.exs` lines 87-101.
```elixir
{:ok, view, _html} = live(conn, "/scoria")
trace = %{id: "trace-123", spans: [%{id: "span-1", name: "llm_call", depth: 0}]}
send(view.pid, {:new_trace, trace})

assert render(view) =~ "llm_call"
assert render(view) =~ "trace-tree"
```

**Object/provenance assertions:** `test/scoria_web/live/workflow_live_test.exs` lines 506-536 and 671-678.
```elixir
{:ok, view, html} = live(conn, "/scoria/workflows/#{replay_run.id}")

assert html =~ "Replay branch"
assert html =~ "source checkpoint"
assert html =~ "execution mode"

send(view.pid, {:promote_successful, %{source_variant: "replay", dataset_name: "Draft QA", dataset_version: "3"}})
assert render(view) =~ "Promotion succeeded"
```

**Loop-link assertions:** `test/scoria_web/live/review_queue_live_test.exs` lines 73-101.
```elixir
{:ok, view, html} = live(test_conn(), "/scoria/reviews")
assert html =~ "Review flagged traces"

html =
  view
  |> element("button[phx-click='select_candidate'][phx-value-id='#{second.id}']")
  |> render_click()

assert html =~ "/scoria/workflows/#{second.workflow_run_id}?review_candidate_id=#{second.id}"
assert html =~ "/scoria?runtime="
```

**DS-06 drift guard:** `test/scoria_web/ds06_drift_guard_test.exs` lines 1-23, 32-54, 89-99. New UI must not add raw palette classes, especially in `ui.ex`.
```elixir
@palette_regex ~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/

test "lib/scoria_web/ui.ex has zero raw palette matches" do
  source = File.read!("lib/scoria_web/ui.ex")
  matches = Regex.scan(@palette_regex, source)
  assert matches == []
end
```

## Shared Patterns

### Dashboard Mount Prefix
**Source:** `lib/scoria_web/dashboard_nav.ex` lines 52-104  
**Apply to:** sidebar links, palette navigation, shortcut navigation, stub paths, object-page links.

Use `assigns[:scoria_base] || ""` in HEEx and derive base in `DashboardNav` for every routed LiveView. Do not hardcode `/scoria` in new implementation code.

### Token-First UI
**Source:** `lib/scoria_web/ui.ex` lines 1-13; `assets/css/04-components.css` lines 1-5; `test/scoria_web/ds06_drift_guard_test.exs` lines 1-23.  
**Apply to:** all new UI/components/styles.

New UI should be emitted through `ScoriaWeb.UI` where feasible and styled through semantic `.scoria-*` classes. Raw Tailwind palette classes in new files will fail DS-06.

### Client Hook Safety
**Source:** `assets/js/scoria.js` lines 54-69.  
**Apply to:** command palette, shortcut overlay, recents recorder.

Bind global listeners in `mounted`, remove them in `destroyed`, ignore editable/IME events, and only prevent default for owned shortcuts.

### Read-Only Status Counts
**Source:** `lib/scoria_web/operator_surface.ex` lines 100-134.  
**Apply to:** Status Home attention strip.

Counts are read helpers with stable fallback shapes. Do not add persistence or write-side behavior for Phase 13 attention states.

### LiveView Test Harness
**Source:** `test/scoria_web/live/orchestrator_live_test.exs` lines 1-39; `test/scoria_web/live/review_queue_live_test.exs` lines 47-62.  
**Apply to:** new `ComingSoonLive`, Status Home, object header, loop threading tests.

Define a tiny router using `scoria_dashboard("/scoria")`, start a local endpoint, then assert LiveView-rendered markup and route behavior under `/scoria`.

## No Analog Found

None. Two files lack an exact same-purpose analog, but both have usable close patterns:

| File | Role | Data Flow | Closest Usable Pattern |
|------|------|-----------|------------------------|
| `lib/scoria_web/live/coming_soon_live.ex` | LiveView | request-response | Use `ReviewQueueLive` for layout/mount shape and `DashboardNav` for metadata source. |
| `test/scoria_web/dashboard_nav_test.exs` | test | transform/request-response | Use `router_test.exs` macro style plus direct assertions against `DashboardNav.groups/0` and `active_key/1`. |

## Metadata

**Analog search scope:** `lib/scoria_web`, `assets/js`, `assets/css`, `test/scoria_web`  
**Files scanned:** 47  
**Pattern extraction date:** 2026-06-11
