# Phase 32: Multi-Model Fallback Orchestration - Research

**Researched:** 2026-05-20
**Domain:** Model Orchestration & Resiliency
**Confidence:** HIGH

## Summary

This phase implements `Scoria.Orchestrator`, a domain-level wrapper around `ReqLLM` that provides recursive fallback attempts. By isolating the fallback logic into the domain layer (rather than hiding it in HTTP middleware), the application explicitly captures the attempt chain in telemetry and guarantees clean circuit breaker integration.

`Scoria.Compaction.SummarizeWorker` and `Scoria.Eval.JudgeRunner` currently instantiate `ReqLLM` directly. They will be updated to point to `Scoria.Orchestrator`, which will inject the requisite `Scoria.Req.Steps.req_options/1` dynamically per model attempt, ensuring the circuit breaker logic tracks the correct target model on each retry.

**Primary recommendation:** Implement a recursive retry loop in `Scoria.Orchestrator` that fetches static fallback chains from `Application.get_env(:scoria, :fallback_chains, %{})`, isolates `req_options` per attempt to avoid step accumulation, and emits clear `[:scoria, :orchestrator, :request, :stop]` and `[:scoria, :orchestrator, :fallback]` telemetry.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. **Fallback Orchestrator Layer (`Scoria.Orchestrator`)**
   - **Domain Wrapper:** We will create a new domain module, `Scoria.Orchestrator`, which wraps calls to the underlying `ReqLLM` client.
   - **Reasoning:** Fallback logic (trying a model, catching a circuit breaker or HTTP error, checking capabilities, and retrying another model) belongs in the domain layer, not inside a `Req` middleware step. Pushing this into `Req` would entangle the HTTP client with domain concerns and obscure telemetry.
   - **Callers:** Existing callers that currently invoke `ReqLLM.generate_text` directly (such as `Scoria.Compaction.SummarizeWorker` and `Scoria.Eval.JudgeRunner`) will be updated to call `Scoria.Orchestrator.generate_text` instead.

2. **Static Fallback Chains Configuration**
   - **Representation:** Fallback chains will be represented statically via application configuration (e.g., `config :scoria, :fallback_chains, %{"gpt-4-turbo" => ["gpt-4", "gpt-3.5-turbo"]}`).
   - **Reasoning:** This explicitly satisfies the "static fallback chains" requirement of ORCH-01, avoids introducing database lookups into the hot path, and aligns with Elixir OTP configuration idioms. Dynamic, database-backed configurations can be introduced in a future phase if Operator UI editability is required.

3. **Telemetry and Observability**
   - **Distinct Events:** The `Scoria.Orchestrator` must emit its own domain-level telemetry events (e.g., `[:scoria, :orchestrator, :request, :stop]` and `[:scoria, :orchestrator, :fallback]`) to track the logical attempt chain.
   - **Reasoning:** Operators must be able to visually distinguish between a primary model success and a successful fallback recovery. The underlying `ReqLLM` telemetry will continue to emit individual HTTP spans for each attempt.

### the agent's Discretion
(None specified)

### Deferred Ideas (OUT OF SCOPE)
- **Dynamic Fallback Chain Management via UI:** Creating LiveView forms to edit fallback chains is out of scope. Configuration is handled strictly via `config.exs` or `runtime.exs`.
- **Advanced Cross-Provider Payload Translation:** For this phase, we assume the fallback model is capable of handling the same payload shape or that `ReqLLM` abstractly handles basic translation. Complex AST transformations of prompts are deferred.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Fallback Routing | API / Backend | — | Core domain logic that shouldn't leak to HTTP clients. |
| Configuration | API / Backend | — | OTP environment manages static fallback mappings. |
| Telemetry | API / Backend | — | Domain wrapper defines the span of the orchestration attempt. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ReqLLM | ~> 1.11 | LLM Client | Existing project standard for text/object generation. |
| :telemetry | standard | Observability | Native BEAM instrumentation primitive. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Domain Wrapper | Req Middleware Step | Middleware obscures telemetry logic and mixes HTTP with domain concepts. `Req` steps shouldn't dictate fallback chains. |

## Architecture Patterns

### Pattern 1: Recursive Fallback with Option Isolation
**What:** Utilizing recursion over the model chain list to safely isolate HTTP options for each target.
**When to use:** When retrying requests across multiple distinct targets using the same HTTP client but different plugins (steps).
**Example:**
```elixir
defp attempt_generate(type, [current_model | rest], args, req_llm_module, primary_model) do
  # 1. Pop existing options safely
  original_options = List.last(args)
  existing_req_options = Keyword.get(original_options, :req_options, [])
  
  # 2. Inject model-specific resiliency steps (does not mutate args permanently)
  resiliency_options = Scoria.Req.Steps.req_options(current_model)
  attempt_options = Keyword.put(original_options, :req_options, existing_req_options ++ resiliency_options)
  attempt_args = List.replace_at(args, length(args) - 1, attempt_options)

  # 3. Apply via dynamic module to support test stubs
  result = apply(req_llm_module, func_name(type), [current_model | attempt_args])
  
  case result do
    {:ok, response} -> {:ok, response}
    {:error, reason} when rest != [] ->
      emit_fallback(primary_model, current_model, hd(rest), reason)
      attempt_generate(type, rest, args, req_llm_module, primary_model) # Notice `args` is passed cleanly
    {:error, reason} -> {:error, reason}
  end
end
```

### Anti-Patterns to Avoid
- **Mutating Options Permanently:** Appending `Scoria.Req.Steps.req_options/1` to `options` across recursive steps will cause the HTTP request to load circuit breaker callbacks for *all* previous failed models. The options array must be scoped solely to the current target attempt.
- **Forcing the Dependency Injection Layer:** Callers should stop loading `Application.get_env(:scoria, :req_llm_module)`. They should load `orchestrator_module` and let `Scoria.Orchestrator` pull the LLM dependency, except where explicitly overriding (like `JudgeRunner` via `attrs`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Error Types | Custom struct parsing | Abstract `{:error, reason}` | Req and ReqLLM already abstract standard failures. CircuitBreakers halt with standard RuntimeErrors. Catch everything loosely. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | Verified config only layer |
| Live service config | None | Verified config only layer |
| OS-registered state | None | Verified config only layer |
| Secrets/env vars | None | Fallback chains managed via config structure, no direct secrets. |
| Build artifacts | None | Verified config only layer |

## Common Pitfalls

### Pitfall 1: Telemetry Type Mismatch
**What goes wrong:** `[:scoria, :orchestrator, :request, :stop]` sends a string or non-native unit for duration.
**Why it happens:** Attempting to manually measure execution time without utilizing monotonic metrics.
**How to avoid:** Use `System.monotonic_time()` before the action and subtract after. Convert cleanly with `System.convert_time_unit(..., :native, :millisecond)`.

### Pitfall 2: Breaking Async Live Tests
**What goes wrong:** `JudgeRunnerTest` overrides `req_llm_module` via its input map, but Orchestrator pulls from App config.
**Why it happens:** The test runs asynchronously so it can't mock the global `Application` environment via `put_env`.
**How to avoid:** `Scoria.Orchestrator.generate_*` should accept `:req_llm_module` inside the `options` Keyword list as an override:
```elixir
{req_llm_module, options} =
  Keyword.pop(options, :req_llm_module, Application.get_env(:scoria, :req_llm_module, ReqLLM))
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | none — see Wave 0 |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ORCH-01 | Recursively try models configured in chain | unit | `mix test test/scoria/orchestrator_test.exs` | ❌ Wave 0 |
| ORCH-02 | Emit `[:scoria, :orchestrator, :fallback]` on model failure | unit | `mix test test/scoria/orchestrator_test.exs` | ❌ Wave 0 |
| ORCH-03 | Replace direct `ReqLLM` calls in workers | integration | `mix test test/scoria/compaction/summarize_worker_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scoria/orchestrator_test.exs` — verifies fallback and telemetry events.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Existing prompt handling |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir / LLM

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Service Degradation via Timeout Accumulation | Denial of Service | CircuitBreakers (existing) ensure fast failure; orchestrator relies on them. |

## Sources

### Primary (HIGH confidence)
- Codebase - Verified test injections via `SummarizeWorkerTest` and `JudgeRunnerTest`.
- Codebase - Examined `Scoria.Req.Steps.CircuitBreaker` and `Scoria.Req.Steps.Resiliency`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows the project architecture and configuration.
- Architecture: HIGH - Recursive retry natively fits Elixir and allows isolated option passing.
- Pitfalls: HIGH - Identified direct need for option popping for `async: true` tests.

**Research date:** 2026-05-20
**Valid until:** 2026-06-20
