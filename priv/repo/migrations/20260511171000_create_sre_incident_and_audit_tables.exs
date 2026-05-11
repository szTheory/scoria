defmodule Scoria.Repo.Migrations.CreateSreIncidentAndAuditTables do
  use Ecto.Migration

  def change do
    create table(:ai_alert_policies, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string, null: false)
      add(:policy_key, :string, null: false)
      add(:sli_kind, :string, null: false)
      add(:severity, :string, null: false)
      add(:routing_class, :string, null: false)
      add(:burn_window, :string, null: false)
      add(:scorer_version_ref, :string)
      add(:baseline_version_ref, :string)
      add(:enabled, :boolean, null: false, default: true)
      add(:lock_version, :integer, null: false, default: 1)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_alert_policies, [:tenant_id]))
    create(index(:ai_alert_policies, [:policy_key]))
    create(index(:ai_alert_policies, [:severity]))
    create(index(:ai_alert_policies, [:enabled]))
    create(unique_index(:ai_alert_policies, [:tenant_id, :policy_key, :sli_kind]))

    create table(:ai_incidents, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string, null: false)
      add(:incident_key, :string, null: false)
      add(:severity, :string, null: false)
      add(:status, :string, null: false, default: "open")
      add(:summary, :text, null: false)
      add(:routing_class, :string, null: false)
      add(:dedupe_key, :string, null: false)
      add(:first_seen_at, :utc_datetime_usec, null: false)
      add(:last_seen_at, :utc_datetime_usec, null: false)
      add(:workflow_run_id, :binary_id)
      add(:trace_id, :string)
      add(:evidence_summary, :map, null: false, default: %{})
      add(:lock_version, :integer, null: false, default: 1)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_incidents, [:tenant_id]))
    create(index(:ai_incidents, [:incident_key]))
    create(index(:ai_incidents, [:severity]))
    create(index(:ai_incidents, [:status]))
    create(unique_index(:ai_incidents, [:tenant_id, :incident_key]))

    create table(:ai_alert_events, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string, null: false)

      add(
        :alert_policy_id,
        references(:ai_alert_policies, on_delete: :nilify_all, type: :binary_id)
      )

      add(:incident_id, references(:ai_incidents, on_delete: :nilify_all, type: :binary_id))
      add(:incident_key, :string, null: false)
      add(:reason_code, :string, null: false)
      add(:severity, :string, null: false)
      add(:status, :string, null: false, default: "new")
      add(:measured_value, :decimal, null: false, precision: 18, scale: 6)
      add(:threshold_value, :decimal, null: false, precision: 18, scale: 6)
      add(:scorer_version_ref, :string)
      add(:baseline_version_ref, :string)
      add(:workflow_run_id, :binary_id)
      add(:trace_id, :string)
      add(:evidence_refs, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_alert_events, [:tenant_id]))
    create(index(:ai_alert_events, [:incident_key]))
    create(index(:ai_alert_events, [:severity]))
    create(index(:ai_alert_events, [:status]))
    create(index(:ai_alert_events, [:inserted_at]))

    create table(:ai_incident_events, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string, null: false)

      add(:incident_id, references(:ai_incidents, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      add(:alert_event_id, references(:ai_alert_events, on_delete: :nilify_all, type: :binary_id))
      add(:incident_key, :string, null: false)
      add(:event_type, :string, null: false)
      add(:reason_code, :string, null: false)
      add(:actor_ref, :string)
      add(:workflow_run_id, :binary_id)
      add(:trace_id, :string)
      add(:evidence_refs, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_incident_events, [:tenant_id]))
    create(index(:ai_incident_events, [:incident_key]))
    create(index(:ai_incident_events, [:inserted_at]))

    create table(:ai_notification_deliveries, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string, null: false)
      add(:incident_id, references(:ai_incidents, on_delete: :nilify_all, type: :binary_id))
      add(:alert_event_id, references(:ai_alert_events, on_delete: :nilify_all, type: :binary_id))
      add(:sink_kind, :string, null: false)
      add(:routing_key, :string, null: false)
      add(:delivery_status, :string, null: false, default: "pending")
      add(:pending_at, :utc_datetime_usec, null: false)
      add(:last_attempt_at, :utc_datetime_usec)
      add(:delivered_at, :utc_datetime_usec)
      add(:attempt_count, :integer, null: false, default: 0)
      add(:payload_hash, :string, null: false)
      add(:last_error, :string)
      add(:workflow_run_id, :binary_id)
      add(:trace_id, :string)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_notification_deliveries, [:tenant_id]))
    create(index(:ai_notification_deliveries, [:delivery_status]))
    create(index(:ai_notification_deliveries, [:pending_at]))
    create(index(:ai_notification_deliveries, [:inserted_at]))

    create table(:ai_audit_outbox_events, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string, null: false)
      add(:event_type, :string, null: false)
      add(:policy_class, :string, null: false)
      add(:sink_status, :string, null: false, default: "pending")
      add(:dedupe_key, :string, null: false)
      add(:payload_hash, :string, null: false)
      add(:pending_at, :utc_datetime_usec, null: false)
      add(:sent_at, :utc_datetime_usec)
      add(:attempt_count, :integer, null: false, default: 0)
      add(:actor_ref, :string)
      add(:workflow_run_id, :binary_id)
      add(:step_id, :binary_id)
      add(:trace_id, :string)
      add(:redacted_refs, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_audit_outbox_events, [:tenant_id]))
    create(index(:ai_audit_outbox_events, [:sink_status]))
    create(index(:ai_audit_outbox_events, [:pending_at]))
    create(index(:ai_audit_outbox_events, [:inserted_at]))
    create(unique_index(:ai_audit_outbox_events, [:tenant_id, :dedupe_key]))
  end
end
