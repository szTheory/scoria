# Scoria v2.0 Relay Roadmap

**Status:** Active
**Milestone initialized:** 2026-05-24
**Latest shipped milestone:** `v1.9 Crucible` on 2026-05-24
**Historical roadmap:** `.planning/milestones/v1.9-ROADMAP.md`
**Historical requirements:** `.planning/milestones/v1.9-REQUIREMENTS.md`

## Milestone Summary

`v2.0 Relay` is a narrow formalization milestone for the repo-local bounded handoff wedge. It intentionally treats the current implementation as the starting point, skips net-new ecosystem research, and focuses on contract truth, delegated evidence, adoption proof, and milestone-quality closeout.

## Phases

- [ ] **Phase 41: Bounded Handoff Contract & Safety** - Lock the public handoff contract, same-run lineage, and projected-context guardrails as explicit shipped truth.
- [ ] **Phase 42: Delegated Evidence & Adoption Story** - Make delegated lineage inspectable and keep the docs/source examples aligned with the actual handoff lane.
- [ ] **Phase 43: Canonical Adoption Proof & Milestone Closeout** - Prove the bounded handoff lane through the default adoption verification path and decide whether any remaining handoff work is real follow-on value.

## Phase Details

### Phase 41: Bounded Handoff Contract & Safety
**Goal**: Developers get one narrow, explicit public handoff contract without widening Scoria into a general orchestration platform.
**Depends on**: Phase 40
**Requirements**: HAND-01, HAND-02, SAFE-01, SAFE-02
**Success Criteria**:
1. `Scoria.start_handoff_run/3` persists explicit root-role, delegated-role, delegated-kind, and handoff-input truth behind the public runtime facade.
2. Delegated work remains under the same durable root run with a handoff step, durable handoff record, and queued child step instead of ownership transfer.
3. Unsafe projected-context keys are rejected explicitly, and the public lane documents a narrow host-controlled context contract rather than accepting broad runtime state.
**Plans**: 3 plans
- [ ] `41-01-PLAN.md` — Verify and tighten the public handoff input contract plus same-run durable lineage.
- [ ] `41-02-PLAN.md` — Harden projected-context safety and explicit rejection behavior for unsafe delegated state.
- [ ] `41-03-PLAN.md` — Backfill tests and milestone documentation that prove the lane stays narrow by default.

### Phase 42: Delegated Evidence & Adoption Story
**Goal**: Delegated lineage is inspectable in the public runtime and the adoption story matches the shipped handoff behavior.
**Depends on**: Phase 41
**Requirements**: EVID-01, ADPT-01
**Success Criteria**:
1. Public run detail and workflow surfaces expose delegated role, delegated kind, projected context, and same-run lineage clearly enough for operator inspection.
2. The bounded handoff guide, README/adoption surfaces, and checked source fragments all describe the same runtime-first integration flow.
3. Any remaining adopter-facing rough edges are documented explicitly as either in-scope closeout work or deferred follow-up, not left ambiguous.
**Plans**: 3 plans
- [ ] `42-01-PLAN.md` — Verify delegated-lineage DTOs and operator-surface projections against the public handoff contract.
- [ ] `42-02-PLAN.md` — Align bounded handoff guide, runtime docs, and checked adoption fragments to one support-truth story.
- [ ] `42-03-PLAN.md` — Capture any real remaining adopter-facing gap and narrow it to explicit milestone scope or defer it.

### Phase 43: Canonical Adoption Proof & Milestone Closeout
**Goal**: The bounded handoff lane has one boring canonical proof path and a clean closeout decision.
**Depends on**: Phase 42
**Requirements**: ADPT-02
**Success Criteria**:
1. `mix test.adoption` remains the canonical default verification lane for the public runtime and bounded handoff surfaces without optional-knowledge prerequisites.
2. The milestone ends with explicit proof references for docs/source alignment, public runtime facade coverage, and bounded handoff behavior.
3. Closeout records whether Scoria should stop touching bounded handoffs for now or carry one narrow follow-up into the next milestone discussion.
**Plans**: 2 plans
- [ ] `43-01-PLAN.md` — Prove the adoption lane and public handoff verification path stay green and scoped correctly.
- [ ] `43-02-PLAN.md` — Write the milestone verification/closeout ledger and record the post-Relay recommendation.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 41. Bounded Handoff Contract & Safety | 2/3 | In Progress|  |
| 42. Delegated Evidence & Adoption Story | 0/3 | Not Started | — |
| 43. Canonical Adoption Proof & Milestone Closeout | 0/2 | Not Started | — |
