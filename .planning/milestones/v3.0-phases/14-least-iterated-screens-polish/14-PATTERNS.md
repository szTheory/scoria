# Phase 14: Least-iterated screens polish - Pattern Map

**Mapped:** 2026-06-12  
**Files analyzed:** 22  
**Analogs found:** 22 / 22

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria_web/live/dataset_live/index.ex` | LiveView | request-response, CRUD | `lib/scoria_web/live/workflow_live/index.ex` + `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | role-match |
| `test/scoria_web/live/dataset_live/index_test.exs` | test | request-response, CRUD | `test/scoria_web/live/review_queue_live_test.exs` + `test/scoria_web/live/dataset_live/promote_component_test.exs` | role-match |
| `lib/scoria_web/dashboard_nav.ex` | navigation config | request-response | itself | exact |
| `test/scoria_web/dashboard_nav_test.exs` | test | request-response | itself | exact |
| `lib/scoria_web/router.ex` | route config | request-response | itself | exact |
| `test/scoria_web/router_test.exs` | test | request-response | `test/scoria_web/live/review_queue_live_test.exs` route harness | role-match |
| `lib/scoria_web/live/review_queue_live.ex` | LiveView | request-response, CRUD | itself + `lib/scoria_web/live/workflow_live/index.ex` | exact |
| `test/scoria_web/live/review_queue_live_test.exs` | test | request-response, CRUD | itself | exact |
| `lib/scoria_web/live/workflow_live/show.ex` | LiveView | request-response, event-driven | itself | exact |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | LiveComponent | request-response, CRUD | itself | exact |
| `test/scoria_web/live/dataset_live/promote_component_test.exs` | test | request-response, CRUD | itself | exact |
| `lib/scoria_web/live/incidents_live/index.ex` | LiveView | request-response, event-driven | itself + `lib/scoria_web/live/workflow_live/index.ex` | exact |
| `test/scoria_web/live/incidents_live_test.exs` | test | request-response, event-driven | itself | exact |
| `lib/scoria_web/components/incident_evidence_component.ex` | component | transform | `lib/scoria_web/components/remote_invocation_evidence_component.ex` + itself | role-match |
| `lib/scoria_web/live/eval_spec_live/index.ex` | LiveView | request-response, CRUD | itself | exact |
| `test/scoria_web/live/eval_spec_live/index_test.exs` | test | request-response, CRUD | itself | exact |
| `lib/scoria_web/live/prompt_live/index.ex` | LiveView | request-response, CRUD | itself | exact |
| `test/scoria_web/live/prompt_live_test.exs` | test | request-response, CRUD | itself | exact |
| `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | LiveView | request-response, event-driven | itself | exact |
| `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` | test | request-response, event-driven | itself | exact |
| `test/support/ds06_baseline.txt` | test fixture | batch | `test/scoria_web/ds06_drift_guard_test.exs` | exact |
| `assets/css/04-components.css` | CSS config | transform | `lib/scoria_web/ui.ex` component classes | role-match |

## Pattern Assignments

### `lib/scoria_web/live/dataset_live/index.ex` (LiveView, request-response + CRUD)

**Analog:** `lib/scoria_web/live/workflow_live/index.ex`, `lib/scoria_web/live/prompt_live/release_workbench_live.ex`, `lib/scoria_web/live/dataset_live/promote_component.ex`

**Imports pattern** (`workflow_live/index.ex` lines 6-12):
```elixir
use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

import Ecto.Query, warn: false
import ScoriaWeb.UI

alias Scoria.Repo
alias Scoria.Workflows.Run
```

For Dataset Builder, prefer `use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}`, `import ScoriaWeb.UI`, and `alias Scoria.Eval`. Add runtime/query aliases only if reconstructing workflow promotion context needs them.

**Mount/list pattern** (`workflow_live/index.ex` lines 14-23):
```elixir
@impl true
def mount(_params, _session, socket) do
  {:ok, socket |> assign(:page_title, "Runs") |> assign(:runs, list_runs())}
end

defp list_runs do
  Repo.all(from(r in Run, order_by: [desc: r.inserted_at], limit: 50))
rescue
  _ -> []
end
```

Dataset Builder should assign `:page_title`, load real datasets via `Eval.list_datasets/0`, split open/sealed datasets, and avoid fake rows.

**URL state / origin context pattern** (`release_workbench_live.ex` lines 49-57, 344-363):
```elixir
@impl true
def handle_params(params, _uri, socket) do
  {:noreply,
   assign(
     socket,
     :origin_context,
     origin_context(params["from"], socket.assigns[:scoria_base] || "")
   )}
end

defp origin_context(from, base_path) when is_binary(from) do
  case String.split(from, ":", parts: 2) do
    [noun, id] when noun in @origin_nouns and id != "" ->
      %{noun: noun, id: id, path: origin_path(noun, id, base_path)}

    _ ->
      nil
  end
end
```

Dataset Builder should parse `promote`, `review_candidate_id`, `run_id`, `step_id`, and `source_variant` in `handle_params/3`. Use patch semantics for same-LiveView drawer state and navigate only from source screens.

**Review promotion reconstruction pattern** (`eval/review_queue.ex` lines 39-45, 209-241):
```elixir
def get_candidate(nil), do: nil

def get_candidate(candidate_id) do
  case Repo.get(OnlineScoreCandidate, candidate_id) do
    nil -> nil
    candidate -> project_detail(candidate)
  end
end

defp build_promotion_context(candidate, run) do
  source_variant = map_value(candidate.promotion_snapshot, "source_variant") || "original"

  %{
    workflow_run_id: candidate.workflow_run_id,
    workflow_step_id: candidate.workflow_step_id,
    source_variant: source_variant,
    provenance: %{
      workflow_run_id: candidate.workflow_run_id,
      workflow_step_id: candidate.workflow_step_id,
      source_variant: source_variant,
      execution_mode: run && run.execution_mode || "live"
    },
    promotion_snapshot: candidate.promotion_snapshot || %{},
    notes: "",
    expected_output: %{}
  }
end
```

Use `Eval.get_review_candidate/1` for `promote=review`; it already returns `promotion_context`.

**Workflow promotion reconstruction pattern** (`workflow_live/show.ex` lines 349-369, 400-433):
```elixir
defp assign_selection(socket, step_id) do
  step = Enum.find(socket.assigns.steps, &(&1.id == step_id))
  selected_comparison = Map.get(socket.assigns.comparison_by_step, step_id)

  selected_comparison_entry =
    selected_comparison_entry(selected_comparison, socket.assigns.selected_source_variant)

  socket
  |> assign(:selected_step_id, step_id)
  |> assign(:selected_step, step)
  |> assign(:selected_comparison_entry, selected_comparison_entry)
  |> assign(:promotion_context, promotion_context(selected_comparison_entry))
end

defp promotion_context(selected_entry) do
  provenance = Map.get(selected_entry, :provenance, %{})
  checkpoint_output = Map.get(selected_entry, :checkpoint_output, %{})
  safety = Map.get(selected_entry, :safety, %{})
  promotion_snapshot = Map.get(selected_entry, :promotion_snapshot, %{})

  %{
    workflow_run_id: workflow_run_id,
    workflow_step_id: workflow_step_id,
    source_variant: source_variant,
    provenance: provenance,
    checkpoint_output: checkpoint_output,
    safety: safety,
    promotion_snapshot: promotion_snapshot,
    notes: "",
    expected_output: %{}
  }
end
```

Dataset Builder may need to extract this private workflow reconstruction into a shared helper or duplicate it narrowly. Keep URLs to stable IDs only; do not encode `promotion_snapshot` or expected-output JSON in query params.

**Shared component shell pattern** (`ui.ex` lines 111-132, 390-403, 792-930):
```elixir
<.panel variant={:flat} class="scoria-panel--flush">
  <:title>Dataset Builder</:title>
  <.table id="datasets" rows={@datasets} density={:compact}>
    <:empty>
      <.empty_state title="No datasets yet">
        Dataset snapshots will appear here after real promotion records exist.
      </.empty_state>
    </:empty>
    <:col :let={dataset} label="Dataset" key={:name}>{dataset.name}</:col>
  </.table>
</.panel>
```

**Promotion drawer/modal embedding pattern** (`workflow_live/show.ex` lines 291-304 + `ui.ex` lines 463-517):
```elixir
<.drawer id="dataset-promote-drawer" show={@promotion_context != nil} on_dismiss="close_promote">
  <:eyebrow>Dataset Builder</:eyebrow>
  <:title_slot>Promote traced evidence</:title_slot>
  <.live_component
    module={ScoriaWeb.DatasetLive.PromoteComponent}
    id="dataset-builder-promote"
    promotion_context={@promotion_context}
    scoria_base={assigns[:scoria_base] || ""}
  />
</.drawer>
```

### `lib/scoria_web/dashboard_nav.ex` (navigation config, request-response)

**Analog:** itself

**Nav SSOT pattern** (lines 47-70):
```elixir
%{
  label: "Improve",
  items: [
    %{
      key: :reviews,
      label: "Review Queue",
      path: "/reviews",
      icon: :flag,
      aliases: ["review", "reviews", "queue"]
    },
    %{
      key: :evals,
      label: "Eval Workbench",
      path: "/eval_specs",
      icon: :grid,
      aliases: ["eval", "evals", "evaluation"]
    }
  ]
}
```

Add Dataset Builder after Review Queue and before Eval Workbench with a real `path: "/datasets"`, not `soon?: true`.

**Active key / shortcut / base stripping pattern** (lines 127-149, 231-260, 268-280):
```elixir
@views %{
  ScoriaWeb.ReviewQueueLive => :reviews,
  ScoriaWeb.EvalSpecLive.Index => :evals,
  ScoriaWeb.PromptLive.Index => :prompts
}

@g_chords %{
  reviews: "g q",
  evals: "g e",
  prompts: "g p"
}

defp strip_known_prefixes(path) do
  path
  |> String.replace(
    ~r{/(workflows|prompts|reviews|eval_specs|approvals|connectors|incidents|coming)(/.*)?$},
    ""
  )
end
```

Add `ScoriaWeb.DatasetLive.Index => :datasets`, `datasets: "g d"`, and `datasets` to `strip_known_prefixes/1`.

### `lib/scoria_web/router.ex` (route config, request-response)

**Analog:** itself

**Dashboard route pattern** (lines 34-47):
```elixir
live_session :scoria_dashboard,
  root_layout: {ScoriaWeb.Layouts, :root},
  on_mount: ScoriaWeb.DashboardNav do
  live("/", ScoriaWeb.OrchestratorLive, :index)
  live("/approvals", ScoriaWeb.ApprovalsLive.Index, :index)
  live("/reviews", ScoriaWeb.ReviewQueueLive, :index)
  live("/workflows", ScoriaWeb.WorkflowLive.Index, :index)
  live("/incidents", ScoriaWeb.IncidentsLive.Index, :index)
  live("/eval_specs", ScoriaWeb.EvalSpecLive.Index, :index)
  live("/prompts", ScoriaWeb.PromptLive.Index, :index)
end
```

Add `live("/datasets", ScoriaWeb.DatasetLive.Index, :index)` inside this live session.

### `lib/scoria_web/live/review_queue_live.ex` (LiveView, request-response + CRUD)

**Analog:** itself

**Current data/event pattern to preserve** (lines 7-33, 46-55):
```elixir
def mount(params, _session, socket) do
  filters = %{
    "review_status" => Map.get(params, "review_status", "pending"),
    "severity" => Map.get(params, "severity", ""),
    "promotion_state" => Map.get(params, "promotion_state", "")
  }

  {:ok,
   socket
   |> assign(:page_title, "Review Queue")
   |> assign(:filters, filters)
   |> assign(:selected_candidate_id, Map.get(params, "review_candidate_id"))
   |> refresh_queue()}
end

def handle_event("change_filters", %{"filters" => params}, socket) do
  {:noreply, socket |> assign(:filters, params) |> refresh_queue()}
end

def handle_event("dismiss_candidate", _params, socket) do
  with %{} = candidate <- socket.assigns.selected_candidate,
       {:ok, updated} <- Eval.dismiss_review_candidate(candidate.id) do
    {:noreply, socket |> assign(:notice, "Candidate dismissed") |> refresh_queue()}
  end
end
```

Keep single-LiveView master/detail triage and form-level `phx-change`; remove direct dataset target selection and direct promote/baseline submit affordances from this UI.

**Source link pattern** (lines 348-375):
```elixir
defp review_run_path(candidate, base) do
  query =
    URI.encode_query([
      {"review_candidate_id", candidate.id},
      {"from", review_origin(candidate)}
    ])

  "#{base}/workflows/#{candidate.workflow_run_id}?#{query}"
end

defp review_origin(candidate), do: "review:#{candidate.id}"
```

Add Dataset Builder links with the same `URI.encode_query/1` style:
`#{base}/datasets?promote=review&review_candidate_id=#{candidate.id}&from=review:#{candidate.id}`.

**Shared component conversion pattern** (`ui.ex` lines 60-74, 135-149, 521-552, 792-930):
```elixir
<.metric label="Flagged items" value={to_string(@summary.total_flagged)} />
<.field id="review-state" label="Review state">
  <select id="review-state" name="filters[review_status]" class="scoria-input">...</select>
</.field>
<.table id="review-queue" rows={@queue_rows} density={:compact}>
  <:col :let={row} label="Candidate" key={:rationale}>{row.rationale}</:col>
  <:action :let={row}>
    <button phx-click="select_candidate" phx-value-id={row.id}>Select</button>
  </:action>
</.table>
```

Selected row state must include explicit selected text/badge and/or `aria-current`, not color alone.

### `lib/scoria_web/live/workflow_live/show.ex` (LiveView, request-response + event-driven)

**Analog:** itself

**Minimum-touch promote affordance pattern** (lines 128-140, 291-304):
```elixir
<button
  type="button"
  phx-click="open_promote_next_step"
  phx-value-step-id={@selected_step_id || ""}
  disabled={promote_span_disabled?(@selected_step_id, @promotion_context)}
  class="scoria-button scoria-button--primary scoria-button--sm"
>
  Promote span to dataset
</button>
```

Replace the source-local modal with a link/navigate to Dataset Builder. Preserve `promote_span_disabled?/2`, `@selected_step_id`, and `@selected_source_variant`.

**URL builder pattern to copy from origin helpers** (lines 509-521):
```elixir
defp prompt_release_path(prompt_id, run, base_path) do
  "#{base_path}/prompts/#{prompt_id}/release?#{origin_query("run", run.id)}"
end

defp origin_query(noun, id), do: URI.encode_query([{"from", "#{noun}:#{id}"}])
```

Use `URI.encode_query/1` for `/datasets?promote=workflow&run_id=...&step_id=...&source_variant=...&from=run:...`.

### `lib/scoria_web/live/dataset_live/promote_component.ex` (LiveComponent, CRUD)

**Analog:** itself

**Stateful update pattern** (lines 9-40):
```elixir
def update(assigns, socket) do
  promotion_context = assigns[:promotion_context] || %{}
  form_params = socket.assigns[:form_params] || initial_form_params(promotion_context)
  {open_datasets, sealed_datasets} = load_dataset_groups()

  {:ok,
   socket
   |> assign(assigns)
   |> assign(:promotion_context, promotion_context)
   |> assign(:open_datasets, open_datasets)
   |> assign(:sealed_datasets, sealed_datasets)
   |> assign(:form_params, form_params)
   |> assign(:form, to_form(promotion_form(form_params), as: "promotion"))}
end
```

Keep the component as the promotion behavior owner. Convert its raw palette markup to shared UI components when embedding it in Dataset Builder.

**Promotion save/error pattern** (lines 76-130):
```elixir
with true <- changeset.valid?,
     {:ok, expected_output} <- decode_expected_output(get_field(changeset, :expected_output)),
     dataset_id when is_integer(dataset_id) <- get_field(changeset, :dataset_id),
     promotion_attrs <-
       Eval.DatasetPromotion.build_promotion_attrs(
         socket.assigns.promotion_context,
         dataset_id,
         get_field(changeset, :notes),
         expected_output
       ),
     {:ok, _item} <- Eval.promote_workflow_source(promotion_attrs) do
  send(self(), {:promote_successful, %{dataset_name: dataset.name}})
  {:noreply, socket}
else
  {:error, %Jason.DecodeError{}} ->
    {:noreply, assign_form(socket, params, add_error(changeset, :expected_output, "must be valid JSON"))}

  {:error, %Ecto.Changeset{} = result_changeset} ->
    {:noreply, socket |> refresh_datasets() |> assign_form(params, add_error(changeset, :dataset_id, message))}
end
```

**Baseline approval pattern** (lines 133-193):
```elixir
with true <- changeset.valid?,
     %{} = dataset <- baseline_target,
     {:ok, expected_output} <- decode_expected_output(get_field(changeset, :expected_output)),
     request_attrs <-
       Eval.DatasetPromotion.build_promotion_attrs(
         socket.assigns.promotion_context,
         dataset.id,
         get_field(changeset, :notes),
         expected_output
       ),
     {:ok, _approval} <- Workflows.request_baseline_promotion(request_attrs) do
  send(self(), {:baseline_promotion_requested, %{dataset_name: dataset.name, dataset_version: dataset.version}})
  {:noreply, socket}
end
```

Do not alter sealed-baseline mutation rules.

### `lib/scoria_web/live/incidents_live/index.ex` (LiveView, event-driven)

**Analog:** itself

**Mount/selection pattern** (lines 16-31, 34-47):
```elixir
def mount(params, session, socket) do
  tenant_id = (is_map(params) && params["tenant"]) || session["tenant_id"] || "default"
  incidents = OperatorSurface.list_tenant_incidents(tenant_id)
  selected = List.first(incidents)

  socket =
    socket
    |> assign(:incidents, incidents)
    |> assign(:summary, OperatorSurface.incidents_summary(tenant_id))
    |> assign(:selected_incident, selected)
    |> assign(:incident_evidence, evidence_for(selected))

  {:ok, socket}
end

def handle_event("select_incident", %{"id" => id}, socket) do
  case Enum.find(socket.assigns.incidents, &(to_string(&1.id) == id)) do
    nil -> {:noreply, socket}
    incident -> {:noreply, socket |> assign(:selected_incident, incident) |> assign(:incident_evidence, evidence_for(incident))}
  end
end
```

Preserve selection and origin links while converting list shell to `<.panel>`, `<.table>` or tokenized list controls, `<.metric>`, and `<.badge>`.

**Origin-preserving link pattern** (lines 149-161):
```elixir
defp incident_run_path(incident, base) do
  query = URI.encode_query([{"from", incident_origin(incident)}])
  "#{base}/workflows/#{incident.workflow_run_id}?#{query}"
end

defp incident_trace_path(incident, base) do
  query = URI.encode_query([{"from", incident_origin(incident)}])
  "#{home_path(base)}?#{query}#traces-#{URI.encode_www_form(to_string(incident.trace_id))}"
end
```

### `lib/scoria_web/components/incident_evidence_component.ex` (component, transform)

**Analog:** `lib/scoria_web/components/remote_invocation_evidence_component.ex` + itself

**Component import/attr pattern** (`remote_invocation_evidence_component.ex` lines 1-8):
```elixir
defmodule ScoriaWeb.RemoteInvocationEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI, only: [notebook: 1]

  attr :evidence, :map, required: true
  attr :selected_tab, :string, default: "remote_invocation"
  attr :on_tab_change, :string, default: nil
```

**Notebook shell pattern** (`remote_invocation_evidence_component.ex` lines 14-39):
```elixir
<.notebook
  id="remote-invocation-notebook"
  title="Remote invocation evidence"
  eyebrow="Remote evidence notebook"
  selected_tab={@selected_tab}
  on_tab_change={@on_tab_change}
>
  <:tab key="remote_invocation" label="Remote">
    <div class="space-y-3">...</div>
  </:tab>
</.notebook>
```

Convert IncidentEvidenceComponent into a thin local notebook/panel adapter. Preserve the current data contract and sections from lines 29-169: health rollup, budget, incident notebook, breaker/relay, and notification delivery outcomes.

### `lib/scoria_web/live/eval_spec_live/index.ex` (LiveView, CRUD)

**Analog:** itself

**Backed event pattern** (lines 22-80):
```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:page_title, "Eval Workbench")
   |> assign(:eval_specs, Eval.list_eval_specs())
   |> assign(:eval_runs, list_eval_runs())
   |> assign(:edit_spec, nil)
   |> assign(:form, nil)}
end

def handle_event("save", %{"eval_spec" => spec_params}, socket) do
  case Eval.update_eval_spec(spec, parsed_params) do
    {:ok, _new_spec} ->
      {:noreply, socket |> assign(:edit_spec, nil) |> assign(:eval_specs, Eval.list_eval_specs())}

    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, :form, to_form(changeset))}
  end
end
```

Convert markup only; preserve edit/save/cancel behavior and JSON rubric handling.

**Quality-loop link pattern** (lines 198-207):
```elixir
defp prompt_release_path(run, base_path) do
  "#{base_path}/prompts/#{run.prompt_template_id}/release?#{origin_query(run)}"
end

defp regressed_runs_path(run, base_path) do
  run_id = run |> regressed_run_ids() |> List.first()
  "#{base_path}/workflows/#{run_id}?#{origin_query(run)}"
end

defp origin_query(run), do: URI.encode_query([{"from", "eval:#{run.id}"}])
```

Preserve these next-step links.

### `lib/scoria_web/live/prompt_live/index.ex` (LiveView, CRUD)

**Analog:** itself

**Backed edit/token pattern** (lines 19-77):
```elixir
def handle_event("validate", %{"prompt_template" => template_params}, socket) do
  template = socket.assigns.edit_template

  changeset =
    template
    |> PromptTemplate.changeset(template_params)
    |> Map.put(:action, :validate)

  system_msg = Ecto.Changeset.get_field(changeset, :system_message) || ""
  user_msg = Ecto.Changeset.get_field(changeset, :user_template) || ""
  estimated_tokens = Tokenizer.estimate_tokens(system_msg <> "\n" <> user_msg)

  {:noreply, socket |> assign(:form, to_form(changeset)) |> assign(:estimated_tokens, estimated_tokens)}
end
```

Convert table/form shell to shared components; keep edit, validate, token estimate, save, and draft update behavior.

### `lib/scoria_web/live/prompt_live/release_workbench_live.ex` (LiveView, event-driven)

**Analog:** itself

**Object header/origin pattern** (lines 166-178, 344-363):
```elixir
<.object_header
  parent_label="Prompt Registry"
  parent_path={(assigns[:scoria_base] || "") <> "/prompts"}
  object_type="Prompt"
  object_id={@draft.id}
  status={prompt_release_status(@draft)}
  key_scalar={"v#{@draft.version}"}
  origin={@origin_context}
/>
```

Keep this pattern and convert comparison deck, notices, approval rail, and modals to shared components.

**Approval event pattern** (lines 102-164):
```elixir
def handle_event("request_release", _params, socket) do
  case PromptRelease.start_release_workflow(draft_id, actor_id) do
    {:ok, _} ->
      {:noreply, assign(socket, pending_approval: fetch_pending_approval(draft_id))}

    _ ->
      {:noreply, assign(socket, rejection_notice: "Failed to request release.")}
  end
end

def handle_event("approve_release", _params, socket) do
  if approval do
    case PromptRelease.approve(approval.id, "approved", %{actor_id: actor_id}) do
      {:ok, _} -> {:noreply, assign(socket, show_approve_modal: false, approval_notice: "Prompt Release Approved.")}
      _ -> {:noreply, assign(socket, show_approve_modal: false, rejection_notice: "Failed to approve.")}
    end
  end
end
```

**Next-step link pattern** (lines 182-197, 365-373):
```elixir
<a :if={@draft_run} href={eval_results_path(@draft_run, @draft, assigns[:scoria_base] || "")}>
  View eval results
</a>

defp eval_results_path(eval_run, draft, base_path) do
  query =
    URI.encode_query([
      {"prompt_template_id", eval_run.prompt_template_id},
      {"from", "prompt:#{draft.id}"}
    ])

  "#{base_path}/eval_specs?#{query}#eval-run-#{eval_run.id}"
end
```

Do not add steppers or experiment controls.

## Test Pattern Assignments

### LiveView route harness tests

**Analog:** `test/scoria_web/live/review_queue_live_test.exs` lines 1-26, 47-63, 196-200
```elixir
defmodule ScoriaWeb.ReviewQueueLiveTest.Router do
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

setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  start_supervised!(ScoriaWeb.ReviewQueueLiveTest.Endpoint)
end
```

Use this for `dataset_live/index_test.exs`, router coverage if needed, and route/nav integration tests that depend on `scoria_dashboard("/scoria")`.

### Isolated LiveView tests

**Analog:** `test/scoria_web/live/eval_spec_live/index_test.exs` lines 53-63, 100-105
```elixir
conn =
  Phoenix.ConnTest.build_conn()
  |> Plug.Test.init_test_session(%{})
  |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.EvalSpecLive.IndexTest.Endpoint)

{:ok, view, html} = live_isolated(conn, ScoriaWeb.EvalSpecLive.Index)
```

Use isolated tests for pure screen markup/event preservation where full dashboard route behavior is not under test.

### Promotion behavior tests

**Analog:** `test/scoria_web/live/dataset_live/promote_component_test.exs` lines 97-132, 213-240
```elixir
view
|> element("button[phx-click='select_open_dataset'][phx-value-dataset-id='#{open_dataset.id}']")
|> render_click()

render_submit(element(view, "form"), %{
  "promotion" => %{
    "dataset_id" => "#{open_dataset.id}",
    "notes" => "operator note",
    "expected_output" => ~s({"result":"success"})
  }
})

assert render(view) =~ "promote:original:Draft QA:1.0"
```

Dataset Builder index tests should add coverage for `promote=review`, invalid/stale IDs, and workflow URL context while continuing to rely on PromoteComponent tests for form internals.

### Navigation tests

**Analog:** `test/scoria_web/dashboard_nav_test.exs` lines 66-96, 98-105
```elixir
sections = DashboardNav.command_sections("/scoria")
navigate = Enum.find(sections, &(&1.label == "Navigate"))
nav_labels = DashboardNav.groups() |> Enum.flat_map(& &1.items) |> Enum.map(& &1.label)

assert Enum.map(navigate.rows, & &1.label) == nav_labels

assert %{label: "Runs", path: "/scoria/workflows", aliases: aliases, kbd: "g r"} =
         Enum.find(navigate.rows, &(&1.label == "Runs"))
```

Add assertions for Dataset Builder label/order, `/scoria/datasets`, aliases, `g d`, active key, and that `stub_screen("dataset-builder") == nil`.

## Shared Patterns

### Shared UI Components

**Source:** `lib/scoria_web/ui.ex`  
**Apply to:** all Phase 14 LiveViews/components

Use these component APIs instead of raw Tailwind palette classes:

```elixir
<.badge tone={tone(status)} label={status_label(status)} />
<.button variant={:primary} size={:sm} phx-click="save">Save</.button>
<.panel variant={:flat}><:title>...</:title>...</.panel>
<.metric label="Open incidents" value={to_string(@summary.open)} />
<.empty_state title="No incidents">...</.empty_state>
<.drawer id="..." show={@show} on_dismiss="close">...</.drawer>
<.modal id="..." show={@show} on_dismiss="close">...</.modal>
<.field id="..." label="..."><select class="scoria-input">...</select></.field>
<.notebook id="..." title="..." selected_tab={@selected_tab}>...</.notebook>
<.table id="..." rows={@rows} density={:compact}>...</.table>
```

Relevant definitions:
- `badge/1`: `ui.ex` lines 60-74
- `button/1`: `ui.ex` lines 76-99
- `panel/1`: `ui.ex` lines 111-132
- `metric/1`: `ui.ex` lines 135-149
- `empty_state/1`: `ui.ex` lines 390-403
- `drawer/1`: `ui.ex` lines 463-517
- `field/1`: `ui.ex` lines 521-552
- `notebook/1`: `ui.ex` lines 679-771
- `table/1`: `ui.ex` lines 792-930

### Error and Validation

**Source:** `lib/scoria_web/live/dataset_live/promote_component.ex` and `lib/scoria/eval/dataset_promotion.ex`  
**Apply to:** Dataset Builder promotion params and promotion form

```elixir
defp validate_expected_output(changeset) do
  validate_change(changeset, :expected_output, fn :expected_output, value ->
    case decode_expected_output(value) do
      {:ok, _map} -> []
      {:error, _reason} -> [expected_output: "must be valid JSON"]
    end
  end)
end
```

```elixir
defp ensure_required_keys!(attrs) do
  Enum.each(@required_keys, fn key ->
    if Map.get(attrs, Atom.to_string(key)) == nil do
      raise ArgumentError, "missing required workflow promotion attribute #{key}"
    end
  end)
end
```

For route params, prefer calm empty/error states over raising on stale IDs. For form internals, preserve existing changeset errors.

### DS-06 Ratchet

**Source:** `test/scoria_web/ds06_drift_guard_test.exs` and `test/support/ds06_baseline.txt`  
**Apply to:** all touched Phase 14 screen/component files

```elixir
baseline_count = Map.get(baseline, path, 0)

cond do
  baseline_count == 0 and count > 0 -> {path, count, 0, :new_violation}
  count > baseline_count -> {path, count, baseline_count, :regression}
  true -> nil
end
```

Current in-scope baseline rows:

```text
lib/scoria_web/components/incident_evidence_component.ex:69
lib/scoria_web/live/dataset_live/promote_component.ex:68
lib/scoria_web/live/incidents_live/index.ex:10
lib/scoria_web/live/prompt_live/release_workbench_live.ex:37
lib/scoria_web/live/review_queue_live.ex:76
```

Lower or remove these rows as conversion reduces raw-palette matches. Do not add palette usage to new `dataset_live/index.ex`.

## No Analog Found

No file lacks an analog. The weakest match is `lib/scoria_web/live/dataset_live/index.ex` because it is a new canonical screen, but the repo already has the necessary patterns split across route-level LiveViews, origin-context object pages, the existing promotion LiveComponent, and Eval context APIs.

## Metadata

**Analog search scope:** `lib/scoria_web`, `lib/scoria/eval*`, `test/scoria_web`, `test/support`, `assets/css`  
**Files scanned:** 140+ via `rg --files`; 20 focused analog/target files read with line numbers  
**Pattern extraction date:** 2026-06-12
