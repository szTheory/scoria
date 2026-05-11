defmodule Scoria.SRETest do
  use ExUnit.Case

  alias Decimal, as: D
  alias Scoria.Repo
  alias Scoria.SRE

  alias Scoria.SRE.{
    AlertEvent,
    AlertPolicy,
    AlertSink,
    AuditOutboxEvent,
    AuditSink,
    BreakerTrip,
    BudgetPolicy,
    BudgetReservation,
    Incident,
    IncidentEvent,
    NotificationDelivery
  }

  defmodule CustomAuditSink do
    @behaviour AuditSink

    @impl true
    def publish(envelope), do: {:ok, Map.put(envelope, :delivered_by, __MODULE__)}
  end

  defmodule CustomAlertSink do
    @behaviour AlertSink

    @impl true
    def publish(envelope), do: {:ok, Map.put(envelope, :delivered_by, __MODULE__)}
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    original_audit = Application.get_env(:scoria, :sre_audit_sink)
    original_alert = Application.get_env(:scoria, :sre_alert_sink)

    on_exit(fn ->
      restore_env(:sre_audit_sink, original_audit)
      restore_env(:sre_alert_sink, original_alert)
    end)

    :ok
  end

  describe "public context boundary" do
    test "exposes durable budget and breaker persistence entrypoints" do
      assert Code.ensure_loaded?(SRE)

      assert function_exported?(SRE, :create_budget_policy, 1)
      assert function_exported?(SRE, :list_budget_policies, 0)
      assert function_exported?(SRE, :get_budget_policy!, 1)
      assert function_exported?(SRE, :update_budget_policy, 2)
      assert function_exported?(SRE, :delete_budget_policy, 1)
      assert function_exported?(SRE, :reserve_usage, 1)
      assert function_exported?(SRE, :reconcile_usage, 2)
      assert function_exported?(SRE, :release_usage, 2)
      assert function_exported?(SRE, :record_breaker_trip, 1)
      assert function_exported?(SRE, :record_alert_event, 1)
      assert function_exported?(SRE, :create_audit_outbox_event, 1)
    end

    test "uses no-op sinks by default so optional integrations are not required" do
      Application.delete_env(:scoria, :sre_audit_sink)
      Application.delete_env(:scoria, :sre_alert_sink)

      assert {:ok, %{status: :noop, envelope: %{event_type: "approval.requested"}}} =
               SRE.create_audit_outbox_event(%{event_type: "approval.requested"})

      assert {:ok, %{status: :noop, envelope: %{severity: :warning}}} =
               SRE.record_alert_event(%{severity: :warning})
    end

    test "resolves configured sinks through the declared behaviors" do
      Application.put_env(:scoria, :sre_audit_sink, CustomAuditSink)
      Application.put_env(:scoria, :sre_alert_sink, CustomAlertSink)

      assert {:ok, %{delivered_by: CustomAuditSink}} =
               SRE.create_audit_outbox_event(%{event_type: "approval.approved"})

      assert {:ok, %{delivered_by: CustomAlertSink}} =
               SRE.record_alert_event(%{severity: :critical})
    end

    test "rejects sink modules that do not implement the required behavior" do
      Application.put_env(:scoria, :sre_audit_sink, Map)

      assert_raise ArgumentError, ~r/does not implement Scoria.SRE.AuditSink/, fn ->
        SRE.create_audit_outbox_event(%{event_type: "approval.denied"})
      end
    end
  end

  describe "schema changesets" do
    test "budget policy validates explicit governance fields and optimistic locking" do
      changeset = BudgetPolicy.changeset(%BudgetPolicy{}, budget_policy_attrs())
      assert changeset.valid?

      invalid =
        BudgetPolicy.changeset(%BudgetPolicy{}, %{tenant_id: "tenant-1", status: "mystery"})

      refute invalid.valid?
    end

    test "reservation and breaker trip changesets validate durable evidence fields" do
      {:ok, policy} = SRE.create_budget_policy(budget_policy_attrs())

      assert BudgetReservation.changeset(%BudgetReservation{}, reservation_attrs(policy)).valid?
      assert BreakerTrip.changeset(%BreakerTrip{}, breaker_trip_attrs()).valid?
    end

    test "alert, incident, delivery, and audit changesets validate durable routing fields" do
      assert AlertPolicy.changeset(%AlertPolicy{}, alert_policy_attrs()).valid?
      assert AlertEvent.changeset(%AlertEvent{}, alert_event_attrs()).valid?
      assert Incident.changeset(%Incident{}, incident_attrs()).valid?
      assert IncidentEvent.changeset(%IncidentEvent{}, incident_event_attrs()).valid?

      assert NotificationDelivery.changeset(
               %NotificationDelivery{},
               notification_delivery_attrs()
             ).valid?

      assert AuditOutboxEvent.changeset(%AuditOutboxEvent{}, audit_outbox_event_attrs()).valid?
    end
  end

  describe "durable budget and breaker persistence" do
    test "creates, updates, lists, and deletes versioned budget policies" do
      assert {:ok, policy} = SRE.create_budget_policy(budget_policy_attrs())

      assert policy.policy_key == "tenant:default:cost_usd"
      assert policy.scope_key == "tenant:tenant-1"
      assert policy.warn_threshold == D.new("80.0")
      assert policy.trip_threshold == D.new("100.0")

      assert [listed] = SRE.list_budget_policies()
      assert listed.id == policy.id
      assert SRE.get_budget_policy!(policy.id).id == policy.id

      assert {:ok, updated} =
               SRE.update_budget_policy(policy, %{
                 trip_threshold: D.new("110.0"),
                 max_consecutive_failures: 4
               })

      assert updated.trip_threshold == D.new("110.0")
      assert updated.max_consecutive_failures == 4

      assert {:ok, %BudgetPolicy{}} = SRE.delete_budget_policy(updated)
      assert SRE.list_budget_policies() == []
    end

    test "reserves, reconciles, and releases usage through explicit multi-backed helpers" do
      {:ok, policy} = SRE.create_budget_policy(budget_policy_attrs())

      assert {:ok, reservation} = SRE.reserve_usage(reservation_attrs(policy))
      assert reservation.status == "reserved"
      assert reservation.estimated_units == D.new("42.5")
      assert reservation.actual_units == nil
      assert reservation.policy_snapshot["policy_key"] == policy.policy_key
      assert reservation.provider_ref == "openai:gpt-5"
      assert reservation.tool_ref == "mcp.search"

      assert {:ok, reconciled} =
               SRE.reconcile_usage(reservation, %{
                 actual_units: D.new("40.0"),
                 reconciliation_status: "matched",
                 metadata: %{"source" => "provider_usage"}
               })

      assert reconciled.status == "reconciled"
      assert reconciled.actual_units == D.new("40.0")
      assert reconciled.reconciliation_status == "matched"
      assert reconciled.metadata["source"] == "provider_usage"

      assert {:ok, released} =
               SRE.release_usage(reconciled, %{
                 release_reason: "post_reconciliation_cleanup",
                 metadata: %{"released_by" => "runtime"}
               })

      assert released.status == "released"
      assert released.release_reason == "post_reconciliation_cleanup"
      assert released.metadata["released_by"] == "runtime"
    end

    test "records append-only breaker trips with evidence references" do
      assert {:ok, trip} = SRE.record_breaker_trip(breaker_trip_attrs())

      assert trip.breaker_key == "openai:gpt-5"
      assert trip.integration_kind == "provider"
      assert trip.reason_code == "provider_timeout"
      assert trip.transition == "closed_to_open"
      assert trip.state == "open"
      assert trip.evidence_refs["trace_id"] == "trace-123"
    end
  end

  describe "durable incident and audit storage nouns" do
    test "persists alert policy, incident, delivery, and audit rows with stable keys and hashed payload refs" do
      {:ok, alert_policy} =
        %AlertPolicy{}
        |> AlertPolicy.changeset(alert_policy_attrs())
        |> Repo.insert()

      {:ok, incident} =
        %Incident{}
        |> Incident.changeset(incident_attrs())
        |> Repo.insert()

      {:ok, alert_event} =
        %AlertEvent{}
        |> AlertEvent.changeset(alert_event_attrs(alert_policy, incident))
        |> Repo.insert()

      {:ok, incident_event} =
        %IncidentEvent{}
        |> IncidentEvent.changeset(incident_event_attrs(incident, alert_event))
        |> Repo.insert()

      {:ok, delivery} =
        %NotificationDelivery{}
        |> NotificationDelivery.changeset(notification_delivery_attrs(incident, alert_event))
        |> Repo.insert()

      {:ok, audit_event} =
        %AuditOutboxEvent{}
        |> AuditOutboxEvent.changeset(audit_outbox_event_attrs())
        |> Repo.insert()

      assert alert_policy.policy_key == "tenant:cost-burn:page"

      assert incident.incident_key ==
               "tenant-1:workflow:tenant:default:cost_usd:budget_fast_burn:2026-05-11T17"

      assert incident_event.event_type == "alert_linked"
      assert delivery.delivery_status == "pending"
      assert delivery.attempt_count == 1
      assert audit_event.payload_hash == "sha256:abcd1234"
      assert audit_event.redacted_refs["approval_id"] == "approval-123"
    end
  end

  defp budget_policy_attrs do
    %{
      tenant_id: "tenant-1",
      policy_key: "tenant:default:cost_usd",
      scope_key: "tenant:tenant-1",
      scope_kind: "tenant",
      resource_kind: "cost_usd",
      status: "active",
      warn_threshold: D.new("80.0"),
      trip_threshold: D.new("100.0"),
      max_workflow_steps: 25,
      max_repeated_tool_calls: 3,
      max_consecutive_failures: 2,
      metadata: %{"source" => "test"}
    }
  end

  defp reservation_attrs(policy) do
    %{
      tenant_id: policy.tenant_id,
      policy_id: policy.id,
      policy_key: policy.policy_key,
      scope_key: policy.scope_key,
      status: "reserved",
      estimated_units: D.new("42.5"),
      actual_units: nil,
      reconciliation_status: "pending",
      policy_snapshot: %{
        "policy_key" => policy.policy_key,
        "warn_threshold" => policy.warn_threshold,
        "trip_threshold" => policy.trip_threshold
      },
      resource_kind: policy.resource_kind,
      reason_code: "llm_completion",
      provider_ref: "openai:gpt-5",
      tool_ref: "mcp.search",
      workflow_run_id: Ecto.UUID.generate(),
      trace_id: "trace-123",
      metadata: %{"step" => 1}
    }
  end

  defp breaker_trip_attrs do
    %{
      tenant_id: "tenant-1",
      breaker_key: "openai:gpt-5",
      integration_kind: "provider",
      reason_code: "provider_timeout",
      transition: "closed_to_open",
      state: "open",
      workflow_run_id: Ecto.UUID.generate(),
      trace_id: "trace-123",
      evidence_refs: %{"trace_id" => "trace-123", "provider_request_id" => "req-42"},
      metadata: %{"consecutive_failures" => 3}
    }
  end

  defp alert_policy_attrs do
    %{
      tenant_id: "tenant-1",
      policy_key: "tenant:cost-burn:page",
      sli_kind: "cost",
      severity: "critical",
      routing_class: "page",
      burn_window: "5m",
      scorer_version_ref: "scorer:v2",
      baseline_version_ref: "baseline:v4",
      enabled: true,
      lock_version: 1,
      metadata: %{"channel" => "ops"}
    }
  end

  defp alert_event_attrs(alert_policy \\ nil, incident \\ nil) do
    %{
      tenant_id: "tenant-1",
      alert_policy_id: alert_policy && alert_policy.id,
      incident_id: incident && incident.id,
      incident_key: "tenant-1:workflow:tenant:default:cost_usd:budget_fast_burn:2026-05-11T17",
      reason_code: "budget_fast_burn",
      severity: "critical",
      status: "new",
      measured_value: D.new("122.5"),
      threshold_value: D.new("100.0"),
      scorer_version_ref: "scorer:v2",
      baseline_version_ref: "baseline:v4",
      workflow_run_id: Ecto.UUID.generate(),
      trace_id: "trace-123",
      evidence_refs: %{"trace_id" => "trace-123", "step_id" => Ecto.UUID.generate()},
      metadata: %{"sli_kind" => "cost"}
    }
  end

  defp incident_attrs do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %{
      tenant_id: "tenant-1",
      incident_key: "tenant-1:workflow:tenant:default:cost_usd:budget_fast_burn:2026-05-11T17",
      severity: "critical",
      status: "open",
      summary: "Cost budget is burning too quickly",
      routing_class: "page",
      dedupe_key: "tenant-1:workflow:budget_fast_burn",
      first_seen_at: now,
      last_seen_at: now,
      workflow_run_id: Ecto.UUID.generate(),
      trace_id: "trace-123",
      evidence_summary: %{"latest_reason_code" => "budget_fast_burn"},
      lock_version: 1,
      metadata: %{"source" => "runtime"}
    }
  end

  defp incident_event_attrs(incident \\ nil, alert_event \\ nil) do
    %{
      tenant_id: "tenant-1",
      incident_id: if(incident, do: incident.id, else: Ecto.UUID.generate()),
      alert_event_id: alert_event && alert_event.id,
      incident_key: "tenant-1:workflow:tenant:default:cost_usd:budget_fast_burn:2026-05-11T17",
      event_type: "alert_linked",
      reason_code: "budget_fast_burn",
      actor_ref: "system:runtime",
      workflow_run_id: Ecto.UUID.generate(),
      trace_id: "trace-123",
      evidence_refs: %{"alert_event_id" => alert_event && alert_event.id},
      metadata: %{"state" => "open"}
    }
  end

  defp notification_delivery_attrs(incident \\ nil, alert_event \\ nil) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %{
      tenant_id: "tenant-1",
      incident_id: incident && incident.id,
      alert_event_id: alert_event && alert_event.id,
      sink_kind: "chimeway",
      routing_key: "ops-primary",
      delivery_status: "pending",
      pending_at: now,
      attempt_count: 1,
      payload_hash: "sha256:beefcafe",
      last_error: nil,
      workflow_run_id: Ecto.UUID.generate(),
      trace_id: "trace-123",
      metadata: %{"delivery_class" => "page"}
    }
  end

  defp audit_outbox_event_attrs do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %{
      tenant_id: "tenant-1",
      event_type: "approval.requested",
      policy_class: "sensitive_tool",
      sink_status: "pending",
      dedupe_key: "approval.requested:approval-123",
      payload_hash: "sha256:abcd1234",
      pending_at: now,
      attempt_count: 0,
      actor_ref: "user:42",
      workflow_run_id: Ecto.UUID.generate(),
      step_id: Ecto.UUID.generate(),
      trace_id: "trace-123",
      redacted_refs: %{"approval_id" => "approval-123", "tool_name" => "deploy_prod"},
      metadata: %{"policy_result" => "review_required"}
    }
  end

  defp restore_env(_key, nil), do: :ok

  defp restore_env(key, value) do
    Application.put_env(:scoria, key, value)
  end
end
