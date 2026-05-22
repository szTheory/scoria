# Research Summary: v1.6 Flightpath

**Domain:** Embedded LLM AI Evaluation, Prompt Lifecycle, and CI Regression
**Researched:** 2026-05-18
**Overall confidence:** HIGH

## Executive Summary

The Elixir ecosystem's approach to LLM prompt management and evaluation is rapidly formalizing. We see a split between local, workflow-centric CI testing (using libraries like `Tribunal` and `LLMEval`) and operational prompt/model iteration (using `Aludel` and `PromptVault`). Observability is converging around OpenInference telemetry via `AgentObs`. 

For Scoria's `v1.6 Flightpath`, adopting a hosted platform like Langfuse or Braintrust conflicts with the product's embedded, Ecto-native North Star. Instead, Scoria should synthesize the community's best ideas—LiveView prompt workbenches, ExUnit CI integration with cassette recording, and structured outputs—into an embedded registry and evaluation pipeline. 

By building an Ecto-backed prompt registry and tying it to Scoria's existing trace observability and approval workflows, Scoria can provide a closed-loop evaluation flywheel: real traces become curated datasets, datasets drive offline eval regressions, and successful evals unlock the "approval-to-release" gate for new prompt versions.

## Key Findings

**Stack:** Native Ecto-backed registry for state, combined with `ExUnit` tags, VCR-style cassette recording for CI efficiency, and OpenInference telemetry semantics.
**Architecture:** Close the loop between Traces -> Datasets -> Evals -> Registry Gates, keeping state durable in PostgreSQL and operator UX in standard Phoenix LiveView.
**Critical pitfall:** Allowing evaluation pipelines to run unbounded expensive API calls during CI/CD, creating flakiness and high costs. (Requires VCR/cassettes or mock capabilities).

## Implications for Roadmap

Based on research, the suggested phase structure for `v1.6 Flightpath`:

1. **Phase 1: Ecto-Backed Prompt Registry & Lifecycle** 
   - Addresses: Versioned prompts, variable interpolation, token tracking.
   - Avoids: Hardcoding prompts in code which breaks the ability to evaluate and update them dynamically.

2. **Phase 2: Trace-to-Dataset Curation (LiveView)**
   - Addresses: Operator storytelling from trace -> dataset.
   - Avoids: Needing an external tool like Arize to manually tag and export good/bad traces.

3. **Phase 3: CI/CD Regression & Evaluation Framework**
   - Addresses: CI-friendly workflows to prove changes are safe before rollout, using ExUnit assertions and cassettes to save costs.
   - Avoids: Non-deterministic and expensive CI runs.

4. **Phase 4: Release Gates & Approvals**
   - Addresses: Approval-to-release gates based on baseline comparisons and dataset benchmarks.
   - Avoids: Pushing prompts to production without explicit governance.

**Phase ordering rationale:**
- The prompt registry must exist before datasets can be mapped to prompt versions. Datasets must exist before meaningful CI regression can happen against historical production data. Release gates depend on all the above to provide the actual "gate" mechanism.

**Research flags for phases:**
- Phase 3: High research flag. Needs validation on the DX of embedding LLM cassettes in standard ExUnit runs without making the test suite painfully slow.
- Phase 2: Moderate research flag. What makes a "dataset" in Scoria? We must design the Ecto schemas to support multi-turn chats, RAG context, and tool uses natively.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Elixir evaluation ecosystem tools (Tribunal, LLMEval, Aludel) provide very clear, successful patterns. |
| Features | HIGH | Table stakes are very clear: cassettes for CI, trace curation for datasets, LiveView for workbench. |
| Architecture | HIGH | Aligns perfectly with Scoria's existing durable workflow and LiveView operator patterns. |
| Pitfalls | HIGH | Ecosystem consensus is strong on the dangers of non-deterministic CI runs and unmanaged prompt drifts. |

## Gaps to Address

- **LLM-as-a-judge specifics:** Do we bundle an LLM-as-a-judge evaluation prompt within Scoria itself or expect the user's application to define the judgment criteria?
- **Dataset Storage:** Should datasets be stored strictly in Ecto, or support exporting/importing to formats like JSONL for integration with external fine-tuning tools?
