defmodule ScoriaWeb.IncidentsLive.Show do
  @moduledoc """
  Routed incident detail. The incident URL is the source of truth; the queue rail
  is context for fast triage, not an in-page toggle pretending to be navigation.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI

  alias ScoriaWeb.IncidentEvidenceComponent
  alias ScoriaWeb.OperatorSurface

  @impl true
  def mount(_params, session, socket) do
    tenant_id = session["tenant_id"] || "default"

    {:ok,
     socket
     |> assign(:page_title, "Incident")
     |> assign(:tenant_id, tenant_id)
     |> assign(:incidents, OperatorSurface.list_tenant_incidents(tenant_id))
     |> assign(:incident, nil)
     |> assign(:incident_evidence, nil)
     |> assign(:origin_context, nil)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _uri, socket) do
    incident = OperatorSurface.fetch_tenant_incident(socket.assigns.tenant_id, id)

    socket =
      socket
      |> assign(:incident, incident)
      |> assign(:page_title, incident_title(incident))
      |> assign(:incident_evidence, evidence_for(incident))
      |> assign(
        :origin_context,
        origin_context(params["from"], socket.assigns[:scoria_base] || "")
      )

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard">
      <div :if={!@incident}>
        <.empty_state title="Incident not found">
          This incident either does not exist or is not available for the current tenant.
        </.empty_state>
      </div>

      <div :if={@incident}>
        <.object_header
          parent_label="Incidents"
          parent_path={(assigns[:scoria_base] || "") <> "/incidents"}
          object_type="Incident"
          object_id={to_string(@incident.id)}
          status={@incident.status}
          key_scalar={incident_key_scalar(@incident)}
          provenance={incident_provenance(@incident)}
          origin={@origin_context}
        />

        <.evidence_action_row class="mb-6" aria-label="Incident next steps">
          <a
            :if={@incident.workflow_run_id}
            href={incident_run_path(@incident, assigns[:scoria_base] || "")}
            class="scoria-button scoria-button--primary scoria-button--sm"
          >
            Open run
          </a>
          <a
            :if={@incident.trace_id}
            href={incident_trace_path(@incident, assigns[:scoria_base] || "")}
            class="scoria-button scoria-button--ghost scoria-button--sm"
          >
            Open trace at failing span
          </a>
        </.evidence_action_row>

        <div class="scoria-page-split--xl-reverse">
          <.panel>
            <:eyebrow>incident queue</:eyebrow>
            <:title>Tenant incidents</:title>

            <ul class="scoria-selectable-list" aria-label="Tenant incidents">
              <li :for={incident <- @incidents}>
                <.selectable_card
                  href={incident_path(incident, assigns[:scoria_base] || "")}
                  selected={incident.id == @incident.id}
                  tone={severity_tone(incident.severity)}
                  aria-current={incident.id == @incident.id && "page"}
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
          </.panel>

          <.panel>
            <:eyebrow>incident evidence</:eyebrow>
            <:title>{@incident.summary || @incident.incident_key}</:title>
            <IncidentEvidenceComponent.render :if={@incident_evidence} evidence={@incident_evidence} />
          </.panel>
        </div>
      </div>
    </div>
    """
  end

  defp evidence_for(nil), do: nil

  defp evidence_for(incident),
    do: OperatorSurface.load_incident_projection(incident.trace_id, incident.workflow_run_id)

  defp incident_title(nil), do: "Incident not found"
  defp incident_title(incident), do: incident.summary || incident.incident_key || "Incident"

  defp incident_key_scalar(incident) do
    [incident.routing_class, incident.severity]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp incident_provenance(%{last_seen_at: %DateTime{} = last_seen_at}) do
    "Last seen #{Calendar.strftime(last_seen_at, "%Y-%m-%d %H:%M")}"
  end

  defp incident_provenance(_incident), do: nil

  defp origin_context("run:" <> run_id, base_path) when run_id != "",
    do: %{noun: "run", id: run_id, path: "#{base_path}/workflows/#{run_id}"}

  defp origin_context(_from, _base_path), do: nil

  defp severity_tone("critical"), do: :fail
  defp severity_tone("warning"), do: :warn
  defp severity_tone(_), do: :info

  defp incident_path(%{id: id}, base), do: "#{base}/incidents/#{id}"

  defp incident_run_path(incident, base) do
    query = URI.encode_query([{"from", incident_origin(incident)}])
    "#{base}/workflows/#{incident.workflow_run_id}?#{query}"
  end

  defp incident_trace_path(incident, base) do
    query = URI.encode_query([{"from", incident_origin(incident)}])
    "#{home_path(base)}?#{query}#traces-#{URI.encode_www_form(to_string(incident.trace_id))}"
  end

  defp incident_origin(incident), do: "incident:#{incident.id}"
  defp home_path(""), do: "/"
  defp home_path(base), do: base

  defp short_id(nil), do: "—"
  defp short_id(id), do: id |> to_string() |> String.slice(0, 8)
end
