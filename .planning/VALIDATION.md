# Phase 1: Core Observability & Telemetry - Validation Strategy

This validation strategy ensures the core observability features built in Phase 1 meet all Nyquist compliance mandates and satisfy the Success Criteria outlined in `ROADMAP.md`.

## Success Criteria Mapping

### 1. Spans mapped from Erlang `:telemetry` accurately reflect OpenInference vocabulary and persist in Ecto.
**Verification Strategy**:
- Automated tests map typical Erlang `:telemetry` events (from Jido and ReqLLM) to Ecto schemas and insert them into a test database.
- Assert that inserted rows in `ai_spans` correctly feature OpenInference `span_kind`, `attributes`, and status mappings.
- Execute integration test validating end-to-end `Scoria.Observe.Telemetry` flow ending in `ai_spans` table validation.

### 2. PII and secrets are redacted before database insertion.
**Verification Strategy**:
- Define a strict deny-list of keys representing PII or secrets (e.g., `password`, `api_key`, `token`, `secret`).
- Fire test telemetry events populated with these sensitive keys deep inside nested maps and lists.
- Query the database to ensure all identified sensitive keys within the JSONB `attributes` column are replaced with `[REDACTED]`.

### 3. Main LLM execution processes are completely unaffected by tracing latency (verified via async insertion).
**Verification Strategy**:
- Emit thousands of telemetry events simulating heavy LLM workload tracing.
- Validate that the `Scoria.Observe.Buffer` handles inputs concurrently via `cast` without causing latency spikes on the emitting process (measured via microbenchmark or synchronous test timeouts).
- Assert that asynchronous batch flushing triggers `Repo.insert_all` correctly under load, and shuts down gracefully without dropping the final spans.

## Execution Requirements
All tests executing these strategies must be written using `ExUnit` and executed via `mix test`. No manual tests are acceptable for phase completion. Every acceptance criteria test must be automated to ensure strict Nyquist compliance.