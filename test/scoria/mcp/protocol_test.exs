defmodule Scoria.MCP.ProtocolTest do
  use ExUnit.Case, async: true
  alias Scoria.MCP.Protocol

  describe "parse/1" do
    test "parses a valid json-rpc request" do
      payload = %{
        "jsonrpc" => "2.0",
        "method" => "ping",
        "params" => %{"foo" => "bar"},
        "id" => 1
      }

      assert {:ok, request} = Protocol.parse(payload)
      assert request.jsonrpc == "2.0"
      assert request.method == "ping"
      assert request.params == %{"foo" => "bar"}
      assert request.id == 1
    end

    test "parses a valid json-rpc notification (no id)" do
      payload = %{
        "jsonrpc" => "2.0",
        "method" => "notify"
      }

      assert {:ok, request} = Protocol.parse(payload)
      assert request.jsonrpc == "2.0"
      assert request.method == "notify"
      assert request.params == nil
      assert request.id == nil
    end

    test "returns error for missing jsonrpc" do
      payload = %{"method" => "ping"}
      assert {:error, response} = Protocol.parse(payload)
      assert response.jsonrpc == "2.0"
      assert response.error.code == -32600
      assert response.error.message == "Invalid Request"
    end

    test "returns error for invalid jsonrpc version" do
      payload = %{"jsonrpc" => "1.0", "method" => "ping"}
      assert {:error, response} = Protocol.parse(payload)
      assert response.error.code == -32600
    end

    test "returns error for missing method" do
      payload = %{"jsonrpc" => "2.0"}
      assert {:error, response} = Protocol.parse(payload)
      assert response.error.code == -32600
    end

    test "returns error for invalid payload type" do
      assert {:error, response} = Protocol.parse("not a map")
      assert response.error.code == -32600
    end
    
    test "includes id in error response if id was provided in payload" do
      payload = %{"jsonrpc" => "1.0", "method" => "ping", "id" => 123}
      assert {:error, response} = Protocol.parse(payload)
      assert response.id == 123
    end
  end

  describe "format_response/2" do
    test "formats successful response correctly" do
      response = Protocol.format_response(1, %{"status" => "ok"})
      assert response.jsonrpc == "2.0"
      assert response.id == 1
      assert response.result == %{"status" => "ok"}
      assert not Map.has_key?(response, :error)
    end
  end

  describe "format_error/4" do
    test "formats error response correctly without data" do
      response = Protocol.format_error(2, -32601, "Method not found")
      assert response.jsonrpc == "2.0"
      assert response.id == 2
      assert response.error.code == -32601
      assert response.error.message == "Method not found"
      assert not Map.has_key?(response.error, :data)
      assert not Map.has_key?(response, :result)
    end

    test "formats error response correctly with data" do
      response = Protocol.format_error(3, -32602, "Invalid params", %{"detail" => "bad param"})
      assert response.jsonrpc == "2.0"
      assert response.id == 3
      assert response.error.code == -32602
      assert response.error.message == "Invalid params"
      assert response.error.data == %{"detail" => "bad param"}
    end
  end
end
