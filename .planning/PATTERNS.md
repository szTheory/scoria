# Phase 1: Core Observability & Telemetry - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 8
**Analogs found:** 0 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/span.ex` | model | CRUD | None | no-match |
| `lib/scoria/trace.ex` | model | CRUD | None | no-match |
| `lib/scoria/span_event.ex` | model | CRUD | None | no-match |
| `lib/scoria/telemetry/handler.ex` | service | event-driven | None | no-match |
| `lib/scoria/telemetry/buffer.ex` | service | batch | None | no-match |
| `lib/scoria/telemetry/redactor.ex` | utility | transform | None | no-match |
| `lib/scoria/telemetry/adapters/req_llm.ex` | service | transform | None | no-match |
| `lib/scoria/telemetry/adapters/jido.ex` | service | transform | None | no-match |

## Pattern Assignments

Since this is an empty/greenfield project, there are no existing source files to derive analog patterns from. The planner must rely strictly on the research, decisions, and architectural guidelines defined in `.planning/research/phase_1_decisions.md`, `.planning/research/evals-and-observability.md`, and `GEMINI.md`.

## Shared Patterns

### GEMINI.md Guidelines
**Source:** `GEMINI.md`
**Apply to:** All files
- **Ash Framework Non-Goal:** Do not attempt to integrate with or use the Ash framework. Strictly use standard Phoenix and Ecto architectures.
- Provide deep, cohesive recommendations with a focus on developer ergonomics, principle of least surprise, and great UI/UX.

### Schema Design Pattern (OBS-01)
**Source:** `.planning/research/phase_1_decisions.md`
**Apply to:** `lib/scoria/span.ex`, `lib/scoria/trace.ex`, `lib/scoria/span_event.ex`
- Adopt a hybrid Ecto schema: use highly-indexed relational columns for searchable, routable fields (e.g., `id`, `trace_id`, `parent_id`, `name`, `span_kind`, `status_code`, `start_time`, `end_time`) and use an `attributes` column defined as `:map` (JSONB) for variable OpenInference attributes.

### Telemetry Batch Ingestion Pattern (OBS-03)
**Source:** `.planning/research/phase_1_decisions.md`
**Apply to:** `lib/scoria/telemetry/buffer.ex`, `lib/scoria/telemetry/handler.ex`
- Use a native OTP Buffer (`Scoria.Telemetry.Buffer`). Use `cast` to a GenServer or write to ETS for max concurrency, and use a background `Task` with `Repo.insert_all` to batch-insert OpenInference spans into Postgres. Avoid Broadway or Oban to prevent unnecessary bloat.
- Hook into the application's shutdown sequence (`System.at_exit` or standard supervision tree termination) to flush remaining spans before exit.

### Redaction Pattern (OBS-04)
**Source:** `.planning/research/phase_1_decisions.md`
**Apply to:** `lib/scoria/telemetry/redactor.ex`
- Use a hybrid Configurable Deny-list + MFA Escape Hatch. Default aggressive deny-list (e.g., password, api_key, token), allow appending via `config :scoria, :redact_keys`, and provide an MFA override via `config :scoria, :redactor`. Intercept OpenInference payload, walk map/JSON recursively, replace with `[REDACTED]`.

### Data Flow Integration (OBS-02, OBS-05)
**Source:** `.planning/research/evals-and-observability.md`
**Apply to:** `lib/scoria/telemetry/handler.ex`, `lib/scoria/telemetry/adapters/req_llm.ex`, `lib/scoria/telemetry/adapters/jido.ex`
- Runtime emits standard Erlang `:telemetry` events (e.g., `[:scoria, :llm, :request, :stop]`).
- Adapters listen to third-party library telemetry (ReqLLM, Jido) and normalize them into OpenInference-compliant span maps.

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/scoria/span.ex` | model | CRUD | Empty codebase |
| `lib/scoria/trace.ex` | model | CRUD | Empty codebase |
| `lib/scoria/span_event.ex` | model | CRUD | Empty codebase |
| `lib/scoria/telemetry/handler.ex` | service | event-driven | Empty codebase |
| `lib/scoria/telemetry/buffer.ex` | service | batch | Empty codebase |
| `lib/scoria/telemetry/redactor.ex` | utility | transform | Empty codebase |
| `lib/scoria/telemetry/adapters/req_llm.ex` | service | transform | Empty codebase |
| `lib/scoria/telemetry/adapters/jido.ex` | service | transform | Empty codebase |

## Metadata

**Analog search scope:** Codebase via glob `**/*.ex`, `**/*.exs`
**Files scanned:** 0 (No Elixir files found)
**Pattern extraction date:** 2024-05-18