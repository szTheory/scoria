# Milestones

## v1.0 MVP

**Shipped:** 2026-05-10
**Phases:** 4 | **Plans:** 13

### Delivered
A Phoenix-native "AI Application Quality Layer" providing deep observability, continuous evaluation, and secure governance tailored for Elixir and Phoenix applications.

### Key Accomplishments
- Implemented Core Observability using Ecto and Telemetry
- Built MCP Gateway & Tool Governance with isolated OTP execution
- Created LiveView Operator UX with token coalescing and HITL approval modals
- Developed Evaluation Flywheel for promoting production traces to testing datasets

---

## v1.1 Caldera

**Shipped:** 2026-05-11
**Phases:** 1 | **Plans:** 4
**Theme:** Durable Agent Workflows & Handoffs

### Objectives
Build a lightweight, OTP-native agent loop capable of managing complex state machines, subagent handoffs, and durable pauses for long-running workflows or operator approval.

### Delivered
Scoria now ships a durable workflow layer with Ecto-backed checkpointing, root-owned delegated handoffs, supervised recovery semantics, and a trace-first workflow visualizer inside the dashboard surface.

### Scope
- **Durable Checkpoints:** Persist the `RunState` into Ecto natively so workflows can survive BEAM restarts, timeout limits, and operator approval delays.
- **Handoffs & Subagents:** First-class support for an agent to cleanly delegate to another `MyAI.Agent` with specialized tools.
- **Jido Integration (Optional):** Provide an adapter to map `Jido` v2 pure-functional decisions/directives into Scoria's observable trace and checkpoint engine.
- **LiveView Workflow Visualizer:** A visual representation of the agent graph/state machine in the admin dashboard.

### Key Accomplishments
- Added durable workflow tables and transactional lifecycle APIs.
- Added supervised runtime execution, exact resume, and retry-failed-step support.
- Added a workflow LiveView under the existing dashboard router surface.
- Added an optional Jido adapter boundary with full end-to-end lifecycle coverage.

---

## v1.2 Corpus

**Shipped:** 2026-05-11
**Phases:** 1 | **Plans:** 6
**Theme:** Advanced RAG, Citations & Knowledge Grounding

### Objectives
Provide batteries-included RAG primitives that natively integrate with the Scoria trace tree and Eval Workbench.

### Delivered
Scoria now ships a durable knowledge layer with pgvector-backed retrieval, provenance-preserving citations, deterministic grounding checks, and trace-first evidence projection inside the dashboard surface.

### Scope
- **Vector Index & Chunking Abstractions:** Clean behaviors for embedding models and chunking strategies.
- **pgvector Integration:** An out-of-the-box Ecto/pgvector adapter to store and query embeddings natively.
- **First-Class Citations:** Ensure the trace explicitly captures "Retrieval" spans, linking the model's generated output back to specific `Chunks` via `Citation` metadata.
- **Groundedness & Hallucination Scorers:** Deterministic and LLM-as-Judge scorers to verify outputs are factually grounded.
- **Scrypath Synergy (Optional):** First-class integration with `Scrypath` as a native retrieval engine. Scoria wraps Scrypath queries in `RETRIEVER` spans so they remain observable and evaluable without forcing external vector databases.

### Key Accomplishments
- Added explicit pgvector bootstrap and a shared knowledge test scaffold.
- Built durable corpus, retrieval, citation, and grounding schemas behind `Scoria.Knowledge`.
- Kept Scrypath optional behind a retrieval normalization boundary.
- Projected evidence and grounding signals into the existing operator surface with async loading.
- Added versioned deterministic-first evaluation for citations and grounding.

**Known deferred items at close:** 1 (see STATE.md Deferred Items)

---

## v1.3 Seismograph

**Status:** Planned
**Theme:** SRE, Circuit Breakers & Ecosystem Synergy

### Objectives
Harden Scoria into a production-grade control plane with proactive governance, circuit breakers, and deep `szTheory` ecosystem integration.

### Scope
- **Circuit Breakers & Budgets:** Introduce configurable token and cost budgets per tenant/user that trip guardrails when exceeded.
- **Parapet SLO Integration:** Define SLOs for latency, cost, and eval pass rates for the upcoming `Parapet` SRE layer.
- **Threadline Audit Export:** Clean integration to export sensitive `ToolApproval` and MCP access events into immutable audit logs.
- **Automated Regression Alerts:** Automatically trigger incident workflows via `Chimeway`/`Mailglass` when a CI gate dips below the baseline.
