defmodule Scoria.Observe.Approval do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_approvals" do
    field(:tool_name, :string)
    field(:arguments, :map, default: %{})
    field(:status, :string, default: "pending")
    field(:session_id, :string)
    field(:run_id, :string)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(approval, attrs) do
    approval
    |> cast(attrs, [:tool_name, :arguments, :status, :session_id, :run_id])
    |> validate_required([:tool_name, :status])
    |> validate_inclusion(:status, ["pending", "approved", "rejected"])
  end
end
