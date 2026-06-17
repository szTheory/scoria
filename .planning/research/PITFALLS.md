# Pitfalls Research — v3.2 Drydock

**Domain:** Multi-lib Docker dev-DX hardening + automated Hex maintenance release
**Milestone:** v3.2 Drydock
**Researched:** 2026-06-17
**Confidence:** HIGH (based on direct code inspection of live footguns + cross-ecosystem verification)

---

## Critical Pitfalls

### Pitfall 1: Fleet-Wide Nuke Destroys Other Libraries' Volumes

**What goes wrong:**

A `make nuke` or `make clean` target that runs `docker compose down -v`, `docker volume prune`, or `docker system prune --volumes` without proper scoping silently destroys pgdata, deps, and build volumes belonging to other running or stopped Compose projects (rulestead, parapet, sigra, etc.) on the same machine. The blast radius is invisible: Compose volumes are named `<project>_pgdata` but a global `docker volume prune` removes ALL unnamed/unused named volumes across every project, not just the current one.

Concrete example: you're in the `scoria/` directory and run `make nuke`. If the implementation is `docker volume prune -f`, it removes `parapet_pgdata` and `rulestead_build` even though they are in a different repo — because they happen to be stopped (not attached to running containers). The user comes back to `rulestead`, does `make up`, and finds an empty database.

**Why it happens:**

Developers write `make nuke`/`clean` as a "scorched earth" reset. The `docker volume prune` command has no `--project` flag — it is global. The `docker compose down -v` IS safely scoped (it only removes volumes declared in the current project's `volumes:` block, prefixed with `COMPOSE_PROJECT_NAME`), but developers conflate the two. The presence of `COMPOSE_PROJECT_NAME` gives a false sense of project isolation that does not extend to global prune commands.

**How to avoid:**

Use ONLY `docker compose down -v` for cleanup, never `docker volume prune` or `docker system prune --volumes` in Makefile targets. The scoped form is safe:

```makefile
## nuke: DANGER — remove THIS instance's containers, networks, and volumes (not other projects')
nuke:
	@echo "WARNING: this removes the $(COMPOSE_PROJECT_NAME) stack and its volumes. Other projects are unaffected."
	docker compose down -v --remove-orphans
```

For the `make clean` target (lighter weight — remove containers but keep data volumes):

```makefile
clean:
	docker compose down --remove-orphans
```

Add a warning banner that names `$(COMPOSE_PROJECT_NAME)` explicitly so the maintainer at 2am can confirm scope before proceeding. Never add `--force` silently — require confirmation or print what will be deleted.

**Warning signs:**

- A nuke target that calls `docker volume prune` or `docker system prune`
- A nuke target that does not export or reference `COMPOSE_PROJECT_NAME`
- CI teardown steps that use prune commands (they should use `down -v`)

**Phase to address:**

The phase adding `make nuke`/`clean`. Gate: run `grep -n "volume prune\|system prune" Makefile` — must return zero hits.

---

### Pitfall 2: Stale Instance Answers the Right Hostname with Wrong Code

**What goes wrong:**

The old `scoria_demo` compose project is alive and answering `http://scoria.localhost` with the pre-branch-scoping code. A maintainer boots the new `scoria-main` instance, goes to `http://scoria.localhost`, and gets a stale response. Nothing looks broken — the page loads. They spend time confused about why their changes have no effect.

This is the exact observed footgun: the `scoria_demo` project predates branch-derived `COMPOSE_PROJECT_NAME`. Its Traefik label hardcodes `Host(scoria.localhost)` and it is still running. The new instance routes to `scoria-main.localhost` but the old one squats the bare `scoria.localhost` URL.

**Why it happens:**

When the project naming strategy changed (from a static `scoria` to branch-derived `scoria-<branch>`), the old container was never torn down. Traefik routes by Host header, so whichever container registered `scoria.localhost` first wins. Two instances can coexist silently if their router ids don't collide (and they may not — if the old instance uses a hardcoded router id and the new one interpolates `${COMPOSE_PROJECT_NAME}`).

**How to avoid:**

1. **Document the one-time teardown command** for the stale instance in the hygiene doc and the `make nuke` target comments: `docker compose -p scoria_demo down -v`.
2. **Add a `make ps` or `make status` target** that runs `docker ps --filter label=traefik.enable=true --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"` to surface ALL Traefik-labeled containers, not just this instance's. A maintainer who sees `scoria_demo_web_1` alongside `scoria-main_web_1` in the output knows there is a conflict.
3. **Proactively audit** in `docs/docker_dev_dx.md`: "If you see stale content at `scoria.localhost`, list all active Traefik-labeled containers with `docker ps -a --filter label=traefik.enable=true` and tear down any projects whose `COMPOSE_PROJECT_NAME` you don't recognize."

**Warning signs:**

- Browser shows old UI at `scoria.localhost` even after `make up` completes
- Traefik dashboard (`:8080`) shows two routers with overlapping or near-identical `Host()` rules
- `docker ps` shows containers with a different project prefix than `COMPOSE_PROJECT_NAME`

**Phase to address:**

The phase adding stale-instance hygiene doc. Gate: verify `docker ps -a --filter label=traefik.enable=true` shows only the expected instance after a fresh `make up`.

---

### Pitfall 3: `make dev` Collides on Port 4000 — Native Server Fights the Fleet

**What goes wrong:**

`make dev` currently runs `SCORIA_DEV_LIVE_RELOAD=1 mix phx.server` with no PORT override. Phoenix defaults to 4000. Any other library in the fleet running natively (or in Docker with a published 4000 port) causes EADDRINUSE. The maintainer gets a cryptic Erlang crash on boot, not a helpful "port 4000 is taken" message, and has to remember to add `PORT=XXXX` manually every time.

**Why it happens:**

Phoenix bakes `:4000` deep into the default dev config. The Docker path correctly avoids fixed port publication (the compose service uses ephemeral loopback `127.0.0.1::4000`), but the native `make dev` path does not inherit that discipline. The port is forgotten because `make dev` is used infrequently (CSS iteration only) and the conflict only surfaces when another app is also running natively.

**How to avoid:**

Bake a non-conflicting default directly into the `dev` Make target:

```makefile
## dev: native host server with live browser reload (CSS/JS iteration)
##      PORT defaults to 4799 to avoid fleet collisions on :4000
dev:
	PORT=$${PORT:-4799} SCORIA_DEV_LIVE_RELOAD=1 mix phx.server
```

Pick a port in the range 4100–4999 that is unlikely to be used by any sibling library. Document the chosen port in the launch banner (or at least in `docs/docker_dev_dx.md`) so the maintainer knows where to point the browser when using `make dev`. Do NOT rely on `System.get_env("PORT") || 4000` in `config/dev.exs` without also setting it in the Makefile — the two must agree.

**Warning signs:**

- `make dev` emits `[error] Failed to start Ranch listener` with `eaddrinuse`
- The Makefile `dev` target has no `PORT=` prefix
- The `shots-native` target hardcodes `--url http://localhost:4000/scoria` (it does today) — this breaks silently if PORT is changed; must be kept in sync

**Phase to address:**

The phase baking PORT default into `make dev`. Gate: `grep "PORT" Makefile` shows the default; `shots-native` target URL agrees with the chosen port.

---

### Pitfall 4: Competing Proxy Networks — Traefik Can Only See One

**What goes wrong:**

Two external networks named `proxy` and `local-dev-proxy` exist. Traefik is attached to one (say `proxy`). A sibling library's compose.yml declares `networks: { local-dev-proxy: { external: true } }`. That library's services are invisible to Traefik — they get 502s even though their labels look correct and the Traefik dashboard may show them (Traefik can discover containers but cannot route to them if the container's advertised network is not one Traefik is on).

The label `traefik.docker.network=local-dev-proxy` points to the wrong network. The label `traefik.docker.network=proxy` points to a network the container is NOT on. Either way: 502.

**Why it happens:**

Different repos adopted "shared reverse proxy" patterns at different times and chose different network names. The naming convention was never locked fleet-wide. Docker Compose project prefixing doesn't apply to external networks — a network named `proxy` is always unprefixed, but a network defined inside the compose file gets `<project>_proxy` unless it has a `name:` override.

**How to avoid:**

Lock `proxy` as the canonical fleet-wide external network name. The current Scoria stack is already correct (`proxy: { external: true }`). The convergence work (out of v3.2 scope for other repos) must update every sibling repo. For the v3.2 Scoria-only scope: add a note in `docs/docker_dev_dx.md` that explicitly states "the canonical external network name is `proxy` — do not create `local-dev-proxy` or any variant; delete stale networks with `docker network rm local-dev-proxy`".

Verify with: `docker network ls | grep -E "proxy|local-dev"` — only one `proxy` network should exist.

**Warning signs:**

- Traefik dashboard shows a router entry but requests return 502
- `docker inspect <container>` shows `Networks` listing `local-dev-proxy` but not `proxy`
- `docker network ls` shows both `proxy` and `local-dev-proxy`

**Phase to address:**

Fleet-standard doc hardening phase. Gate: `docker network ls | grep local-dev-proxy` returns empty on a clean dev machine.

---

### Pitfall 5: Top-Level `name:` in compose.yml Breaks Multi-Instance Interpolation

**What goes wrong:**

Adding a top-level `name:` to `compose.yml` (a tempting "improvement" because it looks explicit) silently overrides `COMPOSE_PROJECT_NAME`. Docker Compose has a documented and open bug ([issue #10171](https://github.com/docker/compose/issues/10171)) where `name:` does not properly interpolate environment variables — `name: ${COMPOSE_PROJECT_NAME}` evaluates to the literal string `COMPOSE_PROJECT_NAME` rather than the variable value in certain versions. This makes every checkout land on the same project name regardless of the branch-derived env var, destroying multi-instance isolation.

**Why it happens:**

The top-level `name:` key looks authoritative and explicit. Developers adding it intend to pin the project name, unaware that the env-var interpolation bug means it overrides without substituting. The current `compose.yml` correctly omits `name:` (with the rationale commented) — this pitfall applies if anyone adds it.

**How to avoid:**

Never add a top-level `name:` to `compose.yml`. The comment in the file already documents this:

```yaml
# NOTE: there is deliberately no top-level `name:` and no `container_name:` on
# any service — both would defeat per-instance prefixing...
```

Add a CI or Make-level assertion: `grep -n "^name:" compose.yml` must return nothing (or only a comment line). The Makefile exports `COMPOSE_PROJECT_NAME` from the git branch — that is the only project-naming mechanism in the fleet standard.

**Warning signs:**

- `docker compose ps` shows project name `COMPOSE_PROJECT_NAME` literally (the string, not the value)
- Two checkouts share containers (second `make up` says "already in use")
- `docker ps` shows containers prefixed with the yaml-literal string rather than `scoria-main`

**Phase to address:**

Layer-caching and compose-hygiene audit phase. Gate: `grep -c "^name:" compose.yml` returns 0.

---

### Pitfall 6: Dockerfile Layer Cache Busted by Config-Before-Source Ordering Violation

**What goes wrong:**

A Dockerfile that copies source before copying `mix.exs`/`mix.lock`/`config/` will invalidate the `deps.get` and `deps.compile` layers on every source change — including CSS edits and HEEx template changes. This means what should be a sub-second bind-mount edit triggers a full dep re-download inside the image build.

The current `Dockerfile.dev` already has this right (mix.exs + mix.lock → config → lib/dev/priv). The pitfall is regression: if someone adds a `COPY . .` convenience line above the COPY/RUN dep layers, every `docker compose up --build` becomes a full rebuild.

**Why it happens:**

`COPY . .` is the "obvious" Docker instruction for copying source, and developers add it when they want to be sure everything is included. They don't realize that it invalidates all subsequent layers — including the ones that cached deps — whenever any file in the build context changes. This is the single most common Docker build performance pitfall in Elixir projects.

**How to avoid:**

The current layer order is correct and must be preserved:

1. `COPY mix.exs mix.lock ./` + `RUN mix deps.get`
2. `COPY config config` + `RUN mix deps.compile`
3. `COPY lib lib` / `COPY dev dev` / `COPY priv priv`
4. `RUN mix compile`

Add a comment at the top of `Dockerfile.dev` (it already exists, but strengthen it): "Do not move source-copy steps above the config COPY. Layer order is deliberate to avoid dep refetch on every source edit."

Verify empirically: edit `assets/css/app.css`, run `docker compose up --build` (or `docker build`), and confirm no `deps.get` step appears in the output. Only `mix compile` (step 4) should execute.

**Warning signs:**

- `docker compose up --build` output shows `mix deps.get` after a CSS-only change
- Build times are >30 seconds on every code edit cycle
- `COPY . .` appears before any `RUN mix deps.get` or `RUN mix deps.compile` in the Dockerfile

**Phase to address:**

Dockerfile caching audit phase. Gate: empirical test — CSS edit + `--build` must NOT show `mix deps.get` in output.

---

### Pitfall 7: `hexpm/elixir` Image Tag Without Date Suffix Causes Silent Pull Failure

**What goes wrong:**

The Debian-based `hexpm/elixir` images require a date suffix in the tag (e.g., `1.19.5-erlang-27.3.2-debian-bookworm-20260518-slim`). A tag without the date suffix (e.g., `hexpm/elixir:1.19.5-erlang-27.3.2-debian-bookworm-slim`) does not exist and `docker pull` fails. Unlike Alpine images (which don't require a date suffix), Debian-based images are not published without it.

This only hurts when someone updates the Erlang/Elixir version in `.tool-versions` and forgets to also find and paste the corresponding dated Debian tag. The build fails with a non-obvious 404-style error.

**Why it happens:**

The `hexpm/bob` build system names Debian images with a date component because the Debian base image itself has a date in its tag. Developers copy the version numbers from `.tool-versions` and construct a tag manually, omitting the date because it looks like a build artifact rather than a required tag component.

**How to avoid:**

- Keep the current tag pinned (the Dockerfile already has the correct dated tag `hexpm/elixir:1.19.5-erlang-27.3.2-debian-bookworm-20260518-slim`).
- When bumping OTP/Elixir versions, always look up the exact full tag from [https://hub.docker.com/r/hexpm/elixir/tags](https://hub.docker.com/r/hexpm/elixir/tags) or `hexpm/bob` releases — do not construct the tag from version numbers alone.
- Add a `docs/docker_dev_dx.md` note: "When updating `.tool-versions`, update the `FROM` tag in `Dockerfile.dev` using the exact dated tag from hub.docker.com/r/hexpm/elixir/tags."

**Warning signs:**

- `docker compose build` fails with "manifest unknown" or "not found"
- The Dockerfile tag has the Elixir + OTP version but no date component
- `.tool-versions` was updated but `Dockerfile.dev` `FROM` line was not

**Phase to address:**

Dockerfile caching audit phase or version-update runbook in `docs/docker_dev_dx.md`.

---

### Pitfall 8: Plaintext `ANTHROPIC_API_KEY` in `.env` — Rotation and Onboarding Friction

**What goes wrong:**

The `.env` file (gitignored) holds a real `ANTHROPIC_API_KEY` in plaintext. Two failure modes:

1. **Security**: If `.env` is accidentally committed (`.gitignore` typo, `git add .` in a hurry, IDE auto-staging), the key is exposed in git history. Even if the commit is reverted, the key must be rotated — because git history is preserved and the key was visible between push and revocation.

2. **Onboarding friction**: A new developer clones the repo, copies `.env.example`, and puts in a throwaway or guessed key. The `make critique` command silently fails because the key format is wrong. There is no indication that a 1Password lookup or team vault entry is the intended source of truth. The `.env.example` currently shows `ANTHROPIC_API_KEY=sk-ant-...` — this is a placeholder that looks real enough to prompt someone to paste a real key directly.

**Why it happens:**

`.env` is the universal "put secrets here" convention for local dev. It works but it puts plaintext credentials on disk with only a `.gitignore` line standing between them and git history. The critiquing harness only needs the key in one context (the `critique` compose service), which reduces the blast radius — but the key is still on disk.

**How to avoid:**

Adopt the `op run` pattern from 1Password CLI as the canonical fleet-wide secrets pattern:

1. Store the key in 1Password as `ANTHROPIC_API_KEY` in a vault entry named `scoria-dev`.
2. Create `.env.op` (committed, no secrets):
   ```
   ANTHROPIC_API_KEY=op://Personal/scoria-dev/ANTHROPIC_API_KEY
   ```
3. Wrap the command: `op run --env-file=.env.op -- docker compose --profile shots run --rm critique`
4. Add a `make critique-op` target that wraps this. Keep `make critique` working with `.env` for maintainers who don't have 1Password.
5. In `.env.example`, replace the `sk-ant-...` placeholder with a comment: `# Get from 1Password: op://Personal/scoria-dev/ANTHROPIC_API_KEY`

Rotate the current key immediately (before v3.2 ships) regardless of whether the new secrets pattern is adopted. The memory note already flags this.

As a lightweight alternative to 1Password, `direnv` with a `.envrc` that sources `.env` and is gitignored also works — but it still puts the key on disk.

**Warning signs:**

- `.env` contains `sk-ant-api03-` or similar real-looking key prefix
- `git log --all --full-diff -p -- .env` shows any history (confirms if key was ever committed)
- `git status` shows `.env` as "untracked" rather than "ignored" (check `.gitignore` entry)
- New developers ask "where do I get the API key" — onboarding doc does not answer this

**Phase to address:**

Secrets-pattern phase. Gate: `.env` is in `.gitignore`; a verification step rotates the current key; `.env.example` shows op:// reference, not a placeholder that looks like a real key.

---

### Pitfall 9: Verification Copy Drift — Docs Tell Verifiers to Hit the Wrong URL

**What goes wrong:**

GSD plan/agent verification copy currently instructs verifiers to run `mix phx.server` and check `http://localhost:4000/scoria`. Both are wrong for this project:

1. `:4000` is fleet-owned — other libraries run there; it may not even be Scoria answering.
2. `mix phx.server` starts the wrong server (it tries to use the standard `MyApp.Endpoint`, not the dev harness `ScoriaWeb.DevEndpoint` that `make dev` boots).
3. The real URL after `make up` is `http://scoria-<branch>.localhost/scoria` — branch-derived.

A verifier following the stale docs concludes "works" against the wrong instance, or concludes "broken" because nothing answers at `:4000`. Either outcome is wrong.

**Why it happens:**

Verification copy was written early in the project when the native `mix phx.server` path was the only option. The Docker DX overhaul changed the canonical verification path but the agent prompts and GSD plans were not updated. Documentation drift is structurally likely in a fast-moving project — the "correct" URL is dynamic (branch-name-derived), making it hard to pin in static docs.

**How to avoid:**

1. Update ALL verification copy that references `mix phx.server`/`localhost:4000/scoria` to: "`make up` → `make url` prints the instance URL → open `http://$(make url output)/scoria`".
2. For human-readable docs, use the template form: "`http://scoria-<branch>.localhost/scoria` (or run `make url` to get the exact URL for your branch)".
3. Print the route list in the launch banner — the entrypoint already does this (`docker/dev-entrypoint.sh`). Ensure the banner includes `make url` as the next step instead of requiring the maintainer to remember the URL format.
4. Add a requirement that any new phase requiring browser verification must state the full URL derivation, not just `:4000`.

**Warning signs:**

- GSD agent prompts contain `localhost:4000/scoria`
- REQUIREMENTS.md verification steps reference `mix phx.server` as the start command
- The launch banner does not print the Traefik URL prominently

**Phase to address:**

Verification copy correction phase. Gate: `grep -rn "localhost:4000" .planning/` returns zero hits in verification sections.

---

### Pitfall 10: `post-publish-smoke.yml` Uses Port 55432 — Exempt from the FLAKE-01 Guard

**What goes wrong:**

The ephemeral port flake fixed in v3.1 (FLAKE-01) pinned CI Postgres hosts to port `5432:5432` to avoid the Linux kernel ephemeral range (32768–60999). The `ci_policy_contract_test.exs` guards this for `ci.yml` and `ci-verify.yml`. However, `post-publish-smoke.yml` still uses `55432:5432` — which is IN the ephemeral range — and the contract test explicitly does NOT check `post-publish-smoke.yml` (it only iterates over the two main workflow files).

The smoke workflow is called from release-please.yml's `post-publish-attest` job. It runs on GitHub Actions runners where the same ephemeral-range collision risk exists. If a GitHub runner has 55432 allocated, the Postgres service container fails to start, the smoke fails, and the release pipeline breaks — at the worst possible time (immediately after publish).

**Why it happens:**

The FLAKE-01 fix was scoped to the merge-gate CI files. Post-publish-smoke was treated as a separate concern (it only runs on release) and was not revisited. The carve-out `D-08` comment in the test refers to retry-action exemptions for release workflows, not port carve-outs — the port guard carve-out is implicit (the file is simply not included in the scan).

**How to avoid:**

Change `post-publish-smoke.yml` Postgres port from `55432:5432` to `5432:5432` (matching CI standard), and update the `SCORIA_DB_PORT` env var to `5432`. Then expand the `ci_policy_contract_test.exs` ephemeral-port guard to also scan `post-publish-smoke.yml` (add it to the file list checked). This closes the blind spot permanently.

**Warning signs:**

- `post-publish-smoke.yml` `services.postgres.ports` contains `55432:5432`
- The contract test's postgres_blocks scan does not reference `post-publish-smoke.yml`
- Release pipeline fails intermittently at the `post-publish-attest` job with Postgres connection errors

**Phase to address:**

Maintenance release hardening phase. Gate: contract test scans post-publish-smoke.yml; port is `5432:5432`.

---

### Pitfall 11: Hex Version Already Published — 1-Hour Rollback Window Is the Only Recovery

**What goes wrong:**

Hex.pm allows a published version to be retracted or modified within 60 minutes of initial publication (or 24 hours for brand-new packages). After the window closes, the version is immutable — publishing the same version number again fails. Possible scenarios for v3.2:

1. `mix.exs` shows `@version "0.1.1"` but the manifest shows `"0.1.1"` — these agree. However if someone manually bumps `mix.exs` to `0.1.2` without a corresponding release-please manifest update, the `Verify release version in mix.exs` step in `release-please.yml` catches it (`grep "@version \"0.1.1\""` fails). But the error message is `grep` returning non-zero — not an obvious "version mismatch" message.

2. More dangerous: docs publish fails but package publish succeeds. The `mix hex.publish --yes` command publishes package + docs together. If docs compilation fails mid-publish (e.g., `@doc` coverage gap, broken ExDoc reference), the package tarball may land on Hex but HexDocs shows the previous version's docs. Users installing `0.1.1` get the right code but wrong/missing docs.

3. The 60-minute re-publish window exists but has reported friction even within the window — users have encountered validation errors when attempting to republish immediately after a failed publish ([Elixir Forum report](https://elixirforum.com/t/could-not-update-a-package-on-hex-pm/29584)).

**Why it happens:**

The automated pipeline (`mix hex.publish --yes`) suppresses the interactive confirmation. If anything goes wrong after that call completes but before the index poll confirms availability, the maintainer may not know whether the publish succeeded. The pipeline's idempotency guard (`mix hex.info scoria ${RELEASE_VERSION} | grep "Released:"`) prevents re-running publish, but it also silently skips recovery if the first publish partially succeeded.

**How to avoid:**

1. Always run `mix hex.publish --dry-run --yes` before the live publish (the pipeline already does this). Confirm dry-run output shows the correct file inventory and version.
2. Verify `mix docs` builds cleanly in the release pipeline BEFORE calling `mix hex.publish` — docs failures after a successful package publish put you in the worst state (correct package, wrong docs, within the narrow rollback window).
3. In `docs/operator_verification.md`, document the manual recovery flow: `mix hex.publish --revert 0.1.1` (within 60 min), then `mix hex.publish --yes` after fixing.
4. The `Verify release version in mix.exs` step currently uses `grep -n "@version \"${RELEASE_VERSION}\""` — this is correct and will hard-fail on mismatch. Keep it.

**Warning signs:**

- `mix docs` produces warnings or errors locally before the release
- `mix hex.publish --dry-run` shows unexpected files in the tarball (check `:files` in `mix.exs`)
- The release-please manifest `"."` key disagrees with `@version` in `mix.exs`

**Phase to address:**

Maintenance release phase (merge release-please PR). Gate: `mix docs` clean before publish; `mix hex.publish --dry-run` shows correct file list; `mix hex.info scoria 0.1.1` confirms listing after publish.

---

### Pitfall 12: release-please PR Already Tagged — Re-Running Creates a Duplicate Release

**What goes wrong:**

The `release-please.yml` has a `release-preflight` guard that checks if the expected tag already exists before running release-please. But the guard uses `jq -r '.["."]' .release-please-manifest.json` to derive the expected tag — which reads the CURRENT manifest, not the tag of the open PR. If the open PR bumps the manifest from `0.1.1` → `0.1.2`, and someone triggers `workflow_dispatch` on main after the PR is merged but BEFORE the tag is pushed, the preflight check reads `0.1.2` (because the manifest was already merged), finds no `v0.1.2` tag, and runs release-please again — potentially opening a new PR for `0.1.3`.

**Why it happens:**

The preflight guard was designed to prevent idempotency issues when release-please is triggered on the merge commit of a release PR (where re-running would be a no-op but could also double-tag). The race condition exists in the window between manifest merge and tag push.

**How to avoid:**

Do not trigger `workflow_dispatch` on the release-please workflow manually unless you are in explicit recovery mode. The normal path is: merge the release-please PR (green CI required) → release-please workflow fires automatically on the merge push → tag is created → hex-publish starts. Monitor the Actions tab after merging, not the PR status.

In the recovery path (if the automatic trigger misfired), use `hex-publish.yml`'s `workflow_dispatch` with an explicit tag and version — not re-triggering `release-please.yml`.

**Warning signs:**

- A second release-please PR opens immediately after merging the first
- The manifest version jumped two patch versions (0.1.1 → 0.1.3 instead of 0.1.2)
- `gh pr list --label "autorelease: pending"` shows more than one open PR

**Phase to address:**

Maintenance release phase. Gate: after merging release-please PR, confirm only one `autorelease: tagged` PR label appears; confirm tag matches manifest version.

---

### Pitfall 13: Post-Publish Smoke Fails Because Registry Index Hasn't Propagated Yet

**What goes wrong:**

The release pipeline waits for Hex.pm to index the new version before calling `post-publish-attest`. The wait logic polls `https://hex.pm/api/packages/scoria/releases/${RELEASE_VERSION}` up to 36 times at 10-second intervals (6 minutes). In practice, Hex.pm indexing is usually under 60 seconds, but edge cases exist — especially if the Hex.pm CDN is under load or the API response is cached by a middlebox.

If the `publish-hex` job sets `skip_index_wait: true` (it does, when chaining from within the same pipeline), the `post-publish-attest` job inherits that and skips the wait. This means the smoke runs immediately after publish confirmation — which may be BEFORE adopters' `mix deps.get` would succeed (CDN propagation is not the same as API indexing).

**Why it happens:**

The `skip_index_wait` optimization was introduced to avoid double-polling. It's correct in the happy path (API index is a proxy for CDN availability). But if the API endpoint returns 200 before all CDN nodes have the tarball, the post-publish smoke will pass while real adopters using a different CDN edge node would fail.

**How to avoid:**

- Keep the post-publish smoke's actual `mix deps.get` as the true signal (it is — the smoke calls `mix scoria.post_publish_smoke` which does a real dep install). If that passes, CDN propagation is confirmed from the GitHub Actions runner's region.
- Accept that the smoke is a single-region proof, not a global CDN guarantee.
- Document in `docs/operator_verification.md`: "Post-publish smoke proves Hex fetch from the Actions runner region. Allow 5 minutes after smoke passes before announcing the release, as CDN propagation is not instantaneous globally."

**Warning signs:**

- `mix deps.get` in the smoke fails with "no package with name scoria found" despite the API returning 200
- The `Wait for Hex.pm index` poll passes immediately (< 5 seconds) — suspiciously fast, may be cached

**Phase to address:**

Maintenance release phase. No code change needed; document the CDN propagation nuance in the operator verification guide.

---

### Pitfall 14: Verification-Copy/Doc Drift Accumulates Because No Automation Guards It

**What goes wrong:**

`docs/docker_dev_dx.md`, the launch banner in `docker/dev-entrypoint.sh`, and `docs/operator_verification.md` are maintained manually. As new Make targets are added (e.g., `make nuke`, `make ps`), as PORT defaults change, and as the verification flow evolves, these three files drift independently. The maintainer-at-2am following the wrong doc wastes 20 minutes before realizing the doc is stale.

The existing project has a strong pattern of contract tests and drift guards (DS-06 raw-color guard, `ci_policy_contract_test.exs`, `HexConsumerContract`). But there is currently no machine-readable guard between the Makefile target list and the docs that describe those targets.

**Why it happens:**

Documentation is easy to skip when shipping quickly. Unlike code, doc drift doesn't break CI. The launch banner is inside a shell script that is only seen at runtime, making it especially easy to forget during a Makefile change.

**How to avoid:**

1. For the launch banner (`docker/dev-entrypoint.sh`): treat it as a user-facing surface, not infra. When adding a target, add the corresponding line to the banner at the same time (co-locate the change).
2. For `docs/docker_dev_dx.md`: add a simple contract test or CI step that asserts the Makefile `## target: description` comments agree with the doc's command table. A basic approach: `grep "^## " Makefile` extracts documented targets; a test asserts all are mentioned in the doc.
3. For operator verification: the existing `ci_policy_contract_test.exs` already asserts doc cross-references; extend it with any new verification commands introduced in v3.2.

**Warning signs:**

- `docs/docker_dev_dx.md` mentions `make up/url/open` but not new targets added this milestone
- Launch banner shows routes that don't match current router
- REQUIREMENTS.md verification steps reference commands that don't exist in the Makefile

**Phase to address:**

Verification copy correction phase. Gate: launch banner and docs manually verified against Makefile at phase close; no `localhost:4000` in planning docs.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `docker volume prune` in nuke target | Simple one-liner | Destroys other projects' data silently | Never |
| Global `docker system prune` | Frees disk space quickly | Wipes all stopped containers + volumes across all projects | Never in a Makefile target |
| `COPY . .` in Dockerfile before dep layers | Simple build | Full dep refetch on every source edit | Never |
| Hardcoded `:4000` in `make dev` | Matches Phoenix default | Collides with fleet; requires manual port juggling | Never in multi-lib fleet |
| Plaintext `.env` for secrets | Zero setup friction | Key exposure risk on accidental commit | Acceptable short-term; rotate and document the 1Password path |
| Static verification URLs in docs | Easy to write | Drift as routing evolves | Acceptable if guarded by a drift test |
| Skipping `mix docs` before Hex publish | Faster publish loop | Docs can be wrong/missing on Hex even when code is correct | Never before a release |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Traefik routing | Setting `traefik.docker.network` to a network the container is NOT on | Label must name the network both Traefik AND the container share; for external `proxy` it is always `proxy` (unprefixed) |
| Compose multi-instance | Adding `container_name:` or top-level `name:` | Omit both; let `COMPOSE_PROJECT_NAME` prefix do the isolation |
| Hex publish pipeline | Running `mix hex.publish --yes` without a preceding dry-run | Always dry-run first to verify file inventory and version |
| release-please + Hex | Triggering `workflow_dispatch` on `release-please.yml` manually after PR merge | Use `hex-publish.yml`'s `workflow_dispatch` for recovery; never re-fire release-please after the tag exists |
| post-publish-smoke port | Port `55432` in smoke's Postgres service (ephemeral range collision) | Use `5432:5432`; expand contract test to cover smoke file |
| `.env` + Docker critique service | Passing `ANTHROPIC_API_KEY` via compose env when the key rotated | Adopt `op run` or document the rotation steps in `docs/docker_dev_dx.md` |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Real `ANTHROPIC_API_KEY` in plaintext `.env` | Key exposed on accidental `git add .` | Rotate key now; adopt `op run` or `direnv` pattern; update `.env.example` to show `op://` reference |
| `HEX_API_KEY` in GitHub secret but also in local shell | Key leaked in shell history (`mix hex.publish` without `--yes` prompts) | Use the CI pipeline for publish; never run `mix hex.publish` locally with the production key |
| `.env` not in `.gitignore` (regression risk) | Credentials in git history | Assert `.env` in `.gitignore` in CI (`grep "^\.env$" .gitignore` must match) |

---

## "Looks Done But Isn't" Checklist

- [ ] **make nuke target**: appears to clean up — verify `docker volume prune` is NOT called; only `docker compose down -v` with `$(COMPOSE_PROJECT_NAME)` in the warning message
- [ ] **Dockerfile layer caching**: image rebuilds fast after CSS edit — empirically verify `mix deps.get` does NOT appear in `docker compose up --build` output after touching `assets/css/app.css`
- [ ] **Multi-instance isolation**: two branches running simultaneously — verify `make url` on each shows different hostnames; verify Traefik dashboard shows two distinct routers
- [ ] **Stale instance remediated**: `scoria_demo` is down — verify `docker ps --filter name=scoria_demo` returns empty
- [ ] **`make dev` port**: PORT is not 4000 — verify `grep "PORT" Makefile` shows non-4000 default; verify `shots-native` URL agrees
- [ ] **secrets pattern**: `.env` key rotated — verify by checking date of last rotation; `op://` reference in `.env.example`
- [ ] **Hex publish docs pass first**: `mix docs` clean before release-please merge — no ExDoc errors locally
- [ ] **post-publish-smoke port**: `5432:5432` not `55432:5432` in `post-publish-smoke.yml`
- [ ] **Verification copy**: no `localhost:4000` in `.planning/` verification sections — `grep -rn "localhost:4000" .planning/` returns zero

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Fleet-wide nuke destroyed other volumes | HIGH | Restore from backup (if any); re-run `make up` in each affected repo to recreate empty volumes + reseed |
| Stale instance answering hostname | LOW | `docker compose -p scoria_demo down -v`; verify with `docker ps -a` |
| Port 4000 collision in `make dev` | LOW | `PORT=4799 make dev` (ad-hoc); bake default into Makefile |
| Competing proxy networks | MEDIUM | `docker network rm local-dev-proxy`; update all affected `compose.yml` to use `proxy`; restart affected stacks |
| Hex version published with wrong content | MEDIUM | Within 60 min: `mix hex.publish --revert 0.1.1`, fix, `mix hex.publish --yes`; after 60 min: must publish `0.1.2` |
| release-please opened duplicate PR | LOW | Close the duplicate; verify `gh pr list --label "autorelease: pending"` shows only one |
| post-publish smoke fails on port collision | MEDIUM | Change to `5432:5432`; add contract guard; re-trigger `workflow_dispatch hex-publish.yml` if publish already succeeded |
| API key accidentally committed | HIGH | Immediately rotate on Anthropic console; `git rebase -i` or BFG to purge history if commit was not pushed; if pushed: rotate first, then force-push with team coordination |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Fleet-wide nuke blast radius | `make nuke`/clean target phase | `grep "volume prune\|system prune" Makefile` returns zero |
| Stale instance (`scoria_demo`) | Stale-instance hygiene doc phase | `docker ps --filter name=scoria_demo` returns empty |
| `make dev` port 4000 collision | PORT default phase | `grep "PORT" Makefile` shows non-4000; `shots-native` URL consistent |
| Competing proxy networks | Fleet-standard doc phase | `docker network ls | grep local-dev-proxy` returns empty |
| Top-level `name:` in compose | Layer/compose audit phase | `grep "^name:" compose.yml` returns zero |
| Dockerfile layer order regression | Dockerfile caching audit phase | CSS edit + `--build` shows no `mix deps.get` |
| `hexpm/elixir` tag without date | Version-update runbook phase | `FROM` tag in Dockerfile.dev has date suffix |
| Plaintext API key in `.env` | Secrets-pattern phase | Key rotated; `.env.example` shows `op://` reference |
| Verification copy drift (`localhost:4000`) | Verification copy correction phase | `grep -rn "localhost:4000" .planning/` returns zero |
| `post-publish-smoke` ephemeral port | Maintenance release phase | `post-publish-smoke.yml` uses `5432:5432`; contract test covers it |
| Hex version rollback window | Maintenance release phase | `mix docs` clean; dry-run passes before live publish |
| release-please duplicate PR | Maintenance release phase | Monitor Actions tab; only one `autorelease: tagged` PR |
| Registry propagation lag | Maintenance release phase | Wait 5 min after smoke before announcing; document in operator guide |
| Doc/banner drift | Verification copy + ongoing | No `localhost:4000` in planning; banner matches Makefile targets |

---

## Sources

- [Docker `docker compose down` docs — volume scoping behavior](https://docs.docker.com/reference/cli/docker/compose/down/)
- [Docker `docker volume prune` docs — global scope, no project filter](https://docs.docker.com/reference/cli/docker/volume/prune/)
- [Docker Compose `name:` interpolation bug — issue #10171](https://github.com/docker/compose/issues/10171)
- [Docker Compose `COMPOSE_PROJECT_NAME` override bug — issue #11734](https://github.com/docker/compose/issues/11734)
- [Traefik `traefik.docker.network` label and 502 routing — official docs](https://doc.traefik.io/traefik/routing/providers/docker/)
- [Traefik 502 mysticism with multi-network containers](https://www.valtersit.com/guides/docker/traefik-reverse-proxy-and-the-docker-502-bad-gateway-mysticism/)
- [hexpm/bob date-suffix on Debian images — issue #100](https://github.com/hexpm/bob/issues/100)
- [hexpm/elixir image tags on Docker Hub](https://hub.docker.com/r/hexpm/elixir)
- [Hex.pm FAQ — 60-minute rollback window](https://hex.pm/docs/faq)
- [Hex.pm publish docs — file inventory, docs publish](https://hex.pm/docs/publish)
- [mix hex.publish — HexDocs](https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html)
- [Elixir Forum — Hex re-publish-within-window friction](https://elixirforum.com/t/could-not-update-a-package-on-hex-pm/29584)
- [1Password CLI — `op run` secrets pattern](https://developer.1password.com/docs/cli/secrets-environment-variables/)
- [direnv + 1Password pattern](https://dev.to/agonza05/load-secrets-automatically-with-1password-and-direnv-pn0)
- [Docker build cache invalidation — official docs](https://docs.docker.com/build/cache/invalidation/)
- [Release Please — Elixir integration (Elixir School)](https://elixirschool.com/blog/managing-releases-with-release-please)
- [Laravel Fleet — cross-project Traefik reverse proxy pattern (cross-ecosystem parallel)](https://github.com/aschmelyun/fleet)
- Scoria codebase: `compose.yml`, `Makefile`, `Dockerfile.dev`, `docker/dev-entrypoint.sh`, `.planning/todos/pending/docker-dx-fleet-hardening.md`, `.github/workflows/` (direct code inspection, HIGH confidence)

---

*Pitfalls research for: v3.2 Drydock — Docker dev-DX hardening + Hex maintenance release*
*Researched: 2026-06-17*
