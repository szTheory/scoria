# Phase 44: Dashboard auth seam - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 21 new/modified surfaces
**Analogs found:** 21 / 21

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria_web/router.ex` | route | request-response | `lib/scoria_web/router.ex` | exact |
| `lib/scoria_web/dashboard_scope.ex` | middleware | request-response | `lib/scoria_web/dashboard_nav.ex` + `lib/scoria/knowledge/scope.ex` | composite-exact |
| `lib/scoria_web/operator_surface.ex` | service | CRUD | `lib/scoria_web/operator_surface.ex` | exact |
| `lib/scoria_web/live/orchestrator_live.ex` | component | streaming | `lib/scoria_web/live/orchestrator_live.ex` | exact |
| `lib/scoria_web/live/approvals_live/index.ex` | component | event-driven | `lib/scoria_web/live/approvals_live/index.ex` | exact |
| `lib/scoria_web/live/connectors_live/index.ex` | component | pub-sub | `lib/scoria_web/live/connectors_live/index.ex` | exact |
| `lib/scoria_web/live/incidents_live/index.ex` | component | request-response | `lib/scoria_web/live/incidents_live/index.ex` | exact |
| `lib/scoria_web/live/incidents_live/show.ex` | component | request-response | `lib/scoria_web/live/incidents_live/show.ex` | exact |
| `lib/scoria_web/live/workflow_live/index.ex` | component | CRUD | `lib/scoria_web/live/workflow_live/index.ex` | exact |
| `lib/scoria_web/live/workflow_live/show.ex` | component | event-driven | `lib/scoria_web/live/workflow_live/show.ex` | exact |
| `lib/scoria_web/live/review_queue_live.ex` | component | CRUD | `lib/scoria_web/live/review_queue_live.ex` | exact |
| `lib/scoria_web/live/eval_spec_live/index.ex` | component | CRUD | `lib/scoria_web/live/eval_spec_live/index.ex` | exact |
| `lib/scoria_web/live/dataset_live/index.ex` | component | CRUD | `lib/scoria_web/live/dataset_live/index.ex` | exact |
| `lib/scoria_web/live/prompt_live/index.ex` | component | CRUD | `lib/scoria_web/live/prompt_live/index.ex` | exact |
| `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | component | event-driven | `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | exact |
| `test/scoria_web/router_test.exs` | test | request-response | `test/scoria_web/router_test.exs` | exact |
| `test/scoria_web/dashboard_scope_test.exs` | test | request-response | `test/scoria/knowledge/tenant_isolation_test.exs` | role-match |
| `test/scoria_web/live/dashboard_auth_test.exs` | test | request-response | `test/scoria_web/live/incidents_live_test.exs` | role-match |
| `test/scoria_web/dashboard_scope_source_guard_test.exs` | test | batch | `test/scoria/workflows/approval_write_invariant_guard_test.exs` | data-flow-match |
| `docs/adoption_lanes.md` | documentation | transform | `docs/adoption_lanes.md` + `test/scoria/adoption_surface_test.exs` | exact |
| `docs/operator_verification.md` | documentation | transform | `docs/operator_verification.md` + `test/scoria/adoption_surface_test.exs` | exact |

## Pattern Assignments

### `lib/scoria_web/router.ex` (route, request-response)

**Analog:** `lib/scoria_web/router.ex`

**Macro and import pattern** (lines 20-36):
```elixir
defmacro scoria_dashboard(path, _opts \\ []) do
  quote bind_quoted: binding() do
    scope path, alias: false, as: false do
      import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 2, live_session: 3]
      import Phoenix.Router, only: [get: 3]

      get("/connectors/:connector_id/auth/start", ScoriaWeb.ConnectorAuthController, :start)

      live_session :scoria_dashboard,
        root_layout: {ScoriaWeb.Layouts, :root},
        on_mount: ScoriaWeb.DashboardNav do
```

**Route list pattern** (lines 37-49):
```elixir
live("/", ScoriaWeb.OrchestratorLive, :index)
live("/approvals", ScoriaWeb.ApprovalsLive.Index, :index)
live("/reviews", ScoriaWeb.ReviewQueueLive, :index)
live("/datasets", ScoriaWeb.DatasetLive.Index, :index)
live("/workflows", ScoriaWeb.WorkflowLive.Index, :index)
live("/workflows/:id", ScoriaWeb.WorkflowLive.Show, :show)
live("/connectors", ScoriaWeb.ConnectorsLive.Index, :index)
live("/incidents", ScoriaWeb.IncidentsLive.Index, :index)
live("/incidents/:id", ScoriaWeb.IncidentsLive.Show, :show)
live("/eval_specs", ScoriaWeb.EvalSpecLive.Index, :index)
live("/prompts", ScoriaWeb.PromptLive.Index, :index)
live("/prompts/:id/release", ScoriaWeb.PromptLive.ReleaseWorkbenchLive, :index)
live("/coming/:screen", ScoriaWeb.ComingSoonLive, :show)
```

**Planner action:** keep the quoted `scope` and route list. Change the macro head to bind `opts`, normalize `List.wrap(Keyword.get(opts, :on_mount, []))`, append `[ScoriaWeb.DashboardScope, ScoriaWeb.DashboardNav]`, and keep `root_layout` Scoria-owned. Do not pass through broad `live_session_opts`.

---

### `lib/scoria_web/dashboard_scope.ex` (middleware, request-response)

**Analog:** `lib/scoria_web/dashboard_nav.ex` for LiveView hook shape.

**Imports pattern** (lines 10-11):
```elixir
import Phoenix.LiveView, only: [attach_hook: 4]
import Phoenix.Component, only: [assign: 3]
```

**On-mount continuation pattern** (lines 220-227):
```elixir
def on_mount(:default, params, _session, socket) do
  socket =
    socket
    |> assign(:scoria_nav, active_key(socket.view, params))
    |> attach_hook(:scoria_base, :handle_params, &assign_base/3)

  {:cont, socket}
end
```

**Mounted assign helper pattern** (lines 230-239):
```elixir
defp assign_base(params, uri, socket) do
  base =
    case socket.assigns[:scoria_base] do
      nil -> derive_base(uri, socket.view, params)
      existing -> existing
    end

  {:cont,
   socket |> assign(:scoria_base, base) |> assign(:scoria_nav, active_key(socket.view, params))}
end
```

**Analog:** `lib/scoria/knowledge/scope.ex` for fail-closed scope normalization.

**Struct and constructor pattern** (lines 17-30):
```elixir
defstruct [:tenant_id, :actor_id, :scope_kind]

def new!(%__MODULE__{} = scope), do: validate!(scope)

def new!(attrs) when is_map(attrs) or is_list(attrs) do
  attrs = normalize_attrs(attrs)

  %__MODULE__{
    tenant_id: required_id!(Map.get(attrs, :tenant_id), :tenant_id),
    actor_id: optional_id(Map.get(attrs, :actor_id)),
    scope_kind: scope_kind!(Map.get(attrs, :scope_kind, "tenant_shared"))
  }
  |> validate!()
end
```

**Required identifier pattern** (lines 162-181):
```elixir
defp required_id!(value, field) do
  case optional_id(value) do
    nil -> raise ArgumentError, "#{field} is required"
    id -> id
  end
end

defp optional_id(value) when is_binary(value) do
  value
  |> String.trim()
  |> case do
    "" -> nil
    id -> id
  end
end

defp optional_id(nil), do: nil

defp optional_id(value) do
  raise ArgumentError, "scope identifiers must be strings, got: #{inspect(value)}"
end
```

**Fail-closed PubSub precedent** from `lib/scoria/observe/operator_broadcast.ex` (lines 27-45):
```elixir
def span_stopped(metadata) when is_map(metadata) do
  case Map.get(metadata, :tenant_id) do
    tenant_id when is_binary(tenant_id) and tenant_id != "" ->
      trace_id = Map.get(metadata, :trace_id)
      broadcast(tenant_id, {:trace_span, trace_id, TraceProjection.span_view(metadata)})
      :ok

    _ ->
      Logger.debug("OperatorBroadcast.span_stopped/1 dropped: missing tenant_id")
      :dropped
  end
end
```

**Planner action:** implement a public scope struct/contract and `on_mount/4` gate. Normalize resolver returns like `Knowledge.Scope`, assign `:scoria_scope`, `:tenant_id`, `:actor_id`, and optional `:session_id` / display label. Halt/redirect/error on missing or malformed scope before LiveView mounts read data.

---

### `lib/scoria_web/operator_surface.ex` (service, CRUD)

**Analog:** `lib/scoria_web/operator_surface.ex`

**Imports and aliases pattern** (lines 11-29):
```elixir
import Ecto.Query, warn: false

alias Decimal, as: D
alias Scoria.Connectors
alias Scoria.Connectors.Connector
alias Scoria.Eval.OnlineScoreCandidate
alias Scoria.Repo
alias Scoria.Runtime
alias Scoria.Workflows
```

**Tenant-qualified list pattern** (lines 33-44):
```elixir
@doc "Runtime posture rows for a tenant, annotated with live presence status."
def load_runtimes(tenant_id) do
  presence_topic = "mcp:runtimes:#{tenant_id}"
  presence_ids = ScoriaWeb.Presence.list(presence_topic) |> Map.keys()

  instances =
    Runtime.Instance
    |> where(tenant_id: ^tenant_id)
    |> order_by(desc: :last_seen_at)
    |> limit(10)
    |> Repo.all()
```

**Tenant-qualified lookup pattern** (lines 192-218):
```elixir
@doc "All incidents for a tenant, newest first - the /incidents triage list."
def list_tenant_incidents(tenant_id) do
  Incident
  |> where(tenant_id: ^tenant_id)
  |> order_by([incident], desc: incident.last_seen_at)
  |> limit(50)
  |> Repo.all()
rescue
  _error -> []
end

@doc "Tenant-scoped incident lookup for routed incident detail pages."
def fetch_tenant_incident(tenant_id, incident_id) when is_binary(incident_id) do
  case Ecto.UUID.cast(incident_id) do
    {:ok, id} ->
      Incident
      |> where([incident], incident.tenant_id == ^tenant_id and incident.id == ^id)
      |> Repo.one()

    :error ->
      nil
  end
rescue
  _error -> nil
end
```

**Planner action:** add tenant-qualified helpers for current global dashboard reads. Reuse this shape for run lists/details, review candidates, eval runs, dataset sources, prompt release evidence, and linked incidents. Where a schema is truly global metadata, document that in the plan and keep tenant-owned evidence out of the unscoped render path.

---

### Dashboard LiveViews (component, request-response / event-driven / streaming)

**Analog:** `lib/scoria_web/live/orchestrator_live.ex`

**Current tenant spoof path to replace** (lines 26-45):
```elixir
def mount(params, session, socket) do
  tenant_id = params["tenant"] || session["tenant_id"] || "default"

  socket =
    socket
    |> assign(:page_title, "Home")
    |> assign(:runtime_query, Map.get(params, "runtime"))
    |> assign(:review_candidate, load_review_candidate(Map.get(params, "review_candidate_id")))
    |> assign(:tenant_id, tenant_id)
    |> load_status_home()
    |> stream(:traces, [])

  if connected?(socket) do
    Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
    hydrate_traces(socket, tenant_id)
  end
end
```

**Assigned tenant read pattern** (lines 277-282):
```elixir
defp load_status_home(socket) do
  tenant_id = socket.assigns.tenant_id

  assign_async(socket, :status_home, fn ->
    {:ok, %{status_home: OperatorSurface.status_home_summary(tenant_id)}}
  end)
end
```

**Tenant-qualified trace hydration pattern** (lines 193-234):
```elixir
defp hydrate_traces(socket, tenant_id) do
  trace_ids =
    Span
    |> where([s], fragment("?->>? = ?", s.attributes, "tenant_id", ^tenant_id))
    |> group_by([s], s.trace_id)
    |> order_by([s], desc: max(s.end_time))
    |> limit(^limit)
    |> select([s], s.trace_id)
    |> Repo.all()

  spans =
    Span
    |> where([s], s.trace_id == ^trace_id)
    |> where([s], fragment("?->>? = ?", s.attributes, "tenant_id", ^tenant_id))
    |> order_by([s], asc: s.start_time)
    |> Repo.all()
end
```

**Apply to:** `orchestrator_live.ex`, `connectors_live/index.ex`, `incidents_live/index.ex`, `incidents_live/show.ex`, `approvals_live/index.ex`, `workflow_live/index.ex`, `workflow_live/show.ex`, `review_queue_live.ex`, `eval_spec_live/index.ex`, `dataset_live/index.ex`, `prompt_live/index.ex`, `prompt_live/release_workbench_live.ex`.

**Planner action:** each LiveView should read only `socket.assigns.tenant_id` or `socket.assigns.scoria_scope`. Keep query params such as `runtime`, `from`, `review_candidate_id`, `scope`, `outcome`, `promote`, and `prompt_template_id` as UI filters/deep-link hints, then validate all object reads against the assigned tenant.

---

### `lib/scoria_web/live/approvals_live/index.ex` (component, event-driven)

**Analog:** `lib/scoria_web/live/approvals_live/index.ex`

**Tenant-scoped inbox pattern** (lines 421-439):
```elixir
defp reload_inbox(%{assigns: %{scope: "decided"}} = socket) do
  filters =
    %{tenant_id: socket.assigns.tenant_id, limit: socket.assigns.decided_limit}
    |> maybe_put_outcome_status(socket.assigns.outcome)

  approvals = Workflows.list_decided_approvals(filters)
  events_by_approval_id = decision_events_by_approval_id(approvals)

  socket
  |> assign(:approval_inbox, approvals)
  |> assign(:decision_receipts, decision_receipts_for(approvals, events_by_approval_id))
end

defp reload_inbox(socket) do
  assign(socket, :approval_inbox, Workflows.list_pending_remote_approvals(%{tenant_id: socket.assigns.tenant_id}))
end
```

**Tenant-scoped deep-link lookup pattern** (lines 528-598):
```elixir
defp assign_active_approval(socket, approval_id)
     when is_binary(approval_id) and approval_id != "" do
  put_active_approval(socket, resolve_scoped_approval(socket, approval_id))
end

defp fetch_tenant_scoped_approval(socket, approval_id) do
  with {:ok, _uuid} <- Ecto.UUID.cast(approval_id),
       %{tenant_id: tenant_id} = approval when tenant_id == socket.assigns.tenant_id <-
         safe_get_lineage(approval_id) do
    approval
  else
    _ -> nil
  end
end
```

**Unsafe fallback to remove** (lines 707-715):
```elixir
%{
  actor_id: socket.assigns.actor_id || approval.session_id || "operator",
  tenant_id:
    socket.assigns.tenant_id || (request_event && request_event.tenant_id) || "default",
  trace_id: request_event && request_event.trace_id
}
```

**Planner action:** keep the tenant-filtered inbox and deep-link patterns, but remove all `"default"` authority fallbacks. Actor may default only from validated `scoria_scope`/host session data; tenant must not.

---

### `lib/scoria_web/live/connectors_live/index.ex` (component, pub-sub)

**Analog:** `lib/scoria_web/live/connectors_live/index.ex`

**PubSub and tenant-read pattern** (lines 18-31):
```elixir
def mount(params, session, socket) do
  tenant_id = params["tenant"] || session["tenant_id"] || "default"

  if connected?(socket) do
    Phoenix.PubSub.subscribe(Scoria.PubSub, "mcp:runtimes:#{tenant_id}")
  end

  socket =
    socket
    |> assign(:page_title, "Connectors")
    |> assign(:tenant_id, tenant_id)
    |> load_fleet()
end
```

**Error handling pattern** (lines 215-240):
```elixir
defp load_fleet(socket) do
  tenant_id = socket.assigns.tenant_id

  case fetch_fleet(tenant_id) do
    {:ok, runtimes, connector_fleet} ->
      socket
      |> assign(:load_error, false)
      |> assign(:runtimes, runtimes)
      |> assign(:connector_fleet, connector_fleet)

    :error ->
      socket
      |> assign(:load_error, true)
      |> assign(:runtimes, [])
      |> assign(:connector_fleet, [])
  end
end

defp fetch_fleet(tenant_id) do
  {:ok, OperatorSurface.load_runtimes(tenant_id), OperatorSurface.connector_fleet(tenant_id)}
rescue
  _ -> :error
end
```

**Planner action:** leave `fetch_fleet/1` shape intact, but source `tenant_id` from the dashboard gate. Subscribe only after the gate assigns a non-empty tenant.

---

### `lib/scoria_web/live/incidents_live/index.ex` and `show.ex` (component, request-response)

**Analog:** `lib/scoria_web/live/incidents_live/index.ex`

**Current mount to replace tenant source in** (lines 16-27):
```elixir
def mount(params, session, socket) do
  tenant_id = (is_map(params) && params["tenant"]) || session["tenant_id"] || "default"
  incidents = OperatorSurface.list_tenant_incidents(tenant_id)

  socket =
    socket
    |> assign(:page_title, "Incidents")
    |> assign(:tenant_id, tenant_id)
    |> assign(:has_incidents, incidents != [])
    |> stream(:incidents, incidents)
end
```

**Tenant-scoped redirect/detail lookup pattern** (lines 33-47):
```elixir
def handle_params(params, uri, socket) do
  case OperatorSurface.find_tenant_incident_for_run(socket.assigns.tenant_id, run_id) do
    nil ->
      {:noreply, assign(socket, :not_found_from, params["from"])}

    incident ->
      {:noreply, push_navigate(socket, to: incident_path(incident, base, params["from"]))}
  end
end
```

**Analog:** `lib/scoria_web/live/incidents_live/show.ex`

**Tenant-scoped object detail pattern** (lines 29-42):
```elixir
def handle_params(%{"id" => id} = params, _uri, socket) do
  incident = OperatorSurface.fetch_tenant_incident(socket.assigns.tenant_id, id)

  socket =
    socket
    |> assign(:incident, incident)
    |> assign(:page_title, incident_title(incident))
    |> assign(:incident_evidence, evidence_for(incident))
    |> assign(:origin_context, origin_context(params["from"], socket.assigns[:scoria_base] || ""))

  {:noreply, socket}
end
```

**Planner action:** copy the object-detail behavior for other tenant-owned detail pages: foreign IDs render generic not found/empty state, not global data.

---

### `lib/scoria_web/live/workflow_live/index.ex` and `show.ex` (component, CRUD/event-driven)

**Analog:** `lib/scoria_web/live/workflow_live/index.ex`

**Global list read to replace** (lines 15-26):
```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:page_title, "Runs")
   |> assign(:runs, list_runs())}
end

defp list_runs do
  Repo.all(from(r in Run, order_by: [desc: r.inserted_at], limit: 50))
rescue
  _ -> []
end
```

**Analog:** `lib/scoria_web/live/workflow_live/show.ex`

**Global run detail read to harden** (lines 38-50, 285-306):
```elixir
def mount(%{"id" => run_id} = params, _session, socket) do
  if connected?(socket) do
    Workflows.subscribe_run(run_id)
  end

  socket =
    socket
    |> load_run(run_id)
    |> assign(:review_candidate, load_review_candidate(run_id, review_candidate_id))
end

defp load_run(socket, run_id) do
  run = Workflows.get_run_tree!(run_id)
  detail = Runtime.get_run_detail!(run_id)

  socket
  |> assign(:run, run)
  |> assign(:linked_incident, linked_incident(run.id))
  |> assign(:remote_invocation_evidence, SRE.remote_invocation_evidence(run_id))
end
```

**Global linked-object reads to harden** (lines 513-519, 552-558):
```elixir
defp linked_incident(run_id) do
  Incident
  |> where([incident], incident.workflow_run_id == ^run_id)
  |> order_by([incident], desc: incident.last_seen_at)
  |> limit(1)
  |> Repo.one()
end

defp existing_prompt_id(candidate) do
  with {:ok, prompt_id} <- Ecto.UUID.cast(candidate),
       true <- Repo.exists?(from(prompt in PromptTemplate, where: prompt.id == ^prompt_id)) do
    prompt_id
  else
    _ -> nil
  end
end
```

**Planner action:** add tenant-aware `OperatorSurface` or context APIs and call them from these pages. Subscribe to workflow updates only after the run has been proven visible to `socket.assigns.tenant_id`, or handle subscription messages defensively.

---

### `review_queue_live.ex`, `eval_spec_live/index.ex`, `dataset_live/index.ex`, `prompt_live/*` (component, CRUD)

**Review queue global read pattern to harden** from `lib/scoria_web/live/review_queue_live.ex` (lines 261-295):
```elixir
defp refresh_queue(socket, reset_selection \\ true) do
  case load_queue(socket.assigns.filters) do
    {:ok, rows, summary} ->
      socket
      |> assign(:load_error, false)
      |> assign(:queue_rows, rows)
      |> assign(:summary, summary)
      |> refresh_selection()

    :error ->
      socket
      |> assign(:load_error, true)
      |> assign(:queue_rows, [])
      |> assign(:summary, empty_summary())
      |> refresh_selection()
  end
end

defp load_queue(filters) do
  rows = Eval.list_review_queue(filters)
  summary = Eval.summarize_review_queue(filters)
  {:ok, rows, summary}
rescue
  _ -> :error
end
```

**Closed query-param facet pattern** from `review_queue_live.ex` (lines 315-330):
```elixir
defp filters_from_params(params) do
  %{
    "review_status" =>
      validate_facet(Map.get(params, "review_status"), @review_statuses, "pending"),
    "severity" => validate_facet(Map.get(params, "severity"), @severities, ""),
    "promotion_state" =>
      validate_facet(Map.get(params, "promotion_state"), @promotion_states, "")
  }
end

defp validate_facet(value, allowed, default) do
  if value in allowed, do: value, else: default
end
```

**Eval global read pattern to harden** from `eval_spec_live/index.ex` (lines 23-30, 180-185):
```elixir
socket
|> assign(:eval_specs, Eval.list_eval_specs())
|> assign(:eval_runs, list_eval_runs())

defp list_eval_runs do
  EvalRun
  |> order_by([run], desc: run.inserted_at)
  |> limit(20)
  |> preload(:scores)
  |> Repo.all()
end
```

**Dataset global read pattern to harden** from `dataset_live/index.ex` (lines 292-317):
```elixir
defp load_datasets(socket) do
  case dataset_rows() do
    {:ok, rows} ->
      socket
      |> assign(:load_error, false)
      |> assign(:dataset_rows, rows)
      |> assign(:datasets, sort_rows(rows, socket.assigns.sort_by, socket.assigns.sort_dir))

    :error ->
      socket
      |> assign(:load_error, true)
      |> assign(:dataset_rows, [])
  end
end

defp dataset_rows do
  {:ok, Eval.list_datasets() |> Enum.map(&dataset_row/1)}
rescue
  _ -> :error
end
```

**Prompt release session/default path to replace** from `release_workbench_live.ex` (lines 16-45):
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
    |> assign(:draft_run, fetch_eval_run(draft.id))
    |> assign(:active_run, fetch_eval_run(if active, do: active.id, else: nil))
    |> assign(:pending_approval, fetch_pending_approval(draft.id))
end
```

**Planner action:** pass `tenant_id` into context/read-model calls. Keep query params as closed filters or object hints, then verify the object is visible to the assigned tenant before rendering evidence.

---

## Test Pattern Assignments

### `test/scoria_web/router_test.exs` (test, request-response)

**Analog:** `test/scoria_web/router_test.exs`

**Disposable router pattern** (lines 1-17):
```elixir
defmodule ScoriaWeb.RouterTest do
  use ExUnit.Case, async: true

  defmodule DummyRouter do
    use Phoenix.Router
    import ScoriaWeb.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/" do
      pipe_through(:browser)
      scoria_dashboard("/scoria")
    end
  end
end
```

**Route assertion pattern** (lines 19-40):
```elixir
assert Phoenix.Router.route_info(DummyRouter, "GET", "/scoria", nil).plug ==
         Phoenix.LiveView.Plug

assert %{
         plug: Phoenix.LiveView.Plug,
         phoenix_live_view: {ScoriaWeb.DatasetLive.Index, :index, _, _}
       } = Phoenix.Router.route_info(DummyRouter, "GET", "/scoria/datasets", nil)
```

**Planner action:** add dummy routers for bare macro, single hook, hook list, and invalid hook shapes. Assert route mount still works and inspect compiled live-session metadata enough to prove hook order: host hook(s), `ScoriaWeb.DashboardScope`, `ScoriaWeb.DashboardNav`.

---

### `test/scoria_web/dashboard_scope_test.exs` (test, request-response)

**Analog:** `test/scoria/knowledge/tenant_isolation_test.exs`

**Normalization and failure test pattern** (lines 51-94):
```elixir
describe "Scoria.Knowledge.Scope" do
  test "normalizes keyword, map, struct, and shorthand inputs" do
    assert %Scope{tenant_id: "tenant-a", actor_id: nil, scope_kind: "tenant_shared"} =
             Scope.new!(tenant_id: "tenant-a")
  end

  test "raises on missing, empty, or conflicting tenant scope" do
    assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
      Scope.new!(%{})
    end

    assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
      Scope.new!(tenant_id: "   ")
    end
  end
end
```

**Identity normalization analog** from `test/scoria/identity_test.exs` (lines 49-76):
```elixir
test "normalizes liveview session maps into the canonical envelope" do
  identity =
    Identity.from_session(%{
      "actor_id" => "actor-4",
      "tenant_id" => "tenant-4",
      "session_id" => "session-4"
    })

  assert identity.actor_id == "actor-4"
  assert identity.tenant_id == "tenant-4"
  assert identity.session_id == "session-4"
end
```

**Planner action:** test default resolver session compatibility, behavior/MFA resolver returns, blank tenant failure, unauthorized halt/redirect, malformed return raising, and assigned `:tenant_id`/`:scoria_scope`/`:actor_id`.

---

### `test/scoria_web/live/dashboard_auth_test.exs` (test, request-response)

**Analog:** `test/scoria_web/live/incidents_live_test.exs`

**Endpoint and session harness pattern** (lines 1-60):
```elixir
defmodule ScoriaWeb.IncidentsLiveTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end
end

defp session_conn do
  build_conn()
  |> Plug.Test.init_test_session(%{"tenant_id" => @tenant})
  |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
end
```

**Cross-tenant object refusal pattern** (lines 358-370):
```elixir
test "incident detail refuses cross-tenant incidents" do
  other =
    seed_incident!(%{
      tenant_id: "other-tenant",
      incident_key: "inc-other-tenant",
      summary: "Other tenant incident",
      trace_id: "trace-other-tenant"
    })

  {:ok, _view, html} = live(session_conn(), "/scoria/incidents/#{other.id}")

  assert html =~ "Incident not found"
  refute html =~ "Other tenant incident"
end
```

**PubSub and tenant fixture pattern** from `test/scoria_web/live/approvals_live_integration_test.exs` (lines 97-132):
```elixir
defp approvals_conn(tenant_id) do
  build_conn()
  |> Plug.Test.init_test_session(%{"tenant_id" => tenant_id, "actor_id" => "operator-int"})
  |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
end

{:ok, view, _html} =
  live(approvals_conn(tenant_id), "/scoria/approvals?runtime=#{session_id}")

assert {:ok, started} =
         Runtime.start_run(
           %{tenant_id: tenant_id, actor_id: "operator-int", session_id: session_id},
           root_role_id: "executor",
           handlers: %{"approval" => {Handlers, :wait_for_approval}}
         )
```

**Planner action:** add cross-tenant spoof tests for `?tenant=tenant-b` while the session/resolver asserts tenant A. Assert tenant B data does not render, object detail IDs from tenant B are unavailable, and PubSub topics/read calls use tenant A.

---

### `test/scoria_web/dashboard_scope_source_guard_test.exs` (test, batch)

**Analog:** `test/scoria/workflows/approval_write_invariant_guard_test.exs`

**Scan path and allowlist pattern** (lines 24-42):
```elixir
@scan_paths Path.wildcard("lib/scoria/**/*.ex") ++ Path.wildcard("priv/repo/**/*.exs")

@allowed_approval_updates MapSet.new([
                          {"lib/scoria/workflows.ex", 435},
                          {"lib/scoria/workflows.ex", 684}
                        ])
```

**Source-scan assertion pattern** (lines 102-125):
```elixir
test "every Approval.changeset(...) call site that terminates in an update is allow-listed" do
  offenders =
    for path <- @scan_paths,
        lines = code_lines(path),
        {line, line_number} <- Enum.with_index(lines, 1),
        Regex.match?(~r/Approval\.changeset\(/, line),
        classify_approval_write(lines, line_number) == :update,
        not MapSet.member?(@allowed_approval_updates, {path, line_number}) do
      "#{path}:#{line_number}"
    end

  assert offenders == [],
         """
         D-20 write-invariant guard: found an Approval row write not on the allow-list.
         Offenders:
         #{Enum.join(offenders, "\n")}
         """
end
```

**Comment-stripping helper pattern** (lines 148-158):
```elixir
defp code_lines(path) do
  path
  |> File.read!()
  |> String.split("\n")
  |> Enum.map(fn line ->
    if String.trim(line) |> String.starts_with?("#"), do: "", else: line
  end)
end
```

**Planner action:** scan `lib/scoria_web/live/**/*.ex` for `params["tenant"]`, `session["tenant_id"] || "default"`, and `|| "default"` near tenant assignment. Keep the guard warning-grade but fail the test if any forbidden authority pattern returns.

---

## Documentation Pattern Assignments

### `docs/adoption_lanes.md` (documentation, transform)

**Analog:** `docs/adoption_lanes.md`

**Current host-session wording to replace** (lines 34-44):
````markdown
#### Host session identity

Host apps **must** set `session["tenant_id"]` and `session["actor_id"]` before mounting `/scoria` (or any route wired with `scoria_dashboard/2`). OrchestratorLive scopes PubSub to `scoria:runs:{tenant_id}` and uses both keys for audit refs on `Workflows.approve/3`.

```elixir
conn
|> put_session("tenant_id", conn.assigns.current_account.id)
|> put_session("actor_id", conn.assigns.current_user.id)
```
````

**Doc contract analog:** `test/scoria/adoption_surface_test.exs` (lines 102-121):
```elixir
test "lane selection guide documents the adoption order and optional boundaries" do
  content = File.read!(@lane_guide)

  assert content =~ "Default runtime lane"
  assert content =~ "identity -> start -> inspect -> resume"
  assert content =~ @default_lane_command
  assert content =~ "This lane is explicitly optional."
  assert content =~ "Start narrow. Expand only when the current lane already feels boring."
end
```

**Planner action:** replace session-only language with host-auth hook plus `scope_resolver:` as canonical. Keep session keys only as the default resolver compatibility input. Add doc-contract assertions for the new canonical fragments.

---

### `docs/operator_verification.md` (documentation, transform)

**Analog:** `docs/operator_verification.md`

**Current operator evidence proof wording to update** (lines 99-147):
````markdown
## Step 2: Prove one real runtime flow

identity =
  Scoria.identity(%{
    actor_id: current_user.id,
    tenant_id: current_account.id,
    session_id: get_session(conn, :assistant_session_id)
  })

## Step 4: Open operator evidence

Open the operator pages for the installed dashboard:

```text
/scoria
/scoria/workflows/:run_id
```
````

**Doc contract analog:** `test/scoria/adoption_surface_test.exs` (lines 257-319):
```elixir
test "operator verification guide documents the four-tier support hierarchy" do
  content = File.read!(@operator_guide)

  assert content =~ @default_lane_command
  assert content =~ "Scoria.start_run"
  assert content =~ "Scoria.get_run"
  assert content =~ "/scoria/workflows/:run_id"
  refute content =~ "mix scoria.test.knowledge"
end
```

**Planner action:** document that the host authenticates the operator and asserts dashboard tenant scope. Add proof guidance for mounting with a host hook/resolver and for verifying `?tenant=` no longer chooses dashboard tenant authority.

---

## Shared Patterns

### Authentication and Hook Order

**Source:** `lib/scoria_web/router.ex` lines 20-36 and `lib/scoria_web/dashboard_nav.ex` lines 220-227.

**Apply to:** router macro and all dashboard LiveViews.

```elixir
host_on_mount_hooks = List.wrap(Keyword.get(opts, :on_mount, []))
on_mount_hooks = host_on_mount_hooks ++ [ScoriaWeb.DashboardScope, ScoriaWeb.DashboardNav]
```

Use Phoenix hook forms directly. Let Phoenix validate invalid hook shapes.

### Fail-Closed Scope

**Source:** `lib/scoria/knowledge/scope.ex` lines 162-181 and `lib/scoria/observe/operator_broadcast.ex` lines 27-45.

**Apply to:** `DashboardScope`, LiveView mounts, PubSub subscriptions, and tenant-qualified reads.

```elixir
tenant_id when is_binary(tenant_id) and tenant_id != "" ->
  {:cont, assign(socket, :tenant_id, tenant_id)}

_ ->
  {:halt, socket}
```

Do not use `"default"` as dashboard authority. Default resolver compatibility may read session keys, but absence or blank tenant must halt or raise.

### Tenant-Qualified Reads

**Source:** `lib/scoria_web/operator_surface.ex` lines 192-218.

**Apply to:** workflow runs, incidents, approvals, review candidates, eval runs, datasets, prompts, release evidence, and linked-object helpers.

```elixir
Incident
|> where([incident], incident.tenant_id == ^tenant_id and incident.id == ^id)
|> Repo.one()
```

Where schema support is missing, planner must choose between adding scope/filtering or suppressing tenant-owned evidence until it can be scoped.

### Query Params Are UI State

**Source:** `lib/scoria_web/live/review_queue_live.ex` lines 315-330.

**Apply to:** `runtime`, `from`, `review_candidate_id`, `scope`, `outcome`, `promote`, `prompt_template_id`.

```elixir
defp validate_facet(value, allowed, default) do
  if value in allowed, do: value, else: default
end
```

Params can narrow display or select a detail candidate, but every object selected from params must be looked up under the assigned tenant.

### Browser Failure Copy

**Source:** `lib/scoria_web/live/incidents_live/show.ex` lines 49-52.

**Apply to:** dashboard unavailable/missing-scope and foreign-object pages.

```elixir
<.empty_state title="Incident not found">
  This incident either does not exist or is not available for the current tenant.
</.empty_state>
```

Use generic browser copy. Put resolver detail in docs, logs, and tests.

## No Analog Found

No file is completely without a local analog. `lib/scoria_web/dashboard_scope.ex` has no single exact existing module, but `DashboardNav` supplies the LiveView hook pattern and `Knowledge.Scope` supplies the normalization/fail-closed pattern.

## Metadata

**Analog search scope:** `lib/scoria_web`, `lib/scoria`, `test/scoria_web`, `test/scoria`, `docs`
**Files scanned:** `rg --files` over project root, narrowed to dashboard/auth/doc/test surfaces
**Pattern extraction date:** 2026-07-07
