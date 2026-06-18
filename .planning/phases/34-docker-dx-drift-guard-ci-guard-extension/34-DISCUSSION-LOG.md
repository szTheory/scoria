# Phase 34: Docker DX drift guard + CI guard extension - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 34-docker-dx-drift-guard-ci-guard-extension
**Areas discussed:** Todo folding, Post-publish port-fix boundary, Dedicated doc-contract ownership, Stale localhost:4000 guard strictness, Cache-table doc strings

---

## Todo Folding

| Option | Description | Selected |
|--------|-------------|----------|
| Fold only Docker DX doc-drift | Fold the Scoria-local guard portion from `docker-dx-fleet-hardening.md`; review/defer unrelated todos. | Yes |
| Fold none | Treat all matched todos as reviewed only. | |
| Other | User supplies a different scope boundary. | |

**User's choice:** Discuss/consider all. The coherent recommendation folds only the Docker DX doc-drift guard item.
**Notes:** Cross-repo fleet convergence, CI cache-key cleanup, and approval toast UI polish are out of scope for this phase.

---

## Post-Publish Port-Fix Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Extend guard only and intentionally fail until Phase 35 | Preserves nominal phase ownership but leaves Phase 34 red by design. | |
| Extend guard and fix `post-publish-smoke.yml` now | Makes the new guard pass, closes the FLAKE-01 blind spot before release, and keeps CI topology unchanged. | Yes |
| Relax or exclude `post-publish-smoke.yml` until Phase 35 | Keeps Phase 34 green but recreates the known blind spot. | |

**User's choice:** User asked for one-shot recommendations after subagent research.
**Notes:** Research found that `55432` sits in Linux's default ephemeral range and that GitHub's runner-machine Postgres example uses `5432:5432`. Phase 34 should absorb the tiny workflow fix and Phase 35 should verify it as precompleted release hardening.

---

## Dedicated Doc-Contract Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Move/narrow assertions into the dedicated doc contract | Create `test/scoria/docker_dx_doc_contract_test.exs`, move/narrow docs assertions there, and keep CI policy tests focused. | Yes |
| Keep both files with disjoint ownership | Smaller diff but risks duplicated strings and unclear failure routing. | |
| Create a shared helper | Centralizes strings but over-abstracts a short file-read contract. | |

**User's choice:** User delegated decision to research-backed recommendation.
**Notes:** The policy lane uses an explicit test-file list, so the new file must be appended to the existing `mix test --no-start --warnings-as-errors ...` command. No new job or step.

---

## Stale Localhost:4000 Guard Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Ban exact stale URL only | Low friction but misses common stale variants. | |
| Ban bare `localhost:4000` | Simple and mechanical but still misses misleading `127.0.0.1:4000` forms. | |
| Context-aware qualified-port guard | Bans browser-start stale URLs while allowing qualified Docker-internal `:4000` mechanics. | Yes |

**User's choice:** User delegated decision to research-backed recommendation.
**Notes:** The guard should preserve correct documentation of Docker-internal container port `4000`, Traefik service target `4000`, and ephemeral fallback examples such as `127.0.0.1::4000`.

---

## Cache-Table Doc Strings

| Option | Description | Selected |
|--------|-------------|----------|
| Pin DOCS-03 minimum only | Least brittle but drops the Phase 31 handoff. | |
| Pin DOCS-03 minimum plus cache-table strings | Guards both Docker DX commands and the reader-facing cache model in one dedicated file. | Yes |
| Split cache strings into another test/file | Clear separation but more policy-lane file-list sprawl. | |

**User's choice:** User delegated decision to research-backed recommendation.
**Notes:** Pin `mix deps.get`, `mix deps.compile`, and `app compile only` without asserting table layout or exact prose. Existing Dockerfile order tests remain in `ci_policy_contract_test.exs`.

---

## Claude's Discretion

- Exact ExUnit test names and helper names.
- Whether to remove the old Docker DX docs test entirely from `ci_policy_contract_test.exs` or leave a non-duplicative residual check for non-doc policy surfaces.
- Exact regex implementation for the context-aware stale URL guard, provided allowed and forbidden examples remain covered.

## Deferred Ideas

- Fleet-wide sibling-repo convergence remains FLEET-01.
- Fleet-wide `make nuke-all` remains FLEET-02.
- Release publish, Hex verification, and live registry smoke remain Phase 35.
- CI cache-key cleanup remains post-ship cleanup.
- Approval toast legibility remains a UI polish todo.
