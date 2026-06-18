# Phase 34: Docker DX drift guard + CI guard extension - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase turns the Docker dev-DX documentation truth from Phase 33 into a
mechanical policy-lane guard, then extends the existing CI ephemeral-port guard
to the post-publish registry smoke workflow.

The implementation should deliver:

- A dedicated `test/scoria/docker_dx_doc_contract_test.exs` that reads
  `docs/docker_dev_dx.md` without app start or DB access.
- Policy-lane wiring so the new doc contract runs beside the existing lane
  contract tests, with no new CI job, service, dependency edge, or protected
  check name.
- An extension of `test/scoria/ci_policy_contract_test.exs` so the FLAKE-01
  ephemeral-host-port ban scans `.github/workflows/post-publish-smoke.yml`.
- The tiny matching fix in `.github/workflows/post-publish-smoke.yml`
  (`55432:5432` -> `5432:5432`, and matching `SCORIA_DB_PORT`) so the new
  guard can pass before release work begins.

Out of scope: publishing `0.1.2`, running the post-publish registry smoke,
changing CI topology, changing `CI / ci-gate`, changing
`Scoria.VerificationLanes.closeout_order/0`, rewriting the Docker DX guide,
sibling-repo migration, proxy bake-offs, and UI polish.

</domain>

<decisions>
## Implementation Decisions

Calibration: the user selected all gray areas and asked for subagent-backed
research, pros/cons/tradeoffs, ecosystem lessons, prompt/brandbook context, and
one cohesive recommendation set. Four `gsd-advisor-researcher` agents covered
the post-publish port boundary, ExUnit doc-contract ownership, stale URL
strictness, and cache-table string contracts. Decisions below are LOCKED.

### Todo folding and scope
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

### Post-publish port-fix boundary
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

### Dedicated Docker DX doc-contract ownership
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

### Canonical Docker DX doc tokens
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

### Stale `localhost:4000` guard strictness
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

### Cache-table doc strings
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

### Voice and engineering posture
- **D-23:** Follow the current `brandbook/brand-book.md` voice: calm, exact,
  useful. Failure messages and docs contract names should say what drifted and
  what to do next. Avoid hype, vague "magic" wording, or shaming prior drift.
- **D-24:** Keep the implementation boring: file reads, simple regex/string
  checks, `async: true`, no app start, no DB, no Docker daemon, no network, no
  CI topology changes.

### Verification recommendations
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

### Claude's Discretion
- Exact test names, helper names, and regex implementation details may be
  refined as long as D-05 through D-26 hold.
- The planner may decide whether to fully remove the old Docker DX guide test
  from `ci_policy_contract_test.exs` or leave a non-duplicative residual check
  there if it guards `.env.example` or another non-doc policy surface. Do not
  leave duplicated canonical doc-token assertions in both files.

### Folded Todos
- **docker-dx-fleet-hardening.md:** Fold only the Scoria-local verification-copy
  drift guard item into Phase 34. Phase 33 corrected the docs and active
  planning prose; Phase 34 makes that corrected Docker/native URL truth
  mechanically durable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` section "Phase 34: Docker DX drift guard + CI guard extension" - phase goal, dependency on Phase 33, and success criteria.
- `.planning/ROADMAP.md` section "Phase 35: Maintenance release - 0.1.2 publish + post-publish smoke" - release work stays later; REL-03 port fix is precompleted here and re-verified there.
- `.planning/REQUIREMENTS.md` - DOCS-03 is the main Phase 34 requirement; REL-03 names the post-publish port blind spot that Phase 34 closes early.
- `.planning/PROJECT.md` section "Current Milestone: v3.2 Drydock" - milestone boundary and Scoria-only Docker dev-DX scope.
- `.planning/STATE.md` - recent decisions: new tests run in the existing policy lane only; no CI topology changes; `CI / ci-gate` unchanged.

### Carried-forward decisions
- `.planning/phases/29-makefile-hardening/29-CONTEXT.md` - `PORT ?= 4799` is Makefile/native policy; Docker internals stay on `:4000`.
- `.planning/phases/30-launch-banner-native-dev-notice/30-CONTEXT.md` - Docker banner route list derives from `mix phx.routes`; Phase 34 owns the parity/drift-guard pattern.
- `.planning/phases/31-dockerfile-caching-audit-doc/31-CONTEXT.md` - Phase 34 should pin cache-table load-bearing strings `mix deps.get`, `mix deps.compile`, and `app compile only`.
- `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md` - Docker DX doc must keep the 1Password/direnv and `ANTHROPIC_API_KEY` secret-consuming command truth.
- `.planning/phases/33-doc-restructure-verification-copy-correction/33-CONTEXT.md` - Phase 33 finalized docs copy and locked the stale-URL semantics that Phase 34 now guards.

### Source and test surfaces
- `docs/docker_dev_dx.md` - primary doc-contract input.
- `test/scoria/ci_policy_contract_test.exs` - existing policy-lane omnibus contract; extend post-publish scan and move/narrow Docker DX doc assertions.
- `.github/workflows/ci-verify.yml` - existing policy lane explicit test-file list; append the new doc-contract file only.
- `.github/workflows/post-publish-smoke.yml` - release registry smoke workflow; fix `55432` to `5432` and include in ephemeral-port scan.
- `.github/workflows/ci.yml` - existing `5432:5432` e2e pattern and unchanged `CI / ci-gate` protected check.
- `docs/MAINTAINERS.md` - FLAKE-01 policy narrative and maintainer CI gate map.
- `Dockerfile.dev` - structural layer-order guard remains in `ci_policy_contract_test.exs`; Phase 34 guards reader-facing docs strings.
- `compose.yml` - Docker-internal `:4000`, Traefik `server.port=4000`, and ephemeral fallback mechanics; do not confuse with stale browser-start URLs.
- `Makefile` - command SSOT for `make up`, `make url`, `make open`, `make dev`, and `make nuke`.

### Voice, architecture, and project DNA
- `brandbook/brand-book.md` - canonical voice and microcopy: calm, exact, useful; operator-grade, evidence-based docs.
- `brandbook/README.md` - brandbook source priority; current brandbook supersedes older prompt research where they conflict.
- `prompts/sztheory-elixir-dna.md` - Operator-First DX, batteries-included but composable, robust CI/CD.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native, Ecto/LiveView/OTP practical ecosystem posture; compose with existing tools rather than hiding mechanisms.
- `prompts/scoria-brand-book-deep-research.md` - supporting historical brand research; subordinate to `brandbook/brand-book.md`.
- `prompts/scoria-gsd-kickoff.md` - project vision and technical alignment.
- `prompts/brand-book-pressure-test-prompt.md` - pressure-test lens for developer credibility, Elixir fit, source-control readiness, accessibility, and useful docs.

### Folded and reviewed todos
- `.planning/todos/pending/docker-dx-fleet-hardening.md` - fold only Scoria-local doc-drift guard into Phase 34; fleet convergence remains deferred.
- `.planning/todos/pending/ci-policy-job-cache-key-mislabel.md` - reviewed and deferred as unrelated post-ship CI cleanup.
- `.planning/todos/pending/2026-06-18-make-approval-toasts-legible.md` - reviewed and deferred as unrelated UI polish.

### External primary references used during discussion
- `https://docs.github.com/en/actions/tutorials/use-containerized-services/create-postgresql-service-containers` - GitHub's PostgreSQL service-container examples use runner-machine `localhost` access and `5432:5432` host/container mapping.
- `https://docs.github.com/en/actions/tutorials/use-containerized-services/use-docker-service-containers` - GitHub Actions service-container networking: runner-machine jobs need host-port mappings; random host ports require `job.services.*.ports`.
- `https://docs.kernel.org/networking/ip-sysctl.html` - Linux default `ip_local_port_range` is `32768` to `60999`, making `55432` an ephemeral-range fixed bind.
- `https://docs.docker.com/reference/compose-file/services/` - Docker Compose distinguishes internal exposed ports from published host ports.
- `https://mix.hexdocs.pm/Mix.Tasks.Test.html` - `mix test` can run explicit files; default task starts the app unless `--no-start` is used.
- `https://github.com/phoenixframework/phoenix/blob/main/guides/testing/testing.md` - Phoenix uses ExUnit and favors clear, explicit tests with real project structure.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/scoria/ci_policy_contract_test.exs` already has `job_blocks/1`,
  `index_of/2`, `service_section/2`, and the FLAKE-01 port-bind extraction
  pattern. Reuse or adapt the existing regex behavior for the post-publish scan
  instead of inventing an unrelated parser.
- `ci_policy_contract_test.exs` already defines `@ephemeral_range_min 32_768`
  and failure text explaining why fixed host ports in that range are banned.
- `docs/docker_dev_dx.md` already contains the Phase 33 final doc truth:
  Docker daily loop, native dev server, caching guarantees, Secrets, stale
  instance hygiene, `make up`, `make dev`, `localhost:4799`, `make nuke`,
  `direnv`, `1Password`, and `ANTHROPIC_API_KEY`.
- `.github/workflows/ci-verify.yml` already runs a single policy-lane test
  command with explicit test files and `--no-start`.

### Established Patterns
- Policy-lane contract tests read repo files directly and stay DB-free,
  Docker-free, network-free, and app-start-free.
- CI topology changes are avoided unless a phase explicitly requires them.
  Adding a test file to the existing policy command is acceptable; adding jobs
  or services is not.
- Drift guards pin load-bearing strings and structural invariants, not broad
  prose style.
- Scoria docs prefer copy-pasteable commands, exact URLs, and honest mechanics
  over vague "it works" copy.
- Archived milestone artifacts are historical records; current docs and active
  planning prose are living surfaces.

### Integration Points
- The new `docker_dx_doc_contract_test.exs` connects to the existing policy lane
  through `.github/workflows/ci-verify.yml`.
- The post-publish workflow fix connects to Phase 35, which will publish
  `0.1.2` and run the registry smoke after this flake class is closed.
- The stale URL guard connects directly to Phase 33's D-11/D-20 distinction:
  browser-start URLs are Traefik or native `4799`; Docker container `:4000`
  remains valid only when explicitly qualified.

</code_context>

<specifics>
## Specific Ideas

Recommended doc-token helper shape:

```elixir
for {fragment, reason} <- [
      {"make up", "Docker daily loop command"},
      {"make dev", "native host command"},
      {"4799", "native host URL/PORT default"},
      {"make nuke", "scoped cleanup command"},
      {"ANTHROPIC_API_KEY", "critique secret variable"}
    ] do
  assert docs =~ fragment,
         "docs/docker_dev_dx.md lost #{reason} (#{inspect(fragment)})"
end

assert docs =~ "direnv" or docs =~ "1Password"
```

Recommended cache-token helper shape:

```elixir
for fragment <- ["mix deps.get", "mix deps.compile", "app compile only"] do
  assert docs =~ fragment,
         "docs/docker_dev_dx.md lost layer-cache token #{inspect(fragment)}; " <>
           "keep the dependency rebuild term visible or update this contract " <>
           "with a Phase 31/D-11 rationale"
end
```

Recommended stale URL checks:

```elixir
refute docs =~ ~r{\bhttps?://localhost:4000(?:/scoria)?\b}

refute docs =~
         ~r{\b(open|visit|browse|browser|go to|curl)\b[^\n]*(?:localhost|127\.0\.0\.1):4000\b}i
```

Allowed `4000` examples:

- `Docker-internal container port 4000`
- `Traefik service target`
- `loadbalancer.server.port=4000`
- `127.0.0.1::4000`
- `docker compose port web 4000`
- `web:4000`
- `ephemeral loopback fallback`

Forbidden examples:

- `open http://localhost:4000/scoria`
- `visit localhost:4000`
- `curl http://localhost:4000/scoria`
- `http://127.0.0.1:4000/scoria` as a fixed fallback or dev-start URL

</specifics>

<deferred>
## Deferred Ideas

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

### Reviewed Todos (not folded)
- `ci-policy-job-cache-key-mislabel.md` - reviewed because it matched policy,
  test, mix, and key terms; deferred because it concerns CI cache naming cleanup
  and is not part of Phase 34's Docker DX drift guard.
- `2026-06-18-make-approval-toasts-legible.md` - reviewed because it matched
  `make`; deferred because it is UI polish and unrelated to this policy-lane
  docs/CI phase.
- `docker-dx-fleet-hardening.md` - non-doc fleet convergence and fleet-wide
  cleanup items remain deferred; only Scoria-local doc-drift guard was folded.

</deferred>

---

*Phase: 34-docker-dx-drift-guard-ci-guard-extension*
*Context gathered: 2026-06-18*
