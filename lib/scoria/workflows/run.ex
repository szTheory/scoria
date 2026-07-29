defmodule Scoria.Workflows.Run do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(running waiting_for_approval paused retrying failed completed cancelled halted)
  @execution_modes ~w(live replay)

  # RAIL-01 D-14/D-15: the timeout rail's pause set. A run whose status is
  # in this set is not dispatchable and consumes no active time.
  @rail_pause_set ["waiting_for_approval", "paused"]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_workflow_runs" do
    field :actor_id, :string
    field :tenant_id, :string
    field :session_id, :string
    field :root_role_id, :string
    field :source_run_id, :binary_id
    field :source_checkpoint_id, :binary_id
    field :status, :string, default: "running"
    field :execution_mode, :string, default: "live"
    field :replay_overrides, :map, default: %{}
    field :current_step_id, :binary_id
    field :latest_checkpoint_id, :binary_id
    field :lock_version, :integer, default: 1
    field :metadata, :map, default: %{}
    field :error_envelope, :map, default: %{}
    field :started_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec
    field :last_heartbeat_at, :utc_datetime_usec

    # Per-run rails (RAIL-01, 56.1-01 D-07). `rail_max_*` are the three
    # configured limits (nil = unlimited); `rail_steps`/`rail_tool_calls` are
    # durable attempt counters incremented only by `Scoria.Workflows.Rails`'
    # atomic `Repo.update_all(inc: ...)`. `rail_paused_ms`/`rail_paused_at`
    # are the D-15 pause-accounting pair, derived from the `:status`
    # transition rather than written at call sites (see the load-bearing
    # comment on `cast/3` below).
    field :rail_max_steps, :integer
    field :rail_max_tool_calls, :integer
    field :rail_max_active_ms, :integer
    field :rail_steps, :integer, default: 0
    field :rail_tool_calls, :integer, default: 0
    field :rail_paused_ms, :integer, default: 0
    field :rail_paused_at, :utc_datetime_usec

    # D-15: the per-run confluence leg accumulator, keyed on the same
    # `(tool, grade)` vocabulary the escalation gate evaluates against.
    # Written ONLY by a dedicated `Repo.update_all(..., returning: [...])`
    # fold (never by this changeset -- see the LOAD-BEARING comment on
    # `cast/3` below, which this field joins on the same disjointness
    # rule as the rail counters).
    #
    # Value shape (plan 57-06, cross-phase obligation 1 for Phase 58): a
    # map keyed by leg name -- currently `"private_data"` and
    # `"untrusted_content"` only, the two EXPOSURE legs D-11 accumulates
    # per run; the EXFIL leg is per-call and NEVER appears here. Each LIT
    # leg's value is itself a map with:
    #   - "lit" -- always `true` when the key is present. An unlit leg is
    #     never written (D-15.2); there is no `false` sentinel and no key
    #     ever means "not (yet) lit".
    #   - "source" -- the STRONGEST witness source seen for this leg so
    #     far (`"declared"` > observed `"scanner_infra"` >
    #     `"default_tier"` > `"unclassified"`), re-graded upward whenever
    #     a stronger witness arrives later in the run (D-15.1) -- never
    #     downward, and never cleared (D-12).
    #   - "reason_code" -- the winning witness's own reason code, or
    #     `nil` when it carries none.
    #   - "first_step_id" -- the id of the step that FIRST lit this leg,
    #     preserved across every later re-grade of "source".
    #   - "strongest_source" -- identical to "source"; both keys exist so
    #     this map is self-describing to a reader who does not already
    #     know "source" here means "the strongest one accumulated so
    #     far", not "the most recent one".
    #
    # This is Phase 58's read path for re-deriving both the named
    # combination and the grade via `Scoria.Confluence.classify/1` --
    # NOT the step's `result_envelope` (wholesale-replaced by
    # `Scoria.Workflows.complete_step/3` on every successful step and
    # zeroed by `retry_step/1`; see the corrected durability note on
    # `Scoria.MCP.Executor.persist_taint/3`) and NOT the audit outbox.
    field :confluence_legs, :map, default: %{}

    has_many :steps, Scoria.Workflows.Step
    has_many :checkpoints, Scoria.Workflows.Checkpoint
    has_many :events, Scoria.Workflows.Event
    has_many :handoffs, Scoria.Workflows.Handoff
    has_many :approvals, Scoria.Observe.Approval, foreign_key: :workflow_run_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  `true` when `run.status == "halted"` -- the terminal status a per-run
  rail writes (RAIL-01). Halted runs cannot be claimed, retried, resumed, or
  clamped back to a live status; see `Scoria.Workflows.halt_run/3` and the
  six terminality guards in `Scoria.Workflows`.
  """
  def halted?(%__MODULE__{status: "halted"}), do: true
  def halted?(%__MODULE__{}), do: false

  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :session_id,
      :actor_id,
      :tenant_id,
      :root_role_id,
      :source_run_id,
      :source_checkpoint_id,
      :status,
      :execution_mode,
      :replay_overrides,
      :current_step_id,
      :latest_checkpoint_id,
      :lock_version,
      :metadata,
      :error_envelope,
      :started_at,
      :completed_at,
      :last_heartbeat_at,
      # Only the three configured LIMITS are cast here. The four
      # counter/pause fields (:rail_steps, :rail_tool_calls, :rail_paused_ms,
      # :rail_paused_at) are DELIBERATELY absent from this list -- see the
      # LOAD-BEARING comment just below this function for why that
      # separation is load-bearing. `:confluence_legs` (D-15) joins them on
      # the SAME rule and is also deliberately absent.
      :rail_max_steps,
      :rail_max_tool_calls,
      :rail_max_active_ms
    ])
    |> validate_replay_allowlist_immutability()
    |> derive_rail_pause_accounting()
    |> validate_required([:root_role_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:execution_mode, @execution_modes)
    |> validate_number(:rail_max_steps, greater_than_or_equal_to: 0)
    |> validate_number(:rail_max_tool_calls, greater_than_or_equal_to: 0)
    |> validate_number(:rail_max_active_ms, greater_than_or_equal_to: 0)
    |> optimistic_lock(:lock_version)
  end

  # LOAD-BEARING: `:rail_steps`, `:rail_tool_calls`, `:rail_paused_ms`,
  # `:rail_paused_at`, and `:confluence_legs` (57 D-15) are never cast by
  # `changeset/2` above -- they are written only by
  # `Scoria.Workflows.Rails`' atomic `Repo.update_all(inc: ...)` (the rail
  # counters), the pause-accounting derivation below, and (for
  # `:confluence_legs`) a dedicated `Repo.update_all(..., returning: [...])`
  # fold that keeps the strongest witness per leg. This is the
  # read-modify-write defence: `Repo.update` SETs only `changeset.changes`,
  # so a concurrent changeset holding a stale `%Run{}` cannot clobber a
  # counter written by another transaction in between; conversely
  # `Repo.update_all(...)` never touches `:lock_version`, so it can never
  # provoke `Ecto.StaleEntryError` against `optimistic_lock/2`. The two
  # writer classes stay disjoint by construction, not by convention.

  # RAIL-01 D-15: pause accounting derived from the `:status` transition
  # itself -- NOT written at call sites. Mirrors
  # `validate_replay_allowlist_immutability/1` immediately below: read the
  # pre-transition value from `changeset.data.status` and the
  # post-transition value from `get_field(changeset, :status)`, then derive.
  #
  # Entering the pause set (`@rail_pause_set`) from outside it sets
  # `rail_paused_at` to the transition time. Leaving the pause set folds
  # `DateTime.diff(now, rail_paused_at, :millisecond)` into `rail_paused_ms`
  # and nulls `rail_paused_at`. Transitions within the set, and transitions
  # where the status does not change, leave both fields untouched.
  #
  # This is the ONLY writer of these two fields -- they are absent from
  # `cast/3` above -- so every caller that moves `:status`
  # (`mark_waiting_for_approval/3`, `resume_run/1`, `complete_step/3`,
  # `fail_step/3`, `retry_step/1`, `halt_run/3`, any future Phase 57 path,
  # and any direct host `Run.changeset/2` call) is accounted for by
  # construction, closing the accumulator-leak defect where
  # `complete_step/3` previously read the run with no regard for its
  # current status and wrote `run_status` unconditionally.
  defp derive_rail_pause_accounting(changeset) do
    previous_status = changeset.data.status
    next_status = get_field(changeset, :status)

    cond do
      previous_status == next_status ->
        changeset

      next_status in @rail_pause_set and previous_status not in @rail_pause_set ->
        now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
        put_change(changeset, :rail_paused_at, now)

      previous_status in @rail_pause_set and next_status not in @rail_pause_set ->
        fold_rail_paused_interval(changeset)

      true ->
        changeset
    end
  end

  # Guard against a nil `rail_paused_at` (a row predating this feature, or
  # any other unexpected state) by folding nothing rather than raising.
  defp fold_rail_paused_interval(changeset) do
    run = changeset.data

    case run.rail_paused_at do
      nil ->
        changeset

      paused_at ->
        now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
        elapsed_ms = DateTime.diff(now, paused_at, :millisecond)

        changeset
        |> put_change(:rail_paused_ms, (run.rail_paused_ms || 0) + elapsed_ms)
        |> put_change(:rail_paused_at, nil)
    end
  end

  defp validate_replay_allowlist_immutability(changeset) do
    run = changeset.data
    next_overrides = get_field(changeset, :replay_overrides) || %{}
    previous_overrides = run.replay_overrides || %{}

    if replay_started?(run) and widening_allowlist?(previous_overrides, next_overrides) do
      add_error(changeset, :replay_overrides, "live_tool_allowlist cannot expand after replay start")
    else
      changeset
    end
  end

  defp replay_started?(%__MODULE__{execution_mode: "replay"} = run), do: not is_nil(run.started_at)
  defp replay_started?(_run), do: false

  defp widening_allowlist?(previous_overrides, next_overrides) do
    previous = MapSet.new(live_tool_allowlist(previous_overrides))
    next = MapSet.new(live_tool_allowlist(next_overrides))
    not MapSet.subset?(next, previous)
  end

  defp live_tool_allowlist(overrides) do
    overrides
    |> Map.get("live_tool_allowlist", Map.get(overrides, :live_tool_allowlist, []))
    |> List.wrap()
  end
end
