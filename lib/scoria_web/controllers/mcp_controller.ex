defmodule ScoriaWeb.MCPController do
  use Phoenix.Controller, formats: [:json]
  import Plug.Conn

  alias Scoria.MCP.SessionRegistry
  alias Scoria.MCP.Protocol
  alias Scoria.MCP.Validator
  alias Scoria.MCP.Executor

  @doc """
  Establishes an SSE connection, registers the session, and enters a receive loop.
  """
  def sse(conn, _params) do
    session_id = Ecto.UUID.generate()
    tenant_id = conn.assigns[:tenant_id] || "default"

    {:ok, instance} = Scoria.Runtime.register_instance(%{
      tenant_id: tenant_id,
      transport_kind: "sse",
      host_session_id: session_id
    })

    # Track in Presence using durable instance.id
    {:ok, _} = ScoriaWeb.Presence.track(self(), "mcp:runtimes:#{tenant_id}", instance.id, %{
      status: "connected"
    })
    
    # Register in SessionRegistry
    {:ok, _} = Registry.register(SessionRegistry, session_id, [])

    conn =
      conn
      |> put_resp_header("content-type", "text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> send_chunked(200)

    # Send initial endpoint event
    endpoint_event = "event: endpoint\ndata: /mcp/messages?session_id=#{session_id}\n\n"
    {:ok, conn} = chunk(conn, endpoint_event)

    try do
      listen_loop(conn)
    after
      Scoria.Runtime.mark_offline(instance.id, "transport_closed")
    end
  end

  @doc """
  Receives a POST message with JSON-RPC payload, finds the session, and sends the message to the process.
  """
  def messages(conn, %{"session_id" => session_id}) do
    case Registry.lookup(SessionRegistry, session_id) do
      [{pid, _}] ->
        send(pid, {:mcp_message, conn.body_params})
        send_resp(conn, 202, "")

      [] ->
        send_resp(conn, 404, "Session not found")
    end
  end

  def messages(conn, _params) do
    send_resp(conn, 404, "Session not found")
  end

  defp listen_loop(conn) do
    receive do
      {:mcp_message, payload} ->
        conn = handle_message(conn, payload)
        listen_loop(conn)

      {:plug_conn, :sent} ->
        # Client disconnected
        conn

      _ ->
        listen_loop(conn)
    after
      30_000 ->
        case chunk(conn, ": keepalive\n\n") do
          {:ok, conn} -> listen_loop(conn)
          {:error, _reason} -> conn
        end
    end
  end

  defp handle_message(conn, payload) do
    case Protocol.parse(payload) do
      {:ok, request} ->
        execute_tool_request(conn, request)

      {:error, error_response} ->
        send_sse_json(conn, error_response)
    end
  end

  defp execute_tool_request(conn, %{method: method, params: params, id: id}) do
    # For JSON-RPC, tools might be invoked via a generic method like "tools/call" 
    # but the problem specifies: lookup the tool from the connection assigns
    # Let's assume `method` is the tool name, or it's provided in params. 
    # Wait, the instruction says:
    # On `{:ok, request}`, lookup the tool from the connection assigns (e.g., `conn.assigns[:mcp_tools]`).
    # If found, validate args via `Scoria.MCP.Validator.validate_args`, execute via `Scoria.MCP.Executor.execute`
    # Let's see if method is the tool name.

    tools = conn.assigns[:mcp_tools] || []
    tool_module = find_tool(tools, method)

    if tool_module do
      # Note: params could be nil, handle it gracefully
      raw_args = params || %{}
      
      case Validator.validate_args(tool_module, raw_args) do
        {:ok, validated_args} ->
          context = Map.new(conn.assigns) # Pass connection assigns as context
          case Executor.execute(tool_module, validated_args, context) do
            {:ok, result} ->
              send_sse_json(conn, Protocol.format_response(id, result))

            {:error, error} ->
              # Format error, we use -32000 for server error
              send_sse_json(conn, Protocol.format_error(id, -32000, "Execution failed", inspect(error)))
          end

        {:error, _changeset} ->
          send_sse_json(conn, Protocol.format_error(id, -32602, "Invalid params"))
      end
    else
      send_sse_json(conn, Protocol.format_error(id, -32601, "Method not found"))
    end
  end

  defp find_tool(tools, method) do
    # tools could be a list of modules or [{name, module}]
    Enum.find(tools, fn 
      {name, _mod} -> to_string(name) == method
      mod -> 
        if function_exported?(mod, :name, 0) do
          mod.name() == method
        else
          inspect(mod) == method
        end
    end)
    |> case do
      {_name, mod} -> mod
      mod -> mod
    end
  end

  defp send_sse_json(conn, data) do
    # encode the result
    json_str = Jason.encode!(data)
    case chunk(conn, "data: #{json_str}\n\n") do
      {:ok, conn} -> conn
      {:error, _} -> conn
    end
  end
end