# Phase 59: Planner Contract Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `59-CONTEXT.md` — this log preserves alternatives and tradeoffs considered.

**Date:** 2026-05-27
**Phase:** 59-planner-contract-foundation
**Areas discussed:** Planner contract shape, check exit semantics, deterministic classification, output format and DX

---

## Planner Contract Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical planner artifact + pure analyzers | Single plan truth for dry-run/check (and future apply), deterministic mutation entries with rationale/evidence | ✓ |
| Branch logic inside existing mutators | Add dry-run/check behavior in current write paths directly | |
| Full AST patch framework now | Adopt heavier codemod stack immediately | |
| Saved plan-file required for apply | Terraform-style persisted plan artifact gating apply | |

**User's choice:** Select all and synthesize one coherent recommendation set; optimize for least surprise and strong DX.  
**Notes:** Recommendation favored a plan-first architecture that stays scoped for Phase 59 while preparing Phase 60 apply parity.

---

## `--check` Exit Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| `0=safe, 1=unsafe/manual-review, 2=error` | Diff/lint-style check semantics with explicit unsafe vs broken separation | ✓ |
| `0=safe, 2=unsafe, 1=error` | Terraform detailed-exitcode style | |
| `0=safe, 1=all non-safe` | Single nonzero for everything | |
| Custom high codes (`0/10/20/...`) | Internal-only nonstandard contract | |

**User's choice:** One-shot recommendation set with stable, ergonomic semantics for humans and CI.  
**Notes:** Selected least-surprise tri-state with explicit machine-readable status trailer.

---

## Deterministic Classification Matrix

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid probes + ownership markers + evidence ledger | Structural checks plus ownership/drift rationale, conservative manual-review fallback | ✓ |
| Regex/string heuristics only | Fast but brittle text-anchor classification | |
| Full AST/CST codemod for all surfaces | Maximum precision but high scope cost now | |
| Manifest/hash ownership only | Deterministic but high false-positive manual-review rate | |

**User's choice:** Optimize for safety and consistency across host-app variability, including ecosystem lessons.  
**Notes:** Selected conservative classifier with explicit precedence and per-surface rules.

---

## Output Format and UX

| Option | Description | Selected |
|--------|-------------|----------|
| Dual mode: grouped text + `--format json` | Human-first local UX and stable machine contract for CI | ✓ |
| Text only | Human-friendly but parser-fragile in automation | |
| JSON only | Great for tools, poor for day-0 operator readability | |
| Table-heavy output | Compact in ideal terminals, brittle with wrapping/logs | |

**User's choice:** “Think deeply one-shot” recommendations emphasizing coherence, least surprise, and great DX.  
**Notes:** Selected calm grouped text default with deterministic section ordering and schema-versioned JSON mode.

---

## Claude's Discretion

- Final module/file organization for planner internals.
- Exact naming of status enums and JSON keys, within versioned schema guarantees.
- Verbosity defaults for patch preview details.

## Deferred Ideas

- Required saved-plan file workflows for apply.
- Full AST codemod expansion in this phase.
- Warning-ratchet follow-up (`WARN-03`) during Phase 59.
