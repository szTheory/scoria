# Phase 42: Delegated Evidence & Adoption Story - Discussion Log

**Gathered:** 2026-05-24
**Mode:** `discuss all` with parallel advisor-style research
**Status:** Decisions locked

## Inputs

- User selected all identified gray areas and explicitly requested a one-shot recommendation set rather than incremental back-and-forth.
- Research was widened to include project-local planning context, prompt guidance under `prompts/`, current runtime/workflow/doc surfaces, and ecosystem lessons from adjacent successful tools/libraries.
- Decision policy used: prefer decisive defaults unless the choice changes product shape, security boundary, durable truth, tenant blast radius, or materially different operator UX.

## Areas Discussed

### 1. Delegated evidence shape

**Options considered**
- One explicit curated handoff record per delegation.
- Split public contract where callers combine handoff rows plus child steps/checkpoints/events.
- Dual-layer read model: primary curated `delegated_handoffs` projection plus existing raw arrays.

**Locked decision**
- Adopt the dual-layer read model.
- Add one primary delegated projection such as `delegated_handoffs`.
- Keep existing `steps`, `checkpoints`, `events`, `approvals`, and `handoffs` as secondary/raw evidence.
- Do not add new durable tables.

**Why**
- This is the most idiomatic Phoenix/Ecto library boundary for Scoria’s shape: durable normalized truth underneath, one curated public struct on top.
- It avoids forcing app developers or operators to reconstruct lineage manually from workflow internals.
- It preserves the advanced evidence path without making raw rows the primary contract.

**Tradeoff accepted**
- Some DTO duplication is acceptable as long as precedence rules are explicit and the projection does not become a second workflow engine.

### 2. Workflow surface presentation

**Options considered**
- Keep delegated evidence lightweight in the tree + existing detail pane only.
- Add a dedicated `Delegated Evidence` section on the workflow page.
- Create a notebook-style delegated operator panel.
- Enrich the right rail with a tab/accordion only.

**Locked decision**
- Add a dedicated run-level `Delegated Evidence` section.
- Keep the tree topology-first with compact handoff markers.
- Keep the right rail selected-step detail only.
- Use summary-first cards with progressive disclosure for full `handoff_input`, full projected context, and adjunct metadata.
- Do not introduce a notebook-style delegated panel in Phase 42.

**Why**
- The workflow page already uses a good strip/tree/detail/notebook layering model.
- Delegated lineage is important enough to deserve a visible run-level section, but not broad enough to deserve a new orchestration sub-product.
- This gives operators one obvious place to inspect delegated truth without making the page noisy or platform-like.

**Tradeoff accepted**
- Some duplication across tree, section, and right rail is acceptable if each layer has a narrow responsibility and defaults stay compact.

### 3. Adoption story ordering

**Options considered**
- Teach bounded handoffs as an advanced extension of the normal runtime-first story.
- Teach bounded handoffs as a first-class parallel onboarding path.
- Keep one primary path plus an early signpost for bounded handoffs.

**Locked decision**
- Keep one canonical runtime-first path.
- Teach bounded handoffs as an advanced extension, with discoverability via an early signpost rather than a competing quickstart.
- Preserve shared checked fragments and avoid parallel canonical example families.

**Why**
- This matches the repo’s existing Keystone/Relay adoption posture and the decisive-defaults methodology.
- It is the most Phoenix-library-like IA: one boring happy path first, advanced guides later.
- It lowers support-truth drift and avoids forcing adopters to choose between two “start here” stories.

**Tradeoff accepted**
- Slightly lower immediate handoff discoverability is acceptable if README signposting remains intentional and the guide is easy to find.

### 4. Real gap vs defer

**Options considered**
- Stop at DTO/docs/test alignment.
- Ship one thin workflow-inspection shim now.
- Add stronger examples/helpers now.
- Defer remaining handoff work to Phase 43 or later.

**Locked decision**
- Ship one thin workflow-inspection shim now.
- Stop after delegated runtime truth is clearly inspectable on the normal workflow page and docs/source checks align to that story.
- Defer anything that primarily adds marketing surface, orchestration UX, extra examples, or hidden-helper semantics.

**Why**
- The real gap is not missing substrate truth. The gap is that the boring operator path under-projects that truth today.
- A thin read-model/UI/docs alignment pass closes the milestone honestly without widening the product boundary.

**Tradeoff accepted**
- Scoria will intentionally leave richer multi-agent UX or stronger example families for later unless Phase 43 or real adopter feedback proves they are necessary.

## Ecosystem Lessons Applied

### What strong libraries/tools got right
- Req / Oban / Ecto / Ash:
  - one obvious happy path
  - deeper layers available
  - explicit durable truth
  - no forced early architecture forks for first-time adopters
- Phoenix LiveDashboard / Oban Web:
  - scan-first embedded operator UI
  - drilldown without spectacle
  - curated read models over raw tables
- OpenAI Agents / LangGraph / Langfuse / Braintrust:
  - first-class inspectability for runs/handoffs/traces
  - durable execution and lineage matter
  - production truth should feed evaluation and operator surfaces

### Footguns to avoid
- Making users reconstruct meaning from overly normalized primitives.
- Two equal-weight onboarding paths in README.
- Example proliferation that silently becomes contract surface.
- Turning bounded delegation into orchestration theater.
- Letting adjunct metadata look more authoritative than the persisted handoff contract.
- Raw JSON walls in default operator views.

## Shift-Left Preference To Carry Forward

Future GSD work for this lane should default to:
- runtime-first docs ordering
- one curated delegated read model over durable truth
- one compact delegated workflow section before any richer UX
- user escalation only when a choice changes product shape, security boundary, durable truth, or materially different operator behavior

## Outcome

Phase 42 is now framed as:
- one curated delegated readback noun
- one visible run-level delegated workflow section
- one canonical runtime-first adoption story
- one thin closeout shim for the real operator/adopter gap

Everything broader stays deferred until canonical adoption proof or later milestone evidence says otherwise.
