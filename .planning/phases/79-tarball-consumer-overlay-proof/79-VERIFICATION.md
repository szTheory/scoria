---
status: passed
phase: 79-tarball-consumer-overlay-proof
verified: 2026-05-29T21:30:00Z
requirements:
  - HEX-CONSUMER-01
---

# Phase 79 Verification

## Goal

Merge-blocking adoption lane proves **full overlay depth** (handoff → route → runtime) from a `mix hex.build --unpack` tarball dependency — not a monorepo root `path:` dep. Close HEX-CONSUMER-01 at milestone level with operator-first failure diagnostics and CI artifact wiring.

**Milestone scope:** HEX-CONSUMER-01 **Complete** (full overlay on tarball). DOCS-HEX-01 remains partial until Phase 82 prose sweep and drift pins (D-46).

## Requirement traceability

| Requirement | Phase 79 delivery | Status | Evidence |
|-------------|-------------------|--------|----------|
| **HEX-CONSUMER-01** | Tarball dep via unpack root; deps.get → install → migrate → **handoff + route + runtime overlay smokes** | **Complete** | `host_app_consumer_proof_test.exs` uses `dep_mode: :hex_tarball`, `run_full_proof!/1`, derived seven-step assertion; `mix test.adoption` green (51 tests). |

Cross-reference with `.planning/REQUIREMENTS.md` traceability table: `HEX-CONSUMER-01 | 78, 79 | Complete`. DOCS-HEX-01 traceability stays `78, 82 | Complete` (SSOT + guards from 78; prose sweep Phase 82).

## Plan must_haves

### 79-01 — Full overlay tarball consumer proof

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| Consumer uses `run_full_proof!/1` not `run_route_proof!/1` (D-30, D-33) | PASS | `Runner.run_full_proof!(host)` in consumer test |
| Derived seven-step contract from sorted overlay basenames (D-32) | PASS | `proof.steps == Runner.expected_steps(host)` → `[:deps_get, :scoria_install, :ecto_create, :ecto_migrate, :host_handoff_smoke_test, :host_route_smoke_test, :host_runtime_smoke_test]` (handoff → route → runtime order) |
| `@moduletag :host_proof` for local iteration (D-43) | PASS | Module tag present; `mix test --only host_proof` runs 1 test |
| Enriched host map with `working_root`, `dep_mode`, `unpack_root` | PASS | Generator return map (79-01) |
| `@moduletag timeout: 180_000` preserved (D-34) | PASS | Module tag; warm wall time ~50s — under D-36 p50 ≤90s and D-37 120s CI threshold |

### 79-02 — Failure diagnostics and snapshot preserve

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| Structured triage raise on failed `run_mix!/1` step (D-39) | PASS | `triage_message/4` with step, command, host paths, unpack/tarball context, overlay list, DB env (no password), replay, preserve hint |
| Nested overlay failure line extraction (D-39) | PASS | `extract_nested_failure_line/1` prepends first FAIL or `** (` line |
| `SCORIA_PRESERVE_HOST` opt-in cleanup skip (D-40, D-44) | PASS | `Generator.register_cleanup/2` skips `rm_rf` when env in ~w(1 true yes) |
| Failure snapshot at `tmp/scoria-host-proof-last-failure/` (D-41) | PASS | `maybe_snapshot_failure!/3` copies `working_root` with `MANIFEST.txt`; best-effort copy on symlink errors |
| Triage raise fields include replay and preserve hints | PASS | `replay_command/3`, `SCORIA_PRESERVE_HOST=1` in raise body |

### 79-03 — CI artifact + closeout ceremony

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| CI uploads `tmp/scoria-host-proof-last-failure/` on job failure only (D-42) | PASS | `.github/workflows/ci-verify.yml` step after adoption lane: `if: failure()`, `retention-days: 7`, `if-no-files-found: ignore` |
| Artifact path scoped — no `_build` or hex cache upload | PASS | Path limited to `tmp/scoria-host-proof-last-failure/` |
| `79-VERIFICATION.md` status passed (D-45) | PASS | This file |
| REQUIREMENTS.md HEX-CONSUMER-01 milestone Complete | PASS | Traceability `78, 79 | Complete`; checkbox prose covers full overlay chain |
| ROADMAP.md Phase 79 Complete; STATE.md → Phase 80 | PASS | Closeout ceremony in 79-03-03 |
| DOCS-HEX-01 **not** milestone Complete in 79 (D-46) | PASS | Prose sweep deferred Phase 82 |
| `VerificationLanes.closeout_order/0` unchanged | PASS | `verification_lanes_test.exs` passes |
| Optional README tarball one-liner (D-47) | PASS | README Verification section |
| Optional operator debug blurb (D-47) | PASS | `docs/operator_verification.md` tarball proof / triage paragraph |

## Automated verification

| Command | Result | Wall time |
|---------|--------|-----------|
| `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs` | PASS — 1 test, 0 failures | ~50s |
| `MIX_ENV=test mix test --only host_proof` | PASS — 1 test, 0 failures | ~50s |
| `MIX_ENV=test mix test.adoption` | PASS — 51 tests, 0 failures | ~58s |
| `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs test/mix/tasks/test.adoption_test.exs` | PASS — 6 tests, 0 failures | ~0.1s |
| CI parity: `MIX_ENV=dev mix scoria.release_preview && SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview MIX_ENV=test mix test.adoption` | PASS — 51 tests, 0 failures | ~53s |

**Performance note:** Consumer proof warm runs ~50–58s locally — well under D-37 escalation threshold (120s). No `@moduletag timeout` bump to 240_000 required.

## Overlay evidence chain

Ordered overlay assertion (derived from sorted basenames):

```
host_handoff_smoke_test → host_route_smoke_test → host_runtime_smoke_test
```

Full step contract:

```
[:deps_get, :scoria_install, :ecto_create, :ecto_migrate, :host_handoff_smoke_test, :host_route_smoke_test, :host_runtime_smoke_test]
```

## Gaps

**None for Phase 79 scope.** Intentional deferrals (not gaps):

- Phase 80: committed `0.1.0` fixture upgrade smoke (HEX-UPGRADE-01)
- Phase 81: live Hex registry post-publish gate (HEX-REGISTRY-01)
- Phase 82: README/operator/adoption_lanes prose sweep + `adoption_surface_test` / `ci_policy_contract_test` pins (DOCS-HEX-01 prose Complete)

## Human verification

| Item | Status | Notes |
|------|--------|-------|
| CI release_preview → adoption unpack reuse | **Local parity passed** | Ran `mix scoria.release_preview` then `SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview mix test.adoption` — green |
| CI artifact upload on adoption failure | **Static wiring verified** | First GHA failure on adoption lane should upload `scoria-host-proof-last-failure` when snapshot exists; confirm post-merge |
| `SCORIA_PRESERVE_HOST=1` disk inspection | **Verified in 79-02** | See 79-02-SUMMARY.md induced failure evidence |

## Verdict

Phase 79 goal **achieved**. All three plan waves delivered: full overlay tarball consumer proof with derived step contract, operator-first failure diagnostics with workspace snapshot preserve, and CI failure artifact upload with milestone closeout ceremony. **HEX-CONSUMER-01 milestone Complete.**

---
*Verified: 2026-05-29*
