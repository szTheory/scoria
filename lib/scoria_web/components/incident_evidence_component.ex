defmodule ScoriaWeb.IncidentEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:evidence, :map, required: true)

  def render(assigns) do
    ~H"""
    <section
      id="incident-evidence-notebook"
      class="scoria-incident-detail"
      aria-labelledby="incident-evidence-title"
    >
      <header class="scoria-incident-detail__header">
        <p class="scoria-eyebrow">Incident trace</p>
        <h2 id="incident-evidence-title" class="scoria-incident-detail__title">
          Trace-first incident review
        </h2>
        <p class="scoria-incident-detail__description">
          Start with the selected run state, then inspect the proof behind the route, budget, breaker, and relay signals.
        </p>
      </header>

      <div class="scoria-incident-evidence-stack">
        <.evidence_section
          title="Triage summary"
          description="What changed, why it routed, and which trace/run to open next."
        >
          <.evidence_rows
            rows={[
              {"trace", @evidence.trace_id},
              {"run", @evidence.run_id},
              {"review queue", @evidence.health_rollup.review_count},
              {"paging", @evidence.health_rollup.page_count}
            ]}
          />

          <div class="scoria-incident-rollup" aria-label="Selected incident health signals">
            <.signal_card
              label="Budget"
              value={@evidence.health_rollup.budget_signal}
              detail={@evidence.health_rollup.budget_detail}
              tone={badge_tone(@evidence.budget.status, :budget)}
            />
            <.signal_card
              label="Breaker"
              value={@evidence.health_rollup.breaker_signal}
              detail={@evidence.health_rollup.breaker_detail}
              tone={badge_tone(@evidence.breaker.state, :breaker)}
            />
            <.signal_card
              label="Audit relay"
              value={@evidence.health_rollup.relay_signal}
              detail="Delivery and audit evidence is listed below."
              tone={relay_tone(@evidence.health_rollup.relay_signal)}
            />
          </div>
        </.evidence_section>

        <.evidence_section
          title="Incident evidence"
          description="Reviewer-facing incident facts before raw transport and persistence details."
        >
          <div class="scoria-incident-evidence-stack scoria-incident-evidence-stack--compact">
            <.incident_section :for={incident <- @evidence.incidents} incident={incident} />
          </div>
        </.evidence_section>

        <.evidence_section
          title="Budget evidence"
          description="Reservation actuals, policy, reason, and provider/tool references."
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

        <.evidence_section
          title="Breaker evidence"
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

        <.evidence_section
          title="Audit and delivery"
          description={@evidence.health_rollup.relay_detail}
          badge={@evidence.health_rollup.relay_signal}
          tone={relay_tone(@evidence.health_rollup.relay_signal)}
        >
          <div
            :if={@evidence.audit_rows == [] and @evidence.deliveries == []}
            class="scoria-incident-empty-evidence"
          >
            No audit rows or delivery outcomes have been recorded for this trace yet.
          </div>

          <div
            :if={@evidence.audit_rows != [] or @evidence.deliveries != []}
            class="scoria-incident-evidence-stack scoria-incident-evidence-stack--compact"
          >
            <.audit_section :for={audit <- @evidence.audit_rows} audit={audit} />
            <.delivery_section :for={delivery <- @evidence.deliveries} delivery={delivery} />
          </div>
        </.evidence_section>
      </div>
    </section>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :any, required: true)
  attr(:detail, :string, required: true)
  attr(:tone, :atom, default: :neutral)

  defp signal_card(assigns) do
    ~H"""
    <article class={["scoria-incident-signal", "scoria-incident-signal--#{@tone}"]}>
      <p class="scoria-incident-signal__label">{@label}</p>
      <p class="scoria-incident-signal__value">{@value}</p>
      <p class="scoria-incident-signal__detail">{@detail}</p>
    </article>
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

  defp relay_tone("Relay degraded"), do: :fail
  defp relay_tone("Relay pending"), do: :warn
  defp relay_tone("Relay healthy"), do: :pass
  defp relay_tone("Relay quiet"), do: :neutral
  defp relay_tone(_value), do: :neutral
end
