# Domain Pitfalls

**Domain:** Multi-model orchestration and distributed evaluations
**Researched:** 2024-05-24

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Retry Storms (The Thundering Herd)
**What goes wrong:** A model API goes down. Hundreds of queued evals and live requests fail, instantly triggering immediate retries. The retries fail, triggering more retries, completely exhausting outgoing connection ports or HTTP client pools.
**Why it happens:** Unbounded retries, lack of exponential backoff, and missing circuit breakers.
**Consequences:** The entire application becomes unresponsive, not just the LLM features.
**Prevention:** 
1. Strict circuit breaking (fail fast if model is down).
2. Explicit max retry limits (e.g., 2).
3. Exponential backoff with jitter on retries.
**Detection:** Outbound connection exhaustion, process mailbox queues growing infinitely.

### Pitfall 2: Oban Database Contention on Massive Insertions
**What goes wrong:** Inserting 100,000 evaluation jobs blocks other database operations.
**Why it happens:** Standard `Ecto.Repo.insert` in a loop instead of batching.
**Consequences:** Ecto pool checkout timeouts for all web requests.
**Prevention:** Use `Oban.insert_all/2` with chunks of 500-1000 jobs.

## Moderate Pitfalls

### Pitfall 3: Feature Parity Mismatch on Fallback
**What goes wrong:** A request meant for an Anthropic model with a 200k token context falls back to a model with a 32k context and fails hard with a generic 400 error.
**Prevention:** The routing layer must be aware of model capabilities. Fallback chains should only route to equivalent or higher-capability models for the specific payload size.

### Pitfall 4: GenServer Bottlenecks for Routing
**What goes wrong:** Placing the router behind a single GenServer for state management (`GenServer.call(Router, :get_model)`).
**Prevention:** The router should be a stateless module that reads from an ETS table for its dynamic routing decisions. ETS handles concurrent reads seamlessly.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Fallback Orchestration | Infinite failover loops (A -> B -> A). | Track the original model requested and limit failover depth to 1 or 2 models in a static chain. |
| Distributed Evals | Starving web/inference queues. | Segregate Oban queues aggressively. `inference` gets high concurrency, `evals` gets lower concurrency to run quietly in background. |

## Sources
- Elixir in Action (OTP bottlenecks).
- PostgreSQL/Oban scaling guides (Batch insertion).