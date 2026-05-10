# Scoria: Research Summary

## Executive Summary

Scoria is a Phoenix-native "AI Application Quality Layer" that bridges the gap between running LLM models and operating them safely in production. Rather than reinventing execution logic and acting as "yet another LLM client," Scoria composes and operationalizes existing execution primitives in the Elixir ecosystem (like ReqLLM, Jido, and Tribunal). It focuses strictly on providing a batteries-included AI Ops Layer, offering deep observability, continuous evaluation, and secure governance tailored for Elixir and Phoenix applications.

By adhering to the szTheory "Unix Philosophy" and "SaaS in a Box" DNA, Scoria explicitly bounds its responsibilities: it integrates with execution engines but strictly owns the operational domain. This includes an Ecto-native runtime trace and span store based on OpenInference, an evaluation flywheel bridging production traces to CI regression datasets, a robust MCP Gateway for controlled tool execution, and an embedded LiveView operator UX. The architectural approach mandates separating protocol transport (Plug/HTTP for MCP) from UI transport (WebSockets for LiveView) while seamlessly integrating with sibling ecosystem tools like Sigra for auth and Threadline for audit logging.

Crucial risks involve storing unredacted PII, overwhelming the LiveView DOM with rapid token streams, and building a monolithic "God Package." Scoria mitigates these by enforcing telemetry redaction at the boundary, applying token coalescing and lazy rendering in the UI, and decoupling its observability (`scoria_observe`) from its evaluation (`scoria_eval`) modules.

## Key Findings

### Stack & Ecosystem
- **Core Strategy:** Compose, normalize, and operationalize. Adapt `ReqLLM` (for normalized calls), `Jido` (for agent execution), and `Tribunal` (for evaluation execution).
- **Ownership:** Scoria strictly owns the persistent data structures (Ecto schemas for traces, datasets, prompts, tool approvals) and the LiveView control plane.
- **Integration Layer:** Defer to existing Elixir primitives instead of building another LangChain or execution engine. Use OpenInference/OpenTelemetry specifications natively for vocabulary.

### Features & Capabilities
- **Table Stakes:** Ecto-native trace and span storage using OpenInference standards, decoupled from heavy external SaaS dependencies.
- **Differentiators:** An integrated "Evaluation Flywheel" that allows operators to seamlessly promote failed production traces into regression datasets directly from the LiveView UI.
- **Anti-Features:** Not a universal LLM SDK or an autonomous agent framework. Scoria avoids nondeterministic magic by tracing everything and offering "Volcanic clarity."

### Architecture
- **Boundary Separation:** Clear separation between LiveView UI transport and MCP protocol transport (using Plug/Streamable HTTP).
- **Security & Governance:** The MCP Gateway acts as a policy-enforced proxy using the "Conn" pattern to inject actor contexts (via Sigra). Strict schema validation, Ecto changesets, and OTP-based process isolation (Task/GenServer) ensure tools don't crash the host or act as confused deputies.
- **Human-in-the-Loop (HITL):** High-risk tool calls suspend execution via `Task.yield`, trigger telemetry/PubSub events, and await operator approval via the LiveView dashboard before resuming.

### Pitfalls & Mitigations
- **PII / Data Leaks:** Mitigate by implementing strict telemetry redaction boundaries and 7-day retention policies for raw payloads.
- **LiveView Stream Bottlenecks:** Mitigate DOM bloat and CPU spikes by coalescing token deltas (e.g., buffering every 50-100ms) and lazy-rendering deep trace trees.
- **Nondeterministic CI:** Mitigate LLM-as-judge fluctuations by allowing regression tolerances and immutably snapshotting judge versions.
- **God Package Rejection:** Mitigate by decoupling trace, eval, and gateway modules, allowing users to `Mix.install` only the components they need.

## Implications for Roadmap

The research suggests a bottom-up integration strategy starting with data primitives and culminating in the sophisticated LiveView UI.

Suggested phases: 4

1. **Phase 1: Core Observability & Telemetry** — The foundation must be laid for capturing and storing traces securely.
   - *Delivers:* OpenInference-compliant span schemas, `scoria_observe` Ecto store (`ai_traces`, `ai_spans`), Telemetry handlers, and basic PII redaction.
   - *Pitfalls avoided:* PII retention and "God Package" architecture (by keeping this layer standalone).

2. **Phase 2: MCP Gateway & Tool Governance** — Establish the secure boundary for model actions.
   - *Delivers:* Plug-based HTTP MCP transport, `Scoria.MCP.Router`, Actor context injection ("Conn" pattern), Schema validation, and OTP isolated tool execution.
   - *Features:* Secure execution boundary and integration with auth layers (Sigra).

3. **Phase 3: The LiveView Operator UX** — Surface the observability data with an operator-first experience.
   - *Delivers:* Embedded LiveView orchestrator, nested trace tree visualization (with lazy loading and CSS grids), async real-time token streaming with coalescing, and HITL tool approval workflows.
   - *Pitfalls avoided:* LiveView DOM bottlenecks (via coalescing and lazy-rendering).

4. **Phase 4: The Evaluation Flywheel** — Close the loop from production to CI.
   - *Delivers:* `scoria_eval` module, Ecto-native dataset storage, and the UI capabilities to "Promote to Dataset" and run deterministic / LLM-as-judge evaluations.
   - *Pitfalls avoided:* Nondeterministic CI failures (via baseline thresholds and versioned rubrics).

### Research Flags
- **Needs research:** Phase 4 (Defining standard evaluation rubrics and Elixir ExUnit integration specifics).
- **Standard patterns:** Phase 1 (Ecto schemas/Telemetry) and Phase 2 (Plug/HTTP RPC).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Excellent alignment with Elixir ecosystem (ReqLLM, Jido, Tribunal) and szTheory principles. |
| Features | HIGH | Clear differentiation by focusing on Ops/Observability rather than LLM client execution. |
| Architecture | HIGH | Strong adherence to OTP process isolation, Plug patterns, and OpenInference standards. |
| Pitfalls | HIGH | Specific and actionable mitigations for UI performance, data security, and architectural bloat. |

**Gaps to Address:**
- Specific integration details of Tribunal for the evaluation engine.
- Fine-grained RBAC/Policy implementation details when integrating with external libraries like Bodyguard or Sigra.

## Sources
- STACK: `.planning/research/elixir-ai-ecosystem.md`
- FEATURES: `.planning/research/evals-and-observability.md`
- ARCHITECTURE: `.planning/research/mcp-and-tools.md`
- PITFALLS: `.planning/research/liveview-operator-ux.md`