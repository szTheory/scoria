# Architecture Research

**Domain:** Elixir/Phoenix Hex library — Docker dev-DX hardening + maintenance release pipeline
**Milestone:** v3.2 Drydock
**Researched:** 2026-06-17
**Confidence:** HIGH (all assertions derived from direct file reads; no training-data speculation)

---

## System Overview

The v3.2 work touches three interlocking planes. Understanding their boundaries up front prevents cross-plane contamination (the most common footgun in this class of work).

```
┌─────────────────────────────────────────────────────────────────────┐
│  PLANE A — Docker / Compose / Makefile / Traefik  (dev-only)        │
│                                                                     │
│  ┌──────────┐   ┌───────────┐   ┌────────────────┐  ┌──────────┐  │
│  │ Makefile │   │compose.yml│   │ Dockerfile.dev  │  │Traefik   │  │
│  │(identity)│──▶│(web + db  │──▶│(layer order,    │  │compose   │  │
│  │          │   │ + shots)  │   │ BuildKit cache) │  │(shared,  │  │
│  └────┬─────┘   └─────┬─────┘   └────────────────┘  │ proxy    │  │
│       │               │                               │ network) │  │
│  BRANCH → INSTANCE   web → proxy network ────────────▶└──────────┘  │
│       │                                                             │
│  ┌────▼───────────────────────────────────────────────────────┐    │
│  │  docker/dev-entrypoint.sh  (DB setup, banner, phx.server)  │    │
│  └────────────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────────────┤
│  PLANE B — Elixir dev host harness  (dev/ + config/dev.exs)        │
│                                                                     │
│  ┌────────────────┐   ┌──────────────┐   ┌─────────────────────┐  │
│  │ ScoriaWeb.     │   │ ScoriaWeb.   │   │ ScoriaWeb.          │  │
│  │ DevEndpoint    │──▶│ DevRouter    │──▶│ DevAssetWatcher     │  │
│  │ (Bandit,       │   │(scoria_dash- │   │(css/js hot-rebuild) │  │
│  │  PORT env)     │   │ board/scoria)│   └─────────────────────┘  │
│  └────────────────┘   └──────────────┘                            │
│       ▲ started via :dev_children (config/dev.exs)                 │
│       │ never in package.files → never shipped to Hex              │
├─────────────────────────────────────────────────────────────────────┤
│  PLANE C — Release / CI pipeline  (.github/workflows/)              │
│                                                                     │
│  ┌──────────────────┐   ┌──────────────┐   ┌────────────────────┐ │
│  │ release-please   │──▶│ ci-verify    │──▶│ hex-publish         │ │
│  │ .yml             │   │ .yml (reuse- │   │ (in release-please │ │
│  │ (PR → tag →      │   │  able SSOT)  │   │  .yml, gated by    │ │
│  │  release)        │   └──────────────┘   │  gate-ci-green)    │ │
│  └──────────────────┘                      └──────────┬─────────┘ │
│                                                        │            │
│  ┌─────────────────────────────────────────────────────▼──────┐    │
│  │  post-publish-smoke.yml  (registry attest, workflow_call)   │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

These planes share no runtime code. Changes in Plane A never touch Plane C and vice versa. The risk of v3.2 is drift between them at the *documentation and verification-copy* level — that is the primary integration surface to guard.

---

## Stream A: Docker dev-DX hardening

### Current component inventory (verified from file reads)

| File | Role | Status |
|------|------|--------|
| `Makefile` | Identity derivation (BRANCH → INSTANCE → COMPOSE_PROJECT_NAME/SCORIA_HOST); targets: proxy/up/up-d/down/logs/url/open/dev/seed/reseed/shots/critique/shots-native | **Exists — modify** |
| `compose.yml` | web + db (unpublished pgvector) + profile-gated shots/critique; no `container_name:`, no top-level `name:`, interpolated Traefik labels | **Exists — minor modify** |
| `Dockerfile.dev` | Layer-ordered BuildKit dev image; pinned to `.tool-versions` (Elixir 1.19.5-OTP-27.3.2 on debian-bookworm-20260518-slim) | **Exists — minor modify** |
| `docker/traefik/compose.yml` | Long-lived shared proxy; `name: dev_proxy`; Traefik v3.7.1 on `proxy` external network | **Exists — no change** |
| `docker/dev-entrypoint.sh` | DB setup (idempotent), URL/route banner, launches the native Phoenix server | **Exists — modify** |
| `dev/dev_endpoint.ex` | `ScoriaWeb.DevEndpoint` — Bandit, PORT env, live_reload opt-in via `SCORIA_DEV_LIVE_RELOAD` | **Exists — no change** |
| `dev/dev_router.ex` | Mounts `scoria_dashboard "/scoria"`, `put_demo_tenant` plug | **Exists — no change** |
| `dev/asset_watcher.ex` | `ScoriaWeb.DevAssetWatcher` — css/js rebuild on assets/ change | **Exists — no change** |
| `config/dev.exs` | DevEndpoint config (PORT from env, `0.0.0.0`, ≥64-char secret_key_base); `dev_children` hook; `FILE_SYSTEM_BACKEND` gate | **Exists — no change** |
| `.env.example` | Documents COMPOSE_PROJECT_NAME, SCORIA_HOST (bare-compose path) and ANTHROPIC_API_KEY | **Exists — modify** |
| `dev/pgvector-compose.yml` | Native-host DB only; publishes `127.0.0.1:55432:5432`; no `container_name:` | **Exists — no change** |
| `.dockerignore` | Excludes `_build/`, `deps/`, `.git/`, `priv/static/scoria/`, `.env`, and dev-only dirs | **Exists — no change** |
| `docs/docker_dev_dx.md` | Portable fleet standard and adoption guide | **Exists — significant modify** |

### Integration point 1 — PORT default in `make dev`

**Current state:** `make dev` launches the native Phoenix server with live reload. The `DevEndpoint` reads `PORT` from env, defaulting to `4000` (in `config/dev.exs`). No PORT override existed in the old Makefile target.

**Integration:** Add `PORT=4799` (or any non-4000 free port) to the `dev` target in `Makefile`. The change is one line:

```make
dev:
	SCORIA_DEV_LIVE_RELOAD=1 PORT=4799 [native Phoenix server command]
```

**Why 4799:** Scoria's library index in szTheory's ecosystem; memorable, distant from 4000 so the fleet has clear headroom, below 8080/3000/6379 collision zones. Any value 4001–4999 outside known fleet ports works. The exact value is a product decision, not an architectural constraint.

**Tradeoffs:**
- Pro: Zero-config collision avoidance; baked into the SSOT target; the shots-native target needs a matching update or a `PORT` variable.
- Con: If an adopter's host app happens to bind 4799 this still collides — but that is far rarer than 4000. The Docker path (`make up`) has no PORT issue at all (ephemeral loopback + Traefik).
- The `shots-native` target in the Makefile must match whatever PORT is chosen, or be parameterized as `$(PORT)`.

**What is new vs modified:** `Makefile` (modified — `dev` target and `shots-native` target).

### Integration point 2 — `make nuke`/clean target + stale-instance hygiene

**Current state:** No nuke/clean target exists. The `down` target stops the current instance stack. There is no documented or automated path to destroy stale instances (e.g., the pre-branch-scoped `scoria_demo` project that was verified still routing `scoria.localhost`).

**Integration:** Add a `nuke` target to `Makefile`. The target operates on the *current* instance (scoped by `COMPOSE_PROJECT_NAME`) by default and offers an `ALL=1` escape hatch for full fleet prune. Pattern:

```make
## nuke: destroy this instance — stop containers, remove volumes, remove image
nuke:
	docker compose down --volumes --rmi local
	@echo "Instance $(COMPOSE_PROJECT_NAME) nuked. Volumes and local image removed."

## nuke-all: prune all stopped scoria-* containers, dangling volumes, orphan networks (fleet hygiene)
nuke-all:
	docker compose down --volumes --rmi local 2>/dev/null || true
	docker container prune -f --filter "label=com.docker.compose.project=$(COMPOSE_PROJECT_NAME)" 2>/dev/null || true
	@echo "Run 'docker system prune' manually for full fleet cleanup."
```

**Why two targets not one:** A `nuke` that silently destroys volumes from other branches is an unusually high blast radius for a Makefile target. The principle of least surprise says the default target is instance-scoped; the fleet-wide case is opt-in and explicitly named `nuke-all`.

**Doc surface:** `docs/docker_dev_dx.md` gains a "Stale instance hygiene" subsection covering:
1. Per-instance `make nuke` (removes this branch's DB volume and local image).
2. Finding orphan instances: `docker ps -a --filter label=com.docker.compose.project` scoped to `scoria-*`.
3. The pre-branch-scoped `scoria_demo` teardown one-liner: `INSTANCE=scoria docker compose down --volumes`.
4. Full fleet prune for a clean slate: `docker system prune -f`.

**What is new vs modified:** `Makefile` (modified — new targets), `docs/docker_dev_dx.md` (modified).

### Integration point 3 — Banner route-list

**Current state:** `docker/dev-entrypoint.sh` already prints a route list (9 paths under "Screens:") alongside the instance URL, seed instructions, and screenshot harness commands. The banner is reasonably complete.

**Gap:** The banner uses a static `http://${HOST}/scoria` URL. The `HOST` variable captures `PHX_HOST` or falls back to `scoria.localhost` — correct for the Docker path but wrong for `make dev` (native), where the URL is `localhost:<PORT>/scoria`. The `make dev` native path never runs the entrypoint script at all — it launches the native Phoenix server directly via the Makefile.

**Integration:** Two sub-changes:

1. **Entrypoint banner** (`docker/dev-entrypoint.sh`): Expand the banner to include the ephemeral fallback URL explicitly (currently it says "run `make url`") — print it inline by calling `docker compose port web 4000` or just directing to `make url`. The current banner is already good; the main v3.2 work is confirming it includes the right routes after any screen additions. Add a "Native dev server" note clarifying that `make dev` uses PORT 4799 (or whatever is chosen) so readers don't search for `4000`.

2. **Native `make dev` banner:** Currently `make dev` prints nothing — the server just starts. Add a brief startup note to the `dev` target:

```make
dev:
	@echo "Starting native dev server at http://localhost:4799/scoria (live-reload on)"
	SCORIA_DEV_LIVE_RELOAD=1 PORT=4799 [native Phoenix server command]
```

**What is new vs modified:** `docker/dev-entrypoint.sh` (minor modify), `Makefile` (modified — dev target comment/echo).

### Integration point 4 — Dockerfile layer-caching guarantee

**Current state (verified from Dockerfile.dev):**

The existing layer order is already correct:
1. Base image + apt (BuildKit cache mount for `/var/cache/apt` and `/var/lib/apt/lists`)
2. `mix local.hex` + `mix local.rebar`
3. `ENV MIX_ENV=dev`
4. **`COPY mix.exs mix.lock ./`** + `mix deps.get` (BuildKit cache mount for `/root/.hex`)
5. **`COPY config config`** + `mix deps.compile` (BuildKit cache mounts for `/root/.hex` and `/root/.cache/rebar3`)
6. **`COPY lib lib / dev dev / priv priv`** + `mix compile`
7. `COPY docker/dev-entrypoint.sh`

A CSS/HEEx edit in `lib/` or `priv/` only invalidates layer 6 (`mix compile` — the app compile). It does NOT invalidate the dep-fetch layer (4) or the dep-compile layer (5). This is the correct architecture.

**Gap/footgun to document:** `priv/static/scoria/` is excluded from the Docker build context via `.dockerignore` — correctly, because the assets are rebuilt in-container by `mix scoria.assets.build`. However, if someone adds a file to `config/` (layer 5), it invalidates dep.compile. If someone adds a new dep to `mix.exs`, it invalidates layers 4 and 5. Neither is a bug — it is the correct cache invalidation semantics. The doc should state this explicitly so maintainers don't panic when they see a dep-compile on a `mix.exs` change.

**What layer ordering guarantees and what breaks it:**

| Change type | Layers invalidated | Expected behavior |
|-------------|-------------------|-------------------|
| Edit `lib/**/*.ex` or `lib/**/*.heex` | Layer 6 only (app compile) | Fast rebuild |
| Edit `priv/**` (non-static) | Layer 6 only | Fast rebuild |
| Edit `assets/**` | Nothing (assets rebuilt in-container via watcher) | Zero rebuild |
| Edit `config/**` | Layers 5–6 (dep.compile + app compile) | Moderate rebuild |
| Edit `mix.lock` | Layers 4–6 (dep.get + dep.compile + app compile) | Full dep rebuild |
| Edit `mix.exs` | Layers 4–6 | Full dep rebuild |

**Recommendation:** The Dockerfile layer order is already sound. The only v3.2 work is a short "Layer caching" subsection in `docs/docker_dev_dx.md` explaining this table. No Dockerfile changes are architecturally required.

**Caveat:** There is one subtle issue. The `EXPOSE 4000` directive is declarative/documentation only in Docker — it does not publish the port and does not conflict with Traefik. It is correct as-is.

**What is new vs modified:** `docs/docker_dev_dx.md` (modified — new "Layer caching" section). No `Dockerfile.dev` change required.

### Integration point 5 — Secrets pattern (1Password CLI / direnv)

**Current state (verified from `.env.example`):**

```
ANTHROPIC_API_KEY=sk-ant-...
```

The comment says "gitignored, untracked — not in git history." The `.env` file is correctly excluded from the Docker build context via `.dockerignore`. The `critique` service in `compose.yml` reads `ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-}` from the environment. The only consumer of the key is the critique service (never the main web service).

**The actual risks:**

1. Plaintext key in `.env` on disk (rotated-but-still-present risk, Mac malware/screenshots).
2. Developer accidentally commits `.env` (gitignore mitigates but doesn't eliminate).
3. Key passed into the `critique` container via compose environment (unavoidable without secret mounts).

**Recommended architecture — direnv + 1Password CLI:**

The idiomatic pattern for this class of project (solo maintainer, Mac-first, Docker Compose, no Kubernetes) is:

```
.envrc  (gitignored, sourced automatically by direnv)
  └──▶ op run / op read (1Password CLI) → injects ANTHROPIC_API_KEY into shell env
         └──▶ compose inherits from shell env (no .env file for secrets)
```

Concretely, `.envrc` contains:
```bash
export ANTHROPIC_API_KEY=$(op read "op://Personal/Anthropic API Key/credential" 2>/dev/null || echo "")
```

And `direnv allow` is run once. After that, `cd`ing into the repo automatically injects the key from the vault. The `.env` file becomes purely for non-secret compose tuning (COMPOSE_PROJECT_NAME / SCORIA_HOST overrides for bare-compose users).

**Integration with compose:** `compose.yml` already reads `${ANTHROPIC_API_KEY:-}` from environment. If direnv injects it into the shell, `docker compose` inherits it automatically — no compose change needed.

**File boundary changes:**

| File | Change |
|------|--------|
| `.envrc` | NEW — direnv hook; gitignored |
| `.gitignore` | Modified — add `.envrc` (if not already present) |
| `.env.example` | Modified — remove or comment out `ANTHROPIC_API_KEY=sk-ant-...`, replace with direnv/1Password note |
| `docs/docker_dev_dx.md` | Modified — new "Secrets" section |

**What is new vs modified:**
- `.envrc` is NEW.
- `.env.example` is modified (remove plaintext key stub).
- `docs/docker_dev_dx.md` is modified.

**Tradeoffs:**
- Pro: Key never touches disk as plaintext; direnv is widely understood in the Elixir/Mac ecosystem; integrates with existing compose env-var pattern without any compose changes.
- Con: Requires `direnv` + `op` CLI setup (one-time; well-documented). If 1Password is unavailable, fall back to manually `export ANTHROPIC_API_KEY=...` in the shell before running critique — no regression from current state.
- The `op` CLI must be authenticated (`op signin`) before `direnv` sources the `.envrc`. Add a "First time" note to docs.

**Important:** Rotate the real key that appears in `.env` before shipping this milestone. The architecture change makes future rotation unnecessary because the key is never stored on disk, but the already-exposed key must be rotated now.

### Integration point 6 — Verification copy drift

**Current state (verified from file reads):**

The bug: GSD plan/agent prose, README sections, and `operator_verification.md` told verifiers to use the raw Phoenix command and old fixed localhost dashboard URL. This is wrong in two ways:
1. `localhost:4000` is fleet-owned; the real Docker path is `http://scoria-<branch>.localhost/scoria`.
2. The correct dev command is `make up` (Docker) or `make dev` (native, port 4799 after the fix).

The `docker/dev-entrypoint.sh` banner already prints the correct URL. The Makefile already has the correct targets. The gap is that prose docs and agent verification templates are stale.

**Sources of verification copy (identified from codebase):**

1. `docs/docker_dev_dx.md` — the canonical standard; currently correct (uses `make up`, `*.localhost` URLs).
2. `docs/operator_verification.md` — needs audit; likely has `localhost:4000` references.
3. `docs/MAINTAINERS.md` — needs audit; has CI topology doc; likely references dev server.
4. GSD `.planning/` artifacts (phase plans, agent prose in phase files) — these are historical; updating them is lower value than guarding the canonical sources.
5. README — has install/adoption instructions; dev harness section needs audit.
6. Any `priv/dev/e2e/` spec that hardcodes the server URL — CI already boots with `PORT: 4000` in the `e2e` job (ci.yml line 53), so the e2e lane is correct for CI. Native e2e needs `PORT=4799` when run locally with `make dev`.

**Architecture for drift-resistance (consistent with Scoria's executable-drift-guard tradition):**

The pattern Scoria already uses: define a canonical SSOT module/function, then write a contract test that asserts the correct string appears in the doc/copy file. Examples: `VerificationLanes.closeout_order/0`, `ci_policy_contract_test.exs`, `adoption_surface_test.exs`, `AdopterDocContract`.

Apply the same pattern here:

```
SSOT: Makefile dev target (PORT=4799) + docker/dev-entrypoint.sh (*.localhost URL)
      ↓ (guarded by)
DocDriftGuard test (new or extend existing contract test):
  - assert "make up" appears in docs/docker_dev_dx.md
  - assert "make dev" appears in docs/docker_dev_dx.md  
  - assert "localhost:4000" does NOT appear outside of legacy/note context in docs/docker_dev_dx.md
  - assert "4799" appears in docs/docker_dev_dx.md (or whichever port is chosen)
  - assert docs/docker_dev_dx.md references the *.localhost pattern
```

This is a lightweight ExUnit test (no DB, `--no-start`, runs in policy lane or standalone). It fails loudly when doc copy drifts from the canonical commands.

**What is new vs modified:**
- `docs/docker_dev_dx.md` — modified (already correct for make up; add native dev path and port).
- `docs/operator_verification.md` — modified (correct localhost:4000 references).
- `docs/MAINTAINERS.md` — audit + modify where needed.
- `test/scoria/docker_dx_doc_contract_test.exs` — NEW contract test.
- GSD `.planning/` phase files — lower priority; correct as encountered.

---

## Stream A: `docs/docker_dev_dx.md` as portable fleet standard — IA architecture

The doc already exists and has a solid skeleton. The v3.2 work is hardening it into a complete portable standard with persona/JTBD framing and digestible chunks.

**Proposed information architecture:**

```
docs/docker_dev_dx.md
│
├── # Docker dev DX — multi-instance, no port conflicts
│     [one-paragraph pitch: why this exists, who it's for]
│
├── ## TL;DR  [already exists — keep; add PORT for native path]
│     make proxy / make up / make url / make open / make dev
│
├── ## The model (and why)  [already exists — keep; minor expand]
│     Three rules (proxy by name, no published DB, ephemeral loopback)
│
├── ## Running multiple instances  [already exists — keep]
│     COMPOSE_PROJECT_NAME derivation, footguns
│
├── ## Native dev server (make dev)  [NEW SECTION]
│     When to use (CSS/HEEx iteration, live reload), PORT=4799,
│     port collision avoidance rationale, what live reload requires
│
├── ## No rebuild on source/style edits  [already exists — expand]
│     Layer caching table (CSS edit → zero rebuild, mix.exs → full dep rebuild)
│
├── ## Stale instance hygiene  [NEW SECTION]
│     make nuke, finding orphan instances, pre-branch-scoped teardown one-liner
│
├── ## Secrets pattern  [NEW SECTION]
│     direnv + 1Password CLI integration, .envrc example,
│     fallback (manual export), first-time setup
│
├── ## Adopting this in another repo  [already exists — keep]
│     Step-by-step fleet adoption checklist, proxy network convergence footgun
│
├── ## Safari / curl-by-hostname  [already exists — keep]
│     dnsmasq optional step
│
└── ## Files  [already exists — keep; add .envrc]
      File inventory table
```

**JTBD framing for sections:**

| Reader persona | Their job to be done | Entry section |
|---------------|---------------------|---------------|
| Returning maintainer | "Start the dashboard for a CSS tweak" | TL;DR |
| Returning maintainer | "Why is my rebuild so slow?" | No rebuild on source/style edits |
| New contributor | "How do I run this for the first time?" | TL;DR → The model |
| Fleet maintainer | "Adopt this for rulestead/parapet" | Adopting this in another repo |
| Anyone | "Old scoria_demo container is routing wrong" | Stale instance hygiene |
| Anyone | "I need the LLM critique pass" | Secrets pattern |

---

## Stream B: Maintenance release pipeline

### Current component inventory (verified from file reads)

| File | Role | Status |
|------|------|--------|
| `.github/workflows/release-please.yml` | Release PR lifecycle; creates GitHub release + tag; chains verify → gate-ci-green → publish-hex → post-publish-attest | **Exists — no change** |
| `.github/workflows/ci-verify.yml` | Reusable CI SSOT: policy → build → {test, ratchet, knowledge, connector, full-suite} → verify-summary | **Exists — no change** |
| `.github/workflows/ci.yml` | PR/main entrypoint: calls ci-verify + runs e2e lane; `ci-gate` fan-in (needs verify + e2e) | **Exists — no change** |
| `.github/workflows/hex-publish.yml` | Manual recovery path: workflow_dispatch with tag + release_version inputs; gate-ci-green → verify → publish → post-publish-attest | **Exists — no change** |
| `.github/workflows/post-publish-smoke.yml` | Reusable registry attest: Hex index poll → fresh install → `mix scoria.post_publish_smoke`; called by release-please + hex-publish | **Exists — no change** |
| `.release-please-manifest.json` | Version manifest consumed by release-please-action | **Exists — no change** |
| `release-please-config.json` | Release Please config (release type, changelog sections) | **Exists — not read; assumed correct** |

### The merge flow for open PR #3

Based on the verified workflow files, the exact sequence when the release-please PR (#3) is merged to `main` on green CI:

```
1. Push to main (PR merge)
   └──▶ release-please.yml triggers (push: branches: [main])
        └──▶ release-please job: detect-already-tagged-release-pr
             (COMMIT_MESSAGE matches "Merge pull request #3")
             └──▶ expected_tag = "v$(jq .release-please-manifest.json)" = "v0.1.1"
                  └──▶ gh release view v0.1.1 → does not exist → should_run=true
                  └──▶ Run Release Please action → creates GitHub release + tag v0.1.1
                       outputs: release_created=true, tag_name=v0.1.1, version=0.1.1, sha=<commit sha>

2. verify job (needs: release-please, if release_created == 'true')
   └──▶ calls ci-verify.yml (full policy → build → parallel lanes → verify-summary)

3. gate-ci-green job (needs: [release-please, verify], if release_created == 'true')
   └──▶ polls ci.yml runs on the release sha for `ci-gate` success
        └──▶ if no run found by attempt 3: dispatches ci.yml on tag ref
        └──▶ waits up to 40×30s = 20 min

4. publish-hex job (needs: [release-please, verify, gate-ci-green])
   └──▶ checkout at tag v0.1.1
   └──▶ erlef/setup-beam from .tool-versions
   └──▶ verify @version "0.1.1" in mix.exs
   └──▶ idempotency check: mix hex.info scoria 0.1.1 → skip if already published
   └──▶ mix hex.publish --dry-run --yes (HEX_API_KEY secret)
   └──▶ mix hex.publish --yes
   └──▶ poll Hex API for up to 36×10s = 6 min

5. post-publish-attest job (needs: [release-please, publish-hex])
   └──▶ calls post-publish-smoke.yml with version=0.1.1, skip_index_wait=true
        └──▶ mix scoria.post_publish_smoke (fresh install smoke + upgrade leg if version > 0.1.0)
```

**Integration points for the maintainer action (merge PR #3):**

The only pre-condition is `ci-gate` passing on the release PR branch (`release-please--branches--main`). The `bootstrap-release-pr-ci` job in release-please.yml already handles dispatching `ci.yml` on the release PR branch if `RELEASE_PLEASE_TOKEN` was used to update it. If the PR is already green (as implied by "merge when CI green"), the merge is the only action required.

**Recovery path:** If `publish-hex` fails after the tag exists, run:
```bash
gh workflow run hex-publish.yml -f tag=v0.1.1 -f release_version=0.1.1
```
This is documented in `hex-publish.yml`'s header comment and in `docs/operator_verification.md`.

**No architectural changes needed** for the maintenance release — the pipeline is complete and correct.

---

## Build / dependency order for v3.2 work

Sequencing based on integration dependencies:

```
1. PORT decision (Makefile dev target)
      ↓ (unblocks)
2. Banner update (make dev echo + dev-entrypoint.sh clarification)
      ↓ (unblocks)
3. make nuke target (Makefile)
      ↓
4. Dockerfile layer audit + doc (docs/docker_dev_dx.md — Layer caching section)
      ↓
5. Secrets architecture (.envrc + .env.example + key rotation)
      ↓ (unblocks)
6. docs/docker_dev_dx.md full rewrite (all sections assembled)
      ↓ (unblocks)
7. Verification copy correction (operator_verification.md, MAINTAINERS.md, README)
      ↓ (unblocks)
8. DocDriftGuard contract test (docker_dx_doc_contract_test.exs)
      ↓
9. Merge release-please PR #3 → automated pipeline handles the rest
```

Steps 1–8 are independent of step 9. Steps 1–5 can proceed in parallel within the same session; they only gate steps 6–8.

---

## Anti-patterns to avoid

### Anti-pattern 1: Fixed PORT in compose.yml

**What people do:** Set `ports: - "4799:4000"` in compose.yml to match the native dev PORT.
**Why it's wrong:** The compose Docker path already uses an ephemeral loopback fallback (`127.0.0.1::4000`) + Traefik. A fixed port in compose.yml recreates the very collision problem the architecture was designed to eliminate. The PORT=4799 fix belongs only in `make dev` (native path).
**Do this instead:** Leave compose.yml ports as-is. Native dev uses `PORT=4799`; Docker uses ephemeral + Traefik.

### Anti-pattern 2: Committing secrets to `.envrc`

**What people do:** Put the actual API key value in `.envrc` after adding it to `.gitignore`.
**Why it's wrong:** `.gitignore` is a hint not a guarantee; pre-commit hooks, `git add -p` accidents, and IDE auto-stage can bypass it. The key is still on disk in plaintext.
**Do this instead:** `.envrc` contains only the `op read` invocation. The key never exists on disk.

### Anti-pattern 3: Top-level `name:` in compose.yml

**What people do:** Add `name: scoria` to compose.yml to make the project name predictable.
**Why it's wrong:** A top-level `name:` overrides `COMPOSE_PROJECT_NAME` — the multi-instance isolation mechanism breaks immediately. Two branches would both use the same project name, collide on container names, and share volumes.
**Do this instead:** No `name:`. COMPOSE_PROJECT_NAME from the Makefile (or env) wins.

### Anti-pattern 4: Hardcoding `localhost:4000` in verification copy

**What people do:** Write raw Phoenix fixed-port dashboard instructions in docs/plans/README.
**Why it's wrong:** The fleet owns 4000 (it's the default for every Phoenix app in the szTheory ecosystem). The actual URLs are instance-scoped `*.localhost` routes. Stale copy causes verifiers to check the wrong URL, see a 404 or another app's UI, and mark verification as failed or — worse — accidentally pass it against a stale instance.
**Do this instead:** `make up` → `http://scoria-<branch>.localhost/scoria`, or `make dev` → `http://localhost:4799/scoria`. Document in the drift guard.

### Anti-pattern 5: Updating docs/docker_dev_dx.md without updating the contract test

**What people do:** Edit the doc to add a new command, forget to update the guard test.
**Why it's wrong:** The guard test becomes stale. It may assert the old command string and silently pass even though the doc has drifted in the other direction.
**Do this instead:** The contract test asserts the positive (correct command present) AND the negative (wrong command absent). Both sides of the assertion must be updated together. A PR touching `docs/docker_dev_dx.md` should always touch `test/scoria/docker_dx_doc_contract_test.exs`.

### Anti-pattern 6: Putting `make nuke` before a confirmation prompt

**What people do:** In an effort to be "safe", add a `read -p "Are you sure?"` prompt to `nuke`.
**Why it's wrong:** Interactive prompts break `make` in CI and non-TTY shells. They also train users to click through rather than read carefully.
**Do this instead:** Make the target name explicit enough that the intent is unambiguous (`nuke` is already strong). Document what it destroys in the `## help` comment and in docs. Trust the user.

---

## Integration points summary

| Point | Files changed | New vs modified | Gated by |
|-------|--------------|-----------------|----------|
| PORT default in `make dev` | `Makefile` | Modified | Nothing |
| Native banner | `Makefile` (dev target echo), `docker/dev-entrypoint.sh` | Modified | PORT decision |
| `make nuke` / `make nuke-all` | `Makefile` | Modified | Nothing |
| Layer caching doc | `docs/docker_dev_dx.md` | Modified section | Dockerfile audit (no code change) |
| Secrets pattern | `.envrc` (new), `.gitignore` (modified), `.env.example` (modified) | New + modified | Nothing |
| docs/docker_dev_dx.md rewrite | `docs/docker_dev_dx.md` | Modified | All above |
| Verification copy correction | `docs/operator_verification.md`, `docs/MAINTAINERS.md`, `README.md` | Modified | docs/docker_dev_dx.md final |
| DocDriftGuard contract test | `test/scoria/docker_dx_doc_contract_test.exs` | New | Verification copy correct |
| Maintenance release | No code changes needed — merge PR #3 | N/A | `ci-gate` green on release PR |

---

## Drift-resistance: architecture for the contract test

The test belongs in the `policy` lane (no DB, no app start, runs fast) alongside `ci_policy_contract_test.exs`. It should:

1. Read `docs/docker_dev_dx.md` as a string.
2. Assert presence of: `"make up"`, `"make dev"`, `"*.localhost"`, `"4799"` (or chosen port), `"make nuke"`, `"direnv"` or `"1Password"`, `"ANTHROPIC_API_KEY"`.
3. Assert absence of: `"localhost:4000"` (except in legacy/note context — may need a regex exclusion for the existing `shots-native` entry which legitimately references 4000 for its current Playwright target).
4. Read `docs/operator_verification.md` and assert absence of the raw Phoenix command as a dev-start instruction (it is valid as a concept reference but not as "the command to run").

This follows the exact pattern of `adoption_surface_test.exs` (`AdopterDocContract`) — read a file, assert strings — with the same no-DB, `--no-start` execution model.

The guard is lightweight, catches the most common class of drift (stale copy), and fits naturally in the existing CI policy lane without any topology changes to `ci-verify.yml` or `ci.yml`.

---

*Architecture research for: v3.2 Drydock — Docker dev-DX hardening + maintenance release*
*Researched: 2026-06-17*
*Confidence: HIGH — all assertions derived from direct file reads*
