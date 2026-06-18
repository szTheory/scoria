# Roadmap: Scoria

**Last updated:** 2026-06-17 (v3.2 Drydock roadmap initialized — Phases 29–35)

## Milestones

- 🚧 **v3.2 Drydock** — Phases 29–35 (Docker dev-DX hardening + maintenance release) — IN PROGRESS
- ✅ **v3.1 CI/CD Velocity** — Phases 23–28 (PR CI 77m→7m38s measured, flakes eliminated, bar preserved) — SHIPPED 2026-06-17 — [archive](milestones/v3.1-ROADMAP.md)
- ✅ **v3.0 Control Room** — Phases 11–17 (dashboard design-system / IA / motion / proof) — SHIPPED 2026-06-14 — [archive](milestones/v3.0-ROADMAP.md)
- ✅ **v2.17 Vesicle** — Phases 18–22 (brand system, interjected) — SHIPPED 2026-06-11 — [archive](milestones/v2.17-ROADMAP.md)
- ✅ **v2.16 ReqLLM Peer Bump** — Phases 08–10 + 10.1 (shipped 2026-05-30) — [archive](milestones/v2.16-ROADMAP.md)
- ✅ **v2.15 Connector Adoption Lane** — Phases 05–07 + 07.1 (shipped 2026-05-30) — [archive](milestones/v2.15-ROADMAP.md)
- ✅ **v2.14 Maintenance Release** — `0.1.1` prep (shipped 2026-05-30)
- ✅ **v2.13 Adopter Docs Truth** — MAINTAINERS split, Hex metadata (shipped 2026-05-30)
- ✅ **v2.12 Adoption Confidence & Reference Demo** — Phases 02–04 (shipped 2026-05-30)

## Phases

<details>
<summary>✅ v3.1 CI/CD Velocity (Phases 23–28) — SHIPPED 2026-06-17</summary>

Infra/docs-only milestone realizing **SEED-003**. Cut PR CI critical path from ~77 min (one serial `verify / test` job) to **7m38s measured** (run 27709716751) and eliminated known flakes — **without weakening the verification bar**: every lane that gated merge still gates merge, nothing demoted to nightly. Hard constraints held: `Scoria.VerificationLanes.closeout_order/0` and the byte-order lane contract (`ci_policy_contract_test`, `verification_lanes_test`) green at every phase; single fast PR+main gate; standard `ubuntu-latest` runners; the `CI / ci-gate` required-check name unchanged. Node-24 actions modernization shipped separately (PR #10, merged) — not a phase here.

- [x] Phase 23: Cache correctness + build-once job (1/1 plan) — completed 2026-06-14
- [x] Phase 24: Knowledge lane scope fix (1/1 plan) — completed 2026-06-15
- [x] Phase 25: Lane parallelization + topology docs (2/2 plans) — completed 2026-06-15
- [x] Phase 26: Full-suite partition sharding (1/1 plan) — completed 2026-06-16
- [x] Phase 27: CI determinism & flake elimination (1/1 plan) — completed 2026-06-17
- [x] Phase 28: DX `mix ci` alias + velocity closeout (3/3 plans) — completed 2026-06-17

Full details: `.planning/milestones/v3.1-ROADMAP.md`. Audit `passed` — 13/13 requirements satisfied (`.planning/milestones/v3.1-MILESTONE-AUDIT.md`).

</details>

<details>
<summary>✅ v3.0 Control Room (Phases 11–17) — SHIPPED 2026-06-14</summary>

UI/IA/DX milestone. No net-new backend capability families. Expose components → delete leaked classes → consolidate → orient → polish → prove. Sequenced for compounding reuse: primitives before screens, least-iterated screens before high-traffic, motion/responsive/theme last before the proof sweep.

- [x] Phase 11: Evaluation engine + seed depth (5/5 plans) — completed 2026-06-04
- [x] Phase 12: Design-system component layer (5/5 plans) — completed 2026-06-04
- [x] Phase 13: Orientation spine (IA) (8/8 plans) — completed 2026-06-12
- [x] Phase 14: Least-iterated screens polish (6/6 plans) — completed 2026-06-12
- [x] Phase 15: High-traffic screens + evidence adapters (5/5 plans) — completed 2026-06-13
- [x] Phase 16: Motion + responsive + theme parity (6/6 plans) — completed 2026-06-13
- [x] Phase 17: Consistency sweep + proof (3/3 plans) — completed 2026-06-13

Full details: `.planning/milestones/v3.0-ROADMAP.md`. Closed with `gaps_found` audit accepted — 10 verification-doc gaps recorded as Known Gaps in MILESTONES.md.

</details>

<details>
<summary>✅ v2.17 Vesicle (Phases 18–22) — SHIPPED 2026-06-11</summary>

- [x] Phase 18: Pressure-test audit + decision lock — gate #1 approved 2026-06-11 (tagline override "AI ops for Phoenix apps."; propagation: not-required) — completed 2026-06-11
- [x] Phase 19: Logo divergence + user choice — gate #2 (2 rounds): TV-1 "Span rail" mark + LK-B "Mark-as-o" fused lockup locked — completed 2026-06-11
- [x] Phase 20: Logo convergence — full variant set — 8 root variants, user confirmed "ship it" — completed 2026-06-11
- [x] Phase 21: Tokens + brand book + standalone HTML — tokens.json/css, brand-book.md 543 lines, 7 examples, index.html 55 KB — completed 2026-06-11
- [x] Phase 22: Integration + final quality gate — quality-gate.mjs 8/8 PASS, 458 KB, mix test 632 green, DS-06 untouched — completed 2026-06-11

Full details: `.planning/milestones/v2.17-ROADMAP.md`

</details>

<details>
<summary>✅ v2.16 ReqLLM Peer Bump (Phases 08–10 + 10.1) — SHIPPED 2026-05-30</summary>

- [x] Phase 08: Bump ReqLLM constraint and lockfile — completed 2026-05-30
- [x] Phase 09: Compatibility fixes and test verification — completed 2026-05-30
- [x] Phase 10: CI lane verification and closeout — completed 2026-05-30
- [x] Phase 10.1: VERIFICATION gap closeout (INSERTED) — 1/1 plan — completed 2026-05-30

Full details: `.planning/milestones/v2.16-ROADMAP.md`

</details>

<details>
<summary>✅ v2.15 Connector Adoption Lane (Phases 05–07 + 07.1) — SHIPPED 2026-05-30</summary>

- [x] Phase 05: Lane contract + Mix task — completed 2026-05-30
- [x] Phase 06: Integration proof + SupportJourney alignment — completed 2026-05-30
- [x] Phase 07: Docs, drift guards, CI wiring — completed 2026-05-30
- [x] Phase 07.1: VERIFICATION gap closeout (INSERTED) — 1/1 plan — completed 2026-05-30

Full details: `.planning/milestones/v2.15-ROADMAP.md`

</details>

### 🚧 v3.2 Drydock (In Progress)

**Milestone Goal:** Make local multi-lib Phoenix dev hands-off and port-conflict-free, harden Scoria as the reference Docker dev-DX standard, and cut the queued maintenance release. Stream A (Docker dev-DX hardening) runs sequenced Phases 29–34; Stream B (maintenance release) is Phase 35, fully independent.

- [x] **Phase 29: Makefile hardening** — PORT 4799 default, `make clean`/`nuke`/`fleet`/`help` (completed 2026-06-18)
- [x] **Phase 30: Launch banner + native-dev notice** — populated fallback URL, Traefik admin link, key-route list, `make dev` echo (completed 2026-06-18)
- [x] **Phase 31: Dockerfile caching audit + doc** — empirical CSS-edit verification + layer-invalidation table in docs (completed 2026-06-18)
- [ ] **Phase 32: Secrets pattern + key rotation** — direnv + 1Password `op run` pattern, `.envrc`/`.env.op` examples, `ANTHROPIC_API_KEY` rotated
- [x] **Phase 33: Doc restructure + verification-copy correction** — `docker_dev_dx.md` rewrite + all `localhost:4000` corrected in docs + `.planning/` (completed 2026-06-18)
- [x] **Phase 34: Docker DX drift guard + CI guard extension** — `docker_dx_doc_contract_test.exs` (policy lane) + extend `ci_policy_contract_test.exs` to scan `post-publish-smoke.yml` (completed 2026-06-18)
- [ ] **Phase 35: Maintenance release — 0.1.2 publish + post-publish smoke** — port fix + merge PR #3 + publish + smoke GREEN

## Phase Details

### Phase 23: Cache correctness + build-once job

**Goal**: CI compiles deps + app exactly once per run and every downstream job reuses that artifact, with cache keys that never collide across `MIX_ENV` or stale tool versions.
**Depends on**: Nothing (foundation for all downstream parallel/shard jobs)
**Requirements**: CACHE-01, CACHE-02
**Success Criteria** (what must be TRUE):

  1. CI cache keys are scoped by OS + OTP + Elixir + `MIX_ENV` + `mix.lock` hash (OTP/Elixir sourced from `.tool-versions`), so `MIX_ENV=dev` and `MIX_ENV=test` `_build` artifacts never share a key — verified by no spurious recompiles in job logs across dev/test steps.
  2. A dedicated `build` job runs `mix deps.get && mix compile --warnings-as-errors` (`MIX_ENV=test`) once and publishes `_build/test` + `deps` via `upload-artifact`.
  3. Every downstream job `needs: build` and restores that artifact instead of recompiling — confirmed by absence of a cold-compile step in downstream job logs.
  4. The lane contract tests (`ci_policy_contract_test`, `verification_lanes_test`) remain green — no command string moved out of pinned byte-order.

**Plans**: 1 plan
Plans:

- [x] 23-01-PLAN.md — env+version-scoped cache keys, build-once job (tar artifact), test-job restore, contract-test extensions

### Phase 24: Knowledge lane scope fix

**Goal**: The knowledge verification lane runs only its knowledge-tagged tests instead of re-running the entire suite, reclaiming ~22 min with zero coverage loss and an unchanged merge bar.
**Depends on**: Phase 23 (runs on the warm shared build artifact)
**Requirements**: KNOW-01
**Success Criteria** (what must be TRUE):

  1. The knowledge lane runs only the 6 knowledge-tagged files (e.g. via `--only knowledge`) — verified by log file/line count dropping from a full-suite re-run to the scoped set.
  2. The same warnings-as-errors bar holds and the literal `mix test.knowledge --warnings-as-errors` contract string is unchanged in `ci-verify.yml`.
  3. Knowledge coverage is preserved: every knowledge-tagged test that ran before still runs (no `:knowledge` test silently excluded).
  4. `ci_policy_contract_test` + `verification_lanes_test` stay green (the command-string contract is unaffected by the internal arg change).

**Plans**: 1 plan

Plans:

- [x] 24-01-PLAN.md — scope knowledge lane to --only knowledge inside the mix task, add the after_suite zero-test guard, and add the derived-file-set coverage contract test (D-01/D-02/D-03)

### Phase 25: Lane parallelization + topology docs

**Goal**: The heavy serial `verify / test` job fans out into parallel `needs:`-jobs gated by one stable fan-in check, the canonical lane order is preserved as YAML byte-order, and the docs that the contract tests assert describe the topology move in the same commit.
**Depends on**: Phase 23 (each parallel job restores the shared build artifact), Phase 24 (scoped knowledge job)
**Requirements**: PAR-01, PAR-02, PAR-03, DX-02
**Success Criteria** (what must be TRUE):

  1. The heavy lanes run as sibling parallel jobs — closeout `test:` chain (carries `services: postgres`), `ratchet:`, `knowledge:`, and `connector` + advisory `gallery` tail — each `needs: build`, instead of one serial job.
  2. A single `verify-summary` fan-in job (`needs:` all children, `if: always()`, asserts each child `result == 'success'`) is the only required check; individual parallel/skipped children are never independently required.
  3. The `CI / ci-gate` required-check name is unchanged (`ci.yml`'s `ci-gate` still `needs: [verify, e2e]`), so branch protection needs no edit.
  4. `Scoria.VerificationLanes` byte-order/closeout-order contract tests (`ci_policy_contract_test`, `verification_lanes_test`) stay green — every canonical lane command string remains in its pinned order with one `test:` job carrying Postgres and no `services:` before it.
  5. `docs/MAINTAINERS.md`, `docs/operator_verification.md`, and `README` describe the new parallel topology, and any "docs describe topology" contract test stays green (docs committed in lockstep with the YAML change).

**Plans**: 2 plans
Plans:
**Wave 1**

- [x] 25-01-PLAN.md — split ci-verify.yml into parallel {test, ratchet, knowledge, connector} + verify-summary fan-in; refactor both contract tests to parallel-shape + derived fan-in completeness; fold WR-01/WR-02/WR-03

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 25-02-PLAN.md — update MAINTAINERS.md / operator_verification.md / README to the parallel topology and the docs-topology contract asserts (lockstep)

**UI hint**: no

### Phase 26: Full-suite partition sharding

**Goal**: The full ExUnit suite runs split across a parallel runner matrix on the shared build artifact, collapsing the suite wall-clock while preserving exact coverage.
**Depends on**: Phase 23 (matrix jobs restore the build artifact), Phase 25 (slots into the parallel topology under the fan-in)
**Requirements**: SHARD-01
**Success Criteria** (what must be TRUE):

  1. The full suite runs as `mix test --warnings-as-errors --partitions 4` across a 4-way runner matrix, each exporting `MIX_TEST_PARTITION=${{ matrix.partition }}` (no `config/test.exs` change — it is already partition-aware).
  2. Each shard uses an isolated database keyed by `MIX_TEST_PARTITION`, so shards never collide on DB state.
  3. There is zero coverage loss versus the single-job run — the union of the 4 shards' executed tests equals the prior full-suite test count.
  4. Only the `verify-summary` fan-in is required; individual matrix shard names are never added as required checks.

**Plans**: 1 plan

Plans:

- [x] 26-01-PLAN.md — add full-suite: 4-way matrix job + move WAE out of test: + fan-in wiring + after_suite guard; fix B-1/B-2/B-3 contract tests + D-03/D-04 structural pins; docs-as-contract topology updates (single atomic commit)

### Phase 27: CI determinism & flake elimination

**Goal**: Known CI flakes are eliminated at the root and a deliberate retry-vs-fix policy prevents new flakes from being masked.
**Depends on**: Phase 25 (operates on the new parallel job topology)
**Requirements**: FLAKE-01, FLAKE-02, FLAKE-03
**Success Criteria** (what must be TRUE):

  1. The Postgres service no longer binds a fixed host port — the `-p 55432:5432` mapping in `ci.yml` + `ci-verify.yml` is replaced with a non-conflicting strategy (network alias / dynamic port / resilient bind); the failure reproduced on run `27508317719` does not recur across repeated runs.
  2. The leftover TEMP diagnostic step (DB run-count + server-render dump) is removed from the `e2e` job in `ci.yml`.
  3. A retry-vs-fix policy is documented and applied — no blanket auto-retries; any retry is scoped to a known-infra-transient step only and is visible in logs.
  4. Contract tests and the verification bar remain green/intact — no lane removed or demoted while fixing flakes.

**Plans**: 1 plan

Plans:

- [x] 27-01-PLAN.md — fix Postgres ephemeral host-port bind in all 5 CI blocks (D-01), remove the TEMP e2e diagnostic (D-06), document the retry-vs-fix flake policy in MAINTAINERS.md (D-07..D-11), and add durable contract guards (D-12 ephemeral-port ban + no-TEMP + no-retry-on-test-workflows)

### Phase 28: DX `mix ci` alias + velocity closeout

**Goal**: A contributor can reproduce the full merge gate locally with one command, and the milestone's headline velocity outcome is proven with real before/after timing.
**Depends on**: Phase 25, Phase 26, Phase 27 (the alias mirrors the final lane set; timing measured against the fully-parallelized pipeline)
**Requirements**: DX-01, VELO-01
**Success Criteria** (what must be TRUE):

  1. A single `mix ci` alias reproduces the merge gate locally (deps lock check, format check, compile WAE, the canonical lane set) and exits non-zero on any gate failure.
  2. On a warm-cache PR run, CI critical-path wall-clock is ≤ ~15 min (target ~12 min), down from the ~77 min baseline — verified via `gh run view <id> --json jobs` before/after timing.
  3. The knowledge job no longer re-runs the full suite (confirmed by log file/line count) and the `build` artifact is restored by every downstream shard (no cold recompiles) — the two largest reclaimed costs are demonstrably gone.
  4. Every gating lane still executes in CI (diffed from job logs, not just YAML) and `ci_policy_contract_test` + `verification_lanes_test` are green — the bar is preserved at milestone close.

**Plans**: 3 plans

Plans:

- [x] 28-01-PLAN.md — `mix ci` Mix task (SSOT-driven, run-all-aggregate, pgvector preflight, --skip-optional) + alias + local-vs-CI asymmetry docs (DX-01)
- [x] 28-02-PLAN.md — durable velocity proof (pinned before/after run IDs + inline gh JSON) + MILESTONES headline + verification back-ref (VELO-01)
- [x] 28-03-PLAN.md — [gap] compile-only ratchet capture (parity-guarded, ~19m→1m46s) + push parallelized topology + capture REAL run 27709716751 + measured proof/MILESTONES/traceability (VELO-01 MET: 7m38s)

---

### Phase 29: Makefile hardening

**Goal**: The Makefile is the single trustworthy entry point for every dev operation — `make dev` binds a non-colliding port by default, stale-instance and cleanup targets exist and are scope-safe, and `make` with no args prints the full target list.
**Depends on**: Nothing (Stream A foundation — all subsequent Stream A phases depend on this)
**Requirements**: DXCLI-01, DXCLI-02, DXCLI-03, DXCLI-04
**Success Criteria** (what must be TRUE):

  1. `make dev` starts the native server at `http://localhost:4799/scoria` — confirmed by `grep "PORT" Makefile` showing `PORT ?= 4799` (or equivalent inline default) and the `shots-native` target URL agreeing with `4799`.
  2. `make clean` stops this instance's containers and keeps named volumes; `make nuke` wipes this instance's named volumes — both scoped to `$(COMPOSE_PROJECT_NAME)` via `docker compose down`; `grep -n "volume prune\|system prune" Makefile` returns zero hits.
  3. `make nuke` prints a warning naming `$(COMPOSE_PROJECT_NAME)` and the volumes it will delete before proceeding — no interactive TTY prompt required; the target name is the safety signal.
  4. `make fleet` runs a `docker ps` filter that surfaces all `scoria-*` containers so a stale instance shadowing `scoria.localhost` is immediately visible.
  5. `make` (no args) prints the help list derived from `##`-comment awk parsing — every new target this phase adds appears in that output.

**Plans**: 1 plan

Plans:
**Wave 1**

- [x] 29-01-PLAN.md — PORT 4799 threading (dev + shots-native + 2 doc comments) + clean/down-alias/nuke teardown ladder + fleet + .DEFAULT_GOAL/help awk parser + .PHONY (DXCLI-01..04, single Makefile pass)

### Phase 30: Launch banner + native-dev notice

**Goal**: Starting the dev server (Docker or native) immediately shows the operator where to go — a populated fallback URL, the Traefik admin link, and a grouped key-route list — eliminating the "where do I poke around?" puzzle.
**Depends on**: Phase 29 (PORT default established, `make dev` echo wired)
**Requirements**: DXCLI-05
**Success Criteria** (what must be TRUE):

  1. `make dev` prints a startup line with `http://localhost:4799/scoria` (or the active `$PORT` value) before the server starts — visible in the terminal without scrolling back past server log noise.
  2. The Docker `docker/dev-entrypoint.sh` banner includes the Traefik admin link (`http://localhost:8080`) and a grouped key-route list covering the `/scoria` screens — all on distinct lines so they are copy-pasteable.
  3. The banner contains a "Native dev server: `make dev` → `http://localhost:4799/scoria`" notice so a reader who reaches the banner via Docker is not confused about the native path and port.

**Plans**: 1/1 plans complete

- [x] 30-01-PLAN.md — Makefile native startup URL line + Docker banner router-derived route list, Traefik link, and native-dev notice (boot-safe)

### Phase 31: Dockerfile caching audit + doc

**Goal**: The Dockerfile layer order is empirically proven to prevent dep refetch on a CSS/HEEx-only edit, and that guarantee is documented as a layer-invalidation table plus an invariant comment so future contributors cannot regress it silently.
**Depends on**: Phase 29 (parallelizable with Phase 30 — no code dependency between them; both depend only on the Phase 29 foundation)
**Requirements**: CACHE-01
**Success Criteria** (what must be TRUE):

  1. Editing `assets/css/app.css` (or any `lib/**/*.heex`) and running `docker compose up --build` produces no `mix deps.get` step in the build output — empirically verified and noted in the phase record.
  2. `Dockerfile.dev` contains an invariant comment at the relevant COPY/RUN boundary explaining that the order is deliberate and must not be violated.
  3. `docs/docker_dev_dx.md` contains a layer-invalidation table with at minimum: CSS/HEEx-only edit → app compile only; `config/` edit → dep.compile + app compile; `mix.exs`/`mix.lock` edit → full dep rebuild.

**Plans**: 1 plan
- [x] 31-01-PLAN.md — Dockerfile boundary invariant comment + docs layer-invalidation table + static COPY-order policy-lane test + empirical cache proof in SUMMARY

### Phase 32: Secrets pattern + local key exposure closeout

**Goal**: Provider API keys stop using plaintext committed-example patterns — the direnv + 1Password `op run` pattern is documented and exemplified, the old plaintext stub is removed from `.env.example`, and the local `.env` `ANTHROPIC_API_KEY` concern is closed by maintainer-accepted no-Git-exposure attestation.
**Depends on**: Phase 29 (parallelizable with Phases 30/31 — no code dependency; all three can execute after Phase 29)
**Requirements**: SEC-01, SEC-02
**Success Criteria** (what must be TRUE):

  1. `.envrc.example` and `.env.op.example` are committed; `.envrc` and `.env.op` are listed in `.gitignore`; the `ANTHROPIC_API_KEY=sk-ant-...` plaintext stub is removed from `.env.example` (replaced by an `op://` reference comment).
  2. `docs/docker_dev_dx.md` contains a Secrets section describing the direnv + `op run` pattern with a first-time setup note (requires `direnv allow` once; `op signin` before sourcing).
  3. The `ANTHROPIC_API_KEY` previously stored as plaintext in local `.env` is assessed before ship: Git metadata confirms `.env` was ignored, untracked, and absent from Git history; the maintainer accepts no rotation is required; the phase record stores only redacted attestation and no token material.

**Plans**: 2 plans
Plans:
**Wave 1**

- [x] 32-01-PLAN.md — SEC-01 safe secret examples, gitignore, `.env.example`, and Docker DX Secrets docs

**Wave 2** *(blocked on Wave 1 + maintainer attestation)*

- [x] 32-02-PLAN.md — SEC-02 redacted maintainer no-Git-exposure attestation checkpoint

### Phase 33: Doc restructure + verification-copy correction

**Goal**: `docs/docker_dev_dx.md` is the reference fleet standard a new contributor can read top-to-bottom and understand the full dev model; every stale fixed-port/raw-Phoenix dev-start reference across docs and `.planning/` is corrected to the real commands and URLs.
**Depends on**: Phases 29, 30, 31, 32 (this phase assembles the complete doc from all Stream A work that precedes it — correct PORT, banner copy, caching section, secrets section must all exist first)
**Requirements**: DOCS-01, DOCS-02
**Success Criteria** (what must be TRUE):

  1. `docs/docker_dev_dx.md` opens with a persona/JTBD paragraph and a TL;DR gameplan at the top; contains readable sections for Native dev server, Caching guarantees, Secrets, and Stale instance hygiene — each digestible in isolation.
  2. `grep -rn "localhost:4000" docs/operator_verification.md docs/MAINTAINERS.md README.md` returns zero hits where the text instructs starting the dev server (legacy/note contexts with explicit qualification are acceptable if clearly marked).
  3. Active `.planning/` prose has no verification-step or "how to start" contexts using the old raw Phoenix command — GSD phase/plan prose uses `make up` / `make dev` + the real `*.localhost` or `:4799` URL.

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 33-01-PLAN.md — restructure `docs/docker_dev_dx.md` as the reader-first fleet standard (DOCS-02)
- [x] 33-02-PLAN.md — correct active docs and qualify support-copilot gallery copy (DOCS-01)
- [x] 33-03-PLAN.md — correct host screenshot/e2e harness docs and defaults (DOCS-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 33-04-PLAN.md — sweep active `.planning` guidance and classify remaining allowed hits (DOCS-01)

### Phase 34: Docker DX drift guard + CI guard extension

**Goal**: The canonical Docker dev-DX commands and URLs are pinned by a policy-lane contract test so verification-copy drift cannot recur silently, and the `ci_policy_contract_test.exs` ephemeral-port scan is extended to cover `post-publish-smoke.yml` — closing the v3.1 FLAKE-01 blind spot before the release.
**Depends on**: Phase 33 (the doc must be in its final correct form before the contract test asserts it)
**Requirements**: DOCS-03
**Success Criteria** (what must be TRUE):

  1. `test/scoria/docker_dx_doc_contract_test.exs` exists in the policy lane (no DB, no app start) and passes in `mix test`; it asserts `"make up"`, `"make dev"`, `"4799"`, `"make nuke"`, `"direnv"` (or `"1Password"`), and `"ANTHROPIC_API_KEY"` are present in `docs/docker_dev_dx.md`.
  2. The same test asserts `"localhost:4000"` is absent from `docs/docker_dev_dx.md` as a dev-start instruction (the negative assertion that makes the guard mechanical).
  3. `ci_policy_contract_test.exs` is extended to scan `.github/workflows/post-publish-smoke.yml` for the ephemeral-port ban (host port must be < 32768); `mix test` passes with this extension in the existing policy lane without any CI topology changes.

**Plans**: TBD

### Phase 35: Maintenance release — 0.1.2 publish + post-publish smoke

**Goal**: The queued `0.1.2` maintenance release ships cleanly to Hex — with the `post-publish-smoke.yml` port flake fixed before the pipeline runs, `mix docs` confirmed clean, and the post-publish registry smoke GREEN.
**Depends on**: Nothing (Stream B — fully independent of Phases 29–34; can execute at any time while Stream A runs)
**Requirements**: REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):

  1. `post-publish-smoke.yml` Postgres host-port bind reads `5432:5432` (not `55432:5432`); `grep "55432" .github/workflows/post-publish-smoke.yml` returns zero hits.
  2. `mix docs` completes with zero errors or warnings locally before the release-please PR is merged — the package-landed-but-docs-wrong partial-publish state cannot occur.
  3. The release-please PR #3 merges on green CI, the automated pipeline runs to completion, and `mix hex.info scoria 0.1.2` confirms the version is live on the Hex registry.
  4. The post-publish registry smoke (`mix scoria.post_publish_smoke`) exits GREEN — confirming `0.1.2` installs from the live Hex registry from the GitHub Actions runner region.

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 29. Makefile hardening | v3.2 | 1/1 | Complete    | 2026-06-18 |
| 30. Launch banner + native-dev notice | v3.2 | 1/1 | Complete    | 2026-06-18 |
| 31. Dockerfile caching audit + doc | v3.2 | 1/1 | Complete    | 2026-06-18 |
| 32. Secrets pattern + local key exposure closeout | v3.2 | 2/2 | Complete    | 2026-06-18 |
| 33. Doc restructure + verification-copy correction | v3.2 | 4/4 | Complete    | 2026-06-18 |
| 34. Docker DX drift guard + CI guard extension | v3.2 | 3/3 | Complete    | 2026-06-18 |
| 35. Maintenance release — 0.1.2 publish + post-publish smoke | v3.2 | 0/TBD | Not started | - |
| 23. Cache correctness + build-once job | v3.1 | 1/1 | Complete    | 2026-06-15 |
| 24. Knowledge lane scope fix | v3.1 | 1/1 | Complete    | 2026-06-15 |
| 25. Lane parallelization + topology docs | v3.1 | 2/2 | Complete   | 2026-06-15 |
| 26. Full-suite partition sharding | v3.1 | 1/1 | Complete   | 2026-06-16 |
| 27. CI determinism & flake elimination | v3.1 | 1/1 | Complete    | 2026-06-17 |
| 28. DX `mix ci` alias + velocity closeout | v3.1 | 3/3 | Complete    | 2026-06-17 |
| 11. Evaluation engine + seed depth | v3.0 | 5/5 | Complete | 2026-06-04 |
| 12. Design-system component layer | v3.0 | 5/5 | Complete | 2026-06-04 |
| 13. Orientation spine (IA) | v3.0 | 8/8 | Complete | 2026-06-12 |
| 14. Least-iterated screens polish | v3.0 | 6/6 | Complete | 2026-06-12 |
| 15. High-traffic screens + evidence adapters | v3.0 | 5/5 | Complete | 2026-06-13 |
| 16. Motion + responsive + theme parity | v3.0 | 6/6 | Complete | 2026-06-13 |
| 17. Consistency sweep + proof | v3.0 | 3/3 | Complete | 2026-06-13 |
| 18. Pressure-test audit + decision lock | v2.17 | 2/2 | Complete | 2026-06-11 |
| 19. Logo divergence + user choice | v2.17 | 3/3 | Complete | 2026-06-11 |
| 20. Logo convergence — full variant set | v2.17 | 2/2 | Complete | 2026-06-11 |
| 21. Tokens + brand book + standalone HTML | v2.17 | 3/3 | Complete | 2026-06-11 |
| 22. Integration + final quality gate | v2.17 | 2/2 | Complete | 2026-06-11 |
| 08 | v2.16 | — | Complete | 2026-05-30 |
| 09 | v2.16 | — | Complete | 2026-05-30 |
| 10 | v2.16 | — | Complete | 2026-05-30 |
| 10.1 | v2.16 | 1/1 | Complete | 2026-05-30 |

## Previous milestone archive

See `.planning/MILESTONES.md` for full closeout history.
