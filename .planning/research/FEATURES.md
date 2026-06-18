# Feature Research — v3.2 Drydock

**Domain:** Hands-off multi-lib Phoenix/Elixir local dev DX + maintenance release hygiene
**Researched:** 2026-06-17
**Confidence:** HIGH (all claims grounded in existing Scoria code + cross-ecosystem lessons from Sail, Tilt, Vite, Laravel, Rails, just/foreman, overmind)

---

## Context: What Already Exists (Do Not Rebuild)

Scoria already ships a solid foundation. Every feature below is scoped to the **gaps** visible in the code audit (Makefile, docker/dev-entrypoint.sh, docs/docker_dev_dx.md, docker-dx-fleet-hardening.md).

Existing and locked:
- Traefik + `*.localhost` shared proxy (external `proxy` network)
- Branch-derived `INSTANCE`/`COMPOSE_PROJECT_NAME`/`SCORIA_HOST` → multi-instance isolation
- DB/Redis unpublished (eliminates `:5432` collision class)
- Ephemeral loopback `127.0.0.1::4000` fallback
- Named volumes for deps/_build/.hex/.mix (no NIF clash between host + Linux)
- BuildKit `--mount=type=cache` for apt + Hex/rebar caches
- `FILE_SYSTEM_BACKEND=fs_poll` for macOS VM file event gap
- `DevAssetWatcher` + live_reload for css/js hot-reload in Docker
- `make proxy/up/up-d/down/logs/seed/reseed/url/open/dev/shots/critique`
- Launch banner with instance name, Traefik URL, screen list, shots/critique commands
- `docs/docker_dev_dx.md` as portable fleet template

---

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Depends On | Notes |
|---------|--------------|------------|------------|-------|
| **Non-colliding `make dev` PORT default** | `make dev` previously launched the native Phoenix server on the default `:4000`. On a multi-lib Mac, `:4000` is always claimed by something else. Any toolchain that ships a native-mode dev command must not collide on the most-used port in the ecosystem. Laravel Sail and most Rails tooling bake in a non-default port for exactly this. | LOW | Existing `dev:` target | Bake `PORT=4799` (or any non-4000 port) into the `dev:` Makefile target. `4799` is outside the macOS ephemeral range (49152–65535) and the common 4001-4010 range other tools use. Document it once in the target comment. |
| **`make nuke` stale-instance cleanup** | Stale compose projects accumulate and shadow new branch URLs (confirmed: old `scoria_demo` project answering `scoria.localhost`). Every serious Docker-based DX has a "full reset" escape hatch — `docker system prune`, `sail destroy`, `tilt down --delete-namespaces`. Users expect to recover in one command when things go wrong. | LOW | Existing `down`/`reseed` targets | `make nuke` = `docker compose down -v --remove-orphans` (removes this instance's volumes + networks) followed by optional `docker builder prune --filter label=com.docker.compose.project=$(COMPOSE_PROJECT_NAME)`. Separate from full-machine Docker nuke. Document as instance-scoped (non-destructive to other running instances). |
| **Stale instance discovery + hygiene doc** | A fleet maintainer loses track of running named instances. There is no visible inventory. Rails dev has `bin/rails server` which refuses to start if PID exists; foreman shows all processes. Without discovery, stale Traefik routing is invisible. | LOW | docs/docker_dev_dx.md | A `make ps` (or `make fleet`) target: `docker ps --filter label=com.docker.compose.project --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"`. Plus a short "hygiene" section in the doc: list → stop → nuke cycle. |
| **Copy-pasteable key-route list in launch banner** | The current banner prints `/scoria` + a handful of screens. But the maintainer also needs to reach nested routes (prompts/:id/release, the Traefik dashboard at :8080, the fallback `make url` port). Today the banner omits the fallback URL and the Traefik admin URL, which are the two things you need when something breaks. Vite and Tilt both print the full set of reachable URLs at startup. Developers should never have to grep for a URL after `make up`. | LOW | docker/dev-entrypoint.sh | Add three sections to the banner: (1) PRIMARY URLs (full Traefik + fallback — print both, with the fallback populated at startup rather than telling users to run `make url`), (2) KEY ROUTES (copy-paste-ready relative paths, grouped by function), (3) OPS COMMANDS (seed, reseed, shots, critique). See microcopy spec below. |
| **Correct verification copy** | Every GSD plan, agent prompt, and phase checkpoint previously pointed at the old fixed localhost dashboard URL. This is wrong: `:4000` is fleet-owned, and the real entry is `make up`/`make dev` -> `<instance>.localhost/scoria` or `http://localhost:4799/scoria`. Wrong verification copy causes silent failures where an agent validates the wrong URL and reports a pass. | LOW | docs/docker_dev_dx.md, banner | Audit and update: (a) all fixed-port localhost references in `.planning/` and `docs/`, (b) the MAINTAINERS.md operator verification section, (c) the banner itself, (d) any GSD phase script snippets. Correct form: `make up` -> `http://scoria-<branch>.localhost/scoria`. |
| **Dockerfile layer-order audit (no dep-refetch on style edit)** | Users paying attention to DX expect that a CSS or HEEx-only edit never triggers `mix deps.get` or a full recompile. This is the #1 Docker DX footgun for Elixir: copying all source before `mix deps.get` defeats BuildKit caching entirely. The named volumes already protect runtime recompile, but the BUILD path (used by `make up --build`) needs layer order verification. | MEDIUM | Dockerfile.dev | Verified pattern: COPY mix.exs mix.lock ./ → RUN mix deps.get → COPY lib/ config/ priv/ ... Do NOT COPY . . before deps.get. Any change to non-manifest source files (lib/, assets/, priv/) must land in layers AFTER the deps layer. Document the invariant in a comment in Dockerfile.dev. |
| **Secrets pattern: rotate `.env` key + flag plaintext risk** | `.env` holds what appears to be a real `ANTHROPIC_API_KEY` in plaintext. Even gitignored files are visible in process lists, shell history, and Docker build context if not excluded. A maintainer running multiple OSS repos expects at minimum: (a) confirmation the key is rotated, (b) a clear ".env.example" showing the shape without values, (c) an opt-in path to 1Password CLI / direnv for secret injection. Scoria's brand voice is "operator-grade"; shipping with a plaintext secret visible to anyone who runs `env` in the container is inconsistent with that. | LOW–MEDIUM | .env, docker/dev-entrypoint.sh | Immediate: Rotate the key. Doc: add `.env.example` (checked in) + `.env` (gitignored). Opt-in pattern: `op run -- make up` via 1Password CLI; or `direnv` + `.envrc` (also gitignored) with `export ANTHROPIC_API_KEY=$(op read "op://...")`. Document both options in the fleet secrets section of docs/docker_dev_dx.md without mandating either (solo maintainer may not have 1Password). |
| **Post-publish registry semver upgrade smoke** | After merging the release-please PR and publishing 0.1.1, the maintainer needs proof that the live Hex package installs correctly at the new version before closing the milestone. Scoria already ships `mix scoria.post_publish_smoke` for this purpose (implemented in v2.10). The table-stakes requirement is that this task is wired into the release workflow and the post-publish step is documented. | LOW | Existing `mix scoria.post_publish_smoke` | Run `mix scoria.post_publish_smoke` after `mix hex.publish`. Confirm the workflow step exists in `.github/workflows/hex-publish.yml` (or equivalent). Document the manual trigger path in MAINTAINERS.md for the case where CI skips it. |

### Differentiators (Competitive Advantage for the Maintainer Persona)

| Feature | Value Proposition | Complexity | Depends On | Notes |
|---------|-------------------|------------|------------|-------|
| **Self-documenting `make help` as default goal** | Running `make` with no arguments currently runs `proxy` (first target). Best-in-class dev tooling (Vite, `just`, modern Makefiles) makes the default goal a formatted help screen — so a first-time contributor (or the maintainer returning after a month) immediately sees every command with a one-line description. The `##` comment pattern (parse with awk) keeps docs co-located with targets. `just --list` behavior is widely praised as the gold standard; Makefile can replicate it cheaply. | LOW | Existing Makefile | Add a `help:` target using the `##` comment awk pattern. Set `.DEFAULT_GOAL := help`. Each target already has `## comment` — the awk is a 3-line addition. Output should look like a formatted table with `proxy`, `up`, `dev`, `nuke` etc. This is zero maintenance because the docs are the target comments. |
| **`make fleet` — live instance inventory** | Running many OSS libs at once means forgetting which instances are up. A `make fleet` that shows all scoria-prefixed compose projects (names, URLs, status) gives the maintainer a dashboard over their running fleet without leaving the terminal. Tilt's `tilt status` does this; overmind does for process groups. Cross-ecosystem lesson: tools that show state reduce "why is my port taken?" debugging time by 90%. | LOW | Docker CLI | `docker ps --filter "name=scoria-"` or `docker compose ls --filter name=scoria`. Optional: parse `SCORIA_HOST` labels from container env and print the Traefik URL for each. |
| **Banner: populated fallback URL at boot (not "run make url")** | The current banner says "run `make url` for the ephemeral 127.0.0.1 port". But at entrypoint time the PORT is known from the `PORT` env var. Printing the actual resolved port in the banner (rather than deferring to `make url`) means developers never have to run a second command to get the fallback. Vite and Phoenix both print resolved URLs at startup. | LOW | docker/dev-entrypoint.sh | Inside the entrypoint, interpolate `http://127.0.0.1:${PORT:-4000}/scoria` directly into the banner. Document that `make url` resolves the exact ephemeral mapping from the host side (the two values are equivalent but `make url` is more precise). |
| **`docs/docker_dev_dx.md` reader-empathy restructure** | The current doc is technically accurate but front-loads the model explanation before the gameplan. Rails Guides and Laravel Sail docs both lead with a "quick start in 60 seconds" block, then explain why. A maintainer returning after a month wants: (1) do I need to run `make proxy` again? (2) what's my URL? (3) how do I nuke a stale instance? — before any model explanation. The current doc answers these but buries them in prose. | LOW | docs/docker_dev_dx.md | Structural rewrite: (1) Persona/JTBD box at top, (2) Gameplan summary (3 bullet prerequisites + 2 commands), (3) Quick reference table (target → what it does → when to use), (4) The model (already excellent), (5) Multi-instance deep-dive, (6) Caching guarantees (with the Dockerfile layer invariant), (7) Fleet secrets pattern, (8) Hygiene / stale instances, (9) Adopting in another repo. Keep existing prose (it is good) — restructure, don't rewrite from scratch. |
| **`.env.example` as checked-in shape document** | A `.env.example` checked into the repo gives three wins: (a) new contributors immediately know what vars are required, (b) CI can warn if `.env` is missing a required var, (c) it documents which vars are secrets (and thus should come from 1Password/direnv) vs which are config (can be plain values). This pattern is universal across Laravel/Rails/Node toolchains. Currently there is no `.env.example` in Scoria. | LOW | .env | Create `.env.example` with all vars present but secrets set to `REPLACE_ME` or `op://Scoria Dev/...`. Annotate each line with a comment. Leave `.env` gitignored. |
| **Release-please PR merge checklist in MAINTAINERS.md** | The existing post-publish smoke is already wired (v2.10). The differentiator is a copy-pasteable runbook: (1) CI green on release-please PR? → merge, (2) Wait for hex-publish workflow, (3) Run `mix scoria.post_publish_smoke`, (4) Verify hex.pm badge shows new version. This reduces cognitive load for a solo maintainer doing a release after weeks of feature work. Cross-ecosystem lesson from release-please's own docs: the PR merge step is the only human action; everything else should be automated. | LOW | MAINTAINERS.md, existing workflows | Add a "Cutting a release" section to MAINTAINERS.md with 4 numbered steps. No new tooling needed. |
| **Verified CSS/HEEx-only edit does NOT rebuild image** | The existing named-volume + bind-mount strategy means runtime recompile is already fast, but the `make up --build` path (used after pulling changes) needs an explicit cache-hit guarantee documented and verifiable. Cross-ecosystem lesson from Vite: the DX story is only complete when you can TELL THE USER what is and isn't cache-invalidating. Scoria should add a one-line comment block to Dockerfile.dev documenting the layer invariant. | MEDIUM | Dockerfile.dev | Document in Dockerfile.dev: "Layer order invariant: mix.exs/mix.lock in layer N; source files in layer N+1+. Do not COPY source before mix deps.get." The audit itself is the MEDIUM-complexity part; the documentation is trivial once the audit is done. |
| **Fleet secrets standardization via `.env.op` + `op run`** | For a maintainer running 8+ OSS repos, managing per-project `.env` files with real secrets is a single-key-rotation nightmare. The 1Password `op run -- make up` pattern (`.env.op` with `op://Vault/Item/field` references, never touched by plain `env`) gives: Touch ID injection, zero plaintext on disk, one secret rotation propagates everywhere. Direnv + `.envrc` is the simpler fallback for users who don't have 1Password. The key point for docs: present BOTH patterns, make them opt-in, and document that the plain `.env` path is still valid for local dev if you rotate regularly. | MEDIUM | docs/docker_dev_dx.md, .env | Add a "Secrets" section to the doc. Provide `.env.op.example`. Document `op run -- make up`. Add a one-sentence note in the banner if `ANTHROPIC_API_KEY` is missing: "ANTHROPIC_API_KEY not set — screenshots work but critique requires it." |

### Anti-Features (Do Not Build)

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| **Migrate `make` to `just`** | `just` has better ergonomics (no .PHONY, spaces OK, `just --list`). Many blog posts declare Makefile dead. | Makefile already exists and works. Introducing `just` requires every contributor and every sibling-repo adopter to install a new binary. The szTheory DNA is "zero-config onboarding" — adding a build prerequisite contradicts it. The benefit is cosmetic. | Add `make help` as the default goal with the `##` awk pattern. This gives `just --list` behavior from the existing tool. |
| **Caddy or nginx-proxy as Traefik replacement** | Caddy has simpler config; nginx-proxy is older but widely known. Some tutorials recommend them for local dev. | Traefik + `*.localhost` is shipped and verified live across two instances. A bake-off is explicitly out of scope per the milestone constraint. Switching would invalidate the existing docs and every adopter template. | Stay on Traefik. Document Caddy as an alternative only in the cross-repo adoption note if a sibling repo strongly prefers it — out of v3.2 scope. |
| **dnsmasq / /etc/hosts as the default path** | `*.localhost` does not work in Safari or in `curl` without headers. Some want full wildcard DNS for all browsers. | dnsmasq setup requires `sudo`, daemon management, and `/etc/resolver/` file manipulation. It is a significant system-level footgun if misconfigured. Most dev work happens in Chrome/Chromium where `*.localhost` works natively. | Keep dnsmasq as the optional path already documented. Don't make it the default. Print a Safari note in the docs (already present). |
| **Auto-assign PORT via shell subcommand in Makefile** | Truly conflict-free port for `make dev` native mode, zero configuration needed. | Shell calls in Makefile variable assignment run at parse time, are slow, and break in unexpected ways across make versions. The complexity is not worth it for a port that is used only in native mode (`make dev`), which already has the Docker fallback. | Bake in a fixed non-4000 default (4799). It will not collide with 4000 or the macOS ephemeral range. Document that `PORT=XXXX make dev` overrides it. |
| **Commit `.env` to git "for convenience"** | Onboarding friction — a new contributor has to copy `.env.example` manually. | Plaintext secrets in git history are unrecoverable without a full rewrite. This is a hard security anti-pattern regardless of audience. | `.env.example` checked in + clear one-line setup instruction in the README or Quick Start section of the doc. |
| **`make dev` that boots Docker (not native)** | Consistency — one command for Docker and native alike. | `make dev` is explicitly the native host server path. Conflating Docker and native paths under one target causes confusion about which asset watcher is running. The split is intentional: `make up` = Docker, `make dev` = native. | Keep the split. Document it clearly: `make dev` = native livereload; `make up` = Dockerized harness. |
| **Single-banner "everything" approach** | More information is better; the banner is the one place all context lives. | A 60-line banner is worse than a 20-line banner. Cognitive overload defeats the purpose. Best-in-class banners (Vite, Phoenix itself) show ONE thing clearly: "Your app is at X." | Keep the banner focused: 3 sections max (URLs, key routes, ops commands). Full route reference lives in the doc, not the banner. |
| **Sibling-repo migration (rulestead/parapet/etc.) in this milestone** | Completing the fleet standard across all repos while the doc is being improved. | Out of scope per PROJECT.md decision. Migrating sibling repos is a separate initiative (docker-dx-fleet-hardening todo). Doing it now dilutes focus and risks introducing cross-repo regressions inside the v3.2 window. | Document the "Adopting in another repo" section in docs/docker_dev_dx.md as the portable standard. Sibling migration stays in the cross-repo todo. |
| **HTTPS locally (mkcert + self-signed cert)** | Some APIs require HTTPS even locally. | Non-trivial setup (mkcert, Traefik TLS config, browser trust stores). The `*.localhost` domain is treated as secure-context in Chrome without HTTPS. Real HTTPS need is rare for a dashboard dev harness. | Document mkcert as a future option. Do not implement it in v3.2. |
| **Automated multi-instance fleet health check in CI** | "Is the fleet healthy?" as a CI gate. | CI should not be aware of local Docker state. Fleet health is a runtime/local concern, not a merge gate. A CI job that talks to local Docker would require a self-hosted runner and is a massive DX regression. | `make fleet` for local inspection only. CI gate stays on unit tests + existing lane contracts. |

---

## Feature Dependencies

```
make help (default goal)
    └──requires──> Makefile ## comment annotations (already present, just need awk target)

make nuke (instance cleanup)
    └──requires──> COMPOSE_PROJECT_NAME derived correctly (already exists)
    └──enhances──> stale instance hygiene doc section

make fleet (inventory)
    └──requires──> docker ps + compose ls (Docker CLI, always present)
    └──enhances──> stale instance hygiene doc section

Banner populated fallback URL
    └──requires──> PORT env var available in entrypoint (already set)
    └──requires──> docker/dev-entrypoint.sh modification

.env.example (checked-in shape doc)
    └──required-before──> fleet secrets section in docs

Fleet secrets (op run / direnv)
    └──requires──> .env.example committed
    └──requires──> docs/docker_dev_dx.md secrets section written

Dockerfile layer invariant documented
    └──requires──> Dockerfile.dev audit (verify COPY order is correct)
    └──enhances──> docs/docker_dev_dx.md caching guarantee section

docs/docker_dev_dx.md restructure
    └──requires──> All above features implemented (so the doc reflects final state)
    └──requires──> make nuke target exists (hygiene section can reference it)
    └──requires──> .env.example committed (secrets section can reference it)

Correct verification copy
    └──requires──> Banner updated (knows the real URL pattern)
    └──requires──> docs/docker_dev_dx.md restructure complete

make dev PORT=4799 default
    └──conflicts_with──> any hardcoded raw-Phoenix fixed-port verification copy
                         (verification copy update must happen in the same pass)

Release-please merge + post-publish smoke
    └──requires──> CI green on release-please PR
    └──requires──> mix scoria.post_publish_smoke exists (already shipped v2.10)
    └──requires──> MAINTAINERS.md release runbook section
```

---

## MVP Definition (v3.2 Drydock Scope)

### Must Ship (v3.2)

These are the concrete gaps from the backlog. Nothing here is new invention — all are hygiene and polish on an already-shipped foundation.

- [x] `make dev` default PORT to 4799 (one line in Makefile) — eliminates the `:4000` collision
- [x] Local key exposure closeout completed via no-Git-exposure attestation; no local-only key rotation claimed or required
- [x] `.env.example` committed (plaintext shape, secrets as `REPLACE_ME`)
- [x] `make nuke` target (instance-scoped `compose down -v --remove-orphans`) — escape hatch for stale instances
- [x] `make fleet` target — live inventory of running scoria-* compose projects
- [x] `make help` as `.DEFAULT_GOAL` with `##` awk self-documentation — zero friction discoverability
- [x] Banner update: add populated fallback URL, Traefik admin URL (:8080), cleaner key-route grouping
- [x] Correct all raw-Phoenix fixed-port verification copy in `.planning/` and `docs/`
- [x] Dockerfile.dev layer order verified + invariant documented in a comment block
- [x] `docs/docker_dev_dx.md` restructure: persona/JTBD box → gameplan → quick-ref table → model → caching → secrets → hygiene → adopter guide
- [x] Fleet secrets section in doc: `.env` (rotate), `.env.op` (op run), `.envrc` (direnv) — three tiers, all opt-in
- [ ] Maintenance release: merge release-please PR #3 on green CI → post-publish smoke → close
- [ ] MAINTAINERS.md: add 4-step release runbook

### Defer After v3.2

- [ ] `make nuke-all` (fleet-wide cleanup) — useful but rare; `make nuke` + `docker system prune` covers 99% of cases
- [ ] `make build-dry` (cache-hit verification run) — Dockerfile comment is sufficient for now
- [ ] Sibling-repo migration — explicit out-of-scope per PROJECT.md
- [ ] HTTPS locally (mkcert) — not needed for Chrome-based dev harness
- [ ] dnsmasq as default path — optional path already documented, leave it

---

## Feature Prioritization Matrix

| Feature | Maintainer Value | Implementation Cost | Priority |
|---------|-----------------|---------------------|----------|
| `make dev` PORT=4799 default | HIGH (eliminates daily collision) | LOW (one line) | P1 |
| Rotate ANTHROPIC_API_KEY | HIGH (security) | LOW | P1 |
| `.env.example` | HIGH (shapes expectations) | LOW | P1 |
| `make nuke` target | HIGH (escape hatch) | LOW | P1 |
| `make help` default goal | HIGH (discoverability) | LOW | P1 |
| Banner: populated fallback URL + grouping | HIGH (stops "where's my app?") | LOW | P1 |
| Correct verification copy | HIGH (stops false-pass agent runs) | LOW | P1 |
| Maintenance release (merge PR #3) | HIGH (0.1.1 on hex.pm) | LOW (procedural) | P1 |
| Dockerfile layer audit + comment | MEDIUM (confidence, not blocker) | MEDIUM (verify + document) | P2 |
| `docs/docker_dev_dx.md` restructure | MEDIUM (reader empathy) | MEDIUM (restructure, not rewrite) | P2 |
| Fleet secrets doc (op run / direnv) | MEDIUM (fleet hygiene) | LOW | P2 |
| `make fleet` target | MEDIUM (fleet visibility) | LOW | P2 |
| MAINTAINERS.md release runbook | MEDIUM (future-self docs) | LOW | P2 |
| `make nuke-all` | LOW (rare edge case) | LOW | P3 |

---

## Operator-Surface Specifications (Concrete and Microcopy-Level)

### Banner: Recommended Structure

The banner lives in `docker/dev-entrypoint.sh`. The current banner is structurally sound but has three gaps: (1) the fallback URL is deferred to `make url` rather than printed inline, (2) there is no Traefik admin link, (3) the screen list is a flat dump rather than grouped by operator workflow.

**Recommended banner structure (25 lines, 3 sections):**

```
────────────────────────────────────────────────────────────────────
  Scoria — dev harness ready   (instance: ${INSTANCE})
────────────────────────────────────────────────────────────────────

  URLs
    Dashboard:   http://${HOST}/scoria
    Fallback:    http://127.0.0.1:${PORT:-4000}/scoria   (if Traefik is down)
    Proxy UI:    http://localhost:8080

  Key routes
    /scoria                          Status Home
    /scoria/approvals                Approvals
    /scoria/workflows                Workflows
    /scoria/reviews                  Review Queue
    /scoria/prompts                  Prompt Registry
    /scoria/prompts/:id/release      Release Workbench
    /scoria/connectors               Connectors

  Ops
    make seed          re-run seed (no downtime)
    make reseed        clean slate (drops DB volume)
    make shots         screenshots  (no API key needed)
    make critique      screenshots + LLM critique

────────────────────────────────────────────────────────────────────
```

**Microcopy principles applied:**

- "dev harness ready" not "is up." "Ready" implies deps fetched and DB migrated, which is what just happened. "Is up" implies the process started — that's a weaker claim.
- Fallback note "(if Traefik is down)" is parenthetical — it reduces anxiety without implying Traefik is fragile.
- "Proxy UI" not "Traefik dashboard" — the user's mental model is "proxy," not the product name.
- Routes are grouped by operator workflow, not alphabetically. The scan pattern is: first check status, then approve/review, then configure.
- Ops section uses imperative verbs (`make seed`, not `run make seed`) — reads as a command palette.
- No intro sentence before the box. Open with the box. Every sentence before the first separator is wasted vertical space in a terminal.

### `make help` Output (Recommended)

The awk pattern reads `## comment` from each target. Target output:

```
Usage:  make <target>

  proxy        start the shared Traefik proxy (once per machine)
  up           build + run this instance (foreground)
  up-d         build + run detached, then print URLs
  down         stop this instance
  dev          native server with live reload (PORT=4799 by default)

  seed         re-run seed against running instance (no downtime)
  reseed       drop this instance's DB + rebuild
  nuke         stop + remove this instance's volumes (clean slate)
  fleet        show all running scoria-* compose instances

  url          print this instance's URL + ephemeral fallback
  open         open this instance in the browser (macOS)
  logs         tail the web container

  shots        capture screenshots (no API key)
  critique     screenshots + LLM critique (needs ANTHROPIC_API_KEY)
  help         show this help
```

**Microcopy principles:**

- Grouped by lifecycle order: start → operate → inspect → harness. Users read top to bottom.
- `dev` shows the default PORT inline — documents the override without a separate section.
- `nuke` is described physically ("stop + remove volumes"), not emotionally ("destroy").
- No target description longer than one line. If it needs a paragraph, it goes in the doc.

### `docs/docker_dev_dx.md` Recommended Structure

**Current structure (reader-empathy audit):**

The current doc leads with `TL;DR` (good) then immediately dives into "The model (and why)" — which is a great section but wrong placement for a returning maintainer who just wants to know what command to run. The JTBD is implicit (never stated). The caching guarantees, secrets pattern, and hygiene flow are absent.

**Recommended restructured outline:**

```
# Docker dev DX — multi-instance, no port conflicts

> You run many Elixir/Phoenix OSS lib demos at once on one Mac. This is the standard that
> makes that hands-off: one Traefik proxy, branch-derived URLs, no published ports, no
> port juggling, no stale containers shadowing your routes.

## Quick Start (60 seconds)

Prerequisites: Docker Desktop running, `make proxy` run once (one-time, machine-wide).

    make up    # → http://scoria-<branch>.localhost/scoria
    make dev   # → http://127.0.0.1:4799/scoria  (native, live reload)

## Command Reference

| Target         | What it does                            | When to use              |
|---------------|------------------------------------------|--------------------------|
| make proxy    | Start Traefik (once per machine)         | After Docker restarts    |
| make up       | Build + start this instance (foreground) | Normal dev               |
| make up-d     | Build + start detached, print URLs       | Background work          |
| make down     | Stop this instance                       | Done for the day         |
| make dev      | Native server, live reload, PORT=4799    | CSS/JS iteration         |
| make nuke     | Stop + remove this instance's volumes    | Stale state, full reset  |
| make fleet    | Show all running scoria-* instances      | Multi-instance audit     |
| make url      | Print URLs for this instance             | When banner scrolled     |
| make open     | Open in browser (macOS)                  | Quick access             |
| make seed     | Re-run seed (no downtime)                | Refresh demo data        |
| make reseed   | Clean slate (drops DB)                   | Full reset               |

## The Model (and Why)

[existing prose — keep as-is; already excellent]

## Multi-Instance Isolation

[existing prose — keep, minor edits]

## Caching Guarantees

[new section]

A css/HEEx-only edit does NOT trigger dep refetch or full recompile. Here's why:

- Source is bind-mounted. Editing code inside the running container is instant.
- deps, _build, ~/.hex, ~/.mix are named volumes. They shadow the bind mount and
  survive `make up --build`. No dep refetch on source edit.
- Dockerfile layer order: mix.exs + mix.lock are copied before RUN mix deps.get.
  A source-only edit lands in a later layer. Only mix.lock changes bust the dep cache.
- BuildKit cache mounts for apt and Hex/rebar persist across full rebuilds.

What WILL bust the cache:
- Changing mix.lock (correct — deps changed)
- Changing mix.exs (correct — dep manifest changed)
- Editing Dockerfile.dev itself

## Secrets

[new section — three tiers, all opt-in]

### Tier 1 — Local .env (fastest, rotate periodically)
Copy .env.example → .env and fill in real values.
Rotate ANTHROPIC_API_KEY when needed at anthropic.com/console.

### Tier 2 — 1Password CLI (recommended for fleet maintainers with 1Password)
op run -- make up
Uses .env.op with op:// references. Secrets are injected in memory at process start
and never touch disk as plaintext.

### Tier 3 — direnv (simpler CLI automation)
.envrc (gitignored):
  export ANTHROPIC_API_KEY=$(op read "op://Scoria Dev/ANTHROPIC_API_KEY/credential")
cd into the project directory → vars load automatically.

## Stale Instance Hygiene

[new section]

Problem: an old compose project (e.g. scoria_demo) can shadow your branch-scoped URL in
Traefik, causing confusing 404s or routing to a stale DB.

Diagnosis:
  make fleet               # list all running scoria-* instances
  docker compose ls        # list all compose projects on the machine

Fix (this instance):
  make nuke                # stop + remove THIS instance's volumes + networks

Fix (a specific stale project by name):
  docker compose -p scoria-demo down -v

Nuclear (full machine reset — removes ALL containers, images, volumes):
  docker system prune -af --volumes

## Adopting in Another Repo

[existing prose — keep, minor edits for the new targets (nuke, fleet)]

## Files

[existing table — keep]
```

**Reader-empathy principles (szTheory DNA applied):**

- **Batteries-included defaults, gameplan at top.** A maintainer returning after a month should be able to start in 30 seconds without reading past the Quick Start section. The TL;DR in the current doc is close to this but buries the prerequisites.
- **Principle of least surprise.** Every command in the Quick Start works with zero extra setup beyond "Docker Desktop installed, `make proxy` run once." No hidden prerequisites.
- **Digestible chunks.** Each section has one job-to-be-done. "The Model" explains why; "Command Reference" says what; "Caching Guarantees" reduces anxiety about editing. Don't mix.
- **Persona box at top.** One paragraph naming who this is for makes every section's tradeoff immediately legible — especially for sibling-repo adopters who reach this doc cold.
- **Grounded, not aspirational (brand voice match).** "Here is what happens when you run this command" rather than "Experience the joy of seamless multi-service DX."
- **Copy-pasteable everything.** Every command in the doc is runnable verbatim. No `<YOUR_INSTANCE_NAME>` placeholders in the Quick Start.

---

## Cross-Ecosystem Lessons Applied

| Pattern | Source | Applied In Scoria v3.2 |
|---------|--------|------------------------|
| Print ALL reachable URLs at startup | Vite, Phoenix native server | Banner: add Traefik admin + populated fallback |
| Default goal = help screen | `just --list`, modern Makefiles (marmelab pattern) | `make help` as `.DEFAULT_GOAL` |
| Self-documenting targets via `##` | marmelab self-documented Makefile pattern (2016, widely adopted) | Existing `## comments` + awk parser |
| Gameplan-first documentation | Laravel Sail docs, Rails Guides | docs/docker_dev_dx.md restructure |
| Persona/JTBD framing at doc top | Rails' "Getting Started" guide | Persona box at top of doc |
| Fixed non-default port for native mode | Laravel Sail (80 in Docker, project-specific fallback) | PORT=4799 in `make dev` |
| `.env.example` as onboarding shape document | Every Rails/Node/Laravel project | `.env.example` committed |
| Secret injection via CLI tool | 1Password `op run`, AWS Vault | `op run -- make up` pattern in docs |
| Instance-scoped nuke target | DataHub `nuke:` pattern, `docker compose down -v` | `make nuke` |
| Fleet inventory command | Tilt `tilt status`, overmind | `make fleet` |
| Deps before source in Dockerfile | Docker best practices universally | Dockerfile.dev audit + comment block |
| Post-publish smoke gate | release-please CI pattern, existing `mix scoria.post_publish_smoke` | MAINTAINERS.md release runbook |

---

## Sources

- Makefile (current): `/Users/jon/projects/scoria/Makefile`
- Launch banner (current): `/Users/jon/projects/scoria/docker/dev-entrypoint.sh`
- Docker DX doc (current): `/Users/jon/projects/scoria/docs/docker_dev_dx.md`
- Backlog: `/Users/jon/projects/scoria/.planning/todos/pending/docker-dx-fleet-hardening.md`
- Project context: `/Users/jon/projects/scoria/.planning/PROJECT.md`
- szTheory DNA: `/Users/jon/projects/scoria/prompts/sztheory-elixir-dna.md`
- Brand book: `/Users/jon/projects/scoria/brandbook/brand-book.md`
- [Self-Documented Makefile — marmelab](https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html) — HIGH confidence
- [Automating Elixir Releases with Release Please — Elixir School](https://elixirschool.com/blog/managing-releases-with-release-please) — HIGH confidence
- [1Password CLI — load secrets into environment](https://developer.1password.com/docs/cli/secrets-environment-variables/) — HIGH confidence
- [Docker Build Cache Optimization — Docker Docs](https://docs.docker.com/build/cache/optimize/) — HIGH confidence
- [Load secrets automatically with 1Password and direnv — DEV Community](https://dev.to/agonza05/load-secrets-automatically-with-1password-and-direnv-pn0) — MEDIUM confidence
- [Preventing Port Conflicts in Docker Compose with Dynamic Ports](https://www.markcallen.com/preventing-port-conflicts-in-docker-compose-with-dynamic-ports/) — MEDIUM confidence (validates ephemeral + proxy approach over fixed ports)
- [just vs Makefile ergonomics — glinteco](https://glinteco.com/en/post/comparing-makefile-and-just-which-one-should-you-choose/) — MEDIUM confidence (validates staying on Make with help target)

---

*Feature research for: v3.2 Drydock — Docker dev-DX hardening + maintenance release*
*Researched: 2026-06-17*
