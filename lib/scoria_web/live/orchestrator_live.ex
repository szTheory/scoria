defmodule ScoriaWeb.OrchestratorLive do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}
  import Ecto.Query, warn: false

  import ScoriaWeb.UI,
    only: [
      attention_card: 1,
      badge: 1,
      evidence_action_row: 1,
      evidence_rows: 1,
      flash_group: 1,
      id: 1,
      page_header: 1,
      panel: 1
    ]

  alias Scoria.Eval
  alias Scoria.Repo
  alias Scoria.Repo.Span

  alias Scoria.Observe.Redactor
  alias Scoria.Observe.TraceProjection

  alias ScoriaWeb.OperatorSurface

  def mount(params, _session, socket) do
    tenant_id = socket.assigns.tenant_id

    socket =
      socket
      |> assign(:page_title, "Home")
      |> assign(:token_buffers, %{})
      |> assign(:token_previews, %{})
      |> assign(:token_timers, %{})
      |> assign(:trace_records, %{})
      |> assign(:runtime_query, Map.get(params, "runtime"))
      |> assign(
        :review_candidate,
        load_review_candidate(tenant_id, Map.get(params, "review_candidate_id"))
      )
      |> assign(:tenant_id, tenant_id)
      |> load_status_home()
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

  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <div>
        <.page_header title="Home">
          <:summary>
            Every AI run in this app, traced. Approve tools, triage incidents, and gate prompt releases from here.
          </:summary>
        </.page_header>

        <section id="home-attention" class="scoria-home__attention" aria-label="Needs attention">
          <.async_result :let={status_home} assign={@status_home}>
            <:loading>
              <p class="scoria-home__clear">Nothing needs attention. 0 approvals pending, 0 open incidents.</p>
            </:loading>
            <:failed :let={_failure}>
              <p class="scoria-home__clear">Nothing needs attention. 0 approvals pending, 0 open incidents.</p>
            </:failed>
            <% cards = attention_cards(status_home, assigns[:scoria_base] || "") %>
            <p :if={cards == []} class="scoria-home__clear">
              Nothing needs attention. 0 approvals pending, 0 open incidents.
            </p>
            <div :if={cards != []} class="scoria-home__attention-grid">
              <.attention_card
                :for={card <- cards}
                count={card.count}
                label={card.label}
                detail={card.detail}
                cta={card.cta}
                path={card.path}
                tone={card.tone}
              />
            </div>
          </.async_result>
        </section>

        <.flash_group flash={@flash} />

        <p :if={map_size(@trace_records) == 0} id="traces-empty" class="scoria-traces__empty">
          No traces yet. The first chat response, agent run, eval sample, or MCP request will appear here as a trace.
        </p>

        <div id="traces-list" phx-update="stream" class="space-y-4">
          <.panel :for={{id, trace} <- @streams.traces} id={id} variant={:flat}>
            <:title>
              <span>Trace</span>
              <.id value={trace.id} copy={trace.id} />
            </:title>
            <:actions>
              <.badge :for={badge <- trace_badges(trace)} tone={badge.tone} label={badge.label} dot={false} />
            </:actions>
            <.live_component
              module={ScoriaWeb.TraceTreeComponent}
              id={"tree-#{id}"}
              spans={trace.spans}
              token_previews={@token_previews}
            />
            <.evidence_action_row :if={trace[:workflow_run_id]} class="mt-3">
              <a class="scoria-button scoria-button--ghost scoria-button--sm" href={trace_run_path(trace, assigns[:scoria_base] || "")}>
                Open run
              </a>
              <a class="scoria-button scoria-button--primary scoria-button--sm" href={trace_run_path(trace, assigns[:scoria_base] || "")}>
                Open trace
              </a>
              <a :if={trace[:review_incident] || trace[:page_incident]} class="scoria-button scoria-button--ghost scoria-button--sm" href={(assigns[:scoria_base] || "") <> "/incidents?from=run:#{trace.workflow_run_id}"}>
                Open incident
              </a>
            </.evidence_action_row>
          </.panel>
        </div>

        <.panel :if={@review_candidate} class="mt-6">
          <:eyebrow>Review candidate context</:eyebrow>
          <:title>{@review_candidate.rationale}</:title>
          <p>
            Queue-selected evidence stays visible while inspecting runtime
            <span :if={@runtime_query} class="font-mono"><%= @runtime_query %></span>.
          </p>
          <.evidence_rows rows={[
            {"Severity", @review_candidate.severity},
            {"Trace", @review_candidate.trace_id},
            {"Workflow", @review_candidate.workflow_run_id}
          ]} />
        </.panel>
      </div>
    </div>
    """
  end

  defp trace_badges(trace) do
    Enum.concat([
      if(trace[:budget_state], do: [%{label: trace[:budget_state], tone: :warn}], else: []),
      if(trace[:breaker_state] == "open", do: [%{label: "Breaker open", tone: :fail}], else: []),
      if(trace[:review_incident], do: [%{label: "Review incident", tone: :info}], else: []),
      if(trace[:page_incident], do: [%{label: "Page incident", tone: :fail}], else: [])
    ])
  end

  defp load_review_candidate(_tenant_id, nil), do: nil

  defp load_review_candidate(tenant_id, candidate_id),
    do: Eval.get_review_candidate_for_tenant(tenant_id, candidate_id)

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

        header
        |> Map.put(:spans, span_views)
        |> enrich_trace_badges()
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

  defp load_status_home(socket) do
    tenant_id = socket.assigns.tenant_id

    assign_async(socket, :status_home, fn ->
      {:ok, %{status_home: OperatorSurface.status_home_summary(tenant_id)}}
    end)
  end

  defp attention_cards(status_home, base_path) do
    [
      approval_attention_card(status_home, base_path),
      incident_attention_card(status_home, base_path),
      connector_attention_card(status_home, base_path),
      review_attention_card(status_home, base_path)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp approval_attention_card(status_home, base_path) do
    count = get_in(status_home, [:approvals, :pending]) || 0

    if count > 0 do
      %{
        count: count,
        label: "Approvals pending",
        detail: "#{count} #{pluralize(count, "tool call")} #{approval_verb(count)} approval.",
        cta: "Review approvals",
        path: base_path <> "/approvals",
        tone: :warn
      }
    end
  end

  defp incident_attention_card(status_home, base_path) do
    count = get_in(status_home, [:incidents, :open]) || 0

    if count > 0 do
      %{
        count: count,
        label: "Open incidents",
        detail: "#{count} #{pluralize(count, "incident")} need triage.",
        cta: "Open incidents",
        path: base_path <> "/incidents",
        tone: :fail
      }
    end
  end

  defp connector_attention_card(status_home, base_path) do
    count = get_in(status_home, [:connectors, :degraded]) || 0

    if count > 0 do
      %{
        count: count,
        label: "Connector health",
        detail: "#{count} #{pluralize(count, "connector")} degraded.",
        cta: "View connector health",
        path: base_path <> "/connectors",
        tone: :warn
      }
    end
  end

  defp review_attention_card(status_home, base_path) do
    count = get_in(status_home, [:reviews, :pending]) || 0

    if count > 0 do
      %{
        count: count,
        label: "Flagged runs",
        detail: "#{count} #{pluralize(count, "run")} need review.",
        cta: "Review flagged runs",
        path: base_path <> "/reviews",
        tone: :info
      }
    end
  end

  defp approval_verb(1), do: "requires"
  defp approval_verb(_count), do: "require"
  defp pluralize(1, singular), do: singular
  defp pluralize(_count, singular), do: singular <> "s"

  defp maybe_open_trace(socket, %{id: trace_id} = header) when is_binary(trace_id) do
    if Map.has_key?(socket.assigns.trace_records, trace_id) do
      socket
    else
      trace = header |> Map.merge(%{spans: []}) |> enrich_trace_badges()

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

    updated_trace = trace |> Map.put(:spans, spans) |> enrich_trace_badges()

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

  defp trace_run_path(trace, base_path) do
    base_path <> "/workflows/#{trace.workflow_run_id}"
  end

  defp enrich_trace_badges(%{id: trace_id, workflow_run_id: run_id} = trace)
       when is_binary(trace_id) and is_binary(run_id) and run_id != "" do
    Map.merge(trace, OperatorSurface.compact_trace_badges(trace_id, run_id))
  rescue
    _error -> trace
  end

  defp enrich_trace_badges(trace), do: trace
end
