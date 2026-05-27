# Phase 64 Research — Adoption Lane Discoverability Sync

**Researched:** 2026-05-27  
**Phase:** 64 — Adoption Lane Discoverability Sync  
**Confidence:** HIGH

## Summary

Phase 64 closes the v2.5 audit integration gap `adoption-lane-discoverability-drift`. The **runtime SSOT** for the adoption lane file list is `Mix.Tasks.Scoria.Test.Adoption.adoption_test_files/0` in `lib/mix/tasks/test.adoption.ex`. Phase 61 added `report_test.exs` and `mode_equivalence_test.exs` to `@adoption_test_files` for the INST-08 thin slice, but `test/mix/tasks/test.adoption_test.exs` `expected_files` was not updated. The discoverability meta-test fails in isolation; `mix test.adoption` remains green because it runs the live list.

**Fix scope:** Test-only sync — update `expected_files` in `test/mix/tasks/test.adoption_test.exs` to match `adoption_test_files/0` exactly (order and membership). Do **not** change the lane task module unless a separate drift is found.

## Current State (Evidence)

| Artifact | `report_test.exs` | `mode_equivalence_test.exs` |
|----------|-------------------|----------------------------|
| `lib/mix/tasks/test.adoption.ex` `@adoption_test_files` | present | present |
| `test/mix/tasks/test.adoption_test.exs` `expected_files` | **missing** | **missing** |

`[VERIFIED: codebase]` `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs` → **1 failure** at line 30 (`==` on file lists).

`[VERIFIED: codebase]` `MIX_ENV=test mix test.adoption` → lane green (77 tests per v2.5 audit).

### Audit gap (v2.5-MILESTONE-AUDIT.md)

```yaml
- id: adoption-lane-discoverability-drift
  severity: low
  requirements: [INST-08]
  evidence: discoverability test fails in isolation; runtime lane passes
```

### Roadmap success criteria

1. `expected_files` matches `adoption_test_files/0`
2. `mix test test/mix/tasks/test.adoption_test.exs` passes in isolation
3. `mix test.adoption` remains green

## Recommended Approach

**Single plan, single file change:**

1. In `test/mix/tasks/test.adoption_test.exs`, insert into `expected_files` after `"test/scoria/install/planner_test.exs"`:
   - `"test/scoria/install/report_test.exs"`
   - `"test/scoria/install/mode_equivalence_test.exs"`
2. Preserve list order identical to `@adoption_test_files` in `lib/mix/tasks/test.adoption.ex`.
3. Keep existing exclusion assertions (`refute` knowledge/semantic_cache paths) unchanged — they still hold.

**Non-goals (ROADMAP + milestone):**

- No new lane files or fourth verification lane
- No doc sweep unless adoption_surface pins break (unlikely — pins are substring-based on operator docs, not file list)
- No changes to `VerificationLanes` registry

## Pattern Reference

Discoverability contract pattern established in Phase 54 (`test.runtime_to_handoff_test.exs`) and mirrored in `test.semantic_fast_path_test.exs`:

- `Mix.Task.load_all()` before assertions
- Assert `function_exported?` for `*_test_files/0` and wrapper `run/1`
- Assert `Module.*_test_files() == expected_files` (hard-coded list must match SSOT module attribute)
- Assert `Mix.Task.get/1` for both `scoria.test.*` and `test.*` aliases

Phase 61 added INST-08 installer proofs to the adoption lane; discoverability test lag is the only remaining drift.

## Risks

| Risk | Mitigation |
|------|------------|
| Wrong insertion order breaks `==` | Copy order verbatim from `lib/mix/tasks/test.adoption.ex` |
| Accidentally editing lane SSOT | Only touch `test.adoption_test.exs` unless test reveals SSOT bug |
| Weakening exclusion assertions | Do not remove `refute` lines for knowledge/semantic paths |

## Validation Architecture

| Check | Command |
|-------|---------|
| Lists match | `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs` exits 0 |
| Lane green | `MIX_ENV=test mix test.adoption` exits 0 |
| Closeout order unchanged | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs` exits 0 |
| No duplicate drift | `rg 'report_test.exs' test/mix/tasks/test.adoption_test.exs` returns 1 match in expected_files block |

Quick run: `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs`  
Full slice: `MIX_ENV=test mix test.adoption && MIX_ENV=test mix test test/scoria/verification_lanes_test.exs`

## RESEARCH COMPLETE
