# Phase 14: least-iterated-screens-polish - Research

**Researched:** 2026-06-12  
**Domain:** Phoenix LiveView operator dashboard polish, design-system adoption, dataset-promotion routing  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Dataset Builder as Canonical Promotion Destination
- **D-01:** Build a real `ScoriaWeb.DatasetLive.Index` mounted at `/datasets`. Add **Dataset Builder** to the Improve nav after Review Queue and before Eval Workbench. Add it to `DashboardNav.@views`, `strip_known_prefixes/1`, command palette navigation, and the `g d` shortcut. Dataset Builder is not a stub and must not use fake rows.
- **D-02:** Dataset Builder owns dataset curation and promotion UX. The index lists open and sealed datasets using shared components (`<.table>`, `<.badge>`, `<.metric>`, `<.panel>`, `<.empty_state>`). Promotion opens inside Dataset Builder using a shared `<.drawer>` or `<.modal>` driven by URL context.
- **D-03:** Promotion URLs carry stable IDs and intent, not raw snapshots. Supported shapes should be equivalent to `/datasets?promote=workflow&run_id=...&step_id=...&source_variant=...` and `/datasets?promote=review&review_candidate_id=...`. The LiveView reconstructs promotion context from existing records; raw promotion snapshots and expected-output JSON are never embedded in query params.
- **D-04:** Within Dataset Builder, use LiveView patch semantics for drawer state and target dataset selection where the current LiveView stays mounted. Use navigate only when crossing from source screens into Dataset Builder. Validate stale or missing IDs and show calm, exact empty/error states.
- **D-05:** Reuse/refactor the current `DatasetLive.PromoteComponent` behavior and the existing `Eval` / `DatasetPromotion` functions. Do not add a new backend promotion model, a new "Promotion Workbench" noun, or altered sealed-baseline mutation rules.
- **D-06:** Source screens converge on Dataset Builder. Review Queue and Workflow Show may be touched only to replace existing promote affordances with "Promote in Dataset Builder" / "Request baseline approval in Dataset Builder" links or navigations. Broader Workflow Show polish remains Phase 15.

### Review Queue Conversion Model
- **D-07:** Keep Review Queue as a single LiveView and preserve the fast master-detail triage flow. Convert it to shared components rather than adding `/reviews/:id`, a lane board, or a separate review workbench.
- **D-08:** Recommended screen shape: index title only (no object breadcrumb), subtitle `Review flagged traces before they become datasets, baselines, or dismissed noise.`, compact metric strip from current `@summary`, filter panel with `<.field>` selects, `<.table id="review-queue">`, and a selected-candidate detail rail on desktop.
- **D-09:** Table columns should prioritize operator scanability: Candidate (rationale plus short trace/run IDs), Severity, Score, Sample, Promotion, and an action cell. Selected row state must not be color-only; use `aria-current` and/or explicit selected text/badge.
- **D-10:** The detail rail keeps triage pivots (`Open run`, `View runtime context`) and dismiss action. Dataset selection, expected-output editing, direct promotion, and sealed-baseline target picking move to Dataset Builder. This makes Review Queue an ingress surface, not a second dataset-management surface.
- **D-11:** Mobile detail may use the same content in `<.drawer>` if needed for usability, but avoid inventing mobile-only behavior. Keep form-level `phx-change` for filters; do not introduce LiveView streams unless research/planning finds a real scaling need.
- **D-12:** Do not add reviewer assignment, rubric editing, corrected-output authoring, bulk actions, annotation scoring, or lane/kanban workflow semantics in Phase 14. Those are future product capabilities, not polish.

### Eval Workbench and Prompt Registry / Release Workbench
- **D-13:** Keep Eval Workbench and Prompt Registry as separate Improve surfaces connected by quality-loop verbs. Do not merge them into a giant "Improve Workbench" tab shell.
- **D-14:** Eval Workbench should answer: what was evaluated, against which dataset/spec, what regressed, and where the operator goes next. Use shared tables/panels/forms and preserve existing links to prompt releases and regressed source runs.
- **D-15:** Prompt Registry should answer: which prompt versions exist, what state they are in, and which candidate can be released. Keep prompt editing on the existing backed behavior; do not add fake prompt experiment controls.
- **D-16:** Release Workbench stays a focused object page. It uses `object_header`, a compact next-step verb row (`View eval results`, `View baseline runs`), two shared comparison panels for Draft Candidate and Active Baseline, text-labeled status badges, shared approve/reject modals, and semantic notice/toast/flash treatment.
- **D-17:** Avoid steppers, wizard language, hidden client-side experiment state, model/prompt playground controls, and any UI that implies experiments can be run unless that capability is already backed by existing code.

### Incidents Evidence Boundary
- **D-18:** Convert `lib/scoria_web/live/incidents_live/index.ex` to shared components/tokens as normal SCREEN-01 work.
- **D-19:** Phase 14 has exactly one evidence-adapter exception: convert only `lib/scoria_web/components/incident_evidence_component.ex` into a thin local notebook/panel adapter because it is first-order Incidents screen content and blocks honest SCREEN-01 completion.
- **D-20:** Preserve the existing incident evidence data contract and section content: health rollup, budget, incident notebook, breaker/relay, and delivery outcomes. Change UI/IA/DX only.
- **D-21:** Do not convert `delegated_evidence_component`, `semantic_evidence_notebook_component`, `replay_evidence_notebook_component`, `trace_tree_component`, workflow detail panels, or other evidence adapters. Phase 15 still owns the broad evidence-adapter sweep, minus this one already-converted component if Phase 14 completes it.

### Cross-Screen Polish Rules
- **D-22:** For every in-scope screen/component touched by Phase 14, remove raw palette classes and shrink/remove the corresponding `test/support/ds06_baseline.txt` row. In-scope targets include Review Queue, Incidents page, IncidentEvidenceComponent, Eval Workbench, Prompt Registry, Release Workbench, Dataset Builder, and the minimum route/nav/source affordance files needed for Dataset Builder.
- **D-23:** Use Scoria brand voice everywhere: calm + exact + useful. Prefer evidence verbs: traced, scored, compared, replayed, promoted, gated, approved, denied. Do not anthropomorphize the model, expose hidden chain-of-thought, use hype copy, or label status by color alone.
- **D-24:** Bind to the existing runtime token system. Do not touch `assets/css/02-tokens.css` for cosmetic preference. Token propagation is reserved for WCAG/accessibility defects or genuine coherence breaks.
- **D-25:** UI polish should use conventional operator-dashboard components: tables, filters, panels, drawers/modals, badges, empty states, object headers, and notebook shells. Avoid decorative cards, marketing composition, graph visualizations, fake timelines, and "vanity dashboard" metrics.

### the agent's Discretion
- Exact component slot shapes, CSS class names, plan slicing, test file organization, route-param names, and whether Dataset Builder's promotion surface is a drawer or modal are planner/executor discretion, constrained by the decisions above.
- Small additions to `ui.ex` are acceptable only if they generalize a repeated Phase 14 need and preserve the token gateway. Prefer existing components first.
- The planner may choose whether Review Queue's detail surface is a sticky desktop rail, a panel column, or a responsive drawer implementation, as long as the workflow remains fast and accessible.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Broad evidence-adapter conversion across all 13 evidence components remains Phase 15.
- Live Ops / Workflows / Approvals / Connectors polish remains Phase 15.
- Full motion/responsive/theme parity sweep remains Phase 16.
- Final screenshot-contact-sheet proof and MAINTAINERS component catalog remain Phase 17.
- Full prompt/model experiment playground, generated prompt variants, side-by-side run controls, and model-parameter tuning are future backend-backed capabilities.
- Review Queue reviewer assignment, corrected-output authoring, human annotation scoring, bulk actions, lane/kanban workflow, and row-keyboard shortcuts are future capabilities.
- Dataset imports/CSV upload, schema builders, archive/delete management, synthetic dataset generation, and batch add observations are future Dataset Builder expansions unless already trivially backed.
- No todo matches were found for Phase 14, so no todos were folded or reviewed.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCREEN-01 | Review Queue, Incidents, Eval Workbench, and Prompt Registry / Release Workbench render through shared components with zero raw-palette leakage and meet the rubric bar. [VERIFIED: .planning/REQUIREMENTS.md] | Target files, shared component inventory, DS-06 baseline rows, and existing tests are mapped below. [VERIFIED: codebase grep] |
| SCREEN-02 | A real Dataset Builder index is the canonical promote-to-dataset destination, converging duplicated promote affordances. [VERIFIED: .planning/REQUIREMENTS.md] | `/datasets` route/nav additions, `DatasetLive.PromoteComponent` reuse, and promotion-context reconstruction paths are mapped below. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 14 should be planned as a Phoenix LiveView design-system adoption phase with one new route: `ScoriaWeb.DatasetLive.Index` at `/datasets`. [VERIFIED: 14-CONTEXT.md] No new packages, no new backend capability family, and no fake data are needed; existing Ecto contexts already expose datasets, review candidates, workflow promotion snapshots, eval runs, prompt templates, and prompt release actions. [VERIFIED: codebase grep]

The highest-risk planning item is Dataset Builder because it changes ownership of promotion UX. [VERIFIED: 14-CONTEXT.md] Current Review Queue and Workflow Show surfaces still contain direct promotion/modal behavior, but the locked direction is to route those affordances into Dataset Builder with stable IDs and reconstruct context server-side. [VERIFIED: codebase grep]

**Primary recommendation:** Plan five slices: nav/route/Dataset Builder shell; Dataset Builder promotion-context reconstruction and component reuse; Review Queue conversion/affordance convergence; Incidents plus the one allowed IncidentEvidence adapter; Eval/Prompt/Release shared-component conversion and DS-06 ratchet updates. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists at the project root, so there are no project-specific AGENTS directives to apply. [VERIFIED: shell `test -f AGENTS.md`]

No project-local `.codex/skills` or `.agents/skills` directory was found in this checkout. [VERIFIED: shell `find .codex .agents -maxdepth 3 -name SKILL.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Screen conversion to shared components | Browser / Client | Frontend Server (LiveView) | HEEx renders semantic classes and LiveView handles events/state; no backend data model change is required. [VERIFIED: codebase grep] |
| Dataset Builder index | Frontend Server (LiveView) | API / Backend (Eval context) | The new LiveView owns routing, URL state, and curation UI while using existing `Eval.list_datasets/0`, `Eval.list_dataset_items/1`, and promotion APIs. [VERIFIED: codebase grep] |
| Promotion context reconstruction | API / Backend | Frontend Server (LiveView) | Query params are untrusted IDs; LiveView should validate params and load canonical workflow/review records before calling existing backend promotion builders. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [VERIFIED: codebase grep] |
| DS-06 raw-palette enforcement | Test / CI | Frontend Server | `test/scoria_web/ds06_drift_guard_test.exs` scans `lib/scoria_web/**/*.{ex,heex}` and enforces current counts against `test/support/ds06_baseline.txt`. [VERIFIED: codebase grep] |
| Screenshot/rubric proof | Dev tooling | Browser / Client | `mix scoria.ui.shots` is dev-only and not merge-blocking CI; use it as a planning/QA checkpoint, not as the primary automated gate. [VERIFIED: docs/MAINTAINERS.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.7 locked | Dashboard routing/layout foundation. [VERIFIED: mix deps] | Existing `scoria_dashboard/2` macro mounts all dashboard LiveViews inside one live session. [VERIFIED: codebase grep] |
| Phoenix LiveView | 1.1.30 locked | Stateful screens, patch/navigate behavior, LiveComponents, LiveViewTest. [VERIFIED: mix deps] | Existing target screens are LiveViews and shared promotion UI is a LiveComponent. [VERIFIED: codebase grep] |
| Ecto / Ecto SQL | 3.13.6 / 3.13.5 locked | Dataset, review, eval, prompt, incident persistence. [VERIFIED: mix deps] | Existing contexts already expose required records and mutation functions. [VERIFIED: codebase grep] |
| ScoriaWeb.UI | repo-local | Token gateway components: `panel`, `metric`, `object_header`, `empty_state`, `modal`, `drawer`, `field`, `notebook`, `raw_evidence`, `table`, `badge`, `button`. [VERIFIED: codebase grep] | Phase 12 locked `ui.ex` as the enforced token gateway. [VERIFIED: 12-CONTEXT.md] |
| DS-06 drift guard | repo-local ExUnit | Raw palette ratchet. [VERIFIED: codebase grep] | The guard fails stale baselines and new/grown palette leakage. [VERIFIED: codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Floki | 0.38.1 locked | HTML assertions in LiveView tests. [VERIFIED: mix.lock] | Existing tests parse links with Floki; use for href/ARIA assertions if string checks become brittle. [VERIFIED: codebase grep] |
| Node.js / Playwright dev tooling | Node v22.14.0, npm 11.1.0; local Playwright package present | Optional screenshot/e2e proof. [VERIFIED: shell probes] | Use `mix scoria.ui.shots` or `mix scoria.ui.e2e` after starting a dev server when a visual proof pass is useful. [VERIFIED: mix help] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `ScoriaWeb.UI` components | New Tailwind utility markup | Rejected by DS-06/token-gateway decisions; new raw-palette markup will fail or increase baseline debt. [VERIFIED: 12-CONTEXT.md] |
| `DatasetLive.PromoteComponent` reuse | New promotion model/workbench | Rejected by D-05; existing APIs already implement draft promotion and sealed-baseline approval. [VERIFIED: 14-CONTEXT.md] [VERIFIED: codebase grep] |
| LiveView patch for Dataset Builder drawer state | Full page reload or separate promote route | Patch keeps the current LiveView mounted for same-screen param changes; official docs specify patch for current-LiveView URL/param changes. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |

**Installation:** no package installation is recommended for Phase 14. [VERIFIED: codebase grep]

## Package Legitimacy Audit

No external packages are recommended or installed for this phase. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | — | — | — | — | — | No package install required. [VERIFIED: codebase grep] |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: no recommended package installs]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no recommended package installs]

## Architecture Patterns

### System Architecture Diagram

```text
Review Queue / Workflow Show
  └─ navigate to /datasets?promote=...&stable_id=...
       ↓
DatasetLive.Index handle_params
  ├─ promote=review → Eval.get_review_candidate(review_candidate_id)
  ├─ promote=workflow → Workflows/Runtime records reconstruct selected comparison entry
  └─ invalid/stale IDs → exact empty/error state
       ↓
Dataset Builder index
  ├─ Eval.list_datasets + Eval.list_dataset_items
  ├─ <.table>/<.badge>/<.metric>/<.panel>/<.empty_state>
  └─ <.drawer> or <.modal> containing reused/refactored PromoteComponent
       ↓
Existing promotion APIs
  ├─ Eval.promote_workflow_source → open dataset item insert
  └─ Workflows.request_baseline_promotion → sealed baseline approval request
```

All arrows reflect existing or locked data flow, except the new `DatasetLive.Index` route that Phase 14 must add. [VERIFIED: 14-CONTEXT.md] [VERIFIED: codebase grep]

### Recommended Project Structure

```text
lib/scoria_web/live/dataset_live/
├── index.ex              # new canonical Dataset Builder LiveView [VERIFIED: 14-CONTEXT.md]
└── promote_component.ex  # existing behavior to reuse/refactor [VERIFIED: codebase grep]

test/scoria_web/live/dataset_live/
├── index_test.exs                 # new route/index/promotion-context tests [VERIFIED: inferred from existing test layout]
└── promote_component_test.exs     # existing behavior tests to preserve/update [VERIFIED: codebase grep]
```

### Pattern 1: Route-Level LiveView Owns URL State

**What:** Use `handle_params/3` in `DatasetLive.Index` to parse `promote`, IDs, selected dataset, and drawer/modal state. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

**When to use:** Use `patch` / `push_patch` for URL changes that stay within `/datasets`; use `navigate` links from Review Queue or Workflow Show into `/datasets`. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [VERIFIED: 14-CONTEXT.md]

**Example:**

```elixir
# Source: Phoenix LiveView live-navigation docs + existing ReleaseWorkbench handle_params pattern.
def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, :promotion_context, promotion_context_from_params(params))}
end
```

### Pattern 2: Shared Component Conversion Is a Ratchet Slice

**What:** For each touched screen, replace raw Tailwind palette classes with `ScoriaWeb.UI` components or semantic `.scoria-*` classes and immediately lower/remove its DS-06 baseline row. [VERIFIED: 12-CONTEXT.md] [VERIFIED: codebase grep]

**When to use:** Every Phase 14 screen slice; the DS-06 stale-baseline test fails if the file count drops but the baseline is not updated. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: lib/scoria_web/ui.ex
<.panel>
  <:title>Dataset Builder</:title>
  <.table id="datasets" rows={@datasets}>
    <:col :let={dataset} label="Dataset" key={:name}>{dataset.name}</:col>
  </.table>
</.panel>
```

### Pattern 3: LiveComponent Only for Encapsulated Stateful Promotion UI

**What:** Keep or refactor `DatasetLive.PromoteComponent` as the stateful promotion surface; use function components for static/shared visual shells. [VERIFIED: codebase grep] Official LiveView docs recommend LiveComponents when encapsulating event handling and state, and prefer function components otherwise. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html]

**When to use:** Promotion form validation, dataset target selection, save/request approval events. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: existing WorkflowLive.Show and DatasetLive.PromoteComponent pattern.
<.live_component
  module={ScoriaWeb.DatasetLive.PromoteComponent}
  id="dataset-builder-promote"
  promotion_context={@promotion_context}
  scoria_base={assigns[:scoria_base] || ""}
/>
```

### Component Responsibilities

| Component / File | Responsibility | Planning Notes |
|------------------|----------------|----------------|
| `lib/scoria_web/dashboard_nav.ex` | Nav SSOT, command palette rows, shortcuts, active keys, base stripping. [VERIFIED: codebase grep] | Add Dataset Builder between Review Queue and Eval Workbench; add `g d`; add `/datasets` to suffix stripping and views. [VERIFIED: 14-CONTEXT.md] |
| `lib/scoria_web/router.ex` | Dashboard route registration. [VERIFIED: codebase grep] | Add `live("/datasets", ScoriaWeb.DatasetLive.Index, :index)` inside `scoria_dashboard/2`. [VERIFIED: 14-CONTEXT.md] |
| `lib/scoria_web/live/review_queue_live.ex` | Single master-detail triage surface. [VERIFIED: codebase grep] | Remove direct dataset target picking/promotion events from UI; keep dismiss/open-run/open-runtime. [VERIFIED: 14-CONTEXT.md] |
| `lib/scoria_web/live/workflow_live/show.ex` | Existing run object page and source promote affordance. [VERIFIED: codebase grep] | Minimum touch only: route promote action to Dataset Builder; broader raw-palette cleanup stays Phase 15 except touched lines. [VERIFIED: 14-CONTEXT.md] |
| `lib/scoria_web/live/incidents_live/index.ex` | Incident list + selected evidence surface. [VERIFIED: codebase grep] | Convert shell/list to shared components and preserve incident run/trace origin links. [VERIFIED: codebase grep] |
| `lib/scoria_web/components/incident_evidence_component.ex` | First-order Incidents evidence content. [VERIFIED: codebase grep] | Only allowed evidence-adapter exception; convert to local notebook/panel adapter while preserving sections. [VERIFIED: 14-CONTEXT.md] |
| `lib/scoria_web/live/eval_spec_live/index.ex` | Eval Workbench list/edit/results. [VERIFIED: codebase grep] | Convert two tables and edit form to shared table/field/panel; preserve prompt release and regressed-run links. [VERIFIED: codebase grep] |
| `lib/scoria_web/live/prompt_live/index.ex` | Prompt Registry list/edit/token estimate. [VERIFIED: codebase grep] | Convert table/form while preserving backed edit/version behavior. [VERIFIED: codebase grep] |
| `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | Prompt release object page. [VERIFIED: codebase grep] | Already has `object_header`; convert comparison deck, notices, rail, and modals to shared components. [VERIFIED: codebase grep] |

### Anti-Patterns to Avoid

- **Embedding snapshots in query params:** Query params should carry stable IDs and intent only; reconstruct promotion context from records. [VERIFIED: 14-CONTEXT.md]
- **Adding `/reviews/:id`:** Review Queue remains one LiveView. [VERIFIED: 14-CONTEXT.md]
- **Adding a new promotion model:** Reuse `Eval.DatasetPromotion`, `Eval.promote_workflow_source/1`, and `Workflows.request_baseline_promotion/1`. [VERIFIED: codebase grep]
- **Leaving stale DS-06 rows:** The current guard fails when a file falls below baseline but the row is not lowered. [VERIFIED: codebase grep]
- **Touching all evidence adapters:** Only `IncidentEvidenceComponent` is in scope; broad adapter sweep remains Phase 15. [VERIFIED: 14-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dataset promotion persistence | New promotion schema/workbench | `Eval.DatasetPromotion`, `Eval.promote_workflow_source/1`, `Workflows.request_baseline_promotion/1` | Existing code handles frozen workflow snapshots, open dataset inserts, sealed-dataset errors, and approval requests. [VERIFIED: codebase grep] |
| Review candidate projection | Custom review SQL in LiveView | `Eval.list_review_queue/1`, `Eval.summarize_review_queue/1`, `Eval.get_review_candidate/1` | Existing projection builds severity, summary, runtime/run paths, promotion context, and lineage. [VERIFIED: codebase grep] |
| Modal/drawer shells | Bespoke fixed div overlays | `<.modal>` / `<.drawer>` | Phase 12 components standardize dismiss behavior and token classes. [VERIFIED: 12-UI-SPEC.md] [VERIFIED: codebase grep] |
| Tables/forms | Raw `<table>` / labels / inputs with utility classes | `<.table>`, `<.field>`, `<.form_section>` | These are the DS-01/DS-03 gateway components. [VERIFIED: 12-UI-SPEC.md] [VERIFIED: codebase grep] |
| Raw-palette scanning | Ad hoc grep-only checks | `mix test test/scoria_web/ds06_drift_guard_test.exs` | Existing ExUnit guard implements baseline growth and stale-baseline checks. [VERIFIED: codebase grep] |

**Key insight:** The phase is not about inventing UI capability; it is about moving existing behavior behind the shared component/token gateway and centralizing promotion UX in Dataset Builder. [VERIFIED: 14-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Dataset Builder Becomes Another Stub
**What goes wrong:** Planner adds `/datasets` route but leaves placeholder rows or fake copy. [VERIFIED: 14-CONTEXT.md]  
**Why it happens:** Phase 13 added honest stubs for reserved capabilities, but Dataset Builder is explicitly not a stub. [VERIFIED: 13-CONTEXT.md]  
**How to avoid:** Back the index with `Eval.list_datasets/0` and `Eval.list_dataset_items/1`; empty states must describe real absence. [VERIFIED: codebase grep]  
**Warning signs:** "Soon", sample rows, mock chart, or fabricated dataset counts on `/datasets`. [VERIFIED: 14-CONTEXT.md]

### Pitfall 2: Promotion Context Lost When Moving From Modal to Route
**What goes wrong:** Workflow Show currently computes `@promotion_context` in memory from selected comparison entry; navigating to `/datasets` loses that assign. [VERIFIED: codebase grep]  
**Why it happens:** Query params are limited to stable IDs by decision, so Dataset Builder must rebuild context. [VERIFIED: 14-CONTEXT.md]  
**How to avoid:** Implement reconstruction functions for `promote=review` via `Eval.get_review_candidate/1` and `promote=workflow` via run/detail/comparison records. [VERIFIED: codebase grep]  
**Warning signs:** URL includes encoded JSON, expected output, or full promotion snapshot. [VERIFIED: 14-CONTEXT.md]

### Pitfall 3: DS-06 Baseline Not Updated With Each Slice
**What goes wrong:** Code conversion reduces raw palette count but tests fail with stale baseline. [VERIFIED: codebase grep]  
**Why it happens:** The guard has a second assertion that counts below baseline must lower the baseline. [VERIFIED: codebase grep]  
**How to avoid:** Update `test/support/ds06_baseline.txt` whenever a touched file changes raw-palette count. [VERIFIED: codebase grep]  
**Warning signs:** `DS-06 drift guard: stale baseline` test failure. [VERIFIED: codebase grep]

### Pitfall 4: Converting Out-of-Scope Evidence Adapters
**What goes wrong:** Planner pulls Phase 15 adapter sweep into Phase 14. [VERIFIED: 14-CONTEXT.md]  
**Why it happens:** Incidents has one allowed exception, and adjacent evidence components also leak raw palette. [VERIFIED: codebase grep]  
**How to avoid:** Touch only `incident_evidence_component.ex` among evidence adapters. [VERIFIED: 14-CONTEXT.md]  
**Warning signs:** Edits to `delegated_evidence_component`, `semantic_evidence_notebook_component`, `replay_evidence_notebook_component`, or `trace_tree_component`. [VERIFIED: 14-CONTEXT.md]

### Pitfall 5: Replacing Backed Forms With Decorative UI
**What goes wrong:** Eval/Prompt surfaces become prettier but lose edit, token-estimate, approval, or release actions. [VERIFIED: codebase grep]  
**Why it happens:** Current screens are plain but backed by tests and contexts. [VERIFIED: codebase grep]  
**How to avoid:** Preserve existing event names and assertions unless a test is intentionally updated to the locked Dataset Builder behavior. [VERIFIED: codebase grep]

## Code Examples

### Route + Nav Additions

```elixir
# Source: lib/scoria_web/router.ex + lib/scoria_web/dashboard_nav.ex patterns.
live("/datasets", ScoriaWeb.DatasetLive.Index, :index)

%{
  key: :datasets,
  label: "Dataset Builder",
  path: "/datasets",
  icon: :grid,
  aliases: ["dataset", "datasets", "builder"],
}
```

### Source Screen Navigate Into Dataset Builder

```elixir
# Source: locked URL shape in 14-CONTEXT.md.
defp review_dataset_path(candidate, base) do
  "#{base}/datasets?" <>
    URI.encode_query([
      {"promote", "review"},
      {"review_candidate_id", candidate.id},
      {"from", "review:#{candidate.id}"}
    ])
end
```

### Dataset Builder Param Validation

```elixir
# Source: Phoenix LiveView handle_params docs + existing origin_context patterns.
def handle_params(%{"promote" => "review", "review_candidate_id" => id}, _uri, socket) do
  case Eval.get_review_candidate(id) do
    nil -> {:noreply, assign(socket, :promotion_error, "Review candidate not found.")}
    candidate -> {:noreply, assign(socket, :promotion_context, candidate.promotion_context)}
  end
end
```

### Shared Table Pattern

```elixir
# Source: lib/scoria_web/ui.ex table component API.
<.table id="review-queue" rows={@queue_rows} density={:compact}>
  <:filter>
    <.field id="review-state" label="Review state">
      <select id="review-state" name="filters[review_status]" class="scoria-input">
        <option value="pending">needs review</option>
      </select>
    </.field>
  </:filter>
  <:col :let={row} label="Candidate" key={:rationale}>{row.rationale}</:col>
  <:action :let={row}>
    <button phx-click="select_candidate" phx-value-id={row.id}>Select</button>
  </:action>
</.table>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Bespoke utility-class LiveView screens | `ScoriaWeb.UI` token-gateway components plus DS-06 ratchet | Phase 12, 2026-06-04 [VERIFIED: 12-CONTEXT.md] | Phase 14 should delete raw-palette leakage in target screens instead of adding new one-off classes. [VERIFIED: 14-CONTEXT.md] |
| Disjoint screen navigation | `DashboardNav.groups/0`, object headers, command palette, origin context | Phase 13, completed 2026-06-12 [VERIFIED: STATE.md] | Dataset Builder must join the same nav/shortcut/palette system. [VERIFIED: 14-CONTEXT.md] |
| Source-local promote modals | Canonical Dataset Builder destination | Phase 14 locked decision [VERIFIED: 14-CONTEXT.md] | Review Queue and Workflow Show become ingress links rather than promotion owners. [VERIFIED: 14-CONTEXT.md] |

**Deprecated/outdated:**
- Direct Review Queue dataset picking and direct promotion are outdated for Phase 14 because Dataset Builder owns that UX. [VERIFIED: 14-CONTEXT.md] [VERIFIED: codebase grep]
- Workflow Show's source-local promote modal should be routed to Dataset Builder by the minimum allowed touch, with broader Workflow Show polish deferred. [VERIFIED: 14-CONTEXT.md]

## Raw-Palette Inventory

| File | Current Baseline Count | Phase 14 Action |
|------|------------------------|-----------------|
| `lib/scoria_web/live/review_queue_live.ex` | 76 | Convert to shared components, reach zero raw-palette matches, and remove the baseline row. [VERIFIED: test/support/ds06_baseline.txt] |
| `lib/scoria_web/live/incidents_live/index.ex` | 10 | Convert shell/list to shared components, reach zero raw-palette matches, and remove the baseline row. [VERIFIED: test/support/ds06_baseline.txt] |
| `lib/scoria_web/components/incident_evidence_component.ex` | 69 | Convert allowed evidence exception to notebook/panel adapter, reach zero raw-palette matches, and remove the baseline row. [VERIFIED: test/support/ds06_baseline.txt] |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | 68 | Reuse/refactor under Dataset Builder, reach zero raw-palette matches, and remove the baseline row. [VERIFIED: test/support/ds06_baseline.txt] |
| `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | 37 | Convert comparison panels/notices/modals/rail, reach zero raw-palette matches, and remove the baseline row. [VERIFIED: test/support/ds06_baseline.txt] |
| `lib/scoria_web/live/eval_spec_live/index.ex` | 0 currently | Convert raw HTML to shared components; no baseline row exists. [VERIFIED: codebase grep] |
| `lib/scoria_web/live/prompt_live/index.ex` | 0 currently | Convert raw HTML to shared components; no baseline row exists. [VERIFIED: codebase grep] |
| `lib/scoria_web/dashboard_nav.ex` / `router.ex` | 0 currently | Add route/nav without palette classes. [VERIFIED: codebase grep] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Workflow-source promotion context can be reconstructed from existing run/detail/comparison records without adding backend APIs. [ASSUMED] | Architecture Patterns | Planner may need a small query/helper extraction from `WorkflowLive.Show` or runtime context to avoid duplicating private LiveView helper logic. |
| A2 | Dataset Builder does not need create/edit/seal dataset management beyond listing open/sealed datasets and promotion target selection. [ASSUMED] | Summary / Don't Hand-Roll | If user expects full dataset CRUD, Phase 14 scope would expand beyond locked decisions. |

## Open Questions (RESOLVED)

1. **RESOLVED — `DatasetLive.PromoteComponent` is visually converted in the same slice that embeds it in `/datasets`.**  
   - What we know: It has 68 raw-palette baseline matches and already owns promotion form behavior. [VERIFIED: codebase grep]  
   - Decision: Plan 14-02 embeds and converts the component in one slice so `/datasets` can honestly reach zero raw-palette leakage for the promotion surface. [VERIFIED: 14-CONTEXT.md]

2. **RESOLVED — Dataset Builder uses a drawer-first promotion surface.**  
   - What we know: User left drawer vs modal to planner discretion. [VERIFIED: 14-CONTEXT.md]  
   - Decision: Plan 14-02 uses `<.drawer id="dataset-promote-drawer">` for review/workflow promotion context so the dataset table remains the canonical backdrop; `<.modal>` remains reserved only for future cases where an existing backed form cannot fit responsibly inside the drawer. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/tests | ✓ | 1.19.5 | None needed. [VERIFIED: shell probe] |
| Erlang/OTP | Compile/tests | ✓ | 28 / ERTS 16.3 | None needed. [VERIFIED: shell probe] |
| Mix | Tests/tasks | ✓ | 1.19.5 | None needed. [VERIFIED: shell probe] |
| PostgreSQL | Ecto tests | ✓ | `pg_isready` accepting connections on `/tmp:5432` | None needed for local tests. [VERIFIED: shell probe] |
| Node.js | Optional screenshot/e2e tasks | ✓ | v22.14.0 | Skip visual proof if only LiveViewTest gate is needed. [VERIFIED: shell probe] |
| npm | Optional screenshot/e2e tasks | ✓ | 11.1.0 | Skip visual proof if only LiveViewTest gate is needed. [VERIFIED: shell probe] |
| Playwright local package | Optional `mix scoria.ui.e2e` / shots tooling | ✓ | `priv/dev/node_modules/@playwright/test` present | Use LiveViewTest-only validation if browser tooling is not required. [VERIFIED: shell probe] |
| Context7 CLI | Doc lookup | ✗ | — | Official HexDocs web pages used instead. [VERIFIED: shell probe] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |

**Missing dependencies with no fallback:** none found for normal planning and test execution. [VERIFIED: shell probe]  
**Missing dependencies with fallback:** Context7 CLI is missing; official HexDocs web lookup was used. [VERIFIED: shell probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest with Phoenix LiveView 1.1.30. [VERIFIED: mix deps] |
| Config file | `test/test_helper.exs` and per-test Phoenix endpoint modules. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/dashboard_nav_test.exs` [VERIFIED: mix help] |
| Full suite command | `mix test` [VERIFIED: mix help] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SCREEN-01 | Review Queue shared-component conversion, preserved triage links, no direct dataset management | LiveView integration | `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` | ✅ update needed [VERIFIED: codebase grep] |
| SCREEN-01 | Incidents shared-component conversion and IncidentEvidence adapter content preserved | LiveView integration | `mix test test/scoria_web/live/incidents_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` | ✅ update needed [VERIFIED: codebase grep] |
| SCREEN-01 | Eval Workbench shared table/form conversion and quality-loop links preserved | LiveView isolated | `mix test test/scoria_web/live/eval_spec_live/index_test.exs test/scoria_web/ds06_drift_guard_test.exs` | ✅ update needed [VERIFIED: codebase grep] |
| SCREEN-01 | Prompt Registry edit/token behavior and Release Workbench approval behavior preserved with shared UI | LiveView isolated/integration | `mix test test/scoria_web/live/prompt_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` | ✅ update needed [VERIFIED: codebase grep] |
| SCREEN-02 | `/datasets` route/nav/palette/shortcut exists and is not a stub | Unit + LiveView integration | `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs test/scoria_web/live/dataset_live/index_test.exs` | ❌ Wave 0 [VERIFIED: codebase grep] |
| SCREEN-02 | Dataset Builder reconstructs promotion context from review/workflow IDs and reuses promotion behavior | LiveView integration/component | `mix test test/scoria_web/live/dataset_live/index_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs` | ❌ Wave 0 for index; ✅ component test exists [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** targeted LiveView test(s) for touched screen + `mix test test/scoria_web/ds06_drift_guard_test.exs`. [VERIFIED: codebase grep]
- **Per wave merge:** `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/incidents_live_test.exs test/scoria_web/live/eval_spec_live/index_test.exs test/scoria_web/live/prompt_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria_web/ds06_drift_guard_test.exs`. [VERIFIED: codebase grep]
- **Phase gate:** Full `mix test`; optional visual pass via running dev server then `mix scoria.ui.shots` for rubric review. [VERIFIED: docs/MAINTAINERS.md] [VERIFIED: mix help]

### Wave 0 Gaps

- [ ] `lib/scoria_web/live/dataset_live/index.ex` — required by SCREEN-02. [VERIFIED: codebase grep]
- [ ] `test/scoria_web/live/dataset_live/index_test.exs` — route/index/promotion-context coverage. [VERIFIED: codebase grep]
- [ ] Update `test/scoria_web/dashboard_nav_test.exs` — Dataset Builder nav item, shortcut, command palette row, stub exclusion. [VERIFIED: codebase grep]
- [ ] Update `test/scoria_web/router_test.exs` if route coverage asserts known dashboard routes. [VERIFIED: codebase grep]
- [ ] Update `test/support/ds06_baseline.txt` after every in-scope conversion. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new auth | Dashboard session behavior remains existing host/session setup. [VERIFIED: codebase grep] |
| V3 Session Management | no new session model | No new cookies or client-side auth state should be added. [VERIFIED: 14-CONTEXT.md] |
| V4 Access Control | yes, existing dashboard data access | Preserve existing session tenant/actor patterns; do not widen access through query params. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Validate all `handle_params` IDs/intent values before lookup or mutation; LiveView docs treat params as untrusted. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| V6 Cryptography | no | No cryptographic changes are in scope. [VERIFIED: 14-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Dashboard

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Query-param tampering for `/datasets?promote=...` | Tampering | Allowlist `promote` values, validate UUID/integer IDs, load records server-side, and show exact not-found/error state. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Cross-tenant record disclosure through stable IDs | Information Disclosure | Preserve existing tenant/session filtering where available; do not trust IDs alone as authorization. [VERIFIED: codebase grep] |
| Sealed dataset mutation bypass | Tampering | Keep sealed-baseline path on `Workflows.request_baseline_promotion/1`; do not call direct item insert for sealed datasets. [VERIFIED: codebase grep] |
| XSS through raw JSON/output display | Information Disclosure / Tampering | Use HEEx escaping and existing `<.raw_evidence>`/`Jason.encode_to_iodata!` display patterns; do not mark promotion snapshots as raw HTML. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/14-least-iterated-screens-polish/14-CONTEXT.md` — locked implementation decisions, scope boundaries, target files. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` — SCREEN-01 and SCREEN-02 definitions. [VERIFIED: file read]
- `.planning/STATE.md` and `.planning/ROADMAP.md` — Phase 13 complete, Phase 14 position, adjacent phase boundaries. [VERIFIED: file read]
- `.planning/phases/12-design-system-component-layer/12-CONTEXT.md` and `12-UI-SPEC.md` — token gateway, DS-06 ratchet, component contracts. [VERIFIED: file read]
- `.planning/phases/13-orientation-spine-ia/13-CONTEXT.md` — nav/IA/origin-context constraints. [VERIFIED: file read]
- `lib/scoria_web/ui.ex`, `dashboard_nav.ex`, `router.ex`, target LiveViews/components, `Scoria.Eval`, `Scoria.Eval.DatasetPromotion`, `Scoria.Eval.ReviewQueue` — current implementation. [VERIFIED: codebase grep]
- `test/support/ds06_baseline.txt`, `test/scoria_web/ds06_drift_guard_test.exs`, target LiveView tests — validation surface. [VERIFIED: codebase grep]
- Phoenix LiveView HexDocs live navigation / LiveView / LiveComponent docs — patch/navigate, `handle_params`, LiveComponent responsibilities. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html]

### Secondary (MEDIUM confidence)

- `docs/MAINTAINERS.md` and `lib/mix/tasks/scoria.ui.shots.ex` — screenshot/critique harness usage and dev-only status. [VERIFIED: codebase grep]
- `priv/shots/gap_register.md` — baseline rubric findings for Eval/Prompt/Release density/responsive/a11y. [VERIFIED: file read]

### Tertiary (LOW confidence)

- None used as authoritative evidence. [VERIFIED: source log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions verified from `mix deps`, `mix.lock`, and shell probes. [VERIFIED: mix deps]
- Architecture: HIGH — locked decisions plus current code surfaces agree on LiveView/component/Ecto boundaries. [VERIFIED: 14-CONTEXT.md] [VERIFIED: codebase grep]
- Dataset Builder reconstruction details: MEDIUM — review-candidate reconstruction is directly available; workflow-source reconstruction likely needs helper extraction from current private WorkflowLive logic. [VERIFIED: codebase grep] [ASSUMED]
- Pitfalls: HIGH — most are direct consequences of locked decisions and existing tests. [VERIFIED: 14-CONTEXT.md] [VERIFIED: codebase grep]

**Research date:** 2026-06-12  
**Valid until:** 2026-07-12 for repo-local planning; re-check LiveView docs/dependency versions if dependencies change before implementation. [ASSUMED]
