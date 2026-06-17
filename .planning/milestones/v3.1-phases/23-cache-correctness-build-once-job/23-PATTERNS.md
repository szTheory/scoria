# Phase 23: Cache Correctness + Build-Once Job - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 3 (ci-verify.yml, ci.yml, ci_policy_contract_test.exs)
**Analogs found:** 5 / 5 change-units

---

## File Classification

| Change Unit | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| New `build` job in `.github/workflows/ci-verify.yml` | CI job block | request-response (compile → artifact) | Existing `policy` and `test` job blocks in `ci-verify.yml` | exact — same file, same YAML indentation/structure |
| `setup-beam` with `version-file` + `id: beam` in `ci-verify.yml` and `ci.yml` | CI step (version install) | config | `erlef/setup-beam@v1` steps in `release-please.yml:218-221`, `hex-publish.yml:137-140`, `post-publish-smoke.yml:82-85` | exact — proven pattern in 3 workflows |
| `actions/cache@v5` with env-scoped key in `ci-verify.yml` and `ci.yml` | CI step (cache) | CRUD | Existing `actions/cache@v5` steps in `ci-verify.yml:29-36`, `ci.yml:73-80` | exact — same file, narrow key replaces current broad key |
| `actions/upload-artifact@v7` in `build` job + `actions/download-artifact@v7` in `test` job | CI step (artifact I/O) | file-I/O | Existing `actions/upload-artifact@v7` step in `ci.yml:131-136` and `ci-verify.yml:123-129` | role-match — same action/version; new use is for build artifact not report |
| New test functions in `test/scoria/ci_policy_contract_test.exs` | test | CRUD (file read + substring assert) | Existing `"postgres service is configured only for the test job"` and `"test job depends on policy..."` tests in the same file | exact — same module, `split_jobs/1`, `assert =~` / `refute =~` style |

---

## Pattern Assignments

### 1. New `build` job in `.github/workflows/ci-verify.yml`

**Analog:** `ci-verify.yml` — `policy` job (lines 16-53) and `test` job (lines 56-151)

**Job structure pattern** (ci-verify.yml lines 16-53 for `policy`, mirrored for `build`):

```yaml
  # policy: baseline expiry + compile WAE + lane-contract tests (no Postgres)
  policy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v6

      - name: Install Erlang and Elixir
        uses: erlef/setup-beam@v1
        with:
          otp-version: "27"
          elixir-version: "1.19"

      - name: Restore deps cache
        uses: actions/cache@v5
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-mix-
```

**`test` job `needs:` + `env:` + `services:` pattern** (ci-verify.yml lines 56-83):

```yaml
  # test: release_preview → closeout lanes → full-suite WAE → knowledge lane
  test:
    runs-on: ubuntu-latest
    needs: policy

    services:
      postgres:
        image: pgvector/pgvector:pg16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: scoria_test
        ports:
          - 55432:5432
        options: >-
          --health-cmd "pg_isready -U postgres -d scoria_test"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 10

    env:
      MIX_ENV: test
      SCORIA_DB_HOST: localhost
      SCORIA_DB_PORT: 55432
      ...
```

**Deviation for `build` job:**
- Place `build` block AFTER the `policy` block and BEFORE the `test` block in the YAML file. This ensures `build` lands in the `policy_section` slice from `split_jobs/1` (which splits at `"\n  test:"`).
- Add `needs: policy` (preserves the `needs: policy` substring the contract test asserts).
- Add `env:\n  MIX_ENV: test` (but NO `services:` block — D-09 hard constraint).
- Add `id: beam` to the `setup-beam` step (see Change Unit 2).
- Job comment must use `# build:` prefix (matching `# policy:` / `# test:` convention).
- Upload step appended at end of `build` steps (see Change Unit 4).
- The `test` job's `needs:` changes from `needs: policy` to `needs: build`.

---

### 2. `setup-beam` with `version-file` + `id: beam` (replaces hardcoded versions)

**Current (to be replaced) in `ci-verify.yml` lines 23-26:**

```yaml
      - name: Install Erlang and Elixir
        uses: erlef/setup-beam@v1
        with:
          otp-version: "27"
          elixir-version: "1.19"
```

**Current (to be replaced) in `ci.yml` lines 62-65:**

```yaml
      - name: Install Erlang and Elixir
        uses: erlef/setup-beam@v1
        with:
          otp-version: "27"
          elixir-version: "1.19"
```

**Replacement pattern** — proven verbatim in `release-please.yml` lines 218-221, `hex-publish.yml` lines 137-140, `post-publish-smoke.yml` lines 82-85:

```yaml
      - uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict
```

**Deviation for `ci-verify.yml` and `ci.yml` build/policy/test/e2e jobs:**
- Add `id: beam` and `name:` explicitly (the proven analogs omit `name:` and `id:`; but `id: beam` is required so downstream steps can reference `${{ steps.beam.outputs.otp-version }}` and `${{ steps.beam.outputs.elixir-version }}` in the cache key).
- Full form for all jobs that feed a cache step:

```yaml
      - name: Install Erlang and Elixir
        id: beam
        uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict
```

**Occurrences to update:**
- `ci-verify.yml` line 22 (`policy` job setup-beam) — add `id: beam`; replace `otp-version`/`elixir-version` with `version-file`/`version-type`
- `ci-verify.yml` line 88 (`test` job setup-beam) — same
- `ci.yml` line 62 (`e2e` job setup-beam) — same
- New `build` job setup-beam — use this form from the start

---

### 3. `actions/cache@v5` with env-scoped key (CACHE-01 fix)

**Current (to be replaced) in `ci-verify.yml` lines 28-36 (`policy` job):**

```yaml
      - name: Restore deps cache
        uses: actions/cache@v5
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-mix-
```

**Current (to be replaced) in `ci-verify.yml` lines 93-101 (`test` job — identical shape):**

```yaml
      - name: Restore deps cache
        uses: actions/cache@v5
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-mix-
```

**Current (to be replaced) in `ci.yml` lines 73-80 (`e2e` job):**

```yaml
      - name: Restore deps cache
        uses: actions/cache@v5
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-mix-
```

**Replacement for test-env jobs** (policy job in ci-verify.yml, build job in ci-verify.yml, test job in ci-verify.yml):

```yaml
      - name: Restore deps + build cache
        uses: actions/cache@v5
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-test-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-test-mix-
```

**Replacement for dev-env job** (`e2e` job in `ci.yml`):

```yaml
      - name: Restore deps + build cache
        uses: actions/cache@v5
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-dev-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-dev-mix-
```

**Deviation:** The `path:` block is unchanged; only `key:` and `restore-keys:` change. The literal string `test` or `dev` replaces `${{ env.MIX_ENV }}` in the key because using the env var would require the `env:` block to be set first — using the literal is simpler and unambiguous. Do NOT use `${{ runner.os }}-mix-` anywhere as a restore-key prefix — that is the bug being fixed.

**Existing Playwright cache in `ci.yml` lines 86-89 is unchanged** (has its own distinct key format — leave untouched):

```yaml
      - name: Cache Playwright browsers
        uses: actions/cache@v5
        with:
          path: ~/.cache/ms-playwright
          key: ${{ runner.os }}-playwright-${{ hashFiles('priv/dev/package.json') }}
```

---

### 4. `upload-artifact@v7` (build job) + `download-artifact@v7` (test job)

**Closest analog — existing upload step in `ci.yml` lines 131-136:**

```yaml
      - name: Upload Playwright report
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: playwright-report
          path: priv/dev/e2e/playwright-report
          retention-days: 7
          if-no-files-found: ignore
```

**Closest analog — existing upload step in `ci-verify.yml` lines 123-129:**

```yaml
      - name: Upload host proof failure snapshot
        if: failure()
        uses: actions/upload-artifact@v7
        with:
          name: scoria-host-proof-last-failure
          path: tmp/scoria-host-proof-last-failure/
          retention-days: 7
          if-no-files-found: ignore
```

**New upload step for `build` job** (no `if:` condition — must always succeed or the job fails):

```yaml
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

**New download + unpack steps for `test` job** (inserted before `mix deps.get`, after setup-beam):

```yaml
      - name: Download compiled artifact
        uses: actions/download-artifact@v7
        with:
          name: build-test-env

      - name: Unpack compiled artifact (restores exact mtimes)
        run: tar -xzf build-test-env.tar.gz
```

**Deviations from analogs:**
- `retention-days: 1` (not `7`) — build artifact has no debugging value after the run.
- `if-no-files-found: error` (not `ignore`) — a missing tarball means compile or pack failed; fail loudly.
- No `if: failure()` or `if: always()` condition — the upload is unconditional because this is the success-path artifact, not a failure-only diagnostic.
- The tar step MUST precede the upload step. This is net-new to this repo (no existing analog for tar-before-upload) — see "No Analog Found" section.
- `actions/download-artifact@v7` is new to this repo — use the same version tag as upload (`v7`).
- The `test` job's existing `- name: Restore deps cache` step is REMOVED (the artifact replaces the cache restore for `_build/test` + `deps`). The `actions/cache@v5` step in the `test` job is deleted entirely; `deps` and `_build/test` come from the artifact.

---

### 5. New test functions in `test/scoria/ci_policy_contract_test.exs`

**Analog 1 — "postgres service is configured only for the test job"** (lines 170-177):

```elixir
  test "postgres service is configured only for the test job" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, test_section] = split_jobs(ci_verify)

    refute policy_section =~ "services:"
    assert test_section =~ "services:"
    assert test_section =~ "postgres"
  end
```

**Analog 2 — "test job depends on policy and preserves closeout chain order"** (lines 154-168):

```elixir
  test "test job depends on policy and preserves closeout chain order" do
    ci_verify = File.read!(@ci_verify)

    release_preview = VerificationLanes.ci_command(:release_preview)
    adoption = VerificationLanes.ci_command(:adoption)
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    assert ci_verify =~ "needs: policy"
    assert ci_verify =~ release_preview
    ...
  end
```

**`split_jobs/1` helper** (lines 397-405) — all new tests use this without modification:

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

**New test functions to add** (place after the existing `"policy job does not run warning_ratchet.test"` test, before the `defp` helpers):

```elixir
  test "build job exists in policy-side slice, needs policy, and has no services block" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, _test_section] = split_jobs(ci_verify)

    assert policy_section =~ "\n  build:"
    assert policy_section =~ "needs: policy"
    assert policy_section =~ "mix compile --warnings-as-errors"
    assert policy_section =~ "upload-artifact"
    refute policy_section =~ "services:"
  end

  test "build job uploads artifact and test job downloads it" do
    ci_verify = File.read!(@ci_verify)
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

  test "cache keys include MIX_ENV segment to prevent dev/test collision" do
    ci_verify = File.read!(@ci_verify)
    ci_entry = File.read!(@ci_entry)

    assert ci_verify =~ ~r/key:.*-test-mix-/
    assert ci_entry =~ ~r/key:.*-dev-mix-/
    refute ci_verify =~ ~r/key: \$\{\{ runner\.os \}\}-mix-/
    refute ci_entry =~ ~r/key: \$\{\{ runner\.os \}\}-mix-/
  end
```

**Style notes:** All new tests use `File.read!(@ci_verify)` / `File.read!(@ci_entry)` module attributes (not inline path strings). Pattern: `[policy_section, test_section] = split_jobs(ci_verify)` with only the relevant binding pattern-matched (`_policy_section` when unused). `assert =~` for presence, `refute =~` for absence, `~r/.../` regex when checking a substring pattern (not a literal). No `index_of/2` needed in new tests — only presence/absence assertions required (D-10: minimal extension).

---

## Shared Patterns

### Job block indentation convention
**Source:** `ci-verify.yml` lines 14-151 — all jobs
**Apply to:** New `build` job block

YAML indentation is 2 spaces for job keys, 4 spaces for job properties (`runs-on:`, `needs:`, `env:`, `steps:`), 6 spaces for step entries (`- uses:`, `- name:`), 8 spaces for step properties (`uses:`, `with:`, `run:`), 10 spaces for `with:` sub-keys. The `jobs:` key is at column 0.

### Conditional upload only on failure
**Source:** `ci-verify.yml` lines 122-129, `ci.yml` lines 130-136
**Apply to:** The existing failure-only upload steps — do NOT copy `if: failure()` to the new build artifact upload (it must upload unconditionally on success, not on failure).

### Module attribute file path references
**Source:** `ci_policy_contract_test.exs` lines 6-16
**Apply to:** All new test functions — reference `@ci_verify` and `@ci_entry` (already defined at module level), not inline string paths.

---

## No Analog Found

| Change | Role | Data Flow | Reason |
|---|---|---|---|
| `tar -czf build-test-env.tar.gz _build/test deps` pack step | CI shell step | file-I/O | No existing step in this repo tars build artifacts before upload. This is net-new; the mtime-preservation rationale is in RESEARCH.md "Mtime Landmine" section. Reference: RESEARCH.md Pattern 1 (lines 508-518). |
| `tar -xzf build-test-env.tar.gz` unpack step | CI shell step | file-I/O | Same — no existing unpack-from-tar step. Must immediately follow `download-artifact` in the `test` job. |
| `actions/download-artifact@v7` | CI step | file-I/O | First use of this action in the repo; use version `v7` to match the already-pinned `upload-artifact@v7`. |

---

## Metadata

**Analog search scope:** `.github/workflows/` (all .yml files), `test/scoria/ci_policy_contract_test.exs`
**Files read:** `ci-verify.yml`, `ci.yml`, `ci_policy_contract_test.exs`, `release-please.yml` (lines 210-249), `hex-publish.yml` (lines 130-144), `post-publish-smoke.yml` (lines 78-89)
**Pattern extraction date:** 2026-06-14
