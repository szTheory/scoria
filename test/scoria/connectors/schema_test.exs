defmodule Scoria.Connectors.SchemaTest do
  use ExUnit.Case, async: false

  alias Scoria.Connectors.{CapabilitySnapshot, Connector, Grant}
  alias Scoria.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  test "connector changeset persists operator-facing columns and enforces tenant key uniqueness" do
    attrs = %{
      tenant_id: "tenant-alpha",
      key: "github",
      label: "GitHub",
      endpoint_url: "https://api.github.example/mcp",
      transport_kind: "streamable_http",
      auth_mode: "oauth_pkce",
      status: "ready",
      health_state: "healthy",
      discovery_metadata_url: "https://api.github.example/.well-known/oauth-authorization-server",
      protected_resource_metadata_url:
        "https://api.github.example/.well-known/oauth-protected-resource",
      last_discovered_at: now(),
      last_refresh_at: now(),
      last_refresh_status: "ok",
      last_good_refresh_at: now(),
      metadata: %{"profile" => "github"}
    }

    assert {:ok, connector} =
             %Connector{}
             |> Connector.changeset(attrs)
             |> Repo.insert()

    assert connector.status == "ready"
    assert connector.health_state == "healthy"
    assert connector.last_refresh_status == "ok"
    assert connector.discovery_metadata_url =~ ".well-known"

    assert {:error, changeset} =
             %Connector{}
             |> Connector.changeset(attrs)
             |> Repo.insert()

    assert "has already been taken" in errors_on(changeset).tenant_id
  end

  test "connector updates are optimistic-lock protected" do
    connector =
      insert_connector(%{
        tenant_id: "tenant-lock",
        key: "slack",
        label: "Slack"
      })

    stale = Repo.get!(Connector, connector.id)
    fresh = Repo.get!(Connector, connector.id)

    assert {:ok, _updated} =
             fresh
             |> Connector.changeset(%{health_state: "degraded", status: "degraded"})
             |> Repo.update()

    assert_raise Ecto.StaleEntryError, fn ->
      stale
      |> Connector.changeset(%{health_state: "healthy"})
      |> Repo.update()
    end
  end

  test "grant encrypts secrets at rest while keeping scope and expiry queryable" do
    connector = insert_connector(%{tenant_id: "tenant-grant", key: "notion", label: "Notion"})

    attrs = %{
      connector_id: connector.id,
      tenant_id: "tenant-grant",
      subject_ref: "user-123",
      grant_kind: "oauth",
      status: "active",
      granted_scopes: ["tools:read", "prompts:read"],
      issuer: "https://auth.notion.example",
      resource_identifier: "notion-workspace-1",
      token_type: "Bearer",
      access_token: "access-secret",
      refresh_token: "refresh-secret",
      client_secret: "client-secret",
      raw_token: %{"access_token" => "access-secret", "refresh_token" => "refresh-secret"},
      expires_at: now(),
      refresh_expires_at: now(),
      last_authenticated_at: now(),
      last_refreshed_at: now(),
      last_refresh_status: "ok",
      metadata: %{"scope_source" => "oauth_callback"}
    }

    assert {:ok, grant} =
             %Grant{}
             |> Grant.changeset(attrs)
             |> Repo.insert()

    reloaded = Repo.get!(Grant, grant.id)
    assert reloaded.access_token == "access-secret"
    assert reloaded.refresh_token == "refresh-secret"
    assert reloaded.client_secret == "client-secret"
    assert reloaded.granted_scopes == ["tools:read", "prompts:read"]
    assert %DateTime{} = reloaded.expires_at
    assert reloaded.metadata == %{"scope_source" => "oauth_callback"}

    result =
      Repo.query!(
        """
        SELECT access_token, refresh_token, client_secret, raw_token
        FROM ai_connector_grants
        WHERE id = $1
        """,
        [Ecto.UUID.dump!(grant.id)]
      )

    [[access_token, refresh_token, client_secret, raw_token]] = result.rows

    assert is_binary(access_token)
    assert is_binary(refresh_token)
    assert is_binary(client_secret)
    assert is_binary(raw_token)
    refute access_token == "access-secret"
    refute refresh_token == "refresh-secret"
    refute client_secret == "client-secret"
    refute raw_token == Jason.encode!(attrs.raw_token)
  end

  test "grant metadata rejects raw secret duplication and grant uniqueness is enforced" do
    connector = insert_connector(%{tenant_id: "tenant-metadata", key: "linear", label: "Linear"})

    base_attrs = %{
      connector_id: connector.id,
      tenant_id: "tenant-metadata",
      subject_ref: "acct-1",
      grant_kind: "api_key",
      status: "active",
      granted_scopes: ["issues:read"],
      last_refresh_status: "ok",
      metadata: %{"scope_source" => "operator"}
    }

    assert {:ok, _grant} =
             %Grant{}
             |> Grant.changeset(base_attrs)
             |> Repo.insert()

    assert {:error, duplicate_changeset} =
             %Grant{}
             |> Grant.changeset(base_attrs)
             |> Repo.insert()

    assert "has already been taken" in errors_on(duplicate_changeset).connector_id

    invalid_changeset =
      %Grant{}
      |> Grant.changeset(%{
        connector_id: connector.id,
        subject_ref: "acct-2",
        grant_kind: "api_key",
        status: "active",
        last_refresh_status: "ok",
        metadata: %{"access_token" => "should-not-live-here"}
      })

    refute invalid_changeset.valid?

    assert "must not duplicate secret-bearing fields: access_token" in errors_on(
             invalid_changeset
           ).metadata
  end

  test "capability snapshot keeps current catalog truth with explicit refresh metadata" do
    connector = insert_connector(%{tenant_id: "tenant-cap", key: "figma", label: "Figma"})

    attrs = %{
      connector_id: connector.id,
      catalog: %{"tools" => [%{"name" => "comments.list"}, %{"name" => "files.read"}]},
      catalog_hash: "sha256:catalog-hash",
      catalog_version: "v2026-05-17",
      tool_count: 2,
      discovery_metadata_url: "https://figma.example/.well-known/oauth-authorization-server",
      protected_resource_metadata_url:
        "https://figma.example/.well-known/oauth-protected-resource",
      last_refreshed_at: now(),
      last_refresh_status: "ok",
      last_good_refresh_at: now(),
      stale_at: now(),
      metadata: %{"etag" => "cap-123"}
    }

    assert {:ok, snapshot} =
             %CapabilitySnapshot{}
             |> CapabilitySnapshot.changeset(attrs)
             |> Repo.insert()

    assert snapshot.catalog_hash == "sha256:catalog-hash"
    assert snapshot.catalog_version == "v2026-05-17"
    assert snapshot.tool_count == 2
    assert snapshot.last_refresh_status == "ok"
    assert get_in(snapshot.catalog, ["tools"]) |> length() == 2

    assert {:error, changeset} =
             %CapabilitySnapshot{}
             |> CapabilitySnapshot.changeset(Map.put(attrs, :catalog_version, "v2026-05-18"))
             |> Repo.insert()

    assert "has already been taken" in errors_on(changeset).connector_id
  end

  defp insert_connector(overrides) do
    attrs =
      Map.merge(
        %{
          tenant_id: nil,
          key: "connector-#{System.unique_integer([:positive])}",
          label: "Connector",
          endpoint_url: "https://connector.example/mcp",
          transport_kind: "streamable_http",
          auth_mode: "oauth_pkce",
          status: "registered",
          health_state: "unknown",
          last_refresh_status: "pending"
        },
        overrides
      )

    Repo.insert!(Connector.changeset(%Connector{}, attrs))
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r/%{(\w+)}/, message, fn _, key ->
        opts |> Keyword.fetch!(String.to_existing_atom(key)) |> to_string()
      end)
    end)
  end

  defp now do
    DateTime.utc_now() |> DateTime.truncate(:microsecond)
  end
end
