defmodule Scoria.MCP.RouterTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Scoria.MCP.Router

  @opts Router.init([])

  test "returns 404 for unknown routes" do
    conn = conn(:get, "/unknown")
    conn = Router.call(conn, @opts)
    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "Not Found"
  end

  test "successfully parses JSON-RPC request and returns result with actor" do
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
    assert ["application/json" <> _] = get_resp_header(conn, "content-type")
    
    response = Jason.decode!(conn.resp_body)
    assert response["jsonrpc"] == "2.0"
    assert response["id"] == 1
    assert response["result"]["method"] == "ping"
    assert response["result"]["params"] == %{"hello" => "world"}
    assert response["result"]["actor"] == %{"id" => "user_123"}
  end

  test "handles missing actor and uses nil" do
    payload = %{
      "jsonrpc" => "2.0",
      "method" => "ping",
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
    assert response["result"]["actor"] == nil
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
    assert response["error"]["message"] == "Invalid Request"
  end
end
