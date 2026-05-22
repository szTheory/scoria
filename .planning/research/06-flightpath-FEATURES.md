# Feature Landscape

**Domain:** Embedded LLM Evaluation & Prompt Management
**Researched:** 2026-05-18

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Prompt Registry & Versioning** | Developers need a single source of truth for prompts, independent of code deployment cycles. | Medium | Must handle variable interpolation, role mappings, and token estimations. |
| **ExUnit CI Integration** | Teams need to verify LLM changes don't break expected application behavior during automated CI. | Medium | Requires `mix test` integration, likely via ExUnit tags. |
| **VCR / Cassette Recording** | CI test runs shouldn't cost money or hit rate limits for identical deterministic assertions. | High | Must accurately hash the context and capture multi-turn responses. |
| **Trace-to-Dataset Curation** | The ability to take a real production trace and say "save this as a baseline test case". | Medium | Closes the loop from production observability to offline testing. |

## Differentiators

Features that set Scoria apart from generic tools or external hosted platforms.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Approval-to-Release Gates** | Operators can enforce a policy that a new prompt version *cannot* be used in production until an Evaluation Run passes and an Operator clicks "Approve". | Medium | Relies heavily on Scoria's existing `v1.1 Caldera` and `v1.5 Switchyard` approval lineage. |
| **Embedded LiveView Workbench** | A visual playground to compare Prompt V1 vs Prompt V2 side-by-side using curated datasets, strictly within the local Phoenix app. | High | Eliminates the need to copy-paste production PII into external tools like OpenAI Playground. |
| **LLM-as-a-Judge Ecto Persistence** | Evaluations aren't just logs; they are durable records linked to the specific canonical runtime identity and tenant. | Low | Leverages existing Scoria primitives. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Hosted API for Eval Telemetry** | Scoria is not Braintrust or Langfuse. We do not accept telemetry over HTTP from other apps. | Keep state fully internal via Ecto and `Scoria` context functions. |
| **Automated Prod Rollouts** | Auto-promoting prompts based purely on AI evaluations is dangerous. | Stop at "Approval Gate required". AI provides evidence, humans provide approval. |
| **Fine-tuning Pipeline** | Scoria shouldn't attempt to orchestrate LoRA or model fine-tuning directly. | Provide a generic `export_dataset_to_jsonl` function and stop there. |

## Feature Dependencies

```text
Prompt Registry → LiveView Workbench (Workbench needs prompts to edit)
Trace Observability → Trace-to-Dataset Curation (Datasets need traces)
Trace-to-Dataset Curation → Evaluation CI Runs (CI needs data to run against)
Evaluation CI Runs → Approval-to-Release Gates (Gates need evidence to approve)
```

## MVP Recommendation

Prioritize for `v1.6 Flightpath`:
1. **Prompt Registry & Versioning** (Ecto backed, basic API).
2. **Trace-to-Dataset Curation** (Take existing traces and promote them to durable Datasets).
3. **CI Regression Task** (A `mix` task or ExUnit integration with VCR cassettes to run datasets against new prompts).
4. **Approval Gate** (A simple flag on prompt versions that requires an explicit flip before `Scoria.Runtime` will serve it).

Defer: Advanced multi-model side-by-side LiveView workbenches. Start with the data primitives and CI integration first, leaving heavy UI comparison for a fast follow.

## Sources

- Scoria North Star mandates (`MILESTONE-ARC.md` and `PROJECT.md`).
- Evaluation ecosystem observations (Tribunal, Aludel).
