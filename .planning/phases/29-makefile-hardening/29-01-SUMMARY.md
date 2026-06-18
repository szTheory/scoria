---
phase: 29-makefile-hardening
plan: "01"
subsystem: infra
tags: [makefile, docker, docker-compose, dev-dx, gnu-make, awk]

requires: []
provides:
  - "Makefile .DEFAULT_GOAL := help — bare make self-documents via awk ## parser"
  - "PORT ?= 4799 in Makefile — non-colliding native dev port, overridable"
  - "make clean + make down (alias) — stop stack, keep volumes"
  - "make nuke — wipe all named volumes scoped to COMPOSE_PROJECT_NAME, named-scope warning"
  - "make fleet — dual-filter docker ps with empty-state guard"
  - "config/dev.exs and dev/dev_endpoint.ex doc comments updated to 4799"
affects: [30-launch-banner, 33-docs-update]

tech-stack:
  added: []
  patterns:
    - "Destructiveness ladder: clean (stop) < reseed (DB-only) < nuke (wipe all volumes)"
    - "Delegating alias pattern: down: clean (prerequisite only, no copied recipe body)"
    - "Self-documenting Makefile: ## name: desc comments parsed by awk index() split"
    - "Empty-state guard for docker ps: -q pre-check avoids header-only false positive"

key-files:
  created: []
  modified:
    - Makefile
    - config/dev.exs
    - dev/dev_endpoint.ex

key-decisions:
  - "PORT ?= 4799 lives in Makefile only (SSOT); config/dev.exs:33 default stays 4000 (D-08: changing it breaks Traefik/container)"
  - "make nuke uses docker compose down -v (Compose-scoped); never docker volume prune / system prune"
  - "down: clean uses prerequisite alias (no copied body) so the two targets cannot drift"
  - "fleet dual-filter: name=scoria- AND label=traefik.enable=true (name-only too noisy)"
  - "awk index() split for help parser — BSD awk compatible; gawk 3-arg match is a syntax error"
  - "dev comment collapsed from 2 lines to 1 to avoid truncated help entry"

patterns-established:
  - "Makefile destructiveness ladder (clean < reseed < nuke) mirrors GNU clean/distclean convention"
  - "All new targets carry ## name: desc one-liner so make help auto-includes them"

requirements-completed: [DXCLI-01, DXCLI-02, DXCLI-03, DXCLI-04]

duration: 3min
completed: 2026-06-18
status: complete
---

# Phase 29 Plan 01: Makefile Hardening Summary

**Makefile hardened as single dev entry point: PORT 4799 threading, clean/nuke destructiveness ladder, fleet dual-filter, awk help parser — bare `make` self-documents all 17 targets**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-06-18T00:43:16Z
- **Completed:** 2026-06-18T00:46:11Z
- **Tasks:** 4 (executed as one ordered Makefile pass + 2 doc-comment edits)
- **Files modified:** 3

## Accomplishments

- `make help` (bare `make`) prints awk-parsed table of all 17 targets including all 5 new ones, with cyan formatting
- `make dev` binds PORT=4799 by default (`SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server`); overridable via `make dev PORT=5000`
- `make clean` / `make down` stop stack keeping named volumes; `down` is a body-less alias of `clean` (no drift)
- `make nuke` enumerates real volumes via `docker compose config --volumes` + sed, warns with `COMPOSE_PROJECT_NAME` scope, then runs `docker compose down -v`; no global prune, no TTY prompt
- `make fleet` uses dual filter (`name=scoria-` + `label=traefik.enable=true`) with `-q` pre-check empty-state guard; exits 0

## Task Commits

All four tasks were executed as a single ordered Makefile pass per plan design:

1. **Task 1: PORT 4799 threading (DXCLI-01)** - `b4e8b3d` (feat) — Makefile PORT default, dev + shots-native recipes, config/dev.exs + dev/dev_endpoint.ex doc comments
2. **Task 2: clean + down alias + nuke (DXCLI-02)** — verified in `b4e8b3d` (same ordered pass)
3. **Task 3: fleet target (DXCLI-03)** — verified in `b4e8b3d` (same ordered pass)
4. **Task 4: .DEFAULT_GOAL + help + .PHONY + dev-comment collapse (DXCLI-04)** — verified in `b4e8b3d` (same ordered pass)

**Plan metadata:** *(docs commit follows)*

## Files Created/Modified

- `/Users/jon/projects/scoria/Makefile` — Added .DEFAULT_GOAL, .PHONY updates, help/fleet targets, PORT variable, clean/down alias/nuke targets, updated dev and shots-native recipes, collapsed dev ## comment
- `/Users/jon/projects/scoria/config/dev.exs` — L22 comment updated: `4000/scoria via \`mix phx.server\`` → `4799/scoria via \`make dev\``; L33 default "4000" unchanged
- `/Users/jon/projects/scoria/dev/dev_endpoint.ex` — Moduledoc L8: `localhost:4000/scoria` → `localhost:4799/scoria`

## Decisions Made

- Implemented all 4 tasks as a single ordered Makefile pass (plan-specified; all tasks edit the same file)
- `dev` comment collapsed from 2 lines to 1: `## dev: native host server with live reload (PORT=4799 by default)` — Claude's Discretion per RESEARCH Pitfall 2
- Kept cyan `\033[36m` formatting in help output — Claude's Discretion default

## Deviations from Plan

None — plan executed exactly as written. All decisions were pre-locked (D-01..D-15) and followed verbatim from the CONTEXT.md and RESEARCH.md verified recipes.

## Issues Encountered

The automated verify command in Task 1 uses `grep -q "PORT=\$(PORT) mix phx.server"` which fails because shell expands `\$` to `$`, making grep treat it as a regex end-of-line anchor. The file content is correct (`PORT=$(PORT) mix phx.server` verified with `-F` fixed-string grep). This is a plan verify command bug, not an implementation issue.

## User Setup Required

None — no external service configuration required. All changes are dev-tooling Makefile targets and doc comments.

## Next Phase Readiness

- Phase 30 (DXCLI-05: launch banner / populated fallback URL) can now build on the `PORT ?= 4799` variable and the `make dev` entry point established here
- Phase 33 (doc update pass): `localhost:4000` copy in `docs/`/`priv/dev/e2e`/`.planning/` is the deferred item; native-path URLs now correctly reference 4799
- `make fleet` already shows `scoria-v217-brand-vesicle` running on the dev machine — no stale instances shadowing routes

## Self-Check: PASS

- `Makefile` exists and contains all required content: verified
- `config/dev.exs` updated at L22, L33 unchanged: verified  
- `dev/dev_endpoint.ex` moduledoc updated: verified
- Commit `b4e8b3d` exists: verified
- `make help` runs, `make fleet` exits 0: verified

---
*Phase: 29-makefile-hardening*
*Completed: 2026-06-18*
