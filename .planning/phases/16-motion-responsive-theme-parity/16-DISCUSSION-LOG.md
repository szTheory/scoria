# Phase 16: Motion + responsive + theme parity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 16-motion-responsive-theme-parity
**Areas discussed:** Mobile shell behavior, Responsive tables and dense evidence surfaces, Motion contract strictness, Parity verification level

---

## Mobile Shell Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Collapsible mobile drawer + compact sticky topbar | Preserve Phase 13 IA groups, keep content first, open existing nav groups from `Menu`, retain command palette and theme toggle. | yes |
| Horizontal top nav on narrow viewports | CSS-light approach with nav scrolling horizontally. | |
| Bottom nav for primary destinations + overflow menu | Mobile-app-like primary destination bar with hidden overflow for the rest. | |
| Content-first topbar + command palette only | Cleanest content viewport but relies on command palette for discovery/navigation. | |

**User's choice:** User asked to consider all gray areas with subagent-backed research and approved the synthesized recommendation set.
**Notes:** Recommendation selected collapsible drawer because Scoria is an embedded operator dashboard with too much IA for horizontal or bottom nav. Command palette remains additive, not the only navigation path.

---

## Responsive Tables and Dense Evidence Surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| Shared `<.table>` overflow viewport plus optional mobile summary slots | Centralize table responsiveness in `ui.ex`; preserve desktop table semantics; add opt-in mobile summaries where they improve scanability. | yes |
| Horizontal scroll only for all tables | Lowest-churn baseline preserving all columns. | |
| CSS-only stacked rows using `data-label`/block layout | Readable mobile rows but weaker comparison semantics and more header duplication. | |
| Per-screen custom mobile layouts/drawers | Best bespoke UX but high drift and mobile-only bug risk. | |

**User's choice:** User asked for one cohesive recommendation and approved the synthesized set.
**Notes:** Recommendation selected shared component behavior with opt-in summaries. Per-screen forks are reserved for true object inspectors, not shared table surfaces.

---

## Motion Contract Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Absolute strict contract | Everything <=200ms, transform/opacity-only, no loops or color/border/shadow transitions. | |
| Strict interaction contract + named state-indicator exceptions | User-triggered motion stays tight; skeleton and finite attention pulse are allowlisted exceptions. | yes |
| Permissive CSS motion | Keep current broader transitions as long as reduced motion works. | |
| Richer LiveView/JS animation layer | Add more JS-driven choreography and route/interaction animation. | |

**User's choice:** User asked for one cohesive recommendation and approved the synthesized set.
**Notes:** Recommendation selected strict interactions with allowlisted state indicators. This keeps the UI calm and auditable without making loading and approval attention states visually dead.

---

## Parity Verification Level

| Option | Description | Selected |
|--------|-------------|----------|
| Leave proof to Phase 17 | Manual Phase 16 spot checks, broad proof later. | |
| Targeted Phase 16 parity smoke checks | Use existing Playwright lane for 375px overflow, focus-visible, reduced-motion, and theme-toggle checks. | yes |
| Token contrast checker plus narrow browser smoke | Add deterministic contrast floor if it reuses token truth. | yes, conditional |
| Full axe/all-screen/theme/viewport CI scan | Broad automated browser accessibility matrix. | |
| Visual-regression screenshots in CI | Commit screenshot baselines and compare in CI. | |

**User's choice:** User approved targeted Phase 16 smoke checks, with token contrast guard only if it can reuse existing token/brandbook truth.
**Notes:** Recommendation keeps Phase 17 as the final broad proof owner and avoids brittle visual-regression CI in Phase 16.

---

## Agent's Discretion

- Exact component APIs for mobile table summaries.
- Exact CSS class names and whether responsive gaps are solved with scoped component classes or a small supported utility expansion.
- Exact motion guard implementation and allowlist encoding.
- Exact Playwright selector list and representative screen set for parity smoke checks.
- Plan slicing and ordering.

## Deferred Ideas

- Dedicated mobile responder mode, bottom navigation, or mobile persona lens.
- Full command-palette object search.
- Full axe/all-screen/theme/viewport browser accessibility lane.
- CI visual regression screenshot baselines.
- Phase 17 final contact sheets, final audit deltas, and maintainer docs.
