# Phase 80: Upgrade smoke in adoption lane - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **HEX-UPGRADE-01** in merge-blocking `mix test.adoption`: the **same** generated Phoenix host installs at pinned published `0.1.0`, passes baseline full overlay smokes and compliant `mix scoria.install --check`, bumps to the current `mix hex.build --unpack` tarball, runs the operator upgrade chain (`--dry-run` → `--check` → apply → `ecto.migrate` → `--check`), then re-runs full overlay smokes — **without** a second `phx.new`.

**In scope:** Committed `0.1.0` baseline fixture; `HexConsumerContract` baseline helpers; `Runner.run_upgrade_proof!/2` + `expected_upgrade_steps/1`; `host_app_upgrade_proof_test.exs` in adoption lane; installer trailer assertions; Phase 79 failure diagnostics reuse; `REQUIREMENTS.md` / ROADMAP reconciliation when verification passes.

**Out of scope:** Live Hex registry fetch (Phase 81); README/operator prose sweep and drift pins (Phase 82); widening `VerificationLanes.closeout_order/0`; new closeout lanes; cross-minor upgrade (`0.1` → `0.2`); per-overlay ExUnit split; global ExUnit timeout widen; rebuilding baseline from HEAD each CI run; skipping upgrade test until `0.1.1`.
</domain>

<decisions>
## Implementation Decisions

### Baseline fixture (0.1.0 tarball)
- **D-50:** **Committed frozen unpack** at `test/fixtures/hex_consumer/scoria-0.1.0-unpack/` — extract once from git tag `v0.1.0` via `mix hex.build --unpack`, commit tree + stamp. **Reject** live Hex fetch in PR CI (Phase 81 owns registry) and **reject** rebuilding 0.1.0 from HEAD each run (not a true published baseline).
- **D-51:** **Drift guard (A+C):** add `HexConsumerContract.baseline_unpack_root!/0`, `baseline_package_fingerprint/0`, and stamp file `.scoria-hex-baseline.stamp` (fingerprint + `v0.1.0` git SHA). Unit/policy test fails if fixture stamp ≠ computed fingerprint. Maintainer refresh via `mix scoria.hex_consumer.refresh_baseline_fixture` (checkout tag → hex.build --unpack → write stamp). Refresh cadence: **almost never** — only tag integrity incident or explicit baseline policy change.
- **D-52:** Optional maintainer-only env `SCORIA_HEX_BASELINE_UNPACK_ROOT` — mirrors `SCORIA_HEX_UNPACK_ROOT`; never set in CI. Fixture is test-only — **not** in `mix.exs` `package[:files]`. Do **not** gitignore fixture dir (unlike `tmp/scoria-hex-consumer/`).

### Same-semver content-revision upgrade (pre-0.1.1)
- **D-53:** **Run upgrade smoke now** while repo semver is `0.1.0`. Treat fingerprint-different tarball (`baseline fixture` → `ensure_current_unpack_root!/0`) as valid **content-revision upgrade** — proves existing host survives dep swap, installer chain, and runtime overlays on populated schema. **Reject** skipping when `published_version() == baseline_upgrade_version()` (Option B).
- **D-54:** Test **asserts** `baseline_package_fingerprint() != package_fingerprint()` when HEAD has diverged from `v0.1.0` — fail fast if fixture accidentally matches current (would negate test value). Add `HexConsumerContract.same_semver_content_upgrade?/0` helper for docs/guards.
- **D-55:** **Naming honesty:** Phase 80 = pre-publish **content-revision** upgrade (path tarball swap). Phase 81 = live registry **semver** upgrade (`0.1.0` → `0.1.x+1`). Hex cannot republish same semver — document in VERIFICATION, not adopter-facing prose sweep (Phase 82).
- **D-56:** Defer `post_baseline_version/0` until release-please first bumps past `0.1.0` — then tighten assertions (semver string in dep, migration count delta). Not a skip gate today.

### Upgrade proof orchestration (Runner)
- **D-57:** Add **`Runner.run_upgrade_proof!(host, current_unpack_root: …)`** + **`Runner.expected_upgrade_steps/1`** — do **not** extend `run_full_proof!/1` with `:phase` (semantic mismatch: post-upgrade skips `:ecto_create`, adds installer modes). Keep `run_full_proof!/1` / `run_route_proof!/1` untouched for Phase 79 consumer proof (D-33).
- **D-58:** Canonical step list (derived SSOT):

  ```elixir
  # Baseline (0.1.0 fixture)
  [:deps_get, :scoria_install, :ecto_create, :ecto_migrate] ++ overlay_atoms ++ [:scoria_install_check]

  # Upgrade (same host, same DB)
  [:bump_dep, :deps_get, :scoria_install_dry_run, :scoria_install_check_pre_apply,
   :scoria_install, :ecto_migrate, :scoria_install_check] ++ overlay_atoms
  ```

  Overlay atoms derived from sorted `host.overlay_tests` (D-32 continuity). Assert **`proof.steps == expected_upgrade_steps(host)`** exactly — no subset/`in` assertions.

- **D-59:** Add **`Generator.bump_unpack_dep!/2`** — rewrite `mix.exs` tarball path, update `host.unpack_root`; force `mix deps.get` after patch (consider `mix deps.clean scoria` if cache sticky).
- **D-60:** Extend **`run_mix!/4`** (or dedicated helpers) with **`expect_exit`** + **`expect_trailer`** for installer modes:
  - Baseline `:scoria_install_check` → exit 0, `SCORIA_CHECK_RESULT status=compliant exit_code=0`
  - Pre-apply `:scoria_install_check_pre_apply` → exit 1, `status=drift exit_code=1` (expected after dep bump)
  - Post-upgrade `:scoria_install_check` → exit 0, compliant
  - `:scoria_install_dry_run` → exit 0, no host mutation
  Pin trailer strings exactly as `test/mix/tasks/scoria.install_check_test.exs` / `Scoria.Install.Contract`.

### Test placement & CI budget
- **D-61:** **Dedicated** `test/scoria/host_app_upgrade_proof_test.exs` — add to `Mix.Tasks.Scoria.Test.Adoption` `@adoption_test_files` and `test/mix/tasks/test.adoption_test.exs` expected list. **Do not** add second test to `host_app_consumer_proof_test.exs` — preserves `--only host_proof` ~50s fast loop (D-43).
- **D-62:** Tags: `@moduletag :host_upgrade` on upgrade module; keep `:host_proof` on consumer module only. Local iteration: `mix test --only host_upgrade`.
- **D-63:** Timeout: **`@moduletag timeout: 180_000`** on upgrade module at ship (warm estimate ~100–116s; adoption lane total ~165–175s). Apply D-37 escalation to **upgrade module only** → `240_000` if CI exceeds 120s on **two consecutive runs**. Consumer module stays `180_000`. **Reject** preemptive `300_000` / `420_000` without evidence.

### Migration ordering (ROADMAP criterion #4)
- **D-64:** **Real migration delta on preserved DB** — upgrade phase runs `ecto.migrate` against existing schema after `copy_missing_files` from bumped tarball. **Reject** synthetic ordering-trap migration in production package (Option B) and **reject** implicit no-op migrate as sufficient proof (Option C).
- **D-65:** **Honest gate today:** `v0.1.0` tag and HEAD share **identical** 24-file `priv/repo/migrations/` tree — `ecto.migrate` post-upgrade is a **no-op** until first post-0.1.0 migration ships. Ship harness now (criteria 1–3); document criterion #4 as **latent** in `80-VERIFICATION.md` with contract assertion: when `published_version() > baseline_upgrade_version()` OR new core migration basenames exist vs fixture, post-upgrade migrate must record new versions in `schema_migrations`. Optional helper `pending_core_migrations/1` on host.
- **D-66:** Knowledge lane remains split: install copies core stub only; knowledge DDL in `priv/repo/knowledge_migrations/` — not part of default host upgrade chain (matches `migration_lane_compatibility_test.exs` precedent).

### Failure diagnostics (reuse Phase 79)
- **D-67:** Extend failure snapshot `MANIFEST.txt` with `baseline_unpack`, `current_unpack`, `upgrade_phase: baseline|upgrade`, failed step. Reuse `SCORIA_PRESERVE_HOST=1` — critical for inspecting mutated host after bump. Same CI artifact path `tmp/scoria-host-proof-last-failure/`.

### HEX-UPGRADE-01 completion ceremony
- **D-68:** Flip requirement **Complete** only in same PR tail as green proof: `80-VERIFICATION.md` (passed) + `REQUIREMENTS.md` traceability + ROADMAP phase 80 Complete + `STATE.md`. Note criterion #4 latent status explicitly in VERIFICATION — not a phase failure.

### Claude's Discretion
- Exact `mix scoria.hex_consumer.refresh_baseline_fixture` task name and whether it lives in `Mix.Tasks.Scoria.HexConsumer.*` vs inline script.
- `assert_check_trailer!/2` helper shape (find by step + occurrence index for duplicate `:scoria_install_check`).
- Whether `run_upgrade_proof!/2` returns `phases: %{baseline: …, upgrade: …}` for debugging.
- Optional one-paragraph in `docs/operator_verification.md` for upgrade smoke debug (minimal; full prose Phase 82).
- Exact `pending_core_migrations/1` implementation vs deferring to Phase 81 semver bump.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements
- `.planning/ROADMAP.md` — Phase 80 success criteria (including migration ordering #4)
- `.planning/REQUIREMENTS.md` — HEX-UPGRADE-01 full definition
- `.planning/PROJECT.md` — v2.10 intent, preserved lane contracts
- `.planning/STATE.md` — Phase 79 decisions, current position

### Prior phase context (locked)
- `.planning/phases/78-hex-consumer-contract-foundation/78-CONTEXT.md` — D-14 baseline fixture hook, D-29 same host, D-03 contract API
- `.planning/phases/79-tarball-consumer-overlay-proof/79-CONTEXT.md` — D-30–D-48 runner contract, timeouts, failure DX
- `.planning/phases/79-tarball-consumer-overlay-proof/79-RESEARCH.md` — §12 Phase 80 integration, timing budgets

### Host proof harness
- `test/scoria/host_app_consumer_proof_test.exs` — consumer proof (unchanged)
- `test/support/scoria/host_app_proof/runner.ex` — extend with `run_upgrade_proof!/2`
- `test/support/scoria/host_app_proof/generator.ex` — extend with `bump_unpack_dep!/2`
- `lib/scoria/hex_consumer_contract.ex` — baseline helpers + existing current unpack cache
- `lib/mix/tasks/test.adoption.ex` — adoption file list (add upgrade test)
- `test/mix/tasks/test.adoption_test.exs` — expected file list guard
- `priv/host_app_proof/overlay/test/` — HOST-01/02 overlay sources

### Installer contract
- `lib/mix/tasks/scoria.install.ex` — dry-run / check / apply modes
- `lib/scoria/install/contract.ex` — `SCORIA_CHECK_RESULT` trailer SSOT
- `test/mix/tasks/scoria.install_check_test.exs` — tri-state exit + trailer pins
- `lib/scoria/install/surface/migrations.ex` — `copy_missing_files` semantics (never overwrite)

### Migration & bootstrap
- `priv/repo/migrations/` — 24 core migrations (identical at v0.1.0 and HEAD today)
- `test/scoria/bootstrap/migration_lane_compatibility_test.exs` — knowledge lane split precedent

### CI & docs
- `.github/workflows/ci-verify.yml` — `SCORIA_HEX_UNPACK_ROOT`, failure artifact hook
- `docs/operator_verification.md` — installer verification modes (minimal update OK)

### Project vision & engineering DNA
- `prompts/sztheory-elixir-dna.md` — operator-first, `mix *.install`, robust CI
- `prompts/phoenix-ai-lib-deep-research.md` §17 — OSS trust: CI gates, semver, fake fixtures, pre-publish artifact verification
- `prompts/scoria-gsd-kickoff.md` — trace-first, executable proof over prose

### External ecosystem
- [hexpm/hex#515](https://github.com/hexpm/hex/issues/515) — unpack + `path:` dep for consumer tests
- Hex immutable releases — same-semver content change is CI path-dep construct, not registry scenario

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HexConsumerContract.ensure_current_unpack_root!/0` — current tarball target for upgrade bump
- `HexConsumerContract.baseline_upgrade_version/0` — already returns `"0.1.0"` (D-03)
- `Runner.run_full_proof!/1`, `expected_steps/1` — compose baseline/post-upgrade overlay segments
- `Runner` triage raises, failure snapshot, `SCORIA_PRESERVE_HOST` — extend MANIFEST for upgrade context
- `install_check_test.exs` — trailer string pins for `--check` expectations
- Phase 79 `@moduletag :host_proof` — keep consumer-only; add parallel `:host_upgrade`

### Established Patterns
- Three-layer v2.10 trust: PR tarball (78–79) → content-revision upgrade (80) → live registry (81)
- Exact ordered step contract — derived from host struct, not hardcoded tuples
- One generated Phoenix host per proof scenario; D-29 = one `phx.new` **per upgrade test**, bump in-place for upgrade chain
- Adoption lane file list is SSOT — changes require `test.adoption_test.exs` guard update
- D-37 timeout escalation requires evidence — don't preempt

### Integration Points
- `host_app_upgrade_proof_test.exs` — new adoption entry (create with baseline fixture, call `run_upgrade_proof!/2`)
- `HexConsumerContract` — baseline fixture path + fingerprint API
- `Generator.bump_unpack_dep!/2` — mix.exs patch between baseline and upgrade phases
- `Runner.run_mix!/4` — expect_exit/trailer for installer check steps
- `test.adoption.ex` — add upgrade test file to closeout lane

</code_context>

<specifics>
## Specific Ideas

Research-backed cohesive stance (user requested one-shot recommendations across all gray areas):

- **Principle of least surprise:** Phase 80 completes the v2.10 adopter story started in 78–79 — "I installed 0.1.0, now I upgrade" — using the same host harness and installer modes adopters already read in README/operator docs.
- **Layered trust (phoenix-ai-lib §17):** Separate artifact proof (path tarball), content-revision upgrade (80), and registry semver (81) — industry pattern (npm pack vs npm registry, Rust vendor vs crates.io).
- **Ecosystem idioms:** Elixir libs rarely vend old Hex tarballs; Scoria appropriately does because `mix scoria.install` upgrade safety **is** the product (szTheory DNA: batteries-included install + robust CI). Hex #515 `path:` unpack is the idiomatic CI mechanism — not live registry in merge-blocking tests.
- **Pre-0.1.1 honesty:** Content-revision upgrade delivers real value today (installer chain + overlays on populated DB) without pretending Hex allows same-version republish. Migration ordering proof activates naturally on first `0.1.1+` migration — document latent, don't fake it.
- **DX preserved:** `:host_proof` stays ~50s; `:host_upgrade` ~100s; preserve host + snapshot on failure; refresh command for stale fixture.
- **Footguns avoided:** Skip-until-0.1.1 (blind spot), live Hex in PR CI (flaky), synthetic trap migrations (surprising), co-located tests (breaks fast loop), preemptive 300s timeout (D-37 violation), extending `run_full_proof!/1` with phases (semantic lie).

</specifics>

<deferred>
## Deferred Ideas

- Live Hex registry upgrade (`{:scoria, "~> 0.1", hex: :scoria}`) — Phase 81 (`HEX-REGISTRY-01`)
- Full README/operator/adoption_lanes upgrade narrative + drift pins — Phase 82
- `post_baseline_version/0` strict semver assertions — when release-please bumps past `0.1.0`
- Cross-minor upgrade (`0.1` → `0.2`) — future semver policy
- `SCORIA_ARTIFACT_PATH` general maintainer override — optional, non-CI
- Synthetic ordering-sensitive migration for empty-delta CI — rejected

</deferred>

---

*Phase: 80-Upgrade smoke in adoption lane*
*Context gathered: 2026-05-29*
