defmodule Scoria.Workflows.Handoff do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending running completed failed cancelled)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_workflow_handoffs" do
    field :delegated_role_id, :string
    field :capability_tags, {:array, :string}, default: []
    field :status, :string, default: "pending"
    field :handoff_input, :map, default: %{}
    field :result_summary, :map, default: %{}

    belongs_to :run, Scoria.Workflows.Run
    belongs_to :step, Scoria.Workflows.Step

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(handoff, attrs) do
    handoff
    |> cast(attrs, [:run_id, :step_id, :delegated_role_id, :capability_tags, :status, :handoff_input, :result_summary])
    |> validate_required([:run_id, :step_id, :delegated_role_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:run_id)
    |> foreign_key_constraint(:step_id)
  end
end
