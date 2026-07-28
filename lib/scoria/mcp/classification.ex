defmodule Scoria.MCP.Classification do
  @moduledoc """
  Tool-declared trifecta classification: the three "lethal trifecta" legs
  (`reads_private_data`, `sees_untrusted_content`, `can_exfiltrate`) plus a
  closed `action_class` enum, sourced from a tool's own declaration rather
  than a per-call host-passed default.

  Deliberately a dependency-free leaf: it references no workflow runtime
  module, no knowledge module, no observability module, and no tool
  behaviour module, so those layers can all depend on this struct without
  ever creating a compile cycle back through here.

  ## `action_class` ordering (D-02)

  `action_classes/0` is `~w(read write exec admin)`, reused verbatim from
  the pre-existing replay-disposition enum (this module is now that list's
  single owner). The order is load-bearing: `"read"` is pinned at index 0
  as the sole non-effectful member, and the replay disposition resolver's
  effectful/remote predicate branches on `Enum.drop(action_classes(), 1)`.

  ## Fail-closed defaults (D-03)

  A tool with no `classification/0` declaration resolves to
  `unclassified_default/0` -- all three legs `true`, `action_class:
  "admin"` -- NOT a bug, a deliberate maximal-caution default so an
  undeclared tool never silently under-reports its risk. It still runs;
  the executor emits `[:scoria, :class, :unclassified]` once per call so
  the default is inspectable rather than silent.
  """

  require Logger

  @action_classes ~w(read write exec admin)
  @default_action_class "admin"
  @sources [:tool_declared, :host_tightened, :unclassified_default]
  @default_isolation_timeout_ms 5_000

  @enforce_keys [:source]
  defstruct [
    :source,
    reads_private_data: false,
    sees_untrusted_content: false,
    can_exfiltrate: false,
    action_class: @default_action_class
  ]

  @type action_class :: String.t()
  @type source :: :tool_declared | :host_tightened | :unclassified_default
  @type t :: %__MODULE__{
          reads_private_data: boolean(),
          sees_untrusted_content: boolean(),
          can_exfiltrate: boolean(),
          action_class: action_class(),
          source: source()
        }

  @doc """
  The closed, ordered `action_class` enum. Order is load-bearing (D-02) --
  `"read"` is pinned at index 0 as the sole non-effectful member.
  """
  @spec action_classes() :: [action_class()]
  def action_classes, do: @action_classes

  @doc "The maximally-gated `action_class`, used whenever a value cannot be trusted."
  @spec default_action_class() :: action_class()
  def default_action_class, do: @default_action_class

  @doc "The closed `source` enum."
  @spec sources() :: [source()]
  def sources, do: @sources

  @doc """
  Normalizes `value` to a member of `action_classes/0`. Any value that is
  not an exact-match binary member of the enum -- including `nil`, `""`,
  atoms, and mismatched case -- fails closed to `default_action_class/0`
  after a `Logger.warning` and a best-effort telemetry emit, mirroring the
  observability layer's own reason-code fallback discipline.
  """
  @spec normalize_action_class(term()) :: action_class()
  def normalize_action_class(value) when is_binary(value) do
    if value in @action_classes do
      value
    else
      fallback_action_class(value)
    end
  end

  def normalize_action_class(value), do: fallback_action_class(value)

  defp fallback_action_class(value) do
    Logger.warning(
      "Unrecognized Scoria.MCP.Classification action_class #{inspect(value)}, defaulting to #{inspect(@default_action_class)}"
    )

    try do
      :telemetry.execute([:scoria, :class, :action_class_fallback], %{}, %{value: value})
    rescue
      _ -> :ok
    end

    @default_action_class
  end

  @doc """
  The fail-closed-but-inspectable maximal default (D-03): all three legs
  `true`, `action_class: "admin"`, `source: :unclassified_default`. Used
  ONLY when a tool has no usable declaration -- it is never a join operand
  (D-04).
  """
  @spec unclassified_default() :: t()
  def unclassified_default do
    %__MODULE__{
      reads_private_data: true,
      sees_untrusted_content: true,
      can_exfiltrate: true,
      action_class: @default_action_class,
      source: :unclassified_default
    }
  end

  @doc """
  Constructs a `%__MODULE__{source: :tool_declared}` from a keyword list or
  map. This is the single origin a generated `classification/0` callback
  (from the tool behaviour's `use` macro) routes through -- unspecified
  legs default conservatively to `false` and an unspecified `action_class`
  defaults to `"read"` (D-A3): declaring this is a positive, if minimal,
  statement, never the maximal `unclassified_default/0` reserved for
  declaring nothing at all.
  """
  @spec declared(Enumerable.t()) :: t()
  def declared(attrs) do
    attrs = Map.new(attrs)

    %__MODULE__{
      reads_private_data: coerce_boolean(Map.get(attrs, :reads_private_data, false)),
      sees_untrusted_content: coerce_boolean(Map.get(attrs, :sees_untrusted_content, false)),
      can_exfiltrate: coerce_boolean(Map.get(attrs, :can_exfiltrate, false)),
      action_class: normalize_action_class(Map.get(attrs, :action_class, "read")),
      source: :tool_declared
    }
  end

  @doc """
  Resolves `tool_module`'s declared classification, or `:none` when the
  module has no usable declaration.

  Detection mirrors the semantic-cache profile's `cond`-based detection
  shape: `Code.ensure_loaded?/1` FIRST (a lazily-loaded module under
  `:interactive` must not be misread as undeclared), then
  `function_exported?/3`. The result is memoized in `:persistent_term`
  keyed by module -- the DECLARATION only, never a per-call joined result.

  The actual `tool_module.classification/0` invocation is isolated behind a
  bounded `Task.Supervisor.async_nolink/2` on the existing
  `Scoria.MCP.TaskSupervisor`, mirroring the trust scanner's bounded-Task
  isolation shape (D-A1): a raising, exiting, or hanging callback -- or an
  unstarted supervisor (e.g. a `--no-start` test lane) -- all fail closed
  to `:none` rather than propagating to the caller.

  Whatever the callback returns is normalized per D-A4: a non-struct
  return, a junk `action_class`, or non-boolean legs all fail closed
  (`action_class` to `default_action_class/0`, legs coerced to `true`), and
  `source` is force-set to `:tool_declared` -- a hand-written
  `classification/0` cannot self-assign `source`.
  """
  @spec tool_declaration(module()) :: {:ok, t()} | :none
  def tool_declaration(tool_module) when is_atom(tool_module) do
    case :persistent_term.get(memo_key(tool_module), :__miss__) do
      :__miss__ ->
        result = resolve_declaration(tool_module)
        :persistent_term.put(memo_key(tool_module), result)
        result

      cached ->
        cached
    end
  end

  def tool_declaration(_tool_module), do: :none

  defp resolve_declaration(tool_module) do
    cond do
      not Code.ensure_loaded?(tool_module) ->
        :none

      not function_exported?(tool_module, :classification, 0) ->
        :none

      true ->
        case isolated_classification(tool_module) do
          {:ok, value} -> {:ok, normalize_callback_return(value)}
          :error -> :none
        end
    end
  end

  defp isolated_classification(tool_module) do
    try do
      task =
        Task.Supervisor.async_nolink(Scoria.MCP.TaskSupervisor, fn ->
          try do
            {:ok, tool_module.classification()}
          catch
            kind, reason -> {:__classification_caught__, kind, reason}
          end
        end)

      case Task.yield(task, isolation_timeout_ms()) || Task.shutdown(task, :brutal_kill) do
        {:ok, {:ok, value}} -> {:ok, value}
        {:ok, {:__classification_caught__, _kind, _reason}} -> :error
        nil -> :error
        {:exit, _reason} -> :error
      end
    rescue
      _ -> :error
    catch
      _kind, _reason -> :error
    end
  end

  # Reads a per-module timeout override via `config :scoria,
  # Scoria.MCP.Classification, isolation_timeout_ms: ...` -- gives tests a
  # way to exercise the timeout branch without a real multi-second sleep.
  defp isolation_timeout_ms do
    :scoria
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:isolation_timeout_ms, @default_isolation_timeout_ms)
  end

  defp normalize_callback_return(value) do
    %__MODULE__{
      reads_private_data: coerce_boolean(field_value(value, :reads_private_data)),
      sees_untrusted_content: coerce_boolean(field_value(value, :sees_untrusted_content)),
      can_exfiltrate: coerce_boolean(field_value(value, :can_exfiltrate)),
      action_class: normalize_action_class(field_value(value, :action_class)),
      source: :tool_declared
    }
  end

  defp field_value(%__MODULE__{} = struct, field), do: Map.get(struct, field)
  defp field_value(map, field) when is_map(map), do: Map.get(map, field)
  defp field_value(_other, _field), do: nil

  defp coerce_boolean(value) when is_boolean(value), do: value
  defp coerce_boolean(_value), do: true

  defp memo_key(tool_module), do: {__MODULE__, :tool_declaration, tool_module}

  @doc false
  def reset_memo(tool_module) do
    :persistent_term.erase(memo_key(tool_module))
    :ok
  end

  @doc false
  def reset_memo do
    :persistent_term.get()
    |> Enum.each(fn
      {{__MODULE__, :tool_declaration, _tool_module} = key, _value} -> :persistent_term.erase(key)
      _entry -> :ok
    end)

    :ok
  end
end
