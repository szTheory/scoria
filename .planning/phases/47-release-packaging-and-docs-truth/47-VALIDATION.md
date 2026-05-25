---
phase: 47
slug: release-packaging-and-docs-truth
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-25
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus bounded Mix task checks |
| **Config file** | `mix.exs`, `config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs --trace` |
| **Full suite command** | `MIX_ENV=test mix test && mix scoria.release_preview` |
| **Estimated runtime** | ~45-120 seconds depending on docs compile and unpack preview |

---

## Sampling Rate

- **After every task commit:** Run the smallest affected `mix test ... --trace` command from the table below.
- **After every plan wave:** Run `MIX_ENV=test mix test` plus the bounded release-preview lane once Plan 47-03 exists.
- **Before `$gsd-verify-work`:** `mix scoria.release_preview` must pass, then the broader `MIX_ENV=test mix test` umbrella.
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 47-01-01 | 01 | 1 | ADPT-03 | T-47-01-01 / T-47-01-02 | `mix docs` exists locally and docs metadata stays aligned to the shipped package story. | source + docs build | `mix docs && MIX_ENV=test mix test test/scoria/package_surface_test.exs --trace` | ❌ W0 | ⬜ pending |
| 47-02-01 | 02 | 2 | ADPT-04 | T-47-02-01 / T-47-02-02 | Explicit package inventory includes runtime code, migrations, README, and adoption guides. | package unpack | `MIX_ENV=test mix test test/scoria/package_surface_test.exs --trace && mix hex.build --unpack --output tmp/scoria-hex-preview` | ❌ W0 | ⬜ pending |
| 47-03-01 | 03 | 3 | ADPT-03, ADPT-04 | T-47-03-01 / T-47-03-02 | One bounded release-preview lane fails fast on docs-build drift or package-inventory drift and is wired into CI. | named task + CI guard | `MIX_ENV=test mix test test/mix/tasks/scoria.release_preview_test.exs --trace && mix scoria.release_preview` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing ExUnit and Mix infrastructure covers this phase.
- No new framework install is required before execution.
- The first implementation plan must create `test/scoria/package_surface_test.exs` so docs/package truth can be checked before the release-preview lane is introduced.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| HexDocs landing-page readability once `mix docs` succeeds | ADPT-03 | ExUnit can prove buildability and metadata, but maintainers may still want one visual smoke check on generated docs nav order and extras labels | Run `mix docs`, open `doc/index.html`, confirm README plus the five guide extras appear in the intended adoption order |

---

## Validation Sign-Off

- [x] All tasks have automated verification commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 does not require installing new test infrastructure.
- [x] No watch-mode flags.
- [x] Feedback latency target stays under 120 seconds for bounded checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** planned on 2026-05-25; execute phase should keep this contract unless repo verification seams materially change.
