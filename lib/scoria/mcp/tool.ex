defmodule Scoria.MCP.Tool do
  @moduledoc """
  Behaviour for defining an MCP tool.
  """

  @doc "Name of the tool"
  @callback name() :: String.t()

  @doc "Description of what the tool does"
  @callback description() :: String.t()

  @doc "Ecto schemaless map definition for tool arguments"
  @callback input_schema() :: map()

  @doc "Executes the tool with validated arguments and context"
  @callback execute(args :: map(), context :: map()) :: {:ok, any()} | {:error, any()}
end
