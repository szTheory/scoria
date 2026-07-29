# Per-Run Rails

Per-run rails (RAIL-01) bound one Scoria run's step count, tool-call count, and active
execution time. They are a runaway-loop circuit breaker scoped to a single run, not a
tenant-level budget and not a replacement for `Scoria.SRE.BudgetEngine`.

Use this guide with [Default Runtime](guides/capabilities/default-runtime.md),
[Connectors and MCP](guides/capabilities/connectors-and-mcp.md),
[Ownership Boundary](guides/ownership-boundary.md), and the
[glossary](guides/reference/glossary.md).

## What this capability is for

Choose per-run rails when you need:

- a hard stop on a run that loops through steps or tool calls without making progress
- a bounded active-execution-time ceiling that does not fire during a long human approval wait
- honest evidence of exactly how much of your tool traffic is (and is not) covered

Rails are enforced automatically for every run — there is no opt-in flag to turn counting
on. What is optional is setting a *limit*. An unconfigured run still counts steps, tool
calls, and active time; it simply never denies, because an absent limit means unlimited.

## The two rungs

There are exactly two places a rail value can come from:

1. **The app default** — `config :scoria, Scoria.Runtime.Rails, max_steps: N, max_tool_calls: N, max_active_ms: N` in your host app's config.
2. **The per-run value** — the `:rails` keyword option passed to `Scoria.start_run/2` or `Scoria.start_handoff_run/3`, e.g. `Scoria.start_run(identity, rails: [max_steps: 50])`.

`Scoria.Runtime.Rails.resolve/1` resolves both rungs into the three `rail_max_*` columns
persisted on the run at creation time, independently per key, last-writer-wins:

**The per-run value is a default, not a ceiling — it may raise the app default, it does
not have to tighten it.** If the app default sets `max_steps: 10` and a specific run
passes `rails: [max_steps: 100]`, the effective limit is `100`, not `10`. This is
deliberate, not a bug: unlike request-derived inputs elsewhere in Scoria (where a
tighten-only join is the safe default because an untrusted caller could otherwise loosen
its own policy), both operands here — the app config and the per-run option — are your
own host source code. There is no untrusted party to defend against, so last-writer-wins
is correct and a `min/2` join would silently break the legitimate case where one
long-running batch job intentionally needs a higher `max_steps` than the app default.

The un-loosenable economic ceiling in Scoria is the tenant `Scoria.SRE.BudgetEngine`
policy. Rails do not touch it, and setting a generous per-run rail does not widen a
tenant's budget.

## The three keys

| Key | Unit | Meaning |
|-----|------|---------|
| `:max_steps` | count | Maximum workflow steps this run may execute. |
| `:max_tool_calls` | count | Maximum MCP tool calls this run may execute. |
| `:max_active_ms` | integer milliseconds | Maximum *active* execution time — a duration, never an absolute wall-clock deadline. |

`:timeout` is deliberately unavailable as a rail name. `:timeout` is already an active
`Scoria.Runtime.Params` dispatch key that changes the per-step handler bound; a
`timeout:` value meant as a run-level rail inside `:rails` would be silently swallowed
by that unrelated dispatch key instead of reaching `Scoria.Runtime.Rails`.

## Validation

`0`, negative integers, floats, binaries, and unknown keys inside `:rails` are all
refused as a tagged error tuple — `{:error, {:invalid_rail, key, value}}` or
`{:error, {:unknown_rail, key}}` — at `Scoria.start_run/2`/`start_handoff_run/3`, before
any run row exists. A malformed `config :scoria, Scoria.Runtime.Rails` app-env value
refuses the next run rather than crashing the host at boot: `Scoria.Runtime.Rails.validate_app_env/0`
never raises and is never called from `Scoria.Application.start/2`.

## The run_id forward obligation — read this before sizing anything

**Rails are enforced only where a `run_id` is present in the tool-call context.** This is
the single most important limitation in this guide.

Scoria populates `run_id` and `step_id` into `run.metadata["runtime"]` at step dispatch.
But the host handler must forward those values into whatever context it passes to
`Scoria.MCP.Executor.execute/4` — Scoria does not, and cannot, infer a `run_id` on your
behalf.

Inbound JSON-RPC MCP requests handled by `Scoria.MCP.Router` carry only `actor_id`,
`tenant_id`, and `session_id` (from `Scoria.Identity.to_map/1`) and therefore have **no
`max_tool_calls` coverage at all** today. This is not the only shape of the gap —
`MCPController` and any direct host call to `Scoria.MCP.Executor.execute/4` have the
identical shape, since the guard lives at the executor rather than at the router. Read
this as "wherever a `run_id` is absent from context", with `MCP.Router` as the concrete
shipped example, not the only one.

Every unattributed call still executes normally — this is a documented gap, not a crash
— and emits `[:scoria, :run, :rail, :skipped]` with `reason: :no_run_id` (or `:no_run`
when a `run_id` is present but matches no persisted run). Counting that event measures
exactly how much of your tool traffic is unrailed:

```elixir
:telemetry.attach(
  "count-unrailed-tool-calls",
  [:scoria, :run, :rail, :skipped],
  fn _event, _measurements, %{reason: reason, site: site}, _config ->
    MyApp.Metrics.increment("scoria.rail.skipped", tags: [reason: reason, site: site])
  end,
  nil
)
```

## The attempts-not-successes contract

The counter rails (`max_steps`, `max_tool_calls`) are enforced by a single atomic
compare-and-swap: `UPDATE ... WHERE counter < limit RETURNING counter`. Exactly `limit`
executions are admitted; there is no overshoot. Rails count *attempts*, not successes —
a call that crashes, times out, is blocked by the replay gate, or is served as a
historical stub has already consumed its budget.

**This no-overshoot guarantee depends on the host running Postgres READ COMMITTED.**
Under `REPEATABLE READ` or `SERIALIZABLE`, the blocked statement aborts with `40001`
instead of re-checking cleanly.

`max_active_ms` is different in kind: it is a ceiling on *admission*, not a wall-clock
kill. Work already in flight when the budget is exhausted is allowed to finish — the run
is denied at its *next* admission point, not interrupted mid-call. `max_active_ms`
measures active time with paused intervals subtracted (`rail_paused_ms`), so a run parked
in `waiting_for_approval` for an arbitrarily long human approval wait never accrues
active time and can never be halted by the timeout rail while it waits. Retrying counts
as active time — a retry loop cannot outrun the rail by pausing.

## Accepted limitation

Rails are enforced at admission. Three cases are not caught by this design:

- a run wedged inside one long tool call (bounded only by the per-call timeout, not by a
  rail);
- a run whose steps are all orphaned in `"running"` after a node death — this is crash
  recovery, not a rail gap, and is the real residual gap in this design;
- a run in `waiting_for_approval` — this is by design, not a gap, since the timeout rail
  measures active time and a paused run accrues none.

## Sizing rails from real traffic

Do not guess a limit before you have traffic. Counting is always on, even for an
unconfigured run, so you can query real history before setting anything:

```sql
SELECT
  max(rail_steps)      AS max_steps_observed,
  max(rail_tool_calls) AS max_tool_calls_observed,
  max(rail_paused_ms)  AS max_paused_ms_observed
FROM ai_workflow_runs
WHERE inserted_at >= now() - interval '30 days'
  AND status IN ('completed', 'failed', 'halted');
```

**The locked sizing recipe: set the rail at observed max over 30 days, times 2, rounded
up.** This is explicitly **NOT p99**. A rail's job is to stop a runaway loop, not to trim
the tail of your latency distribution — p99 sizing produces false halts on legitimate
long-running work. After setting a rail, confirm `[:scoria, :run, :rail, :tripped]` stays
at zero for a week before relying on it in production.

**Warning:** `max(rail_tool_calls)` will read `0` until you wire the `run_id` forward
described above — and `0` is itself an illegal rail value. Do not configure whatever the
query returns while every call is still unattributed; fix the forward first, then
re-query.

## Telemetry

Attach to `[:scoria, :run, :rail, :observed]`, which fires exactly once per run at its
terminal transition (`completed`, `failed`, or `halted`):

```elixir
:telemetry.attach(
  "size-rails-from-observed-traffic",
  [:scoria, :run, :rail, :observed],
  fn _event, measurements, metadata, _config ->
    MyApp.Metrics.histogram("scoria.rail.steps", measurements.steps,
      tags: [terminal_status: metadata.terminal_status, tripped: metadata.tripped]
    )
    MyApp.Metrics.histogram("scoria.rail.active_ms", measurements.active_ms,
      tags: [terminal_status: metadata.terminal_status]
    )
  end,
  nil
)
```

`measurements` separates `steps`, `tool_calls`, `active_ms`, `paused_ms`, and `wall_ms` as
five distinct numbers — never conflate `wall_ms` with the rail's own `active_ms` when
reasoning about a `max_active_ms` trip.

**Cardinality warning:** `run_id`, `step_id`, `trace_id`, and `audit_outbox_event_id` are
correlation keys for log and trace joins. Never attach them as metric tags — that turns
every distinct run into its own metric series. The safe-to-tag dimensions are `rail`,
`reason_code`, `unit`, `terminal_status`, `tripped`, `reason`, and `site`.

## The Phase 57 re-sizing warning

**Re-size every rail after enabling the Phase 57 confluence-escalation gate.** That gate
converts undeclared tool calls into approval round trips, and each round trip costs **2**
against `max_steps` (one step to reach the approval pause, one more to resume after the
decision). A `max_steps` value sized on pre-Phase-57 traffic will start halting
legitimate runs the day strict mode is enabled. Re-run the sizing query above after
enabling the gate, not before.

## What this capability does not do

There is no `mix scoria.rails.observe` task and no dashboard screen for rails in this
release — sizing is a SQL query and a `:telemetry.attach/4` call today. A dashboard rail
screen is future Govern-surface work, not part of this capability.
