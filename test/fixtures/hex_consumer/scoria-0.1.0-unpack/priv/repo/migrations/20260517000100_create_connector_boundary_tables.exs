defmodule Scoria.Repo.Migrations.CreateConnectorBoundaryTables do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:ai_connectors, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string)
      add(:key, :string, null: false)
      add(:label, :string, null: false)
      add(:endpoint_url, :string, null: false)
      add(:transport_kind, :string, null: false)
      add(:auth_mode, :string, null: false)
      add(:profile_key, :string)
      add(:adapter_module, :string)
      add(:status, :string, null: false, default: "registered")
      add(:health_state, :string, null: false, default: "unknown")
      add(:discovery_metadata_url, :string)
      add(:protected_resource_metadata_url, :string)
      add(:last_discovered_at, :utc_datetime_usec)
      add(:last_discovery_error_code, :string)
      add(:last_refresh_at, :utc_datetime_usec)
      add(:last_refresh_status, :string, null: false, default: "pending")
      add(:last_good_refresh_at, :utc_datetime_usec)
      add(:last_refresh_error_code, :string)
      add(:stale_at, :utc_datetime_usec)
      add(:invalidated_at, :utc_datetime_usec)
      add(:lock_version, :integer, null: false, default: 1)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:ai_connectors, [:tenant_id]))
    create_if_not_exists(index(:ai_connectors, [:status]))
    create_if_not_exists(index(:ai_connectors, [:health_state]))
    create_if_not_exists(index(:ai_connectors, [:last_refresh_status]))
    create_if_not_exists(unique_index(:ai_connectors, [:tenant_id, :key]))

    create_if_not_exists table(:ai_connector_grants, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:connector_id, references(:ai_connectors, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      add(:tenant_id, :string)
      add(:subject_ref, :string, null: false)
      add(:grant_kind, :string, null: false)
      add(:status, :string, null: false, default: "pending")
      add(:granted_scopes, {:array, :string}, null: false, default: [])
      add(:issuer, :string)
      add(:resource_identifier, :string)
      add(:token_type, :string)
      add(:access_token, :binary)
      add(:refresh_token, :binary)
      add(:client_secret, :binary)
      add(:device_code, :binary)
      add(:raw_token, :binary)
      add(:expires_at, :utc_datetime_usec)
      add(:refresh_expires_at, :utc_datetime_usec)
      add(:last_authenticated_at, :utc_datetime_usec)
      add(:last_refreshed_at, :utc_datetime_usec)
      add(:last_refresh_status, :string, null: false, default: "pending")
      add(:last_refresh_error_code, :string)
      add(:last_rotated_at, :utc_datetime_usec)
      add(:lock_version, :integer, null: false, default: 1)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:ai_connector_grants, [:connector_id]))
    create_if_not_exists(index(:ai_connector_grants, [:tenant_id]))
    create_if_not_exists(index(:ai_connector_grants, [:status]))
    create_if_not_exists(index(:ai_connector_grants, [:expires_at]))
    create_if_not_exists(index(:ai_connector_grants, [:last_refresh_status]))

    create_if_not_exists(
      unique_index(:ai_connector_grants, [:connector_id, :subject_ref, :grant_kind])
    )

    create_if_not_exists table(:ai_connector_capability_snapshots, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:connector_id, references(:ai_connectors, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      add(:catalog, :map, null: false, default: %{})
      add(:catalog_hash, :string, null: false)
      add(:catalog_version, :string, null: false)
      add(:tool_count, :integer, null: false, default: 0)
      add(:discovery_metadata_url, :string)
      add(:protected_resource_metadata_url, :string)
      add(:last_refreshed_at, :utc_datetime_usec)
      add(:last_refresh_status, :string, null: false, default: "pending")
      add(:last_good_refresh_at, :utc_datetime_usec)
      add(:last_refresh_error_code, :string)
      add(:stale_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:ai_connector_capability_snapshots, [:last_refresh_status]))
    create_if_not_exists(index(:ai_connector_capability_snapshots, [:stale_at]))
    create_if_not_exists(unique_index(:ai_connector_capability_snapshots, [:connector_id]))
  end
end
