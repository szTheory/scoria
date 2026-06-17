# Phase 27: CI determinism & flake elimination - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Eliminate the two known CI flakes at the root and codify a deliberate retry-vs-fix
policy so new flakes can't be masked. Specifically: (1) fix the fixed-host-port
Postgres bind conflict across all CI Postgres jobs, (2) remove the leftover TEMP e2e
diagnostic step, (3) document + enforce a retry-vs-fix policy. The verification bar
(contract tests, lane set) stays green and intact — no lane removed or demoted.

**Not in scope:** further CI parallelization/sharding/caching (Phases 23–26, done),
the `mix ci` local alias and velocity timing (Phase 28), or reworking local dev DB
setup (local stays on its deliberate fixed `55432` docker mapping).
</domain>

<decisions>
## Implementation Decisions

Calibration: `minimal_decisive` (opinionated profile). Each decision was researched
via parallel subagents (idiomatic Elixir/Phoenix/Ecto CI practice, ecosystem
examples, footguns, DX). UI/brand lens N/A — this is a DevOps phase.

### FLAKE-01 — Postgres connection strategy
- **D-01:** Replace the fixed `ports: ['55432:5432']` with the conventional
  **`ports: ['5432:5432']`** and set **`SCORIA_DB_PORT: 5432`** in every CI Postgres
  job block. Apply to all 5 blocks: `e2e` (`.github/workflows/ci.yml`); and `test`,
  `knowledge`, `connector`, `full-suite` matrix (`.github/workflows/ci-verify.yml`).
- **D-02 (root cause / why this works):** `55432` falls inside the GitHub-runner
  **ephemeral port range (`32768–60999`)**, so the kernel can transiently auto-assign
  that port to an outbound socket *before* Docker publishes the service container →
  "port already allocated" (the failure on run `27508317719`). The default `5432` is
  **below** the ephemeral range → immune to this class. This is also the dominant
  Phoenix/Ecto/Oban/Ash CI idiom (principle of least surprise).
- **D-03 (rejected — dynamic host port `- 5432/tcp`):** GitHub's context-availability
  table confirms `job.services.<id>.ports` is **NOT available in job-level `env:`**
  (only step-level / `run:`). The dynamic approach would require per-step env across
  all 5 blocks + the matrix, with a *silent* empty-port failure mode. Higher surface,
  worse failure mode. Do not use.
- **D-04 (rejected — job-in-container + network alias):** Heaviest option; forces
  setup-beam, Node, and Playwright (for `e2e`) to run inside the container. Not worth
  it for marginal benefit.
- **D-05 (local unchanged):** Local dev/test keep `SCORIA_DB_PORT=55432`
  (`lib/scoria/verification_lanes.ex:48` local `command`, `docs/MAINTAINERS.md`
  local-parity note). CI sets the port explicitly via env, so CI=5432 / local=55432
  coexist cleanly. The config default fallback is already `"5432"`.

### FLAKE-02 — Remove TEMP diagnostic
- **D-06:** Delete the `TEMP diagnose runs visibility` step from the `e2e` job in
  `.github/workflows/ci.yml` (currently lines ~115–125). Clear-cut — no gray area.

### FLAKE-03 — Retry-vs-fix policy
- **D-07 (stance):** **Zero-retry default.** Gating test lanes MUST NOT use
  `continue-on-error: true`, job-level retry, or any retry-action wrapper
  (`nick-fields/retry`, `Wandalen/wretry`, etc.) on steps running `mix test`, the e2e
  lane, or any verify job. (Codifies the current de-facto state — no test retries
  exist today.)
- **D-08 (carve-out):** The existing `attempt` polling loops in `release-please.yml`,
  `hex-publish.yml`, and the `*-automerge.yml` workflows poll for CI *completion* /
  Hex index / branch-protection — they are control-flow waits, **not test retries** —
  and are explicitly out of scope of the ban.
- **D-09 (one allowed exception class):** A retry is permitted ONLY on a step doing a
  known infra-transient op (network/package install, browser/toolchain download),
  never on assertion-running steps. It must be a distinctly named step (e.g.
  `Install Playwright (retry: network-transient)`), justified inline, log
  `RETRY <step> attempt N/M: <reason>`, max attempts ≤ 3, added under review.
- **D-10 (fix, don't retry):** A non-deterministic test must be root-caused-and-fixed
  or quarantined (`@tag :flaky`, excluded from the gate) with a tracking issue — never
  made to pass by re-running. (Backed by Fowler / industry consensus; ExUnit ships no
  idiomatic auto-retry — `--repeat-until-failure` is for *reproducing*.)

### Policy doc home
- **D-11:** Add a `### Flake policy: retry vs fix` subsection to **`docs/MAINTAINERS.md`**,
  adjacent to its existing `## CI gate map {#ci-gate-map-maintainers}` anchor. NOT
  `docs/operator_verification.md` (that doc is **adopter**-facing — "default
  verification lane for your host app"). MAINTAINERS.md is explicitly maintainer-only
  and is the canonical CI-narrative home. Optionally retarget the `ci.yml` header
  comment (line ~16) from `operator_verification.md` to `MAINTAINERS.md` so a
  maintainer editing CI lands on the policy. Both docs ship to Hex; precedent already
  accepts maintainer narrative in HexDocs (audience is drawn by document, not directory).

### Recurrence proof (Success Criterion 1)
- **D-12 (durable guard):** Extend `test/scoria/ci_policy_contract_test.exs` with a
  permanent assertion that **no Postgres `ports:` block binds a host port in the
  ephemeral range (≥ 32768)** — root-cause-faithful, catches *any* bad fixed port, not
  just `55432`. Derive the Postgres-job set from `body =~ "postgres:"` (auto-covers a
  future 6th job) and keep a `>= 5` non-empty guard so a broken slice regex fails loud,
  not vacuously. Reuse the existing file-agnostic `job_blocks/1` helper for both
  `ci.yml` and `ci-verify.yml`. Stay string/regex-based (NO yaml parser — matches the
  file's existing convention; asserts on source text incl. comments/ordering).
- **D-13 (empirical corroboration):** One-time **~10× `workflow_dispatch` sweep**
  (covers `ci.yml` e2e + `ci-verify.yml` lanes); paste run URLs into the phase
  VERIFICATION doc. Manual, non-permanent — no recurring CI cost, no "remember to
  remove" cleanup (which is why a temporary repeat-N matrix was rejected).
- **D-14 (honest framing):** State in VERIFICATION that non-recurrence is **structural**
  (host port now below the ephemeral range), with the contract test as the durable
  guarantee and the sweep as corroboration. Rule-of-three: ~10 clean runs is only weak
  *probabilistic* evidence (95% upper bound ~30%) — but the fix is structural, not
  probabilistic, so that's the right bar. Do not overclaim "10× proves it's gone."

### Claude's Discretion
- Exact regex/parse form of the ephemeral-range assertion and how the carve-out for the
  release/merge polling loops is encoded in the contract test (planner/executor choice,
  within D-12).
- Whether to also add a contract assertion banning `continue-on-error`/retry-action
  `uses:` slugs on test workflows to enforce D-07 (recommended; low false-positive risk
  — unambiguous tokens).
- Whether to retarget the `ci.yml` header comment (D-11) now or note it for Phase 28.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements & success criteria
- `.planning/ROADMAP.md` §"Phase 27: CI determinism & flake elimination" — goal + 4
  success criteria (SC1 ephemeral-port fix + non-recurrence; SC2 TEMP removal; SC3
  retry policy; SC4 bar preserved).
- `.planning/REQUIREMENTS.md` — FLAKE-01, FLAKE-02, FLAKE-03 (lines ~33–35).
- `.planning/seeds/SEED-003-ci-efficiency-overhaul.md` — milestone vision / flakiness
  evidence that motivated this work.

### CI workflows to edit
- `.github/workflows/ci.yml` — `e2e` job: Postgres block (lines ~34–52, the `55432`
  bind), TEMP diagnostic step (lines ~115–125), header comment (line ~16).
- `.github/workflows/ci-verify.yml` — 4 Postgres blocks: `test` (~107), `knowledge`
  (~218), `connector` (~278), `full-suite` matrix (~347).
- `.github/workflows/release-please.yml`, `hex-publish.yml`,
  `release-pr-automerge.yml` — the `attempt` polling loops carved out by D-08 (do NOT
  treat as test retries).

### Enforcement & docs
- `test/scoria/ci_policy_contract_test.exs` — existing YAML-scan contract test;
  `job_blocks/1` helper (~line 586), per-job `services:` assertions (test "postgres
  service is configured only for test, knowledge, connector [+full-suite] jobs", ~179),
  `>= N` non-empty guards (idiom at ~250, ~327). Extend here for D-12; keep green for SC4.
- `docs/MAINTAINERS.md` — `## CI gate map {#ci-gate-map-maintainers}` anchor (line 5);
  local-parity note `SCORIA_DB_PORT=55432` (line 77). Add flake-policy subsection (D-11).
- `docs/operator_verification.md` — adopter-facing; do NOT put the policy here (D-11).
- `lib/scoria/verification_lanes.ex:48` — local `command` hardcodes
  `SCORIA_DB_PORT=55432` (local-only; leave per D-05). `mix.exs` `extras:` already ships
  MAINTAINERS.md (lines ~122–140).
- `config/test.exs:6-7`, `config/dev.exs:6-7` — read `SCORIA_DB_HOST`/`SCORIA_DB_PORT`
  with `"5432"` fallback default (no change needed; CI env drives the value).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ci_policy_contract_test.exs` `job_blocks/1` is file-agnostic (takes content) — reuse
  for `ci.yml` and `ci-verify.yml` in the new D-12 guard. No new test infra/deps.
- Existing `>= N` non-empty guard idiom (lines ~250, ~327) — copy for the D-12 guard.
- `workflow_dispatch` is already enabled on `ci.yml` (line ~11) — the D-13 sweep needs
  no workflow change to trigger.

### Established Patterns
- Contract tests assert on **source text** via `File.read!` + `Regex`/`:binary.match`,
  not a parsed AST — preserves comment/ordering checks. Stay string-based (no yaml dep).
- The verification bar / lane set is SSOT'd in `Scoria.VerificationLanes` +
  `ci_policy_contract_test.exs`; SC4 requires both stay green and no lane removed.
- Env-driven DB connection (`SCORIA_DB_HOST`/`SCORIA_DB_PORT`) means CI port choice is
  decoupled from local — change CI to 5432 without touching local 55432.

### Integration Points
- The 5 Postgres job blocks across the two workflow files are the edit surface; the
  contract test is the regression guard that ties the YAML to the policy so they can't drift.
</code_context>

<specifics>
## Specific Ideas

- Root cause is precise and structural: fixed host port `55432` ∈ ephemeral range
  `32768–60999`; default `5432` is below it. The whole FLAKE-01 fix follows from this.
- Failure reproduced on run `27508317719` (cite in VERIFICATION as the before-state).
- Honest, non-overclaiming verification language is explicitly wanted (D-14).
</specifics>

<deferred>
## Deferred Ideas

- `mix ci` local alias + before/after velocity timing — **Phase 28** (DX-01, VELO-01).
- Retargeting/cleanup of the `ci.yml` header comment to MAINTAINERS.md may be folded
  into Phase 28's lane-set documentation pass if not done here (D-11, discretionary).
- Optional broader contract assertion banning retry-action `uses:` slugs — implement
  with D-07 enforcement if cheap; otherwise a follow-up.

None of these expanded the phase scope — discussion stayed within FLAKE-01/02/03.
</deferred>

---

*Phase: 27-ci-determinism-flake-elimination*
*Context gathered: 2026-06-16*
