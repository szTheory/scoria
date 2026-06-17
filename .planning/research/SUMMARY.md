# Project Research Summary — v3.2 Drydock

**Project:** Scoria — v3.2 Drydock
**Domain:** Docker dev-DX hardening + Hex maintenance release (solo-maintainer Phoenix library)
**Researched:** 2026-06-17
**Confidence:** HIGH

## Executive Summary

v3.2 Drydock is a hygiene and hardening milestone across two parallel streams. **Stream A** closes concrete gaps in the Docker dev-DX fleet standard: baking a non-colliding PORT default into `make dev`, adding two-tier instance cleanup (`make clean` / `make nuke`), hardening the launch banner with a populated fallback URL and Traefik admin link + route list, auditing and documenting Dockerfile layer-caching guarantees (already correct — doc and verify only), establishing a zero-plaintext-on-disk secrets pattern via direnv + 1Password `op run`, and correcting stale `localhost:4000` verification copy throughout docs and planning files. **Stream B** is a maintenance release: merge the open release-please PR #3 (`0.1.2`), run the post-publish registry smoke, and close. The two streams are fully independent and can proceed in parallel.

The four researchers converged strongly. The Dockerfile layer order is already correct — no code change, only empirical verification and a comment block. `make nuke` must use only `docker compose down -v --remove-orphans`, never `docker system prune` / `docker volume prune` (daemon-global; would destroy sibling repos' volumes). direnv + `op run` is the clear secrets recommendation: zero plaintext on disk, reuses the maintainer's 1Password, no compose changes (Compose inherits shell env). The highest-leverage anti-recurrence action is a new `docker_dx_doc_contract_test.exs` in the policy lane mirroring `adoption_surface_test.exs`.

**One live bug to fix in Stream B:** `post-publish-smoke.yml` still binds Postgres `55432:5432` (the v3.1 FLAKE-01 fix missed this file) and `ci_policy_contract_test.exs` does not scan it. Fix to `5432:5432`, extend the guard, and run `mix docs` as an explicit pre-publish verification step.

## Recommended Stack

No new technology. Two new *local* dev tools, installed once per machine via `brew`:
- **`direnv` (2.35.x) + `1password-cli` (op 2.x)** — secrets injection via `op run --env-file .env.op`; `op://` references resolve in memory at process start; never plaintext on disk; Compose inherits from shell. Chosen over sops/git-crypt/Doppler (overkill for one maintainer + one key) and plain `.env` (plaintext risk).
- **`PORT ?= 4799` in Makefile** — static non-4000 default (stable URL needed by the Playwright `shots-native` harness; below the macOS ephemeral range). No `config/dev.exs` change — Makefile injects the value; Docker path unaffected. `PORT=XXXX make dev` still overrides.
- **`docker compose down -v --remove-orphans`** — the only safe scoped cleanup verb (scopes to `<COMPOSE_PROJECT_NAME>_*`).
- **`mix docs` pre-publish verification** — must be clean before `mix hex.publish` to avoid the package-landed-but-docs-wrong partial-publish state.

Everything else (Elixir 1.19.5-OTP-27, Traefik v3.7.1, hexpm/elixir bookworm-slim, pgvector pg16, release-please-action v5) ships unchanged.

## Expected Features

### Table stakes (must have)
- `PORT ?= 4799` in `make dev` + co-located `$(PORT)` fix in `shots-native` URL + `dev/dev_endpoint.ex` doc comment
- `make clean` (stop containers, keep volumes) and `make nuke` (stop + wipe named volumes, **instance-scoped**, no TTY prompt — named-scope warning message instead)
- `make fleet` — `docker ps` filtered to `scoria-*`; surfaces stale-instance conflicts
- `make help` as `.DEFAULT_GOAL` with `##`-comment awk parser
- Launch banner: populated fallback URL (`http://127.0.0.1:${PORT}/scoria`), Traefik admin link (`http://localhost:8080`), grouped key-route list, ops command palette
- `docker_dx_doc_contract_test.exs` (new, policy lane) — asserts canonical strings present in `docs/docker_dev_dx.md`; asserts `localhost:4000` absent
- `ci_policy_contract_test.exs` extended to scan `post-publish-smoke.yml` for the ephemeral-port ban
- All `localhost:4000` / `mix phx.server` verification copy corrected in `.planning/` + `docs/`
- `post-publish-smoke.yml` port `55432:5432` → `5432:5432`
- PR #3 merged on green CI → automated pipeline → `0.1.2` on Hex → post-publish smoke passes; `mix docs` clean confirmed before merge
- `ANTHROPIC_API_KEY` rotated (out-of-band maintainer action, pre-ship)

### Differentiators (should have)
- `docs/docker_dev_dx.md` restructured: persona/JTBD → Quick Start → Command Reference → The Model → Native dev server (new) → Caching Guarantees (new) → Secrets (new, opt-in tiers) → Stale Instance Hygiene (new) → Adopting → Safari → Files
- `.envrc.example` + `.env.op.example` committed; `.envrc` + `.env.op` gitignored
- `make dev` echo line showing `http://localhost:4799/scoria` before start
- Dockerfile.dev: empirical cache-verification note + layer-order invariant comment
- MAINTAINERS.md: 4-step "Cutting a release" runbook + CDN-propagation note

### Defer after v3.2
`make nuke-all` (fleet-wide), HTTPS/mkcert, dnsmasq as default, sibling-repo migration, auto-port discovery.

## Architecture Approach

Three planes share no runtime code: **A** Docker/Compose/Makefile/Traefik, **B** Elixir dev host harness, **C** release/CI pipeline. The cross-plane integration surface is *documentation + verification copy* — the drift vector this milestone hardens. The `docker_dx_doc_contract_test.exs` is the mechanical guard at that surface and the single highest-leverage deliverable.

Components touched: `Makefile` (adds `clean`/`nuke`/`fleet`/`help`; modifies `dev`/`shots-native`); `docker/dev-entrypoint.sh` (banner); `docs/docker_dev_dx.md` (restructure + 4 new sections); `post-publish-smoke.yml` (port fix); `ci_policy_contract_test.exs` (extend scan); `.envrc`/`.env.op` (new, gitignored) + committed examples.

## Critical Pitfalls

1. **Fleet-wide nuke destroys sibling volumes** — use ONLY `docker compose down -v --remove-orphans`; gate: `grep -n "volume prune\|system prune" Makefile` must be empty.
2. **Stale `scoria_demo` instance shadows `scoria.localhost`** — `docker compose -p scoria_demo down --volumes`; `make fleet` surfaces this class going forward (one-time pre-Phase-1 teardown).
3. **`post-publish-smoke.yml` `55432:5432` ephemeral-range bind** — only unresolved CI reliability bug; fix to `5432:5432` + extend contract guard.
4. **Verification-copy drift causes false pass/fail** — `docker_dx_doc_contract_test.exs` is the mechanical guard.
5. **Hex partial publish (package landed, docs wrong)** — run `mix docs` before merge; 60-min rollback window has friction.

## Disagreement Flagged for Roadmapper

**`make nuke` confirmation prompt — add or omit?** STACK said add an interactive `read` pause; ARCHITECTURE said no prompt (breaks non-TTY/CI). **Recommended resolution:** omit the TTY prompt; print a prominent warning naming `$(COMPOSE_PROJECT_NAME)` and what will be deleted, then proceed. The target name `nuke` is the safety signal.

## Do NOT Add

`just` migration; Caddy/nginx-proxy bake-off; dnsmasq as default; auto-port discovery; `docker system prune` / `docker volume prune` in any target; sibling-repo migration; `PORT=4799` in `config/dev.exs`; top-level `name:` in compose.yml; Dialyzer gate on publish; local HTTPS/mkcert; `make nuke-all`; interactive TTY prompt in `make nuke`.

## Suggested Roadmap (Stream A 1–6 + independent Stream B 7)

1. **Makefile Hardening** — PORT 4799 + `shots-native` fix + `clean`/`nuke` (no TTY prompt) + `fleet` + `help`. Foundation; zero deps.
2. **Launch Banner + Native Dev Notice** — fallback URL, Traefik admin link, grouped routes, ops palette; `make dev` echo; `dev_endpoint.ex` comment. Depends on Phase 1 PORT.
3. **Dockerfile Caching Audit + Comment Block** — empirical proof + invalidation table; parallel with Phase 2.
4. **Secrets Pattern** — `.envrc`/`.env.op` examples, `.env.example` cleanup, docs Secrets section, key rotation. Parallel with 2/3.
5. **Doc Restructure + Verification-Copy Correction** — `docs/docker_dev_dx.md` rewrite; fix all `localhost:4000` in `.planning/`+`docs/`; MAINTAINERS release runbook. After 1–4.
6. **Contract Test + CI Guard Extension** — `docker_dx_doc_contract_test.exs` (policy lane) + extend `ci_policy_contract_test.exs` to scan `post-publish-smoke.yml`. Last in Stream A.
7. **Maintenance Release (PR #3 → 0.1.2)** — fix `55432`→`5432` + `mix docs` clean → merge on green → Hex publish → post-publish smoke. Fully independent of 1–6.

**Research flags:** none — all phases use standard, documented patterns grounded in direct file inspection.

**Overall confidence:** HIGH. The `post-publish-smoke.yml` `55432:5432` bug is the single confirmed live defect.

## Sources

- STACK: `.planning/research/STACK.md`
- FEATURES: `.planning/research/FEATURES.md`
- ARCHITECTURE: `.planning/research/ARCHITECTURE.md`
- PITFALLS: `.planning/research/PITFALLS.md`
