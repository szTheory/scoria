defmodule ScoriaWeb.ApprovalsLive.Index do
  @moduledoc """
  Approvals inbox — the operator's blocking queue of tool calls awaiting a
  recorded operator decision. Extracted from the Live Ops god-page so approving
  or rejecting a gated call is a focused, linkable surface.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI,
    only: [
      badge: 1,
      drawer: 1,
      evidence_action_row: 1,
      evidence_rows: 1,
      flash_group: 1,
      id: 1,
      modal: 1,
      raw_evidence: 1,
      time: 1,
      toast: 1
    ]

  import Ecto.Query, warn: false

  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows
  alias Scoria.Workflows.Resume
  alias ScoriaWeb.ApprovalCopy
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
      if focused_runtime_query?(socket.assigns.runtime_query) and
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <div class="scoria-pagehead">
        <h1>Approvals</h1>
        <p>
          Side-effecting tool requests waiting for an operator decision. Review the policy reason, expected effect, and run evidence before approving or denying.
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
        scoria_base={assigns[:scoria_base] || ""}
      />

      <.drawer id="approval-detail-drawer" show={@active_approval != nil} on_dismiss="dismiss_approval">
        <:eyebrow>Approval required</:eyebrow>
        <:title_slot>{ApprovalCopy.title(@active_approval)}</:title_slot>

        <div :if={@active_approval} class="scoria-approval-summary">
          <p class="scoria-approval-summary__label">Decision required before this run can continue.</p>
          <p class="scoria-approval-summary__effect">{ApprovalCopy.impact(@active_approval)}</p>
        </div>

        <.evidence_rows rows={ApprovalCopy.request_rows(@active_approval)} />

        <.evidence_action_row :if={@active_approval && @active_approval[:workflow_run_id]} class="mt-2">
          <a
            href={run_href(assigns[:scoria_base] || "", @active_approval[:workflow_run_id])}
            class="scoria-button scoria-button--ghost scoria-button--sm"
          >
            Open run evidence
          </a>
        </.evidence_action_row>

        <.evidence_rows rows={ApprovalCopy.evidence_rows(@active_approval)} />

        <div :if={@active_approval} class="scoria-approval-ids" aria-label="Technical identifiers">
          <span :if={@active_approval[:id]}>
            Approval <.id value={@active_approval[:id]} id={"approval-id-#{@active_approval[:id]}"} />
          </span>
          <span :if={@active_approval[:workflow_run_id]}>
            Run <.id value={@active_approval[:workflow_run_id]} id={"approval-run-id-#{@active_approval[:id]}"} />
          </span>
          <span :if={@active_approval[:session_id]}>
            Session <.id value={@active_approval[:session_id]} id={"approval-session-id-#{@active_approval[:id]}"} />
          </span>
          <span :if={@active_approval[:inserted_at]}>
            Requested <.time at={@active_approval[:inserted_at]} />
          </span>
        </div>

        <.raw_evidence :if={@active_approval} label="Advanced: redacted request payload">
          {ApprovalCopy.raw_arguments(@active_approval)}
        </.raw_evidence>

        <p class="mt-2">
          Scoria records this decision and its audit evidence before attempting to continue the run.
        </p>

        <.evidence_action_row class="mt-6">
          <button
            type="button"
            phx-click="open_decision_modal"
            phx-value-decision="reject"
            class="scoria-button scoria-button--danger"
          >
            {ApprovalCopy.reject_label(@active_approval)}
          </button>
          <button
            type="button"
            phx-click="open_decision_modal"
            phx-value-decision="approve"
            class="scoria-button scoria-button--primary"
          >
            {ApprovalCopy.approve_label(@active_approval)}
          </button>
        </.evidence_action_row>
      </.drawer>

      <.modal id="approval-decision-modal" show={@decision_modal != nil} on_dismiss="close_decision_modal">
        <:title_slot>{ApprovalCopy.decision_title(@decision_modal, @active_approval)}</:title_slot>
        <.badge tone={decision_tone(@decision_modal)} label={decision_badge(@decision_modal)} dot={false} />
        <p>{ApprovalCopy.decision_copy(@decision_modal, @active_approval)}</p>
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
            {ApprovalCopy.reject_label(@active_approval)}
          </button>
          <button
            :if={@decision_modal == "approve"}
            type="button"
            phx-click="approve"
            class="scoria-button scoria-button--primary"
          >
            {ApprovalCopy.approve_label(@active_approval)}
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

  defp maybe_seed_active_approval(
         %{assigns: %{active_approval: nil, runtime_query: runtime_query}} = socket
       ) do
    if focused_runtime_query?(runtime_query) do
      seed_focused_active_approval(socket)
    else
      socket
    end
  end

  defp maybe_seed_active_approval(socket), do: socket

  defp seed_focused_active_approval(socket) do
    case Enum.find(
           socket.assigns.approval_inbox,
           &approval_matches_focus?(&1, socket.assigns.runtime_query)
         ) do
      nil -> socket
      projection -> assign(socket, :active_approval, projection)
    end
  end

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
              _ -> [tone: :warn, message: "Approval denied - run is still waiting for approval."]
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
    "Could not record #{status} approval decision: #{inspect(reason)}"
  end

  defp focused_runtime_query?(query) when is_binary(query), do: query != ""

  defp focused_runtime_query?(query) when is_map(query) do
    workflow_run_id = query["workflow_run_id"] || query[:workflow_run_id]
    session_id = query["session_id"] || query[:session_id]

    (is_binary(workflow_run_id) and workflow_run_id != "") or
      (is_binary(session_id) and session_id != "")
  end

  defp focused_runtime_query?(_query), do: false

  defp approval_matches_focus?(_projection, query) when query in [nil, ""], do: false

  defp approval_matches_focus?(projection, query) when is_binary(query) do
    Map.get(projection, :session_id) == query or Map.get(projection, :workflow_run_id) == query
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

  defp decision_badge("approve"), do: ApprovalCopy.decision_badge("approve")
  defp decision_badge("reject"), do: ApprovalCopy.decision_badge("reject")
  defp decision_badge(_decision), do: "Decision pending"

  defp decision_tone("approve"), do: :pass
  defp decision_tone("reject"), do: :warn
  defp decision_tone(_decision), do: :neutral

  defp run_href(_base_path, nil), do: nil
  defp run_href(base_path, run_id), do: base_path <> "/workflows/#{run_id}"
end
