# Phase 70: Docs Truth Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 70-Docs Truth Foundation
**Areas discussed:** Shipped banner copy, Milestone vs Hex semver, README Install upgrade path, adoption_surface_test contract, Maintainer lane boundaries, CI gate map additions

---

## Shipped banner copy

| Option | Description | Selected |
|--------|-------------|----------|
| A — Capability headline + five bullets | Replaces milestone line; aligns with Choose Your Lane | ✓ |
| B — "What's included" Oban-style block | Extra heading; redundant with lanes | |
| C — Progressive adoption only | Weak at-a-glance inventory | |
| D — Drop banner entirely | Loses one-line product state | |

**User's choice:** Research synthesis — Approach A (locked in CONTEXT D-01–D-06)
**Notes:** Subagents compared Phoenix/Oban/LiveView/OTel patterns; rejected milestone-as-shipped (LangChain footgun). Banner omits proof commands; Status section collapsed.

---

## Milestone vs Hex semver

| Option | Description | Selected |
|--------|-------------|----------|
| A — README callout | High visibility; pollutes capability README | |
| B — operator_verification CI gate map only | Matches ROADMAP #5; README stays clean | ✓ |
| C — Both README + operator | Drift risk | |
| D — CHANGELOG only (Phase 71) | Too late for Phase 70 | |

**User's choice:** Option B for Phase 70; Option D deferred to Phase 71
**Notes:** Two-sentence Version namespaces under gate map. No `2.7.0` on Hex.

---

## README Install upgrade path

| Option | Description | Selected |
|--------|-------------|----------|
| A — Full bash blocks in README | Two SSOTs; overwhelms first install | |
| B — One-liner + link | Too easy to skip upgrade safety | |
| C — Short subsection + link | Progressive disclosure | ✓ |

**User's choice:** Option C (CONTEXT D-10–D-14)
**Notes:** Four-step list + three guardrails; operator guide keeps trailer/drift table.

---

## adoption_surface_test contract

| Option | Description | Selected |
|--------|-------------|----------|
| A — Strict noun list only | Misses milestone regression | |
| B — Refute-regex only | Docs rot | |
| C — Hybrid + AdopterDocContract SSOT | Matches VerificationLanes precedent | ✓ |

**User's choice:** Hybrid (CONTEXT D-15–D-20)
**Notes:** README refutes maintainer commands; operator guide asserts them via ci_policy_contract_test.

---

## Maintainer lane boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| A — install_test in both lanes | PR closeout + maintainer bundle | ✓ |
| B — install_contract only for install_test | Weakens PR gate | |
| C — Split install test file | High churn | |

**User's choice:** 12-file adoption / 5-file install_contract; preferred_envs both spellings; operator doc only (CONTEXT D-21–D-26)

---

## CI gate map additions

| Option | Description | Selected |
|--------|-------------|----------|
| A — Command-labeled "Not in PR CI" row | Grep-friendly; testable | ✓ |
| B — Lane name only | Less actionable | |
| E — WAE disclaimer in Notes only | Incomplete | |

**User's choice:** Lane matrix + Version namespaces line; semantic row with WAE note (CONTEXT D-27–D-31)

---

## Claude's Discretion

- Banner prose polish, AdopterDocContract module placement, optional test trim.

## Deferred Ideas

- SEM-CI-01 in PR CI
- CHANGELOG preamble (Phase 71)
- README Hex flip (Phase 72)
