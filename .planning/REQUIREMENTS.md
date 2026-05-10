# Requirements

## v1 Requirements

### Core Observability (OBS)
- OBS-01: Implement Ecto-native state schemas (`ai_traces`, `ai_spans`, `ai_span_events`) based on OpenInference specifications.
- OBS-02: Implement Telemetry handlers to capture Erlang `:telemetry` events and translate them into spans.
- OBS-03: Create asynchronous processing (Oban or Task) for batch-inserting spans into Ecto without blocking the main process.
- OBS-04: Implement strict telemetry redaction boundaries to scrub PII, secrets, and API keys before insertion.
- OBS-05: Provide adapters for `ReqLLM` or `Jido` events with the internal trace storage.

### MCP Gateway & Tool Governance (MCP)
- MCP-01: Build a Plug/Streamable HTTP transport for JSON-RPC MCP clients/servers (`Scoria.MCP.Router`).
- MCP-02: Implement Actor context injection (via Sigra integration) utilizing the "Conn" pattern for tool execution.
- MCP-03: Implement strict tool schema validation using Ecto changesets before execution.
- MCP-04: Enforce OTP-isolated tool execution (via `Task` or `GenServer`) with strict timeouts (`Task.yield`).
- MCP-05: Implement audit logging of all tool invocations (via Threadline integration).

### LiveView Operator UX (UI)
- UI-01: Build a Root orchestrator LiveView mounted via the host Phoenix application's router (including `mix scoria.install` generator).
- UI-02: Develop a Visual Trace Explorer with lazy-loading for deep trace trees and CSS grid-based nested visualization.
- UI-03: Implement asynchronous token stream rendering with coalescing (buffering) to prevent DOM bloat and CPU spikes.
- UI-04: Build Human-in-the-Loop (HITL) tool approval modals triggered via PubSub for high-risk tools.
- UI-05: Connect real-time PubSub subscriptions (`scoria:runs:tenant_id`) for passive UI updates.

### Evaluation Flywheel (EVAL)
- EVAL-01: Implement Ecto schemas for evaluation datasets (`ai_datasets`, `ai_dataset_items`, `ai_eval_specs`, `ai_eval_runs`, `ai_scores`).
- EVAL-02: Build LiveView UI integration to "Promote to Dataset" directly from a failed production trace.
- EVAL-03: Provide deterministic unit test evaluation capabilities (integrating Tribunal or native functions).
- EVAL-04: Provide LLM-as-judge evaluation capabilities with versioned rubrics and thresholds.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| OBS-01 | Phase 1 | Pending |
| OBS-02 | Phase 1 | Pending |
| OBS-03 | Phase 1 | Pending |
| OBS-04 | Phase 1 | Pending |
| OBS-05 | Phase 1 | Pending |
| MCP-01 | Phase 2 | Complete |
| MCP-02 | Phase 2 | Complete |
| MCP-03 | Phase 2 | Complete |
| MCP-04 | Phase 2 | Pending |
| MCP-05 | Phase 2 | Pending |
| UI-01 | Phase 3 | Pending |
| UI-02 | Phase 3 | Pending |
| UI-03 | Phase 3 | Pending |
| UI-04 | Phase 3 | Pending |
| UI-05 | Phase 3 | Pending |
| EVAL-01 | Phase 4 | Pending |
| EVAL-02 | Phase 4 | Pending |
| EVAL-03 | Phase 4 | Pending |
| EVAL-04 | Phase 4 | Pending |
