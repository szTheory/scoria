---
gsd_state_version: 1.0
milestone: v3.0
milestone_name: Control Room
status: executing
last_updated: "2026-06-12T18:16:21.305Z"
last_activity: 2026-06-12 -- Phase 14 Wave 2 complete
progress:
  total_phases: 20
  completed_phases: 3
  total_plans: 24
  completed_plans: 22
  percent: 15
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-11 — v2.17 Vesicle shipped and archived; v3.0 Control Room active)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 14 — least-iterated-screens-polish

## Current Position

Phase: 14 (least-iterated-screens-polish) — EXECUTING
Plan: 5 of 6
Status: Executing Phase 14 (4/6 plans complete; Wave 3 next)
Last activity: 2026-06-12 -- Phase 14 Wave 2 complete

## Roadmap (v3.0 Control Room, Phases 11–17)

1. **Phase 11 — Evaluation engine + seed depth** (EVAL-01..05) — `mix scoria.ui.shots` harness, 9-dim rubric, full-screen seed depth, baseline audit → gap register/fix backlog. **COMPLETE 2026-06-04**
2. **Phase 12 — Design-system component layer** (DS-01..06) — `ui.ex` table/drawer/modal/form/notebook/skeleton/toast, fix `flash_group`, raw-color drift guard. The enforced token gateway. **COMPLETE 2026-06-04**
3. **Phase 13 — Orientation spine (IA)** (IA-01..06) — nav active-state fix, third axis (Operate/Improve/Configure), Status Home, breadcrumbs, ⌘K palette + shortcuts, quality-loop threading, honest reserved-name stubs. **COMPLETE 2026-06-12**
4. **Phase 14 — Least-iterated screens polish** (SCREEN-01, SCREEN-02) — Review Queue / Incidents / Eval Workbench / Prompt Registry+Release conversions; real Dataset Builder index.
5. **Phase 15 — High-traffic screens + evidence adapters** (SCREEN-03, SCREEN-04) — Live Ops / Workflows / Approvals / Connectors polish; 13 evidence components → thin notebook adapters.
6. **Phase 16 — Motion + responsive + theme parity** (MOTION-01..04) — brand-tied motion, focus-visible/a11y, mobile-first md/lg/xl, light+dark parity.
7. **Phase 17 — Consistency sweep + proof** (PROOF-01..03) — re-run audit, rubric-delta + raw-color → 0, before/after contact sheets, MAINTAINERS.md catalog + harness usage.

## Performance Metrics

- **Current milestone:** `v3.0 Control Room` (resumed 2026-06-11 after v2.17 Vesicle interjection)
- **Latest Shipped:** `v2.17 Vesicle` (2026-06-11) — brand system, phases 18–22
- **Previous Shipped:** `v2.16 ReqLLM Peer Bump` (2026-05-30)
- **Hex release:** `0.1.1` prepared; publish via release-please pending CI green

## Accumulated Context

### Roadmap Evolution

- **v3.0 (resumed):** Control Room UI/IA/DX milestone. Phases 11–17. Phases 11–13 complete (Phase 13 completed 2026-06-12). Core finding: design system is under-*adopted* (~22/25 view files leak raw Tailwind). Paused at clean 12/13 boundary for v2.17 interjection; now resumed. Next: Phase 14 least-iterated screens polish.
- **v2.17 (shipped):** Brand system milestone. Interjected before v3.0 phases 13–17 because brand book was AI-generated seed, never pressure-tested, and no logo/collateral existed. Phases 18–22 (globally monotonic past v3.0's reserved 11–17 block). All 8 mandatory requirements satisfied; BRAND-09 conditional did not fire. Archived in `.planning/milestones/v2.17-*`.
- **v2.16 (shipped):** ReqLLM `~> 1.13` peer bump — minimal dependency hygiene scope.
- **v2.15 (shipped):** Named connector adoption lane — PR WAE after knowledge, not in closeout.

### Decisions

- [Phase 19-01]: opentype.js ^1.3.5 (1.x line) pinned for parse(ArrayBuffer)+Font.getPath API; wawoff2 CJS default import only; data-gap-ratio on lockup SVG root is machine-checkable LOGO-03 contract asserted by smoke.mjs and 19-03 — 2026-06-11
- [Phase 18-02]: propagation: not-required — CONFIRMED. --scoria-text-subtle sole shipped usage is ui.ex:653 (16x16 SVG sort icon, UI component context); WCAG 2.1 SC 1.4.11 ≥3:1 satisfied; assets/css/02-tokens.css untouched; BRAND-09 conditional does not fire — 2026-06-11
- [Phase 18-02]: Final tagline locked — "AI ops for Phoenix apps." (user override; audit-recommended verb triplet "Trace the run. Prove the change. Ship the agent." demoted to hero-headline treatment); one-liner tightened (nouns over gerunds); naming confirmed Scoria (never Scoria AI); palette deltas: none; typography IBM Plex Sans + JetBrains Mono confirmed KEEP — 2026-06-11
- [Phase 18-02]: Logo direction ranked — Trace Vesicle Mark #1, Cinder Mark #2 fallback; LOGO-01–07 hard constraints encoded for Phase 19 (no-rect, evenodd, tight lockup, no subtitle, integrated typemark first-class, 16px pass/fail, monochrome pass/fail) — 2026-06-11
- [Phase 18-01]: Propagation verdict presumption = not-required — 52 shipped pairings audited, 0 FAIL, 6 PASS-LARGE; pending 18-02 usage audit of --scoria-text-subtle in actual rendered text — 2026-06-11
- [Phase 18-01]: --scoria-text-subtle (#88786D Pumice-500) is PASS-LARGE (3.91–4.48:1 across surfaces); acceptable for muted UI labels/icons, prohibited for running body text — 2026-06-11
- [Phase 18-01]: Warning-light (#7A5A16 Sulfur) on Ash-50 = 5.87:1 PASS-AA; 18-CONTEXT known-risk flag was overcautious, no fix needed — 2026-06-11
- v2.17: `brandbook/` is canonical brand source; `assets/css/02-tokens.css` touched only on material audit failures (BRAND-09 conditional) — avoids thrash to v3.0 token gateway + DS-06 ratchet — 2026-06-11
- v2.17: Logo constraints locked — no rect backgrounds, evenodd holes, logotype optically tight to mark, no subtitle in main lockup, integrated type works motif INTO letterforms — 2026-06-11
- v2.17: User approval gates at end of Phase 18 (decisions lock) and Phase 19 (logo choice) — 2026-06-11
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
- [Phase ?]: Gate #2 partial: TV-1 mark locked; typemarks rejected; second round for lockup variations
- [Phase ?]: Gate #2 final: TV-1 mark + LK-B Mark-as-o lockup locked
- [Phase ?]: Primary lockup ships two-tone (ember/scoria 'o' accent); ink density 0.61 vs letters 0.57 confirms color carries the accent
- [Phase ?]: logotype-integrated.svg byte-identical to logo-monochrome.svg (LK-B fused lockup IS the integrated typemark)
- [Phase ?]: Phase 20 confirm: 8-variant logo set shipped as-is
- [Phase ?]: DASHBOARD-MARK scoped to brand_mark/1 body: function-body regex extraction isolates check from icon/1 circles (nav icons); file-wide check would false-FAIL

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
| v2.17 | BRAND-MOTION: brand-motion guidelines applied beyond dashboard (v3.0 Phase 16 scope) | deferred |
| v2.17 | BRAND-SITE: Marketing landing page / docs site build-out (brand book includes blueprints only) | deferred |
| Phase 11-evaluation-engine-seed-depth P01 | 90min | 2 tasks | 2 files |
| Phase 12-design-system-component-layer P01 | 3min | 2 tasks | 4 files |
| Phase 12-design-system-component-layer P02 | 8min | 2 tasks | 2 files |
| Phase 12-design-system-component-layer P03 | 10min | 2 tasks | 2 files |
| Phase 12 P04 | 3min | 2 tasks | 3 files |
| Phase 12-design-system-component-layer P05 | 17min | 3 tasks | 8 files |
| Phase 13 P01 | 4 min | 2 tasks | 4 files |
| Phase 13 P02 | 4 min | 2 tasks | 3 files |
| Phase 13 P03 | 3 min | 2 tasks | 4 files |
| Phase 13 P13-04 | 8 min | - tasks | - files |
| Phase 13 P13-05 | 10 min | - tasks | - files |
| Phase 13 P13-06 | 45 min | - tasks | - files |
| Phase 13 P13-07 | 6 min | - tasks | - files |
| Phase 13 P13-08 | 13 min | 2 tasks | 11 files |

## Operator Next Steps

- `/gsd:plan-phase 14` — plan Phase 14 (Least-iterated screens polish)
