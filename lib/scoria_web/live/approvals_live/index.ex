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
      evidence_section: 1,
      flash_group: 1,
      id: 1,
      modal: 1,
      page_header: 1,
      raw_evidence: 1,
      time: 1,
      tone: 1,
      toast: 1
    ]

  import Ecto.Query, warn: false

  alias Phoenix.LiveView.JS
  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows
  alias Scoria.Workflows.Resume
  alias ScoriaWeb.ApprovalCopy
  alias ScoriaWeb.ApprovalInboxComponent

  # D-17: single /approvals page, Pending|Decided URL-param scope segment (default
  # Pending) + an outcome sub-filter inside Decided (D-24d maps the display word to
  # the schema status value at the query boundary — see outcome_status/1).
  @scopes ~w(pending decided)
  @outcomes ~w(all approved denied expired)
  @decided_page_size 25

  @impl true
  def mount(params, _session, socket) do
    tenant_id = socket.assigns.tenant_id

    socket =
      socket
      |> assign(:page_title, "Approvals")
      |> assign(:active_approval, nil)
      |> assign(:active_approval_receipt, nil)
      |> assign(:decision_modal, nil)
      |> assign(:highlighted_approval_id, nil)
      |> assign(:approval_inbox, [])
      |> assign(:decision_receipts, %{})
      |> assign(:runtime_query, Map.get(params, "runtime"))
      |> assign(:actor_id, dashboard_actor_id(socket))
      |> assign(:tenant_id, tenant_id)
      |> assign(:toasts, [])
      |> assign(:scope, "pending")
      |> assign(:outcome, "all")
      |> assign(:decided_limit, @decided_page_size)
      |> assign(:runtime_seeded?, false)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
    end

    {:ok, socket}
  end

  # D-09: shareable scan state (scope, outcome sub-filter, and the drawer selection)
  # lives in the URL via push_patch + handle_params, so it survives reconnect and is
  # deep-linkable. Ephemeral UI state (decision_modal toggle, toasts, highlighted id)
  # stays in assigns and is untouched here.
  @impl true
  def handle_params(params, _uri, socket) do
    new_scope = normalize_scope(params["scope"])
    new_outcome = normalize_outcome(params["outcome"])

    scope_or_outcome_changed? =
      new_scope != socket.assigns.scope or new_outcome != socket.assigns.outcome

    socket =
      socket
      |> assign(:scope, new_scope)
      |> assign(:outcome, new_outcome)

    socket =
      if scope_or_outcome_changed? do
        assign(socket, :decided_limit, @decided_page_size)
      else
        socket
      end

    socket =
      socket
      |> reload_inbox()
      |> assign_active_approval(params["approval"])

    # The runtime-focused auto-open is a one-shot seed for the LiveView's initial
    # mount, mirroring the original mount-time-only behavior — it must NOT
    # re-trigger on every subsequent patch (e.g. a user's explicit dismiss),
    # which would otherwise immediately reopen the drawer it was told to close.
    socket =
      if new_scope == "pending" and not socket.assigns.runtime_seeded? do
        socket |> maybe_seed_active_approval() |> assign(:runtime_seeded?, true)
      else
        socket
      end

    {:noreply, socket}
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
        |> put_active_approval(projection)
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
    {:noreply,
     socket
     |> assign(:decision_modal, nil)
     |> push_patch(
       to: approvals_path(socket.assigns[:scoria_base] || "", patch_params(socket, %{}))
     )}
  end

  # D-09: selection is a deep-linkable URL param, not a socket-only assign — the
  # actual assignment happens in handle_params/3 once the patch lands.
  def handle_event("select_approval", %{"id" => approval_id}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         approvals_path(
           socket.assigns[:scoria_base] || "",
           patch_params(socket, %{"approval" => approval_id})
         )
     )}
  end

  def handle_event("open_decision_modal", %{"decision" => decision}, socket)
      when decision in ["approve", "reject"] do
    {:noreply, assign(socket, :decision_modal, decision)}
  end

  def handle_event("close_decision_modal", _, socket) do
    {:noreply, assign(socket, :decision_modal, nil)}
  end

  # D-17/D-24d: outcome sub-filter inside Decided scope, applied via table/1's
  # :filter slot. The display word ("Denied") is mapped to the schema status value
  # ("rejected") at the query boundary in outcome_status/1, never inline here.
  def handle_event("change_outcome", %{"outcome" => outcome}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         approvals_path(socket.assigns[:scoria_base] || "", %{
           "scope" => "decided",
           "outcome" => normalize_outcome(outcome)
         })
     )}
  end

  # D-10: decided history is capped + load-more (no table/1 stream upgrade) rather
  # than a URL param, since it is pure pagination convenience, not shareable filter
  # state.
  def handle_event("load_more_decided", _, socket) do
    {:noreply,
     socket
     |> assign(:decided_limit, socket.assigns.decided_limit + @decided_page_size)
     |> reload_inbox()}
  end

  @impl true
  def render(assigns) do
    # CR-01 (phase 40 review): the decision modal renders on top of the still-mounted
    # approval drawer (the drawer intentionally stays open behind the confirm modal).
    # Both modal/1 and drawer/1 attach a window-scoped Escape listener, so without this
    # gate a single Escape while the modal is open fires BOTH close_decision_modal and
    # dismiss_approval — ejecting the operator from the drawer and dropping the
    # ?approval= deep-link instead of just cancelling the confirm. Compute the "modal is
    # topmost" condition once and share it between the modal's `show` and the drawer's
    # `keydown_enabled` so they can never fall out of sync.
    assigns =
      assign(
        assigns,
        :decision_modal_open?,
        assigns.decision_modal != nil && !decided?(assigns.active_approval)
      )

    ~H"""
    <div class="scoria-dashboard relative">
      <.page_header title="Approvals">
        <:summary>
          Requests that need a person to decide before Scoria continues. Review what will happen, then approve or deny.
        </:summary>
      </.page_header>

      <.flash_group flash={@flash} />

      <div id="toast-region" class="scoria-toast-region">
        <.toast :for={t <- @toasts} id={t.id} tone={t.tone} message={t.message} duration_ms={t.duration_ms} />
      </div>

      <ApprovalInboxComponent.render
        approvals={@approval_inbox}
        highlight_approval_id={@highlighted_approval_id}
        select_event="select_approval"
        scoria_base={assigns[:scoria_base] || ""}
        scope={@scope}
        outcome={@outcome}
        pending_href={approvals_path(assigns[:scoria_base] || "", %{})}
        decided_href={approvals_path(assigns[:scoria_base] || "", %{"scope" => "decided"})}
        has_more={@scope == "decided" and length(@approval_inbox) >= @decided_limit}
        decision_receipts={@decision_receipts}
      />

      <.drawer
        id="approval-detail-drawer"
        show={@active_approval != nil}
        on_dismiss="dismiss_approval"
        keydown_enabled={!@decision_modal_open?}
      >
        <:eyebrow>{ApprovalCopy.eyebrow(@active_approval)}</:eyebrow>
        <:title_slot>{ApprovalCopy.title(@active_approval)}</:title_slot>

        <section :if={@active_approval} class="scoria-approval-decision">
          <.badge
            tone={tone(ApprovalCopy.field(@active_approval, :status))}
            label={ApprovalCopy.status_line(@active_approval)}
          />

          <p :if={!decided?(@active_approval)} class="scoria-approval-summary__effect">{ApprovalCopy.impact(@active_approval)}</p>

          <%!-- D-19/D-20/D-27: the decided receipt states only the RECORDED
                DECISION (audit-event-sourced decider/time via
                @active_approval_receipt) — never that the tool side-effect or
                run continuation succeeded. --%>
          <p :if={decided?(@active_approval)} class="scoria-approval-summary__effect">{@active_approval_receipt}</p>

          <div
            :if={!decided?(@active_approval)}
            class="scoria-approval-actions"
            aria-label="Approval actions"
          >
            <%!-- D-15: Deny is the safe, reversible hold — it keeps the run
                  paused, nothing irreversible happens. Approve is the
                  irreversible action, so it alone carries --primary emphasis;
                  Deny stays neutral/ghost rather than --danger so red chrome
                  isn't mistaken for the higher-risk choice. --%>
            <button
              type="button"
              phx-click={JS.push_focus() |> JS.push("open_decision_modal")}
              phx-value-decision="reject"
              class="scoria-button scoria-button--ghost"
            >
              {ApprovalCopy.reject_label(@active_approval)}
            </button>
            <button
              type="button"
              phx-click={JS.push_focus() |> JS.push("open_decision_modal")}
              phx-value-decision="approve"
              class="scoria-button scoria-button--primary"
            >
              {ApprovalCopy.approve_label(@active_approval)}
            </button>
          </div>

          <%!-- D-18: a legitimate re-decision offers "Start a new request"
                routing to the origin run — never a re-approve. No decision
                affordances are emitted once an approval is decided. --%>
          <div
            :if={decided?(@active_approval) && @active_approval[:workflow_run_id]}
            class="scoria-approval-actions"
            aria-label="Decision receipt"
          >
            <a
              href={run_href(assigns[:scoria_base] || "", @active_approval[:workflow_run_id])}
              class="scoria-button scoria-button--ghost scoria-button--sm"
            >
              Start a new request
            </a>
          </div>
        </section>

        <.evidence_section :if={@active_approval} title="What you're approving">
          <.evidence_rows rows={ApprovalCopy.request_rows(@active_approval)} />
          <.evidence_rows rows={ApprovalCopy.evidence_rows(@active_approval)} />
        </.evidence_section>

        <details
          :if={@active_approval}
          id={"approval-identifiers-#{@active_approval[:id]}"}
        >
          <summary>Identifiers</summary>
          <dl>
            <div :if={@active_approval[:id]}>
              <dt>Approval</dt>
              <dd><.id value={@active_approval[:id]} id={"approval-id-#{@active_approval[:id]}"} /></dd>
            </div>
            <div :if={@active_approval[:workflow_run_id]}>
              <dt>Run</dt>
              <dd><.id value={@active_approval[:workflow_run_id]} id={"approval-run-id-#{@active_approval[:id]}"} /></dd>
            </div>
            <div :if={@active_approval[:session_id]}>
              <dt>Session</dt>
              <dd><.id value={@active_approval[:session_id]} id={"approval-session-id-#{@active_approval[:id]}"} /></dd>
            </div>
            <div :if={@active_approval[:trace_id]}>
              <dt>Trace</dt>
              <dd><.id value={@active_approval[:trace_id]} id={"approval-trace-id-#{@active_approval[:id]}"} /></dd>
            </div>
            <div :if={@active_approval[:inserted_at]}>
              <dt>Requested</dt>
              <dd><.time at={@active_approval[:inserted_at]} /></dd>
            </div>
          </dl>
        </details>

        <.raw_evidence
          :if={@active_approval}
          id={"approval-raw-#{@active_approval[:id]}"}
          label="Request payload"
          value={ApprovalCopy.raw_arguments(@active_approval)}
          open={false}
          copyable={true}
          copy_label="Copy request payload"
        >
        </.raw_evidence>

        <.evidence_action_row :if={@active_approval && @active_approval[:workflow_run_id]} class="mt-2">
          <a
            href={run_href(assigns[:scoria_base] || "", @active_approval[:workflow_run_id])}
            class="scoria-button scoria-button--ghost scoria-button--sm"
          >
            View run details
          </a>
        </.evidence_action_row>
      </.drawer>

      <.modal
        id="approval-decision-modal"
        show={@decision_modal_open?}
        on_dismiss="close_decision_modal"
      >
        <:title_slot>{ApprovalCopy.decision_title(@decision_modal, @active_approval)}</:title_slot>
        <.badge tone={decision_tone(@decision_modal)} label={decision_badge(@decision_modal)} dot={false} />
        <p>{decision_confirm_copy(@decision_modal, @active_approval)}</p>
        <:footer>
          <button type="button" phx-click="close_decision_modal" class="scoria-button scoria-button--ghost">
            Keep reviewing
          </button>
          <%!-- D-15: Deny stays neutral/ghost here too — see the drawer action
                comment above for the risk-gradient rationale. --%>
          <button
            :if={@decision_modal == "reject"}
            type="button"
            phx-click="reject"
            class="scoria-button scoria-button--ghost"
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

  # D-10: decided history loads via list_decided_approvals/1 (capped + load-more);
  # the pending inbox stays PubSub-reload driven with assign-based lookups — do NOT
  # stream it (see seed_focused_active_approval/1, select handling below).
  #
  # D-20: decided-at/decider SSOT is the decision AuditOutboxEvent, batch-loaded
  # by the visible id-set (a single query, not one per row) to avoid N+1.
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
    assign(
      socket,
      :approval_inbox,
      Workflows.list_pending_remote_approvals(%{tenant_id: socket.assigns.tenant_id})
    )
  end

  defp decision_receipts_for(approvals, events_by_approval_id) do
    Map.new(approvals, fn approval ->
      {ApprovalCopy.field(approval, :id),
       decision_receipt_text(
         approval,
         Map.get(events_by_approval_id, ApprovalCopy.field(approval, :id))
       )}
    end)
  end

  # D-20: missing event -> "Decided · time unavailable", never "unknown" and
  # never a fabricated actor/time. ApprovalCopy.decision_receipt/3 (Plan 03,
  # locked) is the SSOT for the "have decider+time" vs "bare outcome word"
  # cases; this function owns only the "no event at all" fallback.
  defp decision_receipt_text(_approval, nil), do: "Decided · time unavailable"

  defp decision_receipt_text(approval, event) do
    ApprovalCopy.decision_receipt(
      ApprovalCopy.field(approval, :status),
      decider_ref(event),
      format_decided_at(event.inserted_at)
    )
  end

  # ⚠ SAFETY (D-20/D-27, T-39-07-R): Workflows.approve/3 (pre-existing,
  # lib/scoria/workflows.ex, out of this plan's files_modified scope) writes
  # the decision AuditOutboxEvent's `actor_ref` from the run/approval's
  # IMMUTABLE ROOT identity (the original requester) — the SAME value the
  # `approval.requested` event's actor_ref carries — NOT the operator who
  # actually recorded THIS decision. The real decision-time actor is captured
  # separately as `event.metadata["metadata"]["decision_actor_id"]` (verified
  # against a live `approve/3` write). Reading bare `actor_ref` here would
  # silently misattribute every decision to the requester — the exact
  # repudiation defect D-20/T-39-07-R exist to prevent — so the decider is
  # sourced from the metadata field first, falling back to actor_ref only if
  # that field is absent (defensive compat with any older/malformed event).
  defp decider_ref(event) do
    get_in(event.metadata, ["metadata", "decision_actor_id"]) || event.actor_ref
  end

  defp format_decided_at(nil), do: nil
  defp format_decided_at(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
  defp format_decided_at(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")

  # D-20: batch-load by the visible id-set (single `in ^ids` query) rather than
  # one approval_decision_event/1 call per row — the history-table analog of
  # approval_decision_event/1 below.
  defp decision_events_by_approval_id([]), do: %{}

  defp decision_events_by_approval_id(approvals) do
    ids = Enum.map(approvals, &to_string(ApprovalCopy.field(&1, :id)))

    AuditOutboxEvent
    |> where([event], event.event_type in ^decision_event_types())
    |> where([event], fragment("?->>?", event.redacted_refs, "approval_id") in ^ids)
    |> order_by([event], desc: event.inserted_at)
    |> Repo.all()
    |> Enum.reduce(%{}, fn event, acc ->
      # ORDER BY desc inserted_at + Map.put_new keeps the most recent decision
      # event per approval id (there is normally exactly one terminal decision
      # event per approval; defensive against any duplicate).
      Map.put_new(acc, get_in(event.redacted_refs, ["approval_id"]), event)
    end)
  end

  defp decision_event_types, do: Enum.map(~w(approved rejected expired), &"approval.#{&1}")

  defp maybe_put_outcome_status(filters, outcome) do
    case outcome_status(outcome) do
      nil -> filters
      status -> Map.put(filters, :status, status)
    end
  end

  # D-24d: the outcome facet maps to the schema status value for the query, NOT the
  # display word — "Denied" -> "rejected" (ApprovalCopy.decision_outcome/1 owns the
  # "Denied" display label; the schema value is "rejected"). "All" applies no
  # status constraint.
  defp outcome_status("approved"), do: "approved"
  defp outcome_status("denied"), do: "rejected"
  defp outcome_status("expired"), do: "expired"
  defp outcome_status(_outcome), do: nil

  defp normalize_scope(scope) when scope in @scopes, do: scope
  defp normalize_scope(_scope), do: "pending"

  defp normalize_outcome(outcome) when outcome in @outcomes, do: outcome
  defp normalize_outcome(_outcome), do: "all"

  # D-09/T-39-07-I: the deep-link selection is resolved against the currently
  # loaded (already tenant-scoped) inbox first; if the id isn't in the current
  # scope's page, fall back to a tenant-scoped lineage lookup so a decided-scope
  # link still opens correctly from a pending-scope URL and vice versa, but never
  # across tenants.
  defp assign_active_approval(socket, approval_id)
       when is_binary(approval_id) and approval_id != "" do
    put_active_approval(socket, resolve_scoped_approval(socket, approval_id))
  end

  defp assign_active_approval(socket, _approval_id), do: put_active_approval(socket, nil)

  # D-19/D-20/D-27: every place :active_approval is assigned routes through
  # here so the audit-sourced decided receipt (:active_approval_receipt) never
  # drifts out of sync with which approval is open.
  defp put_active_approval(socket, nil) do
    socket
    |> assign(:active_approval, nil)
    |> assign(:active_approval_receipt, nil)
  end

  defp put_active_approval(socket, approval) do
    socket
    |> assign(:active_approval, approval)
    |> assign(:active_approval_receipt, decided_receipt_for(approval))
  end

  defp decided_receipt_for(approval) do
    if decided?(approval) do
      decision_receipt_text(approval, approval_decision_event(approval))
    else
      nil
    end
  end

  # D-20: single-approval analog of decision_events_by_approval_id/1 above,
  # mirroring approval_request_event/1 but matching the decision event type
  # "approval.<status>" and reading inserted_at (decided-at) / actor_ref
  # (decider) — NOT updated_at and NOT get_approval_lineage!'s requesting actor.
  defp approval_decision_event(approval) do
    AuditOutboxEvent
    |> where(
      [event],
      event.workflow_run_id == ^ApprovalCopy.field(approval, :workflow_run_id) and
        event.event_type in ^decision_event_types()
    )
    |> where(
      [event],
      fragment(
        "?->>? = ?",
        event.redacted_refs,
        "approval_id",
        ^ApprovalCopy.field(approval, :id)
      )
    )
    |> order_by([event], desc: event.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp resolve_scoped_approval(socket, approval_id) do
    case Enum.find(socket.assigns.approval_inbox, &(to_string(&1.id) == approval_id)) do
      nil -> fetch_tenant_scoped_approval(socket, approval_id)
      approval -> approval
    end
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

  defp safe_get_lineage(approval_id) do
    Workflows.get_approval_lineage!(approval_id)
  rescue
    Ecto.NoResultsError -> nil
  end

  defp patch_params(socket, extra) do
    socket
    |> scope_query_params()
    |> Map.merge(Map.new(extra, fn {k, v} -> {to_string(k), v} end))
  end

  defp scope_query_params(%{assigns: %{scope: "decided", outcome: outcome}}) do
    base = %{"scope" => "decided"}
    if outcome == "all", do: base, else: Map.put(base, "outcome", outcome)
  end

  defp scope_query_params(_socket), do: %{}

  defp approvals_path(scoria_base, params) do
    query =
      params
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Enum.map(fn {k, v} -> {to_string(k), to_string(v)} end)
      |> URI.encode_query()

    base = approvals_base_path(scoria_base)
    if query == "", do: base, else: base <> "?" <> query
  end

  defp approvals_base_path(""), do: "/approvals"
  defp approvals_base_path(base), do: base <> "/approvals"

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
      projection -> put_active_approval(socket, projection)
    end
  end

  defp record_approval_decision(socket, status) do
    case socket.assigns.active_approval do
      nil ->
        socket

      approval ->
        attrs = approval_decision_attrs(socket, approval)

        with {:ok, updated_approval} <- Workflows.approve(approval.id, status, attrs),
             {:ok, updated_socket, resume_outcome} <-
               maybe_resume_approval(socket, updated_approval, status) do
          # WR-03: a rejection deliberately keeps the workflow paused, so it must not
          # report the same green ":pass / decision recorded" toast as an approval —
          # that blurs a safety-relevant distinction. Branch the toast on status.
          #
          # `:not_resumable` (RAIL-01, D-05) overrides the default "Approval
          # granted." copy: the decision was recorded, but the run was halted
          # by a per-run rail and cannot be resumed, so telling the operator
          # it was "granted" would mislead them into thinking the run is
          # proceeding.
          toast_opts =
            case {status, resume_outcome} do
              {"approved", :not_resumable} ->
                [tone: :info, message: approval_error_message("approved", :not_resumable)]

              {"approved", _outcome} ->
                [tone: :pass, message: "Approval granted."]

              _ ->
                [tone: :warn, message: "Approval denied - run is still waiting for approval."]
            end

          # Clearing the drawer selection via push_patch (instead of a bare assign)
          # keeps the deep-linkable ?approval=<id> URL param in sync with the
          # decision (D-09) — handle_params/3 re-resolves :active_approval to nil
          # and reloads the inbox for the current scope.
          updated_socket
          |> assign(:decision_modal, nil)
          |> put_toast(toast_opts)
          |> push_patch(
            to: approvals_path(socket.assigns[:scoria_base] || "", patch_params(socket, %{}))
          )
        else
          {:error, reason} ->
            socket
            |> put_flash(:error, approval_error_message(status, reason))
            |> put_toast(tone: :fail, message: approval_error_message(status, reason))
        end
    end
  end

  # `Resume.resume_run/1` runs AFTER `Workflows.approve/3` has already
  # committed the decision (this function is called second in
  # `record_approval_decision/2`'s own `with` chain). A run halted by a
  # per-run rail (RAIL-01) falls through `Workflows.resume_run/1`'s
  # catch-all as `{:error, :not_resumable}` -- the decision WAS recorded,
  # only the resume did not happen. Reporting that through the generic
  # failure branch would tell the operator their approval failed when it
  # did not (D-05). The third element of the returned tuple carries the
  # resume outcome so the caller can pick an accurate toast instead of the
  # default "Approval granted." copy, which would otherwise mislead the
  # operator into thinking the run is proceeding.
  defp maybe_resume_approval(socket, _approval, status) when status != "approved",
    do: {:ok, socket, :not_applicable}

  defp maybe_resume_approval(socket, approval, "approved") do
    case approval.workflow_run_id do
      nil -> {:ok, socket, :not_applicable}
      run_id -> Resume.resume_run(run_id)
    end
    |> case do
      {:ok, _run} -> {:ok, socket, :resumed}
      {:error, :not_resumable} -> {:ok, socket, :not_resumable}
      {:error, reason} -> {:error, reason}
    end
  end

  defp approval_decision_attrs(socket, approval) do
    request_event = approval_request_event(approval)

    %{
      actor_id: dashboard_actor_id(socket),
      tenant_id: socket.assigns.tenant_id,
      trace_id: request_event && request_event.trace_id
    }
  end

  defp dashboard_actor_id(socket) do
    socket.assigns[:actor_id] || Map.get(socket.assigns[:scoria_scope] || %{}, :actor_id)
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

  # RAIL-01, D-05: `Resume.resume_run/1` runs AFTER the decision has already
  # committed, so this is NOT a failed approval -- the decision was recorded.
  # The run simply cannot be resumed because a per-run rail halted it.
  defp approval_error_message(_status, :not_resumable) do
    "Approval decision recorded. This run was halted by a per-run rail and cannot be resumed."
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
      |> put_active_approval(nil)
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

  # D-19: positive-whitelist predicate — only these three statuses are
  # decided. Fails safe (mirrors the server's :not_pending/StaleEntryError
  # guard in `approval_error_message/2` above): anything else (including a
  # missing status) is treated as NOT decided, so the action section +
  # confirm modal keep rendering rather than silently hiding a genuinely
  # pending approval.
  defp decided?(%{status: status}) when is_binary(status),
    do: status in ~w(approved rejected expired)

  defp decided?(_approval), do: false

  # D-15/D-27: the concrete irreversible-effect magnitude (impact_lead/1)
  # reused for both approve and deny confirms, so a Deny confirm also shows
  # the operator what is at stake — this is what makes the two-step confirm
  # earn its friction instead of restating the title. Never claims resume/
  # side-effect success; the trailing clause only describes what Scoria does
  # with the DECISION itself (records it, then either continues or holds).
  defp decision_confirm_copy("approve", approval) do
    "#{ApprovalCopy.impact_lead(approval)} Scoria records the decision, then continues the run."
  end

  defp decision_confirm_copy("reject", approval) do
    "#{ApprovalCopy.impact_lead(approval)} Scoria records the decision; the run stays paused until approved."
  end

  defp decision_confirm_copy(_decision, _approval), do: nil
end
