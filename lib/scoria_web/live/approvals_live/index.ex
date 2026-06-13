defmodule ScoriaWeb.ApprovalsLive.Index do
  @moduledoc """
  Approvals inbox — the operator's blocking queue of tool calls awaiting a
  workflow-owned decision. Extracted from the Live Ops god-page so approving or
  rejecting a gated call is a focused, linkable surface.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI,
    only: [
      badge: 1,
      drawer: 1,
      evidence_action_row: 1,
      evidence_rows: 1,
      flash_group: 1,
      modal: 1,
      toast: 1
    ]

  import Ecto.Query, warn: false

  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows
  alias Scoria.Workflows.Resume
  alias ScoriaWeb.ApprovalInboxComponent

  @impl true
  def mount(params, session, socket) do
    tenant_id = params["tenant"] || session["tenant_id"] || "default"

    socket =
      socket
      |> assign(:page_title, "Approvals")
      |> assign(:active_approval, nil)
      |> assign(:decision_modal, nil)
      |> assign(:highlighted_approval_id, nil)
      |> assign(:approval_table_density, :compact)
      |> assign(:approval_inbox, [])
      |> assign(:runtime_query, Map.get(params, "runtime"))
      |> assign(
        :actor_id,
        session["actor_id"] || session["user_id"] || session["session_id"] || "operator"
      )
      |> assign(:tenant_id, tenant_id)
      |> assign(:toasts, [])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
    end

    {:ok, socket |> reload_inbox() |> maybe_seed_active_approval()}
  end

  @impl true
  def handle_info({:approval_decided, approval_id, _status}, socket) do
    socket =
      socket
      |> maybe_clear_active_approval(approval_id)
      |> maybe_clear_highlighted_approval(approval_id)
      |> reload_inbox()

    {:noreply, socket}
  end

  def handle_info({:hitl_request, projection}, socket) do
    socket = reload_inbox(socket)

    socket =
      if is_nil(socket.assigns.active_approval) or
           approval_matches_focus?(projection, socket.assigns.runtime_query) do
        socket
        |> assign(:active_approval, projection)
        |> assign(:highlighted_approval_id, nil)
      else
        assign(socket, :highlighted_approval_id, projection.id)
      end

    {:noreply, socket}
  end

  # Ignore the run/trace stream broadcasts the Live Ops page consumes.
  def handle_info(_message, socket), do: {:noreply, socket}

  @impl true
  def handle_event("approve", _, socket) do
    {:noreply, record_approval_decision(socket, "approved")}
  end

  def handle_event("reject", _, socket) do
    {:noreply, record_approval_decision(socket, "rejected")}
  end

  def handle_event("dismiss_approval", _, socket) do
    {:noreply, socket |> assign(:active_approval, nil) |> assign(:decision_modal, nil)}
  end

  def handle_event("select_approval", %{"id" => approval_id}, socket) do
    case Enum.find(socket.assigns.approval_inbox, &(to_string(&1.id) == approval_id)) do
      nil -> {:noreply, socket}
      approval -> {:noreply, assign(socket, :active_approval, approval)}
    end
  end

  def handle_event("open_decision_modal", %{"decision" => decision}, socket)
      when decision in ["approve", "reject"] do
    {:noreply, assign(socket, :decision_modal, decision)}
  end

  def handle_event("close_decision_modal", _, socket) do
    {:noreply, assign(socket, :decision_modal, nil)}
  end

  def handle_event("set_density", %{"density" => density}, socket) do
    density =
      case density do
        "compact" -> :compact
        "comfortable" -> :comfortable
        _ -> :default
      end

    {:noreply, assign(socket, :approval_table_density, density)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <div class="scoria-pagehead">
        <h1>Approvals</h1>
        <p>
          Operator-gated tool calls awaiting a workflow-owned decision. Select one to review its arguments and approve or reject.
        </p>
      </div>

      <.flash_group flash={@flash} />

      <div id="toast-region" class="scoria-toast-region">
        <.toast :for={t <- @toasts} id={t.id} tone={t.tone} message={t.message} duration_ms={t.duration_ms} />
      </div>

      <ApprovalInboxComponent.render
        approvals={@approval_inbox}
        highlight_approval_id={@highlighted_approval_id}
        density={@approval_table_density}
        select_event="select_approval"
      />

      <.drawer id="approval-detail-drawer" show={@active_approval != nil} on_dismiss="dismiss_approval">
        <:eyebrow>Approval detail</:eyebrow>
        <:title_slot>Approval Required</:title_slot>

        <.evidence_rows rows={approval_detail_rows(@active_approval)} />

        <.evidence_action_row :if={@active_approval && @active_approval[:workflow_run_id]} class="mt-4">
          <a
            href={(assigns[:scoria_base] || "") <> "/workflows/#{@active_approval[:workflow_run_id]}"}
            class="scoria-button scoria-button--ghost scoria-button--sm"
          >
            View workflow run
          </a>
        </.evidence_action_row>

        <p class="mt-4">
          Record a workflow-owned decision. The approval state and audit evidence are written durably before any resume attempt.
        </p>

        <.evidence_action_row class="mt-6">
          <button
            type="button"
            phx-click="open_decision_modal"
            phx-value-decision="reject"
            class="scoria-button scoria-button--danger"
          >
            Reject approval
          </button>
          <button
            type="button"
            phx-click="open_decision_modal"
            phx-value-decision="approve"
            class="scoria-button scoria-button--primary"
          >
            Approve workflow
          </button>
        </.evidence_action_row>
      </.drawer>

      <.modal id="approval-decision-modal" show={@decision_modal != nil} on_dismiss="close_decision_modal">
        <:title_slot>{decision_title(@decision_modal)}</:title_slot>
        <.badge tone={decision_tone(@decision_modal)} label={decision_badge(@decision_modal)} dot={false} />
        <p>{decision_copy(@decision_modal)}</p>
        <:footer>
          <button type="button" phx-click="close_decision_modal" class="scoria-button scoria-button--ghost">
            Keep reviewing
          </button>
          <button
            :if={@decision_modal == "reject"}
            type="button"
            phx-click="reject"
            class="scoria-button scoria-button--danger"
          >
            Reject approval
          </button>
          <button
            :if={@decision_modal == "approve"}
            type="button"
            phx-click="approve"
            class="scoria-button scoria-button--primary"
          >
            Approve workflow
          </button>
        </:footer>
      </.modal>
    </div>
    """
  end

  # ── Internals (ported from OrchestratorLive) ───────────────────────────────

  defp reload_inbox(socket) do
    assign(
      socket,
      :approval_inbox,
      Workflows.list_pending_remote_approvals(%{tenant_id: socket.assigns.tenant_id})
    )
  end

  defp maybe_seed_active_approval(%{assigns: %{active_approval: nil}} = socket) do
    case Enum.find(
           socket.assigns.approval_inbox,
           &approval_matches_focus?(&1, socket.assigns.runtime_query)
         ) do
      nil -> socket
      projection -> assign(socket, :active_approval, projection)
    end
  end

  defp maybe_seed_active_approval(socket), do: socket

  defp record_approval_decision(socket, status) do
    case socket.assigns.active_approval do
      nil ->
        socket

      approval ->
        attrs = approval_decision_attrs(socket, approval)

        with {:ok, updated_approval} <- Workflows.approve(approval.id, status, attrs),
             {:ok, updated_socket} <- maybe_resume_approval(socket, updated_approval, status) do
          # WR-03: a rejection deliberately keeps the workflow paused, so it must not
          # report the same green ":pass / decision recorded" toast as an approval —
          # that blurs a safety-relevant distinction. Branch the toast on status.
          toast_opts =
            case status do
              "approved" -> [tone: :pass, message: "Approval granted."]
              _ -> [tone: :warn, message: "Approval rejected — workflow remains paused."]
            end

          updated_socket
          |> assign(:active_approval, nil)
          |> assign(:decision_modal, nil)
          |> reload_inbox()
          |> put_toast(toast_opts)
        else
          {:error, reason} ->
            socket
            |> put_flash(:error, approval_error_message(status, reason))
            |> put_toast(tone: :fail, message: approval_error_message(status, reason))
        end
    end
  end

  defp maybe_resume_approval(socket, _approval, status) when status != "approved",
    do: {:ok, socket}

  defp maybe_resume_approval(socket, approval, "approved") do
    case approval.workflow_run_id do
      nil -> {:ok, socket}
      run_id -> Resume.resume_run(run_id)
    end
    |> case do
      {:ok, _run} -> {:ok, socket}
      {:error, reason} -> {:error, reason}
    end
  end

  defp approval_decision_attrs(socket, approval) do
    request_event = approval_request_event(approval)

    %{
      actor_id: socket.assigns.actor_id || approval.session_id || "operator",
      tenant_id:
        socket.assigns.tenant_id || (request_event && request_event.tenant_id) || "default",
      trace_id: request_event && request_event.trace_id
    }
  end

  defp approval_request_event(approval) do
    AuditOutboxEvent
    |> where(
      [event],
      event.workflow_run_id == ^approval.workflow_run_id and
        event.event_type == "approval.requested"
    )
    |> where([event], fragment("?->>? = ?", event.redacted_refs, "approval_id", ^approval.id))
    |> order_by([event], desc: event.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp approval_error_message(_status, :not_pending) do
    "This approval was already decided by another operator."
  end

  defp approval_error_message(_status, %Ecto.StaleEntryError{}) do
    "This approval was already decided by another operator."
  end

  defp approval_error_message(status, reason) do
    "Could not #{status} approval through workflow-owned state: #{inspect(reason)}"
  end

  defp approval_matches_focus?(_projection, query) when query in [nil, ""], do: true

  defp approval_matches_focus?(projection, query) when is_binary(query) do
    projection.session_id == query or projection.workflow_run_id == query
  end

  defp approval_matches_focus?(projection, query) when is_map(query) do
    workflow_run_id = query["workflow_run_id"] || query[:workflow_run_id]
    session_id = query["session_id"] || query[:session_id]

    (is_binary(workflow_run_id) and projection.workflow_run_id == workflow_run_id) or
      (is_binary(session_id) and projection.session_id == session_id)
  end

  defp approval_matches_focus?(_projection, _query), do: false

  defp maybe_clear_active_approval(socket, approval_id) do
    if socket.assigns.active_approval && socket.assigns.active_approval.id == approval_id do
      socket
      |> assign(:active_approval, nil)
      |> assign(:decision_modal, nil)
    else
      socket
    end
  end

  defp maybe_clear_highlighted_approval(socket, approval_id) do
    if socket.assigns.highlighted_approval_id == approval_id do
      assign(socket, :highlighted_approval_id, nil)
    else
      socket
    end
  end

  defp put_toast(socket, opts) do
    toast = %{
      id: "toast-#{System.unique_integer([:positive])}",
      tone: Keyword.get(opts, :tone, :neutral),
      message: Keyword.fetch!(opts, :message),
      duration_ms: Keyword.get(opts, :duration_ms, 4000)
    }

    Phoenix.Component.update(socket, :toasts, fn toasts -> [toast | toasts] end)
  end

  defp approval_detail_rows(nil), do: []

  defp approval_detail_rows(approval) do
    [
      {"Tool", approval[:tool_name]},
      {"Reason", approval[:reason]},
      {"Arguments", approval[:arguments_preview]},
      {"Connector", approval[:connector_label] || connector_label(approval)},
      {"Workflow", approval[:workflow_run_id]},
      {"Status", approval[:status]}
    ]
  end

  defp connector_label(%{blocker_kind: "connector"}), do: "connector approval"
  defp connector_label(_approval), do: nil

  defp decision_title("approve"), do: "Approve workflow"
  defp decision_title("reject"), do: "Reject approval"
  defp decision_title(_decision), do: "Review approval"

  defp decision_badge("approve"), do: "Resume when possible"
  defp decision_badge("reject"), do: "Keep workflow paused"
  defp decision_badge(_decision), do: "Decision pending"

  defp decision_tone("approve"), do: :pass
  defp decision_tone("reject"), do: :warn
  defp decision_tone(_decision), do: :neutral

  defp decision_copy("approve") do
    "Approval resumes the workflow when possible after the durable approval event is written."
  end

  defp decision_copy("reject") do
    "Reject records a durable rejection and keeps the workflow paused. To continue, the run needs a new approval request or operator retry."
  end

  defp decision_copy(_decision), do: "Review the approval before recording a durable decision."
end
