# Phase 34: Docker DX Drift Guard + CI Guard Extension - Research

**Researched:** 2026-06-18  
**Domain:** Elixir ExUnit policy-lane contracts, GitHub Actions service-port policy, Docker dev-DX documentation drift guards  
**Confidence:** HIGH for repo-local implementation shape; MEDIUM for external docs citations  

<user_constraints>
## User Constraints (from CONTEXT.md)

_Source for this entire verbatim constraints section: `.planning/phases/34-docker-dx-drift-guard-ci-guard-extension/34-CONTEXT.md` [VERIFIED: repo file]._

### Locked Decisions

Calibration: the user selected all gray areas and asked for subagent-backed
research, pros/cons/tradeoffs, ecosystem lessons, prompt/brandbook context, and
one cohesive recommendation set. Four `gsd-advisor-researcher` agents covered
the post-publish port boundary, ExUnit doc-contract ownership, stale URL
strictness, and cache-table string contracts. Decisions below are LOCKED.

#### Todo folding and scope
- **D-01:** Fold only the Scoria-local Docker DX doc-drift guard portion of
  `.planning/todos/pending/docker-dx-fleet-hardening.md` into Phase 34. The
  folded problem is verification-copy drift: active docs and plans previously
  pointed maintainers at raw Phoenix fixed-port startup, and Phase 34 now makes
  the corrected Docker/native URL truth mechanically durable.
- **D-02:** Do not fold the cross-repo fleet convergence items from
  `docker-dx-fleet-hardening.md`. Sibling-repo migration, `proxy` network
  convergence across repos, and any fleet-wide cleanup target remain FLEET-01 /
  FLEET-02 future work.
- **D-03:** Review but defer
  `.planning/todos/pending/ci-policy-job-cache-key-mislabel.md`. The policy job
  already carries `MIX_ENV: test`; this todo is post-ship cleanup and not part
  of Docker DX doc drift or post-publish port scanning.
- **D-04:** Review but defer
  `.planning/todos/pending/2026-06-18-make-approval-toasts-legible.md`. It is a
  focused UI polish issue and unrelated to this policy-lane/docs phase.

#### Post-publish port-fix boundary
- **D-05:** Phase 34 should absorb the tiny
  `.github/workflows/post-publish-smoke.yml` port fix now. The new guard must
  pass in the same phase that introduces it, and the release lane should not
  knowingly carry the old `55432` flake into Phase 35.
- **D-06:** The workflow fix is intentionally narrow:
  `ports: - 55432:5432` becomes `ports: - 5432:5432`, and
  `SCORIA_DB_PORT: 55432` becomes `SCORIA_DB_PORT: 5432`. Do not change job
  names, workflow triggers, service shape, release wiring, summary text, or
  post-publish smoke behavior.
- **D-07:** Do not create an intentionally failing Phase 34 guard that waits
  for Phase 35, and do not add an allowlist/exception for
  `post-publish-smoke.yml`. Both choices normalize a known red guard or recreate
  the exact blind spot this phase exists to close.
- **D-08:** Do not switch the post-publish workflow to random host ports or
  `job.services.*.ports[...]` in this phase. GitHub Actions supports random
  host-port assignment, but using it would require extra env plumbing and is a
  broader CI behavior change. The least-surprise fix is parity with the existing
  `ci.yml` and `ci-verify.yml` `5432:5432` mappings.
- **D-09:** Phase 35 should treat the REL-03 port-fix portion as already
  satisfied by Phase 34, then verify it before release with a zero-hit
  `grep "55432" .github/workflows/post-publish-smoke.yml` check and the
  extended policy test.

#### Dedicated Docker DX doc-contract ownership
- **D-10:** Create `test/scoria/docker_dx_doc_contract_test.exs` with
  `defmodule Scoria.DockerDxDocContractTest do` and
  `use ExUnit.Case, async: true`. The test must be file-read-only and safe under
  `mix test --no-start`.
- **D-11:** Move or narrow the existing broad Docker DX guide assertions from
  `test/scoria/ci_policy_contract_test.exs` into the new dedicated doc-contract
  file. Keep `ci_policy_contract_test.exs` focused on CI policy, Compose,
  Makefile, Dockerfile structure, and the post-publish workflow port guard.
- **D-12:** Do not introduce a shared helper module for this short contract.
  Table-driven local helpers inside `docker_dx_doc_contract_test.exs` are fine;
  production modules or `test/support` indirection would over-abstract the
  failure surface.
- **D-13:** Update the existing policy-lane command in
  `.github/workflows/ci-verify.yml` by appending
  `test/scoria/docker_dx_doc_contract_test.exs` to the explicit file list. Do
  not add a new job, step, service, matrix lane, or required check.

#### Canonical Docker DX doc tokens
- **D-14:** The dedicated doc contract must pin the DOCS-03 minimum tokens in
  `docs/docker_dev_dx.md`: `make up`, `make dev`, `4799` or
  `http://localhost:4799/scoria`, `make nuke`, `ANTHROPIC_API_KEY`, and at
  least one of `direnv` or `1Password`.
- **D-15:** Prefer table-driven assertions with explicit failure messages that
  name the lost contract and the likely repair. Do not assert section headings,
  table row order, or exact prose beyond load-bearing fragments.
- **D-16:** Keep the test reader-oriented. This is not a prose linter; it pins
  the commands, URLs, and nouns a maintainer needs during the local Docker/native
  dev loop.

#### Stale `localhost:4000` guard strictness
- **D-17:** Use a context-aware stale URL guard, not only an exact-string
  refute. Hard-ban browser-start variants such as:
  - `http://localhost:4000`
  - `http://localhost:4000/scoria`
  - `visit localhost:4000`
  - `open localhost:4000`
  - `curl http://localhost:4000/scoria`
  - fixed fallback copy such as `http://127.0.0.1:4000/scoria`
- **D-18:** Do not ban all `:4000` references. `docs/docker_dev_dx.md` is
  allowed to mention Docker-internal mechanics when they are explicitly
  qualified: Docker-internal container port, container listener, Traefik service
  target, `loadbalancer.server.port=4000`, `web:4000`, `127.0.0.1::4000`,
  `docker compose port web 4000`, CI self-test, or ephemeral loopback fallback.
- **D-19:** Implement the guard as two layers:
  1. a direct refute for `localhost:4000` browser-start URL forms; and
  2. a lightweight scan of doc paragraphs or lines containing `4000`, requiring
     one of the allowed qualifiers above.
  Failure text should tell the maintainer to use Docker
  `make up`/`make url`/`http://<instance>.localhost/scoria` or native
  `make dev`/`http://localhost:4799/scoria`.

#### Cache-table doc strings
- **D-20:** In the same `docker_dx_doc_contract_test.exs` file, add a separate
  test block that pins the Phase 31 cache-table load-bearing strings:
  `mix deps.get`, `mix deps.compile`, and `app compile only`.
- **D-21:** This string guard complements, but does not replace, the existing
  structural Dockerfile guard in `ci_policy_contract_test.exs`. The doc test
  guards the reader-facing mental model; the CI policy test guards Dockerfile
  COPY/cache structure.
- **D-22:** Do not split the cache strings into another file. One dedicated
  Docker DX doc-contract file keeps docs drift failures discoverable and avoids
  policy-lane file-list sprawl.

#### Voice and engineering posture
- **D-23:** Follow the current `brandbook/brand-book.md` voice: calm, exact,
  useful. Failure messages and docs contract names should say what drifted and
  what to do next. Avoid hype, vague "magic" wording, or shaming prior drift.
- **D-24:** Keep the implementation boring: file reads, simple regex/string
  checks, `async: true`, no app start, no DB, no Docker daemon, no network, no
  CI topology changes.

#### Verification recommendations
- **D-25:** Minimum local verification after implementation:
  ```bash
  SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors \
    test/scoria/docker_dx_doc_contract_test.exs \
    test/scoria/ci_policy_contract_test.exs \
    test/scoria/verification_lanes_test.exs \
    test/scoria/adoption_surface_test.exs
  ```
- **D-26:** Also run focused static checks:
  ```bash
  rg -n "55432" .github/workflows/post-publish-smoke.yml
  rg -n "localhost:4000|127\\.0\\.0\\.1:4000" docs/docker_dev_dx.md
  ```
  Expected: zero hits in the first command; zero stale browser-start hits in the
  second, while qualified `:4000` mechanics may remain.

### the agent's Discretion

- Exact test names, helper names, and regex implementation details may be
  refined as long as D-05 through D-26 hold.
- The planner may decide whether to fully remove the old Docker DX guide test
  from `ci_policy_contract_test.exs` or leave a non-duplicative residual check
  there if it guards `.env.example` or another non-doc policy surface. Do not
  leave duplicated canonical doc-token assertions in both files.

### Deferred Ideas (OUT OF SCOPE)

- **Phase 35 release publish and registry smoke:** Phase 34 pre-fixes the known
  post-publish port flake, but publishing `0.1.2`, running `mix docs`, merging
  the release-please PR, checking Hex, and running the live registry smoke all
  stay in Phase 35.
- **Fleet-wide sibling-repo convergence:** remains FLEET-01 and out of v3.2
  implementation scope. Phase 34 guards Scoria as the reference implementation
  only.
- **Fleet-wide `make nuke-all`:** remains FLEET-02 and out of scope due to high
  blast radius.
- **CI cache-key mislabel cleanup:** still a post-ship cleanup item, not part of
  Docker DX doc drift or post-publish port scanning.
- **Approval toast legibility:** remains a focused UI polish todo and should not
  distract this infra/docs phase.

#### Reviewed Todos (not folded)
- `ci-policy-job-cache-key-mislabel.md` - reviewed because it matched policy,
  test, mix, and key terms; deferred because it concerns CI cache naming cleanup
  and is not part of Phase 34's Docker DX drift guard.
- `2026-06-18-make-approval-toasts-legible.md` - reviewed because it matched
  `make`; deferred because it is UI polish and unrelated to this policy-lane
  docs/CI phase.
- `docker-dx-fleet-hardening.md` - non-doc fleet convergence and fleet-wide
  cleanup items remain deferred; only Scoria-local doc-drift guard was folded.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-03 | A policy-lane `docker_dx_doc_contract_test.exs` asserts canonical commands/URLs are present in `docs/docker_dev_dx.md` and `localhost:4000` as dev-start is absent. | Implement a DB-free, app-free ExUnit file-read contract; wire it into the existing `ci-verify.yml` policy command; make stale `:4000` checking context-aware so Docker-internal `4000` remains allowed. [VERIFIED: `.planning/REQUIREMENTS.md` DOCS-03; `.planning/ROADMAP.md` Phase 34] |
</phase_requirements>

## Summary

Phase 34 is a narrow policy-lane hardening phase, not a Docker, release, or CI-topology redesign. The current `ci-verify.yml` policy job has no Postgres service and runs an explicit `mix test --no-start --warnings-as-errors` file list; the planner should append `test/scoria/docker_dx_doc_contract_test.exs` to that command and avoid adding jobs, services, matrices, dependencies, or protected-check name changes. [VERIFIED: `.github/workflows/ci-verify.yml:15-56`; VERIFIED: `34-CONTEXT.md` D-13/D-24]

The existing Docker DX guide already contains the canonical material to pin: `make up`, `make dev`, native `http://localhost:4799/scoria`, `make nuke`, cache-table strings, and the direnv/1Password/`ANTHROPIC_API_KEY` secret flow. Its remaining `:4000` hits are qualified mechanics, not stale browser-start guidance: the top-level anti-footgun mention, container-port explanation, and `127.0.0.1::4000` ephemeral fallback example. [VERIFIED: `docs/docker_dev_dx.md:15-24`, `docs/docker_dev_dx.md:40-43`, `docs/docker_dev_dx.md:121-129`, `docs/docker_dev_dx.md:237-242`, `docs/docker_dev_dx.md:244-296`, `docs/docker_dev_dx.md:5`, `docs/docker_dev_dx.md:58-62`, `docs/docker_dev_dx.md:371-380`]

The existing FLAKE-01 port guard scans `.github/workflows/ci.yml` and `.github/workflows/ci-verify.yml`, but not `.github/workflows/post-publish-smoke.yml`. The post-publish workflow currently has `55432:5432` and `SCORIA_DB_PORT: 55432`, which are the two lines Phase 34 should change to `5432`. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:210-255`; VERIFIED: `.github/workflows/post-publish-smoke.yml:51-62`]

**Primary recommendation:** Create one dedicated doc-contract test file, append it to the existing policy-lane file list, extend the existing port-bind scanner to include `post-publish-smoke.yml`, and apply only the two-line post-publish `55432` to `5432` fix. [VERIFIED: `34-CONTEXT.md` D-05/D-06/D-10/D-13]

## Project Constraints

| Constraint | Status | Source |
|------------|--------|--------|
| `AGENTS.md` project instructions | None found in repo root. | [VERIFIED: `test -f AGENTS.md`] |
| Project skills | No `.codex/skills` or `.agents/skills` directories found in this repo. | [VERIFIED: `find .codex/skills .agents/skills`] |
| Knowledge graph | No `.planning/graphs/graph.json` exists, so graph context was unavailable. | [VERIFIED: `ls .planning/graphs/graph.json`] |
| Worktree state | Worktree is dirty, including Docker/DX files and `test/scoria/ci_policy_contract_test.exs`; implementers must preserve unrelated user changes. | [VERIFIED: `git status --short`] |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Docker DX documentation drift guard | Test / CI policy lane | Documentation | The guard reads `docs/docker_dev_dx.md` directly and fails in the policy lane before app-starting tests. [VERIFIED: `ci-verify.yml:53-56`; VERIFIED: `34-CONTEXT.md` D-10/D-13] |
| Stale browser-start URL classification | Test / CI policy lane | Docker docs | The test owns classification of forbidden browser-start strings while allowing documented Docker-internal `4000` mechanics. [VERIFIED: `34-CONTEXT.md` D-17/D-18/D-19] |
| Post-publish service-port policy | Test / CI policy lane | GitHub Actions workflow | `ci_policy_contract_test.exs` already owns FLAKE-01 fixed-host-port enforcement; Phase 34 should add the post-publish workflow to that same scanner. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:210-255`; VERIFIED: `34-CONTEXT.md` D-05/D-06] |
| Release publishing and live registry smoke | GitHub Actions release workflow | Phase 35 planning | Phase 34 pre-fixes and guards the port; publishing `0.1.2` and running the live smoke remain out of scope. [VERIFIED: `34-CONTEXT.md` Deferred Ideas; VERIFIED: `.planning/ROADMAP.md` Phase 35] |

## Current Relevant State

| Surface | Evidence | Planning Implication |
|---------|----------|----------------------|
| Policy lane command | `ci-verify.yml` runs `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`. [VERIFIED: `.github/workflows/ci-verify.yml:53-56`] | Append the new file to the same command; no new job or service. |
| Policy job has no DB service | `policy` job steps contain no `services:` block and the existing contract asserts policy/build/summary must not have services. [VERIFIED: `.github/workflows/ci-verify.yml:15-56`; VERIFIED: `test/scoria/ci_policy_contract_test.exs:204-207`] | New test must be pure file reads and safe under `--no-start`. |
| Existing Docker DX guide assertions are broad | `ci_policy_contract_test.exs` currently has a broad "Docker DX guide documents the collision-resistant workflow" block asserting many doc tokens and `env_example`. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:790-820`] | Move/narrow doc-only token assertions into the new file; keep only non-duplicative non-doc checks in `ci_policy_contract_test.exs`. |
| Dockerfile/Compose guards already exist | Current policy tests pin Dockerfile COPY order, BuildKit caches, Compose ephemeral fallback, Traefik labels, and critique secret handling. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:652-720`] | Do not duplicate Dockerfile/Compose structural assertions in the new doc-contract file. |
| Docker DX doc canonical tokens exist | `docs/docker_dev_dx.md` contains the TL;DR commands, native `4799` URL, cache-table strings, and secrets flow. [VERIFIED: `docs/docker_dev_dx.md:15-24`, `docs/docker_dev_dx.md:40-43`, `docs/docker_dev_dx.md:237-242`, `docs/docker_dev_dx.md:244-296`] | Assertions can be simple string checks with precise failure text. |
| Allowed `:4000` mechanics exist | `docs/docker_dev_dx.md` contains qualified `:4000` mechanics and a `127.0.0.1::4000` Compose example. [VERIFIED: `docs/docker_dev_dx.md:58-62`, `docs/docker_dev_dx.md:371-380`] | Do not use a blanket `refute docs =~ ":4000"`. |
| Post-publish workflow still has old port | `post-publish-smoke.yml` maps `55432:5432` and sets `SCORIA_DB_PORT: 55432`. [VERIFIED: `.github/workflows/post-publish-smoke.yml:51-62`] | Phase 34 must fix both lines before enabling the guard. |
| `ci.yml` and `ci-verify.yml` use low fixed host ports | Existing CI service blocks use `5432:5432` and `SCORIA_DB_PORT: 5432`. [VERIFIED: `.github/workflows/ci.yml:41-52`; VERIFIED: `.github/workflows/ci-verify.yml:114-125`, `.github/workflows/ci-verify.yml:198-209`, `.github/workflows/ci-verify.yml:263-274`, `.github/workflows/ci-verify.yml:323-334`, `.github/workflows/ci-verify.yml:392-403`] | The post-publish fix should match this shape for least surprise. |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | Project targets Elixir `~> 1.19`; local Mix is `1.19.5`. | Runs explicit ExUnit policy files with `--no-start` and warnings-as-errors. | Mix docs support explicit file paths and `--no-start`; repo already uses this in CI. [VERIFIED: `mix.exs:11`; VERIFIED: `mix --version`; CITED: https://mix.hexdocs.pm/Mix.Tasks.Test.html] |
| ExUnit | Bundled with Elixir `1.19.5`. | Implements `use ExUnit.Case, async: true` file-read-only contract tests. | Existing policy tests use async ExUnit and file reads. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:1-2`; CITED: https://mix.hexdocs.pm/Mix.Tasks.Test.html] |
| GitHub Actions YAML | Existing workflows. | Hosts the policy lane and post-publish smoke workflow. | Existing reusable CI SSOT must remain byte-shape stable except for explicit file-list and two-line port fix. [VERIFIED: `.github/workflows/ci-verify.yml:1-56`; VERIFIED: `.github/workflows/post-publish-smoke.yml:1-130`] |
| ripgrep | Local `15.1.0`. | Focused static verification after implementation. | Phase context explicitly recommends `rg` checks for `55432` and stale browser-start URLs. [VERIFIED: `rg --version`; VERIFIED: `34-CONTEXT.md` D-26] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Docker | Local `29.5.2`. | Context only; no Docker daemon use is required for Phase 34 implementation or validation. | Use only to understand Compose semantics if debugging, not in the phase's required verification. [VERIFIED: `docker --version`; VERIFIED: `34-CONTEXT.md` D-24] |
| Git | Local `2.41.0`. | Inspect diffs and avoid overwriting unrelated dirty-worktree edits. | Use before editing overlapping files. [VERIFIED: `git --version`; VERIFIED: `git status --short`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Fixed `5432:5432` in post-publish workflow | Random host port plus `${{ job.services.postgres.ports[5432] }}` | GitHub Actions supports random host ports, but Phase 34 locked it out because env plumbing would broaden behavior; use `5432:5432` parity with current CI. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts; VERIFIED: `34-CONTEXT.md` D-08] |
| Dedicated doc-contract file | Keep all doc assertions in `ci_policy_contract_test.exs` | Existing omnibus test is already broad; locked decision says dedicated ownership makes doc drift failures discoverable while keeping CI policy focused. [VERIFIED: `34-CONTEXT.md` D-10/D-11] |
| Blanket `:4000` ban | Context-aware `4000` line/paragraph classification | Blanket ban would fail correct Docker-internal mechanics such as `loadbalancer.server.port=4000` and `127.0.0.1::4000`. [VERIFIED: `docs/docker_dev_dx.md:371-380`; VERIFIED: `34-CONTEXT.md` D-18] |

**Installation:** No external package installation is required. [VERIFIED: `34-CONTEXT.md` D-24]

## Package Legitimacy Audit

No external packages are introduced by this phase, so the package legitimacy gate is not applicable. [VERIFIED: `34-CONTEXT.md` D-24]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | n/a | n/a | n/a | n/a | n/a | No install |

**Packages removed due to [SLOP] verdict:** none.  
**Packages flagged as suspicious [SUS]:** none.  

## Architecture Patterns

### System Architecture Diagram

```text
Phase 34 implementation input
  |
  v
Repo file reads only
  |
  +--> docs/docker_dev_dx.md
  |      |
  |      +--> required token assertions
  |      +--> stale browser-start :4000 scanner
  |      +--> cache-table string assertions
  |
  +--> .github/workflows/{ci.yml,ci-verify.yml,post-publish-smoke.yml}
         |
         +--> job_blocks/1 extraction
         +--> postgres block filtering
         +--> host:container port extraction
         +--> host_port < 32768 assertion
  |
  v
Existing policy lane
  |
  v
mix test --no-start --warnings-as-errors explicit file list
  |
  v
No app start, no DB, no Docker daemon, no network
```

This diagram is implementation guidance for a file-read-only policy lane and reflects the existing CI command plus locked Phase 34 decisions. [VERIFIED: `.github/workflows/ci-verify.yml:53-56`; VERIFIED: `34-CONTEXT.md` D-10/D-24]

### Recommended Project Structure

```text
test/scoria/
├── docker_dx_doc_contract_test.exs   # new doc-token and stale-URL guard
├── ci_policy_contract_test.exs       # extend existing CI workflow port scan
├── verification_lanes_test.exs       # unchanged lane-order contract
└── adoption_surface_test.exs         # unchanged existing policy-lane file
```

The new file belongs under `test/scoria/` because the current policy-lane file list and existing contract tests live there. [VERIFIED: `.github/workflows/ci-verify.yml:56`; VERIFIED: `test/scoria/ci_policy_contract_test.exs:1`; VERIFIED: `test/scoria/verification_lanes_test.exs:1`; VERIFIED: `test/scoria/adoption_surface_test.exs:1`]

### Pattern 1: Dedicated File-Read Contract

**What:** Add `Scoria.DockerDxDocContractTest` with `use ExUnit.Case, async: true`, local helper functions only, and direct `File.read!("docs/docker_dev_dx.md")`. [VERIFIED: `34-CONTEXT.md` D-10/D-12]

**When to use:** Use it for doc-token, stale browser-start URL, and cache-table string assertions only; do not test Compose/Dockerfile structure here. [VERIFIED: `34-CONTEXT.md` D-20/D-21]

**Example:**

```elixir
defmodule Scoria.DockerDxDocContractTest do
  use ExUnit.Case, async: true

  @doc_path "docs/docker_dev_dx.md"

  test "Docker DX guide keeps canonical local dev commands visible" do
    docs = File.read!(@doc_path)

    for {fragment, reason} <- [
          {"make up", "Docker daily loop command"},
          {"make dev", "native host command"},
          {"http://localhost:4799/scoria", "native host URL"},
          {"make nuke", "scoped cleanup command"},
          {"ANTHROPIC_API_KEY", "critique secret variable"}
        ] do
      assert docs =~ fragment,
             "docs/docker_dev_dx.md lost #{reason} (#{inspect(fragment)}); " <>
               "restore the Docker/native dev-DX contract or update Phase 34 rationale"
    end

    assert docs =~ "direnv" or docs =~ "1Password",
           "docs/docker_dev_dx.md must keep the process-scoped secrets setup visible"
  end
end
```

The example uses only locked fragments and existing ExUnit file-read style. [VERIFIED: `34-CONTEXT.md` D-14/D-15; VERIFIED: `test/scoria/ci_policy_contract_test.exs:790-820`]

### Pattern 2: Context-Aware `4000` Guard

**What:** Use a hard refute for browser-start URL patterns and a second pass over `4000` lines or paragraphs requiring allowed qualifier text. [VERIFIED: `34-CONTEXT.md` D-17/D-19]

**When to use:** Use this only against `docs/docker_dev_dx.md`, not the whole repo; `ci.yml` still uses `PORT: 4000` for its e2e app boot and Compose still uses container `4000`. [VERIFIED: `.github/workflows/ci.yml:49-56`; VERIFIED: `compose.yml:66-70`, `compose.yml:86-89`; VERIFIED: `34-CONTEXT.md` D-18]

**Example:**

```elixir
test "Docker DX guide does not reintroduce localhost:4000 as a browser start URL" do
  docs = File.read!(@doc_path)

  refute docs =~ ~r{\bhttps?://localhost:4000(?:/scoria)?\b},
         "Use Docker `make url` / `http://<instance>.localhost/scoria` or native `make dev` / `http://localhost:4799/scoria`; localhost:4000 is not the Scoria dev-start URL."

  refute docs =~ ~r{\b(open|visit|browse|browser|go to|curl)\b[^\n]*(?:localhost|127\.0\.0\.1):4000\b}i,
         "Stale browser-start copy points at :4000; use the Traefik route or native :4799 URL."

  for line <- String.split(docs, "\n"), String.contains?(line, "4000") do
    assert qualified_4000_mechanic?(line),
           "Unqualified :4000 mention in docs/docker_dev_dx.md: #{line}\n" <>
             "Qualify it as Docker-internal, Traefik target, web:4000, 127.0.0.1::4000, docker compose port web 4000, CI self-test, or ephemeral fallback."
  end
end
```

Use local helper `qualified_4000_mechanic?/1`; do not add `test/support` indirection. [VERIFIED: `34-CONTEXT.md` D-12/D-18]

### Pattern 3: Existing Port Scanner Extension

**What:** Add `@post_publish_smoke ".github/workflows/post-publish-smoke.yml"`, read it inside the existing FLAKE-01 test, extract its postgres job block with the existing `job_blocks/1`, and combine it with the existing `ci.yml`/`ci-verify.yml` postgres blocks. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:210-255`; VERIFIED: `34-CONTEXT.md` D-05/D-06]

**When to use:** Use after the two-line post-publish `55432` fix lands; do not add an allowlist for this workflow. [VERIFIED: `34-CONTEXT.md` D-05/D-07]

**Example:**

```elixir
post_publish = File.read!(@post_publish_smoke)

post_publish_postgres =
  job_blocks(post_publish)
  |> Enum.map(fn {job, body} -> {"post-publish-smoke.yml:#{job}", body} end)
  |> Enum.filter(fn {_name, body} -> body =~ "postgres:" end)

postgres_blocks = Map.new(verify_postgres ++ entry_postgres ++ post_publish_postgres)

assert map_size(postgres_blocks) >= 6,
       "expected >= 6 postgres jobs across ci.yml + ci-verify.yml + post-publish-smoke.yml; regex may be broken"
```

Prefixing the job key with the file name avoids silent overwrite if multiple workflows use the same job id such as `smoke`. [VERIFIED: `.github/workflows/post-publish-smoke.yml:38-45`; VERIFIED: `test/scoria/ci_policy_contract_test.exs:222`]

### Anti-Patterns to Avoid

- **Adding a new CI job/check/service:** Phase 34 only appends a file to the existing policy-lane command. [VERIFIED: `34-CONTEXT.md` D-13/D-24]
- **Starting the app or touching the database from the doc contract:** `mix test --no-start` is load-bearing and policy has no service block. [VERIFIED: `.github/workflows/ci-verify.yml:15-56`; CITED: https://mix.hexdocs.pm/Mix.Tasks.Test.html]
- **Banning every `:4000` string:** Docker container listener, Traefik service target, `web:4000`, and `127.0.0.1::4000` are valid mechanics. [VERIFIED: `compose.yml:66-70`, `compose.yml:86-89`, `compose.yml:105`, `compose.yml:144`; VERIFIED: `34-CONTEXT.md` D-18]
- **Duplicating doc-token assertions in both test files:** Move or narrow broad guide assertions so failures have one owner. [VERIFIED: `34-CONTEXT.md` D-11]
- **Changing `CI / ci-gate` or `VerificationLanes.closeout_order/0`:** These are explicit milestone constraints and not part of this phase. [VERIFIED: `.planning/STATE.md` Recent decisions; VERIFIED: `.planning/PROJECT.md:38-40`; VERIFIED: `test/scoria/verification_lanes_test.exs:30-44`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML parsing for this narrow scan | A new YAML parser/dependency | Existing `job_blocks/1` plus existing regex scanner | Current tests already parse top-level jobs and fixed host binds; adding a parser would introduce dependency and behavior churn. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:842-872`] |
| Shared contract helpers | `test/support` or production helper module | Local private helpers in the new test file | Locked decision says the contract is short and should not be over-abstracted. [VERIFIED: `34-CONTEXT.md` D-12] |
| Prose linting | Broad Markdown style checker | Load-bearing fragments and context-aware stale URL rules | Phase goal is command/URL truth, not copy style. [VERIFIED: `34-CONTEXT.md` D-15/D-16] |
| New CI lane | Separate docs/policy workflow job | Existing policy lane explicit file list | Protects branch-check stability and avoids CI topology changes. [VERIFIED: `.github/workflows/ci-verify.yml:53-56`; VERIFIED: `34-CONTEXT.md` D-13] |

**Key insight:** This phase should add mechanical guardrails around already-decided truth; it should not create new abstractions, dependencies, or workflow topology. [VERIFIED: `34-CONTEXT.md` D-23/D-24]

## Docker DX Doc Contract Design

### Required Assertions

| Test Block | Required Checks | Notes |
|------------|-----------------|-------|
| Canonical commands and URL | Assert `make up`, `make dev`, native `4799` or `http://localhost:4799/scoria`, `make nuke`, `ANTHROPIC_API_KEY`, and `direnv` or `1Password`. | These are DOCS-03 minimum tokens plus Phase 32 secrets truth. [VERIFIED: `34-CONTEXT.md` D-14; VERIFIED: `docs/docker_dev_dx.md:15-24`, `docs/docker_dev_dx.md:40-43`, `docs/docker_dev_dx.md:244-296`] |
| Stale browser-start URL | Refute `http://localhost:4000`, `http://localhost:4000/scoria`, command-context `open/visit/curl ... localhost:4000`, and fixed `127.0.0.1:4000` fallback copy. | Do not ban qualified Docker mechanics. [VERIFIED: `34-CONTEXT.md` D-17/D-18/D-19] |
| Qualified `4000` mechanics | For each `4000` line/paragraph, require qualifiers such as `Docker-internal`, `container`, `Traefik`, `service target`, `loadbalancer.server.port=4000`, `web:4000`, `127.0.0.1::4000`, `docker compose port web 4000`, `CI`, or `ephemeral fallback`. | Current doc has `:4000` only in qualified contexts. [VERIFIED: `rg -n "localhost:4000|127\\.0\\.0\\.1:4000|:4000" docs/docker_dev_dx.md`] |
| Cache-table strings | Assert `mix deps.get`, `mix deps.compile`, and `app compile only`. | This guards reader-facing Phase 31 mental model; Dockerfile structure remains in `ci_policy_contract_test.exs`. [VERIFIED: `34-CONTEXT.md` D-20/D-21; VERIFIED: `docs/docker_dev_dx.md:237-242`; VERIFIED: `test/scoria/ci_policy_contract_test.exs:652-671`] |

### Allowed vs Stale `:4000`

| Classification | Examples | Test Behavior |
|----------------|----------|---------------|
| Stale browser-start URL | `open http://localhost:4000/scoria`, `visit localhost:4000`, `curl http://localhost:4000/scoria`, `http://127.0.0.1:4000/scoria` as fixed fallback | Hard fail with repair text naming Docker `make up`/`make url`/Traefik route or native `make dev`/`:4799`. [VERIFIED: `34-CONTEXT.md` D-17/D-19] |
| Allowed Docker mechanics | `Docker-internal container port 4000`, `Traefik service target`, `loadbalancer.server.port=4000`, `web:4000`, `127.0.0.1::4000`, `docker compose port web 4000`, `ephemeral loopback fallback` | Allow only when qualifier appears on the same line/paragraph. [VERIFIED: `34-CONTEXT.md` D-18] |
| Current doc hits | Line 5 "no `:4000` juggling", line 60 "Container `:4000`", line 372 `127.0.0.1::4000` | Should pass a context-aware guard. [VERIFIED: `rg -n "localhost:4000|127\\.0\\.0\\.1:4000|:4000" docs/docker_dev_dx.md`] |

### Failure Message Style

Failure messages should name the drifted contract and the likely repair, using calm, exact, useful wording. [VERIFIED: `brandbook/brand-book.md:421-458`; VERIFIED: `34-CONTEXT.md` D-23]

Recommended shape:

```elixir
assert docs =~ fragment,
       "docs/docker_dev_dx.md lost #{reason} (#{inspect(fragment)}); " <>
         "restore the Docker/native dev-DX contract or update this guard with a Phase 34 rationale"
```

This mirrors existing contract-test explicitness while adding a next action. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:243-252`; VERIFIED: `brandbook/brand-book.md:430-436`]

## CI Policy Contract Extension Guidance

1. Add `@post_publish_smoke ".github/workflows/post-publish-smoke.yml"` beside existing workflow path attributes. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:6-14`]
2. In the existing FLAKE-01 test, read `post_publish = File.read!(@post_publish_smoke)`. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:210-213`]
3. Build `post_publish_postgres` using existing `job_blocks/1`, filter bodies containing `postgres:`, and prefix keys with `post-publish-smoke.yml:` before combining with other workflow blocks. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:214-222`; VERIFIED: `.github/workflows/post-publish-smoke.yml:38-52`]
4. Raise the non-empty guard from `>= 5` to `>= 6` because the scanner should cover e2e plus four `ci-verify.yml` Postgres jobs plus post-publish smoke. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:224-227`; VERIFIED: `.github/workflows/ci.yml:34-42`; VERIFIED: `.github/workflows/ci-verify.yml:107-115`, `.github/workflows/ci-verify.yml:191-199`, `.github/workflows/ci-verify.yml:256-264`, `.github/workflows/ci-verify.yml:316-324`, `.github/workflows/ci-verify.yml:385-393`; VERIFIED: `.github/workflows/post-publish-smoke.yml:44-52`]
5. Keep the existing `Regex.scan(~r/-\s*["']?(\d+):\d+(?:\/tcp)?["']?/, body)` behavior unless implementation evidence shows it fails on the current YAML shape. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:233-238`]
6. Fix `.github/workflows/post-publish-smoke.yml` by changing only line 52 to `5432:5432` and line 62 to `SCORIA_DB_PORT: 5432`. [VERIFIED: `.github/workflows/post-publish-smoke.yml:51-62`; VERIFIED: `34-CONTEXT.md` D-06]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fixed CI Postgres host port `55432` | Fixed low host port `5432` in CI service containers | v3.1 Phase 27; Phase 34 extends to post-publish | Avoids Linux ephemeral-range collision while preserving simple localhost runner access. [VERIFIED: `.planning/PROJECT.md:119`; CITED: https://docs.kernel.org/networking/ip-sysctl.html; CITED: https://docs.github.com/en/actions/tutorials/use-containerized-services/create-postgresql-service-containers] |
| Broad Docker DX assertions inside `ci_policy_contract_test.exs` | Dedicated `docker_dx_doc_contract_test.exs` for doc fragments and stale URL semantics | Phase 34 planned | Keeps CI policy and docs drift failures separated without adding a CI job. [VERIFIED: `34-CONTEXT.md` D-10/D-11/D-13] |
| Raw Phoenix `localhost:4000` dev-start copy | Docker `make up`/`make url` Traefik route or native `make dev`/`localhost:4799` | v3.2 Phases 29-33 | Prevents verification-copy drift in multi-instance local development. [VERIFIED: `.planning/phases/33-doc-restructure-verification-copy-correction/33-CONTEXT.md` D-06-D-11] |

**Deprecated/outdated:** `http://localhost:4000/scoria` as a Scoria browser dev-start URL is stale in docs and planning copy; only qualified Docker-internal or CI mechanics may keep `4000`. [VERIFIED: `.planning/phases/33-doc-restructure-verification-copy-correction/33-CONTEXT.md:56-58`; VERIFIED: `34-CONTEXT.md` D-17/D-18]

## Common Pitfalls

### Pitfall 1: Blanket `:4000` Ban

**What goes wrong:** A test refutes all `:4000` strings and fails correct Docker-internal docs or pressures implementers to change container wiring. [VERIFIED: `compose.yml:66-70`, `compose.yml:86-89`; VERIFIED: `34-CONTEXT.md` D-18]

**Why it happens:** Browser-start copy and container listener mechanics both mention port `4000`. [VERIFIED: `.planning/phases/29-makefile-hardening/29-CONTEXT.md` D-08/D-10]

**How to avoid:** Hard-ban browser-start forms and separately require qualifiers for remaining `4000` mentions. [VERIFIED: `34-CONTEXT.md` D-17/D-19]

**Warning signs:** A proposed assertion looks like `refute docs =~ ":4000"` or includes `compose.yml` in the stale URL scan. [VERIFIED: `34-CONTEXT.md` D-18]

### Pitfall 2: App Start or DB Access in Policy Lane

**What goes wrong:** A docs guard starts `Scoria.Application`, reaches Oban/Ecto, and fails under `--no-start` or without Postgres. [VERIFIED: `.github/workflows/ci-verify.yml:15-56`; VERIFIED: `test/scoria/ci_policy_contract_test.exs:190-207`]

**Why it happens:** Copying patterns from app-booting tests instead of existing file-read policy contracts. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:24-33`, `test/scoria/ci_policy_contract_test.exs:652-820`]

**How to avoid:** Use only `File.read!`, `String`, and `Regex`; no aliases to application modules except already-existing lane contract tests. [VERIFIED: `34-CONTEXT.md` D-10/D-24]

**Warning signs:** `Repo`, `Application.ensure_all_started`, Docker commands, `System.cmd("docker", ...)`, or network calls in the new test file. [VERIFIED: `34-CONTEXT.md` D-24]

### Pitfall 3: Duplicated Doc Assertions

**What goes wrong:** The same doc-token failure appears in both `ci_policy_contract_test.exs` and `docker_dx_doc_contract_test.exs`, making ownership unclear. [VERIFIED: `34-CONTEXT.md` D-11]

**Why it happens:** The existing broad Docker DX guide test already asserts many doc fragments. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:790-820`]

**How to avoid:** Move doc-only canonical token assertions to the new file; leave only non-doc or non-duplicative checks in `ci_policy_contract_test.exs`. [VERIFIED: `34-CONTEXT.md` D-11 and Claude's Discretion]

**Warning signs:** Both files assert `make dev`, `make nuke`, `ANTHROPIC_API_KEY`, or `http://localhost:4799/scoria`. [VERIFIED: `34-CONTEXT.md` D-14]

### Pitfall 4: CI Topology Drift

**What goes wrong:** A docs guard phase adds a new job, changes `needs`, or renames the required umbrella check. [VERIFIED: `.planning/STATE.md` Recent decisions; VERIFIED: `.github/workflows/ci.yml:127-147`]

**Why it happens:** Treating a new contract test as a new lane instead of another explicit file in the policy command. [VERIFIED: `.github/workflows/ci-verify.yml:53-56`]

**How to avoid:** Only append the new file to the existing command. [VERIFIED: `34-CONTEXT.md` D-13]

**Warning signs:** Diff touches `jobs:`, adds `services:` under `policy`, changes `verify-summary.needs`, or edits `ci-gate`. [VERIFIED: `.github/workflows/ci-verify.yml:14-56`, `.github/workflows/ci-verify.yml:447-464`; VERIFIED: `.github/workflows/ci.yml:127-147`]

### Pitfall 5: Stale Phase 35 Overlap

**What goes wrong:** Phase 34 leaves the post-publish workflow red for Phase 35 or performs release publishing work early. [VERIFIED: `34-CONTEXT.md` D-05/D-07 and Deferred Ideas]

**Why it happens:** REL-03 spans both a workflow fix and release verification, but only the workflow fix belongs here. [VERIFIED: `.planning/REQUIREMENTS.md` REL-03; VERIFIED: `.planning/ROADMAP.md` Phase 35]

**How to avoid:** Fix and guard `post-publish-smoke.yml`; leave `mix docs`, release PR merge, Hex checks, and live smoke execution to Phase 35. [VERIFIED: `34-CONTEXT.md` D-09 and Deferred Ideas]

**Warning signs:** Plan tasks mention publishing `0.1.2`, merging PR #3, or running `mix scoria.post_publish_smoke` as the Phase 34 deliverable. [VERIFIED: `34-CONTEXT.md` Deferred Ideas]

## Code Examples

### Policy-Lane File List

```yaml
# Source: .github/workflows/ci-verify.yml:53-56
- name: Verify lane-contract tests with warnings as errors
  env:
    SCORIA_LANE_CONTRACT_ONLY: "true"
  run: mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/docker_dx_doc_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs
```

The only intended YAML edit in `ci-verify.yml` is appending `test/scoria/docker_dx_doc_contract_test.exs` to this run line. [VERIFIED: `.github/workflows/ci-verify.yml:53-56`; VERIFIED: `34-CONTEXT.md` D-13]

### Post-Publish Port Fix

```yaml
# Source: .github/workflows/post-publish-smoke.yml:51-62
ports:
  - 5432:5432

env:
  SCORIA_DB_PORT: 5432
```

This mirrors existing CI service-container shape and avoids the default Linux ephemeral range. [VERIFIED: `.github/workflows/ci.yml:41-52`; VERIFIED: `.github/workflows/ci-verify.yml:114-125`; CITED: https://docs.kernel.org/networking/ip-sysctl.html]

### Existing Port Scanner Pattern

```elixir
# Source: test/scoria/ci_policy_contract_test.exs:238-252
port_bindings = Regex.scan(~r/-\s*["']?(\d+):\d+(?:\/tcp)?["']?/, body)

assert port_bindings != [],
       "Job #{job}: no host:container port binding extracted — the FLAKE-01 " <>
         "ephemeral-port guard must not pass vacuously (regex broken or unknown form)"

for [_full, host_port_str] <- port_bindings do
  host_port = String.to_integer(host_port_str)

  assert host_port < @ephemeral_range_min,
         "Job #{job}: host port #{host_port} is in the ephemeral range (>= 32768) — " <>
           "use a port below 32768 to prevent kernel bind conflicts on GitHub runners"
end
```

Reuse this scanner and add `post-publish-smoke.yml` as another workflow input. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:210-255`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit policy tests | yes | 1.19.5 local | Use project toolchain via CI if local OTP mismatch matters. [VERIFIED: `elixir --version`; VERIFIED: `.tool-versions:1-2`] |
| Mix | Validation commands | yes | 1.19.5 local | None needed. [VERIFIED: `mix --version`] |
| ripgrep | Static verification | yes | 15.1.0 | `grep -R` if unavailable. [VERIFIED: `rg --version`] |
| git | Dirty-worktree/diff inspection | yes | 2.41.0 | None needed. [VERIFIED: `git --version`] |
| Docker | Not required for Phase 34 validation | yes | 29.5.2 | Skip Docker; this phase is file-read-only. [VERIFIED: `docker --version`; VERIFIED: `34-CONTEXT.md` D-24] |
| Node | GSD tooling/research cache only | yes | 22.14.0 | Not required by implementation. [VERIFIED: `node --version`] |

**Missing dependencies with no fallback:** none for Phase 34 implementation. [VERIFIED: environment probes]  
**Missing dependencies with fallback:** none for Phase 34 implementation. [VERIFIED: environment probes]  

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix `1.19.5` local; project target Elixir `~> 1.19`. [VERIFIED: `mix --version`; VERIFIED: `mix.exs:11`] |
| Config file | `mix.exs` defines test filters and test support paths; no separate ExUnit config file is needed for this phase. [VERIFIED: `mix.exs:20-25`, `mix.exs:54-65`] |
| Quick run command | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` [VERIFIED: `34-CONTEXT.md` D-25] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: existing Mix test framework; CITED: https://mix.hexdocs.pm/Mix.Tasks.Test.html] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOCS-03 | Docker DX guide preserves canonical commands/URL/secrets tokens and rejects stale browser-start `localhost:4000`. | unit / contract | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs` | No, Wave 0 create. [VERIFIED: `test -f test/scoria/docker_dx_doc_contract_test.exs`] |
| DOCS-03 / REL-03 context | FLAKE-01 host-port ban covers `post-publish-smoke.yml` and rejects host ports `>= 32768`. | unit / contract | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | Existing file. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:1`] |
| DOCS-03 lane wiring | New doc-contract file runs in existing policy lane with no new job/check/service. | unit / contract | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | Existing assertion should be extended or covered by lane-step check. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:609-617`] |

### Sampling Rate

- **Per task commit:** Run the quick policy command from D-25. [VERIFIED: `34-CONTEXT.md` D-25]
- **Per wave merge:** Run the quick policy command plus the static `rg` checks from D-26. [VERIFIED: `34-CONTEXT.md` D-26]
- **Phase gate:** `mix test --warnings-as-errors` is preferred if time permits; at minimum the explicit policy command and static checks must be green because this phase changes only file-read policy surfaces. [VERIFIED: scope in `34-CONTEXT.md` D-24]

### Expected Outcomes

```bash
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors \
  test/scoria/docker_dx_doc_contract_test.exs \
  test/scoria/ci_policy_contract_test.exs \
  test/scoria/verification_lanes_test.exs \
  test/scoria/adoption_surface_test.exs
```

Expected after implementation: exits `0`; no application start, DB, Docker daemon, or network is required. [VERIFIED: `34-CONTEXT.md` D-24/D-25; CITED: https://mix.hexdocs.pm/Mix.Tasks.Test.html]

```bash
rg -n "55432" .github/workflows/post-publish-smoke.yml
```

Expected after implementation: zero hits. [VERIFIED: `34-CONTEXT.md` D-26]

```bash
rg -n "localhost:4000|127\\.0\\.0\\.1:4000" docs/docker_dev_dx.md
```

Expected after implementation: zero stale browser-start hits; qualified `:4000` mechanics may remain and should be evaluated by the ExUnit guard. [VERIFIED: `34-CONTEXT.md` D-26]

### Wave 0 Gaps

- [ ] `test/scoria/docker_dx_doc_contract_test.exs` - create dedicated DOCS-03 contract. [VERIFIED: missing file check]
- [ ] `test/scoria/ci_policy_contract_test.exs` - extend FLAKE-01 scanner to include `.github/workflows/post-publish-smoke.yml`. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:210-255`]
- [ ] `.github/workflows/ci-verify.yml` - append the new file to the existing policy command. [VERIFIED: `.github/workflows/ci-verify.yml:53-56`]
- [ ] `.github/workflows/post-publish-smoke.yml` - change `55432:5432` and `SCORIA_DB_PORT: 55432` to `5432`. [VERIFIED: `.github/workflows/post-publish-smoke.yml:51-62`]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement: false`. [VERIFIED: `.planning/config.json`; VERIFIED: `rg -n "security_enforcement|nyquist_validation" .planning/config.json`]

### Applicable ASVS Categories

OWASP ASVS is a security verification standard with categories including V2 Authentication, V3 Session Management, V4 Access Control, V5 Validation/Sanitization/Encoding, V6 Stored Cryptography, V10 Malicious Code, and V14 Configuration. [CITED: https://devguide.owasp.org/en/03-requirements/05-asvs/]

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No auth flow changes. [VERIFIED: Phase 34 scope in `34-CONTEXT.md`] |
| V3 Session Management | no | No sessions/cookies touched. [VERIFIED: Phase 34 scope in `34-CONTEXT.md`] |
| V4 Access Control | no | No app authorization boundary touched. [VERIFIED: Phase 34 scope in `34-CONTEXT.md`] |
| V5 Validation, Sanitization and Encoding | yes | Validate docs/workflow text with explicit regex/string contracts; avoid parsing user input or rendering HTML. [VERIFIED: planned test surfaces; CITED: https://devguide.owasp.org/en/03-requirements/05-asvs/] |
| V6 Stored Cryptography | no | No crypto or secret storage changes; doc contract only preserves `ANTHROPIC_API_KEY` guidance. [VERIFIED: `34-CONTEXT.md` D-14/D-24] |
| V10 Malicious Code | yes, limited | No new packages, no network calls, no shelling out from tests; pure file reads reduce supply-chain and execution risk. [VERIFIED: `34-CONTEXT.md` D-24] |
| V14 Configuration | yes | Guard GitHub Actions service-port configuration and policy-lane wiring. [VERIFIED: `.github/workflows/ci-verify.yml:53-56`; VERIFIED: `.github/workflows/post-publish-smoke.yml:51-62`] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CI flake from fixed host port in Linux ephemeral range | Denial of Service | Enforce `host_port < 32768` for fixed Postgres binds; `55432` is in the default Linux local port range. [CITED: https://docs.kernel.org/networking/ip-sysctl.html; VERIFIED: `test/scoria/ci_policy_contract_test.exs:210-255`] |
| Accidental app/DB/network side effects from policy tests | Tampering / Denial of Service | `mix test --no-start`; `File.read!` only; no DB services in policy job. [VERIFIED: `.github/workflows/ci-verify.yml:15-56`; CITED: https://mix.hexdocs.pm/Mix.Tasks.Test.html] |
| Secret leakage in docs or tests | Information Disclosure | Assert only variable names and process-scoped guidance; never inspect `.env`, shell history, logs, or token-bearing sources. [VERIFIED: `34-CONTEXT.md` D-14/D-24; VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md` D-04] |
| Protected-check rename or CI topology drift | Tampering | Keep `CI / ci-gate` and `VerificationLanes.closeout_order/0` unchanged; append only the policy file list. [VERIFIED: `.github/workflows/ci.yml:127-147`; VERIFIED: `test/scoria/verification_lanes_test.exs:30-44`; VERIFIED: `34-CONTEXT.md` D-13] |

## Risks and Non-Goals

| Risk / Non-Goal | Guidance |
|-----------------|----------|
| Dirty worktree overlap | Files relevant to this phase already have uncommitted changes; implementation must inspect current diffs and avoid reverting unrelated edits. [VERIFIED: `git status --short`] |
| Phase 35 overlap | Do not publish, merge release PR #3, run `mix docs`, check Hex, or run live post-publish smoke in Phase 34. [VERIFIED: `34-CONTEXT.md` Deferred Ideas] |
| Overbroad doc assertions | Do not assert section headings, table row order, or exact prose beyond load-bearing fragments. [VERIFIED: `34-CONTEXT.md` D-15] |
| Random-port redesign | Do not switch post-publish to random host ports in this phase, even though GitHub supports it. [VERIFIED: `34-CONTEXT.md` D-08; CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts] |
| Cross-repo fleet work | Sibling repo migration and proxy-network convergence remain deferred. [VERIFIED: `34-CONTEXT.md` D-02 and Deferred Ideas] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | All implementation recommendations assume the current dirty worktree content is the planning baseline. | Project Constraints / Current Relevant State | If uncommitted user changes are reverted or altered before execution, line numbers and exact assertions may need recalibration. |

## Open Questions (RESOLVED)

1. **RESOLVED: Should the old Docker DX guide test be fully removed or narrowed?**  
   What we know: D-11 says move or narrow broad Docker DX guide assertions from `ci_policy_contract_test.exs`; Claude's Discretion leaves exact split to the planner. [VERIFIED: `34-CONTEXT.md` D-11 and Claude's Discretion]  
   Planner answer: Narrow the old omnibus test to the `.env.example` instance-example guard only. Move the Docker DX guide token, stale browser URL, and cache-table ownership to `Scoria.DockerDxDocContractTest`; keep `ci_policy_contract_test.exs` focused on CI policy, Compose, Makefile, Dockerfile structure, and non-doc secrets/instance surfaces. [VERIFIED: `34-CONTEXT.md` D-11]

2. **RESOLVED: Line vs paragraph qualification for `4000` scan?**  
   What we know: D-19 permits paragraph or line scanning. [VERIFIED: `34-CONTEXT.md` D-19]  
   Planner answer: Use direct refutes for stale browser-start URL forms, then apply qualifier enforcement only to paragraphs or lines that pair `4000` with browser-start/fallback context. Explicitly allow the current anti-footgun/no-juggling copy, because it warns against fixed-port juggling rather than instructing a browser start. Qualified Docker-internal, container, Traefik, CI, and ephemeral fallback mechanics remain allowed. [VERIFIED: current `docs/docker_dev_dx.md`; VERIFIED: `34-CONTEXT.md` D-17-D-19]

## Sources

### Primary (HIGH confidence)

- `.planning/phases/34-docker-dx-drift-guard-ci-guard-extension/34-CONTEXT.md` - locked decisions D-01 through D-26 and deferred scope. [VERIFIED: repo file]
- `.planning/ROADMAP.md` - Phase 34 and Phase 35 goals/success criteria. [VERIFIED: repo file]
- `.planning/REQUIREMENTS.md` - DOCS-03 and REL-03 context. [VERIFIED: repo file]
- `.github/workflows/ci-verify.yml` - existing policy lane command and CI topology. [VERIFIED: repo file]
- `.github/workflows/post-publish-smoke.yml` - current `55432` bind and env value. [VERIFIED: repo file]
- `test/scoria/ci_policy_contract_test.exs` - existing policy contract patterns and FLAKE-01 scanner. [VERIFIED: repo file]
- `docs/docker_dev_dx.md` - target doc content and current allowed `:4000` references. [VERIFIED: repo file]
- `brandbook/brand-book.md` - calm, exact, useful failure-message voice. [VERIFIED: repo file]

### Secondary (MEDIUM confidence)

- GitHub Actions PostgreSQL service containers docs - runner-machine jobs use localhost plus mapped host ports; official example maps `5432:5432`. [CITED: https://docs.github.com/en/actions/tutorials/use-containerized-services/create-postgresql-service-containers]
- GitHub Actions contexts docs - random service host ports can be read from `job.services.<service>.ports[...]`. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts]
- Docker docs - `HOST_PORT:CONTAINER_PORT` semantics and ephemeral published ports. [CITED: https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/]
- Mix `test` docs - explicit file arguments, default app start, `--no-start`, `--warnings-as-errors`, and async test reporting. [CITED: https://mix.hexdocs.pm/Mix.Tasks.Test.html]
- Linux kernel ip-sysctl docs - default `ip_local_port_range` is `32768` to `60999`. [CITED: https://docs.kernel.org/networking/ip-sysctl.html]
- OWASP ASVS developer guide - ASVS categories for security-domain mapping. [CITED: https://devguide.owasp.org/en/03-requirements/05-asvs/]

### Tertiary (LOW confidence)

- None used for implementation-critical recommendations.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo already uses ExUnit/Mix policy-lane tests; no new packages. [VERIFIED: repo files]
- Architecture: HIGH - locked decisions and existing workflow topology define the implementation shape. [VERIFIED: `34-CONTEXT.md`; VERIFIED: `.github/workflows/ci-verify.yml`]
- Pitfalls: HIGH for repo pitfalls, MEDIUM for external CI port semantics - repo evidence and official docs agree. [VERIFIED: repo files; CITED: GitHub/Docker/Linux docs]

**Research date:** 2026-06-18  
**Valid until:** 2026-07-18 for repo-local decisions; re-check GitHub Actions docs before changing service-port strategy. [ASSUMED]
