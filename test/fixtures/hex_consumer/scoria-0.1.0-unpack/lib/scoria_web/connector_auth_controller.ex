defmodule ScoriaWeb.ConnectorAuthController do
  use Phoenix.Controller, formats: [:html]

  alias Scoria.Connectors.Auth

  def start(conn, %{"connector_id" => connector_id} = params) do
    {:ok, %{authorization_url: authorization_url}} =
      Auth.start_authorization(connector_id, params)

    redirect(conn, external: authorization_url)
  end

  def callback(conn, %{"connector_id" => connector_id} = params) do
    auth_state = %{
      "trace_id" => Map.get(params, "trace_id", "connector-auth-callback"),
      "actor_id" => Map.get(params, "actor_id", "operator")
    }

    case Auth.complete_authorization(connector_id, params, auth_state, params) do
      {:ok, _grant} -> send_resp(conn, 200, "connector authorization recorded")
      {:error, reason} -> send_resp(conn, 500, "connector auth callback failed: #{inspect(reason)}")
    end
  end
end
