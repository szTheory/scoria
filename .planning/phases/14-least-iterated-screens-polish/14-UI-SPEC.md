---
phase: 14
slug: least-iterated-screens-polish
status: approved
shadcn_initialized: false
preset: none
created: 2026-06-12
reviewed_at: 2026-06-12T11:55:16-04:00
---

# Phase 14 - UI Design Contract: Least-Iterated Screens Polish

> Visual and interaction contract for the Phase 14 screen polish slice. This phase adopts the existing Scoria design-system component layer; it does not redesign the token system or add a new UI library.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none - custom token-first scoped CSS, not shadcn |
| Preset | not applicable |
| Component library | `ScoriaWeb.UI` Phoenix LiveView function components |
| Component source | `lib/scoria_web/ui.ex`, `assets/css/04-components.css` |
| Icon library | Existing inline SVG/Heroicon-style 16px and 18px icons |
| Font - sans | IBM Plex Sans via `--scoria-font-sans` |
| Font - mono | JetBrains Mono via `--scoria-font-mono` |

shadcn gate: not applicable. This is a Phoenix LiveView project with an established repo-local component layer and no `components.json`.

Registry safety gate: no external registries, no shadcn blocks, no third-party UI packages.

---

## Spacing Scale

Declared values for Phase 14 screen templates:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, badge dots, tight inline pairs |
| sm | 8px | Compact control spacing, button groups, dense table affordances |
| md | 16px | Default element gaps, panel body padding, form field groups |
| lg | 24px | Section rhythm, page header to content gap, drawer body sections |
| xl | 32px | Major screen regions and dashboard grids |
| 2xl | 48px | Empty-state vertical rhythm and large section breaks |
| 3xl | 64px | Page-level spacing only when a layout genuinely needs breathing room |

Exceptions:
- Existing shared component CSS may internally resolve to `--scoria-space-3` = 12px for default table cells, form input inline padding, and nav item padding. Phase 14 implementers should use the component classes and not hand-author new 12px layout utilities.
- Interactive controls in tables, drawers, modals, and selected rows must preserve a 44px minimum hit target where practical.
- No raw Tailwind spacing/palette class cleanup should change `assets/css/02-tokens.css` for cosmetic preference.

---

## Typography

Contract: 4 type tiers, 2 weights. Use IBM Plex Sans for UI text and JetBrains Mono for IDs, code, trace labels, timestamps, token counts, and raw evidence.

| Role | Token | Size | Weight | Line Height | Usage |
|------|-------|------|--------|-------------|-------|
| Display / metric | `--scoria-fs-display` / `--scoria-fs-metric` | 30px | 600 | `--scoria-lh-tight` = 1.2 | Metric values, high-emphasis counts |
| Page / panel heading | `--scoria-fs-panel` | 18px | 600 | `--scoria-lh-tight` = 1.2 | Screen section titles, drawer and modal headings |
| Body / table | `--scoria-fs-body` | 14px | 400 | `--scoria-lh-body` = 1.5 | Tables, descriptions, form help, empty state bodies |
| Label / meta | `--scoria-fs-label` | 12px | 400 or 600 | 1.45 | Column headers, field labels, badges, trace IDs, timestamps |

Locked implementation detail: `.scoria-badge` may use `--scoria-fs-badge` = 11px through existing CSS. Do not introduce 11px directly in new HEEx templates.

---

## Color

All Phase 14 surfaces bind to semantic Scoria tokens. Do not introduce raw palette classes under `lib/scoria_web/`.

| Role | Semantic Token | Light Value | Dark Value | Usage |
|------|----------------|-------------|------------|-------|
| Dominant (60%) | `--scoria-surface-app` | `#faf5ef` | `#11100f` | Dashboard app background |
| Secondary (30%) | `--scoria-surface-panel` | `#fff9f3` | `#181513` | Panels, table shells, nav/sidebar surfaces |
| Raised | `--scoria-surface-panel-raised` | `#ffffff` | `#211c19` | Drawers, modals, selected detail rails, raised comparison panels |
| Sunken | `--scoria-surface-sunken` | `#f1e8de` | `#0c0b0a` | Inputs, code blocks, raw evidence |
| Accent (10%) | `--scoria-action` | `#b94f31` | `#e65a32` | Reserved list below |
| Destructive | `--scoria-danger-action` | `#9e2f20` | `#ff6b4a` | Dismiss, reject, destructive confirmation controls only |

Accent reserved for:
- Primary CTAs: `Promote in Dataset Builder`, `Request baseline approval in Dataset Builder`, `Create dataset item` when backed by existing promotion behavior.
- Active Improve nav item and command-palette row focus.
- Active table sort indicator and density toggle selected state.
- Notebook active tab underline.
- Focus rings via `--scoria-focus-ring`.
- Selected Review Queue row border/badge, paired with `aria-current` or explicit "Selected" text.

Semantic tone usage:
- `:pass` for approved, healthy, active, completed.
- `:info` for running, queued, reference, in progress.
- `:warn` for pending, needs review, approval requested, degraded.
- `:fail` for failed, rejected, denied, unhealthy.
- `:trace` for replay, trace, candidate, promotion candidate.
- `:neutral` for unknown, default, archived, unselected.

Status is never color-only. Every badge and span must carry visible text.

---

## Screen Visual Contracts

### Dataset Builder

Focal point: the dataset table is the primary visual anchor. The promotion drawer is secondary and always sits over a still-visible dataset context.

Required shape:
- Index title: `Dataset Builder`.
- Subtitle: `Curate production traces into eval datasets and baseline approval requests.`
- Metric strip from real dataset counts only: open datasets, sealed datasets, candidate promotions, approval requests if already available.
- `<.table id="datasets">` with columns: Dataset, State, Items, Last promoted, Source, Action.
- Empty state uses `<.empty_state>` and no sample rows.
- Promotion state is URL-driven with `handle_params/3`, stable IDs, and a shared `<.drawer>` by default. Use `<.modal>` only if the reused promotion form cannot fit responsibly inside the drawer.
- Same-LiveView changes use `push_patch`/patch semantics. Cross-screen entry from Review Queue or Workflow Show uses navigation into `/datasets`.

### Review Queue

Focal point: the review table is primary; the selected candidate detail rail is secondary; the metric strip is tertiary.

Required shape:
- Index title only; no object breadcrumb.
- Subtitle: `Review flagged traces before they become datasets, baselines, or dismissed noise.`
- Compact `<.metric>` strip from current `@summary`.
- Filter panel with `<.field>` selects and form-level `phx-change`.
- `<.table id="review-queue">` columns: Candidate, Severity, Score, Sample, Promotion, Action.
- Selected row state must include `aria-current` or explicit `Selected` badge/text, not color alone.
- Detail rail keeps `Open run`, `View runtime context`, and `Dismiss candidate`.
- Dataset selection, expected-output editing, direct promotion, and sealed-baseline target selection move to Dataset Builder.

### Incidents

Focal point: the selected incident and its evidence notebook are primary; the incident list/filter context is secondary.

Required shape:
- Convert `IncidentsLive.Index` to shared panels, badges, metrics, fields, and table/list treatment.
- Convert only `IncidentEvidenceComponent` among evidence adapters in this phase.
- Preserve the existing evidence data contract: health rollup, budget, incident notebook, breaker/relay, and delivery outcomes.
- Incident-to-run and incident-to-trace links keep origin context.

### Eval Workbench

Focal point: evaluated dataset/spec and regression outcome are primary; prompt release and regressed-run next steps are secondary.

Required shape:
- Use shared tables, panels, fields, badges, and empty states.
- Preserve existing backed edit/results behavior.
- Keep links to prompt releases and regressed source runs.
- Do not add experiment controls, fake charts, playground affordances, or wizard/stepper language.

### Prompt Registry and Release Workbench

Focal point for Prompt Registry: prompt versions table and release eligibility.

Focal point for Release Workbench: object header plus side-by-side Draft Candidate and Active Baseline comparison panels.

Required shape:
- Keep Prompt Registry and Eval Workbench as separate Improve surfaces.
- Prompt Registry uses shared table/form components and preserves prompt editing/version behavior.
- Release Workbench uses `<.object_header>`, compact next-step row, two shared comparison panels, text-labeled badges, and shared approve/reject modals.
- Next-step verbs stay flat: `View eval results`, `View baseline runs`.
- No hidden client-side experiment state, generated prompt variants, model playground controls, or capability-implying UI unless already backed.

---

## Interaction Contracts

Dataset Builder promotion URLs:
- `/datasets?promote=workflow&run_id=...&step_id=...&source_variant=original`
- `/datasets?promote=workflow&run_id=...&step_id=...&source_variant=replay`
- `/datasets?promote=review&review_candidate_id=...`

Rules:
- Query params carry stable IDs and intent only. Never embed raw snapshots or expected-output JSON in params.
- Invalid, stale, or missing IDs show exact empty/error states and keep the user on Dataset Builder.
- Dataset Builder reconstructs promotion context server-side from existing records and calls existing promotion APIs.
- Source screens use `Promote in Dataset Builder` and `Request baseline approval in Dataset Builder` links instead of source-local dataset management.
- Tables keep density controls, visible sort state, and text headers. Mobile may collapse detail surfaces into drawers; do not invent separate mobile-only workflows.
- Drawers and modals keep the existing close button, scrim click, and Escape dismissal contract.

---

## Copywriting Contract

Voice: calm, exact, useful. Prefer evidence verbs: traced, scored, compared, replayed, promoted, gated, approved, denied.

| Element | Copy |
|---------|------|
| Dataset Builder nav label | `Dataset Builder` |
| Dataset Builder subtitle | `Curate production traces into eval datasets and baseline approval requests.` |
| Dataset Builder primary CTA | `Promote in Dataset Builder` |
| Sealed baseline CTA | `Request baseline approval in Dataset Builder` |
| Dataset Builder empty heading | `No datasets yet` |
| Dataset Builder empty body | `Promote a flagged trace or workflow source to start a regression dataset.` |
| Invalid promotion heading | `Promotion source not found` |
| Invalid promotion body | `The source ID no longer resolves. Return to the originating run or review item and open Dataset Builder again.` |
| Review Queue subtitle | `Review flagged traces before they become datasets, baselines, or dismissed noise.` |
| Review Queue empty heading | `No flagged traces for this filter set` |
| Review Queue empty body | `Production traces that fail scoring, trigger policy, or look promotion-ready will appear here.` |
| Review Queue selected marker | `Selected` |
| Review Queue detail CTAs | `Open run`; `View runtime context`; `Promote in Dataset Builder`; `Dismiss candidate` |
| Incidents empty heading | `No open incidents` |
| Incidents empty body | `Runtime failures, breaker trips, and delivery issues will appear here with links back to the affected run.` |
| Eval Workbench empty heading | `No eval runs yet` |
| Eval Workbench empty body | `Promote a production trace to a dataset, then run an eval to compare prompt behavior against a baseline.` |
| Prompt Registry empty heading | `No prompt versions yet` |
| Prompt Registry empty body | `Prompt versions appear after backed prompt edits are recorded.` |
| Release Workbench next steps | `View eval results`; `View baseline runs` |
| Generic loading label | `Loading...` |
| Generic recoverable error | `{Object} could not be loaded. Check the ID or return to the previous screen and try again.` |

Destructive confirmations:
- `Dismiss candidate`: confirmation heading `Dismiss this candidate?`; body `The trace leaves the active review queue, but its run evidence remains available.`; confirm button `Dismiss candidate`; alternate action `Keep reviewing`.
- `Reject release candidate`: confirmation heading `Reject this release candidate?`; body `The active baseline stays unchanged and the candidate remains in prompt history.`; confirm button `Reject release candidate`; alternate action `Keep comparing`.

Prohibited copy:
- Generic CTAs such as `Submit`, `OK`, `Cancel`, `Save`, or `Click here`.
- "Something went wrong", "No data found", "Nothing here", hype language, model anthropomorphism, or hidden chain-of-thought language.

---

## Accessibility and Responsive Contract

- WCAG 2.1 AA remains the target.
- Status is never conveyed by color alone; every badge includes visible text.
- Icon-only controls require `aria-label` or visible label fallback.
- Focus-visible states use the existing `--scoria-focus-ring` token and must not be suppressed.
- Tables must remain scannable at desktop widths and usable on narrow widths through responsive column priority, drawer detail surfaces, or horizontal table overflow where already established.
- Review Queue selected state must be announced semantically with `aria-current`, `aria-selected`, or equivalent plus visible text.
- Drawer/modal focus and Escape dismissal follow existing `ScoriaWeb.UI` contracts.
- No infinite motion, bounce, sparkle, decorative graph, or marketing composition patterns.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable - not a React project |
| Third-party | none | not applicable |

---

## DS-06 Raw-Palette Contract

Phase 14 must remove in-scope raw-palette leakage for every touched screen/component. Nonzero baseline rows are deleted only after the corresponding file reaches zero DS-06 raw-palette matches.

| File | Current Baseline | Contract |
|------|------------------|----------|
| `lib/scoria_web/live/review_queue_live.ex` | 76 | Convert to shared components; reach zero matches; remove row |
| `lib/scoria_web/live/incidents_live/index.ex` | 10 | Convert shell/list; reach zero matches; remove row |
| `lib/scoria_web/components/incident_evidence_component.ex` | 69 | Convert allowed evidence exception; reach zero matches; remove row |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | 68 | Convert for Dataset Builder embedding; reach zero matches; remove row |
| `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | 37 | Convert comparison/notice/modal/rail UI; reach zero matches; remove row |
| `lib/scoria_web/live/eval_spec_live/index.ex` | 0 | Keep at zero while converting to shared components |
| `lib/scoria_web/live/prompt_live/index.ex` | 0 | Keep at zero while converting to shared components |
| `lib/scoria_web/dashboard_nav.ex` and `lib/scoria_web/router.ex` | 0 | Add Dataset Builder without palette classes |

Verification command for each implementation slice: `mix test test/scoria_web/ds06_drift_guard_test.exs`.

---

## Pre-Populated From

| Source | Decisions Used |
|--------|----------------|
| `14-CONTEXT.md` | 25 locked implementation decisions plus deferred scope boundaries |
| `14-RESEARCH.md` | Stack, target files, raw-palette inventory, validation map, security notes |
| `12-UI-SPEC.md` | Existing token/component contracts and spacing/type exceptions |
| `brandbook/brand-book.md` | Palette, voice, typography, accessibility constraints |
| `lib/scoria_web/ui.ex` | Component inventory and interaction APIs |
| User input this session | 0 new answers needed; upstream artifacts answered the design choices |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS - specific CTAs, actionable empty/error states, and destructive confirmations are declared.
- [x] Dimension 2 Visuals: PASS - each in-scope screen declares focal point, hierarchy, and component shape.
- [x] Dimension 3 Color: PASS - 60/30/10 surface split, explicit accent reservation, semantic tones, and destructive color are declared.
- [x] Dimension 4 Typography: PASS - 4 type tiers and 2 weights are declared; existing 11px badge token is documented as an implementation detail.
- [x] Dimension 5 Spacing: PASS - standard spacing scale is declared; existing 12px component internals are justified as locked CSS behavior.
- [x] Dimension 6 Registry Safety: PASS - no shadcn or third-party registries are used.

**Approval:** approved 2026-06-12
