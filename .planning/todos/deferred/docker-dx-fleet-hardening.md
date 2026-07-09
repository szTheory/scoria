---
id: docker-dx-fleet-hardening
title: "Docker dev-DX fleet hardening — port-conflict-free multi-lib local DX"
status: deferred
created: 2026-06-13
deferred: 2026-07-09
priority: medium
resolves_phase: null
tags: [dx, docker, infra, cross-repo]
source: "Surfaced during Phase 16 (16-05 checkpoint) — user could not reach the dashboard through the wrong fixed localhost URL because the fleet owns :4000."
---

## Deferred Status

Deferred out of close-blocking todos at v3.4 closeout. The Scoria-local portions have mostly shipped
across v3.2, but the cross-repo fleet convergence remains a separate initiative and stays represented
in `PROJECT.md`, `STATE.md`, and `ROADMAP.md` deferred work.

## Why this exists

User runs **many Elixir/Phoenix OSS lib demos simultaneously** on one Mac (scoria,
rulestead, parapet, sigra, threadline, accrue, scrypath, mailglass…). They hit
**constant host-port conflicts** (esp. `:4000`, `:5432`, `:3000`, `:6379`) and want a
**hands-off, seamless, port-juggling-free** local DX with good Docker layer caching (no
dep refetch on style edits) and useful URLs printed on launch. Goal: "make this a great
DX, easy to use, hands-off, a joy to work with."

This is a **cross-repo initiative**, not Scoria-only. Scoria already has most of the
single-repo pieces; the remaining work is fleet-wide convergence + a few concrete bugs.

## What ALREADY exists in Scoria (do not rebuild)

Implemented 2026-06-04 (+ multi-instance pass, commit `cf9494d`):
- Traefik + `*.localhost` strategy: shared external `proxy` network, `make proxy` boots
  Traefik, browser reaches `http://<instance>.localhost/scoria`. DB/Redis NOT published
  (kills the :5432 collision class). Harness reaches app by compose service name.
- **Multi-instance:** `COMPOSE_PROJECT_NAME`/`SCORIA_HOST` derived from git branch
  (`scoria-<branch>`), no `container_name:`, interpolated Traefik labels. Two instances
  verified live through one Traefik. `INSTANCE=x make up` to override.
- **Caching:** bind-mount source + named volumes for deps/_build/.hex/.mix; BuildKit
  `--mount=type=cache`; `.dockerignore`; `FILE_SYSTEM_BACKEND=fs_poll` (macOS VM file
  events). pgvector pg16.
- **Asset hot-reload:** `dev/asset_watcher.ex` rebuilds bundle on css/js edit; `make dev`
  = native live-reload server.
- **DX surface:** `make up/up-d/down/logs/url/open/proxy/shots/critique`, launch banner,
  `docs/docker_dev_dx.md` (portable fleet standard).
- Hex packaging confirmed: none of dev/compose/Dockerfile/docs-dev ship to adopters.

## Concrete gaps / bugs found 2026-06-13 (the actionable backlog)

1. **`make dev` has no PORT default** → native harness tries `:4000` and collides with the
   fleet. Fix: default `PORT` to a non-4000 free port (e.g. 4799) in the `dev` target, or
   auto-pick a free port. (Memory already says "pass `PORT=`" — bake it into the target.)
2. **Fleet proxy-network convergence:** TWO proxy nets coexist (`proxy` vs
   `local-dev-proxy`). Scoria + the running Traefik are on `proxy` (good), but other libs
   may be on `local-dev-proxy`. Converge ALL libs on one shared `proxy` net.
3. **Cross-repo fixed ports:** `rulestead` publishes FIXED `:4000/:3000/:6379` — the main
   collision source. Migrate sibling repos to the same Traefik+`*.localhost`+unpublished-DB
   standard (`docs/docker_dev_dx.md` is the portable template).
4. **Stale instance hygiene:** an old `scoria_demo` compose project still answers
   `scoria.localhost` (pre-branch-scoping). Add a `make nuke`/clean target + doc the
   `docker compose down` per-instance + prune flow.
5. **SECURITY:** `.env` (gitignored, untracked — not in git history) holds a real-looking
   `ANTHROPIC_API_KEY` in plaintext. **Rotate it.** Consider a secrets pattern (1Password
   CLI / direnv) for the fleet.
6. **Doc/plan drift:** Phase 33 folded the Scoria-local verification-copy cleanup into
   the active milestone: GSD plans + agents now tell verifiers to use `make up` /
   `make dev` plus the real branch-scoped endpoint instead of the old fixed-port
   native start path. Keep the fleet-wide version of this rule in the cross-repo
   standard. Update verification copy to `make up` / `make dev` + the real
   `http://<instance>.localhost/scoria` URL, and print a **route list** in the launch
   banner (copy-paste-able key routes) so it's obvious where to poke around.
7. **Dockerfile caching audit:** confirm a CSS/HEEx-only edit does NOT trigger dep refetch
   or full recompile (user's explicit worry). Validate layer ordering empirically.

## How to approach (per user's standing instruction)

Run this as a **dedicated initiative** (its own session — NOT inside a feature phase).
Research the alternatives **with subagents**: Traefik vs Caddy vs nginx-proxy vs
docker-compose profiles; compose project namespacing; `*.localhost` vs dnsmasq vs
/etc/hosts; pros/cons/footguns/anti-patterns/lessons-learned for a multi-lib local fleet.
Deliverable: a systematic, comprehensive, low-maintenance fleet standard + docs written
with reader empathy (persona/JTBD, clear gameplan summary at top, digestible chunks).

Suggested entry: `/gsd:new-milestone` (or `/gsd:explore`) scoped to "Docker dev-DX fleet
standard", seeded with this file + the [[v3-docker-dx-decisions]] memory.
