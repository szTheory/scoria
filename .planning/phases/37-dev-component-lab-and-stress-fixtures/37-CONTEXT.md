# Phase 37: Dev Component Lab And Stress Fixtures - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 37 adds a maintainer-only component lab and fixture matrix for Scoria's embedded `/scoria` admin/operator UI. The lab makes existing UI primitives, recurring component groups, fixture data, themes, viewport behavior, motion preferences, overlays, empty/loading/error states, and ugly data visible before later phases tighten shared controls and page flows.

This phase is a dev-quality and proof-enablement phase. It must not change the public `scoria_dashboard/2` macro, turn the lab into adopter-facing product UI, add runtime UI dependencies, ship lab modules or browser proof tooling to Hex, or fix the Phase 38/39 UI issues it exposes. Toast legibility and approval decision history may be represented as stress fixtures, but their product fixes stay in Phases 38 and 39.

</domain>

<decisions>
## Implementation Decisions

### Lab Access Boundary

- **D-01:** Build the lab as a Phoenix-native maintainer workshop mounted only by `ScoriaWeb.DevRouter`, outside the public `scoria_dashboard/2` macro. A clearly private path such as `/scoria/_lab` is preferred because it is easy to find locally and hard to confuse with adopter-facing routes.
- **D-02:** Put lab LiveViews/modules under `dev/` or another compile-`:dev`-only path. Keep fixture payload files under `priv/dev` when file-backed data is useful. Preserve the existing package boundary where `dev`, `priv/dev`, and `priv/shots` are excluded from Hex.
- **D-03:** Do not add a public macro option such as `scoria_dashboard lab: true` in this phase. That creates a production exposure footgun, a public API commitment, and a Hex footprint expansion.
- **D-04:** Do not add PhoenixStorybook in Phase 37. The first pass should prove whether a repo-local lab is sufficient. `STORYBOOK-01` remains the deferred evaluation path if the lab becomes too costly to maintain.
- **D-05:** Do not link the lab from the public dashboard nav, operator command palette, or adopter docs as a product surface. Maintainer docs may mention the local URL and proof commands.

### Lab Shape And Information Architecture

- **D-06:** Use a hybrid inventory-driven catalog: component-first ownership as the spine, reusable stress-scenario bands for state coverage, and a small set of curated operator-flow probes for cross-component risks.
- **D-07:** The lab IA should match maintainer inspection jobs, not the operator dashboard IA. Top-level sections should be: `Foundations`, `Primitives`, `Groups`, `States`, `Viewports`, `Overlays`, and `Fixtures`.
- **D-08:** The Phase 36 inventory is the coverage anchor. Lab entries should reference stable inventory IDs such as `PRIM-TABLE`, `GROUP-APPROVAL-INBOX-COMPONENT`, `HOOK-COMMANDPALETTE`, `RISK-RESPONSIVE-SCAN`, and `RISK-OVERLAY-FOCUS`.
- **D-09:** Render canonical `ScoriaWeb.UI` primitives and recurring component groups before Phase 38 changes shared controls. At minimum, cover buttons, icon buttons, badges, panels, page sections, overview stats, signal summaries, tables/lists, drawers, modals, toasts, fields/forms, notebooks, raw evidence/code, empty states, skeletons, IDs, timestamps, approval inbox, workflow tree/detail, connector drawer, incident evidence, and evidence notebook groups.
- **D-10:** Include curated flow probes only where isolated components are insufficient: dense approvals with toast overlay, table/list mobile summaries, drawer/modal focus and dismissal, command palette, mobile nav, raw evidence copy controls, and long evidence payloads. Do not recreate every dashboard page as a second app.

### State, Tone, Viewport, And Motion Coverage

- **D-11:** Use one canonical lab state vocabulary across fixtures, docs, tests, and labels: `normal`, `long_text`, `empty`, `dense`, `disabled`, `selected`, `loading`, `warning`, `danger`, and `error`.
- **D-12:** Keep lab states separate from visual tones. Visual tone names remain semantic design-system choices such as `:neutral`, `:pass`, `:info`, `:warn`, `:fail`, `:trace`, and `:brand`. Example: `approval_requested` may use `:warn`, but the lab state is `warning`.
- **D-13:** Viewport coverage should explicitly exercise 320, 375, 768, 1024, 1440, and wide desktop widths. Labels should read as maintainer controls or proof targets, not decorative marketing.
- **D-14:** Theme coverage must include light, dark, and system. Reduced-motion behavior must be visible and testable enough to support Phase 40, but Phase 37 should not invent new motion language beyond existing tokens.
- **D-15:** The lab should expose visual stress failures with real constraints: long unbroken IDs, long policy names, dense rows, empty datasets, loading placeholders, disabled controls, selected rows/cards, warning/danger/error states, small viewports, overlay stacking, and copy controls near raw evidence.

### Fixture Ownership And Domain Language

- **D-16:** Own component-lab scenarios through a static dev-only fixture catalog, using HEEx-safe maps/struct-like data and optional JSON files where data volume makes files clearer. Suggested owner names: `ScoriaWeb.DevLabFixtures` or `ScoriaWeb.DevFixtures`.
- **D-17:** Treat `priv/repo/dev_seed.exs` as the DB-backed projection for real LiveView page screenshots and click-through proof, not as the source of every component state. Component lab fixtures should be deterministic and reset-free.
- **D-18:** Use `36-inventory.json` for coverage alignment, not as a rich domain data generator. Inventory IDs can drive navigation and coverage checks; curated fixture examples must provide the actual domain payloads.
- **D-19:** Fixture data must cover approvals, incidents, reviews, datasets, workflow detail, connectors, prompts, evals, and empty/error paths with realistic and ugly values.
- **D-20:** Name fixture scenarios with Scoria domain nouns/events/verbs instead of backend table names: `approval_requested`, `approval_denied`, `incident_opened`, `incident_escalated`, `review_candidate_flagged`, `dataset_promoted`, `dataset_empty`, `workflow_waiting_for_approval`, `workflow_failed_step`, `connector_degraded`, `connector_scope_blocked`, `prompt_release_blocked`, and `eval_regression_detected`.
- **D-21:** Fixture data is example evidence, not product truth. Runtime contexts must not call dev fixture modules, and fixture defaults must not become hidden business rules.

### UI, JTBD, Brand, And Microcopy

- **D-22:** Primary persona: Scoria maintainer improving shared UI primitives. Their job is to see every meaningful state and breakpoint before changing shared UI, so they do not fix one page while breaking five others.
- **D-23:** Secondary persona: future contributor touching a LiveView page. Their job is to find the canonical component, copy pattern, state name, and fixture example without reverse-engineering older pages.
- **D-24:** Tertiary persona: release/verifier maintainer. Their job is to use deterministic local surfaces for browser proof, screenshots, and later regression guards.
- **D-25:** The lab's visual motif is a field-engineer bench or evidence notebook: components are specimens under stress, not marketing demo cards. Use compact section headers, state badges, viewport labels, fixture source labels, inventory IDs, and evidence disclosures.
- **D-26:** Keep the brand direction from `brandbook/`: grounded, composed, operator-grade, Phoenix-native, evidence-led, dark/light/system safe, volcanic without flame/phoenix/AI-magic tropes, and distinct from generic blue-purple AI SaaS.
- **D-27:** Use maintainer-first microcopy. Recommended strings:
  - Page title: `Component Lab`
  - Subtitle: `Inspect Scoria primitives, groups, fixtures, themes, and stress states before changing shared UI.`
  - Primary command: `Run lab proof`
  - Secondary command: `Open fixture matrix`
  - Empty fixture state: `No fixture rows for this state. Add deterministic dev fixture data before using this state for proof.`
  - Fixture error: `Lab fixture failed to render. Check the fixture builder and component attrs before changing runtime UI.`
  - Labels: `Reduced motion`, `Ugly data`, `Dense data`, `Long text`, `Technical evidence`, `Copy fixture payload`.
- **D-28:** Hide backend guts from the primary lab orientation: Ecto schema names, PubSub topics, private helper names, raw maps, macro mechanics, and internal route implementation. Expose them only as evidence when useful.
- **D-29:** Expose evidence-oriented details where they help maintainers: trace IDs, run IDs, approval IDs, actor/session/tenant IDs, policy/version names, payloads, fixture source labels, inventory refs, risk refs, and component owners such as `ScoriaWeb.UI.table/1`.

### Proof And Documentation Shape

- **D-30:** Phase 37 proof should prioritize whether the lab renders, covers required states/domains, stays dev-only, preserves package boundaries, and provides useful browser-inspection surfaces. Do not turn screenshot diffs into a required CI gate in this phase.
- **D-31:** Add focused tests or guards that prove the lab is excluded from `scoria_dashboard/2`, not shipped through `package.files`, and not linked from public dashboard nav or command palette.
- **D-32:** Add coverage checks that every canonical state name exists and that required fixture domains are represented. If practical, tie coverage to Phase 36 inventory IDs and required risk IDs.
- **D-33:** Browser proof should be focused and deterministic: local route loads, theme toggles, reduced motion, overlay/focus probes, mobile-width scan, dense table/list cases, toast region legibility fixture, and copy controls. Keep it advisory or Phase-37-specific unless Phase 41 later promotes it.
- **D-34:** Maintainer docs should explain how to start the dev server, open the lab, inspect states, update fixtures, run focused proof, and understand which lab probes support Phases 38-41.

### Reviewed Todos

- **Reviewed, not folded:** `Make approval toasts legible over dense UI` - belongs to Phase 38 as `RISK-TOAST-LEGIBILITY`. Phase 37 may include dense approval/toast stress fixtures only.
- **Reviewed, not folded:** `Add approval decision history` - belongs to Phase 39 as `RISK-APPROVAL-HISTORY`. Phase 37 may include decided-approval fixture examples only.
- **Reviewed, not folded:** `CI policy job: -test-mix- cache key while compiling under MIX_ENV=dev (WR-01)` - out of scope for the component lab.
- **Reviewed, not folded:** `Docker dev-DX fleet hardening - port-conflict-free multi-lib local DX` - out of scope for the component lab.

### Claude's Discretion

Downstream agents may choose exact module names, route path, and fixture file layout as long as the decisions above hold. Prefer boring names, small modules, and explicit coverage checks over a clever DSL. If a preview abstraction is added, keep it internal to `dev/` and shaped around Phoenix function components and `attr`/`slot` contracts.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase And Milestone Scope

- `.planning/ROADMAP.md` - Phase 37 goal and success criteria.
- `.planning/REQUIREMENTS.md` - `LAB-01`, `LAB-02`, `FIXT-01`, v3.3 out-of-scope boundaries, and future `STORYBOOK-01` / `VISUAL-CI-01`.
- `.planning/PROJECT.md` - Scoria product posture and v3.3 milestone direction.
- `.planning/STATE.md` - current phase position and recent Phase 36 decisions.
- `.planning/phases/36-baseline-and-inventory/36-CONTEXT.md` - locked inventory, design-system, risk, and downstream decisions.
- `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` - human-readable inventory, risk register, and Phase 37+ gate.
- `.planning/phases/36-baseline-and-inventory/36-inventory.json` - canonical inventory row IDs, statuses, risk refs, and coverage enums.

### Brand, Product, And Research

- `brandbook/brand-book.md` - canonical Scoria brand, voice, UI, and microcopy direction.
- `brandbook/README.md` - brand artifact ownership and token SSOT rules.
- `brandbook/tokens.json` - semantic/raw token references for light, dark, state, motion, and typography.
- `brandbook/tokens.css` - docs/marketing token CSS; hexes must remain consistent with runtime tokens.
- `prompts/sztheory-elixir-dna.md` - batteries-included, composable, operator-first Elixir library philosophy.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops product thesis, domain nouns, and lessons from AI ops/eval/trace ecosystems.
- `prompts/scoria-gsd-kickoff.md` - original Scoria product vision and operator UI alignment.
- `prompts/brand-book-pressure-test-prompt.md` - brand-system pressure-test lenses; use newer `brandbook/` content as canonical where they differ.
- `prompts/scoria-brand-book-deep-research.md` - older brand research; use only when not superseded by `brandbook/`.

### Existing Dev Harness And Package Boundary

- `mix.exs` - `elixirc_paths/1`, dev-only dependencies, package `files`, docs extras, and Hex footprint boundaries.
- `dev/dev_router.ex` - current dev-only dashboard route owner and session tenant setup.
- `dev/dev_endpoint.ex` - current dev-only endpoint, LiveView socket, live reload policy, and screenshot harness support.
- `dev/mix_tasks/scoria_dev_db.ex` - dev DB setup entry point.
- `priv/repo/dev_seed.exs` - current DB-backed dev data projection for dashboard screens.
- `Makefile` - maintainer dev commands including `make dev`.
- `config/dev.exs` - dev endpoint/server configuration.

### Current UI, Components, Hooks, Fixtures, And Proof

- `lib/scoria_web/router.ex` - public `scoria_dashboard/2` macro that Phase 37 must not change for lab exposure.
- `lib/scoria_web/ui.ex` - canonical `ScoriaWeb.UI` primitive vocabulary.
- `assets/css/02-tokens.css` - runtime dashboard token SSOT.
- `assets/css/04-components.css` - runtime component CSS and responsive/theme behavior.
- `assets/css/05-motion.css` - motion tokens and reduced-motion behavior.
- `assets/js/scoria.js` - dashboard hooks for theme, command palette, copy, dismissable overlays, mobile nav, and recents.
- `lib/scoria_web/components/` - recurring dashboard component groups for lab coverage.
- `lib/scoria_web/live/` - operator page flows for curated probes and fixture domains.
- `lib/scoria/support_journey.ex` - shared support-copilot domain fixture spine.
- `lib/scoria/support_journey/handlers.ex` - realistic handler outputs and approval/tool domain examples.
- `test/support/` - test fixture/helper patterns.
- `test/scoria_web/ui_component_test.exs` - existing component proof surface.
- `test/scoria_web/ds06_drift_guard_test.exs` - raw-palette drift guard and `ScoriaWeb.UI` zero-palette assertion.
- `test/scoria_web/token_contrast_guard_test.exs` - token contrast proof.
- `priv/dev/e2e/` - current Playwright proof surfaces and ready-state helpers.
- `priv/dev/shots.mjs` - screenshot harness implementation.
- `lib/mix/tasks/scoria.ui.shots.ex` - maintainer screenshot/proof entry point.
- `docs/MAINTAINERS.md` - maintainer proof and design-system docs target.
- `docs/uat_automation.md` - browser/UAT proof notes and limitations.

### External Ecosystem References

- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html` - Phoenix LiveDashboard router/mount precedent.
- `https://hexdocs.pm/phoenix_storybook/PhoenixStorybook.Stories.Variation.html` - PhoenixStorybook variation/state precedent.
- `https://hexdocs.pm/phoenix_storybook/components.html` - PhoenixStorybook variation groups and component story structure.
- `https://storybook.js.org/docs/writing-stories/args` - Storybook args/state modeling precedent.
- `https://storybook.js.org/docs/essentials/controls` - Storybook interactive controls precedent.
- `https://storybook.js.org/docs/writing-stories/mocking-data-and-modules/mocking-network-requests` - Storybook fixture/mock lesson.
- `https://lookbook.build/guide/components/view_component` - Rails Lookbook/ViewComponent preview precedent.
- `https://viewcomponent.org/guide/previews.html` - ViewComponent preview naming and isolation precedent.
- `https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Html.html` - Phoenix fixture/test-support generator precedent.
- `https://hexdocs.pm/ecto/testing-with-ecto.html` - Ecto test data and sandbox boundary precedent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `ScoriaWeb.DevRouter` and `ScoriaWeb.DevEndpoint` already establish the correct dev-only route and endpoint boundary. They are compiled only in `:dev` and excluded from Hex.
- `mix.exs` already excludes `dev`, `priv/dev`, and `priv/shots` from package `files`, which gives Phase 37 a clear packaging contract.
- `ScoriaWeb.UI` already exposes the primitives the lab should render: buttons, icon buttons, badges, panels, page sections, stats, tables, drawers, modals, toasts, fields, notebooks, raw evidence, empty states, skeletons, IDs, timestamps, tone/status helpers, and related shell components.
- `assets/css/02-tokens.css`, `04-components.css`, and `05-motion.css` define the runtime token/component/motion language the lab should inspect rather than bypass.
- `assets/js/scoria.js` owns the browser hooks most relevant to lab probes: theme toggle, command palette, copy IDs, dismissable overlays, mobile nav, and recent object recording.
- `SupportJourney` and `priv/repo/dev_seed.exs` contain realistic Scoria domain data and should inform fixture examples without becoming the component-lab source of truth.
- Existing Playwright and screenshot harnesses under `priv/dev` provide a natural proof path for lab route smoke and focused state checks.

### Established Patterns

- Scoria is a Phoenix library, not a standalone hosted app. Dev harnesses may exist for maintainers, but adopter-facing routes come through explicit public macros.
- Function components with `attr` and `slot` contracts are the preferred reusable UI primitive shape.
- Runtime CSS is token-scoped through `.scoria-root`; raw palette drift is already guarded.
- Browser proof is useful when focused and deterministic. Broad screenshot diff gating remains deferred.
- Dev seed data is intentionally realistic and idempotent, but component states need deterministic fixture rows that do not require DB reset.

### Integration Points

- Mount the lab in `dev/dev_router.ex`, outside `scoria_dashboard("/scoria")`.
- Add dev-only LiveView/module owners under `dev/`.
- Store bulky or inspectable lab fixture payloads under `priv/dev` if needed.
- Extend maintainer docs in `docs/MAINTAINERS.md`.
- Add focused tests/guards under `test/` only where they do not compile dev-only modules from runtime paths incorrectly.
- Extend `priv/dev/e2e/` or add a small proof script only for focused lab route/state/browser checks.

</code_context>

<specifics>
## Specific Ideas

- Preferred lab route: `/scoria/_lab`.
- Preferred lab page title: `Component Lab`.
- Preferred lab concept: a maintainer workshop or evidence bench, not a public operator page or a beautiful gallery.
- Preferred coverage model: inventory-driven component/group pages, reusable state bands, and curated flow probes.
- Required state names: `normal`, `long_text`, `empty`, `dense`, `disabled`, `selected`, `loading`, `warning`, `danger`, `error`.
- Required fixture domains: approvals, incidents, reviews, datasets, workflow detail, connectors, prompts, evals, empty paths, and error paths.
- Required design pillars to consider and make visible where relevant: accessibility, responsive behavior, theme parity, motion/reduced motion, performance/render stability, information hierarchy, affordance clarity, density/scannability, microcopy, evidence discoverability, keyboard/focus behavior, and brand fit.
- Successful-system lessons to apply: show bad data, not just ideal states; make the canonical component path easier than local invention; document component intent and non-goals; separate domain state from visual tone; prove focus/keyboard/motion/responsive behavior where visuals are inspected.
- Footguns to avoid: turning the lab into a second app, exposing dev tooling through public macros, fixture data becoming runtime truth, state-name drift, happy-path-only examples, accessibility proof deferred until after visual polish, and PhoenixStorybook adoption before the local lab proves insufficient.

</specifics>

<deferred>
## Deferred Ideas

- Do not add PhoenixStorybook in Phase 37. Re-evaluate under `STORYBOOK-01` only if the repo-local lab is insufficient.
- Do not add screenshot-diff CI in Phase 37. Visual CI remains deferred to `VISUAL-CI-01` unless Phase 41 finds a deterministic low-noise path.
- Do not fix approval toast legibility in Phase 37; only add stress fixtures/probes that make the problem visible for Phase 38.
- Do not implement approval decision history in Phase 37; only add fixture examples that help Phase 39 reason about decided approvals.
- Do not expose the lab as an adopter-facing feature or public dashboard macro option.

### Reviewed Todos (not folded)

- `Make approval toasts legible over dense UI` - represented only as Phase 37 stress-fixture/probe input; fix remains Phase 38.
- `Add approval decision history` - represented only as Phase 37 fixture/probe input; feature remains Phase 39.
- `CI policy job: -test-mix- cache key while compiling under MIX_ENV=dev (WR-01)` - unrelated CI correctness follow-up.
- `Docker dev-DX fleet hardening - port-conflict-free multi-lib local DX` - unrelated sibling/fleet DX follow-up.

</deferred>

---

*Phase: 37-Dev Component Lab And Stress Fixtures*
*Context gathered: 2026-06-20*
