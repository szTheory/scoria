# Technology Stack

**Project:** Scoria (v1.6 Flightpath)
**Researched:** 2026-05-18

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Phoenix / LiveView | >= 1.7 | Operator Workbench UX | Scoria North Star constraint: must stay Phoenix native. Enables embedded dataset curation and prompt comparison side-by-side. |
| Ecto / PostgreSQL | >= 3.10 | Durable state | Store Prompt versions, Datasets, Evaluation Runs, and Release Gates. |

### Evaluation & Telemetry Patterns
| Technology / Pattern | Version | Purpose | Why |
|----------------------|---------|---------|-----|
| OpenInference Semantics | Current | Trace representation | Aligns Scoria traces with industry standard (similar to `AgentObs` approach), making them easily exportable if needed, while keeping them structured for internal LLM-as-a-judge evals. |
| HTTP VCR / Cassettes | — | Cost-effective CI | Mimics `LLMEval`'s approach of recording API calls to reuse in CI, making regression tests fast, deterministic, and free after the first run. |
| LLM-as-a-Judge | — | Qualitative evaluation | Using another LLM model to assert on faithfulness, relevance, and safety (similar to `Tribunal`). |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Instructor.ex` | >= 0.0.5 | Structured Outputs | Use when Scoria's internal evaluation pipeline needs to parse judgment results (pass/fail/score/reason) reliably into an Ecto Changeset. |
| `Tiktoken` (Elixir) | — | Token Counting | Crucial for tracking prompt size limits and compacting context inside the prompt registry. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| External Platform | Embedded Ecto/LiveView | Langfuse / Braintrust / Arize | **Scoria Non-Goal.** Integrating a hosted platform forces the user out of the Phoenix ecosystem, requires external data privacy considerations, and creates external operational dependencies. |
| CI Eval Runner | Custom ExUnit Tasks | External CI CLI (Promptfoo) | We want to leverage the developer's existing `mix test` infrastructure rather than requiring node/python sidecars. |
| Evaluation Fw | Custom Ecto + Mix Tasks | `Tribunal` / `LLMEval` | While Tribunal and LLMEval are great, Scoria requires deep integration with its own durable Ecto traces and approvals. We should adopt their patterns (cassettes, tags, thresholds) but integrate them natively into Scoria's pipeline. |

## Integration Strategy

\`\`\`elixir
# Example developer CI integration leveraging Scoria Evals
# in test_helper.exs
ExUnit.start(exclude: [:llm_eval])

# in my_prompt_eval_test.exs
@tag :llm_eval
test "v2 prompt does not regress on baseline dataset" do
  dataset = Scoria.Evals.get_dataset!("onboarding_baseline")
  
  # Runs the dataset against the new prompt. Uses cassettes internally.
  report = Scoria.Evals.run_regression!(dataset, prompt_version: "v2.0.1")
  
  assert report.pass_rate >= 0.95
  assert report.hallucination_rate < 0.01
end
\`\`\`

## Sources

- Ecosystem tools analysis: Tribunal, LLMEval, Aludel, AgentObs.
- OpenInference semantic conventions.
