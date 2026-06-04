---
gsd_state_version: 1.0
milestone: v3.0
milestone_name: Control Room
status: ready_to_plan
last_updated: 2026-06-04T17:27:15.273Z
last_activity: 2026-06-04
progress:
  total_phases: 15
  completed_phases: 2
  total_plans: 10
  completed_plans: 10
  percent: 13
stopped_at: Phase 12 complete (5/5) — ready to discuss Phase 13
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-03 after v3.0 Control Room milestone start)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 13 — orientation spine (ia)

## Current Position

Phase: 13
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-04

Progress: [██████████] 100%

## Roadmap (v3.0 Control Room, Phases 11–17)

1. **Phase 11 — Evaluation engine + seed depth** (EVAL-01..05) — `mix scoria.ui.shots` harness, 9-dim rubric, full-screen seed depth, baseline audit → gap register/fix backlog. Foundation; every later phase re-runs this loop.
2. **Phase 12 — Design-system component layer** (DS-01..06) — `ui.ex` table/drawer/modal/form/notebook/skeleton/toast, fix `flash_group`, raw-color drift guard. The enforced token gateway.
3. **Phase 13 — Orientation spine (IA)** (IA-01..06) — nav active-state fix, third axis (Operate/Improve/Configure), Status Home, breadcrumbs, ⌘K palette + shortcuts, quality-loop threading, honest reserved-name stubs.
4. **Phase 14 — Least-iterated screens polish** (SCREEN-01, SCREEN-02) — Review Queue / Incidents / Eval Workbench / Prompt Registry+Release conversions; real Dataset Builder index.
5. **Phase 15 — High-traffic screens + evidence adapters** (SCREEN-03, SCREEN-04) — Live Ops / Workflows / Approvals / Connectors polish; 13 evidence components → thin notebook adapters.
6. **Phase 16 — Motion + responsive + theme parity** (MOTION-01..04) — brand-tied motion, focus-visible/a11y, mobile-first md/lg/xl, light+dark parity.
7. **Phase 17 — Consistency sweep + proof** (PROOF-01..03) — re-run audit, rubric-delta + raw-color → 0, before/after contact sheets, MAINTAINERS.md catalog + harness usage.

## Performance Metrics

- **Current milestone:** `v3.0 Control Room` (planning — roadmap created 2026-06-03)
- **Latest Shipped:** `v2.16 ReqLLM Peer Bump` (2026-05-30)
- **Previous Shipped:** `v2.15 Connector Adoption Lane` (2026-05-30)
- **Hex release:** `0.1.1` prepared; publish via release-please pending CI green

## Accumulated Context

### Roadmap Evolution

- **v3.0 (planning):** Control Room UI/IA/DX milestone. Phases 11–17 continue numbering from v2.16's Phase 10.1. Core finding: design system is under-*adopted*, not under-built (~22/25 view files leak raw Tailwind). Sequenced for compounding reuse: primitives (12) before screens (14, 15), least-iterated before high-traffic, cross-cutting motion/parity (16) last before proof (17).
- **v2.16 (shipped):** ReqLLM `~> 1.13` peer bump — minimal dependency hygiene scope.
- **v2.15 (shipped):** Named connector adoption lane — PR WAE after knowledge, not in closeout.

### Decisions

- v3.0 keeps the custom token-first scoped CSS architecture; `ui.ex` is the enforced token gateway (no Tailwind/BEM switch) — 2026-06-03
- v3.0 is UI-only: reserved-name screens with no backend ship as honest "coming soon" stubs, never fake data — 2026-06-03
- Screenshot+critique harness is committed dev-only tooling, not merge-blocking CI (consistent with LiveViewTest-only posture) — 2026-06-03
- Full light + dark parity held to the same polish bar; harness captures both themes mechanically — 2026-06-03
- v2.16 scope: ReqLLM-only — no optional szTheory Hex deps — 2026-05-30
- [Phase ?]: RunSummary.run_id is the correct field for downstream run ID linking
- [Phase ?]: All seeded review candidates need review_status: pending for list_review_queue(%{}) to return them
- [Phase ?]: Use add_if_not_exists when deleted interim migrations may have partially applied columns
- [Phase 12-05]: DS-06 baseline committed; File.exists? guard and :ui_ex_zero tag removed — ratchet runs by default in mix test
- [Phase 12-05]: Phoenix.Component.update/3 must be qualified in approvals_live — Ecto.Query import creates ambiguity
- [Phase 12-05]: DS-06 baseline uses Regex.scan count (all occurrences per file) not grep -c (lines with a match) — must stay consistent
- [Phase ?]: Use Map.get/3 in template instead of :default in slot attr declarations
- [Phase ?]: empty_slot is the slot name in notebook/1 to avoid conflict with the empty boolean attr
- [Phase ?]: JS.hide in toast/1 omits to: option — targets self (Pitfall 3 from RESEARCH.md; avoids id interpolation in component)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| Release | Publish 0.1.1 via release-please + registry semver upgrade smoke | in_progress |
| Future req | FEAT-RESERVED: real backend + UI for stubbed reserved screens | deferred |
| Future req | IA-LENS: remembered persona "primary lens" on Status Home | deferred |
| Future req | CMDK-SEARCH: full-text object search in command palette | deferred |
| Tech debt | ReqLLM streaming adapter (ECOS-02) | deferred |
| Tech debt | SummarizeWorker dedicated unit test | deferred |
| Tech debt | Local `mix test.connector` migrate_core! ordering on fresh DB | deferred |
| e2e (Phase 14/15) | WR-03 drawer-float + escape-dismiss e2e specs — CSS/code fixed in Phase 12, but no screen consumes `<.modal>`/`<.drawer>` yet; `test.fixme` in priv/dev/e2e/uat.spec.mjs until a screen adopts the shells | deferred |
| e2e (Phase 14/15) | Notebook tab-switch e2e spec — blocked on `SRE.remote_invocation_evidence/1` (stub returns `%{approvals: []}`); `test.fixme` until real evidence is wired | deferred |
| Phase 13 (IA) | shots overlay capture: connectors `connector_drawer`/`runtime_drawer` (list renders empty in harness pass) + `prompt_release approve_modal` (no release link on `/prompts`) — see 11-HUMAN-UAT.md | deferred |
| Phase 11-evaluation-engine-seed-depth P01 | 90min | 2 tasks | 2 files |
| Phase 12-design-system-component-layer P01 | 3min | 2 tasks | 4 files |
| Phase 12-design-system-component-layer P02 | 8min | 2 tasks | 2 files |
| Phase 12-design-system-component-layer P03 | 10min | 2 tasks | 2 files |
| Phase 12 P04 | 3min | 2 tasks | 3 files |
| Phase 12-design-system-component-layer P05 | 17min | 3 tasks | 8 files |

## Operator Next Steps

- `/gsd:plan-phase 11` — plan the first v3.0 phase (evaluation engine + seed depth)
- Merge release-please PR when main CI green
