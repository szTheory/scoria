# Requirements: Scoria — v3.0 Control Room

**Defined:** 2026-06-03
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Milestone goal:** Take the embedded `/scoria` operator dashboard to "insane polish" — a fully-adopted design system, a clear persona/JTBD information architecture, brand-tied motion, full light/dark parity, and seed data that exercises every screen — proven by a committed screenshot+critique evaluation loop.

> UI/IA/DX milestone. No net-new backend capability families. Keep the custom token-first scoped CSS architecture; `lib/scoria_web/ui.ex` becomes the enforced token gateway.

## v1 Requirements

### Evaluation & Seed Depth

- [x] **EVAL-01**: A maintainer can run `mix scoria.ui.shots` to capture every dashboard screen across its state matrix (empty / populated / modal-open / drawer-open × light / dark × mobile / desktop) against the local dev server, gated on the existing `data-scoria-ready` sentinel.
- [x] **EVAL-02**: Captured screenshots can be critiqued against a 9-dimension rubric (brand-fit, consistency, hierarchy, affordance/least-surprise, accessibility, responsive, motion, microcopy, density) to produce structured per-screen findings.
- [x] **EVAL-03**: The screenshot + critique harness ships as committed dev-only tooling (not merge-blocking CI) with documented usage.
- [x] **EVAL-04**: `dev_seed.exs` populates every dashboard screen — Reviews, Incidents, Eval Workbench, and Prompt Registry included — so each renders at its most useful when clicked through.
- [x] **EVAL-05**: A baseline audit produces a ranked design-system gap register and a prioritized fix backlog.

### Design System Component Layer

- [x] **DS-01**: Operators see consistent tables across screens via a shared `<.table>` component supporting sort, filter/search, pagination, a density toggle, and a first-class empty state.
- [x] **DS-02**: Drawers and modals across screens use shared slot-based shells with consistent open/dismiss behavior.
- [x] **DS-03**: Forms (eval and prompt editors) use a shared form-control component set with consistent labelling and validation display.
- [x] **DS-04**: Evidence panels (trace, citation, semantic, replay, memory, delegated, remote-invocation) render through one unified notebook shell for visual consistency.
- [x] **DS-05**: Loading and transient feedback use shared skeleton and toast components, and `flash_group` routes through the token system with no raw-palette classes.
- [x] **DS-06**: An executable drift guard fails the build if any raw palette class (`stone-/rose-/sky-/emerald-/amber-/...`) appears under `lib/scoria_web/`.

### Information Architecture & Orientation

- [x] **IA-01**: Sidebar navigation is organized into three task-tempo groups (Operate / Improve / Configure) and the active screen is always reflected in the nav.
- [x] **IA-02**: A newcomer landing on the dashboard sees a Status Home that states what Scoria does and surfaces what needs attention now, with one-click paths to each persona's primary jobs — without adding a click for returning power users.
- [x] **IA-03**: Operators can orient on every screen via object-aware breadcrumbs.
- [x] **IA-04**: Power users can navigate to any screen or object and run key actions from a `⌘K` command palette and keyboard shortcuts.
- [x] **IA-05**: Related screens are threaded so the quality loop (incident → run → trace → replay → promote-to-dataset → eval → gate prompt release) is navigable without context loss.
- [x] **IA-06**: Reserved brand-name capabilities (Cost Ledger, Replay Playground, MCP Gateway, Tool Registry, Feedback Inbox) appear in the IA as honest "coming soon" screens with no fabricated data.

### Screen Polish

- [x] **SCREEN-01**: Review Queue, Incidents, Eval Workbench, and Prompt Registry / Release Workbench render through shared components with zero raw-palette leakage and meet the rubric bar.
- [x] **SCREEN-02**: A real Dataset Builder index is the canonical promote-to-dataset destination, converging the previously duplicated promote affordances.
- [ ] **SCREEN-03**: Live Ops, Workflows / Trace Explorer, Approvals, and Connectors render through shared components and meet the rubric bar; the home page's inline god-page buttons are replaced with design-system deep-links.
- [x] **SCREEN-04**: The evidence components are thin adapters over the unified notebook shell with no duplicated layout logic.

### Motion, Responsive & Theme Parity

- [ ] **MOTION-01**: Interactions carry restrained, brand-tied motion (origin-aware, ≤200ms, transform/opacity-only) that respects `prefers-reduced-motion` and avoids the brand antipatterns (fire/sparkle/bounce, infinite loops, layout-property animation).
- [ ] **MOTION-02**: Every interactive element has a visible focus-visible state and status is never conveyed by color alone.
- [ ] **MOTION-03**: The dashboard is usable mobile-first; the shell and tables adapt intentionally at the `md / lg / xl` breakpoints.
- [ ] **MOTION-04**: Every screen meets the polish bar in both light and dark themes, with WCAG AA contrast in both.

### Proof & Docs

- [ ] **PROOF-01**: A final audit shows rubric-score improvement (baseline → final) per screen and a raw-color-class count of zero.
- [ ] **PROOF-02**: Before/after contact sheets document the iteration as a basis for future passes.
- [ ] **PROOF-03**: `docs/MAINTAINERS.md` documents the design-system component catalog and how to run the screenshot harness.

## Future Requirements

Deferred to a later milestone (acknowledged, not in this roadmap).

- **FEAT-RESERVED**: Real backend + UI for the currently-stubbed reserved screens (Cost Ledger, Replay Playground, MCP Gateway, Tool Registry, Feedback Inbox) as those capabilities land.
- **IA-LENS**: Remembered soft "primary lens" persona preference on the Status Home (ship Status Home without it first; add if the static home proves insufficient).
- **CMDK-SEARCH**: Full-text object search in the command palette (v1 ships nav + recent objects + static actions).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Net-new runtime / eval / connector capabilities | This is a UI/IA/DX milestone; backend scope stays frozen. |
| Switching CSS architecture to real Tailwind or pure BEM | Keep momentum on the custom token-first scoped system; switching would invite override hell and discard the existing foundation. |
| Rewriting the token layer or `.scoria-root` scoping | The token SSOT is sound; the gap is adoption, not the tokens. |
| Browser tests in merge-blocking CI | Harness is dev-only, consistent with the repo's LiveViewTest-only posture. |
| Fake/seeded data for stubbed reserved screens | Violates brand voice ("evidence over intuition"); stubs say "not yet available". |
| Marketing landing page / docs site redesign | Covered separately by the brand book; out of dashboard scope. |

## Traceability

Each requirement maps to exactly one phase. Phase numbering continues from v2.16 (ended at Phase 10.1).

| Requirement | Phase | Status |
|-------------|-------|--------|
| EVAL-01 | Phase 11 — Evaluation engine + seed depth | Complete |
| EVAL-02 | Phase 11 — Evaluation engine + seed depth | Complete |
| EVAL-03 | Phase 11 — Evaluation engine + seed depth | Complete |
| EVAL-04 | Phase 11 — Evaluation engine + seed depth | Complete |
| EVAL-05 | Phase 11 — Evaluation engine + seed depth | Complete |
| DS-01 | Phase 12 — Design-system component layer | Complete |
| DS-02 | Phase 12 — Design-system component layer | Complete |
| DS-03 | Phase 12 — Design-system component layer | Complete |
| DS-04 | Phase 12 — Design-system component layer | Complete |
| DS-05 | Phase 12 — Design-system component layer | Complete |
| DS-06 | Phase 12 — Design-system component layer | Complete |
| IA-01 | Phase 13 — Orientation spine (IA) | Complete |
| IA-02 | Phase 13 — Orientation spine (IA) | Complete |
| IA-03 | Phase 13 — Orientation spine (IA) | Complete |
| IA-04 | Phase 13 — Orientation spine (IA) | Complete |
| IA-05 | Phase 13 — Orientation spine (IA) | Complete |
| IA-06 | Phase 13 — Orientation spine (IA) | Complete |
| SCREEN-01 | Phase 14 — Least-iterated screens polish | Complete |
| SCREEN-02 | Phase 14 — Least-iterated screens polish | Complete |
| SCREEN-03 | Phase 15 — High-traffic screens + evidence adapters | Pending |
| SCREEN-04 | Phase 15 — High-traffic screens + evidence adapters | Complete |
| MOTION-01 | Phase 16 — Motion + responsive + theme parity | Pending |
| MOTION-02 | Phase 16 — Motion + responsive + theme parity | Pending |
| MOTION-03 | Phase 16 — Motion + responsive + theme parity | Pending |
| MOTION-04 | Phase 16 — Motion + responsive + theme parity | Pending |
| PROOF-01 | Phase 17 — Consistency sweep + proof | Pending |
| PROOF-02 | Phase 17 — Consistency sweep + proof | Pending |
| PROOF-03 | Phase 17 — Consistency sweep + proof | Pending |

**Coverage:**
- v1 requirements: 28 total
- Mapped to phases: 28 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-03*
*Last updated: 2026-06-03 after v3.0 roadmap creation (phases 11–17)*
