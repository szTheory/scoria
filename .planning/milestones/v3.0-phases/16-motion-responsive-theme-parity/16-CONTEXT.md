# Phase 16: Motion + responsive + theme parity - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning
**Source:** Advisor-mode discussion - user selected all 4 gray areas, explicitly requested subagent-backed research, and approved the synthesized recommendation set

<domain>
## Phase Boundary

Phase 16 is the cross-dashboard motion, responsive, focus, and light/dark parity sweep for the v3.0 Control Room. The phase closes MOTION-01 through MOTION-04 by hardening the already-adopted shared component system after Phases 12-15: mobile shell behavior, shared table/evidence responsiveness, restrained brand-tied motion, visible focus and non-color-only status, and theme parity across the dashboard.

This phase is UI/IA/DX only. It must not add net-new backend capability, new route families, fake data, a dedicated mobile app model, broad visual regression infrastructure, or Phase 17 proof/docs deliverables. Phase 17 still owns final audit, before/after contact sheets, and maintainer documentation. Phase 16 may add targeted browser and token checks needed to prove MOTION-01..04 before that final proof pass.

</domain>

<decisions>
## Implementation Decisions

### Mobile Shell Contract
- **D-01:** Below `md` (`<768px`), the dashboard shell becomes a single-column content layout. The current fixed `248px` sidebar grid must not remain visible at mobile width.
- **D-02:** Use a compact sticky mobile topbar with brand/current page context, a `Menu` control, command palette access, and theme toggle access. Command palette is additive, not the only navigation path.
- **D-03:** The `Menu` control opens an accessible off-canvas nav drawer that renders the existing `DashboardNav` Operate / Improve / Configure groups and active state. Do not create a separate mobile nav SSOT.
- **D-04:** The mobile nav drawer needs scrim click, Escape dismiss, focus containment/restore, scrollable nav content, and reduced-motion-safe open/close behavior. Animate opacity/transform only; never animate width, left/right layout, or grid columns.
- **D-05:** Mobile global breadcrumbs should be compact. Object-specific identity, origin, and provenance remain in `object_header` / page content rather than consuming the entire topbar.
- **D-06:** Do not use horizontal nav, bottom nav, or command-palette-only navigation in Phase 16. Those patterns hide too much of Scoria's IA, split navigation truth, or overfit a dedicated mobile responder app that Scoria is not building in this milestone.

### Responsive Tables and Evidence Surfaces
- **D-07:** Centralize table responsiveness in `ScoriaWeb.UI.table/1` and scoped component CSS. The default table rendering should include a real overflow viewport so wide tables remain usable at 375px.
- **D-08:** Add opt-in mobile row summary behavior to `<.table>` for scan-heavy tables where a compact mobile summary is materially better than horizontal scroll alone. Summaries should expose the object label, status, key scalar/time, and primary action without hiding critical state.
- **D-09:** Preserve real table semantics on desktop. Do not globally convert all tables into cards or block-layout pseudo-tables.
- **D-10:** Use mobile summaries for Runs, Review Queue, Connectors, Dataset Builder, and similar scan surfaces where the user is choosing an object to inspect. Keep dense comparison/detail surfaces honest: overflow table, stacked evidence sections, or object-detail stack depending on the existing component.
- **D-11:** Workflow trace/evidence mobile layout should stack the trace/span list first and selected evidence below it. It should not become a table-card clone or invent a separate mobile-only trace application.
- **D-12:** Replace unsupported responsive utility usage (`sm:grid-cols-*`, arbitrary `lg:grid-cols-[...]`, arbitrary `xl:grid-cols-[...]`) with scoped Scoria component classes or add explicit supported utilities only when they are general and token-bound.
- **D-13:** Sticky table headers, action columns, and row selection must work inside the chosen scroll container. Selection and status must include text/structure (`aria-selected`, `aria-current`, badges, or labels), never color alone.
- **D-14:** Per-screen custom mobile forks are allowed only for true object inspectors when the shared component cannot express the layout. They are not the default for shared tables.

### Motion Contract
- **D-15:** Adopt a "strict interactions, allowlisted state indicators" motion contract. User-triggered interaction motion is capped at 200ms and uses transform and/or opacity only.
- **D-16:** `assets/css/05-motion.css` is the only home for keyframes and named motion primitives. New one-off keyframes in LiveViews/components are out of bounds.
- **D-17:** Modal opening uses `scoria-pop`: opacity plus small Y/scale, 150ms. Scrim fades at 100ms. Reduced motion removes scale/slide or makes the transition effectively instant.
- **D-18:** Drawer opening uses an edge-origin slide/fade at 200ms max. It may be renamed or split into `scoria-slide-inline-end`, but it must not animate width, left/right, or layout.
- **D-19:** Command palette and toast motion should be opacity-only fade at roughly 100-120ms. Existing JS may delay `hidden` long enough for the fade, but it must not own choreography beyond keyboard/focus behavior.
- **D-20:** Skeleton animation is an allowlisted loading-state exception only: opacity pulse, no shimmer, no transform, no layout motion, static under `prefers-reduced-motion`, and replaced when async content resolves.
- **D-21:** Approval/attention pulse is an allowlisted finite state-indicator exception only: approval-required or similar urgent operator attention, maximum two cycles, always paired with visible explanatory text, and static under reduced motion. If a motion guard is strict, prefer outline/opacity/filter over border-color animation.
- **D-22:** Hover and active affordances may use instantaneous or short color/border/shadow changes, plus a tiny active button press if retained. Do not use row translate, bounce, spring, fire/sparkle/lava effects, infinite attention loops, route/page-load cascades, shimmer loaders, or `transition: all`.

### Focus, Status, and Theme Parity
- **D-23:** Preserve and audit the scoped global `:focus-visible` rule, but ensure every interactive element still exposes a visible focus state in both dark and light themes after component-specific backgrounds and overflow containers are applied.
- **D-24:** Status is never communicated by color alone. Badges, selected rows, highlighted approvals, table sort state, traces, and evidence outcomes need visible text, icons, ARIA state, or structural indicators in addition to tone colors.
- **D-25:** Keep the semantic token model. Do not touch `assets/css/02-tokens.css` for cosmetic preference. Token changes are reserved for WCAG/accessibility defects or genuine coherence breaks.
- **D-26:** Full light/dark parity means both themes are first-class surfaces. Fix component/state-specific contrast or focus issues at the semantic component layer before per-screen overrides.
- **D-27:** Do not reintroduce raw palette classes. DS-06 stays a ratchet and `ui.ex` remains zero raw-palette.

### Verification and Proof Level
- **D-28:** Add targeted Phase 16 parity smoke checks under the existing `mix scoria.ui.e2e` Playwright lane rather than waiting entirely for Phase 17.
- **D-29:** The targeted browser checks should cover: no horizontal page overflow at 375px on the shell and key table screens, visible focus styles on representative links/buttons/inputs, reduced-motion behavior for known animated primitives, and light/dark theme-toggle smoke on high-risk screens.
- **D-30:** Use Playwright viewport/media emulation and computed-style checks where LiveViewTest cannot see browser truth. Keep assertions stable and selector-light; avoid screenshot comparisons in CI.
- **D-31:** Add a deterministic token contrast guard only if it can reuse `assets/css/02-tokens.css` and brandbook-approved pairings without creating a parallel token source. The guard is a floor, not a replacement for visual review.
- **D-32:** Do not add full visual-regression screenshot baselines, full axe/all-screen/theme/viewport CI, or broad screenshot critique expansion in Phase 16. Phase 17 owns final screenshot/contact-sheet proof and docs. Axe can be considered later when Scoria is ready for a standing browser-a11y lane.

### Cross-Screen Polish Rules
- **D-33:** Phase 16 should prefer design-system fixes that pay dividends across all screens: shell, table, drawer/modal, command palette, notebook/evidence primitives, form controls, focus states, and responsive utility coverage.
- **D-34:** Keep LiveView and Phoenix library ergonomics boring: CSS-first, component-owned, mount-prefix-safe, no new JS framework, no new CSS architecture, no global reset outside `.scoria-root`.
- **D-35:** All new UI copy follows Scoria brand voice: calm, exact, useful. Prefer operator evidence verbs and plain consequence copy. Avoid hype, magic language, hidden chain-of-thought language, or decorative motion copy.

### Agent's Discretion
- Exact component APIs for mobile summary slots, CSS class names, motion guard implementation, selector lists for parity smoke tests, and plan slicing are planner/executor discretion.
- The planner may decide whether mobile nav drawer uses the existing command-palette focus helper utilities or a new small hook, as long as it remains scoped to the dashboard and does not duplicate navigation data.
- The planner may choose the first representative screens for smoke coverage, but should include Home/shell, one shared-table scan screen, one object/evidence screen, and one overlay path.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Prior Decisions
- `.planning/PROJECT.md` - v3.0 Control Room goal, product boundary, personas, UI-only milestone constraints, and Phase 16 next-step state.
- `.planning/REQUIREMENTS.md` - MOTION-01 through MOTION-04 and Phase 16 traceability; Phase 17 proof/docs boundary.
- `.planning/ROADMAP.md` - Phase 16 goal, success criteria, dependency on Phase 15, and Phase 17 boundary.
- `.planning/STATE.md` - current milestone state, completed Phase 15 status, deferred items, and accumulated decisions.
- `.planning/phases/15-high-traffic-screens-evidence-adapters/15-CONTEXT.md` - current high-traffic screen and evidence adapter contract; Phase 16 boundary explicitly deferred there.
- `.planning/phases/14-least-iterated-screens-polish/14-CONTEXT.md` - Dataset Builder, Review Queue, Eval, Prompt, Incident polish rules and Phase 16 boundary.
- `.planning/phases/13-orientation-spine-ia/13-CONTEXT.md` - navigation groups, Status Home, command palette, breadcrumbs/object headers, origin context, and honest stub rules.
- `.planning/phases/12-design-system-component-layer/12-CONTEXT.md` - token gateway, DS-06 ratchet, shared component layer, and earlier motion/responsive/theme deferrals.
- `.planning/phases/12-design-system-component-layer/12-UI-SPEC.md` - component contracts, token/tone mapping, focus guidance, modal/drawer/table/notebook/form details, and DS-06 regex.
- `.planning/phases/11-evaluation-engine-seed-depth/11-CONTEXT.md` - screenshot/critique harness decisions and state matrix.
- `.planning/phases/11-evaluation-engine-seed-depth/11-UI-SPEC.md` - screenshot viewport/theme matrix, rubric dimensions, ready sentinel, and harness constraints.
- `priv/shots/gap_register.md` - baseline responsive/a11y/theme critique findings, especially mobile sidebar/table risk and focus-state gaps.

### Brand, Product Strategy, and Prompt Corpus
- `brandbook/brand-book.md` - binding brand voice, token/contrast guidance, accessibility guidance, mobile notes, UI posture, and antipatterns.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops strategy, LiveView operator UI lessons, observability/eval flywheel, and product boundary cautions.
- `prompts/scoria-gsd-kickoff.md` - project vision, trace store, eval workbench, governance layer, and embedded LiveView dashboard goals.
- `prompts/sztheory-elixir-dna.md` - embedded LiveView dashboards, durable state, operator-first DX, and Elixir ecosystem posture.
- `prompts/scoria-brand-book-deep-research.md` - original Scoria positioning, brand direction, and UI/brand lessons.
- `prompts/brand-book-pressure-test-prompt.md` - pressure-test lenses for brand, UI/UX, accessibility, implementation readiness, and microcopy.

### Existing UI, CSS, JS, and Proof Surfaces
- `lib/scoria_web/ui.ex` - shared components and token gateway: table, drawer, modal, object_header, command_palette, notebook/evidence primitives, field/form_section, skeleton, toast, badge, flash.
- `lib/scoria_web/components/layouts/app.html.heex` - current shell, sidebar, topbar, command palette, shortcuts overlay, theme toggle.
- `lib/scoria_web/components/layouts/root.html.heex` - `.scoria-root`, default theme, CSS/JS embedding, socket path.
- `lib/scoria_web/dashboard_nav.ex` - navigation SSOT for groups, active view mapping, command palette rows, shortcuts, and mount-prefix-safe paths.
- `assets/css/01-reset.css` - scoped reset and global `:focus-visible` baseline.
- `assets/css/02-tokens.css` - semantic token SSOT and light/dark re-pointing; do not change for cosmetic preference.
- `assets/css/03-base.css` - dashboard base styles and dark background atmosphere.
- `assets/css/04-components.css` - shell, nav, table, drawer/modal, command palette, notebook, evidence, toast, flash, and component CSS.
- `assets/css/05-motion.css` - named keyframes, motion primitives, reduced-motion kill switch, and state-indicator exceptions.
- `assets/css/06-utilities.css` - scoped token-backed utility subset; responsive utility gaps must be fixed or replaced here/component CSS.
- `assets/js/scoria.js` - ThemeToggle, command palette, focus trap helpers, keyboard shortcuts, recents, and dashboard-scoped JS patterns.
- `priv/dev/shots.mjs` - screenshot matrix: dark/light, mobile/desktop, populated/empty/overlay states.
- `lib/mix/tasks/scoria.ui.shots.ex` - screenshot and critique task; Phase 17 uses this for broad proof.
- `priv/dev/e2e/uat.spec.mjs` - existing Playwright browser truth lane for toast/skeleton/overlay UAT.
- `priv/dev/e2e/command_palette.spec.mjs` - existing command palette browser tests and focus/keyboard patterns.
- `lib/mix/tasks/scoria.ui.e2e.ex` - existing e2e task used by CI.
- `.github/workflows/ci.yml` - existing Playwright installation/cache and `mix scoria.ui.e2e` posture.
- `test/scoria_web/ds06_drift_guard_test.exs` - raw-palette ratchet and `ui.ex` zero assertion.
- `test/scoria_web/ui_drift_guard_test.exs` - guard against per-component status-color helpers.
- `test/scoria_web/ui_component_test.exs` - shared component contract tests.

### Phase 16 Code Surfaces to Inspect
- `lib/scoria_web/live/orchestrator_live.ex` - Home shell/content and attention strip; mobile shell and topbar interaction affect this first screen.
- `lib/scoria_web/live/workflow_live/index.ex` - Runs table scan surface.
- `lib/scoria_web/live/workflow_live/show.ex` - canonical trace/evidence object page and mobile stack target.
- `lib/scoria_web/live/approvals_live/index.ex` - approval inbox/detail/decision modal, attention highlight, focus, and status text.
- `lib/scoria_web/live/connectors_live/index.ex` - runtime/connector shared tables and drawer inspection.
- `lib/scoria_web/live/review_queue_live.ex` - scan table plus selected detail rail; mobile summary/stack target.
- `lib/scoria_web/live/incidents_live/index.ex` - incident list/detail evidence layout and unsupported `sm:grid-cols-3` usage.
- `lib/scoria_web/live/dataset_live/index.ex` - Dataset Builder table/promote route surface.
- `lib/scoria_web/live/dataset_live/promote_component.ex` - promotion modal/forms and responsive grid usage.
- `lib/scoria_web/live/eval_spec_live/index.ex` - Eval Workbench shared tables/forms.
- `lib/scoria_web/live/prompt_live/index.ex` - Prompt Registry table/forms.
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex` - Release Workbench comparison panels and approval/reject modals.
- `lib/scoria_web/components/approval_inbox_component.ex` - approval row selection/highlight.
- `lib/scoria_web/components/runtime_detail_drawer_component.ex` - drawer content and evidence rows.
- `lib/scoria_web/components/connector_detail_drawer_component.ex` - drawer content and evidence rows.
- `lib/scoria_web/components/workflow_detail_panel_component.ex` - selected step detail and promotion affordance.
- `lib/scoria_web/components/workflow_tree_component.ex` - workflow tree row selection/focus.
- `lib/scoria_web/components/trace_tree_component.ex` - Home trace summary/tree interaction.
- `lib/scoria_web/components/citation_evidence_component.ex` - notebook/evidence responsive layout.
- `lib/scoria_web/components/delegated_evidence_component.ex` - notebook/evidence responsive layout.
- `lib/scoria_web/components/memory_notebook_component.ex` - notebook/evidence responsive layout.
- `lib/scoria_web/components/replay_evidence_notebook_component.ex` - comparison/evidence responsive layout.
- `lib/scoria_web/components/semantic_evidence_notebook_component.ex` - semantic evidence responsive layout.
- `lib/scoria_web/components/remote_invocation_evidence_component.ex` - existing notebook adapter model.
- `lib/scoria_web/components/incident_evidence_component.ex` - incident notebook adapter and unsupported arbitrary grid usage.

### External Ecosystem References Consulted
- `https://oban-web.hexdocs.pm/overview.html` - embedded Phoenix LiveView dashboard pattern: directly mounted, realtime, filterable, detailed inspection.
- `https://github.com/phoenixframework/phoenix_live_dashboard` - Phoenix LiveDashboard pattern: focused realtime pages for Phoenix performance/debugging.
- `https://docs.github.com/en/get-started/accessibility/github-command-palette` - command palette as additive keyboard navigation/action surface, not the sole IA.
- `https://docs.datadoghq.com/tracing/trace_explorer/trace_view/` - trace detail separation: trace header, span visualization/details, and inspection.
- `https://designsystem.digital.gov/components/table/` - government design-system table guidance for structured data and responsive variants.
- `https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions` - WCAG animation-from-interactions reduced-motion requirement.
- `https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion` - CSS media feature for reduced motion preferences.
- `https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html` - WCAG text contrast minimums.
- `https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html` - WCAG non-text UI contrast target.
- `https://playwright.dev/docs/emulation` - viewport/media emulation for browser truth checks.
- `https://playwright.dev/docs/accessibility-testing` - Playwright + axe guidance and limits of automated accessibility tests.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html` - LiveView JS command/transition capabilities; use sparingly and component-owned.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ScoriaWeb.UI.table/1` is the right seam for table overflow and optional mobile summaries. It already owns density, sort, pagination, empty state, filter slot, and action slot.
- `ScoriaWeb.UI.drawer/1` and `modal/1` already provide shared overlay shells with Escape/scrim/close semantics. Mobile nav can borrow their CSS/focus lessons, but should remain shell-level navigation.
- `ScoriaWeb.UI.command_palette/1` plus `assets/js/scoria.js` already contains dashboard-scoped focus trap, keyboard handling, hidden-state delay, and recents patterns.
- `assets/css/05-motion.css` already has `scoria-fade`, `scoria-pop`, `scoria-slide`, `scoria-attention`, `scoria-skeleton-pulse`, duration tokens, and `prefers-reduced-motion` suppression.
- `assets/css/01-reset.css` already defines scoped `:focus-visible`; Phase 16 audits whether component backgrounds/overflows preserve visible focus.
- `priv/dev/shots.mjs` already captures dark/light and 375px/1280px screenshots for the broad matrix.
- `mix scoria.ui.e2e` and `priv/dev/e2e` already provide a CI-backed browser truth lane for JS/CSS behavior.

### Established Patterns
- Scoria is an embedded Phoenix library dashboard. Routes and client behavior must remain mount-prefix-safe and scoped under `.scoria-root`.
- Shared components are slot/attr shells; parent LiveViews own state and events.
- The CSS architecture is custom scoped layers and semantic tokens, not Tailwind runtime compilation. Utility classes are a compatibility subset, not a promise that arbitrary Tailwind syntax works.
- DS-06 is an executable ratchet. Touched in-scope files should move toward zero raw palette and no new file may introduce palette classes.
- Browser proof is targeted. LiveViewTest remains the default for server-rendered behavior; Playwright covers browser-only truths; screenshot/critique remains dev-only broad proof.

### Integration Points
- Shell changes connect through `app.html.heex`, `DashboardNav`, `assets/css/04-components.css`, and `assets/js/scoria.js`.
- Table responsiveness connects through `ui.ex`, `04-components.css`, and shared table callsites across Runs, Review Queue, Connectors, Dataset Builder, Eval, Prompt, and Approvals.
- Evidence responsiveness connects through notebook/evidence primitives and the Phase 15 thin adapters.
- Motion guard/checks connect through `05-motion.css`, `04-components.css`, component tests, and Playwright parity specs.
- Theme parity connects through `02-tokens.css`, component CSS, ThemeToggle hook, screenshot harness, and targeted Playwright checks.

</code_context>

<specifics>
## Specific Ideas

- Mobile topbar should keep user trust and orientation: brand mark/name, current page label, `Menu`, command palette, and theme toggle. If space is tight, icon+accessible-label buttons are acceptable, but theme and menu must remain discoverable.
- Mobile nav drawer should render the same Operate / Improve / Configure groups, including "Soon" text badges. It should not become a top-four shortcut list.
- Table mobile summaries should be terse and object-shaped:
  - Runs: run/trace ID, status badge, started-at/root role, `Open trace`.
  - Review Queue: candidate rationale/trace, severity/score, promotion state, `Open run` or selected detail.
  - Connectors: runtime/connector label, text status, last seen/refresh, `Inspect`.
  - Dataset Builder: dataset name/version/state/count, primary open/promote action.
- Workflow Show mobile stack: object header, next-step verbs, trace/span list, selected-step detail, evidence notebook stack. Keep evidence grouped by notebook primitives.
- Motion wording for planners: "The interface may feel responsive, but it should never feel alive for its own sake." Use the brand's calm, exact operator posture.
- Verification wording for planners: "Add proof that prevents late Phase 17 surprises; do not turn Phase 16 into visual-regression infrastructure."

</specifics>

<deferred>
## Deferred Ideas

- Dedicated mobile responder mode, bottom navigation, or saved mobile persona lens.
- Full command-palette object search beyond existing nav/recent/static action behavior.
- Full axe/all-screen/theme/viewport browser accessibility lane.
- CI visual regression screenshot baselines and approval workflow.
- Phase 17 final contact sheets, final audit deltas, and MAINTAINERS design-system docs.
- No todo matches were found for Phase 16, so no todos were folded or reviewed.

</deferred>

---

*Phase: 16-motion-responsive-theme-parity*
*Context gathered: 2026-06-13*
