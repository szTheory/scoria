defmodule Scoria.SRE.BudgetPolicy do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(active disabled)
  @resource_kinds ~w(token_in token_out cost_usd tool_calls workflow_steps)
  @scope_kinds ~w(global tenant actor workflow)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_budget_policies" do
    field(:tenant_id, :string)
    field(:policy_key, :string)
    field(:scope_key, :string)
    field(:scope_kind, :string)
    field(:resource_kind, :string)
    field(:status, :string, default: "active")
    field(:warn_threshold, :decimal)
    field(:trip_threshold, :decimal)
    field(:max_workflow_steps, :integer)
    field(:max_repeated_tool_calls, :integer)
    field(:max_consecutive_failures, :integer)
    field(:lock_version, :integer, default: 1)
    field(:metadata, :map, default: %{})

    has_many(:reservations, Scoria.SRE.BudgetReservation, foreign_key: :policy_id)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(policy, attrs) do
    policy
    |> cast(attrs, [
      :tenant_id,
      :policy_key,
      :scope_key,
      :scope_kind,
      :resource_kind,
      :status,
      :warn_threshold,
      :trip_threshold,
      :max_workflow_steps,
      :max_repeated_tool_calls,
      :max_consecutive_failures,
      :lock_version,
      :metadata
    ])
    |> validate_required([
      :tenant_id,
      :policy_key,
      :scope_key,
      :scope_kind,
      :resource_kind,
      :status,
      :warn_threshold,
      :trip_threshold
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:resource_kind, @resource_kinds)
    |> validate_inclusion(:scope_kind, @scope_kinds)
    |> optimistic_lock(:lock_version)
    |> unique_constraint([:tenant_id, :policy_key, :scope_key, :resource_kind])
  end
end
