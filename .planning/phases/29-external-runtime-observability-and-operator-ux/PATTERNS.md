# Phase 29: External Runtime Observability & Operator UX - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 5
**Analogs found:** 4 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria_web/live/orchestrator_live.ex` | controller | real-time dashboard | `lib/scoria_web/live/orchestrator_live.ex` | exact |
| `lib/scoria_web/live/workflow_live/show.ex` | controller | detail/truth page | `lib/scoria_web/live/workflow_live/show.ex` | exact |
| `lib/scoria_web/components/runtime_detail_drawer_component.ex` | component | detail drawer | `lib/scoria_web/components/connector_detail_drawer_component.ex` | exact |
| `lib/scoria_web/components/memory_notebook_component.ex` | component | dense evidence | `lib/scoria_web/components/incident_evidence_component.ex` | role-match |
| `lib/scoria_web/presence.ex` | utility | pub-sub / events | none | n/a |

## Pattern Assignments

### `lib/scoria_web/live/orchestrator_live.ex` (controller, real-time dashboard)

**Analog:** `lib/scoria_web/live/orchestrator_live.ex` (itself)

**Async evidence loading pattern** (lines 112-119):
```elixir
  def handle_event("load_retrieval_evidence", %{"id" => trace_id}, socket) do
    {:noreply,
     assign_async(socket, :retrieval_evidence, fn ->
       {:ok, %{retrieval_evidence: sample_evidence(trace_id)}}
     end)}
  end
```

**Compact rail/card loop layout** (lines 154-180):
```elixir
          <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
            <div class="flex items-center justify-between gap-4">
              <div>
                <p class="text-xs uppercase tracking-[0.24em] text-stone-500">connector fleet</p>
                <h2 class="text-lg font-semibold text-stone-900">Connector posture</h2>
              </div>
            </div>

            <div class="mt-4 space-y-3">
              <article :for={connector <- @connector_fleet} class="rounded-xl border border-stone-200 bg-stone-50 p-3">
                <div class="flex items-start justify-between gap-3">
                  <div>
                    <p class="text-sm font-semibold text-stone-900"><%= connector.connector_label %></p>
                    <p class="mt-1 text-xs text-stone-600">
                      <%= connector.health_state %> · refresh <%= connector.last_refresh_status %>
                    </p>
                  </div>
                  <button phx-click="open_connector_drawer" phx-value-id={connector.connector_id} class="text-xs font-medium text-blue-700 underline">
                    Open drawer
                  </button>
                </div>
              </article>
            </div>
          </section>
```

---

### `lib/scoria_web/live/workflow_live/show.ex` (controller, detail/truth page)

**Analog:** `lib/scoria_web/live/workflow_live/show.ex` (itself)

**Evidence mounting structure** (lines 49-62):
```elixir
        <section class="mt-6 rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
          <h2 class="text-lg font-semibold">Timeline</h2>
          <ol id="workflow-timeline" class="mt-3 space-y-2">
            <li :for={event <- @events} class="rounded-xl bg-stone-50 px-3 py-2 text-sm">
              <span class="font-medium"><%= event.event_type %></span>
              <span class="ml-2 font-mono text-xs text-stone-500"><%= event.sequence %></span>
            </li>
          </ol>
        </section>

        <RemoteInvocationEvidenceComponent.render
          :if={@remote_invocation_evidence.approvals != []}
          evidence={@remote_invocation_evidence}
        />
```

---

### `lib/scoria_web/components/runtime_detail_drawer_component.ex` (component, detail drawer)

**Analog:** `lib/scoria_web/components/connector_detail_drawer_component.ex`

**Drawer skeleton and header** (lines 4-15):
```elixir
    <%= if @drawer do %>
      <section id="connector-detail-drawer" class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="text-xs uppercase tracking-[0.24em] text-stone-500">connector detail</p>
            <h2 class="text-lg font-semibold text-stone-900"><%= @drawer.connector_label %></h2>
            <p class="mt-1 text-sm text-stone-600"><%= @drawer.connector_key %> · <%= @drawer.health_state %></p>
          </div>
          <button phx-click="close_connector_drawer" class="text-xs font-medium text-stone-600 underline">Close</button>
        </div>
```

**Grid metadata** (lines 17-26):
```elixir
        <div class="mt-4 grid gap-3 md:grid-cols-2">
          <div class="rounded-xl bg-stone-50 p-3">
            <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Auth provenance</p>
            <p class="mt-2 text-sm font-medium text-stone-900"><%= @drawer.auth_provenance.status %></p>
            <p class="mt-1 text-xs text-stone-600"><%= @drawer.auth_provenance.subject_ref || "no active subject" %></p>
          </div>
          <!-- Additional columns follow identical block patterns -->
        </div>
```

---

### `lib/scoria_web/components/memory_notebook_component.ex` (component, dense evidence)

**Analog:** `lib/scoria_web/components/incident_evidence_component.ex`

**Notebook header and scoping badges** (lines 9-22):
```elixir
      <div class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <p class="text-xs uppercase tracking-[0.24em] text-stone-500">incident evidence</p>
          <h3 class="text-lg font-semibold text-stone-900">Trace-first incident notebook</h3>
          <p class="mt-1 text-sm text-stone-600">
            Composite health rollup stays compact while the evidence below explains the selected run.
          </p>
        </div>

        <div class="flex flex-wrap gap-2 text-xs text-stone-700">
          <span class="rounded-full border border-stone-300 bg-white px-3 py-1">
            trace <span class="font-mono"><%= @evidence.trace_id %></span>
          </span>
```

**Iterative dense notebook blocks** (lines 65-81):
```elixir
          <div class="rounded-lg border border-stone-200 bg-white p-4">
            <h4 class="text-sm font-semibold text-stone-900">Incident notebook</h4>
            <div class="mt-3 space-y-3">
              <article :for={incident <- @evidence.incidents} class="rounded-lg border border-stone-200 p-3">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <p class="text-sm font-semibold text-stone-900"><%= incident.summary %></p>
                    <p class="mt-1 text-xs text-stone-500"><%= incident.reason_code %></p>
                  </div>
                  <div class="flex flex-wrap gap-2">
                    <span class={badge_class(incident.routing_class, :routing)}><%= incident.routing_label %></span>
                    <span class={badge_class(incident.severity, :severity)}><%= incident.severity_label %></span>
                  </div>
                </div>
```

**Status badge formatting** (lines 145-163):
```elixir
  defp badge_class(value, kind) do
    base = "rounded-full px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em]"

    tone =
      case {kind, value} do
        {:severity, "critical"} -> "border border-rose-200 bg-rose-50 text-rose-800"
        {:routing, "review"} -> "border border-sky-200 bg-sky-50 text-sky-800"
        _ -> "border border-emerald-200 bg-emerald-50 text-emerald-800"
      end

    [base, tone]
  end
```

## Shared Patterns

### Typography & Structure Conventions
**Source:** Project UI Specs
**Apply to:** All component files
```text
- Badges: Text-[11px] font-semibold uppercase tracking-[0.18em] rounded-full px-2.5 py-1
- Sub-headings: Text-xs uppercase tracking-[0.24em] text-stone-500
- Borders: border-stone-200, rounded-xl / rounded-2xl
- Monospace IDs: `<span class="font-mono text-xs"><%= id %></span>`
```

## No Analog Found

Files with no close match in the codebase (planner should use standard external patterns):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/scoria_web/presence.ex` | utility | event-driven | No explicit `Phoenix.Presence` usage exists in `lib/` yet. Standard `use Phoenix.Presence` boiler template must be generated. |

## Metadata

**Analog search scope:** `lib/scoria_web/live/**/*.ex`, `lib/scoria_web/components/**/*.ex`
**Files scanned:** 14
**Pattern extraction date:** 2026-05-20
