---
phase: 36-baseline-and-inventory
plan: P01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/36-baseline-and-inventory/36-INVENTORY.md
  - .planning/phases/36-baseline-and-inventory/36-inventory.json
autonomous: true
requirements:
  - BASE-01
  - INV-02
must_haves:
  truths:
    - "BASE-01: Maintainer can see that UI cleanup commits 1773267, d35906f, 4337c5e, 452f035, 2d324a0, and f490cea precede v3.3 planning commits beginning at 8540e04."
    - "D-01 D-02 D-03 D-04: Phase 36 creates repository-local Markdown plus JSON artifacts, uses stable IDs, and treats JSON row fields as canonical without adding a runtime lab."
    - "D-05 D-06 D-07 D-08 D-09 D-10 D-11 D-12: Inventory row schema, layer/status enums, classification rules, and Phoenix ownership boundaries are explicit before row collection starts."
    - "D-13 D-14 D-15 D-16 D-17: Baseline proof cites git provenance and existing proof only; screenshots are advisory; v3.0 proof gaps are risks, not regressions."
    - "D-18 D-19 D-20 D-21 D-22 D-23: Known Risk Register exists centrally and required starting risks are stable IDs with per-row risk_refs."
    - "D-24 D-25 D-26 D-27 D-28: Inventory defaults are operator-first, Phoenix-native, brandbook-aligned, design-pillar-aware, and decisive unless product/security/truth boundaries change."
  artifacts:
    - path: ".planning/phases/36-baseline-and-inventory/36-INVENTORY.md"
      provides: "Maintainer-readable baseline proof, taxonomy, risk register, and artifact contract shell"
    - path: ".planning/phases/36-baseline-and-inventory/36-inventory.json"
      provides: "Structured inventory schema metadata, required risk register entries, and starter rows"
  key_links:
    - from: ".planning/phases/36-baseline-and-inventory/36-INVENTORY.md"
      to: ".planning/phases/36-baseline-and-inventory/36-inventory.json"
      via: "Markdown states JSON owns canonical row IDs/status fields"
      pattern: "36-inventory\\.json"
    - from: ".planning/phases/36-baseline-and-inventory/36-inventory.json"
      to: ".planning/phases/36-baseline-and-inventory/36-CONTEXT.md"
      via: "Required enums, row keys, and risk IDs reflect D-01 through D-28"
      pattern: "RISK-(V30-PROOF|TOAST-LEGIBILITY|APPROVAL-HISTORY|RESPONSIVE-SCAN|OVERLAY-FOCUS)"
---

<objective>
Create the Phase 36 baseline and inventory contract artifacts before any detailed inventory filling begins.

Purpose: Preserve recent UI cleanup as committed baseline truth and make the structured inventory schema, classification rules, and required risks machine-checkable enough for Phase 36 executors.
Output: `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` and `.planning/phases/36-baseline-and-inventory/36-inventory.json` with baseline proof, schema metadata, starter rows, and the required Known Risk Register.
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
@.planning/milestones/v3.0-MILESTONE-AUDIT.md
@priv/shots/gap_register.md
@priv/shots/gap_register_final.md
</context>

<artifacts_this_phase_produces>
- `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md`: Markdown artifact with baseline proof, source scope, taxonomy, risk register narrative, inventory summary tables, exclusions, and Phase 37+ gate.
- `.planning/phases/36-baseline-and-inventory/36-inventory.json`: JSON artifact with top-level fields `generated_at`, `git_sha`, `phase`, `scope`, `schema_version`, `layer_enum`, `status_enum`, `required_row_fields`, `baseline`, `rows`, and `risks`.
- Generated JSON row fields: `id`, `name`, `layer`, `status`, `owner_path`, `evidence`, `replacement_or_owner`, `next_action`, `risk_refs`.
- Generated JSON risk fields: `risk_id`, `title`, `affected_jtbd_persona_operator_flow`, `affected_inventory_refs`, `owner_phase`, `mitigation_evidence_target`, `status`, `closeout_proof`.
- Schema push detection: no Payload CMS, Prisma, Drizzle, Supabase, or TypeORM schema files are modified by this plan; no schema push task is required.
</artifacts_this_phase_produces>

<tasks>

<task type="auto">
  <name>Task 1: Record Baseline Provenance And Artifact Contract</name>
  <files>.planning/phases/36-baseline-and-inventory/36-INVENTORY.md, .planning/phases/36-baseline-and-inventory/36-inventory.json</files>
  <read_first>
    .planning/STATE.md
    .planning/ROADMAP.md
    .planning/REQUIREMENTS.md
    .planning/phases/36-baseline-and-inventory/36-CONTEXT.md
    .planning/phases/36-baseline-and-inventory/36-RESEARCH.md
    .planning/phases/36-baseline-and-inventory/36-PATTERNS.md
    .planning/phases/36-baseline-and-inventory/36-UI-SPEC.md
    .planning/phases/36-baseline-and-inventory/36-INVENTORY.md if it exists
    .planning/phases/36-baseline-and-inventory/36-inventory.json if it exists
  </read_first>
  <action>
    Create `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` and `.planning/phases/36-baseline-and-inventory/36-inventory.json` as repository-local artifacts per D-01 and D-02. In Markdown, add sections `Baseline Truth`, `Artifact Contract`, `Source Scope`, `Classification Rules`, `Known Risk Register`, `Excluded From Phase 36`, and `Phase 37+ Gate`. In JSON, add metadata fields `generated_at`, `git_sha`, `phase`, `scope`, `schema_version`, `layer_enum`, `status_enum`, `required_row_fields`, `baseline`, `rows`, and `risks`.

    Populate `baseline` with git provenance per D-13 and D-14: cleanup commits `1773267`, `d35906f`, `4337c5e`, `452f035`, `2d324a0`, `f490cea`; v3.3 planning commits beginning at `8540e04` and current planning lineage visible from `git log --oneline -12`. Cite existing proof only per D-15: `test/scoria_web/ui_component_test.exs`, `test/scoria_web/ds06_drift_guard_test.exs`, `priv/dev/e2e/`, `mix scoria.ui.shots`, `priv/shots/gap_register.md`, and `priv/shots/gap_register_final.md`. Label screenshots advisory per D-16 and record v3.0 proof gaps as `RISK-V30-PROOF` per D-17.

    Define the exact `layer_enum` values `foundation`, `primitive`, `component-group`, `page`, `hook`, `fixture`, `test`, `doc`, `one-off`; define exact `status_enum` values `canonical`, `duplicated`, `legacy`, `missing`, `intentionally-page-specific`. Define the required row fields from D-05 and D-06. Add the classification rules for canonical, duplicated, legacy, missing, intentionally page-specific, and Phoenix ownership per D-07 through D-12.

    Do not install packages, add PhoenixStorybook, add a runtime lab, change `/scoria` runtime UI, change tests, or create screenshot-diff CI. Those boundaries implement D-02, D-16, D-24, and the Deferred Ideas.
  </action>
  <verify>
    <automated>test -f .planning/phases/36-baseline-and-inventory/36-INVENTORY.md && test -f .planning/phases/36-baseline-and-inventory/36-inventory.json</automated>
    <automated>node -e "const fs=require('fs'); const p='.planning/phases/36-baseline-and-inventory/36-inventory.json'; const j=JSON.parse(fs.readFileSync(p,'utf8')); const layers=['foundation','primitive','component-group','page','hook','fixture','test','doc','one-off']; const statuses=['canonical','duplicated','legacy','missing','intentionally-page-specific']; for (const v of layers) if (!j.layer_enum.includes(v)) throw new Error('missing layer '+v); for (const v of statuses) if (!j.status_enum.includes(v)) throw new Error('missing status '+v); for (const k of ['id','name','layer','status','owner_path','evidence','replacement_or_owner','next_action','risk_refs']) if (!j.required_row_fields.includes(k)) throw new Error('missing row field '+k);"</automated>
    <automated>git log --oneline -12 | grep -E '8540e04|f490cea'</automated>
  </verify>
  <acceptance_criteria>
    `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` exists and states that Phase 36 produces Markdown plus JSON artifacts per D-01, uses repository-local artifacts per D-02, and avoids duplicate source-of-truth drift per D-04.
    `.planning/phases/36-baseline-and-inventory/36-inventory.json` parses with Node `JSON.parse`.
    JSON contains exact enums for `layer` and `status`, and exact required row fields `id`, `name`, `layer`, `status`, `owner_path`, `evidence`, `replacement_or_owner`, `next_action`, `risk_refs`.
    Baseline proof cites cleanup commits `1773267`, `d35906f`, `4337c5e`, `452f035`, `2d324a0`, `f490cea` and v3.3 planning start `8540e04`.
    The artifact contract states screenshots are advisory, screenshot diff CI is out of scope, and v3.0 proof gaps are inventory risks rather than automatic regressions.
  </acceptance_criteria>
  <done>Baseline truth and schema contract artifacts exist, parse, and reflect D-01 through D-17 without runtime/source changes.</done>
</task>

<task type="auto">
  <name>Task 2: Seed Required Risks And Starter Inventory Rows</name>
  <files>.planning/phases/36-baseline-and-inventory/36-INVENTORY.md, .planning/phases/36-baseline-and-inventory/36-inventory.json</files>
  <read_first>
    .planning/phases/36-baseline-and-inventory/36-CONTEXT.md
    .planning/phases/36-baseline-and-inventory/36-RESEARCH.md
    .planning/phases/36-baseline-and-inventory/36-PATTERNS.md
    .planning/phases/36-baseline-and-inventory/36-INVENTORY.md
    .planning/phases/36-baseline-and-inventory/36-inventory.json
    .planning/todos/2026-06-18-make-approval-toasts-legible.md
    .planning/todos/2026-06-20-add-approval-decision-history.md
    .planning/milestones/v3.0-MILESTONE-AUDIT.md
  </read_first>
  <action>
    Populate JSON `risks` with required starting risks per D-18 through D-20: `RISK-V30-PROOF`, `RISK-TOAST-LEGIBILITY`, `RISK-APPROVAL-HISTORY`, `RISK-RESPONSIVE-SCAN`, and `RISK-OVERLAY-FOCUS`. Each risk object must include `risk_id`, `title`, `affected_jtbd_persona_operator_flow`, `affected_inventory_refs`, `owner_phase`, `mitigation_evidence_target`, `status`, and `closeout_proof`. Fold `.planning/todos/2026-06-18-make-approval-toasts-legible.md` into `RISK-TOAST-LEGIBILITY` for Phase 38 per D-21, and `.planning/todos/2026-06-20-add-approval-decision-history.md` into `RISK-APPROVAL-HISTORY` for Phase 39 per D-22.

    Add starter rows covering baseline foundations needed before full inventory: `FOUND-BRANDBOOK`, `FOUND-CSS-TOKENS`, `FOUND-CSS-COMPONENTS`, `PRIM-SCORIA-UI`, `HOOK-SCORIA-JS`, `TEST-DS06-DRIFT`, `DOC-MAINTAINERS`, and `DOC-SHOTS-GAP-REGISTER`. Each row must include all required fields, use stable IDs per D-03, use canonical JSON row fields per D-04, include design-pillar-aware `next_action` text per D-27, and attach risk refs where relevant per D-23.

    In Markdown, render a central `Known Risk Register` summary that points to JSON as canonical for fields and does not duplicate long risk prose per D-18. Include operator-first and embedded-library framing per D-24 and D-25, brandbook ownership per D-26, and decisive default guidance per D-28.
  </action>
  <verify>
    <automated>node -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8')); const riskIds=new Set((j.risks||[]).map(r=>r.risk_id)); for (const id of ['RISK-V30-PROOF','RISK-TOAST-LEGIBILITY','RISK-APPROVAL-HISTORY','RISK-RESPONSIVE-SCAN','RISK-OVERLAY-FOCUS']) if (!riskIds.has(id)) throw new Error('missing risk '+id); const riskKeys=['risk_id','title','affected_jtbd_persona_operator_flow','affected_inventory_refs','owner_phase','mitigation_evidence_target','status','closeout_proof']; for (const r of j.risks) for (const k of riskKeys) if (!(k in r)) throw new Error('risk '+r.risk_id+' missing '+k); const rowKeys=['id','name','layer','status','owner_path','evidence','replacement_or_owner','next_action','risk_refs']; for (const row of j.rows||[]) for (const k of rowKeys) if (!(k in row)) throw new Error('row '+row.id+' missing '+k);"</automated>
    <automated>grep -E 'RISK-(V30-PROOF|TOAST-LEGIBILITY|APPROVAL-HISTORY|RESPONSIVE-SCAN|OVERLAY-FOCUS)' .planning/phases/36-baseline-and-inventory/36-INVENTORY.md</automated>
    <automated>git diff --name-only | grep -v '^#' | grep -E '^\\.planning/phases/36-baseline-and-inventory/36-(INVENTORY\\.md|inventory\\.json|P01-PLAN\\.md|P02-PLAN\\.md)$|^$'</automated>
  </verify>
  <acceptance_criteria>
    JSON `risks` contains exactly the five required starting risk IDs at minimum, and each has all required fields from D-19.
    `RISK-TOAST-LEGIBILITY` cites owner phase 38 and folds the approval toast todo per D-21.
    `RISK-APPROVAL-HISTORY` cites owner phase 39 and folds the approval decision history todo per D-22.
    Starter rows include foundations, primitive gateway, hook gateway, proof, and docs surfaces with stable IDs and all required row fields.
    Markdown states later phases touching a row with `risk_refs` must mitigate, prove unchanged, or explicitly defer with evidence per D-23.
    No source/runtime file is edited; Phase 36 artifacts remain repository-local per D-24.
  </acceptance_criteria>
  <done>Required risks and starter row contract are present in JSON and summarized in Markdown without duplicating row-source truth.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| repository source -> planning artifacts | Existing source, proof, docs, and git history are transformed into Markdown/JSON artifacts that future agents will trust. |
| planning artifacts -> later implementation phases | Phase 37+ agents consume IDs, classifications, and risks as work boundaries. |
| local evidence -> committed files | Git logs, proof notes, and screenshots may contain irrelevant or sensitive local evidence if copied carelessly. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-36-P01-01 | Tampering | `36-inventory.json` schema fields | mitigate | Validate exact enums, required row keys, and required risk keys with Node JSON parsing commands in each task. |
| T-36-P01-02 | Repudiation | Baseline proof claims | mitigate | Record exact git commit hashes for cleanup and v3.3 planning lineage, and cite existing proof commands/artifacts only. |
| T-36-P01-03 | Information Disclosure | Generated Markdown/JSON evidence | mitigate | Store repository-relative paths and commit/test references only; do not paste secrets, local screenshots with private data, or environment contents. |
| T-36-P01-04 | Elevation of Privilege | Phase 36 scope creep into runtime UI | mitigate | Limit modified files to `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` and `36-inventory.json`; verify no runtime/source paths are modified. |
| T-36-P01-SC | Tampering | npm/pip/cargo installs | accept | No package installs are planned and the Package Legitimacy Audit says none are needed. |
</threat_model>

<verification>
Overall verification:
- `node -e "JSON.parse(require('fs').readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8'))"` succeeds.
- Required layer and status enums appear in JSON exactly as specified.
- Required risk IDs `RISK-V30-PROOF`, `RISK-TOAST-LEGIBILITY`, `RISK-APPROVAL-HISTORY`, `RISK-RESPONSIVE-SCAN`, and `RISK-OVERLAY-FOCUS` appear in Markdown and JSON.
- `git diff --name-only` shows only Phase 36 planning artifact files for this plan.
</verification>

<success_criteria>
BASE-01 is satisfied for baseline provenance. INV-02 is partially satisfied by a strict classification schema, starting risks, and starter rows; Plan P02 completes the full inventory row set for INV-01 and INV-02.
</success_criteria>

<source_audit>
SOURCE | ID | Feature/Requirement | Plan | Status | Notes
GOAL | phase-36 | Preserve recent UI cleanup as baseline truth and produce complete inventory before more UI changes | P01,P02 | COVERED | P01 preserves baseline/schema; P02 completes inventory.
REQ | BASE-01 | Clean baseline preserves recent UI cleanup as committed prior art | P01 | COVERED | Git provenance and existing proof citations.
REQ | INV-01 | Inspect current UI inventory across foundations, primitives, component groups, pages, hooks, fixtures, tests, docs, one-offs | P02 | COVERED | Full row collection is in dependent plan.
REQ | INV-02 | See canonical, legacy, duplicated, missing, page-specific classifications | P01,P02 | COVERED | P01 defines schema; P02 applies to rows.
RESEARCH | no new dependencies | Phase 36 should not install packages or add runtime lab | P01 | COVERED | Explicit action and threat model.
RESEARCH | risk register | Required stable risk IDs and row risk refs | P01,P02 | COVERED | P01 seeds risks; P02 cross-links rows.
CONTEXT | D-01..D-28 | Locked user decisions | P01,P02 | COVERED | Decision IDs visible in must_haves and task acceptance criteria.
</source_audit>

<output>
Create `.planning/phases/36-baseline-and-inventory/36-P01-SUMMARY.md` when done.
</output>
