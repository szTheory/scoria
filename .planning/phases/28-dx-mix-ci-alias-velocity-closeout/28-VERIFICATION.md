---
phase: 28-dx-mix-ci-alias-velocity-closeout
verified: 2026-06-17T00:00:00Z
status: gaps_found
score: 8/10 must-haves verified
gaps:
  - truth: "The proof document contains a critical-path headline ≤ ~15 min (the VELO-01 phase goal)"
    status: failed
    reason: "28-VELOCITY-PROOF.md states a projected critical path of ~23min, not ≤~15min. The 'after' run used (27514007418) reflects only Phase 23 (build-once); Phases 24-26 (knowledge fix, lane parallelization, sharding) were implemented locally but never pushed to GitHub and never triggered a GitHub Actions run with the fully-parallelized topology. The plan's own must_have artifact check requires 'a headline wall-clock number ≤ ~15.' The measured/projected number is ~23min. The MILESTONES.md headline reads '77m→~23min projected' — honest, but not the target."
    artifacts:
      - path: ".planning/phases/28-dx-mix-ci-alias-velocity-closeout/28-VELOCITY-PROOF.md"
        issue: "Headline critical-path number is ~23min (projected), not ≤~15min. The fully-parallelized topology (Phases 24-26) has no real GitHub Actions run to cite."
      - path: ".planning/MILESTONES.md"
        issue: "v3.1 headline reads '77m→~23min projected', not ≤~15min. The VELO-01 requirement states ≤~15min."
    missing:
      - "A real GitHub Actions run of the fully-parallelized topology (Phases 24-26 merged + pushed) whose measured critical path is ≤~15min"
      - "OR an explicit downward revision of the VELO-01 target to ~23min, accepted by the developer as satisfying the milestone goal"
  - truth: "REQUIREMENTS.md traceability table shows DX-01 and VELO-01 as Complete (not Pending)"
    status: failed
    reason: "REQUIREMENTS.md still shows 'Pending' for both DX-01 and VELO-01 in the traceability table (lines 88-89). DX-01 is functionally complete in the codebase; VELO-01 has an honesty gap. The REQUIREMENTS.md was not updated to reflect completion status."
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "Traceability table rows for DX-01 (Phase 28) and VELO-01 (Phase 28) both show 'Pending'; the checkboxes in the requirement definitions are also unchecked ([ ])."
    missing:
      - "Update the [ ] checkboxes for DX-01 and VELO-01 to [x]"
      - "Update the traceability table status for DX-01 to 'Complete' (VELO-01 status depends on gap closure above)"
---

# Phase 28: DX `mix ci` alias + velocity closeout — Verification Report

**Phase Goal:** DX `mix ci` alias + velocity closeout — one local command mirroring the gate; prove ≤~15m warm-cache critical path via before/after `gh run` timing.
**Verified:** 2026-06-17T00:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Previous Verification (Plan 02 back-reference doc)

The existing `28-VERIFICATION.md` was a plan-02 completion record (status: complete), not a
phase-level goal-backward verification. This document replaces and supersedes it as the
canonical phase verification with proper `status:` frontmatter.

Back-reference to timing proof is preserved: **`28-VELOCITY-PROOF.md`** (same directory)

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A contributor runs `mix ci` and it executes the full merge-gating lane set and exits non-zero on any gate failure | VERIFIED | `lib/mix/tasks/scoria.ci.ex` 227 lines; `run_full/0` executes preamble + all gating lanes, calls `aggregate_and_halt/1` which calls `System.halt(1)` on any non-zero result |
| 2 | When pgvector is absent, `mix ci` hard-fails (non-zero) with actionable `Next step:` block — never silently skips a merge-gating lane | VERIFIED | `run_preflight/0` calls `System.halt(1)` directly on non-zero; `Next step:` microcopy block printed with `mix scoria.pgvector.bootstrap` instruction; no lanes run on preflight failure |
| 3 | `mix ci --skip-optional` prints which lanes were skipped, stamps `RESULT: PARTIAL ... NOT a merge-gate pass`, and STILL exits non-zero | VERIFIED | `run_skip_optional/0` prints skipped lane list, stamps the exact `RESULT: PARTIAL (knowledge, semantic_fast_path, connector skipped — NOT a merge-gate pass)` string, calls `System.halt(1)` unconditionally |
| 4 | The step list is derived from `Scoria.VerificationLanes` (not hardcoded) and the byte-order contract tests stay green | VERIFIED | `gating_lane_ids/0` calls `VerificationLanes.closeout_order()`, `VerificationLanes.exclusions/1`, and `run_lanes/1` calls `VerificationLanes.command(id)` — no command strings duplicated; SUMMARY reports both contract test suites green |
| 5 | `docs/MAINTAINERS.md`, `docs/operator_verification.md`, and `README.md` document `mix ci` and the deliberate local-vs-CI asymmetry | VERIFIED | MAINTAINERS.md has `### Local merge gate: mix ci` section (line 90) with full asymmetry note; operator_verification.md line 298 mentions `mix ci`; README.md line 286 mentions `mix ci` |
| 6 | `28-VELOCITY-PROOF.md` exists (≥40 lines) with pinned before/after run IDs AND raw `gh run view --json` JSON captured inline | VERIFIED | File is 230 lines; before run 27508317719 + after run 27514007418 both present with full inline JSON; `grep -E '"(jobs\|databaseId)"'` confirms both JSON blocks present |
| 7 | Critical-path is computed honestly per D-D2 (sum of stage maxima along dependency chain, active run time, not billable minutes) | VERIFIED | `28-VELOCITY-PROOF.md` walks `policy (179s) + build (19s) + max(parallel lanes: 1147s ratchet) + verify-summary (30s)` using `completedAt − startedAt` per job; honesty caveats section present (6 caveats) |
| 8 | `.planning/MILESTONES.md` carries a v3.1 headline (with before/after run IDs) above v3.0 | VERIFIED | v3.1 at line 3, v3.0 at line 22; headline contains `77m`, run IDs 27508317719 and 27514007418, and `28-VELOCITY-PROOF.md` citation |
| 9 | The critical-path headline is ≤ ~15 min (VELO-01 phase goal: "prove ≤~15m") | FAILED | Headline is ~23min projected. The after-run (27514007418) is Phase 23 only; Phases 24-26 not pushed to GitHub; no real GitHub Actions run of the fully-parallelized topology exists. The plan explicitly required "headline wall-clock number ≤ ~15" per the artifact must_have. ~23min > 15min. |
| 10 | REQUIREMENTS.md traceability updated to show DX-01 and VELO-01 as Complete | FAILED | Both show `Pending` with unchecked `[ ]` checkboxes in the traceability table |

**Score:** 8/10 truths verified

---

## Deferred Items

None identified — the VELO-01 gap is a real gap, not a later-phase deferral. No later phase in
the roadmap is scoped to achieve ≤~15m CI critical path.

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/scoria.ci.ex` | Mix.Tasks.Scoria.Ci, ≥80 lines, SSOT-driven | VERIFIED | 227 lines; `defmodule Mix.Tasks.Scoria.Ci`; uses `VerificationLanes.closeout_order/0`, `command/1`, `exclusions/1` |
| `mix.exs` | `ci: ["scoria.ci"]` alias | VERIFIED | Line 115: `ci: ["scoria.ci"]` (single-element delegating list, bare atom key) |
| `docs/MAINTAINERS.md` | Contains `mix ci` and local-vs-CI asymmetry | VERIFIED | `### Local merge gate: mix ci` section at line 90; asymmetry documented at line 113-115 |
| `docs/operator_verification.md` | Contains `mix ci` | VERIFIED | Line 298 |
| `README.md` | Contains `mix ci` | VERIFIED | Line 286 |
| `28-VELOCITY-PROOF.md` | ≥40 lines, before/after run IDs, inline JSON, `27508317719\|baseline run unavailable` | VERIFIED | 230 lines; run ID 27508317719 present; both JSON blocks inline |
| `.planning/MILESTONES.md` | `v3.1` headline above `v3.0`; contains `77m` | VERIFIED | v3.1 at line 3 (above v3.0 at line 22); `77m` present in velocity headline |
| `28-VERIFICATION.md` | Back-references `28-VELOCITY-PROOF.md` | VERIFIED | This document back-references `28-VELOCITY-PROOF.md` in the previous verification section and in the frontmatter history |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `mix.exs aliases/0` | `Mix.Tasks.Scoria.Ci` | `ci: ["scoria.ci"]` | WIRED | Line 115: exact single-element delegating list |
| `lib/mix/tasks/scoria.ci.ex` | `Scoria.VerificationLanes` | `closeout_order/0 + command/1 + exclusions/1` | WIRED | Lines 191-192, 197; all three functions used in `gating_lane_ids/0` and `run_lanes/1` |
| `lib/mix/tasks/scoria.ci.ex` | `mix scoria.pgvector.bootstrap --check` | preflight probe | WIRED | Line 163: `System.cmd("sh", ["-c", "mix scoria.pgvector.bootstrap --check"], ...)` |
| `.planning/MILESTONES.md` | `28-VELOCITY-PROOF.md` | before/after run IDs headline | WIRED | Line 7: `77m` and both run IDs in velocity headline with citation to `28-VELOCITY-PROOF.md` |
| `28-VERIFICATION.md` | `28-VELOCITY-PROOF.md` | back-reference | WIRED | This document; also in previous plan-02 content |

---

## Code Review Findings (28-REVIEW.md) — Impact on Must-Haves

The code review flagged 2 warnings. Assessment of their impact on must-have truths:

**WR-01 (WARNING): Connector lane uses `command/1` not `ci_command/1`**
- The plan's design contract explicitly required `VerificationLanes.command(id)` (the local command string). WR-01 notes that `command(:connector)` returns `"mix test.connector"` while `ci_command(:connector)` returns `"mix test.connector --warnings-as-errors"`, creating a weaker local check.
- Impact on must-haves: The must-have truth "step list derived from `VerificationLanes`" is satisfied — the code does call `VerificationLanes.command(id)`. However, the meta-goal "a green that never lies" is weakened: a local connector PASS does not guarantee a CI connector PASS.
- Verdict: Non-blocking for the verification gate (the plan chose `command/1` not `ci_command/1` by design), but a genuine correctness gap worth tracking. Does not fail any must-have truth as written.

**WR-02 (WARNING): No `preferred_env` for `scoria.ci` in `mix.exs cli/0`**
- `"scoria.ci"` and `"ci"` are absent from `preferred_envs`. Subprocesses for `:adoption` and `:runtime_to_handoff` lanes will fail if `MIX_ENV` is not set by the caller (defaults to `dev` in a fresh shell; `mix test` requires `:test`).
- Impact on must-haves: This is a latent runtime failure. The must-have "runs full gate set" could silently fail in a fresh shell where `MIX_ENV` is not set. However, the `:semantic_fast_path` lane already inlines `MIX_ENV=test`, and the most common contributor use case (running from an existing dev shell) typically has MIX_ENV set or the lane commands themselves set it.
- Verdict: Non-blocking for the gate as verified by code inspection, but a correctness gap. Recommend adding `"scoria.ci": :test` to `preferred_envs`.

---

## Behavioral Spot-Checks

Step 7b: SKIPPED — Running `mix ci` requires a live pgvector Postgres on :55432 and the full
Elixir build environment. Cannot execute without starting services. The implementation logic
is verified by static analysis of the code paths above.

---

## Probe Execution

Step 7c: SKIPPED — No `probe-*.sh` scripts exist for this phase.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| DX-01 | 28-01 | Single `mix ci` alias reproducing the merge gate locally | SATISFIED (functionally) | `lib/mix/tasks/scoria.ci.ex` exists, wired, docs updated; REQUIREMENTS.md traceability not yet updated to Complete |
| VELO-01 | 28-02 | Warm-cache PR CI critical-path ≤ ~15 min proven via `gh run` timing | PARTIALLY SATISFIED | Proof doc exists and is honest; projected ~23min from architecture+timing is documented with honesty caveats; but the ≤~15min target is not met and no real parallelized run exists |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/mix/tasks/scoria.ci.ex` | 139 | Hardcoded PARTIAL message that can drift from `@optional_lane_ids` | Info | IN-02 from 28-REVIEW.md: runtime-generated skip list and hardcoded RESULT string can diverge if `@optional_lane_ids` changes; no test guards the two strings are consistent |

No TBD/FIXME/XXX debt markers found in the phase's files.

---

## Human Verification Required

None required. All gaps are programmatically observable (numeric target miss, REQUIREMENTS.md
status not updated).

---

## Gaps Summary

**Gap 1 (BLOCKER): VELO-01 target not demonstrated**

The phase goal is to "prove ≤~15m warm-cache critical path." The actual proof documents ~23min projected. The underlying reason is structural: Phases 24-26 (knowledge lane fix, lane parallelization, sharding) were implemented locally but never pushed to GitHub, so no real GitHub Actions run of the fully-parallelized topology exists. The honest projected critical path from step timing + architecture is ~23min — over the ≤~15min target by 8 minutes.

The VELO-01 must-have in the plan specifies "a headline wall-clock number ≤ ~15." This is not met.

Two resolution paths exist:
1. Push Phases 24-26 to GitHub, trigger a real parallelized CI run, capture the actual critical path with `gh run view --json`, and update `28-VELOCITY-PROOF.md` and MILESTONES.md if the measured number is ≤~15min.
2. Accept the ~23min projected outcome as the milestone's actual achievement (the ratchet lane is the remaining bottleneck), update VELO-01's target wording, and re-verify.

**Gap 2 (WARNING): REQUIREMENTS.md traceability not updated**

Both DX-01 and VELO-01 remain marked as `[ ] Pending` in REQUIREMENTS.md. DX-01 is
functionally complete and the checkbox should be updated. VELO-01 status depends on Gap 1 resolution.

---

*Verified: 2026-06-17*
*Verifier: Claude (gsd-verifier)*
