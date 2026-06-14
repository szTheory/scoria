# Phase 23: Cache correctness + build-once job - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

CI compiles deps + app **exactly once per run**, and every downstream job reuses
that artifact instead of recompiling — with cache keys that can never collide
across `MIX_ENV` or stale tool versions.

Delivers CACHE-01 (env- and version-scoped cache keys) and CACHE-02 (a dedicated
`build` job that compiles once and shares `_build/test` + `deps` as an artifact).

**In scope:** cache-key scoping in `ci.yml` + `ci-verify.yml`, a new `build` job,
downstream jobs restoring the build artifact, sourcing OTP/Elixir from
`.tool-versions`, keeping the lane-contract tests green.

**Out of scope (later phases):** knowledge lane scoping (Phase 24), lane
parallelization / topology docs (Phase 25), partition sharding (Phase 26), flake
elimination incl. the fixed `55432:5432` Postgres port (Phase 27), `mix ci` alias
+ velocity closeout (Phase 28).
</domain>

<decisions>
## Implementation Decisions

### Build-job placement
- **D-01:** The new `build` job lives in the **reusable `ci-verify.yml`**, not the
  `ci.yml` entry. This warms a single compile for every consumer of `ci-verify.yml`
  (PR `verify`, release-please verify, hex-publish recovery) — one SSOT, no
  duplicated compile logic.
- **D-02:** Job sequence inside `ci-verify.yml` is `policy → build → test`.
  `build` runs `mix deps.get && mix compile --warnings-as-errors` under
  `MIX_ENV=test`, then publishes `_build/test` + `deps` via `actions/upload-artifact`.
- **D-03:** `test` (and any other `ci-verify.yml` job that needs compiled output)
  `needs: build` and **downloads/restores the artifact** rather than cold-compiling.
  Confirm via job logs: no cold-compile step in `test`.

### dev-env lanes (the e2e + release_preview wrinkle)
- **D-04:** The `build` job uploads the **`MIX_ENV=test` artifact only** (CACHE-02 is
  literal). It does NOT build a second dev artifact.
- **D-05:** Dev-env lanes (`e2e` job in `ci.yml`, and the `MIX_ENV=dev`
  `mix scoria.release_preview` step in the `test` job) keep their **own dev compile**,
  but now warmed by a **correctly env-scoped dev cache key** (the CACHE-01 fix).
  Rationale: a test-env `_build` is useless to a dev-env compile; dev compile is the
  cheaper half; building a second dev artifact would exceed CACHE-02's stated scope and
  add artifact plumbing for little gain.

### Cache-key + version sourcing
- **D-06:** Switch `setup-beam` in **both** `ci.yml` and `ci-verify.yml` from the
  hardcoded `otp-version: "27"` / `elixir-version: "1.19"` to
  `version-file: .tool-versions` + `version-type: strict` — matching the pattern
  already used in `release-please.yml`, `hex-publish.yml`, `post-publish-smoke.yml`.
  Kills the current drift between hardcoded CI versions and `.tool-versions`
  (`erlang 27.3.2`, `elixir 1.19.5-otp-27`).
- **D-07:** Cache key recipe:
  `${{ runner.os }}-otp<OTP>-elixir<ELIXIR>-<MIX_ENV>-mix-${{ hashFiles('**/mix.lock') }}`
  where `<OTP>`/`<ELIXIR>` are read from `.tool-versions` into a step output (or sourced
  from the `setup-beam` outputs if available) so dev and test `_build` never share a key.
  `restore-keys` should fall back on the same os+otp+elixir+env prefix, NOT a bare
  `${{ runner.os }}-mix-` (the current too-broad fallback that lets dev/test collide).

### Contract-test handling
- **D-08:** Insert `build` as `policy → build (needs: policy) → test (needs: build)`.
  Because `build` keeps `needs: policy`, the literal `needs: policy` substring asserted
  by `ci_policy_contract_test.exs` still appears; `test` moves to `needs: build`.
- **D-09:** `split_jobs/1` (splits `ci-verify.yml` at `"\n  test:"`) keeps working — the
  `build` job lands in the policy-side slice; it must have **no `services:`** block so
  `refute policy_section =~ "services:"` still holds. Postgres stays test-job-only.
- **D-10:** Extend the contract tests minimally to assert the new `build` job + artifact
  upload/restore and the `needs:` chain. **No pinned command string moves out of
  byte-order** — `verification_lanes_test` lane ordering and all `VerificationLanes`
  command strings stay byte-identical (Success Criterion #4).

### Claude's Discretion
- Exact mechanism for reading `.tool-versions` into a cache-key step output (inline
  `grep`/`cut`, a composite action, or `setup-beam` outputs) — planner/researcher's call.
- Artifact `name`, `retention-days`, and `if-no-files-found` settings, consistent with
  existing `upload-artifact` usage in the repo.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` § "Phase 23: Cache correctness + build-once job" — goal,
  success criteria (esp. #1 key scoping, #2 build job, #3 downstream restore, #4 contracts green).
- `.planning/REQUIREMENTS.md` — CACHE-01, CACHE-02 (and the requirement→phase mapping table).

### CI files to modify
- `.github/workflows/ci.yml` — PR/main entry: `verify` (uses `ci-verify.yml`), `e2e`
  (MIX_ENV=dev), `ci-gate` fan-in. Holds the dev-env e2e cache.
- `.github/workflows/ci-verify.yml` — reusable `workflow_call` SSOT: `policy → test`.
  Where the new `build` job goes.
- `.tool-versions` — `erlang 27.3.2`, `elixir 1.19.5-otp-27` — the version source of truth.

### Contract tests (must stay green — Success Criterion #4)
- `test/scoria/ci_policy_contract_test.exs` — asserts `needs: policy`, closeout lane
  order, `services:` only on test job, `split_jobs/1` at `"\n  test:"`. Extend minimally.
- `test/scoria/verification_lanes_test.exs` — pins command byte-order / lane set.
- `lib/.../verification_lanes.ex` (`Scoria.VerificationLanes`) — SSOT for lane command strings.

### Patterns to mirror
- `.github/workflows/release-please.yml`, `hex-publish.yml`, `post-publish-smoke.yml` —
  existing `version-file: .tool-versions` + `version-type: strict` usage to copy.
- `docs/operator_verification.md` — CI gate map (maintainer narrative referenced by contracts).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `version-file: .tool-versions` + `version-type: strict` setup-beam pattern already
  proven in 3 workflows — copy verbatim into `ci.yml`/`ci-verify.yml`.
- `actions/upload-artifact@v7` + `actions/cache@v5` already in use in `ci.yml`
  (Playwright cache, host-proof / playwright-report artifacts) — same versions/idioms.

### Established Patterns
- **Contract-as-byte-order:** `ci_policy_contract_test` + `verification_lanes_test`
  treat the YAML as a typed contract (substring + ordering asserts). Any topology change
  must be reflected in these tests in the same commit; command strings are byte-frozen.
- **Reusable workflow SSOT:** executable lanes live in `ci-verify.yml`; `ci.yml` is a
  thin entry + the e2e/browser lane. Recovery/release paths reuse `ci-verify.yml`.

### Integration Points
- `build` job → `upload-artifact` → `test` job `download-artifact`/restore (within reusable wf).
- `e2e` job (ci.yml, MIX_ENV=dev) stays on its own `actions/cache` — now env-scoped.
- setup-beam version source → `.tool-versions` → also feeds the cache-key OTP/Elixir segments.

### ⚠️ Hard constraint for research/planning (mtime landmine)
Sharing `_build` via `actions/upload-artifact` is a known source of **spurious Elixir
recompiles**: artifact download does not reliably preserve file mtimes, and `mix`'s
incremental compiler keys off mtimes — so a naive upload/download can re-trigger a full
compile downstream, defeating the entire phase. The plan MUST address this (e.g. tar the
artifact to preserve timestamps, `touch`-normalize after download, or otherwise prove via
`mix compile` output / `--dry-run` that the downstream job performs **no** recompile).
This is the make-or-break of Success Criterion #3.
</code_context>

<specifics>
## Specific Ideas

- User confirmed the `minimal_decisive` posture: decisions above are locked defaults,
  not open questions. Researcher/planner should proceed without re-asking.
- The dev/test split (D-04/D-05) was the one explicitly weighed fork — user chose
  "test-only artifact; dev via env-scoped cache" over "build both dev+test artifacts."
</specifics>

<deferred>
## Deferred Ideas

- None raised that belong to other phases — discussion stayed within phase scope.

### Reviewed Todos (not folded)
- **"Docker dev-DX fleet hardening — port-conflict-free multi-lib local DX"**
  (`docker-dx-fleet-hardening.md`, weak keyword match: "dev", "phase") — not folded.
  Reason: it's about local Docker dev DX / multi-lib port conflicts, unrelated to CI
  cache/build-once. (Note: the fixed `55432:5432` Postgres port *in CI* is a separate
  concern already owned by Phase 27, not this phase.)

</deferred>

---

*Phase: 23-cache-correctness-build-once-job*
*Context gathered: 2026-06-14*
