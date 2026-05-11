defmodule Scoria.SRE.BudgetReservation do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(reserved reconciled released tripped)
  @reconciliation_statuses ~w(pending matched overage released)
  @resource_kinds ~w(token_in token_out cost_usd tool_calls workflow_steps)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_budget_reservations" do
    field(:tenant_id, :string)
    field(:policy_key, :string)
    field(:scope_key, :string)
    field(:status, :string, default: "reserved")
    field(:reconciliation_status, :string, default: "pending")
    field(:resource_kind, :string)
    field(:estimated_units, :decimal)
    field(:actual_units, :decimal)
    field(:reason_code, :string)
    field(:provider_ref, :string)
    field(:tool_ref, :string)
    field(:workflow_run_id, :binary_id)
    field(:trace_id, :string)
    field(:release_reason, :string)
    field(:policy_snapshot, :map, default: %{})
    field(:metadata, :map, default: %{})

    belongs_to(:policy, Scoria.SRE.BudgetPolicy)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, [
      :tenant_id,
      :policy_id,
      :policy_key,
      :scope_key,
      :status,
      :reconciliation_status,
      :resource_kind,
      :estimated_units,
      :actual_units,
      :reason_code,
      :provider_ref,
      :tool_ref,
      :workflow_run_id,
      :trace_id,
      :release_reason,
      :policy_snapshot,
      :metadata
    ])
    |> validate_required([
      :tenant_id,
      :policy_key,
      :scope_key,
      :status,
      :reconciliation_status,
      :resource_kind,
      :estimated_units,
      :reason_code
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:reconciliation_status, @reconciliation_statuses)
    |> validate_inclusion(:resource_kind, @resource_kinds)
    |> foreign_key_constraint(:policy_id)
  end
end
