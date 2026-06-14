defmodule ScoriaWeb.IncidentEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

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
          <.evidence_section
            title="Composite health rollup"
            description="Composite health rollup stays compact while the evidence below explains the selected run."
          >
            <.evidence_rows
              rows={[
                {"trace", @evidence.trace_id},
                {"run", @evidence.run_id}
              ]}
            />

            <div class="mt-3 grid gap-3 lg:grid-cols-5">
              <.rollup_section
                label="Budget"
                value={@evidence.health_rollup.budget_signal}
                detail={@evidence.health_rollup.budget_detail}
              />
              <.rollup_section
                label="Breaker"
                value={@evidence.health_rollup.breaker_signal}
                detail={@evidence.health_rollup.breaker_detail}
              />
              <.rollup_section
                label="Review incidents"
                value={@evidence.health_rollup.review_count}
                detail="Open review alerts stay visible without becoming pager noise."
              />
              <.rollup_section
                label="Page incidents"
                value={@evidence.health_rollup.page_count}
                detail="Fast burn and breaker trips remain explicit."
              />
              <.rollup_section
                label="Audit relay"
                value={@evidence.health_rollup.relay_signal}
                detail={@evidence.health_rollup.relay_detail}
              />
            </div>
          </.evidence_section>

          <div class="scoria-evidence-split">
            <div class="space-y-4">
              <.evidence_section
                title="Budget strip"
                description="Reservation actuals, reason codes, and provider/tool refs for the selected run."
                badge={@evidence.budget.status_label}
                tone={badge_tone(@evidence.budget.status, :budget)}
              >
                <.evidence_rows
                  rows={[
                    {"Reservation actuals", @evidence.budget.actuals},
                    {"policy", @evidence.budget.policy_key},
                    {"Reason and integration", @evidence.budget.reason_code},
                    {"provider/tool", "#{@evidence.budget.provider_ref} / #{@evidence.budget.tool_ref}"}
                  ]}
                />
              </.evidence_section>

              <.evidence_section title="Incident notebook">
                <div class="space-y-3">
                  <.incident_section :for={incident <- @evidence.incidents} incident={incident} />
                </div>
              </.evidence_section>
            </div>

            <div class="space-y-4">
              <.evidence_section title="Breaker and relay evidence">
                <.evidence_section
                  title={@evidence.breaker.breaker_key}
                  description={"#{@evidence.breaker.reason_code} via #{@evidence.breaker.integration_kind}"}
                  badge={@evidence.breaker.state_label}
                  tone={badge_tone(@evidence.breaker.state, :breaker)}
                >
                  <.evidence_rows
                    rows={[
                      {"breaker key", @evidence.breaker.breaker_key},
                      {"state", @evidence.breaker.state_label},
                      {"reason code", @evidence.breaker.reason_code},
                      {"integration kind", @evidence.breaker.integration_kind}
                    ]}
                  />
                </.evidence_section>

                <div class="mt-3 space-y-3">
                  <.audit_section :for={audit <- @evidence.audit_rows} audit={audit} />
                </div>
              </.evidence_section>

              <.evidence_section title="Notification delivery outcomes">
                <div class="space-y-3">
                  <.delivery_section :for={delivery <- @evidence.deliveries} delivery={delivery} />
                </div>
              </.evidence_section>
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

  defp rollup_section(assigns) do
    ~H"""
    <.evidence_section title={@label} badge={to_string(@value)} tone={tone(@value)}>
      <.evidence_rows rows={[{"value", @value}, {"detail", @detail}]} />
    </.evidence_section>
    """
  end

  attr(:incident, :map, required: true)

  defp incident_section(assigns) do
    ~H"""
    <.evidence_section
      title={@incident.summary}
      description={@incident.reason_code}
      badge={@incident.routing_label}
      tone={badge_tone(@incident.routing_class, :routing)}
    >
      <.evidence_rows
        rows={[
          {"routing", @incident.routing_label},
          {"severity", @incident.severity_label},
          {"scorer version", @incident.scorer_version},
          {"baseline version", @incident.baseline_version},
          {"alert reason code", @incident.reason_code},
          {"incident key", @incident.incident_key}
        ]}
      />

      <.evidence_action_row>
        <a class="scoria-button scoria-button--ghost scoria-button--sm" href={"#trace-#{@incident.trace_id}"}>
          Trace <%= @incident.trace_id %>
        </a>
        <a
          :if={@incident.run_id}
          class="scoria-button scoria-button--ghost scoria-button--sm"
          href={"#run-#{@incident.run_id}"}
        >
          Run <%= @incident.run_id %>
        </a>
        <a
          :if={@incident.approval_id}
          class="scoria-button scoria-button--ghost scoria-button--sm"
          href={"#approval-#{@incident.approval_id}"}
        >
          Approval <%= @incident.approval_id %>
        </a>
      </.evidence_action_row>
    </.evidence_section>
    """
  end

  attr(:audit, :map, required: true)

  defp audit_section(assigns) do
    ~H"""
    <.evidence_section
      title={@audit.event_type}
      description={"approval #{@audit.approval_id} - actor #{@audit.actor_ref}"}
      badge={@audit.sink_status}
      tone={badge_tone(@audit.sink_status, :audit)}
    >
      <.evidence_rows
        rows={[
          {"event type", @audit.event_type},
          {"approval", @audit.approval_id},
          {"actor", @audit.actor_ref},
          {"sink status", @audit.sink_status}
        ]}
      />
    </.evidence_section>
    """
  end

  attr(:delivery, :map, required: true)

  defp delivery_section(assigns) do
    ~H"""
    <.evidence_section
      title={@delivery.sink_kind}
      description={@delivery.routing_key}
      badge={@delivery.delivery_status}
      tone={badge_tone(@delivery.delivery_status, :delivery)}
    >
      <.evidence_rows
        rows={[
          {"routing key", @delivery.routing_key},
          {"delivery status", @delivery.delivery_status},
          {"outcome", @delivery.delivery_outcome},
          {"transport mode", @delivery.transport_mode},
          {"transport sink", @delivery.transport_sink},
          {"attempts", @delivery.attempt_count},
          {"last error", @delivery.last_error}
        ]}
      />
    </.evidence_section>
    """
  end

  # Domain (value, kind) -> semantic tone atom. Rendering lives in ScoriaWeb.UI.badge/1.
  defp badge_tone("page", :routing), do: :fail
  defp badge_tone("review", :routing), do: :info
  defp badge_tone("trip", :budget), do: :fail
  defp badge_tone("warn", :budget), do: :warn
  defp badge_tone("open", :breaker), do: :fail
  defp badge_tone("failed", :delivery), do: :fail
  defp badge_tone("pending", :audit), do: :warn
  defp badge_tone(_value, _kind), do: :pass
end
