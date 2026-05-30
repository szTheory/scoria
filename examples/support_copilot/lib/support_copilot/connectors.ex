defmodule SupportCopilot.Connectors do
  @moduledoc false

  alias Scoria.Connectors.Connector
  alias Scoria.Repo
  alias Scoria.SupportJourney

  def ensure_billing_connector! do
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

    case Repo.get_by(Connector, tenant_id: attrs.tenant_id, key: attrs.key) do
      nil ->
        Repo.insert!(Connector.changeset(%Connector{}, attrs))

      connector ->
        connector
    end
  end
end
