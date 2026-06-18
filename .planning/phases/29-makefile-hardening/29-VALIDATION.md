---
phase: 29
slug: makefile-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-17
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

This phase edits the `Makefile` plus two doc comments. There is no unit-test
framework in play — every success criterion is verifiable by a deterministic
`grep`/CLI assertion against the working tree (and, for `fleet`/`nuke`, a live
`make`/`docker` invocation). Those assertions ARE the validation suite.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — shell/grep assertions (Makefile phase, no app code) |
| **Config file** | none |
| **Quick run command** | `bash .planning/phases/29-makefile-hardening/verify.sh` (the SC grep block, if scripted) — otherwise the per-criterion greps below |
| **Full suite command** | same grep block + `make help` smoke + `make fleet` smoke |
| **Estimated runtime** | ~5 seconds (no compile, no DB) |

---

## Sampling Rate

- **After every task commit:** Run the relevant SC grep for the file just edited.
- **After every plan wave:** Run the full SC-1..SC-5 grep block.
- **Before `/gsd:verify-work`:** All five SC checks must pass; `make help` and `make fleet` must run without error.
- **Max feedback latency:** ~5 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|--------|
| 29-01-* | 01 | 1 | DXCLI-01 | N/A | grep | `grep "PORT ?= 4799" Makefile` + `grep "localhost:\$(PORT)" Makefile` + `grep "localhost:4799" config/dev.exs dev/dev_endpoint.ex` | ⬜ pending |
| 29-02-* | 02 | 1 | DXCLI-02 | no global prune; scoped to `$(COMPOSE_PROJECT_NAME)` | grep | `grep "^clean:" -A2 Makefile`, `grep "^down: clean" Makefile`, `grep "^nuke:" -A8 Makefile`, **`grep -n "volume prune\|system prune" Makefile` returns 0** | ⬜ pending |
| 29-02-* | 02 | 1 | DXCLI-02 | warning before destructive cmd; no TTY prompt | grep | `grep "^nuke:" -A8 Makefile` shows the `@echo NUKE:` + `docker compose config --volumes` lines; `grep -nE "read |confirm|y/N" Makefile` returns 0 in nuke | ⬜ pending |
| 29-03-* | 03 | 1 | DXCLI-03 | filter by name+traefik label, running-only | grep + smoke | `grep "^fleet:" -A8 Makefile` shows `--filter name=scoria- --filter label=traefik.enable=true`; `make fleet` exits 0 (empty-state prints "No scoria instances running.") | ⬜ pending |
| 29-04-* | 04 | 1 | DXCLI-04 | help is `.DEFAULT_GOAL`; awk over `##` comments | grep + smoke | `grep ".DEFAULT_GOAL := help" Makefile`; `make` (no args) prints every new target (`clean`,`down`,`reseed`,`nuke`,`fleet`,`help`,`dev`,…) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements — no test framework to install. Validation is deterministic shell assertions; no Wave 0 stubs needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `make dev` actually binds 4799 in a live native boot | DXCLI-01 | Requires a running Postgres + native `mix phx.server`; not run in CI | After `make up-d`, run `make dev`, confirm the server logs `:4799` and `http://localhost:4799/scoria` loads. |
| `make nuke` deletes only this instance's volumes | DXCLI-02 | Destructive; only safe to confirm on a throwaway instance | On a disposable branch instance: `make up-d`, note `docker volume ls` for `$(COMPOSE_PROJECT_NAME)_*`, run `make nuke`, confirm those volumes are gone and other instances' volumes remain. |
| `make fleet` lists a real running instance | DXCLI-03 | Needs ≥1 live `scoria-*` stack to show a non-empty table | With an instance up, `make fleet` shows its project name + status + ports. |

*The static `grep` assertions above are fully automated; the live boots are the manual confirmations the executor records.*

---

## Validation Sign-Off

- [ ] All tasks have an automated grep/CLI verify or a documented manual confirmation
- [ ] Sampling continuity: no 3 consecutive tasks without an automated check
- [ ] Wave 0 covers all MISSING references (N/A — none)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter (set by planner once per-task `<automated>` blocks are written)

**Approval:** pending
