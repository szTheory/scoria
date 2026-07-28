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

  @doc """
  Optional trifecta classification: declares whether this tool reads
  private data, sees untrusted content, can exfiltrate, and its
  `action_class` (`"read"` / `"write"` / `"exec"` / `"admin"`). Declaring
  this once on the tool module lets the MCP executor resolve the tool's
  classification before every call instead of trusting a per-call
  host-passed default.
  """
  @callback classification() :: Scoria.MCP.Classification.t()

  @optional_callbacks [classification: 0]

  @doc """
  `use Scoria.MCP.Tool, reads_private_data: true, sees_untrusted_content:
  false, can_exfiltrate: true, action_class: "exec"` generates a
  `classification/0` callback from the given opts.

  Any opt left unspecified defaults conservatively: `reads_private_data:
  false`, `sees_untrusted_content: false`, `can_exfiltrate: false`,
  `action_class: "read"` -- a bare `use Scoria.MCP.Tool` is a positive (if
  minimal) declaration, not the maximal `unclassified_default/0` reserved
  for tools declaring nothing at all.
  """
  defmacro __using__(opts) do
    reads_private_data = Keyword.get(opts, :reads_private_data, false)
    sees_untrusted_content = Keyword.get(opts, :sees_untrusted_content, false)
    can_exfiltrate = Keyword.get(opts, :can_exfiltrate, false)
    action_class = Keyword.get(opts, :action_class, "read")

    quote do
      @behaviour Scoria.MCP.Tool

      @impl true
      def classification do
        Scoria.MCP.Classification.declared(
          reads_private_data: unquote(reads_private_data),
          sees_untrusted_content: unquote(sees_untrusted_content),
          can_exfiltrate: unquote(can_exfiltrate),
          action_class: unquote(action_class)
        )
      end
    end
  end
end
