defmodule Scoria.Connectors.AdoptionLaneTest do
  use ExUnit.Case, async: false

  alias Scoria.Connectors
  alias Scoria.Connectors.Connector
  alias Scoria.Repo
  alias Scoria.SupportJourney

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  test "SupportJourney billing connector registers and surfaces operator fleet evidence" do
    attrs = %{
      tenant_id: SupportJourney.tenant_id(),
      key: SupportJourney.connector_key(),
      label: SupportJourney.connector_label(),
      endpoint_url: "https://billing.example/mcp",
      transport_kind: "streamable_http",
      auth_mode: "oauth_pkce",
      status: "ready",
      health_state: "healthy",
      last_refresh_status: "ok"
    }

    connector = Repo.insert!(Connector.changeset(%Connector{}, attrs))

    fleet = Connectors.list_connector_fleet(%{tenant_id: SupportJourney.tenant_id()})

    assert Enum.any?(fleet, fn row ->
             row.connector_key == SupportJourney.connector_key() and
               row.connector_label == SupportJourney.connector_label()
           end)

    drawer = Connectors.get_connector_drawer(connector.id)

    assert drawer.connector_key == SupportJourney.connector_key()
    assert drawer.connector_label == SupportJourney.connector_label()
    assert drawer.health_state == "healthy"
    assert drawer.status == "ready"
  end
end
