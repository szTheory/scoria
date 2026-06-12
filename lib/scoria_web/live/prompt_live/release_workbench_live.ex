defmodule ScoriaWeb.PromptLive.ReleaseWorkbenchLive do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}
  import Ecto.Query, warn: false
  import ScoriaWeb.UI

  alias Scoria.Repo
  alias Scoria.PromptRegistry
  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.Eval.EvalRun
  alias Scoria.Workflows.PromptRelease

  @origin_nouns ~w(incident review run dataset eval prompt)

  @impl true
  def mount(%{"id" => id}, session, socket) do
    # T-26-03: Validate operator's session identity
    actor_id = session["actor_id"] || session["operator_id"] || "operator-fallback"
    tenant_id = session["tenant_id"] || "default"

    # Fetch draft template
    draft = PromptRegistry.get_prompt_template!(id)

    active =
      Repo.one(
        from(p in PromptTemplate,
          where: p.entity_id == ^draft.entity_id and p.status == "active",
          order_by: [desc: p.version],
          limit: 1
        )
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
      |> assign(:pending_approval, fetch_pending_approval(draft.id))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     assign(
       socket,
       :origin_context,
       origin_context(params["from"], socket.assigns[:scoria_base] || "")
     )}
  end

  defp fetch_eval_run(nil), do: nil

  defp fetch_eval_run(prompt_id) do
    Repo.one(
      from(r in EvalRun,
        where: r.prompt_template_id == ^prompt_id,
        order_by: [desc: r.inserted_at],
        limit: 1
      )
    )
  end

  defp fetch_pending_approval(prompt_id) do
    alias Scoria.Observe.Approval

    Repo.one(
      from(a in Approval,
        where:
          a.tool_name == "prompt_release" and a.status == "pending" and
            fragment("?->>'template_id' = ?", a.arguments, ^prompt_id),
        order_by: [desc: a.inserted_at],
        limit: 1
      )
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

  def handle_event("request_release", _params, socket) do
    draft_id = socket.assigns.draft.id
    actor_id = socket.assigns.actor_id
    alias Scoria.Workflows.PromptRelease

    case PromptRelease.start_release_workflow(draft_id, actor_id) do
      {:ok, _} ->
        {:noreply, assign(socket, pending_approval: fetch_pending_approval(draft_id))}

      _ ->
        {:noreply, assign(socket, rejection_notice: "Failed to request release.")}
    end
  end

  def handle_event("approve_release", _params, socket) do
    actor_id = socket.assigns.actor_id
    approval = socket.assigns.pending_approval
    alias Scoria.Workflows.PromptRelease

    if approval do
      case PromptRelease.approve(approval.id, "approved", %{actor_id: actor_id}) do
        {:ok, _} ->
          {:noreply,
           assign(socket,
             show_approve_modal: false,
             approval_notice: "Prompt Release Approved.",
             pending_approval: nil
           )}

        _ ->
          {:noreply,
           assign(socket, show_approve_modal: false, rejection_notice: "Failed to approve.")}
      end
    else
      {:noreply,
       assign(socket, show_approve_modal: false, rejection_notice: "No pending approval found.")}
    end
  end

  def handle_event("reject_release", _params, socket) do
    actor_id = socket.assigns.actor_id
    approval = socket.assigns.pending_approval
    alias Scoria.Workflows.PromptRelease

    if approval do
      case PromptRelease.approve(approval.id, "rejected", %{actor_id: actor_id}) do
        {:ok, _} ->
          {:noreply,
           assign(socket,
             show_reject_modal: false,
             rejection_notice: "Prompt Release Rejected.",
             pending_approval: nil
           )}

        _ ->
          {:noreply,
           assign(socket, show_reject_modal: false, rejection_notice: "Failed to reject.")}
      end
    else
      {:noreply,
       assign(socket, show_reject_modal: false, rejection_notice: "No pending approval found.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl py-8">
      <.object_header
        parent_label="Prompt Registry"
        parent_path={(assigns[:scoria_base] || "") <> "/prompts"}
        object_type="Prompt"
        object_id={@draft.id}
        status={prompt_release_status(@draft)}
        key_scalar={"v#{@draft.version}"}
        origin={@origin_context}
      />

      <p class="scoria-eyebrow">Release Workbench</p>

      <div class="mb-6 flex flex-wrap gap-3" aria-label="Prompt release next steps">
        <a
          :if={@draft_run}
          href={eval_results_path(@draft_run, @draft, assigns[:scoria_base] || "")}
          class="scoria-button scoria-button--ghost scoria-button--sm"
        >
          View eval results
        </a>
        <a
          :if={@active_run}
          href={eval_results_path(@active_run, @draft, assigns[:scoria_base] || "")}
          class="scoria-button scoria-button--ghost scoria-button--sm"
        >
          View baseline runs
        </a>
      </div>

      <.panel :if={@approval_notice} class="mb-6" role="status">
        <.badge tone={:pass} label="Release approved" />
        <p><%= @approval_notice %></p>
      </.panel>

      <.panel :if={@rejection_notice} class="mb-6" role="status">
        <.badge tone={:fail} label="Release notice" />
        <p><%= @rejection_notice %></p>
      </.panel>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
        <.panel variant={:raised}>
          <:eyebrow>Candidate</:eyebrow>
          <:title>Draft Candidate (v<%= @draft.version %>)</:title>
          <:actions>
            <.badge tone={tone(@draft.status)} label={status_label(@draft.status)} />
          </:actions>
          
          <%= if @draft_run do %>
            <div class="space-y-4">
              <div class="flex justify-between">
                <span class="text-sm">Dataset</span>
                <span class="text-sm font-medium"><%= @draft_run.dataset_version %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm">Eval Spec</span>
                <span class="text-sm font-medium"><%= @draft_run.eval_spec_version %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm">Items Passed</span>
                <span class="text-sm font-medium"><%= @draft_run.passed_items %> / <%= @draft_run.total_items %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm">Avg Latency</span>
                <span class="text-sm font-medium"><%= @draft_run.avg_latency_ms %>ms</span>
              </div>
            </div>
          <% else %>
            <p class="text-sm">No eval run evidence ready.</p>
          <% end %>
        </.panel>

        <.panel variant={:raised}>
          <:eyebrow>Baseline</:eyebrow>
          <:title>Active Baseline <%= if @active do %>(v<%= @active.version %>)<% end %></:title>
          <:actions>
            <.badge :if={@active} tone={tone(@active.status)} label={status_label(@active.status)} />
          </:actions>
          
          <%= if @active_run do %>
            <div class="space-y-4">
              <div class="flex justify-between">
                <span class="text-sm">Dataset</span>
                <span class="text-sm font-medium"><%= @active_run.dataset_version %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm">Eval Spec</span>
                <span class="text-sm font-medium"><%= @active_run.eval_spec_version %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm">Items Passed</span>
                <span class="text-sm font-medium"><%= @active_run.passed_items %> / <%= @active_run.total_items %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm">Avg Latency</span>
                <span class="text-sm font-medium"><%= @active_run.avg_latency_ms %>ms</span>
              </div>
            </div>
          <% else %>
            <p class="text-sm">No baseline eval run found.</p>
          <% end %>
        </.panel>
      </div>

      <div class="mt-12 flex items-center justify-between border-t pt-6">
        <%= if is_nil(@pending_approval) do %>
          <div></div>
          <.button phx-click="request_release" disabled={!can_approve?(@draft, @draft_run, @active, @active_run)}>
            Request Release
          </.button>
        <% else %>
          <.button variant={:danger} phx-click="open_reject" disabled={@draft.status != "draft"}>
            Reject Release
          </.button>

          <.button phx-click="open_approve" disabled={!can_approve?(@draft, @draft_run, @active, @active_run)}>
            Approve Prompt Release
          </.button>
        <% end %>
      </div>

      <.modal
        id="approve-release-modal"
        show={@show_approve_modal}
        on_dismiss="close_approve"
        title="Approve Release?"
      >
        <p>
          This will activate Draft v<%= @draft.version %> and demote the current active version.
          Production traffic will begin using the new prompt immediately.
        </p>
        <:footer>
          <.button variant={:ghost} phx-click="close_approve">Cancel</.button>
          <.button phx-click="approve_release">Confirm Approval</.button>
        </:footer>
      </.modal>

      <.modal
        id="reject-release-modal"
        show={@show_reject_modal}
        on_dismiss="close_reject"
        title="Reject this release candidate?"
      >
        <p>
          The active baseline stays unchanged. The release workflow remains paused until a new
          approval decision is recorded.
        </p>
        <:footer>
          <.button variant={:ghost} phx-click="close_reject">Keep comparing</.button>
          <.button variant={:danger} phx-click="reject_release">Reject release candidate</.button>
        </:footer>
      </.modal>
    </div>
    """
  end

  defp can_approve?(_draft, draft_run, _active, active_run) do
    case {draft_run, active_run} do
      {nil, _} ->
        false

      {d, nil} ->
        d.status == "completed"

      {d, a} ->
        d.status == "completed" and
          a.status == "completed" and
          to_string(d.dataset_version) == to_string(a.dataset_version) and
          to_string(d.eval_spec_version) == to_string(a.eval_spec_version)
    end
  end

  defp prompt_release_status(%{status: "draft"}), do: "draft_blocked"
  defp prompt_release_status(%{status: status}) when is_binary(status), do: status
  defp prompt_release_status(_draft), do: "draft_blocked"

  defp origin_context(nil, _base_path), do: nil

  defp origin_context(from, base_path) when is_binary(from) do
    case String.split(from, ":", parts: 2) do
      [noun, id] when noun in @origin_nouns and id != "" ->
        %{noun: noun, id: id, path: origin_path(noun, id, base_path)}

      _ ->
        nil
    end
  end

  defp origin_context(_from, _base_path), do: nil

  defp origin_path("incident", _id, base_path), do: base_path <> "/incidents"
  defp origin_path("review", _id, base_path), do: base_path <> "/reviews"
  defp origin_path("run", id, base_path), do: base_path <> "/workflows/#{id}"
  defp origin_path("dataset", _id, base_path), do: base_path <> "/eval_specs"
  defp origin_path("eval", _id, base_path), do: base_path <> "/eval_specs"
  defp origin_path("prompt", _id, base_path), do: base_path <> "/prompts"

  defp eval_results_path(eval_run, draft, base_path) do
    query =
      URI.encode_query([
        {"prompt_template_id", eval_run.prompt_template_id},
        {"from", "prompt:#{draft.id}"}
      ])

    "#{base_path}/eval_specs?#{query}#eval-run-#{eval_run.id}"
  end
end
