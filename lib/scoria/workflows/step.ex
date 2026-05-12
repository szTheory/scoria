defmodule Scoria.Workflows.Step do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(queued running waiting_for_approval retrying failed completed cancelled)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_workflow_steps" do
    field :sequence, :integer
    field :kind, :string
    field :role_id, :string
    field :status, :string, default: "queued"
    field :attempt, :integer, default: 1
    field :retry_count, :integer, default: 0
    field :idempotency_key, :string
    field :handoff_input, :map, default: %{}
    field :projected_context, :map, default: %{}
    field :result_envelope, :map, default: %{}
    field :error_envelope, :map, default: %{}
    field :started_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec

    belongs_to :run, Scoria.Workflows.Run
    belongs_to :parent_step, Scoria.Workflows.Step
    has_many :checkpoints, Scoria.Workflows.Checkpoint
    has_many :events, Scoria.Workflows.Event
    has_many :handoffs, Scoria.Workflows.Handoff

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(step, attrs) do
    step
    |> cast(attrs, [
      :run_id,
      :parent_step_id,
      :sequence,
      :kind,
      :role_id,
      :status,
      :attempt,
      :retry_count,
      :idempotency_key,
      :handoff_input,
      :projected_context,
      :result_envelope,
      :error_envelope,
      :started_at,
      :completed_at
    ])
    |> validate_required([:run_id, :sequence, :kind, :role_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:run_id)
    |> foreign_key_constraint(:parent_step_id)
    |> unique_constraint([:run_id, :sequence])
  end
end
