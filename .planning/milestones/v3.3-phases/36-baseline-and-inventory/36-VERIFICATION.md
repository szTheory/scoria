---
phase: 36-baseline-and-inventory
verified: 2026-06-20T17:59:28Z
status: passed
score: 17/17 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 36: Baseline And Inventory Verification Report

**Phase Goal:** Preserve the recent UI cleanup as baseline truth and produce a complete design-system inventory before changing more UI.
**Verified:** 2026-06-20T17:59:28Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Current UI cleanup is committed separately from v3.3 work. | VERIFIED | `git merge-base --is-ancestor` passed for cleanup commits `1773267`, `d35906f`, `4337c5e`, `452f035`, `2d324a0`, and `f490cea` before v3.3 start `8540e04`; `36-INVENTORY.md` lists those commits under Baseline Truth. |
| 2 | Inventory names foundations, primitives, component groups, pages, CSS/JS hooks, fixtures, tests, and docs. | VERIFIED | `36-inventory.json` has 86 rows across all 9 layers: foundation, primitive, component-group, page, hook, fixture, test, doc, one-off. |
| 3 | Inventory classifies each item as canonical, duplicated, legacy, missing, or page-specific. | VERIFIED | JSON rows cover all 5 status enums: canonical 65, duplicated 3, legacy 1, missing 3, intentionally-page-specific 14. |
| 4 | Known risks include stale v3.0 proof gaps, toast legibility, approval history, responsive tables/lists, and overlay/focus regressions. | VERIFIED | JSON contains all five required risk IDs: `RISK-V30-PROOF`, `RISK-TOAST-LEGIBILITY`, `RISK-APPROVAL-HISTORY`, `RISK-RESPONSIVE-SCAN`, `RISK-OVERLAY-FOCUS`; risk refs validate against local risk objects. |
| 5 | No implementation phase starts without the inventory artifact. | VERIFIED | `36-INVENTORY.md` has `Phase 37+ Gate` requiring both inventory artifacts to exist, parse, contain required risks, cover layer/status enums, validate rows, pass source reconciliation, and preserve no-runtime-source-change scope. |
| 6 | BASE-01 baseline provenance is visible to maintainers. | VERIFIED | Baseline Truth cites cleanup commits, v3.3 planning start `8540e04`, and existing proof surfaces. |
| 7 | P01 artifact family is repository-local Markdown plus JSON, without runtime lab/source changes. | VERIFIED | Artifacts exist under `.planning/phases/36-baseline-and-inventory/`; `git diff --name-only` had no runtime/source paths. |
| 8 | P01 schema contract uses exact layer/status enums and required row fields. | VERIFIED | Node validation passed for exact `layer_enum`, `status_enum`, and required row fields. |
| 9 | P01 baseline proof uses git provenance and existing proof only. | VERIFIED | Markdown states screenshots are advisory, cites existing ExUnit/Playwright/shots proof, and records v3.0 gaps as `RISK-V30-PROOF`. |
| 10 | P01 central risk register contains required stable risk IDs and per-row risk refs. | VERIFIED | JSON has 5 risk objects with required fields; all row `risk_refs` point to valid local risk IDs. |
| 11 | P01 downstream defaults are operator-first, Phoenix-native, brandbook-aligned, design-pillar-aware, and decisive. | VERIFIED | `36-INVENTORY.md` Phase 37+ Gate records D-24 through D-28 defaults; JSON row `next_action` text uses those constraints. |
| 12 | INV-01 rows cover foundations, primitives, groups, pages, hooks, fixtures, tests, docs, and one-off patterns. | VERIFIED | Independent source-reconciliation validator passed: 267 fixture/proof files accounted for by rows or exclusions, 34 `ScoriaWeb.UI` defs represented, and 6 JS hooks represented. |
| 13 | INV-02 every row uses exact enums and required fields. | VERIFIED | Validator checked unique row IDs, required keys, enum membership, nonempty evidence, and valid `risk_refs` for all 86 rows. |
| 14 | Markdown summarizes while JSON owns stable IDs, canonical status fields, owner paths, evidence, relationships, and risk refs. | VERIFIED | `36-INVENTORY.md` lines under Artifact Contract state JSON is canonical; JSON contains the canonical row/risk fields. |
| 15 | Classification decisions are evidence-backed and respect Phoenix ownership boundaries. | VERIFIED | Every row has nonempty evidence; Markdown records function component, LiveComponent, JS hook, and token-scoped CSS ownership boundaries. |
| 16 | Known risks are centralized and every risky row links to a valid `risk_id`. | VERIFIED | JSON risk validation passed; `RISK-TOAST-LEGIBILITY` owner phase is 38 and `RISK-APPROVAL-HISTORY` owner phase is 39. |
| 17 | Markdown includes final Phase 36 sections, validation, and multi-source coverage audit. | VERIFIED | Markdown validator passed for Baseline Truth, Known Risk Register, Phase 37+ Gate, Validation, Multi-Source Coverage Audit, D-01 through D-28, BASE-01, INV-01, INV-02, and all required risks. |

**Score:** 17/17 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` | Maintainer-readable baseline proof, inventory summaries, risk register, validation, and Phase 37+ gate | VERIFIED | Exists, 160 lines, substantive sections present, manually linked to JSON contract and gate. |
| `.planning/phases/36-baseline-and-inventory/36-inventory.json` | Machine-readable inventory rows, risks, schema metadata, documented exclusions | VERIFIED | Parses as JSON; 86 rows, 5 risks, 236 documented exclusions; strict row/risk/source reconciliation checks passed. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `36-INVENTORY.md` | `36-inventory.json` | Markdown states JSON owns canonical row IDs/status fields | VERIFIED | Manual `rg` found `36-inventory.json` and canonical JSON row/status ownership in Artifact Contract. Generic checker false-negative was caused by escaped pattern handling. |
| `36-inventory.json` | `36-CONTEXT.md` | Required enums, row keys, and risk IDs reflect D-01 through D-28 | VERIFIED | GSD key-link checker found required risk pattern in JSON; Markdown coverage audit cites D-01 through D-28. |
| `36-inventory.json` | `lib/scoria_web/ui.ex` | Primitive rows use `ScoriaWeb.UI` function names | VERIFIED | Source validator found 34 UI defs and matching primitive rows. |
| `36-inventory.json` | `assets/js/scoria.js` | Hook rows use named browser interop capabilities | VERIFIED | Source validator found 6 hooks and matching hook rows. |
| `36-INVENTORY.md` | `.planning/ROADMAP.md` | Phase 37+ gate blocks later implementation without artifacts | VERIFIED | Manual `rg` found `## Phase 37+ Gate` and the implementation-blocking text in Markdown. Generic checker false-negative was caused by escaped pattern handling. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `36-inventory.json` | `rows`, `risks`, `documented_exclusions` | Repository source scan evidence and planning decisions | Yes | VERIFIED - artifact is the canonical static data source for later phases; independent source reconciliation passed. |
| `36-INVENTORY.md` | Summary tables and gate text | `36-inventory.json`, ROADMAP, REQUIREMENTS, D-01..D-28 | Yes | VERIFIED - Markdown summarizes JSON counts and contract without owning row truth. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| JSON parses and schema/risk/row contract holds | Independent Node validator for enums, required fields, risk refs, row IDs, source paths, UI defs, hooks, and keyword hits | `{"rows":86,"risks":5,"exclusions":236,"discoveredFixtureProof":267,"uiDefs":34,"hooks":6,"keywordHits":2,"status":"PASS"}` | PASS |
| Markdown contract contains required sections and IDs | Node Markdown validator | `PASS markdown contract` | PASS |
| Cleanup commits precede v3.3 planning | `git merge-base --is-ancestor` for all cleanup commits before `8540e04` | `PASS cleanup-commits-precede-v33-planning` | PASS |
| Runtime/source scope guard | `git diff --name-only` | No modified runtime/source paths | PASS |
| Full workspace tests | `mix test --no-start --warnings-as-errors` | Not rerun during verification; prior run failed in known unrelated tests listed under residual risk | SKIP |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| None declared | `find scripts -path '*/tests/probe-*.sh'` and plan/summary probe grep | No phase probes found | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BASE-01 | P01 | Maintainer can start v3.3 from a clean baseline preserving recent UI cleanup as committed prior art. | SATISFIED | Baseline Truth, commit ancestry check, proof-surface citations. |
| INV-01 | P02 | Maintainer can inspect a current inventory of foundations, primitives, groups, pages, hooks, fixtures, tests, docs, and one-offs. | SATISFIED | 86 JSON rows across all layers plus source-reconciliation validator. |
| INV-02 | P01, P02 | Maintainer can see canonical, legacy, duplicated, missing, or intentionally page-specific classifications. | SATISFIED | JSON covers exact five statuses and Markdown summarizes classification guidance. |

No Phase 36 requirements are orphaned in `.planning/REQUIREMENTS.md`; the traceability table maps only BASE-01, INV-01, and INV-02 to Phase 36.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `36-INVENTORY.md` | 153 | `TBD` substring inside `JTBD` | INFO | False positive; not a debt marker. |

### Human Verification Required

None. This phase produced planning artifacts, not visual/runtime UI behavior.

### Residual Risk

The broad `mix test --no-start --warnings-as-errors` suite was reported as failing before this verification with three known failures:

- `test/scoria/ci_policy_contract_test.exs:686` expects v2.15 in `.planning/ROADMAP.md`, while the roadmap now reflects v3.3.
- `test/scoria/warning_inventory/capture_parity_test.exs:53` does not capture an injected warning offender.
- `test/scoria/support_copilot_gallery_test.exs:8` expected `Approval inbox`.

These are residual automated-suite risks, but they do not directly contradict Phase 36's artifact requirements. Phase-specific JSON, Markdown, baseline, source reconciliation, risk, gate, and no-runtime-source-change checks passed.

### Gaps Summary

No Phase 36 gaps found.

---

_Verified: 2026-06-20T17:59:28Z_
_Verifier: the agent (gsd-verifier)_
