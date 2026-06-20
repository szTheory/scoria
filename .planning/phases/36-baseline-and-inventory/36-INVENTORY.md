# Phase 36 Baseline And Inventory

**Created:** 2026-06-20
**Milestone:** v3.3 Design System Stress Test
**Purpose:** Baseline truth and inventory contract for the Scoria admin/operator UI.

## Baseline Truth

Phase 36 starts from the recent `/scoria` UI cleanup as committed prior art, before v3.3 planning work.

Cleanup commits that precede v3.3 planning:

- `1773267`
- `d35906f`
- `4337c5e`
- `452f035`
- `2d324a0`
- `f490cea` (`ui: consolidate scoria control room patterns`)

v3.3 planning begins at `8540e04` and the current lineage is visible in `git log --oneline -12`.

Existing baseline proof is reused rather than reinvented:

- `test/scoria_web/ui_component_test.exs`
- `test/scoria_web/ds06_drift_guard_test.exs`
- `priv/dev/e2e/`
- `mix scoria.ui.shots`
- `priv/shots/gap_register.md`
- `priv/shots/gap_register_final.md`

Screenshots are advisory baseline evidence only. Phase 36 does not create screenshot-diff CI, does not promote screenshots into a required merge gate, and treats v3.0 proof gaps as inventory risks rather than automatic regressions. Those gaps are tracked centrally as `RISK-V30-PROOF`.

## Artifact Contract

Phase 36 produces Markdown plus JSON artifacts per D-01. The artifacts are repository-local per D-02 and intentionally boring: no PhoenixStorybook install, no runtime component lab, no new package, and no `/scoria` runtime UI change.

The Markdown file owns rationale, baseline proof, source scope, taxonomy explanation, exclusions, and the maintainer-readable risk summary. The structured companion file, `36-inventory.json`, owns canonical row IDs, canonical `layer` and `status` fields, row evidence, owner paths, and risk references. This avoids duplicate source-of-truth drift per D-04: prose may summarize rows, but JSON row fields are canonical.

Required JSON metadata fields:

- `generated_at`
- `git_sha`
- `phase`
- `scope`
- `schema_version`
- `layer_enum`
- `status_enum`
- `required_row_fields`
- `baseline`
- `rows`
- `risks`

Required inventory row fields:

- `id`
- `name`
- `layer`
- `status`
- `owner_path`
- `evidence`
- `replacement_or_owner`
- `next_action`
- `risk_refs`

Required risk fields:

- `risk_id`
- `title`
- `affected_jtbd_persona_operator_flow`
- `affected_inventory_refs`
- `owner_phase`
- `mitigation_evidence_target`
- `status`
- `closeout_proof`

## Source Scope

Phase 36 inventories existing Scoria surfaces without changing them:

- Foundations: `brandbook/`, `assets/css/01-reset.css`, `assets/css/02-tokens.css`, `assets/css/03-base.css`, `assets/css/04-components.css`, `assets/css/05-motion.css`, `assets/css/06-utilities.css`
- Primitives: `lib/scoria_web/ui.ex`
- Component groups: `lib/scoria_web/components/`
- Pages and flows: `lib/scoria_web/live/`, dashboard layouts, router-derived `/scoria` surfaces
- Hooks and browser interop: `assets/js/scoria.js`
- Fixtures and proof: `test/scoria_web/`, `priv/dev/e2e/`, `priv/dev/shots.mjs`, `lib/mix/tasks/scoria.ui.shots.ex`
- Docs and proof records: `docs/MAINTAINERS.md`, `docs/uat_automation.md`, `priv/shots/gap_register.md`, `priv/shots/gap_register_final.md`

The structured index uses repository-relative paths and commit/test references only. It must not paste secrets, local environment contents, private screenshot data, or unrelated local evidence.

## Classification Rules

Every row has exactly one `layer` value:

- `foundation`
- `primitive`
- `component-group`
- `page`
- `hook`
- `fixture`
- `test`
- `doc`
- `one-off`

Every row has exactly one `status` value:

- `canonical`
- `duplicated`
- `legacy`
- `missing`
- `intentionally-page-specific`

Classification guidance:

- `canonical`: clear owner, stable API/token/route contract, representative usage, and appropriate tests or docs for the layer.
- `duplicated`: two or more items solve the same UI job; cite call sites and identify the preferred consolidation target.
- `legacy`: still used but superseded; include the migration target.
- `missing`: repeated code, repeated copy, repeated tests, or documented needs imply an absent abstraction, state, fixture, proof, or doc.
- `intentionally-page-specific`: tied to a named LiveView/page workflow where extraction would leak domain context or reduce clarity.

Phoenix ownership boundaries stay explicit. Function components with `attr`/`slot` contracts are the preferred primitive shape. LiveComponents are for stateful component behavior. JS hooks are for browser interop that `Phoenix.LiveView.JS` and server-rendered LiveView cannot cover cleanly. CSS remains token-scoped through the Scoria design system.

## Known Risk Register

The canonical risk rows live in `36-inventory.json`. This Markdown section summarizes the central register only: later phases that touch a row with `risk_refs` must mitigate the risk, prove it unchanged, or explicitly defer it with evidence.

| Risk | Owner Phase | Summary |
|------|-------------|---------|
| `RISK-V30-PROOF` | 41 | Stale v3.0 proof gaps and partial verification-doc coverage stay visible as proof work, not automatic UI regressions. |
| `RISK-TOAST-LEGIBILITY` | 38 | Approval warning/error toast readability over dense UI, folded from `.planning/todos/pending/2026-06-18-make-approval-toasts-legible.md`. |
| `RISK-APPROVAL-HISTORY` | 39 | Discoverability of approved, denied, and expired approvals without implying in-place reversal, folded from `.planning/todos/pending/2026-06-20-add-approval-decision-history.md`. |
| `RISK-RESPONSIVE-SCAN` | 40 | Responsive tables/lists and mobile scan paths must remain usable at narrow widths. |
| `RISK-OVERLAY-FOCUS` | 40 | Drawers, modals, command palette, mobile nav, focus restoration, escape behavior, reduced motion, and theme parity remain cross-cutting proof risks. |

Phase 36 keeps Scoria's operator-first embedded-library posture: repo-local artifacts, Phoenix-native proof, Mix-task evidence, Ecto/Phoenix/LiveView boundaries, no hidden hosted-service assumptions, and no runtime dependency expansion. Brandbook ownership remains canonical for tone and visual direction. Inventory `next_action` text should stay design-pillar-aware: accessibility, responsive behavior, theme parity, motion/reduced motion, performance and render stability, information hierarchy, affordance clarity, density/scannability, microcopy, evidence discoverability, keyboard/focus behavior, and brand fit.

## Excluded From Phase 36

Phase 36 does not:

- Install packages.
- Add PhoenixStorybook.
- Add a runtime component lab.
- Change `/scoria` runtime UI.
- Change source files, tests, fixtures, routes, or CSS.
- Create screenshot-diff CI.
- Implement approval toast legibility fixes.
- Implement approval decision history.
- Change approval semantics.
- Broaden into CI cache-key cleanup or sibling-repo Docker fleet work.

## Phase 37+ Gate

No later v3.3 UI implementation phase should start until this Markdown artifact and `36-inventory.json` both exist and parse. Downstream defaults are operator-first, Phoenix-native, brandbook-aligned, design-pillar-aware, and decisive unless a choice changes product shape, security/policy boundaries, durable truth, tenant blast radius, or materially different operator/adopter workflow.
