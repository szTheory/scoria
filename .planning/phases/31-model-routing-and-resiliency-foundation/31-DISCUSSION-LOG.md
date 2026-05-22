# Phase 31 Discussion Log

**Phase:** 31 - Model Routing & Resiliency Foundation
**Date:** 2026-05-20
**Mode:** recommendation-first discuss-all
**Status:** decisions locked for planning

## Discussion Setup

- Initiated `/gsd-discuss-phase 31`.
- User requested one-shot recommendations in YOLO mode for Phase 31.
- Subagent-backed research considered: Circuit breaker design in Elixir (GenServer vs. ETS), `Req` middleware steps for retries and circuit state, and embedded library constraints for Scoria.

## Inputs Consulted

- `.planning/milestones/v1.8-ROADMAP.md`
- `~/.gemini/gemini.md` (autonomous recommendation mandate - provide one-shot, idiomatic Elixir recommendations)
- Core architectural non-goal: No Ash framework, rely on standard Phoenix/Ecto/ETS patterns.

## Area Decisions

### 1. Circuit Breaker State Management

**Options considered:**
- Add a dependency on an Erlang library like `:fuse` or `:circuit_breaker`.
- Use a central `GenServer` to track error rates (could become a bottleneck under massive fan-out).
- Use a custom ETS-backed state machine with atomic counters (`:ets.update_counter`) and a periodic cleanup/half-open probe process.

**Locked recommendation:**
- **Custom ETS-backed implementation (`Scoria.Observe.CircuitBreaker`).**
- Use an ETS table (e.g., `:scoria_circuit_breakers`) created during application startup.
- Store state as `{model_id, status, failure_count, last_failure_at}`. 
- Use atomic `ets:update_counter` for fast incrementing.
- A small GenServer (`Scoria.Observe.CircuitBreaker.Manager`) manages the transition from `open` (tripped) -> `half_open` after a timeout, without blocking caller processes.

**Why this won:**
- Zero external dependencies.
- Perfect for high-concurrency "embedded library" constraints—callers check the ETS table directly without GenServer messaging overhead.
- Meets the success criteria: "Node-local ETS table tracks model health state (open/closed circuit)."

### 2. Req Request Interception & Retry Strategy

**Options considered:**
- Wrap `Req.request/1` in a custom `Scoria.LLM` module.
- Build custom `Req` steps (`Req.Step.register/3`) injected into the client struct.

**Locked recommendation:**
- **Inject custom `Req` steps.**
- Introduce `Scoria.Req.Steps.CircuitBreaker`: Intercepts the request *before* execution. If the ETS table shows the model circuit is `open`, it immediately halts the pipeline and returns a `{:error, :circuit_breaker_open}` or similar domain error, without waiting for HTTP timeouts.
- Introduce `Scoria.Req.Steps.Resiliency`: Wraps the actual execution to record successes and failures to the ETS table.
- Rely on `Req`'s built-in `retry: :transient` (or custom retry step) with exponential backoff for 429s and 5xx, but configure it so that exhaustion trips the circuit.

**Why this won:**
- `Req`'s architecture is specifically designed for middleware steps.
- Keeps domain logic cleanly separated from HTTP mechanics.
- Fulfills success criteria: "Repeated failures trip the circuit breaker, immediately returning errors without waiting for timeouts."

### 3. Thresholds & Heuristics

**Options considered:**
- Configurable thresholds per model.
- Global defaults.

**Locked recommendation:**
- **Global defaults with model-level overrides.**
- Default thresholds: 5 consecutive failures trips the circuit. Open timeout: 30 seconds before transitioning to `half-open`.
- Configurable via `Application.get_env(:scoria, :circuit_breaker_opts)`.

**Why this won:**
- Principle of least surprise: "Batteries included" defaults that can be tuned by power users.

## Shift-Left Defaults Locked

- ETS table `:scoria_circuit_breakers` is created in `Scoria.Application` supervisor tree.
- `Req` clients used throughout Scoria (like in `Scoria.Compaction.SummarizeWorker`) will be modified to attach these resilient steps.

## Result

The discussion produced a coherent, recommendation-first Phase 31 posture and was written into `31-CONTEXT.md` for downstream planning.
