# Phase 46: Operator evidence and verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `46-CONTEXT.md`.

**Date:** 2026-05-25
**Phase:** 46-operator-evidence-and-verification
**Mode:** discuss-all + research synthesis
**Areas analyzed:** operator surface ownership, evidence density, provenance contract, verification lane, ecosystem lessons

## Inputs Reviewed

### Local project context
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/phases/44-semantic-cache-contract-and-persistence/44-CONTEXT.md`
- `.planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md`
- `.planning/research/SUMMARY.md`
- `.planning/research/liveview-operator-ux.md`
- `.planning/research/evals-and-observability.md`
- `.planning/research/elixir-ai-ecosystem.md`
- `prompts/scoria-brand-book-deep-research.md`
- `prompts/phoenix-ai-lib-deep-research.md`
- `prompts/scoria-gsd-kickoff.md`
- `prompts/sztheory-elixir-dna.md`

### Code seams reviewed
- `lib/scoria/runtime.ex`
- `lib/scoria/runtime/run_detail.ex`
- `lib/scoria/workflows/runtime.ex`
- `lib/scoria/semantic_cache.ex`
- `lib/scoria/semantic_cache/entry.ex`
- `lib/scoria/semantic_cache/entry_event.ex`
- `lib/scoria_web/live/workflow_live/show.ex`
- `lib/scoria_web/components/workflow_detail_panel_component.ex`
- `lib/scoria_web/components/runtime_detail_drawer_component.ex`
- `lib/mix/tasks/test.adoption.ex`
- `test/scoria/runtime/semantic_fast_path_test.exs`
- `test/scoria/semantic_cache/lookup_test.exs`
- `test/scoria/semantic_cache/invalidation_test.exs`
- `test/scoria_web/live/workflow_live_test.exs`

## Research Tracks

### Operator surface shape
- Compared:
  - workflow page as canonical deep-inspection surface
  - runtime surface as canonical surface
  - symmetric deep detail on both
- Conclusion:
  - workflow page should remain canonical deep-inspection surface
  - runtime surface should stay summary-first with strong deep links

### Verification lane
- Compared:
  - fold proof into `mix test.adoption`
  - dedicated semantic-fast-path checked lane
  - full-suite-only proof posture
- Conclusion:
  - semantic proof should ship as a dedicated named lane, preferred command `mix test.semantic_fast_path`

### Ecosystem and product-shape lessons
- Reviewed lessons from:
  - Langfuse
  - LangSmith
  - Braintrust
  - Arize Phoenix / OpenInference
  - OpenAI Agents SDK
  - Phoenix LiveView / Ecto component and async patterns
- Conclusion:
  - Scoria should borrow provenance loops, progressive disclosure, and trace-to-dataset discipline
  - Scoria should avoid hosted-platform shape drift, duplicated evidence surfaces, and magical cache UX

## Key Recommendation Summary

1. Preserve one semantic-evidence contract across runtime, workflow, docs, and verification.
2. Keep the workflow run page as the canonical semantic notebook.
3. Keep the runtime surface compact: verdict, fallback, scope, reason, and deep links.
4. Show fallback as positive proof that Scoria checked and intentionally declined reuse.
5. Ship a dedicated semantic proof lane and document it as the canonical support-truth command.
6. Shift these defaults left in future GSD work unless a later phase changes product shape or blast radius.

## External References Consulted

- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html`
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html`
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html`
- `https://langfuse.com/docs/observability/data-model`
- `https://langfuse.com/docs/evaluation/experiments/datasets`
- `https://docs.langchain.com/langsmith/observability-studio`
- `https://docs.langchain.com/langsmith/annotation-queues`
- `https://www.braintrust.dev/docs/observe`
- `https://www.braintrust.dev/docs/observe/examine-traces`
- `https://www.braintrust.dev/docs/evaluate`
- `https://arize.com/docs/phoenix/evaluation/llm-evals`
- `https://openai.github.io/openai-agents-python/tracing/`

## Deferred During Discussion

- Duplicating deep semantic detail across runtime and workflow surfaces
- Analytics-heavy cache dashboards before the evidence notebook is shipped
- Hosted-style observability product features
- Broader queue/review workflows beyond direct Phase 46 proof needs

