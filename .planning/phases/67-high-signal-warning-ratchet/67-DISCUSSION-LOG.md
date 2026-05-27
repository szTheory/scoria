# Phase 67: High-Signal Warning Ratchet - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 67-High-Signal Warning Ratchet
**Areas discussed:** All six gray areas (user requested full research + locked recommendations via subagents)

---

## Ratchet scope — fix vs defer

| Option | Description | Selected |
|--------|-------------|----------|
| A: p3-only fix | Minimal; defer p2 adoption WAE | |
| B: p2+p3 literal WARN-06 | Full adoption file list WAE in 67 | |
| C: gate machinery only | Ratchet check without burn-down | |
| **A′: Hold p0/p1, fix p3, guard p2, keep p4 baselined, zero p5 high-signal** | Coherent staged scope | ✓ |

**User's choice:** Auto-locked via research synthesis (no manual selection).
**Notes:** Aligns with ROADMAP "without destabilizing full suite" and Phase 66 inventory tiers.

---

## Unclassified warnings policy

| Option | Description | Selected |
|--------|-------------|----------|
| A: Zero high-signal | Registry or fix | ✓ (part of C) |
| B: Capped baseline row | Owner+expiry for unclassified | |
| C: Split zero high-signal / baseline full-suite | | ✓ |
| D: Ratchet floor only | Non-increasing count | |
| E: Quarantine table | Separate artifact | |

**User's choice:** Option C — zero unclassified in WARN-06 paths; no baseline caps for taxonomy lag.

---

## Knowledge migration redefines

| Option | Description | Selected |
|--------|-------------|----------|
| A: DDL in lib | Thin .exs delegate | Deferred Phase 68 |
| B: Scoped ignore_module_conflict | Migrator boundary only | ✓ |
| C: Migrate once per suite | persistent_term gate | ✓ |
| F: Baseline only | | Rejected |

**User's choice:** C + B in Phase 67; structural A1 deferred.

---

## Host-proof / adoption-lane noise

| Option | Description | Selected |
|--------|-------------|----------|
| A: Fix at source | Generator + priv overlay | ✓ |
| B: @compile suppress | | Rejected |
| D: Baseline subprocess noise | | Rejected |
| E: Fix only when CI fails | | Rejected |

**User's choice:** A + Phase 60 architecture guard; maintainer adoption WAE documented, not CI in 67.

---

## CI enforcement for WARN-06

| Option | Description | Selected |
|--------|-------------|----------|
| A: policy job hardcoded paths | | Rejected (Postgres) |
| B: policy job from JSON | | Rejected |
| C: local-only until 68 | Partial | |
| **D: Hybrid** | SSOT in Elixir; prove 67 locally; CI test job in 68 | ✓ |

---

## Plan shape

| Option | Description | Selected |
|--------|-------------|----------|
| A: One plan per tier | | Rejected (empty p0, fat p3) |
| B: One plan per cluster | | Rejected (fragmentation) |
| **C: Tier-ordered vertical slices** | 5 plans 67-00..67-04 | ✓ |

---

## Claude's Discretion

Listed in CONTEXT.md — WarningRatchet API naming, new cluster atoms, contract test placement.

## Deferred Ideas

See CONTEXT.md `<deferred>` — full-suite WAE CI, Phase 69 CI-03 bundle, auto-fix task, global test WAE in mix.exs.
