# Phase 61: Proof And Stability Closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 61-Proof And Stability Closeout
**Areas discussed:** All six (user requested full research-backed recommendations, no per-area Q&A)

---

## Research method

Six parallel research passes covered: host topology matrix, summary truth contract, proof harness placement, idempotency depth, guardrail stability scope, and docs alignment. Synthesis aligned with `prompts/scoria-gsd-kickoff.md`, `prompts/sztheory-elixir-dna.md`, `prompts/scoria-brand-book-deep-research.md`, phases 59–60 CONTEXT, and current test/CI layout.

---

## 1. Host topology proof matrix

| Option | Description | Selected |
|--------|-------------|----------|
| A | Fixture matrix + one phx.new host | ✓ (primary) |
| B | Expanded router topologies | ✓ (minimal: list-form root + non-root) |
| C | Full surface Cartesian matrix | |

**User's choice:** Hybrid A + minimal B (research recommendation adopted wholesale)

**Notes:** Shared `HostInstallFixtures`; six fixture classes; one consumer proof; one tailwind-absent case; no combinatorial phx.new.

---

## 2. Summary truth contract

| Option | Description | Selected |
|--------|-------------|----------|
| A | Semantic parity only | |
| B | Stable operator vocabulary | ✓ |
| C | Machine contract hardening | ✓ (additive `summary_operator`, schema `"1.0"`) |

**User's choice:** B + selective C

**Notes:** Planner atoms unchanged; Report projection layer; trailer frozen; no full-log goldens.

---

## 3. Proof harness placement

| Option | Description | Selected |
|--------|-------------|----------|
| A | Adoption lane only | |
| B | Dedicated installer suite | |
| C | Layered thin adoption + deep mix test | ✓ |

**User's choice:** Layered C

**Notes:** No new closeout lane; optional `mix test.install_contract` for maintainers only.

---

## 4. Idempotency proof depth

| Option | Description | Selected |
|--------|-------------|----------|
| A | Apply twice only | ✓ (embedded in B tail) |
| B | Full dry-run → check → apply → check cycle | ✓ (primary) |
| C | Per-surface matrix | ✓ (selective gaps only) |

**User's choice:** B + A tail + selective C

**Notes:** Owned-host fixture required; subprocess for exit truth; unique tmp dirs.

---

## 5. Guardrail stability scope

| Option | Description | Selected |
|--------|-------------|----------|
| A | Lane contract tests only | ✓ (fast pre-check) |
| B | Canonical CI closeout chain | ✓ (required gate) |
| C | Full mix test + knowledge WAE | ✓ (optional smoke, non-blocking) |

**User's choice:** B required; A pre-check; C documented only

**Notes:** WARN-03 explicitly out of Phase 61 scope.

---

## 6. Docs/support alignment

| Option | Description | Selected |
|--------|-------------|----------|
| A | Tests only | ✓ |
| B | Full docs pass | |
| C | Minimal operator subsection | ✓ |

**User's choice:** A + C + `Install.Contract` SSOT + `mix help` moduledoc

**Notes:** No README/handoffs sweep; adoption_surface narrow pins only.

---

## Claude's Discretion

Listed in CONTEXT.md: fixture module naming, tag vs directory for deep tests, optional grouped human sections beyond summary counts.

## Deferred Ideas

See CONTEXT.md deferred section (plan file, partial apply, WARN-03, router fuzzing).
