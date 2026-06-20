defmodule ScoriaWeb.IncidentsLive.Index do
  @moduledoc """
  Incidents — tenant-level SRE triage. Lists the tenant's incidents newest-first
  as routed object links. Extracted from the Live Ops god-page (where incident
  evidence was only reachable per-trace) so incident history is a focused,
  linkable surface.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI

  alias ScoriaWeb.OperatorSurface

  @impl true
  def mount(params, session, socket) do
    tenant_id = (is_map(params) && params["tenant"]) || session["tenant_id"] || "default"
    incidents = OperatorSurface.list_tenant_incidents(tenant_id)

    socket =
      socket
      |> assign(:page_title, "Incidents")
      |> assign(:tenant_id, tenant_id)
      |> assign(:incidents, incidents)
      |> assign(:triage_summary, triage_summary(incidents))
      |> assign(:not_found_from, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    base = incidents_base_path(uri)

    cond do
      incident_id = params["incident"] ->
        {:noreply, push_navigate(socket, to: incident_path(incident_id, base, params["from"]))}

      run_id = run_origin_id(params["from"]) ->
        case OperatorSurface.find_tenant_incident_for_run(socket.assigns.tenant_id, run_id) do
          nil ->
            {:noreply, assign(socket, :not_found_from, params["from"])}

          incident ->
            {:noreply, push_navigate(socket, to: incident_path(incident, base, params["from"]))}
        end

      true ->
        {:noreply, assign(socket, :not_found_from, nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <div class="scoria-pagehead">
        <h1>Incidents</h1>
        <p style="margin-top: var(--scoria-space-1); color: var(--scoria-text-muted);">
          SRE triage for this tenant. Select an incident to inspect its trace-first evidence — budget, breaker, alerts, and audit relay.
        </p>
      </div>

      <div :if={@incidents == []}>
        <.empty_state title="No open incidents">
          Runtime failures, breaker trips, and delivery issues will appear here with links back to the affected run.
        </.empty_state>
      </div>

      <div :if={@incidents != []}>
        <.page_section class="scoria-incident-index__triage">
          <:eyebrow>incident posture</:eyebrow>
          <:title>Tenant triage</:title>
          <:description>{@triage_summary.detail}</:description>
          <:actions>
            <a
              :if={@triage_summary.incident}
              href={incident_path(@triage_summary.incident, assigns[:scoria_base] || "")}
              class="scoria-button scoria-button--primary scoria-button--sm"
            >
              {@triage_summary.cta}
            </a>
          </:actions>

          <.overview_stats label="Incident queue summary">
            <:stat
              :for={signal <- @triage_summary.signals}
              label={signal.label}
              value={signal.value}
              tone={signal.tone}
            >
              {signal.detail}
            </:stat>
          </.overview_stats>
        </.page_section>

        <.page_section class="scoria-incident-index__history">
          <:eyebrow>incident history</:eyebrow>
          <:title>Incident history</:title>
          <:description>{@triage_summary.history_detail}</:description>

          <p :if={@not_found_from} class="scoria-incident-index__notice">
            No incident is linked to <span class="font-mono">{@not_found_from}</span> for this tenant.
          </p>

          <ul class="scoria-selectable-list" aria-label="Tenant incidents">
            <li :for={incident <- @incidents}>
              <.selectable_card
                href={incident_path(incident, assigns[:scoria_base] || "")}
                tone={severity_tone(incident.severity)}
              >
                <:title>{incident.summary || incident.incident_key}</:title>
                <:status><.badge tone={severity_tone(incident.severity)} label={incident.severity} /></:status>
                <:meta>
                  route {incident.routing_class} · {incident.status}
                  <span :if={incident.trace_id}>
                    · trace <span class="font-mono" title={incident.trace_id}>{short_id(incident.trace_id)}</span>
                  </span>
                </:meta>
              </.selectable_card>
            </li>
          </ul>
        </.page_section>
      </div>
    </div>
    """
  end

  defp severity_tone("critical"), do: :fail
  defp severity_tone("warning"), do: :warn
  defp severity_tone(_), do: :info

  defp triage_summary(incidents) do
    open_incidents = Enum.filter(incidents, &(&1.status == "open"))
    page_incidents = Enum.filter(open_incidents, &(&1.routing_class == "page"))
    review_incidents = Enum.filter(open_incidents, &(&1.routing_class == "review"))
    not_open_count = length(incidents) - length(open_incidents)

    {state, incident, cta} =
      cond do
        page_incidents != [] ->
          {:page, List.first(page_incidents), "Open paging incident"}

        review_incidents != [] ->
          {:review, List.first(review_incidents), "Open review incident"}

        open_incidents != [] ->
          {:open, List.first(open_incidents), "Open newest open incident"}

        true ->
          {:clear, nil, nil}
      end

    %{
      state: state,
      incident: incident,
      cta: cta,
      detail: triage_detail(length(open_incidents), length(incidents)),
      history_detail: history_detail(length(incidents), length(open_incidents), not_open_count),
      signals: [
        %{
          label: "Needs triage",
          value: open_value(length(open_incidents)),
          detail: needs_triage_detail(length(open_incidents)),
          tone: needs_triage_tone(length(open_incidents))
        },
        %{
          label: "Review",
          value: review_value(length(review_incidents)),
          detail: review_detail(length(review_incidents)),
          tone: if(length(review_incidents) > 0, do: :warn, else: :neutral)
        },
        %{
          label: "Paging",
          value: paging_value(length(page_incidents)),
          detail: paging_detail(length(page_incidents)),
          tone: if(length(page_incidents) > 0, do: :fail, else: :neutral)
        }
      ]
    }
  end

  defp triage_detail(0, history_count) do
    "No open incidents. #{pluralize(history_count, "incident record")} remain below for trace evidence."
  end

  defp triage_detail(open_count, history_count) do
    "#{pluralize(open_count, "open incident")} across #{pluralize(history_count, "incident record")}. Open one to inspect trace-first evidence."
  end

  defp history_detail(history_count, open_count, 0) do
    "#{pluralize(history_count, "record")}, #{open_count_phrase(open_count)}."
  end

  defp history_detail(history_count, open_count, not_open_count) do
    "#{pluralize(history_count, "record")}, #{open_count_phrase(open_count)}, #{not_open_count_phrase(not_open_count)}."
  end

  defp open_value(0), do: "No open incidents"
  defp open_value(count), do: open_count_phrase(count)

  defp needs_triage_detail(0),
    do: "Recent incident records remain available for audit and trace context."

  defp needs_triage_detail(_count),
    do: "These are the current incident records that still need triage."

  defp needs_triage_tone(0), do: :pass
  defp needs_triage_tone(_count), do: :info

  defp review_value(0), do: "No review-routed incidents"
  defp review_value(count), do: "#{count} review-routed"

  defp review_detail(0), do: "No open incidents are waiting in the review lane."
  defp review_detail(_count), do: "Operator review or audit relay needs inspection."

  defp paging_value(0), do: "No paging active"
  defp paging_value(count), do: "#{count} paging"

  defp paging_detail(0), do: "No open incidents are paging an operator."
  defp paging_detail(_count), do: "Immediate operator response is required."

  defp open_count_phrase(1), do: "1 open"
  defp open_count_phrase(count), do: "#{count} open"

  defp not_open_count_phrase(1), do: "1 no longer open"
  defp not_open_count_phrase(count), do: "#{count} no longer open"

  defp pluralize(1, noun), do: "1 #{noun}"
  defp pluralize(count, noun), do: "#{count} #{noun}s"

  defp short_id(nil), do: "—"
  defp short_id(id), do: id |> to_string() |> String.slice(0, 8)

  defp incident_path(%{id: id}, base), do: incident_path(id, base, nil)
  defp incident_path(%{id: id}, base, from), do: incident_path(id, base, from)

  defp incident_path(id, base, nil), do: "#{base}/incidents/#{id}"

  defp incident_path(id, base, from) do
    "#{base}/incidents/#{id}?#{URI.encode_query([{"from", from}])}"
  end

  defp incidents_base_path(uri) do
    path = URI.parse(uri).path || "/incidents"

    if String.ends_with?(path, "/incidents") do
      String.replace_suffix(path, "/incidents", "")
    else
      ""
    end
  end

  defp run_origin_id("run:" <> run_id) when run_id != "", do: run_id
  defp run_origin_id(_from), do: nil
end
