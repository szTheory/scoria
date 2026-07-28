defmodule Scoria.Workflows.Rails do
  @moduledoc """
  DB-facing per-run rail admission (RAIL-01). Owns the atomic
  compare-and-swap that admits or denies a step/tool-call attempt against a
  run's configured `rail_max_*` limits.

  **The honest contract, verbatim (56.1-CONTEXT.md D-09):** `max_steps` and
  `max_tool_calls` are enforced by a single atomic
  `UPDATE ... WHERE counter < limit RETURNING counter`. Postgres takes a
  row-level exclusive lock on the run row for the statement's duration, so
  concurrent sibling steps and tool calls serialize on it. Exactly `limit`
  executions are admitted; there is no overshoot. Rails count *attempts*,
  not successes: a call that crashes, times out, is blocked by the replay
  gate, or is served as a historical stub has already consumed its budget.
  This no-overshoot guarantee depends on Postgres **READ COMMITTED**
  EvalPlanQual re-checking the `WHERE` after a lock wait; under a host
  running `REPEATABLE READ` or `SERIALIZABLE` the blocked statement aborts
  with `40001` instead.

  Counting is unconditional -- `admit_step/2` always executes its single
  UPDATE, even when the run's limit is `nil` (unlimited), so an unlimited
  run still admits AND counts. This is what makes the sizing recipe in
  `guides/capabilities/per-run-rails.md` (`max(rail_steps)` over historical
  runs) possible; short-circuiting on a `nil` limit would leave the
  counters at `0` forever for the ~100% of adopters who never configure a
  rail.

  `Scoria.Runtime.Rails` (not this module) owns the host-facing config
  resolution (`resolve/1`, `validate_app_env/0`); this module is DB-facing
  only.
  """

  import Ecto.Query, warn: false

  alias Scoria.Repo
  alias Scoria.Workflows.Run

  @doc """
  Atomically admits (or denies) the next step execution against
  `run.rail_max_steps`.

  Returns `{:ok, count}` with the POST-increment `rail_steps` value on
  admission, or `:denied` when the limit has already been reached. `now` is
  bound as an Elixir parameter (never `fragment("now()")`, which is
  transaction-start time and would be stale inside a long host
  transaction and unfreezable in tests) -- unused today (no time-based
  predicate on this rail) but accepted for signature symmetry with a future
  active-time check.
  """
  def admit_step(run_id, now \\ DateTime.utc_now()) do
    _ = now

    query =
      from(r in Run,
        where: r.id == ^run_id,
        # THREE-VALUED-LOGIC TRAP: `r.rail_steps < r.rail_max_steps` is NULL
        # (not TRUE) when the limit is NULL, so the row would not match and
        # "unlimited" would silently become "deny everything". The
        # `is_nil/1` disjunct is MANDATORY -- and it is also what makes an
        # unlimited run admit-and-COUNT rather than short-circuit (see
        # moduledoc).
        where: is_nil(r.rail_max_steps) or r.rail_steps < r.rail_max_steps,
        select: r.rail_steps
      )

    case Repo.update_all(query, inc: [rail_steps: 1]) do
      {1, [count]} -> {:ok, count}
      {0, _} -> :denied
    end
  end

  @doc """
  Atomically admits (or denies) the next tool call against
  `run.rail_max_tool_calls`. Same CAS shape as `admit_step/2`.
  """
  def admit_tool_call(run_id, now \\ DateTime.utc_now()) do
    _ = now

    query =
      from(r in Run,
        where: r.id == ^run_id,
        where: is_nil(r.rail_max_tool_calls) or r.rail_tool_calls < r.rail_max_tool_calls,
        select: r.rail_tool_calls
      )

    case Repo.update_all(query, inc: [rail_tool_calls: 1]) do
      {1, [count]} -> {:ok, count}
      {0, _} -> :denied
    end
  end

  @doc """
  Cold-path disambiguation for a `:denied` admission -- one follow-up
  `Repo.one/1` over the rail columns, never folded into the admit
  statement itself. Returns `:no_run` when the row is absent, otherwise the
  reason for the denial per the fixed check order
  (`max_active_ms` -> `max_steps` -> `max_tool_calls`).
  """
  def deny_reason(run_id) do
    run =
      Repo.one(
        from(r in Run,
          where: r.id == ^run_id,
          select: %{
            rail_steps: r.rail_steps,
            rail_max_steps: r.rail_max_steps,
            rail_tool_calls: r.rail_tool_calls,
            rail_max_tool_calls: r.rail_max_tool_calls
          }
        )
      )

    case run do
      nil ->
        :no_run

      %{rail_steps: steps, rail_max_steps: max_steps}
      when not is_nil(max_steps) and steps >= max_steps ->
        :max_steps_exceeded

      %{rail_tool_calls: calls, rail_max_tool_calls: max_calls}
      when not is_nil(max_calls) and calls >= max_calls ->
        :max_tool_calls_exceeded

      _ ->
        :unknown
    end
  end
end
