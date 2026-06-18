---
phase: 29-makefile-hardening
reviewed: 2026-06-17T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - Makefile
  - config/dev.exs
  - dev/dev_endpoint.ex
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 29: Code Review Report

**Reviewed:** 2026-06-17
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the Makefile hardening changes plus the doc-comment-only edits in
`config/dev.exs` and `dev/dev_endpoint.ex`. I focused on the areas the phase
flagged: shell-injection / unsafe expansion, destructive-command scoping,
BSD-vs-GNU awk/make portability, PORT single-source-of-truth, and doc/behavior
agreement.

**The destructive-command safety is sound.** `nuke` uses `docker compose down -v`,
which is scoped to the active Compose project (`COMPOSE_PROJECT_NAME=$(INSTANCE)`)
— it is NOT a global `docker system prune` / `docker volume prune`, so it cannot
touch other branches' or unrelated projects' volumes. The pre-action echo block
correctly enumerates only this instance's volumes via `docker compose config
--volumes`. `reseed` likewise scopes its `docker volume rm` to
`$(COMPOSE_PROJECT_NAME)_pgdata`. No destructive-scope defect found.

**Portability is sound.** I executed the `help` awk parser against the actual
Makefile under the darwin system awk (`awk version 20200816`, the BSD/onetrueawk
build) and it produced correct, aligned output for all 17 targets. The parser
uses only `substr`/`index`/`printf` — all POSIX awk, no GNU `gensub`/`gawk`
extensions. `.DEFAULT_GOAL` is supported by GNU Make 3.81. No portability defect.

**No shell-injection vector** was introduced: the new recipes (`fleet`, `nuke`,
`help`) interpolate only Make-controlled variables (`$(COMPOSE_PROJECT_NAME)`,
`$(MAKEFILE_LIST)`) and `docker`-emitted output, never untrusted external input.

The two warnings below are doc/behavior mismatches around the PORT
single-source-of-truth, which the phase explicitly asked to verify. They are
genuine correctness-of-documentation defects, not style nits.

## Warnings

### WR-01: PORT single-source-of-truth breaks for direct `mix phx.server` — config defaults to 4000, not 4799

**File:** `config/dev.exs:33` (doc claims at `config/dev.exs:22` and `dev/dev_endpoint.ex:8`)
**Issue:** The Makefile establishes `PORT ?= 4799` as the single source of truth
and threads it through `make dev` (`PORT=$(PORT) mix phx.server`) and
`shots-native`. But the runtime port actually comes from
`config/dev.exs:33`: `port: String.to_integer(System.get_env("PORT", "4000"))`.
The fallback there is **4000**, not 4799. So the "single source of truth" only
holds when the server is launched via `make dev`. A developer who runs
`mix phx.server` directly (a documented, supported path — the moduledoc and
config comment both say the harness boots via `mix phx.server`) gets port
**4000**, while the doc comments at `config/dev.exs:22`
("`http://localhost:4799/scoria`") and `dev/dev_endpoint.ex:8`
("`http://localhost:4799/scoria`") assert 4799. The documentation is now wrong
for the non-Make path, and `shots-native` (which hardcodes `$(PORT)`=4799 in its
URL) will fail to connect to a server that a developer started with a bare
`mix phx.server`.

There are now effectively two sources of truth for the dev port (Makefile=4799,
config=4000) that only agree by side effect of how `make dev` is invoked.

**Fix:** Make the config fallback match the documented canonical port so the SSOT
holds regardless of launch path:
```elixir
http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4799"))],
```
If 4000 must remain the bare default (e.g. to match the dockerized `web:4000`
service), then instead correct the doc comments to state that 4799 is a
Make-only convention and that direct `mix phx.server` binds 4000.

### WR-02: `shots-native` assumes a server is already running on `$(PORT)` but neither boots one nor documents the dependency

**File:** `Makefile:101-103`
**Issue:** `mix scoria.ui.shots` does **not** boot a web server (confirmed in
`lib/mix/tasks/scoria.ui.shots.ex` / `scoria.ui.e2e.ex:14`: "this task does not
boot a web server"). The `shots-native` recipe runs `mix scoria.ui.shots --url
http://localhost:$(PORT)/scoria` with no prerequisite that starts `dev`, and the
help text ("run the harness on the host against a local `mix phx.server`")
implies but does not enforce that the operator has already started `make dev` in
another terminal. If they haven't — or started a bare `mix phx.server` on 4000
(see WR-01) — the harness silently targets a dead/wrong port. This is a
foot-gun in a target whose whole purpose is to be the "single trustworthy dev
entry point."

**Fix:** Either make the dependency explicit in the help text, e.g.
```make
## shots-native: capture against an already-running `make dev` (run that first)
```
or add a connectivity preflight so the failure is legible rather than a Playwright
timeout:
```make
shots-native:
	@curl -sf -o /dev/null http://localhost:$(PORT)/scoria \
	  || { echo "No dev server on :$(PORT). Run 'make dev' first."; exit 1; }
	mix scoria.ui.shots --url http://localhost:$(PORT)/scoria
```

## Info

### IN-01: `PORT ?= 4799` is defined mid-file, after two targets that don't use it

**File:** `Makefile:33`
**Issue:** `PORT ?= 4799` sits between the `fleet` target (line 23-31) and the
`proxy` target, while the identity variables (`INSTANCE`, `COMPOSE_PROJECT_NAME`,
`SCORIA_HOST`) are grouped at the top (lines 11-14). Make evaluates all variable
assignments before running recipes, so placement is functionally harmless, but
scattering the single-source-of-truth knob away from the other config variables
hurts discoverability for the next maintainer — defeating part of the phase's
"single trustworthy entry point" goal.

**Fix:** Move `PORT ?= 4799` up next to the other exported identity/config
variables (after line 14) so all tunable defaults live in one block.

### IN-02: `nuke` confirmation banner is printed but `down -v` runs unconditionally — no actual confirmation gate

**File:** `Makefile:71-77`
**Issue:** The `nuke` recipe echoes a prominent "NUKE: irreversibly deleting ALL
named volumes" banner and enumerates the volumes, then immediately executes
`docker compose down -v` with no interactive confirmation or
`--dry-run`-style guard. The banner reads like a prompt ("irreversibly
deleting") but there is no pause — a mistyped `make nuke` (one char from the
common `make up`) destroys the instance's DB and caches instantly. The scoping
is correct (so this is Info, not a Warning), but the banner's wording implies a
safety gate that does not exist.

**Fix:** Either add a confirmation gate, e.g.
```make
nuke:
	@echo "NUKE: irreversibly deleting ALL named volumes for '$(COMPOSE_PROJECT_NAME)'."
	@read -p "       Type the instance name to confirm: " ans; \
	 [ "$$ans" = "$(COMPOSE_PROJECT_NAME)" ] || { echo "Aborted."; exit 1; }
	docker compose down -v
```
or soften the banner wording to past/imperative ("Wiping ...") so it doesn't
read as an unfulfilled prompt.

### IN-03: `fleet` dual-filter requires BOTH `name=scoria-` and the traefik label — undocumented coupling

**File:** `Makefile:24,29`
**Issue:** Both the existence check (line 24) and the display command (line 29)
AND-combine `--filter name=scoria-` with `--filter label=traefik.enable=true`.
A scoria instance started without the traefik label (e.g. a manual `docker run`
for debugging, or a compose override that disables traefik) will be invisible to
`fleet`, yet `fleet`'s stated purpose is to "spot a stale one shadowing your
route." A stale container holding the route but lacking the label would be
exactly the case the operator is hunting and `fleet` would hide it. The
name-prefix filter alone would catch it.

**Fix:** Consider filtering on `name=scoria-` only, or document that `fleet`
intentionally lists only traefik-enabled instances:
```make
## fleet: list traefik-routed scoria-* instances (label-gated)
```

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
