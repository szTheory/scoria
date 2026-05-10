# Ecosystem Research: Elixir AI & Scoria's Fit

**Project:** Scoria
**Focus:** Elixir AI Ecosystem & Integration
**Confidence:** HIGH (Based on detailed architectural context and ecosystem analysis)

## Executive Summary

The Elixir ecosystem has matured rapidly, offering strong primitives for LLM interaction (ReqLLM, LangChain), agent workflows (Jido), and testing (Tribunal). However, there is a clear missing piece: a Phoenix-native "AI Application Quality Layer" that bridges the gap between running models and operating them safely in production.

Scoria is positioned not as another LLM client or agent framework, but as a **batteries-included AI Ops Layer** for Phoenix. By adhering to the szTheory "Unix Philosophy" and "SaaS in a Box" DNA, Scoria will adapt existing execution primitives while strictly owning the operational, observability, evaluation, and governance domains through a native Ecto/LiveView integration.

## Ecosystem Landscape & Scoria's Position

The strategy for Scoria is to **compose, normalize, and operationalize** rather than reinventing execution logic. 

| Ecosystem Library | Capability | Scoria Integration Strategy |
|-------------------|------------|-----------------------------|
| **ReqLLM / LLMDB** | Standardized LLM requests, streaming, and capability metadata. | **Adapt as Default:** Wrap ReqLLM for provider abstraction and LLMDB for model catalogs. Scoria focuses on instrumenting these calls. |
| **LangChain for Elixir** | Multi-provider support, chains, and complex prompt abstractions. | **Coexist / Adapt:** Allow LangChain to be an execution engine, while Scoria captures its traces and telemetry. |
| **Jido (v2)** | BEAM-native autonomous agent framework (functional decisions, directives). | **Adapt / Instrument:** Make Jido agents observable in Phoenix. Scoria provides the LiveView UI and persistent trace store for Jido workflows. |
| **AshAI** | Ash resource exposure, typed domain actions as MCP tools. | **Support as Adapter:** Allow Ash apps to plug into Scoria's MCP Gateway, keeping Scoria's core pure Elixir/Phoenix. |
| **Tribunal** | LLM evaluation framework with deterministic/LLM-as-judge ExUnit modes. | **Adapt as Engine:** Use Tribunal for underlying evaluation execution, while Scoria owns the persistent dataset storage, UI, and trace promotion flywheel. |
| **AgentObs** | Translates `:telemetry` to OpenTelemetry/OpenInference spans. | **Coexist:** Leverage OpenInference span vocabulary, but Scoria owns the local Ecto storage and LiveView trace explorer. |
| **MCP SDKs (Hermes, Anubis)** | Protocol-level client/server implementations. | **Wrap / Govern:** Build a Phoenix-native MCP Gateway/Control Plane on top to handle auth, policy, registry, and audit logging. |
| **Aludel** | Prompt/eval workbench in LiveView. | **Differentiate / Replace:** Scoria will own the LiveView operator UI for production traces, CI gates, and prompt registries directly. |

## What Scoria Should Own (Core Primitives)

Scoria must own the data structures and control plane that Phoenix operators interact with directly.

1. **The Runtime Trace & Span Store (Ecto-Native State):**
   - **Owns:** `ai_runs`, `ai_traces`, `ai_spans`, `ai_span_events`.
   - **Why:** To provide Day-2 operations, offline replay, and local debugging, traces must be durably stored in the application's PostgreSQL database, accessible directly via Phoenix LiveView.

2. **The Evaluation Flywheel (Datasets & Baselines):**
   - **Owns:** `ai_datasets`, `ai_eval_specs`, `ai_eval_runs`, `ai_scores`, and the UI to promote a failed production trace into a dataset item.
   - **Why:** Evals cannot just be CI tests; they must be a continuous loop fed by real user interactions and operator annotations. 

3. **Prompt & Tool Registry:**
   - **Owns:** `ai_prompts`, `ai_prompt_versions`, `ai_tools`, `ai_tool_approvals`.
   - **Why:** Immutable prompt versions and tool definitions are critical for regression testing and trace audits. Operators need to know *exactly* which prompt version produced a given output.

4. **MCP Gateway & Governance:**
   - **Owns:** MCP Streamable HTTP transport, Registry, Policy execution, Authentication, and the Approval workflows.
   - **Why:** Exposing internal system tools to LLMs requires strict operator oversight, side-effect classification (e.g., `read_only` vs `financial_action`), and human-in-the-loop approval.

5. **The Operator UX (LiveView Dashboard):**
   - **Owns:** Trace Explorer, Eval Workbench, Replay Playground, Feedback Inbox, and Tool Approval UI.
   - **Why:** Operator-first DX is the killer differentiator. It provides the "Shape of AI" patterns seamlessly integrated into a standard Phoenix admin interface.

## What Scoria Should Adapt (Integration Layer)

Scoria should explicitly NOT build these from scratch, to avoid the "yet another client" footgun.

1. **Provider Clients & Normalization:**
   - **Adapts:** `ReqLLM` for normalized API calls and streaming chunks; `LLMDB` for token limits and pricing.
2. **Execution Engines & Agents:**
   - **Adapts:** `Jido` or basic function-calling loops. Scoria provides a lightweight loop but defers to external libraries for complex multi-agent orchestration.
3. **Core Evaluation Logic:**
   - **Adapts:** `Tribunal` or custom deterministic functions for scoring. Scoria focuses on orchestrating the runs and persisting the scores.
4. **Export & Observability standards:**
   - **Adapts:** OpenTelemetry / OpenInference specifications for external SRE exports (and integrates with Parapet).
5. **Ecosystem Synergies (szTheory DNA):**
   - **Adapts:** `Sigra` for admin auth, `Threadline` for audit logs, `Parapet` for SRE/SLOs.

## Strategic Implications & Footguns to Avoid

* **Footgun:** Trying to be the universal LLM SDK.
  * **Mitigation:** Focus strictly on *Phoenix AI Ops*. Be the Oban Web + LangSmith of Elixir, not the next LangChain.
* **Footgun:** Nondeterministic magic.
  * **Mitigation:** Trace everything. The core brand is "Volcanic clarity" (Scoria). Make the internal structure visible (Traces, spans, tool calls).
* **Footgun:** Building MCP transport in LiveView.
  * **Mitigation:** Separate the UI (LiveView) from the protocol. Use Plug/Phoenix endpoint for Streamable HTTP JSON-RPC MCP traffic.

## Architecture Target

```text
                           ┌────────────────────────────┐
                           │ Phoenix LiveView AI Admin  │
                           │ (Owned by Scoria)          │
                           └──────────────┬─────────────┘
                                          │
┌──────────────┐     ┌────────────────────▼───────────────────┐
│ App chat UI  │────▶│ Scoria Runtime                         │
│ LiveView/API │     │ agents runs messages tools guardrails  │
└──────────────┘     └───────────────┬───────────────┬────────┘
                                     │               │
                         ┌───────────▼───────┐   ┌──▼─────────────┐
                         │ Provider Adapter  │   │ MCP Gateway    │
                         │ (ReqLLM + LLMDB)  │   │ (Scoria Plug)  │
                         └───────────┬───────┘   └──┬─────────────┘
                                     │              │
┌────────────────────────────────────────────────────────────────┐
│ Scoria Observability & Eval Store (Ecto)                       │
│ traces, spans, prompts, datasets, eval_runs, tool_approvals    │
└────────────────────────────────────────────────────────────────┘
```