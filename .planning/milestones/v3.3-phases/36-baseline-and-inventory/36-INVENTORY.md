# Phase 36 Baseline And Inventory

**Created:** 2026-06-20
**Milestone:** v3.3 Design System Stress Test
**Purpose:** Baseline truth and inventory contract for the Scoria admin/operator UI.

## Baseline Truth

Phase 36 starts from the recent `/scoria` UI cleanup as committed prior art before v3.3 planning or implementation work. BASE-01 is satisfied by preserving that cleanup as separate git history and by keeping this phase artifact-only.

Cleanup commits that precede v3.3 planning:

- `1773267`
- `d35906f`
- `4337c5e`
- `452f035`
- `2d324a0`
- `f490cea` (`ui: consolidate scoria control room patterns`)

v3.3 planning begins at `8540e04`; current lineage is inspectable with `git log --oneline -12`. Existing baseline proof is reused rather than reinvented: `test/scoria_web/ui_component_test.exs`, `test/scoria_web/ds06_drift_guard_test.exs`, `test/scoria_web/token_contrast_guard_test.exs`, `priv/dev/e2e/`, `mix scoria.ui.shots`, `priv/shots/gap_register.md`, and `priv/shots/gap_register_final.md`.

Screenshots are advisory baseline evidence only. Phase 36 does not create screenshot-diff CI, does not promote screenshots into a merge gate, and tracks stale v3.0 proof gaps through `RISK-V30-PROOF` rather than treating them as automatic runtime regressions.

## Artifact Contract

Phase 36 produces a paired inventory artifact family per D-01: this Markdown file plus `.planning/phases/36-baseline-and-inventory/36-inventory.json`. The artifacts are repository-local per D-02 and intentionally do not add PhoenixStorybook, a runtime component lab, packages, routes, CSS, tests, fixtures, or runtime UI behavior.

The JSON file is canonical for row IDs, layer/status enums, owner paths, evidence, relationships, documented exclusions, risk object fields, and `risk_refs` per D-03 and D-04. This Markdown file summarizes the inventory, risk narrative, validation commands, exclusions, and later-phase gate for maintainers; it must not become a competing row source.

Generated JSON row fields are exactly: `id`, `name`, `layer`, `status`, `owner_path`, `evidence`, `replacement_or_owner`, `next_action`, and `risk_refs` per D-06. Generated risk fields are exactly: `risk_id`, `title`, `affected_jtbd_persona_operator_flow`, `affected_inventory_refs`, `owner_phase`, `mitigation_evidence_target`, `status`, and `closeout_proof` per D-19.

## Inventory Summary By Layer

INV-01 is covered by 86 JSON rows and 236 documented exclusions. Source reconciliation covers foundations, `ScoriaWeb.UI` primitives, component groups, LiveView pages, CSS/JS hooks, fixtures, tests, docs, and one-off or missing patterns.

| Layer | Rows | Example row IDs |
|-------|------|-----------------|
| `foundation` | 3 | `FOUND-CSS-LAYERS`, `FOUND-BRANDBOOK`, `FOUND-DS06-GUARD` |
| `primitive` | 34 | `PRIM-ATTENTION-CARD`, `PRIM-BADGE`, `PRIM-BUTTON`, `PRIM-COMMAND-PALETTE`, `PRIM-DRAWER`, `PRIM-EMPTY-STATE`, `PRIM-EVIDENCE-ACTION-ROW`, `PRIM-EVIDENCE-EMPTY`, `PRIM-EVIDENCE-ROWS`, `PRIM-EVIDENCE-SECTION` |
| `component-group` | 14 | `GROUP-APPROVAL-INBOX-COMPONENT`, `GROUP-CITATION-EVIDENCE-COMPONENT`, `GROUP-CONNECTOR-DETAIL-DRAWER-COMPONENT`, `GROUP-DELEGATED-EVIDENCE-COMPONENT`, `GROUP-INCIDENT-EVIDENCE-COMPONENT`, `GROUP-LAYOUTS`, `GROUP-MEMORY-NOTEBOOK-COMPONENT`, `GROUP-REMOTE-INVOCATION-EVIDENCE-COMPONENT`, `GROUP-REPLAY-EVIDENCE-NOTEBOOK-COMPONENT`, `GROUP-RUNTIME-DETAIL-DRAWER-COMPONENT` |
| `page` | 16 | `PAGE-LAYOUTS-APP-HTML`, `PAGE-LAYOUTS-ROOT-HTML`, `PAGE-APPROVALS-LIVE-INDEX`, `PAGE-COMING-SOON-LIVE`, `PAGE-CONNECTORS-LIVE-INDEX`, `PAGE-DATASET-LIVE-INDEX`, `PAGE-DATASET-LIVE-PROMOTE-COMPONENT`, `PAGE-EVAL-SPEC-LIVE-INDEX`, `PAGE-INCIDENTS-LIVE-INDEX`, `PAGE-INCIDENTS-LIVE-SHOW` |
| `hook` | 6 | `HOOK-COMMANDPALETTE`, `HOOK-COPYID`, `HOOK-DISMISSABLE`, `HOOK-MOBILENAV`, `HOOK-RECORDRECENTOBJECT`, `HOOK-THEMETOGGLE` |
| `fixture` | 4 | `FIXTURE-TEST-FIXTURES`, `FIXTURE-TEST-SUPPORT`, `FIXTURE-PRIV-DEV-HARNESS`, `FIXTURE-SHOTS-PROOF-DATA` |
| `test` | 2 | `TEST-SCORIA-WEB-UI-PROOF`, `TEST-PLAYWRIGHT-PROOF` |
| `doc` | 2 | `DOC-PRIMARY-SURFACES`, `DOC-SHOTS-GAP-REGISTER` |
| `one-off` | 5 | `ONEOFF-PAGE-LOCAL-SCORIA-CLASSES`, `ONEOFF-RAW-LINK-BUTTON-CLASSES`, `MISSING-COMPONENT-LAB-STATES`, `MISSING-APPROVAL-DECISION-HISTORY`, `MISSING-TOAST-LEGIBILITY-PROOF` |

## Classification Guidance

INV-02 is covered by exact D-05 status values. Canonical row status lives in JSON; this table summarizes current coverage.

| Status | Rows | Example row IDs |
|--------|------|-----------------|
| `canonical` | 65 | `FOUND-CSS-LAYERS`, `FOUND-BRANDBOOK`, `FOUND-DS06-GUARD`, `PRIM-ATTENTION-CARD`, `PRIM-BADGE`, `PRIM-BUTTON`, `PRIM-COMMAND-PALETTE`, `PRIM-DRAWER` |
| `duplicated` | 3 | `PRIM-METRIC`, `PRIM-SIGNAL-STRIP`, `ONEOFF-RAW-LINK-BUTTON-CLASSES` |
| `legacy` | 1 | `FIXTURE-SHOTS-PROOF-DATA` |
| `missing` | 3 | `MISSING-COMPONENT-LAB-STATES`, `MISSING-APPROVAL-DECISION-HISTORY`, `MISSING-TOAST-LEGIBILITY-PROOF` |
| `intentionally-page-specific` | 14 | `PAGE-APPROVALS-LIVE-INDEX`, `PAGE-CONNECTORS-LIVE-INDEX`, `PAGE-DATASET-LIVE-INDEX`, `PAGE-DATASET-LIVE-PROMOTE-COMPONENT`, `PAGE-EVAL-SPEC-LIVE-INDEX`, `PAGE-INCIDENTS-LIVE-INDEX`, `PAGE-INCIDENTS-LIVE-SHOW`, `PAGE-ORCHESTRATOR-LIVE` |

Classification rules remain:

- `canonical`: clear owner, stable API/token/route contract, representative usage, and appropriate proof/docs for the layer (D-07).
- `duplicated`: multiple surfaces solve the same UI job and the row names a preferred consolidation target (D-08).
- `legacy`: still used but superseded, with migration or proof replacement target (D-09).
- `missing`: repeated code/copy/tests/docs imply an absent abstraction, state, fixture, proof, or doc (D-10).
- `intentionally-page-specific`: tied to a named LiveView/operator workflow where extraction would reduce clarity (D-11).

Phoenix ownership remains explicit per D-12: function components with `attr`/`slot` contracts own reusable primitives, LiveComponents own stateful component behavior, JS hooks own browser interop that LiveView/`Phoenix.LiveView.JS` cannot cover cleanly, and CSS stays token-scoped through Scoria design-system layers.

## Known Risk Register

The canonical risk objects live in `36-inventory.json`. Per D-18 and D-23, every later phase that touches a row with `risk_refs` must mitigate the risk, prove it unchanged, or explicitly defer it with evidence.

| Risk | Owner Phase | Title | Affected row refs | Status |
|------|-------------|-------|-------------------|--------|
| `RISK-V30-PROOF` | 41 | Stale v3.0 proof gaps and partial verification-doc coverage | `DOC-MAINTAINERS`, `DOC-PRIMARY-SURFACES`, `DOC-SHOTS-GAP-REGISTER`, `FIXTURE-PRIV-DEV-HARNESS`, `FIXTURE-SHOTS-PROOF-DATA`, `FIXTURE-TEST-FIXTURES`, `FIXTURE-TEST-SUPPORT`, `FOUND-DS06-GUARD`, ... | open |
| `RISK-TOAST-LEGIBILITY` | 38 | Approval warning/error toast readability over dense UI | `FOUND-CSS-COMPONENTS`, `FOUND-CSS-LAYERS`, `MISSING-TOAST-LEGIBILITY-PROOF`, `PAGE-APPROVALS-LIVE-INDEX`, `PRIM-FLASH-GROUP`, `PRIM-SCORIA-UI`, `PRIM-TOAST` | open |
| `RISK-APPROVAL-HISTORY` | 39 | Approval decision history discoverability | `MISSING-APPROVAL-DECISION-HISTORY`, `PAGE-APPROVALS-LIVE-INDEX`, `PRIM-SCORIA-UI` | open |
| `RISK-RESPONSIVE-SCAN` | 40 | Responsive tables/lists and mobile scan paths | `DOC-MAINTAINERS`, `DOC-PRIMARY-SURFACES`, `DOC-SHOTS-GAP-REGISTER`, `FIXTURE-SHOTS-PROOF-DATA`, `FOUND-CSS-COMPONENTS`, `FOUND-CSS-LAYERS`, `MISSING-COMPONENT-LAB-STATES`, `ONEOFF-PAGE-LOCAL-SCORIA-CLASSES`, ... | open |
| `RISK-OVERLAY-FOCUS` | 40 | Overlay focus, dismissal, motion, and theme parity | `DOC-MAINTAINERS`, `DOC-PRIMARY-SURFACES`, `FIXTURE-PRIV-DEV-HARNESS`, `FOUND-CSS-COMPONENTS`, `FOUND-CSS-LAYERS`, `FOUND-CSS-TOKENS`, `HOOK-COMMANDPALETTE`, `HOOK-COPYID`, ... | open |

Required starting risks are present per D-20: `RISK-V30-PROOF`, `RISK-TOAST-LEGIBILITY`, `RISK-APPROVAL-HISTORY`, `RISK-RESPONSIVE-SCAN`, and `RISK-OVERLAY-FOCUS`. D-21 folds the approval toast legibility todo into Phase 38 ownership; D-22 folds approval decision history into Phase 39 ownership.

## Excluded From Phase 36

Phase 36 explicitly does not add PhoenixStorybook, a runtime component lab, screenshot-diff CI, approval decision history implementation, approval toast fixes, CI cache-key cleanup, sibling Docker fleet hardening, or approval semantic changes. It also does not change `/scoria` runtime UI, routes, source files, tests, fixtures, CSS, JavaScript, packages, or database/schema files.

Generated/vendor/binary/report-heavy paths are excluded only through JSON `documented_exclusions`, with `source`, `reason`, and `reviewed_by_phase`. The recursive scanner intentionally excludes node_modules, Playwright reports, test-results, screenshot/binary image files, build/cache outputs, and local filesystem metadata when they do not represent current Scoria design-system ownership.

## Phase 37+ Gate

No Phase 37+ v3.3 implementation phase starts unless both `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` and `.planning/phases/36-baseline-and-inventory/36-inventory.json` exist, parse, and satisfy all of the following:

1. JSON parses successfully.
2. All required risk IDs exist: `RISK-V30-PROOF`, `RISK-TOAST-LEGIBILITY`, `RISK-APPROVAL-HISTORY`, `RISK-RESPONSIVE-SCAN`, `RISK-OVERLAY-FOCUS`.
3. All layer enum values are represented: `foundation`, `primitive`, `component-group`, `page`, `hook`, `fixture`, `test`, `doc`, `one-off`.
4. All status enum values are represented: `canonical`, `duplicated`, `legacy`, `missing`, `intentionally-page-specific`.
5. Every row has required keys, nonempty evidence, unique ID, and only valid `risk_refs`.
6. Source-scan reconciliation passes for foundations, primitives, component groups, pages, hooks, fixtures/proof inputs, tests, docs, and one-off/missing keyword candidates.
7. `git diff --name-only` shows no runtime/source modifications from Phase 36 inventory work.

Downstream defaults are operator-first, Phoenix-native, brandbook-aligned, design-pillar-aware, and decisive unless a choice changes product shape, security/policy boundary, durable truth, tenant blast radius, or materially different operator/adopter workflow (D-24 through D-28).

## Validation

Run these commands from the repository root:

```sh
node -e "JSON.parse(require('fs').readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8'))"
node -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8')); const layers=['foundation','primitive','component-group','page','hook','fixture','test','doc','one-off']; const statuses=['canonical','duplicated','legacy','missing','intentionally-page-specific']; for (const l of layers) if (!j.rows.some(r=>r.layer===l)) throw new Error('missing layer '+l); for (const s of statuses) if (!j.rows.some(r=>r.status===s)) throw new Error('missing status '+s); for (const id of ['RISK-V30-PROOF','RISK-TOAST-LEGIBILITY','RISK-APPROVAL-HISTORY','RISK-RESPONSIVE-SCAN','RISK-OVERLAY-FOCUS']) if (!j.risks.some(r=>r.risk_id===id)) throw new Error('missing risk '+id);"
node -e "const fs=require('fs'); const md=fs.readFileSync('.planning/phases/36-baseline-and-inventory/36-INVENTORY.md','utf8'); for (const s of ['Baseline Truth','Known Risk Register','Phase 37+ Gate','Validation','Multi-Source Coverage Audit']) if (!md.includes(s)) throw new Error('missing section '+s); for (let i=1;i<=28;i++){ const id='D-'+String(i).padStart(2,'0'); if (!md.includes(id)) throw new Error('missing decision '+id); }"
git diff --name-only | grep -Ev '^(\.planning/phases/36-baseline-and-inventory/36-(INVENTORY\.md|inventory\.json|P01-PLAN\.md|P02-PLAN\.md|PATTERNS\.md))$' | wc -l | tr -d ' ' | grep '^0$'
```

Screenshots remain advisory. Existing proof surfaces are cited from ExUnit, Playwright, `mix scoria.ui.shots`, `priv/shots/gap_register.md`, and `priv/shots/gap_register_final.md`; stale v3.0 proof gaps remain visible through `RISK-V30-PROOF`.

## Multi-Source Coverage Audit

| Source | Item | Status | Evidence |
|--------|------|--------|----------|
| GOAL | Preserve recent UI cleanup as baseline truth and inventory current design-system surfaces before more UI changes | COVERED | Baseline Truth, JSON source reconciliation, Phase 37+ Gate |
| BASE-01 | Clean baseline preserving recent UI cleanup as committed prior art | COVERED | Cleanup commits and existing proof surfaces cited above |
| INV-01 | Inventory foundations, primitives, component groups, LiveView pages, CSS/JS hooks, fixtures, tests, docs, one-offs | COVERED | 86 JSON rows across all layer enums |
| INV-02 | Classify canonical, duplicated, legacy, missing, and page-specific patterns | COVERED | All status enums represented in JSON |
| RESEARCH | Paired Markdown plus structured JSON artifacts | COVERED | D-01, D-03, D-04 and artifact contract |
| RESEARCH | Existing proof only; no new visual CI | COVERED | D-13, D-15, D-16, validation/proof sections |
| RESEARCH | No package installs | COVERED | D-02, Excluded From Phase 36 |
| RESEARCH | Parse JSON and assert required fields/enums/risks | COVERED | Validation commands and Task 1 source-scan validators |
| D-01 | COVERED | Paired Markdown plus JSON artifact family is present. |
| D-02 | COVERED | Repository-local artifacts only; no PhoenixStorybook/runtime lab/package install. |
| D-03 | COVERED | Stable IDs are assigned across rows and risks. |
| D-04 | COVERED | JSON owns canonical row and risk fields; Markdown summarizes. |
| D-05 | COVERED | Exact layer/status enums are used and validated. |
| D-06 | COVERED | Every row carries required keys. |
| D-07 | COVERED | Canonical rows require clear owner/evidence/proof. |
| D-08 | COVERED | Duplicated rows identify consolidation targets. |
| D-09 | COVERED | Legacy row points at later proof replacement. |
| D-10 | COVERED | Missing rows identify absent lab/history/toast proof. |
| D-11 | COVERED | Page-specific rows are tied to named LiveView/operator workflows. |
| D-12 | COVERED | Phoenix component, LiveComponent, hook, and token CSS ownership boundaries stay explicit. |
| D-13 | COVERED | Baseline proof is lightweight and layered. |
| D-14 | COVERED | Cleanup commits precede v3.3 planning commits. |
| D-15 | COVERED | Existing ExUnit, Playwright, shots, and Mix proof are reused. |
| D-16 | COVERED | Screenshots stay advisory in Phase 36. |
| D-17 | COVERED | v3.0 proof gaps are risks, not automatic regressions. |
| D-18 | COVERED | Central risk register plus per-row risk_refs. |
| D-19 | COVERED | Risk objects include required owner/evidence/closeout fields. |
| D-20 | COVERED | Five required starting risks are present. |
| D-21 | COVERED | Approval toast legibility todo folded into risk. |
| D-22 | COVERED | Approval decision history todo folded into risk. |
| D-23 | COVERED | Later phases touching risk rows must mitigate/prove/defer. |
| D-24 | COVERED | Operator-first Phoenix library posture preserved. |
| D-25 | COVERED | JTBD/user-flow wording used for next actions. |
| D-26 | COVERED | Brandbook is canonical visual/voice truth. |
| D-27 | COVERED | Design pillars inform row next actions and risks. |
| D-28 | COVERED | Decisive defaults; ask only for product/security/truth/workflow changes. |

---
*Phase: 36-baseline-and-inventory*
*Updated: 2026-06-20*
