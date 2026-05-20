defmodule Scoria.Runtime.Instance do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "runtime_instances" do
    field :tenant_id, :string
    field :host_session_id, :string
    field :current_run_id, :string
    field :first_seen_at, :utc_datetime
    field :last_seen_at, :utc_datetime
    field :terminal_offline_reason, :string
    field :transport_kind, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(instance, attrs) do
    instance
    |> cast(attrs, [:tenant_id, :host_session_id, :current_run_id, :first_seen_at, :last_seen_at, :terminal_offline_reason, :transport_kind])
    |> validate_required([:tenant_id, :first_seen_at, :last_seen_at, :transport_kind])
  end
end
