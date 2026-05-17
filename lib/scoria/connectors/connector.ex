defmodule Scoria.Connectors.Connector do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(registered discovering ready degraded disabled error)
  @health_states ~w(unknown healthy degraded failing unreachable)
  @transport_kinds ~w(streamable_http sse)
  @auth_modes ~w(none oauth_pkce client_credentials api_key bearer device_code)
  @refresh_statuses ~w(pending ok error stale)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ai_connectors" do
    field(:tenant_id, :string)
    field(:key, :string)
    field(:label, :string)
    field(:endpoint_url, :string)
    field(:transport_kind, :string)
    field(:auth_mode, :string)
    field(:profile_key, :string)
    field(:adapter_module, :string)
    field(:status, :string, default: "registered")
    field(:health_state, :string, default: "unknown")
    field(:discovery_metadata_url, :string)
    field(:protected_resource_metadata_url, :string)
    field(:last_discovered_at, :utc_datetime_usec)
    field(:last_discovery_error_code, :string)
    field(:last_refresh_at, :utc_datetime_usec)
    field(:last_refresh_status, :string, default: "pending")
    field(:last_good_refresh_at, :utc_datetime_usec)
    field(:last_refresh_error_code, :string)
    field(:stale_at, :utc_datetime_usec)
    field(:invalidated_at, :utc_datetime_usec)
    field(:lock_version, :integer, default: 1)
    field(:metadata, :map, default: %{})

    has_many(:grants, Scoria.Connectors.Grant)
    has_one(:capability_snapshot, Scoria.Connectors.CapabilitySnapshot)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(connector, attrs) do
    connector
    |> cast(attrs, [
      :tenant_id,
      :key,
      :label,
      :endpoint_url,
      :transport_kind,
      :auth_mode,
      :profile_key,
      :adapter_module,
      :status,
      :health_state,
      :discovery_metadata_url,
      :protected_resource_metadata_url,
      :last_discovered_at,
      :last_discovery_error_code,
      :last_refresh_at,
      :last_refresh_status,
      :last_good_refresh_at,
      :last_refresh_error_code,
      :stale_at,
      :invalidated_at,
      :lock_version,
      :metadata
    ])
    |> validate_required([
      :key,
      :label,
      :endpoint_url,
      :transport_kind,
      :auth_mode,
      :status,
      :health_state,
      :last_refresh_status
    ])
    |> validate_format(:endpoint_url, ~r/^https?:\/\//)
    |> validate_inclusion(:transport_kind, @transport_kinds)
    |> validate_inclusion(:auth_mode, @auth_modes)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:health_state, @health_states)
    |> validate_inclusion(:last_refresh_status, @refresh_statuses)
    |> optimistic_lock(:lock_version)
    |> unique_constraint([:tenant_id, :key])
  end
end
