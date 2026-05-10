# Scoria GSD Kickoff Context

## Project Vision
**Scoria** is a Phoenix-native AI ops layer: a batteries-included framework for building, observing, evaluating, debugging, and governing LLM chat, agents, tools, and MCP workflows.

**Tagline:** Trace the run. Prove the change. Ship the agent.
**Brand Archetype:** The Field Engineer. Grounded, composed, operator-grade, and evidence-based. 

## Core Capabilities to Build
1. **Runtime & Trace Store:** An embedded Ecto store and runtime for capturing traces, spans, and tokens natively within Phoenix apps.
2. **Eval Workbench:** Tools for offline/online evaluations, promoting production traces to datasets, and CI regression gates.
3. **MCP / Tool Governance:** A control plane to manage, authenticate, and audit MCP servers, tools, and prompts.
4. **LiveView Operator UI:** A comprehensive admin dashboard to visualize traces, replay agent loops, compare eval scores, and manage AI costs/budgets.

## Technical Alignment (szTheory DNA)
Scoria must adhere strictly to the **szTheory DNA**:
* **Batteries Included:** A `mix scoria.install` should set up the Ecto tables, telemetry handlers, and LiveView routes.
* **Ecosystem Synergy:** 
  * Integrate with **Sigra** for admin dashboard auth.
  * Emit telemetry and structured events to **Threadline** for audit logs.
  * Provide SLI/SLO hooks for the upcoming **Parapet** observability layer.
* **UI/UX Excellence:** Implement "Shape of AI" and modern interface patterns within the LiveView admin dashboard to handle streaming responses, tool call visualization, and trace trees elegantly.

## GSD Objective
Execute a deep Research -> Plan -> Implement lifecycle to build the foundational MVP of Scoria. Focus on the core data model (Traces, Spans, Evals), the Phoenix integration layer, and the scaffolding of the LiveView operator dashboard.