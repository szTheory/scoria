# Phase 1: Core Observability & Telemetry - Research

**Researched:** 2026-05-09
**Domain:** AI Ops, Observability, Telemetry, Ecto
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked Decisions
- **Ash Framework Non-Goal:** Do not attempt to integrate with or use the Ash framework. We are strictly all-in on standard Phoenix and Ecto architectures (from GEMINI.md).
- **Async Batching Engine:** Use a native OTP Buffer (`Scoria.Telemetry.Buffer`) with GenServer + `Repo.insert_all` instead of Oban or Broadway (from phase_1_decisions.md).
- **Redaction Strategy:** Hybrid Configurable Deny-list + MFA Escape Hatch for deep PII scrubbing (from phase_1_decisions.md).
- **OpenInference Schema:** Hybrid Ecto schema with Core Metadata Columns (indexed) + JSONB `:map` field for arbitrary attributes (from phase_1_decisions.md).

### the agent's Discretion
- Adapter integration patterns for `ReqLLM` or `Jido`.

### Deferred Ideas (OUT OF SCOPE)
- N/A
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OBS-01 | Implement Ecto-native state schemas (`ai_traces`, `ai_spans`, `ai_span_events`) based on OpenInference specifications. | Hybrid schema: core relational columns + JSONB (`:map`) `attributes`. |
| OBS-02 | Implement Telemetry handlers to capture Erlang `:telemetry` events and translate them into spans. | Standard `:telemetry.attach/4` translating into OpenInference span maps. |
| OBS-03 | Create asynchronous processing for batch-inserting spans into Ecto without blocking the main process. | Native OTP Buffer (GenServer) + `Task` using `Repo.insert_all`. Avoid Oban. |
| OBS-04 | Implement strict telemetry redaction boundaries to scrub PII, secrets, and API keys before insertion. | Configurable deny-list applied recursively, with MFA override. |
| OBS-05 | Provide adapters for `ReqLLM` or `Jido` events with the internal trace storage. | Default `:telemetry` event interception for known `ReqLLM` namespaces. |
</phase_requirements>

## Summary

This phase establishes the foundational AI observability layer for Scoria. The goal is to capture AI execution data (LLM requests, agent steps, tool calls), format it according to the OpenInference standard, and durably persist it in an Ecto database. The architecture prioritizes minimal performance impact on the application's critical path by using native OTP buffering and batch insertion, specifically avoiding heavy dependencies like Oban or Broadway for telemetry ingestion. Redaction of PII and secrets is enforced at the ingestion boundary before persistence.

**Primary recommendation:** Build a native OTP-based telemetry buffer that captures `:telemetry` events, applies a default deny-list redaction, formats as OpenInference spans, and flushes to a hybrid Ecto schema (Core columns + JSONB) using `Repo.insert_all`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Telemetry Ingestion | Backend OTP | — | Erlang `:telemetry` handlers run synchronously in the calling process; must offload data immediately to avoid blocking. |
| Batching & Flushing | Backend OTP (Buffer) | — | A GenServer/Task combo gathers span data and periodically flushes it to Ecto to optimize DB write performance. |
| Trace Persistence | Database (Ecto) | — | Postgres handles indexing core metadata for LiveView queries while storing arbitrary OI fields in JSONB. |
| Data Redaction | Backend OTP | — | Redaction must occur securely in memory before any data is sent over the wire to the database. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | ~> 1.0 | Event capture | Erlang standard for instrumentation. |
| `Ecto` | ~> 3.10 | Database mapping | Idiomatic Phoenix persistence, strong JSONB support. |
| `OTP (GenServer/Task)` | N/A | Concurrency buffer | Zero dependencies, predictable latency, massive throughput. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `ReqLLM` / `Jido` | Current | Telemetry sources | The primary sources of AI events that Scoria will listen to and adapt. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| OTP Buffer | Oban | Oban provides guarantees but overwhelming Postgres with transaction overhead for time-series telemetry is an anti-pattern. |
| OTP Buffer | Broadway | Broadway handles massive throughput but introduces an overly complex, heavy dependency for a "SaaS in a Box" library. |

## Architecture Patterns

### System Architecture Diagram
```
Client Request -> [Phoenix Controller/LiveView] -> App Logic (ReqLLM/Jido)
                                                           |
                                                   (emits :telemetry)
                                                           |
                                                    [Scoria.Observe]
                                                    (Telemetry Handler)
                                                           |
                                                (async cast / ETS write)
                                                           |
                                              [Scoria.Telemetry.Buffer] (GenServer)
                                                (applies default redaction)
                                                           |
                                                 (periodic flush Task)
                                                           |
                                                    [Repo.insert_all]
                                                           |
                                                  [PostgreSQL / Ecto]
                                                  (scoria_traces, scoria_spans)
```

### Recommended Project Structure
```
lib/scoria/
├── observe/             # Public API for observability
│   ├── telemetry.ex     # Telemetry attachment and handlers
│   ├── buffer.ex        # GenServer for batching spans
│   └── redactor.ex      # PII/Secret scrubbing logic
└── repo/
    ├── trace.ex         # Ecto schema for ai_traces
    ├── span.ex          # Ecto schema for ai_spans
    └── span_event.ex    # Ecto schema for ai_span_events
```

### Pattern 1: Native OTP Buffer for Telemetry
**What:** Use a GenServer to accumulate span data in memory and periodically flush to the database.
**When to use:** High-volume time-series telemetry where synchronous DB inserts would impact application latency.
**Example:**
```elixir
defmodule Scoria.Telemetry.Buffer do
  use GenServer
  
  # ... initialization and flush timer ...
  
  def handle_cast({:span, span_data}, state) do
    new_state = [span_data | state.spans]
    if length(new_state) >= @batch_size do
      flush(new_state)
      {:noreply, %{state | spans: []}}
    else
      {:noreply, %{state | spans: new_state}}
    end
  end
end
```

### Anti-Patterns to Avoid
- **Synchronous Telemetry Inserts:** Never call `Repo.insert/2` directly inside a `:telemetry` handler, as it blocks the process executing the AI call.
- **Strict Migrations for OpenInference:** Do not create columns for every OpenInference property (e.g., `llm.token_count`). Specs evolve too fast. Use a JSONB `:map` column.
- **Oban for Telemetry Storage:** Writing every telemetry event as a persistent background job overwhelms the DB.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Custom trace shapes | A proprietary JSON format | OpenInference specs | Standardized schema mapped on OTel; allows future export compatibility and standard UI filtering. |
| Complex Job Queues | Broadway/Oban for telemetry | Native OTP Buffer | A local library shouldn't mandate heavy external queue infrastructure for simple telemetry batching. |

## Common Pitfalls

### Pitfall 1: Telemetry Redaction Failures
**What goes wrong:** Sensitive user prompts or API keys are written to the database.
**Why it happens:** Attempting to manually allow-list safe keys fails because JSON payloads are highly dynamic.
**How to avoid:** Use an aggressive default deny-list (`password`, `api_key`, `token`, etc.) applied recursively to all map/JSON values before buffering, and provide an MFA escape hatch for deep regex scrubbing.
**Warning signs:** PII appearing in the `attributes` column during manual inspection.

### Pitfall 2: Application Shutdown Data Loss
**What goes wrong:** The node shuts down or restarts, and the in-memory buffer loses the last N seconds of spans.
**Why it happens:** The GenServer is forcefully terminated before its periodic flush triggers.
**How to avoid:** Implement graceful shutdown handling (e.g., `terminate/2` callback or hooking into `System.at_exit`) to execute a synchronous `Repo.insert_all` before the VM exits.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OBS-01 | Trace/Span schema validation | unit | `mix test test/scoria/repo/span_test.exs` | ❌ Wave 0 |
| OBS-02 | Telemetry capture translation | unit | `mix test test/scoria/observe/telemetry_test.exs` | ❌ Wave 0 |
| OBS-03 | Async batch buffering and flush | unit/integration | `mix test test/scoria/observe/buffer_test.exs` | ❌ Wave 0 |
| OBS-04 | Deny-list redaction | unit | `mix test test/scoria/observe/redactor_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Aggressive Deny-list Redaction + MFA |

### Known Threat Patterns for Elixir Telemetry

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII / Secret Leakage | Information Disclosure | Recursive redaction of JSON keys (`api_key`, `secret`, `password`) before persistence. |
| DB Resource Exhaustion | Denial of Service | Batching telemetry with a max buffer size and dropping events if the buffer is overwhelmed (backpressure). |

## Sources

### Primary (HIGH confidence)
- `.planning/research/phase_1_decisions.md` - Verified architecture decisions for Scoria Phase 1.
- `.planning/research/evals-and-observability.md` - Verified OpenInference mapping and Ecto schema design.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows the project's pre-approved phase 1 decisions and Elixir idioms.
- Architecture: HIGH - GenServer buffering and Ecto JSONB are proven OTP/Phoenix patterns.
- Pitfalls: HIGH - Redaction and shutdown hooks are standard industry concerns for telemetry.

**Research date:** 2026-05-09
**Valid until:** 2027-05-09