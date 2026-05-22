# Phase 31: Model Routing and Resiliency Foundation - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 6
**Analogs found:** 4 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/observe/circuit_breaker/manager.ex` | service | event-driven | `lib/scoria/observe/buffer.ex` | exact |
| `lib/scoria/observe/circuit_breaker.ex` | service | state-access | `lib/scoria/sre/breaker_registry.ex` | role-match |
| `lib/scoria/req/steps/circuit_breaker.ex` | middleware | request-response | None | n/a |
| `lib/scoria/req/steps/resiliency.ex` | middleware | request-response | None | n/a |
| `lib/scoria/application.ex` | config | setup | `lib/scoria/application.ex` | exact |
| `lib/scoria/compaction/summarize_worker.ex` | worker | batch | `lib/scoria/compaction/summarize_worker.ex` | exact |

## Pattern Assignments

### `lib/scoria/observe/circuit_breaker/manager.ex` (service, event-driven)

**Analog:** `lib/scoria/observe/buffer.ex`

**Imports and Init pattern** (lines 1-10, 16-29):
```elixir
defmodule Scoria.Observe.CircuitBreaker.Manager do
  use GenServer
  require Logger

  @default_sweep_interval 5000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(opts) do
    # Can also initialize ETS table here via Scoria.Observe.CircuitBreaker.init_table()
    state = %{
      sweep_interval: Keyword.get(opts, :sweep_interval, @default_sweep_interval),
      timer: nil
    }

    state = schedule_sweep(state)
    {:ok, state}
  end
```

**Scheduled Task pattern** (lines 37-43, 49-53):
```elixir
  @impl true
  def handle_info(:sweep, state) do
    # Perform ETS half-open sweep here
    state = schedule_sweep(state)
    {:noreply, state}
  end

  defp schedule_sweep(state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    timer = Process.send_after(self(), :sweep, state.sweep_interval)
    %{state | timer: timer}
  end
```

---

### `lib/scoria/observe/circuit_breaker.ex` (service, state-access)

**Analog:** `lib/scoria/sre/breaker_registry.ex`

**ETS table initialization pattern** (lines 10-10, 209-215):
```elixir
  @open_table :scoria_circuit_breakers

  def init_table do
    case :ets.whereis(@open_table) do
      :undefined -> :ets.new(@open_table, [:named_table, :public, :set, read_concurrency: true])
      _table -> @open_table
    end

    :ok
  end
```

**ETS state check pattern** (lines 189-204):
```elixir
  defp check_circuit(model_id) do
    init_table()
    now = System.system_time(:millisecond)

    case :ets.lookup(@open_table, model_id) do
      [{_model_id, :open, until_ms}] ->
        if until_ms > now do
          {:error, :circuit_breaker_open}
        else
          # Transition to half-open
          :ets.insert(@open_table, {model_id, :half_open, 0})
          :ok
        end
      _ ->
        :ok
    end
  end
```

**ETS state mutation pattern** (lines 182-184):
```elixir
  def record_failure(model_id, open_timeout_ms) do
    # Using :ets.update_counter or :ets.insert
    :ets.insert(@open_table, {model_id, :open, System.system_time(:millisecond) + open_timeout_ms})
  end
```

---

### `lib/scoria/application.ex` (config, setup)

**Analog:** `lib/scoria/application.ex`

**Supervision tree addition pattern** (lines 10-23):
```elixir
  @impl true
  def start(_type, _args) do
    children =
      [
        Scoria.Repo,
        # ... existing children ...
        {Task.Supervisor, name: Scoria.Workflow.TaskSupervisor},
        Scoria.SRE.Relay,
        # New manager added here
        Scoria.Observe.CircuitBreaker.Manager
      ] ++ maybe_reconciler()
```

---

### `lib/scoria/compaction/summarize_worker.ex` (worker, batch)

**Analog:** `lib/scoria/compaction/summarize_worker.ex`

**Injecting configuration pattern** (lines 90-102):
```elixir
  defp generate_summary!(prompt) do
    req_llm_module = Application.get_env(:scoria, :req_llm_module, ReqLLM)
    
    # Needs update to inject custom Req options that append our steps:
    # req_opts = [
    #   req_options: [
    #     {Req.Request, :append_request_steps, [circuit_breaker: &Scoria.Req.Steps.CircuitBreaker.run/1]}
    #     # ... resiliency step as well
    #   ]
    # ]

    with {:ok, response} <-
           req_llm_module.generate_text(summary_model(), prompt,
             # Pass options along with system_prompt
           ) do
      # ...
```

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md / Req library patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/scoria/req/steps/circuit_breaker.ex` | middleware | request-response | First custom Req step introduced in project |
| `lib/scoria/req/steps/resiliency.ex` | middleware | request-response | First custom Req step introduced in project |

*Note on Req Steps: Expected pattern is a standard Req pipeline step: `def run(%Req.Request{} = request) -> Req.Request.t() | {Req.Request.t(), Req.Response.t() | struct()}`.*

## Metadata

**Analog search scope:** `lib/scoria/**/*.ex`
**Files scanned:** 111
**Pattern extraction date:** 2024-05-18
