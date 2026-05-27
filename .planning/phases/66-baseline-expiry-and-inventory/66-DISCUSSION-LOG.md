# Phase 66: Baseline Expiry And Inventory - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 66-Baseline Expiry And Inventory
**Areas discussed:** All five gray areas (user requested full research synthesis; no interactive Q&A)

---

## Baseline expiry enforcement shape

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated Mix task (`mix scoria.warning_baseline.check`) | Code SSOT; testable parser; local ≡ CI | ✓ |
| CI-only shell (grep/awk) | Fast to add; brittle; poor local DX | |
| Mix task + thin CI wrapper | Best of both; matches release_preview pattern | ✓ (combined with row 1) |
| ExUnit/compile-time check | Parser tested in suite; compile-time awkward for `.planning/` | |

**User's choice:** Research-driven recommendation — Mix task + CI wrapper (Option 3), strict UTC date semantics, Accepted-section-only parsing.

**Notes:** Cross-ecosystem research (Credo, Dialyzer, Rust bestbefore, ESLint ratchets, Go nolintlint) confirms calendar expiry is always a meta-gate outside native suppressions. Elixir idiomatic path is Mix task like existing `scoria.release_preview`.

---

## CI gate placement and failure mode

| Option | Description | Selected |
|--------|-------------|----------|
| A. First step in same job | Before compile; still waits on Postgres service health | |
| B. After compile WAE | Policy after compile; weaker "inventory first" signal | |
| C. Separate `policy` job (no Postgres) | Fast fail; decoupled from DB; `needs: policy` | ✓ |
| D. Warn-only transition | Contributor-friendly short-term; violates WARN-03 | |

**User's choice:** Option C — `policy` job with baseline check first, then compile + lane WAE; `test` job preserves closeout order unchanged.

**Notes:** Oban/Ecto/Tokio staged lint-before-proof pattern. Phase 68 reserves full-suite WAE slot after `runtime_to_handoff`.

---

## Inventory command contract

| Option | Description | Selected |
|--------|-------------|----------|
| `mix scoria.warning_inventory` | Full mix task; credo-like DX | ✓ |
| Shell pipeline only | Fragile; not WARN-04 reproducible | |
| Committed `.planning/WARNING-INVENTORY.md` only | Human summary without machine baseline | Partial (as `--write` output) |
| JSON + optional MD | Machine-diffable + human view | ✓ |

**User's choice:** `mix scoria.warning_inventory` with `--format json|md|table`, `--write`, `--since`, `--scope full` default; capture mode without WAE; cluster-count JSON committed, full warnings gitignored.

**Notes:** ESLint/Notion lesson — don't commit per-line baselines. Credo grouped output informs reporter design.

---

## Inventory classification taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed enum (cluster + lane + path) | Stable but path-prefix brittle | |
| Auto-cluster regex only | Drifts on Elixir version message text | |
| Hybrid registry + matchers | Stable cluster_id; testable match/1 | ✓ |
| Directory-only bucketing | Too vague for Phase 67 prioritization | |

**User's choice:** Hybrid registry with 7 initial clusters + sentinel; `ratchet_tier` ordering; lane attribution secondary via `VerificationLanes` + `adoption_test_files/0`.

**Notes:** Credo categories + Dialyzer tags + RuboCop departments inform two-layer model (compiler_kind + cluster_id).

---

## Phase 66 learnings artifact

| Option | Description | Selected |
|--------|-------------|----------|
| Create LEARNINGS at discuss | Conflicts with GSD extract workflow | |
| Promote A+C now, hold B | Split timing awkward for Phase 66 (B earned here) | |
| Execute closeout: extract + carry-forward merge | GSD-correct; B earned when WARN-03 verified | ✓ |

**User's choice:** No `66-LEARNINGS.md` at discuss; pointer in CONTEXT only; full file at execute via extract + assessment carry-forward.

---

## Claude's Discretion

- Module file layout, preflight strictness for `test/tmp/`, CI contract test file placement.

## Deferred Ideas

- Full-suite WAE CI gate (Phase 68)
- Auto-fix inventory command
- Baseline rows duplicated into VerificationLanes
