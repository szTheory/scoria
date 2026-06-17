# Stack Research — v3.2 Drydock

**Milestone:** v3.2 Drydock
**Domain:** DevX/DevOps + release hygiene for a solo-maintainer Phoenix-native Hex library
**Researched:** 2026-06-17
**Confidence:** HIGH (all concrete mechanisms verified against live source files; tool behavior
verified against official docs and community practice)

---

## What This Stack Document Covers

Five concrete mechanism decisions for the gaps in v3.2 Drydock:

- **(A1) PORT default** — bake a non-4000 default into `make dev` without colliding the fleet
- **(A2) Dockerfile layer-caching** — guarantee a CSS/HEEx-only edit triggers no dep refetch
- **(A3) Fleet secrets pattern** — replace plaintext `.env` `ANTHROPIC_API_KEY` with a
  vault-backed, zero-plaintext-on-disk approach
- **(A4) `make nuke`/clean + stale-instance hygiene** — define the compose down/prune flow
- **(B) Maintenance release** — merge the open release-please PR (PR #3, `0.1.2`), Hex publish
  flow, and post-publish registry smoke

---

## (A1) PORT Default for `make dev`

### Current State

`config/dev.exs` line 33:
```elixir
http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))]
```

`Makefile` line 61:
```make
dev:
  SCORIA_DEV_LIVE_RELOAD=1 mix phx.server
```

The `dev` target passes no `PORT`, so the native harness binds `:4000`. Since every other Phoenix
lib demo on the same Mac also wants `:4000`, the maintainer must remember to pass `PORT=4799 make
dev` or the bind fails with "address already in use".

### Recommendation: Static Non-4000 Default Baked into the Makefile Target

**Mechanism:** Add `PORT ?= 4799` near the top of the Makefile (in the per-instance identity
block), then pass it explicitly in the `dev` target:

```make
PORT ?= 4799

## dev: native host server with live browser reload (for CSS/JS iteration;
##      the asset watcher rebuilds the bundle, live reload refreshes the page)
##      Binds PORT (default 4799) to avoid clashing with other lib demos on :4000.
dev:
  PORT=$(PORT) SCORIA_DEV_LIVE_RELOAD=1 mix phx.server
```

**Why not a free-port auto-picker?**

An auto-picker (`python3 -c "import socket; ..."` or a `lsof` loop) has two footguns:
1. The discovered port is not stable across invocations — you get a different URL every `make dev`,
   breaking the Playwright harness (`make shots-native`) which hard-codes `localhost:4000`.
2. It introduces shell scripting brittleness into a Makefile that is otherwise plain and portable.

The brand voice is "least surprise". A stable port you can bookmark is better DX than a random one
you have to discover with `make url` every session.

**Why 4799?**

- Far enough from 4000 to be immediately distinctive
- Below the ephemeral range (32768–60999 on Linux) so it can never collide with Docker's
  ephemeral host-port assignment
- Short enough that `http://localhost:4799/scoria` fits on one line in the terminal
- Not used by any common local service (4800 is used by some SaaS trial servers; 4799 is clear)

**Integration notes:**

- The `shots-native` Makefile target already hard-codes `localhost:4000/scoria`. Update it to
  use the same `PORT` variable: `mix scoria.ui.shots --url http://localhost:$(PORT)/scoria`
- `dev/dev_endpoint.ex` module doc references `localhost:4000/scoria` — update that comment too
- The `config/dev.exs` fallback (`System.get_env("PORT", "4000")`) can stay as-is; the Makefile
  injects the right value. No config change needed.

**Do NOT add:**

- Auto-port discovery shell scripting in the Makefile
- Changes to `config/dev.exs` fallback value (that would break the Docker path)
- A separate `config/dev.local.exs` override just for port (unnecessary indirection)

---

## (A2) Dockerfile Layer-Caching Guarantee

### Current State

`Dockerfile.dev` already has the correct three-layer ordering:

```
Layer 1: COPY mix.exs mix.lock ./   +  mix deps.get     (invalidated by lock changes)
Layer 2: COPY config config         +  mix deps.compile  (invalidated by config changes)
Layer 3: COPY lib dev priv          +  mix compile       (invalidated by source changes)
```

Named volumes in `compose.yml` shadow the bind mount for `deps`, `_build`, `hex`, `mix`.
BuildKit cache mounts accelerate apt + Hex package downloads.

### Is the Guarantee Real?

**Yes, with one important nuance.** For day-to-day dev work (the fully-dockerized `make up`
path), a CSS or HEEx file edit:

1. Lands in the bind-mounted `/app` inside the container
2. Is picked up by the polling watcher (`FILE_SYSTEM_BACKEND=fs_poll`, 500ms interval)
3. Triggers `ScoriaWeb.DevAssetWatcher` or Phoenix code reloader
4. Does NOT trigger `docker compose up --build` unless the maintainer explicitly requests a
   rebuild

The Dockerfile layer ordering only matters for cold image rebuilds (`docker compose up --build`).
During live dev, the image is not rebuilt — the bind mount sees changes directly.

For `docker compose up --build` after a CSS/HEEx-only edit, the named volumes already hold
`deps` and `_build`. The build re-runs:

- Layer 1: cache HIT (mix.exs + mix.lock unchanged)
- Layer 2: cache HIT (config unchanged)
- Layer 3: cache MISS (lib/priv changed) → runs `mix compile`
- Named volume `build` is NOT wiped by a rebuild (volumes persist across `docker compose up --build`)

The net result: **no dep refetch, no full dep recompile — just incremental app recompile**.
This is already correct. No changes needed.

**One real footgun to document:** `mix compile` inside the container compiles into the named
`build` volume, but if a maintainer also has a macOS `_build` dir from `mix phx.server`, those
are separate (different BEAM artefacts). The `.dockerignore` correctly excludes host `_build`
and `deps` from the build context, preventing NIF crashes. This is already handled.

### What the Audit Should Verify (no code change, empirical proof)

To prove the guarantee empirically, add a one-time verification note to `docs/docker_dev_dx.md`:

```
Caching verification (run once to convince yourself):
  time docker compose up --build          # first build: ~90s
  # edit one line in lib/scoria_web/components/ui.ex
  time docker compose up --build          # rebuild: Layer 1+2 cache hit, ~15s
```

The cache HIT messages in BuildKit output (`CACHED`) confirm layers 1 and 2 are skipped.

**Do NOT add:**

- A `--no-cache` flag anywhere in the Makefile (defeats caching entirely)
- Separate build stages for CSS vs Elixir (the CSS pipeline runs via DevAssetWatcher at
  runtime, not at image build time — adding a build stage adds complexity with no benefit)
- A `mix phx.digest` step in Dockerfile.dev (that is production only)

---

## (A3) Fleet Secrets Pattern

### The Problem

`.env.example` (gitignored companion `.env`) holds:
```
ANTHROPIC_API_KEY=sk-ant-...
```

This is plaintext on disk. The `critique` Docker service receives it via `ANTHROPIC_API_KEY:
${ANTHROPIC_API_KEY:-}`. The `make dev` path reads it via shell or manual export. The actual
`.env` is gitignored but the key has been in a real-looking value and should be rotated.

### Recommendation: direnv + `op run` via `.envrc` (1Password CLI)

**Mechanism:**

1. Install `direnv` (`brew install direnv`) and hook it into the shell (`eval "$(direnv hook
   zsh)"` in `~/.zshrc`).
2. Keep `.env.example` in the repo — but change its format to hold `op://` references instead
   of literal secrets, and rename the example to `.env.op.example` (safe to commit, documents
   required secrets structure without values).
3. The maintainer creates `.envrc` (gitignored) in the project root:
   ```bash
   # .envrc — loaded by direnv on `cd` into the project; never committed
   # Requires: brew install direnv; eval "$(direnv hook zsh)" in ~/.zshrc
   # Requires: 1Password CLI (brew install 1password-cli); `op signin` once
   use_env() {
     local key="$1" ref="$2"
     export "$key"="$(op read "$ref" 2>/dev/null || echo "")"
   }
   use_env ANTHROPIC_API_KEY "op://Personal/Scoria Dev/anthropic_api_key"
   ```
   Or, using the single `op run` batch pattern (faster — one CLI invocation):
   ```bash
   # .envrc
   # op:// references in .env.op are resolved in batch; vars land in the shell.
   direnv_load op run --env-file .env.op --no-masking -- direnv dump
   ```
4. `.env.op` (gitignored, contains references only — safe to optionally commit once references
   are confirmed non-sensitive):
   ```
   ANTHROPIC_API_KEY=op://Personal/Scoria Dev/anthropic_api_key
   ```
5. `.envrc.example` (committed — onboarding template):
   ```bash
   # Copy to .envrc, fill in your 1Password vault paths, then `direnv allow`.
   # Requires: brew install direnv && eval "$(direnv hook zsh)"
   # Requires: brew install 1password-cli && op signin
   direnv_load op run --env-file .env.op --no-masking -- direnv dump
   ```
6. `.env.op.example` (committed — documents required secret names, safe because values are op://
   references):
   ```
   # Copy to .env.op and update the op:// paths to match your 1Password vault.
   ANTHROPIC_API_KEY=op://Personal/Scoria Dev/anthropic_api_key
   ```

**For the Docker `critique` service:** The Docker path reads from `ANTHROPIC_API_KEY`
(already in compose.yml as `${ANTHROPIC_API_KEY:-}`). With direnv active, the shell that runs
`docker compose` inherits the exported var. No Docker change needed.

**For CI:** The GitHub Actions secret `ANTHROPIC_API_KEY` is already the right pattern — secrets
are injected by the runner, never in `.env`. The CI path is unaffected.

**Why direnv + op over the alternatives:**

| Option | Verdict | Why |
|--------|---------|-----|
| **direnv + `op run`** | Recommended | Auto-loads on `cd`; zero plaintext; well-known pattern; no daemon; works with any shell command including `make dev` and `docker compose` |
| 1Password Environments (named pipe .env) | Good alternative | Tighter integration; works even without direnv; but newer/less-documented than `op run` |
| sops | Overkill | Designed for team key-management at scale; single-maintainer overhead is high; no auto-inject on `cd` |
| git-crypt | Wrong tool | Encrypts committed files; `.env` is gitignored so git-crypt adds nothing; adds key-exchange complexity |
| doppler | Overkill | Another SaaS with an account; unnecessary for a solo maintainer who already owns 1Password |
| Plain `.env` | Current state; stop | Plaintext on disk; key leaked to any process that can read it; git-ignorable but still risky on shared machines |

**Session management:** `op run` requires the 1Password desktop app to be unlocked (or `op
signin` in CLI-only mode). The 10-minute session auto-refreshes on use. For a solo maintainer
who has 1Password open all day, there is no friction.

**Performance note:** The `op run` + `direnv` integration fires only on the first `cd` into
the directory (and on `.envrc` changes). Subsequent shell commands in the same session inherit
the vars from the process environment — no re-invocation.

**Onboarding microcopy for `docs/docker_dev_dx.md`:**

```
## Secrets (ANTHROPIC_API_KEY)

The critique harness needs ANTHROPIC_API_KEY. Get it from 1Password and keep it off disk:

  brew install direnv 1password-cli
  echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc  # or bash/fish equivalent
  source ~/.zshrc

  cp .env.op.example .env.op         # fill in your op:// vault path
  cp .envrc.example .envrc           # ready to use as-is
  direnv allow .                     # approve; loads on every `cd` hereafter

  make critique   # ANTHROPIC_API_KEY is in the environment automatically
```

**Do NOT add:**

- sops, git-crypt, or Doppler — too heavy for one maintainer and one API key
- A committed `.env` with literal secrets (even "fake" ones invite accidents)
- A requirement for a running 1Password Connect server (overkill; `op run` uses the desktop app)
- direnv `.env` auto-loading (direnv's `dotenv` standard lib loads `.env` as plaintext — that
  defeats the purpose; use `op run` instead)

---

## (A4) `make nuke` / Clean + Stale-Instance Hygiene

### The Problem

The `docker-dx-fleet-hardening` todo identifies a stale `scoria_demo` compose project that
answered `scoria.localhost` before branch-scoping was introduced. There is no `nuke` target.
The fleet can accumulate stale stopped containers, old named volumes, and orphan networks.

### Recommendation: Two-tier cleanup — `make clean` (safe) and `make nuke` (destructive)

**Mechanism:**

```make
## clean: stop this instance and remove its containers + orphans (keeps named volumes)
clean:
	docker compose down --remove-orphans
	@echo "Containers removed. Named volumes (pgdata, deps, build, hex, mix) kept."
	@echo "To also wipe the DB and build cache: make nuke"

## nuke: full teardown — containers + volumes for THIS instance (data will be lost)
nuke:
	@echo "This will delete all data for instance: $(COMPOSE_PROJECT_NAME)"
	@echo "Press Ctrl-C to cancel, Enter to continue..."
	@read _confirm
	docker compose down --volumes --remove-orphans
	@echo "Instance $(COMPOSE_PROJECT_NAME) wiped."
	@echo "If you have stale instances from old branch names, list them with:"
	@echo "  docker compose ls"
	@echo "Then clean each with:  COMPOSE_PROJECT_NAME=<name> docker compose down --volumes"
```

**Why two tiers?**

- `clean` is the everyday target: stop and remove containers without touching the named volumes
  (`deps`, `build`, `hex`, `mix`). This is safe to run before switching branches — the next
  `make up` reuses cached build artifacts.
- `nuke` is the blast-radius target: wipe everything including named volumes. Used when
  dependencies change and the build cache is suspect, or to free disk space. Requires a
  confirmation prompt to prevent accidental data loss.

**Stale `scoria_demo` instance cleanup instruction:**

Document in `docs/docker_dev_dx.md` (no code change needed):

```
## Cleaning up stale instances

Before branch-scoping (commit cf9494d), Scoria used a fixed project name `scoria`.
If you still have that stale project running:

  docker compose ls                   # lists all projects; look for `scoria` or `scoria_demo`
  COMPOSE_PROJECT_NAME=scoria docker compose down --volumes
  COMPOSE_PROJECT_NAME=scoria_demo docker compose down --volumes

After that, only branch-scoped projects remain:  scoria-main, scoria-feat-xyz, etc.
```

**Fleet-level prune (periodic hygiene, not a Makefile target):**

Document the one-liner but don't automate it — `docker system prune` can surprise people:

```
# Remove ALL stopped containers, unused networks, and dangling images (not volumes):
docker system prune -f

# Also wipe unused named volumes (careful — this affects ALL projects, not just Scoria):
docker volume prune -f
```

**Why NOT a single `make nuke` with `docker system prune`?**

`docker system prune` operates on the entire Docker daemon — it would wipe volumes and images
from sibling repos (rulestead, parapet, etc.) running on the same machine. The per-project
`docker compose down --volumes` is the correct scope.

**Do NOT add:**

- `docker system prune` in any Makefile target (wrong scope for a per-project nuke)
- Auto-confirmation (`--force` / `-f`) on the destructive `nuke` target (a pause protects real data)
- A `make prune` fleet-wide target (fleet hygiene is a manual one-liner, not a Makefile concern)

---

## (B) Maintenance Release — PR #3, version 0.1.2

### Current State

- Release-please PR #3 (`chore(main): release 0.1.2`) is open and labeled `autorelease: pending`
- `.release-please-manifest.json` has `"." : "0.1.1"` (post-v3.1 commits accumulated a large
  feature diff; release-please computed the next tag as `0.1.2`, not `0.1.1`)
- PR body shows the full CHANGELOG for `0.1.2` — it is the correct PR to merge
- The `release-please.yml` workflow gates Hex publish behind `ci-gate` (the required check
  from `ci.yml`), then runs the `post-publish-attest` smoke via `post-publish-smoke.yml`

### The Release Flow (no code change required for the happy path)

```
1.  Verify CI is green on the release-please--branches--main branch
2.  Merge PR #3 via the GitHub UI (or `gh pr merge 3 --squash`)
3.  release-please.yml fires on the push to main:
      → detects the merged release PR
      → creates GitHub release + tag v0.1.2
      → triggers the `verify` job (ci-verify.yml) against the tagged SHA
      → waits for `ci-gate` to be green on that SHA
      → runs `publish-hex` job: mix hex.publish --yes
      → waits for Hex.pm to index the package (polls /api/packages/scoria/releases/0.1.2)
      → runs `post-publish-attest` via post-publish-smoke.yml
4.  Post-publish smoke: fresh Phoenix host fetches scoria 0.1.2 from registry,
    runs install/migrate/overlay subset, proves live install.
```

### One Existing Footgun to Fix Before Merging

`post-publish-smoke.yml` still binds Postgres on port `55432:5432` (lines 52/62). The v3.1
FLAKE-01 fix (`27-01`) corrected `ci.yml` and `ci-verify.yml` to use `5432:5432` to avoid the
ephemeral-range collision on GitHub-hosted runners, but `post-publish-smoke.yml` was not
updated. The CI policy contract guard does not cover `post-publish-smoke.yml` (it is not in
`ci.yml` or `ci-verify.yml`).

Fix before or alongside the release merge:

```yaml
# post-publish-smoke.yml, services.postgres.ports
ports:
  - 5432:5432        # was 55432:5432 — ephemeral-range collision risk
```
And:
```yaml
# post-publish-smoke.yml, env block
SCORIA_DB_PORT: 5432  # was 55432
```

This is a pre-merge hygiene fix. The port guard in `ci_policy_contract_test.exs` should be
extended to also cover `post-publish-smoke.yml` as a follow-on hardening step.

### Post-Publish Registry Smoke — What It Proves

`mix scoria.post_publish_smoke` (already wired in `post-publish-smoke.yml`) runs:
- Fresh `phx.new` host generation
- `mix deps.get` fetching scoria 0.1.2 from Hex registry
- `mix scoria.install`
- `mix ecto.create` + `mix ecto.migrate`
- Route overlay smoke (proves `/scoria` is mounted)
- Runtime lane smoke (proves `Scoria.start_run/2`)
- If `version > "0.1.0"`: upgrade smoke (`--dry-run` / `--check` / apply / migrate from
  previous fixture to current)

This is a HIGH-confidence signal: if the post-publish smoke passes, the package is genuinely
installable from the public registry.

### Tools / Versions Involved

| Tool | Version | Purpose | Confidence |
|------|---------|---------|------------|
| `googleapis/release-please-action` | v5 (wired in `.github/workflows/release-please.yml`) | PR management + GitHub Release creation | HIGH — already shipping |
| `erlef/setup-beam` | v1 with `.tool-versions` strict | Elixir 1.19.5-otp-27 in CI | HIGH — locked in `.tool-versions` |
| `mix hex.publish --yes` | Hex 2.2.x (the hex tool version shipped with Elixir 1.19.5) | Publishes to registry | HIGH |
| `release-type: elixir` | release-please understands `mix.exs @version` | Bumps version in mix.exs + CHANGELOG | HIGH |

**Do NOT add:**

- A separate `expublish` or `hex_release` Mix task — the existing `release-please.yml` +
  `hex-publish.yml` + `post-publish-smoke.yml` is the complete, working, already-proven stack
- A manual `mix hex.publish` step outside of CI — the dry-run → publish → index-wait →
  attest sequence in CI is the idempotent, recovery-safe path
- A Dialyzer gate in the publish flow — Dialyzer is not in the current CI topology (deferred
  per project decisions); do not add it as a blocker here

---

## Recommended Versions / Tools Summary

| Technology | Version | Status | Role in v3.2 |
|------------|---------|--------|--------------|
| Elixir | 1.19.5-otp-27 | Already pinned in `.tool-versions` | No change |
| `hexpm/elixir` base image | `1.19.5-erlang-27.3.2-debian-bookworm-20260518-slim` | Already pinned in Dockerfile.dev | No change |
| Traefik | v3.7.1 (already pinned in `docker/traefik/compose.yml`) | Already running | No change |
| `pgvector/pgvector:pg16` | pg16 | Already pinned in compose.yml + dev/pgvector-compose.yml | No change |
| `googleapis/release-please-action` | v5 | Already wired | No change |
| `direnv` | latest stable via `brew install direnv` (2.35.x as of mid-2026) | New addition (secrets pattern) | Install once per machine |
| `1password-cli` | latest stable via `brew install 1password-cli` (op 2.x) | New addition (secrets pattern) | Install once per machine |
| `PORT` static default | 4799 | New addition (Makefile) | Single-line change |

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| PORT selection | Static 4799 default in Makefile | Free-port auto-picker (lsof/python socket) | Unstable URL per session; breaks shots-native; shell scripting fragility |
| PORT selection | Static 4799 default in Makefile | Change `config/dev.exs` fallback to 4799 | Breaks the Docker path (which needs 4000 internally; PORT=4000 is set inside the container by the compose environment) |
| Secrets | direnv + `op run --env-file` | 1Password Environments (named pipe) | Great alternative; slightly more complex initial setup; `op run` pattern is more portable and better-documented for CLI workflows |
| Secrets | direnv + `op run --env-file` | sops | Multi-person key management overhead; single maintainer doesn't need it |
| Secrets | direnv + `op run --env-file` | doppler | Another SaaS account; cost; `op run` reuses existing 1Password subscription |
| Stale cleanup | Per-project `compose down --volumes` | `docker system prune` | Wrong scope; nukes other projects on the same machine |
| Release | Merge PR #3 → automated publish | Manual `mix hex.publish` | Bypasses CI gate and post-publish smoke; manual path exists in `hex-publish.yml` as recovery only |

---

## What NOT to Add

| Avoid | Why |
|-------|-----|
| Auto-port discovery in Makefile | Unstable URLs; shell scripting that breaks on non-Mac platforms |
| sops, git-crypt, Doppler | All overkill for a single maintainer with one API key; adds key-management overhead without benefit |
| `docker system prune` as a Makefile target | Wrong blast radius; would nuke other projects |
| A new `--no-cache` make target | Would defeat all BuildKit caching; defeats the purpose of the caching audit |
| Separate Dockerfile build stages for CSS vs Elixir | CSS is a runtime concern (DevAssetWatcher); build stages add complexity without benefit in a dev image |
| Adding Dialyzer to the Hex publish gate | Not in the current CI topology; out of scope for v3.2 |
| direnv `dotenv` stdlib (auto-loading `.env`) | Loads plaintext files — defeats the point of the secrets pattern |
| Committed `.env` with `op://` references | Tempting shortcut but muddies `.gitignore` hygiene; `.env.op` with the references is the clean pattern |

---

## Integration Points with Existing Impl

| Gap | Touch Point | What Changes |
|-----|------------|--------------|
| PORT default | `Makefile` line 61 (`dev` target) | Add `PORT ?= 4799`; pass `PORT=$(PORT)` |
| PORT default | `Makefile` line 74 (`shots-native`) | Update URL to `localhost:$(PORT)/scoria` |
| PORT default | `dev/dev_endpoint.ex` line 8 | Update comment from `localhost:4000` to `localhost:4799 (default)` |
| Dockerfile caching | `Dockerfile.dev` | Already correct; add empirical verification comment only |
| Secrets pattern | `.gitignore` | Add `.envrc` and `.env.op` (new files, gitignored) |
| Secrets pattern | New: `.envrc.example` | Committed onboarding template |
| Secrets pattern | New: `.env.op.example` | Committed op:// reference template |
| Secrets pattern | `docs/docker_dev_dx.md` | Add "Secrets" section with setup microcopy |
| Stale hygiene | `Makefile` | Add `clean` and `nuke` targets |
| Stale hygiene | `docs/docker_dev_dx.md` | Add stale-instance cleanup section |
| Release | `.github/workflows/post-publish-smoke.yml` | Fix `55432:5432` → `5432:5432` before or with merge |
| Release | PR #3 on GitHub | Merge when CI green |

---

## Sources

- Live source files read: `Makefile`, `compose.yml`, `Dockerfile.dev`, `config/dev.exs`,
  `dev/dev_endpoint.ex`, `dev/pgvector-compose.yml`, `docker/dev-entrypoint.sh`,
  `.env.example`, `release-please-config.json`, `.release-please-manifest.json`,
  `.github/workflows/release-please.yml`, `.github/workflows/hex-publish.yml`,
  `.github/workflows/post-publish-smoke.yml`, `.planning/todos/pending/docker-dx-fleet-hardening.md`
- 1Password CLI `op run` docs: https://www.1password.dev/cli/reference/commands/run/
- direnv official site: https://direnv.net/
- direnv + 1Password integration patterns: https://perrotta.dev/2025/03/1password-cli--direnv-integration/
- Docker Compose pruning: https://docs.docker.com/engine/manage-resources/pruning/
- Hex publish docs: https://hex.pm/docs/publish
- Release Please Elixir guide: https://elixirschool.com/blog/managing-releases-with-release-please
- Elixir Forum: secrets management discussion confirming direnv + 1Password as community consensus:
  https://elixirforum.com/t/how-you-manage-configuration-of-secrets-in-elixir-projects/67815
- GitHub: PR #3 inspected directly (`gh pr view 3`)
- Dockerfile caching strategy verified against community practice:
  https://fnlog.dev/wanderer/elixir-bit-caching-docker-dependencies/

---

*Stack research for: v3.2 Drydock — Docker dev-DX fleet hardening + maintenance release*
*Researched: 2026-06-17*
