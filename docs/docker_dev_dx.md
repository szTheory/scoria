# Docker dev DX - multi-instance, no port conflicts

This guide is for the solo maintainer running many Phoenix/Elixir demo repos
on one Mac. The job is a hands-off, port-conflict-free local loop: one
predictable Scoria dashboard route, no `:4000` or `:5432` juggling, scoped
cleanup when an old instance gets in the way, and enough diagnostics to tell
which checkout owns which route.

Scoria is dev-Dockerized only. It ships to Hex as a Phoenix library; the
Compose, Makefile, Traefik, and native helper files below are repository
tooling, not package contents.

## TL;DR

```bash
make proxy       # once per machine: shared Traefik proxy + `proxy` network
make up-build    # first run, or after mix.lock/Dockerfile/config dependency changes
make up          # daily Docker source/style loop: start without rebuilding
make url         # print Traefik URL + ephemeral 127.0.0.1 fallback
make open        # open the Traefik URL in the browser (macOS)
make fleet       # list all Traefik-routed demo containers across local repos
make doctor      # route/proxy/native-DB diagnostics when something feels off
make dev         # native host server + pgvector helper on SCORIA_DB_PORT=55432
```

Default path for the Scoria repo dashboard:

```bash
make proxy
make up-build
make up
make url
```

Open the printed `http://<instance>.localhost/scoria` route, or run
`make open` on macOS. Use native mode only when host Mix iteration,
screenshots, Playwright/e2e, or another task explicitly needs the BEAM running
on the host:

```bash
make dev
# open http://localhost:4799/scoria
```

## Mental model

Three rules remove the recurring local-development collision class:

1. **One shared reverse proxy, routes by instance.** A single Traefik process
   joins the external `proxy` network. Every local demo web service joins that
   network, carries labels, and is reached at `http://<instance>.localhost/...`.
   Unlimited Phoenix dashboards share ports 80/443 because the apps do not
   publish fixed HTTP ports.
2. **No published database ports in the Docker stack.** The dashboard container
   reaches Postgres by Compose service name (`SCORIA_DB_HOST=db`) on the
   project network. This keeps every repo away from the shared host `5432`
   lane.
3. **Ephemeral loopback is only a fallback.** The Docker web service maps
   Docker-internal container port `4000` to a random `127.0.0.1` host port.
   `make url` prints that fallback for proxy outages. Container `:4000` is the
   Traefik service target and ephemeral fallback source, not the browser start
   URL.

Instance identity comes from `COMPOSE_PROJECT_NAME` and `SCORIA_HOST`. The
[Makefile](../Makefile) derives both from the branch plus a stable checkout
hash:

```make
APP         := scoria
BRANCH      := $(shell git rev-parse --abbrev-ref HEAD | tr '/A-Z' '-a-z' | sed 's/[^a-z0-9-]/-/g')
WORKTREE    := $(shell git rev-parse --show-toplevel 2>/dev/null || pwd)
WORKTREE_ID := $(shell printf '%s' '$(WORKTREE)' | shasum | awk '{print substr($$1,1,8)}')
INSTANCE ?= $(APP)-$(BRANCH)-$(WORKTREE_ID)
export COMPOSE_PROJECT_NAME = $(INSTANCE)
export SCORIA_HOST          = $(INSTANCE).localhost
```

The generated shape is `scoria-<branch>-<hash>`, for example
`http://scoria-main-a1b2c3d4.localhost/scoria`. Override deliberately with
`make up INSTANCE=scoria-foo`. Bare `docker compose up` falls back to
`scoria` / `scoria.localhost`; set the two vars in `.env` only when you
intentionally run without the Makefile.

## Docker daily loop

Use this when you want the Scoria repo dashboard in the same model the fleet
uses: Traefik route, unpublished DB, per-instance volumes, and no host HTTP or
Postgres port ownership.

Commands:

```bash
make proxy
make up-build
make up
make url
make open
```

Expected output:

```text
Instance:  scoria-<branch>-<hash>
Traefik:   http://scoria-<branch>-<hash>.localhost/scoria
Fallback:  http://127.0.0.1:<ephemeral>/scoria
Traefik admin: http://localhost:8080
```

Footguns:

- `make proxy` is machine-wide. Run it once, then leave it running.
- `make up-build` is for the first run or intentional image rebuilds. The
  daily source/style loop is `make up`.
- **No top-level `name:` and no `container_name:`.** Both defeat per-instance
  scope and make the second checkout collide.
- Docker container port `4000` remains internal. If you need a browser route,
  use the Traefik URL from `make url`.

Recovery:

```bash
make doctor
make fleet
make down INSTANCE=<project>
make nuke INSTANCE=<project>
```

`make nuke INSTANCE=<project>` wipes only that Compose project's named volumes:
its DB data, deps/build volumes, and Hex/Mix caches. It is not a daemon-wide
cleanup command.

## Native dev server

Use this only when the BEAM needs to run on the host: LiveReload iteration,
native Mix debugging, screenshots, Playwright/e2e, or maintainer harnesses.

Commands:

```bash
make dev
# open http://localhost:4799/scoria
```

For screenshot and e2e work:

```bash
make dev
mix scoria.ui.shots --url http://localhost:4799/scoria
mix scoria.ui.e2e --base-url http://localhost:4799/scoria
```

Expected output:

```text
==> Scoria dev (native) -> http://localhost:4799/scoria
==> Native DB -> 127.0.0.1:55432 (pool 5)
```

`make dev` starts the helper in
[dev/pgvector-compose.yml](../dev/pgvector-compose.yml) under a separate
`<instance>-native` Compose project, then runs the host server with:

```bash
SCORIA_DB_PORT=55432
SCORIA_DB_POOL_SIZE=5
PORT=4799
```

Override the native lane explicitly when you need to:

```bash
SCORIA_DB_PORT=56432 SCORIA_DB_POOL_SIZE=3 PORT=4899 make dev
```

Footguns:

- Native mode publishes a Postgres port because host Mix needs one. The Docker
  dashboard stack does not.
- Direct `docker compose -f dev/pgvector-compose.yml` defaults the Compose
  project name to `dev`, which is easy to collide across repos. Prefer the
  Makefile targets.
- Raw `mix test` also defaults to `SCORIA_DB_PORT=55432`; tune
  `SCORIA_TEST_DB_POOL_SIZE` or `SCORIA_DB_POOL_SIZE` when several suites run.

Recovery:

```bash
make native-db-status
make native-db-down
make doctor
```

## Caching guarantees

Use this when you need to know whether a source, style, config, or dependency
edit should rebuild the Docker image.

Commands:

```bash
make up          # source, HEEx, CSS, and JS daily loop
make up-build    # dependency, Dockerfile, or config rebuild path
make up-d        # detached daily loop, then print URL
make up-d-build  # detached rebuild path, then print URL
```

Expected output:

- `make up` uses `docker compose up --no-build`. If the image does not exist
  yet, Docker says so; run `make up-build` once.
- Source is bind-mounted.
- `deps`, `_build`, `~/.hex`, and `~/.mix` are named volumes, so Linux build
  artifacts never collide with host macOS artifacts.
- CSS/JS changes rebuild runtime assets through `ScoriaWeb.DevAssetWatcher`.

Footguns:

- `.dockerignore` must exclude host `_build/`, `deps/`, and
  `priv/static/scoria/`; leaking host artifacts into the Linux image causes
  architecture and stale-bundle failures.
- macOS file events do not cross the Docker VM. The container uses
  `FILE_SYSTEM_BACKEND=fs_poll` so Phoenix LiveReload and the asset watcher can
  see changes.
- Docker Desktop should use VirtioFS. `:cached` and `:delegated` bind flags are
  legacy no-ops here.

Recovery:

```bash
make up-build
make doctor
```

Layer-cache invalidation applies only to an explicit build. Day-to-day
`make up` does not rebuild image layers at all.

| You edit | First invalidated layer | What re-runs |
|----------|-------------------------|--------------|
| CSS (`assets/css/*.css`) or any `assets/` file | none - `assets/` is not `COPY`'d; assets build in-container at runtime and `priv/static/scoria/` is `.dockerignore`'d | nothing rebuilds; running container rebuilds assets on the fly |
| A `.heex` template or any `lib/`, `dev/`, `priv/` source file | `COPY lib lib` (step 3) | `mix compile` - app compile only; deps untouched |
| Anything under `config/` | `COPY config config` (step 2) | `mix deps.compile` + `mix compile` |
| `mix.exs` or `mix.lock` | `COPY mix.exs mix.lock` (step 1) | `mix deps.get` -> `mix deps.compile` -> `mix compile` (full dep rebuild) |

## Secrets

Use this only for the screenshot critique pass. The dashboard, normal Docker
loop, and native dev server do not need `ANTHROPIC_API_KEY`.

Commands:

```bash
op signin
cp .envrc.example .envrc
cp .env.op.example .env.op
direnv allow .
```

Edit `.env.op` so the `op://` secret reference points at your real 1Password
vault, item, and field.

Docker critique:

```bash
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique
```

Native Mix critique:

```bash
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique
```

Expected output:

- `.env.op` stores 1Password secret references only, not plaintext key
  material.
- `op run --env-file` resolves references only for the wrapped child process.
- Compose creates a runtime secret from the resolved `ANTHROPIC_API_KEY` and
  mounts it only into the profile-gated `critique` service.
- `docker compose config` shows the secret source name, not the token value.

Footguns:

- Do not commit `.envrc` or `.env.op`; both are local files and are gitignored.
- Do not put real provider keys in `.envrc`, `.env`, docs, shell history, logs,
  screenshots, or planning artifacts.
- Sign in to 1Password before running a critique command.
- Re-run `direnv allow .` after changing `.envrc`.

Recovery:

```bash
op signin
direnv allow .
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- env | rg '^ANTHROPIC_API_KEY='
```

If a real provider key was exposed outside a process-scoped command, rotate it
at the provider before using it again.

## Stale instance hygiene

Use this when a route opens the wrong checkout, the fallback points at a
different container, or a previous branch's data is still in the way.

The source of truth for the latest local Scoria UI is always the route printed by `make url`
from the checkout you are working in. Old milestone or branch hostnames such
as `scoria-v217-brand-vesicle.localhost` are just running Compose projects;
they are not aliases for "latest".

Commands:

```bash
make fleet
make doctor
make down INSTANCE=<project>
make nuke INSTANCE=<project>
```

Expected output:

- `make fleet` lists Traefik-routed demo containers across the local fleet,
  including Compose project, container name, status, and ports.
- `make doctor` prints the current Scoria instance, proxy network status,
  whether the current web container is running, stale Scoria routes that are
  not this checkout, the routed container table, native pgvector helper status,
  and host Postgres connection pressure.

Footguns:

- Stop only the instance you identified. Do not assume every route named
  `scoria-*` belongs to the checkout in your shell.
- `make down INSTANCE=<project>` stops containers and keeps volumes.
- `make nuke INSTANCE=<project>` stops containers and deletes only that
  instance's named volumes. It should be a scoped reset, not a vague "things
  are weird" reflex.

Recovery:

```bash
make fleet
make doctor
make down INSTANCE=<project>
make up
make url
```

If data is the problem:

```bash
make fleet
make nuke INSTANCE=<project>
make up-build
make url
```

## Adopting this in another repo

The portable standard is: one shared Traefik network, per-checkout Compose
project names, no published backing-service ports, an ephemeral HTTP fallback,
and Makefile commands that print the browser route.

1. Create the proxy network and run the shared proxy once:

   ```bash
   docker network create proxy
   docker compose -f docker/traefik/compose.yml up -d
   ```

2. In the project's `compose.yml`, give each web service a route and an
   ephemeral fallback:

   ```yaml
   services:
     web:
       environment:
         PHX_HOST: ${MYAPP_HOST:-myapp.localhost}
       ports:
         - "127.0.0.1::4000"        # ephemeral fallback; never a fixed port
       networks: [default, proxy]
       labels:
         - traefik.enable=true
         - traefik.docker.network=proxy
         - traefik.http.routers.${COMPOSE_PROJECT_NAME:-myapp}.rule=Host(`${MYAPP_HOST:-myapp.localhost}`)
         - traefik.http.routers.${COMPOSE_PROJECT_NAME:-myapp}.entrypoints=web
         - traefik.http.routers.${COMPOSE_PROJECT_NAME:-myapp}.service=${COMPOSE_PROJECT_NAME:-myapp}
         - traefik.http.services.${COMPOSE_PROJECT_NAME:-myapp}.loadbalancer.server.port=4000
   networks:
     proxy: { external: true }
     default:
   ```

   Do not publish DB ports. Do not add `container_name:`. Do not add top-level
   Compose `name:`.

3. Copy the Makefile instance block and rename the app and host variable:

   ```make
   APP         := myapp
   BRANCH      := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/A-Z' '-a-z' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$$//')
   WORKTREE    := $(shell git rev-parse --show-toplevel 2>/dev/null || pwd)
   WORKTREE_ID := $(shell root='$(WORKTREE)'; if command -v shasum >/dev/null 2>&1; then printf '%s' "$$root" | shasum | awk '{print substr($$1,1,8)}'; else printf '%s' "$$root" | cksum | awk '{print $$1}'; fi)
   INSTANCE ?= $(APP)-$(if $(BRANCH),$(BRANCH),local)-$(WORKTREE_ID)
   export COMPOSE_PROJECT_NAME = $(INSTANCE)
   export MYAPP_HOST           = $(INSTANCE).localhost
   ```

4. Add `make url`, `make fleet`, and `make doctor` equivalents. The important
   behavior is label-based discovery
   (`docker ps --filter label=traefik.enable=true`) instead of name-prefix
   discovery, because a local fleet will not all start with the same repo name.

### Converge the fleet onto one proxy network

The biggest cross-repo footgun is two competing shared proxy networks, for
example `proxy` and `local-dev-proxy`. If Traefik is on one and a repo joins
the other, labels look correct but the service is invisible to routing. Pick
`proxy`, point every repo at it, and delete the stray network. The
`traefik.docker.network` label must name the real network: an external `proxy`
is unprefixed; an in-file network gets project-prefixed.

### Safari / curl-by-hostname

`*.localhost` resolves natively in Chrome/Chromium and modern curl, which covers
day-to-day dev and the harness. Safari does not resolve it. If you need Safari
or hostname-based curl, add a one-time wildcard resolver:

```bash
brew install dnsmasq
echo 'address=/localhost/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf
sudo brew services start dnsmasq
sudo mkdir -p /etc/resolver
echo 'nameserver 127.0.0.1' | sudo tee /etc/resolver/localhost
```

Add `mkcert` only if you also want HTTPS locally.

## Files

| File | Role |
|------|------|
| [compose.yml](../compose.yml) | Dashboard stack: unpublished `db`, Traefik-routed `web`, ephemeral fallback, profile-gated `shots` / `critique`. |
| [Dockerfile.dev](../Dockerfile.dev) | Dev-only image; layer-ordered with BuildKit cache mounts. |
| [docker/traefik/compose.yml](../docker/traefik/compose.yml) | Shared proxy, run once per machine. |
| [docker/dev-entrypoint.sh](../docker/dev-entrypoint.sh) | DB setup plus URL, route, and harness banner. |
| [dev/pgvector-compose.yml](../dev/pgvector-compose.yml) | Native-host DB helper, publishing `${SCORIA_DB_PORT:-55432}`. |
| [Makefile](../Makefile) | Command source of truth: `proxy`, `up-build`, `up`, `up-d`, `down`, `url`, `open`, `fleet`, `doctor`, `native-db`, `native-db-down`, `dev`, `shots`, `critique`. |
