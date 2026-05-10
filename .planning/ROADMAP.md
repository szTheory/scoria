# Roadmap: Scoria

## Phases

- [ ] **Phase 1: Core Observability & Telemetry** - Foundation for capturing and storing OpenInference-compliant traces securely.
- [ ] **Phase 2: MCP Gateway & Tool Governance** - Secure boundary, HTTP transport, and OTP-isolated tool execution.
- [ ] **Phase 3: LiveView Operator UX** - The embedded control plane, visual trace tree, and HITL tool approval.
- [ ] **Phase 4: Evaluation Flywheel** - Closing the loop from production to CI with dataset management and evals.

## Phase Details

### Phase 1: Core Observability & Telemetry
**Goal**: The foundation must be laid for capturing and storing traces securely in Ecto using OpenInference standards without blocking main processes.
**Depends on**: Nothing
**Requirements**: OBS-01, OBS-02, OBS-03, OBS-04, OBS-05
**Requirement Mapping (Built vs Integrated)**:
- **Built**: Ecto-native state schemas (`ai_traces`, `ai_spans`, `ai_span_events`), strict telemetry redaction logic, background batch-insert workers.
- **Integrated**: Existing Erlang `:telemetry` handlers, OpenInference schema vocabularies, Oban (or OTP Tasks) for async insertion.
**Architectural boundaries**: Decoupled from evaluation and UI layers; acts as a standalone observability engine (`scoria_observe`). Must strictly redact PII before storage.
**Success Criteria** (what must be TRUE):
  1. Spans mapped from Erlang `:telemetry` accurately reflect OpenInference vocabulary and persist in Ecto.
  2. PII and secrets are redacted before database insertion.
  3. Main LLM execution processes are completely unaffected by tracing latency (verified via async insertion).
**Plans**: 4 plans
- [ ] 01-01-PLAN.md — Core Ecto Schemas and Database Structure
- [ ] 01-02-PLAN.md — Telemetry Redaction Engine
- [ ] 01-03-PLAN.md — Async Batching Engine
- [ ] 01-04-PLAN.md — Telemetry Handlers and Adapters

### Phase 2: MCP Gateway & Tool Governance
**Goal**: Establish a secure, policy-enforced boundary for model actions via a Phoenix-native MCP integration.
**Depends on**: Phase 1 (for observing tool executions)
**Requirements**: MCP-01, MCP-02, MCP-03, MCP-04, MCP-05
**Requirement Mapping (Built vs Integrated)**:
- **Built**: `Scoria.MCP.Router` Plug endpoint, isolated OTP execution wrappers for tools, Tool schema validation using Ecto changesets, HTTP/SSE transport mapping.
- **Integrated**: Sigra (for actor context and auth), Threadline (for audit logging), standard JSON-RPC 2.0 specs.
**Architectural boundaries**: Strictly separates MCP protocol transport (Plug/HTTP) from UI transport (WebSockets). Implements strict OTP process isolation (`Task`/`GenServer`) to prevent tool failures from crashing the host.
**Success Criteria** (what must be TRUE):
  1. Tool executions happen in isolated OTP processes that do not crash the host app upon failure or timeout.
  2. All tool invocations are strictly schema-validated before execution and bound to an authenticated actor context.
  3. MCP traffic is handled via a standard Plug endpoint securely.
**Plans**: 3 plans
- [x] 02-01-PLAN.md — MCP Router and JSON-RPC Protocol Transport
- [x] 02-02-PLAN.md — Tool Definition and Changeset Validation
- [ ] 02-03-PLAN.md — OTP-Isolated Execution and Audit Logging

### Phase 3: LiveView Operator UX
**Goal**: Surface observability data with a deeply integrated, operator-first LiveView experience featuring the "Shape of AI".
**Depends on**: Phase 1, Phase 2
**Requirements**: UI-01, UI-02, UI-03, UI-04, UI-05
**Requirement Mapping (Built vs Integrated)**:
- **Built**: Embedded LiveView orchestrator dashboard, nested CSS-grid trace tree visualization, token coalescing/buffering logic, HITL tool approval modals.
- **Integrated**: Phoenix LiveView, Phoenix PubSub, host app's router (via `mix scoria.install`), Sigra (for UI RBAC).
**Architectural boundaries**: Strictly bounded to LiveView and PubSub. Does not run LLM execution logic directly on the UI process. Must handle deep DOMs via lazy rendering and fast streams via buffering.
**Success Criteria** (what must be TRUE):
  1. User can view deeply nested trace trees without browser lag, utilizing lazy rendering.
  2. Real-time streaming tokens render efficiently without spiking CPU or DOM updates, utilizing coalescing.
  3. High-risk tool calls trigger an interactive approval modal for an admin, pausing the actual execution process until resolved.
  4. Day-0 users can install the dashboard via a `mix scoria.install` task with zero manual configuration.
**Plans**: TBD
**UI hint**: yes

### Phase 4: Evaluation Flywheel
**Goal**: Close the loop from production to CI by enabling operators to promote traces to tests and run evaluations directly from the UI.
**Depends on**: Phase 1, Phase 3
**Requirements**: EVAL-01, EVAL-02, EVAL-03, EVAL-04
**Requirement Mapping (Built vs Integrated)**:
- **Built**: Ecto schemas for datasets and eval runs (`ai_datasets`, `ai_eval_runs`), "Promote to Dataset" UI workflow, Versioned rubric storage.
- **Integrated**: Tribunal (for the underlying evaluation engine execution), ExUnit (for CI gate testing).
**Architectural boundaries**: `scoria_eval` is a distinct module/sub-app decoupled from `scoria_observe`. It owns the storage of dataset versions in Ecto but delegates deterministic/LLM evaluation execution to standard Elixir/Tribunal primitives.
**Success Criteria** (what must be TRUE):
  1. Operator can promote a failed production trace into a versioned dataset via a single click in the LiveView UI.
  2. Operator can execute deterministic or LLM-as-judge evaluations on datasets.
  3. Evals can be configured with baseline thresholds to prevent nondeterministic CI failures (e.g., requires >95% success).
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Observability & Telemetry | 4/4 | Complete | - |
| 2. MCP Gateway & Tool Governance | 2/3 | In Progress | - |
| 3. LiveView Operator UX | 0/0 | Not started | - |
| 4. Evaluation Flywheel | 0/0 | Not started | - |
