defmodule Scoria.SRE.IncidentTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Decimal, as: D
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.{AlertEvent, Incident, IncidentEvent, NotificationDelivery}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "incident dedupe and routing" do
    test "preserves scorer and baseline evidence while creating a producer-shaped delivery row" do
      assert {:ok,
              %{
                incident: incident,
                alert_event: alert_event,
                incident_event: incident_event,
                notification_deliveries: [delivery]
              }} =
               SRE.record_alert_event(%{
                 tenant_id: "tenant-1",
                 subject_kind: "workflow",
                 policy_key: "tenant:default:quality",
                 reason_code: "ci_baseline_dip",
                 summary: "CI baseline dip on helpfulness",
                 measured_value: D.new("0.61"),
                 threshold_value: D.new("0.75"),
                 scorer_version: "scorer-v4",
                 baseline_version: "baseline-2026-05-11",
                 trace_id: "trace-baseline",
                 workflow_run_id: Ecto.UUID.generate(),
                 window_bucket: "ci:2026-05-11T18",
                 routing_class: "review"
               })

      assert incident.incident_key ==
               "tenant-1:workflow:tenant:default:quality:ci_baseline_dip:ci:2026-05-11T18"

      assert incident.severity == "warning"
      assert incident.routing_class == "review"
      assert incident.evidence_summary["scorer_version"] == "scorer-v4"
      assert incident.evidence_summary["baseline_version"] == "baseline-2026-05-11"

      assert alert_event.scorer_version_ref == "scorer-v4"
      assert alert_event.baseline_version_ref == "baseline-2026-05-11"
      assert incident_event.metadata["scorer_version"] == "scorer-v4"
      assert incident_event.metadata["baseline_version"] == "baseline-2026-05-11"
      assert delivery.sink_kind == "chimeway"
      assert delivery.routing_key == "reviews"
      assert delivery.delivery_status == "pending"
      assert delivery.metadata["routing_class"] == "review"
      assert delivery.metadata["severity"] == "warning"
      assert delivery.metadata["summary"] == "CI baseline dip on helpfulness"
      assert delivery.metadata["transport_mode"] == "unconfigured"
    end

    test "deduplicates repeated equivalent alerts into one incident while preserving alert events" do
      envelope = %{
        tenant_id: "tenant-1",
        subject_kind: "workflow",
        policy_key: "tenant:default:cost_usd",
        reason_code: "budget_fast_burn",
        summary: "Fast burn budget incident",
        measured_value: D.new("103.0"),
        threshold_value: D.new("100.0"),
        trace_id: "trace-fast-burn-1",
        workflow_run_id: Ecto.UUID.generate(),
        window_bucket: "2026-05-11T18",
        fast_burn: true
      }

      assert {:ok, %{incident: incident, notification_deliveries: [_delivery]}} =
               SRE.record_alert_event(envelope)

      assert {:ok, %{incident: repeated_incident, alert_event: repeated_event}} =
               SRE.record_alert_event(%{
                 envelope
                 | trace_id: "trace-fast-burn-2",
                   workflow_run_id: Ecto.UUID.generate()
               })

      assert incident.id == repeated_incident.id
      assert repeated_incident.severity == "critical"
      assert repeated_incident.routing_class == "page"
      assert repeated_event.status == "deduped"

      assert Repo.aggregate(from(i in Incident, where: i.tenant_id == "tenant-1"), :count) == 1

      assert Repo.aggregate(from(a in AlertEvent, where: a.incident_id == ^incident.id), :count) ==
               2

      assert Repo.aggregate(
               from(e in IncidentEvent, where: e.incident_id == ^incident.id),
               :count
             ) == 2

      assert Repo.aggregate(
               from(d in NotificationDelivery, where: d.incident_id == ^incident.id),
               :count
             ) == 1
    end

    test "review incidents escalate to page by creating a second delivery intent row" do
      run_id = Ecto.UUID.generate()

      assert {:ok, %{incident: incident, notification_deliveries: [review_delivery]}} =
               SRE.record_alert_event(%{
                 tenant_id: "tenant-escalation",
                 subject_kind: "workflow",
                 policy_key: "tenant:default:latency",
                 reason_code: "latency_spike",
                 summary: "Latency warning",
                 measured_value: D.new("90.0"),
                 threshold_value: D.new("100.0"),
                 trace_id: "trace-review",
                 workflow_run_id: run_id,
                 window_bucket: "2026-05-11T19",
                 severity: "warning",
                 routing_class: "review"
               })

      assert review_delivery.sink_kind == "chimeway"

      assert {:ok, %{incident: escalated_incident, notification_deliveries: [page_delivery]}} =
               SRE.record_alert_event(%{
                 tenant_id: "tenant-escalation",
                 subject_kind: "workflow",
                 policy_key: "tenant:default:latency",
                 reason_code: "latency_spike",
                 summary: "Latency critical",
                 measured_value: D.new("150.0"),
                 threshold_value: D.new("100.0"),
                 trace_id: "trace-page",
                 workflow_run_id: Ecto.UUID.generate(),
                 window_bucket: "2026-05-11T19",
                 severity: "critical",
                 routing_class: "page"
               })

      assert incident.id == escalated_incident.id
      assert escalated_incident.routing_class == "page"
      assert page_delivery.sink_kind == "mailglass"
      assert page_delivery.routing_key == "ops@example.com"
      assert page_delivery.metadata["routing_class"] == "page"

      deliveries =
        NotificationDelivery
        |> where([delivery], delivery.incident_id == ^incident.id)
        |> order_by([delivery], asc: delivery.inserted_at)
        |> Repo.all()

      assert Enum.map(deliveries, & &1.sink_kind) == ["chimeway", "mailglass"]
    end
  end

end
