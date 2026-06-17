---
gsd_state_version: 1.0
milestone: v3.2
milestone_name: Drydock
status: planning
last_updated: "2026-06-17T21:24:32.809Z"
last_activity: 2026-06-17
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-17 after v3.1 CI/CD Velocity milestone)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** v3.1 CI/CD Velocity SHIPPED + archived (audit `passed`, 13/13). Planning the next milestone — start with `/gsd:new-milestone` (SEED-004 async/`Process.sleep` cleanup is the leading candidate).

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-06-17 — Milestone v3.2 started

## Performance Metrics

- **Latest Shipped:** `v3.1 CI/CD Velocity` (2026-06-17) — CI velocity/flake infra+docs; phases 23–28, 9 plans, 13 tasks. Audit `passed` (13/13 satisfied). PR CI critical path 77m→7m38s MEASURED (run 27709716751); bar preserved (closeout order unchanged, `CI / ci-gate` name stable, nothing demoted).
- **Previous Shipped:** `v3.0 Control Room` (2026-06-14) — dashboard design-system / IA / motion / proof; phases 11–17, 38 plans, 65 tasks. Audit `gaps_found` accepted (18/28 satisfied, 10 partial, 0 unsatisfied).
- **Previous Shipped:** `v2.17 Vesicle` (2026-06-11) — brand system, phases 18–22
- **Hex release:** `0.1.1` prepared; publish via release-please pending CI green
- **Tags:** `v3.1` and `v3.0` annotated tags created locally on `main` — NOT pushed; pushing is the user's call.

## Accumulated Context

### Roadmap Evolution

- **v3.1 (shipped 2026-06-17):** CI/CD Velocity, phases 23–28 — infra/docs-only milestone realizing SEED-003. Cut PR CI critical path from ~77m (one serial `verify / test` job) to **7m38s MEASURED** (run 27709716751) without weakening the bar: build-once artifact job, knowledge lane `--only knowledge`, parallel fan-out topology `policy → build → { test, ratchet, knowledge, connector, full-suite[×4] } → verify-summary`, 4-way partition sharding, Postgres host-port flake fix + zero-retry policy, and the `mix ci` DX alias. `closeout_order/0` byte-stable, `CI / ci-gate` required-check name unchanged, nothing demoted to nightly. Audit `passed` (13/13). Archived in `.planning/milestones/v3.1-*`.
- **v3.0 (shipped 2026-06-14):** Control Room UI/IA/DX milestone, phases 11–17. Core finding: the design system was under-*adopted*, not under-built (`ui.ex` never exposed the components the token-first CSS already supported). Closed with the design system fully adopted, raw-palette count a verified zero, an enforced DS-06 drift guard, a persona/JTBD IA spine, brand-tied motion + light/dark parity, and a committed screenshot+critique evaluation loop. Closed `gaps_found` (10 verification-doc partials recorded as Known Gaps in MILESTONES.md). Archived in `.planning/milestones/v3.0-*`.
- **v2.17 (shipped):** Brand system milestone, interjected before v3.0 phases 13–17. All 8 mandatory requirements satisfied; BRAND-09 conditional did not fire. Archived in `.planning/milestones/v2.17-*`.
- **v2.16 (shipped):** ReqLLM `~> 1.13` peer bump — minimal dependency hygiene scope.
- **v2.15 (shipped):** Named connector adoption lane — PR WAE after knowledge, not in closeout.

### Decisions (current-milestone summary; full log in PROJECT.md Key Decisions)

- Phase 28 Plan 03 (VELO-01 MEASURED): compile-only ratchet capture (mix test --only :__ratchet_compile_only__) cuts ratchet lane from ~19m to 1m46s; measured critical path 7m38s in run 27709716751 (GREEN, warm-cache); VELO-01 MET — 2026-06-17
- Phase 24 (KNOW-01): `--only knowledge` injected inside `scoria.test.knowledge.ex`; CI YAML and VerificationLanes records unchanged; Layer 2 `after_suite total > 0` guard env-gated; D-03 contract test ratchets file set and `use Scoria.KnowledgeCase` choke point — 2026-06-15
- v3.0 keeps the custom token-first scoped CSS architecture; `ui.ex` is the enforced token gateway (no Tailwind/BEM switch) — 2026-06-03
- v3.0 is UI-only: reserved-name screens with no backend ship as honest "coming soon" stubs, never fake data — 2026-06-03
- Screenshot+critique harness is committed dev-only tooling, not merge-blocking CI (consistent with LiveViewTest-only posture) — 2026-06-03
- Full light + dark parity held to the same polish bar; harness captures both themes mechanically — 2026-06-03
- DS-06 baseline committed; ratchet runs unconditionally in `mix test`; baseline uses `Regex.scan` count (all occurrences per file), must stay consistent — [Phase 12]
- v3.0 closed with `gaps_found` accepted: 10 partials are verification-doc gaps (Phases 13 & 14 never run through gsd-verifier) + IA-05/PROOF-01/PROOF-02 documented threading/proof gaps; 0 functionally unsatisfied — 2026-06-14

## Deferred Items

Items acknowledged and deferred at the v3.1 milestone close on 2026-06-17:

| Category | Item | Status |
|----------|------|--------|
| seed | 003-ci-efficiency-overhaul | SHIPPED as v3.1 |
| uat/verification | Phase 26 live 4-shard CI matrix (`26-HUMAN-UAT.md` / `26-VERIFICATION.md` human_needed) | satisfied GREEN by run 27709716751 |
| todo | ci-policy-job-cache-key-mislabel | pending (post-ship cleanup) |
| todo | docker-dx-fleet-hardening | pending |

**Notes:**

- `003-ci-efficiency-overhaul` (SEED-003) became this milestone, **v3.1 CI/CD Velocity** — now shipped. Seed file retained in `.planning/seeds/` for provenance.
- Phase 26's only open human item (a live 4-shard GHA matrix run) was confirmed GREEN in run 27709716751; its `human_needed` verification + partial UAT are informational only, not functional gaps (see `.planning/milestones/v3.1-MILESTONE-AUDIT.md`).
- `ci-policy-job-cache-key-mislabel` is a medium-priority post-ship cleanup todo surfaced during the close. Todo file retained in `.planning/todos/`.
- `docker-dx-fleet-hardening` is future work (Docker DX / fleet hardening). Todo file retained in `.planning/todos/`.

### v3.0 tech debt carried forward (from milestone audit)

| Source | Item |
|--------|------|
| Phase 13 (IA-05) | incident→trace deep-link fragile; OrchestratorLive lacks `handle_params/3` and drops `?from=` context |
| Phase 13 (IA-05) | dataset→eval quality-loop edge has no explicit cross-screen affordance (sidebar/⌘K only) |
| Phase 14 (SCREEN-01) | `review_queue_live.ex:58` hardcoded `/scoria` mount path (portability one-liner; WARNING-only in dev harness) |
| Phase 14 | `PromoteComponent` receives unused `step` assign in `workflow_live/show.ex:276` (harmless dead assignment) |
| Phase 17 (PROOF-01) | final LLM critique not mechanically re-run (deterministic checklist substituted; documented in-file) |
| Phase 17 (PROOF-02) | only 2/9 screens have paired before/after contact-sheet captures |
| Phases 13 & 14 | no `VERIFICATION.md` — optionally close via `/gsd:verify-work` / `/gsd:validate-phase 13`/`14` |

### Prior-milestone deferred items (still open)

| Category | Item | Status |
|----------|------|--------|
| Release | Publish 0.1.1 via release-please + registry semver upgrade smoke | in_progress |
| Future req | FEAT-RESERVED: real backend + UI for stubbed reserved screens | deferred |
| Future req | IA-LENS: remembered persona "primary lens" on Status Home | deferred |
| Future req | CMDK-SEARCH: full-text object search in command palette | deferred |
| Tech debt | ReqLLM streaming adapter (ECOS-02) | deferred |
| Tech debt | SummarizeWorker dedicated unit test | deferred |
| Tech debt | Local `mix test.connector` migrate_core! ordering on fresh DB | deferred |
| e2e (Phase 14/15) | WR-03 drawer-float + escape-dismiss e2e specs — `test.fixme` until a screen consumes the shells | deferred |
| e2e (Phase 14/15) | Notebook tab-switch e2e spec — blocked on real `SRE.remote_invocation_evidence/1` | deferred |
| v2.17 | BRAND-SITE: marketing landing page / docs site build-out (brand book has blueprints only) | deferred |

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
