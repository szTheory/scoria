# Phase 54: Executable proof and closeout truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves alternatives and tradeoffs reviewed.

**Date:** 2026-05-27
**Phase:** 54-executable-proof-and-closeout-truth
**Areas discussed:** Proof lane shape, prerequisite-independence proof, support-surface command alignment, closeout verification policy

---

## Area Selection

The user requested full-scope analysis ("consider all") and explicitly asked for one coherent, one-shot recommendation set with ecosystem tradeoff research. All identified gray areas were discussed and researched in parallel.

| Option | Description | Selected |
|--------|-------------|----------|
| Discuss all areas | Cover all Phase 54 decision areas in one pass with deep research and cohesive recommendations. | yes |
| Discuss subset only | Limit discussion to one or two gray areas. | |

**User's choice:** Discuss all areas.
**Notes:** Decision quality and cohesion were prioritized over incremental questioning.

---

## Proof Lane Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated canonical lane command | Add `mix test.runtime_to_handoff` (wrapper) over `mix scoria.test.runtime_to_handoff`. | yes |
| Extend `mix test.adoption` | Fold runtime-to-handoff proof into default-lane verifier. | |
| Composite orchestrator command | Introduce higher-level command chaining internal checks. | |
| File/tag-only invocation | Use raw `mix test ...` file lists or tags as canonical command. | |

**User's choice:** Lock recommendation set (dedicated canonical lane command).
**Notes:** Chosen for lane clarity, least surprise, and alignment with existing Scoria lane patterns.

---

## Prerequisite-Independence Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Negative-contract assertions in bounded lane | Prove runtime-to-handoff path does not require semantic/knowledge/hosted setup. | yes |
| CI matrix only | Rely mostly on environment matrix jobs to prove optionality boundaries. | |
| Host-app-heavy proof as canonical | Make generated-host runtime-to-handoff proof the primary contract. | |
| Narrative-only docs claim | State optionality in docs without dedicated lane checks. | |

**User's choice:** Lock recommendation set (bounded negative-contract strategy).
**Notes:** Maintains fast local DX while preserving strong proof that optional lanes are not hidden prerequisites.

---

## Support-Surface Command Alignment

| Option | Description | Selected |
|--------|-------------|----------|
| Single canonical command string across all support surfaces | Enforce one exact runtime-to-handoff command in README/docs/examples/tests. | yes |
| Soft synonym policy | Allow multiple equivalent command names in docs. | |
| Generated command registry first | Build a command registry system before aligning surfaces. | |
| Section-by-section ad hoc wording | Let each doc phrase command independently. | |

**User's choice:** Lock recommendation set (single canonical string with test enforcement).
**Notes:** Drift resistance is enforced through existing docs/source contract tests and shared fragments.

---

## Closeout Verification Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Full chain at milestone closeout | Require `release_preview` + `test.adoption` + `test.runtime_to_handoff` for closeout. | yes |
| Narrow chain by default | Allow narrow chain unless a maintainer decides to run full chain. | |
| Full chain always at every step | Require full chain for each implementation step. | |
| Exception without strict protocol | Allow informal skipping with narrative notes. | |

**User's choice:** Lock recommendation set (full closeout chain + strict temporary exception protocol).
**Notes:** Preserves release truth while allowing bounded iteration checks during implementation.

---

## Claude's Discretion

- Exact lane test file list and CI job breadth can be tuned during planning as long as locked decisions and prerequisite-independence guarantees remain intact.
- Closeout ledger filename/details can be finalized in planning (`54-VERIFICATION.md` or equivalent) while preserving required evidence fields.

## Deferred Ideas

- Make host-app-heavy runtime-to-handoff proof the primary canonical lane.
- Build command registry/generator infrastructure for docs string management.
- Add broad alias/synonym command support for runtime-to-handoff lane.
