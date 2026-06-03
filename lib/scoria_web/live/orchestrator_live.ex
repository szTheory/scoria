defmodule ScoriaWeb.OrchestratorLive do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}
  import Ecto.Query, warn: false

  alias Scoria.Eval
  alias Scoria.Repo
  alias Scoria.Repo.Span

  alias Scoria.Observe.Redactor
  alias Scoria.Observe.TraceProjection

  alias ScoriaWeb.OperatorSurface

  alias ScoriaWeb.{
    CitationEvidenceComponent,
    IncidentEvidenceComponent
  }

  def mount(params, session, socket) do
    tenant_id = params["tenant"] || session["tenant_id"] || "default"

    socket =
      socket
      |> assign(:page_title, "Live Ops")
      |> assign(:token_buffers, %{})
      |> assign(:token_previews, %{})
      |> assign(:token_timers, %{})
      |> assign(:budget_state, nil)
      |> assign(:incident_evidence, nil)
      |> assign(:trace_records, %{})
      |> assign(:replay_notice, nil)
      |> assign(:promote_notice, nil)
      |> assign(:runtime_query, Map.get(params, "runtime"))
      |> assign(:review_candidate, load_review_candidate(Map.get(params, "review_candidate_id")))
      |> assign(:tenant_id, tenant_id)
      |> load_summary()
      |> stream(:traces, [])

    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
        hydrate_traces(socket, tenant_id)
      else
        socket
      end

    {:ok, socket}
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

  # Approvals/connectors/runtimes moved to their own routed pages; ignore their
  # broadcasts here so the live trace stream keeps working.
  def handle_info(_message, socket), do: {:noreply, socket}

  def handle_event("load_metadata", %{"id" => trace_id}, socket) do
    {:noreply,
     assign_async(socket, :trace_metadata, fn ->
       # Fetch deep trace metadata (simulated here)
       {:ok, %{trace_metadata: %{id: trace_id, deep_data: "loaded lazily"}}}
     end)}
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
          <.link navigate={(assigns[:scoria_base] || "") <> "/approvals"} class="scoria-taskcard">
            <div class="scoria-taskcard__title">
              <span>Approve pending tool calls</span>
              <span class={["scoria-badge", "scoria-badge--bare", (if @approval_count == 0, do: "scoria-badge--neutral", else: "scoria-badge--warn")]}><%= @approval_count %></span>
            </div>
            <p class="scoria-taskcard__desc">Review and approve or deny operator-gated tool calls.</p>
          </.link>
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

        <div id="ops-summary" class="mb-6 grid gap-4 sm:grid-cols-3">
          <.link navigate={(assigns[:scoria_base] || "") <> "/approvals"} class="scoria-taskcard">
            <p class="text-xs uppercase tracking-[0.24em] text-stone-500">Approvals</p>
            <p class="mt-2 text-2xl font-semibold text-stone-900"><%= @approval_count %></p>
            <p class="mt-1 text-xs text-stone-600">pending decisions →</p>
          </.link>
          <.link navigate={(assigns[:scoria_base] || "") <> "/connectors"} class="scoria-taskcard">
            <p class="text-xs uppercase tracking-[0.24em] text-stone-500">Connectors</p>
            <p class="mt-2 text-2xl font-semibold text-stone-900"><%= @fleet_summary.runtimes_online %>/<%= @fleet_summary.runtimes_total %></p>
            <p class="mt-1 text-xs text-stone-600">
              runtimes online · <%= @fleet_summary.connectors_degraded %> connector(s) degraded →
            </p>
          </.link>
          <.link navigate={(assigns[:scoria_base] || "") <> "/incidents"} class="scoria-taskcard">
            <p class="text-xs uppercase tracking-[0.24em] text-stone-500">Incidents</p>
            <p class="mt-2 text-2xl font-semibold text-stone-900"><%= @incidents_summary.open %></p>
            <p class="mt-1 text-xs text-stone-600">
              open · <%= @incidents_summary.page %> paging →
            </p>
          </.link>
        </div>

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

  defp flash_kind_class(:error), do: "border-rose-200 bg-rose-50 text-rose-900"
  defp flash_kind_class(:info), do: "border-sky-200 bg-sky-50 text-sky-900"
  defp flash_kind_class(_kind), do: "border-stone-200 bg-stone-50 text-stone-900"

  defp load_review_candidate(nil), do: nil
  defp load_review_candidate(candidate_id), do: Eval.get_review_candidate(candidate_id)

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

  defp load_summary(socket) do
    tenant_id = socket.assigns.tenant_id

    socket
    |> assign(:approval_count, OperatorSurface.pending_approval_count(tenant_id))
    |> assign(:fleet_summary, OperatorSurface.fleet_summary(tenant_id))
    |> assign(:incidents_summary, OperatorSurface.incidents_summary(tenant_id))
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
