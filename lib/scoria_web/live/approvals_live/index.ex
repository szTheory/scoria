defmodule ScoriaWeb.ApprovalsLive.Index do
  @moduledoc """
  Approvals inbox — the operator's blocking queue of tool calls awaiting a
  workflow-owned decision. Extracted from the Live Ops god-page so approving or
  rejecting a gated call is a focused, linkable surface.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI, only: [flash_group: 1, toast: 1]

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
      |> assign(:highlighted_approval_id, nil)
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
    {:noreply, assign(socket, :active_approval, nil)}
  end

  def handle_event("select_approval", %{"id" => approval_id}, socket) do
    case Enum.find(socket.assigns.approval_inbox, &(to_string(&1.id) == approval_id)) do
      nil -> {:noreply, socket}
      approval -> {:noreply, assign(socket, :active_approval, approval)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <div class="scoria-pagehead">
        <h1>Approvals</h1>
        <p class="text-stone-600 mt-1">
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
        select_event="select_approval"
      />

      <%= if @active_approval do %>
        <div id="approval-modal" class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
          <div class="bg-white p-6 rounded shadow-lg max-w-md w-full">
            <h2 class="text-xl font-bold mb-4">Approval Required</h2>
            <p class="mb-2"><strong>Tool:</strong> <%= @active_approval[:tool_name] %></p>
            <p :if={@active_approval[:reason]} class="mb-2 text-sm text-stone-700">
              <strong>Reason:</strong> <%= @active_approval[:reason] %>
            </p>
            <p :if={@active_approval[:arguments_preview] not in [nil, %{}]} class="mb-2 text-sm text-stone-700">
              <strong>Arguments:</strong>
              <span class="font-mono text-xs block mt-1 whitespace-pre-wrap break-all"><%= inspect(@active_approval[:arguments_preview]) %></span>
            </p>
            <span
              :if={@active_approval[:connector_label] || @active_approval[:blocker_kind] == "connector"}
              class="inline-block mb-3 rounded-full border border-stone-200 bg-stone-50 px-3 py-1 text-xs font-medium text-stone-700"
            >
              <%= @active_approval[:connector_label] || "connector approval" %>
            </span>
            <a
              :if={@active_approval[:workflow_run_id]}
              href={(assigns[:scoria_base] || "") <> "/workflows/#{@active_approval[:workflow_run_id]}"}
              class="text-sm text-blue-700 underline block mb-4"
            >
              View workflow run
            </a>
            <p class="text-sm text-stone-600">
              Record a workflow-owned decision. The approval state and audit evidence are written durably before any resume attempt.
            </p>
            <div class="flex justify-end gap-3 mt-6">
              <button phx-click="dismiss_approval" class="scoria-button scoria-button--ghost">Decide later</button>
              <button phx-click="reject" class="scoria-button scoria-button--danger">Reject decision</button>
              <button phx-click="approve" class="scoria-button scoria-button--primary">Approve decision</button>
            </div>
            <p class="mt-4 text-xs text-stone-500">
              Reject records a durable rejection and keeps the workflow paused. To continue, the run needs a new approval request or operator retry.
            </p>
          </div>
        </div>
      <% end %>
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
      assign(socket, :active_approval, nil)
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
end
