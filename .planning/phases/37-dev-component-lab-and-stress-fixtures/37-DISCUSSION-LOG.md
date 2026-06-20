# Phase 37: Dev Component Lab And Stress Fixtures - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-20
**Phase:** 37-Dev Component Lab And Stress Fixtures
**Areas discussed:** Lab access boundary, State matrix shape, Fixture ownership, Proof and docs shape, UI/JTBD/brand lens

---

## Lab Access Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Dev harness route under `dev/` | Mount `/scoria/_lab` only from `ScoriaWeb.DevRouter`; compile only in `:dev`; exclude from Hex; no public macro change. | yes |
| Dev-only PhoenixStorybook | Add PhoenixStorybook as a dev dependency and story surface. Mature, but adds dependency/setup and conflicts with first-pass repo-local decision. | |
| Public `scoria_dashboard/2` option | Let host apps opt into the lab. Convenient, but changes public API, risks production exposure, and expands Hex/runtime footprint. | |
| Static/generated artifact | Generate HTML/contact-sheet style artifacts under `priv/dev`. Isolated, but weaker LiveView/JS/focus fidelity. | |

**User's choice:** Discuss all and produce a one-shot researched recommendation.
**Notes:** Recommendation is the existing dev harness route. Keep the lab out of public dashboard mount behavior, package files, public nav, and adopter docs. PhoenixStorybook stays deferred.

---

## State Matrix Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Component-first catalog | Best ownership model for `ScoriaWeb.UI` primitives and Phoenix `attr`/`slot` contracts, but can miss flow-level failures. | |
| Stress-scenario-first wall | Makes ugly data, dense UI, theme, motion, and responsive failures obvious, but ownership can get muddy. | |
| Operator-flow-first lab pages | Catches real cross-component workflow issues, but risks becoming a second dashboard and is too broad for Phase 37. | |
| Hybrid inventory-driven catalog | Component-first spine, reusable stress bands, and a few flow probes tied to Phase 36 inventory/risk IDs. | yes |

**User's choice:** Discuss all and produce a cohesive recommendation.
**Notes:** Recommendation is the hybrid. The Phase 36 inventory gives the lab its spine; reusable state bands cover normal/long/empty/dense/disabled/selected/loading/warning/danger/error; curated probes cover overlays, toast region, mobile tables/lists, copy controls, and raw evidence.

---

## Fixture Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Static dev fixture catalog | Deterministic HEEx-safe maps/fixtures for component states and ugly data; diffable and DB-free. | yes |
| `priv/repo/dev_seed.exs` projection | Real DB-backed dashboard data for page screenshots/click-throughs; good for associations and real IDs. | yes as projection only |
| Generated scenarios from `36-inventory.json` | Good for coverage alignment, but too shallow for rich domain data. | yes as coverage anchor only |
| Test/support factories | Idiomatic for ExUnit setup, but not automatically available to dev/runtime and can hide too much setup. | |

**User's choice:** Discuss all and produce a researched recommendation.
**Notes:** Recommendation is a hybrid: static dev-only fixture catalog owns component-lab data; `dev_seed` remains the DB-backed page projection; `36-inventory.json` provides coverage IDs; test fixtures may inform tests but should not couple the lab to test-only helpers.

---

## Proof And Docs Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Focused route/state/package guards | Prove the lab loads locally, remains dev-only, covers required states/domains, and does not ship publicly. | yes |
| Broad screenshot-diff CI | Strong visual regression signal if deterministic, but too brittle/noisy for Phase 37 and already deferred. | |
| Advisory Playwright/browser proof | Useful for theme, reduced motion, overlays, focus, mobile scan, copy controls, and lab ready-state. | yes |
| Docs-only lab | Low implementation cost, but fails LAB-01/LAB-02 and does not reveal real UI failures. | |

**User's choice:** Discuss all and produce a researched recommendation.
**Notes:** Recommendation is focused proof plus maintainer docs. Screenshot diffs remain deferred to Phase 41/`VISUAL-CI-01`.

---

## UI/JTBD/Brand Lens

| Option | Description | Selected |
|--------|-------------|----------|
| Operator dashboard clone | Uses familiar dashboard IA, but confuses production operators with maintainer inspection jobs. | |
| Storybook-style gallery | Familiar for component demos, but risks happy-path beauty over failure finding. | |
| Field-engineer component workshop | Maintainer-oriented bench/evidence notebook for primitives, groups, fixtures, stress states, and proof. | yes |

**User's choice:** Discuss all and produce a researched recommendation.
**Notes:** Recommendation is a field-engineer workshop. Primary persona is the maintainer improving shared UI; secondary is the contributor choosing canonical patterns; tertiary is the verifier using deterministic proof. Brand direction remains grounded, composed, operator-grade, evidence-led, Phoenix-native, dark/light/system safe, and not generic AI SaaS.

---

## Claude's Discretion

- Exact module names, path names, and fixture file layout may be chosen by downstream planner/executor if they preserve the decisions in `37-CONTEXT.md`.
- Prefer simple internal modules and explicit coverage checks over a custom DSL.

## Deferred Ideas

- PhoenixStorybook adoption after local lab insufficiency is proven.
- Screenshot-diff CI after Phase 41 determines the screenshot harness is deterministic enough.
- Actual approval toast legibility fix in Phase 38.
- Actual approval decision history in Phase 39.
- CI cache-key and Docker fleet follow-ups remain outside v3.3 Phase 37.
