defmodule ScoriaWeb.MCPControllerTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Scoria.MCP.SessionRegistry
  alias ScoriaWeb.MCPController

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    conn = conn(:get, "/")
    {:ok, conn: conn}
  end

  test "returns 404 for unknown session id", %{conn: conn} do
    conn = MCPController.messages(conn, %{"session_id" => "unknown"})
    assert conn.status == 404
    assert conn.resp_body == "Session not found"
  end

  test "sse loop registers and receives messages", %{conn: conn} do
    conn = assign(conn, :mcp_tools, [])
    conn = assign(conn, :tenant_id, "test_tenant")

    parent = self()
    task = Task.async(fn ->
      Ecto.Adapters.SQL.Sandbox.allow(Scoria.Repo, parent, self())
      MCPController.sse(conn, %{})
    end)

    Process.sleep(50)

    # Find the session id registered by the task
    registrations = Registry.select(SessionRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])
    {session_id, pid} = Enum.find(registrations, fn {_id, p} -> p == task.pid end)

    assert pid == task.pid

    # Send a message to the controller via messages/2
    msg_conn = conn(:post, "/mcp/messages?session_id=#{session_id}")
    msg_conn = %{msg_conn | body_params: %{"jsonrpc" => "2.0", "id" => 1, "method" => "ping"}}
    
    res_conn = MCPController.messages(msg_conn, %{"session_id" => session_id})
    assert res_conn.status == 202

    # Stop the task
    Process.exit(task.pid, :kill)
  end
end