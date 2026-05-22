# Architecture Patterns

**Domain:** Multi-model orchestration and distributed evaluations
**Researched:** 2024-05-24

## Recommended Architecture

The architecture relies heavily on Elixir's OTP primitives for state (ETS, GenServer) and Oban for distributed execution, ensuring we stay firmly within the Phoenix/Ecto ecosystem.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Scoria.Orchestrator.Router` | Determines which model to invoke based on policy, health, and fallback rules. | `CircuitBreaker`, `Connectors` |
| `Scoria.Orchestrator.CircuitBreaker` | Tracks rolling failure rates and latencies of models. | `ETS` (state), `:telemetry` (listeners) |
| `Scoria.Eval.Coordinator` | Schedules distributed eval campaigns. | `Ecto` (saves campaign), `Oban` (enqueues jobs) |
| `Scoria.Eval.Worker` | Oban worker that executes a single evaluation prompt. | `Orchestrator.Router`, `Ecto` (saves result) |

### Data Flow (Fallback Orchestration)

1. Caller requests an LLM generation via `Scoria.Orchestrator.Router`.
2. `Router` checks `CircuitBreaker` (ETS) for the primary model's health.
3. If primary is unhealthy (open circuit), `Router` falls back to secondary model.
4. Request is dispatched via `Req` (inside `Connectors`).
5. On success/failure, a `:telemetry` event is emitted.
6. A `telemetry` handler updates the `CircuitBreaker` state.

## Patterns to Follow

### Pattern 1: Oban Queue Segregation
**What:** Define separate queues for `inference`, `evals`, and `system`.
**When:** Always, to prevent massive evaluation campaigns from starving production inference requests.
**Example:**
```elixir
config :scoria, Oban,
  queues: [inference: 10, evals: 50, system: 5]
```

### Pattern 2: ETS Circuit Breaker State
**What:** Use ETS with `read_concurrency: true` for the circuit breaker to avoid GenServer bottlenecks on every LLM call.
**When:** Routing high volumes of LLM requests across a cluster.
**Example:**
```elixir
:ets.new(:model_health, [:set, :public, :named_table, read_concurrency: true])
# Store state like: {:openai_gpt4, :closed, fail_count, last_failure_timestamp}
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Hidden Retries
**What:** Deeply nested connector libraries retrying requests infinitely without emitting logs or telemetry.
**Why bad:** Causes request timeouts in Phoenix and exhausts connection pools, while appearing "stuck" to the operator.
**Instead:** Use `Req` retry steps explicitly mapped to specific status codes (e.g., 429), strictly bounded (max 3 retries), and emit a telemetry event on every retry.

### Anti-Pattern 2: Global Evaluation Fan-out
**What:** Loading 10,000 evaluations into memory and mapping over them with `Task.async_stream`.
**Why bad:** Will crash the node if memory spikes, and will be lost on deployment/restart.
**Instead:** Insert 10,000 Oban jobs (using `Oban.insert_all`) and let workers drain the queue.

## Scalability Considerations

| Concern | At 100 evals | At 10K evals | At 1M evals |
|---------|--------------|--------------|-------------|
| Eval execution | `Task.async_stream` | Oban standard queues | Oban batched workers & Pro features |
| State Tracking | DB reads | ETS node-local | CRDTs or Redis (though ETS usually suffices per-node) |

## Sources
- Oban Documentation (Queue segregation, insert_all).
- Elixir standard library (`:ets` concurrency flags).