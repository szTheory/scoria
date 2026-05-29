defmodule Scoria.Repo.Migrations.CreateSreBudgetAndBreakerTables do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:ai_budget_policies, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string, null: false)
      add(:policy_key, :string, null: false)
      add(:scope_key, :string, null: false)
      add(:scope_kind, :string, null: false)
      add(:resource_kind, :string, null: false)
      add(:status, :string, null: false, default: "active")
      add(:warn_threshold, :decimal, null: false, precision: 12, scale: 4)
      add(:trip_threshold, :decimal, null: false, precision: 12, scale: 4)
      add(:max_workflow_steps, :integer)
      add(:max_repeated_tool_calls, :integer)
      add(:max_consecutive_failures, :integer)
      add(:lock_version, :integer, null: false, default: 1)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:ai_budget_policies, [:tenant_id]))
    create_if_not_exists(index(:ai_budget_policies, [:policy_key]))
    create_if_not_exists(index(:ai_budget_policies, [:scope_key]))
    create_if_not_exists(index(:ai_budget_policies, [:status]))

    create_if_not_exists(
      unique_index(:ai_budget_policies, [:tenant_id, :policy_key, :scope_key, :resource_kind])
    )

    create_if_not_exists table(:ai_budget_reservations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string, null: false)
      add(:policy_id, references(:ai_budget_policies, on_delete: :nilify_all, type: :binary_id))
      add(:policy_key, :string, null: false)
      add(:scope_key, :string, null: false)
      add(:status, :string, null: false, default: "reserved")
      add(:reconciliation_status, :string, null: false, default: "pending")
      add(:resource_kind, :string, null: false)
      add(:estimated_units, :decimal, null: false, precision: 18, scale: 6)
      add(:actual_units, :decimal, precision: 18, scale: 6)
      add(:reason_code, :string, null: false)
      add(:provider_ref, :string)
      add(:tool_ref, :string)
      add(:workflow_run_id, :binary_id)
      add(:trace_id, :string)
      add(:release_reason, :string)
      add(:policy_snapshot, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:ai_budget_reservations, [:tenant_id]))
    create_if_not_exists(index(:ai_budget_reservations, [:policy_key]))
    create_if_not_exists(index(:ai_budget_reservations, [:scope_key]))
    create_if_not_exists(index(:ai_budget_reservations, [:status]))
    create_if_not_exists(index(:ai_budget_reservations, [:workflow_run_id]))
    create_if_not_exists(index(:ai_budget_reservations, [:inserted_at]))

    create_if_not_exists table(:ai_breaker_trips, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string, null: false)
      add(:breaker_key, :string, null: false)
      add(:integration_kind, :string, null: false)
      add(:reason_code, :string, null: false)
      add(:transition, :string, null: false)
      add(:state, :string, null: false)
      add(:workflow_run_id, :binary_id)
      add(:trace_id, :string)
      add(:evidence_refs, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:ai_breaker_trips, [:tenant_id]))
    create_if_not_exists(index(:ai_breaker_trips, [:breaker_key]))
    create_if_not_exists(index(:ai_breaker_trips, [:state]))
    create_if_not_exists(index(:ai_breaker_trips, [:inserted_at]))
  end
end
