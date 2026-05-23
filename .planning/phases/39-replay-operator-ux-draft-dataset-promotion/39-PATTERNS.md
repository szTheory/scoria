# Phase 39: replay-operator-ux-draft-dataset-promotion - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria_web/live/workflow_live/show.ex` | liveview | request-response | `lib/scoria_web/live/workflow_live/show.ex` | exact |
| `lib/scoria_web/components/workflow_detail_panel_component.ex` | component | request-response | `lib/scoria_web/components/workflow_detail_panel_component.ex` | exact |
| `lib/scoria_web/components/replay_evidence_notebook_component.ex` | component | transform | `lib/scoria_web/components/incident_evidence_component.ex` | role-match |
| `test/scoria_web/live/workflow_live_test.exs` | test | request-response | `test/scoria_web/live/workflow_live_test.exs` | exact |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | component | request-response | `lib/scoria_web/live/dataset_live/promote_component.ex` | exact |
| `lib/scoria/eval.ex` | service | CRUD | `lib/scoria/eval.ex` | exact |
| `lib/scoria/workflows/dataset_promotion.ex` | service | transform | `lib/scoria/workflows/prompt_release.ex` | partial |
| `test/scoria_web/live/dataset_live/promote_component_test.exs` | test | request-response | `test/scoria_web/live/dataset_live/promote_component_test.exs` | exact |
| `test/scoria/eval_test.exs` | test | CRUD | `test/scoria/eval_test.exs` | exact |
| `lib/scoria/workflows.ex` | service | event-driven | `lib/scoria/workflows.ex` | exact |
| `lib/scoria/workflows/remote_approval_projection.ex` | service | request-response | `lib/scoria/workflows/remote_approval_projection.ex` | exact |
| `lib/scoria/runtime/run_detail.ex` | model | transform | `lib/scoria/runtime/run_detail.ex` | exact |
| `test/scoria/workflows/remote_approval_projection_test.exs` | test | request-response | `test/scoria/workflows/remote_approval_projection_test.exs` | exact |
| `test/scoria/workflows_test.exs` | test | event-driven | `test/scoria/workflows_test.exs` | exact |
| `test/scoria/runtime_view_test.exs` | test | transform | `test/scoria/runtime_view_test.exs` | exact |

## Pattern Assignments

### `lib/scoria_web/live/workflow_live/show.ex` (liveview, request-response)

**Analog:** `lib/scoria_web/live/workflow_live/show.ex`

**Imports + mount/subscription** ([lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:1)):
```elixir
defmodule ScoriaWeb.WorkflowLive.Show do
  use Phoenix.LiveView

  alias Scoria.Runtime
  alias Scoria.SRE
  alias Scoria.Workflows
  alias ScoriaWeb.{MemoryNotebookComponent, RemoteInvocationEvidenceComponent, WorkflowDetailPanelComponent}
  alias ScoriaWeb.WorkflowTreeComponent

  @impl true
  def mount(%{"id" => run_id}, _session, socket) do
    if connected?(socket) do
      Workflows.subscribe_run(run_id)
    end
```

**Async assign + reload pattern** (lines 16-23):
```elixir
socket =
  socket
  |> load_run(run_id)
  |> assign_async(:compacted_memories, fn ->
    {:ok, %{compacted_memories: Runtime.list_compacted_memories_for_run(run_id)}}
  end)

{:ok, socket}
```

**Event and modal state pattern** (lines 27-45):
```elixir
def handle_event("select_step", %{"id" => step_id}, socket) do
  {:noreply, assign_selection(socket, step_id)}
end

def handle_event("open_promote_modal", %{"step-id" => step_id}, socket) do
  {:noreply, assign(socket, :promote_step_id, step_id)}
end

def handle_info({:workflow_updated, run_id}, socket), do: {:noreply, load_run(socket, run_id)}
```

**Render composition pattern** (lines 67-118):
```elixir
<div class="grid gap-6 lg:grid-cols-[minmax(0,1.2fr)_minmax(20rem,0.8fr)]">
  <section class="rounded-2xl border border-stone-200 bg-white shadow-sm">
    <WorkflowTreeComponent.workflow_tree steps={@steps} selected_step_id={@selected_step_id} />
  </section>

  <WorkflowDetailPanelComponent.workflow_detail_panel step={@selected_step} checkpoint={@selected_checkpoint} />
</div>

<RemoteInvocationEvidenceComponent.render
  :if={@remote_invocation_evidence.approvals != []}
  evidence={@remote_invocation_evidence}
/>

<.live_component
  module={ScoriaWeb.DatasetLive.PromoteComponent}
  id="promote-component"
  step={Enum.find(@steps, &(&1.id == @promote_step_id))}
/>
```

**Selection helper pattern** (lines 125-158):
```elixir
defp load_run(socket, run_id) do
  run = Workflows.get_run_tree!(run_id)
  steps = decorate_steps(run.steps)
  selected_step_id = socket.assigns[:selected_step_id] || default_step_id(steps)

  socket
  |> assign(:run, run)
  |> assign(:steps, steps)
  |> assign(:events, run.events)
  |> assign(:remote_invocation_evidence, SRE.remote_invocation_evidence(run_id))
  |> assign_new(:promote_step_id, fn -> nil end)
  |> assign_selection(selected_step_id)
end
```

Use this same posture for the replay strip and comparison toggle: derive assigns in helpers, keep HEEx declarative.

---

### `lib/scoria_web/components/workflow_detail_panel_component.ex` (component, request-response)

**Analog:** `lib/scoria_web/components/workflow_detail_panel_component.ex`

**Component contract** ([lib/scoria_web/components/workflow_detail_panel_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/workflow_detail_panel_component.ex:1)):
```elixir
defmodule ScoriaWeb.WorkflowDetailPanelComponent do
  use Phoenix.Component

  attr :step, :map, default: nil
  attr :checkpoint, :map, default: nil
```

**Button-to-parent event pattern** (lines 11-20):
```elixir
<button
  type="button"
  phx-click="open_promote_modal"
  phx-value-step-id={@step.id}
  class="rounded-md bg-stone-100 px-3 py-1.5 text-sm font-medium text-stone-700 hover:bg-stone-200"
>
  Promote to Dataset
</button>
```

**Current detail block to replace/curate** (lines 22-42):
```elixir
<dl class="mt-4 space-y-2 text-sm">
  <div>
    <dt class="font-medium text-stone-600">Projected Context</dt>
    <dd class="workflow-projected-context whitespace-pre-wrap font-mono text-xs"><%= inspect(@step.projected_context) %></dd>
  </div>
  <div :if={@checkpoint}>
    <dt class="font-medium text-stone-600">Checkpoint</dt>
    <dd class="workflow-checkpoint-metadata whitespace-pre-wrap font-mono text-xs"><%= inspect(@checkpoint.snapshot) %></dd>
  </div>
</dl>
```

Phase 39 should keep the same shell and CTA, but swap `inspect/1` blobs for structured replay/evidence sections.

---

### `lib/scoria_web/components/replay_evidence_notebook_component.ex` (component, transform)

**Analog:** `lib/scoria_web/components/incident_evidence_component.ex`

**Imports/attr pattern** ([lib/scoria_web/components/incident_evidence_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/incident_evidence_component.ex:1)):
```elixir
defmodule ScoriaWeb.IncidentEvidenceComponent do
  use Phoenix.Component

  attr(:evidence, :map, required: true)
```

**Notebook header + metadata chips** (lines 8-26):
```elixir
<section class="rounded-xl border border-stone-200 bg-stone-50 p-4 shadow-sm">
  <div class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
    <div>
      <p class="text-xs uppercase tracking-[0.24em] text-stone-500">incident evidence</p>
      <h3 class="text-lg font-semibold text-stone-900">Trace-first incident notebook</h3>
    </div>

    <div class="flex flex-wrap gap-2 text-xs text-stone-700">
      <span class="rounded-full border border-stone-300 bg-white px-3 py-1">
        trace <span class="font-mono"><%= @evidence.trace_id %></span>
      </span>
    </div>
  </div>
```

**Two-column notebook body pattern** (lines 60-169):
```elixir
<div class="mt-4 grid gap-4 xl:grid-cols-[1.25fr,0.9fr]">
  <div class="space-y-4">
    <div class="rounded-lg border border-stone-200 bg-white p-4">
      <h4 class="text-sm font-semibold text-stone-900">Incident notebook</h4>
      <div class="mt-3 space-y-3">
        <article :for={incident <- @evidence.incidents} class="rounded-lg border border-stone-200 p-3">
```

**Badge helper pattern** (lines 173-190):
```elixir
defp badge_class(value, kind) do
  base = "rounded-full px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em]"
  tone =
    case {kind, value} do
      {:severity, "critical"} -> "border border-rose-200 bg-rose-50 text-rose-800"
      _ -> "border border-emerald-200 bg-emerald-50 text-emerald-800"
    end

  [base, tone]
end
```

Use this for the replay provenance strip/notebook visual language rather than extending `workflow_detail_panel_component.ex` into a single long `dl`.

---

### `test/scoria_web/live/workflow_live_test.exs` (test, request-response)

**Analog:** `test/scoria_web/live/workflow_live_test.exs`

**Mount/setup pattern:** tests live under a local router/endpoint and use persisted workflow records before `live/2` (test names at lines 58, 89, 115, 207).

**Concrete behaviors already locked in:**
- mount from persisted run tree
- react to `Workflows.complete_step/2`
- render durable remote approval evidence
- open the promotion modal from a selected step

Add Phase 39 assertions in this file rather than creating a new LiveView test module.

---

### `lib/scoria_web/live/dataset_live/promote_component.ex` (component, request-response)

**Analog:** `lib/scoria_web/live/dataset_live/promote_component.ex`

**Imports/update pattern** ([lib/scoria_web/live/dataset_live/promote_component.ex](/Users/jon/projects/scoria/lib/scoria_web/live/dataset_live/promote_component.ex:1)):
```elixir
defmodule ScoriaWeb.DatasetLive.PromoteComponent do
  use Phoenix.LiveComponent
  import Ecto.Changeset
  alias Scoria.Eval

  @impl true
  def update(assigns, socket) do
    step = assigns[:step] || %{}
```

**Current dataset loading pattern** (lines 17-32):
```elixir
datasets =
  Eval.list_datasets()
  |> Enum.filter(&(&1.state == :open))

{:ok,
 socket
 |> assign(assigns)
 |> assign(:datasets, datasets)
 |> assign(:form, to_form(changeset, as: "item"))}
```

Phase 39 should replace the `open`-only filter with visible open + sealed lanes.

**Form validation pattern** (lines 36-40, 82-99):
```elixir
def handle_event("validate", %{"item" => params}, socket) do
  changeset =
    params
    |> dataset_item_form()
    |> Map.put(:action, :validate)
```

```elixir
{%{}, types}
|> cast(params, [:dataset_id, :input, :expected_output])
|> validate_required([:dataset_id, :input, :expected_output])
|> validate_json(:input)
|> validate_json(:expected_output)
```

**Current save/error shape** (lines 46-78):
```elixir
with {:ok, input_map} <- Jason.decode(input_json),
     {:ok, exp_map} <- Jason.decode(exp_json) do
  attrs = %{input: input_map, expected_output: exp_map}

  case Eval.add_dataset_item(dataset_id, attrs) do
    {:ok, _item} ->
      send(self(), {:promote_successful})
      {:noreply, socket}
    {:error, _} ->
      changeset = add_error(changeset, :dataset_id, "failed to save to dataset")
      {:noreply, assign(socket, :form, to_form(changeset, as: "item"))}
  end
end
```

Phase 39 should keep the same LiveComponent event loop, but submit a typed workflow-promotion request instead of raw JSON.

---

### `lib/scoria/eval.ex` (service, CRUD)

**Analog:** `lib/scoria/eval.ex`

**Context imports** ([lib/scoria/eval.ex](/Users/jon/projects/scoria/lib/scoria/eval.ex:1)):
```elixir
defmodule Scoria.Eval do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Scoria.Repo

  alias Scoria.Eval.Dataset
  alias Scoria.Eval.DatasetItem
```

**Dataset CRUD pattern** (lines 23-25, 36-65, 71-88):
```elixir
def list_datasets do
  Repo.all(Dataset)
end

def create_dataset(attrs \\ %{}) do
  {items, dataset_attrs} = Map.pop(attrs, :items, [])

  Ecto.Multi.new()
  |> Ecto.Multi.insert(:dataset, Dataset.changeset(%Dataset{}, attrs_with_defaults))
  |> Ecto.Multi.run(:items, fn repo, %{dataset: dataset} ->
```

```elixir
def add_dataset_item(dataset_id, attrs) do
  dataset = get_dataset!(dataset_id)

  %DatasetItem{}
  |> DatasetItem.changeset(Map.put(attrs, :dataset_id, dataset.id), dataset.state)
  |> Repo.insert()
end
```

**Existing snapshot semantics to reuse** (lines 741-760):
```elixir
defp put_dataset_snapshot!(attrs) do
  dataset_id = fetch_attr(attrs, :dataset_id)
  dataset_version = fetch_attr(attrs, :dataset_version)

  case dataset_id do
    nil ->
      attrs

    id ->
      dataset = get_dataset!(id)

      if dataset.state != :sealed do
        raise ArgumentError, "eval specs must point at sealed datasets"
      end

      put_new_attr(attrs, :dataset_version, dataset.version)
  end
end
```

Phase 39 should follow this style: centralize snapshot/immutability checks in service code, not in the LiveComponent.

---

### `lib/scoria/workflows/dataset_promotion.ex` (service, transform)

**Analog:** `lib/scoria/workflows/prompt_release.ex`

**Service shell** ([lib/scoria/workflows/prompt_release.ex](/Users/jon/projects/scoria/lib/scoria/workflows/prompt_release.ex:1)):
```elixir
defmodule Scoria.Workflows.PromptRelease do
  @moduledoc """
  Event-driven workflow service for prompt release approvals.
  """

  alias Scoria.Repo
  alias Scoria.Workflows
```

**Workflow-owned request pattern** (lines 13-33):
```elixir
def start_release_workflow(template_id, actor_id) do
  Repo.transaction(fn ->
    {:ok, run} = Workflows.create_run(%{tenant_id: "system", actor_id: actor_id, root_role_id: "operator"})
    {:ok, step} = Workflows.create_step(run.id, %{sequence: 1, kind: "tool_call", status: "running", role_id: "operator"})
    {:ok, step_or_approval} = request_remote_approval(run.id, step.id, %{tool_name: "prompt_release", arguments: %{"template_id" => template_id}})
    step_or_approval
  end)
end
```

**Approval wrapper pattern** (lines 40-63):
```elixir
def request_remote_approval(run_id, step_id, attrs) do
  attrs =
    attrs
    |> Map.new()
    |> Map.put_new(:replay_allowed, true)

  Workflows.request_remote_approval(run_id, step_id, attrs)
end
```

Use this module shape if Phase 39 adds a workflow-owned baseline-promotion approval lane. The exact mutation target changes from prompt activation to frozen dataset-promotion request persistence.

---

### `test/scoria_web/live/dataset_live/promote_component_test.exs` (test, request-response)

**Analog:** `test/scoria_web/live/dataset_live/promote_component_test.exs`

**Current isolated component test seam** ([test/scoria_web/live/dataset_live/promote_component_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/dataset_live/promote_component_test.exs:1)):
```elixir
defmodule ScoriaWeb.DatasetLive.PromoteComponentTest.DummyLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :step, %{projected_context: %{"foo" => "bar"}})}
  end
end
```

**Behavior already covered:** render initial payload, select dataset, submit form, verify persisted item (test name at line 63).

Extend this file for variant selection, sealed dataset visibility, and approval-gated baseline actions.

---

### `test/scoria/eval_test.exs` (test, CRUD)

**Analog:** `test/scoria/eval_test.exs`

**Coverage to preserve/extend:** open dataset creation, sealing, `add_dataset_item/2`, and promotion helpers (test names at lines 19, 35, 48, 56).

Use this file for:
- frozen workflow snapshot metadata assertions
- sealed dataset rejection assertions
- any new helper that builds workflow-derived dataset items

---

### `lib/scoria/workflows.ex` (service, event-driven)

**Analog:** `lib/scoria/workflows.ex`

**Imports and projection delegation** ([lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:1)):
```elixir
defmodule Scoria.Workflows do
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.Workflows.RemoteApprovalProjection
  alias Scoria.Workflows.{Checkpoint, Event, Handoff, ReplayDisposition, Run, Step}
```

**Approval request transaction** (lines 306-400):
```elixir
Repo.transaction(fn repo ->
  run = repo.get!(Run, run_id)
  step = repo.get!(Step, step_id)

  checkpoint =
    insert_checkpoint(repo, run.id, step.id, with_replay_evidence(run, attrs, %{
      transition: "waiting_for_approval",
      status: "waiting_for_approval",
      snapshot: %{reason: Map.get(attrs, :reason) || Map.get(attrs, "reason")},
      metadata: %{}
    }))

  approval =
    %Approval{}
    |> Approval.changeset(approval_attrs)
    |> repo.insert!()
```

```elixir
{:ok, {run, approval, audit_outbox_event}} ->
  SRE.emit_audit_outbox_telemetry(audit_outbox_event)
  broadcast(run.id, {:approval_requested, run.id, approval.id})
  {:ok, approval}
```

**Approval decision transaction** (lines 601-653):
```elixir
Repo.transaction(fn repo ->
  approval = repo.get!(Approval, approval_id)
  audit_context = approval_decision_context(repo, approval, attrs)

  updated_approval =
    approval
    |> Approval.changeset(update_attrs)
    |> repo.update!()

  audit_outbox_event =
    SRE.insert_audit_outbox_event(repo, %{event_type: "approval.#{status}", ...})
```

**Replay evidence merge pattern** (lines 750-804):
```elixir
attrs
|> Map.put_new(:replay_disposition, "blocked")
|> Map.put_new(:replay_scope, "replay_live")
|> Map.put_new(:replay_reason_code, Map.fetch!(replay_evidence, :replay_reason_code))
|> Map.put_new(:source_run_id, replay_evidence.source_run_id)
|> Map.put_new(:source_checkpoint_id, replay_evidence.source_checkpoint_id)
|> Map.put_new(:executed_live, false)
```

This is the exact service-level shape to copy for any sealed-baseline approval request path.

---

### `lib/scoria/workflows/remote_approval_projection.ex` (service, request-response)

**Analog:** `lib/scoria/workflows/remote_approval_projection.ex`

**Query/filter pattern** ([lib/scoria/workflows/remote_approval_projection.ex](/Users/jon/projects/scoria/lib/scoria/workflows/remote_approval_projection.ex:13)):
```elixir
def list_pending_approvals(filters \\ %{}) do
  filters = normalize_filters(filters)

  Approval
  |> where([approval], approval.status == "pending")
  |> apply_filters(filters)
  |> order_by([approval], desc: approval.inserted_at, desc: approval.id)
  |> Repo.all()
  |> Enum.map(&project_approval/1)
end
```

**Projection map pattern** (lines 39-77):
```elixir
%{
  id: approval.id,
  workflow_run_id: approval.workflow_run_id,
  status: approval.status,
  tool_name: approval.tool_name,
  replay_allowed: approval.replay_allowed,
  replay_disposition: approval.replay_disposition,
  replay_reason_code: approval.replay_reason_code,
  replay_scope: approval.replay_scope,
  source_run_id: approval.source_run_id,
  source_checkpoint_id: approval.source_checkpoint_id,
  source_step_id: approval.source_step_id,
  source_approval_id: approval.source_approval_id,
  executed_live: approval.executed_live
}
```

If baseline-promotion approvals need an operator-facing projection, mirror this explicit map style.

---

### `lib/scoria/runtime/run_detail.ex` (model, transform)

**Analog:** `lib/scoria/runtime/run_detail.ex`

**DTO shell** ([lib/scoria/runtime/run_detail.ex](/Users/jon/projects/scoria/lib/scoria/runtime/run_detail.ex:1)):
```elixir
defmodule Scoria.Runtime.RunDetail do
  @enforce_keys [:summary, :steps, :checkpoints, :events, :approvals, :handoffs]
  defstruct [:summary, :steps, :checkpoints, :events, :approvals, :handoffs]
```

**From-run projection pattern** (lines 23-31):
```elixir
def from_run_tree(%Run{} = run) do
  %__MODULE__{
    summary: RunSummary.from_run(run),
    steps: Enum.map(run.steps, &step_item/1),
    checkpoints: Enum.map(run.checkpoints, &checkpoint_item/1),
    events: Enum.map(run.events, &event_item/1),
    approvals: Enum.map(run.approvals, &approval_item/1),
    handoffs: Enum.map(run.handoffs, &handoff_item/1)
  }
end
```

**Replay field extraction pattern** (lines 47-106):
```elixir
%{
  replay_disposition: checkpoint.replay_disposition,
  replay_reason_code: checkpoint.replay_reason_code,
  source_run_id: map_value(checkpoint.metadata, "source_run_id"),
  source_checkpoint_id: map_value(checkpoint.metadata, "source_checkpoint_id"),
  replay_scope: map_value(checkpoint.metadata, "replay_scope"),
  executed_live: truthy?(map_value(checkpoint.metadata, "executed_live"))
}
```

Phase 39 should prefer adding promotion-facing fields here only if the UI truly needs new durable DTO facts.

---

### `test/scoria/workflows/remote_approval_projection_test.exs` (test, request-response)

**Analog:** `test/scoria/workflows/remote_approval_projection_test.exs`

**Coverage already present:** replay-safe inbox projection and lineage projection (test names at lines 15 and 74).

Use this file if baseline-promotion approvals get their own `tool_name` or need new projected lineage fields.

---

### `test/scoria/workflows_test.exs` (test, event-driven)

**Analog:** `test/scoria/workflows_test.exs`

**Coverage already present via named tests and assertions:**
- `mark_waiting_for_approval/3` persists wait state before projection concerns
- replay approval requests create replay-scoped blocked approvals
- approval updates preserve historical lineage

The grep hits around lines 89, 130, 192, and 244 show this is already the regression home for approval lifecycle and replay state. Add sealed-baseline approval flow tests here, not in UI tests.

---

### `test/scoria/runtime_view_test.exs` (test, transform)

**Analog:** `test/scoria/runtime_view_test.exs`

**Coverage already present:** replay summary posture, historical-stub projection, blocked replay projection, and `executed_live` facts (grep hits around lines 71, 190, 310, 398).

Only extend this file if Phase 39 requires new durable `RunDetail` fields. Do not add UI-only projection expectations here.

## Shared Patterns

### Workflow page subscription and projection reload
**Source:** [lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:11)
**Apply to:** workflow replay UX additions
```elixir
if connected?(socket) do
  Workflows.subscribe_run(run_id)
end

def handle_info({:workflow_updated, run_id}, socket), do: {:noreply, load_run(socket, run_id)}
```

### Evidence notebook layout
**Source:** [lib/scoria_web/components/incident_evidence_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/incident_evidence_component.ex:8)
**Apply to:** new replay provenance notebook component
```elixir
<section class="rounded-xl border border-stone-200 bg-stone-50 p-4 shadow-sm">
  <div class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
```

### Dataset immutability guard
**Source:** [lib/scoria/eval/dataset_item.ex](/Users/jon/projects/scoria/lib/scoria/eval/dataset_item.ex:15), [lib/scoria/eval/dataset.ex](/Users/jon/projects/scoria/lib/scoria/eval/dataset.ex:15)
**Apply to:** workflow promotion service and Eval mutations
```elixir
%DatasetItem{}
|> DatasetItem.changeset(attrs_with_fk, dataset.state)
|> Repo.insert()
```

```elixir
defp validate_dataset_state(changeset, :sealed) do
  add_error(changeset, :dataset_id, "cannot add or modify items in a sealed dataset")
end
```

### Approval-gated baseline path
**Source:** [lib/scoria/workflows/prompt_release.ex](/Users/jon/projects/scoria/lib/scoria/workflows/prompt_release.ex:13), [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:306)
**Apply to:** sealed baseline promotion requests
```elixir
{:ok, step_or_approval} = request_remote_approval(run.id, step.id, %{tool_name: "prompt_release", arguments: %{"template_id" => template_id}})
```

```elixir
{:ok, {run, approval, audit_outbox_event}} ->
  SRE.emit_audit_outbox_telemetry(audit_outbox_event)
  broadcast(run.id, {:approval_requested, run.id, approval.id})
  {:ok, approval}
```

### Replay evidence projection
**Source:** [lib/scoria/runtime/run_detail.ex](/Users/jon/projects/scoria/lib/scoria/runtime/run_detail.ex:47), [lib/scoria/workflows/remote_approval_projection.ex](/Users/jon/projects/scoria/lib/scoria/workflows/remote_approval_projection.ex:39)
**Apply to:** any new replay/original comparison view-models
```elixir
replay_disposition: checkpoint.replay_disposition,
replay_reason_code: checkpoint.replay_reason_code,
source_run_id: map_value(checkpoint.metadata, "source_run_id"),
replay_scope: map_value(checkpoint.metadata, "replay_scope"),
executed_live: truthy?(map_value(checkpoint.metadata, "executed_live"))
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | — | — | Existing workflow, approval, and evidence modules are close enough for all Phase 39 files. The only partial match is the implied workflow-owned dataset-promotion service, which should copy `PromptRelease` transaction and approval patterns. |

## Metadata

**Analog search scope:** `lib/scoria_web/live`, `lib/scoria_web/components`, `lib/scoria`, `test/scoria_web/live`, `test/scoria`

**Files scanned:** 17 read directly, with targeted grep over adjacent workflow/runtime tests

**Pattern extraction date:** 2026-05-23
