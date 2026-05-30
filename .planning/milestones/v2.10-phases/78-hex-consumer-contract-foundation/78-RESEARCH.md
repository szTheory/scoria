# Phase 78 Research: Hex Consumer Contract Foundation

**Researched:** 2026-05-29  
**Phase:** 78 — Hex consumer contract foundation  
**Requirements (partial):** HEX-CONSUMER-01†, DOCS-HEX-01†  
**Objective:** What a planner needs to know before authoring Phase 78 plans.

## Summary

Phase 78 closes the gap between “Scoria is published on Hex” and “merge-blocking adoption proves the **packaged artifact**.” Today `HostAppProof.Generator.create_host!/1` always injects `{:scoria, path: repo_root}` (`test/support/scoria/host_app_proof/generator.ex:67–74`), and `host_app_consumer_proof_test.exs` **asserts** that repo-root path (`:13`). `Runner.run_route_proof!/1` is a dead alias of `run_full_proof!/1` — both run all three overlay smokes (`runner.ex:21–38`).

The phase introduces `Scoria.HexConsumerContract` (mirror `Scoria.AdopterDocContract`), lazy/cached `mix hex.build --unpack` via `ensure_current_unpack_root!/0`, required `dep_mode` on the generator, a real route-only runner filter, and CI reuse of `tmp/scoria-release-preview` through `SCORIA_HEX_UNPACK_ROOT`. Proof depth stays at **route tracer** (Hybrid C); full HOST-01/HOST-02 overlay on tarball is Phase 79.

**Primary recommendation:** Three-plan wave — (1) contract SSOT + unit guards, (2) unpack cache + `package_surface_test` refactor, (3) generator/runner/consumer test + CI env — with `mix test.adoption` as the phase gate.

---

## Requirement Mapping

| ID | Phase 78 slice | Deliverable |
|----|----------------|-------------|
| **HEX-CONSUMER-01†** | Tarball dep → `deps.get` → `scoria.install` → migrate → **route smoke only** | `dep_mode: :hex_tarball`, `run_route_proof!/1`, consumer test assertions |
| **DOCS-HEX-01†** | SSOT module + executable test guards only | `HexConsumerContract`, `hex_consumer_contract_test`, `package_surface_test` via contract |
| **Out of scope** | HOST-01/02 on tarball, upgrade smoke, live registry, prose sweep, new lanes | Phases 79–82 per `78-CONTEXT.md` |

---

## Current State

### Reusable assets

| Asset | Location | Role |
|-------|----------|------|
| Adopter SSOT pattern | `lib/scoria/adopter_doc_contract.ex` | Public lib module; tests import constants — **no runtime** |
| Release unpack | `lib/mix/tasks/scoria.release_preview.ex` | `mix hex.build --unpack --output tmp/scoria-release-preview`; `unpack_root!/1` handles nested unpack dir |
| Package guards | `test/scoria/package_surface_test.exs` | Hardcoded Hex dep strings; per-test `hex.build` into unique tmp dir (`:69–91`) |
| Host harness | `test/support/scoria/host_app_proof/generator.ex` | `phx.new` host, copies `priv/host_app_proof/overlay/test/*.exs`, repo `path:` dep |
| Proof runner | `test/support/scoria/host_app_proof/runner.ex` | Step chain: deps.get → install → ecto.create → migrate → overlay smokes |
| Adoption entry | `test/scoria/host_app_consumer_proof_test.exs` | Single test, `async: false`, `@moduletag timeout: 180_000`, calls `run_full_proof!/1` |
| Lane SSOT | `lib/mix/tasks/test.adoption.ex` | Includes `host_app_consumer_proof_test.exs` in `@adoption_test_files` |
| CI order | `.github/workflows/ci-verify.yml` | `release_preview` (L105–106) → `test.adoption` (L118–119); **no** `SCORIA_HEX_UNPACK_ROOT` yet |
| Overlay sources | `priv/host_app_proof/overlay/test/` | `host_route_smoke_test.exs`, `host_runtime_smoke_test.exs`, `host_handoff_smoke_test.exs` |

### Gaps

1. No `Scoria.HexConsumerContract` — version/dep snippets duplicated in README test and `package_surface_test`.
2. No tarball dep path — adoption still proves monorepo tree via `path: File.cwd!()`.
3. No unpack cache — every `package_surface_test` hex preview spawns `hex.build`; CI would double-build without env reuse.
4. `run_route_proof!/1` does not filter overlays — Phase 78 green bar cannot be route-only.
5. `create_host!/1` has no `dep_mode` — silent repo-root default violates D-25–D-27.
6. CI does not pass unpack root from release preview to test job.

### Explicit non-goals (locked)

- Live `{:scoria, "~> 0.1", hex: :scoria}` in generated host or PR CI (Phase 81).
- `path:` to `.tar` or `MIX_EX_PATH` overrides (D-08).
- README/operator/adoption_lanes prose sweep or `ci_policy_contract_test` topology pins (Phase 82).
- Widening `VerificationLanes.closeout_order/0` (stays `[:release_preview, :adoption, :runtime_to_handoff]`).
- Routing `HostInstallFixtures` through `Generator` (stays repo `path:` for installer truth, D-28).

---

## 1. HexConsumerContract Module Design

### Placement and visibility (D-01, D-05)

- **File:** `lib/scoria/hex_consumer_contract.ex`
- **Class:** Public, non-runtime SSOT — same as `AdopterDocContract`; **not** `test/support`.
- **Shipped:** Lives under `lib/` included in `mix.exs` `package[:files]` — tarball consumers get the contract module.
- **Separate from** `AdopterDocContract` — Hex mechanics vs capability prose; Phase 82 may add doc delegates.

### Version policy (D-02)

| Source | Rule |
|--------|------|
| Human-edited | `mix.exs` `@version` only (currently `"0.1.0"`, `mix.exs:4`) |
| `published_version/0` | `Application.spec(:scoria, :vsn) |> to_string()` |
| `@hex_requirement` | Explicit module attribute `"~> 0.1"` — **not** auto-derived from patch |
| `baseline_upgrade_version/0` | `"0.1.0"` — hook for Phase 80 committed fixture (`test/fixtures/hex_consumer/scoria-0.1.0-unpack/`, D-14) |

### Core API (D-03)

```elixir
defmodule Scoria.HexConsumerContract do
  @app :scoria
  @hex_requirement "~> 0.1"
  @baseline_upgrade_version "0.1.0"
  @github_repo "szTheory/scoria"

  def app, do: @app
  def hex_requirement, do: @hex_requirement
  def published_version, do: ...
  def baseline_upgrade_version, do: @baseline_upgrade_version

  # Adopter-facing (README, drift tests)
  def hex_dep_tuple, do: {@app, @hex_requirement, hex: @app}
  def hex_dep_snippet, do: "{:scoria, \"~> 0.1\", hex: :scoria}"

  def github_fallback_tuple(version), do: {@app, github: @github_repo, tag: "v#{version}"}
  def github_fallback_snippet(version), do: ...

  # CI tarball consumer (generated host mix.exs)
  def tarball_dep_tuple(unpack_root), do: {@app, path: unpack_root}
  def tarball_dep_snippet(unpack_root), do: "{:scoria, path: #{inspect(unpack_root)}}"

  def ensure_current_unpack_root!, do: ...
  def package_fingerprint, do: ...  # optional export for tests/debug
end
```

**Two-surface SSOT:** adopter Hex snippet vs CI tarball path tuple — explicit functions, no conflation (D-06, D-07).

**Snippet formatting:** Match README exactly (`README.md:57`) — active dep line must equal `hex_dep_snippet/0` byte-for-byte (D-04). GitHub fallback is commented in README (`:58`); `github_fallback_snippet(published_version())` guards the tag form.

### Guard tests (D-04, D-22)

New file: `test/scoria/hex_consumer_contract_test.exs`

| Assertion | Source |
|-----------|--------|
| `published_version/0 == Mix.Project.config()[:version]` | mix.exs ↔ Application spec |
| README single active `{:scoria,` line == `hex_dep_snippet/0` | Replaces hardcoded string in `package_surface_test` `:47–66` |
| `hex_dep_tuple/0` third element `hex: :scoria` | Registry shape guard |
| `tarball_dep_tuple/1` never includes `:hex` key | CI vs adopter separation |

Refactor `package_surface_test` “Hex-primary install” to import contract instead of literal `"{:scoria, \"~> 0.1\", hex: :scoria}"`.

---

## 2. `ensure_current_unpack_root!/0` — Caching & Fingerprint

### Three-layer cache (D-10–D-13)

```
Layer 1: SCORIA_HEX_UNPACK_ROOT env (CI — reuse release preview)
Layer 2: Fingerprint cache tmp/scoria-hex-consumer/<version>-<fingerprint>/
Layer 3: setup_all in host_app_consumer_proof_test (one call per module)
```

### Resolution algorithm (recommended)

1. **Env short-circuit:** If `System.get_env("SCORIA_HEX_UNPACK_ROOT")` is set, validate `mix.exs` exists (reuse `ReleasePreview`-style `unpack_root!/1` logic), return absolute path. CI sets `tmp/scoria-release-preview` after `mix scoria.release_preview` (D-12).
2. **Cache hit:** Compute `package_fingerprint/0`. If `tmp/scoria-hex-consumer/<version>-<fp>/` exists **and** contains stamp file matching fingerprint **and** valid unpack root → return path.
3. **Cache miss:** Acquire exclusive lock (`tmp/scoria-hex-consumer/.build.lock`), double-check cache, run `mix hex.build --unpack --output <cache_dir>`, write stamp, release lock, return unpack root.
4. **Never** `File.rm_rf!` shared cache dir in test `on_exit` (D-10).

### Fingerprint strategy (planner discretion — recommend content-aware)

Locked inputs: `package[:files]` from `Mix.Project.config()` + `published_version/0`.

| Approach | Pros | Cons |
|----------|------|------|
| **Hash sorted `:files` list only** | Fast, stable | **Stale artifact** if file contents change without version bump |
| **Hash list + mtimes of listed paths** | Catches edits without version bump | CI checkout timestamps can vary |
| **Hash list + SHA256 of file contents** | Correct for local/CI parity | Slower on first build |

**Recommendation:** Content hash of all paths in `package[:files]` plus version (truncate to 12–16 hex chars for dir name). Document pitfall if planner chooses list-only hash.

Reuse unpack-root discovery from `Mix.Tasks.Scoria.ReleasePreview.unpack_root!/1` — consider extracting shared helper to avoid drift (e.g. `Scoria.HexConsumerContract.unpack_root!/1` called by both modules).

### Locking

No `:file.lock` precedent in repo. Standard Erlang pattern:

```elixir
File.mkdir_p!(cache_parent)
File.open!(lock_path, [:write], fn fd ->
  :ok = :file.lock(fd, :exclusive)
  try do
    # double-check + hex.build
  after
    :file.unlock(fd)
  end
end)
```

Parallel test modules or CI jobs contending on first build — exclusive lock prevents corrupt partial unpack dirs.

### Reject compile-time `@unpack_root` (D-15)

Module attributes captured at compile time → stale unpack under incremental compile. Always resolve at runtime via `ensure_current_unpack_root!/0`.

---

## 3. HostAppProof.Generator `dep_mode` (D-25–D-29)

### Required keyword — no default

```elixir
def create_host!(opts) do
  dep_mode = Keyword.fetch!(opts, :dep_mode)  # :hex_tarball | :path
  unpack_root = Keyword.get(opts, :unpack_root)
  ...
  patch_mix_exs!(host_root, dep_mode: dep_mode, unpack_root: unpack_root, repo_root: repo_root)
end
```

Raise with allowed atoms if invalid. **Prefer required from start** (D-25); only caller today is `host_app_consumer_proof_test.exs`.

### `:hex_tarball`

- Requires `unpack_root:` (from `setup_all` / `ensure_current_unpack_root!/0`).
- Injects `HexConsumerContract.tarball_dep_tuple(unpack_root)` into `deps do` block via existing regex anchor (`generator.ex:72`).
- Generated line: `{:scoria, path: "/abs/path/to/unpack"}` — unpack dir contains packaged `mix.exs`, not monorepo root (D-06).

### `:path`

- Explicit maintainer debug only: `{:scoria, path: repo_root}` (current behavior).
- **Never** used in adoption tests (D-27).

### Unchanged

- `HostInstallFixtures` (`test/support/scoria/host_install_fixtures.ex`) — repo-local installer truth, D-28.
- `copy_overlay!` still copies all three overlay files; route filtering happens in **Runner**, not Generator (Phase 79 switches runner, not overlay copy).

### Phase 80 hook

Same `create_host!` with `dep_mode: :hex_tarball, unpack_root: fixture_path` where fixture is committed `0.1.0` unpack — no second `phx.new` (D-29).

---

## 4. `Runner.run_route_proof!/1` — Route-Only Filter (D-16, D-17)

### Current behavior

`smoke_pair!/1` runs **all** `host.overlay_tests`:

```elixir
test_args = ["test"] ++ Enum.map(host.overlay_tests, &("test/" <> &1)) ++ ["--trace"]
```

Overlay order from `Generator.overlay_test_files/0`: sorted basenames → `host_handoff_smoke_test.exs`, `host_route_smoke_test.exs`, `host_runtime_smoke_test.exs`.

Step atoms derive from filename root: `:host_handoff_smoke_test`, etc. (`runner.ex:15–17`).

### Recommended filter (D-17 discretion)

Add module attribute or constant:

```elixir
@route_overlay_test "host_route_smoke_test.exs"
```

Refactor `smoke_pair!/2`:

```elixir
def smoke_pair!(host, overlay_files \\ host.overlay_tests)
def run_route_proof!(host) do
  run_steps(host, [..., fn h -> smoke_pair!(h, [@route_overlay_test]) end])
end
def run_full_proof!(host) do
  run_steps(host, [..., &smoke_pair!/1])  # all overlays — Phase 79 consumer test
end
```

### Phase 78 expected steps

```elixir
assert proof.steps == [
  :deps_get,
  :scoria_install,
  :ecto_create,
  :ecto_migrate,
  :host_route_smoke_test
]
```

**Not** `:host_runtime_smoke_test` or `:host_handoff_smoke_test` — deferred to Phase 79 (D-19).

Preserve `@moduletag timeout: 180_000`, `async: false`, one host per run (D-20).

---

## 5. `host_app_consumer_proof_test.exs` Changes (D-11, D-18)

### Structure

```elixir
setup_all do
  {:ok, unpack_root: Scoria.HexConsumerContract.ensure_current_unpack_root!()}
end

test "generated Phoenix host proves tarball adoption path", %{unpack_root: unpack_root} do
  host = Generator.create_host!(
    dep_mode: :hex_tarball,
    unpack_root: unpack_root,
    cleanup: &on_exit/1
  )

  mix_exs = File.read!(Path.join(host.root, "mix.exs"))

  refute mix_exs =~ "{:scoria, path: #{inspect(host.repo_root)}}"
  assert mix_exs =~ Scoria.HexConsumerContract.tarball_dep_snippet(unpack_root)
  # optional: assert String.starts_with?(unpack_root, Path.expand("tmp/scoria-hex-consumer"))

  proof = Runner.run_route_proof!(host)
  assert proof.steps == [...route only...]
end
```

Flip assertion polarity from current `assert mix_exs =~ "{:scoria, path: "` (`:13`).

---

## 6. CI Wiring — `SCORIA_HEX_UNPACK_ROOT` (D-12)

### Change location

`.github/workflows/ci-verify.yml` — `test` job, after release preview step.

### Recommended shape

Either job-level env (after step 105) or step-scoped env on subsequent steps:

```yaml
- name: Run release preview lane
  run: MIX_ENV=dev mix scoria.release_preview

# Subsequent steps inherit:
env:
  SCORIA_HEX_UNPACK_ROOT: tmp/scoria-release-preview
```

Or append to existing job `env:` block at L75–81 — valid because release preview always runs first in that job.

### Effect

- `ensure_current_unpack_root!/0` skips redundant `hex.build` during `mix test.adoption` and full `mix test`.
- Aligns with `Mix.Tasks.Scoria.ReleasePreview.release_preview_output_dir/0` → `"tmp/scoria-release-preview"`.
- **Do not** change `ci_policy_contract_test.exs` in Phase 78 (D-23) — topology pin deferred to Phase 82.

### Local maintainer flow

Without env: lazy cache build on first `ensure_current_unpack_root!/0`.  
With prior `mix scoria.release_preview`: can set `SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview` manually for parity.

Optional future: `SCORIA_ARTIFACT_PATH` — defer unless trivial (D-29 discretion).

---

## 7. `package_surface_test` Refactor (D-13)

| Test | Change |
|------|--------|
| `"Hex-primary install with optional GitHub fallback"` | Use `HexConsumerContract.hex_dep_snippet/0`, `github_fallback_snippet(published_version())` |
| `"hex preview includes the required release surface"` | Replace unique tmp + inline `hex.build` with `ensure_current_unpack_root!/0`; drop per-test `on_exit` rm of shared cache |
| `"project metadata..."` | Optional: assert `Mix.Project.config()[:version] == HexConsumerContract.published_version()` |

Keep `@required_package_paths` local or delegate subset to `ReleasePreview.required_package_paths/0` — note `package_surface_test` includes `support_copilot_gallery.md` while release preview test list does not (intentional broader surface test).

---

## 8. Test File Structure & Plan Wave Ordering

### New / modified files

| File | Action |
|------|--------|
| `lib/scoria/hex_consumer_contract.ex` | **Create** — SSOT + cache |
| `test/scoria/hex_consumer_contract_test.exs` | **Create** — unit guards |
| `test/scoria/package_surface_test.exs` | **Modify** — contract + cache |
| `test/support/scoria/host_app_proof/generator.ex` | **Modify** — required `dep_mode` |
| `test/support/scoria/host_app_proof/runner.ex` | **Modify** — route filter |
| `test/scoria/host_app_consumer_proof_test.exs` | **Modify** — tarball proof |
| `.github/workflows/ci-verify.yml` | **Modify** — env var |

**Untouched:** `lib/mix/tasks/test.adoption.ex` file list, `HostInstallFixtures`, `adoption_surface_test.exs`, `ci_policy_contract_test.exs`, `VerificationLanes`.

### Recommended three-plan waves

| Plan | Wave | Scope | Depends on |
|------|------|-------|------------|
| **78-01** | 1 | `HexConsumerContract` API (without cache or with stub), `hex_consumer_contract_test.exs`, refactor README dep assertions in `package_surface_test` | — |
| **78-02** | 2 | `ensure_current_unpack_root!/0`, fingerprint + lock, `package_surface_test` hex preview via cache | 78-01 |
| **78-03** | 3 | Generator `dep_mode`, Runner route filter, consumer test `setup_all`, CI `SCORIA_HEX_UNPACK_ROOT` | 78-02 |

**Gate after each wave:** targeted `mix test` files below; final gate `mix test.adoption`.

Alternative: merge 78-01+78-02 if contract without cache is too incomplete to test — planner may combine if single PR preferred.

---

## 9. Risks & Pitfalls

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Stale unpack cache** | Tests pass against old packaged files | Content-aware `package_fingerprint/0`; stamp file invalidation |
| **Lock contention / deadlock** | Parallel modules hang on first build | Short critical section; double-check after lock; unlock in `after` |
| **Repo-root `path:` regression** | Adoption proves monorepo, not tarball | Consumer test refutes `host.repo_root`; required `:hex_tarball` |
| **`create_host!` breaking change** | Compile error if dep_mode omitted | Single caller — update in same plan as Generator |
| **Double `hex.build` in CI** | Slow/flaky adoption lane | `SCORIA_HEX_UNPACK_ROOT` after release preview |
| **Nested unpack layout drift** | `hex.build --unpack` puts mix.exs in subdir | Share `unpack_root!/1` with `ReleasePreview` |
| **Route-only vs full overlay confusion** | Phase 78 claims complete HEX-CONSUMER-01 | Mark partial in requirements; Phase 79 switches to `run_full_proof!/1` |
| **Accidental `:path` default** | Silent repo-root proof | `Keyword.fetch!/2` on `dep_mode` — no default (D-25) |
| **Shared cache deleted in on_exit** | Flaky parallel tests | Never rm `tmp/scoria-hex-consumer/` in tests |
| **README guard without contract** | Drift between mix.exs version and snippet | `published_version/0` ↔ `Mix.Project.config()` test |
| **Widening closeout order** | Scope creep | Do not touch `VerificationLanes.closeout_order/0` |

---

## 10. Integration Points (downstream phases)

| Phase | Consumes Phase 78 |
|-------|-------------------|
| **79** | Switch consumer test to `run_full_proof!/1`; full step list; completes HEX-CONSUMER-01 |
| **80** | `baseline_upgrade_version/0`, `dep_mode: :hex_tarball` with committed `0.1.0` fixture |
| **81** | Live `hex: :scoria` in post-publish smoke — separate from tarball tuple |
| **82** | README/operator prose, `adoption_surface_test` / `ci_policy_contract_test` pins |

---

## Validation Architecture

Nyquist mapping: each partial requirement → executable command. Phase 78 does **not** require full `mix test` green as the only gate — **`mix test.adoption`** is the merge-blocking slice.

### Test framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Adoption lane | `mix test.adoption` → `Mix.Tasks.Scoria.Test.Adoption` |
| Consumer proof timeout | `@moduletag timeout: 180_000` on `HostAppConsumerProofTest` |
| Postgres | Required for consumer proof (ecto.create/migrate in generated host) |

### Requirement → test map

| Req ID | Behavior | Test type | Automated command | Exists? |
|--------|----------|-----------|-------------------|---------|
| **DOCS-HEX-01†** | `published_version/0` matches mix.exs | unit | `MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs` | ❌ create |
| **DOCS-HEX-01†** | README active dep line matches `hex_dep_snippet/0` | drift guard | same file + refactored `package_surface_test.exs` | ❌ / ⚠️ partial |
| **DOCS-HEX-01†** | Hex dep tuple shape | unit | `mix test test/scoria/hex_consumer_contract_test.exs` | ❌ |
| **DOCS-HEX-01†** | Unpack includes required package paths | integration | `MIX_ENV=test mix test test/scoria/package_surface_test.exs` | ✅ refactor |
| **HEX-CONSUMER-01†** | Generated host uses tarball path dep, not repo root | integration | `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs` | ✅ modify |
| **HEX-CONSUMER-01†** | deps.get → install → migrate → route smoke | integration | same | ✅ modify |
| **HEX-CONSUMER-01†** | Adoption closeout green | lane | `MIX_ENV=test mix test.adoption` | ✅ |
| **Preserved** | Closeout order unchanged | contract | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs` | ✅ |
| **Preserved** | Release preview discoverability | unit | `MIX_ENV=test mix test test/mix/tasks/scoria.release_preview_test.exs` | ✅ |
| **Preserved** | Adoption file list unchanged | discoverability | `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs` | ✅ |

### Sampling rate

| When | Command |
|------|---------|
| After contract module (78-01) | `mix test test/scoria/hex_consumer_contract_test.exs test/scoria/package_surface_test.exs` |
| After cache (78-02) | `mix test test/scoria/package_surface_test.exs` (hex preview uses cache) |
| After harness (78-03) | `mix test test/scoria/host_app_consumer_proof_test.exs` |
| **Phase gate** | `mix test.adoption` |
| CI parity (maintainer) | `MIX_ENV=dev mix scoria.release_preview && SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview mix test.adoption` |

### Explicitly not Phase 78 gates

- `mix test test/scoria/adoption_surface_test.exs` prose tarball pins — Phase 82
- `mix test test/scoria/ci_policy_contract_test.exs` env topology — Phase 82
- Full overlay steps in consumer proof — Phase 79
- `post-publish-smoke.yml` — Phase 81

### Wave 0 gaps (to create in plans)

- [ ] `lib/scoria/hex_consumer_contract.ex`
- [ ] `test/scoria/hex_consumer_contract_test.exs`
- [ ] `Runner.run_route_proof!/1` real filter (currently identical to full proof)
- [ ] `Generator` required `dep_mode`
- [ ] CI `SCORIA_HEX_UNPACK_ROOT` in `ci-verify.yml`

---

## RESEARCH COMPLETE
