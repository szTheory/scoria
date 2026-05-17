defmodule Scoria.Workflows.Run do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(running waiting_for_approval paused retrying failed completed cancelled)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_workflow_runs" do
    field :actor_id, :string
    field :tenant_id, :string
    field :session_id, :string
    field :root_role_id, :string
    field :status, :string, default: "running"
    field :current_step_id, :binary_id
    field :latest_checkpoint_id, :binary_id
    field :lock_version, :integer, default: 1
    field :metadata, :map, default: %{}
    field :error_envelope, :map, default: %{}
    field :started_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec
    field :last_heartbeat_at, :utc_datetime_usec

    has_many :steps, Scoria.Workflows.Step
    has_many :checkpoints, Scoria.Workflows.Checkpoint
    has_many :events, Scoria.Workflows.Event
    has_many :handoffs, Scoria.Workflows.Handoff
    has_many :approvals, Scoria.Observe.Approval, foreign_key: :workflow_run_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :session_id,
      :actor_id,
      :tenant_id,
      :root_role_id,
      :status,
      :current_step_id,
      :latest_checkpoint_id,
      :lock_version,
      :metadata,
      :error_envelope,
      :started_at,
      :completed_at,
      :last_heartbeat_at
    ])
    |> validate_required([:root_role_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> optimistic_lock(:lock_version)
  end
end
