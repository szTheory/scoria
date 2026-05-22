# Phase 36: Vanguard Milestone-State Reconciliation - Research

**Date:** 2026-05-21
**Status:** Complete

## Objective

Research what is needed to plan Phase 36 well: a milestone-state reconciliation phase that aligns root planning surfaces, milestone-local Vanguard artifacts, and the restored Phase 30-34 verification chain without rewriting historical audit truth.

## Key Findings

### 1. This phase is a truth-reconciliation pass, not a feature implementation pass

The repo already has the canonical proof chain restored by Phase 35:
- `.planning/phases/30-oban-infrastructure-and-queue-segregation/30-VERIFICATION.md`
- `.planning/phases/31-model-routing-and-resiliency-foundation/31-VERIFICATION.md`
- `.planning/phases/32-multi-model-fallback-orchestration/32-VERIFICATION.md`
- `.planning/phases/33-distributed-evaluation-fan-out/33-VERIFICATION.md`
- `.planning/phases/34-real-time-operator-dashboards/34-VERIFICATION.md`

The remaining problem is surface drift:
- `.planning/ROADMAP.md` says 33-36 are not started.
- `.planning/milestones/v1.8-ROADMAP.md` still marks 30-34 as not started.
- `.planning/REQUIREMENTS.md` still frames the active requirements around stale Vanguard traceability.
- `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/MILESTONES.md`, and `.planning/MILESTONE-ARC.md` still describe older active milestone/current phase truth.

### 2. Scoria already has an internal precedent for this exact class of repair

Phase 11 established the closeout rule:
- restore missing verification in the original phase directory
- align milestone/state docs to the repaired truth
- keep the original audit as a historical snapshot instead of mutating it

Phase 35 reinforced the same posture:
- proof was backfilled phase-locally
- exact commands and chronology stayed in verification/validation artifacts
- milestone-state reconciliation was explicitly left for Phase 36

### 3. The correct authority chain is already implicit in the repo

The least-surprise ownership order is:
1. Phase-local verification artifacts = canonical proof facts
2. Milestone-local Vanguard docs = milestone fact surface
3. Root `.planning/*` docs = reconciled projections for repo-wide readability

This matches Scoria’s Phoenix/Ecto posture:
- durable truth lives closest to the seam that proves it
- higher-level operator/status surfaces project from that truth
- mutable summaries should not outrank evidence

### 4. The phase should end in “closure-ready”, not “shipped”

Even after reconciliation, the milestone should not jump directly to archived/shipped state because:
- `.planning/v1.8-MILESTONE-AUDIT.md` is still a dated `gaps_found` artifact from 2026-05-21
- the explicit control sequence in the context is reconcile -> fresh audit -> complete milestone

So Phase 36 should update docs to a `ready to close` posture and explicitly point at:
- `$gsd-audit-milestone v1.8`
- `$gsd-complete-milestone v1.8`

### 5. Top-level docs should not duplicate detailed proof lanes

Detailed proof belongs in:
- `*-VERIFICATION.md`
- `*-VALIDATION.md`
- milestone audit / closeout artifacts

Top-level docs should carry:
- current status truth
- requirement/phase closure state
- light pointers to canonical proof files
- terse dated supersession notes where needed

They should not carry:
- copied command strings
- duplicated chronology blocks
- full audit-style forensic detail

## Recommended Planning Decomposition

The cleanest decomposition is three plans in one wave sequence:

1. Reconcile roadmap and requirement surfaces
- update root `.planning/ROADMAP.md`
- update `.planning/milestones/v1.8-ROADMAP.md`
- update root `.planning/REQUIREMENTS.md`
- update `.planning/milestones/v1.8-REQUIREMENTS.md`
- ensure active Vanguard truth, phase completion state, and proof pointers agree

2. Reconcile project and milestone state surfaces
- update `.planning/STATE.md`
- update `.planning/PROJECT.md`
- update `.planning/MILESTONES.md`
- update `.planning/MILESTONE-ARC.md`
- move repo narrative from stale “Phase 32 / v1.7 active” to current “v1.8 closure-ready after reconciliation”

3. Run a final drift/coverage pass
- grep/read audit of all touched docs
- verify no surface still claims stale active milestone or pending Vanguard requirement truth
- verify historical audit remains unchanged
- verify top-level docs point to phase-local proof rather than duplicating proof lanes

## File-Specific Risks and Footguns

### `.planning/ROADMAP.md`
- Risk: leaving progress rows stale after updating phase headings
- Risk: marking Phase 36 complete inside the planning artifact before execution exists

### `.planning/REQUIREMENTS.md`
- Risk: confusing global “Active” requirements narrative with milestone-local archived requirement truth
- Risk: updating traceability rows without reflecting the restored verification chain

### `.planning/STATE.md`
- Risk: stale current phase/current milestone headlines create immediate operator mistrust
- Risk: over-updating metrics that Phase 36 cannot truthfully prove

### `.planning/PROJECT.md`
- Risk: changing product thesis instead of only milestone/current-state sections
- Risk: making v1.8 sound shipped instead of closure-ready

### `.planning/MILESTONES.md` and `.planning/MILESTONE-ARC.md`
- Risk: these are the easiest places for split-brain narrative because they carry strategic prose
- Risk: fixing the ledger row but leaving the “active milestone” narrative stale

## Anti-Patterns to Avoid

- Treating root docs as stronger than phase-local verification
- Rewriting `.planning/v1.8-MILESTONE-AUDIT.md`
- Marking `v1.8 Vanguard` shipped before a fresh milestone audit exists
- Copying proof commands into multiple top-level docs
- Mixing “current truth” narrative with long incident-style chronology in every file
- Editing unrelated planning artifacts outside the listed drift surfaces

## Verification Strategy

This is a docs/state phase, so verification should be grep-and-read driven rather than code-test driven.

The plan should require:
- direct file existence and string checks on every touched artifact
- explicit proof pointers to `30-VERIFICATION.md` through `34-VERIFICATION.md`
- negative checks for stale milestone markers such as:
  - `Phase 32 complete` as current focus
  - `v1.7 Outrider` as active milestone
  - Vanguard requirements still `Pending`
- a final no-drift pass that compares the root roadmap, milestone roadmap, root requirements, milestone requirements, and milestone/state docs against the locked Phase 36 context

## Nyquist / Validation Note

This phase is planning-state reconciliation rather than runtime behavior implementation. A heavy Nyquist-style `VALIDATION.md` is not the critical artifact here; the plan itself should embed exact grep/read verification steps for state alignment. If a validation artifact is created later, it should stay lightweight and doc-focused.

## Recommended Plan Shape

- Prefer `type: execute` plans rather than TDD.
- Keep all plans autonomous unless a file reveals conflicting uncommitted user edits at execution time.
- Use explicit `<read_first>` lists heavily because this phase is about comparing artifacts, not generating new domain behavior.
- Every `<action>` should name exact target states, not vague “align X with Y” language.

## Planning Inputs That Must Be Read

- `36-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `.planning/MILESTONES.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/milestones/v1.8-ROADMAP.md`
- `.planning/milestones/v1.8-REQUIREMENTS.md`
- `.planning/v1.8-MILESTONE-AUDIT.md`
- `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-02-SUMMARY.md`
- `.planning/phases/35-vanguard-verification-backfill/35-01-SUMMARY.md`
- `.planning/phases/35-vanguard-verification-backfill/35-02-SUMMARY.md`
- `.planning/phases/35-vanguard-verification-backfill/35-03-SUMMARY.md`

## Recommendation

Plan Phase 36 as a three-plan docs/state reconciliation package:
- Plan 01: roadmap + requirements truth alignment
- Plan 02: project + milestone state narrative alignment
- Plan 03: final drift audit and closure-ready handoff

This is the smallest plan shape that preserves clear ownership, keeps verification concrete, and matches Scoria’s established evidence-first closeout pattern.

## RESEARCH COMPLETE
