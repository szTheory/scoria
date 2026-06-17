# Phase 29: Makefile hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 29-makefile-hardening
**Areas discussed:** Target taxonomy, nuke wipe mechanism, PORT threading, fleet + help
**Mode:** advisor (USER-PROFILE present; `opinionated` → `minimal_decisive`). User explicitly requested deep per-area subagent research and a one-shot coherent recommendation set. Four parallel `gsd-advisor-researcher` agents were spawned.

---

## Target taxonomy (clean/nuke vs existing down/reseed)

| Option | Description | Selected |
|--------|-------------|----------|
| A. `down` → delegating alias of `clean`; reseed stays DB-only | clean/nuke canonical; `down: clean`; reseed unchanged | ✓ |
| B. Drop `down`, keep only clean/nuke | Strict one-name-per-action; breaks muscle memory + removes the most recognizable compose verb | |
| (sub) Fold `reseed` into `nuke` | Simpler taxonomy but forces cold recompile on every slate reset (wipes cache volumes) | rejected |

**User's choice:** Option A. **Notes:** `down` already maps byte-for-byte to the DXCLI-02 `clean` definition, so it's a genuine two-names-for-one-action case → alias (delegating, can't drift). `reseed` kept distinct because nuke wipes deps/build/hex/mix caches; reseed must stay the fast warm-cache DB reset. Modeled on GNU clean/distclean tiered convention.

---

## `make nuke` volume-wipe mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| `docker compose down -v` + dynamic warning | Scoped by construction; drift-proof; never prune | ✓ |
| Explicit `docker volume rm $(PROJECT)_<name>...` | Mirrors reseed but hardcodes 6 names that drift; misses anonymous volumes | |
| `down --volumes --remove-orphans` | Adds orphan-container removal (orthogonal; widens blast radius) | |

**User's choice:** `down -v`. **Notes:** Compose namespaces volumes by `$(COMPOSE_PROJECT_NAME)`; `external` proxy network untouched. Warning enumerates volumes dynamically via `docker compose config --volumes | sed`. No TTY prompt (target name is the safety signal). Zero `prune` hits (DXCLI-02).

---

## PORT threading (native 4799)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Makefile-only SSOT (`PORT ?= 4799`; dev.exs default stays `"4000"`) | Literal 4799 only in Makefile; dev.exs stays a mechanism; zero Docker/CI blast radius | ✓ |
| B. Both (also bump dev.exs default → 4799) | Would silently re-port the Docker container (compose `web` sets no PORT) and break Traefik/web:4000/SHOTS_BASE_URL | rejected |

**User's choice:** Option A. **Notes:** CORRECTION to the original straw-man (which proposed bumping dev.exs). Research caught that the compose `web` service inherits the dev.exs default. `make dev` binds `PORT=$(PORT) mix phx.server`; `make dev PORT=5000` overrides. 4799 verified sane.

### Exhaustive 4000-occurrence change/leave classification (for the planner)

**CHANGE → 4799 (native `make dev` path):**

| File:line | Current | Action |
|---|---|---|
| `Makefile:73` (`shots-native`) | `--url http://localhost:4000/scoria` | → `http://localhost:$(PORT)/scoria` — required by DXCLI-01 |
| `config/dev.exs:~22` (comment) | `http://localhost:4000/scoria via mix phx.server` | → `http://localhost:4799/scoria via make dev` |
| `dev/dev_endpoint.ex:8` (moduledoc) | `http://localhost:4000/scoria` | → `http://localhost:4799/scoria` — required by DXCLI-01 |

**LEAVE → stays 4000 (Docker-internal — container listens on 4000):**

| File:line | Why leave |
|---|---|
| `compose.yml:5` (comment) | Explains why host port isn't fixed — still accurate |
| `compose.yml:~68` (`docker compose port web 4000` comment) | Container internal port |
| `compose.yml:~69` (`127.0.0.1::4000`) | Ephemeral host→container:4000 map |
| `compose.yml:~83` (`loadbalancer.server.port=4000`) | Traefik routes to container:4000 |
| `compose.yml:~98` (`SHOTS_BASE_URL http://web:4000/scoria`) | Docker shots reach `web:4000` |
| `compose.yml:~133` (critique `--url http://web:4000/scoria`) | Docker-internal |
| `Dockerfile.dev:~58` (`EXPOSE 4000`) | Declarative; container binds 4000 |
| `Makefile:52` (`url` target `docker compose port web 4000`) | Queries container's 4000 mapping |
| `config/dev.exs:33` (`System.get_env("PORT","4000")`) | The mechanism/fallback — deliberately keep 4000 |
| `config/dev.exs:~27,29` (`web:4000` comments) | Docker service:port refs |
| `.github/workflows/ci.yml:~56` (`PORT: 4000`) | CI sets its own PORT in a clean runner |
| `.github/workflows/ci.yml:~108` (`curl localhost:4000`) | CI self-consistent with its PORT |

**OUT OF SCOPE (Phase 33 / DOCS reqs — do NOT touch this phase):** mix-task default URLs (`scoria.ui.shots`/`scoria.ui.e2e` `opts[:url] || "http://localhost:4000/scoria"`), all `docs/`, `priv/dev/e2e/*.spec.mjs`, `priv/dev/shots.mjs`, `priv/repo/dev_seed.exs`, `docs/uat_automation.md`, `docs/MAINTAINERS.md`, `.planning/`.

**Not a port (false positives):** `duration_ms: 4000` / `estimated_tokens > 4000` in `lib/scoria_web/ui.ex`, approvals/prompt LiveViews, and a test fixture.

---

## `make fleet` + `make help`

| Option | Description | Selected |
|--------|-------------|----------|
| fleet: `--filter name=scoria- --filter label=traefik.enable=true` | One routable row per instance; project name == subdomain | ✓ |
| fleet: `--filter name=scoria-` only (straw-man) | Too noisy — returns db containers + unrelated `scoria-repro-pg2` (verified live) | rejected |
| fleet: `docker compose ls` | Substring name match; can't show Traefik host/port columns | rejected |
| help: standalone-comment awk + `index()` split, `.DEFAULT_GOAL := help` | Verified on GNU Make 3.81 + BSD awk; matches existing `## name: desc` convention | ✓ |
| help: canonical `target: ## desc` (`FS=":.*?## "`) | Printed nothing under 3.81; gawk `match(…,arr)` is a BSD-awk syntax error; needs rewriting all comments | rejected |

**User's choice:** label-filtered fleet + index()-awk help. **Notes:** REFINEMENT to the fleet straw-man. Both recipes toolchain-verified on macOS (the maintainer's stack). Running-only fleet (a shadowing instance is by definition running). Empty-state guard via `-q` id check ("No scoria instances running."). Cyan target color acceptable.

---

## Claude's Discretion

- Target placement/ordering within the file (group the destructiveness ladder; lead with `help`/`.DEFAULT_GOAL`).
- Keep help cyan color vs plain text (default: keep).
- Minor warning-copy wording (must name scope + irreversibility + cold-recompile cost).

## Deferred Ideas

- Launch banner / fallback URL / Traefik admin link / key-route list → DXCLI-05, Phase 30.
- Mix-task default URL correction + all `docs/`/`priv/dev/e2e`/`.planning/` `localhost:4000` copy → DOCS reqs, Phase 33.
- `uat_automation.md` native e2e port note (`PORT=4010` → `make dev`) → Phase 33.
- `--remove-orphans` on teardown targets — considered, omitted (orthogonal, widens blast radius).
