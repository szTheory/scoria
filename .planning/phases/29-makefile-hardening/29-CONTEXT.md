# Phase 29: Makefile hardening - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

The `Makefile` becomes the single trustworthy entry point for every dev operation. This phase:
- Binds the **native** dev harness (`make dev` → `mix phx.server`) to a non-colliding default port **4799** (still overridable), and fixes the co-located hardcoded `:4000` in `shots-native` + the `dev/dev_endpoint.ex` doc comment.
- Adds scope-safe cleanup/teardown targets (`clean`, `nuke`) alongside the existing `down`/`reseed`, all scoped to `$(COMPOSE_PROJECT_NAME)` — never global prune.
- Adds `make fleet` to surface running `scoria-*` instances so a stale instance shadowing `scoria.localhost` is visible at a glance.
- Makes bare `make` print an auto-generated help list parsed from `##` comments.

**Out of scope (belongs to later phases):** launch-banner/key-route work (DXCLI-05, Phase 30), Dockerfile caching audit (Phase 31), doc rewrites + correcting `localhost:4000` copy across `docs/`/`priv/dev/e2e`/`.planning/` (DOCS reqs, Phase 33), secrets/rotation (Phase 32). Sibling-repo migration is out of scope for the whole milestone.
</domain>

<decisions>
## Implementation Decisions

Calibration: user profile is `opinionated` / `minimal_decisive` — decisions below are LOCKED, one coherent set. Backed by four parallel research agents (idioms, ecosystem lessons, footguns, DX/microcopy; toolchain-verified on macOS GNU Make 3.81 + BSD awk). Two corrections to the initial straw-man are noted inline.

### Target taxonomy — destructiveness ladder + delegating alias
- **D-01:** Adopt a 3-rung destructiveness ladder mirroring the GNU `clean`→`distclean` convention: `clean` (stop, keep volumes) < `reseed` (DB-only fast reset) < `nuke` (wipe all named volumes).
- **D-02:** `clean` is canonical and is byte-for-byte the existing `down` body (`docker compose down`). Keep `down` as a **delegating alias** — `down: clean` (a prerequisite, NOT a copied recipe) so the two names can never drift. `down` stays for muscle memory / compose-verb familiarity.
- **D-03:** `reseed` STAYS as-is (down → `docker volume rm $(COMPOSE_PROJECT_NAME)_pgdata` → `up-d`/seed). It must NOT fold into `nuke`: `nuke` wipes the deps/build/hex/mix cache volumes (cold recompile next boot), which would defeat the entire reason those cache volumes exist (`compose.yml`: "never re-fetched on edits"). `reseed` = fast daily-driver DB slate (warm caches); `nuke` = rare full teardown.
- **D-04:** Canonical `##` help wording (one line each):
  - `## clean: stop this instance's stack (keeps named volumes/caches)`
  - `## down: alias of clean`
  - `## reseed: fast DB slate — drop pgdata only, rebuild + reseed (keeps caches)`
  - `## nuke: stop + WIPE all of this instance's named volumes (cold rebuild next boot)`
  - `## fleet: list running scoria-* instances (spot a stale one shadowing your route)`
  - `## help: print this help (the default target)`

### `make nuke` volume-wipe mechanism
- **D-05:** Use `docker compose down -v` (a.k.a. `--volumes`) — scoped to `$(COMPOSE_PROJECT_NAME)` **by construction** (Compose namespaces every named volume with the project name; `external` resources like the shared `proxy` network are never touched). Do NOT hand-roll `docker volume rm` name lists (drift when `compose.yml` changes) and NEVER `docker system prune` / `docker volume prune` (DXCLI-02 forbids; `grep -n "volume prune\|system prune" Makefile` must return zero).
- **D-06:** Print a named-scope warning BEFORE the destructive command, **dynamically enumerated** so it never drifts:
  ```make
  nuke:
  	@echo "NUKE: irreversibly deleting ALL named volumes for instance '$(COMPOSE_PROJECT_NAME)':"
  	@docker compose config --volumes | sed 's/^/         - $(COMPOSE_PROJECT_NAME)_/'
  	@echo "       Destroys this instance's DB data + wipes deps/build/hex/mix caches (next 'make up' = cold recompile)."
  	@echo "       Other branches/instances are NOT affected."
  	docker compose down -v
  ```
  No TTY prompt — the target name `nuke` is the safety signal (DXCLI-02).

### PORT threading (native 4799)
- **D-07:** Single source of truth lives in the **Makefile only**: `PORT ?= 4799` (placed near the identity block). The `dev` recipe binds it explicitly: `SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server`. `?=` + explicit recipe binding means `make dev PORT=5000` overrides cleanly.
- **D-08 (CORRECTION to straw-man):** Do NOT change `config/dev.exs:33` default `System.get_env("PORT", "4000")`. The compose `web` service sets no `PORT` and inherits this default; bumping it to 4799 would silently move the *container's* listener off 4000 and break Traefik (`loadbalancer.server.port=4000`), `web:4000`, the `127.0.0.1::4000` map, and `SHOTS_BASE_URL`. Keep it as a pure mechanism (read PORT, fall back to 4000). The 4799 *policy* lives only in the Makefile.
- **D-09:** Native-path edits: `shots-native` → `mix scoria.ui.shots --url http://localhost:$(PORT)/scoria`; doc comments in `config/dev.exs` (~L22) and `dev/dev_endpoint.ex` moduledoc (~L8) → `http://localhost:4799/scoria via make dev`.
- **D-10:** Every Docker-internal `:4000` STAYS (container listens on 4000): `compose.yml` Traefik label/ports/`web:4000`/`SHOTS_BASE_URL`/critique URL, `Dockerfile.dev EXPOSE 4000`, the `url` target's `docker compose port web 4000`, and CI's `PORT: 4000`/`curl localhost:4000`. The mix-task default URLs (`scoria.ui.shots`/`scoria.ui.e2e`) and all `docs/`/`priv/dev/e2e`/`.planning/` copy are OUT OF SCOPE (DOCS reqs, Phase 33). See the exhaustive change/leave table in DISCUSSION-LOG for the planner.
- **D-11:** 4799 is confirmed sane: unprivileged, not IANA-registered for a common service, clear of common dev ports (3000/4000/5173/5432/6379/8080), outside the macOS ephemeral range. Keep it.

### `make fleet` + `make help`
- **D-12 (REFINEMENT to straw-man):** `fleet` filters on BOTH name and the Traefik label — `docker ps --filter name=scoria- --filter label=traefik.enable=true` — to get exactly one routable row per instance. Verified live that `--filter name=scoria-` alone is too noisy (returns db containers + unrelated `scoria-repro-pg2`). Running-only is correct (a shadowing instance is by definition running). Format: `table {{.Label "com.docker.compose.project"}}\t{{.Status}}\t{{.Ports}}` (project name == the `.localhost` subdomain). Empty-state guard via a `-q` id pre-check printing "No scoria instances running." (a `--format table` always emits a header row, so a naive `|| echo` never fires).
- **D-13:** `help` uses `.DEFAULT_GOAL := help` + a **standalone-comment awk** parser using `index()` to split `## name: desc` (preserves colons in descriptions). Do NOT use the popular `target: ## desc` / `FS=":.*?## "` pattern — it printed nothing under GNU Make 3.81 and would force rewriting all existing comments; the gawk `match($0,re,arr)` 3-arg variant is a BSD-awk syntax error. Keep the existing `## name: desc` convention untouched. Place `.DEFAULT_GOAL`/`help` at the top of the file. Cyan target color (`\033[36m`) is acceptable (drop the wrapper for zero-escape output if preferred).
- **D-14:** Verified recipes (macOS GNU Make 3.81 / BSD awk / darwin):
  ```make
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

### Cross-cutting
- **D-15:** Update `.PHONY` to add `help fleet clean nuke` (existing `down`/`reseed` already present). Every new target carries its `## name: desc` line so it auto-appears in `make help` (satisfies DXCLI-04 success criterion).

### Claude's Discretion
- Exact placement/ordering of the new targets within the file (group the destructiveness ladder together; `help`/`.DEFAULT_GOAL` lead the file).
- Whether to keep the help cyan color or emit plain text (low-stakes; default keep).
- Minor warning-copy wording, as long as it names scope + irreversibility + cold-recompile cost.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 29: Makefile hardening" — goal + 5 success criteria (the verification bar).
- `.planning/REQUIREMENTS.md` — DXCLI-01, DXCLI-02, DXCLI-03, DXCLI-04 (the locked requirements for this phase).
- `.planning/PROJECT.md` §"Current Milestone: v3.2 Drydock" — milestone goal + "Docker dev-DX hardening (Scoria-only)" target features + locked context (Traefik/`*.localhost` stays; sibling migration out of scope).

### Files this phase edits
- `Makefile` — all target/`.PHONY`/`.DEFAULT_GOAL` changes (the primary surface).
- `config/dev.exs` (~L22–33) — doc-comment edit only (the `PORT` default stays `"4000"`).
- `dev/dev_endpoint.ex` (moduledoc ~L8) — doc-comment edit only.

### Files this phase must NOT change (Docker-internal :4000 — leave)
- `compose.yml` (Traefik label, ports, `web:4000`, `SHOTS_BASE_URL`, critique URL), `Dockerfile.dev` (`EXPOSE 4000`), `.github/workflows/ci.yml` (`PORT: 4000`, `curl localhost:4000`). See DISCUSSION-LOG change/leave table.

### DX philosophy
- `prompts/sztheory-elixir-dna.md` — Operator-First DX / least-surprise DNA folded into the taxonomy + microcopy decisions.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing `Makefile` per-instance identity block (`BRANCH`/`INSTANCE`/`export COMPOSE_PROJECT_NAME`/`export SCORIA_HOST`) — `nuke`/`fleet` reuse `$(COMPOSE_PROJECT_NAME)` for scoping with zero new plumbing.
- Existing `## target: desc` comment convention already on all 13 targets — `help` awk parses it as-is, no comment rewrites.
- `config/dev.exs:33` already reads `System.get_env("PORT", "4000")` — PORT env plumbing already exists; this phase only sets the default in the Makefile and updates comments.

### Established Patterns
- Compose project = `scoria-<branch>`; named volumes auto-prefixed by project name → `down -v` is correctly scoped without name lists.
- `reseed`'s existing `docker volume rm $(COMPOSE_PROJECT_NAME)_pgdata` is the DB-only precedent (kept distinct from `nuke`).
- The shared `proxy` network / Traefik is `external` and shared across instances — every teardown target must avoid touching it (`down -v` does by design).

### Integration Points
- `make dev` → native `mix phx.server` → `ScoriaWeb.DevEndpoint` (binds `$(PORT)`=4799).
- `make shots-native` / `make critique` (native) hit `localhost:$(PORT)`; Dockerized shots hit `web:4000` — the two paths never cross.
</code_context>

<specifics>
## Specific Ideas

- Destructiveness ladder explicitly modeled on the GNU clean/distclean/maintainer-clean tiered convention (clean keeps reconstructibles; the harder target wipes them).
- `nuke` warning enumerates real on-disk volume names via `docker compose config --volumes` piped through `sed` — drift-proof and honest about the cold-recompile cost.
- Toolchain-pinned verification: all awk/`docker ps`/filter recipes validated on the maintainer's exact stack (GNU Make 3.81 + BSD awk on darwin) — "Makefile hardening" means it must run where the maintainer runs it.
</specifics>

<deferred>
## Deferred Ideas

- **Launch banner / populated fallback URL / Traefik admin link / key-route list** — DXCLI-05, Phase 30. (`make dev` echo wiring lands there, building on this phase's PORT default.)
- **Mix-task default URL correction** (`scoria.ui.shots` / `scoria.ui.e2e` defaulting to `localhost:4000`) and all `docs/`/`priv/dev/e2e`/`.planning/` `localhost:4000` copy — DOCS reqs, Phase 33. Flagged by the PORT research as a separate doc-consistency concern; `make shots-native` already passes `--url` explicitly so it's not a blocker here.
- **`uat_automation.md` native e2e port note** (`PORT=4010` → `make dev`/`PORT=4799`) — Phase 33 doc pass.
- **`--remove-orphans` on teardown targets** — considered; omitted (orthogonal to volume wiping, widens blast radius). Revisit only if service churn becomes frequent.
</deferred>

---

*Phase: 29-makefile-hardening*
*Context gathered: 2026-06-17*
