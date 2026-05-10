# Phase 1 Architectural Decisions: Scoria AI Ops Layer

This document outlines the research, tradeoffs, and final recommendations for three core architectural decisions in Phase 1 of Scoria. The goal is to build an idiomatic, highly ergonomic Elixir/Phoenix-native AI Application Quality Layer that requires minimal configuration while remaining robust and scalable.

---

## 1. Async Batching Engine for Telemetry (OBS-03)

**Context:** We need to handle high-throughput async processing to batch-insert OpenInference spans into Ecto without blocking the application's critical path.

### Options & Tradeoffs

| Approach | Pros | Cons |
| :--- | :--- | :--- |
| **Native OTP Buffer (GenServer/Task/ETS)** | Zero dependencies. Built into the language. Extremely fast memory buffering. Predictable, low latency for the caller. | Requires manual implementation of flush intervals, backpressure, and graceful shutdown (to prevent data loss on node exit). |
| **Oban Job Queue** | Persistent, guaranteed delivery, built-in retries, Ecto-native, familiar to the Elixir community. | High DB ingestion latency. Oban is designed for background jobs, not high-volume time-series telemetry. Writing every span as an Oban job would overwhelm Postgres with transaction overhead. |
| **Broadway / GenStage** | Industry standard for high-throughput, backpressure, and concurrent batching pipelines. | Overkill for a local library not consuming from SQS/Kafka/RabbitMQ. Introduces a heavy, complex dependency for a "simple to install" library. |

### Industry Lessons & Idiomatic Elixir
- **AppSignal & Phoenix.Tracker:** Both rely heavily on native OTP for telemetry ingestion. AppSignal batches data in memory using a C extension and flushes periodically. `Phoenix.Tracker` uses CRDTs and GenServers to batch and broadcast state.
- **Datadog:** Agent batches spans in-memory and flushes on a timer to avoid crushing network/disk IO.
- **Idiomatic Elixir:** For library-level telemetry, synchronous DB inserts are a cardinal sin. However, requiring users to install Broadway is too heavy. Native OTP processes (using ETS for concurrent writes if needed, and GenServers for coordinated flushing) represent the "batteries included, no bloat" ideal.

### Recommendation: Native OTP Buffer (GenServer + Repo.insert_all)
**The "Perfect" One-Shot Approach:** Use a native OTP Buffer (`Scoria.Telemetry.Buffer`). 
When a telemetry event is emitted, the caller `cast`s it to the Buffer GenServer (or writes directly to an ETS table for maximum concurrency). A recurring `Process.send_after` timer flushes the buffer every `N` milliseconds or when `M` spans are accumulated. 
Flushing is performed via a background `Task` using `Repo.insert_all` to batch-insert the OpenInference spans efficiently into Postgres. We hook into the application's shutdown sequence (`System.at_exit` or standard supervision tree termination) to flush remaining spans before exit. This gives us zero dependencies, immense throughput, and predictable DB load.

---

## 2. Redaction Strategy (OBS-04)

**Context:** AI traces often contain sensitive PII, API keys, or user data. We must scrub these before they hit the Ecto Repo.

### Options & Tradeoffs

| Approach | Pros | Cons |
| :--- | :--- | :--- |
| **Strict Allow-list** | Maximum security. No chance of accidental data leakage. | Horrible developer ergonomics. AI prompts and JSON payloads change constantly. Forcing users to allow-list every JSON key destroys the "trace everything by default" goal. |
| **Purely Custom MFA** | Ultimate flexibility. Users can define exactly how they want to scrub data. | Not "SaaS in a Box". Requires users to write boilerplate code immediately after `mix scoria.install`. |
| **Configurable Deny-List + MFA** | Sane defaults, immediate protection for standard secrets, easy to extend. | Deny-lists are reactive; a developer might log a `stripe_secret` when the deny-list only looks for `api_key`. |

### Industry Lessons & Idiomatic Elixir
- **Sentry & Plug:** Elixir's Sentry client and Plug both use default deny-lists (`["password", "secret", "token", "authorization"]`) to scrub parameters before logging or reporting.
- **Langfuse / Braintrust:** Often struggle with PII unless the developer explicitly wraps data in a redactor function at the call site. This leads to leaked secrets in development.
- **Idiomatic Elixir:** Provide secure, sensible defaults out of the box, with a configuration key in `config.exs` to either append to the default list or override the redaction logic entirely via an MFA.

### Recommendation: Hybrid Configurable Deny-list + MFA Escape Hatch
**The "Perfect" One-Shot Approach:** Ship `Scoria` with an aggressive default deny-list of keys (e.g., `["password", "api_key", "authorization", "secret", "token", "cookie", "ssn"]`). 
Scoria intercepts the OpenInference payload, walks the map/JSON recursively, and replaces the values of matching keys with `[REDACTED]`.
In `config.exs`, developers can seamlessly add to this list:
```elixir
config :scoria, :redact_keys, ["my_custom_internal_token"]
```
For deep PII scrubbing (e.g., running Regex over the actual text of an LLM prompt to remove phone numbers), we provide an MFA escape hatch:
```elixir
config :scoria, :redactor, {MyApp.Security, :scrub_prompt_pii, []}
```
This achieves "secure by default", zero-config setup, while scaling to strict enterprise compliance needs.

---

## 3. OpenInference Schema Design in Ecto (OBS-01)

**Context:** How to model the OpenInference span data in Postgres/Ecto so it is fast to query in Phoenix LiveView but flexible enough to handle the evolving OpenInference specification.

### Options & Tradeoffs

| Approach | Pros | Cons |
| :--- | :--- | :--- |
| **Strict Columns** | Type safety, optimal query performance, straightforward Ecto schema. | OpenInference specs evolve. Spans have dozens of optional attributes (token counts, tool calls, model settings). Maintaining migrations for every attribute is a maintenance nightmare. |
| **Pure JSONB** | Zero migrations needed for new attributes. Complete schema flexibility. | Harder to query effectively. Finding "all failed LLM calls" requires JSON path querying, which can be slower and harder to index optimally. Complex Ecto queries. |
| **Core Columns + JSONB Attributes** | Fast queries for primary UI filtering (time, status, trace grouping). Flexibility for everything else. | Requires thoughtful boundary design to decide what deserves a column vs. what goes in JSONB. |

### Industry Lessons & Idiomatic Elixir
- **Oban:** Uses core relational columns for things the system queries on constantly (`state`, `queue`, `worker`, `scheduled_at`), while arbitrary payloads go into `args` (JSONB) and `errors` (JSONB).
- **Langfuse / Datadog:** Datadog indexes core "tags" and standardizes core metrics, but arbitrary logs remain schema-less. Langfuse uses relational models for Traces/Spans, but dumps LLM-specific parameters into JSON columns.
- **Idiomatic Elixir:** Ecto treats JSONB (`:map`) as a first-class citizen. Combining highly-indexed relational columns with an `:map` field is the gold standard for telemetry/events in Elixir.

### Recommendation: Core Metadata Columns + JSONB Attributes
**The "Perfect" One-Shot Approach:** Adopt a hybrid Ecto schema. 

Create a `scoria_spans` table where the **searchable, routable, and relational** fields of OpenInference are distinct, indexed columns:
- `id` (UUID, primary key)
- `trace_id` (UUID, indexed for grouping spans)
- `parent_id` (UUID, for hierarchical waterfalls)
- `name` (String, e.g., "OpenAI Chat")
- `span_kind` (String, e.g., "LLM", "CHAIN", "RETRIEVER")
- `status_code` (String, "OK" | "ERROR")
- `start_time` (UTC DateTime, indexed for timeline sorting)
- `end_time` (UTC DateTime)

All other highly variable OpenInference attributes (e.g., `llm.prompts`, `llm.model_name`, `llm.token_count`, `retrieval.documents`) are stored in a single `attributes` column defined as `:map` (JSONB). 

**Why this wins:** 
1. **LiveView Ergonomics:** The Phoenix LiveDashboard can do `Repo.all(from s in Span, where: s.status_code == "ERROR", order_by: [desc: s.start_time])` instantly using standard indexes.
2. **Future-Proof:** When OpenInference adds a new attribute for "Agent Reasoning Steps", Scoria requires zero database migrations. The UI simply renders the new keys out of the `attributes` map. 
3. **Ecto Native:** The developer interacts with a clean `%Scoria.Span{}` struct that feels like standard Phoenix.
