# Phase 36: Baseline And Inventory - Research

**Researched:** 2026-06-20
**Domain:** Phoenix LiveView design-system inventory and baseline proof
**Confidence:** HIGH for repo-local inventory/proof findings; MEDIUM for Phoenix docs guidance; LOW for generic external inventory conventions.

## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Inventory Artifact Shape

- **D-01:** Produce a paired inventory artifact family: a human-readable Markdown inventory plus a structured companion index. The Markdown artifact owns rationale, examples, exclusions, research-backed guidance, risk narrative, and maintainer-readable baseline truth. The structured index owns canonical IDs, layer/status fields, file paths, route/component identifiers, state coverage, and machine-checkable relationships.
- **D-02:** Prefer boring repository-local artifacts over adding PhoenixStorybook or a runtime component lab in this phase. Phase 37 may build a dev-only lab from the inventory, but Phase 36 only defines the map and contract.
- **D-03:** Use stable identifiers from the start. Every component, page, hook, fixture, test, doc, and risk should have an ID that future phases can reference without relying on prose matching.
- **D-04:** Avoid duplicate source-of-truth drift. The Markdown inventory may summarize index rows, but canonical IDs and status fields live in the structured index.

### Classification Rules

- **D-05:** Classify every inventory row with both `layer` and `status`.
  - `layer`: `foundation`, `primitive`, `component-group`, `page`, `hook`, `fixture`, `test`, `doc`, `one-off`.
  - `status`: `canonical`, `duplicated`, `legacy`, `missing`, `intentionally-page-specific`.
- **D-06:** Every inventory row must include `id`, `name`, `layer`, `status`, `owner_path`, `evidence`, `replacement_or_owner`, `next_action`, and `risk_refs`.
- **D-07:** Mark `canonical` only when the item has a clear owner, stable API/token/route contract, representative usage, and appropriate tests or docs for its layer.
- **D-08:** Mark `duplicated` when two or more items solve the same UI job. Cite all relevant call sites and identify the preferred replacement or consolidation target.
- **D-09:** Mark `legacy` when still used but superseded. Include the migration target.
- **D-10:** Mark `missing` when repeated code, repeated copy, repeated tests, or documented needs imply an absent abstraction, state, fixture, proof, or doc.
- **D-11:** Mark `intentionally-page-specific` only when the behavior is tied to a named LiveView/page workflow and extracting it would leak domain context or reduce clarity.
- **D-12:** Phoenix ownership still matters inside the taxonomy. Function components with `attr`/`slot` contracts are the preferred primitive shape; LiveComponents are for stateful component behavior; JS hooks are for browser interop that `Phoenix.LiveView.JS` and server-rendered LiveView cannot cover cleanly; CSS remains token-scoped through the Scoria design system.

### Baseline Proof Boundary

- **D-13:** Use layered lightweight baseline proof. Phase 36 should cite git provenance, existing functional/design-system tests, and advisory screenshot evidence. It should not create a brittle visual gate.
- **D-14:** Git provenance must show the recent UI cleanup is committed separately before v3.3 planning work. Current evidence: UI cleanup commits include `1773267`, `d35906f`, `4337c5e`, `452f035`, `2d324a0`, and `f490cea`; v3.3 planning commits are `8540e04` and `2f2ad6e`.
- **D-15:** Existing proof should be reused before new proof is invented: ExUnit UI/component tests, DS-06 raw-palette guard, existing Playwright e2e files, `mix scoria.ui.shots`, `priv/shots/gap_register.md`, and `priv/shots/gap_register_final.md`.
- **D-16:** Screenshots in Phase 36 are advisory baseline evidence only. Do not promote screenshot diffs into required CI during this phase. Phase 41 may decide whether visual CI is mature enough.
- **D-17:** v3.0 proof gaps are inventory risks, not automatic regressions. They become implementation work only in the relevant later phase.

### Risk Coverage

- **D-18:** Use a hybrid risk model: a central `Known Risk Register` plus per-inventory-item `risk_refs`. Do not duplicate risk prose on every row.
- **D-19:** The risk register must include stable `risk_id`, title, affected JTBD/persona/operator flow, affected inventory refs, owner phase, mitigation/evidence target, status, and closeout proof.
- **D-20:** Required starting risks:
  - `RISK-V30-PROOF` - stale v3.0 proof gaps and partial verification-doc coverage.
  - `RISK-TOAST-LEGIBILITY` - approval warning/error toast readability over dense UI; owner phase 38.
  - `RISK-APPROVAL-HISTORY` - discoverability of approved/denied/expired approvals without implying in-place reversal; owner phase 39.
  - `RISK-RESPONSIVE-SCAN` - responsive tables/lists and mobile scan paths.
  - `RISK-OVERLAY-FOCUS` - drawers, modals, command palette, mobile nav, focus restoration, escape behavior, reduced motion, and theme parity.
- **D-21:** Fold the todo `Make approval toasts legible over dense UI` into `RISK-TOAST-LEGIBILITY` for Phase 38.
- **D-22:** Fold the todo `Add approval decision history` into `RISK-APPROVAL-HISTORY` for Phase 39.
- **D-23:** Every later phase that touches an item with `risk_refs` must either mitigate the risk, prove it unchanged, or explicitly defer it with evidence.

### Design, Product, And DX Lens

- **D-24:** Treat Scoria as an operator-first Phoenix library, not a hosted UI platform. The inventory should preserve boring embedded-library ergonomics: repo-local docs, Mix tasks, Ecto/Phoenix/LiveView-native proof, no runtime dependency expansion, and no hidden service assumptions.
- **D-25:** UI inventory judgments must be JTBD-first. The operator should see job-oriented surfaces and consequences, not backend implementation guts. Expose traces, spans, IDs, policies, and payloads as evidence when useful, not as primary orientation copy.
- **D-26:** Use the newer `brandbook/` as canonical brand truth. The UI direction is field-engineer, grounded, composed, operator-grade, Phoenix-native, evidence-led, dark/light/system safe, and volcanic without flame/phoenix/AI-magic tropes.
- **D-27:** The design pillars to consider for every UI inventory item are: accessibility, responsive behavior, theme parity, motion/reduced motion, performance and render stability, information hierarchy, affordance clarity, density/scannability, microcopy, evidence discoverability, keyboard/focus behavior, and brand fit.
- **D-28:** Prefer decisive defaults. Downstream agents should ask the user again only if a choice changes product shape, security/policy boundary, durable truth model, tenant blast radius, or materially different operator/adopter workflow.

### Reviewed Todos

- **Reviewed, not folded:** `CI policy job: -test-mix- cache key while compiling under MIX_ENV=dev (WR-01)` - out of scope for v3.3 UI inventory; keep as pending CI correctness follow-up.
- **Reviewed, not folded:** `Docker dev-DX fleet hardening - port-conflict-free multi-lib local DX` - out of scope for v3.3 UI inventory; keep as sibling/fleet DX follow-up.

### the agent's Discretion

Downstream research/planning agents may choose the exact file names and schema format for the structured index, but the recommendation is a Markdown inventory plus a structured data file under `.planning/phases/36-baseline-and-inventory/`. Keep the artifacts source-control friendly, diffable, and easy to review.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Do not add PhoenixStorybook in Phase 36. The roadmap already defers Storybook evaluation until after the dev-only component lab proves insufficient.
- Do not add screenshot-diff CI in Phase 36. Visual CI remains a future requirement (`VISUAL-CI-01`) unless Phase 41 finds the harness deterministic enough.
- Do not implement approval decision history in Phase 36. It is folded as a Phase 39 risk.
- Do not fix approval toast legibility in Phase 36. It is folded as a Phase 38 risk.
- Do not change core approval semantics to allow approving a denied request in place.
- Do not broaden into CI cache-key cleanup or sibling-repo Docker fleet hardening.

### Reviewed Todos (not folded)

- `CI policy job: -test-mix- cache key while compiling under MIX_ENV=dev (WR-01)` - not part of the v3.3 UI design-system inventory.
- `Docker dev-DX fleet hardening - port-conflict-free multi-lib local DX` - not part of the v3.3 UI design-system inventory.

## Summary

Phase 36 should produce two repository-local artifacts: `36-INVENTORY.md` for maintainer-readable rationale and `36-inventory.json` for stable IDs, paths, classifications, relationships, and risk refs. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] The phase should not install PhoenixStorybook, add a runtime component lab, change UI behavior, or promote screenshot diffs to CI. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

The implementation work is mostly discovery and classification over existing Scoria surfaces: `ScoriaWeb.UI`, `assets/css/*.css`, `assets/js/scoria.js`, dashboard layout files, `lib/scoria_web/live/`, `lib/scoria_web/components/`, tests under `test/scoria_web/`, Playwright specs under `priv/dev/e2e/`, screenshot artifacts under `priv/shots/`, and docs/brandbook files. [VERIFIED: codebase grep] The recent UI cleanup is already separated from v3.3 planning in git history: cleanup commits `1773267` through `f490cea` precede v3.3 planning commits `8540e04`, `2f2ad6e`, `d9097e8`, and `16b574b`. [VERIFIED: git log]

**Primary recommendation:** Plan Phase 36 as a baseline-proof plus inventory-writing phase that emits source-control-friendly Markdown and JSON, runs existing focused proof only, and blocks Phase 37+ until both artifacts exist. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BASE-01 | Maintainer can start v3.3 from a clean baseline that preserves the recent Scoria UI cleanup as committed prior art. | Git history already separates UI cleanup commits from v3.3 planning commits; plan should record this in the inventory baseline section. [VERIFIED: git log] |
| INV-01 | Maintainer can inspect a current inventory of UI foundations, `ScoriaWeb.UI` primitives, component groups, LiveView pages, CSS/JS hooks, fixtures, tests, and known one-off patterns. | The required surfaces exist across `lib/scoria_web`, `assets`, `test/scoria_web`, `priv/dev/e2e`, `priv/shots`, `docs`, and `brandbook`. [VERIFIED: codebase grep] |
| INV-02 | Maintainer can see which components and page patterns are canonical, legacy, duplicated, missing, or intentionally page-specific. | Context locks the `layer` and `status` enums and required row fields; plan should implement those fields in the structured index. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |

## Project Constraints (from CLAUDE.md / AGENTS.md)

- No root `CLAUDE.md`, `.claude/CLAUDE.md`, or root `AGENTS.md` was found in this workspace during research. [VERIFIED: codebase grep]
- No project-local `.claude/skills/` or `.agents/skills/` directory was found. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Baseline provenance | Repository / Git | Docs | Git commit ordering is the durable proof that cleanup preceded v3.3 planning. [VERIFIED: git log] |
| Design-system inventory | Docs / Planning artifacts | API / Backend for source references | Phase output is repository-local Markdown plus structured JSON, not runtime behavior. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |
| UI primitive classification | Frontend Server (LiveView) | CSS / Static assets | `ScoriaWeb.UI` owns function-component contracts, while CSS owns tokenized rendering. [VERIFIED: codebase grep] |
| Browser interop inventory | Browser / Client | Frontend Server (LiveView) | `assets/js/scoria.js` owns named hooks for copy, theme, command palette, dismissable overlays, mobile nav, and recents. [VERIFIED: codebase grep] |
| Risk register | Docs / Planning artifacts | Tests / Browser proof | Risks must have stable IDs and link to affected inventory refs and later owner phases. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Build, tests, docs, Mix tasks. | Current local runtime and project build system. [VERIFIED: `mix --version`] |
| Phoenix | 1.8.7 locked | Dashboard routing, layouts, controllers, LiveView host integration. | Existing dependency in `mix.lock`; no new framework needed. [VERIFIED: mix.lock] |
| Phoenix LiveView | 1.1.30 locked | Server-rendered interactive dashboard and function components. | Existing dependency; official docs support function components with `attr` and `slot` contracts. [VERIFIED: mix.lock] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |
| `ScoriaWeb.UI` | local | UI primitives, semantic tone mapping, overlays, tables, evidence primitives, flash/toast shell. | Existing enforced token gateway and maintainer catalog surface. [VERIFIED: docs/MAINTAINERS.md] |
| Scoria CSS layers | local | Tokens, base, components, motion, utilities. | Existing token-scoped runtime styling files under `assets/css/`. [VERIFIED: codebase grep] |
| `assets/js/scoria.js` | local | Browser hooks and LiveSocket boot. | Existing bundled client interop surface. [VERIFIED: codebase grep] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| ExUnit / Phoenix.LiveViewTest | project standard | Server-rendered UI/component assertions. | Baseline proof for markup, classes, ARIA, `phx-*`, and component contracts. [VERIFIED: docs/uat_automation.md] |
| Floki | 0.38.1 locked | HTML inspection in tests. | Existing test dependency for rendered HTML assertions. [VERIFIED: mix.lock] |
| LazyHTML | 0.1.11 locked | HTML parsing support for LiveView tests. | Existing test dependency through LiveView/test stack. [VERIFIED: mix.lock] |
| Playwright / `@playwright/test` | 1.60.0 | Browser-truth proof for CSS, JS, focus, responsive, motion. | Existing dev-only harness under `priv/dev`; not shipped to Hex. [VERIFIED: priv/dev/package.json] |
| `mix scoria.ui.shots` | local | Advisory screenshot and critique harness. | Cite existing evidence; do not make screenshot diffs required in Phase 36. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Repository-local Markdown + JSON | PhoenixStorybook | Context explicitly defers PhoenixStorybook; adding it now expands runtime/dev dependency scope before inventory is known. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |
| Existing ExUnit + Playwright proof | New screenshot-diff CI | Context explicitly keeps screenshots advisory and reserves visual CI for later Phase 41 judgment. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |
| Stable JSON index | Markdown-only inventory | Markdown-only would duplicate status fields in prose and make later phase references brittle. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |

**Installation:**

```bash
# No new package installation for Phase 36. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
```

**Version verification:** Existing stack versions were verified from `mix.lock`, `priv/dev/package.json`, and local runtime commands during research. [VERIFIED: mix.lock] [VERIFIED: priv/dev/package.json] [VERIFIED: `mix --version`]

## Package Legitimacy Audit

Phase 36 should not install external packages. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | n/a | n/a | n/a | n/a | n/a | No install planned. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Git history + current source tree
  |
  v
Baseline proof collector
  |-- git log provenance
  |-- existing ExUnit UI/component tests
  |-- existing Playwright browser truths
  |-- advisory shot/gap-register evidence
  v
Inventory classifier
  |-- foundations: brandbook + CSS tokens/layers
  |-- primitives: ScoriaWeb.UI attr/slot components
  |-- component groups: lib/scoria_web/components
  |-- pages: router + LiveView modules
  |-- hooks: assets/js/scoria.js + phx-hook/data-* call sites
  |-- fixtures/tests/docs/one-offs
  v
Structured index (stable IDs, layer/status, paths, evidence, risk_refs)
  |
  v
Markdown inventory (rationale, examples, baseline truth, risk narrative)
  |
  v
Phase 37+ gate: no UI implementation starts until artifacts exist
```

### Recommended Project Structure

```text
.planning/phases/36-baseline-and-inventory/
|-- 36-RESEARCH.md
|-- 36-INVENTORY.md        # human-readable inventory, rationale, risk narrative
`-- 36-inventory.json      # stable IDs, layer/status fields, paths, evidence refs
```

### Pattern 1: Structured Index Is The Canonical Row Store

**What:** Store every row with `id`, `name`, `layer`, `status`, `owner_path`, `evidence`, `replacement_or_owner`, `next_action`, and `risk_refs`. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

**When to use:** Use this for every foundation, primitive, component group, page, hook, fixture, test, doc, and one-off row. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

**Example:**

```json
{
  "id": "PRIM-TABLE",
  "name": "Scoria table",
  "layer": "primitive",
  "status": "canonical",
  "owner_path": "lib/scoria_web/ui.ex",
  "evidence": [
    "lib/scoria_web/ui.ex:1198",
    "test/scoria_web/ui_component_test.exs"
  ],
  "replacement_or_owner": "ScoriaWeb.UI.table/1",
  "next_action": "Feed Phase 37 lab states for desktop table, mobile summary, empty, pagination, sort.",
  "risk_refs": ["RISK-RESPONSIVE-SCAN"]
}
```

### Pattern 2: Phoenix Primitive Ownership

**What:** Prefer function components with `attr` and `slot` contracts for reusable primitives; official LiveView docs describe `attr/3` and `slot/3` as compile-time validation mechanisms. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]

**When to use:** Use this when deciding whether a UI surface belongs in `ScoriaWeb.UI`, a stateful LiveComponent, or a page-local LiveView. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

**Example:**

```elixir
# Source: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html
attr :rows, :list, required: true
slot :col do
  attr :label, :string, required: true
end
def table(assigns), do: ~H"..."
```

### Pattern 3: JS Boundary Inventory

**What:** Inventory `Phoenix.LiveView.JS` commands separately from custom JS hooks. Official docs describe composable JS commands and browser hooks; hooks are the boundary for behavior that server-rendered LiveView and JS commands do not cover cleanly. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html] [CITED: https://phoenix-live-view.hexdocs.pm/js-interop.html]

**When to use:** Use this when classifying `CopyId`, `ThemeToggle`, `Dismissable`, `CommandPalette`, `MobileNav`, and `RecordRecentObject`. [VERIFIED: codebase grep]

**Example:**

```javascript
// Source: assets/js/scoria.js
Hooks.CopyId = {
  mounted() {
    this.el.addEventListener("click", function () {
      var text = el.getAttribute("data-copy") || el.textContent.trim();
    });
  }
}
```

### Anti-Patterns to Avoid

- **Markdown as the only source of truth:** It breaks stable downstream references; keep canonical IDs and status fields in JSON. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
- **Fixing found UI defects in Phase 36:** The phase is discovery/classification/proof-boundary work unless a defect blocks inventory generation. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
- **Adding PhoenixStorybook now:** Context explicitly defers this until after a dev-only lab proves insufficient. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
- **Treating v3.0 proof gaps as regressions:** Context says they are inventory risks until owner phases mitigate or defer them with evidence. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UI primitive contracts | Ad hoc prose-only component docs | `ScoriaWeb.UI` `attr`/`slot` declarations plus ExDoc/docs references | Existing component contracts are machine-checkable at compile/test time. [VERIFIED: docs/MAINTAINERS.md] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |
| Browser behavior proof | New screenshot-diff system | Existing Playwright specs and `mix scoria.ui.e2e` | Existing docs define browser-truth scope for JS/CSS/focus/motion. [VERIFIED: docs/uat_automation.md] |
| Visual baseline gate | New CI image diff lane | Advisory `mix scoria.ui.shots` and gap registers | Context explicitly forbids screenshot CI promotion in Phase 36. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |
| Design token truth | External token schema | `brandbook/tokens.json`, `brandbook/tokens.css`, `assets/css/02-tokens.css` | Brandbook is locked as canonical brand truth. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |
| Risk tracking | Inline prose duplicated on rows | Central Known Risk Register plus row `risk_refs` | Context mandates hybrid risk model. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |

**Key insight:** The hard part is traceability, not code generation; Phase 36 should make existing UI state addressable by stable IDs before any later phase mutates it. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Inventory Drift Between Markdown And JSON

**What goes wrong:** Status or IDs are edited in prose but not in the structured index. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
**Why it happens:** Two artifacts can become competing sources of truth. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
**How to avoid:** Make JSON canonical for row fields; Markdown summarizes and links to IDs. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
**Warning signs:** Rows in Markdown lack matching JSON IDs, or risk refs exist only in prose. [ASSUMED]

### Pitfall 2: Misclassifying Page-Specific Markup As Duplication

**What goes wrong:** Planner creates consolidation work for workflow-specific UI that should remain page-local. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
**Why it happens:** Similar markup can serve different operator jobs. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
**How to avoid:** Use JTBD language and mark `intentionally-page-specific` only when extraction would leak domain context or reduce clarity. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
**Warning signs:** `replacement_or_owner` says `ScoriaWeb.UI` but the evidence is only one named workflow. [ASSUMED]

### Pitfall 3: Turning Advisory Screenshots Into A Brittle Gate

**What goes wrong:** Phase 36 accidentally creates visual CI obligations before the harness is deterministic. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
**Why it happens:** Existing `priv/shots` artifacts look like visual baselines. [VERIFIED: codebase grep]
**How to avoid:** Cite screenshot evidence as advisory only and keep CI proof to existing focused tests. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
**Warning signs:** Plan tasks mention image diffs, thresholds, or required screenshot CI in Phase 36. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

### Pitfall 4: Losing v3.0 Proof Gaps

**What goes wrong:** Stale verification gaps disappear because the current UI appears cleaner. [VERIFIED: .planning/milestones/v3.0-MILESTONE-AUDIT.md]
**Why it happens:** Final gap register resolved 11 P1 items deterministically but did not rerun the LLM critique and had partial capture limitations. [VERIFIED: priv/shots/gap_register_final.md]
**How to avoid:** Seed `RISK-V30-PROOF` with v3.0 audit and final gap-register limitations. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
**Warning signs:** Inventory baseline says "v3.0 proof complete" without mentioning missing Phase 13/14 verification or final screenshot limitations. [VERIFIED: .planning/milestones/v3.0-MILESTONE-AUDIT.md]

## Code Examples

### Canonical Function Component Row Extraction

```bash
# Source: codebase grep
rg -n "^\\s*(attr|slot)\\b|def\\s+\\w+\\(" lib/scoria_web/ui.ex
```

Use this to seed primitive rows from `ScoriaWeb.UI`; the planner should not require a handwritten component list if a grep-generated seed can reduce omissions. [VERIFIED: codebase grep]

### Canonical Hook Extraction

```bash
# Source: codebase grep
rg -n "Hooks\\.|phx-hook|data-command-|data-mobile-nav|data-theme-toggle|data-copy" assets/js/scoria.js lib/scoria_web
```

Use this to map hook definitions to HEEx/function-component call sites and `data-*` contracts. [VERIFIED: codebase grep]

### Baseline Provenance Check

```bash
# Source: git log
git log --oneline --decorate -n 16
```

Use this to prove UI cleanup commits precede v3.3 planning commits. [VERIFIED: git log]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw palette and per-component status coloring | `ScoriaWeb.UI` semantic tones plus DS-06 guard | v3.0 cleanup, documented by gap register final | Inventory should mark `ScoriaWeb.UI` and DS-06 as canonical foundation/primitive proof. [VERIFIED: priv/shots/gap_register_final.md] |
| Fixed desktop-biased dashboard assumptions | Mobile drawer, table viewport, mobile summaries, reduced-motion/focus tests | v3.0 Phase 16 | Inventory must attach `RISK-RESPONSIVE-SCAN` and `RISK-OVERLAY-FOCUS` to cross-cutting rows. [VERIFIED: priv/dev/e2e/phase16_parity.spec.mjs] |
| Broad screenshot critique as proof | Focused ExUnit/Playwright plus advisory screenshot evidence | v3.0 final proof boundary | Phase 36 should reuse proof without promoting screenshots to CI. [VERIFIED: docs/uat_automation.md] [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |

**Deprecated/outdated:**
- PhoenixStorybook in Phase 36: deferred explicitly; do not plan it now. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
- Screenshot diff CI in Phase 36: deferred explicitly; do not plan it now. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
- Approval history/toast fixes in Phase 36: folded into later risk owner phases. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Warning signs for inventory drift are inferred from standard documentation-maintenance failure modes. | Common Pitfalls | Planner may need a stricter schema validation task if drift risk is higher than assumed. |
| A2 | Warning signs for page-specific markup are inferred from code-review practice, not directly verified from a Scoria failure. | Common Pitfalls | Planner may over-index on extraction checks without enough product context. |
| A3 | RESOLVED: `36-inventory.json` is the exact filename for the structured index. | Resolved Questions | Downstream references must use this filename consistently. |
| A4 | A Phase 36 artifact contract test should parse `36-inventory.json` and validate required fields. | Validation Architecture | Planner may choose a script instead of ExUnit, but some automated validation is still needed. |
| A5 | A Wave 0 artifact contract should validate row fields, enum values, unique IDs, and required risk IDs. | Validation Architecture | Inventory drift could reach later phases if this validation is omitted. |
| A6 | Structured inventory JSON shape and enum validation is the relevant ASVS V5 control for this phase. | Security Domain | Planner may classify this as a documentation integrity control instead of application input validation. |
| A7 | Repository-local inventory content should be parsed and validated but never executed by tooling. | Security Domain | Future automation could create script-injection risk if inventory fields are executed or shell-interpolated. |

## Resolved Questions

1. **Exact structured index filename**
   - What we know: Context recommends a structured data file under the phase directory. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
   - RESOLVED: The structured index filename is `.planning/phases/36-baseline-and-inventory/36-inventory.json`. [VERIFIED: revision_context]
   - Resolution rationale: `36-inventory.json` is diffable, machine-readable, local to the phase, and matches the plan artifacts already referenced by P01/P02. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-P01-PLAN.md] [VERIFIED: .planning/phases/36-baseline-and-inventory/36-P02-PLAN.md]

2. **Whether to add schema validation**
   - What we know: The structured index owns canonical IDs and status fields. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
   - RESOLVED: Validation should be inline Node validation commands in the plans, not a new runtime dependency. [VERIFIED: revision_context]
   - Resolution rationale: The plans already use `node -e` snippets to parse `36-inventory.json`, validate required row/risk keys, verify enum coverage, and reconcile discovered sources to inventory rows. A later executor may choose a repository-local planning-artifact script if the inline checks become too long, but Phase 36 should not add a package or runtime dependency for schema validation. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-P01-PLAN.md] [VERIFIED: .planning/phases/36-baseline-and-inventory/36-P02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Git | Baseline provenance | yes | 2.41.0 | none needed. [VERIFIED: `git --version`] |
| Mix / Elixir | Existing tests and docs | yes | Mix 1.19.5 / Erlang OTP 28 | none needed. [VERIFIED: `mix --version`] |
| Node.js | Existing Playwright harness | yes | v22.14.0 | Skip browser proof if not needed; Phase 36 can rely on existing artifacts. [VERIFIED: `node --version`] |
| npm | Existing Playwright harness | yes | 11.1.0 | Skip browser proof if not needed; Phase 36 can rely on existing artifacts. [VERIFIED: `npm --version`] |
| Playwright | Existing e2e proof | yes in `priv/dev/package.json` | 1.60.0 | Use existing ExUnit proof and cite browser specs if local browser run is unavailable. [VERIFIED: priv/dev/package.json] |

**Missing dependencies with no fallback:**
- None found for the research/planning scope. [VERIFIED: environment probe]

**Missing dependencies with fallback:**
- None found for the research/planning scope. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest; Playwright for browser-truth lane. [VERIFIED: docs/uat_automation.md] |
| Config file | `mix.exs`, `config/test.exs`, `priv/dev/e2e/playwright.config.mjs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/ui_drift_guard_test.exs --warnings-as-errors` [VERIFIED: codebase grep] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: docs/uat_automation.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| BASE-01 | Baseline artifact records separated cleanup and v3.3 commits. | unit/docs contract | `mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs --warnings-as-errors` for existing UI proof; add Phase 36 artifact contract in Wave 0. [VERIFIED: codebase grep] | No Phase 36 contract yet. [VERIFIED: codebase grep] |
| INV-01 | Inventory includes foundations, primitives, component groups, pages, hooks, fixtures, tests, docs, one-offs. | artifact contract | Add `test/scoria_web/design_inventory_contract_test.exs` or planning-artifact test that parses `36-inventory.json`. [ASSUMED] | No. [VERIFIED: codebase grep] |
| INV-02 | Inventory rows include valid `layer` and `status` classification. | artifact contract | Add JSON parsing assertion with existing `Jason`. [VERIFIED: mix.lock] | No. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run focused artifact contract plus `mix test test/scoria_web/ds06_drift_guard_test.exs --warnings-as-errors`. [VERIFIED: docs/MAINTAINERS.md]
- **Per wave merge:** Run `mix test --warnings-as-errors`; run `mix scoria.ui.e2e --base-url <dev-url>` only if the plan changes proof code or browser harness references. [VERIFIED: docs/uat_automation.md]
- **Phase gate:** Inventory Markdown and JSON must exist, parse, and include all required starting risks before `$gsd-verify-work`. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

### Wave 0 Gaps

- [ ] `36-INVENTORY.md` - human-readable inventory artifact. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
- [ ] `36-inventory.json` - structured inventory index. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
- [ ] Artifact contract test or script - validates required row fields, enum values, unique IDs, and required risk IDs. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 36 does not change authentication behavior. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |
| V3 Session Management | no | Phase 36 does not change sessions. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |
| V4 Access Control | no | Phase 36 does not change authorization or approval semantics. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |
| V5 Input Validation | yes | Validate structured inventory JSON shape and enum values before downstream use. [ASSUMED] |
| V6 Cryptography | no | Phase 36 does not change cryptography. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |

### Known Threat Patterns for Phase 36

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Untrusted inventory content later consumed by scripts | Tampering | Keep index repository-local, parse with `Jason`, validate enums and paths, avoid executing inventory content. [ASSUMED] |
| Baseline claims without provenance | Repudiation | Record git commit evidence and existing proof command references. [VERIFIED: git log] |
| Accidental package/runtime expansion | Elevation of privilege / Supply chain | Do not install new packages in Phase 36. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/36-baseline-and-inventory/36-CONTEXT.md` - locked phase decisions, classification rules, risk model, deferred scope. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - BASE-01, INV-01, INV-02 and v3.3 boundaries. [VERIFIED: file read]
- `.planning/STATE.md` - milestone position and pending todos. [VERIFIED: file read]
- `git log --oneline --decorate -n 16` - baseline cleanup versus v3.3 planning commit order. [VERIFIED: command]
- `docs/MAINTAINERS.md` and `docs/uat_automation.md` - existing design-system and proof conventions. [VERIFIED: file read]
- `priv/shots/gap_register.md`, `priv/shots/gap_register_final.md`, `.planning/milestones/v3.0-MILESTONE-AUDIT.md` - v3.0 proof gap and limitation evidence. [VERIFIED: file read]
- `lib/scoria_web/ui.ex`, `assets/js/scoria.js`, `assets/css/*.css`, `lib/scoria_web/router.ex`, `test/scoria_web/*`, `priv/dev/e2e/*` - inventory surfaces. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- `https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html` - function component, `attr`, `slot`, and global attribute guidance. [CITED: official docs]
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html` - composable JS command guidance. [CITED: official docs]
- `https://phoenix-live-view.hexdocs.pm/js-interop.html` - hook lifecycle and JS interop boundary. [CITED: official docs]

### Tertiary (LOW confidence)

- `https://m3.material.io/foundations/design-tokens/overview` and `https://atlassian.design/tokens/design-tokens/` were checked but not relied on because the fetched pages exposed little usable text in this environment. [CITED: official docs]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and surfaces verified from lockfiles, package files, local runtime commands, and repo docs. [VERIFIED: mix.lock]
- Architecture: HIGH - phase artifact shape and boundaries are locked in CONTEXT.md and confirmed by codebase surfaces. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]
- Pitfalls: MEDIUM - most are locked by context or prior artifacts; two warning-sign claims are marked assumed. [VERIFIED: .planning/phases/36-baseline-and-inventory/36-CONTEXT.md]

**Research date:** 2026-06-20
**Valid until:** 2026-07-20 for repo-local planning; re-check dependency versions only if Phase 36 begins after a dependency update.
