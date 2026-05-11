defmodule Scoria.SRE.AlertPolicy do
  use Ecto.Schema
  import Ecto.Changeset

  @severities ~w(info warning critical)
  @routing_classes ~w(review page ticket)
  @sli_kinds ~w(latency quality cost tool_reliability)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_alert_policies" do
    field(:tenant_id, :string)
    field(:policy_key, :string)
    field(:sli_kind, :string)
    field(:severity, :string)
    field(:routing_class, :string)
    field(:burn_window, :string)
    field(:scorer_version_ref, :string)
    field(:baseline_version_ref, :string)
    field(:enabled, :boolean, default: true)
    field(:lock_version, :integer, default: 1)
    field(:metadata, :map, default: %{})

    has_many(:alert_events, Scoria.SRE.AlertEvent)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(policy, attrs) do
    policy
    |> cast(attrs, [
      :tenant_id,
      :policy_key,
      :sli_kind,
      :severity,
      :routing_class,
      :burn_window,
      :scorer_version_ref,
      :baseline_version_ref,
      :enabled,
      :lock_version,
      :metadata
    ])
    |> validate_required([
      :tenant_id,
      :policy_key,
      :sli_kind,
      :severity,
      :routing_class,
      :burn_window
    ])
    |> validate_inclusion(:sli_kind, @sli_kinds)
    |> validate_inclusion(:severity, @severities)
    |> validate_inclusion(:routing_class, @routing_classes)
    |> optimistic_lock(:lock_version)
    |> unique_constraint([:tenant_id, :policy_key, :sli_kind])
  end
end
