---
phase: 28-dx-mix-ci-alias-velocity-closeout
verified: 2026-06-17T20:00:00Z
status: passed
score: 10/10 must-haves verified
re_verification:
  previous_status: gaps_found
  previous_score: 8/10
  gaps_closed:
    - "The proof document contains a critical-path headline ≤ ~15 min (VELO-01): 28-VELOCITY-PROOF.md now carries 7m38s MEASURED (458s) from real run 27709716751 — replacing '~23min projected'. VELO-01 MET."
    - "REQUIREMENTS.md traceability updated: DX-01 and VELO-01 both show [x] Complete in the checkbox definitions (lines 39, 44) and | Complete | in the traceability table (lines 88-89)."
  gaps_remaining: []
  regressions: []
---

# Phase 28: DX `mix ci` alias + velocity closeout — Verification Report (Re-verification)

**Phase Goal:** A contributor can reproduce the full merge gate locally with one command, and the milestone's headline velocity outcome is proven with real before/after timing.
**Verified:** 2026-06-17T20:00:00Z
**Status:** passed
**Re-verification:** Yes — gap closure after initial gaps_found (8/10)

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A contributor runs `mix ci` and it executes the full merge-gating lane set and exits non-zero on any gate failure | VERIFIED | `lib/mix/tasks/scoria.ci.ex` 227 lines; `run_full/0` executes preamble + all gating lanes, calls `aggregate_and_halt/1` which calls `System.halt(1)` on any non-zero result |
| 2 | When pgvector is absent, `mix ci` hard-fails (non-zero) with actionable `Next step:` block — never silently skips a merge-gating lane | VERIFIED | `run_preflight/0` calls `System.halt(1)` directly on non-zero; `Next step:` microcopy block printed with `mix scoria.pgvector.bootstrap` instruction; no lanes run on preflight failure |
| 3 | `mix ci --skip-optional` prints which lanes were skipped, stamps `RESULT: PARTIAL ... NOT a merge-gate pass`, and STILL exits non-zero | VERIFIED | `run_skip_optional/0` prints skipped lane list, stamps the exact `RESULT: PARTIAL (knowledge, semantic_fast_path, connector skipped — NOT a merge-gate pass)` string, calls `System.halt(1)` unconditionally |
| 4 | The step list is derived from `Scoria.VerificationLanes` (not hardcoded) and the byte-order contract tests stay green | VERIFIED | `gating_lane_ids/0` calls `VerificationLanes.closeout_order()`, `VerificationLanes.exclusions/1`, and `run_lanes/1` calls `VerificationLanes.command(id)` — no command strings duplicated |
| 5 | `docs/MAINTAINERS.md`, `docs/operator_verification.md`, and `README.md` document `mix ci` and the deliberate local-vs-CI asymmetry | VERIFIED | MAINTAINERS.md has `### Local merge gate: mix ci` section (line 90) with full asymmetry note AND now also documents compile-only ratchet capture + `capture_parity_test.exs` reference (lines 41, 81); operator_verification.md line 298 mentions `mix ci`; README.md line 286 mentions `mix ci` |
| 6 | `28-VELOCITY-PROOF.md` exists (≥40 lines) with pinned before/after run IDs AND raw `gh run view --json` JSON captured inline | VERIFIED | File is 271 lines; before run 27508317719 + Phase-23 after run 27514007418 + measured parallelized run 27709716751 all present with full inline JSON; `grep -E '"(jobs\|databaseId)"'` confirms JSON blocks present |
| 7 | Critical-path is computed honestly per D-D2 (sum of stage maxima along dependency chain, active run time, not billable minutes) | VERIFIED | `28-VELOCITY-PROOF.md` walks `policy (19s) + build (20s) + max(parallel lanes: 417s verify/test) + verify-summary (2s)` using `completedAt − startedAt` per job; Honesty Caveats section (6 caveats) present and updated; both "local-only" and "post-push pending" caveats resolved |
| 8 | `.planning/MILESTONES.md` carries a v3.1 headline (with before/after run IDs) above v3.0 | VERIFIED | v3.1 at line 3–21, v3.0 at line 24; headline contains `77m→**7m38s MEASURED**`, run IDs 27508317719 and 27709716751, and `28-VELOCITY-PROOF.md` citation; the word "projected" does not appear in the v3.1 velocity headline |
| 9 | The critical-path headline is ≤ ~15 min (VELO-01 phase goal: "prove ≤~15m") | VERIFIED | `28-VELOCITY-PROOF.md` headline (line 8): `7m38s measured (458s)` from real, green, warm-cache GitHub Actions run 27709716751 (commit 06cdc34, 2026-06-17). MEASURED critical path = 19 + 20 + 417 + 2 = 458s = 7m38s ≤ 15 min. VELO-01 MET. |
| 10 | REQUIREMENTS.md traceability updated to show DX-01 and VELO-01 as Complete | VERIFIED | DX-01: `[x]` (line 39), `| DX-01 | Phase 28 | Complete |` (line 88). VELO-01: `[x]` (line 44), `| VELO-01 | Phase 28 | Complete |` (line 89). Footer updated: "Last updated: 2026-06-17 — DX-01 and VELO-01 flipped to Complete; measured 7m38s critical path in run 27709716751 (Plan 28-03)" |

**Score:** 10/10 truths verified

---

## Gap Closure Verification (Previously Failed Items)

### Gap 1 (CLOSED): VELO-01 target demonstrated

**Previous state:** 28-VELOCITY-PROOF.md stated ~23min projected; fully-parallelized topology (Phases 24-26) had never been pushed to GitHub; no real GitHub Actions run existed.

**Current state:** Run 27709716751 (commit 06cdc34, 2026-06-17) is a REAL, GREEN, warm-cache GitHub Actions run of the fully-parallelized topology (Phases 23-28 applied, including Plan 28-03 Task A compile-only ratchet fix). The proof document carries:
- Headline: `7m38s measured (458s)` — not "projected"
- Immutable URL: `https://github.com/szTheory/scoria/actions/runs/27709716751`
- Raw `gh run view --json` JSON inline (retention-durable)
- D-D2 computation: `policy (19s) + build (20s) + max(parallel lanes: 417s verify/test) + verify-summary (2s) = 458s = 7m38s`
- Warm-cache confirmed: `verify / build` step "Restore deps + build cache" was a Cache HIT

**Root cause closed:** The ratchet lane was cut from ~19m07s (1147s) to 1m46s (106s) by making `capture_output_standalone!/0` compile-only (`mix do compile --force + test --only __ratchet_compile_only__`). The ratchet no longer runs the entire test suite; it compiles `lib/` and all test files but executes zero tests. WARN-06 gate integrity maintained and parity-tested.

**VELO-01 MET: 7m38s ≤ ~15m target.**

### Gap 2 (CLOSED): REQUIREMENTS.md traceability updated

**Previous state:** Both DX-01 and VELO-01 showed `[ ] Pending` in checkbox definitions and traceability table.

**Current state:** 
- DX-01: `[x]` (line 39), `| Complete |` (traceability line 88)
- VELO-01: `[x]` (line 44), `| Complete |` (traceability line 89)
- Footer timestamp updated to 2026-06-17 with explicit confirmation of the flip and the measured run ID

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/scoria.ci.ex` | Mix.Tasks.Scoria.Ci, ≥80 lines, SSOT-driven | VERIFIED | 227 lines; `defmodule Mix.Tasks.Scoria.Ci`; uses `VerificationLanes.closeout_order/0`, `command/1`, `exclusions/1` |
| `mix.exs` | `ci: ["scoria.ci"]` alias | VERIFIED | Line 115: `ci: ["scoria.ci"]` (single-element delegating list) |
| `docs/MAINTAINERS.md` | Contains `mix ci`, local-vs-CI asymmetry, compile-only ratchet, `capture_parity_test` reference | VERIFIED | Lines 41, 81: compile-only documentation and `capture_parity_test.exs` reference present |
| `docs/operator_verification.md` | Contains `mix ci` | VERIFIED | Line 298 |
| `README.md` | Contains `mix ci` | VERIFIED | Line 286 |
| `lib/scoria/warning_inventory.ex` | `capture_output_standalone!/0` is compile-only (force-recompiles lib/ + compiles test files, runs zero tests) | VERIFIED | Lines 197-218: argv is `["do", "compile", "--force", "+", "test", "--only", "__ratchet_compile_only__"]` with `env: [{"MIX_ENV", "test"}]` and `stderr_to_stdout: true`; `--warnings-as-errors` absent; code comments explain WHY `--force` is retained |
| `test/scoria/warning_inventory/capture_parity_test.exs` | Parity guard: optimized capture surfaces same high-signal unclassified warnings; clean tree passes | VERIFIED | 115 lines; `@moduletag :ratchet_parity`; test 1 injects `@_parity_unused_attr` in `test/scoria/__ratchet_parity_tmp_test.exs`, runs the argv, filters `cluster_id == :unclassified_compile AND high_signal_path?`, asserts injected warning IS caught; test 2 asserts clean tree yields zero offenders; `on_exit` cleanup present |
| `28-VELOCITY-PROOF.md` | ≥40 lines, MEASURED critical path headline, before/after/measured run IDs, inline JSON, no "~23min projected" as headline | VERIFIED | 271 lines; headline is `7m38s measured`; three run JSONs inline (27508317719, 27514007418, 27709716751); `actions/runs/27709716751` URL present; "~23min projected" does not appear as the headline (the original projection sections are preserved for history but the headline and summary tables reflect the measured run) |
| `.planning/MILESTONES.md` | v3.1 headline carries measured number (not "projected"), new run ID, above v3.0 | VERIFIED | Line 7: `77m→**7m38s MEASURED**` with `measured 27709716751 commit 06cdc34 — VELO-01 MET`; above v3.0 at line 24; "projected" does not appear in the velocity headline |
| `.planning/REQUIREMENTS.md` | DX-01 `[x]` Complete, VELO-01 `[x]` Complete | VERIFIED | Lines 39, 44: both `[x]`; lines 88-89: both `| Complete |`; footer updated 2026-06-17 |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `mix.exs aliases/0` | `Mix.Tasks.Scoria.Ci` | `ci: ["scoria.ci"]` | WIRED | Line 115 confirmed |
| `lib/mix/tasks/scoria.ci.ex` | `Scoria.VerificationLanes` | `closeout_order/0 + command/1 + exclusions/1` | WIRED | Lines 191-192, 197; all three functions used |
| `lib/mix/tasks/scoria.ci.ex` | `mix scoria.pgvector.bootstrap --check` | preflight probe | WIRED | Line 163: `System.cmd("sh", ["-c", "mix scoria.pgvector.bootstrap --check"], ...)` |
| `capture_output_standalone!/0` | compile-only argv | `["do", "compile", "--force", "+", "test", "--only", "__ratchet_compile_only__"]` | WIRED | `lib/scoria/warning_inventory.ex` line 212 |
| `capture_parity_test.exs` | `Scoria.WarningInventory.parse_output/1 + classify/1` | direct call in test | WIRED | Lines 70-75: `WarningInventory.parse_output(output) |> WarningInventory.classify()` then filter on `cluster_id == :unclassified_compile` |
| `capture_parity_test.exs` | `Scoria.WarningRatchet.high_signal_path?/1` | filter in test | WIRED | Line 74: `WarningRatchet.high_signal_path?(row.file)` |
| `.planning/MILESTONES.md` | `28-VELOCITY-PROOF.md` | measured critical-path headline + run ID 27709716751 | WIRED | Line 7: run ID and proof citation present |
| `28-VELOCITY-PROOF.md` | GitHub Actions run 27709716751 | immutable URL + inline JSON | WIRED | Lines 114-115, 188: URL and raw JSON present; `"databaseId":27709716751` in inline JSON |

---

## Data-Flow Trace (Level 4)

Not applicable — this phase produces CI tooling, planning artifacts, and documentation (no runtime components rendering dynamic data from a database).

---

## Behavioral Spot-Checks

Step 7b: Key static-analysis checks run in lieu of live execution.

| Behavior | Check | Result | Status |
|----------|-------|--------|--------|
| `capture_output_standalone!/0` has `--force` | `grep -Eq '"compile",\s*"--force"' lib/scoria/warning_inventory.ex` | MATCH at line 212 | PASS |
| `capture_output_standalone!/0` has `--only` tag | `grep -Eq '"test",\s*"--only"' lib/scoria/warning_inventory.ex` | MATCH at line 212 | PASS |
| `__ratchet_compile_only__` tag unused in test/ (outside warning_inventory) | `grep -rn "@tag :__ratchet_compile_only__\|@moduletag :__ratchet_compile_only__" test/ \| grep -v "warning_inventory" \| wc -l` | 0 | PASS |
| MILESTONES.md v3.1 headline does not contain "projected" | `grep "7m38s" MILESTONES.md` | `7m38s MEASURED` | PASS |
| REQUIREMENTS.md DX-01 traceability row | `grep "| DX-01 | Phase 28 | Complete |"` | MATCH at line 88 | PASS |
| REQUIREMENTS.md VELO-01 traceability row | `grep "| VELO-01 | Phase 28 | Complete |"` | MATCH at line 89 | PASS |
| Parity test injects and asserts on `__ratchet_parity_tmp` | file read | `assert Enum.any?(offender_files, &String.contains?(&1, "__ratchet_parity_tmp"))` at line 79 | PASS |
| MAINTAINERS.md documents compile-only ratchet + parity guard | `grep -iq 'compile-only\|capture_parity'` | MATCH at lines 41, 81 | PASS |

Full behavioral test (`MIX_ENV=test mix test test/scoria/warning_inventory/capture_parity_test.exs`): SKIPPED — requires a live pgvector Postgres environment. The parity test code is substantive and correct by static analysis; the CI ratchet lane in run 27709716751 executed step "Verify WARN-06 compile-only capture parity" (18:09:35Z → 18:10:17Z) GREEN, confirming the test passed in the real CI run.

---

## Probe Execution

Step 7c: No `probe-*.sh` scripts exist for this phase. SKIPPED.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| DX-01 | 28-01 | Single `mix ci` alias reproducing the merge gate locally | SATISFIED | `lib/mix/tasks/scoria.ci.ex` exists, wired, docs updated; REQUIREMENTS.md `[x]` Complete |
| VELO-01 | 28-02 / 28-03 | Warm-cache PR CI critical-path ≤ ~15 min proven via `gh run` timing | SATISFIED | 28-VELOCITY-PROOF.md headline: 7m38s MEASURED from run 27709716751; D-D2 computation: 458s = 7m38s ≤ 15m; REQUIREMENTS.md `[x]` Complete |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/mix/tasks/scoria.ci.ex` | 139 | Hardcoded PARTIAL message that can drift from `@optional_lane_ids` | Info | Pre-existing IN-02 from 28-REVIEW.md — not introduced by Plan 28-03; no new anti-patterns introduced by gap closure |

No TBD/FIXME/XXX debt markers found in the files modified by Plan 28-03 (`lib/scoria/warning_inventory.ex`, `test/scoria/warning_inventory/capture_parity_test.exs`, `docs/MAINTAINERS.md`, `28-VELOCITY-PROOF.md`, `.planning/MILESTONES.md`, `.planning/REQUIREMENTS.md`).

---

## Human Verification Required

None. All gaps closed programmatically:
- VELO-01 is proven by a real GitHub Actions run with inline JSON (not a local claim)
- REQUIREMENTS.md updates are directly observable in file content
- The parity test's CI-run green result is captured in the inline JSON at job `verify / ratchet`, step "Verify WARN-06 compile-only capture parity" (18:09:35Z → 18:10:17Z, conclusion: success)

---

## Gaps Summary

No gaps remain. Both previously failing truths are now VERIFIED:

**Truth 9 (CLOSED):** The VELO-01 target is now demonstrated by a real, measured, warm-cache GitHub Actions run (27709716751, commit 06cdc34). Critical path = 7m38s (458s) ≤ ~15m target. The ratchet compile-only optimization (Plan 28-03 Task A) cut the ratchet lane from ~19m07s to 1m46s, removing the bottleneck that caused the original ~23min projection.

**Truth 10 (CLOSED):** REQUIREMENTS.md shows both DX-01 and VELO-01 as `[x]` with `| Complete |` in the traceability table.

Phase 28 goal is fully achieved: a contributor can reproduce the full merge gate locally with `mix ci`, and the milestone's headline velocity outcome is proven with a real before/after GitHub Actions timing of 7m38s critical path (down from ~76min serial baseline).

---

*Verified: 2026-06-17T20:00:00Z*
*Verifier: Claude (gsd-verifier) — re-verification after Plan 28-03 gap closure*
