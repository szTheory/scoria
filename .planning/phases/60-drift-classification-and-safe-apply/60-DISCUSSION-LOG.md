# Phase 60: Drift Classification And Safe Apply - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `60-CONTEXT.md` — this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 60-drift-classification-and-safe-apply
**Areas discussed:** Manifest ownership model for drift, Apply safety gate when drift is unsafe, Planner-to-apply execution contract, Operator remediation/report contract

---

## Manifest ownership model for drift

| Option | Description | Selected |
|--------|-------------|----------|
| Structural probes only | Keep current heuristic classification with no explicit ownership markers/ledger | |
| Marker-only managed blocks | Use inline managed-region markers everywhere for ownership truth | |
| Manifest-only ledger | Ownership tracked only in installer manifest file | |
| Hybrid ownership | Marker-owned snippet surfaces + structural migration ownership + manifest ledger | ✓ |

**User's choice:** Hybrid ownership model.
**Notes:** Chosen for safety + practicality balance, conservative ambiguity handling, and coherent fit with phase 59 planner truth decisions.

---

## Apply safety gate when drift is unsafe

| Option | Description | Selected |
|--------|-------------|----------|
| Strict atomic gate | If any blocking drift exists, apply performs zero writes and exits blocked | ✓ |
| Partial apply | Apply safe entries while skipping blockers | |
| Strict default + opt-in partial | Block by default, allow partial via explicit override flag | |

**User's choice:** Strict atomic gate.
**Notes:** Prioritized least surprise and operator trust; avoids hidden partial mutation states.

---

## Planner-to-apply execution contract

| Option | Description | Selected |
|--------|-------------|----------|
| Keep split behavior | Planner for preview/check, separate imperative apply logic | |
| Planner-driven executor | Apply consumes canonical planner entries and typed operations directly | ✓ |
| Required sealed planfile | Must save plan artifact then apply that exact file | |
| Re-plan on apply only | Apply recomputes intended mutations without strict plan equivalence guard | |

**User's choice:** Planner-driven executor contract.
**Notes:** Chosen to keep preview/check/apply equivalent by construction and deterministic in order/behavior.

---

## Operator remediation/report contract

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal report | Classification/path/rationale only | |
| Human-only remediation text | Rich manual guidance without structured machine payload | |
| Structured remediation contract | Canonical remediation payload rendered in human and JSON outputs | ✓ |

**User's choice:** Structured remediation contract.
**Notes:** Emphasized operator-grade UX and CI-friendly machine stability from one shared truth object.

---

## Claude's Discretion

- Exact manifest schema field naming and file placement.
- Exact operation enum naming for planner-to-apply execution entries.
- Whether optional power-user flags are introduced now or deferred.

## Deferred Ideas

- Optional `--allow-partial` mode for advanced users (deferred).
- Sealed plan-file workflow (`--write-plan` / `--apply-plan`) for later CI hardening (deferred).
