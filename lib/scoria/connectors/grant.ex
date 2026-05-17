defmodule Scoria.Connectors.Grant do
  use Ecto.Schema
  import Ecto.Changeset

  alias Scoria.Connectors.Connector
  alias Scoria.Vault

  defmodule Encrypted.Binary do
    use Cloak.Ecto.Binary, vault: Vault
  end

  defmodule Encrypted.Map do
    use Cloak.Ecto.Map, vault: Vault
  end

  @grant_kinds ~w(oauth authorization_code client_credentials bearer api_key device_code)
  @statuses ~w(pending active refreshing expired revoked reauth_required error)
  @refresh_statuses ~w(pending ok error expired)
  @forbidden_metadata_keys ~w(
    access_token
    refresh_token
    client_secret
    device_code
    token
    token_response
    raw_token
    raw_token_response
  )

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ai_connector_grants" do
    field(:tenant_id, :string)
    field(:subject_ref, :string)
    field(:grant_kind, :string)
    field(:status, :string, default: "pending")
    field(:granted_scopes, {:array, :string}, default: [])
    field(:issuer, :string)
    field(:resource_identifier, :string)
    field(:token_type, :string)
    field(:access_token, Encrypted.Binary)
    field(:refresh_token, Encrypted.Binary)
    field(:client_secret, Encrypted.Binary)
    field(:device_code, Encrypted.Binary)
    field(:raw_token, Encrypted.Map)
    field(:expires_at, :utc_datetime_usec)
    field(:refresh_expires_at, :utc_datetime_usec)
    field(:last_authenticated_at, :utc_datetime_usec)
    field(:last_refreshed_at, :utc_datetime_usec)
    field(:last_refresh_status, :string, default: "pending")
    field(:last_refresh_error_code, :string)
    field(:last_rotated_at, :utc_datetime_usec)
    field(:lock_version, :integer, default: 1)
    field(:metadata, :map, default: %{})

    belongs_to(:connector, Connector)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(grant, attrs) do
    grant
    |> cast(attrs, [
      :connector_id,
      :tenant_id,
      :subject_ref,
      :grant_kind,
      :status,
      :granted_scopes,
      :issuer,
      :resource_identifier,
      :token_type,
      :access_token,
      :refresh_token,
      :client_secret,
      :device_code,
      :raw_token,
      :expires_at,
      :refresh_expires_at,
      :last_authenticated_at,
      :last_refreshed_at,
      :last_refresh_status,
      :last_refresh_error_code,
      :last_rotated_at,
      :lock_version,
      :metadata
    ])
    |> validate_required([
      :connector_id,
      :grant_kind,
      :status,
      :subject_ref,
      :last_refresh_status
    ])
    |> validate_inclusion(:grant_kind, @grant_kinds)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:last_refresh_status, @refresh_statuses)
    |> validate_secret_metadata_separation()
    |> foreign_key_constraint(:connector_id)
    |> optimistic_lock(:lock_version)
    |> unique_constraint([:connector_id, :subject_ref, :grant_kind])
  end

  defp validate_secret_metadata_separation(changeset) do
    validate_change(changeset, :metadata, fn :metadata, metadata ->
      metadata_keys =
        metadata
        |> Map.keys()
        |> Enum.map(&to_string/1)

      duplicates = Enum.filter(@forbidden_metadata_keys, &(&1 in metadata_keys))

      if duplicates == [] do
        []
      else
        [metadata: "must not duplicate secret-bearing fields: #{Enum.join(duplicates, ", ")}"]
      end
    end)
  end
end
