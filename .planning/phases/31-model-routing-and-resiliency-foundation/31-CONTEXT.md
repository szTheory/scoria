# Phase 31 Context: Model Routing & Resiliency Foundation

This document captures the architectural decisions and constraints locked during the Phase 31 discuss phase. It serves as the primary input for `/gsd-plan-phase 31`.

## Core Objective

Provide a robust foundation for model HTTP requests that correctly identifies and handles model failures via ETS-backed circuit breakers and bounded retries. This ensures massive evaluation campaigns or sudden API rate limits (429s) don't hang the system or burn through resources unnecessarily.

## Architectural Decisions

1. **Custom ETS-Backed Circuit Breakers (`Scoria.Observe.CircuitBreaker`)**
   - **No external dependencies:** We will not use `:fuse` or other circuit breaker libraries.
   - **State:** Tracked in an ETS table (e.g., `:scoria_circuit_breakers`) created at application startup.
   - **Data Model:** `{model_id, status, failure_count, last_failure_at}` where status is `:closed`, `:open`, or `:half_open`.
   - **Concurrency:** Callers read/write directly to ETS using `:ets.lookup` and `:ets.update_counter` to avoid GenServer bottlenecks.
   - **Management:** A lightweight GenServer (`Scoria.Observe.CircuitBreaker.Manager`) periodically sweeps the ETS table to transition `:open` circuits to `:half_open` after the timeout expires.

2. **Req Middleware Integration (`Scoria.Req.Steps`)**
   - **Interception:** Build a custom `Req` step (`Scoria.Req.Steps.CircuitBreaker`) that halts the request pipeline if the target model's circuit is `:open`. This immediately returns an error (e.g. `{:error, :circuit_breaker_open}`) without initiating HTTP traffic.
   - **Resiliency Tracking:** Build another `Req` step (`Scoria.Req.Steps.Resiliency`) that observes the request outcome. It updates the ETS circuit breaker table—resetting failure counts on success, or incrementing them on HTTP 5xx, 429s, or timeouts.
   - **Retries:** Leverage `Req`'s built-in `retry: :transient` combined with our custom steps to handle exponential backoff for 429s. If the retries are exhausted, it counts as a failure against the circuit breaker.

3. **Global Defaults & Tuning**
   - Provide "batteries included" global thresholds (e.g., trip after 5 consecutive failures, 30-second `:open` timeout).
   - Allow configuration overrides via `config :scoria, :circuit_breaker_opts`.

## Excluded from Scope

- **Multi-Model Fallback:** Falling back to secondary models automatically is explicitly deferred to Phase 32. Phase 31 only implements the tracking and early-failing mechanism for a single requested model.
- **Operator UI Elements:** Wiring these circuit breakers into LiveView dashboards is out of scope for this phase.

## Downstream Impact

- The `ReqLLM` calls used in `Scoria.Compaction.SummarizeWorker` (and future eval coordinators) will be wrapped or configured to attach these new `Req` steps.
- The `Scoria.Application` supervisor will be updated to start the new ETS table and Manager GenServer.
