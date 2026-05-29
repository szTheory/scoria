# Phase 78: Hex consumer contract foundation - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Introduce `Scoria.HexConsumerContract` as the single source of truth for Hex dep snippets, version policy, and tarball consumer wiring; parameterize `HostAppProof.Generator` with explicit `dep_mode`; and make merge-blocking adoption prove a **`mix hex.build --unpack` artifact** (route smoke only), not a repo-root `path:` dep.

**Partial requirements:** HEX-CONSUMER-01† (tarball dep + install → migrate → route; overlay depth completes in Phase 79), DOCS-HEX-01† (SSOT + executable test guards only; prose drift guards in Phase 82).

**Out of scope for Phase 78:** Full HOST-01/HOST-02 overlay on tarball (Phase 79), upgrade smoke (Phase 80), live registry post-publish gate (Phase 81), README/operator narrative sweep (Phase 82), widening `VerificationLanes.closeout_order/0`, new closeout lanes, gallery/semantic/knowledge in hex proof.
</domain>

<decisions>
## Implementation Decisions

### HexConsumerContract module (visibility & API)
- **D-01:** Ship `Scoria.HexConsumerContract` in `lib/scoria/hex_consumer_contract.ex` as a **public, non-runtime** SSOT module — same class as `Scoria.AdopterDocContract`, not `test/support`.
- **D-02:** Version SSOT: only `mix.exs` `@version` is edited by humans/release-please; `published_version/0` reads `Application.spec(:scoria, :vsn)`; `@hex_requirement` is explicit policy (`"~> 0.1"`, not auto-derived from patch).
- **D-03:** Core API: `app/0`, `hex_requirement/0`, `published_version/0`, `hex_dep_tuple/0`, `hex_dep_snippet/0`, `github_fallback_tuple/1`, `github_fallback_snippet/1`, `tarball_dep_tuple/1`, `tarball_dep_snippet/1`, `baseline_upgrade_version/0` (`"0.1.0"` for Phase 80).
- **D-04:** Guard tests: `published_version/0` matches `Mix.Project.config()[:version]`; README active dep line matches `hex_dep_snippet/0`.
- **D-05:** Do **not** merge `HexConsumerContract` into `AdopterDocContract`; keep capability prose vs Hex mechanics separate. Phase 82 may add `AdopterDocContract` delegates for doc pins.

### Tarball dep shape (PR CI vs registry)
- **D-06:** Merge-blocking PR CI uses **Approach A**: `{:scoria, path: unpack_root}` where `unpack_root` is the directory from `mix hex.build --unpack` containing `mix.exs` — proves packaged **file inventory**, not monorepo tree.
- **D-07:** Adopter-facing SSOT remains literal Hex dep: `{:scoria, "~> 0.1", hex: :scoria}` via `hex_dep_snippet/0` / `hex_dep_tuple/0` (README, drift tests). Do not require `:hex` SCM in ephemeral generated host `mix.exs`.
- **D-08:** Reject `path:` to raw `.tar` files and `MIX_EX_PATH`-style env overrides as primary proof mechanisms.
- **D-09:** Live `{:scoria, "~> 0.1", hex: :scoria}` registry resolution stays **Phase 81** (`post-publish-smoke.yml`); not Phase 78.

### hex.build lifecycle & caching
- **D-10:** `HexConsumerContract.ensure_current_unpack_root!/0` — fingerprint of `package[:files]` + version; cache under `tmp/scoria-hex-consumer/<version>-<fingerprint>/` with stamp file; exclusive lock during build; never delete shared dir in test `on_exit`.
- **D-11:** `host_app_consumer_proof_test` uses `setup_all` to call `ensure_current_unpack_root!/0` once per module.
- **D-12:** CI: after `mix scoria.release_preview`, set `SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview` on test job so adoption + full suite reuse unpack tree without duplicate `hex.build`.
- **D-13:** Refactor `package_surface_test` hex preview to use `ensure_current_unpack_root!/0` instead of unique per-test tmp dirs.
- **D-14:** Phase 80 baseline `0.1.0` uses **committed fixture** (`test/fixtures/hex_consumer/scoria-0.1.0-unpack/`), not CI `hex.build` every run — design hook in contract, implement in Phase 80.
- **D-15:** Reject compile-time `@unpack_root` module attributes for merge-blocking proof (stale artifact risk).

### Phase 78 proof depth vs Phase 79
- **D-16:** **Hybrid C:** Phase 78 greens **route tracer only** on tarball dep; Phase 79 greens full overlay chain (HOST-01 runtime + HOST-02 handoff).
- **D-17:** Phase 78: `host_app_consumer_proof_test` uses `Runner.run_route_proof!/1` (route overlay only); implement `run_route_proof!/1` as real filter (today dead alias of `run_full_proof!/1`).
- **D-18:** Phase 78 assertions: refute repo-root `path:` in generated `mix.exs`; assert tarball dep via `HexConsumerContract`; optional assert unpack path under artifact dir.
- **D-19:** Phase 79: switch consumer test to `Runner.run_full_proof!/1` with existing step list assertion; mark HEX-CONSUMER-01 complete in requirements audit.
- **D-20:** Preserve `@moduletag timeout: 180_000`, `async: false`, one `phx.new` host per run (v2.5 D-03, v2.9 precedent).

### DOCS-HEX-01 split (78 vs 82)
- **D-21:** Phase 78 delivers **executable + SSOT tests only** — no README/operator/adoption_lanes prose sweep.
- **D-22:** Phase 78 tests: `HexConsumerContract` unit tests, `host_app_consumer_proof_test` dep shape, `package_surface_test` version/snippet alignment via contract.
- **D-23:** Defer `adoption_surface_test` and `ci_policy_contract_test` **narrative** tarball/registry pins to Phase 82 (after Phase 81 CI topology is stable).
- **D-24:** Optional single README Verification sentence — **late Phase 78 or early Phase 79 only**, after adoption is tarball merge-blocking; not required in 78 foundation PR.

### HostAppProof.Generator dep_mode
- **D-25:** **Required `dep_mode` keyword** — no silent default (`Keyword.fetch!/2` or validate and raise with allowed atoms).
- **D-26:** Adoption consumer test: `create_host!(dep_mode: :hex_tarball, cleanup: &on_exit/1)`.
- **D-27:** `:hex_tarball` patches `mix.exs` via `HexConsumerContract.tarball_dep_tuple(unpack_root)`; `:path` remains explicit opt-in for local maintainer debug only — **never** in adoption tests.
- **D-28:** `HostInstallFixtures` and installer contract tests stay on repo `path:` — fast, repo-local installer truth; do not route through `Generator`.
- **D-29:** Phase 80 will use `dep_mode: :hex_tarball, version: "0.1.0"` (or dedicated atom) on same host struct; no second `phx.new`.

### Claude's Discretion
- Exact `package_fingerprint/0` implementation (mtime vs content hash of `:files` list).
- Whether Phase 78 temporarily allows default `:path` before tightening to required `dep_mode` (prefer required from start).
- Exact `run_route_proof!/1` filtering implementation in `Runner`.
- Optional `SCORIA_ARTIFACT_PATH` local maintainer override (document as non-CI) — defer unless trivial.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements
- `.planning/ROADMAP.md` — Phase 78–82 goals, success criteria, v2.10 scope
- `.planning/REQUIREMENTS.md` — HEX-CONSUMER-01†, DOCS-HEX-01†, out-of-scope table
- `.planning/PROJECT.md` — v2.10 milestone intent, preserved lane contracts
- `.planning/STATE.md` — current position, deferred queue

### Existing SSOT patterns
- `lib/scoria/adopter_doc_contract.ex` — adopter doc drift SSOT pattern to mirror
- `lib/mix/tasks/scoria.release_preview.ex` — `hex.build --unpack` + required package paths
- `test/scoria/package_surface_test.exs` — Hex-primary README guard, hex preview unpack
- `test/scoria/adoption_surface_test.exs` — README/lane drift guards (extend in Phase 82 only)

### Host proof harness
- `test/support/scoria/host_app_proof/generator.ex` — `create_host!/1`, `patch_mix_exs!/2`
- `test/support/scoria/host_app_proof/runner.ex` — `run_route_proof!/1`, `run_full_proof!/1`
- `test/scoria/host_app_consumer_proof_test.exs` — adoption consumer proof entry point
- `lib/mix/tasks/test.adoption.ex` — adoption lane file list
- `priv/host_app_proof/overlay/test/` — HOST route/runtime/handoff smoke sources

### CI topology
- `.github/workflows/ci-verify.yml` — `release_preview` → `test.adoption` order
- `docs/operator_verification.md` — maintainer CI gate map (prose updates Phase 82)
- `test/scoria/ci_policy_contract_test.exs` — CI YAML drift guards (topology pins Phase 82)

### Prior phase decisions
- `.planning/milestones/v2.5-phases/61-proof-and-stability-closeout/61-CONTEXT.md` — D-03 one `phx.new` host; doc SSOT before prose sweep
- `.planning/milestones/v2.7-MILESTONE-AUDIT.md` — Hex-primary README, `package_surface_test` flip

### Project vision & engineering DNA
- `prompts/sztheory-elixir-dna.md` — operator-first DX, batteries-included, `mix install`
- `prompts/phoenix-ai-lib-deep-research.md` §17 — OSS trust: CI gates, semver, changelog, pre-publish artifact verification
- `prompts/scoria-gsd-kickoff.md` — core value: trace-first, executable proof

### External ecosystem
- Hex `mix hex.build` docs — `--unpack` for pre-publish verification
- [hexpm/hex#515](https://github.com/hexpm/hex/issues/515) — unpack + `path:` to package dir for consumer tests

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.AdopterDocContract` — pattern for public lib SSOT + test assertions
- `Mix.Tasks.Scoria.ReleasePreview` — `hex.build --unpack`, `unpack_root!/1`, `@required_package_paths`
- `package_surface_test` — `find_unpack_root!/1`, Hex-primary README assertion, hex preview test
- `HostAppProof.Generator` / `Runner` — phx.new host, overlay copy, proof step chain
- `mix.exs` `@version "0.1.0"` — canonical version edit target

### Established Patterns
- Merge-blocking adoption uses **one** generated host (`host_app_consumer_proof_test`); overlay files copied from `priv/host_app_proof/overlay/test/`
- `VerificationLanes.closeout_order/0` unchanged — tarball proof stays inside `:adoption` lane
- CI: policy job → `release_preview` → `test.adoption` → other closeout lanes → full suite
- Warning inventory classifies `test/support/scoria/host_app_proof/` separately from overlay tests

### Integration Points
- `HexConsumerContract` consumed by: `HostAppProof.Generator`, `host_app_consumer_proof_test`, `package_surface_test`
- `HostAppProof.Generator.patch_mix_exs!/2` — primary injection point for `dep_mode`
- `Runner.run_route_proof!/1` — phase 78 proof depth seam (implement real route-only filter)
- CI env `SCORIA_HEX_UNPACK_ROOT` — wire in `ci-verify.yml` test job after release preview step

</code_context>

<specifics>
## Specific Ideas

- Two-surface SSOT: **adopter Hex snippet** vs **CI tarball path tuple** — same module, explicit functions, no conflation.
- Three-layer caching: contract fingerprint cache + `setup_all` + CI reuse of `tmp/scoria-release-preview`.
- Tracer bullet: prove tarball installs and routes in 78 before re-proving overlays in 79 (v2.9 already validated overlay semantics on `path:`).
- szTheory/Scoria vision: "Trace the run. Prove the change." — post-Hex trust requires packaged artifact proof, not monorepo path.
</specifics>

<deferred>
## Deferred Ideas

- `SCORIA_ARTIFACT_PATH` env override for local maintainer parity (Ecto-style `ECTO_PATH`) — optional, non-CI, document if added
- Full README / `operator_verification.md` / `adoption_lanes.md` tarball narrative — Phase 82
- `adoption_surface_test` / `ci_policy_contract_test` topology pins — Phase 82 (after Phase 81 CI final)
- HOST-01 + HOST-02 overlay on tarball — Phase 79
- Upgrade smoke baseline → current bump — Phase 80
- Live registry + post-publish overlay subset — Phase 81
- Local Hex registry for true `:hex` SCM in PR CI — rejected (ops cost >> benefit vs unpack path)
- Widening `closeout_order/0` or advisory `mix scoria.test.hex_consumer` lane — out of scope per REQUIREMENTS.md

</deferred>

---

*Phase: 78-Hex consumer contract foundation*
*Context gathered: 2026-05-29*
