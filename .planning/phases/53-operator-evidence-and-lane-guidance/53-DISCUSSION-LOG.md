# Phase 53: Operator evidence and lane guidance - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 53-operator-evidence-and-lane-guidance
**Areas discussed:** Operator evidence tightening, Lane decision wording, Drift checks, Phase boundary

---

## Area Selection

The interactive picker was unavailable in Default mode, so the workflow fallback selected all gray areas. This matched the phase scope and the maintainer profile preference for recommendation-first discussion with only major breakpoints escalated.

| Option | Description | Selected |
|--------|-------------|----------|
| All areas | Cover the full Phase 53 decision surface once, then write context for planning. | yes |
| Evidence only | Focus on operator evidence projection and leave docs/test-shape choices to planner discretion. | |
| Docs/tests only | Focus on lane wording and drift checks, assuming the evidence UI already needs only verification/tightening. | |

**User's choice:** Fallback default: All areas.
**Notes:** No user correction was provided after fallback.

---

## Operator Evidence Tightening

| Option | Description | Selected |
|--------|-------------|----------|
| Curated evidence digest in existing `DelegatedEvidenceComponent` | Keep one operator surface and show lineage, projected context, and delegated outcome together through existing curated DTOs. | yes |
| Lineage-first workflow tree enhancement | Emphasize parent/child trace relationships in the tree/detail rail. | |
| Projected-context-first inspection panel | Center least-privilege projected context inspection. | |
| Outcome-first delegated status summary | Prioritize fast pending/running/completed/failed support triage. | |
| Separate notebook-style delegated forensics | Add a richer expert audit surface. | |

**User's choice:** Research-selected: Curated evidence digest in existing `DelegatedEvidenceComponent`.
**Notes:** Advisor research converged on tightening the existing component. The locked decision is that "easy to inspect" means a stable run-level evidence anchor with same-run lineage, projected-context summary, and delegated outcome/status visible together. No new public API or raw workflow table path is needed.

---

## Lane Decision Wording

| Option | Description | Selected |
|--------|-------------|----------|
| Blunt default-first gate | Strongly gate adopters through the default lane before handoff. | |
| Evidence-triggered escalation wording | Start default-first, then escalate only when same-run delegation with narrow projected context is genuinely needed. | yes |
| Equal lane menu | Present default, handoff, semantic, and knowledge lanes as peer choices. | |
| Prerequisite/non-prerequisite matrix | Add explicit support matrix wording. | |
| Scenario-based lane examples | Explain lane choice through concrete adopter scenarios. | |

**User's choice:** Research-selected: Evidence-triggered escalation wording.
**Notes:** Docs should say "start here" for the default lane, "add this only when" for bounded handoff, and "you do not need" for non-prerequisites. Handoff remains optional and layered, not first-adoption required.

---

## Drift Checks

| Option | Description | Selected |
|--------|-------------|----------|
| Doc-surface invariants in `test/scoria/adoption_surface_test.exs` | Pin public docs wording and lane hierarchy with lightweight ExUnit file assertions. | yes |
| Shared source-fragment checks via `Scoria.TestSupport.AdoptionExample` | Pin example API shape and docs fragments. | yes |
| LiveView/runtime DTO vocabulary checks | Pin operator-visible evidence labels and curated DTO behavior. | yes |
| Phase 54 bounded executable proof command | Prove the adopter path through a command or generated-host lane. | |
| External doc snapshot/golden renderer | Snapshot rendered docs output. | |

**User's choice:** Research-selected: use the existing lightweight ExUnit patterns; defer executable proof.
**Notes:** Phase 53 drift checks should pin public-contract invariants, not command execution. Phase 54 owns proof-command behavior.

---

## Phase Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Strict requirement allocation boundary | Map Phase 53 to `EVID-01` and `DOCS-01`; preserve Phase 54 for proof and closeout truth. | yes |
| Phase 53 names existing verifier only | Reference `mix test.adoption` as current truth while avoiding new proof promises. | partial |
| Phase 53 adds proof-command placeholder contract | Publish an internal placeholder for Phase 54's proof command. | |
| Pull bounded proof into Phase 53 | Implement the executable proof lane now. | |
| Phase 53 writes a handoff checklist for Phase 54 | Record deferrals so Phase 54 has clean entry criteria. | yes |

**User's choice:** Research-selected: strict requirement boundary plus concise Phase 54 deferrals.
**Notes:** Phase 53 may reference the current default-lane verifier but must not publish a placeholder runtime-to-handoff proof command or imply the Phase 54 proof exists.

---

## the agent's Discretion

- Exact UI copy, component factoring, and test organization are left to planner/executor discretion within the locked decisions.
- Planner may choose the narrowest file set that satisfies operator evidence, docs guidance, and drift-check coverage.

## Deferred Ideas

- Canonical runtime-to-handoff proof command - Phase 54.
- Optional semantic/knowledge prerequisite-denial proof - Phase 54.
- Support-surface command naming and closeout proof chain - Phase 54.
- Notebook-style delegated forensics - defer unless real adopter/operator feedback proves the curated digest insufficient.
