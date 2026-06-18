# Phase 29: Makefile hardening - Research

**Researched:** 2026-06-17
**Domain:** GNU Make / shell scripting / Docker Compose dev-DX
**Confidence:** HIGH

## Summary

The decisions in CONTEXT.md (D-01..D-15) are fully self-consistent, toolchain-verified, and
ready for planning. This research phase confirms the live state of every file the decisions
reference, surfaces exact line numbers for every edit, identifies one notable structural
detail (the `dev` target has a two-line `##` comment block that needs collapsing to one
line), and certifies that zero locked decisions need reopening.

The Makefile currently has 73 lines, 13 targets, and a single `.PHONY` line on line 2. No
`.DEFAULT_GOAL`, no `help` target, no `clean`, `nuke`, or `fleet` target exists today.
`proxy` is the current first target (line 16) and is therefore the implicit default — bare
`make` today runs `proxy`, not help. The awk parser from D-14 was executed against the live
file and produces correct output for all 13 existing targets. Five named volumes are defined
in `compose.yml`: `pgdata`, `deps`, `build`, `hex`, `mix`, `shots_node_modules` (6 total).

The `config/dev.exs` PORT default on line 33 reads `System.get_env("PORT", "4000")` and
MUST NOT change (D-08 confirmed). The comment on line 22 and the `dev_endpoint.ex` moduledoc
on line 8 are the only text edits outside the Makefile.

**Primary recommendation:** Execute the locked D-01..D-15 plan exactly as written. No
research-driven changes to the decision set.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: 3-rung destructiveness ladder — `clean` (stop, keep volumes) < `reseed` (DB-only) < `nuke` (wipe all named volumes)
- D-02: `clean` body = existing `down` body (`docker compose down`); `down: clean` delegating alias (prerequisite, not copied recipe)
- D-03: `reseed` stays as-is; must NOT fold into `nuke`
- D-04: Canonical `##` help wording for all new + aliased targets (exact copy from CONTEXT.md)
- D-05: `nuke` uses `docker compose down -v`; never `docker volume rm` name lists; NEVER `docker system prune` / `docker volume prune`
- D-06: `nuke` prints dynamic warning via `docker compose config --volumes | sed 's/^/         - $(COMPOSE_PROJECT_NAME)_/'`; no TTY prompt
- D-07: `PORT ?= 4799` in Makefile; `dev` recipe = `SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server`
- D-08: `config/dev.exs:33` default `"4000"` STAYS — changing it would break Docker/Traefik/SHOTS_BASE_URL
- D-09: `shots-native` → `http://localhost:$(PORT)/scoria`; `config/dev.exs:~L22` comment → `http://localhost:4799/scoria via make dev`; `dev/dev_endpoint.ex` moduledoc line 8 → `http://localhost:4799/scoria`
- D-10: ALL Docker-internal `:4000` references STAY (compose.yml, Dockerfile.dev, CI)
- D-11: Port 4799 is confirmed sane (unprivileged, not IANA-common, outside macOS ephemeral range)
- D-12: `fleet` filters `--filter name=scoria- --filter label=traefik.enable=true`; empty-state guard via `-q` pre-check; format uses `com.docker.compose.project` label
- D-13: `help` uses `.DEFAULT_GOAL := help` + standalone-comment awk with `index()` split; `.DEFAULT_GOAL`/`help` lead the file
- D-14: Verified recipes for `help` and `fleet` (macOS GNU Make 3.81 / BSD awk / darwin) — exact body in CONTEXT.md
- D-15: `.PHONY` updated to add `help fleet clean nuke`; every new target carries its `##` line

### Claude's Discretion
- Exact placement/ordering of new targets within the file (group destructiveness ladder; `help`/`.DEFAULT_GOAL` lead)
- Whether to keep help cyan color or emit plain text (default: keep cyan)
- Minor warning-copy wording (must name scope + irreversibility + cold-recompile cost)

### Deferred Ideas (OUT OF SCOPE)
- Launch banner / fallback URL / Traefik admin link / key-route list → DXCLI-05, Phase 30
- Mix-task default URL correction + all `docs/`/`priv/dev/e2e`/`.planning/` `localhost:4000` copy → DOCS reqs, Phase 33
- `uat_automation.md` native e2e port note → Phase 33
- `--remove-orphans` on teardown targets — omitted (orthogonal, widens blast radius)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DXCLI-01 | `make dev` binds `PORT ?= 4799` (non-4000 default); `shots-native` URL updated to `$(PORT)`; `dev_endpoint.ex` doc comment updated | D-07, D-09 — exact edit locations confirmed below |
| DXCLI-02 | `make clean` (stop, keep volumes) + `make nuke` (wipe named volumes), scoped via `$(COMPOSE_PROJECT_NAME)`, no prune; `nuke` prints named-scope warning, no TTY prompt | D-02, D-05, D-06 — recipes verified |
| DXCLI-03 | `make fleet` lists running `scoria-*` instances with Traefik-label filter | D-12, D-14 — recipe verified on macOS |
| DXCLI-04 | Bare `make` prints help derived from `##` comments via `.DEFAULT_GOAL := help` | D-13, D-14 — awk parser verified live |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Port default (4799) | Makefile / dev harness | — | Native-path-only concern; Docker path is unaffected and self-contained |
| Cleanup scoping | Docker Compose (project namespace) | Makefile (invocation) | Compose project name IS the scope; Makefile passes it via env |
| Fleet visibility | Docker daemon (ps filter) | Makefile (UX wrapper) | `docker ps` is the authoritative view; Makefile is the ergonomic entry point |
| Help discoverability | Makefile (`.DEFAULT_GOAL`) | — | Pure Makefile feature; no external dependency |
| Doc comment accuracy | Source files (`dev.exs`, `dev_endpoint.ex`) | — | Comments must match the runtime behavior documented in the Makefile |

## Live Codebase State (Verified Against Disk)

### Current Makefile — complete target inventory

[VERIFIED: disk read]

| Line | Target / Directive | Current State |
|------|--------------------|---------------|
| 2 | `.PHONY` | `proxy up up-d down logs url open dev seed reseed shots critique shots-native` — **missing** `help fleet clean nuke` |
| 16 | `proxy:` | First target → implicit default today (bare `make` runs proxy); `.DEFAULT_GOAL` absent |
| 31 | `down:` | Body: `docker compose down` — this is the body `clean` will adopt (D-02 confirmed) |
| 43 | `reseed:` | Body: `docker compose down` / `docker volume rm $(COMPOSE_PROJECT_NAME)_pgdata` / `$(MAKE) up-d` — stays unchanged |
| 52 | `url:` | `docker compose port web 4000` — stays (Docker-internal, D-10) |
| 58–59 | `## dev:` | **Two-line comment block** (lines 58–59) — see note below |
| 61 | `dev:` body | `SCORIA_DEV_LIVE_RELOAD=1 mix phx.server` — changes to `SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server` |
| 73 | `shots-native:` body | `mix scoria.ui.shots --url http://localhost:4000/scoria` — changes to `http://localhost:$(PORT)/scoria` |

**No** `help`, `fleet`, `clean`, or `nuke` target exists. **No** `.DEFAULT_GOAL` exists. **No** `PORT ?=` line exists. **No** `volume prune` or `system prune` string exists. Total: 73 lines.

### The `## dev:` two-line comment — action required

Lines 58–59 currently read:
```
## dev: native host server with live browser reload (for CSS/JS iteration;
##      the asset watcher rebuilds the bundle, live reload refreshes the page)
```

The awk parser (`^## [a-zA-Z0-9_-]+:`) correctly ignores line 59 (it doesn't match the
pattern). The `help` output for `dev` will read: `native host server with live browser
reload (for CSS/JS iteration;` — truncated mid-sentence. The planner must decide whether
to collapse this to a single `##` line or leave it as-is (the continuation line is
harmless for the parser but aesthetically imperfect in the help output). This is a
**Claude's Discretion** call — suggested fix: shorten to one line, e.g.:
```make
## dev: native host server with live reload (CSS/JS iteration; PORT=4799 by default)
```

### `config/dev.exs` edit location — confirmed

[VERIFIED: disk read]

| Line | Content | Action |
|------|---------|--------|
| 22 | `# Serves the Scoria dashboard at http://localhost:4000/scoria via \`mix phx.server\`` | Change: `http://localhost:4799/scoria via \`make dev\`` |
| 33 | `http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))],` | **LEAVE** — D-08 |

### `dev/dev_endpoint.ex` edit location — confirmed

[VERIFIED: disk read]

| Line | Content | Action |
|------|---------|--------|
| 7–8 | `…`mix phx.server\` serves the\ndashboard at \`http://localhost:4000/scoria\`` | Change line 8: `http://localhost:4799/scoria` |
| 16 | `…running under \`mix phx.server\`.` | **LEAVE** — describes how the server works, not a URL instruction |

### `compose.yml` — Docker-internal :4000 references that STAY

[VERIFIED: disk read]

| Line | Reference | Status |
|------|-----------|--------|
| 69 | `- "127.0.0.1::4000"` | LEAVE — ephemeral host→container:4000 |
| 83 | `traefik.http.services.…loadbalancer.server.port=4000` | LEAVE — Traefik routes to container |
| 98 | `SHOTS_BASE_URL: http://web:4000/scoria` | LEAVE — Docker-internal shots path |
| 133 | `"--url", "http://web:4000/scoria"` (critique command) | LEAVE — Docker-internal |

Named volumes in compose.yml (what `docker compose down -v` will wipe, scoped by project name): `pgdata`, `deps`, `build`, `hex`, `mix`, `shots_node_modules`.

## Standard Stack

No external packages are installed by this phase. All changes are:
1. Makefile edits (shell/make syntax)
2. Text comment edits in two Elixir source files

**Toolchain already present on disk:**
- GNU Make 3.81 [VERIFIED: `make --version`]
- BSD awk (macOS default — the D-14 recipes are verified against this)
- Docker Compose (invoked by existing targets — already in use)

## Package Legitimacy Audit

Not applicable — this phase installs no external packages.

## Architecture Patterns

### System Architecture Diagram

```
make (no args)
    └─► .DEFAULT_GOAL := help
            └─► awk parses MAKEFILE_LIST for ^## [name]: desc lines
                    └─► prints formatted target list to stdout

make dev
    ├─► PORT ?= 4799 (Makefile SSOT)
    └─► SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server
            └─► ScoriaWeb.DevEndpoint binds 0.0.0.0:$(PORT)
                    └─► http://localhost:4799/scoria

make clean / make down
    └─► docker compose down
            └─► stops containers, keeps named volumes
                    (scoped to $(COMPOSE_PROJECT_NAME) = scoria-<branch>)

make nuke
    ├─► echo warning with $(COMPOSE_PROJECT_NAME)
    ├─► docker compose config --volumes | sed (enumerate volumes)
    └─► docker compose down -v
            └─► stops containers + wipes ALL named volumes
                    (scoped by Compose project name; external proxy network untouched)

make fleet
    ├─► docker ps --filter name=scoria- --filter label=traefik.enable=true -q
    │       ├─[empty]─► "No scoria instances running."
    │       └─[ids]──► docker ps ... --format 'table {{.Label ...}}\t{{.Status}}\t{{.Ports}}'
```

### Recommended Makefile Structure After This Phase

```makefile
# Scoria dev DX shortcuts. ...
.DEFAULT_GOAL := help
.PHONY: proxy up up-d down logs url open dev seed reseed shots critique shots-native help fleet clean nuke

# --- Per-instance identity block (lines 10-13, unchanged) ---

## help: print this help (the default target)
help:
    @echo "..."
    @awk '...' $(MAKEFILE_LIST)

## fleet: list running scoria-* instances ...
fleet:
    @names=$$(docker ps ...); ...

PORT ?= 4799

## proxy: ...        (existing targets, unchanged)
...

## clean: stop this instance's stack (keeps named volumes/caches)
clean:
    docker compose down

## down: alias of clean
down: clean

## reseed: ...       (existing body, unchanged)
reseed:
    ...

## nuke: stop + WIPE all of this instance's named volumes (cold rebuild next boot)
nuke:
    @echo "NUKE: ..."
    @docker compose config --volumes | sed ...
    docker compose down -v
```

### Anti-Patterns to Avoid

- **`docker system prune` / `docker volume prune` in any target:** Daemon-global; destroys sibling repos' volumes. DXCLI-02 forbids. The grep check `grep -n "volume prune\|system prune" Makefile` must return zero.
- **Hardcoded volume name lists in `nuke`:** E.g., `docker volume rm $(PROJ)_pgdata $(PROJ)_deps …` — drifts when `compose.yml` changes. Use `docker compose down -v`.
- **Copying `down`'s body into `clean`:** Creates drift. Use `down: clean` as a prerequisite alias.
- **`--remove-orphans` on any teardown target:** Widens blast radius; deferred by decision.
- **Bumping `config/dev.exs` PORT default to 4799:** Silently moves the container listener off 4000, breaking Traefik.
- **Interactive TTY prompt in `make nuke`:** Breaks non-TTY/CI invocations. The target name is the safety signal.
- **gawk `match($0, re, arr)` 3-arg form in awk:** BSD awk syntax error. Use `index()` as in D-14.
- **`FS=":.*?## "` help pattern:** Printed nothing under GNU Make 3.81 with existing `## name: desc` convention.
- **`docker compose ls` for fleet:** Substring match; can't surface Traefik host/port columns; returns stale entries.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Volume scoping to project | Explicit `docker volume rm $(PROJECT)_pgdata $(PROJECT)_deps …` | `docker compose down -v` | Compose namespaces by project name; hand-rolled lists drift when compose.yml changes |
| Help discoverability | A separate `help.sh` or hardcoded echo list | `awk` over `MAKEFILE_LIST` | Self-documenting; new targets auto-appear if they carry `## name: desc` |
| Fleet enumeration | Custom scripts querying Docker API | `docker ps` with `--filter label=` | Docker's built-in filter handles multi-instance; name-only filter is too noisy (verified) |

**Key insight:** Compose's project-name scoping is the correctness guarantee for all teardown operations. Never fight it.

## Common Pitfalls

### Pitfall 1: `.DEFAULT_GOAL` placement — must precede all targets
**What goes wrong:** If `.DEFAULT_GOAL := help` appears after the first target definition (even after a non-target block like variable assignments), GNU Make 3.81 may ignore it.
**Why it happens:** Make processes `.DEFAULT_GOAL` only if set before any target is seen in some implementations.
**How to avoid:** Place `.DEFAULT_GOAL := help` and the `help` target at the very top of the file, before the identity block.
**Warning signs:** Bare `make` runs `proxy` instead of `help`.

**CONFIRMED SAFE:** The identity block (lines 4–13) is all variable assignments — no target definitions. `.DEFAULT_GOAL := help` can safely precede it on line 1, OR be placed after line 13 but before `proxy:` on line 16. Either placement works because no target has been seen yet. The plan should place it at the very top for clarity.

### Pitfall 2: `## dev:` two-line comment produces truncated help entry
**What goes wrong:** The awk parser emits `native host server with live browser reload (for CSS/JS iteration;` — a sentence fragment — for the `dev` target.
**Why it happens:** The continuation line `##      the asset watcher…` doesn't match `^## [a-zA-Z0-9_-]+:` so it's skipped; the first line ends mid-sentence.
**How to avoid:** Collapse the two-line `## dev:` comment to one line that fits naturally. This is a Claude's Discretion call (suggested: `## dev: native host server with live reload (PORT=4799 by default)`).
**Warning signs:** `make help` shows a sentence ending with a semicolon for `dev`.

### Pitfall 3: `.PHONY` ordering — new targets must be added, not replace
**What goes wrong:** Forgetting to add `help fleet clean nuke` to `.PHONY` while adding the targets.
**Why it happens:** Copy-paste error or incremental edits leaving `.PHONY` stale.
**How to avoid:** The `.PHONY` line must list all 4 new targets. D-15 specifies exactly this. Verify with `grep "PHONY" Makefile`.
**Warning signs:** `make clean` triggers a "Nothing to be done for 'clean'" if a file named `clean` ever exists.

### Pitfall 4: `docker ps --format table` always emits a header row
**What goes wrong:** `|| echo "No instances"` never fires even when docker ps returns only the header.
**Why it happens:** `docker ps` with `--format table` exits 0 and writes a header even with zero results.
**How to avoid:** Pre-check with `-q` (IDs only): if empty → print "No scoria instances running." D-12 specifies exactly this guard.
**Warning signs:** `make fleet` with no running instances prints only the column headers with no data.

### Pitfall 5: `nuke` warning `sed` prefix uses project name correctly
**What goes wrong:** `sed 's/^/         - $(COMPOSE_PROJECT_NAME)_/'` may be double-escaped in Make.
**Why it happens:** Make expands `$` before shell sees it; `$$` is needed for shell variables but `$(COMPOSE_PROJECT_NAME)` is a Make variable and must NOT be doubled.
**How to avoid:** Use `$(COMPOSE_PROJECT_NAME)` (single `$`) in the sed substitution — Make expands it before passing to the shell. The D-06 recipe is written correctly as-is.

### Pitfall 6: `--filter name=scoria-` returns db containers + unrelated repos
**What goes wrong:** `docker ps --filter name=scoria-` alone returns `scoria-main-db-1`, `scoria-main-web-1`, plus unrelated containers like `scoria-repro-pg2`.
**Why it happens:** `--filter name=` does prefix substring matching on container names, not on Compose project names.
**How to avoid:** Add `--filter label=traefik.enable=true` — only the `web` service carries this label; db/shots/critique containers do not. D-12 specifies this dual-filter.

## Code Examples

### D-14 Verified `help` and `fleet` Recipes

```makefile
# Source: CONTEXT.md D-14 (verified: GNU Make 3.81 + BSD awk + darwin)
.DEFAULT_GOAL := help

## help: print this help (the default target)
help:
	@echo "Scoria dev DX — each branch runs as its own instance at scoria-<branch>.localhost"
	@echo ""
	@awk '/^## [a-zA-Z0-9_-]+:/ { line = substr($$0, 4); i = index(line, ":"); printf "  \033[36m%-14s\033[0m %s\n", substr(line, 1, i-1), substr(line, i+2) }' $(MAKEFILE_LIST)

## fleet: list running scoria-* instances (spot a stale one shadowing your route)
fleet:
	@names=$$(docker ps --filter name=scoria- --filter label=traefik.enable=true -q); \
	if [ -z "$$names" ]; then \
		echo "No scoria instances running."; \
	else \
		echo "Running scoria instances (open at http://<project>.localhost/scoria):"; \
		docker ps --filter name=scoria- --filter label=traefik.enable=true \
			--format 'table {{.Label "com.docker.compose.project"}}\t{{.Status}}\t{{.Ports}}'; \
	fi
```

### D-06 Verified `nuke` Recipe

```makefile
# Source: CONTEXT.md D-06 (verified design; dynamic volume enumeration)
## nuke: stop + WIPE all of this instance's named volumes (cold rebuild next boot)
nuke:
	@echo "NUKE: irreversibly deleting ALL named volumes for instance '$(COMPOSE_PROJECT_NAME)':"
	@docker compose config --volumes | sed 's/^/         - $(COMPOSE_PROJECT_NAME)_/'
	@echo "       Destroys this instance's DB data + wipes deps/build/hex/mix caches (next 'make up' = cold recompile)."
	@echo "       Other branches/instances are NOT affected."
	docker compose down -v
```

### D-02 `clean` + `down` Alias Pattern

```makefile
# Source: CONTEXT.md D-02
## clean: stop this instance's stack (keeps named volumes/caches)
clean:
	docker compose down

## down: alias of clean
down: clean
```

### D-07 + D-09 `PORT` Block and Updated `dev` / `shots-native`

```makefile
PORT ?= 4799

## dev: native host server with live reload (PORT=4799 by default)
dev:
	SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server

## shots-native: run the harness on the host against a local mix phx.server
shots-native:
	mix scoria.ui.shots --url http://localhost:$(PORT)/scoria
```

### D-09 Comment Edit in `config/dev.exs` (line 22)

```elixir
# Before (line 22):
# Serves the Scoria dashboard at http://localhost:4000/scoria via `mix phx.server`
# After:
# Serves the Scoria dashboard at http://localhost:4799/scoria via `make dev`
```

### D-09 Moduledoc Edit in `dev/dev_endpoint.ex` (line 8)

```elixir
# Before (line 8):
  dashboard at `http://localhost:4000/scoria` for the screenshot/critique
# After:
  dashboard at `http://localhost:4799/scoria` for the screenshot/critique
```

## Validation Architecture

Each success criterion maps to a concrete shell/grep command the executor runs after
implementing the plan. These commands form the acceptance criteria for the phase.

### SC-1: `make dev` starts native server at PORT 4799

**Requirement:** DXCLI-01

```bash
# Verify PORT variable set to 4799 in Makefile
grep "PORT" Makefile
# Expected output includes: PORT ?= 4799

# Verify shots-native URL uses $(PORT)
grep "shots-native" Makefile -A2
# Expected: --url http://localhost:$(PORT)/scoria  (not hardcoded 4000)

# Verify dev recipe binds PORT
grep "^dev:" Makefile -A2
# Expected: SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server

# Verify dev.exs comment updated
grep -n "localhost:" config/dev.exs | head -5
# Expected line 22: http://localhost:4799/scoria via `make dev`

# Verify dev_endpoint.ex moduledoc updated
grep -n "localhost:" dev/dev_endpoint.ex | head -3
# Expected line 8: http://localhost:4799/scoria
```

### SC-2: `make clean` keeps volumes; `make nuke` wipes them; no prune

**Requirement:** DXCLI-02

```bash
# Verify clean body
grep "^clean:" Makefile -A2
# Expected: docker compose down  (no -v flag)

# Verify down is a delegating alias (no body)
grep "^down:" Makefile -A2
# Expected: down: clean  (single prerequisite, no recipe body)

# Verify nuke uses down -v
grep "^nuke:" Makefile -A5
# Expected: docker compose down -v

# THE CRITICAL NEGATIVE CHECK (DXCLI-02 explicit criterion)
grep -n "volume prune\|system prune" Makefile
# Expected: zero hits (empty output)

# Verify scoping via COMPOSE_PROJECT_NAME (already in identity block)
grep "COMPOSE_PROJECT_NAME" Makefile | head -3
# Expected: export COMPOSE_PROJECT_NAME = $(INSTANCE)
```

### SC-3: `make nuke` prints named-scope warning; no TTY prompt

**Requirement:** DXCLI-02

```bash
# Verify nuke warning lines
grep "^nuke:" Makefile -A8
# Expected output:
#   @echo "NUKE: irreversibly deleting ALL named volumes for instance '$(COMPOSE_PROJECT_NAME)':"
#   @docker compose config --volumes | sed 's/^/         - $(COMPOSE_PROJECT_NAME)_/'
#   docker compose down -v
# Must NOT contain: read, confirm, [y/N], prompt, or any shell `read` command

# Negative check for interactive prompt
grep -n "read\s\+\|confirm\|prompt\|y/N\|\[y\b" Makefile
# Expected: zero hits in nuke context
```

### SC-4: `make fleet` surfaces scoria-* containers with Traefik filter

**Requirement:** DXCLI-03

```bash
# Verify fleet target exists and uses both filters
grep "^fleet:" Makefile -A10
# Expected: --filter name=scoria- AND --filter label=traefik.enable=true
# Expected: empty-state guard checking -q output before table format

# Verify fleet in .PHONY
grep "PHONY" Makefile
# Expected: includes 'fleet'
```

### SC-5: Bare `make` prints help from ## comments; all new targets appear

**Requirement:** DXCLI-04

```bash
# Verify .DEFAULT_GOAL
grep "DEFAULT_GOAL" Makefile
# Expected: .DEFAULT_GOAL := help

# Verify help target exists
grep "^help:" Makefile -A3
# Expected: @awk '...' $(MAKEFILE_LIST)

# Verify all new targets have ## comments
grep "^## help:\|^## fleet:\|^## clean:\|^## down:\|^## nuke:" Makefile
# Expected: 5 lines, one for each new/aliased target

# Run make help (live check — no containers needed)
make help
# Expected: table including help, fleet, clean, down, nuke entries
# Expected: all 13 existing targets still present

# Verify help and nuke and fleet and clean in .PHONY
grep "PHONY" Makefile
# Expected: .PHONY: ... help fleet clean nuke
```

### Quick compound verification (run after all edits)

```bash
# All 5 success criteria combined — paste into terminal
echo "=== SC-1: PORT binding ===" && grep "PORT ?= 4799" Makefile && grep "localhost:\$(PORT)" Makefile && \
echo "=== SC-2: no prune ===" && (grep -c "volume prune\|system prune" Makefile | grep -q "^0$" && echo "PASS: zero prune hits" || echo "FAIL: prune found") && \
echo "=== SC-2: clean body ===" && grep "^clean:" Makefile -A1 && \
echo "=== SC-2: down alias ===" && grep "^down:" Makefile -A1 && \
echo "=== SC-3: nuke has COMPOSE_PROJECT_NAME in warning ===" && grep -A8 "^nuke:" Makefile | grep "COMPOSE_PROJECT_NAME" && \
echo "=== SC-4: fleet dual filter ===" && grep "traefik.enable=true" Makefile && \
echo "=== SC-5: DEFAULT_GOAL ===" && grep "DEFAULT_GOAL" Makefile && \
echo "=== SC-5: live help ===" && make help
```

## Runtime State Inventory

Not applicable — this is a greenfield-additions phase (new Makefile targets + comment edits). No rename or migration is involved. No runtime state holds the strings being added.

## Environment Availability

This phase requires only tools already in active use on the maintainer's machine:

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| GNU Make | All Makefile targets | Yes | 3.81 (verified) | — |
| BSD awk | `make help` awk parser | Yes | macOS default (verified) | — |
| Docker / Docker Compose | `make fleet`, `make nuke`, `make clean` | Assumed present (existing targets use it) | — | — |
| bash / sh | Shell recipes in `fleet`, `nuke` | Yes | macOS default | — |

No missing dependencies.

## Open Questions

None. All locked decisions have been verified against the live codebase. The only open
item is a Claude's Discretion call:

1. **The `## dev:` two-line comment**
   - What we know: The parser ignores the continuation line; `make help` will show a truncated sentence for `dev`.
   - What's unclear: Whether the planner prefers to leave it truncated, collapse it to one line, or write a new single-line description.
   - Recommendation: Collapse to one line that fits in the help table: `## dev: native host server with live reload (PORT=4799 by default; SCORIA_DEV_LIVE_RELOAD=1)`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Docker / Docker Compose is installed and accessible to `make fleet` and `make nuke` | Environment Availability | `make fleet`/`make nuke` fail at runtime; but existing `make up`/`down`/`reseed` already depend on Compose, so this assumption is sound |

All other claims in this research are VERIFIED against disk reads of the live files or against running the awk command against the live Makefile.

## Sources

### Primary (HIGH confidence)
- Disk read: `/Users/jon/projects/scoria/Makefile` (73 lines, verified 2026-06-17)
- Disk read: `/Users/jon/projects/scoria/config/dev.exs` (60 lines, verified 2026-06-17)
- Disk read: `/Users/jon/projects/scoria/dev/dev_endpoint.ex` (49 lines, verified 2026-06-17)
- Disk read: `/Users/jon/projects/scoria/compose.yml` (149 lines, verified 2026-06-17)
- Live execution: `awk '/^## [a-zA-Z0-9_-]+:/ { ... }' Makefile` — confirmed correct output on GNU Make 3.81 / BSD awk / darwin
- Live execution: `make --version` → GNU Make 3.81
- Disk read: `.planning/phases/29-makefile-hardening/29-CONTEXT.md` — all D-01..D-15 decisions
- Disk read: `.planning/phases/29-makefile-hardening/29-DISCUSSION-LOG.md` — decision rationale

### Secondary (MEDIUM confidence)
- GNU Make manual §3.5 "How Make Reads a Makefile" — `.DEFAULT_GOAL` behavior [ASSUMED: consistent with GNU Make 3.81]

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Locked decisions (D-01..D-15): HIGH — verified by four parallel research agents + disk confirmation
- Live codebase state (line numbers, current content): HIGH — direct disk reads
- Awk parser behavior: HIGH — executed live against the actual Makefile
- Validation commands: HIGH — derived directly from ROADMAP.md success criteria

**Research date:** 2026-06-17
**Valid until:** This research describes a static codebase; valid until any of the three target files change.
