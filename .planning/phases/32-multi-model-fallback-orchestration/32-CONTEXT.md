# Phase 32 Context: Multi-Model Fallback Orchestration

This document captures the architectural decisions and constraints locked during the Phase 32 discuss phase. It serves as the primary input for `/gsd-plan-phase 32`.

## Core Objective

Implement a fallback orchestration layer that automatically routes requests to secondary models when the primary model fails or its circuit breaker is tripped. This builds upon the circuit breakers introduced in Phase 31.

## Architectural Decisions

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

## Excluded from Scope

- **Dynamic Fallback Chain Management via UI:** Creating LiveView forms to edit fallback chains is out of scope. Configuration is handled strictly via `config.exs` or `runtime.exs`.
- **Advanced Cross-Provider Payload Translation:** For this phase, we assume the fallback model is capable of handling the same payload shape or that `ReqLLM` abstractly handles basic translation. Complex AST transformations of prompts are deferred.

## Downstream Impact

- **Worker Updates:** `Scoria.Compaction.SummarizeWorker` and any other direct `ReqLLM` consumers must switch to `Scoria.Orchestrator`.
- **Telemetry Dashboards:** The existing SRE components might need minor updates to visualize the new `[:scoria, :orchestrator, :fallback]` events (though likely deferred to Phase 34 Operator UI).
