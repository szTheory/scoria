# Phase 42: Delegated Evidence & Adoption Story - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the bounded handoff lane inspectable and support-truthful on the default Scoria path. Phase 42 should expose delegated lineage clearly through the public runtime detail read model and the normal workflow surface, then align README/docs/source-checked examples to that same runtime-first story.

This phase does not widen Scoria into a general orchestration platform, does not add a second canonical onboarding path, and does not turn bounded handoffs into a heavier notebook/product family than the current milestone warrants.

</domain>

<decisions>
## Implementation Decisions

### Delegated evidence read model
- **D-01:** Scoria should not leave delegated evidence as a split public contract that callers must reconstruct from `handoffs`, child `steps`, checkpoints, and events.
- **D-02:** The public `RunDetail` shape should add one primary curated delegated read model such as `delegated_handoffs`, while preserving the existing lower-level `steps`, `checkpoints`, `events`, `approvals`, and `handoffs` arrays as secondary evidence.
- **D-03:** The delegated read model should be projection-only over existing durable truth. No new durable tables or alternate workflow authority should be introduced for Phase 42.
- **D-04:** Each delegated handoff projection should keep the bounded-handoff contract legible in one place: delegated role, delegated kind, handoff input, projected context, same-run lineage, and the most relevant current status/readback needed for operator inspection.
- **D-05:** Projection rules must be explicit about precedence so the curated delegated object is a stable summary of persisted truth, not a competing workflow engine or speculative interpretation layer.

### Workflow surface presentation
- **D-06:** The workflow tree should remain topology-first and compact. Keep the existing handoff marker and parent/child structure, but do not overload tree rows with full delegation detail.
- **D-07:** The main workflow page should add a dedicated run-level `Delegated Evidence` section rather than forcing operators to infer delegated truth only from the tree or right rail.
- **D-08:** The right rail should remain selected-step detail, not become the primary handoff-inspection surface.
- **D-09:** The delegated-evidence section should use calm summary-first cards: root role -> delegated role, delegated kind, parent step -> child step, status, and a tiny projected-context preview by default.
- **D-10:** Full `handoff_input`, full projected context, and any optional adjunct metadata such as `capability_tags` should sit behind progressive disclosure. Default views should avoid raw JSON walls.
- **D-11:** Phase 42 should not create a notebook-style delegated-work panel unless the existing milestone truth proves handoffs now carry enough dense forensic surface to justify a new product sub-surface. Current recommendation: do not do this.

### Adoption story ordering
- **D-12:** Bounded handoffs should be taught as an advanced extension of the normal runtime-first adoption flow, not as a first-class parallel onboarding path.
- **D-13:** README and checked examples should continue to teach one obvious path first: `identity -> start -> inspect -> resume`, plus exact `session_id` vs `run_id` semantics and `/scoria/workflows/:run_id` as operator evidence.
- **D-14:** README should still signpost bounded handoffs early enough that the feature is discoverable, but the signpost should branch out from the core runtime path rather than compete with it.
- **D-15:** The bounded handoff guide should remain the focused deep dive for the delegation lane, with the README and Phoenix runtime example acting as the canonical high-level adoption story.
- **D-16:** Checked source fragments and adoption-lane assertions should stay layered off one shared runtime-first story. Avoid creating multiple “canonical” example families that can drift.

### Real gap vs defer
- **D-17:** The real Phase 42 gap is not lack of substrate truth; it is that the normal boring operator path still under-projects bounded handoff specifics even though the durable runtime data already exists.
- **D-18:** Phase 42 should therefore ship one thin workflow-inspection shim over existing runtime truth and stop there.
- **D-19:** Work belongs in Phase 42 only when all of the following are true:
  - it fixes a failure in the default runtime-first adoption or workflow-inspection path today
  - it makes already-persisted delegated truth inspectable without raw table reading
  - it can be solved as a thin projection/docs/test alignment pass
  - it does not introduce new public nouns, hidden helper defaults, or a second canonical flow
- **D-20:** Defer anything that mainly adds feature marketing, extra examples, richer orchestration UX, platform-shape expansion, or semantics that make adjunct metadata look more authoritative than the persisted handoff contract.

### DX and ecosystem posture
- **D-21:** Keep the public shape closer to Req/Oban/Ecto-style library ergonomics than to agent-platform magic: one obvious high-level path, deeper evidence available, durable truth underneath.
- **D-22:** For Phoenix/Ecto/Plug idiom, prefer curated read models over forcing callers to manually join normalized workflow rows. This is the least-surprise boundary for an embedded library with operator UI.
- **D-23:** Keep operator UX calm and scan-first, more like LiveDashboard/Oban Web than like a hosted observability workbench. Delegated evidence should be visible, not theatrical.
- **D-24:** Shift low-impact discuss/planning choices left in future GSD work for this lane. The default bias should be:
  - one canonical runtime-first adoption story
  - one thin curated delegated read model over durable truth
  - one compact run-level workflow section before any richer UX is considered
  - escalation to the user only if the choice changes product shape, security boundary, durable truth, or materially different operator behavior

### the agent's Discretion
- Exact field names and helper decomposition for the delegated projection, provided the public default read path becomes one obvious bounded-handoff object and raw evidence remains available underneath.
- Exact component split for the `Delegated Evidence` section, provided the section stays compact, scan-first, and projection-backed rather than becoming a new orchestration cockpit.
- Exact README/doc heading order and wording, provided the runtime-first lane remains canonical and bounded handoffs remain an extension rather than a parallel start path.
- Exact heuristics for previewing projected context, provided previews stay safe, compact, and consistent with the bounded-context product story.

</decisions>

<specifics>
## Specific Ideas

- The right mental model is: Scoria persists normalized workflow truth, then publishes one calm delegated read model the way a Phoenix library would expose a curated public struct rather than asking apps to join internal tables themselves.
- The workflow page should feel like “delegation is inspectable here” rather than “Scoria has a separate multi-agent workstation.”
- The recommended disclosure ladder is:
  - run header summary
  - workflow tree topology
  - dedicated delegated-evidence cards
  - selected-step detail
  - lower notebooks only for heavier evidence families that truly need them
- The docs story should read like: “Here is the normal runtime lane. If one role needs to hand a bounded slice to another, here is the narrow delegation extension.”
- Adjacent ecosystem lesson to preserve: the best products in this space keep one obvious happy path and make deeper truth inspectable, but they do not force the first-time user to choose between multiple competing architectures on page one.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase truth
- `.planning/ROADMAP.md` - Phase 42 scope, success criteria, and plan breakdown.
- `.planning/PROJECT.md` - `v2.0 Relay` thesis, runtime-first product boundary, and narrow bounded-handoff posture.
- `.planning/REQUIREMENTS.md` - `EVID-01` and `ADPT-01`.
- `.planning/STATE.md` - current milestone posture and accumulated bounded-handoff/adoption decisions.
- `.planning/METHODOLOGY.md` - decisive-defaults lens and when to shift choices left.

### Locked prior context
- `.planning/phases/41-bounded-handoff-contract-safety/41-CONTEXT.md` - locked handoff contract, projected-context safety boundary, and Phase 41 vs Phase 42 split.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md` - runtime-first public API posture and curated public inspection rules.
- `.planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md` - one obvious adoption path and operator-evidence story.
- `.planning/phases/18-add-executable-adoption-flow-guards/18-CONTEXT.md` - executable docs/source guard philosophy and default adoption lane posture.
- `.planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md` - operator-surface principles for evidence-heavy embedded UX.
- `.planning/phases/29-external-runtime-observability-and-operator-ux/29-CONTEXT.md` - calm operator-grade dashboard posture and progressive inspection patterns.

### Project-local research and design guidance
- `.planning/memory/bounded-handoff-productization-lessons.md` - projected context as product boundary and support truth as product value.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops and control-plane lessons.
- `prompts/scoria-gsd-kickoff.md` - Scoria product vision and operator-grade UX framing.
- `prompts/scoria-brand-book-deep-research.md` - calm field-engineer brand and anti-platform-sprawl guidance.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, embedded dashboard, operator-first DX.

### Current runtime and workflow surfaces
- `lib/scoria/runtime.ex` - public runtime facade and handoff start/readback surface.
- `lib/scoria/runtime/run_detail.ex` - current public detail DTO that should gain the primary delegated read model.
- `lib/scoria/workflows/handoff.ex` - durable handoff row shape and adjunct metadata boundaries.
- `lib/scoria_web/live/workflow_live/show.ex` - workflow page composition and current evidence layout.
- `lib/scoria_web/components/workflow_tree_component.ex` - current topology-first workflow tree.
- `lib/scoria_web/components/runtime_detail_drawer_component.ex` - existing scan-first runtime detail UI posture.

### Support-truth docs and verification
- `README.md` - current public adoption story and bounded-handoff signpost.
- `docs/phoenix_runtime_example.md` - canonical runtime-first host-app flow.
- `docs/bounded_handoffs.md` - bounded handoff guide and inspectability promise.
- `lib/mix/tasks/test.adoption.ex` - canonical adoption verification lane.
- `test/scoria/adoption_surface_test.exs` - docs/public-surface assertions.
- `test/scoria/handoff_example_source_test.exs` - bounded-handoff checked-fragment alignment.
- `test/support/scoria/adoption_example.ex` - canonical checked fragments.
- `test/scoria/runtime_test.exs` - bounded handoff facade and contract coverage.
- `test/scoria/runtime_view_test.exs` - curated runtime detail and evidence projection expectations.
- `test/scoria_web/live/workflow_live_test.exs` - workflow surface behavior and evidence rendering expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Runtime.RunDetail` already centralizes the curated public readback seam and is the correct place to add a primary delegated projection.
- The runtime substrate already persists enough truth for a thin read-model shim: handoff rows, parent/child steps, projected context, checkpoints, and events all exist today.
- `ScoriaWeb.WorkflowLive.Show` already supports a layered evidence page with strips, tree, detail pane, and lower sections; delegated evidence can fit that existing composition without a new route family.
- The current adoption lane already has executable guards around README/docs/checked fragments, which means support-truth alignment can stay source-backed rather than prose-only.

### Established Patterns
- Scoria prefers durable Ecto truth plus curated DTOs over projection-only UI state or raw schema dumps.
- Public runtime and adoption surfaces teach one obvious path first, with advanced capability guides branching off later.
- Operator UI in Scoria is evidence-first and relatively calm; dense notebook-style treatments are reserved for evidence families that truly need them.

### Integration Points
- The delegated projection work should center on `lib/scoria/runtime/run_detail.ex`, the workflow LiveView and components, and the runtime/detail test suites.
- Support-truth alignment should center on `README.md`, `docs/bounded_handoffs.md`, checked example fragments, and `mix test.adoption` assertions.
- Phase 42 should avoid creating new helper APIs or route families unless the existing runtime-first/operator-evidence path proves insufficient after the thin shim lands.

</code_context>

<deferred>
## Deferred Ideas

- Turning delegated evidence into a notebook-style orchestration sub-surface with heavier forensic panels.
- Adding multiple stronger example families, helper APIs, or onboarding branches beyond the current runtime-first story and bounded-handoff guide.
- Promoting `capability_tags` or similar adjunct metadata into a more authoritative policy/capability contract than Phase 41 allowed.
- Broader multi-agent/orchestration UX that changes Scoria’s product shape from bounded delegation toward a platform surface.
- Any follow-on work that proves valuable only after Phase 43’s canonical adoption proof or real adopter confusion data.

</deferred>

---

*Phase: 42-delegated-evidence-adoption-story*
*Context gathered: 2026-05-24*
