# Requirements: Scoria — v3.2 Drydock

**Defined:** 2026-06-17
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

> Milestone persona/JTBD: the **solo maintainer** running many Elixir/Phoenix lib demos at once on one Mac wants a hands-off, port-conflict-free local dev experience and a trustworthy one-command maintenance release. Scoria's Traefik + `*.localhost` multi-instance stack is already shipped and **locked** — this milestone hardens the remaining gaps and cuts the queued release. Sibling-repo migration and any proxy bake-off are out of scope.

## v1 Requirements

Requirements for milestone v3.2. Each maps to a roadmap phase.

### DX-CLI — Makefile & launch-banner ergonomics

- [x] **DXCLI-01**: Maintainer can run `make dev` and the native dev harness binds a non-4000 default port (`PORT ?= 4799`, still overridable), with the co-located hardcoded `:4000` in the `shots-native` target and the `dev/dev_endpoint.ex` doc comment updated to match.
- [x] **DXCLI-02**: Maintainer can run `make clean` (stop this instance's containers, keep named volumes) and `make nuke` (also wipe this instance's named volumes) — both scoped to `$(COMPOSE_PROJECT_NAME)` via `docker compose down`, never `docker system/volume prune`; `make nuke` prints a named-scope warning of exactly what it will delete and proceeds without a TTY prompt.
- [x] **DXCLI-03**: Maintainer can run `make fleet` to list the running `scoria-*` instances/containers so a stale instance shadowing `scoria.localhost` is immediately visible.
- [x] **DXCLI-04**: `make` with no target prints `make help` (the `.DEFAULT_GOAL`), listing every target from its `##` description comment.
- [x] **DXCLI-05**: The launch banner prints a copy-pasteable key-route list, a populated `http://127.0.0.1:${PORT}/scoria` fallback URL, and the Traefik admin link — so the maintainer never guesses where to poke around.

### CACHE — Docker layer-caching guarantee

- [x] **CACHE-01**: A CSS/HEEx-only source edit triggers no Mix dependency refetch and no full app recompile — empirically verified and documented as a layer-invalidation table plus a layer-order invariant comment in `Dockerfile.dev`.

### SEC — fleet secrets pattern

- [x] **SEC-01**: Maintainer can keep provider API keys out of plaintext on disk via a documented direnv + 1Password (`op run`) pattern, with committed `.envrc.example` and `.env.op.example`, the plaintext key removed from `.env.example`, and `.envrc`/`.env.op` gitignored.
- [x] **SEC-02**: The previously on-disk local `.env` `ANTHROPIC_API_KEY` concern is closed before ship by maintainer-accepted no-Git-exposure attestation: Git metadata confirms `.env` is ignored, untracked, and absent from Git history; no rotation is claimed or required for this local-only key; no token material is stored in repo artifacts.

### DOCS — verification-copy truth, portable standard & drift guard

- [x] **DOCS-01**: Dev-server verification copy across `docs/operator_verification.md`, `docs/MAINTAINERS.md`, `README`, and GSD agent/plan prose uses `make up` / `make dev` + the real `*.localhost` (and `:4799`) URLs, with no raw Phoenix fixed-port startup guidance left in active instructions.
- [x] **DOCS-02**: `docs/docker_dev_dx.md` is restructured as the reference fleet standard with reader-empathy IA (persona/JTBD, gameplan-at-top, digestible chunks) and new Native-dev-server, Caching-guarantees, Secrets, and Stale-instance-hygiene sections.
- [x] **DOCS-03**: A policy-lane `docker_dx_doc_contract_test.exs` asserts the canonical commands/URLs are present in `docs/docker_dev_dx.md` and that `localhost:4000` as a dev-start is absent, so the verification-copy drift cannot recur.

### REL — maintenance release

- [x] **REL-01**: Maintainer can merge the open release-please PR on green CI to publish `0.1.2` to Hex, with `mix docs` confirmed clean before merge (no package-landed-but-docs-wrong partial publish).
- [x] **REL-02**: A post-publish registry semver upgrade smoke confirms the published `0.1.2` installs from the live Hex registry.
- [x] **REL-03**: `post-publish-smoke.yml` Postgres host-port bind is fixed (`55432:5432` → `5432:5432`) and `ci_policy_contract_test.exs` is extended to scan that file for the ephemeral-port ban, closing the v3.1 FLAKE-01 blind spot.

## v2 Requirements

Deferred to a future milestone. Tracked, not in this roadmap.

### Fleet convergence (cross-repo)

- **FLEET-01**: Migrate sibling repos (rulestead/parapet/etc.) onto the shared Traefik + unpublished-DB standard and converge the competing `proxy` / `local-dev-proxy` nets. (Out of v3.2 by decision; stays in the `docker-dx-fleet-hardening` todo.)
- **FLEET-02**: `make nuke-all` fleet-wide teardown (high blast radius — deliberately deferred).

### Test-code determinism (SEED-004)

- **TESTDET-01**: Convert forced-serial `IntegrationCase` files to `async: true`, de-globalize per-module Phoenix test endpoints, replace ~14 `Process.sleep` sites with `eventually/2`, then raise partition count past 4.

## Out of Scope

Explicitly excluded for v3.2. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Sibling-repo migration | Scoria is the reference impl + portable docs; cross-repo edits fall outside this repo's `.planning/` governance (→ FLEET-01). |
| Proxy bake-off (Caddy/nginx-proxy/compose-profiles) | Traefik + `*.localhost` is shipped and verified live; re-litigating wastes the milestone. |
| Auto-port discovery in `make dev` | Unstable URLs break the `shots-native` harness; a static `4799` default is simpler and predictable. |
| `docker system prune` / `docker volume prune` in any target | Daemon-global blast radius would destroy sibling repos' volumes. |
| Local HTTPS / mkcert / dnsmasq-as-default | `*.localhost` is a secure context in Chromium; keep these as optional escape hatches, not defaults. |
| `make nuke-all` (fleet-wide) | Rare need, high blast radius (→ FLEET-02). |
| Interactive TTY prompt in `make nuke` | Breaks non-TTY/CI invocations; the target name + named-scope warning is the safety signal. |
| Dialyzer gate on Hex publish | Not in the current CI topology; out of a maintenance-release scope. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DXCLI-01 | Phase 29 | Complete |
| DXCLI-02 | Phase 29 | Complete |
| DXCLI-03 | Phase 29 | Complete |
| DXCLI-04 | Phase 29 | Complete |
| DXCLI-05 | Phase 30 | Complete |
| CACHE-01 | Phase 31 | Complete |
| SEC-01 | Phase 32 | Complete |
| SEC-02 | Phase 32 | Complete |
| DOCS-01 | Phase 33 | Complete |
| DOCS-02 | Phase 33 | Complete |
| DOCS-03 | Phase 34 | Complete |
| REL-01 | Phase 35 | Complete |
| REL-02 | Phase 35 | Complete |
| REL-03 | Phase 35 | Complete |

**Coverage:**

- v1 requirements: 14 total
- Mapped to phases: 14 (100%)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-17*
*Last updated: 2026-06-17 — traceability filled after roadmap creation (Phases 29–35)*
