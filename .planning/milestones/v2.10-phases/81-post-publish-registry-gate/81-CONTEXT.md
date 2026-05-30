# Phase 81: Post-publish registry gate - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **HEX-REGISTRY-01**: extend post-publish attestation from compile-only `deps.get` to **live Hex registry** proof — install → migrate → **overlay subset** on `{:scoria, …, hex: :scoria}` — and wire it as a **blocking** job in the release chain. Document and wire **conditional semver upgrade** (`FROM previous → TO just-published`) when `published_version > "0.1.0"`.

**In scope:** `:hex_registry` dep mode on existing `HostAppProof` harness; `mix scoria.post_publish_smoke` Mix task; refactor `.github/workflows/post-publish-smoke.yml` to reusable `workflow_call` SSOT; blocking job in `release-please.yml` (after `publish-hex`) and `hex-publish.yml` (recovery); `HexConsumerContract` registry/semver helpers; operator gate map stub for v2.10 topology; `81-VERIFICATION.md` with latent upgrade note for `0.1.0`-only releases.

**Out of scope:** Live Hex in PR CI / `mix test.adoption` (D-09); full handoff+route+runtime overlay (tarball adoption owns that); README/adoption_lanes prose sweep + drift pins (Phase 82); widening `VerificationLanes.closeout_order/0`; new closeout lanes; cross-minor upgrade (`0.1` → `0.2`); rebuilding baseline from HEAD in post-publish; synthetic trap migrations.
</domain>

<decisions>
## Implementation Decisions

### Overlay proof depth (registry subset)
- **D-69:** Post-publish proves **route + runtime overlays only** (6 steps: `deps_get → scoria_install → ecto_create → ecto_migrate → host_route_smoke_test → host_runtime_smoke_test`). **Reject** full handoff+route+runtime (7 steps) — duplicates merge-blocking tarball proof with ~5–10s marginal gain; **reject** route-only — too shallow for installer-heavy lib (misses HOST-01 approval/resume/evidence).
- **D-70:** Overlays copy from **`deps/scoria/priv/host_app_proof/overlay/test/` after `deps.get`**, never from checkout workspace — proves packaged Hex artifact, not git HEAD overlays.
- **D-71:** Assert **exact ordered steps** via new `Runner.expected_registry_steps/1` / `run_registry_proof!/1` — same discipline as adoption lane (D-32 continuity); no subset/`in` assertions.

### Harness integration (hybrid Mix task + extended Generator/Runner)
- **D-72:** **Hybrid C:** extend `Generator`/`Runner` with `:hex_registry` dep mode **and** thin `mix scoria.post_publish_smoke` entrypoint. **Reject** inline shell expansion in YAML (drift from Runner, overlay-from-checkout footgun); **reject** adoption-lane ExUnit file in `mix test.adoption`.
- **D-73:** Add `dep_mode: :hex_registry` with `hex_version:` opt to `Generator.create_host!/1`. Fresh-install attest uses **exact pin** `{:scoria, "#{RELEASE_VERSION}", hex: :scoria}` — not `~> 0.1` — so resolver cannot pick stale index during lag.
- **D-74:** Add `Generator.overlay_from_dep!/1` — populate host overlay list from resolved Hex package tree after `deps.get`.
- **D-75:** New `@moduletag :registry_proof` test module (`host_app_registry_proof_test.exs`) invoked by Mix task / workflow only — **not** in `@adoption_test_files`. Local iteration: `SCORIA_REGISTRY_VERSION=0.1.0 mix scoria.post_publish_smoke`.
- **D-76:** Reuse Phase 79 failure DX: triage raises, `SCORIA_PRESERVE_HOST=1`, `tmp/scoria-host-proof-last-failure/` MANIFEST extended with `dep_mode: registry`, `registry_version`.

### Release blocking semantics (reusable workflow in publish chain)
- **D-77:** Refactor `post-publish-smoke.yml` to **`workflow_call` SSOT** with inputs: `version` (required), `skip_index_wait` (default false). **Remove** `release: published` as primary blocking trigger — it races ahead of `publish-hex` in `release-please.yml`.
- **D-78:** Add **`post-publish-attest` job** to `release-please.yml`: `needs: [release-please, publish-hex]`, `uses: ./.github/workflows/post-publish-smoke.yml`, `with: version: ${{ … }}, skip_index_wait: true`. Attest failure = **failed release workflow** (ROADMAP criterion #2). Green release-please run = safe to announce Hex-primary.
- **D-79:** Mirror attest job in **`hex-publish.yml`** (manual recovery) so recovery path gets same proof — not compile-only.
- **D-80:** Keep **`workflow_dispatch`** on post-publish workflow for maintainer debug/re-run with `tag`/`version` inputs.
- **D-81:** Post-publish job adds **Postgres service** (mirror `ci-verify.yml` pgvector on 55432) — required for runtime overlay and install/migrate chain.
- **D-82:** When chained after `publish-hex`, pass `skip_index_wait: true` — dedupe 36×10s index poll already in `publish-hex`. Standalone `workflow_dispatch` keeps full index wait.

### Real semver upgrade path (conditional, pairs with Phase 80)
- **D-83:** **Conditional upgrade leg** when `HexConsumerContract.semver_upgrade_eligible?(version)` (`Version.compare(version, "0.1.0") == :gt`). On **`0.1.0`-only releases today:** fresh-install attest only; document upgrade as **latent** in `81-VERIFICATION.md` (mirror 80-CONTEXT D-65 migration honesty).
- **D-84:** When eligible: same-host registry upgrade via **`run_upgrade_proof!/2` with `bump: {:registry, from: prev, to: current}`** — reuse Phase 80 orchestration (D-57); **do not** fork a second upgrade runner.
- **D-85:** Baseline leg pins **exact previous semver** (`registry_dep_tuple_pinned("0.1.0")` on first `0.1.1`); upgrade target uses exact just-published version. **Reject** `~> 0.1` on baseline — both legs would resolve to same artifact (no-op footgun).
- **D-86:** Add `Generator.bump_registry_dep!/2` + `HexConsumerContract.registry_upgrade_pair/1`, `semver_upgrade_eligible?/1`, `registry_dep_tuple_pinned/1`, `registry_dep_snippet_pinned/1`. `registry_upgrade_from_version/1` resolves previous patch (floor at `"0.1.0"` for first bump).
- **D-87:** Post-upgrade `ecto.migrate` migration-delta assertion **activates** when first post-0.1.0 core migration ships — latent until then (D-65 continuity). Harness ships now; criterion documented in VERIFICATION.
- **D-88:** Phase 80 content-revision upgrade (tarball fixture → HEAD) stays merge-blocking PR CI; Phase 81 registry semver upgrade is **complementary release attestation**, not redundant.

### Operator gate map (minimal — Phase 82 expands prose)
- **D-89:** Add post-publish attest row to `docs/operator_verification.md` CI gate map: **PR = tarball full depth + content-revision upgrade; release = registry subset + conditional semver upgrade**. Full tarball-vs-registry narrative + drift pins deferred to Phase 82 (D-23 continuity).

### Claude's Discretion
- Exact Mix task module path (`Mix.Tasks.Scoria.PostPublishSmoke` vs nested under `HexConsumer`).
- Whether fresh-install and upgrade run as one Mix task with internal branching vs two workflow jobs.
- `registry_upgrade_from_version/1` implementation: hardcoded floor + patch decrement vs Hex releases API for robustness.
- Retry count on `mix deps.get` after index wait (2–3 retries recommended).
- `@moduletag timeout` on registry proof module (start `180_000`; D-37 escalation if CI evidence).
- Optional contract test pinning workflow job names in `ci_policy_contract_test.exs` — minimal stub OK; full pins Phase 82.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements
- `.planning/ROADMAP.md` — Phase 81 success criteria (overlay subset, blocking attestation, semver upgrade, gate map)
- `.planning/REQUIREMENTS.md` — HEX-REGISTRY-01 definition; deferred advisory hex_consumer lane
- `.planning/PROJECT.md` — v2.10 three-layer trust intent
- `.planning/STATE.md` — Phase 80 completion, D-55/D-68 registry ownership

### Prior phase context (locked)
- `.planning/phases/78-hex-consumer-contract-foundation/78-CONTEXT.md` — D-09 registry deferred to Phase 81; tarball vs registry split
- `.planning/phases/79-tarball-consumer-overlay-proof/79-CONTEXT.md` — full overlay step contract, D-32 ordering, failure DX
- `.planning/phases/80-upgrade-smoke-in-adoption-lane/80-CONTEXT.md` — content-revision vs registry semver (D-55), `run_upgrade_proof!/2`, latent migration (D-65)

### Host proof harness
- `lib/scoria/hex_consumer_contract.ex` — extend with registry pin + semver helpers
- `test/support/scoria/host_app_proof/generator.ex` — add `:hex_registry`, `overlay_from_dep!/1`, `bump_registry_dep!/2`
- `test/support/scoria/host_app_proof/runner.ex` — add `run_registry_proof!/1`, `expected_registry_steps/1`; extend `run_upgrade_proof!/2` bump dispatch
- `test/scoria/host_app_consumer_proof_test.exs` — tarball consumer (unchanged)
- `test/scoria/host_app_upgrade_proof_test.exs` — tarball upgrade (unchanged)
- `priv/host_app_proof/overlay/test/` — route + runtime overlay sources
- `lib/mix/tasks/test.adoption.ex` — adoption file list (**do not** add registry proof)

### Workflows
- `.github/workflows/post-publish-smoke.yml` — refactor to `workflow_call` SSOT
- `.github/workflows/release-please.yml` — add blocking `post-publish-attest` after `publish-hex`
- `.github/workflows/hex-publish.yml` — add attest job for recovery parity
- `.github/workflows/ci-verify.yml` — Postgres service/env reference for post-publish job

### Docs & contracts
- `docs/operator_verification.md` — CI gate map + Hex release section (minimal Phase 81 update)
- `test/scoria/ci_policy_contract_test.exs` — gate map contract tests (Phase 82 may extend)

### Project vision & engineering DNA
- `prompts/sztheory-elixir-dna.md` — `mix *.install`, robust CI, zero-config onboarding
- `prompts/phoenix-ai-lib-deep-research.md` §17 — OSS trust: ExUnit, CI gates, semver, fake fixtures, release automation
- `prompts/scoria-gsd-kickoff.md` — trace-first, executable proof over prose

### External ecosystem
- [hexpm/hex#515](https://github.com/hexpm/hex/issues/515) — path-unpack for PR CI (Phases 78–80)
- Hex immutable releases — same-semver republish impossible; registry upgrade only when `> 0.1.0`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HexConsumerContract.hex_dep_snippet/0` / `hex_dep_tuple/0` — registry dep SSOT (extend with pinned variants)
- `Runner.run_route_proof!/1` — 5-step seam; registry proof extends to 6 steps with runtime overlay
- `Runner.run_upgrade_proof!/2`, `expected_upgrade_steps/1` — upgrade orchestration to reuse with registry bump strategy
- `Generator.create_host!/1`, `patch_mix_exs!/1`, overlay copy helpers — add third dep_mode branch
- Phase 79 triage, failure snapshot, `SCORIA_PRESERVE_HOST` — extend MANIFEST for registry context
- `post-publish-smoke.yml` index wait loop — reuse via `skip_index_wait` when chained after publish-hex

### Established Patterns
- **Three-layer v2.10 trust:** PR tarball full depth (78–79) → PR content-revision upgrade (80) → release registry subset + semver (81)
- **Mix task for ops, harness for proof:** `mix test.adoption` / `mix scoria.release_preview` precedent — registry attest is maintainer/release Mix task, not closeout lane
- **Exact step contracts:** derived from host struct, asserted with `==`, never `in`
- **Layered-trust industry norm:** npm pack vs registry; Scoria appropriately exceeds typical Hex libs because install/upgrade safety is the product

### Integration Points
- `lib/mix/tasks/scoria.post_publish_smoke.ex` — new entrypoint reading `SCORIA_REGISTRY_VERSION`
- `test/scoria/host_app_registry_proof_test.exs` — fresh-install registry proof (`:registry_proof`)
- `test/scoria/host_app_registry_upgrade_proof_test.exs` — optional semver upgrade (`:registry_upgrade`, env-gated locally)
- `release-please.yml` — final job in publish chain before attestation complete
- `docs/operator_verification.md` — gate map table row for post-publish vs PR CI

</code_context>

<specifics>
## Specific Ideas

Research-backed cohesive stance (user requested one-shot recommendations across all gray areas):

- **Principle of least surprise:** Adopters read Hex-primary README and run `mix scoria.install`. Post-publish must prove that exact path — not a lighter compile-only check that could pass while install/migrate/runtime fails on live registry.
- **Layered trust (phoenix-ai-lib §17 + szTheory DNA):** Typical Hex libs stop at pre-publish CI + dry-run publish (Oban, Broadway, Req). Scoria's installer contract justifies going further — but only **post-publish**, not in every PR. Subset overlays (route+runtime) prove core adopter success without re-running 175s adoption lane on every release.
- **Handoff stays tarball-gated:** HOST-02 delegation semantics are merge-blocking on packaged artifact; registry gate proves transport + install + core runtime (HOST-01) — the path every Hex adopter hits first.
- **Hybrid harness, not shell drift:** Phases 78–80 invested in Generator/Runner/triage — throwing that away for inline `elixir -e` in YAML violates DRY and creates overlay-from-checkout false positives.
- **Blocking in publish chain, not advisory race:** `release: published` trigger fires before `publish-hex` completes — attestation must be `needs: publish-hex` inside release-please. Reusable workflow mirrors `ci-verify.yml` SSOT pattern maintainers already understand.
- **Semver upgrade honesty:** At `0.1.0` only, upgrade is impossible and unnecessary on registry — document latent, wire conditional for `0.1.1+`. Phase 80 tarball content-revision covers pre-patch upgrade mechanics in PR CI.
- **Exact version pins:** Fresh install uses just-published exact version; upgrade baseline uses exact previous — avoids Hex resolver no-op during index lag.
- **DX preserved:** Local replay via Mix task + env vars; `workflow_dispatch` for recovery; failure snapshot + preserve host; gate map tells maintainers PR vs release responsibilities.

</specifics>

<deferred>
## Deferred Ideas

- Full README/operator/adoption_lanes tarball-vs-registry narrative + drift pins — Phase 82 (DOCS-HEX-01)
- Cross-minor registry upgrade (`0.1` → `0.2`) — future semver policy
- Advisory `mix scoria.test.hex_consumer` lane — rejected in REQUIREMENTS.md
- Live Hex fetch in PR CI — rejected (D-09, 78–80)
- Full handoff overlay on registry path — tarball adoption owns HOST-02
- Separate `workflow_dispatch`-only upgrade proof as primary gate — supplement only, not release-blocking
- `SCORIA_ARTIFACT_PATH` general maintainer override — optional, non-CI

</deferred>

---

*Phase: 81-Post-publish registry gate*
*Context gathered: 2026-05-29*
