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

  **Accepted limitation (56.1-04, RAIL-01):** rails are enforced at
  admission -- a run already executing a step or a tool call when its
  budget is exhausted is not interrupted, it is denied at the next
  admission point. Three cases are not caught by this: a run wedged inside
  one long tool call (bounded only by the per-call `Task.yield`/
  `Task.shutdown` default of 5 000 ms, see `Runtime.execute_step/2`'s
  `@default_timeout`); a run whose steps are all orphaned in `"running"`
  after a node death (this is crash recovery, not RAIL-01, and it is the
  real residual gap); and a run in `"waiting_for_approval"`, which is by
  design and not a gap (D-14).
  """

  import Ecto.Query, warn: false

  alias Scoria.Repo
  alias Scoria.Workflows.Run

  @doc """
  Atomically admits (or denies) the next step execution against
  `run.rail_max_steps` AND `run.rail_max_active_ms` in a single UPDATE.

  Returns `{:ok, count}` with the POST-increment `rail_steps` value on
  admission, or `:denied` when either limit has already been reached. `now`
  is bound as an Elixir parameter, explicitly type-ascribed to
  `:utc_datetime_usec` inside the fragment -- never a Postgres-side clock
  read, which would be transaction-start time (stale inside a long host
  transaction) and unfreezable in tests.
  """
  def admit_step(run_id, now \\ DateTime.utc_now()) do
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
        where: ^active_time_predicate(now),
        select: r.rail_steps
      )

    case Repo.update_all(query, inc: [rail_steps: 1]) do
      {1, [count]} -> {:ok, count}
      {0, _} -> :denied
    end
  end

  # RAIL-01 D-09/D-14: the active-time predicate, composed via `dynamic/2`
  # so it can be shared between `admit_step/2`'s `where` and any future
  # caller. `now` is bound with an explicit `:utc_datetime_usec` type
  # ascription -- NOT cosmetic: `started_at`/`inserted_at` are
  # `timestamp(6)` WITHOUT time zone, and an unascribed `%DateTime{}` is
  # encoded by Postgrex as `timestamptz`, whose implicit subtraction cast
  # consults the session `TimeZone` and silently shifts the rail by the UTC
  # offset on any non-UTC session (RESEARCH Pitfall 5). The anchor is
  # `COALESCE(started_at, inserted_at)` -- `inserted_at` is `NOT NULL` via
  # `timestamps()`, so the predicate never divides by a nil anchor.
  defp active_time_predicate(now) do
    dynamic(
      [r],
      is_nil(r.rail_max_active_ms) or
        fragment(
          "(EXTRACT(EPOCH FROM (? - COALESCE(?, ?))) * 1000 - ?) < ?",
          type(^now, :utc_datetime_usec),
          r.started_at,
          r.inserted_at,
          r.rail_paused_ms,
          r.rail_max_active_ms
        )
    )
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
  (`max_active_ms` -> `max_steps` -> `max_tool_calls`): a run over BOTH its
  time and step budgets reports `:max_active_ms_exceeded`.

  `now` is bound as an Elixir parameter, matching `admit_step/2`'s own rule
  (never a Postgres-side clock read).
  """
  def deny_reason(run_id, now \\ DateTime.utc_now()) do
    run =
      Repo.one(
        from(r in Run,
          where: r.id == ^run_id,
          select: %{
            rail_steps: r.rail_steps,
            rail_max_steps: r.rail_max_steps,
            rail_tool_calls: r.rail_tool_calls,
            rail_max_tool_calls: r.rail_max_tool_calls,
            rail_max_active_ms: r.rail_max_active_ms,
            rail_paused_ms: r.rail_paused_ms,
            started_at: r.started_at,
            inserted_at: r.inserted_at
          }
        )
      )

    case run do
      nil ->
        :no_run

      row ->
        cond do
          active_time_exceeded?(row, now) -> :max_active_ms_exceeded
          steps_exceeded?(row) -> :max_steps_exceeded
          tool_calls_exceeded?(row) -> :max_tool_calls_exceeded
          true -> :unknown
        end
    end
  end

  defp active_time_exceeded?(%{rail_max_active_ms: nil}, _now), do: false

  defp active_time_exceeded?(%{rail_max_active_ms: max_active_ms} = row, now) do
    anchor = row.started_at || row.inserted_at
    elapsed_ms = DateTime.diff(now, anchor, :millisecond) - (row.rail_paused_ms || 0)
    elapsed_ms >= max_active_ms
  end

  defp steps_exceeded?(%{rail_steps: steps, rail_max_steps: max_steps}) do
    not is_nil(max_steps) and steps >= max_steps
  end

  defp tool_calls_exceeded?(%{rail_tool_calls: calls, rail_max_tool_calls: max_calls}) do
    not is_nil(max_calls) and calls >= max_calls
  end
end
