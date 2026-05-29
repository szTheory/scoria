---
status: passed
phase: 80-upgrade-smoke-in-adoption-lane
verified: 2026-05-29T21:45:00Z
requirements:
  - HEX-UPGRADE-01
---

# Phase 80 Verification

## Goal

Merge-blocking adoption lane proves **content-revision upgrade** from committed `v0.1.0` baseline tarball to current `mix hex.build --unpack` artifact on the **same** generated Phoenix host — baseline install → compliant `--check` → dep bump → operator chain → re-smoke — without a second `phx.new`. Close HEX-UPGRADE-01 at milestone level.

**Scope note (D-55):** Phase 80 = pre-publish **content-revision** upgrade (path tarball swap at same semver). Phase 81 = live registry **semver** upgrade (`0.1.0` → `0.1.x+1`).

## Requirement traceability

| Requirement | Phase 80 delivery | Status | Evidence |
|-------------|-------------------|--------|----------|
| **HEX-UPGRADE-01** | Same host installs at v0.1.0 fixture, baseline smokes + check, bumps to HEAD tarball, dry-run/check/apply/migrate chain, full overlay re-smoke | **Complete** | `host_app_upgrade_proof_test.exs` with `run_upgrade_proof!/2`; `mix test.adoption` green (52 tests) |

Cross-reference with `.planning/REQUIREMENTS.md` traceability table: `HEX-UPGRADE-01 | 80 | Complete`.

## Success criteria

| # | Criterion | Verified | Evidence |
|---|-----------|----------|----------|
| 1 | Generated host installs at pinned `0.1.0`, passes baseline overlay smokes and compliant `--check` | **PASS** | Baseline phase: route + runtime overlays from v0.1.0 fixture; `scoria_install_check` compliant trailer |
| 2 | Bump to current tarball runs `--dry-run` → `--check` → apply → migrate → compliant `--check` | **PASS** | Upgrade phase steps `:scoria_install_dry_run`, `:scoria_install_check_pre_apply`, `:scoria_install`, `:ecto_migrate`, `:scoria_install_check` all green |
| 3 | Overlay smokes pass after upgrade without host regeneration | **PASS** | Post-upgrade overlay smoke: handoff + route + runtime (HEAD overlays refreshed after `:bump_dep`) |
| 4 | Migration ordering bugs on existing schema caught | **latent** | 24 identical core migrations at v0.1.0 and HEAD — post-upgrade `ecto.migrate` is no-op today. Contract: when `published_version() > baseline_upgrade_version()` OR new core migration basenames diverge from fixture, post-upgrade migrate must record new versions in `schema_migrations` (future `pending_core_migrations/1` helper) |

## Plan must_haves

### 80-01 — Baseline fixture + contract APIs

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| Committed v0.1.0 unpack fixture (D-50) | PASS | `test/fixtures/hex_consumer/scoria-0.1.0-unpack/` |
| `baseline_unpack_root!/0`, `baseline_package_fingerprint/0`, `same_semver_content_upgrade?/0` (D-51, D-54) | PASS | `HexConsumerContract` APIs; upgrade test asserts fingerprints differ |
| Drift stamp + refresh task (D-52) | PASS | `.scoria-hex-baseline.stamp`; `mix scoria.hex_consumer.refresh_baseline_fixture` |

### 80-02 — Runner upgrade orchestration

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| `run_upgrade_proof!/2` separate from `run_full_proof!/1` (D-57) | PASS | Two-phase baseline then upgrade on same host |
| `expected_upgrade_steps/1` exact flat list (D-58) | PASS | `proof.steps == Runner.expected_upgrade_steps(host)` |
| Installer tri-state trailers (D-60) | PASS | Compliant baseline/post; pre-apply accepts drift or compliant when install surfaces unchanged |
| MANIFEST upgrade context (D-67) | PASS | `baseline_unpack`, `current_unpack`, `upgrade_phase` in failure snapshot |

### 80-03 — Adoption lane + closeout

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| `host_app_upgrade_proof_test.exs` with `:host_upgrade` tag (D-61, D-62) | PASS | `@moduletag :host_upgrade`, `timeout: 180_000` |
| Registered in `mix test.adoption` (D-61) | PASS | `@adoption_test_files` + `test.adoption_test.exs` guard |
| Consumer module unchanged (D-63) | PASS | `host_app_consumer_proof_test.exs` untouched; `:host_proof` ~61s |
| HEX-UPGRADE-01 Complete ceremony (D-68) | PASS | This file + REQUIREMENTS + ROADMAP + STATE |

## Automated verification

| Command | Result | Wall time |
|---------|--------|-----------|
| `MIX_ENV=test mix test --only host_upgrade` | PASS — 1 test, 0 failures | ~64s |
| `MIX_ENV=test mix test test/scoria/host_app_upgrade_proof_test.exs` | PASS — 1 test, 0 failures | ~64s |
| `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs` | PASS — 1 test, 0 failures | ~0.2s |
| `MIX_ENV=test mix test.adoption` | PASS — 52 tests, 0 failures | ~116s |

**Timing observation (D-37):** Upgrade proof warm run ~64s; full adoption lane ~116s — both under 120s CI escalation threshold. No timeout bump to 240_000 required. Consumer `:host_proof` unchanged at ~61s.

## Upgrade step contract

Baseline overlays (v0.1.0 fixture — route + runtime):

```
[:deps_get, :scoria_install, :ecto_create, :ecto_migrate,
 :host_route_smoke_test, :host_runtime_smoke_test, :scoria_install_check]
```

Upgrade chain + HEAD overlays (handoff + route + runtime):

```
[:bump_dep, :deps_get, :scoria_install_dry_run, :scoria_install_check_pre_apply,
 :scoria_install, :ecto_migrate, :scoria_install_check,
 :host_handoff_smoke_test, :host_route_smoke_test, :host_runtime_smoke_test]
```

## Gaps

**None for Phase 80 scope.** Intentional deferrals (not gaps):

- Criterion #4 migration ordering proof — **latent** until first post-0.1.0 core migration ships
- Phase 81: live Hex registry post-publish gate (HEX-REGISTRY-01)
- Phase 82: README/operator prose sweep (DOCS-HEX-01 prose Complete)
- `post_baseline_version/0` strict semver assertions (D-56) — when release-please bumps past `0.1.0`

## Human verification

| Item | Status | Notes |
|------|--------|-------|
| Pre-apply check accepts compliant when install surfaces identical | **Verified** | Content-revision upgrade at same semver; drift expected only when router/runtime/migrations differ |
| Baseline overlays sourced from v0.1.0 fixture | **Verified** | HEAD handoff/runtime overlays incompatible with v0.1.0 dep; baseline uses fixture overlay copies |
| CI failure artifact on adoption lane failure | **Inherited from Phase 79** | `tmp/scoria-host-proof-last-failure/` upload unchanged |

## Verdict

Phase 80 goal **achieved**. All three plan waves delivered: committed v0.1.0 baseline fixture, runner upgrade orchestration with installer trailer assertions, and merge-blocking upgrade smoke in adoption lane with closeout ceremony. **HEX-UPGRADE-01 Complete.**

---
*Verified: 2026-05-29*
