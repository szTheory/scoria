---
phase: 30
slug: launch-banner-native-dev-notice
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 30-RESEARCH.md "## Validation Architecture". A banner↔router **parity contract test** is explicitly **Phase 34 scope** — keep the derivation testable here, but do NOT build the contract test.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) for any Elixir-side assertion; shell/CLI checks for Makefile + entrypoint |
| **Config file** | `mix.exs` / `test/test_helper.exs` (existing); no new framework needed |
| **Quick run command** | `mix phx.routes ScoriaWeb.DevRouter 2>/dev/null \| awk '$2=="GET" && $3 ~ /^\/scoria/ && $3 !~ /:/ {print $3}' \| sort -u` (asserts the 9-path set) |
| **Full suite command** | `mix test` (no regression) + `shellcheck docker/dev-entrypoint.sh` |
| **Estimated runtime** | ~30 seconds (pipeline + shellcheck); `mix test` per existing suite |

---

## Sampling Rate

- **After every task commit:** Run the route-filter pipeline; `shellcheck docker/dev-entrypoint.sh`.
- **After every plan wave:** `mix test` (no regression) + `bash -n docker/dev-entrypoint.sh` syntax check (full `docker compose up` banner check if practical).
- **Before `/gsd-verify-work`:** All five req-rows below pass.
- **Max feedback latency:** ~30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| native line | 01 | 1 | DXCLI-05 | — | N/A | manual/CLI | `make -n dev` shows the `@echo`; `make dev PORT=5000` dry-inspect shows `:5000` | ❌ W0 | ⬜ pending |
| route list | 01 | 1 | DXCLI-05 | — | N/A | CLI/smoke | quick-run pipeline returns exactly the 9-path set (incl. `/scoria/datasets`, no `:` routes) | ✅ verified | ⬜ pending |
| Traefik link | 01 | 1 | DXCLI-05 | — | N/A | grep | `grep -F 'http://localhost:8080' docker/dev-entrypoint.sh` | ❌ W0 | ⬜ pending |
| native notice | 01 | 1 | DXCLI-05 | — | N/A | grep | `grep -F 'Native dev server' docker/dev-entrypoint.sh` | ❌ W0 | ⬜ pending |
| boot-safety | 01 | 1 | DXCLI-05 | — | banner still prints if routes derivation fails; no `set -e` abort | review/CLI | `shellcheck docker/dev-entrypoint.sh` clean; confirm `\|\| true` + empty-check present | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `shellcheck` clean on the modified `docker/dev-entrypoint.sh` (shellcheck 0.11.0 available on host — verified).
- [ ] A one-off CLI assertion (or plan note) that the filtered pipeline returns exactly the 9-path set — the seam Phase 34 will harden into a contract test. Do NOT write the contract test here.
- [ ] Framework install: none needed (existing ExUnit + host shellcheck cover this phase).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `make dev` startup line renders before Phoenix boot noise | DXCLI-05 | Requires running the native dev server interactively | `make dev` (or `make -n dev` to inspect recipe); confirm `==> Scoria dev (native) → http://localhost:4799/scoria` prints first |
| Docker banner visual layout (distinct copy-pasteable lines) | DXCLI-05 | Requires `docker compose up` boot to see rendered banner | Boot via Docker; confirm Traefik link, native notice, and aligned route list each on their own line |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
