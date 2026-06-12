defmodule ScoriaWeb.IncidentsLive.Index do
  @moduledoc """
  Incidents — tenant-level SRE triage. Lists the tenant's incidents newest-first
  and renders the trace-first incident evidence notebook for the selected one.
  Extracted from the Live Ops god-page (where incident evidence was only
  reachable per-trace) so incident history is a focused, linkable surface.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI

  alias ScoriaWeb.IncidentEvidenceComponent
  alias ScoriaWeb.OperatorSurface

  @impl true
  def mount(params, session, socket) do
    tenant_id = (is_map(params) && params["tenant"]) || session["tenant_id"] || "default"
    incidents = OperatorSurface.list_tenant_incidents(tenant_id)
    selected = List.first(incidents)

    socket =
      socket
      |> assign(:page_title, "Incidents")
      |> assign(:tenant_id, tenant_id)
      |> assign(:incidents, incidents)
      |> assign(:summary, OperatorSurface.incidents_summary(tenant_id))
      |> assign(:selected_incident, selected)
      |> assign(:selected_incident_id, selected && selected.id)
      |> assign(:incident_evidence, evidence_for(selected))

    {:ok, socket}
  end

  @impl true
  def handle_event("select_incident", %{"id" => id}, socket) do
    case Enum.find(socket.assigns.incidents, &(to_string(&1.id) == id)) do
      nil ->
        {:noreply, socket}

      incident ->
        {:noreply,
         socket
         |> assign(:selected_incident, incident)
         |> assign(:selected_incident_id, incident.id)
         |> assign(:incident_evidence, evidence_for(incident))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <div class="scoria-pagehead">
        <h1>Incidents</h1>
        <p class="text-stone-600 mt-1">
          SRE triage for this tenant. Select an incident to inspect its trace-first evidence — budget, breaker, alerts, and audit relay.
        </p>
      </div>

      <div :if={@incidents == []}>
        <.empty_state title="No incidents">
          Budget trips, breaker openings, and policy regressions surface here with full trace evidence once they fire.
        </.empty_state>
      </div>

      <div :if={@incidents != []}>
        <div class="grid gap-4 sm:grid-cols-3 mb-6">
          <.metric label="Open incidents" value={to_string(@summary.open)} />
          <.metric label="Review queue" value={to_string(@summary.review)} />
          <.metric label="Paging" value={to_string(@summary.page)} />
        </div>

        <div class="grid gap-6 xl:grid-cols-[0.85fr,1.15fr]">
          <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
            <p class="text-xs uppercase tracking-[0.24em] text-stone-500">incident history</p>
            <h2 class="text-lg font-semibold text-stone-900">Tenant incidents</h2>

            <div class="mt-4 space-y-2">
              <button
                :for={incident <- @incidents}
                type="button"
                phx-click="select_incident"
                phx-value-id={incident.id}
                class={[
                  "w-full rounded-xl border p-3 text-left transition",
                  if(incident.id == @selected_incident_id,
                    do: "border-stone-400 bg-stone-50",
                    else: "border-stone-200 hover:border-stone-300"
                  )
                ]}
                aria-current={incident.id == @selected_incident_id && "true"}
              >
                <div class="flex items-start justify-between gap-3">
                  <p class="text-sm font-semibold text-stone-900"><%= incident.summary || incident.incident_key %></p>
                  <.badge tone={severity_tone(incident.severity)} label={incident.severity} />
                </div>
                <div class="mt-2 flex flex-wrap items-center gap-2 text-xs">
                  <.badge tone={routing_tone(incident.routing_class)} label={incident.routing_class} dot={false} />
                  <.badge tone={status_tone(incident.status)} label={incident.status} dot={false} />
                  <span :if={incident.trace_id} class="text-stone-500">
                    trace <.id value={short_id(incident.trace_id)} copy={incident.trace_id} />
                  </span>
                </div>
              </button>
            </div>
          </section>

          <div>
            <div :if={@selected_incident} class="mb-4 flex flex-wrap gap-3">
              <a
                :if={@selected_incident.workflow_run_id}
                href={incident_run_path(@selected_incident, assigns[:scoria_base] || "")}
                class="scoria-button scoria-button--primary scoria-button--sm"
              >
                Open run
              </a>
              <a
                :if={@selected_incident.trace_id}
                href={incident_trace_path(@selected_incident, assigns[:scoria_base] || "")}
                class="scoria-button scoria-button--ghost scoria-button--sm"
              >
                Open trace at failing span
              </a>
            </div>
            <IncidentEvidenceComponent.render :if={@incident_evidence} evidence={@incident_evidence} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp evidence_for(nil), do: nil

  defp evidence_for(incident),
    do: OperatorSurface.load_incident_projection(incident.trace_id, incident.workflow_run_id)

  defp severity_tone("critical"), do: :fail
  defp severity_tone("warning"), do: :warn
  defp severity_tone(_), do: :info

  defp routing_tone("page"), do: :fail
  defp routing_tone(_), do: :info

  defp status_tone("open"), do: :warn
  defp status_tone(status) when status in ["resolved", "closed"], do: :pass
  defp status_tone(_), do: :neutral

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
