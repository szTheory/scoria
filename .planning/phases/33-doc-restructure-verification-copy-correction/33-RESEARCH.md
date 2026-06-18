# Phase 33: Doc restructure + verification-copy correction - Research

**Researched:** 2026-06-18
**Domain:** Documentation IA, Docker/Phoenix local dev-DX, verification-copy drift
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Calibration: the user selected all gray areas and asked for subagent-backed research, ecosystem comparison, pros/cons, footguns, and one cohesive recommendation set. Five `gsd-advisor-researcher` agents researched document IA, `.planning` sweep boundary, command wording, adjacent docs, and prompt/brand voice. Decisions below are LOCKED.

#### Document IA and emphasis
- **D-01:** Rewrite `docs/docker_dev_dx.md` as a **guided reference narrative**, not a troubleshooting-only page and not an architecture-first design memo. The order should be: persona/JTBD -> TL;DR gameplan -> short mental model -> task sections -> appendices.
- **D-02:** The top of the doc must make the reader and job explicit: a solo maintainer running many Phoenix/Elixir library demos on one Mac wants a hands-off, port-conflict-free loop. This is the reason for Traefik, per-instance Compose names, unpublished DB ports, native `4799`, `make fleet`, `make doctor`, and scoped cleanup.
- **D-03:** Preserve the strongest existing content, but change the emphasis. Keep the multi-instance model, layer-cache table, process-scoped 1Password/direnv secrets pattern, and adoption appendix. Move stale-instance hygiene out of buried multi-instance prose into its own readable section.
- **D-04:** Required standalone sections in `docs/docker_dev_dx.md`: Docker daily loop, Native dev server, Caching guarantees, Secrets, Stale instance hygiene. Each section should be digestible alone using this pattern: when to use it -> commands -> expected URL/output -> footguns -> recovery.
- **D-05:** Put returning-maintainer commands up front without losing the why. The doc should be fast to scan like successful framework quickstarts, but still teach the invariant that avoids future drift: user-facing browser URLs are Traefik `*.localhost` or native `localhost:4799`; Docker container `:4000` is not the browser start URL.

#### Command wording pattern
- **D-06:** Use **context-specific wording** as the canonical replacement pattern. Docker-first is the default for "run the Scoria repo dashboard"; native-first is only for host Mix iteration, screenshots, Playwright/e2e, or other tasks that explicitly require the BEAM running on the host.
- **D-07:** Canonical Scoria repo dashboard wording:
  ```text
  Run `make proxy` once, `make up-build` on first run, then `make up`.
  Use `make url` or `make open` and open the printed `http://<instance>.localhost/scoria` URL.
  ```
- **D-08:** Canonical native host wording:
  ```text
  Run `make dev` and open `http://localhost:4799/scoria`.
  ```
  If useful, add that `make dev PORT=5000` is supported and prints the matching URL.
- **D-09:** Canonical maintainer screenshot/e2e wording:
  ```text
  Start the dashboard with `make dev`, then run:
  `mix scoria.ui.shots --url http://localhost:4799/scoria`
  `mix scoria.ui.e2e --base-url http://localhost:4799/scoria`
  ```
- **D-10:** Canonical GSD/planning wording:
  ```text
  Verify with Docker: `make up` -> `make url` -> `http://<instance>.localhost/scoria`.
  Verify native: `make dev` -> `http://localhost:4799/scoria`.
  ```
- **D-11:** Never present `http://localhost:4000/scoria` as a Scoria browser dev-start URL. If `:4000` appears, it must be explicitly qualified as Docker-internal container listener, Traefik service target, CI self-test port, or ephemeral loopback mechanism.

#### Verification-copy sweep boundary
- **D-12:** Use an **active/current sweep with explicit archive exclusions**, not a blanket `.planning` rewrite. Correct current docs and current planning instructions. Preserve `.planning/milestones/**` and old shipped audit artifacts as historical records.
- **D-13:** Include in the active sweep: `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/research/**`, pending todos, and active `.planning/phases/**` files where they give current verification/how-to-start instructions or handoff notes.
- **D-14:** Exclude archived or historical evidence from the failure gate: `.planning/milestones/**`, top-level old `v*-MILESTONE-AUDIT.md` files, `.planning/debug/**`, `.planning/memory/**`, and `.planning/todos/completed/**`. These may be inventoried as historical hits, but Phase 33 should not mutate them.
- **D-15:** Do not rewrite correct implementation evidence such as `PORT=$(PORT) mix phx.server` in Phase 29/30 artifacts when it describes what `make dev` does internally. The stale-copy target is user-facing "start/open/visit/verify at localhost:4000" guidance, not every literal occurrence of `mix phx.server`.

#### Docs and code-adjacent surfaces
- **D-16:** At minimum, update the named Phase 33 docs: `README.md`, `docs/operator_verification.md`, and `docs/MAINTAINERS.md`.
- **D-17:** Also include `docs/uat_automation.md`; Phase 29 explicitly deferred this doc to Phase 33 and it still instructs direct `mix phx.server` / `PORT=4010` for the Scoria dashboard. Replace with `make dev` and `http://localhost:4799/scoria`.
- **D-18:** Include `docs/support_copilot_gallery.md`, but do **not** blindly replace the gallery app's `mix phx.server`. The support-copilot gallery is a separate Phoenix app configured for `http://localhost:4010`; keep its command and qualify the URLs explicitly as gallery-app URLs (`http://localhost:4010/` and `http://localhost:4010/scoria`).
- **D-19:** Include user-facing dev-harness copy/defaults that Phase 29 parked under DOCS: `lib/mix/tasks/scoria.ui.shots.ex`, `lib/mix/tasks/scoria.ui.e2e.ex`, `priv/dev/shots.mjs`, `priv/dev/e2e/*.spec.mjs`, and `priv/repo/dev_seed.exs` when they present Scoria dashboard URLs or start instructions. Preferred default URL for host harnesses is `http://localhost:4799/scoria`.
- **D-20:** Do not edit generated `priv/static/scoria/app.js` just because it contains bundled strings. Do not change Docker Compose service ports, Traefik labels, `Dockerfile.dev EXPOSE 4000`, CI `PORT: 4000`, or `config/dev.exs` runtime fallback.

#### Voice and UX constraints
- **D-21:** `brandbook/` is canonical for voice and docs style. `prompts/` are supporting DNA only.
- **D-22:** Write in Scoria's voice: calm, exact, useful. Lead with concrete commands, URLs, expected output, failure mode, and recovery. Avoid "seamless", "magic", "powerful", "just works", and any copy that hides the mechanism.
- **D-23:** Use operator-first nouns: instance, route, proxy, fallback, native DB, cache, secret, scope. Do not shame the reader for prior wrong commands; state what changed and what is canonical now.
- **D-24:** For destructive commands, always show scope. `make nuke` is allowed only as scoped instance cleanup, not as a vague "if things are weird" fix. Do not introduce `docker system prune`, `docker volume prune`, or a fleet-wide nuke target.
- **D-25:** Docs accessibility rules apply if any rendered docs/HTML examples are touched: meaningful link text, code blocks for copy-pasteable commands, visible text labels for status/warnings, no color-only status, and brandbook contrast/focus constraints.

#### Verification recommendations
- **D-26:** Recommended active-doc checks:
  ```bash
  rg -n "localhost:4000|mix phx\\.server" README.md docs/operator_verification.md docs/MAINTAINERS.md docs/uat_automation.md
  rg -n "PORT=4010|localhost:4010|localhost:4000|mix phx\\.server" docs/uat_automation.md docs/support_copilot_gallery.md
  ```
  `docs/support_copilot_gallery.md` may still contain `mix phx.server` if it is clearly the gallery app startup, not Scoria repo dashboard startup.
- **D-27:** Recommended active-planning check:
  ```bash
  rg -n "mix phx\\.server|localhost:4000/scoria" .planning \
    -g '!milestones/**' \
    -g '!v*-MILESTONE-AUDIT.md' \
    -g '!debug/**' \
    -g '!memory/**' \
    -g '!todos/completed/**'
  ```
  Then classify remaining hits as implementation evidence, current stale instruction, or quoted historical rationale.
- **D-28:** Recommended dev-harness checks:
  ```bash
  rg -n "localhost:4000/scoria|mix phx\\.server" lib/mix/tasks/scoria.ui.*.ex priv/dev priv/repo/dev_seed.exs
  make -n dev
  ```
- **D-29:** Recommended regression tests after implementation, selected by touched surfaces: `mix test test/scoria/ci_policy_contract_test.exs`, `mix test test/scoria/package_surface_test.exs test/scoria/support_journey_source_test.exs`, and any existing docs/source-contract test that guards README/operator/maintainer copy.

#### Folded Todos
- **docker-dx-fleet-hardening.md:** Fold the doc/plan drift item and docs-reader-empathy requirement into Phase 33. The folded problem: stale GSD plans/agents/docs told verifiers to run `mix phx.server` -> `http://localhost:4000/scoria`, which is wrong for Scoria's fleet-routed dev model. Phase 33 corrects that copy and turns `docs/docker_dev_dx.md` into the portable standard.

### the agent's Discretion

- Exact prose, section titles, and command comments may be refined as long as D-01 through D-29 hold.
- The planner may decide whether to do the code-adjacent dev-harness copy/default updates in the same plan or a second plan, but they should remain part of Phase 33 unless a blocking risk appears.

### Deferred Ideas (OUT OF SCOPE)

- **Phase 34 Docker DX drift guard:** contract tests for the final `docs/docker_dev_dx.md` strings, absence of stale dev-start `localhost:4000`, and CI/post-publish smoke port extension.
- **Sibling-repo fleet convergence:** remains FLEET-01 and out of v3.2 implementation scope. Phase 33 only makes Scoria the reference standard.
- **Fleet-wide `make nuke-all`:** remains FLEET-02 and out of scope due to high blast radius.
- **Release publish and post-publish registry smoke:** Phase 35.
- **CI cache-key mislabel cleanup:** reviewed via todo match; still post-ship cleanup and unrelated to Phase 33.

#### Reviewed Todos (not folded)
- `ci-policy-job-cache-key-mislabel.md` - reviewed because it matched on `mix` and `phase`; deferred because it concerns CI cache key/env labeling, not Docker dev-DX documentation or stale local-dev verification copy.
- `docker-dx-fleet-hardening.md` - non-doc fleet convergence items remain deferred; only the doc/plan drift and reader-empathy items were folded into Phase 33.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | Dev-server verification copy across `docs/operator_verification.md`, `docs/MAINTAINERS.md`, `README`, and GSD agent/plan prose uses `make up` / `make dev` + the real `*.localhost` and `:4799` URLs; no `mix phx.server` -> `localhost:4000/scoria`. | Source-of-truth commands are verified in `Makefile`, `compose.yml`, and `config/dev.exs`; stale hits are inventoried for active docs, `.planning/`, and code-adjacent harness defaults. [VERIFIED: codebase grep] |
| DOCS-02 | `docs/docker_dev_dx.md` is restructured as the reference fleet standard with reader-empathy IA and standalone Native-dev-server, Caching-guarantees, Secrets, and Stale-instance-hygiene sections. | Current doc content already contains the raw material, but section order and names do not match the locked IA; rewrite should preserve cache/secrets facts and promote stale-instance hygiene. [VERIFIED: docs/docker_dev_dx.md] |
</phase_requirements>

## Summary

Phase 33 is a documentation and copy-correction phase, not a dev-stack redesign. The true Scoria repo dashboard paths are Docker-first `make proxy` once, `make up-build` on first/build-affecting runs, `make up`, then `make url` or `make open` for `http://<instance>.localhost/scoria`; native host work uses `make dev` and `http://localhost:4799/scoria`. [VERIFIED: Makefile:40] [VERIFIED: Makefile:50] [VERIFIED: Makefile:54] [VERIFIED: Makefile:97] [VERIFIED: Makefile:147]

The existing `docs/docker_dev_dx.md` has useful raw material but needs an information-architecture pass: persona/JTBD and TL;DR are present-ish, but the required standalone sections are not named or structured as locked decisions require. `Native host dev and tests`, `No rebuild on source/style edits`, and `Running multiple instances` should become or feed the required `Native dev server`, `Caching guarantees`, and `Stale instance hygiene` sections, each with commands, expected URL/output, footguns, and recovery. [VERIFIED: docs/docker_dev_dx.md:1] [VERIFIED: docs/docker_dev_dx.md:84] [VERIFIED: docs/docker_dev_dx.md:119] [VERIFIED: docs/docker_dev_dx.md:162]

The stale-copy sweep has two tiers. Active docs have direct stale Scoria harness instructions in `docs/MAINTAINERS.md` and `docs/uat_automation.md`; README/operator/support-copilot hits are the separate gallery app and should be qualified rather than blindly replaced. Code-adjacent harness defaults still point at `http://localhost:4000/scoria` and should be updated if the planner takes the D-19 scope in the same plan. [VERIFIED: codebase grep]

**Primary recommendation:** Plan one cohesive doc/copy pass that rewrites `docs/docker_dev_dx.md`, updates active docs and code-adjacent harness defaults to `make dev` / `http://localhost:4799/scoria`, and sweeps active `.planning` prose with explicit archive exclusions and context classification. [VERIFIED: 33-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Docker daily dev model documentation | Documentation / Repository | Dev tooling (`Makefile`, Compose) | The planner should edit docs, but factual ownership stays in `Makefile` and `compose.yml`; docs must describe the existing commands rather than inventing new start paths. [VERIFIED: Makefile:1] [VERIFIED: compose.yml:1] |
| Native dev server guidance | Dev tooling | Phoenix dev endpoint | `make dev` owns the user command and passes `PORT=4799`, `SCORIA_DB_PORT=55432`, and pool settings into Phoenix; `config/dev.exs` keeps the low-level fallback `"4000"` for Docker/internal use. [VERIFIED: Makefile:147] [VERIFIED: config/dev.exs:21] |
| Stale verification-copy correction | Documentation / Planning artifacts | Dev harness tasks | Active docs and `.planning` own the user-facing instructions; harness task defaults and comments also need alignment when they present Scoria dashboard URLs. [VERIFIED: docs/MAINTAINERS.md:350] [VERIFIED: lib/mix/tasks/scoria.ui.shots.ex:17] |
| Support-copilot gallery instructions | Example app docs | Main repo docs | The gallery is a separate Phoenix app under `examples/support_copilot`; `mix phx.server` may remain there only when the docs explicitly identify it as gallery-app startup and cite `localhost:4010` gallery URLs. [VERIFIED: docs/support_copilot_gallery.md:9] [VERIFIED: examples/support_copilot/README.md:10] |
| Drift verification | Test / Policy lane | Shell grep checks | Phase 33 should use targeted `rg` gates plus existing policy-lane docs contracts; Phase 34 owns the new dedicated drift-guard test. [VERIFIED: test/scoria/ci_policy_contract_test.exs:790] [VERIFIED: .github/workflows/ci-verify.yml:53] |

## Standard Stack

### Core

| Tool / Surface | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| GNU Make | 3.81 | Canonical local dev entrypoint: `proxy`, `up-build`, `up`, `url`, `open`, `fleet`, `doctor`, `dev`, cleanup targets. | The Makefile already derives instance identity and prints canonical routes; docs should point to it instead of raw Phoenix commands. [VERIFIED: Makefile:1] [VERIFIED: environment probe] |
| Docker + Docker Compose | Docker 29.5.2 / Compose v5.1.3 | Docker dev stack, Traefik routing, per-instance Compose names, unpublished DB, ephemeral fallback. | Compose project names isolate local environments, and service-to-service networking uses container ports while host ports are only for outside access. [VERIFIED: environment probe] [CITED: docs.docker.com/compose/how-tos/project-name] [CITED: docs.docker.com/compose/how-tos/networking] |
| Phoenix dev endpoint via Mix | Phoenix dependency `~> 1.7` in `mix.exs`; docs fetched show Phoenix v1.8.8 latest docs. | Low-level server mechanism used by `make dev` and Docker entrypoint. | Phoenix docs support `mix phx.server` as an endpoint-start mechanism, but Scoria docs must expose `make dev` because it supplies the project-specific port and native DB defaults. [VERIFIED: mix.exs:76] [CITED: phoenix.hexdocs.pm/Mix.Tasks.Phx.Server.html] |
| ExUnit policy lane | Elixir project test framework | Fast no-start docs/config contract checks. | Existing `ci_policy_contract_test.exs` reads docs and config files and CI runs it with `SCORIA_LANE_CONTRACT_ONLY=true`. [VERIFIED: test/scoria/ci_policy_contract_test.exs:1] [VERIFIED: .github/workflows/ci-verify.yml:53] |
| ripgrep (`rg`) | 15.1.0 | Drift inventory and verification gates. | The phase success criteria are grep/rg-driven string gates across docs and planning prose. [VERIFIED: environment probe] [VERIFIED: 33-CONTEXT.md] |

### Supporting

| Tool / Surface | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| 1Password CLI `op run --env-file` | CLI availability not probed; docs pattern already committed. | Process-scoped secret resolution for critique commands. | Keep in the Secrets section; do not resolve secrets into a long-lived shell or read local secret-bearing files during this phase. [VERIFIED: docs/docker_dev_dx.md:162] [CITED: www.1password.dev/cli/reference/commands/run] |
| direnv | Not probed | Local project pointer to `.env.op` via `.envrc.example`. | Document first-time setup and `direnv allow .`; no new wrapper target required. [VERIFIED: .envrc.example:1] |
| Playwright / Node harness | Node v22.14.0 / npm 11.1.0 available | Maintainer screenshots and e2e docs/defaults under `priv/dev`. | Update only user-facing base URLs and prerequisites; do not redesign the harness. [VERIFIED: environment probe] [VERIFIED: priv/dev/e2e/playwright.config.mjs:1] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `make up` / `make url` for Docker verification | Hardcoded `http://scoria-main-...localhost/scoria` | Hardcoding a dynamic branch/hash route drifts; `make url` is the stable source of truth. [VERIFIED: Makefile:97] |
| `make dev` for native host verification | Raw `PORT=4799 mix phx.server` | Raw Mix works mechanically but bypasses the native pgvector helper and the startup URL/DB echo lines; user docs should use `make dev`. [VERIFIED: Makefile:147] |
| Active `.planning` sweep with exclusions | Blanket rewrite of every `.planning` hit | Blanket rewrites would mutate archived milestone history and implementation evidence; locked D-12 through D-15 require classification. [VERIFIED: 33-CONTEXT.md] |

**Installation:** No external packages should be installed for Phase 33. [VERIFIED: phase scope]

## Package Legitimacy Audit

No external packages are recommended or installed in Phase 33, so the package legitimacy gate is not applicable. [VERIFIED: phase scope]

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer / verifier input
        |
        v
Choose context ---------------------------------------------------------+
 |                                                                    |
 | Docker repo dashboard                                               | Native host harness / e2e / screenshots
 v                                                                    v
make proxy once -> make up-build first/build-affecting run             make dev
        |                                                              |
make up / make up-d                                                    Makefile starts native DB helper
        |                                                              |
make url / make open                                                   Makefile passes PORT=4799 + SCORIA_DB_PORT=55432
        |                                                              |
http://<instance>.localhost/scoria                                     http://localhost:4799/scoria
        |                                                              |
        +-------------------- docs and harness copy -------------------+
                              |
                              v
                    rg gates + policy-lane docs tests
                              |
                              v
                    Phase 34 dedicated drift guard later
```

### Recommended Project Structure

```text
docs/
├── docker_dev_dx.md              # Primary rewritten reference standard
├── MAINTAINERS.md                # Maintainer screenshot/e2e runbook updates
├── operator_verification.md      # Gallery qualification and local-dev link updates
├── uat_automation.md             # Native e2e start command correction
└── support_copilot_gallery.md    # Separate gallery-app startup qualification

lib/mix/tasks/
├── scoria.ui.shots.ex            # Screenshot task docs/default URL
└── scoria.ui.e2e.ex              # E2E task docs/default URL

priv/dev/
├── shots.mjs                     # Script usage/default URL
└── e2e/*.mjs                     # Playwright comments/default base URL

.planning/
├── PROJECT.md / ROADMAP.md / REQUIREMENTS.md / STATE.md
├── research/**                   # Active planning research, classify hits
└── phases/**                     # Active phase artifacts, classify hits
```

### Pattern 1: Context-Specific Command Replacement

**What:** Replace stale Scoria dashboard start/open instructions with Docker-first or native-host wording based on the workflow. [VERIFIED: 33-CONTEXT.md]

**When to use:** Use Docker wording for the normal repo dashboard; use native wording only for host Mix iteration, screenshots, Playwright/e2e, or explicit host-BEAM tasks. [VERIFIED: 33-CONTEXT.md]

**Example:**

```markdown
Run `make proxy` once, `make up-build` on the first run, then `make up`.
Use `make url` or `make open` and open the printed
`http://<instance>.localhost/scoria` URL.

For host screenshot/e2e work, run `make dev` and open
`http://localhost:4799/scoria`.
```

### Pattern 2: Section-as-Task Reference IA

**What:** Each required `docs/docker_dev_dx.md` task section should follow `when to use -> commands -> expected URL/output -> footguns -> recovery`. [VERIFIED: 33-CONTEXT.md]

**When to use:** Apply this to Docker daily loop, Native dev server, Caching guarantees, Secrets, and Stale instance hygiene. [VERIFIED: 33-CONTEXT.md]

**Example:**

````markdown
Stale instance hygiene
----------------------

Use this when a route points at the wrong checkout or old data keeps appearing.

```bash
make fleet
make down INSTANCE=<project>
make nuke INSTANCE=<project>
```

Expected: `make fleet` shows the Compose project that owns the route.
Recovery: stop only that instance; use `make nuke` only when you intend to wipe
that instance's DB and caches.
````

### Pattern 3: Active-Sweep Classification

**What:** Classify every active `.planning` hit as stale instruction, implementation evidence, or quoted historical rationale before editing. [VERIFIED: 33-CONTEXT.md]

**When to use:** Use this for `.planning/research/**`, pending todos, and active `.planning/phases/**`; exclude archived milestone/debug/memory/completed-todo paths. [VERIFIED: 33-CONTEXT.md] [VERIFIED: codebase grep]

**Example:**

```bash
rg -n "mix phx\\.server|localhost:4000/scoria" .planning \
  -g '!**/milestones/**' \
  -g '!v*-MILESTONE-AUDIT.md' \
  -g '!**/debug/**' \
  -g '!**/memory/**' \
  -g '!**/todos/completed/**'
```

### Anti-Patterns to Avoid

- **Replacing every `mix phx.server` literal blindly:** Some literals are correct low-level implementation evidence in `Makefile`, `docker/dev-entrypoint.sh`, `dev/*`, and Phase 29/30 artifacts. [VERIFIED: Makefile:151] [VERIFIED: docker/dev-entrypoint.sh:53] [VERIFIED: 33-CONTEXT.md]
- **Changing Docker-internal `:4000` wiring:** `compose.yml` uses `web:4000`, Traefik load-balancer port `4000`, and an ephemeral loopback mapping `127.0.0.1::4000`; these are mechanisms, not stale browser-start docs. [VERIFIED: compose.yml:66] [VERIFIED: compose.yml:89] [VERIFIED: compose.yml:105]
- **Using `make nuke` as vague troubleshooting:** `make nuke` wipes named volumes for one instance and should only be documented with explicit scope. [VERIFIED: Makefile:89] [VERIFIED: 33-CONTEXT.md]
- **Reading or printing local secrets to improve the Secrets section:** Phase 32 explicitly avoided secret-bearing sources; Phase 33 should preserve that posture. [VERIFIED: 32-VERIFICATION.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dev URL discovery | Manual branch/hash URL construction in prose | `make url` / `make open` | The Makefile derives `COMPOSE_PROJECT_NAME` and `SCORIA_HOST`; hardcoded examples drift. [VERIFIED: Makefile:11] [VERIFIED: Makefile:97] |
| Native host startup | Ad hoc `PORT=... mix phx.server` instructions | `make dev` | `make dev` also starts the native DB helper and prints the native URL/DB settings. [VERIFIED: Makefile:147] |
| Stale-instance discovery | Manual `docker ps` grep recipes in docs | `make fleet` / `make doctor` | Existing targets already encode label-based discovery and route diagnostics. [VERIFIED: Makefile:29] [VERIFIED: Makefile:125] |
| Secret resolution | Custom shell wrappers that export plaintext keys | `op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- ...` | 1Password's command resolves secret references for the subprocess; Phase 32 intentionally avoided long-lived shell exports. [VERIFIED: docs/docker_dev_dx.md:184] [CITED: www.1password.dev/cli/reference/commands/run] |
| Planning sweep | Custom script that rewrites every hit | `rg` inventory plus human/context classification | Locked decisions allow implementation evidence and historical rationale while targeting stale verification/start instructions. [VERIFIED: 33-CONTEXT.md] |

**Key insight:** The dangerous drift is user-facing start/open/verify copy, not the low-level `mix phx.server` mechanism or Docker-internal `:4000` service wiring. [VERIFIED: 33-CONTEXT.md] [VERIFIED: Makefile:151] [VERIFIED: compose.yml:89]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None found for this docs/string-correction phase; the target strings are in repository docs/source/planning files, not DB keys or records. [VERIFIED: phase scope] | No data migration. |
| Live service config | None found; Traefik labels and Compose service ports intentionally remain unchanged. [VERIFIED: compose.yml:77] [VERIFIED: 33-CONTEXT.md] | No service patch. |
| OS-registered state | None found; no launchd/systemd/pm2/task registrations are part of the phase. [VERIFIED: codebase grep] | No OS re-registration. |
| Secrets/env vars | `.env`, `.envrc`, and `.env.op` are local/ignored patterns; no env var rename is required and `ANTHROPIC_API_KEY` stays the runtime variable. [VERIFIED: .env.example:11] [VERIFIED: .envrc.example:1] [VERIFIED: .env.op.example:1] | Preserve Phase 32 pattern; do not read secret-bearing local files. |
| Build artifacts | No `localhost:4000` / `mix phx.server` hits were found under `priv/static`; generated `priv/static/scoria/app.js` remains out of scope by locked decision. [VERIFIED: codebase grep] [VERIFIED: 33-CONTEXT.md] | No artifact migration. |

**Nothing found in category:** Stored data, live service config, OS-registered state, and generated build artifacts all require no migration beyond repository text edits. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Treating `localhost:4000` As Always Wrong

**What goes wrong:** An executor changes Docker service ports, Traefik labels, CI self-test ports, or `config/dev.exs` fallback while trying to remove stale docs copy. [VERIFIED: 33-CONTEXT.md]

**Why it happens:** The stale browser URL and the valid internal container listener both contain `4000`. [VERIFIED: compose.yml:66] [VERIFIED: config/dev.exs:33]

**How to avoid:** Only rewrite browser-start instructions; preserve explicitly qualified Docker-internal, Traefik service target, CI self-test, and ephemeral loopback references. [VERIFIED: 33-CONTEXT.md]

**Warning signs:** Diffs in `compose.yml`, `config/dev.exs`, `.github/workflows/ci.yml`, `Dockerfile.dev`, or Docker labels when the task was supposed to be docs/copy. [VERIFIED: 33-CONTEXT.md]

### Pitfall 2: Leaving Host Harness Defaults Behind

**What goes wrong:** Docs say `make dev` / `localhost:4799`, but `mix scoria.ui.shots`, `mix scoria.ui.e2e`, Playwright config, and `priv/repo/dev_seed.exs` still print or default to `localhost:4000/scoria`. [VERIFIED: lib/mix/tasks/scoria.ui.shots.ex:132] [VERIFIED: lib/mix/tasks/scoria.ui.e2e.ex:77] [VERIFIED: priv/repo/dev_seed.exs:1037]

**Why it happens:** Phase 29 explicitly deferred these code-adjacent user-facing defaults to DOCS/Phase 33. [VERIFIED: 29-CONTEXT.md]

**How to avoid:** Include D-19 surfaces in the plan unless deliberately split into a second Phase 33 plan. [VERIFIED: 33-CONTEXT.md]

**Warning signs:** `rg -n "localhost:4000/scoria|mix phx\\.server" lib/mix/tasks/scoria.ui.*.ex priv/dev priv/repo/dev_seed.exs` still reports stale Scoria dashboard defaults after docs are updated. [VERIFIED: codebase grep]

### Pitfall 3: Breaking the Gallery App While Fixing Scoria Docs

**What goes wrong:** The support-copilot gallery's `mix phx.server` gets replaced with Scoria repo `make dev`, even though the gallery is its own Phoenix app. [VERIFIED: docs/support_copilot_gallery.md:9] [VERIFIED: examples/support_copilot/README.md:10]

**Why it happens:** The same command string appears in both stale Scoria dashboard docs and correct gallery-app quickstarts. [VERIFIED: codebase grep]

**How to avoid:** Keep the gallery command but qualify it as `examples/support_copilot` app startup and name the gallery URLs `http://localhost:4010/` and `http://localhost:4010/scoria`. [VERIFIED: 33-CONTEXT.md] [VERIFIED: examples/support_copilot/README.md:13]

**Warning signs:** README/operator docs lose the gallery quickstart or claim the gallery runs through Scoria's Makefile. [VERIFIED: README.md:243] [VERIFIED: docs/operator_verification.md:192]

### Pitfall 4: Updating Archived History

**What goes wrong:** A blanket `.planning` replacement mutates milestone archives, debug history, memory, completed todos, or old audits. [VERIFIED: 33-CONTEXT.md]

**Why it happens:** `rg` without exclusions returns archived historical hits. [VERIFIED: codebase grep]

**How to avoid:** Use the active sweep globs with `!**/milestones/**`, `!**/debug/**`, `!**/memory/**`, and `!**/todos/completed/**`; then classify remaining hits. [VERIFIED: codebase grep]

**Warning signs:** Diffs under `.planning/milestones/**`, `.planning/debug/**`, `.planning/memory/**`, or `.planning/todos/completed/**`. [VERIFIED: codebase grep]

## Code Examples

### Canonical Docker Docs Copy

```markdown
Run `make proxy` once, `make up-build` on the first run, then `make up`.
Use `make url` or `make open` and open the printed
`http://<instance>.localhost/scoria` URL.
```

Source: locked Phase 33 command wording. [VERIFIED: 33-CONTEXT.md]

### Canonical Native Harness Copy

```markdown
Start the dashboard with `make dev`, then run:

```bash
mix scoria.ui.shots --url http://localhost:4799/scoria
mix scoria.ui.e2e --base-url http://localhost:4799/scoria
```
```

Source: locked Phase 33 command wording and current Makefile native defaults. [VERIFIED: 33-CONTEXT.md] [VERIFIED: Makefile:147]

### Active Planning Sweep

```bash
rg -n "mix phx\\.server|localhost:4000/scoria" .planning \
  -g '!**/milestones/**' \
  -g '!v*-MILESTONE-AUDIT.md' \
  -g '!**/debug/**' \
  -g '!**/memory/**' \
  -g '!**/todos/completed/**'
```

Source: locked Phase 33 verification recommendation, corrected to exclude nested `.planning/milestones/**` paths in this repo. [VERIFIED: 33-CONTEXT.md] [VERIFIED: codebase grep]

### Docs Contract Quick Check

```bash
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs
```

Source: existing CI policy-lane command and local green run: 56 tests, 0 failures. [VERIFIED: .github/workflows/ci-verify.yml:53] [VERIFIED: test run]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw `mix phx.server` for Scoria dashboard start/open docs | `make up` -> `make url` for Docker, `make dev` -> `localhost:4799` for native host work | Phases 29-30, 2026-06-18 | Docs must stop instructing Scoria browser startup through `localhost:4000/scoria`. [VERIFIED: 29-VERIFICATION.md] [VERIFIED: 30-VERIFICATION.md] |
| Static or fixed local host ports | Per-instance Traefik route plus ephemeral loopback fallback | Already implemented before Phase 33; hardened in Phase 29 | Multiple checkouts can run side by side; docs should teach instance route ownership. [VERIFIED: compose.yml:66] [VERIFIED: Makefile:97] |
| Vague cache statement | Four-row layer-invalidation table | Phase 31, 2026-06-18 | `docs/docker_dev_dx.md` should preserve the table while moving it into the `Caching guarantees` section. [VERIFIED: docs/docker_dev_dx.md:146] |
| Plaintext key example | `.env.op` secret references plus process-scoped `op run --env-file` | Phase 32, 2026-06-18 | Secrets section should stay process-scoped and avoid reading local secret-bearing files. [VERIFIED: docs/docker_dev_dx.md:162] |

**Deprecated/outdated:**
- `PORT=4010 mix phx.server` for Scoria e2e docs is stale; replace with `make dev` and `http://localhost:4799/scoria`. [VERIFIED: docs/uat_automation.md:33] [VERIFIED: 33-CONTEXT.md]
- `http://localhost:4000/scoria` as a Scoria browser dev-start URL is stale; keep `4000` only when explicitly internal/fallback/CI-qualified. [VERIFIED: 33-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact prose/section titles can be refined by the planner/executor as long as locked decisions hold. | User Constraints / Architecture Patterns | Low; this is direct discretion from context, not a technical uncertainty. [VERIFIED: 33-CONTEXT.md] |

## Open Questions

1. **RESOLVED: Code-adjacent harness copy is Plan 03.**
   - What we know: D-19 includes `lib/mix/tasks/scoria.ui.*.ex`, `priv/dev`, and `priv/repo/dev_seed.exs`, and D-20 protects generated/static and CI/container wiring. [VERIFIED: 33-CONTEXT.md]
   - Planner decision: Plan 03 owns the complete host screenshot/e2e harness copy/default update as three tasks: Mix task and seed copy, Playwright entrypoint defaults, and remaining e2e spec base URL constants. This keeps D-19 surfaces together while preserving D-20 protected Docker/internal wiring. [RESOLVED: 33-03-PLAN.md]

2. **RESOLVED: Active research rewrite scope is Plan 04 Task 2 plus final classification.**
   - What we know: D-13 includes `.planning/research/**`, and current hits exist in `ARCHITECTURE.md`, `FEATURES.md`, `PITFALLS.md`, `STACK.md`, and `SUMMARY.md`. [VERIFIED: codebase grep]
   - Planner decision: Plan 04 Task 2 rewrites active `.planning/research/*.md` guidance that still reads as current or recommended stale start copy. Plan 04 Task 3 then records final active-scope classification in `33-PLANNING-SWEEP.md`, distinguishing implementation evidence, current phase decision quotation, current phase verification pattern, quoted historical rationale, and defects fixed in the plan. [RESOLVED: 33-04-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `rg` | Drift inventory and gates | yes | ripgrep 15.1.0 | `grep -R`, slower. [VERIFIED: environment probe] |
| `git` | Instance derivation and context checks | yes | 2.41.0 | none needed. [VERIFIED: environment probe] |
| `make` | Source-of-truth command dry-runs | yes | GNU Make 3.81 | Direct recipe inspection if Make unavailable. [VERIFIED: environment probe] |
| `mix` | Policy-lane tests | yes | Erlang/OTP 28, Mix available | Static `rg` gates only if Mix unavailable. [VERIFIED: environment probe] |
| Docker / Compose | Optional live dev verification and source truth | yes | Docker 29.5.2 / Compose v5.1.3; daemon responded | Use `make -n` and static file checks if daemon unavailable. [VERIFIED: environment probe] |
| Node / npm | Harness context only | yes | Node v22.14.0 / npm 11.1.0 | Not required for docs-only verification unless running Playwright. [VERIFIED: environment probe] |

**Missing dependencies with no fallback:** none found. [VERIFIED: environment probe]

**Missing dependencies with fallback:** none found. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix project. [VERIFIED: mix.exs:1] |
| Config file | `test/test_helper.exs`; `SCORIA_LANE_CONTRACT_ONLY=true` avoids starting the app for policy-lane checks. [VERIFIED: test/test_helper.exs:1] |
| Quick run command | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` [VERIFIED: test run] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOCS-01 | Active docs and planning prose no longer instruct Scoria dev-start via `mix phx.server` -> `localhost:4000/scoria`; allowed `4000` contexts are qualified. | Static grep + policy-lane docs contracts | `rg -n "localhost:4000|mix phx\\.server" README.md docs/operator_verification.md docs/MAINTAINERS.md docs/uat_automation.md`; active `.planning` sweep with exclusions; `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | Existing tests yes; dedicated Phase 34 doc-contract not yet. [VERIFIED: test/scoria/ci_policy_contract_test.exs:790] |
| DOCS-02 | `docs/docker_dev_dx.md` opens with persona/JTBD + TL;DR and contains standalone Docker daily loop, Native dev server, Caching guarantees, Secrets, and Stale instance hygiene sections. | Static document inspection + policy-lane docs contract | `rg -n "^## (Docker daily loop|Native dev server|Caching guarantees|Secrets|Stale instance hygiene)" docs/docker_dev_dx.md`; policy-lane command above | Existing policy test yes; may need string updates if headings change. [VERIFIED: test/scoria/ci_policy_contract_test.exs:790] |

### Sampling Rate

- **Per task commit:** Run the targeted `rg` gate for touched docs/source plus `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs`. [VERIFIED: test run]
- **Per wave merge:** Run all Phase 33 active-doc, planning, and harness sweeps from D-26 through D-28. [VERIFIED: 33-CONTEXT.md]
- **Phase gate:** Policy-lane docs contract green plus zero unclassified stale hits in active docs/planning/harness surfaces. [VERIFIED: 33-CONTEXT.md]

### Wave 0 Gaps

- None for Phase 33 implementation. Existing `ci_policy_contract_test.exs` already has a Docker DX guide contract and refutes exact `http://localhost:4000/scoria` in `docs/docker_dev_dx.md`; DOCS-03's dedicated `docker_dx_doc_contract_test.exs` remains Phase 34 scope. [VERIFIED: test/scoria/ci_policy_contract_test.exs:790] [VERIFIED: ROADMAP.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No auth/session behavior changes in this docs phase. [VERIFIED: phase scope] |
| V3 Session Management | no | No browser session behavior changes. [VERIFIED: phase scope] |
| V4 Access Control | no | No authorization behavior changes. [VERIFIED: phase scope] |
| V5 Input Validation | limited | Treat URLs/commands as documentation strings; no new runtime input parser should be introduced. [VERIFIED: phase scope] |
| V6 Cryptography / Secrets | yes | Preserve Phase 32's process-scoped `op run --env-file` pattern; do not read or print secret-bearing local files. [VERIFIED: docs/docker_dev_dx.md:162] [VERIFIED: 32-VERIFICATION.md] |

### Known Threat Patterns for Docs / Dev-DX Copy

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret disclosure while "verifying" Secrets docs | Information Disclosure | Do not read `.env`, shell history, logs, screenshots, or process environments; verify only committed examples and docs. [VERIFIED: 32-VERIFICATION.md] |
| Dangerous cleanup guidance | Tampering / Denial of Service | Document `make nuke` only with explicit `INSTANCE`/Compose project scope; do not introduce global prune commands. [VERIFIED: Makefile:89] [VERIFIED: 33-CONTEXT.md] |
| Incorrect dev URL causes verifier to validate the wrong app | Spoofing / Tampering | Use `make url` for Docker and `make dev` for native; avoid hardcoded `localhost:4000/scoria` browser-start copy. [VERIFIED: Makefile:97] [VERIFIED: Makefile:147] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/33-doc-restructure-verification-copy-correction/33-CONTEXT.md` - locked decisions, sweep boundary, command wording, scope fences. [VERIFIED: codebase grep]
- `Makefile` - command and URL source of truth. [VERIFIED: codebase grep]
- `compose.yml`, `config/dev.exs`, `docker/dev-entrypoint.sh` - Docker/Phoenix internal port and banner truth. [VERIFIED: codebase grep]
- `docs/docker_dev_dx.md`, `README.md`, `docs/operator_verification.md`, `docs/MAINTAINERS.md`, `docs/uat_automation.md`, `docs/support_copilot_gallery.md` - current docs state and stale hits. [VERIFIED: codebase grep]
- `.planning/phases/29-*`, `30-*`, `31-*`, `32-*` summaries/verifications - carried-forward completed Stream A facts. [VERIFIED: codebase grep]
- `test/scoria/ci_policy_contract_test.exs`, `.github/workflows/ci-verify.yml`, `test/test_helper.exs` - validation architecture. [VERIFIED: codebase grep]

### Secondary (MEDIUM/LOW confidence official docs)

- Docker Compose project names - https://docs.docker.com/compose/how-tos/project-name/ [CITED: docs.docker.com/compose/how-tos/project-name]
- Docker Compose networking - https://docs.docker.com/compose/how-tos/networking/ [CITED: docs.docker.com/compose/how-tos/networking]
- Docker Compose service `expose` - https://docs.docker.com/reference/compose-file/services/#expose [CITED: docs.docker.com/reference/compose-file/services/#expose]
- Phoenix `mix phx.server` - https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Server.html [CITED: phoenix.hexdocs.pm/Mix.Tasks.Phx.Server.html]
- Phoenix endpoint config - https://phoenix.hexdocs.pm/Phoenix.Endpoint.html [CITED: phoenix.hexdocs.pm/Phoenix.Endpoint.html]
- 1Password secret references and `op run` - https://www.1password.dev/cli/secret-references and https://www.1password.dev/cli/reference/commands/run [CITED: www.1password.dev]

### Tertiary (LOW confidence)

- None used for prescriptive recommendations. [VERIFIED: research process]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - direct local files and environment probes establish Make/Docker/Phoenix/test commands; external docs only confirm general concepts. [VERIFIED: codebase grep]
- Architecture: HIGH - this is a repo-local documentation and dev-DX correction, with locked decisions from CONTEXT.md. [VERIFIED: 33-CONTEXT.md]
- Pitfalls: HIGH - stale hits and protected contexts were verified with `rg` against current repo files. [VERIFIED: codebase grep]

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 for local docs/source truth; re-run `rg` and `make -n` before implementation if the worktree changes. [VERIFIED: research process]
