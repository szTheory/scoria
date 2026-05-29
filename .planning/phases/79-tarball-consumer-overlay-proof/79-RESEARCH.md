# Phase 79 Research: Tarball Consumer Overlay Proof

**Researched:** 2026-05-29  
**Phase:** 79 — Tarball consumer overlay proof  
**Requirements:** HEX-CONSUMER-01 (completion)  
**Objective:** What a planner needs to know before authoring Phase 79 plans.

## Summary

Phase 79 is the **mechanical completion** of Phase 78's explicit seam (D-19): switch merge-blocking `host_app_consumer_proof_test` from `Runner.run_route_proof!/1` to `Runner.run_full_proof!/1` so adoption proves the **packaged tarball** runs the same v2.9 overlay depth (route + HOST-01 runtime + HOST-02 handoff). Phase 78 already shipped `HexConsumerContract`, fingerprinted unpack cache, tarball `dep_mode`, route-only runner filter, and CI `SCORIA_HEX_UNPACK_ROOT` reuse — `run_full_proof!/1` exists and runs all three overlays in **one** `mix test` subprocess via `smoke_pair!/1` (`runner.ex:35–42`).

Phase 79 adds: (1) consumer test switch + derived exact step assertion, (2) failure diagnostics stack (enhanced raises, `SCORIA_PRESERVE_HOST`, failure snapshot, CI artifact), (3) HEX-CONSUMER-01 milestone closeout ceremony reconciling premature `REQUIREMENTS.md` drift from Phase 78 summaries. No new proof chain, no `mix test.adoption` file-list change, no `closeout_order/0` widening.

**Primary recommendation:** Three-plan wave — (1) consumer proof switch + step SSOT + `:host_proof` tag, (2) failure diagnostics (Runner raise, preserve flag, snapshot), (3) CI artifact + closeout ceremony + optional README/operator blurb — with `mix test.adoption` as the phase gate and `host_app_consumer_proof_test.exs` as the targeted integration probe.

---

## Requirement Mapping

| ID | Phase 79 slice | Deliverable |
|----|----------------|-------------|
| **HEX-CONSUMER-01** | Full overlay on tarball dep inside `mix test.adoption` | `run_full_proof!/1`, seven-step derived assertion, green adoption lane |
| **HEX-CONSUMER-01** | Failure triage for sandbox/LiveView overlays | Enhanced `Runner` raise, `SCORIA_PRESERVE_HOST`, snapshot + CI artifact |
| **HEX-CONSUMER-01** | Milestone truth reconciliation | `79-VERIFICATION.md`, `REQUIREMENTS.md` / `ROADMAP.md` / `STATE.md` ceremony (D-45) |
| **DOCS-HEX-01** | Optional README one-liner only (D-47) | Single Verification sentence — **not** milestone Complete for DOCS-HEX-01 |
| **Out of scope** | Upgrade smoke, live registry, prose sweep, new lanes | Phases 80–82 per `79-CONTEXT.md` |

---

## Current State

### Phase 78 shipped (reuse as-is)

| Asset | Location | Phase 79 role |
|-------|----------|---------------|
| Tarball SSOT + cache | `lib/scoria/hex_consumer_contract.ex` | Unchanged; snapshot MANIFEST uses `package_fingerprint/0` + `published_version/0` |
| Tarball dep generator | `test/support/scoria/host_app_proof/generator.ex` | Extend host map + preserve flag; **no** dep_mode change |
| Route-only filter | `runner.ex:25–32` `@route_overlay_test` | Keep as debug seam (D-33) |
| Full proof runner | `runner.ex:35–42` `run_full_proof!/1` | Consumer test switches here (D-30) |
| Consumer test (route-only) | `host_app_consumer_proof_test.exs:20–28` | **Modify** — one-line runner swap + step assertion |
| Adoption lane entry | `lib/mix/tasks/test.adoption.ex:14` | **Untouched** |
| CI unpack reuse | `ci-verify.yml:82` `SCORIA_HEX_UNPACK_ROOT` | Add failure artifact step only |
| Overlay sources | `priv/host_app_proof/overlay/test/*.exs` (3 files) | HOST-01/02 semantics proven on repo `path:` in v2.9; 79 re-proves on tarball |

### Phase 78 evidence (timing baseline)

| Command | Result | Notes |
|---------|--------|-------|
| `mix test host_app_consumer_proof_test.exs` | ~53–56s | Route-only tarball proof (78-VERIFICATION) |
| `mix test.adoption` (CI parity) | ~49–69s | Full adoption lane with route-only consumer |
| `@moduletag timeout: 180_000` | Preserved | v2.5 D-03, v2.9 full-overlay precedent |

Full overlay adds ~5–10s (two more smokes in **same** `mix test` subprocess, not three separate hosts). Expected warm p50 ≤90s, p95 ≤120s (D-36); module tag stays 180_000 unless CI exceeds 120s twice (D-37 → 240_000 escalation).

### Gaps (Phase 79 work)

1. **Consumer test still calls `run_route_proof!/1`** — five-step assertion; runtime/handoff not exercised on tarball (`host_app_consumer_proof_test.exs:20–28`).
2. **Step assertion hardcoded to route-only tuple** — should derive from `host.overlay_tests` per D-32 (install prefix + sorted overlay atoms).
3. **Minimal failure raise** — `run_mix!/1` includes step, command, host root, raw output only (`runner.ex:64–70`); missing D-39 triage block.
4. **No preserve flag** — `register_cleanup/2` always `File.rm_rf!(working_root)` on exit (`generator.ex:210–214`).
5. **No failure snapshot** — `working_root` is local to `create_host!/1`, not on host map (`generator.ex:23–24`); snapshot path `tmp/scoria-host-proof-last-failure/` does not exist.
6. **No CI artifact upload** — zero `upload-artifact` steps in `.github/workflows/` today.
7. **No `@moduletag :host_proof`** — local iteration requires full adoption lane.
8. **REQUIREMENTS ledger drift** — checkbox `[x]` and traceability `Complete` for HEX-CONSUMER-01 in `REQUIREMENTS.md` ahead of overlay depth; 78-VERIFICATION correctly marks **Partial**. Ceremony in 79 must reconcile (D-45).
9. **Optional docs** — README Verification section has no tarball one-liner (D-47); `operator_verification.md` mentions runtime proof but not tarball/ preserve debug.

### Explicit non-goals (locked)

- Remove `run_route_proof!/1` (D-33 — debug seam).
- Per-step Runner timeouts or global ExUnit timeout widen (D-35, D-38).
- Split overlays into separate ExUnit cases (duplicate `phx.new`, D-38).
- `420_000` module tag or gallery 300s as precedent (D-37).
- `adoption_surface_test` / `ci_policy_contract_test` narrative pins (Phase 82, D-46).
- Mark DOCS-HEX-01 milestone Complete (Phase 82).
- Widen `VerificationLanes.closeout_order/0`.

---

## 1. Consumer Test Switch (D-30, D-31)

### Change surface

Single mechanical swap in `host_app_consumer_proof_test.exs`:

```elixir
proof = Runner.run_full_proof!(host)
```

**Preserve unchanged (D-31):**

- `setup_all` → `ensure_current_unpack_root!/0`
- `dep_mode: :hex_tarball`, `unpack_root:`, `cleanup: &on_exit/1`
- Tarball dep assertions: refute repo-root `path:`, assert `HexConsumerContract.tarball_dep_snippet/1`
- `@moduletag timeout: 180_000`, `async: false`

### Why this completes HEX-CONSUMER-01

`run_full_proof!/1` invokes `smoke_pair!(host, host.overlay_tests)` which runs **one** subprocess:

```bash
mix test test/host_handoff_smoke_test.exs test/host_route_smoke_test.exs test/host_runtime_smoke_test.exs --trace
```

All three overlay files are copied at host creation regardless of runner (`generator.ex:57–58`, `copy_overlay!/1`). v2.9 validated HOST-01/HOST-02 semantics on generated host with repo `path:`; Phase 79 proves the **tarball artifact** compiles and passes the same smokes.

### Optional: enrich host map for diagnostics

`create_host!/1` should add fields needed by D-39/D-41 (planner discretion, recommended):

```elixir
%{
  ...
  working_root: working_root,   # parent of host.root — snapshot + preserve target
  unpack_root: unpack_root,     # when dep_mode :hex_tarball
  dep_mode: dep_mode
}
```

Without `working_root` on the host map, failure snapshot cannot copy the full generated tree from `Runner` alone.

---

## 2. Step Assertion Contract (D-32)

### SSOT derivation (recommended)

Match Phase 78 style but derive overlay atoms from generator sort order:

```elixir
install = [:deps_get, :scoria_install, :ecto_create, :ecto_migrate]

overlay =
  host.overlay_tests
  |> Enum.map(fn file -> file |> Path.rootname() |> String.to_atom() end)

assert proof.steps == install ++ overlay
```

**Optional helper** (Claude discretion, D-32):

```elixir
# Runner or shared module
def expected_steps(host) do
  install = [:deps_get, :scoria_install, :ecto_create, :ecto_migrate]
  overlay = Enum.map(host.overlay_tests, &(&1 |> Path.rootname() |> String.to_atom()))
  install ++ overlay
end
```

Consumer test: `assert proof.steps == Runner.expected_steps(host)`.

### Expected steps today

Sorted `priv/host_app_proof/overlay/test/*.exs` basenames (`generator.ex:7–10`):

| File | Step atom | Requirement |
|------|-----------|-------------|
| `host_handoff_smoke_test.exs` | `:host_handoff_smoke_test` | HOST-02 |
| `host_route_smoke_test.exs` | `:host_route_smoke_test` | route smoke |
| `host_runtime_smoke_test.exs` | `:host_runtime_smoke_test` | HOST-01 |

**Full assertion:**

```elixir
[:deps_get, :scoria_install, :ecto_create, :ecto_migrate,
 :host_handoff_smoke_test, :host_route_smoke_test, :host_runtime_smoke_test]
```

### What NOT to assert

- **`:overlay_smoke`** — internal `run_mix!/1` step inside `smoke_pair!/1`; `run_steps/2` flat-maps only the per-file atoms returned by `smoke_pair!/1` (`runner.ex:45–50`, `18–22`).
- **Subset / `in` assertions** — rejected on adoption path (D-32).
- **Requirement prose order** (route → runtime → handoff) — execution order follows **sorted filenames** (handoff → route → runtime). v2.9 and Phase 78 established this SSOT; all three run in one subprocess regardless of order.

---

## 3. Overlay Order SSOT

```
Generator.overlay_test_files/0
  → Path.wildcard(priv/.../overlay/test/*.exs)
  → Enum.sort/1 basenames
  → host.overlay_tests

Runner.run_full_proof!/1
  → smoke_pair!(host)  # all host.overlay_tests
  → one mix test subprocess, files in overlay_tests order

proof.steps
  → install atoms ++ one atom per overlay file (NOT :overlay_smoke)
```

Adding a fourth overlay file in `priv/` automatically extends proof depth — consumer test derived assertion stays correct without hardcoded tuple edits. Removing/reordering files requires intentional priv/ change + v2.9 HOST semantics review.

---

## 4. Runner Raise Enhancement (D-39, P0)

### Current raise (`runner.ex:64–70`)

Minimal: step, command, host root, output.

### Required triage block

On every failed `run_mix!/1` step, raise must include:

| Field | Source |
|-------|--------|
| `step` | `run_mix!` argument |
| `command` | `mix #{Enum.join(args, " ")}` |
| `host.root`, `host.app_name`, `host.db_name` | host map |
| `unpack_root` / `SCORIA_HEX_UNPACK_ROOT` | host map + `System.get_env/1` |
| Tarball dep snippet | `HexConsumerContract.tarball_dep_snippet(unpack_root)` |
| Overlay file list | `host.overlay_tests` |
| `SCORIA_DB_*` | env (host, port, username — **no password**) |
| Replay command | See below |
| Preserve hint | `SCORIA_PRESERVE_HOST=1 MIX_ENV=test mix test ...` |

### Replay commands

**Install steps** (`deps_get`, `scoria_install`, `ecto_create`, `ecto_migrate`):

```elixir
"cd #{host.root} && MIX_ENV=test mix #{Enum.join(args, " ")}"
```

**Overlay failure** (`:overlay_smoke` step inside `smoke_pair!/1`):

```elixir
overlay_paths = Enum.map(host.overlay_tests, &("test/" <> &1))
"cd #{host.root} && MIX_ENV=test mix test #{Enum.join(overlay_paths, " ")} --trace"
```

Per-overlay replay when a specific file can be inferred:

```elixir
"cd #{host.root} && MIX_ENV=test mix test test/#{file} --trace"
```

### smoke_pair nested failure extraction

When `step == :overlay_smoke`, scan `output` for first line matching:

- `FAIL` (ExUnit failure marker), or
- `** (` (ExUnit stack/context marker)

Prepend extracted line to triage block before full output (truncate if huge). Helps distinguish runtime sandbox vs handoff LiveView failures inside combined subprocess output.

### Implementation sketch

Refactor `run_mix!/1` failure path:

```elixir
if status != 0 do
  maybe_snapshot_failure!(host, step)  # D-41 — before re-raise
  raise triage_message(host, step, args, output)
end
```

Extract `triage_message/4` and `extract_nested_failure_line/1` as private functions. Keep raises as plain strings (existing pattern) — no custom exception modules required.

---

## 5. Preserve Flag (D-40, P0)

### Location

`Generator.register_cleanup/2` (`generator.ex:210–214`).

### Behavior

```elixir
defp preserve_host? do
  System.get_env("SCORIA_PRESERVE_HOST") in ~w(1 true yes)
end

defp register_cleanup(opts, path) do
  case Keyword.get(opts, :cleanup) do
    nil -> :ok
    register when is_function(register, 1) ->
      if preserve_host?() do
        IO.warn("SCORIA_PRESERVE_HOST: preserved host at #{path}")
      else
        register.(fn -> File.rm_rf!(path) end)
      end
  end
end
```

**Precedent:** Phoenix generator `autoremove?: false` for inspection. Default remains cleanup-on-exit (disk hygiene — rejected always-preserve, D-44).

### Maintainer usage

```bash
SCORIA_PRESERVE_HOST=1 MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs --trace
# or with tag:
SCORIA_PRESERVE_HOST=1 mix test --only host_proof
```

Preserved path is `working_root` (includes generated app dir), not only `host.root`.

---

## 6. Failure Snapshot (D-41, P1)

### Trigger

On any proof step failure, **before** re-raise in `Runner` (or shared hook called from `run_mix!/1`).

### Destination

```
tmp/scoria-host-proof-last-failure/   # workspace-relative, replace prior
├── MANIFEST.txt
└── <copied working_root tree>
```

### Copy semantics

1. `File.rm_rf!("tmp/scoria-host-proof-last-failure")` if exists.
2. `File.mkdir_p!("tmp/scoria-host-proof-last-failure")`.
3. Copy `host.working_root` → `tmp/scoria-host-proof-last-failure/host/` (or mirror basename).
4. Write `MANIFEST.txt` alongside.

### MANIFEST.txt fields (minimum)

```
timestamp: 2026-05-29T...
failed_step: overlay_smoke | deps_get | ...
host_root: /tmp/scoria-host-proof-123/scoria_host_proof_123
app_name: scoria_host_proof_123
db_name: scoria_host_proof_123_test
unpack_root: /abs/path/to/unpack
scoria_version: 0.1.0
package_fingerprint: <12-char from HexConsumerContract.package_fingerprint/0>
SCORIA_HEX_UNPACK_ROOT: tmp/scoria-release-preview | (unset)
replay_full: cd ... && MIX_ENV=test mix test test/host_... --trace
replay_preserve: SCORIA_PRESERVE_HOST=1 MIX_ENV=test mix test --only host_proof
tarball_dep: {:scoria, path: "..."}
```

Optional `SCORIA_HOST_PROOF_ROOT` override for snapshot destination — non-CI, planner discretion.

### Dependencies

Requires `working_root` (and ideally `unpack_root`) on host map — see §1.

---

## 7. CI Artifact Hook (D-42, P1)

### First artifact in repo

No existing `actions/upload-artifact` in `.github/workflows/`. Phase 79 introduces conditional upload on test job failure.

### Recommended placement

`.github/workflows/ci-verify.yml` — `test` job, after adoption lane (or end of job with `if: failure()`):

```yaml
- name: Upload host proof failure snapshot
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: scoria-host-proof-last-failure
    path: tmp/scoria-host-proof-last-failure/
    retention-days: 7
    if-no-files-found: ignore
```

**Constraints (D-42):**

- Failure only — not on green runs.
- Path scoped to snapshot dir — **not** `_build`, hex cache, or full tmp.
- `if-no-files-found: ignore` — failures outside consumer proof do not fail the artifact step.

Snapshot must land under workspace `tmp/` (not system `/tmp` only) so GHA can upload it. `Generator.working_root` uses `System.tmp_dir!()` today — snapshot **copy** to workspace `tmp/scoria-host-proof-last-failure/` satisfies CI artifact path regardless of where host was generated.

---

## 8. Module Tag for Local Iteration (D-43, P2)

Add to `HostAppConsumerProofTest`:

```elixir
@moduletag :host_proof
```

Maintainer loop:

```bash
mix test --only host_proof
SCORIA_PRESERVE_HOST=1 mix test --only host_proof --trace
```

Does not change `mix test.adoption` contract — tag is additive for ExUnit filtering.

---

## 9. HEX-CONSUMER-01 Closeout Ceremony (D-45–D-48)

### Same PR tail as green proof (requirement-owning phase)

| Artifact | Action |
|----------|--------|
| `79-VERIFICATION.md` | Write with `status: passed` after all gates green |
| `.planning/REQUIREMENTS.md` | Confirm `[x]` HEX-CONSUMER-01 checkbox; traceability `78, 79 \| Complete`; fix narrative if still says route-only |
| `.planning/ROADMAP.md` | Phase 79 → Complete with date |
| `.planning/STATE.md` | Phase 79 complete; pointer to Phase 80 |
| `78-VERIFICATION.md` | Optional retro note: milestone Complete deferred to 79 (D-48 audit hygiene) |

**Insufficient:** VERIFICATION-only update without REQUIREMENTS/ROADMAP/STATE (D-45).

**Do not:** Mark DOCS-HEX-01 milestone Complete — prose sweep + drift pins remain Phase 82 (D-46).

### Optional README one-liner (D-47, not gate)

Under README `## Verification` (~L191), after adoption commands:

> Adoption closeout in CI exercises Scoria via a `mix hex.build --unpack` tarball (`{:scoria, path: unpack_root}`), not a monorepo root `path:` — see `Scoria.HexConsumerContract` and `SCORIA_HEX_UNPACK_ROOT` in maintainer CI.

No `adoption_surface_test` pin until Phase 82.

### Optional operator doc (Claude discretion)

One paragraph in `docs/operator_verification.md`: tarball consumer proof, `SCORIA_PRESERVE_HOST`, snapshot path, `--only host_proof`. Defer extended prose to Phase 82 if non-trivial.

---

## 10. Test File Structure & Plan Wave Ordering

### Modified files

| File | Action | Priority |
|------|--------|----------|
| `test/scoria/host_app_consumer_proof_test.exs` | Switch to `run_full_proof!/1`, derived steps, `:host_proof` tag | P0 |
| `test/support/scoria/host_app_proof/runner.ex` | Enhanced raise, nested failure extract, snapshot hook, optional `expected_steps/1` | P0–P1 |
| `test/support/scoria/host_app_proof/generator.ex` | `SCORIA_PRESERVE_HOST`, host map enrichment | P0 |
| `.github/workflows/ci-verify.yml` | Conditional `upload-artifact` | P1 |
| `README.md` | Optional Verification one-liner | P2 |
| `docs/operator_verification.md` | Optional debug paragraph | P2 |
| `.planning/REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `79-VERIFICATION.md` | Closeout ceremony | Gate |

**Untouched:** `lib/mix/tasks/test.adoption.ex`, `HexConsumerContract`, `run_route_proof!/1`, overlay priv sources, `VerificationLanes`, `adoption_surface_test`, `ci_policy_contract_test`.

### Recommended three-plan waves

| Plan | Wave | Scope | Depends on |
|------|------|-------|------------|
| **79-01** | 1 | Consumer test → `run_full_proof!/1`; derived `proof.steps`; `@moduletag :host_proof`; optional `expected_steps/1` + host map fields | — |
| **79-02** | 2 | Runner enhanced raise + nested FAIL extract; Generator `SCORIA_PRESERVE_HOST`; failure snapshot + MANIFEST | 79-01 |
| **79-03** | 3 | CI artifact; closeout ceremony; optional README/operator blurb; `79-VALIDATION.md` timing note | 79-02 |

**Gate after each wave:** targeted commands below; **phase gate** `mix test.adoption`.

Alternative: merge 79-02+79-03 if snapshot + CI artifact are tightly coupled in one PR — planner may combine if single review preferred.

---

## 11. Risks & Pitfalls

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Runtime/handoff flake on tarball** | Adoption lane red on packaged artifact | Preserve + snapshot + CI artifact; enhanced raise with replay; v2.9 overlay already green on path dep |
| **180s timeout insufficient** | CI hang/fail | D-36 budget: expect ~60–70s warm; escalate to 240_000 only after CI >120s twice (D-37) |
| **Combined overlay subprocess obscures failing file** | Hard triage | Extract first FAIL/`** (` line; MANIFEST replay lists all overlay paths |
| **`working_root` not on host map** | Snapshot copies wrong/missing tree | Add to `create_host!/1` return (§1) |
| **Premature HEX-CONSUMER-01 Complete** | Milestone audit false positive | Ceremony bundle D-45; 78-VERIFICATION already documents partial |
| **Assert `:overlay_smoke` in steps** | Wrong contract vs `smoke_pair!/1` design | Derived assertion excludes internal step (D-32) |
| **Hardcoded seven-tuple drifts on new overlay file** | Brittle test | Prefer derived `expected_steps/1` |
| **Always preserve hosts** | Disk exhaustion in CI/dev | Opt-in env only (D-40, D-44) |
| **Upload full `_build` artifact** | Slow CI, leaked cache noise | Scoped path only (D-42) |
| **Split overlay ExUnit tests** | 3× `phx.new` cost | Rejected — one host per run (D-38) |
| **Tarball missing overlay support modules** | False confidence if path dep worked | Tarball is `hex.build` output — same files as publish; fingerprint cache catches stale unpack |
| **REQUIREMENTS checkbox already `[x]`** | Confusion about done-ness | 79 ceremony aligns checkbox with full overlay evidence |

---

## 12. Integration Points (downstream phases)

| Phase | Consumes Phase 79 |
|-------|-------------------|
| **80** | Same host struct + `run_full_proof!/1`; `baseline_upgrade_version/0` + committed `0.1.0` fixture |
| **81** | Live `hex: :scoria` post-publish — separate from tarball tuple |
| **82** | README/operator/adoption_lanes prose + `adoption_surface_test` / `ci_policy_contract_test` pins |

Phase 79 failure diagnostics (`SCORIA_PRESERVE_HOST`, snapshot path) directly benefit Phase 80 upgrade smoke debugging on same host harness.

---

## Out of Scope (Phases 80–82)

| Item | Phase |
|------|-------|
| Upgrade smoke (`HEX-UPGRADE-01`) | 80 |
| Live registry post-publish (`HEX-REGISTRY-01`) | 81 |
| Full docs sweep + drift pins (`DOCS-HEX-01` Complete) | 82 |
| `adoption_surface_test` / `ci_policy_contract_test` tarball narrative | 82 |
| `run_route_proof!/1` removal | Never (debug seam) |
| New closeout lanes / `closeout_order/0` widen | — |
| `SCORIA_ARTIFACT_PATH` general overrides | Optional future |
| Per-overlay separate ExUnit cases | Rejected |

---

## Validation Architecture

Nyquist mapping: HEX-CONSUMER-01 completion → executable commands with timing budgets and triage paths.

### Test framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Adoption lane | `mix test.adoption` → `Mix.Tasks.Scoria.Test.Adoption` |
| Consumer proof timeout | `@moduletag timeout: 180_000` on `HostAppConsumerProofTest` (escalation: 240_000 per D-37) |
| Local iteration tag | `@moduletag :host_proof` → `mix test --only host_proof` |
| Postgres | Required (ecto.create/migrate + sandbox overlays) |
| CI unpack | `SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview` after `mix scoria.release_preview` |

### Timing budgets

| Context | p50 target | p95 target | Hard ceiling | Escalation |
|---------|------------|------------|--------------|------------|
| `host_app_consumer_proof_test.exs` (warm, full overlay) | ≤90s | ≤120s | 180s module tag | If CI >120s **two consecutive runs** → bump to 240_000 + update `79-VALIDATION.md` |
| `mix test.adoption` (full lane) | ~60–90s incremental over Phase 78 | ~120s | Suite inherits consumer tag | Do not widen global ExUnit |
| Gallery lane (reference only) | — | — | 300s | **Not precedent** for consumer proof (D-37) |

Phase 78 baseline: route-only consumer ~53–56s; adoption lane ~49–69s CI parity. Full overlay delta ~5–10s (one extra subprocess work, not three hosts).

### Requirement → test map

| Req ID | Behavior | Test type | Automated command | Exists? |
|--------|----------|-----------|-------------------|---------|
| **HEX-CONSUMER-01** | Tarball dep, not repo root | integration | `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs` | ✅ modify |
| **HEX-CONSUMER-01** | deps.get → install → migrate → **full overlay** | integration | same (`run_full_proof!/1`) | ✅ modify |
| **HEX-CONSUMER-01** | Exact ordered seven-step contract | integration | assert `proof.steps == install ++ overlay` | ❌ add |
| **HEX-CONSUMER-01** | Adoption closeout green | lane | `MIX_ENV=test mix test.adoption` | ✅ gate |
| **HEX-CONSUMER-01** | Enhanced failure triage | DX / manual | Induce failure + check raise fields | ❌ add |
| **HEX-CONSUMER-01** | Preserve host for debug | DX / manual | `SCORIA_PRESERVE_HOST=1 mix test --only host_proof` | ❌ add |
| **HEX-CONSUMER-01** | Failure snapshot on disk | DX / manual | Induce failure → `tmp/scoria-host-proof-last-failure/MANIFEST.txt` | ❌ add |
| **HEX-CONSUMER-01** | CI artifact on failure | CI | GHA upload after failed adoption | ❌ add |
| **Preserved** | Route-only debug seam | unit | `run_route_proof!/1` still compiles/callable | ✅ |
| **Preserved** | Closeout order unchanged | contract | `mix test test/scoria/verification_lanes_test.exs` | ✅ |
| **Preserved** | Adoption file list | discoverability | `mix test test/mix/tasks/test.adoption_test.exs` | ✅ |

### Sampling rate (plan waves)

| When | Command |
|------|---------|
| After 79-01 (proof switch) | `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs` |
| After 79-01 (tag check) | `MIX_ENV=test mix test --only host_proof` |
| After 79-02 (diagnostics) | Induced failure locally; verify preserve + snapshot |
| **Phase gate** | `MIX_ENV=test mix test.adoption` |
| CI parity (maintainer) | `MIX_ENV=dev mix scoria.release_preview && SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview MIX_ENV=test mix test.adoption` |
| Closeout | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs test/mix/tasks/test.adoption_test.exs` |

### CI verification steps

1. Policy job green (unchanged).
2. Test job: `mix scoria.release_preview` → `mix test.adoption` with full overlay consumer (~60–90s expected).
3. On failure: confirm `tmp/scoria-host-proof-last-failure/` artifact uploaded (7-day retention).
4. First post-merge GHA run: record consumer timing; if >120s twice, execute D-37 escalation.

### Failure triage paths

| Symptom | First check | Deep dive |
|---------|-------------|-----------|
| Consumer test timeout (>180s) | CI runner load; DB service health | `--trace` locally; check `HOST STEP` logs; compare warm vs cold |
| `:deps_get` / `:scoria_install` fail | Tarball unpack path stale/wrong | `echo $SCORIA_HEX_UNPACK_ROOT`; `HexConsumerContract.ensure_current_unpack_root!/0`; re-run `mix scoria.release_preview` |
| `:ecto_create` / `:ecto_migrate` fail | Postgres env in generated host | Raise block `SCORIA_DB_*`; CI service port 55432 |
| `:overlay_smoke` fail (route) | Tarball missing router/install surfaces | Replay route overlay only; compare unpack `mix.exs` vs repo |
| `:overlay_smoke` fail (runtime) | HOST-01 sandbox/Reconciler | Extract FAIL line; `SCORIA_PRESERVE_HOST=1 mix test test/host_runtime_smoke_test.exs --trace` in preserved host |
| `:overlay_smoke` fail (handoff) | HOST-02 LiveView evidence | Replay handoff overlay; inspect `/scoria/workflows/:run_id` assertions |
| Empty CI artifact | Failure before snapshot hook | Confirm snapshot runs in `run_mix!` before raise; path under workspace `tmp/` |
| Step list assertion mismatch | New overlay file or sort order change | `host.overlay_tests` vs hardcoded tuple; use derived assertion |

### Wave 0 gaps (to create in plans)

- [ ] Consumer test uses `run_full_proof!/1` with derived step assertion
- [ ] `@moduletag :host_proof`
- [ ] Enhanced `Runner` raise (D-39 fields + nested FAIL extract)
- [ ] `SCORIA_PRESERVE_HOST` in Generator cleanup
- [ ] Failure snapshot → `tmp/scoria-host-proof-last-failure/`
- [ ] CI `upload-artifact` on failure
- [ ] Closeout ceremony artifacts (79-VERIFICATION, ledger reconciliation)
- [ ] Optional README / operator blurb

---

## RESEARCH COMPLETE
