defmodule ScoriaWeb.OrchestratorLive do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}
  import Ecto.Query, warn: false

  alias Scoria.Eval
  alias Scoria.Repo
  alias Scoria.Repo.Span

  alias Scoria.Observe.Redactor
  alias Scoria.Observe.TraceProjection

  alias Scoria.SRE.AuditOutboxEvent

  alias Scoria.Workflows
  alias Scoria.Workflows.Resume

  alias ScoriaWeb.OperatorSurface

  alias ScoriaWeb.{
    ApprovalInboxComponent,
    CitationEvidenceComponent,
    ConnectorDetailDrawerComponent,
    IncidentEvidenceComponent,
    RuntimeDetailDrawerComponent
  }

  def mount(params, session, socket) do
    tenant_id = params["tenant"] || session["tenant_id"] || "default"

    socket =
      socket
      |> assign(:page_title, "Live Ops")
      |> assign(:token_buffers, %{})
      |> assign(:token_previews, %{})
      |> assign(:token_timers, %{})
      |> assign(:active_approval, nil)
      |> assign(:highlighted_approval_id, nil)
      |> assign(:approval_inbox, [])
      |> assign(:connector_fleet, [])
      |> assign(:connector_drawer, nil)
      |> assign(:runtimes, [])
      |> assign(:runtime_drawer, nil)
      |> assign(
        :actor_id,
        session["actor_id"] || session["user_id"] || session["session_id"] || "operator"
      )
      |> assign(:budget_state, nil)
      |> assign(:incident_evidence, nil)
      |> assign(:trace_records, %{})
      |> assign(:replay_notice, nil)
      |> assign(:promote_notice, nil)
      |> assign(:runtime_query, Map.get(params, "runtime"))
      |> assign(:review_candidate, load_review_candidate(Map.get(params, "review_candidate_id")))
      |> assign(:tenant_id, tenant_id)
      |> stream(:traces, [])

    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
        Phoenix.PubSub.subscribe(Scoria.PubSub, "mcp:runtimes:#{tenant_id}")
        hydrate_traces(socket, tenant_id)
      else
        socket
      end

    {:ok, socket |> load_operator_surface() |> maybe_seed_active_approval()}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, load_operator_surface(socket)}
  end

  def handle_info({:new_trace, trace}, socket) do
    trace_id = trace.id
    header = Map.take(trace, [:id, :session_id, :workflow_run_id, :tenant_id])

    socket =
      Enum.reduce(trace.spans, maybe_open_trace(socket, header), fn span, sock ->
        span_view = normalize_span_view(span)
        upsert_trace_span(sock, trace_id, span_view)
      end)

    {:noreply, socket}
  end

  def handle_info({:trace_opened, header}, socket) do
    {:noreply, maybe_open_trace(socket, header)}
  end

  def handle_info({:trace_span, trace_id, span_view}, socket) do
    socket =
      socket
      |> upsert_trace_span(trace_id, span_view)
      |> maybe_clear_token_preview(span_view)

    {:noreply, socket}
  end

  def handle_info({:trace_delta, %{trace_id: _trace_id, span_id: span_id, chunk: chunk}}, socket) do
    {:noreply, append_trace_delta(socket, span_id, chunk)}
  end

  def handle_info({:flush_tokens, span_id}, socket) do
    {:noreply, flush_token_preview(socket, span_id)}
  end

  def handle_info({:approval_decided, approval_id, _status}, socket) do
    socket =
      socket
      |> maybe_clear_active_approval(approval_id)
      |> maybe_clear_highlighted_approval(approval_id)
      |> load_operator_surface()

    {:noreply, socket}
  end

  def handle_info({:hitl_request, projection}, socket) do
    socket = load_operator_surface(socket)

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

  def handle_event("approve", _, socket) do
    {:noreply, record_approval_decision(socket, "approved")}
  end

  def handle_event("reject", _, socket) do
    {:noreply, record_approval_decision(socket, "rejected")}
  end

  def handle_event("dismiss_approval", _, socket) do
    {:noreply, assign(socket, :active_approval, nil)}
  end

  def handle_event("load_metadata", %{"id" => trace_id}, socket) do
    {:noreply,
     assign_async(socket, :trace_metadata, fn ->
       # Fetch deep trace metadata (simulated here)
       {:ok, %{trace_metadata: %{id: trace_id, deep_data: "loaded lazily"}}}
     end)}
  end

  def handle_event("open_connector_drawer", %{"id" => connector_id}, socket) do
    {:noreply, assign(socket, :connector_drawer, OperatorSurface.connector_drawer(connector_id))}
  end

  def handle_event("close_connector_drawer", _, socket) do
    {:noreply, assign(socket, :connector_drawer, nil)}
  end

  def handle_event("open_runtime_drawer", %{"id" => id}, socket) do
    runtime = Enum.find(socket.assigns.runtimes, &(&1.id == id))
    {:noreply, assign(socket, :runtime_drawer, runtime)}
  end

  def handle_event("close_runtime_drawer", _, socket) do
    {:noreply, assign(socket, :runtime_drawer, nil)}
  end

  def handle_event("load_retrieval_evidence", %{"id" => trace_id}, socket) do
    {:noreply,
     assign_async(socket, :retrieval_evidence, fn ->
       {:ok, %{retrieval_evidence: sample_evidence(trace_id)}}
     end)}
  end

  def handle_event("load_budget_state", params, socket) do
    trace_id = Map.get(params, "id")
    run_id = Map.get(params, "run_id")

    {:noreply,
     socket
     |> refresh_trace_badges(trace_id, run_id)
     |> assign_async(:budget_state, fn ->
       {:ok, %{budget_state: OperatorSurface.load_budget_projection(trace_id, run_id)}}
     end)}
  end

  def handle_event("load_incident_evidence", params, socket) do
    trace_id = Map.get(params, "id")
    run_id = Map.get(params, "run_id")

    {:noreply,
     socket
     |> refresh_trace_badges(trace_id, run_id)
     |> assign_async(:incident_evidence, fn ->
       {:ok, %{incident_evidence: OperatorSurface.load_incident_projection(trace_id, run_id)}}
     end)}
  end

  def handle_event("replay_retrieval", %{"id" => trace_id}, socket) do
    {:noreply, assign(socket, :replay_notice, "replay_retrieval queued for #{trace_id}")}
  end

  def handle_event("promote_retrieval", %{"id" => trace_id}, socket) do
    {:noreply, assign(socket, :promote_notice, "promote_retrieval queued for #{trace_id}")}
  end

  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <div>
        <div class="scoria-pagehead">
          <h1>Live Ops</h1>
          <p class="text-stone-600 mt-1">Live runtime activity, approvals, and connector health. Start from a task below.</p>
        </div>

        <div class="grid gap-4 md:grid-cols-2 mb-6">
          <a href="#approvals-section" class="scoria-taskcard">
            <div class="scoria-taskcard__title">
              <span>Approve pending tool calls</span>
              <span class={["scoria-badge", "scoria-badge--bare", (if @approval_inbox == [], do: "scoria-badge--neutral", else: "scoria-badge--warn")]}><%= length(@approval_inbox) %></span>
            </div>
            <p class="scoria-taskcard__desc">Review and approve or deny operator-gated tool calls.</p>
          </a>
          <.link navigate={(assigns[:scoria_base] || "") <> "/reviews"} class="scoria-taskcard">
            <div class="scoria-taskcard__title"><span>Review flagged traces</span></div>
            <p class="scoria-taskcard__desc">Triage low-quality or policy-flagged runs and promote them to datasets.</p>
          </.link>
          <.link navigate={(assigns[:scoria_base] || "") <> "/workflows"} class="scoria-taskcard">
            <div class="scoria-taskcard__title"><span>Inspect a run</span></div>
            <p class="scoria-taskcard__desc">Open the Trace Explorer for any durable run's steps and evidence.</p>
          </.link>
          <.link navigate={(assigns[:scoria_base] || "") <> "/eval_specs"} class="scoria-taskcard">
            <div class="scoria-taskcard__title"><span>Tune evals &amp; prompts</span></div>
            <p class="scoria-taskcard__desc">Manage rubrics and prompt versions in the workbench.</p>
          </.link>
        </div>

        <div
          :for={{kind, message} <- @flash}
          id={"flash-#{kind}"}
          class={["mb-4 rounded-lg border px-4 py-3 text-sm", flash_kind_class(kind)]}
        >
          <%= message %>
        </div>

        <section
          :if={@review_candidate}
          class="mb-6 rounded-2xl border border-blue-200 bg-blue-50 p-4 text-sm text-blue-950 shadow-sm"
        >
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-blue-700">Review candidate context</p>
          <p class="mt-2 font-semibold text-stone-900"><%= @review_candidate.rationale %></p>
          <p class="mt-2 text-stone-700">
            Queue-selected evidence stays visible while inspecting runtime
            <span :if={@runtime_query} class="font-mono"><%= @runtime_query %></span>.
          </p>
          <div class="mt-3 flex flex-wrap gap-2 text-xs text-stone-700">
            <span class="rounded-full border border-blue-200 bg-white px-3 py-1"><%= @review_candidate.severity %></span>
            <span class="rounded-full border border-blue-200 bg-white px-3 py-1">trace <span class="font-mono"><%= @review_candidate.trace_id %></span></span>
            <span class="rounded-full border border-blue-200 bg-white px-3 py-1">workflow <span class="font-mono"><%= @review_candidate.workflow_run_id %></span></span>
          </div>
        </section>

        <div id="approvals-section" class="mb-6 grid gap-6 lg:grid-cols-2">
          <%= if approval_inbox_component?() do %>
            <ApprovalInboxComponent.render
              approvals={@approval_inbox}
              highlight_approval_id={@highlighted_approval_id}
            />
          <% else %>
            <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
              <p class="text-xs uppercase tracking-[0.24em] text-stone-500">approvals</p>
              <h2 class="text-lg font-semibold text-stone-900">Approval inbox</h2>
            </section>
          <% end %>

          <div class="space-y-6">
            <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
              <div class="flex items-center justify-between gap-4">
                <div>
                  <p class="text-xs uppercase tracking-[0.24em] text-stone-500">external runtimes</p>
                  <h2 class="text-lg font-semibold text-stone-900">Runtime posture</h2>
                </div>
              </div>

              <div class="mt-4 space-y-3">
                <article :for={runtime <- @runtimes} class="rounded-xl border border-stone-200 bg-stone-50 p-3 flex justify-between items-start">
                  <div>
                    <p class="text-sm font-semibold text-stone-900 truncate max-w-[12rem]"><%= runtime.id %></p>
                    <p class="text-xs text-stone-500 mt-1">
                      <span class={"inline-block w-2 h-2 rounded-full mr-1 #{if runtime.status == "online", do: "bg-emerald-500", else: "bg-stone-300"}"}></span>
                      <%= runtime.status %>
                    </p>
                  </div>
                  <button phx-click="open_runtime_drawer" phx-value-id={runtime.id} class="text-xs font-medium text-blue-700 underline">
                    Details
                  </button>
                </article>
              </div>
            </section>

            <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
              <div class="flex items-center justify-between gap-4">
                <div>
                  <p class="text-xs uppercase tracking-[0.24em] text-stone-500">connector fleet</p>
                  <h2 class="text-lg font-semibold text-stone-900">Connector posture</h2>
                </div>
              </div>

              <div class="mt-4 space-y-3">
                <article :for={connector <- @connector_fleet} class="rounded-xl border border-stone-200 bg-stone-50 p-3">
                  <div class="flex items-start justify-between gap-3">
                    <div>
                      <p class="text-sm font-semibold text-stone-900"><%= connector.connector_label %></p>
                      <p class="mt-1 text-xs text-stone-600">
                        <%= connector.health_state %> · refresh <%= connector.last_refresh_status %>
                      </p>
                    </div>
                    <button phx-click="open_connector_drawer" phx-value-id={connector.connector_id} class="text-xs font-medium text-blue-700 underline">
                      Open drawer
                    </button>
                  </div>

                  <div class="mt-3 flex flex-wrap gap-3 text-xs text-stone-600">
                    <span>approvals <%= connector.pending_approval_count %></span>
                    <span>pending tools <%= connector.pending_local_tool_count %></span>
                    <span>auth <%= connector.auth_provenance.status %></span>
                  </div>
                </article>
              </div>
            </section>
          </div>
        </div>

        <%= if runtime_drawer_component?() do %>
          <RuntimeDetailDrawerComponent.render drawer={@runtime_drawer} />
        <% end %>
        <%= if connector_drawer_component?() do %>
          <ConnectorDetailDrawerComponent.render drawer={@connector_drawer} />
        <% end %>

        <div id="traces-list" phx-update="stream" class="space-y-4">
          <div :for={{id, trace} <- @streams.traces} id={id} class="bg-white p-4 rounded shadow">
            <.live_component
              module={ScoriaWeb.TraceTreeComponent}
              id={"tree-#{id}"}
              spans={trace.spans}
              token_previews={@token_previews}
            />
            <div class="mt-3 flex flex-wrap gap-2 text-[11px]">
              <span :for={badge <- trace_badges(trace)} class={trace_badge_class(badge.tone)}>
                <%= badge.label %>
              </span>
            </div>
            <div class="mt-3 flex flex-wrap gap-3 text-xs">
              <button phx-click="load_metadata" phx-value-id={trace.id} class="text-blue-500 underline">Load Deep Metadata</button>
              <button phx-click="load_retrieval_evidence" phx-value-id={trace.id} class="text-emerald-700 underline">Load Retrieval Evidence</button>
              <button phx-click="load_budget_state" phx-value-id={trace.id} phx-value-run_id={trace[:workflow_run_id]} class="text-amber-700 underline">Load Budget State</button>
              <button phx-click="load_incident_evidence" phx-value-id={trace.id} phx-value-run_id={trace[:workflow_run_id]} class="text-rose-700 underline">Load Incident Evidence</button>
              <button phx-click="replay_retrieval" phx-value-id={trace.id} class="text-stone-700 underline">Replay Retrieval</button>
              <button phx-click="promote_retrieval" phx-value-id={trace.id} class="text-stone-700 underline">Promote Retrieval</button>
            </div>
          </div>
        </div>

        <%= if assigns[:trace_metadata] do %>
          <div class="mt-4 p-4 bg-gray-100 rounded text-sm">
            <.async_result :let={metadata} assign={@trace_metadata}>
              <:loading>Loading metadata...</:loading>
              <:failed :let={_failure}>Failed to load metadata</:failed>
              <pre><%= inspect(metadata) %></pre>
            </.async_result>
          </div>
        <% end %>

        <%= if assigns[:retrieval_evidence] do %>
          <div id="retrieval-evidence" class="mt-6">
            <.async_result :let={evidence} assign={@retrieval_evidence}>
              <:loading>Loading retrieval evidence...</:loading>
              <:failed :let={_failure}>Failed to load retrieval evidence</:failed>
              <CitationEvidenceComponent.render evidence={evidence} />
            </.async_result>
          </div>
        <% end %>

        <%= if assigns[:budget_state] do %>
          <div id="budget-state" class="mt-6">
            <.async_result :let={budget_state} assign={@budget_state}>
              <:loading>Loading budget state...</:loading>
              <:failed :let={_failure}>Failed to load budget state</:failed>
              <div class="rounded-xl border border-stone-200 bg-white p-4 shadow-sm">
                <p class="text-xs uppercase tracking-[0.24em] text-stone-500">Budget state</p>
                <div class="mt-3 flex flex-wrap gap-2 text-xs">
                  <span class={trace_badge_class("amber")}><%= budget_state.status_label %></span>
                  <span class={trace_badge_class("rose")} :if={budget_state.breaker_open?}>breaker open</span>
                  <span class={trace_badge_class("sky")} :if={budget_state.review_open?}>review incident</span>
                  <span class={trace_badge_class("rose")} :if={budget_state.page_open?}>page incident</span>
                </div>
                <p class="mt-3 text-sm text-stone-700"><%= budget_state.actuals %></p>
              </div>
            </.async_result>
          </div>
        <% end %>

        <%= if assigns[:incident_evidence] do %>
          <div id="incident-evidence" class="mt-6">
            <.async_result :let={evidence} assign={@incident_evidence}>
              <:loading>Loading incident evidence...</:loading>
              <:failed :let={_failure}>Failed to load incident evidence</:failed>
              <IncidentEvidenceComponent.render evidence={evidence} />
            </.async_result>
          </div>
        <% end %>

        <%= if @replay_notice do %>
          <div class="mt-4 rounded border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-900">
            <%= @replay_notice %>
          </div>
        <% end %>

        <%= if @promote_notice do %>
          <div class="mt-4 rounded border border-blue-200 bg-blue-50 p-3 text-sm text-blue-900">
            <%= @promote_notice %>
          </div>
        <% end %>
      </div>

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
              href={"/workflows/#{@active_approval[:workflow_run_id]}"}
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

  defp sample_evidence(trace_id) do
    %{
      id: trace_id,
      query_text: "citation-backed retrieval for trace #{trace_id}",
      freshness: "freshness: current corpus snapshot",
      citations: [
        %{label: "[1]", title: "Trace-first design", locator: "file:///docs/trace-first.md"},
        %{label: "[2]", title: "Grounding rules", locator: "file:///docs/grounding.md"}
      ],
      ranked_chunks: [
        %{
          rank: 1,
          score: "0.98",
          body: "citation evidence is shown side-by-side for operator review."
        },
        %{rank: 2, score: "0.91", body: "unsupported claims are surfaced before promotion."}
      ],
      unsupported_claims: ["none"],
      grounding_scores: [%{kind: "deterministic", score: "1.0"}]
    }
  end

  defp trace_badges(trace) do
    Enum.concat([
      if(trace[:budget_state], do: [%{label: trace[:budget_state], tone: "amber"}], else: []),
      if(trace[:breaker_state] == "open", do: [%{label: "breaker open", tone: "rose"}], else: []),
      if(trace[:review_incident], do: [%{label: "review incident", tone: "sky"}], else: []),
      if(trace[:page_incident], do: [%{label: "page incident", tone: "rose"}], else: [])
    ])
  end

  defp trace_badge_class(tone) do
    base = "rounded-full px-2.5 py-1 font-semibold uppercase tracking-[0.18em]"

    color =
      case tone do
        "rose" -> "border border-rose-200 bg-rose-50 text-rose-800"
        "sky" -> "border border-sky-200 bg-sky-50 text-sky-800"
        "amber" -> "border border-amber-200 bg-amber-50 text-amber-800"
        _ -> "border border-emerald-200 bg-emerald-50 text-emerald-800"
      end

    [base, color]
  end

  defp refresh_trace_badges(socket, trace_id, run_id) do
    case Map.get(socket.assigns.trace_records, trace_id) do
      nil ->
        socket

      trace ->
        badge_assigns = OperatorSurface.compact_trace_badges(trace_id, run_id)
        updated_trace = Map.merge(trace, badge_assigns)

        socket
        |> assign(:trace_records, Map.put(socket.assigns.trace_records, trace_id, updated_trace))
        |> stream_insert(:traces, updated_trace)
    end
  rescue
    _error ->
      socket
  end

  defp record_approval_decision(socket, status) do
    case socket.assigns.active_approval do
      nil ->
        socket

      approval ->
        attrs = approval_decision_attrs(socket, approval)

        with {:ok, updated_approval} <- Workflows.approve(approval.id, status, attrs),
             {:ok, updated_socket} <- maybe_resume_approval(socket, updated_approval, status) do
          updated_socket
          |> assign(:active_approval, nil)
          |> load_operator_surface()
        else
          {:error, reason} ->
            put_flash(socket, :error, approval_error_message(status, reason))
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

  defp flash_kind_class(:error), do: "border-rose-200 bg-rose-50 text-rose-900"
  defp flash_kind_class(:info), do: "border-sky-200 bg-sky-50 text-sky-900"
  defp flash_kind_class(_kind), do: "border-stone-200 bg-stone-50 text-stone-900"

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

  defp load_review_candidate(nil), do: nil
  defp load_review_candidate(candidate_id), do: Eval.get_review_candidate(candidate_id)

  defp approval_inbox_component? do
    Code.ensure_loaded?(ApprovalInboxComponent) and
      function_exported?(ApprovalInboxComponent, :render, 1)
  end

  defp runtime_drawer_component? do
    Code.ensure_loaded?(RuntimeDetailDrawerComponent) and
      function_exported?(RuntimeDetailDrawerComponent, :render, 1)
  end

  defp connector_drawer_component? do
    Code.ensure_loaded?(ConnectorDetailDrawerComponent) and
      function_exported?(ConnectorDetailDrawerComponent, :render, 1)
  end

  @doc false
  defp hydrate_traces(socket, tenant_id) do
    limit = Application.get_env(:scoria, :orchestrator_hydrate_trace_limit, 25)

    trace_ids =
      Span
      |> where([s], fragment("?->>? = ?", s.attributes, "tenant_id", ^tenant_id))
      |> group_by([s], s.trace_id)
      |> order_by([s], desc: max(s.end_time))
      |> limit(^limit)
      |> select([s], s.trace_id)
      |> Repo.all()

    traces =
      trace_ids
      |> Enum.map(&build_hydrated_trace(&1, tenant_id))
      |> Enum.reject(&is_nil/1)

    trace_records =
      Enum.reduce(traces, socket.assigns.trace_records, fn trace, acc ->
        if Map.has_key?(acc, trace.id), do: acc, else: Map.put(acc, trace.id, trace)
      end)

    new_traces = Enum.reject(traces, &Map.has_key?(socket.assigns.trace_records, &1.id))

    socket
    |> assign(:trace_records, trace_records)
    |> then(fn sock ->
      if new_traces == [] do
        sock
      else
        Enum.reduce(new_traces, sock, fn trace, s -> stream_insert(s, :traces, trace) end)
      end
    end)
  end

  defp build_hydrated_trace(trace_id, tenant_id) do
    spans =
      Span
      |> where([s], s.trace_id == ^trace_id)
      |> where([s], fragment("?->>? = ?", s.attributes, "tenant_id", ^tenant_id))
      |> order_by([s], asc: s.start_time)
      |> Repo.all()

    case spans do
      [] ->
        nil

      [first | _] = span_rows ->
        attrs = first.attributes || %{}

        header = %{
          id: trace_id,
          session_id: attrs["session_id"] || attrs[:session_id],
          workflow_run_id: attrs["workflow_run_id"] || attrs[:workflow_run_id],
          tenant_id: tenant_id
        }

        span_views =
          span_rows
          |> Enum.map(&span_view_from_record/1)
          |> TraceProjection.with_depths()

        Map.put(header, :spans, span_views)
    end
  end

  defp span_view_from_record(%Span{} = span) do
    %{attributes: attributes} =
      Redactor.redact(%{attributes: span.attributes || %{}})

    TraceProjection.span_view(%{
      id: span.id,
      name: span.name,
      span_kind: span.span_kind,
      status_code: span.status_code,
      parent_id: span.parent_id,
      start_time: span.start_time,
      end_time: span.end_time,
      attributes: attributes
    })
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

  defp load_operator_surface(socket) do
    tenant_id = socket.assigns.tenant_id

    socket
    |> assign(:approval_inbox, Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id}))
    |> assign(:connector_fleet, OperatorSurface.connector_fleet(tenant_id))
    |> assign(:runtimes, OperatorSurface.load_runtimes(tenant_id))
  end

  defp maybe_open_trace(socket, %{id: trace_id} = header) when is_binary(trace_id) do
    if Map.has_key?(socket.assigns.trace_records, trace_id) do
      socket
    else
      trace = Map.merge(header, %{spans: []})

      socket
      |> assign(:trace_records, Map.put(socket.assigns.trace_records, trace_id, trace))
      |> stream_insert(:traces, trace)
    end
  end

  defp maybe_open_trace(socket, _header), do: socket

  defp upsert_trace_span(socket, trace_id, span_view) do
    trace =
      Map.get(socket.assigns.trace_records, trace_id, %{
        id: trace_id,
        spans: []
      })

    spans =
      trace.spans
      |> Enum.reject(&(&1.id == span_view.id))
      |> Kernel.++([Map.put_new(span_view, :parent_id, nil)])
      |> TraceProjection.with_depths()

    updated_trace = Map.put(trace, :spans, spans)

    socket
    |> assign(:trace_records, Map.put(socket.assigns.trace_records, trace_id, updated_trace))
    |> stream_insert(:traces, updated_trace)
  end

  defp normalize_span_view(span) do
    span
    |> Map.new()
    |> Map.put_new(:id, Map.get(span, :id) || Ecto.UUID.generate())
    |> Map.put_new(:parent_id, nil)
  end

  defp append_trace_delta(socket, span_id, chunk) do
    buffers = socket.assigns.token_buffers
    span_buffer = Map.get(buffers, span_id, [])

    span_buffer =
      if length(span_buffer) >= 256 do
        [chunk | Enum.take(span_buffer, 127)]
      else
        [chunk | span_buffer]
      end

    socket =
      assign(socket, :token_buffers, Map.put(buffers, span_id, span_buffer))

    if Map.has_key?(socket.assigns.token_timers, span_id) do
      socket
    else
      coalesce_ms = Application.get_env(:scoria, :live_token_coalesce_ms, 75)
      ref = Process.send_after(self(), {:flush_tokens, span_id}, coalesce_ms)

      assign(socket, :token_timers, Map.put(socket.assigns.token_timers, span_id, ref))
    end
  end

  defp flush_token_preview(socket, span_id) do
    chunks =
      socket.assigns.token_buffers
      |> Map.get(span_id, [])
      |> Enum.reverse()

    preview =
      socket.assigns.token_previews
      |> Map.get(span_id, "")
      |> Kernel.<>(Enum.join(chunks, ""))

    socket =
      socket
      |> assign(:token_buffers, Map.put(socket.assigns.token_buffers, span_id, []))
      |> assign(:token_previews, Map.put(socket.assigns.token_previews, span_id, preview))
      |> assign(:token_timers, Map.delete(socket.assigns.token_timers, span_id))

    case find_trace_for_span(socket, span_id) do
      nil -> socket
      trace -> stream_insert(socket, :traces, trace)
    end
  end

  defp find_trace_for_span(socket, span_id) do
    Enum.find_value(socket.assigns.trace_records, fn {_trace_id, trace} ->
      if Enum.any?(trace.spans, &(Map.get(&1, :id) == span_id)), do: trace, else: nil
    end)
  end

  defp maybe_clear_token_preview(socket, span_view) do
    if Map.get(span_view, :end_time) do
      span_id = span_view.id

      socket =
        case Map.get(socket.assigns.token_timers, span_id) do
          nil ->
            socket

          ref ->
            _ = Process.cancel_timer(ref)
            assign(socket, :token_timers, Map.delete(socket.assigns.token_timers, span_id))
        end

      socket
      |> assign(:token_buffers, Map.delete(socket.assigns.token_buffers, span_id))
      |> assign(:token_previews, Map.delete(socket.assigns.token_previews, span_id))
    else
      socket
    end
  end
end
