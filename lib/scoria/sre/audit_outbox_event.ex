defmodule Scoria.SRE.AuditOutboxEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @sink_statuses ~w(pending processing delivered failed)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_audit_outbox_events" do
    field(:tenant_id, :string)
    field(:event_type, :string)
    field(:policy_class, :string)
    field(:sink_status, :string, default: "pending")
    field(:dedupe_key, :string)
    field(:payload_hash, :string)
    field(:pending_at, :utc_datetime_usec)
    field(:sent_at, :utc_datetime_usec)
    field(:attempt_count, :integer, default: 0)
    field(:actor_ref, :string)
    field(:workflow_run_id, :binary_id)
    field(:step_id, :binary_id)
    field(:trace_id, :string)
    field(:redacted_refs, :map, default: %{})
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(audit_event, attrs) do
    audit_event
    |> cast(attrs, [
      :tenant_id,
      :event_type,
      :policy_class,
      :sink_status,
      :dedupe_key,
      :payload_hash,
      :pending_at,
      :sent_at,
      :attempt_count,
      :actor_ref,
      :workflow_run_id,
      :step_id,
      :trace_id,
      :redacted_refs,
      :metadata
    ])
    |> validate_required([
      :tenant_id,
      :event_type,
      :policy_class,
      :sink_status,
      :dedupe_key,
      :payload_hash,
      :pending_at,
      :attempt_count
    ])
    |> validate_inclusion(:sink_status, @sink_statuses)
    |> validate_number(:attempt_count, greater_than_or_equal_to: 0)
    |> unique_constraint([:tenant_id, :dedupe_key])
  end
end
