# Research Summary: Scoria (v1.8 Vanguard)

**Domain:** Multi-model orchestration and distributed evaluations
**Researched:** 2024-05-24
**Overall confidence:** HIGH

## Executive Summary

The Vanguard milestone focuses on introducing highly resilient multi-model orchestration and robust distributed evaluation execution. Research confirms that remaining within the strict Elixir/Phoenix ecosystem (specifically using OTP, `:telemetry`, ETS, and Oban) is not just feasible, but provides the most scalable and observable path forward. 

By avoiding heavy abstractions like LangChain or external circuit-breaker libraries, Scoria can maintain its "operator-visible" mandate. A custom `Scoria.Orchestrator.Router` backed by ETS for circuit-breaking, combined with Oban for fanning out evaluations, perfectly balances performance with transparency.

## Key Findings

**Stack:** Core Elixir OTP primitives (ETS), `:telemetry`, `Req`, and `Oban` are fully capable of handling advanced routing and distributed jobs without external dependencies.
**Architecture:** A decoupled Router/CircuitBreaker pattern using ETS for concurrent state reads prevents single-process bottlenecks during high-volume inference.
**Critical pitfall:** Retry storms causing connection exhaustion. Strict circuit breaking and jittered exponential backoffs are mandatory.

## Implications for Roadmap

Based on research, suggested phase structure for Vanguard:

1. **Phase 1: Oban Integration & Queue Segregation** - Establish the infrastructure for background processing.
   - Addresses: Need for isolated execution contexts (`inference` vs `evals`).
   - Avoids: DB contention and starvation of web queues.

2. **Phase 2: The Routing & Circuit Breaker Layer** - Implement ETS-backed health tracking and telemetry hooks.
   - Addresses: Multi-model failover and rate limit tracking.
   - Avoids: GenServer bottlenecks and retry storms.

3. **Phase 3: Distributed Eval Coordinator** - Build the campaign lifecycle and Oban worker logic.
   - Addresses: Fanning out tests across tenants.

4. **Phase 4: Real-time Operator Dashboards** - Expose the orchestration state and eval progress via Phoenix LiveView.
   - Addresses: "Operator-visible by default" mandate.

**Research flags for phases:**
- Phase 2: May require deeper load-testing on ETS concurrency tuning depending on expected inference volume.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Elixir standard library and Oban are industry-standard for these exact problems. |
| Features | HIGH | Native HTTP clients (Req) and Oban provide all necessary primitives. |
| Architecture | HIGH | OTP patterns (ETS/GenServer) map perfectly to circuit breakers and routing. |
| Pitfalls | HIGH | Retry storms and Ecto pool exhaustion are well-documented Elixir scaling hurdles. |

## Gaps to Address

- **Cross-Node Circuit Breaking:** Do we need cluster-aware circuit breakers (e.g., using Phoenix.PubSub to broadcast health state), or are node-local ETS tables sufficient for MVP? Recommending node-local for MVP due to simplicity.