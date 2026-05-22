# Domain Pitfalls

**Domain:** LLM Evaluation, Prompt Lifecycle, CI Regression
**Researched:** 2026-05-18

## Critical Pitfalls

Mistakes that cause rewrites, abandonment, or major production issues.

### Pitfall 1: Flaky CI Deployments due to LLM Non-Determinism
**What goes wrong:** A PR contains a minor code change, but the CI pipeline fails because an LLM evaluation test arbitrarily returned a slightly different phrasing that failed a regex assertion.
**Why it happens:** LLMs are non-deterministic. Traditional binary assertions (exact match, regex) fail randomly on valid answers.
**Consequences:** Developers lose trust in the CI suite and disable the evaluation tests entirely.
**Prevention:** 
1. Use **Cassettes (VCR)** to lock responses for regression tests.
2. Use **LLM-as-a-judge** (with structured outputs) rather than fragile string assertions for dynamic tests.
**Detection:** Flaky test reports in CI that pass on re-run without code changes.

### Pitfall 2: Environment Drift for Prompts
**What goes wrong:** The prompt in staging is different from the prompt in production, but there is no version control linking the two. A fix verified in staging breaks in prod.
**Why it happens:** Prompts are stored in the database without immutable versioning, allowing in-place edits.
**Consequences:** Regression testing becomes impossible because the baseline is a moving target.
**Prevention:** Implement strict **append-only immutable versioning** for prompts. Once a prompt is used in an evaluation or production run, it can never be modified, only superseded by a new version.

### Pitfall 3: Platform Drift (The "LangSmith" Trap)
**What goes wrong:** The Scoria system attempts to build a full-scale external telemetry collector, trying to accept HTTP requests from other services.
**Why it happens:** Chasing features of massive enterprise AI platforms.
**Consequences:** Violates Scoria's North Star. Adds massive operational complexity (auth, rate limiting, scalable ingestion) that normal Phoenix teams do not want.
**Prevention:** Stick rigidly to Ecto and local BEAM telemetry. Scoria evaluates what happens *inside* its own Phoenix application, nothing more.

## Moderate Pitfalls

### Pitfall 4: Expensive CI Bills
**What goes wrong:** A test suite containing 50 eval cases runs on every PR, push, and commit across a team of 10 developers, racking up thousands of dollars in LLM API fees.
**Prevention:** Require explicit `@tag :eval` exclusion by default, or strictly enforce VCR cassettes for all CI runs. Only run live evals on `main` branch merges or via manual triggers.

### Pitfall 5: Prompt Token Overflow
**What goes wrong:** An operator updates a prompt via the UI, adding context. In production, this pushes the total context window over the model's limit, causing hard crashes.
**Prevention:** The Prompt Registry must calculate estimated token counts (via Elixir `Tiktoken` port) and warn/block saving if the prompt exceeds the configured model's context window.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Prompt Registry | Allowing in-place edits to active prompts. | Enforce immutable versions. Edits create new drafts. |
| Trace-to-Dataset | Hardcoding specific user PII into shared datasets. | Introduce redaction/anonymization hooks before saving a trace to a dataset. |
| CI Runner | Test suite slows to a crawl. | Use `Task.async_stream` to parallelize evaluations, and rely on cassettes to avoid network latency. |
| Release Gates | Operator rubber-stamping. | Surface visual delta (diff) of prompt changes and clear pass/fail metrics on the approval UI. |

## Sources

- Ecosystem lessons from `Promptfoo`, `Langfuse`, and Elixir evaluation libraries.
- Scoria North Star Constraints.
