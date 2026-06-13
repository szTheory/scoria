# Roadmap: Scoria

**Last updated:** 2026-06-12 (Phase 13 Orientation spine completed; v3.0 Control Room active)

## Milestones

- 🚧 **v3.0 Control Room** — Phases 11–17 (admin dashboard UI/UX iteration) — IN PROGRESS
- ✅ **v2.17 Vesicle** — Phases 18–22 (brand system, interjected) — SHIPPED 2026-06-11 — [archive](milestones/v2.17-ROADMAP.md)
- ✅ **v2.16 ReqLLM Peer Bump** — Phases 08–10 + 10.1 (shipped 2026-05-30) — [archive](milestones/v2.16-ROADMAP.md)
- ✅ **v2.15 Connector Adoption Lane** — Phases 05–07 + 07.1 (shipped 2026-05-30) — [archive](milestones/v2.15-ROADMAP.md)
- ✅ **v2.14 Maintenance Release** — `0.1.1` prep (shipped 2026-05-30)
- ✅ **v2.13 Adopter Docs Truth** — MAINTAINERS split, Hex metadata (shipped 2026-05-30)
- ✅ **v2.12 Adoption Confidence & Reference Demo** — Phases 02–04 (shipped 2026-05-30)

## Phases

### v3.0 Control Room (Phases 11–17)

UI/IA/DX milestone. No net-new backend capability families. Expose components → delete leaked classes → consolidate → orient → polish → prove. Sequenced for compounding reuse: primitives before screens, least-iterated screens before high-traffic, motion/responsive/theme last before the proof sweep.

- [x] **Phase 11: Evaluation engine + seed depth** — Committed `mix scoria.ui.shots` screenshot+critique harness, 9-dimension rubric, full-screen seed depth, baseline audit → gap register + fix backlog. (completed 2026-06-04)
- [x] **Phase 12: Design-system component layer** — Expose `ui.ex` table/drawer/modal/form/notebook/skeleton/toast components, fix `flash_group`, add executable raw-color drift guard. The enforced token gateway. (completed 2026-06-04)
- [x] **Phase 13: Orientation spine (IA)** — Fix nav active-state, third nav axis (Operate/Improve/Configure), Status Home, breadcrumbs, ⌘K palette + shortcuts, cross-screen quality-loop threading, honest reserved-name stubs. (completed 2026-06-12)
- [x] **Phase 14: Least-iterated screens polish** — Review Queue / Incidents / Eval Workbench / Prompt Registry+Release conversions (zero raw-palette leakage); real Dataset Builder index.
- [ ] **Phase 15: High-traffic screens + evidence adapters** — Live Ops / Workflows / Approvals / Connectors polish; 13 evidence components as thin notebook-shell adapters.
- [ ] **Phase 16: Motion + responsive + theme parity** — Restrained brand-tied motion, focus-visible/a11y, mobile-first responsive across md/lg/xl, full light+dark parity.
- [ ] **Phase 17: Consistency sweep + proof** — Re-run audit loop, rubric-delta + raw-color count → 0, before/after contact sheets, MAINTAINERS.md catalog + harness usage.

<details>
<summary>✅ v2.17 Vesicle (Phases 18–22) — SHIPPED 2026-06-11</summary>

- [x] Phase 18: Pressure-test audit + decision lock — gate #1 approved 2026-06-11 (tagline override "AI ops for Phoenix apps."; propagation: not-required) — completed 2026-06-11
- [x] Phase 19: Logo divergence + user choice — gate #2 (2 rounds): TV-1 "Span rail" mark + LK-B "Mark-as-o" fused lockup locked — completed 2026-06-11
- [x] Phase 20: Logo convergence — full variant set — 8 root variants, user confirmed "ship it" — completed 2026-06-11
- [x] Phase 21: Tokens + brand book + standalone HTML — tokens.json/css, brand-book.md 543 lines, 7 examples, index.html 55 KB — completed 2026-06-11
- [x] Phase 22: Integration + final quality gate — quality-gate.mjs 8/8 PASS, 458 KB, mix test 632 green, DS-06 untouched — completed 2026-06-11

Full details: `.planning/milestones/v2.17-ROADMAP.md`

</details>

<details>
<summary>✅ v2.16 ReqLLM Peer Bump (Phases 08–10 + 10.1) — SHIPPED 2026-05-30</summary>

- [x] Phase 08: Bump ReqLLM constraint and lockfile — completed 2026-05-30
- [x] Phase 09: Compatibility fixes and test verification — completed 2026-05-30
- [x] Phase 10: CI lane verification and closeout — completed 2026-05-30
- [x] Phase 10.1: VERIFICATION gap closeout (INSERTED) — 1/1 plan — completed 2026-05-30

Full details: `.planning/milestones/v2.16-ROADMAP.md`

</details>

<details>
<summary>✅ v2.15 Connector Adoption Lane (Phases 05–07 + 07.1) — SHIPPED 2026-05-30</summary>

- [x] Phase 05: Lane contract + Mix task — completed 2026-05-30
- [x] Phase 06: Integration proof + SupportJourney alignment — completed 2026-05-30
- [x] Phase 07: Docs, drift guards, CI wiring — completed 2026-05-30
- [x] Phase 07.1: VERIFICATION gap closeout (INSERTED) — 1/1 plan — completed 2026-05-30

Full details: `.planning/milestones/v2.15-ROADMAP.md`

</details>

## Phase Details

### Phase 11: Evaluation engine + seed depth
**Goal**: A maintainer can mechanically capture and critique every dashboard screen, and every screen renders at its most useful — establishing the proof loop every later phase re-runs.
**Depends on**: Nothing (foundation phase)
**Requirements**: EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05
**Success Criteria** (what must be TRUE):
  1. A maintainer can run `mix scoria.ui.shots` and get screenshots of every screen across its state matrix (empty / populated / modal-open / drawer-open × light / dark × mobile / desktop), gated on the `data-scoria-ready` sentinel.
  2. Captured screenshots can be critiqued against the 9-dimension rubric (brand-fit, consistency, hierarchy, affordance, a11y, responsive, motion, microcopy, density) to produce structured per-screen findings.
  3. The harness is committed as dev-only tooling (not merge-blocking CI) with documented usage.
  4. Clicking through Reviews, Incidents, Eval Workbench, and Prompt Registry shows populated, useful content from `dev_seed.exs` — no empty/thin screens.
  5. A baseline audit produces a ranked design-system gap register and a prioritized fix backlog.
**Plans**: 5 plans
  - [x] 11-01-PLAN.md — Seed depth: idempotent dev_seed.exs populating all 9 screens (EVAL-04)
  - [x] 11-02-PLAN.md — UICritique module + 9-key findings-JSON unit test (EVAL-02)
  - [x] 11-03-PLAN.md — Harness: scoria.ui.shots Mix task + Playwright shots.mjs (EVAL-01)
  - [x] 11-04-PLAN.md — Hex hygiene (package.files) + gitignore + MAINTAINERS docs (EVAL-03)
  - [x] 11-05-PLAN.md — Baseline audit: render + commit ranked gap register (EVAL-05)
**UI hint**: yes

### Phase 12: Design-system component layer
**Goal**: `ui.ex` exposes the components the CSS already supports, becoming the enforced token gateway so screen polish becomes "delete bespoke markup, call a component" — and raw-palette drift cannot return.
**Depends on**: Phase 11 (gap register prioritizes which components matter most)
**Requirements**: DS-01, DS-02, DS-03, DS-04, DS-05, DS-06
**Success Criteria** (what must be TRUE):
  1. Operators see consistent tables via a shared `<.table>` supporting sort, filter/search, pagination, density toggle, and a first-class empty state.
  2. Drawers and modals across screens use shared slot-based shells with consistent open/dismiss behavior.
  3. Forms (eval and prompt editors) use a shared form-control set with consistent labelling and validation display.
  4. Evidence panels render through one unified `<.notebook>` shell, and loading/transient feedback use shared skeleton and toast components with `flash_group` routed through the token system (no raw-palette classes).
  5. The build fails if any raw palette class (`stone-/rose-/sky-/emerald-/amber-/...`) appears under `lib/scoria_web/`.
**Plans**: 5 plans
  - [x] 12-01-PLAN.md — Wave 0: net-new CSS + skeleton keyframe + DS-06 guard & component-test scaffolds
  - [x] 12-02-PLAN.md — ui.ex: flash_group semantic fix (zeroes ui.ex) + `<.table>` (DS-05, DS-01)
  - [x] 12-03-PLAN.md — ui.ex: `<.drawer>`/`<.modal>` + `<.field>`/`<.form_section>` (DS-02, DS-03)
  - [x] 12-04-PLAN.md — ui.ex: `<.notebook>` shell + `<.skeleton>` + `<.toast>` (DS-04, DS-05)
  - [x] 12-05-PLAN.md — Real toast + real skeleton wiring + notebook proof adapter + commit DS-06 baseline (DS-05, DS-04, DS-06)
**UI hint**: yes

### Phase 13: Orientation spine (IA)
**Goal**: A newcomer dropped on the dashboard immediately understands what Scoria does and how to reach their job, while a returning power user keeps a zero-click path — the screens stop feeling like disjoint islands.
**Depends on**: Phase 12 (Status Home, palette, breadcrumbs, and stubs are built from shared components)
**Requirements**: IA-01, IA-02, IA-03, IA-04, IA-05, IA-06
**Success Criteria** (what must be TRUE):
  1. The sidebar is organized into Operate / Improve / Configure groups and the active screen is always reflected in the nav (active-state bug fixed).
  2. A newcomer landing on the dashboard sees a Status Home that states what Scoria does and surfaces what needs attention now, with one-click paths to each persona's primary jobs — without adding a click for returning power users.
  3. Operators can orient on every screen via object-aware breadcrumbs.
  4. Power users can navigate to any screen or object and run key actions from a `⌘K` command palette and keyboard shortcuts.
  5. Related screens are threaded so the quality loop (incident → run → trace → replay → promote-to-dataset → eval → gate prompt release) is navigable without context loss, and reserved brand-name capabilities (Cost Ledger, Replay Playground, MCP Gateway, Tool Registry, Feedback Inbox) appear as honest "coming soon" screens with no fabricated data.
**Plans**: 8 plans
  - [x] 13-01-PLAN.md — Shared IA UI primitives for attention cards, object headers, command palette, and stubs
  - [x] 13-02-PLAN.md — DashboardNav grouped SSOT, Home relabel, active-state fix, and Soon nav metadata
  - [x] 13-03-PLAN.md — Shared coming-soon route and honest reserved capability stub pages
  - [x] 13-04-PLAN.md — Status Home at `/` with attention strip and preserved live run stream
  - [x] 13-05-PLAN.md — Object-aware headers and allowlisted origin context on object pages
  - [x] 13-06-PLAN.md — Command palette, recents, keyboard shortcuts, and automated browser checkpoint
  - [x] 13-07-PLAN.md — Incident and Review Queue ingress threading into run evidence
  - [x] 13-08-PLAN.md — Run and Prompt Release Workbench egress threading through quality-loop verbs
**UI hint**: yes

### Phase 14: Least-iterated screens polish
**Goal**: The least-iterated, highest-gain screens reach the rubric bar through shared components with zero raw-palette leakage, banking the biggest design-system deltas first.
**Depends on**: Phase 13 (orientation spine + components in place; threading targets exist)
**Requirements**: SCREEN-01, SCREEN-02
**Success Criteria** (what must be TRUE):
  1. Review Queue, Incidents, Eval Workbench, and Prompt Registry / Release Workbench render through shared components with zero raw-palette leakage and meet the rubric bar.
  2. A real Dataset Builder index is the canonical promote-to-dataset destination, converging the previously duplicated promote affordances.
**Plans**: 6 plans
  - [x] 14-01-PLAN.md - Dataset Builder route, navigation, and real index shell (SCREEN-02)
  - [x] 14-02-PLAN.md - Dataset Builder promotion reconstruction and PromoteComponent conversion (SCREEN-02)
  - [x] 14-03-PLAN.md - Review Queue shared-component conversion and Dataset Builder promotion ingress (SCREEN-01, SCREEN-02)
  - [x] 14-04-PLAN.md - Incidents screen and IncidentEvidenceComponent conversion (SCREEN-01)
  - [x] 14-05-PLAN.md - Eval Workbench shared-component conversion (SCREEN-01)
  - [x] 14-06-PLAN.md - Prompt Registry and Release Workbench conversion (SCREEN-01)
**UI hint**: yes

### Phase 15: High-traffic screens + evidence adapters
**Goal**: The high-traffic screens reach the rubric bar through shared components, and the scattered evidence components collapse into thin notebook-shell adapters with no duplicated layout logic.
**Depends on**: Phase 14 (component patterns proven on least-iterated screens first)
**Requirements**: SCREEN-03, SCREEN-04
**Success Criteria** (what must be TRUE):
  1. Live Ops, Workflows / Trace Explorer, Approvals, and Connectors render through shared components and meet the rubric bar; the home page's inline god-page buttons are replaced with design-system deep-links.
  2. The evidence components are thin adapters over the unified notebook shell with no duplicated layout logic.
**Plans**: TBD
**UI hint**: yes

### Phase 16: Motion + responsive + theme parity
**Goal**: Every screen meets the polish bar in both light and dark themes, with restrained brand-tied motion and intentional mobile-first responsive behavior.
**Depends on**: Phase 15 (all screens converted to shared components before the cross-cutting sweep)
**Requirements**: MOTION-01, MOTION-02, MOTION-03, MOTION-04
**Success Criteria** (what must be TRUE):
  1. Interactions carry restrained, brand-tied motion (origin-aware, ≤200ms, transform/opacity-only) that respects `prefers-reduced-motion` and avoids the brand antipatterns (fire/sparkle/bounce, infinite loops, layout-property animation).
  2. Every interactive element has a visible focus-visible state and status is never conveyed by color alone.
  3. The dashboard is usable mobile-first; the shell and tables adapt intentionally at the `md / lg / xl` breakpoints.
  4. Every screen meets the polish bar in both light and dark themes, with WCAG AA contrast in both.
**Plans**: TBD
**UI hint**: yes

### Phase 17: Consistency sweep + proof
**Goal**: The iteration is proven and documented — a final audit shows measurable improvement, raw-color count reaches zero, and maintainers can re-run the loop.
**Depends on**: Phase 16 (proof runs against the fully-polished, motion-and-parity-complete dashboard)
**Requirements**: PROOF-01, PROOF-02, PROOF-03
**Success Criteria** (what must be TRUE):
  1. A final audit shows rubric-score improvement (baseline → final) per screen and a raw-color-class count of zero.
  2. Before/after contact sheets document the iteration as a basis for future passes.
  3. `docs/MAINTAINERS.md` documents the design-system component catalog and how to run the screenshot harness.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 11. Evaluation engine + seed depth | v3.0 | 5/5 | Complete    | 2026-06-04 |
| 12. Design-system component layer | v3.0 | 5/5 | Complete    | 2026-06-04 |
| 13. Orientation spine (IA) | v3.0 | 8/8 | Complete    | 2026-06-12 |
| 14. Least-iterated screens polish | v3.0 | 5/6 | In Progress|  |
| 15. High-traffic screens + evidence adapters | v3.0 | 5/5 | Complete   | 2026-06-13 |
| 16. Motion + responsive + theme parity | v3.0 | 0/? | Not started | - |
| 17. Consistency sweep + proof | v3.0 | 0/? | Not started | - |
| 18. Pressure-test audit + decision lock | v2.17 | 2/2 | Complete | 2026-06-11 |
| 19. Logo divergence + user choice | v2.17 | 3/3 | Complete | 2026-06-11 |
| 20. Logo convergence — full variant set | v2.17 | 2/2 | Complete | 2026-06-11 |
| 21. Tokens + brand book + standalone HTML | v2.17 | 3/3 | Complete | 2026-06-11 |
| 22. Integration + final quality gate | v2.17 | 2/2 | Complete | 2026-06-11 |
| 08 | v2.16 | — | Complete | 2026-05-30 |
| 09 | v2.16 | — | Complete | 2026-05-30 |
| 10 | v2.16 | — | Complete | 2026-05-30 |
| 10.1 | v2.16 | 1/1 | Complete | 2026-05-30 |

## Previous milestone archive

See `.planning/MILESTONES.md` for full closeout history.
