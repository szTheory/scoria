defmodule Scoria.Connectors.CapabilitySnapshot do
  use Ecto.Schema
  import Ecto.Changeset

  alias Scoria.Connectors.Connector

  @refresh_statuses ~w(pending ok error stale)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ai_connector_capability_snapshots" do
    field(:catalog, :map, default: %{})
    field(:catalog_hash, :string)
    field(:catalog_version, :string)
    field(:tool_count, :integer, default: 0)
    field(:discovery_metadata_url, :string)
    field(:protected_resource_metadata_url, :string)
    field(:last_refreshed_at, :utc_datetime_usec)
    field(:last_refresh_status, :string, default: "pending")
    field(:last_good_refresh_at, :utc_datetime_usec)
    field(:last_refresh_error_code, :string)
    field(:stale_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    belongs_to(:connector, Connector)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [
      :connector_id,
      :catalog,
      :catalog_hash,
      :catalog_version,
      :tool_count,
      :discovery_metadata_url,
      :protected_resource_metadata_url,
      :last_refreshed_at,
      :last_refresh_status,
      :last_good_refresh_at,
      :last_refresh_error_code,
      :stale_at,
      :metadata
    ])
    |> validate_required([
      :connector_id,
      :catalog_hash,
      :catalog_version,
      :last_refresh_status
    ])
    |> validate_inclusion(:last_refresh_status, @refresh_statuses)
    |> validate_number(:tool_count, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:connector_id)
    |> unique_constraint(:connector_id)
  end
end
