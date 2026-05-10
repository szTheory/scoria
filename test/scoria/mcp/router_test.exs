defmodule Scoria.MCP.RouterTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Scoria.MCP.Router

  defmodule DummyTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "dummy_tool"

    @impl true
    def description, do: "dummy"

    @impl true
    def input_schema do
      %{
        hello: :string
      }
    end

    @impl true
    def execute(%{hello: "world"}, context) do
      {:ok, %{result: "success", actor: context}}
    end

    def execute(%{hello: "timeout"}, _context) do
      Process.sleep(5000)
      {:ok, %{}}
    end

    def execute(%{hello: "crash"}, _context) do
      raise "boom"
    end
  end

  # We use a short timeout for tests where we want to test timeout
  # Wait, the Router doesn't allow overriding timeout currently, it defaults to 5000.
  # So for a timeout test in the Router, we'd have to wait 5 seconds?
  # Let's fix Executor to take timeout from options or just mock the execution, but we're doing E2E so waiting 5s is bad for tests.
  # Better to pass timeout from Router opts or just test crash and assume timeout works (since Executor test tests it).
  # Actually, let's not wait 5 seconds. We'll just test the other cases, or update Executor to take Application config.
  # Let's just test success, method not found, invalid params, internal error.

  @opts Router.init(tools: %{"ping" => DummyTool})

  test "returns 404 for unknown routes" do
    conn = conn(:get, "/unknown")
    conn = Router.call(conn, @opts)
    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "Not Found"
  end

  test "successfully executes tool and returns result" do
    payload = %{
      "jsonrpc" => "2.0",
      "method" => "ping",
      "params" => %{"hello" => "world"},
      "id" => 1
    }

    conn =
      conn(:post, "/", payload)
      |> put_req_header("content-type", "application/json")
      |> assign(:current_actor, %{id: "user_123"})

    conn = Router.call(conn, @opts)
    
    assert conn.state == :sent
    assert conn.status == 200
    
    response = Jason.decode!(conn.resp_body)
    assert response["jsonrpc"] == "2.0"
    assert response["id"] == 1
    assert response["result"]["result"] == "success"
    assert response["result"]["actor"] == %{"id" => "user_123"}
  end

  test "returns method not found for unregistered tool" do
    payload = %{
      "jsonrpc" => "2.0",
      "method" => "unknown_tool",
      "params" => %{},
      "id" => 2
    }

    conn =
      conn(:post, "/", payload)
      |> put_req_header("content-type", "application/json")

    conn = Router.call(conn, @opts)
    
    assert conn.state == :sent
    assert conn.status == 200
    
    response = Jason.decode!(conn.resp_body)
    assert response["error"]["code"] == -32601
    assert response["error"]["message"] == "Method not found"
  end

  test "returns invalid params when validation fails" do
    payload = %{
      "jsonrpc" => "2.0",
      "method" => "ping",
      "params" => %{"hello" => 123}, # expected string
      "id" => 3
    }

    conn =
      conn(:post, "/", payload)
      |> put_req_header("content-type", "application/json")

    conn = Router.call(conn, @opts)
    
    assert conn.state == :sent
    assert conn.status == 200
    
    response = Jason.decode!(conn.resp_body)
    assert response["error"]["code"] == -32602
    assert response["error"]["message"] == "Invalid params"
    assert %{"hello" => ["is invalid"]} = response["error"]["data"]
  end

  test "returns internal error when tool crashes" do
    payload = %{
      "jsonrpc" => "2.0",
      "method" => "ping",
      "params" => %{"hello" => "crash"},
      "id" => 4
    }

    conn =
      conn(:post, "/", payload)
      |> put_req_header("content-type", "application/json")

    conn = Router.call(conn, @opts)
    
    assert conn.state == :sent
    assert conn.status == 200
    
    response = Jason.decode!(conn.resp_body)
    assert response["error"]["code"] == -32603
    assert response["error"]["message"] == "Internal error"
  end

  test "returns 400 with JSON-RPC error for invalid request" do
    payload = %{
      "method" => "ping"
      # missing jsonrpc and id
    }

    conn =
      conn(:post, "/", payload)
      |> put_req_header("content-type", "application/json")

    conn = Router.call(conn, @opts)
    
    assert conn.state == :sent
    assert conn.status == 400
    
    response = Jason.decode!(conn.resp_body)
    assert response["jsonrpc"] == "2.0"
    assert response["error"]["code"] == -32600
  end
end
