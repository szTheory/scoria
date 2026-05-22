# Phase 25: CI/CD Regression & Evaluation Framework - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Give Scoria a deterministic, CI-friendly evaluation execution layer that turns the prompt registry and sealed datasets into ordinary regression gates for developers, while also supporting explicit live judge runs and durable result records for future release approvals.

This phase is about the execution, fixture, and persistence shape of the eval flywheel. It should make offline regression tests boring inside normal Phoenix/ExUnit workflows; provide explicit, non-default live evaluation commands; and persist enough run evidence that Phase 26 can compare candidate vs baseline prompt versions without re-inventing run truth.

It does not broaden into a hosted eval service, broad benchmark marketplace behavior, or a heavy standalone experiment product. It stays embedded, Phoenix-first, Ecto-native, and operator-grade.

</domain>

<decisions>
## Implementation Decisions

### Offline regression developer flow
- **D-01:** Deterministic offline evals should run as ordinary ExUnit tests inside `mix test`, not as a separate default runner.
- **D-02:** Scoria should layer optional test selection on top of normal ExUnit semantics:
  - `@moduletag :eval`
  - stable dataset-oriented tags for targeted reruns
  - file/module reruns should keep working with normal `mix test` ergonomics
- **D-03:** `mix test` must remain fully offline for this lane:
  - no live network calls
  - no judge-model calls
  - no hidden fixture recording
- **D-04:** The default CI contract should continue to treat eval regressions like ordinary test regressions: red test, failing build, normal ExUnit output.

### Replay artifact strategy
- **D-05:** Offline regression artifacts should be committed, replay-only baseline fixtures tied to immutable prompt and sealed dataset versions.
- **D-06:** Scoria should prefer fixture capture at the provider-response seam rather than raw opaque HTTP dumps whenever possible:
  - normalize irrelevant transport noise
  - keep the artifact aligned to Scoria’s actual runtime/eval boundary
  - preserve deterministic replay without over-coupling to provider headers and IDs
- **D-07:** CI must never auto-record or auto-refresh replay artifacts. Missing or mismatched artifacts should fail loudly.
- **D-08:** Refreshing or re-recording replay artifacts is an explicit maintainer workflow only, never an implicit test fallback.
- **D-09:** Replay artifacts must be keyed by immutable execution identity, not mutable labels. At minimum the keying model should include:
  - prompt version
  - sealed dataset version
  - eval spec version
  - provider/model identity when relevant

### Eval spec and run model
- **D-10:** Scoria should use a split eval model:
  - `EvalSpec` is the immutable baseline contract
  - `EvalRun` captures the resolved execution snapshot of one run
- **D-11:** `EvalSpec` should lock the stable comparison contract:
  - subject reference
  - dataset snapshot/version
  - scorer definitions
  - threshold policy
  - eval mode
  - rubric/judge prompt versions when applicable
- **D-12:** `EvalRun` should snapshot the resolved execution environment actually used:
  - provider/model
  - runtime defaults
  - replay/offline mode
  - cassette/fixture provenance
  - judge model if live
  - explicit overrides used for this run
- **D-13:** The planner should avoid a forever-untyped catch-all `rubric` blob. Prefer typed Ecto embeds or similarly explicit structured fields for subject, scorers, thresholds, and execution policy.
- **D-14:** Mutable aliases like “current dataset” or “default judge model” must not be treated as durable eval truth.

### Mix task and command shape
- **D-15:** `mix scoria.eval` should remain the explicit live-evaluation lane, primarily for judge-based or otherwise online scoring workflows.
- **D-16:** Offline deterministic regression remains under `mix test`; Scoria should not hide the primary regression gate behind `mix scoria.eval`.
- **D-17:** Maintenance responsibilities should use explicit namespaced tasks instead of overloading `mix scoria.eval`. Recommended direction:
  - `mix scoria.eval` for live evaluation runs
  - `mix scoria.eval.refresh` (or equivalent) for replay-artifact refresh/record workflows
  - future reporting/inspection tasks may be added under the same namespace if needed
- **D-18:** Networked or mutating commands must be obvious from the command name and help text. Principle of least surprise matters more than minimizing task count.

### Result durability and release-gate signal
- **D-19:** `EvalRun` persistence should follow a hybrid model:
  - immutable run header facts on the run row
  - per-item evidence on associated rows
  - derived comparison/projection views for UI and reporting
- **D-20:** `EvalRun` must persist the facts Phase 26 will need to trust later:
  - executed prompt version reference
  - dataset/version reference
  - eval spec/version reference
  - runner mode (`offline_replay`, `live_judge`, or equivalent)
  - replay artifact provenance
  - aggregate pass/fail counts
  - aggregate latency/cost metrics as appropriate
  - threshold verdict
  - explicit baseline comparison anchor when a release decision depends on it
- **D-21:** Per-item evidence should persist separately from the run header and include:
  - dataset item reference
  - pass/fail or numeric score
  - concise explanation/reason
  - scorer kind
  - scorer/judge model identity when applicable
  - rubric version
  - evidence/provenance refs back to fixture, trace, or other durable source
- **D-22:** Scoria should not persist giant opaque “everything blob” run payloads as the primary truth model. Durable facts belong in explicit fields and associations; rich UI views can be projected from them.
- **D-23:** Scoria should not persist raw chain-of-thought style reasoning. Store concise explanations and durable evidence references instead.

### Canonical eval persistence boundary
- **D-24:** Phase 25 planning must resolve the current split between older eval persistence shapes and the newer Phase 24 `ai_eval_datasets` path. There should be one canonical dataset/eval persistence model going forward.
- **D-25:** The Phase 24 `ai_eval_datasets` / `ai_eval_dataset_items` path is the stronger starting point for the current milestone because it already reflects the open/sealed dataset model and current code usage.
- **D-26:** If older eval schemas remain temporarily for compatibility, the planner must treat convergence and truth-boundary cleanup as part of this phase rather than allowing long-term split-brain eval storage.

### Shift-left defaults and interruption policy
- **D-27:** Low-impact eval framework choices should be shifted left into Scoria defaults and future GSD assumptions rather than repeatedly asking for them.
- **D-28:** Shift-left defaults should include:
  - offline evals live in `mix test`
  - replay-only CI
  - explicit refresh tasks
  - immutable keying by prompt/dataset/spec version
  - typed spec/run split
  - low-cardinality aggregate metrics with drill-down evidence rows
- **D-29:** Human interruption should be reserved for materially consequential choices only:
  - introducing live-network behavior into default test lanes
  - changing the canonical truth boundary for eval persistence
  - loosening replay determinism or baseline immutability
  - expanding Phase 25 into hosted or cross-environment product scope

### the agent's Discretion
- Exact fixture storage layout and naming convention, provided immutable identity and replay-only semantics remain intact.
- Exact Ecto module names or embeds for scorer/threshold/subject config, provided the split spec/run boundary remains explicit.
- Exact names of maintenance Mix tasks, provided live scoring and fixture refresh remain clearly separated.
- Exact comparison-query/projection strategy for dashboards, provided run header truth and per-item evidence remain durable and inspectable.

</decisions>

<specifics>
## Specific Ideas

- The coherent Phase 25 product shape is:
  - sealed datasets from Phase 24
  - immutable prompt versions from Phase 23
  - deterministic offline replay in normal ExUnit
  - explicit live judge runs outside the default test path
  - durable run/evidence rows ready for Phase 26 release comparison
- The best Elixir/Phoenix mental model is:
  - ExUnit for default regression truth
  - focused namespaced Mix tasks for explicit maintenance or online behavior
  - Ecto rows as durable truth
  - LiveView/reporting as projection over that truth
- The best long-term fixture seam is not “record every raw HTTP byte forever.”
  It is “commit replayable normalized provider responses at the Scoria boundary, backed by a small contract suite for wire-level confidence.”
- The main footguns to avoid are:
  - hidden live calls inside `mix test`
  - auto-refreshing fixtures in CI
  - mutable aliases in eval specs
  - giant opaque `EvalRun` blobs
  - allowing the older and newer eval persistence paths to drift in parallel

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and project intent
- `.planning/ROADMAP.md` - Phase 25 goal, success criteria, and dependency on Phase 24.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and v1.6 Flightpath thesis.
- `.planning/STATE.md` - current milestone sequencing and shipped baseline through Phase 24.
- `prompts/scoria-brand-book-deep-research.md` - operator-grade, evidence-first, calm control-plane posture.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, Ecto-native, embedded LiveView, zero-surprise DX rules.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem lessons for Phoenix-native AI runtime, eval, and ops tooling.

### Prior locked Scoria decisions
- `.planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md` - durable evidence posture, low-cardinality metrics, and truth-vs-projection discipline.
- `.planning/phases/22-curated-connector-profiles-and-boring-adoption-path/22-CONTEXT.md` - shift-left defaults, one boring default path, and explicit proof-lane philosophy.
- `.planning/phases/23-ecto-backed-prompt-registry-and-lifecycle/23-RESEARCH.md` - immutable prompt versioning and token/runtime considerations.
- `.planning/phases/24-trace-to-dataset-curation-via-liveview/24-RESEARCH.md` - open/sealed dataset model and exact-runtime-shape dataset philosophy.
- `.planning/phases/24-trace-to-dataset-curation-via-liveview/24-SUMMARY.md` - Phase 24 execution boundary and completed dataset curation direction.

### Current code surface
- `lib/scoria/eval.ex` - current eval context surface and dataset/eval-spec operations.
- `lib/scoria/eval/dataset.ex` - current canonical dataset schema used by Phase 24 code.
- `lib/scoria/eval/dataset_item.ex` - current dataset item schema and sealed-dataset validation boundary.
- `lib/scoria/eval/eval_spec.ex` - existing versioned eval spec shape that should be evolved, not bypassed.
- `lib/scoria/eval/eval_run.ex` - current run schema starting point for durable execution records.
- `lib/scoria/eval/score.ex` - current per-item scoring/evidence starting point.
- `lib/mix/tasks/scoria.eval.ex` - current live-eval task stub and naming baseline.
- `test/support/eval_case.ex` - default ExUnit seam for deterministic eval tests.
- `test/mix/tasks/scoria.eval_test.exs` - current expectations around the live-eval task surface.
- `.github/workflows/ci.yml` - current CI lanes and the contract that `mix test` remains a first-class default proof lane.
- `mix.exs` - current dependency set, including Tribunal and Phoenix/Ecto tooling.

### Repo-local research
- `.planning/research/evals-and-observability.md` - offline vs online eval split, trace-to-dataset flywheel, and evaluator evidence model.
- `.planning/milestones/v1.0-phases/04-evaluation-flywheel/04-RESEARCH.md` - earlier eval architecture recommendations and pitfalls.
- `.planning/research/liveview-operator-ux.md` - embedded operator workbench expectations relevant to future eval result UX.

### External standards and adjacent-system guidance
- `https://hexdocs.pm/mix/Mix.Tasks.Test.html` - official `mix test` filters and tag-selection behavior.
- `https://hexdocs.pm/phoenix/testing.html` - Phoenix testing conventions and ExUnit tag ergonomics.
- `https://hexdocs.pm/mix/Mix.Task.html` - Mix task design and namespacing conventions.
- `https://hexdocs.pm/tribunal/exunit-integration.html` - Tribunal’s ExUnit integration posture.
- `https://hexdocs.pm/tribunal/evaluation-modes.html` - Tribunal’s split between ExUnit test mode and broader evaluation modes.
- `https://hexdocs.pm/req/Req.Test.html` - idiomatic request replay/testing seam for Req-based clients.
- `https://hexdocs.pm/req_cassette/ReqCassette.html` - replay/record cassette tooling aligned with Req.
- `https://hexdocs.pm/bypass/Bypass.html` - contract-style HTTP boundary testing in Elixir.
- `https://hexdocs.pm/exvcr/readme.html` - older VCR-style approach and its tradeoffs.
- `https://langfuse.com/docs/evaluation/core-concepts` - experiment/run concepts and offline-vs-online evaluation framing.
- `https://langfuse.com/docs/evaluation/experiments/datasets` - dataset/version thinking for experiments.
- `https://www.braintrust.dev/docs/evaluate/run-evaluations` - CI/offline evaluation workflows.
- `https://www.braintrust.dev/docs/evaluate/compare-experiments` - baseline/candidate comparison expectations.
- `https://docs.langchain.com/langsmith/evaluation-concepts` - eval subject/scorer/run conceptual model.
- `https://arize.com/docs/phoenix/evaluation/llm-evals` - evaluator evidence and operator-facing eval patterns.
- `https://developers.openai.com/api/docs/guides/evaluation-best-practices` - combining deterministic, human, and model-based evaluation with threshold discipline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.EvalCase` already gives Phase 25 the right default seam for ordinary ExUnit-based evals.
- The current CI workflow already encodes Scoria’s “boring default proof lane” posture by treating `mix test` as a standard gate.
- `Scoria.Eval.Dataset` and `Scoria.Eval.DatasetItem` already capture the open/sealed dataset posture that Phase 25 should build on rather than bypass.
- `Scoria.Eval.EvalSpec`, `EvalRun`, and `Score` already provide a usable starting point for versioned specs and durable run evidence.

### Established Patterns
- Scoria repeatedly keeps durable Ecto rows as truth and uses UI or task surfaces as projections over that truth.
- The repo prefers one obvious default lane with explicit secondary lanes for heavier or more specialized verification work.
- Prior phases consistently shift low-impact decisions left and reserve interruption for product-shape or blast-radius changes.
- Operator-grade evidence is favored over hidden mutable state or prose-only guidance.

### Integration Points
- Phase 25 should connect sealed datasets, immutable prompt versions, and eval specs into one canonical eval execution boundary.
- The default offline lane should integrate at the ExUnit/test-helper seam, not invent a parallel truth system.
- Live judge runs and refresh workflows should integrate through explicit Mix tasks and persist back into durable eval rows.
- Result persistence must be shaped so Phase 26 can consume it directly for release gates and approval comparisons.

</code_context>

<deferred>
## Deferred Ideas

- Hosted or multi-environment experiment service behavior.
- Rich benchmark marketplace/catalog features.
- Fully generalized provider-agnostic replay infrastructure beyond what Phase 25 needs for deterministic CI and live judge runs.
- Broad release-approval UI work beyond the run evidence needed to support Phase 26.

</deferred>

---

*Phase: 25-ci-cd-regression-and-evaluation-framework*
*Context gathered: 2026-05-19*
