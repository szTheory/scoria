# Roadmap: Scoria

**Last updated:** 2026-06-11 (milestone v2.17 Vesicle interjected; v3.0 Control Room paused)

## Milestones

- 🚧 **v2.17 Vesicle** — Phases 18–22 (brand system) — IN PROGRESS (interjected)
- ⏸ **v3.0 Control Room** — Phases 11–17 (admin dashboard UI/UX iteration) — PAUSED (resumes after v2.17)
- ✅ **v2.16 ReqLLM Peer Bump** — Phases 08–10 + 10.1 (shipped 2026-05-30) — [archive](milestones/v2.16-ROADMAP.md)
- ✅ **v2.15 Connector Adoption Lane** — Phases 05–07 + 07.1 (shipped 2026-05-30) — [archive](milestones/v2.15-ROADMAP.md)
- ✅ **v2.14 Maintenance Release** — `0.1.1` prep (shipped 2026-05-30)
- ✅ **v2.13 Adopter Docs Truth** — MAINTAINERS split, Hex metadata (shipped 2026-05-30)
- ✅ **v2.12 Adoption Confidence & Reference Demo** — Phases 02–04 (shipped 2026-05-30)

## Phases

### v2.17 Vesicle (Phases 18–22)

Brand system milestone. Pressure-test the AI-generated brand book, lock decisions, generate and choose a logo system programmatically, build the full variant set, author canonical brandbook/ collateral, and wire into README / dashboard / Hex copy. No net-new runtime capability. SVG/text-first; `brandbook/` becomes canonical; dashboard CSS touched only on material audit failures.

- [ ] **Phase 18: Pressure-test audit + decision lock** — 14-section brand-book pressure test → `brandbook/pressure-test.md`; WCAG contrast script in `brandbook/tools/`; suite-coherence vs Threadline + szTheory DNA; Decisions Locked section → **user approval gate #1**.
- [ ] **Phase 19: Logo divergence + user choice** — generation tooling in `brandbook/tools/` (faceted-polygon vesicle geometry, evenodd holes, opentype.js glyph outlines); ≥6 mark/lockup options + ≥2 integrated typemark studies; `options-gallery.html` (dark+light, 256/64/32/16px, monochrome, favicon/sidebar/README mocks) → **user choice gate #2** with ranked recommendation and second-round escape.
- [ ] **Phase 20: Logo convergence — full variant set** — chosen direction → `logo-primary.svg`, `logo-primary-light.svg`, `logo-mark.svg`, `logo-monochrome.svg`, `logo-lockup-subtitle.svg`, `logotype-integrated.svg`, `favicon.svg`, `social-card.svg`; clear-space/min-size spec; manual optical-correction pass; lightweight confirm checkpoint.
- [ ] **Phase 21: Tokens + brand book + standalone HTML** — `tokens.json` + `tokens.css` (naming reconciled with `assets/css/02-tokens.css`); `brand-book.md` post-audit rewrite; `examples/*.svg` ×7; professional standalone `index.html` (file:// offline-safe); `brandbook/README.md` maintenance rules.
- [ ] **Phase 22: Integration + final quality gate** — README header + badges (GitHub dark/light-aware); dashboard favicon + sidebar mark swap (`layouts.ex`); `mix.exs`/GitHub/HexDocs copy; conditional BRAND-09 token-propagation plan if Phase 18 verdict requires; scripted final quality gate (contrast AA, no-rect grep, evenodd check, <500KB + extension allowlist, offline `index.html`, hex-consistency, `mix test` green incl. DS-06).

---

### v3.0 Control Room (Phases 11–17) — PAUSED (resumes after v2.17)

UI/IA/DX milestone. No net-new backend capability families. Expose components → delete leaked classes → consolidate → orient → polish → prove. Sequenced for compounding reuse: primitives before screens, least-iterated screens before high-traffic, motion/responsive/theme last before the proof sweep.

- [x] **Phase 11: Evaluation engine + seed depth** — Committed `mix scoria.ui.shots` screenshot+critique harness, 9-dimension rubric, full-screen seed depth, baseline audit → gap register + fix backlog. (completed 2026-06-04)
- [x] **Phase 12: Design-system component layer** — Expose `ui.ex` table/drawer/modal/form/notebook/skeleton/toast components, fix `flash_group`, add executable raw-color drift guard. The enforced token gateway. (completed 2026-06-04)
- [ ] **Phase 13: Orientation spine (IA)** — Fix nav active-state, third nav axis (Operate/Improve/Configure), Status Home, breadcrumbs, ⌘K palette + shortcuts, cross-screen quality-loop threading, honest reserved-name stubs.
- [ ] **Phase 14: Least-iterated screens polish** — Review Queue / Incidents / Eval Workbench / Prompt Registry+Release conversions (zero raw-palette leakage); real Dataset Builder index.
- [ ] **Phase 15: High-traffic screens + evidence adapters** — Live Ops / Workflows / Approvals / Connectors polish; 13 evidence components as thin notebook-shell adapters.
- [ ] **Phase 16: Motion + responsive + theme parity** — Restrained brand-tied motion, focus-visible/a11y, mobile-first responsive across md/lg/xl, full light+dark parity.
- [ ] **Phase 17: Consistency sweep + proof** — Re-run audit loop, rubric-delta + raw-color count → 0, before/after contact sheets, MAINTAINERS.md catalog + harness usage.

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

### Phase 18: Pressure-test audit + decision lock
**Goal**: The brand book is validated — every section rated and tagged, accessibility checked programmatically, suite coherence assessed — and key brand decisions are locked with user approval before any asset generation begins.
**Depends on**: Nothing (first v2.17 phase)
**Requirements**: BRAND-01, BRAND-02
**Success Criteria** (what must be TRUE):
  1. A maintainer can read `brandbook/pressure-test.md` with all 14 sections tagged (KEEP/TIGHTEN/REWORK/ADD/REMOVE), a 1–10 scorecard across 15 dimensions, gaps ranked by severity, and surface stress-test notes (GitHub/HexDocs/dashboard/terminal/favicon/social).
  2. A runnable script in `brandbook/tools/` produces a WCAG-AA contrast verdict table for all documented token pairings; the table is embedded in `pressure-test.md`.
  3. The pressure test includes an explicit suite-coherence assessment vs the Threadline brandbook and `szTheory` DNA, and an explicit verdict on whether `assets/css/02-tokens.css` requires propagation.
  4. A Decisions Locked section records the final choices (tagline, palette/typography deltas if any, naming, propagation verdict), and the user has approved it at gate #1 before Phase 19 begins.
**Plans**: 2 plans
  - [ ] 18-01-PLAN.md — Contrast checker + pressure-test Sections 1-7 (exec judgment, brand DNA, 15-dim scorecard, stress tests, gaps, upgrades, token spec) with embedded WCAG table
  - [ ] 18-02-PLAN.md — Pressure-test Sections 8-14 (logo ranking + Phase-19 constraints, voice, blueprints, artifacts, actions, quality gate) + Decisions Locked + propagation verdict + gate #1 checkpoint
**Checkpoint**: Gate #1 — user approval of Decisions Locked section required before proceeding

### Phase 19: Logo divergence + user choice
**Goal**: The user can choose a logo direction from a gallery of genuinely distinct, programmatically generated options rendered at real usage sizes — with an explicit escape if none fits.
**Depends on**: Phase 18 (brand decisions locked before logo generation)
**Requirements**: BRAND-03
**Success Criteria** (what must be TRUE):
  1. Committed generation tooling in `brandbook/tools/` produces faceted-polygon vesicle silhouettes with evenodd-punched holes; a separate script outlines IBM Plex Sans glyphs via opentype.js for integrated typemark studies.
  2. `brandbook/options-gallery.html` presents ≥6 genuinely distinct mark+lockup options and ≥2 integrated logotype-only studies rendered on dark AND light grounds at 256/64/32/16px with a monochrome row.
  3. The gallery includes in-situ mocks: browser-tab favicon strip, 24px dashboard sidebar slot, and README header band.
  4. No option contains a rectangular background shape (enforced by geometry); all marks use `fill-rule="evenodd"`; logotype is optically tight to the mark; main lockup has no subtitle.
  5. The gallery includes a ranked recommendation and a documented "none of these → second round" escape path; the user's chosen direction is recorded before Phase 20 begins.
**Plans**: TBD (~3 plans)
**Checkpoint**: Gate #2 — user choice of logo direction required before proceeding

### Phase 20: Logo convergence — full variant set
**Goal**: The chosen direction becomes a complete, committed logo variant set ready for integration — with every usage context covered and optical quality verified.
**Depends on**: Phase 19 (user choice recorded)
**Requirements**: BRAND-04
**Success Criteria** (what must be TRUE):
  1. All eight variants are committed: `logo-primary.svg` (dark ground), `logo-primary-light.svg`, `logo-mark.svg`, `logo-monochrome.svg` (currentColor), `logo-lockup-subtitle.svg`, `logotype-integrated.svg`, `favicon.svg` (pixel-snapped simplified path), `social-card.svg`.
  2. Every variant has a tight viewBox, and `brandbook/brand-book.md` (or a companion spec) documents clear-space rules and minimum display sizes.
  3. A manual optical-correction pass has been applied: fills only (no strokes), baseline alignment confirmed, favicon path legible at 16px.
  4. A lightweight confirm checkpoint (screenshot strip) has been reviewed and accepted before Phase 21/22 integration work proceeds.
**Plans**: TBD (~2 plans)
**Checkpoint**: Lightweight confirm — screenshot strip review before proceeding

### Phase 21: Tokens + brand book + standalone HTML
**Goal**: `brandbook/` is a self-contained, professional canonical brand source — tokens, rewritten brand book, SVG specimens, and a standalone HTML brand book that opens offline.
**Depends on**: Phase 18 (decisions locked drive token reconciliation); can start non-logo plans in parallel with Phase 20
**Requirements**: BRAND-05, BRAND-06
**Success Criteria** (what must be TRUE):
  1. `brandbook/tokens.json` and `brandbook/tokens.css` are present with naming reconciled with `assets/css/02-tokens.css` so future propagation is mechanical.
  2. `brandbook/brand-book.md` is a post-audit rewrite with no filler — content aligned to KEEP/TIGHTEN/REWORK verdicts, accurate voice/copy guidance, and complete UI guidance sections.
  3. `brandbook/examples/` contains ≥7 SVG specimens covering: palette swatch sheet, typography scale, component reference, terminal/code block, readme-header, landing-hero, and docs-page.
  4. `brandbook/index.html` opens directly from `file://` with no load-bearing network dependencies, covers identity, logo system, color, typography, tokens, voice/microcopy, UI guidance, and landing/docs blueprints in a professional layout.
  5. `brandbook/` total size is < 500KB and contains only html/md/json/css/svg file types (zero binaries).
  6. `brandbook/README.md` documents maintenance rules for keeping the brandbook current.
**Plans**: TBD (~3 plans)
**UI hint**: yes

### Phase 22: Integration + final quality gate
**Goal**: The finalized brand is live on real surfaces and passes a scripted quality gate — no manual spot-checks; evidence is reproducible.
**Depends on**: Phase 20 (logo variants committed), Phase 21 (tokens + brand book complete)
**Requirements**: BRAND-07, BRAND-08, BRAND-09 (conditional)
**Success Criteria** (what must be TRUE):
  1. The README header uses the chosen lockup in a GitHub dark/light-aware `<picture>` block with an aligned badge row; the dashboard serves `favicon.svg` and displays the new mark in the 24px sidebar brand slot (`lib/scoria_web/components/layouts.ex`).
  2. `mix.exs` package description, GitHub repo description, and HexDocs front copy use the finalized brand voice.
  3. A scripted gate verifies: all documented fg/bg token pairs meet WCAG AA (≥4.5:1 normal / ≥3:1 large); no `<rect>` elements in any logo SVG (grep); all logo paths use `fill-rule="evenodd"`; `index.html` opens offline; `du -s brandbook/` < 500KB with extension allowlist; tokens.json ↔ tokens.css ↔ brand-book.md hex values consistent.
  4. `mix test` is green including the DS-06 raw-color drift guard baseline (untouched unless BRAND-09 conditional plan fired).
  5. If Phase 18 recorded a propagation verdict of "required": one atomic conditional plan has updated `assets/css/02-tokens.css`, the precompiled `priv/static` CSS, and `test/support/ds06_baseline.txt`, with no semantic custom-property renames and `mix test` green.
**Plans**: TBD (~2 plans + 1 conditional)

---

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
**Plans**: TBD
**UI hint**: yes

### Phase 14: Least-iterated screens polish
**Goal**: The least-iterated, highest-gain screens reach the rubric bar through shared components with zero raw-palette leakage, banking the biggest design-system deltas first.
**Depends on**: Phase 13 (orientation spine + components in place; threading targets exist)
**Requirements**: SCREEN-01, SCREEN-02
**Success Criteria** (what must be TRUE):
  1. Review Queue, Incidents, Eval Workbench, and Prompt Registry / Release Workbench render through shared components with zero raw-palette leakage and meet the rubric bar.
  2. A real Dataset Builder index is the canonical promote-to-dataset destination, converging the previously duplicated promote affordances.
**Plans**: TBD
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
| 18. Pressure-test audit + decision lock | v2.17 | 0/~2 | Not started | - |
| 19. Logo divergence + user choice | v2.17 | 0/~3 | Not started | - |
| 20. Logo convergence — full variant set | v2.17 | 0/~2 | Not started | - |
| 21. Tokens + brand book + standalone HTML | v2.17 | 0/~3 | Not started | - |
| 22. Integration + final quality gate | v2.17 | 0/~2 | Not started | - |
| 11. Evaluation engine + seed depth | v3.0 | 5/5 | Complete    | 2026-06-04 |
| 12. Design-system component layer | v3.0 | 5/5 | Complete    | 2026-06-04 |
| 13. Orientation spine (IA) | v3.0 | 0/? | Paused | - |
| 14. Least-iterated screens polish | v3.0 | 0/? | Paused | - |
| 15. High-traffic screens + evidence adapters | v3.0 | 0/? | Paused | - |
| 16. Motion + responsive + theme parity | v3.0 | 0/? | Paused | - |
| 17. Consistency sweep + proof | v3.0 | 0/? | Paused | - |
| 08 | v2.16 | — | Complete | 2026-05-30 |
| 09 | v2.16 | — | Complete | 2026-05-30 |
| 10 | v2.16 | — | Complete | 2026-05-30 |
| 10.1 | v2.16 | 1/1 | Complete | 2026-05-30 |

## Previous milestone archive

See `.planning/MILESTONES.md` for full closeout history.
