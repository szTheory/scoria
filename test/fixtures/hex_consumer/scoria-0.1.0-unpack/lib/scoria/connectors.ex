defmodule Scoria.Connectors do
  @moduledoc """
  Thin connector read-model helpers for the embedded operator surface.
  """

  import Ecto.Query, warn: false

  alias Scoria.Connectors.{CapabilitySnapshot, Connector, Grant}
  alias Scoria.Observe.Approval
  alias Scoria.Repo

  def get_connector!(connector_id), do: Repo.get!(Connector, connector_id)

  def list_connector_fleet(filters \\ %{}) do
    tenant_id = Map.get(filters, :tenant_id) || Map.get(filters, "tenant_id")

    Connector
    |> maybe_filter_tenant(tenant_id)
    |> preload([:capability_snapshot, :grants])
    |> order_by([connector], asc: connector.label, asc: connector.inserted_at)
    |> Repo.all()
    |> Enum.map(&fleet_row/1)
  end

  def get_connector_drawer(connector_id) do
    connector =
      Connector
      |> Repo.get!(connector_id)
      |> Repo.preload([:capability_snapshot, :grants])

    %{
      connector_id: connector.id,
      connector_label: connector.label,
      connector_key: connector.key,
      endpoint_url: connector.endpoint_url,
      transport_kind: connector.transport_kind,
      auth_mode: connector.auth_mode,
      status: connector.status,
      health_state: connector.health_state,
      last_refresh_status: connector.last_refresh_status,
      capability_snapshot: capability_snapshot_item(connector.capability_snapshot),
      grants: Enum.map(connector.grants, &grant_item/1)
    }
  end

  defp maybe_filter_tenant(query, nil), do: query
  defp maybe_filter_tenant(query, tenant_id), do: where(query, [connector], connector.tenant_id == ^tenant_id)

  defp fleet_row(connector) do
    pending_approval_count =
      Approval
      |> where([approval], approval.connector_id == ^connector.id and approval.status == "pending")
      |> Repo.aggregate(:count)

    %{
      connector_id: connector.id,
      connector_label: connector.label,
      connector_key: connector.key,
      health_state: connector.health_state,
      last_refresh_status: connector.last_refresh_status,
      pending_approval_count: pending_approval_count,
      pending_local_tool_count: capability_tool_count(connector.capability_snapshot),
      auth_provenance: auth_provenance(connector)
    }
  end

  defp capability_tool_count(%CapabilitySnapshot{tool_count: count}) when is_integer(count), do: count
  defp capability_tool_count(_snapshot), do: 0

  defp auth_provenance(connector) do
    latest_grant =
      connector.grants
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> List.first()

    %{status: latest_grant && latest_grant.status || connector.auth_mode}
  end

  defp capability_snapshot_item(nil), do: nil

  defp capability_snapshot_item(snapshot) do
    %{
      catalog_version: snapshot.catalog_version,
      tool_count: snapshot.tool_count,
      last_refresh_status: snapshot.last_refresh_status
    }
  end

  defp grant_item(%Grant{} = grant) do
    %{
      id: grant.id,
      subject_ref: grant.subject_ref,
      status: grant.status,
      granted_scopes: grant.granted_scopes || [],
      last_refresh_status: grant.last_refresh_status
    }
  end
end
