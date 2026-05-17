# Phase 16: Re-verify Keystone Identity and Runtime API - Pattern Map

**Mapped:** 2026-05-16
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md` | config | transform | `.planning/phases/07-seismograph/07-VERIFICATION.md` | exact |
| `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md` | config | transform | `.planning/phases/07-seismograph/07-VERIFICATION.md` | exact |
| `.planning/phases/12-canonical-runtime-identity/12-VALIDATION.md` | config | transform | `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md` | exact |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` | exact |
| `.planning/PROJECT.md` | config | transform | `.planning/PROJECT.md` | exact |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` | exact |

## Pattern Assignments

### `.planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md` (config, transform)

**Primary analog:** `.planning/phases/07-seismograph/07-VERIFICATION.md`

**Supporting analogs:** `.planning/phases/12-canonical-runtime-identity/12-VALIDATION.md`, `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-01-SUMMARY.md`

**Frontmatter + heading pattern** (`07-VERIFICATION.md` lines 1-10):
```markdown
---
phase: 07-seismograph
status: passed
verified_on: 2026-05-12
verified_by_phase: 11-re-verify-seismograph-and-align-milestone-state
---

# Phase 7 Verification Report
```

**Requirements coverage section pattern** (`07-VERIFICATION.md` lines 13-21):
```markdown
## Requirements Coverage
- `SRE-01`: Passed. ...
- `SRE-02`: Passed. ...
- `SRE-03`: Passed. ...
```

**Test evidence pattern** (`07-VERIFICATION.md` lines 23-29):
```markdown
## Test Evidence
- `SCORIA_DB_HOST=localhost ... mix test ...`
- Result: `63 tests, 0 failures`
- `SCORIA_DB_HOST=localhost ... MIX_ENV=test mix test`
- Result: `1 doctest, 139 tests, 0 failures (13 excluded)`
```

**Evidence-chain chronology pattern** (`07-VERIFICATION.md` lines 31-36):
```markdown
## Evidence Chain Notes
- The original `v1.3` audit in `.planning/v1.3-MILESTONE-AUDIT.md` remains a historical gap snapshot ...
- Phase 11 backfills this verification artifact so Seismograph has the normal validation -> verification closeout chain.
```

**Command source pattern to copy into the report** (`12-VALIDATION.md` lines 35-40):
```markdown
| 12-01-01 | 01 | 1 | IDEN-01 | ... | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs` | ❌ W0 | ⬜ pending |
| 12-01-02 | 01 | 1 | IDEN-01 | ... | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/identity_test.exs` | ❌ W0 | ⬜ pending |
| 12-02-01 | 02 | 2 | IDEN-02 | ... | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/workflows/integration_test.exs test/scoria/sre/audit_outbox_test.exs` | ✅ | ⬜ pending |
| 12-03-01 | 03 | 3 | IDEN-02 | ... | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows/runtime_telemetry_test.exs test/scoria/mcp/executor_telemetry_test.exs test/scoria/sre/telemetry_test.exs` | ✅ | ⬜ pending |
```

**Manual acceptance-script seed** (`12-VALIDATION.md` lines 50-54):
```markdown
## Manual-Only Verifications
| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator evidence reads coherently after the identity refactor | IDEN-02 | Existing suites prove persistence and telemetry, but not notebook readability end-to-end | Open the workflow/operator LiveView against a run with actor, tenant, and session ids and confirm approval/evidence drilldowns show the same durable identity lineage |
```

**Backfill framing precedent** (`11-01-SUMMARY.md` lines 13-20):
```markdown
## Accomplishments
- Wrote `.planning/phases/07-seismograph/07-VERIFICATION.md` to close the missing verification gap ...
- Re-verified the repaired Seismograph seams with one consolidated focused suite ...
```

**Apply to this file**
- Keep the 07 verification skeleton intact: frontmatter, goal achievement, requirements coverage, test evidence, evidence-chain notes, residual risks.
- Replace the generic requirements bullets with `IDEN-01` and `IDEN-02`, using Phase 12’s targeted identity lanes plus the bounded manual operator walkthrough.
- Make the chronology explicit with `verified_on: 2026-05-16` and `verified_by_phase: 16-re-verify-keystone-identity-and-runtime-api`.

---

### `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md` (config, transform)

**Primary analog:** `.planning/phases/07-seismograph/07-VERIFICATION.md`

**Supporting analogs:** `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md`, `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-01-SUMMARY.md`

**Frontmatter + report structure** (`07-VERIFICATION.md` lines 1-10, 23-39):
```markdown
---
phase: 07-seismograph
status: passed
verified_on: 2026-05-12
verified_by_phase: 11-re-verify-seismograph-and-align-milestone-state
---

## Test Evidence
- `...`
- Result: `...`

## Evidence Chain Notes
- `...`

## Residual Risks
- `...`
```

**Per-requirement proof source** (`13-VALIDATION.md` lines 39-44):
```markdown
| 13-01-01 | 01 | 1 | `RUNT-01` | `T-13-01-*` | Public facade starts runs without exposing workflow-internal contract shape | unit + integration | `MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs` | ✅ | ✅ green |
| 13-02-01 | 02 | 2 | `IDEN-03`, `RUNT-02` | `T-13-02-*` | Resume uses exact `run_id`, preserves same-session continuity, and does not infer resume from `session_id` | integration | `MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/workflows/integration_test.exs` | ✅ | ✅ green |
| 13-03-01 | 03 | 3 | `RUNT-03` | `T-13-03-*` | Inspect APIs return curated stable DTOs instead of raw workflow schemas | unit | `MIX_ENV=test mix test test/scoria/runtime_view_test.exs test/scoria/runtime_test.exs` | ✅ | ✅ green |
| 13-04-01 | 04 | 4 | `IDEN-03`, `RUNT-01`, `RUNT-02`, `RUNT-03` | `T-13-04-*` | End-to-end public runtime flow proves multi-run same-session continuity and operator-visible state alignment | integration | `MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/workflows/integration_test.exs` | ✅ | ✅ green |
```

**Closeout-pass pattern** (`13-VALIDATION.md` lines 22-23, 30-32, 74):
```markdown
| **Quick run command** | `MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_view_test.exs test/scoria/workflows/integration_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test` |

- **After every plan wave:** Run `MIX_ENV=test mix test`
- **Before `$gsd-verify-work`:** Full suite must be green

**Approval:** validated via targeted lanes plus full `mix test`
```

**Backfill framing precedent** (`11-01-SUMMARY.md` lines 13-20):
```markdown
- Wrote `.planning/phases/07-seismograph/07-VERIFICATION.md` to close the missing verification gap ...
- Re-ran the default lane ... so milestone closeout records current truth instead of historical assumptions.
```

**Apply to this file**
- Use the same section order as `07-VERIFICATION.md`, but make the core body a requirement-to-command matrix for `IDEN-03`, `RUNT-01`, `RUNT-02`, and `RUNT-03`.
- Treat the targeted runtime lanes as primary proof and one fresh `MIX_ENV=test mix test` run as secondary regression hygiene.
- Keep the evidence-chain notes explicit that this is a Phase 16 backfill into the original Phase 13 directory.

---

### `.planning/phases/12-canonical-runtime-identity/12-VALIDATION.md` (config, transform)

**Primary analog:** `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md`

**Supporting analog:** `.planning/phases/12-canonical-runtime-identity/12-VALIDATION.md`

**Validated frontmatter pattern** (`13-VALIDATION.md` lines 1-8):
```markdown
---
phase: 13
slug: public-runtime-api-and-session-lifecycle
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-14
---
```

**Terminal-truth task table pattern** (`13-VALIDATION.md` lines 37-46):
```markdown
## Per-Task Verification Map
| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | `RUNT-01` | `T-13-01-*` | ... | unit + integration | `MIX_ENV=test mix test ...` | ✅ | ✅ green |
```

**Manual-verification placement pattern** (`12-VALIDATION.md` lines 50-54):
```markdown
## Manual-Only Verifications
| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator evidence reads coherently after the identity refactor | IDEN-02 | Existing suites prove persistence and telemetry, but not notebook readability end-to-end | Open the workflow/operator LiveView against a run with actor, tenant, and session ids and confirm approval/evidence drilldowns show the same durable identity lineage |
```

**Approval-line pattern** (`13-VALIDATION.md` line 74):
```markdown
**Approval:** validated via targeted lanes plus full `mix test`
```

**Apply to this file**
- Preserve the existing Phase 12 table and manual-verification section shape.
- Convert frontmatter and terminal lines from pre-execution truth to post-verification truth: `status`, per-row `Status`, and approval text should match the actual rerun results.
- Do not delete the manual section; tighten it into a bounded acceptance script with explicit observations instead of leaving a vague reminder.

---

### `.planning/ROADMAP.md` (config, transform)

**Primary analog:** `.planning/ROADMAP.md`

**Supporting analog:** `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-02-SUMMARY.md`

**Phase block pattern** (`ROADMAP.md` lines 23-35, 37-50, 80-92):
```markdown
### Phase 12: Canonical Runtime Identity
...
Plans:

- [ ] 12-01: Identity Envelope and Public Runtime Nouns
- [ ] 12-02: Workflow and Approval Identity Propagation
- [ ] 12-03: Telemetry and Audit Identity Alignment

**Requirement coverage:** `IDEN-01`, `IDEN-02`
```

**Progress-table pattern** (`ROADMAP.md` lines 122-132):
```markdown
## Progress
| Phase | Milestone | Plans Complete | Status |
|-------|-----------|----------------|--------|
| 12. Canonical Runtime Identity | v1.4 | 0/3 | Pending |
| 13. Public Runtime API and Session Lifecycle | v1.4 | 0/4 | Pending |
```

**State-alignment intent** (`11-02-SUMMARY.md` lines 13-18):
```markdown
## Accomplishments
- Updated milestone status documents to reflect the shipped state of `v1.3 Seismograph`.
- Promoted the new Seismograph verification artifact into the milestone evidence chain ...
```

**Apply to this file**
- Update the Phase 12 and 13 plan checkboxes and the progress table in place; do not invent a parallel closeout section.
- Keep Phase 16 as the backfill phase, but make `ROADMAP.md` reflect that 12 and 13 are already shipped/verified reality once the canonical verification files exist.
- Follow the same terse status language already used elsewhere in the roadmap.

---

### `.planning/PROJECT.md` (config, transform)

**Primary analog:** `.planning/PROJECT.md`

**Supporting analog:** `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-02-SUMMARY.md`

**Key decisions table pattern** (`PROJECT.md` lines 72-75):
```markdown
## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Activate `v1.4 Keystone` after `v1.3 Seismograph` | ... | — Pending |
```

**State-alignment intent** (`11-02-SUMMARY.md` lines 13-18):
```markdown
## Accomplishments
- Updated milestone status documents to reflect the shipped state ...
- Promoted the new verification artifact into the milestone evidence chain ...
```

**Apply to this file**
- Update only the current-tense Keystone decision outcomes that are false after the Phase 12 and 13 backfill.
- Keep milestone narrative, scope, and historical context intact; this file should not become a second verification report.
- Use terse explicit completed-truth language in the `Outcome` column instead of leaving `— Pending`.

---

### `.planning/REQUIREMENTS.md` (config, transform)

**Primary analog:** `.planning/REQUIREMENTS.md`

**Supporting analog:** `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-02-SUMMARY.md`

**Requirement checklist pattern** (`REQUIREMENTS.md` lines 8-18):
```markdown
### Identity
- [ ] **IDEN-01**: ...
- [ ] **IDEN-02**: ...
- [ ] **IDEN-03**: ...

### Runtime API
- [ ] **RUNT-01**: ...
- [ ] **RUNT-02**: ...
- [ ] **RUNT-03**: ...
```

**Traceability table pattern** (`REQUIREMENTS.md` lines 53-69):
```markdown
## Traceability
| Requirement | Phase | Status |
|-------------|-------|--------|
| IDEN-01 | Phase 16 | Pending |
| IDEN-02 | Phase 16 | Pending |
| IDEN-03 | Phase 16 | Pending |
| RUNT-01 | Phase 16 | Pending |
| RUNT-02 | Phase 16 | Pending |
| RUNT-03 | Phase 16 | Pending |
```

**State-alignment intent** (`11-02-SUMMARY.md` lines 13-16):
```markdown
- Updated the `v1.3` requirements archive so the final requirement outcomes reflect satisfied milestone behavior rather than the pre-fix audit snapshot.
```

**Apply to this file**
- Flip the Phase 12/13 requirement checkboxes and traceability rows to terminal truth once `12-VERIFICATION.md` and `13-VERIFICATION.md` exist.
- Keep the requirement prose unchanged; only reconcile completion and traceability metadata.
- Preserve the table shape and footer summary.

---

### `.planning/STATE.md` (config, transform)

**Primary analog:** `.planning/STATE.md`

**Supporting analog:** `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-02-SUMMARY.md`

**Current-position pattern** (`STATE.md` lines 8-16):
```markdown
## Current Position
**Milestone:** v1.4 Keystone
**Phase:** 15. Adoption Surface, Docs, and Example Flow
**Plan:** Complete
**Status:** Executed and validated
**Last activity:** 2026-05-15 - Phase 15 executed with passing runtime, install-lane, and migration-lane validation
```

**Todo / reference-update pattern** (`STATE.md` lines 56-66):
```markdown
**Todos:**
- Reconcile roadmap/state tracking for the already-landed Phase 12 and 13 runtime work so milestone bookkeeping matches the shipped code.

**Reference Updates:**
- `v1.3 Seismograph` shipped-state evidence lives in `.planning/phases/07-seismograph/07-VERIFICATION.md` plus follow-on Phase 8-11 artifacts.
```

**State-alignment note pattern** (`11-02-SUMMARY.md` lines 11-19):
```markdown
**The planning surface now treats `v1.3 Seismograph` as shipped everywhere that previously disagreed, while keeping the original audit as a historical gap snapshot.**
...
## Notes
- The historical `v1.3` audit remains unchanged as a dated checkpoint of the issues Phase 8-11 closed.
```

**Apply to this file**
- Move the current position forward from Phase 15 to the current Phase 16 truth after re-verification lands.
- Remove or rewrite the explicit TODO about reconciling Phase 12/13 once that work is complete.
- Add reference updates that point to the new `12-VERIFICATION.md` and `13-VERIFICATION.md`, while keeping historical audit files framed as snapshots rather than editing them.

## Shared Patterns

### Canonical Verification Artifact Shape
**Source:** `.planning/phases/07-seismograph/07-VERIFICATION.md` lines 1-39
**Apply to:** `.planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md`, `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md`
```markdown
---
phase: 07-seismograph
status: passed
verified_on: 2026-05-12
verified_by_phase: 11-re-verify-seismograph-and-align-milestone-state
---

## Requirements Coverage
- ...

## Test Evidence
- `...`
- Result: `...`

## Evidence Chain Notes
- ...

## Residual Risks
- ...
```

### Requirement-To-Command Validation Matrix
**Source:** `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md` lines 37-46
**Apply to:** `13-VERIFICATION.md`, `12-VALIDATION.md`
```markdown
## Per-Task Verification Map
| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| ... | ... | ... | ... | ... | ... | ... | `mix test ...` | ✅ | ✅ green |
```

### Manual Acceptance Script Instead Of Vague Reminder
**Source:** `.planning/phases/12-canonical-runtime-identity/12-VALIDATION.md` lines 50-54
**Apply to:** `12-VALIDATION.md`, `12-VERIFICATION.md`
```markdown
## Manual-Only Verifications
| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator evidence reads coherently after the identity refactor | IDEN-02 | Existing suites prove persistence and telemetry, but not notebook readability end-to-end | Open the workflow/operator LiveView against a run with actor, tenant, and session ids and confirm approval/evidence drilldowns show the same durable identity lineage |
```

### Live-State Reconciliation Stays In Place
**Source:** `.planning/ROADMAP.md` lines 122-132; `.planning/REQUIREMENTS.md` lines 53-69; `.planning/STATE.md` lines 56-66; `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-02-SUMMARY.md` lines 13-19
**Apply to:** `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`
```markdown
## Progress
| Phase | Milestone | Plans Complete | Status |
|-------|-----------|----------------|--------|
| 12. Canonical Runtime Identity | v1.4 | 0/3 | Pending |

## Traceability
| Requirement | Phase | Status |
|-------------|-------|--------|
| IDEN-01 | Phase 16 | Pending |

**Todos:**
- Reconcile roadmap/state tracking for the already-landed Phase 12 and 13 runtime work so milestone bookkeeping matches the shipped code.
```

## No Analog Found

None. Every Phase 16 target file has an exact in-repo structural analog.

## Metadata

**Analog search scope:** `.planning/`, especially phase-local verification/validation artifacts and live milestone-state docs
**Files scanned:** 10
**Pattern extraction date:** 2026-05-16
