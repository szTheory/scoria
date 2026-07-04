# Requirements: v3.3 Design System Stress Test

**Milestone goal:** Make the embedded `/scoria` admin/operator UI internally coherent at the foundation, component, component-group, page-flow, copy, accessibility, motion, fixture, and proof levels without regressing the recent cleanup work.

## Requirements

### Baseline And Inventory

- [x] **BASE-01**: Maintainer can start v3.3 from a clean baseline that preserves the recent Scoria UI cleanup as committed prior art.
- [x] **INV-01**: Maintainer can inspect a current inventory of UI foundations, `ScoriaWeb.UI` primitives, component groups, LiveView pages, CSS/JS hooks, fixtures, tests, and known one-off patterns.
- [x] **INV-02**: Maintainer can see which components and page patterns are canonical, legacy, duplicated, missing, or intentionally page-specific.

### Component Lab And Fixtures

- [x] **LAB-01**: Developer can open a dev-only component lab that renders Scoria UI primitives and recurring component groups without changing the public dashboard macro or Hex package footprint.
- [x] **LAB-02**: Developer can inspect component states for light, dark, system, reduced motion, mobile, tablet, desktop, long text, empty data, dense data, disabled, selected, loading, warning, danger, and error cases.
- [x] **FIXT-01**: Developer can use realistic and ugly dev fixture data to reveal design-system quality across approvals, incidents, reviews, datasets, workflow detail, connectors, prompts, and empty/error paths.

### Foundations And Primitives

- [x] **DS-01**: Operator-facing UI uses semantic tokens for color, surface, text, border, focus, status, code, overlay, and motion; raw palette or page-local style drift remains guarded.
- [x] **DS-02**: Shared primitive controls have consistent variants, sizes, spacing, icons, focus states, disabled states, loading states, accessible names, and reduced-motion-safe feedback.
- [x] **DS-03**: Overview stats, signal summaries, metadata rows, raw evidence/code blocks, IDs, copy controls, timestamps, badges, buttons, icon buttons, links, panels, drawers, modals, toasts, forms, tables, and lists use one coherent design-system language.
- [x] **DS-04**: Approval toasts remain readable over dense UI in light and dark themes.

### Component Groups And Page Flows

- [x] **FLOW-01**: Operator can understand each dashboard page by its page title, summary, primary action, data region, empty state, loading state, error state, and next action without redundant headers or implementation jargon.
- [x] **FLOW-02**: Operator can scan and act on approvals, incidents, reviews, datasets, workflow detail, connectors, prompts, and eval screens using consistent IA and page-section conventions.
- [x] **FLOW-03**: Operator can inspect approval decisions with action-first drawers, plain-language consequences, progressive disclosure for raw payload and metadata, and no duplicated decision copy.
- [x] **FLOW-04**: Operator can find approved, denied, expired, or otherwise decided approvals through a decision-history surface without implying that a denied approval can be approved in place.
- [x] **COPY-01**: UI copy consistently uses user-flow language first, with technical terms, IDs, traces, payloads, and audit details exposed only where they help the operator or developer.

### Accessibility, Motion, And Responsive Behavior

- [x] **A11Y-01**: Keyboard-only users can complete navigation, search/command palette, table/list scan, drawer/modal decisions, copy controls, disclosures, and form flows with visible focus and predictable focus restoration.
- [x] **A11Y-02**: Dialogs, drawers, tabs/disclosures, icon buttons, status indicators, forms, empty states, toasts, and tables/lists meet WCAG 2.2 AA intent using native semantics or correct ARIA.
- [x] **MOTION-01**: Motion is restrained, tokenized, useful, transform/opacity-based where possible, and respects `prefers-reduced-motion`.
- [x] **RESP-01**: Primary dashboard pages remain usable at 320, 375, 768, 1024, 1440, and wide desktop widths without squished tables, trapped scrolling, clipped content, or floating elements covering navigation.

### Proof, Documentation, And Guardrails

- [ ] **PROOF-01**: Maintainer can run focused tests and browser proofs that cover component lab states, theme switching, overlays, mobile shell, copy affordances, toast legibility, and core operator flows.
- [ ] **PROOF-02**: Maintainer docs explain the Scoria design-system conventions for BEM, tokens, page headers, stats, overlays, evidence/code, copy controls, fixtures, motion, accessibility, and drift guards.
- [ ] **PROOF-03**: Drift guards prevent regressions to duplicate density controls, inconsistent stats, redundant single-region headers, raw palette leakage, inaccessible icon buttons, unreadable toasts, oversized copy buttons, and untested component states.

## Future Requirements

- **STORYBOOK-01**: Evaluate PhoenixStorybook only if the dev-only component lab proves insufficient for sustained component documentation and visual review.
- **UNDO-01**: Explore approval decision reversal or toast-level undo only if the domain model defines durable superseding approval evidence and a safe time-bound reversal policy.
- **AXE-PIPELINE-01**: Promote accessibility scans from dev-only proof to a required CI lane if signal-to-noise is strong and runtime cost is acceptable.
- **VISUAL-CI-01**: Add screenshot diff gating if the current screenshot harness becomes deterministic enough for low-noise CI enforcement.

## Out Of Scope

- Rewriting the whole dashboard architecture.
- Changing the public `scoria_dashboard` mount macro.
- Adding runtime UI dependencies or PhoenixStorybook in the first pass.
- Changing core approval semantics to allow approving a denied request in place.
- Broad CI topology changes unrelated to UI proof.
- Sibling-repo Docker/fleet convergence.
- Test-suite determinism work from SEED-004.

## Traceability

| Requirement | Phase |
|-------------|-------|
| BASE-01 | 36 |
| INV-01 | 36 |
| INV-02 | 36 |
| LAB-01 | 37 |
| LAB-02 | 37 |
| FIXT-01 | 37 |
| DS-01 | 38 |
| DS-02 | 38 |
| DS-03 | 38 |
| DS-04 | 38 |
| FLOW-01 | 39 |
| FLOW-02 | 39 |
| FLOW-03 | 39 |
| FLOW-04 | 39 |
| COPY-01 | 39 |
| A11Y-01 | 40 |
| A11Y-02 | 40 |
| MOTION-01 | 40 |
| RESP-01 | 40 |
| PROOF-01 | 41 |
| PROOF-02 | 41 |
| PROOF-03 | 41 |
