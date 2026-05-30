# Phase 80: Upgrade smoke in adoption lane - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 80-Upgrade smoke in adoption lane
**Areas discussed:** Baseline fixture, Same-version bump semantics, Upgrade proof orchestration, Test placement & CI budget, Migration ordering validation

**Mode:** User selected all areas; research via parallel subagents + prompts/ codebase analysis; one-shot cohesive recommendations (no per-question interactive turns).

---

## Baseline fixture creation & refresh

| Option | Description | Selected |
|--------|-------------|----------|
| A — Committed frozen unpack from `v0.1.0` tag | Extract via `mix hex.build --unpack`, commit `test/fixtures/hex_consumer/scoria-0.1.0-unpack/` | ✓ |
| B — Live Hex fetch at test setup | Network-dependent; contradicts D-14 | |
| C — Maintainer refresh script + drift guard | `mix scoria.hex_consumer.refresh_baseline_fixture` + stamp/fingerprint CI guard | ✓ (with A) |

**User's choice:** A+C (committed fixture + refresh/guard hygiene)
**Notes:** Matches Phase 78 D-14, Hex #515 path-dep pattern, warning-inventory drift-guard culture. Reject B for PR CI (Phase 81). Fixture ~1–2 MB; never gitignore. Refresh almost never except tag integrity incident.

---

## Same-version bump semantics

| Option | Description | Selected |
|--------|-------------|----------|
| A — Fingerprint-different tarball = valid upgrade | Content-revision upgrade at same semver | ✓ |
| B — Skip until `published_version() > 0.1.0` | Defer entire test pre-0.1.1 | |
| C — Explicit `post_baseline_version/0` gate | Semver labeling when multiple releases exist | ✓ (naming only, not skip) |

**User's choice:** A now + C as future labeling (reject B)
**Notes:** HEAD ~60 commits ahead of v0.1.0; migrations identical today; installer identical; runtime/lib differs — real signal on overlays + installer chain. Assert `baseline_fp != current_fp`. Hex cannot republish 0.1.0 — Phase 80 = pre-publish content-revision; Phase 81 = registry semver.

---

## Upgrade proof orchestration

| Option | Description | Selected |
|--------|-------------|----------|
| A — `run_upgrade_proof!/2` + `expected_upgrade_steps/1` | Dedicated orchestrator composing baseline + upgrade segments | ✓ |
| B — Extend `run_full_proof!/1` with `:phase` | Call twice with baseline/post_upgrade | |
| C — Inline orchestration in test | Ad-hoc System.cmd in test module | |

**User's choice:** A
**Notes:** Post-upgrade skips `:ecto_create`; adds qualified check steps (`:scoria_install_check_pre_apply` for drift exit 1). Extend `run_mix!` with expect_exit/trailer. Keep Phase 79 consumer API untouched.

---

## Test placement & CI budget

| Option | Description | Selected |
|--------|-------------|----------|
| A — Second test in `host_app_consumer_proof_test.exs` | Same module, shared tags | |
| B — Dedicated `host_app_upgrade_proof_test.exs` | Separate file, `:host_upgrade` tag | ✓ |
| C — Preemptive 240s timeout | Before CI evidence | |
| C-alt — 180s initially, D-37 escalation | Evidence-based bump on upgrade module only | ✓ |

**User's choice:** B + 180s initially (D-37 for upgrade module if needed)
**Notes:** Preserves `--only host_proof` ~50s loop. Adoption lane grows ~58s → ~165–175s (expected). Update `test.adoption.ex` + guard test.

---

## Migration ordering validation

| Option | Description | Selected |
|--------|-------------|----------|
| A — Real migration delta on preserved DB | Pending migrations from bumped tarball on existing schema | ✓ |
| B — Synthetic ordering-trap migration | Production hack for CI | |
| C — Implicit ecto.migrate success only | No-op false green at 0.1.0 | |

**User's choice:** A with honest latent gate
**Notes:** v0.1.0 and HEAD share identical 24 migration files — criterion #4 cannot be fully proven until first post-0.1.0 migration. Ship harness; document latent in VERIFICATION; assert pending migrations when semver/migration delta exists.

---

## Claude's Discretion

- Refresh task naming/placement
- Trailer assertion helper shape
- `phases:` map in upgrade proof result
- Minimal operator_verification paragraph vs defer to Phase 82
- `pending_core_migrations/1` helper timing

## Deferred Ideas

- Live registry semver upgrade — Phase 81
- Full upgrade prose + drift pins — Phase 82
- Synthetic trap migrations — rejected
- Skip-until-0.1.1 — rejected
