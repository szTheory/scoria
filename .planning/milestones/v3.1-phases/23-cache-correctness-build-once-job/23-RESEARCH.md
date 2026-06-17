# Phase 23: Cache Correctness + Build-Once Job - Research

**Researched:** 2026-06-14
**Domain:** GitHub Actions CI caching, Elixir/Mix incremental compiler, artifact sharing
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** New `build` job lives in the reusable `ci-verify.yml`, not `ci.yml`. Single compile for every consumer.
- **D-02:** Sequence inside `ci-verify.yml`: `policy → build → test`. `build` runs `mix deps.get && mix compile --warnings-as-errors` under `MIX_ENV=test`, then publishes `_build/test` + `deps` via `actions/upload-artifact`.
- **D-03:** `test` (and any other job needing compiled output) `needs: build` and downloads/restores the artifact. Confirm via job logs: no cold-compile step in `test`.
- **D-04:** `build` job uploads the **`MIX_ENV=test` artifact only**. Does NOT build a second dev artifact.
- **D-05:** Dev-env lanes (`e2e` job in `ci.yml`, `MIX_ENV=dev` `mix scoria.release_preview` step in `test`) keep their own dev compile, now warmed by a correctly env-scoped dev cache key (the CACHE-01 fix).
- **D-06:** Switch `setup-beam` in **both** `ci.yml` and `ci-verify.yml` from hardcoded `otp-version: "27"` / `elixir-version: "1.19"` to `version-file: .tool-versions` + `version-type: strict`.
- **D-07:** Cache key recipe: `${{ runner.os }}-otp<OTP>-elixir<ELIXIR>-<MIX_ENV>-mix-${{ hashFiles('**/mix.lock') }}`. `restore-keys` must NOT fall back to a bare `${{ runner.os }}-mix-`.
- **D-08:** `build` keeps `needs: policy`; `test` moves to `needs: build`. The literal `needs: policy` substring survives (contract test).
- **D-09:** `split_jobs/1` splits at `"\n  test:"`. `build` job lands in the policy-side slice with **no `services:` block**.
- **D-10:** Extend contract tests minimally. No pinned command string moves out of byte-order.

### Claude's Discretion

- Exact mechanism for reading `.tool-versions` into a cache-key step output (inline `grep`/`cut`, composite action, or setup-beam outputs).
- Artifact `name`, `retention-days`, and `if-no-files-found` settings, consistent with existing `upload-artifact` usage in the repo.

### Deferred Ideas (OUT OF SCOPE)

- Knowledge lane scoping (Phase 24), lane parallelization/topology docs (Phase 25), partition sharding (Phase 26), flake elimination incl. fixed `55432:5432` Postgres port (Phase 27), `mix ci` alias + velocity closeout (Phase 28).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CACHE-01 | CI cache keys are scoped by OS + OTP + Elixir + `MIX_ENV` + `mix.lock` hash so dev and test `_build` never collide or cause spurious recompiles | D-06 (version-file pattern), D-07 (key recipe), setup-beam `otp-version`/`elixir-version` outputs |
| CACHE-02 | A dedicated `build` job compiles deps + app once (`MIX_ENV=test`, warnings-as-errors) and publishes `_build/test` + `deps` as an artifact that every downstream job restores instead of recompiling | D-01/D-02/D-03, mtime landmine analysis, tar-before-upload pattern |
</phase_requirements>

---

## Summary

Phase 23 wires two orthogonal CI improvements: (1) fixing cache-key scoping so `MIX_ENV=dev` and `MIX_ENV=test` caches never share a key, and (2) adding a dedicated `build` job in `ci-verify.yml` that compiles once and passes the result to downstream jobs via `actions/upload-artifact`. The biggest implementation risk is the **mtime landmine**: artifact upload/download does not reliably preserve file modification times, and Mix's incremental compiler uses mtime as the primary staleness signal — so naive upload/download can re-trigger a full `mix compile`, defeating the entire phase.

The good news: as of Elixir 1.15+, mtime change alone is NOT sufficient to trigger a recompile. The compiler checks `(mtime changed) AND (beam missing OR content digest changed)`. If content and size are unchanged after artifact restore, only a per-file `File.read` + MD5 comparison occurs before Mix concludes nothing needs compiling. However, this still results in "checking" every source file, and one additional trigger — `old_cache_key != new_cache_key` (the OTP/Elixir version cache key stored in the manifest) — can force a full recompile if OTP/Elixir version strings change. The **tar-before-upload** pattern is the safest and most widely recommended workaround: pack `_build` and `deps` into a `.tar.gz` before upload, extract after download. This preserves exact mtimes, so Mix sees unchanged mtimes in the manifest and skips all staleness checks entirely.

**Primary recommendation:** tar `_build/test` + `deps` into a single tarball before `actions/upload-artifact`, extract after `actions/download-artifact`. Verify zero recompile in CI by grepping job logs for the absence of `Compiling N files`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| BEAM compilation (MIX_ENV=test) | CI job (`build`) | — | Single compile, all downstream jobs consume the artifact |
| Build artifact sharing | GitHub Actions artifact store | — | `upload-artifact` / `download-artifact` within the reusable workflow |
| Cache key scoping (CACHE-01) | CI workflow config (`ci.yml`, `ci-verify.yml`) | — | Key must embed OTP+Elixir+MIX_ENV before `mix.lock` hash |
| Version source of truth | `.tool-versions` | `setup-beam` outputs | setup-beam reads `.tool-versions`; its outputs feed the cache key |
| Dev compile (e2e, release_preview) | CI job (`e2e` in `ci.yml`, dev step in `test`) | `actions/cache` | Dev compile is cheap; no second artifact needed (D-04/D-05) |
| Contract-test assertions | `test/scoria/ci_policy_contract_test.exs`, `verification_lanes_test.exs` | `lib/scoria/verification_lanes.ex` | Byte-order assertions must stay green |
| mtime preservation on artifact restore | Tar wrapper step (shell) | — | `actions/upload-artifact` does NOT preserve mtimes; tar does |

---

## Standard Stack

### Core — CI Infrastructure (no new Elixir dependencies)

This phase is **entirely GitHub Actions YAML + ExUnit test additions**. There are no new Elixir/Hex packages to install. The relevant action versions are already pinned in the repo:

| Action | Version | Purpose | Source in Repo |
|--------|---------|---------|----------------|
| `actions/upload-artifact` | `v7` | Upload compiled artifact tarball | `ci.yml:131`, `ci-verify.yml:124` |
| `actions/download-artifact` | `v7` | Restore artifact in downstream jobs | Repo uses v7 for upload; must match |
| `actions/cache` | `v5` | Warm deps/`_build` per env | `ci.yml:73,86`, `ci-verify.yml:29,94` |
| `erlef/setup-beam` | `v1` | Install OTP + Elixir; expose version outputs | `ci-verify.yml:22`, `ci.yml:62` |

[VERIFIED: repo grep] `actions/upload-artifact@v7` and `actions/cache@v5` are the pinned versions in `.github/workflows/ci.yml` and `ci-verify.yml`.

### Version Source Pattern — already established in 3 workflows

```yaml
# Pattern from release-please.yml, hex-publish.yml, post-publish-smoke.yml
- uses: erlef/setup-beam@v1
  with:
    version-file: .tool-versions
    version-type: strict
```

[VERIFIED: repo read] This exact pattern appears in `release-please.yml:220`, `hex-publish.yml:137`, `post-publish-smoke.yml:83`.

### Package Legitimacy Audit

> No new Elixir packages. No new npm packages. No new external actions beyond `actions/download-artifact@v7` which is the first-party GitHub action paired with the already-pinned `upload-artifact@v7`.

| Package/Action | Registry | Age | slopcheck | Disposition |
|----------------|----------|-----|-----------|-------------|
| `actions/download-artifact@v7` | GitHub Actions | Maintained by GitHub | N/A (first-party) | Approved |

**Packages removed due to slopcheck:** none
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
ci.yml (push/PR/dispatch trigger)
  │
  ├─► verify job ──► calls ci-verify.yml (workflow_call)
  │                     │
  │                     ├─► policy job (setup-beam + cache restore + compile WAE + lane contract tests)
  │                     │        │
  │                     │   needs: policy
  │                     │        │
  │                     ├─► build job (MIX_ENV=test)
  │                     │       ├── setup-beam (version-file: .tool-versions)
  │                     │       ├── id: beam → outputs otp-version, elixir-version
  │                     │       ├── cache restore (env-scoped key)
  │                     │       ├── mix deps.get && mix compile --warnings-as-errors
  │                     │       ├── tar czf build-artifact.tar.gz _build/test deps
  │                     │       └── upload-artifact@v7 (build-artifact.tar.gz)
  │                     │              │
  │                     │         needs: build
  │                     │              │
  │                     └─► test job (MIX_ENV=test, services: postgres)
  │                             ├── setup-beam (version-file: .tool-versions)
  │                             ├── download-artifact@v7
  │                             ├── tar xzf build-artifact.tar.gz
  │                             ├── mix deps.get  (no compile — artifact already compiled)
  │                             └── [all lane steps: release_preview, adoption, ...]
  │
  ├─► e2e job (MIX_ENV=dev, own dev compile, env-scoped dev cache key)
  └─► ci-gate fan-in
```

### Recommended Project Structure Changes

```
.github/workflows/
├── ci.yml               # MODIFY: setup-beam → version-file; fix e2e cache key (CACHE-01)
└── ci-verify.yml        # MODIFY: add build job; update test job; fix policy cache key
test/scoria/
└── ci_policy_contract_test.exs   # MODIFY: extend assertions for build job
```

No new files beyond the RESEARCH.md; all changes are modifications to existing files.

---

## The Mtime Landmine — Complete Analysis

### Root cause

`actions/upload-artifact` packs files into a zip archive. Zip's timestamp format (MS-DOS time) has 2-second resolution and does NOT reliably preserve the original file mtime. On download, files get timestamps reflecting the download time or the zip entry time — neither matches the mtime recorded by Mix in the manifest when the `build` job compiled.

[CITED: github.com/actions/upload-artifact/issues/384] — multiple user reports confirming mtime loss; open since 2023.

### Mix staleness detection algorithm (Elixir 1.19.5)

[VERIFIED: elixir-lang/elixir blob main lib/mix/lib/mix/compilers/elixir.ex lines 444-457]

A source file triggers recompile if ANY of:
1. `size != last_size` (file size changed)
2. `has_any_key?(stale_modules, modules)` (a module it depends on is stale)
3. `last_mtime != mtime AND (missing_beam_file? OR digest_changed?)`

Critically:
- mtime change alone does NOT trigger a recompile if size is the same
- When mtime changes but size is equal, Mix reads the file and computes an MD5 digest; if the digest matches the manifest, no compile occurs
- However, this still causes a `File.read` + MD5 for every source file with a mismatched mtime — this is non-zero I/O on every downstream job

Additionally, at the top level (lines 103-105):
```
!!opts[:force] or is_nil(old_deps_config) or old_cache_key != new_cache_key or
    (Keyword.get(opts, :check_cwd, true) and old_cwd != File.cwd!()) ->
  {true, stale, deps_config(local_deps, opts)}
```
- `old_cache_key != new_cache_key`: this is the OTP/Elixir version composite key stored IN THE MANIFEST. If the OTP/Elixir version strings differ between the `build` job and the `test` job (impossible with `version-file:` but previously possible with hardcoded versions), this forces a full recompile.
- `old_cwd != File.cwd!()`: the working directory must be the same between build and test jobs. On standard `ubuntu-latest` GitHub runners this is always `/home/runner/work/scoria/scoria` — stable.

### Why tar-before-upload is the correct solution

`tar` (GNU tar on Ubuntu, as used by GitHub Actions runners) preserves file mtimes in the archive header and restores them exactly on extraction by default. This means:

**Upload step (build job):**
```bash
tar -czf build-artifact.tar.gz _build/test deps
```

**Download + extract (test job):**
```bash
# After download-artifact restores build-artifact.tar.gz:
tar -xzf build-artifact.tar.gz
```

After extraction, `_build/test` and `deps` have the exact same mtimes as when the `build` job wrote them. Mix sees `last_mtime == mtime` for every source, skips all digest checks, and outputs `mix compile` with no `Compiling N files` line.

### Options comparison

| Mechanism | Preserves mtimes? | Complexity | Risk |
|-----------|-------------------|------------|------|
| **tar before upload / tar after download** | Yes (exact) | Low (2 shell steps) | Near zero — standard pattern [CITED: docs.github.com/en/actions/guides/storing-workflow-data-as-artifacts] |
| `touch`-normalize after download | Partial — requires correct ordering: source files must be OLDER than manifests which must be OLDER than `.beam` files; a single ordering mistake causes spurious recompile | Medium (error-prone) | High — easy to get ordering wrong |
| Skip artifact; use `actions/cache` only | `actions/cache` uses tar+zstd internally; preserves mtimes by default | Medium (different semantics: cache may miss on first run) | Low if key is stable — but D-02/D-03 specify upload-artifact |
| Naive upload/download (no tar) | No | Lowest | HIGH — artifact zip strips mtimes; every source file gets digest-checked; any size mismatch causes recompile |

**Recommendation:** tar-before-upload. This is the canonical workaround documented by GitHub for metadata preservation and is used in ecosystem projects (e.g., CMake, Docker layer caching use the same pattern). [CITED: GitHub community discussions #42615, upload-artifact/issues/384]

### The touch-normalize pitfall (do not use)

If tar is for some reason impossible, touch-normalization requires:
1. Touch all source `.ex` files to timestamp T-2
2. Touch `deps/**` to timestamp T-1
3. Touch `_build/test/**/*.beam` and `.mix/compile.*` manifest files to timestamp T

Getting this wrong in either direction causes: (a) source newer than manifest → recompile; (b) manifest newer than `.beam` → recompile. Two shell steps with correct ordering is brittle. Tar eliminates this entirely.

---

## Reading `.tool-versions` Into Cache Key Steps

### Recommended: use `setup-beam` step outputs directly

`erlef/setup-beam@v1` exposes outputs `otp-version` and `elixir-version` when given an `id:`.

[VERIFIED: erlef/setup-beam README] Output format:
- `otp-version`: e.g. `OTP-27.3.2` (the full OTP string)
- `elixir-version`: e.g. `v1.19.5-otp-27` (includes OTP ref)

Usage pattern:
```yaml
- name: Install Erlang and Elixir
  id: beam
  uses: erlef/setup-beam@v1
  with:
    version-file: .tool-versions
    version-type: strict

- name: Restore deps + build cache
  uses: actions/cache@v5
  with:
    path: |
      deps
      _build
    key: ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ env.MIX_ENV }}-mix-${{ hashFiles('**/mix.lock') }}
    restore-keys: |
      ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ env.MIX_ENV }}-mix-
```

This yields a key like:
`Linux-OTP-27.3.2-v1.19.5-otp-27-test-mix-<hash>`

This satisfies D-07's requirement (os + OTP + Elixir + MIX_ENV + mix.lock hash) and ensures dev/test never collide.

**Why this over inline grep/cut:** `setup-beam` outputs use the exact installed version strings (useful if `version-type: strict` resolves to a minor patch), require no shell parsing, and are already the pattern used by community composite actions (e.g., `felt/ultimate-elixir-ci`). [VERIFIED: felt/ultimate-elixir-ci .github/actions/elixir-setup/action.yml]

**Why NOT inline grep/cut:**
```bash
# Fragile alternative — avoid
OTP=$(grep "^erlang" .tool-versions | cut -d' ' -f2)
ELIXIR=$(grep "^elixir" .tool-versions | cut -d' ' -f2)
echo "otp=$OTP" >> $GITHUB_OUTPUT
```
This reads the raw asdf version string (`27.3.2`, `1.19.5-otp-27`), not the installed OTP string. Minor version resolution differences could make the key diverge from what's actually installed if setup-beam ever adjusts a micro version.

**The `restore-keys` constraint (D-07):** Must include os+otp+elixir+env prefix. Never use a bare `${{ runner.os }}-mix-` fallback — that would allow a dev-env cached `_build` to be restored into a test-env job, corrupting beam files.

---

## Job Topology Inside a Reusable workflow_call

### How artifacts pass between jobs in the same reusable workflow

Within a single `workflow_call` workflow, `actions/upload-artifact` and `actions/download-artifact` share artifact names within the same workflow run. The artifact uploaded by the `build` job is available to the `test` job using the same `name:` because they run under the same `GITHUB_RUN_ID`.

[CITED: docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts]

```yaml
# build job
- uses: actions/upload-artifact@v7
  with:
    name: build-test-env     # shared within this workflow_call run
    path: build-artifact.tar.gz
    retention-days: 1
    if-no-files-found: error

# test job (needs: build)
- uses: actions/download-artifact@v7
  with:
    name: build-test-env
    path: .   # downloads to workspace root
```

### `needs:` semantics

```yaml
jobs:
  policy:
    ...
  build:
    needs: policy     # runs after policy succeeds; literal "needs: policy" preserved (D-08)
    ...
  test:
    needs: build      # runs after build succeeds; "needs: policy" no longer here
    ...
```

`test` job no longer has `needs: policy` directly — it has `needs: build`. The contract test assertion `assert ci_verify =~ "needs: policy"` still passes because `build` has `needs: policy`.

### Does `e2e` need changes?

Per D-04/D-05: `e2e` (in `ci.yml`, `MIX_ENV=dev`) does NOT download the test artifact. Its only change is fixing the cache key from `${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}` to the env-scoped key (CACHE-01). No topology change to `ci.yml`'s job graph.

---

## Contract-Test Impact Analysis

### Current assertions that MUST remain green

**`ci_policy_contract_test.exs`** (read in full — [VERIFIED: repo read]):

| Test | Current assertion | Impact of build job |
|------|-------------------|---------------------|
| `"ci-verify.yml is reusable workflow_call SSOT"` | asserts `"needs: policy"` (note: is file-level assert, not split-based) | `build` has `needs: policy` — still present in file ✓ |
| `"test job depends on policy and preserves closeout chain order"` | `assert ci_verify =~ "needs: policy"` — substring match on whole file | `build` job contains `needs: policy` — still passes ✓ |
| `"postgres service is configured only for the test job"` | `split_jobs/1` at `"\n  test:"` → `refute policy_section =~ "services:"` | `build` job lands in policy-side slice; it must have NO `services:` block (D-09) ✓ |
| `"policy job runs warning baseline..."` | `[policy_section, _test_section] = split_jobs(ci_verify)` | The `build` job appears in `policy_section` (before `\n  test:`); this is FINE — `split_jobs` just needs the test job to start at `"\n  test:"` |
| `"policy job does not run warning_ratchet.test"` | `refute policy_section =~ "scoria.warning_ratchet"` | `build` job must not run ratchet — trivially satisfied |
| `"ci-verify.yml documents per-job intent comments..."` | `assert policy_section =~ "# policy:"` and `assert ci_verify =~ "# test:"` | A new `# build:` comment is acceptable; existing comments must stay ✓ |
| `"policy job runs ci_policy_contract_test in lane-contract step"` | Regex finds the lane-contract step in `policy_section` | Must still be in policy job, not build job ✓ |

**`verification_lanes_test.exs`** (read in full — [VERIFIED: repo read]):

| Test | Current assertion | Impact |
|------|-------------------|--------|
| `"ci lane ordering follows the canonical closeout chain"` | Asserts `release_preview < adoption < runtime_to_handoff < semantic < mix test --WAE < knowledge < connector < gallery` byte-order positions in `ci_verify` | These all live in the `test` job; build job is above `\n  test:` and does not contain any lane commands — no impact ✓ |
| `"lane contract defines command, env, prerequisites..."` | Asserts lane IDs, command strings — reads `VerificationLanes`, not the YAML | No impact ✓ |
| All lane ordering tests | All operate on lane command strings in the `test` job | Not touched ✓ |

### split_jobs/1 constraint — critical detail

```elixir
defp split_jobs(content) do
  case :binary.match(content, "\n  test:") do
    {index, _length} ->
      [String.slice(content, 0, index), String.slice(content, index, byte_size(content))]
    :nomatch ->
      flunk("expected policy and test jobs in ci-verify.yml")
  end
end
```

The split is on the **literal byte sequence** `"\n  test:"`. The `build` job YAML must be placed so that its job key (`  build:`) appears **before** `  test:` in the file. Because D-02 defines `policy → build → test` sequence, the YAML order is:
1. `  policy:` block
2. `  build:` block (starts after `policy` block ends)
3. `  test:` block (starts at `"\n  test:"` — the split point)

This means `build` lands entirely in `policy_section` from `split_jobs`. That is correct and satisfies D-09.

### Minimal new assertions to add (D-10)

New test function(s) in `ci_policy_contract_test.exs`:

```elixir
test "build job exists, needs policy, and has no services block" do
  ci_verify = File.read!(@ci_verify)
  [policy_section, _test_section] = split_jobs(ci_verify)

  # build job is present in the policy-side slice
  assert policy_section =~ "\n  build:"
  # build job depends on policy (not test)
  assert policy_section =~ "needs: policy"
  # build job has no postgres service (D-09 hard constraint)
  # (policy_section already asserted by existing test; confirm build specifically)
  refute policy_section =~ "services:"
end

test "build job uploads artifact and test job downloads it" do
  ci_verify = File.read!(@ci_verify)

  # Upload in the policy-side, download in the test-side
  [policy_section, test_section] = split_jobs(ci_verify)

  assert policy_section =~ "upload-artifact"
  assert test_section =~ "download-artifact"
end

test "test job needs build, not policy directly" do
  ci_verify = File.read!(@ci_verify)
  [_policy_section, test_section] = split_jobs(ci_verify)

  assert test_section =~ "needs: build"
  refute test_section =~ "needs: policy"
end
```

**What must NOT change:** `VerificationLanes` command strings, `closeout_order/0`, `ids/0` — these are byte-frozen (D-10). No existing test function body may be modified.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| mtime preservation on artifact transfer | Custom timestamp-fixup scripts, `touch` ordering | `tar czf` before upload, `tar xzf` after download | tar preserves mtime in archive headers; ordering is automatic; no edge cases |
| Version extraction from `.tool-versions` | `grep`/`cut` shell pipeline, custom action | `setup-beam@v1` step outputs (`steps.beam.outputs.otp-version`) | setup-beam already resolves the exact installed version; outputs are verified to be the string that matters for cache key uniqueness |
| Cache key uniqueness across OTP/Elixir versions | Manual version strings in workflow YAML | `version-file: .tool-versions` + `version-type: strict` | Already used in 3 existing workflows; single source of truth; eliminates drift |
| Sharing compiled beam between jobs | Custom rsync, NFS mount, git stash | `actions/upload-artifact@v7` / `actions/download-artifact@v7` | Official GitHub Actions mechanism, already pinned in the repo |

---

## Common Pitfalls

### Pitfall 1: Naive artifact upload (no tar) causes spurious full recompile

**What goes wrong:** Upload `_build/test` + `deps` directly to `actions/upload-artifact`. Zip strips mtimes. On `test` job, Mix sees all source file mtimes have changed (zip's extraction time). Mix reads every `.ex` file to compute MD5. If any size differs even by a byte (e.g., line endings), it recompiles that module and its transitive dependents. Result: `Compiling 42 files (.ex)` in the test job — exactly what this phase prevents.

**Why it happens:** `actions/upload-artifact`'s zip format does not preserve POSIX mtime. This is a documented known limitation with open issues since 2023.

**How to avoid:** `tar czf build-artifact.tar.gz _build/test deps` before upload; `tar xzf build-artifact.tar.gz` after download. Tar's ustar/POSIX format stores mtime in the header; GNU tar on Ubuntu restores it exactly.

**Warning signs:** Job log shows `Compiling N files (.ex)` in the `test` job step that should not compile. Success Criterion #3 fails.

### Pitfall 2: Cache key too broad (`${{ runner.os }}-mix-`) — already present in repo

**What goes wrong:** The current `ci.yml` and `ci-verify.yml` use `${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}` with restore-key `${{ runner.os }}-mix-`. A dev-env `_build` restored into a test-env job produces compiled BEAM files with wrong Mix env baked in — `Application.get_env` values, config resolution, and compiled protocol consolidation paths all differ.

**Why it happens:** Restore-key `${{ runner.os }}-mix-` matches ANY earlier cache with that prefix, regardless of env.

**How to avoid:** D-07 specifies the narrowed restore-key: `${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ env.MIX_ENV }}-mix-`. This includes MIX_ENV before the mix.lock hash.

**Warning signs:** `test` job fails with errors like `function not exported`, `no module` — a symptom of dev-compiled protocols being loaded in test env.

### Pitfall 3: `build` job's `split_jobs/1` placement

**What goes wrong:** The `build` YAML block is placed AFTER the `test` block in `ci-verify.yml`. `split_jobs/1` splits at `"\n  test:"` and the `build` job appears in `test_section`. The assertion `refute policy_section =~ "services:"` passes, but new assertions checking for `build` in `policy_section` fail.

**How to avoid:** Ensure YAML job key order is: `policy`, then `build`, then `test`. GitHub Actions does not require job definitions to be in dependency order, but the contract tests enforce byte-position ordering here.

**Warning signs:** `ci_policy_contract_test.exs` failures asserting `policy_section =~ "\n  build:"`.

### Pitfall 4: `old_cache_key != new_cache_key` forces full recompile (Elixir manifest cache key)

**What goes wrong:** Mix stores a cache key in the manifest (`_build/test/lib/scoria/.mix/compile.elixir`) based on Elixir/OTP version, Mix version, and options. If the `build` job runs with setup-beam outputs `OTP-27.3.2` / `v1.19.5-otp-27` and the `test` job restores a cache with different version strings (from a prior `actions/cache` hit with hardcoded `"27"`/`"1.19"` keys), `old_cache_key != new_cache_key` triggers `force? = true` → full recompile. D-06 (switching to `version-file: .tool-versions`) eliminates this drift permanently.

**How to avoid:** Both `build` and `test` must use `version-file: .tool-versions` + `version-type: strict` in the same run, so version strings are always identical within a single workflow run.

### Pitfall 5: `retention-days: 1` vs `7` for the build artifact

**What goes wrong:** The existing `playwright-report` artifact uses `retention-days: 7`. Setting the build artifact too high (e.g., 30 days) unnecessarily consumes artifact storage; too low (1 day) is fine for intra-run sharing since artifacts are available for the duration of the run regardless of retention setting. Retention only affects how long the artifact is browsable after run completion.

**How to avoid:** Use `retention-days: 1` for the build artifact (it has no debugging value after the run). Use `if-no-files-found: error` to fail loudly if the tar or compile step didn't produce output.

### Pitfall 6: `mix deps.get` in `test` job after artifact restore

**What goes wrong:** Removing `mix deps.get` from `test` entirely causes failures if deps directory is incomplete (e.g., cache miss on the artifact). The artifact may not be present if the upload step failed.

**How to avoid:** Keep `mix deps.get` in the `test` job (it's a no-op when `deps/` is complete and `mix.lock` hasn't changed). Add `if-no-files-found: error` to the upload step to fail `build` loudly rather than silently producing an empty artifact.

---

## Code Examples

### Pattern 1: `build` job YAML in `ci-verify.yml`

```yaml
  # build: compile once (MIX_ENV=test, WAE) and share artifact to downstream jobs
  build:
    runs-on: ubuntu-latest
    needs: policy
    env:
      MIX_ENV: test

    steps:
      - uses: actions/checkout@v6

      - name: Install Erlang and Elixir
        id: beam
        uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict

      - name: Restore deps + build cache
        uses: actions/cache@v5
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-test-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-test-mix-

      - name: Install dependencies
        run: mix deps.get

      - name: Compile with warnings as errors
        run: mix compile --warnings-as-errors

      - name: Pack compiled artifact (preserves mtimes)
        run: tar -czf build-test-env.tar.gz _build/test deps

      - name: Upload compiled artifact
        uses: actions/upload-artifact@v7
        with:
          name: build-test-env
          path: build-test-env.tar.gz
          retention-days: 1
          if-no-files-found: error
```

### Pattern 2: `test` job artifact restore (CACHE-02)

Replace the current `test` job's `Restore deps cache` + `Install dependencies` + setup-beam with:

```yaml
  test:
    runs-on: ubuntu-latest
    needs: build      # changed from: needs: policy
    # ... services: postgres, env: MIX_ENV=test (unchanged)

    steps:
      - uses: actions/checkout@v6

      - name: Install Erlang and Elixir
        id: beam
        uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict

      - name: Download compiled artifact
        uses: actions/download-artifact@v7
        with:
          name: build-test-env

      - name: Unpack compiled artifact (restores exact mtimes)
        run: tar -xzf build-test-env.tar.gz

      - name: Install dependencies (no-op when deps/ complete)
        run: mix deps.get

      # All existing steps unchanged from here...
      - name: Run release preview lane
        run: MIX_ENV=dev mix scoria.release_preview
      # ...
```

### Pattern 3: CACHE-01 fix for `policy` job in `ci-verify.yml`

```yaml
      - name: Install Erlang and Elixir
        id: beam
        uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict

      - name: Restore deps cache
        uses: actions/cache@v5
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-test-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-test-mix-
```

### Pattern 4: CACHE-01 fix for `e2e` job in `ci.yml` (dev env)

```yaml
      - name: Install Erlang and Elixir
        id: beam
        uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict

      - name: Restore deps cache
        uses: actions/cache@v5
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-dev-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-dev-mix-
```

Note `dev` in the key — never shares with `test`.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded `otp-version: "27"` / `elixir-version: "1.19"` | `version-file: .tool-versions` + `version-type: strict` | This phase (D-06) | Eliminates drift between CI and `.tool-versions`; kills `OTP-27` vs `27.3.2` key mismatch |
| Single `${{ runner.os }}-mix-<hash>` key for all envs | `os-OTP-ELIXIR-MIX_ENV-mix-<hash>` per-env key | This phase (D-07) | dev/test caches never collide |
| Serial `policy → test` | `policy → build → test` | This phase (D-02) | One compile per run; downstream jobs never cold-compile |
| Naive `_build` cache (restores but may recompile) | tar artifact with preserved mtimes | This phase | Zero downstream recompile when artifact hit; Mix sees unchanged mtimes, skips all staleness checks |

**Deprecated / outdated in this repo after this phase:**
- `otp-version: "27"` / `elixir-version: "1.19"` in `ci.yml` and `ci-verify.yml` — replaced by `version-file:` pattern
- `${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}` cache key — replaced everywhere

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `tar` on `ubuntu-latest` GitHub runners is GNU tar and preserves mtime in the archive | Mtime Landmine | If GH runner uses a different tar that doesn't preserve mtime, downstream jobs still recompile. Mitigation: add `-p` flag or verify with `tar --version` in CI; Ubuntu 22.04/24.04 runners always have GNU tar. |
| A2 | `setup-beam` `otp-version` output for `erlang 27.3.2` will be `OTP-27.3.2` (not `27.3.2`) | Cache Key Pattern | Cache key format would differ from documented example. Impact: key still unique; zero functional risk. |
| A3 | `actions/download-artifact@v7` is the correct counterpart for `upload-artifact@v7` | Standard Stack | v3 and v4/v7 artifact actions are NOT cross-compatible. Using mismatched versions causes download failure. Mitigated by using the same version tag. |

**If this table were empty:** All claims in this research were verified or cited — no user confirmation needed.

---

## Open Questions (RESOLVED)

1. **Does `test` job still need `mix deps.get` after restoring the artifact?**
   - What we know: `deps/` is fully populated in the artifact. `mix deps.get` is a no-op when `mix.lock` has not changed and all deps are present.
   - What's unclear: If the cache within `build` is partial (first run, no cache hit), does `deps/` get fully populated?
   - Recommendation: Keep `mix deps.get` in `test` — it is a safety net and fast (~1s on cache hit). Remove `mix compile` from `test`; keep `mix deps.get`.

2. **Should the `policy` job also use the artifact (no `actions/cache`)?**
   - What we know: `policy` runs `mix compile --warnings-as-errors` (compile WAE check). If it uses the artifact, compile WAE in policy becomes a no-op (artifact already compiled WAE).
   - What's unclear: D-02 doesn't specify whether `policy` uses the artifact.
   - Recommendation: Keep `policy` on `actions/cache` (its compile WAE step is the lint gate; it should run independently to confirm no warning baseline regression). `build` is the compile-once job for test execution, not a replacement for the policy compile check.

3. **`mix archive.install hex phx_new` in `test` — does it need to run after artifact restore?**
   - What we know: This installs a Mix archive (not a dep), so it's NOT in `deps/`. It's idempotent and fast.
   - Recommendation: Keep this step in `test` unchanged; it doesn't affect mtime of anything in `_build` or `deps`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|---------|
| `tar` (GNU) | Mtime preservation pattern | ✓ | GNU tar (ubuntu-latest) | None needed — GNU tar is always present on `ubuntu-latest` |
| `actions/upload-artifact@v7` | CACHE-02 build job | ✓ | Already pinned in repo | — |
| `actions/download-artifact@v7` | CACHE-02 test job | ✓ | Same version family | — |
| `actions/cache@v5` | CACHE-01 cache key fix | ✓ | Already pinned in repo | — |
| `erlef/setup-beam@v1` | D-06 version-file pattern | ✓ | Already in both workflows | — |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** none

---

## Validation Architecture

### Proving Success Criterion #1 (CACHE-01: env-scoped cache keys)

**Test:** Read the YAML of `ci.yml` and `ci-verify.yml` after the change. Assert cache key strings contain `MIX_ENV` (or the literal `test`/`dev`) between the Elixir version segment and the mix.lock hash.

**ExUnit assertion (new in `ci_policy_contract_test.exs`):**
```elixir
test "cache keys include MIX_ENV segment to prevent dev/test collision" do
  ci_verify = File.read!(".github/workflows/ci-verify.yml")
  ci_entry = File.read!(".github/workflows/ci.yml")

  # test-env jobs have 'test' in their cache key
  assert ci_verify =~ ~r/key:.*-test-mix-/
  # dev-env e2e job has 'dev' in its cache key
  assert ci_entry =~ ~r/key:.*-dev-mix-/
  # no bare runner.os-mix- keys remain
  refute ci_verify =~ ~r/key: \$\{\{ runner\.os \}\}-mix-/
  refute ci_entry =~ ~r/key: \$\{\{ runner\.os \}\}-mix-/
end
```

### Proving Success Criterion #2 (CACHE-02: build job exists and compiles once)

**ExUnit assertion (new in `ci_policy_contract_test.exs`):**
```elixir
test "build job exists, needs policy, uploads artifact, has no services block" do
  ci_verify = File.read!(".github/workflows/ci-verify.yml")
  [policy_section, _] = split_jobs(ci_verify)

  assert policy_section =~ "\n  build:"
  assert policy_section =~ "needs: policy"
  assert policy_section =~ "mix compile --warnings-as-errors"
  assert policy_section =~ "upload-artifact"
  refute policy_section =~ "services:"
end
```

### Proving Success Criterion #3 (no downstream recompile) — make-or-break

**Primary proof: CI job log inspection.**

After the phase ships, in the `test` job log, search for `Compiling` in the step after `Unpack compiled artifact`. Expected: **absent**. The `mix deps.get` step should show `Resolving Hex dependencies...` with `ok` and no compilation lines.

**Concrete log patterns to assert against:**
- PASS: `mix deps.get` output ends with `ok` or `All packages have been fetched, nothing to compile.`
- PASS: No `Compiling N files (.ex)` line appears between `Unpack compiled artifact` and `Run release preview lane` steps
- FAIL signal: `Compiling 1 files (.ex)` or `Compiling 47 files (.ex)` in the test job's artifact-restore section

**How to observe in CI:**

```bash
# After a PR run, inspect the test job logs:
gh run view <run-id> --log | grep -A5 "Unpack compiled artifact" | grep -i "compiling"
# Expected: no output (grep finds nothing = zero recompile)
```

**Lightweight pre-ship validation in a test branch:**
1. Push the phase changes to a test branch
2. Let CI run
3. Check `test` job log for `Compiling`:
   ```bash
   gh run view <run-id> --log-failed 2>/dev/null || gh run view <run-id> --log | grep "Compiling"
   ```
4. If `Compiling N files` appears, the tar pattern is not working — debug by adding `ls -la _build/test/lib/` before and after untar to verify mtime is preserved.

**Manual local simulation:**
```bash
# Simulate what the build job does:
MIX_ENV=test mix deps.get && mix compile --warnings-as-errors
tar -czf /tmp/build-test-env.tar.gz _build/test deps

# Simulate what the test job does:
rm -rf _build/test deps
tar -xzf /tmp/build-test-env.tar.gz

# Verify zero recompile:
MIX_ENV=test mix compile --warnings-as-errors
# Expected output: nothing (or "Compiling 0 files")
```

### Proving Success Criterion #4 (contract tests green)

**Standard:** `mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` must pass with zero failures.

**Run command:**
```bash
SCORIA_LANE_CONTRACT_ONLY=true MIX_ENV=test mix test --no-start --warnings-as-errors \
  test/scoria/ci_policy_contract_test.exs \
  test/scoria/verification_lanes_test.exs
```

This is the same command used in the `policy` job's lane-contract step — the strongest local parity check available.

### Validation Architecture Summary

| Requirement | Behavior | Test Type | Automated Command | Observable Signal |
|-------------|----------|-----------|-------------------|-------------------|
| CACHE-01 | Cache keys include MIX_ENV, no bare `runner.os-mix-` key | ExUnit (contract) | `mix test test/scoria/ci_policy_contract_test.exs` | New assertions pass; grep fails on old key pattern |
| CACHE-02 / SC#2 | `build` job present in policy-side, has `needs: policy`, uploads artifact | ExUnit (contract) | `mix test test/scoria/ci_policy_contract_test.exs` | New build-job assertions pass |
| CACHE-02 / SC#3 | Zero `Compiling N files` in test job after artifact restore | CI log inspection | `gh run view <id> --log \| grep "Compiling"` | Absent = pass |
| SC#4 | Contract tests green, no command string moved | ExUnit | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors <contract files>` | Zero failures |

### Wave 0 Gaps

- [ ] New test functions in `test/scoria/ci_policy_contract_test.exs` — covers CACHE-01, CACHE-02 SC#1 and SC#2; see "Minimal new assertions" section above
- Existing test infrastructure (`ExUnit`, `mix test`, `SCORIA_LANE_CONTRACT_ONLY`) fully covers SC#4; no framework install needed

---

## Security Domain

> This phase modifies GitHub Actions YAML and adds ExUnit tests. No new network endpoints, user-facing surfaces, or authentication flows.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | No | — |
| V6 Cryptography | No | — |

**CI-specific security note:** The artifact `build-test-env.tar.gz` contains compiled BEAM files (no secrets, no credentials). `retention-days: 1` minimizes exposure window. The artifact is internal to the workflow run — not externally downloadable without GitHub credentials.

---

## Sources

### Primary (HIGH confidence)

- `elixir-lang/elixir` — `lib/mix/lib/mix/compilers/elixir.ex` lines 440-457 — exact staleness detection algorithm; lines 103-105 — `old_cache_key != new_cache_key` force-recompile trigger [VERIFIED: read via gh api]
- `erlef/setup-beam` README — output names `otp-version`, `elixir-version`; `version-file` + `version-type: strict` documentation [VERIFIED: WebFetch from GitHub]
- `/Users/jon/projects/scoria/.github/workflows/ci.yml` — current cache key patterns, upload-artifact@v7 usage [VERIFIED: repo read]
- `/Users/jon/projects/scoria/.github/workflows/ci-verify.yml` — current policy/test topology, upload-artifact@v7, cache@v5 [VERIFIED: repo read]
- `/Users/jon/projects/scoria/test/scoria/ci_policy_contract_test.exs` — all existing assertions; `split_jobs/1` implementation [VERIFIED: repo read]
- `/Users/jon/projects/scoria/test/scoria/verification_lanes_test.exs` — all existing lane order assertions [VERIFIED: repo read]
- `felt/ultimate-elixir-ci` `.github/actions/elixir-setup/action.yml` — production Elixir CI using `steps.beam.outputs.otp-version` / `elixir-version` in cache keys [VERIFIED: read via gh api]

### Secondary (MEDIUM confidence)

- `github.com/orgs/community/discussions/42615` — artifact zip does not preserve mtime; confirms the problem [CITED: WebFetch]
- `github.com/actions/upload-artifact/issues/384` — same mtime issue, open since 2023 [CITED: WebSearch]
- GitHub Docs — artifacts available within same workflow run via shared `GITHUB_RUN_ID` [CITED: docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts]

### Tertiary (LOW confidence)

- WebSearch results confirming GNU tar preserves mtime in headers — standard behavior, corroborated by multiple sources but not verified against an authoritative specification URL in this session [ASSUMED, but standard knowledge]

---

## Metadata

**Confidence breakdown:**
- Standard stack (action versions, patterns): HIGH — all verified against actual repo files
- Mtime landmine analysis: HIGH — verified against Elixir compiler source code
- setup-beam outputs: HIGH — verified against official README
- Contract test impact: HIGH — verified against actual test file contents
- tar mtime preservation: MEDIUM/HIGH — standard Unix behavior, widely documented, no counter-examples found

**Research date:** 2026-06-14
**Valid until:** 2026-09-14 (stable — GitHub Actions action versions change slowly; Elixir compiler staleness algorithm is stable)
