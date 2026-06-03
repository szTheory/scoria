defmodule ScoriaWeb.IncidentEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI, only: [badge: 1]

  attr(:evidence, :map, required: true)

  def render(assigns) do
    ~H"""
    <section class="rounded-xl border border-stone-200 bg-stone-50 p-4 shadow-sm">
      <div class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <p class="text-xs uppercase tracking-[0.24em] text-stone-500">incident evidence</p>
          <h3 class="text-lg font-semibold text-stone-900">Trace-first incident notebook</h3>
          <p class="mt-1 text-sm text-stone-600">
            Composite health rollup stays compact while the evidence below explains the selected run.
          </p>
        </div>

        <div class="flex flex-wrap gap-2 text-xs text-stone-700">
          <span class="rounded-full border border-stone-300 bg-white px-3 py-1">
            trace <span class="font-mono"><%= @evidence.trace_id %></span>
          </span>
          <span :if={@evidence.run_id} class="rounded-full border border-stone-300 bg-white px-3 py-1">
            run <span class="font-mono"><%= @evidence.run_id %></span>
          </span>
        </div>
      </div>

      <div class="grid gap-3 lg:grid-cols-5">
        <div class="rounded-lg border border-stone-200 bg-white p-3">
          <p class="text-[11px] uppercase tracking-[0.22em] text-stone-500">Budget</p>
          <p class="mt-2 text-sm font-semibold text-stone-900"><%= @evidence.health_rollup.budget_signal %></p>
          <p class="mt-1 text-xs text-stone-600"><%= @evidence.health_rollup.budget_detail %></p>
        </div>

        <div class="rounded-lg border border-stone-200 bg-white p-3">
          <p class="text-[11px] uppercase tracking-[0.22em] text-stone-500">Breaker</p>
          <p class="mt-2 text-sm font-semibold text-stone-900"><%= @evidence.health_rollup.breaker_signal %></p>
          <p class="mt-1 text-xs text-stone-600"><%= @evidence.health_rollup.breaker_detail %></p>
        </div>

        <div class="rounded-lg border border-stone-200 bg-white p-3">
          <p class="text-[11px] uppercase tracking-[0.22em] text-stone-500">Review incidents</p>
          <p class="mt-2 text-sm font-semibold text-stone-900"><%= @evidence.health_rollup.review_count %></p>
          <p class="mt-1 text-xs text-stone-600">Open review alerts stay visible without becoming pager noise.</p>
        </div>

        <div class="rounded-lg border border-stone-200 bg-white p-3">
          <p class="text-[11px] uppercase tracking-[0.22em] text-stone-500">Page incidents</p>
          <p class="mt-2 text-sm font-semibold text-stone-900"><%= @evidence.health_rollup.page_count %></p>
          <p class="mt-1 text-xs text-stone-600">Fast burn and breaker trips remain explicit.</p>
        </div>

        <div class="rounded-lg border border-stone-200 bg-white p-3">
          <p class="text-[11px] uppercase tracking-[0.22em] text-stone-500">Audit relay</p>
          <p class="mt-2 text-sm font-semibold text-stone-900"><%= @evidence.health_rollup.relay_signal %></p>
          <p class="mt-1 text-xs text-stone-600"><%= @evidence.health_rollup.relay_detail %></p>
        </div>
      </div>

      <div class="mt-4 grid gap-4 xl:grid-cols-[1.25fr,0.9fr]">
        <div class="space-y-4">
          <div class="rounded-lg border border-stone-200 bg-white p-4">
            <div class="flex items-center justify-between gap-3">
              <div>
                <h4 class="text-sm font-semibold text-stone-900">Budget strip</h4>
                <p class="mt-1 text-xs text-stone-600">
                  Reservation actuals, reason codes, and provider/tool refs for the selected run.
                </p>
              </div>
              <.badge tone={badge_tone(@evidence.budget.status, :budget)} label={@evidence.budget.status_label} dot={false} />
            </div>

            <div class="mt-3 grid gap-3 md:grid-cols-2 text-sm text-stone-700">
              <div class="rounded-md bg-stone-50 p-3">
                <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Reservation actuals</p>
                <p class="mt-2 font-medium"><%= @evidence.budget.actuals %></p>
                <p class="mt-1 text-xs text-stone-500">policy <%= @evidence.budget.policy_key %></p>
              </div>

              <div class="rounded-md bg-stone-50 p-3">
                <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Reason and integration</p>
                <p class="mt-2 font-medium"><%= @evidence.budget.reason_code %></p>
                <p class="mt-1 text-xs text-stone-500">
                  <%= @evidence.budget.provider_ref %> / <%= @evidence.budget.tool_ref %>
                </p>
              </div>
            </div>
          </div>

          <div class="rounded-lg border border-stone-200 bg-white p-4">
            <h4 class="text-sm font-semibold text-stone-900">Incident notebook</h4>
            <div class="mt-3 space-y-3">
              <article :for={incident <- @evidence.incidents} class="rounded-lg border border-stone-200 p-3">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <p class="text-sm font-semibold text-stone-900"><%= incident.summary %></p>
                    <p class="mt-1 text-xs text-stone-500"><%= incident.reason_code %></p>
                  </div>
                  <div class="flex flex-wrap gap-2">
                    <.badge tone={badge_tone(incident.routing_class, :routing)} label={incident.routing_label} dot={false} />
                    <.badge tone={badge_tone(incident.severity, :severity)} label={incident.severity_label} dot={false} />
                  </div>
                </div>

                <div class="mt-3 grid gap-2 text-xs text-stone-600 md:grid-cols-2">
                  <p>scorer version <span class="font-medium text-stone-900"><%= incident.scorer_version %></span></p>
                  <p>baseline version <span class="font-medium text-stone-900"><%= incident.baseline_version %></span></p>
                  <p>alert reason code <span class="font-medium text-stone-900"><%= incident.reason_code %></span></p>
                  <p>incident key <span class="font-mono text-[11px] text-stone-800"><%= incident.incident_key %></span></p>
                </div>

                <div class="mt-3 flex flex-wrap gap-3 text-xs">
                  <a class="text-blue-700 underline" href={"#trace-#{incident.trace_id}"}>Trace <%= incident.trace_id %></a>
                  <a :if={incident.run_id} class="text-blue-700 underline" href={"#run-#{incident.run_id}"}>Run <%= incident.run_id %></a>
                  <a :if={incident.approval_id} class="text-blue-700 underline" href={"#approval-#{incident.approval_id}"}>Approval <%= incident.approval_id %></a>
                </div>
              </article>
            </div>
          </div>
        </div>

        <div class="space-y-4">
          <div class="rounded-lg border border-stone-200 bg-white p-4">
            <h4 class="text-sm font-semibold text-stone-900">Breaker and relay evidence</h4>
            <div class="mt-3 space-y-3">
              <div class="rounded-md bg-stone-50 p-3">
                <div class="flex items-center justify-between gap-3">
                  <p class="text-sm font-medium text-stone-900"><%= @evidence.breaker.breaker_key %></p>
                  <.badge tone={badge_tone(@evidence.breaker.state, :breaker)} label={@evidence.breaker.state_label} dot={false} />
                </div>
                <p class="mt-2 text-xs text-stone-600"><%= @evidence.breaker.reason_code %> via <%= @evidence.breaker.integration_kind %></p>
              </div>

              <div :for={audit <- @evidence.audit_rows} class="rounded-md bg-stone-50 p-3 text-sm text-stone-700">
                <div class="flex items-center justify-between gap-3">
                  <p class="font-medium text-stone-900"><%= audit.event_type %></p>
                  <.badge tone={badge_tone(audit.sink_status, :audit)} label={audit.sink_status} dot={false} />
                </div>
                <p class="mt-1 text-xs text-stone-500">
                  approval <%= audit.approval_id %> · actor <%= audit.actor_ref %>
                </p>
              </div>
            </div>
          </div>

          <div class="rounded-lg border border-stone-200 bg-white p-4">
            <h4 class="text-sm font-semibold text-stone-900">Notification delivery outcomes</h4>
            <div class="mt-3 space-y-3">
              <div :for={delivery <- @evidence.deliveries} class="rounded-md bg-stone-50 p-3 text-sm text-stone-700">
                <div class="flex items-center justify-between gap-3">
                  <p class="font-medium text-stone-900"><%= delivery.sink_kind %></p>
                  <.badge tone={badge_tone(delivery.delivery_status, :delivery)} label={delivery.delivery_status} dot={false} />
                </div>
                <p class="mt-1 text-xs text-stone-500"><%= delivery.routing_key %></p>
                <p class="mt-2 text-xs text-stone-600">
                  outcome <span class="font-medium text-stone-900"><%= delivery.delivery_outcome %></span>
                  <span :if={delivery.transport_mode}>· <%= delivery.transport_mode %></span>
                  <span :if={delivery.transport_sink}>· <%= delivery.transport_sink %></span>
                </p>
                <p class="mt-2 text-xs text-stone-600">
                  attempts <%= delivery.attempt_count %>
                  <span :if={delivery.last_error}>· <%= delivery.last_error %></span>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  # Domain (value, kind) → semantic tone atom. Rendering lives in ScoriaWeb.UI.badge/1.
  defp badge_tone("critical", :severity), do: :fail
  defp badge_tone("warning", :severity), do: :warn
  defp badge_tone("page", :routing), do: :fail
  defp badge_tone("review", :routing), do: :info
  defp badge_tone("trip", :budget), do: :fail
  defp badge_tone("warn", :budget), do: :warn
  defp badge_tone("open", :breaker), do: :fail
  defp badge_tone("failed", :delivery), do: :fail
  defp badge_tone("pending", :audit), do: :warn
  defp badge_tone(_value, _kind), do: :pass
end
