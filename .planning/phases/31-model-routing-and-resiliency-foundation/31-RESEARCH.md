<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### the agent's Discretion
None explicitly listed in CONTEXT.md, but the exact mechanism of appending Req steps and ETS atomic updates are open to implementation details.

### Deferred Ideas (OUT OF SCOPE)
- **Multi-Model Fallback:** Falling back to secondary models automatically is explicitly deferred to Phase 32. Phase 31 only implements the tracking and early-failing mechanism for a single requested model.
- **Operator UI Elements:** Wiring these circuit breakers into LiveView dashboards is out of scope for this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ORCH-02 | Circuit Breakers (Track rolling failure rates and latencies of models using ETS, trip when unhealthy). | ETS `:update_counter` provides lock-free concurrency for tracking failures. |
| ORCH-03 | Configurable Retry Policies (Handle HTTP 429s gracefully with jittered exponential backoff using `Req` steps). | `Req` built-in `retry: :transient` seamlessly handles backoff; custom steps can halt requests on open circuits. |
</phase_requirements>

# Phase 31: Model Routing and Resiliency Foundation - Research

**Researched:** 2026-05-20
**Domain:** Elixir OTP (ETS/GenServer) & HTTP Client (Req) Resilience
**Confidence:** HIGH

## Summary
This phase implements a zero-dependency, ETS-backed circuit breaker for model HTTP requests. It pairs perfectly with Elixir's concurrent environment by using lock-free ETS reads and atomic counters for state updates, avoiding GenServer bottlenecks under high fan-out. A companion GenServer manages periodic transitions from `:open` to `:half_open`.

To integrate with Scoria's HTTP calls, we leverage `Req`'s extensible step architecture. A `CircuitBreaker` request step halts execution if the circuit is open, while a `Resiliency` response/error step observes final outcomes to update the ETS counters. Combined with `Req`'s built-in `:transient` retries, this creates a robust, highly concurrent failure management foundation.

**Primary recommendation:** Use `:ets.update_counter/4` for atomic failure increments and `Req.Request.halt/2` to instantly short-circuit requests on open breakers.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Circuit Breaker State | API / Backend | — | Node-local ETS table (`:scoria_circuit_breakers`) ensures sub-millisecond, lock-free access for all model routing decisions. |
| Timeout Management | API / Backend | — | `GenServer` manager periodically sweeps ETS to safely transition `:open` to `:half_open` circuits without blocking callers. |
| HTTP Interception | API / Backend | — | `Req` middleware steps wrap outbound calls to enforce circuit state and track outcomes. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir (ETS) | Built-in | Fast, in-memory KV store | Unbeatable read concurrency; `ets:update_counter` allows atomic increments without GenServer serialization. |
| Req | ~> 0.5.17 | HTTP Client | First-class middleware (steps) architecture allows elegant interception of requests, responses, and errors. |

## Architecture Patterns

### System Architecture Diagram
```
[Application Supervisor]
       │
       ├──> [ETS Table: :scoria_circuit_breakers] (Created on boot)
       │
       └──> [CircuitBreaker.Manager (GenServer)]
                 │ sweeps every N ms
                 ▼
          (Transitions :open -> :half_open)

[Caller (e.g., Oban Worker)]
       │
       ▼
[Req Pipeline]
  │
  ├──> 1. Scoria.Req.Steps.CircuitBreaker (Request Step)
  │         ├── Reads ETS. If :open -> Req.Request.halt(req, error)
  │         └── If :closed/:half_open -> Continue
  │
  ├──> 2. Req.Steps.retry (Built-in)
  │         └── Handles transient errors (429, 5xx) with backoff
  │
  ├──> 3. HTTP Execution
  │
  └──> 4. Scoria.Req.Steps.Resiliency (Response/Error Step)
            ├── On 2xx: ETS reset failure count -> 0, status -> :closed
            └── On 429/5xx/Error: ETS increment failure count
                      └── If count >= threshold -> status -> :open
```

### Recommended Project Structure
```
lib/scoria/
├── observe/
│   ├── circuit_breaker.ex        # ETS interface (lookup, record_success, record_failure)
│   └── circuit_breaker/
│       └── manager.ex            # GenServer for timeout sweeps
└── req/
    └── steps/
        ├── circuit_breaker.ex    # Halts pipeline if circuit is open
        └── resiliency.ex         # Updates ETS based on request outcome
```

### Pattern 1: Atomic ETS Updates
**What:** Using `:ets.update_counter/4` to increment failures and flip to `:open` in a single atomic operation without race conditions.
**When to use:** When tracking high-volume metric states.
**Example:**
```elixir
# Update counter, setting default if missing.
# If the new count equals the threshold, we can pattern match the result to flip the status.
new_count = :ets.update_counter(
  :scoria_circuit_breakers,
  model_id,
  {3, 1}, # Increment 3rd element (failure_count) by 1
  {model_id, :closed, 0, nil} # Default record
)

if new_count >= threshold do
  # Flip to open
  :ets.update_element(:scoria_circuit_breakers, model_id, [{2, :open}, {4, System.os_time(:second)}])
end
```

### Pattern 2: Halting a Req Pipeline
**What:** Stopping a Req pipeline dead in its tracks if a precondition fails.
**When to use:** In the `Scoria.Req.Steps.CircuitBreaker` step.
**Example:**
```elixir
def check_circuit(request) do
  if Scoria.Observe.CircuitBreaker.open?(request.options[:model_id]) do
    Req.Request.halt(request, %RuntimeError{message: "Circuit breaker is open"})
  else
    request
  end
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exponential Backoff | Custom retry loops | `Req` `retry: :transient` | Req natively handles the headers (e.g., `Retry-After`), jitter, and standard 429/5xx status codes out of the box. |
| GenServer bottleneck | GenServer state for metrics | ETS + Atomic Counters | GenServers serialize requests. High fan-out evaluations would bottleneck on a single circuit breaker process. ETS avoids this. |

## Common Pitfalls

### Pitfall 1: Race conditions when reading and updating ETS
**What goes wrong:** Process A reads failure count `4`, Process B reads `4`. Both increment and write `5`. The threshold `5` logic might trigger twice or fail to trigger properly if written naively.
**Why it happens:** Separating the read from the write operation in ETS.
**How to avoid:** Use `:ets.update_counter/4` to atomically increment and return the new value. Only update the status to `:open` if the threshold is crossed.

### Pitfall 2: Req Step Ordering
**What goes wrong:** The resiliency step runs *before* the retry step, meaning every single retry attempt counts as a failure, tripping the circuit breaker prematurely.
**Why it happens:** Carelessly registering steps without considering the built-in retry step's location in the pipeline.
**How to avoid:** Append the response/error steps (`append_response_steps` / `append_error_steps`) so they evaluate the *final* outcome after retries are exhausted. Alternatively, design the failure threshold to match the retry count.

## Code Examples

### Attaching Req Steps
```elixir
def attach(req, opts \\ []) do
  req
  |> Req.Request.register_options([:model_id])
  |> Req.Request.merge_options(opts)
  |> Req.Request.append_request_steps(
    scoria_circuit_breaker: &Scoria.Req.Steps.CircuitBreaker.run/1
  )
  |> Req.Request.append_response_steps(
    scoria_resiliency_response: &Scoria.Req.Steps.Resiliency.handle_response/1
  )
  |> Req.Request.append_error_steps(
    scoria_resiliency_error: &Scoria.Req.Steps.Resiliency.handle_error/1
  )
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| GenServer for all state | ETS for concurrent reads/writes | Constant | Avoids mailbox congestion under heavy load (e.g. Oban batch eval runs). |
| Custom HTTP wrapper | Req Steps | Req ~> 0.3+ | Keeps business logic (circuit breaking) neatly composed as middleware rather than messy macro wrappers. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Req retry step handles `429` statuses effectively out of the box with `:transient` | Don't Hand-Roll | Retries might need custom rules if provider-specific 429s are non-standard. |

## Open Questions (RESOLVED)

1. **Req step ordering with built-in retries**
   - What we know: `Req` has built-in retry logic that runs as response/error steps.
   - What's unclear: If we `append_response_steps`, does it run *after* the `retry` step has fully exhausted its attempts, or on every attempt?
   - Recommendation: RESOLVED: The plan should include a test specifically ensuring that 3 retries result in only 1 recorded failure (or exactly the threshold behavior desired) to verify the pipeline execution order.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir ETS | Circuit Breaker State | ✓ | Built-in | — |
| Req | HTTP Interception | ✓ | ~> 0.5.17 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | none — see Wave 0 |
| Quick run command | `mix test test/scoria/observe/circuit_breaker_test.exs test/scoria/req/steps_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ORCH-02 | ETS tracks failures & trips open | unit | `mix test test/scoria/observe/circuit_breaker_test.exs` | ❌ Wave 0 |
| ORCH-02 | GenServer transitions open to half-open | unit | `mix test test/scoria/observe/circuit_breaker_manager_test.exs` | ❌ Wave 0 |
| ORCH-03 | Req step halts on open circuit | unit | `mix test test/scoria/req/steps/circuit_breaker_test.exs` | ❌ Wave 0 |
| ORCH-03 | Req step records failures on 429/500 | unit | `mix test test/scoria/req/steps/resiliency_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test <specific_test_file>`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scoria/observe/circuit_breaker_test.exs` — covers ORCH-02
- [ ] `test/scoria/observe/circuit_breaker_manager_test.exs` — covers ORCH-02 timeout logic
- [ ] `test/scoria/req/steps/circuit_breaker_test.exs` — covers ORCH-03
- [ ] `test/scoria/req/steps/resiliency_test.exs` — covers ORCH-03

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Standard pattern matching and guard clauses on ETS ops |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/ETS

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom exhaustion | Denial of Service | Do not use dynamic/user-provided strings as atoms for model IDs. Use strings for ETS keys or map safely to known atoms. |
| ETS Table Memory Leak | Denial of Service | Ensure periodic cleanup of stale models or set a sensible upper bound on number of tracked models if dynamically added. |

## Sources

### Primary (HIGH confidence)
- Context7 / Req documentation - Confirmed `Req.Request.halt/2` usage.
- Context7 / Req documentation - Confirmed `append_request_steps`, `append_response_steps`, `append_error_steps` API.
- Project `mix.exs` - Confirmed Req version `~> 0.5.17`.

### Secondary (MEDIUM confidence)
- N/A

### Tertiary (LOW confidence)
- N/A

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Built-in OTP and explicit library versions verified.
- Architecture: HIGH - Matches standard Elixir high-concurrency patterns.
- Pitfalls: HIGH - Documented common OTP race conditions and Req step ordering nuances.

**Research date:** 2026-05-20
**Valid until:** 2026-11-20