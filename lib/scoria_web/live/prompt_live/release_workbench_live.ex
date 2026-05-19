defmodule ScoriaWeb.PromptLive.ReleaseWorkbenchLive do
  use Phoenix.LiveView
  import Ecto.Query, warn: false

  alias Scoria.Repo
  alias Scoria.PromptRegistry
  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.Eval.EvalRun
  alias Scoria.Workflows.PromptRelease

  @impl true
  def mount(%{"id" => id}, session, socket) do
    # T-26-03: Validate operator's session identity
    actor_id = session["actor_id"] || session["operator_id"] || "operator-fallback"
    tenant_id = session["tenant_id"] || "default"

    # Fetch draft template
    draft = PromptRegistry.get_prompt_template!(id)
    
    active =
      Repo.one(
        from p in PromptTemplate,
          where: p.entity_id == ^draft.entity_id and p.status == "active",
          order_by: [desc: p.version],
          limit: 1
      )

    socket =
      socket
      |> assign(:actor_id, actor_id)
      |> assign(:tenant_id, tenant_id)
      |> assign(:draft, draft)
      |> assign(:active, active)
      |> assign(:rejection_notice, nil)
      |> assign(:approval_notice, nil)
      |> assign(:show_approve_modal, false)
      |> assign(:show_reject_modal, false)
      |> assign(:draft_run, fetch_eval_run(draft.id))
      |> assign(:active_run, fetch_eval_run(if active, do: active.id, else: nil))

    {:ok, socket}
  end

  defp fetch_eval_run(nil), do: nil
  defp fetch_eval_run(prompt_id) do
    Repo.one(
      from r in EvalRun,
        where: r.prompt_template_id == ^prompt_id,
        order_by: [desc: r.inserted_at],
        limit: 1
    )
  end

  @impl true
  def handle_event("open_approve", _params, socket) do
    {:noreply, assign(socket, show_approve_modal: true)}
  end

  def handle_event("close_approve", _params, socket) do
    {:noreply, assign(socket, show_approve_modal: false)}
  end

  def handle_event("open_reject", _params, socket) do
    {:noreply, assign(socket, show_reject_modal: true)}
  end

  def handle_event("close_reject", _params, socket) do
    {:noreply, assign(socket, show_reject_modal: false)}
  end

  def handle_event("approve_release", _params, socket) do
    # TBD: approve release logic via PromptRelease.approve
    {:noreply, assign(socket, show_approve_modal: false, approval_notice: "Prompt Release Approved.")}
  end

  def handle_event("reject_release", _params, socket) do
    # TBD: reject release logic via PromptRelease.approve
    {:noreply, assign(socket, show_reject_modal: false, rejection_notice: "Prompt Release Rejected.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl py-8">
      <!-- Status Strip -->
      <div class="mb-6 flex items-center gap-4 border-b border-stone-200 pb-4">
        <h1 class="text-xl font-semibold">Release Workbench</h1>
        <%= if @draft.status == "draft" do %>
          <span class="inline-flex items-center rounded bg-amber-100 px-2 py-0.5 text-xs font-medium text-amber-800">
            Draft blocked
          </span>
        <% else %>
          <span class="inline-flex items-center rounded bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-800">
            Active
          </span>
        <% end %>
      </div>

      <%= if @approval_notice do %>
        <div class="mb-6 rounded-md bg-emerald-50 p-4 border border-emerald-200">
          <p class="text-sm text-emerald-800"><%= @approval_notice %></p>
        </div>
      <% end %>

      <%= if @rejection_notice do %>
        <div class="mb-6 rounded-md bg-rose-50 p-4 border border-rose-200">
          <p class="text-sm text-rose-800"><%= @rejection_notice %></p>
        </div>
      <% end %>

      <!-- Comparison Deck -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
        <!-- Draft Column -->
        <div class="rounded-xl border border-stone-200 bg-white shadow-sm p-4">
          <h2 class="text-sm font-semibold uppercase tracking-wider text-stone-500 mb-4">Draft Candidate (v<%= @draft.version %>)</h2>
          
          <%= if @draft_run do %>
            <div class="space-y-4">
              <div class="flex justify-between">
                <span class="text-sm text-stone-600">Dataset</span>
                <span class="text-sm font-medium"><%= @draft_run.dataset_version %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm text-stone-600">Eval Spec</span>
                <span class="text-sm font-medium"><%= @draft_run.eval_spec_version %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm text-stone-600">Items Passed</span>
                <span class="text-sm font-medium"><%= @draft_run.passed_items %> / <%= @draft_run.total_items %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm text-stone-600">Avg Latency</span>
                <span class="text-sm font-medium"><%= @draft_run.avg_latency_ms %>ms</span>
              </div>
            </div>
          <% else %>
            <p class="text-sm text-stone-500">No eval run evidence ready.</p>
          <% end %>
        </div>

        <!-- Active Column -->
        <div class="rounded-xl border border-stone-200 bg-white shadow-sm p-4">
          <h2 class="text-sm font-semibold uppercase tracking-wider text-stone-500 mb-4">Active Baseline <%= if @active do %>(v<%= @active.version %>)<% end %></h2>
          
          <%= if @active_run do %>
            <div class="space-y-4">
              <div class="flex justify-between">
                <span class="text-sm text-stone-600">Dataset</span>
                <span class="text-sm font-medium"><%= @active_run.dataset_version %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm text-stone-600">Eval Spec</span>
                <span class="text-sm font-medium"><%= @active_run.eval_spec_version %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm text-stone-600">Items Passed</span>
                <span class="text-sm font-medium"><%= @active_run.passed_items %> / <%= @active_run.total_items %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm text-stone-600">Avg Latency</span>
                <span class="text-sm font-medium"><%= @active_run.avg_latency_ms %>ms</span>
              </div>
            </div>
          <% else %>
            <p class="text-sm text-stone-500">No baseline eval run found.</p>
          <% end %>
        </div>
      </div>

      <!-- Approval Rail -->
      <div class="mt-12 flex items-center justify-between border-t border-stone-200 pt-6">
        <button phx-click="open_reject" class="px-4 py-2 text-sm font-medium text-rose-600 hover:bg-rose-50 rounded" disabled={@draft.status != "draft"}>
          Reject Release
        </button>

        <button phx-click="open_approve" class="px-4 py-2 text-sm font-medium bg-blue-600 text-white hover:bg-blue-700 rounded disabled:opacity-50 disabled:cursor-not-allowed" disabled={!can_approve?(@draft, @draft_run, @active, @active_run)}>
          Approve Prompt Release
        </button>
      </div>

      <!-- Approve Modal -->
      <%= if @show_approve_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
          <div class="w-full max-w-md rounded-xl bg-white p-6 shadow-lg">
            <h3 class="mb-4 text-lg font-semibold">Approve Release?</h3>
            <p class="mb-6 text-sm text-stone-600">
              This will activate Draft v<%= @draft.version %> and demote the current active version.
              Production traffic will begin using the new prompt immediately.
            </p>
            <div class="flex justify-end gap-3">
              <button phx-click="close_approve" class="px-4 py-2 text-sm text-stone-600 hover:bg-stone-50 rounded">Cancel</button>
              <button phx-click="approve_release" class="px-4 py-2 text-sm font-medium bg-blue-600 text-white hover:bg-blue-700 rounded">Confirm Approval</button>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Reject Modal -->
      <%= if @show_reject_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
          <div class="w-full max-w-md rounded-xl bg-white p-6 shadow-lg">
            <h3 class="mb-4 text-lg font-semibold">Reject this draft release?</h3>
            <p class="mb-6 text-sm text-stone-600">
              Production traffic will stay on the current active prompt and the workflow will remain paused until a new approval decision is recorded.
            </p>
            <div class="flex justify-end gap-3">
              <button phx-click="close_reject" class="px-4 py-2 text-sm text-stone-600 hover:bg-stone-50 rounded">Cancel</button>
              <button phx-click="reject_release" class="px-4 py-2 text-sm font-medium bg-rose-600 text-white hover:bg-rose-700 rounded">Confirm Rejection</button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp can_approve?(_draft, draft_run, _active, active_run) do
    case {draft_run, active_run} do
      {nil, _} -> false
      {d, nil} ->
        d.status == "completed"
      {d, a} ->
        d.status == "completed" and
          a.status == "completed" and
          to_string(d.dataset_version) == to_string(a.dataset_version) and
          to_string(d.eval_spec_version) == to_string(a.eval_spec_version)
    end
  end
end
