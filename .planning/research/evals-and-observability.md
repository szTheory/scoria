# Research: AI Evaluations, Tracing, and Observability in Phoenix (Scoria)

**Project:** Scoria
**Domain:** AI Ops, Observability, and Evaluation Layer
**Confidence:** HIGH (Based on OpenInference specifications, industry-standard AI platforms like Braintrust/Arize, and Elixir/OTP architecture principles)

## Executive Summary
For Phoenix applications deploying LLM agents, basic logging is insufficient. Multi-step LLM operations (retrieval, tool calling, guardrails, LLM interactions) require structured, deeply nested observability. By combining OpenInference span standards with an Ecto-native trace store and a LiveView operator UI, Scoria can provide a "batteries-included" observability and evaluation flywheel. This document outlines the architectural approach for trace storage, standardized span vocabularies, dataset management, and evaluation modalities.

---

## 1. Tracing & Observability Architecture

### OpenInference Standards
OpenInference is a semantic convention specification built on top of OpenTelemetry (OTel) explicitly designed for AI applications. Scoria should adopt its vocabulary natively:

*   **Span Kinds:** `LLM`, `AGENT`, `CHAIN`, `TOOL`, `RETRIEVER`, `RERANKER`, `EMBEDDING`, `GUARDRAIL`, and `EVALUATOR`.
*   **Key Attributes:** 
    *   `llm.model_name`, `llm.system` (provider).
    *   Flattened lists for IO: `llm.input_messages`, `llm.output_messages`.
    *   Usage: `llm.token_count.prompt`, `llm.token_count.completion`, `llm.token_count.total`.
    *   `input.value`, `output.value` for tool and agent steps.

### Ecto-Native Trace Implementation
Instead of forcing a heavy external dependency (like Datadog or Langfuse) on day zero, Scoria should provide a local Ecto store for traces, optimized for LiveView inspection.

**Schema Design:**
*   `ai_traces`: Represents a full run/workflow. Contains `workflow_name`, `actor_id`, `tenant_id`, total latency, status.
*   `ai_spans`: Belongs to a trace. Contains `trace_id`, `parent_span_id`, `span_kind` (mapped to OpenInference), `start_time`, `end_time`, `input_preview_redacted`, `output_preview_redacted`, token usage, cost.
*   `ai_span_events`: For streaming deltas, tool approvals, and runtime interruptions.

**Data Flow:**
1.  Runtime emits standard Erlang `:telemetry` events (e.g., `[:scoria, :llm, :request, :stop]`).
2.  A telemetry handler attached by `Scoria.Observe` transforms these into OpenInference-compliant span maps.
3.  Asynchronous Oban jobs (or lightweight OTP GenServers) batch-insert spans into the Ecto tables to avoid blocking the main chat/agent execution process.
4.  **Redaction:** A strict redaction policy (stripping PII, secrets, API keys) must be applied *before* the Ecto `insert` or OTel export.

---

## 2. Evaluation Strategy

Evals are the core engine for preventing AI regressions. They run in three contexts: Unit tests (deterministic), CI pipelines (offline suites), and Production (online monitoring).

### Deterministic Evaluations
**What they are:** Hard-coded, predictable assertions run against model outputs or tool calls.
**When to use:** CI gates, tool-choice testing, JSON schema validation.
**Implementation:** Pure Elixir functions.
*   *Exact Match / Regex:* Refusals contain the exact string "I cannot assist with that".
*   *Schema Validation:* The output is valid JSON that matches the Ecto schema for `RefundCustomer`.
*   *Tool Execution:* Asserting that the `lookup_order` tool was requested by the LLM.
**Pros:** Fast, cheap, 100% reliable, immune to drift.

### LLM-as-Judge Evaluations
**What they are:** Using a separate (often stronger) LLM model to score the output of the subject LLM based on a rubric.
**When to use:** Subjective quality checks like helpfulness, tone, safety, or groundedness (are claims backed by citations?).
**Implementation:** A separate `LLM` span configured as an `EVALUATOR` kind. It requires:
*   `judge_model` (e.g., `gpt-4o`).
*   `rubric_version` (immutably stored).
*   Inputs: The retrieved context + the subject's answer.
**Pros:** Scales to evaluate thousands of traces automatically; handles nuanced semantic checks.
**Cons / Pitfalls:** Prone to "judge drift," bias, and API costs. Must be regularly calibrated against human baselines.

---

## 3. Dataset Management & Flywheel

A standalone evaluation suite is useless without real-world test cases. Scoria's killer feature is its integrated LiveView UI that turns production failures into regression tests.

### The Eval Flywheel
`Capture Trace` -> `Identify Failure` -> `Promote to Dataset` -> `Annotate Expected Output` -> `Run CI Eval against Candidate` -> `Deploy`

### Native Ecto Dataset Storage
To support offline and online evals, datasets must be treated as versioned, immutable assets in Ecto.

**Schema Design:**
*   `ai_datasets`: `name`, `version`, `description`, `owner_id`. (e.g., `support_refunds@v3`).
*   `ai_dataset_items`:
    *   `input`: JSON map of the user messages, context, and tenant state.
    *   `expected`: JSON map of the "golden" response, required tool calls, or specific criteria.
    *   `metadata`: Tags, difficulty.
    *   `source_trace_id`: Foreign key pointing back to the production trace that spawned this test case.

**LiveView UX (The "Shape of AI"):**
In the Scoria LiveView Trace Explorer, when an operator views a trace with a bad LLM response or incorrect tool call, they click a **"Promote to Dataset"** button. This opens a modal where they can edit the `input` (stripping unnecessary context) and define the `expected` rubric. This seamlessly bridges production observability with CI reliability.

---

## 4. Pitfalls & Engineering Warnings

| Pitfall | Consequence | Mitigation in Scoria |
| :--- | :--- | :--- |
| **Storing raw PII indefinitely** | Compliance violations (GDPR/SOC2) and data leaks via the LiveView UI. | Implement redaction at the telemetry ingestion boundary. Use retention policies to scrub `raw_payloads` after 7 days while keeping aggregate span data. |
| **LiveView stream bottleneck** | Rendering every individual token delta crashes the client or spikes CPU. | Coalesce token deltas every N ms or N characters in the LiveView socket state. |
| **Nondeterministic CI failures** | LLM-as-judge scores fluctuate, failing PRs randomly. | Expose a `regression_tolerance` (e.g., pass if within 2% of baseline). Snapshot judge versions permanently. |
| **"God Package" architecture** | Users abandon Scoria because it forces them to adopt a heavy dependencies they don't need. | Decouple `scoria_observe` (traces) from `scoria_eval`. Expose a `Mix.install` generator that wires up only what's needed. |

## Conclusion
By standardizing around OpenInference schemas and embedding the trace and dataset storage directly into Ecto, Scoria provides a professional, "operator-grade" control plane for Elixir/Phoenix teams. It eliminates the need for expensive third-party SaaS tools to achieve baseline AI observability and regression testing.