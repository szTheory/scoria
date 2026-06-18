# Docker dev DX — multi-instance, no port conflicts

This is the local-development setup for the Scoria dashboard, and the **reference
standard** for running many Elixir/Phoenix lib demos side by side on one machine
without host-port conflicts. Scoria is dev-Dockerized only — it ships to Hex as a
library; none of the files below are in the package.

## TL;DR

```bash
make proxy     # once per machine: shared Traefik proxy + `proxy` network
make up        # build + run THIS checkout -> http://scoria-<branch>.localhost/scoria
make url       # print the URL + the ephemeral 127.0.0.1 fallback
make open      # open it in the browser (macOS)
make dev       # native host server with live CSS/JS reload (no Docker)
```

Two checkouts/branches can `make up` at the same time — each gets its own URL,
DB, and volumes. No port juggling.

## The model (and why)

Three rules eliminate the entire port-conflict class:

1. **One shared reverse proxy, host-routing by name.** A single long-lived
   Traefik joins an external `proxy` network; every app joins it and carries
   labels, and is reached at `http://<name>.localhost/...`. Unlimited web UIs
   share ports 80/443 — no app publishes its own HTTP port. `*.localhost`
   resolves to `127.0.0.1` automatically in Chrome/Chromium (so the screenshot
   harness works) and modern curl. See [docker/traefik/compose.yml](../docker/traefik/compose.yml).
2. **Never publish DB/Redis ports.** Backing services are reached by compose
   service name on the project's own network (`SCORIA_DB_HOST=db`). This kills
   the recurring `5432 already in use` across projects outright. (A *native*
   host `mix` run is the one exception — see [dev/pgvector-compose.yml](../dev/pgvector-compose.yml),
   which publishes a high, fleet-unlikely `55432`.)
3. **Ephemeral loopback only as a fallback.** The web service also maps
   `127.0.0.1::4000` — Docker picks a free host port, so it can never collide.
   Use it when Traefik is down (`make url` prints it). Never use a **fixed**
   published HTTP port — every Phoenix wants 4000, so fixed ports are the
   anti-pattern that started all of this.

## Running multiple instances

Identity is driven by `COMPOSE_PROJECT_NAME` (Compose prefixes containers and
named volumes with it → free per-instance data isolation) and `SCORIA_HOST`
(the Traefik route). The [Makefile](../Makefile) derives both from the git
branch:

```make
BRANCH   := $(shell git rev-parse --abbrev-ref HEAD | tr '/A-Z' '-a-z' | sed 's/[^a-z0-9-]//g')
INSTANCE ?= scoria-$(BRANCH)
export COMPOSE_PROJECT_NAME = $(INSTANCE)
export SCORIA_HOST          = $(INSTANCE).localhost
```

So branch `main` → `http://scoria-main.localhost/scoria`; branch `feat/x` →
`http://scoria-feat-x.localhost/scoria`. Override with `make up INSTANCE=scoria-foo`.
Bare `docker compose up` (no Makefile) falls back to `scoria`/`scoria.localhost`;
set the two vars in `.env` to pin a different instance.

**Footguns this avoids:**
- **No top-level `name:` and no `container_name:`.** Both defeat per-instance
  prefixing — a fixed `container_name` makes a second instance fail with
  "name already in use". Let `COMPOSE_PROJECT_NAME` win.
- **Traefik router/service ids and the Host rule interpolate the instance**, or
  two instances would collide on one route.

## No rebuild on source/style edits

- **Source is bind-mounted**; `deps`, `_build`, `~/.hex`, `~/.mix` are **named
  volumes** that shadow the bind mount. Editing code never re-fetches or
  re-compiles dependencies, and the Linux-native build artifacts never clash
  with the host's macOS/arm64 ones.
- **`.dockerignore` excludes host `_build/`/`deps/`** — leaking host-arch NIFs
  into the Linux image causes "Failed to load NIF" crashes.
- **CSS/JS hot-reload:** `ScoriaWeb.DevAssetWatcher` (dev-only) rebuilds
  `priv/static/scoria/app.{css,js}` when `assets/` changes; the existing
  `live_reload` pattern then refreshes the page. No manual
  `mix scoria.assets.build`. (`make dev`, native, enables browser refresh via
  `SCORIA_DEV_LIVE_RELOAD=1`; the dockerized `web` keeps reload off so the
  screenshot harness stays deterministic.)
- **macOS fs events don't cross the Docker VM**, so the container sets
  `FILE_SYSTEM_BACKEND=fs_poll` (config/dev.exs gates phoenix_live_reload *and*
  the asset watcher onto polling).
- **Cold builds** reuse BuildKit cache mounts for apt + the Hex/rebar caches —
  see [Dockerfile.dev](../Dockerfile.dev). Use VirtioFS in Docker Desktop;
  `:cached`/`:delegated` mount flags are legacy no-ops now — don't add them.

### Layer-cache invalidation (cold `docker compose up --build` only)

Day-to-day you run `docker compose up`: source is bind-mounted and `deps`/`_build`
are named volumes, so **editing anything rebuilds no image layer at all** — you just
restart the app. The table below applies only to a cold `--build`, where the
`Dockerfile.dev` COPY order decides what the BuildKit cache can reuse. (The base
image + `apt` layer sit above all of these and rebuild only when the base image or
package list changes.)

| You edit | First invalidated layer | What re-runs |
|----------|-------------------------|--------------|
| CSS (`assets/css/*.css`) or any `assets/` file | **none** — `assets/` is not `COPY`'d (built in-container at runtime; `priv/static/scoria/` is `.dockerignore`'d) | nothing rebuilds; running container rebuilds assets on the fly |
| A `.heex` template or any `lib/`, `dev/`, `priv/` source file | `COPY lib lib` (step 3) | `mix compile` — **app compile only**; deps untouched |
| Anything under `config/` | `COPY config config` (step 2) | `mix deps.compile` + `mix compile` |
| `mix.exs` or `mix.lock` | `COPY mix.exs mix.lock` (step 1) | `mix deps.get` → `mix deps.compile` → `mix compile` (full dep rebuild) |

## Secrets (ANTHROPIC_API_KEY)

The dashboard and normal dev server do not need this key. The screenshot critique pass does.

### First-time setup

Install `direnv` and the 1Password CLI, then enable the `direnv` shell hook for
your shell.

```bash
op signin
cp .envrc.example .envrc
cp .env.op.example .env.op
```

Edit `.env.op` so the `op://` secret reference points at your real
1Password vault, item, and field. Then allow the local direnv file once:

```bash
direnv allow .
```

### Run the critique pass

Docker:

```bash
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique
```

Native Mix:

```bash
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique
```

### How it works

`.env.op` stores 1Password secret reference values only, not plaintext key
material. `op run` resolves those references only for the wrapped child process.
For Docker, Compose receives the resolved `ANTHROPIC_API_KEY` from that child
environment and interpolates it into the profile-gated `critique` service. For
native Mix, the same runtime variable name stays in use.

### Footguns

- Never commit `.envrc` or `.env.op`; both are local files and are gitignored.
- A secret reference (`op://...`) is safe to commit in an example. A plaintext
  key is not.
- Do not put real provider keys in `.envrc` or `.env`.
- Sign in to 1Password before running a critique command.
- Re-run `direnv allow .` after changing `.envrc`.
- Rotate any key that touched disk as plaintext.

## Adopting this in another repo

1. `docker network create proxy` and run the shared proxy once:
   `docker compose -f docker/traefik/compose.yml up -d` (copy that file).
2. In the project's `compose.yml`, for each web service:
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
         - traefik.http.services.${COMPOSE_PROJECT_NAME:-myapp}.loadbalancer.server.port=4000
   networks:
     proxy: { external: true }
     default:
   ```
   Don't publish DB ports. No `container_name:`. No top-level `name:`.
3. Copy the Makefile `INSTANCE`/`COMPOSE_PROJECT_NAME`/`SCORIA_HOST` block
   (rename the host var).

### Converge the fleet onto one proxy network

The biggest cross-repo footgun is **two competing shared proxy networks** (e.g.
`proxy` and `local-dev-proxy`): if Traefik is on one and a repo joins the other,
that repo's services are invisible to routing — labels look correct but you get
502s. Pick **`proxy`**, point every repo at it (`networks: {proxy: {external:
true}}`), and delete the stray network. The `traefik.docker.network` label must
name the **real** network: an external `proxy` is unprefixed; an in-file network
gets project-prefixed.

### Safari / curl-by-hostname (optional)

`*.localhost` resolves natively in Chrome/Chromium and modern curl — enough for
day-to-day dev and the harness. **Safari does not** resolve it. If you need
Safari (or `curl http://scoria.localhost` without a Host header), add a one-time
wildcard resolver:

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
| [compose.yml](../compose.yml) | The dashboard stack: `db` (unpublished pgvector), `web` (Traefik + ephemeral fallback), profile-gated `shots`/`critique`. |
| [Dockerfile.dev](../Dockerfile.dev) | Dev-only image; layer-ordered + BuildKit cache mounts. |
| [docker/traefik/compose.yml](../docker/traefik/compose.yml) | Shared proxy (run once, machine-wide). |
| [docker/dev-entrypoint.sh](../docker/dev-entrypoint.sh) | DB setup + URL/route banner. |
| [dev/pgvector-compose.yml](../dev/pgvector-compose.yml) | Native-host DB only (publishes 55432). |
| [Makefile](../Makefile) | `proxy`/`up`/`down`/`url`/`open`/`dev`/`shots`/`critique`. |
