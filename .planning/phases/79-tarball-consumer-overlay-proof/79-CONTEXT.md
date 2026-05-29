# Phase 79: Tarball consumer overlay proof - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete **HEX-CONSUMER-01** at milestone level: merge-blocking `mix test.adoption` must prove the **packaged tarball** (not repo `path:`) runs the same v2.9 overlay depth — route smoke + HOST-01 runtime (approval/resume/evidence) + HOST-02 handoff — via `Runner.run_full_proof!/1`.

**In scope:** Switch `host_app_consumer_proof_test` from `run_route_proof!/1` to `run_full_proof!/1`; strict step contract; failure diagnostics (rich raises, preserve flag, failure snapshot); optional README Verification one-liner (D-24); ledger reconciliation when verification passes.

**Out of scope:** Upgrade smoke (Phase 80), live registry post-publish (Phase 81), `adoption_surface_test` / `ci_policy_contract_test` narrative pins (Phase 82), widening `VerificationLanes.closeout_order/0`, new closeout lanes, `run_route_proof!/1` removal (keep as debug seam), global ExUnit timeout changes, per-step Runner timeouts, splitting overlay smokes into separate ExUnit cases (duplicate `phx.new` cost).
</domain>

<decisions>
## Implementation Decisions

### Consumer proof switch (core deliverable)
- **D-30:** `host_app_consumer_proof_test` calls `Runner.run_full_proof!(host)` — not `run_route_proof!/1` (implements Phase 78 D-19).
- **D-31:** Keep tarball dep assertions unchanged: `dep_mode: :hex_tarball`, refute repo-root `path:`, assert `HexConsumerContract.tarball_dep_snippet/1`.
- **D-32:** Assert **exact ordered** `proof.steps` via install prefix + derived overlay atoms from `host.overlay_tests` (single source of truth with sorted `priv/host_app_proof/overlay/test/*.exs`):

  ```elixir
  install = [:deps_get, :scoria_install, :ecto_create, :ecto_migrate]
  overlay = Enum.map(host.overlay_tests, &(&1 |> Path.rootname() |> String.to_atom()))
  assert proof.steps == install ++ overlay
  ```

  Expected today: `… ++ [:host_handoff_smoke_test, :host_route_smoke_test, :host_runtime_smoke_test]`. Do **not** use subset/`in` assertions on adoption path. Do **not** assert `:overlay_smoke` (internal to `smoke_pair!/2`).

- **D-33:** Keep `run_route_proof!/1` as route-only debug seam; consumer test must not call it.

### Timeout & CI budget
- **D-34:** Keep `@moduletag timeout: 180_000` and `async: false` (v2.5 D-03, v2.9 shipped full overlay at 180s). Full overlay adds ~5–10s over route-only (~56s warm); not a step-count explosion (one `mix test` subprocess for three overlays).
- **D-35:** Do **not** add per-step ExUnit timeouts in `Runner` — steps are `System.cmd/3`; module tag remains SSOT budget.
- **D-36:** Published maintainer budget: warm local tarball full proof ≤90s p50, ≤120s p95; CI consumer test must stay <180s without changing `mix test.adoption` contract or suite-wide `ExUnit.start/1`.
- **D-37:** Escalation only: if CI consumer proof exceeds **120s on two consecutive runs**, bump module tag to **240_000** (not 300/420) and update `79-VALIDATION.md` + VERIFICATION flake note. Gallery 300s is a different lane — not precedent here.
- **D-38:** Rejected: `420_000`, global adoption timeout widen, splitting overlays into separate ExUnit tests (violates one-host-per-run).

### Failure diagnostics (DX)
- **D-39:** **P0 — Enhanced `Runner` raise** on every failed step: include `step`, command, `host.root`, `host.app_name`, `host.db_name`, `unpack_root` / `SCORIA_HEX_UNPACK_ROOT`, tarball dep snippet, overlay file list, `SCORIA_DB_*` (no password), replay command (`cd #{host.root} && MIX_ENV=test mix test test/<overlay> --trace`), and preserve hint (`SCORIA_PRESERVE_HOST=1 …`). For `smoke_pair!` failures, surface first `FAIL` / `** (` line from nested output.
- **D-40:** **P0 — `SCORIA_PRESERVE_HOST=1`** in `Generator.register_cleanup/2`: when env in `~w(1 true yes)`, skip `on_exit` `File.rm_rf!` and `IO.warn` preserved path (Phoenix `autoremove?: false` precedent).
- **D-41:** **P1 — Failure snapshot:** on proof failure before re-raise, copy `working_root` → `tmp/scoria-host-proof-last-failure/` (replace prior) + `MANIFEST.txt` (timestamp, step, unpack fingerprint/version, replay commands). Workspace-relative for agents and CI artifacts.
- **D-42:** **P1 — CI artifact:** `ci-verify.yml` `upload-artifact` on failure only, path `tmp/scoria-host-proof-last-failure/`, retention 7 days. Do not upload full `_build` or hex cache.
- **D-43:** **P2 — `@moduletag :host_proof`** on consumer module for `mix test --only host_proof` local iteration.
- **D-44:** Rejected: always preserve host (disk hygiene); `MIX_TEST_CLUSTER` patterns (no distribution); second `phx.new` for debug.

### HEX-CONSUMER-01 completion ceremony
- **D-45:** Flip milestone **Complete** only in **same PR tail** as green proof: `79-VERIFICATION.md` (passed) + reconcile `REQUIREMENTS.md` traceability (`HEX-CONSUMER-01 | 78, 79 | Complete` — fix premature Complete/checkbox drift from Phase 78 summaries) + `ROADMAP.md` phase 79 Complete + `STATE.md`. VERIFICATION-only insufficient for 79 (requirement-owning phase).
- **D-46:** Do **not** mark **DOCS-HEX-01** milestone Complete in 79 — prose sweep and D-23 pins remain Phase 82. Executable SSOT tests from 78 stay; no `adoption_surface_test` / `ci_policy_contract_test` narrative pins in 79.
- **D-47:** **D-24 README one-liner in 79** (optional polish, not gate): single sentence under README `## Verification` — adoption closeout exercises `mix hex.build` unpack tarball (not monorepo `path:`), aligned with `HexConsumerContract` / CI `SCORIA_HEX_UNPACK_ROOT`. No `adoption_surface_test` pin until Phase 82.
- **D-48:** Retroactive note in `78-VERIFICATION.md` cross-ref optional: milestone Complete deferred to 79 (audit hygiene).

### Claude's Discretion
- Whether to extract `Runner.expected_steps/1` helper shared with test (nice-to-have).
- Exact `MANIFEST.txt` fields and optional `SCORIA_HOST_PROOF_ROOT` override.
- Operator doc one-paragraph debug blurb in 79 vs minimal defer to 82 (prefer one paragraph in `docs/operator_verification.md` if trivial).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements
- `.planning/ROADMAP.md` — Phase 79 success criteria, v2.10 scope
- `.planning/REQUIREMENTS.md` — HEX-CONSUMER-01 full definition; traceability reconciliation
- `.planning/PROJECT.md` — v2.10 intent, preserved lane contracts
- `.planning/STATE.md` — current position, Phase 78 decisions

### Prior phase context (locked)
- `.planning/phases/78-hex-consumer-contract-foundation/78-CONTEXT.md` — D-16–D-20, D-19 Phase 79 switch
- `.planning/phases/78-hex-consumer-contract-foundation/78-VERIFICATION.md` — partial HEX-CONSUMER-01, route-only evidence
- `.planning/phases/78-hex-consumer-contract-foundation/78-RESEARCH.md` — overlay order, step atoms, timing notes

### Host proof harness
- `test/scoria/host_app_consumer_proof_test.exs` — adoption consumer entry (modify)
- `test/support/scoria/host_app_proof/runner.ex` — `run_full_proof!/1`, `run_route_proof!/1`, enhanced raises
- `test/support/scoria/host_app_proof/generator.ex` — preserve flag, cleanup
- `priv/host_app_proof/overlay/test/` — `host_route_smoke_test.exs`, `host_runtime_smoke_test.exs`, `host_handoff_smoke_test.exs`
- `lib/scoria/hex_consumer_contract.ex` — tarball dep SSOT
- `lib/mix/tasks/test.adoption.ex` — adoption file list (unchanged)

### v2.9 overlay precedent
- `.planning/milestones/v2.9-MILESTONE-AUDIT.md` — HOST-01/HOST-02 validated on generated host
- `.planning/milestones/v2.9-REQUIREMENTS.md` — HOST-01, HOST-02 definitions

### CI & docs
- `.github/workflows/ci-verify.yml` — `SCORIA_HEX_UNPACK_ROOT`, failure artifact hook
- `docs/operator_verification.md` — maintainer debug (minimal update OK)
- `README.md` — optional D-24 Verification sentence

### Project vision & engineering DNA
- `prompts/sztheory-elixir-dna.md` — operator-first DX, executable proof, batteries-included
- `prompts/phoenix-ai-lib-deep-research.md` §17 — OSS trust: CI gates, semver, pre-publish artifact verification
- `prompts/scoria-gsd-kickoff.md` — trace-first, executable proof over prose

### Prior milestone patterns
- `.planning/milestones/v2.5-phases/61-proof-and-stability-closeout/61-CONTEXT.md` — one `phx.new` host, doc SSOT before prose sweep

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Runner.run_full_proof!/1` — already runs all overlays via `smoke_pair!/1`; Phase 79 is test switch + assertions + DX, not new proof chain
- `Runner.run_route_proof!/1` — route-only filter for fast local debug
- `HexConsumerContract.ensure_current_unpack_root!/0` — `setup_all` unpack cache (Phase 78)
- Three overlay smokes in `priv/host_app_proof/overlay/test/` — HOST-01/02 semantics proven on `path:` in v2.9; 79 re-proves on tarball

### Established Patterns
- Exact ordered `proof.steps == [...]` contract (Phase 78 route, gallery proof)
- One generated Phoenix host per adoption proof (`async: false`, 180s module tag)
- Tarball dep `{:scoria, path: unpack_root}` in generated `mix.exs` — not repo root
- `VerificationLanes.closeout_order/0` unchanged — proof stays in `:adoption` lane

### Integration Points
- `host_app_consumer_proof_test.exs` — sole merge-blocking consumer proof file
- `Generator.register_cleanup/2` — preserve flag + failure snapshot hook
- `Runner.run_mix!/1` — enhanced triage block on failure
- `ci-verify.yml` test job — conditional artifact upload

</code_context>

<specifics>
## Specific Ideas

Research-backed cohesive stance (user requested one-shot recommendations):

- **Principle of least surprise:** Phase 79 is the mechanical completion of Phase 78's explicit seam (`run_route_proof` → `run_full_proof`) — adopters already trust v2.9 overlay semantics; 79 proves the **artifact** runs them.
- **Ecosystem idioms:** Phoenix generator tests use `autoremove?: false` for inspection; Hex consumer tests use unpack + path dep (Hex #515); ExUnit uses module-level timeout for slow integration — all align with D-34–D-44.
- **OSS trust (§17 research):** Merge-blocking proof + changelog/semver + bounded verifier timeouts; avoid masking hangs with 7-minute tags.
- **Footgun avoided:** Premature `REQUIREMENTS.md` Complete from Phase 78 summaries — reconcile only when 79-VERIFICATION passes (v2.5/v2.7 audit lesson).
</specifics>

<deferred>
## Deferred Ideas

- Upgrade smoke on same host struct — Phase 80 (`dep_mode` + version pin)
- Live registry `{:scoria, hex: :scoria}` in PR CI — Phase 81
- Full README / operator / adoption_lanes prose + `adoption_surface_test` pins — Phase 82
- `SCORIA_ARTIFACT_PATH` / `SCORIA_HOST_PROOF_ROOT` general overrides — optional, non-CI
- Per-overlay ExUnit tests (duplicate `phx.new`) — rejected
- Global `mix test.adoption --trace` as public contract — rejected

</deferred>

---

*Phase: 79-Tarball consumer overlay proof*
*Context gathered: 2026-05-29*
