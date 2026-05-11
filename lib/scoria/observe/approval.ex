defmodule Scoria.Observe.Approval do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending approved rejected expired)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_approvals" do
    field(:tool_name, :string)
    field(:arguments, :map, default: %{})
    field(:status, :string, default: "pending")
    field(:session_id, :string)
    field(:run_id, :string)
    field(:workflow_run_id, :binary_id)
    field(:step_id, :binary_id)
    field(:checkpoint_id, :binary_id)
    field(:lock_version, :integer, default: 1)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(approval, attrs) do
    approval
    |> cast(attrs, [:tool_name, :arguments, :status, :session_id, :run_id, :workflow_run_id, :step_id, :checkpoint_id, :lock_version])
    |> validate_required([:tool_name, :status])
    |> validate_inclusion(:status, @statuses)
    |> optimistic_lock(:lock_version)
  end
end
