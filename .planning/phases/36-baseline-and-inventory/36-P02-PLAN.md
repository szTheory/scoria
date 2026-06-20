---
phase: 36-baseline-and-inventory
plan: P02
type: execute
wave: 2
depends_on:
  - 36-P01
files_modified:
  - .planning/phases/36-baseline-and-inventory/36-INVENTORY.md
  - .planning/phases/36-baseline-and-inventory/36-inventory.json
autonomous: true
requirements:
  - INV-01
  - INV-02
must_haves:
  truths:
    - "INV-01: Maintainer can inspect rows for foundations, ScoriaWeb.UI primitives, component groups, LiveView pages, CSS/JS hooks, fixtures, tests, docs, and one-off patterns."
    - "INV-02: Every row uses exact `layer` and `status` enums and required fields from D-05 and D-06."
    - "D-01 D-03 D-04: Markdown summarizes the inventory while JSON owns stable IDs, canonical status fields, owner paths, evidence, relationships, and risk refs."
    - "D-07 D-08 D-09 D-10 D-11 D-12: Classification decisions are evidence-backed and respect Phoenix component, LiveComponent, JS hook, and token-scoped CSS ownership."
    - "D-18 D-19 D-20 D-23: Known risks are centralized and every row with a risk links to a valid `risk_id`."
    - "D-24 D-25 D-26 D-27 D-28: Inventory descriptions use operator-first JTBD language, brandbook truth, design pillars, and decisive defaults."
  artifacts:
    - path: ".planning/phases/36-baseline-and-inventory/36-INVENTORY.md"
      provides: "Complete maintainer-readable inventory, summaries, risk narrative, exclusions, and Phase 37+ blocker gate"
    - path: ".planning/phases/36-baseline-and-inventory/36-inventory.json"
      provides: "Complete machine-readable inventory rows and risk register for downstream phase consumption"
  key_links:
    - from: ".planning/phases/36-baseline-and-inventory/36-inventory.json"
      to: "lib/scoria_web/ui.ex"
      via: "primitive rows use ScoriaWeb.UI function names and attr/slot evidence"
      pattern: "PRIM-"
    - from: ".planning/phases/36-baseline-and-inventory/36-inventory.json"
      to: "assets/js/scoria.js"
      via: "hook rows use named browser interop capabilities"
      pattern: "HOOK-"
    - from: ".planning/phases/36-baseline-and-inventory/36-INVENTORY.md"
      to: ".planning/ROADMAP.md"
      via: "Phase 37+ gate states no implementation phase starts without inventory artifacts"
      pattern: "Phase 37\\+ Gate"
---

<objective>
Complete the Phase 36 design-system inventory and gate later UI implementation work on the finished artifacts.

Purpose: Make the current `/scoria` design system inspectable before any v3.3 UI implementation changes foundations, primitives, component groups, page flows, fixtures, proof, or docs.
Output: Complete `36-INVENTORY.md` and `36-inventory.json` covering all required inventory layers, classifications, required risks, and later-phase ownership.
</objective>

<execution_context>
@/Users/jon/.codex/gsd-core/workflows/execute-plan.md
@/Users/jon/.codex/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/PROJECT.md
@.planning/phases/36-baseline-and-inventory/36-CONTEXT.md
@.planning/phases/36-baseline-and-inventory/36-RESEARCH.md
@.planning/phases/36-baseline-and-inventory/36-PATTERNS.md
@.planning/phases/36-baseline-and-inventory/36-UI-SPEC.md
@.planning/phases/36-baseline-and-inventory/36-INVENTORY.md
@.planning/phases/36-baseline-and-inventory/36-inventory.json
@lib/scoria_web/ui.ex
@assets/css/01-reset.css
@assets/css/02-tokens.css
@assets/css/03-base.css
@assets/css/04-components.css
@assets/css/05-motion.css
@assets/css/06-utilities.css
@assets/js/scoria.js
@lib/scoria_web/components/layouts/app.html.heex
@lib/scoria_web/components/layouts/root.html.heex
@lib/scoria_web/live/
@lib/scoria_web/components/
@test/scoria_web/
@priv/dev/e2e/
@docs/MAINTAINERS.md
@docs/uat_automation.md
@brandbook/
@priv/shots/gap_register.md
@priv/shots/gap_register_final.md
</context>

<artifacts_this_phase_produces>
- `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md`: final Markdown inventory with baseline, taxonomy, complete summaries by layer, Known Risk Register, proof references, deferred/out-of-scope boundaries, and Phase 37+ gate.
- `.planning/phases/36-baseline-and-inventory/36-inventory.json`: final structured index with stable rows and risks using exact enum and required-key contracts.
- Generated JSON row fields: `id`, `name`, `layer`, `status`, `owner_path`, `evidence`, `replacement_or_owner`, `next_action`, `risk_refs`.
- Generated JSON risk fields: `risk_id`, `title`, `affected_jtbd_persona_operator_flow`, `affected_inventory_refs`, `owner_phase`, `mitigation_evidence_target`, `status`, `closeout_proof`.
- Generated schema/data only: planning-artifact JSON schema fields listed above; no app database, ORM, Payload CMS, Prisma, Drizzle, Supabase, or TypeORM schema fields are created or modified.
- Schema push detection: no schema-relevant files are modified; no schema push task is required.
</artifacts_this_phase_produces>

<tasks>

<task type="auto">
  <name>Task 1: Complete Inventory Rows Across Required Layers</name>
  <files>.planning/phases/36-baseline-and-inventory/36-inventory.json</files>
  <read_first>
    .planning/phases/36-baseline-and-inventory/36-CONTEXT.md
    .planning/phases/36-baseline-and-inventory/36-RESEARCH.md
    .planning/phases/36-baseline-and-inventory/36-PATTERNS.md
    .planning/phases/36-baseline-and-inventory/36-UI-SPEC.md
    .planning/phases/36-baseline-and-inventory/36-inventory.json
    lib/scoria_web/ui.ex
    assets/css/01-reset.css
    assets/css/02-tokens.css
    assets/css/03-base.css
    assets/css/04-components.css
    assets/css/05-motion.css
    assets/css/06-utilities.css
    assets/js/scoria.js
    lib/scoria_web/components/layouts/app.html.heex
    lib/scoria_web/components/layouts/root.html.heex
    lib/scoria_web/live/
    lib/scoria_web/components/
    test/scoria_web/
    priv/dev/e2e/
    docs/MAINTAINERS.md
    docs/uat_automation.md
    brandbook/
  </read_first>
  <action>
    Fill `36-inventory.json` `rows` so discovered source surfaces reconcile to inventory rows and the inventory names foundations, primitives, component groups, pages, CSS/JS hooks, fixtures, tests, docs, and one-off patterns per INV-01. Use exact `layer` values `foundation`, `primitive`, `component-group`, `page`, `hook`, `fixture`, `test`, `doc`, `one-off` and exact `status` values `canonical`, `duplicated`, `legacy`, `missing`, `intentionally-page-specific` per D-05.

    Follow the analog patterns assigned in `36-PATTERNS.md`: use `.planning/research/v3.3-design-system-stress-test-inventory.md` for the Markdown inventory shape and the source categories that must become rows; use `.planning/WARNING-INVENTORY.md` for generated artifact metadata and repository-scope inventory discipline; use `test/scoria_web/ds06_drift_guard_test.exs` as the parsing/validation analog for deterministic source-to-row reconciliation, including repository-relative paths, strict parsing, and checks that fail on unclassified lines rather than silently dropping them.

    Add rows for foundations: brandbook tokens and docs, CSS reset/tokens/base/components/motion/utilities, and DS-06 drift guard evidence. Add primitive rows for `ScoriaWeb.UI` function component families including badges, buttons, icon buttons, panels/page sections, metrics/overview stats/signal summaries, IDs/timestamps/metadata rows, raw evidence/code, drawers/modals, toasts/flash, forms, tables/lists, empty/skeleton states, command palette shell, notebooks, and evidence actions. Add component-group rows from `lib/scoria_web/components/`, layout shell rows for app/root layouts, page rows for LiveViews under `lib/scoria_web/live/`, hook rows for named capabilities in `assets/js/scoria.js`, fixture rows for dev/e2e/shots inputs, test rows for ExUnit and Playwright proof surfaces, doc rows for maintainer/UAT/brand/proof docs, and one-off rows where page-local markup or proof gaps imply noncanonical patterns.

    Discover one-off and missing candidates with source scans over `lib/scoria_web/live`, `lib/scoria_web/components`, `docs`, `brandbook`, and `priv/shots` for terms such as `TODO`, `FIXME`, `MISSING`, `legacy`, `deprecated`, `one-off`, and `duplicated`, plus page-local `scoria-*` class usage that is not owned by `ScoriaWeb.UI`. Each discovered candidate must become a `one-off` or `missing` row, or appear in `documented_exclusions` with an explicit reason.

    Apply D-07 through D-12: mark `canonical` only with clear owner, stable contract, representative usage, and proof/docs; mark `duplicated` where multiple surfaces solve one UI job and identify the preferred replacement; mark `legacy` only with a migration target; mark `missing` when repeated code/copy/tests/docs imply an absent abstraction or proof; mark `intentionally-page-specific` only for a named LiveView/operator workflow where extraction would reduce clarity; keep Phoenix ownership boundaries explicit for function components, LiveComponents, JS hooks, and token-scoped CSS.

    Every row must include all required keys from D-06, use stable IDs from D-03, keep canonical fields in JSON per D-04, use JTBD-first wording per D-25, include brand/design-pillar considerations per D-26 and D-27, and attach `risk_refs` only to IDs present in JSON `risks` per D-18 through D-23. Add a top-level `documented_exclusions` array to `36-inventory.json`; each exclusion must include `source`, `reason`, and `reviewed_by_phase`, and must be used only for one-off/missing surfaces that are intentionally not represented as rows. Do not edit any read-only input file.
  </action>
  <verify>
    <automated>node -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8')); const layers=['foundation','primitive','component-group','page','hook','fixture','test','doc','one-off']; const statuses=['canonical','duplicated','legacy','missing','intentionally-page-specific']; const rowKeys=['id','name','layer','status','owner_path','evidence','replacement_or_owner','next_action','risk_refs']; const ids=new Set(); const riskIds=new Set((j.risks||[]).map(r=>r.risk_id)); for (const row of j.rows||[]) { if (ids.has(row.id)) throw new Error('duplicate row '+row.id); ids.add(row.id); for (const k of rowKeys) if (!(k in row)) throw new Error(row.id+' missing '+k); if (!layers.includes(row.layer)) throw new Error(row.id+' bad layer '+row.layer); if (!statuses.includes(row.status)) throw new Error(row.id+' bad status '+row.status); if (!Array.isArray(row.evidence) || row.evidence.length===0) throw new Error(row.id+' missing evidence'); if (!Array.isArray(row.risk_refs)) throw new Error(row.id+' risk_refs not array'); for (const r of row.risk_refs) if (!riskIds.has(r)) throw new Error(row.id+' unknown risk '+r); } for (const l of layers) if (!(j.rows||[]).some(r=>r.layer===l)) throw new Error('missing layer coverage '+l); for (const s of statuses) if (!(j.rows||[]).some(r=>r.status===s)) throw new Error('missing status coverage '+s);"</automated>
    <automated>node -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8')); for (const prefix of ['FOUND-','PRIM-','GROUP-','PAGE-','HOOK-','FIXTURE-','TEST-','DOC-','ONEOFF-','MISSING-']) if (!(j.rows||[]).some(r=>r.id.startsWith(prefix))) throw new Error('missing id family '+prefix);"</automated>
    <automated>node -e "const fs=require('fs'), cp=require('child_process'); const j=JSON.parse(fs.readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8')); const rows=j.rows||[]; const exclusions=new Set((j.documented_exclusions||[]).map(e=>e.source)); for (const e of j.documented_exclusions||[]) for (const k of ['source','reason','reviewed_by_phase']) if (!(k in e)) throw new Error('bad exclusion missing '+k); const has=(source, layer)=>rows.some(r=>r.layer===layer && (r.owner_path===source || (r.evidence||[]).some(ev=>ev.startsWith(source)))); const list=(cmd)=>cp.execSync(cmd,{encoding:'utf8',shell:'/bin/bash'}).split('\\n').map(s=>s.trim()).filter(Boolean); const requirePath=(source, layer)=>{ if (!has(source, layer) && !exclusions.has(source)) throw new Error('inventory missing '+layer+' source '+source); }; for (const p of list('find assets/css -maxdepth 1 -type f -name \"*.css\" | sort')) requirePath(p,'foundation'); for (const p of list('find lib/scoria_web/live -type f \\( -name \"*.ex\" -o -name \"*.heex\" \\) | sort')) requirePath(p,'page'); for (const p of list('find lib/scoria_web/components -type f \\( -name \"*.ex\" -o -name \"*.heex\" \\) | sort')) requirePath(p, p.includes('/layouts/') ? 'page' : 'component-group'); for (const p of list('find test/scoria_web -type f -name \"*_test.exs\" | sort')) requirePath(p,'test'); for (const p of list('find priv/dev/e2e -type f -name \"*.mjs\" | sort')) requirePath(p,'test'); for (const p of list('find brandbook docs -type f \\( -name \"*.md\" -o -name \"*.json\" -o -name \"*.css\" \\) | sort')) requirePath(p,'doc'); for (const p of list('find priv/shots -maxdepth 1 -type f \\( -name \"*.md\" -o -name \"*.json\" \\) | sort 2>/dev/null || true')) requirePath(p,'fixture'); const ui=fs.readFileSync('lib/scoria_web/ui.ex','utf8'); for (const name of [...ui.matchAll(/^\\s*def\\s+([a-zA-Z0-9_!?]+)\\s*\\(/gm)].map(m=>m[1]).filter(n=>!n.startsWith('__')).sort()) if (!rows.some(r=>r.layer==='primitive' && (r.replacement_or_owner||'').includes('ScoriaWeb.UI.'+name+'/'))) throw new Error('missing primitive ScoriaWeb.UI.'+name); const js=fs.readFileSync('assets/js/scoria.js','utf8'); for (const name of [...js.matchAll(/Hooks\\.([A-Za-z0-9_]+)\\s*=/g)].map(m=>m[1]).sort()) if (!rows.some(r=>r.layer==='hook' && ((r.name||'').includes(name) || (r.replacement_or_owner||'').includes(name)))) throw new Error('missing hook '+name);"</automated>
    <automated>node -e "const fs=require('fs'), cp=require('child_process'); const j=JSON.parse(fs.readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8')); const rows=j.rows||[]; const exclusions=new Set((j.documented_exclusions||[]).map(e=>e.source)); const out=cp.execSync('rg -n \"TODO|FIXME|MISSING|legacy|deprecated|one-off|duplicated\" lib/scoria_web/live lib/scoria_web/components docs brandbook priv/shots 2>/dev/null || true',{encoding:'utf8',shell:'/bin/bash'}).split('\\n').filter(Boolean); for (const hit of out) { const source=hit.split(':').slice(0,2).join(':'); const covered=rows.some(r=>['one-off','missing'].includes(r.layer) && (r.owner_path===source.split(':')[0] || (r.evidence||[]).some(ev=>ev.startsWith(source)))); if (!covered && !exclusions.has(source) && !exclusions.has(source.split(':')[0])) throw new Error('unclassified one-off/missing candidate '+source); }"</automated>
  </verify>
  <acceptance_criteria>
    `36-inventory.json` has rows or documented exclusions for every discovered source-scan item: `ScoriaWeb.UI` component defs, `lib/scoria_web/live/**`, named hooks in `assets/js/scoria.js`, CSS files, ExUnit tests, Playwright specs, docs/brandbook paths, fixtures/shots inputs, and one-off/missing documented exclusions.
    `36-inventory.json` has at least one row for every `layer` enum and at least one row for every `status` enum.
    Every row includes `id`, `name`, `layer`, `status`, `owner_path`, `evidence`, `replacement_or_owner`, `next_action`, and `risk_refs`.
    Row IDs are unique and stable, using clear families such as `FOUND-`, `PRIM-`, `GROUP-`, `PAGE-`, `HOOK-`, `FIXTURE-`, `TEST-`, `DOC-`, `ONEOFF-`, and `MISSING-`.
    Every `risk_refs` entry points to a risk object in the same JSON file.
    Source-scan reconciliation fails on omitted current foundations, `ScoriaWeb.UI` primitives, component groups, LiveView pages, CSS/JS hooks, fixtures, tests, docs, and one-off patterns unless the omission appears in `documented_exclusions` with `source`, `reason`, and `reviewed_by_phase`.
    No runtime/source file is modified.
  </acceptance_criteria>
  <done>Structured inventory rows are complete enough for downstream phases to reference stable IDs, owners, classifications, and risks.</done>
</task>

<task type="auto">
  <name>Task 2: Finalize Markdown Inventory And Phase Gate</name>
  <files>.planning/phases/36-baseline-and-inventory/36-INVENTORY.md, .planning/phases/36-baseline-and-inventory/36-inventory.json</files>
  <read_first>
    .planning/ROADMAP.md
    .planning/REQUIREMENTS.md
    .planning/phases/36-baseline-and-inventory/36-CONTEXT.md
    .planning/phases/36-baseline-and-inventory/36-RESEARCH.md
    .planning/phases/36-baseline-and-inventory/36-PATTERNS.md
    .planning/phases/36-baseline-and-inventory/36-UI-SPEC.md
    .planning/phases/36-baseline-and-inventory/36-INVENTORY.md
    .planning/phases/36-baseline-and-inventory/36-inventory.json
    priv/shots/gap_register.md
    priv/shots/gap_register_final.md
    docs/MAINTAINERS.md
    docs/uat_automation.md
  </read_first>
  <action>
    Finalize `36-INVENTORY.md` as the maintainer-readable companion to JSON per D-01 and D-04. Include a baseline section for BASE-01, inventory summary sections for each layer required by INV-01, classification guidance for INV-02, and a central Known Risk Register summary that references JSON risk IDs rather than duplicating full row prose. Include exact starting risk IDs `RISK-V30-PROOF`, `RISK-TOAST-LEGIBILITY`, `RISK-APPROVAL-HISTORY`, `RISK-RESPONSIVE-SCAN`, and `RISK-OVERLAY-FOCUS`.

    Add a `Phase 37+ Gate` section stating no implementation phase starts without both `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` and `.planning/phases/36-baseline-and-inventory/36-inventory.json` present, parseable, and containing required risk IDs and layer/status coverage. State that Phase 36 does not add PhoenixStorybook, a runtime component lab, screenshot-diff CI, approval decision history, approval toast fixes, CI cache-key cleanup, sibling Docker fleet hardening, or approval semantic changes.

    Add a short `Validation` section with commands to parse JSON and assert layer/status/risk coverage. Keep screenshots advisory, cite existing ExUnit/Playwright/shots proof surfaces only, and mention stale v3.0 proof gaps through `RISK-V30-PROOF`.

    Add a `Multi-Source Coverage Audit` table covering GOAL, BASE-01, INV-01, INV-02, research constraints, and D-01 through D-28. All items must be marked COVERED. If any source item cannot be represented in the artifact, stop and report the missing source item instead of silently omitting it.
  </action>
  <verify>
    <automated>node -e "const fs=require('fs'); const md=fs.readFileSync('.planning/phases/36-baseline-and-inventory/36-INVENTORY.md','utf8'); for (const s of ['Baseline Truth','Known Risk Register','Phase 37+ Gate','Multi-Source Coverage Audit']) if (!md.includes(s)) throw new Error('missing section '+s); for (let i=1;i<=28;i++){ const id='D-'+String(i).padStart(2,'0'); if (!md.includes(id)) throw new Error('missing decision '+id); } for (const id of ['BASE-01','INV-01','INV-02','RISK-V30-PROOF','RISK-TOAST-LEGIBILITY','RISK-APPROVAL-HISTORY','RISK-RESPONSIVE-SCAN','RISK-OVERLAY-FOCUS']) if (!md.includes(id)) throw new Error('missing '+id);"</automated>
    <automated>node -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8')); const layers=['foundation','primitive','component-group','page','hook','fixture','test','doc','one-off']; const statuses=['canonical','duplicated','legacy','missing','intentionally-page-specific']; for (const l of layers) if (!j.rows.some(r=>r.layer===l)) throw new Error('missing layer '+l); for (const s of statuses) if (!j.rows.some(r=>r.status===s)) throw new Error('missing status '+s); for (const id of ['RISK-V30-PROOF','RISK-TOAST-LEGIBILITY','RISK-APPROVAL-HISTORY','RISK-RESPONSIVE-SCAN','RISK-OVERLAY-FOCUS']) if (!j.risks.some(r=>r.risk_id===id)) throw new Error('missing risk '+id);"</automated>
    <automated>git diff --name-only | grep -v '^#' | grep -Ev '^(\\.planning/phases/36-baseline-and-inventory/36-(INVENTORY\\.md|inventory\\.json|P01-PLAN\\.md|P02-PLAN\\.md|PATTERNS\\.md))$' | wc -l | tr -d ' ' | grep '^0$'</automated>
  </verify>
  <acceptance_criteria>
    Markdown contains `Baseline Truth`, `Known Risk Register`, `Phase 37+ Gate`, `Validation`, and `Multi-Source Coverage Audit` sections.
    Markdown includes visible citations for D-01 through D-28, BASE-01, INV-01, and INV-02.
    Markdown states the JSON file is canonical for row IDs, statuses, owner paths, evidence, relationships, and risk refs.
    The Phase 37+ gate blocks later implementation unless both inventory artifacts exist, parse, contain required risk IDs, and cover all layer/status enums.
    Deferred items remain out of scope: PhoenixStorybook, runtime lab, screenshot-diff CI, approval decision history implementation, approval toast fix, CI cache-key cleanup, sibling Docker fleet hardening, and approval semantic changes.
    `git diff --name-only` shows no runtime/source modifications from Phase 36 inventory work.
  </acceptance_criteria>
  <done>Markdown and JSON form a complete Phase 36 inventory artifact family that gates later UI implementation phases.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| source tree -> inventory rows | Existing UI source files are read-only evidence for generated planning artifacts. |
| JSON inventory -> Markdown inventory | JSON is the canonical row store; Markdown summarizes without becoming a competing source of truth. |
| Phase 36 artifacts -> Phase 37+ execution | Future implementation phases trust row IDs, classifications, risks, and owner phases. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-36-P02-01 | Tampering | `rows[].risk_refs` | mitigate | Node validation rejects unknown risk refs and duplicate row IDs. |
| T-36-P02-02 | Spoofing | Inventory owner paths | mitigate | Use repository-relative `owner_path` values backed by source evidence and never external unverified URLs as owner truth. |
| T-36-P02-03 | Repudiation | Classification decisions | mitigate | Require nonempty `evidence` for every row and record replacement/owner/next action. |
| T-36-P02-04 | Information Disclosure | Evidence copied into artifacts | mitigate | Include paths, test names, routes, component names, and commit hashes only; do not copy local secrets, env values, private screenshots, or payload bodies. |
| T-36-P02-05 | Denial of Service | Later-phase planning blocked by incomplete inventory | mitigate | Add Phase 37+ gate plus validation commands for layer/status/risk coverage before implementation begins. |
| T-36-P02-SC | Tampering | npm/pip/cargo installs | accept | No package installs are planned and no dependency changes are needed for repository-local artifacts. |
</threat_model>

<verification>
Overall verification:
- `node -e "JSON.parse(require('fs').readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8'))"` succeeds.
- Node validation confirms all layer enums, all status enums, all required risk IDs, unique row IDs, required row fields, and valid risk refs.
- Markdown validation confirms D-01 through D-28, BASE-01, INV-01, INV-02, required risks, and Phase 37+ gate are present.
- `git diff --name-only` confirms no runtime/source paths changed as part of Phase 36 inventory creation.
</verification>

<success_criteria>
Phase 36 is complete when the Markdown and JSON inventory artifacts exist, parse, contain complete layer/status/risk coverage, cite baseline proof, name known risks, and explicitly block later implementation phases from starting without these artifacts.
</success_criteria>

<source_audit>
SOURCE | ID | Feature/Requirement | Plan | Status | Notes
GOAL | phase-36 | Preserve recent UI cleanup as baseline truth and produce a complete design-system inventory before changing more UI | P01,P02 | COVERED | Baseline in P01; complete inventory and gate in P02.
REQ | BASE-01 | Clean baseline preserving recent UI cleanup as committed prior art | P01 | COVERED | Provenance and proof boundary.
REQ | INV-01 | Inspect inventory of foundations, primitives, groups, pages, hooks, fixtures, tests, docs, one-offs | P02 | COVERED | Full row collection.
REQ | INV-02 | See canonical, duplicated, legacy, missing, page-specific classifications | P01,P02 | COVERED | Schema and applied rows.
RESEARCH | paired artifacts | Markdown plus structured JSON | P01,P02 | COVERED | Artifact family.
RESEARCH | existing proof only | ExUnit, Playwright, shots evidence, no new visual CI | P01,P02 | COVERED | Proof boundary preserved.
RESEARCH | package audit | No package installs | P01,P02 | COVERED | Threat model and actions.
RESEARCH | validation architecture | Parse JSON and assert required fields/enums/risks | P01,P02 | COVERED | Node validation commands.
CONTEXT | D-01..D-28 | Locked user decisions | P01,P02 | COVERED | Visible in must_haves and Markdown validation.
</source_audit>

<output>
Create `.planning/phases/36-baseline-and-inventory/36-P02-SUMMARY.md` when done.
</output>
