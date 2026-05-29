defmodule Scoria.Workflows.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_workflow_events" do
    field :sequence, :integer
    field :event_type, :string
    field :payload, :map, default: %{}
    field :replay_disposition, :string
    field :replay_reason_code, :string

    belongs_to :run, Scoria.Workflows.Run
    belongs_to :step, Scoria.Workflows.Step

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :run_id,
      :step_id,
      :sequence,
      :event_type,
      :payload,
      :replay_disposition,
      :replay_reason_code
    ])
    |> validate_required([:run_id, :sequence, :event_type])
    |> foreign_key_constraint(:run_id)
    |> foreign_key_constraint(:step_id)
    |> unique_constraint([:run_id, :sequence])
  end
end
