# Phase 26: Release Gates and Approvals - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/runtime/release_gate.ex` | middleware / service | request-response | `lib/scoria/runtime.ex` | exact |
| `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | component (LiveView) | embedded UI / request-response | `lib/scoria_web/live/orchestrator_live.ex` | exact |
| `lib/scoria/workflows/prompt_release.ex` | service | event-driven / workflow | `lib/scoria/workflows.ex` | exact |

## Pattern Assignments

### `lib/scoria/runtime/release_gate.ex` (middleware / service, request-response)

**Analog:** `lib/scoria/runtime.ex` and `lib/scoria/prompt_registry.ex`

**Imports & Setup pattern** (from `lib/scoria/runtime.ex`, lines 10-15):
```elixir
  import Ecto.Query, warn: false

  alias Ecto.NoResultsError
  alias Scoria.Repo
  alias Scoria.Runtime.{Params, RunDetail, RunSummary}
```

**Core Gating & Status Check pattern** (from `lib/scoria/prompt_registry.ex`, lines 71-78):
```elixir
  def update_draft_template(%PromptTemplate{} = template, attrs) do
    if template.status != "draft" do
      changeset =
        template
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.add_error(:status, "cannot modify content fields of non-draft template")
      {:error, changeset}
    else
```

**Safe Retrieval / Error Handling pattern** (from `lib/scoria/runtime.ex`, lines 44-49):
```elixir
  def get_run(run_id) do
    {:ok, get_run!(run_id)}
  rescue
    NoResultsError -> {:error, :not_found}
  end
```

---

### `lib/scoria_web/live/prompt_live/release_workbench_live.ex` (component, embedded UI)

**Analog:** `lib/scoria_web/live/orchestrator_live.ex`

**Imports & Setup pattern** (lines 1-8):
```elixir
defmodule ScoriaWeb.OrchestratorLive do
  use Phoenix.LiveView
  import Ecto.Query, warn: false

  alias Decimal, as: D
  alias Scoria.Repo

  alias Scoria.Connectors
```

**Async Evidence Loading pattern** (lines 100-106):
```elixir
  def handle_event("load_retrieval_evidence", %{"id" => trace_id}, socket) do
    {:noreply,
     assign_async(socket, :retrieval_evidence, fn ->
       {:ok, %{retrieval_evidence: sample_evidence(trace_id)}}
     end)}
  end
```

**Async Result Rendering pattern** (lines 201-207):
```elixir
        <%= if assigns[:retrieval_evidence] do %>
          <div id="retrieval-evidence" class="mt-6">
            <.async_result :let={evidence} assign={@retrieval_evidence}>
              <:loading>Loading retrieval evidence...</:loading>
              <:failed :let={_failure}>Failed to load retrieval evidence</:failed>
              <CitationEvidenceComponent.render evidence={evidence} />
            </.async_result>
          </div>
        <% end %>
```

**Approval UI & CTA pattern** (lines 244-256):
```elixir
      <%= if @active_approval do %>
        <div id="approval-modal" class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
          <div class="bg-white p-6 rounded shadow-lg max-w-md w-full">
            <h2 class="text-xl font-bold mb-4">Approval Required</h2>
            <p class="mb-2"><strong>Tool:</strong> <%= @active_approval.tool_name %></p>
            <p class="text-sm text-stone-600">
              Record a workflow-owned decision. The approval state and audit evidence are written durably before any resume attempt.
            </p>
            <div class="flex justify-end space-x-4 mt-6">
              <button phx-click="reject" class="px-4 py-2 bg-red-500 text-white rounded">Reject Decision</button>
              <button phx-click="approve" class="px-4 py-2 bg-blue-500 text-white rounded">Approve Decision</button>
            </div>
```

---

### `lib/scoria/workflows/prompt_release.ex` (service, event-driven)

**Analog:** `lib/scoria/workflows.ex`

**Workflow Approval Request pattern** (lines 292-297):
```elixir
  def request_remote_approval(run_id, step_id, attrs) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:replay_allowed, true)

    mark_waiting_for_approval(run_id, step_id, attrs)
  end
```

**Approval Transaction & State Change pattern** (lines 436-451):
```elixir
  def approve(approval_id, status, attrs) when status in ["approved", "rejected", "expired"] do
    attrs = Map.new(attrs)

    Repo.transaction(fn repo ->
      approval = repo.get!(Approval, approval_id)
      audit_context = approval_decision_context(repo, approval, attrs)

      update_attrs =
        attrs
        |> Map.drop([:actor_id, "actor_id", :tenant_id, "tenant_id", :session_id, "session_id"])
        |> Map.put(:status, status)

      updated_approval =
        approval
        |> Approval.changeset(update_attrs)
        |> repo.update!()
```

## Shared Patterns

### Authentication & Identification
**Source:** `lib/scoria/workflows.ex`
**Apply to:** All workflow and operator actions
```elixir
  defp immutable_identity(%Run{} = run, fallback_attrs) do
    root_identity =
      Identity.normalize(%{
        actor_id: run.actor_id,
        tenant_id: run.tenant_id,
        session_id: run.session_id,
        metadata: run.metadata
      })
```

### Audit Evidence Trail
**Source:** `lib/scoria/workflows.ex`
**Apply to:** All state transitions and approvals
```elixir
      audit_outbox_event =
        SRE.insert_audit_outbox_event(repo, %{
          tenant_id: audit_context.tenant_id,
          event_type: "approval.#{status}",
          policy_class: "approval",
          # ...
        })
```

## Metadata

**Analog search scope:** `lib/scoria/`, `lib/scoria_web/live/`
**Files scanned:** 5
**Pattern extraction date:** 2026-05-19