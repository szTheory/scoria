defmodule ScoriaWeb.Components.IncidentEvidenceComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ScoriaWeb.IncidentEvidenceComponent
  alias ScoriaWeb.RemoteInvocationEvidenceComponent

  @palette_regex ~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/

  test "incident adapter uses shared evidence primitives without raw palette classes" do
    source = File.read!("lib/scoria_web/components/incident_evidence_component.ex")

    assert source =~ "evidence_section"
    assert source =~ "evidence_rows"
    assert source =~ "scoria-incident-detail"
    refute source =~ @palette_regex
  end

  test "remote invocation adapter still uses the shared notebook primitive" do
    source = File.read!("lib/scoria_web/components/remote_invocation_evidence_component.ex")

    assert source =~ "<.notebook"
    assert source =~ "evidence_section"
    assert source =~ "evidence_rows"
    refute source =~ @palette_regex
  end

  test "renders remote invocation trace at the top-level run inspection boundary" do
    html =
      render_component(&RemoteInvocationEvidenceComponent.render/1,
        evidence: %{approvals: [%{tool_name: "summarizer", status: "approved", id: "approval-1"}]}
      )

    assert html =~ ~s(id="remote-invocation-notebook")
    assert html =~ "Remote invocation trace"
    assert html =~ "Remote trace notebook"
    refute html =~ "Remote invocation evidence"
    refute html =~ "Remote evidence notebook"
  end

  test "renders incident trace through the incident detail adapter" do
    html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

    assert html =~ ~s(id="incident-evidence-notebook")
    assert html =~ "scoria-incident-detail"
    assert html =~ "Incident trace"
    assert html =~ "Trace-first incident review"
    refute html =~ "Trace-first incident evidence"
    refute html =~ "scoria-notebook__tab"
  end

  test "uses reviewer persona copy for incident facts" do
    html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

    assert html =~ "Reviewer-facing incident facts"
    refute html =~ "Operator-facing incident facts"
  end

  test "preserves triage, budget, incident, breaker, and relay evidence sections" do
    html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

    assert html =~ "Triage summary"
    assert html =~ "Budget evidence"
    assert html =~ "Reservation actuals"
    assert html =~ "Incident evidence"
    assert html =~ "Breaker evidence"
    assert html =~ "Audit and delivery"
  end

  test "uses incident-scoped responsive classes instead of cramped nested grids" do
    source = File.read!("lib/scoria_web/components/incident_evidence_component.ex")
    css = File.read!("assets/css/04-components.css")
    html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

    assert html =~ "scoria-incident-rollup"
    assert html =~ "scoria-incident-signal"
    assert html =~ "scoria-incident-evidence-stack"
    assert css =~ ".scoria-incident-detail"
    assert css =~ ".scoria-incident-rollup"
    assert css =~ ".scoria-incident-signal"
    assert css =~ "repeat(auto-fit"
    refute source =~ "lg:grid-cols-5"
    refute source =~ "scoria-evidence-split"
  end

  test "keeps relay counts in audit delivery detail instead of signal cards" do
    html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

    rollup_text =
      html
      |> Floki.parse_document!()
      |> Floki.find(".scoria-incident-rollup")
      |> Floki.text()

    assert html =~ "Audit and delivery"
    assert html =~ "Audit outbox accepted the event"
    refute rollup_text =~ "Audit outbox accepted the event"
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
