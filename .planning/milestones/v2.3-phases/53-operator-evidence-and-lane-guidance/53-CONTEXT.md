# Phase 53: Operator evidence and lane guidance - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the runtime-to-handoff example easy to inspect from existing operator-facing surfaces and make adopter docs explain when to stay on the default runtime lane versus escalate into bounded handoff. This phase covers requirements `EVID-01` and `DOCS-01`: operator evidence projection and lane-decision guidance. It does not create the canonical runtime-to-handoff proof command or closeout proof lane; that remains Phase 54.

</domain>

<decisions>
## Implementation Decisions

### Operator evidence projection
- **D-01:** Tighten the existing curated `DelegatedEvidenceComponent` on `/scoria/workflows/:run_id`; do not introduce a new public API, raw table readback path, or separate notebook-style delegated forensics surface in Phase 53.
- **D-02:** "Easy to inspect" means one stable delegated-evidence anchor that shows the three scan-depth evidence dimensions together: same-run lineage, bounded projected-context summary, and delegated outcome/status.
- **D-03:** Empty, pending, and completed delegated states should remain explicit. Empty state should reinforce that normal default-lane runs are valid; pending state should show that the handoff is recorded even before delegated child execution completes; completed/running/failed states should keep status visible without hiding lineage or projected context.
- **D-04:** Operator evidence should continue to flow through the curated `Scoria.get_run_detail/1` DTO and `detail.delegated_handoffs`, not through adopter-facing raw workflow internals.

### Lane decision wording
- **D-05:** Use evidence-triggered escalation wording across docs: start with the default runtime lane; escalate to bounded handoff only when there is a real same-run delegation need with narrow, host-controlled projected context and operator-visible delegated lineage.
- **D-06:** Bounded handoff must not be framed as required for first adoption. The docs should be blunt that `mix test.adoption` and the default runtime lane prove the first adoption boundary before optional lanes are layered in.
- **D-07:** Preserve the Phase 52 ownership split: the host app owns identity, escalation policy, prompt/draft selection, and projected-context selection; Scoria owns durable run creation, projected-context validation, queued delegated child creation, and curated readback.
- **D-08:** Prefer precise modal language over loose "should" guidance where support truth matters. Use direct phrasing such as "start here", "add this only when", and "you do not need" for prerequisite boundaries.

### Drift checks
- **D-09:** Pin Phase 53 drift at the public-contract layer using existing ExUnit patterns, not snapshots or new rendered-doc tooling.
- **D-10:** `test/scoria/adoption_surface_test.exs` should own broad docs invariants: default lane first, bounded handoff as escalation, no first-adoption handoff requirement, v2.2 lane hierarchy, public facade over raw internals.
- **D-11:** `Scoria.TestSupport.AdoptionExample` and existing source-doc tests should pin example API fragments: `Scoria.identity/1`, `Scoria.start_run/2`, `Scoria.start_handoff_run/3`, `Scoria.get_run_detail/1`, `delegated_handoffs`, and `session_id` versus `run_id`.
- **D-12:** Existing LiveView/runtime tests should pin operator-visible evidence vocabulary and DTO behavior: `Delegated Evidence`, handoff input, projected context, parent/child same-run lineage, and empty/pending delegated states.

### Phase 54 boundary
- **D-13:** Phase 53 stops after evidence-surface tightening, lane wording alignment, and source/docs drift checks for those contracts.
- **D-14:** Phase 54 owns the canonical runtime-to-handoff proof command, prerequisite-denial proof, support-surface command naming, generated-host or bounded executable proof mechanics, and milestone closeout truth.
- **D-15:** Phase 53 docs may reference current truth such as `mix test.adoption` as the default-lane verifier, but must not publish a placeholder runtime-to-handoff proof command or imply that Phase 54 proof already exists.

### the agent's Discretion
- Exact UI copy, visual hierarchy, and component factoring are left to the planner/executor as long as the evidence dimensions and lane-boundary decisions above remain intact.
- Exact test grouping is left to the planner/executor as long as public-contract drift checks stay lightweight and do not absorb Phase 54 executable proof scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` - Phase 53 goal, success criteria, plan split, and Phase 54 boundary.
- `.planning/REQUIREMENTS.md` - `EVID-01` and `DOCS-01` ownership for Phase 53; `DOCS-02`, `PROOF-01`, and `PROOF-02` deferred to Phase 54.
- `.planning/PROJECT.md` - Product boundary, milestone context, lane hierarchy, and support-truth constraints.
- `.planning/STATE.md` - Current Phase 52 completion state and accumulated decisions.

### Phase 52 locked context
- `.planning/phases/52-runtime-to-handoff-example-contract/52-PATTERNS.md` - Existing public facade, docs, runtime, and test patterns to reuse.
- `.planning/phases/52-runtime-to-handoff-example-contract/52-03-SUMMARY.md` - Host/Scoria ownership boundary, projected-context rejection wording, and Phase 53 readiness notes.
- `.planning/phases/52-runtime-to-handoff-example-contract/52-VERIFICATION.md` - Confirms Phase 53/54 work is separate from Phase 52 completion.

### Runtime and operator surfaces
- `lib/scoria.ex` - Public runtime facade including `start_run/2`, `start_handoff_run/3`, and `get_run_detail/1`.
- `lib/scoria/runtime/run_detail.ex` - Curated `delegated_handoffs` DTO construction and public evidence shape.
- `lib/scoria_web/components/delegated_evidence_component.ex` - Existing delegated evidence UI to tighten.
- `lib/scoria_web/live/workflow_live/show.ex` - Workflow page integration point for `DelegatedEvidenceComponent`.
- `test/scoria_web/live/workflow_live_test.exs` - Existing delegated evidence UI and state coverage.

### Adoption docs and drift tests
- `README.md` - Top-level lane hierarchy, bounded handoff summary, and verification wording.
- `docs/adoption_lanes.md` - Main lane-decision guidance.
- `docs/operator_verification.md` - Default-lane operator proof and lane-boundary wording.
- `docs/phoenix_runtime_example.md` - Runtime-to-handoff adopter example and operator evidence links.
- `docs/bounded_handoffs.md` - Bounded handoff contract, ownership boundary, projected-context safety, and readback guidance.
- `test/support/scoria/adoption_example.ex` - Shared source fragments for docs/source drift checks.
- `test/scoria/adoption_surface_test.exs` - Public docs invariant checks.
- `test/scoria/phoenix_example_source_test.exs` - Phoenix example source-fragment checks.
- `test/scoria/handoff_example_source_test.exs` - Bounded handoff guide source-fragment checks.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.get_run_detail/1` and `Scoria.Runtime.RunDetail` already expose `delegated_handoffs` with parent step, child step, delegated role/kind, handoff input, projected context, and status fields.
- `ScoriaWeb.DelegatedEvidenceComponent` already renders a run-level `Delegated Evidence` section with empty, pending, projected-context, handoff-input, and capability metadata affordances.
- `test/scoria_web/live/workflow_live_test.exs` already covers rendered delegated evidence labels and empty/pending states.
- `Scoria.TestSupport.AdoptionExample` already centralizes docs fragments for source-alignment tests.

### Established Patterns
- Public adopter guidance stays on the top-level `Scoria` facade and curated readback surfaces.
- Docs/source drift is pinned with ExUnit `File.read!` assertions and shared fragment lists, not generated snapshots.
- Operator evidence surfaces favor curated DTOs and LiveView components over raw workflow table inspection.
- Named proof lanes remain explicit: `mix test.adoption`, `mix test.semantic_fast_path`, `mix test.knowledge`, and `mix scoria.release_preview`.

### Integration Points
- Evidence UI work connects through `lib/scoria_web/components/delegated_evidence_component.ex` and `lib/scoria_web/live/workflow_live/show.ex`.
- Runtime evidence shape connects through `lib/scoria/runtime/run_detail.ex`.
- Lane wording connects through `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`, `docs/phoenix_runtime_example.md`, and `docs/bounded_handoffs.md`.
- Drift checks connect through `test/scoria/adoption_surface_test.exs`, `test/scoria/phoenix_example_source_test.exs`, `test/scoria/handoff_example_source_test.exs`, and `test/scoria_web/live/workflow_live_test.exs`.

</code_context>

<specifics>
## Specific Ideas

- Keep the operator page anchored on `/scoria/workflows/:run_id`.
- Keep the curated handoff readback example on `{:ok, detail} = Scoria.get_run_detail(handoff_run.run_id)` and `delegated = detail.delegated_handoffs`.
- Use the trigger phrase shape: default runtime lane first; bounded handoff only for same-run delegation with narrow projected context and operator-visible delegated lineage.
- Keep "No Delegated Handoffs Recorded" as a valid default-lane state rather than a warning that adoption is incomplete.

</specifics>

<deferred>
## Deferred Ideas

- Canonical runtime-to-handoff proof command and executable proof lane - Phase 54.
- Optional semantic/knowledge prerequisite-denial proof for the runtime-to-handoff lane - Phase 54.
- Support-surface command naming and milestone closeout verification ledger - Phase 54.
- Notebook-style delegated forensics or richer audit workbench - defer unless real operator confusion proves the curated evidence digest insufficient.

</deferred>

---

*Phase: 53-operator-evidence-and-lane-guidance*
*Context gathered: 2026-05-27*
