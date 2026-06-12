defmodule ScoriaWeb.IncidentEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI, only: [badge: 1, notebook: 1]

  attr(:evidence, :map, required: true)

  def render(assigns) do
    ~H"""
    <.notebook
      id="incident-evidence-notebook"
      title="Trace-first incident notebook"
      eyebrow="Incident evidence"
      selected_tab="incident"
    >
      <:tab key="incident" label="Incident">
        <div class="space-y-4">
          <div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
            <p style="color: var(--scoria-text-muted); font-size: var(--scoria-fs-body);">
              Composite health rollup stays compact while the evidence below explains the selected run.
            </p>

            <div class="flex flex-wrap gap-2" style="font-size: var(--scoria-fs-label); color: var(--scoria-text-muted);">
              <span class="scoria-panel" style="padding: var(--scoria-space-1) var(--scoria-space-3); border-radius: var(--scoria-radius-pill);">
                trace <span style="font-family: var(--scoria-font-mono);"><%= @evidence.trace_id %></span>
              </span>
              <span
                :if={@evidence.run_id}
                class="scoria-panel"
                style="padding: var(--scoria-space-1) var(--scoria-space-3); border-radius: var(--scoria-radius-pill);"
              >
                run <span style="font-family: var(--scoria-font-mono);"><%= @evidence.run_id %></span>
              </span>
            </div>
          </div>

          <div class="grid gap-3 lg:grid-cols-5">
            <.rollup_card label="Budget" value={@evidence.health_rollup.budget_signal} detail={@evidence.health_rollup.budget_detail} />
            <.rollup_card label="Breaker" value={@evidence.health_rollup.breaker_signal} detail={@evidence.health_rollup.breaker_detail} />
            <.rollup_card label="Review incidents" value={@evidence.health_rollup.review_count} detail="Open review alerts stay visible without becoming pager noise." />
            <.rollup_card label="Page incidents" value={@evidence.health_rollup.page_count} detail="Fast burn and breaker trips remain explicit." />
            <.rollup_card label="Audit relay" value={@evidence.health_rollup.relay_signal} detail={@evidence.health_rollup.relay_detail} />
          </div>

          <div class="grid gap-4 xl:grid-cols-[1.25fr,0.9fr]">
            <div class="space-y-4">
              <section class="scoria-panel scoria-panel--raised" style="padding: var(--scoria-space-4);">
                <div class="flex items-center justify-between gap-3">
                  <div>
                    <h4 style="font-size: var(--scoria-fs-body); font-weight: 600; color: var(--scoria-text);">Budget strip</h4>
                    <p style="margin-top: var(--scoria-space-1); font-size: var(--scoria-fs-label); color: var(--scoria-text-muted);">
                      Reservation actuals, reason codes, and provider/tool refs for the selected run.
                    </p>
                  </div>
                  <.badge tone={badge_tone(@evidence.budget.status, :budget)} label={@evidence.budget.status_label} dot={false} />
                </div>

                <div class="mt-3 grid gap-3 md:grid-cols-2" style="font-size: var(--scoria-fs-body); color: var(--scoria-text-muted);">
                  <.detail_card label="Reservation actuals" value={@evidence.budget.actuals} detail={"policy #{@evidence.budget.policy_key}"} />
                  <.detail_card label="Reason and integration" value={@evidence.budget.reason_code} detail={"#{@evidence.budget.provider_ref} / #{@evidence.budget.tool_ref}"} />
                </div>
              </section>

              <section class="scoria-panel scoria-panel--raised" style="padding: var(--scoria-space-4);">
                <h4 style="font-size: var(--scoria-fs-body); font-weight: 600; color: var(--scoria-text);">Incident notebook</h4>
                <div class="mt-3 space-y-3">
                  <article :for={incident <- @evidence.incidents} class="scoria-panel" style="padding: var(--scoria-space-3);">
                    <div class="flex flex-wrap items-center justify-between gap-3">
                      <div>
                        <p style="font-size: var(--scoria-fs-body); font-weight: 600; color: var(--scoria-text);"><%= incident.summary %></p>
                        <p style="margin-top: var(--scoria-space-1); font-size: var(--scoria-fs-label); color: var(--scoria-text-muted);"><%= incident.reason_code %></p>
                      </div>
                      <div class="flex flex-wrap gap-2">
                        <.badge tone={badge_tone(incident.routing_class, :routing)} label={incident.routing_label} dot={false} />
                        <.badge tone={badge_tone(incident.severity, :severity)} label={incident.severity_label} dot={false} />
                      </div>
                    </div>

                    <div class="mt-3 grid gap-2 md:grid-cols-2" style="font-size: var(--scoria-fs-label); color: var(--scoria-text-muted);">
                      <p>scorer version <span style="font-weight: 600; color: var(--scoria-text);"><%= incident.scorer_version %></span></p>
                      <p>baseline version <span style="font-weight: 600; color: var(--scoria-text);"><%= incident.baseline_version %></span></p>
                      <p>alert reason code <span style="font-weight: 600; color: var(--scoria-text);"><%= incident.reason_code %></span></p>
                      <p>incident key <span style="font-family: var(--scoria-font-mono); color: var(--scoria-text);"><%= incident.incident_key %></span></p>
                    </div>

                    <div class="mt-3 flex flex-wrap gap-3" style="font-size: var(--scoria-fs-label);">
                      <a style="color: var(--scoria-link); text-decoration: underline;" href={"#trace-#{incident.trace_id}"}>Trace <%= incident.trace_id %></a>
                      <a :if={incident.run_id} style="color: var(--scoria-link); text-decoration: underline;" href={"#run-#{incident.run_id}"}>Run <%= incident.run_id %></a>
                      <a :if={incident.approval_id} style="color: var(--scoria-link); text-decoration: underline;" href={"#approval-#{incident.approval_id}"}>Approval <%= incident.approval_id %></a>
                    </div>
                  </article>
                </div>
              </section>
            </div>

            <div class="space-y-4">
              <section class="scoria-panel scoria-panel--raised" style="padding: var(--scoria-space-4);">
                <h4 style="font-size: var(--scoria-fs-body); font-weight: 600; color: var(--scoria-text);">Breaker and relay evidence</h4>
                <div class="mt-3 space-y-3">
                  <div class="scoria-panel" style="padding: var(--scoria-space-3);">
                    <div class="flex items-center justify-between gap-3">
                      <p style="font-size: var(--scoria-fs-body); font-weight: 600; color: var(--scoria-text);"><%= @evidence.breaker.breaker_key %></p>
                      <.badge tone={badge_tone(@evidence.breaker.state, :breaker)} label={@evidence.breaker.state_label} dot={false} />
                    </div>
                    <p style="margin-top: var(--scoria-space-2); font-size: var(--scoria-fs-label); color: var(--scoria-text-muted);"><%= @evidence.breaker.reason_code %> via <%= @evidence.breaker.integration_kind %></p>
                  </div>

                  <div
                    :for={audit <- @evidence.audit_rows}
                    class="scoria-panel"
                    style="padding: var(--scoria-space-3); font-size: var(--scoria-fs-body); color: var(--scoria-text-muted);"
                  >
                    <div class="flex items-center justify-between gap-3">
                      <p style="font-weight: 600; color: var(--scoria-text);"><%= audit.event_type %></p>
                      <.badge tone={badge_tone(audit.sink_status, :audit)} label={audit.sink_status} dot={false} />
                    </div>
                    <p style="margin-top: var(--scoria-space-1); font-size: var(--scoria-fs-label);">
                      approval <%= audit.approval_id %> · actor <%= audit.actor_ref %>
                    </p>
                  </div>
                </div>
              </section>

              <section class="scoria-panel scoria-panel--raised" style="padding: var(--scoria-space-4);">
                <h4 style="font-size: var(--scoria-fs-body); font-weight: 600; color: var(--scoria-text);">Notification delivery outcomes</h4>
                <div class="mt-3 space-y-3">
                  <div
                    :for={delivery <- @evidence.deliveries}
                    class="scoria-panel"
                    style="padding: var(--scoria-space-3); font-size: var(--scoria-fs-body); color: var(--scoria-text-muted);"
                  >
                    <div class="flex items-center justify-between gap-3">
                      <p style="font-weight: 600; color: var(--scoria-text);"><%= delivery.sink_kind %></p>
                      <.badge tone={badge_tone(delivery.delivery_status, :delivery)} label={delivery.delivery_status} dot={false} />
                    </div>
                    <p style="margin-top: var(--scoria-space-1); font-size: var(--scoria-fs-label);"><%= delivery.routing_key %></p>
                    <p style="margin-top: var(--scoria-space-2); font-size: var(--scoria-fs-label);">
                      outcome <span style="font-weight: 600; color: var(--scoria-text);"><%= delivery.delivery_outcome %></span>
                      <span :if={delivery.transport_mode}>· <%= delivery.transport_mode %></span>
                      <span :if={delivery.transport_sink}>· <%= delivery.transport_sink %></span>
                    </p>
                    <p style="margin-top: var(--scoria-space-2); font-size: var(--scoria-fs-label);">
                      attempts <%= delivery.attempt_count %>
                      <span :if={delivery.last_error}>· <%= delivery.last_error %></span>
                    </p>
                  </div>
                </div>
              </section>
            </div>
          </div>
        </div>
      </:tab>
    </.notebook>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :any, required: true)
  attr(:detail, :string, required: true)

  defp rollup_card(assigns) do
    ~H"""
    <article class="scoria-panel" style="padding: var(--scoria-space-3);">
      <p class="scoria-eyebrow"><%= @label %></p>
      <p style="margin-top: var(--scoria-space-2); font-size: var(--scoria-fs-body); font-weight: 600; color: var(--scoria-text);"><%= @value %></p>
      <p style="margin-top: var(--scoria-space-1); font-size: var(--scoria-fs-label); color: var(--scoria-text-muted);"><%= @detail %></p>
    </article>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :any, required: true)
  attr(:detail, :string, required: true)

  defp detail_card(assigns) do
    ~H"""
    <div class="scoria-panel" style="padding: var(--scoria-space-3);">
      <p class="scoria-eyebrow"><%= @label %></p>
      <p style="margin-top: var(--scoria-space-2); font-weight: 600; color: var(--scoria-text);"><%= @value %></p>
      <p style="margin-top: var(--scoria-space-1); font-size: var(--scoria-fs-label); color: var(--scoria-text-muted);"><%= @detail %></p>
    </div>
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
