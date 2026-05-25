# Phase 42: Delegated Evidence & Adoption Story - Research

**Researched:** 2026-05-24 [VERIFIED: current session date]
**Domain:** delegated-lineage inspectability, workflow-surface projection, and runtime-first adoption-story alignment inside the existing bounded handoff lane [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/42-delegated-evidence-adoption-story/42-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: roadmap/context/ui-spec review plus local runtime, LiveView, docs, and test inspection]

## User Constraints

- `v2.0 Relay` is a repo-local formalization milestone, so Phase 42 should research the current Scoria surfaces and gaps rather than reopen broad ecosystem selection. [VERIFIED: .planning/PROJECT.md; .planning/STATE.md]
- Phase 42 must close `EVID-01` and `ADPT-01` without drifting into broader orchestration UX, new durable handoff storage, or a second onboarding path. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/42-delegated-evidence-adoption-story/42-CONTEXT.md]
- The delegated-evidence work should build on the same-run contract already locked in Phase 41, not redefine the substrate. [VERIFIED: .planning/phases/41-bounded-handoff-contract-safety/41-CONTEXT.md; .planning/phases/41-bounded-handoff-contract-safety/41-RESEARCH.md]
- Support truth remains part of product truth, so plans need code, UI, docs, and checked-source coverage together instead of prose-only cleanup. [VERIFIED: .planning/PROJECT.md; .planning/STATE.md; test/scoria/adoption_surface_test.exs]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVID-01 | Developer or operator can inspect delegated lineage, delegated role, delegated kind, and projected context through public run-detail DTOs and the workflow surface. [VERIFIED: .planning/REQUIREMENTS.md] | `Scoria.Runtime.RunDetail` currently exposes only low-level `handoffs` plus `steps`, so callers still have to reconstruct the Phase 41 handoff story manually. Add one curated delegated projection and feed the workflow page from that projection. [VERIFIED: lib/scoria/runtime/run_detail.ex; lib/scoria/runtime.ex; lib/scoria_web/live/workflow_live/show.ex] |
| ADPT-01 | Adoption docs and checked source fragments show how bounded handoffs fit into the normal identity -> start -> inspect -> resume runtime flow for Phoenix apps. [VERIFIED: .planning/REQUIREMENTS.md] | README and docs already teach the runtime-first path, but the bounded-handoff branch still promises inspectability more strongly than the current DTO/UI prove. Align docs and checked fragments to the curated delegated evidence surface without creating a second quickstart. [VERIFIED: README.md; docs/phoenix_runtime_example.md; docs/bounded_handoffs.md; test/support/scoria/adoption_example.ex] |
</phase_requirements>

## Summary

Phase 42 should be executed as the roadmap’s existing three-slice breakdown: first add a curated delegated read model to public runtime detail, then surface that read model on the normal workflow page with a calm run-level section, then align README/docs/checked fragments and explicitly record any remaining adopter-facing rough edge as either closeout work or a deferred follow-up. [VERIFIED: .planning/ROADMAP.md]

The main evidence gap is not missing substrate truth. Phase 41 already persists explicit delegated role, delegated kind, handoff input, parent/child lineage, and bounded projected context under one durable run. The gap is that `RunDetail` still publishes those facts only through raw `handoffs` and generic `steps`, leaving apps and operators to reconstruct the delegated story themselves. [VERIFIED: lib/scoria/runtime/run_detail.ex; test/scoria/runtime_test.exs; .planning/phases/41-bounded-handoff-contract-safety/41-CONTEXT.md]

The workflow page has the same shape problem. `WorkflowLive.Show` renders a topology-first tree and a selected-step replay panel, but there is no dedicated run-level delegated section even though Phase 42 context explicitly wants one. The current screen therefore makes handoff lineage discoverable only indirectly through tree rows and step detail. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; lib/scoria_web/components/workflow_tree_component.ex; lib/scoria_web/components/workflow_detail_panel_component.ex; .planning/phases/42-delegated-evidence-adoption-story/42-UI-SPEC.md]

Support-truth drift is narrow but real. README and `docs/bounded_handoffs.md` correctly keep bounded handoffs as an extension of the runtime-first lane, yet the guide says `Scoria.get_run_detail/1` exposes the needed inspectability while the current public DTO does not provide one curated delegated noun. The docs should branch from the core runtime path and point to the workflow page plus curated delegated evidence, not force readers to infer that raw arrays are the intended public contract. [VERIFIED: README.md; docs/phoenix_runtime_example.md; docs/bounded_handoffs.md; lib/scoria/runtime/run_detail.ex]

**Primary recommendation:** plan Phase 42 as three plans aligned to the roadmap: `42-01` for the curated delegated read model and DTO tests, `42-02` for the run-level delegated workflow section and LiveView behavior, and `42-03` for runtime-first docs/source alignment plus an explicit gap/defer ledger. [VERIFIED: .planning/ROADMAP.md]

## Architecture Patterns

### Pattern 1: Keep normalized durable truth underneath, publish one curated delegated projection on top
**What:** Add a primary `delegated_handoffs`-style projection to `Scoria.Runtime.RunDetail` while preserving raw `steps`, `handoffs`, `events`, and `checkpoints` as secondary evidence. [VERIFIED: .planning/phases/42-delegated-evidence-adoption-story/42-CONTEXT.md; lib/scoria/runtime/run_detail.ex]
**Why:** This matches Scoria’s Phoenix/Ecto posture and keeps public inspectability boring and stable. [VERIFIED: .planning/PROJECT.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]

### Pattern 2: The workflow page should consume curated runtime DTOs for support-truth features
**What:** Build the delegated-evidence section from `Runtime.get_run_detail!/1` assigns rather than adding fresh run-tree joins in the LiveView template. [VERIFIED: lib/scoria/runtime.ex; lib/scoria_web/live/workflow_live/show.ex]
**Why:** Replay provenance already follows this pattern, and it keeps UI behavior coupled to the public DTO contract instead of internal schemas. [VERIFIED: .planning/STATE.md; lib/scoria/runtime/replay_comparison.ex; lib/scoria_web/live/workflow_live/show.ex]

### Pattern 3: Docs should branch bounded handoffs from the runtime-first lane, not compete with it
**What:** Keep `identity -> start -> inspect -> resume` first in README and the Phoenix example, then signpost `Scoria.start_handoff_run/3`, `Scoria.get_run_detail/1`, and `/scoria/workflows/:run_id` as the advanced delegation branch. [VERIFIED: README.md; docs/phoenix_runtime_example.md; docs/bounded_handoffs.md]
**Why:** That is the least-surprise adoption story for an embedded Phoenix library with an operator dashboard. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md; .planning/phases/18-add-executable-adoption-flow-guards/18-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating raw `handoffs` plus `steps` as “good enough” public inspectability
That would technically expose the data while still violating the Phase 42 decision that delegated lineage should be legible in one curated place. [VERIFIED: lib/scoria/runtime/run_detail.ex; .planning/phases/42-delegated-evidence-adoption-story/42-CONTEXT.md]

### Pitfall 2: Putting full delegated detail into tree rows or turning the right rail into a second handoff console
That would add noise, blur component responsibilities, and drift toward platform-like orchestration UX the phase explicitly defers. [VERIFIED: .planning/phases/42-delegated-evidence-adoption-story/42-UI-SPEC.md; .planning/phases/42-delegated-evidence-adoption-story/42-DISCUSSION-LOG.md]

### Pitfall 3: Upgrading README into a second bounded-handoff quickstart
That would create two competing entrypoints and make support-truth drift more likely. [VERIFIED: README.md; .planning/phases/42-delegated-evidence-adoption-story/42-DISCUSSION-LOG.md]

### Pitfall 4: Leaving the final adopter-facing gap implicit
If a rough edge remains after the DTO/UI/docs pass, it needs an explicit closeout or defer record rather than vague “future work” language. [VERIFIED: .planning/ROADMAP.md; .planning/phases/42-delegated-evidence-adoption-story/42-CONTEXT.md]

## Recommended Plan Breakdown

1. `42-01`: add the curated delegated runtime projection, explicit precedence/linkage rules, and DTO regression tests.
2. `42-02`: render a run-level delegated evidence section on `/scoria/workflows/:run_id` with summary-first cards, progressive disclosure, and LiveView coverage.
3. `42-03`: align README/docs/checked fragments to the runtime-first delegation story and record any remaining adopter-facing gap as closeout or deferred follow-up.
