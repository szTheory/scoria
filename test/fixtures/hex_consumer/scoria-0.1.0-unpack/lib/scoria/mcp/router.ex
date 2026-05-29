defmodule Scoria.MCP.Router do
  @moduledoc """
  Plug router for handling incoming MCP (Model Context Protocol) JSON-RPC 2.0 requests.
  """

  use Plug.Router
  alias Scoria.Identity
  alias Scoria.MCP.Protocol
  alias Scoria.MCP.Validator
  alias Scoria.MCP.Executor

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  def call(conn, opts) do
    conn = assign(conn, :mcp_tools, Keyword.get(opts, :tools, %{}))
    super(conn, opts)
  end

  post "/" do
    identity = Identity.from_conn_assigns(conn.assigns)
    tools = conn.assigns[:mcp_tools]

    case Protocol.parse(conn.body_params) do
      {:ok, request} ->
        case Map.fetch(tools, request.method) do
          {:ok, tool_module} ->
            params = request.params || %{}
            case Validator.validate_args(tool_module, params) do
              {:ok, valid_args} ->
                case Executor.execute(tool_module, valid_args, Identity.to_map(identity)) do
                  {:ok, result} ->
                    send_success(conn, request.id, result)

                  {:error, :timeout} ->
                    send_error(conn, request.id, -32000, "Execution timeout")

                  {:error, _reason} ->
                    send_error(conn, request.id, -32603, "Internal error")
                end

              {:error, changeset} ->
                errors = traverse_errors(changeset)
                send_error(conn, request.id, -32602, "Invalid params", errors)
            end

          :error ->
            send_error(conn, request.id, -32601, "Method not found")
        end

      {:error, error_response} ->
        send_json(conn, 400, error_response)
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp send_success(conn, id, result) do
    response = Protocol.format_response(id, result)
    send_json(conn, 200, response)
  end

  defp send_error(conn, id, code, message, data \\ nil) do
    response = Protocol.format_error(id, code, message, data)
    send_json(conn, 200, response) # JSON-RPC errors typically return 200 OK
  end

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  defp traverse_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
