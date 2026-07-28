defmodule Scoria.Runtime.Rails do
  @moduledoc """
  Resolves the per-run rails config surface (RAIL-01): a two-rung ladder,
  the per-run `:rails` option over the app-level
  `config :scoria, Scoria.Runtime.Rails` default -- LAST-WRITER-WINS per
  key, independently.

  This is deliberately NOT Phase 56's D-04 tighten-only join (a `min/2`
  copied from `Trust.Scan.most_restrictive/2` or Phase 56's own join would
  pass every ladder case except the one that matters). D-04 justifies
  tighten-only because its host operand is request-derived; here BOTH
  operands -- the per-run option and the app default -- are host source
  code, so D-04's own predicate returns false and last-writer-wins is
  correct. Do not "fix" this into a min-join.

  `:rails`, not `:limits`/`:budget` -- `budget_context` is an active
  `Scoria.Runtime.Params` dispatch key feeding tenant `BudgetEngine`, and
  RAIL-01 states rails are distinct from tenant-level budgets/breakers.
  And not Ruby on Rails.

  The three recognised keys are `:max_steps` (a count), `:max_tool_calls`
  (a count), and `:max_active_ms` (integer milliseconds -- a duration,
  never an absolute deadline). Absent or `nil` at both rungs means
  unlimited. `0`, a negative integer, a float, a binary, or any other
  non-positive-integer shape is refused as
  `{:error, {:invalid_rail, key, value}}` -- a deliberate inversion of
  Phase 56's D-04 fail-closed-to-most-restrictive rule: a rail's junk
  operand is a typo in the HOST'S OWN source, where "most restrictive"
  would mean every run halts on step zero and the adopter is bricked. Loud
  refusal at a host-controlled call site IS the fail-closed behaviour
  here. An unknown key inside `:rails` is `{:error, {:unknown_rail, key}}`
  -- a typo'd `max_tool_call` silently becoming "unlimited" is the most
  likely and most dangerous adopter mistake, deliberately diverging from
  `Scoria.Observe.Bounds`'s permissive `Keyword.merge`.

  `validate_app_env/0` NEVER raises and must NEVER be called from, or
  raise out of, `Scoria.Application.start/2` -- `application.ex` states
  the doctrine verbatim: a boot crash takes the entire host app down
  (T-53-08). A misconfigured app env fails closed on the RUN, which is
  recoverable, never on the BOOT, which is not.

  Resolution happens exactly once, at run creation -- a later config
  change must never retroactively halt a live run.
  """

  require Logger

  @recognised_keys ~w(max_steps max_tool_calls max_active_ms)a
  @recognised_key_strings Enum.map(@recognised_keys, &Atom.to_string/1)
  @warned_table :scoria_runtime_rails_warned_keys

  @type resolved :: %{
          rail_max_steps: pos_integer() | nil,
          rail_max_tool_calls: pos_integer() | nil,
          rail_max_active_ms: pos_integer() | nil
        }

  @doc """
  Resolves the two-rung ladder for one run: `opts[:rails]` (per-run,
  wins outright in either direction) over
  `config :scoria, Scoria.Runtime.Rails` (the app default) -- last-writer-
  wins, independently per key.

  Returns `{:ok, resolved}` or `{:error, {:invalid_rail, key, value}}` or
  `{:error, {:unknown_rail, key}}`. On error, no run row has been created
  yet -- callers (`Scoria.Runtime.Params.start/2` and `start_handoff/3`)
  propagate the error out of their own `with` chain before
  `Scoria.Workflows.create_run/1` is ever reached.
  """
  @spec resolve(map() | keyword()) ::
          {:ok, resolved()}
          | {:error, {:invalid_rail, atom(), term()}}
          | {:error, {:unknown_rail, atom() | String.t()}}
  def resolve(opts \\ []) do
    opts = normalize_map(opts)
    per_run = opts |> canonical_value(:rails) |> normalize_map()

    with :ok <- validate_app_env(),
         :ok <- validate_no_unknown_keys(per_run),
         {:ok, resolved} <- resolve_values(per_run) do
      {:ok, resolved}
    end
  rescue
    _exception -> {:error, {:invalid_rail, :rails, opts}}
  end

  @doc """
  Validates `config :scoria, Scoria.Runtime.Rails` in isolation, without
  any per-run input. Returns `:ok` or `{:error, {:invalid_rail, key,
  value}}`.

  NEVER raises. Must NEVER be called from, or allowed to raise out of,
  `Scoria.Application.start/2` (T-53-08) -- a boot crash takes the entire
  host application down. A misconfigured app env is logged once per boot
  at `Logger.error` (via the same ETS `log_once` idiom as
  `Scoria.Observe.Bounds`) and refuses the next `resolve/1` call -- i.e.
  the next run -- never the boot itself.
  """
  @spec validate_app_env() :: :ok | {:error, {:invalid_rail, atom(), term()}}
  def validate_app_env do
    env = app_env()

    @recognised_keys
    |> Enum.reduce_while(:ok, fn key, :ok ->
      case validate_value(key, canonical_value(env, key)) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> maybe_log_app_env_error()
  rescue
    exception ->
      error = {:error, {:invalid_rail, :app_env, Exception.message(exception)}}
      maybe_log_app_env_error(error)
  end

  # -- ladder resolution -------------------------------------------------

  defp resolve_values(per_run) do
    env = app_env()

    Enum.reduce_while(@recognised_keys, {:ok, %{}}, fn key, {:ok, acc} ->
      per_run_value = canonical_value(per_run, key)

      case validate_value(key, per_run_value) do
        :ok ->
          app_value = canonical_value(env, key)
          effective = first_present([per_run_value, app_value])
          {:cont, {:ok, Map.put(acc, rail_field(key), effective)}}

        {:error, _reason} = error ->
          {:halt, error}
      end
    end)
  end

  defp first_present(values), do: Enum.find(values, &(&1 != nil))

  defp rail_field(:max_steps), do: :rail_max_steps
  defp rail_field(:max_tool_calls), do: :rail_max_tool_calls
  defp rail_field(:max_active_ms), do: :rail_max_active_ms

  # `nil`/absent inherits the next rung and is unlimited if neither rung
  # sets it. A positive integer is the only accepted concrete value; `0`,
  # negative integers, floats, binaries, and anything else are refused.
  defp validate_value(_key, nil), do: :ok
  defp validate_value(_key, value) when is_integer(value) and value > 0, do: :ok
  defp validate_value(key, value), do: {:error, {:invalid_rail, key, value}}

  defp validate_no_unknown_keys(per_run) do
    per_run
    |> Map.keys()
    |> Enum.find(&(&1 not in @recognised_keys and &1 not in @recognised_key_strings))
    |> case do
      nil -> :ok
      key -> {:error, {:unknown_rail, key}}
    end
  end

  # -- app env ------------------------------------------------------------

  defp app_env do
    Application.get_env(:scoria, Scoria.Runtime.Rails, [])
    |> normalize_map()
  end

  defp maybe_log_app_env_error(:ok), do: :ok

  defp maybe_log_app_env_error({:error, {:invalid_rail, key, value}} = error) do
    if first_warning_for_key?(key) do
      Logger.error(
        "Scoria.Runtime.Rails: invalid config :scoria, Scoria.Runtime.Rails for " <>
          "#{inspect(key)}: #{inspect(value)} -- every run will be refused until this is fixed"
      )
    end

    error
  end

  defp first_warning_for_key?(key) do
    ensure_warned_table()
    :ets.insert_new(@warned_table, {key, true})
  end

  defp ensure_warned_table do
    case :ets.whereis(@warned_table) do
      :undefined -> :ets.new(@warned_table, [:named_table, :set, :public, read_concurrency: true])
      _table -> :ok
    end
  end

  # -- normalization ------------------------------------------------------

  defp normalize_map(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_map()
  defp normalize_map(attrs) when is_list(attrs), do: attrs |> Enum.into(%{}) |> normalize_map()
  defp normalize_map(attrs) when is_map(attrs), do: Map.new(attrs)
  defp normalize_map(_attrs), do: %{}

  defp canonical_value(attrs, key) when is_map(attrs) do
    cond do
      Map.has_key?(attrs, key) -> Map.get(attrs, key)
      Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
      true -> nil
    end
  end

  defp canonical_value(_attrs, _key), do: nil
end
