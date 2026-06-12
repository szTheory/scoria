defmodule ScoriaWeb.Components.IncidentEvidenceComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ScoriaWeb.IncidentEvidenceComponent

  test "renders incident evidence through the notebook adapter" do
    html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

    assert html =~ ~s(id="incident-evidence-notebook")
    assert html =~ "scoria-notebook"
    assert html =~ "Trace-first incident notebook"
  end

  test "preserves health rollup, budget, notebook, breaker relay, and delivery sections" do
    html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

    assert html =~ "Composite health rollup"
    assert html =~ "Budget strip"
    assert html =~ "Reservation actuals"
    assert html =~ "Incident notebook"
    assert html =~ "Breaker and relay evidence"
    assert html =~ "Notification delivery outcomes"
  end

  test "escapes raw evidence values through HEEx" do
    html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

    refute html =~ "<script>alert(&quot;incident&quot;)</script>"
    assert html =~ "&lt;script&gt;alert(&quot;incident&quot;)&lt;/script&gt;"
  end

  defp evidence do
    %{
      trace_id: "trace-incident",
      run_id: "run-incident",
      health_rollup: %{
        budget_signal: "Budget steady",
        budget_detail: "No hard cap exceeded",
        breaker_signal: "Breaker closed",
        breaker_detail: "Fallback chain healthy",
        review_count: 2,
        page_count: 1,
        relay_signal: "Relay delivered",
        relay_detail: "Audit outbox accepted the event"
      },
      budget: %{
        status: "warn",
        status_label: "Budget warning",
        actuals: "1,024 tokens",
        policy_key: "tenant-cap",
        reason_code: "budget.soft_limit",
        provider_ref: "openai",
        tool_ref: "summarizer"
      },
      incidents: [
        %{
          summary: "Unsafe raw value <script>alert(\"incident\")</script>",
          reason_code: "incident.policy",
          routing_class: "page",
          routing_label: "Page incident",
          severity: "critical",
          severity_label: "Critical severity",
          scorer_version: "score-v1",
          baseline_version: "base-v1",
          incident_key: "incident-key",
          trace_id: "trace-incident",
          run_id: "run-incident",
          approval_id: "approval-incident"
        }
      ],
      breaker: %{
        breaker_key: "model-provider",
        state: "open",
        state_label: "Open",
        reason_code: "breaker.open",
        integration_kind: "provider"
      },
      audit_rows: [
        %{
          event_type: "approval.requested",
          sink_status: "pending",
          approval_id: "approval-incident",
          actor_ref: "operator"
        }
      ],
      deliveries: [
        %{
          sink_kind: "pager",
          delivery_status: "failed",
          routing_key: "sre-primary",
          delivery_outcome: "retry scheduled",
          transport_mode: "webhook",
          transport_sink: "pagerduty",
          attempt_count: 2,
          last_error: "timeout"
        }
      ]
    }
  end
end
