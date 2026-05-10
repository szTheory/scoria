defmodule Scoria.MCP.Router do
  @moduledoc """
  Plug router for handling incoming MCP (Model Context Protocol) JSON-RPC 2.0 requests.
  """

  use Plug.Router
  alias Scoria.MCP.Protocol

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  post "/" do
    # Get the actor context from assigns.
    # We fallback to nil if it's not set.
    actor = conn.assigns[:current_actor]

    case Protocol.parse(conn.body_params) do
      {:ok, request} ->
        # Placeholder execution: echo back the parsed method/params and the actor.
        result = %{
          "method" => request.method,
          "params" => request.params,
          "actor" => actor
        }

        response = Protocol.format_response(request.id, result)
        send_json(conn, 200, response)

      {:error, error_response} ->
        send_json(conn, 400, error_response)
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
