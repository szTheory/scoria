---
status: passed
phase: 78-hex-consumer-contract-foundation
verified: 2026-05-29T20:00:00Z
score: 2/2 partial requirements delivered as scoped
requirements:
  - HEX-CONSUMER-01
  - DOCS-HEX-01
---

# Phase 78 Verification

> **Retro note (Phase 79 closeout):** HEX-CONSUMER-01 milestone **Complete** deferred to Phase 79 full overlay — see [79-VERIFICATION.md](../79-tarball-consumer-overlay-proof/79-VERIFICATION.md). Phase 78 delivered route-only tarball proof and HexConsumerContract SSOT as scoped.

## Goal

Introduce `Scoria.HexConsumerContract` as SSOT for Hex dep snippets and tarball consumer wiring; parameterize `HostAppProof.Generator` with explicit `dep_mode`; make merge-blocking adoption prove a `mix hex.build --unpack` artifact (route smoke only), not a repo-root `path:` dep.

**Phase-scoped partial requirements:** HEX-CONSUMER-01† (route-only overlay; full overlay in Phase 79), DOCS-HEX-01† (SSOT + executable guards; prose drift in Phase 82).

## Requirement traceability

| Requirement | Phase 78 delivery | Status | Evidence |
|-------------|-------------------|--------|----------|
| **HEX-CONSUMER-01** | Tarball dep via unpack root; deps.get → install → migrate → **route smoke only** | **Partial (as scoped)** | `host_app_consumer_proof_test.exs` uses `dep_mode: :hex_tarball`, `run_route_proof!/1`, five-step assertion; `mix test.adoption` green (51 tests). Runtime/handoff overlays deferred to Phase 79 per D-16/D-19. |
| **DOCS-HEX-01** | `HexConsumerContract` SSOT + executable drift guards | **Partial (as scoped)** | `lib/scoria/hex_consumer_contract.ex`, `hex_consumer_contract_test.exs`, `package_surface_test.exs` contract imports. README/operator/adoption_lanes prose sweep, `adoption_surface_test` / `ci_policy_contract_test` pins deferred to Phase 82 per D-21/D-23. |

Cross-reference with `.planning/REQUIREMENTS.md` traceability table: both requirements remain **Pending** at milestone level until Phases 79 (HEX-CONSUMER-01 complete) and 82 (DOCS-HEX-01 complete). Phase 78 partial delivery matches plan frontmatter and CONTEXT boundary.

## Plan must_haves

### 78-01 — HexConsumerContract SSOT

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| Public lib SSOT separate from `AdopterDocContract` (D-01, D-05) | PASS | `lib/scoria/hex_consumer_contract.ex` and `lib/scoria/adopter_doc_contract.ex` are distinct modules |
| `published_version/0` reads `Application.spec(:scoria, :vsn)`; `@hex_requirement` explicit `~> 0.1` (D-02) | PASS | Module attributes and `published_version/0` implementation |
| `hex_dep_snippet/0` byte-matches README active dep line (D-03, D-04) | PASS | README line 57; tests trim whitespace before compare |
| Tarball helpers exist; no `:hex` key on tarball tuples (D-03, D-07) | PASS | `tarball_dep_tuple/1` returns `{:scoria, path: unpack_root}`; unit test asserts tuple_size 2 |
| `package_surface_test` imports contract, no hardcoded active dep string (D-04, D-22) | PASS | `HexConsumerContract.hex_dep_snippet()` used; `rg` finds zero hardcoded `{:scoria, "~> 0.1", hex: :scoria}` in test file |
| `ensure_current_unpack_root!/0` stub → full cache in 78-02 (D-10) | PASS | Wave 2 replaced stub with fingerprint cache |
| `baseline_upgrade_version/0` returns `"0.1.0"` hook only (D-14) | PASS | Unit test + module attribute |
| No README/operator prose sweep in Phase 78 (D-21) | PASS | No docs prose changes in phase artifacts |
| Phase 80 reuses same host struct (D-29) | PASS | Design hook present; no Phase 80 fixture dir created |

### 78-02 — Fingerprinted unpack cache

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| Three-layer cache: env short-circuit, fingerprint dir, exclusive lock (D-10, D-12) | PASS | `ensure_current_unpack_root!/0`, `SCORIA_HEX_UNPACK_ROOT`, `:file.lock`, stamp file |
| `package_fingerprint/0` hashes file contents + version (D-10) | PASS | `package_path_hash_lines/1` reads and SHA256-hashes contents |
| `SCORIA_HEX_UNPACK_ROOT` reuses release preview output (D-12) | PASS | `env_override_root!/1`; CI parity probe passed locally |
| Shared cache never deleted in test `on_exit` (D-10) | PASS | No `File.rm_rf!` of `tmp/scoria-hex-consumer/` in tests; module has no cache deletion |
| `package_surface_test` hex preview uses contract cache (D-13) | PASS | `ensure_current_unpack_root!/0`; zero inline `hex.build` or `find_unpack_root!` in test file |
| Unpack root contains packaged `mix.exs`, not monorepo root | PASS | `unpack_root!/1` discovery logic |

### 78-03 — Tarball consumer harness

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| `create_host!/1` requires explicit `dep_mode` `:hex_tarball` \| `:path` (D-25, D-26) | PASS | `Keyword.fetch!(opts, :dep_mode)`; no default `opts \\ []` |
| `:hex_tarball` injects `tarball_dep_tuple(unpack_root)`; refutes repo-root path (D-06, D-18, D-27) | PASS | Generator branch + consumer test refute/assert |
| `run_route_proof!/1` route overlay only (D-16, D-17) | PASS | `@route_overlay_test` filter; steps `[:deps_get, :scoria_install, :ecto_create, :ecto_migrate, :host_route_smoke_test]` |
| `run_full_proof!/1` still runs all overlays (Phase 79 seam) | PASS | `&smoke_pair!/1` with full `host.overlay_tests` |
| `setup_all` calls `ensure_current_unpack_root!/0` once (D-11) | PASS | `host_app_consumer_proof_test.exs` setup_all |
| CI `SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview` on test job (D-12) | PASS | `.github/workflows/ci-verify.yml` lines 75–82 |
| `mix test.adoption` green with route-only tarball proof | PASS | 51 tests, 0 failures |
| `HostInstallFixtures` stays on repo `path:` (D-28) | PASS | Unchanged; still injects `{:scoria, path: repo_root}` |
| Live Hex registry resolution not in Phase 78 (D-09) | PASS | No registry SCM in generated host mix.exs |
| `@moduletag timeout: 180_000`, `async: false` preserved (D-20) | PASS | Consumer test module tags |
| `VerificationLanes.closeout_order/0` unchanged | PASS | `verification_lanes_test.exs` passes |

## Automated verification

| Command | Result |
|---------|--------|
| `MIX_ENV=test mix compile --warnings-as-errors` | PASS |
| `MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs test/scoria/package_surface_test.exs` | PASS — 9 tests, 0 failures |
| `MIX_ENV=test mix test test/scoria/package_surface_test.exs` (×2 consecutive) | PASS — cache hit on second run (~0.04s) |
| `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs` | PASS — 1 test, 0 failures (~53s) |
| `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs test/mix/tasks/test.adoption_test.exs` | PASS — 6 tests, 0 failures |
| `MIX_ENV=test mix test.adoption` | PASS — 51 tests, 0 failures (~60s) |
| CI parity: `MIX_ENV=dev mix scoria.release_preview && SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview MIX_ENV=test mix test.adoption` | PASS — 51 tests, 0 failures (~49s) |

## Gaps

**None for Phase 78 scope.** Intentional deferrals (not gaps):

- Phase 79: full overlay on tarball (`run_full_proof!/1`), HEX-CONSUMER-01 completion
- Phase 80: committed `0.1.0` fixture upgrade smoke
- Phase 81: live Hex registry post-publish gate
- Phase 82: README/operator/adoption_lanes prose + `adoption_surface_test` / `ci_policy_contract_test` pins

## Human verification

| Item | Status | Notes |
|------|--------|-------|
| CI release_preview → adoption unpack reuse | **Local parity passed** | Ran `mix scoria.release_preview` then `SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview mix test.adoption` — green |
| GitHub Actions `ci-verify.yml` end-to-end on merge | **Not run in this session** | Workflow env wiring verified statically; recommend confirming first green CI run on next push |

## Verdict

Phase 78 goal **achieved**. All three plan waves delivered: `HexConsumerContract` SSOT and drift guards, fingerprinted unpack cache with env override, and tarball route-only adoption proof wired through Generator/Runner/CI. Partial requirement milestones (HEX-CONSUMER-01†, DOCS-HEX-01†) match CONTEXT and REQUIREMENTS traceability.

---
*Verified: 2026-05-29*
