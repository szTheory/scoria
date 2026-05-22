# Architecture Patterns

**Domain:** Embedded Evaluation and Release Operations
**Researched:** 2026-05-18

## Recommended Architecture

The system extends Scoria's existing Ecto-durable core. Traces generated from standard `Scoria.Runtime` operations are curated into `Datasets`. During CI or manual evaluation runs, `Evals` run prompts against datasets, recording `EvalRuns` which serve as evidence for `ReleaseGates`.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Scoria.Registry` | Manages versioned prompt templates, variables, and status (draft, active, archived). | `Scoria.Runtime`, `Scoria.Evals` |
| `Scoria.Evals.Dataset` | Collections of structured inputs, expected outputs, and baseline traces. | `Scoria.Observe`, `Scoria.Evals` |
| `Scoria.Evals.Runner` | Executes evaluation logic, applies VCR cassettes, calls LLM-as-a-judge. | `Scoria.Registry`, `Scoria.Connectors` |
| `Scoria.Evals.Gate` | Governs whether a Prompt/Model configuration can go live based on operator approval and EvalRun evidence. | `Scoria.Workflows` (Approvals), `Scoria.Runtime` |

### Data Flow (The Evaluation Flywheel)

1. **Observe:** App runs normally via `Scoria.Runtime`. Telemetry records traces in `Scoria.Observe`.
2. **Curate:** An operator uses the LiveView dashboard to flag a trace. It is converted into a `Dataset` row.
3. **Iterate:** Developer updates a prompt template in `Scoria.Registry` to a new draft version.
4. **Evaluate:** `Scoria.Evals.Runner` runs the new draft prompt against the curated `Dataset`.
5. **Assert:** The runner records an `EvalRun` containing the metrics (faithfulness, latency, success).
6. **Release:** If metrics meet the required threshold, an Operator is prompted to unlock the `ReleaseGate`. The draft becomes the active version.

## Patterns to Follow

### Pattern 1: VCR / Deterministic Cassettes for CI
**What:** Intercepting HTTP requests from the LLM adapter during testing and saving them to disk (`priv/repo/cassettes`). Future test runs replay the file.
**When:** Whenever running `mix test` or standard CI regression suites.
**Example:**
\`\`\`elixir
Scoria.Evals.Runner.run_with_cassette("v2_prompt_regression", fn ->
  Scoria.Runtime.invoke(prompt_v2, dataset_input)
end)
\`\`\`
*(This mimics existing library patterns from `LLMEval`.)*

### Pattern 2: ExUnit Tag Segregation
**What:** Tagging eval tests to avoid accidental invocation.
**When:** Integrating Scoria into a client application's test suite.
**Example:**
\`\`\`elixir
@tag :scoria_eval
test "Customer support prompt avoids PII disclosure" do ...
\`\`\`

### Pattern 3: Embedded Workbench State
**What:** Keeping workbench and iteration state entirely in LiveView assigns (or temporary Ecto changesets) until explicitly saved.
**Why:** Avoids bloating the database with hundreds of minor prompt tweaks. Only explicitly "saved" or "evaluated" versions become immutable records.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Hidden External Requests in CI
**What:** Running live API calls to OpenAI during every GitHub Actions PR build.
**Why bad:** Destroys CI reliability, inflates API bills, causes random failures due to non-determinism, and breaks on PRs from external contributors who lack API keys.
**Instead:** Mandate cassette recordings. If a cassette is missing, the test fails unless explicitly run with `UPDATE_CASSETTES=true mix test`.

### Anti-Pattern 2: String-only Prompts
**What:** Storing prompts as giant raw strings in code or DB.
**Why bad:** Makes context truncation, variable mapping, and token counting extremely difficult.
**Instead:** Store prompts as structured maps (System Message, Few-Shot Examples, User Template).

## Scalability Considerations

| Concern | At 100 traces | At 10K traces | At 1M traces |
|---------|--------------|--------------|-------------|
| Dataset Queries | Simple `SELECT` | Needs indexing on tags | Materialized views or offline aggregation jobs. |
| CI Eval Runs | Fast inline execution | Concurrent async tasks (`Task.async_stream`) | Distributed eval workers or sampling strategies. |

## Sources

- Scoria `PROJECT.md` Constraints: State truth (Keep auth, grants, approvals durable in Ecto).
- Elixir evaluation testing ecosystem patterns (`Tribunal`, `LLMEval`).
