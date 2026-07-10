defmodule Scoria.MCP.Tool do
  @moduledoc """
  `Scoria.MCP.Tool` is the behaviour for host-defined MCP tools that Scoria can
  register, validate, invoke, and show to reviewers.

  Implement this behaviour when a remote connector exposes a tool that should
  participate in Scoria's connector policy, approval, and audit flow. The host
  owns the tool's business meaning, argument contract, implementation, and
  authorization policy. Scoria owns the MCP metadata shape, invocation evidence,
  and reviewer trace projection.

  See `guides/capabilities/connectors-and-mcp.md` for the connector and MCP
  capability guide.
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
