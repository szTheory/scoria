defmodule Scoria.SRE.IncidentTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Decimal, as: D
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.{AlertEvent, Incident, IncidentEvent}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    ensure_incident_tables!()
    :ok
  end

  describe "incident dedupe and routing" do
    test "preserves scorer and baseline evidence on the incident and append-only event rows" do
      assert {:ok, %{incident: incident, alert_event: alert_event, incident_event: incident_event}} =
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

      assert {:ok, %{incident: incident}} = SRE.record_alert_event(envelope)

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
      assert Repo.aggregate(from(a in AlertEvent, where: a.incident_id == ^incident.id), :count) == 2
      assert Repo.aggregate(from(e in IncidentEvent, where: e.incident_id == ^incident.id), :count) == 2
    end
  end

  defp ensure_incident_tables! do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_incidents (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      incident_key varchar NOT NULL,
      severity varchar NOT NULL,
      status varchar NOT NULL DEFAULT 'open',
      summary text NOT NULL,
      routing_class varchar NOT NULL,
      dedupe_key varchar NOT NULL,
      first_seen_at timestamp(6) without time zone NOT NULL,
      last_seen_at timestamp(6) without time zone NOT NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      evidence_summary jsonb NOT NULL DEFAULT '{}'::jsonb,
      lock_version integer NOT NULL DEFAULT 1,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("CREATE UNIQUE INDEX IF NOT EXISTS ai_incidents_tenant_incident_key_idx ON ai_incidents (tenant_id, incident_key)")

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_alert_events (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      alert_policy_id uuid NULL,
      incident_id uuid NULL,
      incident_key varchar NOT NULL,
      reason_code varchar NOT NULL,
      severity varchar NOT NULL,
      status varchar NOT NULL DEFAULT 'new',
      measured_value numeric(18,6) NOT NULL,
      threshold_value numeric(18,6) NOT NULL,
      scorer_version_ref varchar NULL,
      baseline_version_ref varchar NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      evidence_refs jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_incident_events (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      incident_id uuid NOT NULL,
      alert_event_id uuid NULL,
      incident_key varchar NOT NULL,
      event_type varchar NOT NULL,
      reason_code varchar NOT NULL,
      actor_ref varchar NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      evidence_refs jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)
  end
end
