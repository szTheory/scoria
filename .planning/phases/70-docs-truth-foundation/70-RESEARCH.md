# Phase 70: Docs Truth Foundation — Research

**Researched:** 2026-05-28  
**Phase:** 70-docs-truth-foundation  
**Requirements:** DOCS-03, DOCS-04, INST-DX-01

## Summary

Phase 70 is a **docs-and-contract alignment** slice: replace milestone-as-shipped narrative in adopter docs with capability vocabulary, add a maintainer-only `install_contract` Mix lane (WIP already exists), and extend the CI gate map so semantic fast-path is explicitly **not** a PR CI step while planning `v2.x` vs Hex `0.1.0` namespaces are documented once for maintainers.

No CI topology or `VerificationLanes.closeout_order/0` changes. Executable SSOT patterns already exist from v2.4–v2.6 (`VerificationLanes`, `ci_policy_contract_test`, adoption lane file lists).

## Current State (grep-backed)

| Surface | Milestone drift | Action |
|---------|-----------------|--------|
| `README.md` L13, L222 | `Scoria is shipped through \`v2.1…\`` (banner + Status) | Replace with capability headline + 5 bullets; collapse Status |
| `README.md` Install | No `--check`/`--dry-run` upgrade subsection | Add D-10–D-13 subsection before Quickstart |
| `docs/semantic_fast_path.md` | Title/scope uses `v2.1` | Adopter copy → capability wording |
| `docs/operator_verification.md` | `v2.1` semantic wording; no lane matrix / version namespaces | Add table + Version namespaces + install_contract section |
| `test/scoria/adoption_surface_test.exs` L25 | Asserts milestone banner **present** | Invert via `Scoria.AdopterDocContract` |
| `lib/mix/tasks/scoria.test.install_contract.ex` | Exists (untracked) | Commit + `mix.exs` preferred_envs |
| `mix.exs` `cli/0` | No install_contract preferred_envs | Add both spellings |
| `test/mix/tasks/test.install_contract_test.exs` | Missing | Create per D-25 |

**Adoption lane SSOT** (`lib/mix/tasks/test.adoption.ex`): 12 files — already excludes `report_test`, `mode_equivalence_test`, `install_check_test`, `planner_test`. `install_test.exs` stays in adoption **and** install_contract (intentional overlap per CONTEXT D-22).

## Recommended Plan Split (3 plans, 3 waves)

| Wave | Plan | Delivers |
|------|------|----------|
| 1 | 70-01 | `Scoria.AdopterDocContract`, install_contract task + mix.exs + `test.install_contract_test.exs` |
| 2 | 70-02 | README banner/install/status; semantic_fast_path adopter wording |
| 3 | 70-03 | operator_verification gate map + namespaces + install_contract doc; `adoption_surface_test` + `ci_policy_contract_test` |

## Key Patterns to Reuse

1. **Dual Mix registration:** `Mix.Tasks.Scoria.Test.*` + `Mix.Tasks.Test.*` wrapper in same file; `preferred_envs` in `mix.exs` `cli/0`.
2. **Doc SSOT split:** README teases + links; `docs/operator_verification.md` for maintainer/CI depth (see phase 63–64 plans).
3. **Policy tests as doc contracts:** `ci_policy_contract_test.exs` asserts substrings in operator guide (CI-03, WARN-06 precedents).
4. **Lane list tests:** `test/mix/tasks/test.adoption_test.exs` mirrors `@adoption_test_files` — replicate for install_contract.

## Validation Architecture

| Property | Value |
|----------|-------|
| Framework | ExUnit (Mix) |
| Quick run | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/ci_policy_contract_test.exs test/mix/tasks/test.install_contract_test.exs` |
| Lane spot-check | `MIX_ENV=test mix scoria.test.install_contract` |
| Full closeout | `SCORIA_DB_PORT=55432 mix test.adoption` then existing CI parity commands |
| Estimated quick runtime | ~30–90s (policy + surface tests) |

**Per-requirement verification:**

| REQ | Automated command | Manual |
|-----|-------------------|--------|
| DOCS-03 | `mix test test/scoria/adoption_surface_test.exs` (capability + refute milestone) | Read README banner once |
| DOCS-04 | `mix test test/scoria/ci_policy_contract_test.exs` | Scan CI gate map table |
| INST-DX-01 | `mix test test/mix/tasks/test.install_contract_test.exs` + `mix scoria.test.install_contract` | Confirm absent from README via adoption_surface refute |

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Re-introducing milestone banner via Status duplicate | Collapse Status to pre-Hex note only (D-05) |
| Readers think semantic lane untested in CI | Gate map Notes: full-suite WAE still covers semantic tests (D-28) |
| install_contract leaks to adopter docs | Refute in `AdopterDocContract`; doc only in operator guide (D-24) |

## RESEARCH COMPLETE
