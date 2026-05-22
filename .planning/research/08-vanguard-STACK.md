# Technology Stack

**Project:** Scoria (v1.8 Vanguard)
**Researched:** 2024-05-24
**Domain:** Multi-model orchestration and distributed evaluations

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir & Phoenix | Latest | Core application platform | Strict adherence to project constraints and embedded architecture. |
| Oban | ~2.17 | Distributed job queueing | Rock-solid PG-backed queueing system essential for fanning out distributed evaluations across tenants. |

### Infrastructure & State
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| ETS | Native | Circuit breaker & routing state | In-memory, ultra-fast reads/writes for tracking rate limits and failure rates across models without DB overhead. |
| PostgreSQL / Ecto | Latest | Persistence & Aggregation | Storing evaluation campaigns, results, and multi-model routing policies. |
| Phoenix.PubSub | Native | Real-time eval updates | Pushing progress of distributed evaluations to LiveView operator dashboards. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Req | ~0.4+ | HTTP Client & API abstraction | Making requests to external LLM providers. Has built-in retry and custom step support perfectly suited for fallback logic. |
| :telemetry | Native | Observability & Routing | Emitting events on model failures/latencies, which can be hooked into the circuit breaker logic. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Orchestration Framework | Native Elixir/Req Steps | LangChain (Elixir) | LangChain adds heavy abstractions that violate the "operator-visible" and "embedded Phoenix-first" principles. Better to build lightweight `Req` plugins. |
| Circuit Breaking | Custom ETS + :telemetry | :fuse or :circuit_breaker | External libraries often obscure state. A bespoke `gen_statem` or ETS approach gives us total observability in LiveDashboard. |
| Evaluation Distribution | Oban | Broadway | Broadway is stream-focused (Kafka/SQS/RabbitMQ), while Oban excels at PG-backed transactional job scheduling, keeping infrastructure minimal. |

## Sources
- Official Elixir ecosystem patterns (Oban for job coordination, ETS for high-concurrency shared state, Req for API orchestration).
- Scoria architecture constraints (No Ash, Phoenix-first, Ecto-backed).