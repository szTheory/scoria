defmodule Scoria.MCP.Protocol do
  @moduledoc """
  JSON-RPC 2.0 parsing and formatting for the MCP Gateway.
  """

  @type jsonrpc_request :: %{
          jsonrpc: String.t(),
          method: String.t(),
          params: term() | nil,
          id: term() | nil
        }

  @type jsonrpc_error :: %{
          code: integer(),
          message: String.t(),
          data: term() | nil
        }

  @doc """
  Parses an incoming map into a structured JSON-RPC request.
  Validates `jsonrpc: "2.0"`, `method`, `params`, and `id`.

  Returns `{:ok, request}` or `{:error, error_response}`.
  """
  def parse(payload) when is_map(payload) do
    with :ok <- validate_jsonrpc(payload),
         :ok <- validate_method(payload) do
      request = %{
        jsonrpc: "2.0",
        method: payload["method"],
        params: Map.get(payload, "params"),
        id: Map.get(payload, "id")
      }

      {:ok, request}
    else
      {:error, code, message} ->
        # Determine id if present for error response, otherwise nil
        id = Map.get(payload, "id")
        {:error, format_error(id, code, message)}
    end
  end

  def parse(_), do: {:error, format_error(nil, -32600, "Invalid Request")}

  defp validate_jsonrpc(%{"jsonrpc" => "2.0"}), do: :ok
  defp validate_jsonrpc(_), do: {:error, -32600, "Invalid Request"}

  defp validate_method(%{"method" => method}) when is_binary(method), do: :ok
  defp validate_method(_), do: {:error, -32600, "Invalid Request"}

  @doc """
  Formats a successful JSON-RPC 2.0 response.
  """
  def format_response(id, result) do
    %{
      jsonrpc: "2.0",
      id: id,
      result: result
    }
  end

  @doc """
  Formats a JSON-RPC 2.0 error response.
  """
  def format_error(id, code, message, data \\ nil) do
    error = %{
      code: code,
      message: message
    }

    error = if data, do: Map.put(error, :data, data), else: error

    %{
      jsonrpc: "2.0",
      id: id,
      error: error
    }
  end
end
