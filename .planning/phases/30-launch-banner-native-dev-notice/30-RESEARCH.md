# Phase 30: Launch banner + native-dev notice - Research

**Researched:** 2026-06-18
**Domain:** Shell scripting (bash heredoc), GNU Make recipes, `mix phx.routes` output parsing (Phoenix 1.8.7 / LiveView 1.1.30), Docker dev-container entrypoint UX
**Confidence:** HIGH — all factual claims below verified by running the actual commands against this repo's code in this session.

## Summary

This is a low-risk DX phase touching exactly two files (`Makefile` `dev:` target, `docker/dev-entrypoint.sh`) and reading one source-of-truth (`lib/scoria_web/router.ex` via the dev-only `ScoriaWeb.DevRouter`). All twelve CONTEXT decisions (D-01..D-12) are LOCKED; this research supplies verified, copy-paste-ready command pipelines so the plan's tasks need no guesswork.

The single most important finding **corrects an assumption in CONTEXT D-08/D-09**: despite the `scoria_dashboard` macro using `as: false`, `mix phx.routes ScoriaWeb.DevRouter` **DOES emit route-helper names** in column 1 (`orchestrator_path`, `dataset_index_path`, etc.). The `as: false` suppresses compile-time `Routes.*` helper *functions* but Phoenix's console formatter still derives and prints a display name. This is good news — it means a *mechanical* friendly-label column is available for free if the planner wants one (D-08 explicitly permits a mechanically-derived second column and forbids only a hand-curated map). Paths-only remains acceptable and is the simplest robust output.

Three boot-safety facts are verified and load-bearing: (1) `mix phx.routes` route rows print to **stdout** while compile noise prints to **stderr**, so `2>/dev/null` cleanly isolates the table; (2) bare `mix phx.routes` (no router arg) **crashes** with `UndefinedFunctionError` because it resolves to the macro-only `ScoriaWeb.Router` — the `ScoriaWeb.DevRouter` argument is **mandatory**; (3) the entrypoint currently runs `set -euo pipefail`, so the routes derivation MUST be wrapped to never abort boot (D-09).

**Primary recommendation:** In `dev-entrypoint.sh`, compute the route list into a shell variable *before* the heredoc using a `|| true`-guarded pipeline against `ScoriaWeb.DevRouter`, with a static fallback string; interpolate it into the existing unquoted `<<BANNER` heredoc (which already expands `${HOST}`/`${INSTANCE}`). In the `Makefile` `dev:` recipe, add one `@echo` line above the existing `mix phx.server` exec, interpolating `$(PORT)`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**`make dev` native startup line (success criterion 1)**
- **D-01:** `make dev` echoes **exactly one line** before `mix phx.server` starts — the populated `/scoria` URL honoring `$PORT`, e.g. `==> Scoria dev (native) → http://localhost:4799/scoria`.
- **D-02:** The line MUST interpolate the Makefile `$(PORT)` (default 4799) so `make dev PORT=5000` echoes the matching URL. Single source of truth stays `PORT ?= 4799` in the Makefile. Do NOT touch `config/dev.exs` port default. Add the `@echo` to the `dev` recipe (currently just `SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server`).
- **D-03:** Use `localhost` (not `127.0.0.1`) in the native line.
- **D-04:** The `make dev` line does **not** carry the route list — routes live in the Docker banner only.

**Docker banner key-route list (success criterion 2)**
- **D-05:** **Derive the `/scoria` route list at banner time from the live router** (`mix phx.routes`, filtered to `/scoria` paths), NOT a hand-maintained list. The current static `Screens:` block has already drifted — it omits `/datasets`.
- **D-06:** **Render as a single, column-aligned flat list** — one route per line, copy-pasteable. "Grouped" = visually aligned, not bucketed. No category headers.
- **D-07:** **Filter out parameterized/non-pokeable routes.** Exclude routes containing `:` params and non-GET/non-live entries (MCP `post`/`sse`). Print static GET/`live` `/scoria` paths only.
- **D-08 (label nuance — Claude's discretion, resolved):** Print derived **paths** column-aligned without reintroducing a hand-maintained label map. If a second human-readable column is desired, derive it mechanically from the route, never a hand-curated lookup. Paths-only is acceptable and preferred over a fragile label map.
- **D-09:** Route derivation runs inside the container where `mix` + a compiled app are available (entrypoint runs `mix deps.get` + `mix dev.setup` before the banner). Verify `mix phx.routes` output format/exit behavior; filter must be robust to the `as: false`/`alias: false` scoped router. Keep the banner resilient — if derivation fails, the banner must still print (don't `set -e` abort the boot on a routes hiccup).

**Traefik admin link + native notice (success criteria 2 & 3)**
- **D-10:** Print the Traefik admin link as the **bare `http://localhost:8080`** on its own distinct line. (`docker/traefik/compose.yml` exposes the dashboard at `127.0.0.1:8080` with `--api.dashboard=true --api.insecure=true`; auto-redirects `/` → `/dashboard/`.)
- **D-11:** Add the native-dev notice line: `Native dev server: make dev → http://localhost:4799/scoria`. Hardcoding 4799 here is correct (states the native default policy). The container itself still listens on `:4000`. Own distinct, copy-pasteable line.
- **D-12:** All three new banner elements (Traefik link, native notice, route list) go on **distinct lines**. Fit them into the existing `cat <<BANNER ... BANNER` heredoc; keep existing Open/Traefik/demo-data/screenshot-harness sections.

### Claude's Discretion
- Exact microcopy/wording of the `make dev` echo and the banner additions, as long as URLs are literal/copy-pasteable and the native-vs-Docker distinction is unambiguous.
- The precise `mix phx.routes` parse/filter pipeline (grep/awk/sed) and column-alignment mechanism — pick the most robust under the container's shell; mirror the Phase 29 awk-alignment idiom if convenient.
- Whether the derived route list replaces the existing static `Screens:` block in place or is built just above the heredoc and interpolated in.
- Banner section ordering/visual separators, as long as the three required elements are present on distinct lines.
- Fallback rendering if `mix phx.routes` derivation fails (must not abort boot).

### Deferred Ideas (OUT OF SCOPE)
- **Category-bucketed route grouping** (Operate / Build / Connect) and **nav-taxonomy-mirrored grouping** (reuse `ScoriaWeb.DashboardNav` groups).
- **Friendly human labels** on each route line beyond the path (unless a mechanical, drift-free derivation is used; hand-maintained label map rejected).
- **Banner ↔ router parity contract test** and **`make dev` URL ↔ PORT default test** — Phase 34 scope, NOT this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DXCLI-05 | The launch banner prints a copy-pasteable key-route list, a populated `http://127.0.0.1:${PORT}/scoria` fallback URL, and the Traefik admin link — so the maintainer never guesses where to poke around. | Verified `mix phx.routes ScoriaWeb.DevRouter` pipeline produces the 9 literal GET `/scoria` paths (incl. `/datasets`); verified Traefik dashboard exposed at `localhost:8080`; verified Makefile `$(PORT)` is in scope in the `dev:` recipe for the populated native URL. All three banner elements have verified, distinct-line rendering paths. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Native startup URL line | Build tooling (Makefile recipe) | — | `make dev` is the native entry point; `$(PORT)` lives here (Phase 29 D-07). |
| Docker banner (routes + Traefik link + native notice) | Container entrypoint (`docker/dev-entrypoint.sh`, bash) | — | Banner prints once on `docker compose up`; entrypoint already has the compiled app + `mix`. |
| Route source-of-truth | Phoenix router (`lib/scoria_web/router.ex` via `ScoriaWeb.DevRouter`) | — | Read-only here; banner *reflects* it. Never edited (D-05). |
| Traefik dashboard exposure | Shared proxy (`docker/traefik/compose.yml`) | — | Read-only reference; `:8080` already exposed. |

## Standard Stack

No new packages. This phase uses only tooling already present and verified in this session:

| Tool | Version (verified) | Purpose | Why Standard |
|------|--------------------|---------|--------------|
| Elixir / Mix | OTP 28, erts-16.3, Mix 1.19.5 | `mix phx.routes` route enumeration | Already the build tool; no alternative needed. |
| Phoenix | 1.8.7 `[VERIFIED: mix.lock]` | `mix phx.routes` console formatter | Source of route output format. |
| Phoenix LiveView | 1.1.30 `[VERIFIED: mix.lock]` | `live/3` routes render as `GET` rows | Confirms verb-column filter works. |
| GNU Make | 3.81 (macOS; Phase 29-pinned) | `dev:` recipe `@echo` | Established build entry. |
| bash | `#!/usr/bin/env bash` (entrypoint shebang `[VERIFIED: docker/dev-entrypoint.sh:1]`) | heredoc + pipeline | Container shell is bash, so process substitution / `${var}` expansion / arrays are all available if needed. |
| awk / grep / sort | BSD on macOS; GNU in container | route filter + alignment | Phase 29 used BSD-awk-safe idioms; the *container* (Debian-based Elixir image) ships GNU awk, but writing BSD-safe awk keeps the pipeline runnable on the host too (testing convenience). |

**Package Legitimacy Audit:** N/A — this phase installs no external packages. (No `## Package Legitimacy Audit` table required.)

## VERIFIED: Exact `mix phx.routes` output format

Run in-repo this session:

```
$ mix phx.routes ScoriaWeb.DevRouter
          connector_auth_path  GET  /scoria/connectors/:connector_id/auth/start     ScoriaWeb.ConnectorAuthController :start
          connector_auth_path  GET  /scoria/connectors/:connector_id/auth/callback  ScoriaWeb.ConnectorAuthController :callback
            orchestrator_path  GET  /scoria                                         ScoriaWeb.OrchestratorLive :index
         approvals_index_path  GET  /scoria/approvals                               ScoriaWeb.ApprovalsLive.Index :index
            review_queue_path  GET  /scoria/reviews                                 ScoriaWeb.ReviewQueueLive :index
           dataset_index_path  GET  /scoria/datasets                                ScoriaWeb.DatasetLive.Index :index
          workflow_index_path  GET  /scoria/workflows                               ScoriaWeb.WorkflowLive.Index :index
           workflow_show_path  GET  /scoria/workflows/:id                           ScoriaWeb.WorkflowLive.Show :show
        connectors_index_path  GET  /scoria/connectors                              ScoriaWeb.ConnectorsLive.Index :index
         incidents_index_path  GET  /scoria/incidents                               ScoriaWeb.IncidentsLive.Index :index
         eval_spec_index_path  GET  /scoria/eval_specs                              ScoriaWeb.EvalSpecLive.Index :index
            prompt_index_path  GET  /scoria/prompts                                 ScoriaWeb.PromptLive.Index :index
prompt_release_workbench_path  GET  /scoria/prompts/:id/release                     ScoriaWeb.PromptLive.ReleaseWorkbenchLive :index
             coming_soon_path  GET  /scoria/coming/:screen                          ScoriaWeb.ComingSoonLive :show
```

Column structure `[VERIFIED: cat -te showed NO tab characters]`:
- **Col 1 — helper name**, RIGHT-aligned, space-padded (longest name `prompt_release_workbench_path` sets the column width). **Present despite `as: false`** — see "Common Pitfalls" P1.
- **2-space gap**, then **Col 2 — verb** (`GET` for every row; live + plain `get` both render as `GET`).
- **2-space gap**, then **Col 3 — path**, LEFT-aligned, space-padded.
- **2-space gap**, then **Col 4 — module + action** (`Module.Name :action`).
- One **trailing blank line** at EOF (harmless; the `$2=="GET"` filter skips it).

**Whitespace-splitting is safe:** with no tabs and single-token helper/verb/path columns, `awk` default field-splitting puts `verb` in `$2` and `path` in `$3` reliably for every row.

**Stream routing `[VERIFIED]`:** route rows → **stdout**; `Compiling N files`/`Generated scoria app` → **stderr**. Therefore `2>/dev/null` isolates a clean table. (At banner time the app is already compiled by the prior `mix dev.setup`, so usually no compile noise prints at all — but `2>/dev/null` is still the correct hygiene.)

**Router argument is MANDATORY `[VERIFIED]`:** bare `mix phx.routes` (no arg) crashes with `(UndefinedFunctionError) function ScoriaWeb.Router.formatted_routes/1 is undefined` because Mix defaults to `ScoriaWeb.Router`, which is the *macro module* (no compiled routes). Always pass `ScoriaWeb.DevRouter` — the router the dev endpoint actually mounts (`dev/dev_endpoint.ex:48` → `dev/dev_router.ex:36` mounts `scoria_dashboard("/scoria")`).

## VERIFIED: the filter pipeline and its expected output

Recommended pipeline (BSD-awk-safe, runs identically on host and in container):

```bash
mix phx.routes ScoriaWeb.DevRouter 2>/dev/null \
  | awk '$2 == "GET" && $3 ~ /^\/scoria/ && $3 !~ /:/ { print $3 }' \
  | sort -u
```

Each predicate maps to a D-07 requirement:
- `$2 == "GET"` → excludes any non-GET row (defensive; MCP `post`/`sse` are not in `DevRouter` anyway — verified absent).
- `$3 ~ /^\/scoria/` → keeps only dashboard paths (defensive; everything in `DevRouter` is `/scoria*`).
- `$3 !~ /:/` → drops every parameterized route (`/workflows/:id`, `/prompts/:id/release`, `/coming/:screen`, both `/connectors/:connector_id/auth/*`).
- `sort -u` → stable, de-duplicated ordering (alphabetical), copy-paste friendly.

**Verified output set (9 literal GET `/scoria` paths):**

```
/scoria
/scoria/approvals
/scoria/connectors
/scoria/datasets        ← the route the hand-maintained banner DRIFTED to omit (D-05)
/scoria/eval_specs
/scoria/incidents
/scoria/prompts
/scoria/reviews
/scoria/workflows
```

This is the expected output the planner and (later, Phase 34) the parity test should assert. Note `/scoria/connectors` appears once even though the router has both a `live("/connectors", …)` and parameterized `get("/connectors/:connector_id/auth/*")` rows — the `:` filter drops the parameterized ones, `sort -u` dedupes.

### Optional mechanical label column (D-08 — permitted, not required)

If a second human-readable column is wanted WITHOUT a hand-curated map, derive it mechanically from the path's last segment. Paths-only is preferred and simpler; this is documented only because D-08 left the door open:

```bash
# paths + mechanical label (last path segment, "home" for bare /scoria)
mix phx.routes ScoriaWeb.DevRouter 2>/dev/null \
  | awk '$2=="GET" && $3 ~ /^\/scoria/ && $3 !~ /:/ {
      p=$3; n=split(p,a,"/"); seg=(n>=3 ? a[n] : "home");
      printf "%-22s %s\n", p, seg
    }' \
  | sort
```

**Recommendation: ship paths-only** (`print $3`). It is the minimal, drift-proof, copy-pasteable rendering the user endorsed (D-06 "single column-aligned flat list").

### Column alignment

Paths-only output is already visually aligned (every line is just a path). If the planner wants the paths flush under a heading with a leading indent (to match the existing banner's 4-space `Screens:` indent), pipe through:

```bash
... | sort -u | sed 's/^/    /'
```

A full awk `printf "%-Ns"` two-column alignment (Phase 29 D-14 idiom) is only needed if the optional label column is added; for paths-only it is unnecessary.

## Architecture Patterns

### Banner integration: compute-then-interpolate (recommended)

The existing heredoc delimiter is **unquoted** (`cat <<BANNER`), so `${HOST}` and `${INSTANCE}` already expand inside it `[VERIFIED: docker/dev-entrypoint.sh:15-45]`. A pre-computed route variable interpolates the same way.

**Pattern (boot-safe, D-09):**

```bash
# --- compute the derived route list BEFORE the heredoc (never aborts boot) ---
ROUTES="$(mix phx.routes ScoriaWeb.DevRouter 2>/dev/null \
  | awk '$2 == "GET" && $3 ~ /^\/scoria/ && $3 !~ /:/ { print $3 }' \
  | sort -u \
  | sed 's/^/    /')" || true

if [ -z "$ROUTES" ]; then
  ROUTES="    (route list unavailable — run \`mix phx.routes ScoriaWeb.DevRouter\` or open http://${HOST}/scoria)"
fi
```

Then inside the existing `<<BANNER` heredoc, replace the stale `Screens:` block with:

```
  Key routes (derived live from the router):
${ROUTES}
```

…and add the two new distinct lines (D-10/D-11) into the heredoc, e.g. near the Open/Traefik area:

```
  Traefik admin (which app is routed where):  http://localhost:8080

  Native dev server: make dev → http://localhost:4799/scoria
```

**Why compute-then-interpolate over inline command substitution in the heredoc:** an unquoted heredoc does NOT run command substitution unless you write `$(...)` inside it, and even then a failing `$(...)` inside a `set -e` script under `pipefail` can surface a non-zero status awkwardly. Capturing into `$ROUTES` with a trailing `|| true` and an empty-check fallback is the explicit, auditable boot-safe form (D-09: "if derivation fails, the banner must still print").

### Boot-safety detail (`set -euo pipefail`)

`docker/dev-entrypoint.sh:4` is `set -euo pipefail` `[VERIFIED]`. Two consequences the plan must handle:
1. A failing pipeline assigned to a variable: `VAR="$(failing | pipe)"` — under `set -e` + `pipefail`, the command-substitution exit status would abort the script. The `|| true` suffix neutralizes this.
2. `set -u` (nounset): `$ROUTES` is always assigned (the `|| true` guarantees the assignment runs even on pipeline failure, yielding empty string), and the `if [ -z "$ROUTES" ]` fallback covers the empty case. No unbound-variable risk.

Do **not** disable `set -e` for the whole script (it protects `mix deps.get` / `mix dev.setup`). Scope the tolerance to the routes line only via `|| true`.

### Makefile `dev:` recipe pattern

Current recipe `[VERIFIED: Makefile:89-91]`:
```make
## dev: native host server with live reload (PORT=4799 by default)
dev:
	SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server
```

Add exactly one `@echo` line BEFORE the exec (D-01/D-02/D-03):
```make
## dev: native host server with live reload (PORT=4799 by default)
dev:
	@echo "==> Scoria dev (native) → http://localhost:$(PORT)/scoria"
	SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server
```

- `$(PORT)` is already in scope (`PORT ?= 4799` at `Makefile:33`); `make dev PORT=5000` interpolates `…:5000/scoria` `[VERIFIED: ?= + recipe binding semantics, Phase 29 D-07]`.
- `@` suppresses echoing the command itself (prints only the URL line, not `echo "…"`).
- Each Make recipe line is its own shell; the `@echo` runs and completes before `mix phx.server` is exec'd, so the line is guaranteed to appear *above* Phoenix's boot logs (satisfies criterion 1 "without scrolling back past server log noise").
- The `→` (U+2192) is fine in a Makefile recipe on a UTF-8 terminal; it matches the user-endorsed shape (CONTEXT "Specific Ideas"). If the planner prefers ASCII safety, `->` is an acceptable Claude's-discretion swap, but `→` matches the locked example in D-01.

### Anti-Patterns to Avoid
- **Re-introducing a hand-maintained route/label list** — exactly the drift D-05 kills (the current `Screens:` block omitting `/datasets` is the proof).
- **`grep '/scoria'` without the `:` exclusion** — would print parameterized, non-pokeable URLs (violates D-07).
- **Bare `mix phx.routes`** (no router arg) — crashes (verified). Always `ScoriaWeb.DevRouter`.
- **Letting the routes pipeline abort boot** — must be `|| true` + fallback (D-09).
- **Quoting the heredoc delimiter** (`<<'BANNER'`) — would stop `${HOST}`/`${INSTANCE}`/`${ROUTES}` expansion. Keep it unquoted.
- **Touching `config/dev.exs` port default or any container `:4000` wiring** — Phase 29 D-08/D-10 forbid it; the native 4799 is a Makefile-only policy.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Knowing which `/scoria` routes exist | A curated list in the banner | `mix phx.routes ScoriaWeb.DevRouter` filtered | Curated lists drift (the present banner already did — missing `/datasets`). |
| Friendly route labels | A hand-curated path→label map | Paths-only, or mechanical last-segment derivation | A map is the exact drift D-08 rejects. |
| Column alignment | Manual padding | `sort -u` (paths-only needs none) or awk `printf "%-Ns"` (Phase 29 idiom) | Manual padding desyncs the moment a path length changes. |

**Key insight:** every banner element must be *derived* from a single source of truth so the banner cannot lie. The router is the SoT for routes; the Makefile `$(PORT)` is the SoT for the native port; `docker/traefik/compose.yml` is the SoT for `:8080`.

## Verification of CONTEXT's asserted supporting facts

| CONTEXT claim | Verdict | Evidence |
|---------------|---------|----------|
| Traefik dashboard at `127.0.0.1:8080`, `--api.dashboard=true --api.insecure=true` | ✅ TRUE | `docker/traefik/compose.yml:27-31` |
| Entrypoint runs `mix deps.get` + `mix dev.setup` before banner (app compiled, `mix phx.routes` available) | ✅ TRUE | `docker/dev-entrypoint.sh:6-13`; `mix.exs:114` aliases `dev.setup` → `["scoria.dev.db", "run priv/repo/dev_seed.exs"]` |
| Hand-maintained `Screens:` block omits `/datasets` | ✅ TRUE | banner lists 9 screens but not `/datasets`; router `lib/scoria_web/router.ex:40` has `live("/datasets", …)`; `mix phx.routes` confirms `/scoria/datasets` |
| `make dev` recipe is just `SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server` | ✅ TRUE | `Makefile:90-91` |
| `PORT ?= 4799` is the Makefile SoT | ✅ TRUE | `Makefile:33` |
| heredoc interpolates `HOST`/`INSTANCE` | ✅ TRUE | `docker/dev-entrypoint.sh:12-13,20` (unquoted `<<BANNER`) |
| scoped router uses `as: false`/`alias: false` so "no route helper names" | ⚠️ **PARTIALLY FALSE** | `as: false` is in `router.ex:22`, BUT `mix phx.routes` STILL prints helper names in col 1 (see Pitfall P1). The filter must not depend on col 1 being blank. |
| MCP `post`/`sse` routes need excluding from the list | ⚠️ N/A for DevRouter | `scoria_mcp` is a *separate* macro NOT mounted by `ScoriaWeb.DevRouter`; `mix phx.routes ScoriaWeb.DevRouter` shows zero `sse`/`messages`/`post` rows. The `$2=="GET"` predicate is correct defense-in-depth but excludes nothing in practice here. |

The two ⚠️ rows are the places the plan must adjust away from CONTEXT's literal wording — neither changes a locked decision; both make the filter *more* robust than CONTEXT assumed.

## Common Pitfalls

### Pitfall P1: Assuming `as: false` blanks the route-name column
**What goes wrong:** A filter written to *rely on* an empty col-1 (e.g. anchoring the path as `$2`) would mis-parse, because col 1 is NOT empty.
**Why it happens:** `as: false` suppresses generated `Routes.*_path/2` helper *functions*, but Phoenix's `ConsoleFormatter` still computes a display name for `mix phx.routes` output. Verified: every row has a populated col-1 helper name.
**How to avoid:** Anchor on the **verb** and **path** columns (`$2`, `$3`), never on col 1. The recommended pipeline does exactly this.
**Warning signs:** A filter that prints helper names instead of paths, or an empty result.

### Pitfall P2: Bare `mix phx.routes` in the entrypoint
**What goes wrong:** `UndefinedFunctionError: ScoriaWeb.Router.formatted_routes/1` → empty `$ROUTES`, fallback fires every boot (banner silently degraded).
**Why it happens:** Mix defaults the router arg to `<App>Web.Router`, which here is the macro-only module.
**How to avoid:** Always `mix phx.routes ScoriaWeb.DevRouter`.
**Warning signs:** The fallback "(route list unavailable…)" string appears on a healthy boot.

### Pitfall P3: `set -euo pipefail` aborts boot on a routes hiccup
**What goes wrong:** If the routes pipeline returns non-zero (e.g. transient compile failure), the whole entrypoint exits before `exec mix phx.server` — the container "fails to start" with no banner.
**Why it happens:** `set -e` + `pipefail` propagate the pipeline's failure through the `VAR="$(...)"` assignment.
**How to avoid:** Suffix the assignment with `|| true` and provide an empty-check fallback (D-09). Scope the tolerance to that one line; do not weaken `set -e` globally.
**Warning signs:** Container restart loop after a code edit that briefly broke compilation.

### Pitfall P4: Quoting the heredoc delimiter
**What goes wrong:** `${ROUTES}`/`${HOST}` print literally instead of expanding.
**Why it happens:** `<<'BANNER'` disables expansion.
**How to avoid:** Keep the existing unquoted `<<BANNER`. Backslash-escape any literal `` ` `` (the file already does this for `\`make url\``) and literal `$` you don't want expanded.

### Pitfall P5: `mix phx.routes` compile noise leaking into the banner
**What goes wrong:** On the rare cold boot where the routes call triggers a recompile, `Compiling N files` would appear inside the route block.
**Why it happens:** Compile messages go to stderr.
**How to avoid:** `2>/dev/null` on the routes call (already in the recommended pipeline). At banner time the prior `mix dev.setup` has compiled, so this is belt-and-suspenders.

## Code Examples

### Full recommended entrypoint diff (conceptual)

```bash
# Source: derived in this session; verified pipeline output
# (after the existing `mix dev.setup`, before `cat <<BANNER`)

HOST="${PHX_HOST:-scoria.localhost}"
INSTANCE="${COMPOSE_PROJECT_NAME:-scoria}"

ROUTES="$(mix phx.routes ScoriaWeb.DevRouter 2>/dev/null \
  | awk '$2 == "GET" && $3 ~ /^\/scoria/ && $3 !~ /:/ { print $3 }' \
  | sort -u \
  | sed 's/^/    /')" || true
[ -z "$ROUTES" ] && ROUTES="    (routes unavailable — open http://${HOST}/scoria)"

cat <<BANNER

────────────────────────────────────────────────────────────────────
  Scoria dashboard — dev harness is up   (instance: ${INSTANCE})
────────────────────────────────────────────────────────────────────
  Open:  http://${HOST}/scoria        (via Traefik; *.localhost resolves
                                        automatically in Chrome/Chromium)
         host fallback: run \`make url\` for the ephemeral 127.0.0.1 port

  Traefik admin (which app is routed where):  http://localhost:8080

  Native dev server: make dev → http://localhost:4799/scoria

  Key routes (derived live from the router):
${ROUTES}

  ... (keep existing Demo-data + Screenshot/critique sections) ...
────────────────────────────────────────────────────────────────────

BANNER

exec mix phx.server
```

### Makefile `dev:` recipe

```make
## dev: native host server with live reload (PORT=4799 by default)
dev:
	@echo "==> Scoria dev (native) → http://localhost:$(PORT)/scoria"
	SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server
```

## State of the Art

| Old Approach | Current Approach | Why |
|--------------|------------------|-----|
| Hand-maintained `Screens:` list in banner | Live-derived from `mix phx.routes` | Curated list drifted (omitted `/datasets`). |
| No native startup URL line | One `@echo` honoring `$(PORT)` | Criterion 1; operator sees `/scoria` URL up front. |

**Not deprecated, just clarified:** `as: false` affects helper *functions*, not `mix phx.routes` display output (Phoenix 1.8.7 behavior).

## Runtime State Inventory

This is a banner/Makefile-text phase (no rename/migration of stored state), so most categories are N/A. Included for completeness because the phase edits a Docker entrypoint:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified no DB keys/collections reference banner text. | None |
| Live service config | None — Traefik `:8080` already exposed; no config change (read-only reference). | None |
| OS-registered state | None. | None |
| Secrets/env vars | None — entrypoint reads `PHX_HOST`/`COMPOSE_PROJECT_NAME` (already present); no new env vars. | None |
| Build artifacts | The `docker/dev-entrypoint.sh` change takes effect on next `docker compose up` (entrypoint is bind-mounted/baked per the image). The Makefile change is immediate. No stale compiled artifact carries the old banner. | Rebuild/restart container to see new banner. |

## Validation Architecture

`workflow.nyquist_validation` is **absent** from `.planning/config.json` → treat as **enabled**. Below is the validation map. NOTE: a banner↔router *parity contract test* is explicitly **Phase 34 scope** (CONTEXT deferred + canonical refs). Phase 30 should keep the derivation testable but **not build the contract test**. The validations below are the in-phase acceptance checks.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) for any Elixir-side assertion; shell/CLI checks for Makefile + entrypoint |
| Config file | `mix.exs` (test config); `test/test_helper.exs` |
| Quick run command | `mix phx.routes ScoriaWeb.DevRouter 2>/dev/null \| awk '$2=="GET" && $3 ~ /^\/scoria/ && $3 !~ /:/ {print $3}' \| sort -u` (asserts the 9-path set) |
| Full suite command | `mix test` (do not regress) + `shellcheck docker/dev-entrypoint.sh` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Command | Exists? |
|--------|----------|-----------|---------|---------|
| DXCLI-05 (native line) | `make dev` prints `…http://localhost:4799/scoria` before server; honors `PORT` | manual/CLI | `make -n dev` shows the `@echo`; `make dev PORT=5000` (or dry inspection) shows `:5000` | ❌ Wave 0 (manual check) |
| DXCLI-05 (route list) | Banner route block == the 9 literal GET `/scoria` paths incl. `/datasets`, no `:` routes | CLI/smoke | the quick-run pipeline above returns exactly the 9-path set | ✅ pipeline verified this session |
| DXCLI-05 (Traefik link) | Banner contains `http://localhost:8080` on its own line | grep | `grep -F 'http://localhost:8080' docker/dev-entrypoint.sh` | ❌ Wave 0 |
| DXCLI-05 (native notice) | Banner contains `Native dev server: make dev → http://localhost:4799/scoria` on its own line | grep | `grep -F 'Native dev server' docker/dev-entrypoint.sh` | ❌ Wave 0 |
| DXCLI-05 (boot-safety) | Entrypoint still prints banner if routes derivation fails; no `set -e` abort | review/CLI | `shellcheck docker/dev-entrypoint.sh` clean; confirm `|| true` + empty-check present | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** run the route-filter pipeline; `shellcheck docker/dev-entrypoint.sh`.
- **Per wave merge:** `mix test` (no regression) + visual `docker compose up` banner check (or `bash -n docker/dev-entrypoint.sh` syntax check if a full boot is impractical).
- **Phase gate:** all five req-rows above pass before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `shellcheck` clean on the modified `docker/dev-entrypoint.sh` (shellcheck 0.11.0 available on host — verified).
- [ ] A one-off CLI assertion (or note in the plan) that the filtered pipeline returns exactly the 9-path set — the seam Phase 34 will harden into a contract test. Do NOT write the contract test here.
- Framework install: none needed.

## Security Domain

`security_enforcement` is absent from config → treat as enabled. This phase's attack surface is minimal (no user input, no network input, no auth/crypto). Applicable ASVS categories:

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V5 Input Validation | marginally | The routes pipeline consumes only `mix phx.routes` output (trusted, locally generated). No external input parsed. |
| V12 Files & Resources | marginally | Entrypoint runs `mix` in the container; no new file reads from untrusted sources. |
| V14 Configuration | yes | Keep `set -euo pipefail`; scope the routes tolerance to `|| true` on one line only (don't broadly disable error handling). |
| Others (V2/V3/V4/V6) | no | No auth, session, access control, or cryptography touched. |

| Pattern | STRIDE | Mitigation |
|---------|--------|-----------|
| Banner advertises `http://localhost:8080` Traefik dashboard (insecure, no auth) | Information Disclosure | Acceptable: dev-only, bound to `127.0.0.1` (`docker/traefik/compose.yml:31`), already the established pattern (`make proxy` already echoes it). Out of scope to change. |

No new security controls required. The only hardening rule is the boot-safety scoping (V14).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | (none) | — | All factual claims verified by running commands against the repo this session. |

**This table is empty:** every load-bearing claim was verified via `mix phx.routes`, `cat -te`, stream-split tests, and direct file reads — no `[ASSUMED]` claims remain. The two CONTEXT corrections (P1 `as: false`, MCP-routes-N/A) are themselves verified, not assumed.

## Open Questions

1. **Paths-only vs. mechanical 2-column label rendering (D-08 discretion)**
   - What we know: paths-only is drift-proof, user-endorsed (D-06), and simplest; the helper-name column IS available and a last-segment label is derivable mechanically.
   - What's unclear: whether the user wants the extra label column for readability.
   - Recommendation: **ship paths-only.** It satisfies every locked criterion; a label column can be a trivial future polish if desired.

2. **`→` vs `->` in the Makefile/banner**
   - What we know: `→` matches the user-endorsed example shapes (D-01, Specific Ideas) and renders fine on UTF-8 terminals.
   - Recommendation: **use `→`** to match the locked examples; treat `->` as an acceptable fallback only if a non-UTF-8 terminal is a concern (not flagged as one).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | route derivation | ✓ (host + container) | OTP 28 / Mix 1.19.5 | — |
| Phoenix | `mix phx.routes` | ✓ | 1.8.7 | — |
| awk / grep / sort / sed | filter pipeline | ✓ | BSD (host) / GNU (container) | pipeline written BSD-safe |
| bash | entrypoint | ✓ | container shell (shebang `env bash`) | — |
| shellcheck | lint the entrypoint | ✓ (host) | 0.11.0 | `bash -n` syntax check |
| Docker / compose | boot the banner | assumed present (dev workflow) | — | `bash -n` / pipeline check without full boot |

**Missing dependencies:** none blocking.

## Sources

### Primary (HIGH confidence — verified in this session)
- `mix phx.routes ScoriaWeb.DevRouter` (ran live) — exact output format, column structure, stdout/stderr split, mandatory router arg, filtered 9-path output set.
- `cat -te` on routes output — confirmed no tabs (space-padded columns).
- `lib/scoria_web/router.ex` (read) — `scoria_dashboard`/`scoria_mcp` macros, `as: false`, the 12 routes.
- `dev/dev_router.ex`, `dev/dev_endpoint.ex` (read) — the dev server mounts `ScoriaWeb.DevRouter` → `scoria_dashboard("/scoria")`.
- `docker/dev-entrypoint.sh` (read) — `set -euo pipefail`, unquoted `<<BANNER` heredoc, stale `Screens:` block, deps.get + dev.setup order.
- `Makefile` (read) — `dev:` recipe, `PORT ?= 4799`.
- `docker/traefik/compose.yml` (read) — `:8080`, `--api.dashboard=true --api.insecure=true`.
- `mix.exs` / `mix.lock` (read) — Phoenix 1.8.7, LiveView 1.1.30, `dev.setup` alias.

### Secondary (MEDIUM)
- Phase 29 `29-CONTEXT.md` D-07/D-08/D-10/D-14 — PORT policy, awk-alignment idiom, Docker `:4000` invariants.

### Tertiary (LOW)
- (none)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions read from mix.lock; tooling run live.
- `mix phx.routes` format & pipeline: HIGH — executed against this repo; output captured verbatim.
- Banner/Makefile integration mechanics: HIGH — heredoc + recipe semantics verified against actual files.
- Pitfalls: HIGH — P1/P2/P3 reproduced or directly observed this session.

**Research date:** 2026-06-18
**Valid until:** ~2026-07-18 (stable; only a Phoenix major bump or router edit would change the `mix phx.routes` format or route set).
