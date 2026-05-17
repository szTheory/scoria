# Phase 16: Re-verify Keystone Identity and Runtime API - Research

**Researched:** 2026-05-16 [VERIFIED: shell session]
**Domain:** Verification backfill and milestone-state reconciliation for Keystone identity and public runtime APIs [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: repo-local planning artifacts and current code/test seams were inspected directly]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Phase 12 should be treated as unverified until Phase 16 reruns the current-code targeted identity lanes, completes the bounded manual operator-evidence walkthrough, and writes a canonical `12-VERIFICATION.md`. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-02:** The Phase 12 proof bar should be strict but proportional: rerun the Phase 12 identity/propagation lanes plus one downstream Phase 13 runtime smoke lane to prove the public runtime still honors canonical identity. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-03:** `12-VALIDATION.md` must be brought to terminal truth as part of this phase. Pending task rows cannot remain after verification closes. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-04:** The manual-only operator evidence check is required closure evidence, not optional polish. It should be converted into a bounded acceptance script with explicit expected observations. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-05:** Canonical backfilled proof must live in `.planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md` and `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md`, not only in Phase 16 artifacts. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-06:** Phase 16 may add a small link-first summary of the re-verification pass, but that summary must point back to the canonical phase-local verification files rather than duplicating them as a second source of truth. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-07:** Backfilled verification files must make chronology explicit with current verification date plus clear attribution that the proof was backfilled by Phase 16, preserving the historical audit trail instead of pretending those files existed earlier. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-08:** Phase 16 must reconcile every live milestone-state surface that still implies Phase 12 or 13 work is pending, not just `ROADMAP.md` and `REQUIREMENTS.md`. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-09:** Live-state reconciliation includes `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, relevant progress markers, stale validation status/task rows, and bookkeeping notes whose present-tense meaning is now false. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-10:** Historical audit artifacts such as `.planning/v1.4-MILESTONE-AUDIT.md` remain immutable dated snapshots. Phase 16 corrects current truth around them; it does not rewrite them. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-11:** Phase 13 re-verification should record targeted runtime lanes as the primary acceptance evidence for `IDEN-03`, `RUNT-01`, `RUNT-02`, and `RUNT-03`. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-12:** Phase 13 should also record one fresh full `MIX_ENV=test mix test` closeout pass as secondary regression hygiene, clearly framed as a confidence pass rather than the requirement proof itself. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-13:** `13-VERIFICATION.md` should use a requirement-to-command matrix that maps each requirement to the public runtime seam and the exact test command that proves it. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-14:** Missing `*-VERIFICATION.md` artifacts, stale validation status rows, and orphaned requirement traceability should be treated as workflow defects that GSD prevents by default rather than choices the user must repeatedly weigh in on. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-15:** Backfill/reconciliation phases should default to canonical phase-local verification artifacts plus a small re-verification summary, targeted proof lanes plus one closeout full-suite pass, and explicit separation between live-state docs and historical audit snapshots. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **D-16:** User interruption should be reserved for genuinely product-shaping decisions. Naming, artifact placement, requirement metadata, and evidence formatting conventions should be shifted left into GSD defaults unless they materially change product shape or milestone scope. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]

### Claude's Discretion
- Exact wording and frontmatter fields used to mark verification chronology, provided they clearly distinguish current verification truth from historical gap snapshots. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- Exact acceptance-script format for the bounded manual operator-evidence check, provided it is short, reproducible, and produces explicit observations. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- Exact grouping of targeted Phase 12 and Phase 13 verification commands, provided requirement traceability stays direct and the public-runtime contract remains explicit. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Pulling Phase 17 defaults/adoption re-verification work into Phase 16. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- Pulling Phase 18 executable docs/operator harness guards into Phase 16 as a blocking requirement. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- Broad archival rewriting of historical milestone audits or older notes to erase the fact that verification drift existed. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- Any reopening of the product-shape decisions from Phases 12 and 13; those are already locked and only need proof plus state reconciliation here. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `IDEN-01` | A Scoria run can carry explicit actor, tenant, and session identifiers through its canonical runtime entrypoint. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse `test/scoria/identity_test.exs`, `test/scoria/workflows_test.exs`, and one public-facade smoke lane to prove normalization plus durable persistence through the current `Scoria` boundary. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; test/scoria/identity_test.exs; test/scoria/workflows_test.exs; test/scoria/runtime_test.exs] |
| `IDEN-02` | Workflow, approval, telemetry, and audit paths preserve the same actor, tenant, and session identity without requiring app-specific internal conventions. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse approval/runtime/audit and telemetry lanes, then close with a bounded manual operator-evidence walkthrough because Phase 12 still has a manual-only acceptance gap. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; test/scoria/workflows/runtime_test.exs; test/scoria/workflows/integration_test.exs; test/scoria/workflows/runtime_telemetry_test.exs; test/scoria/mcp/executor_telemetry_test.exs; test/scoria/sre/telemetry_test.exs] |
| `IDEN-03` | Session identity supports resumable app-facing flows so a Phoenix app can continue a prior run without reconstructing hidden state manually. [VERIFIED: .planning/REQUIREMENTS.md] | Use the public runtime integration lane that proves same-session new runs and exact `run_id` resume without session-driven inference. [VERIFIED: test/scoria/runtime_integration_test.exs; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md] |
| `RUNT-01` | Developers can start a run through a documented public `Scoria` API instead of assembling lower-level workflow modules directly. [VERIFIED: .planning/REQUIREMENTS.md] | Use `test/scoria_test.exs`, `test/scoria/runtime_test.exs`, and the facade-driven integration lane as the canonical proof set. [VERIFIED: test/scoria_test.exs; test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs] |
| `RUNT-02` | Developers can resume an interrupted or approval-paused run through the same public runtime surface. [VERIFIED: .planning/REQUIREMENTS.md] | Map requirement closure directly to `Scoria.resume_run/2` coverage in `test/scoria/runtime_integration_test.exs`, not to substrate-only resume tests. [VERIFIED: test/scoria/runtime_integration_test.exs; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| `RUNT-03` | Developers can inspect the current state of a run, including status and durable identifiers needed by the host app. [VERIFIED: .planning/REQUIREMENTS.md] | Use `test/scoria/runtime_view_test.exs` and `test/scoria/runtime_test.exs` to prove curated DTO inspection and session grouping without leaking workflow schemas. [VERIFIED: test/scoria/runtime_view_test.exs; test/scoria/runtime_test.exs; lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex] |
</phase_requirements>

## Summary

Phase 16 is a closure-and-traceability phase, not a feature-design phase. The current repo already ships `Scoria.Identity`, the public `Scoria` and `Scoria.Runtime` lifecycle APIs, curated runtime DTOs, and targeted tests for identity propagation, resume semantics, and inspection contracts; the audit gap exists because the canonical phase verification artifacts are missing and Phase 12 validation still reports pending rows. [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex; lib/scoria/identity.ex; lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex; .planning/v1.4-MILESTONE-AUDIT.md; .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md]

The planning implication is simple: do not spend Phase 16 rediscovering product semantics. Reuse the existing repo-local proof seams, write canonical `12-VERIFICATION.md` and `13-VERIFICATION.md` in the original phase directories, convert the one Phase 12 manual check into a short acceptance script with expected observations, and then reconcile every live milestone-state surface that still says Phases 12 and 13 are pending. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md; .planning/phases/07-seismograph/07-VERIFICATION.md; .planning/v1.4-MILESTONE-AUDIT.md]

The main risk is false closeout. If Phase 16 only adds a Phase 16 summary, or only updates `ROADMAP.md`, the milestone will still have orphaned requirements because the canonical proof chain and Phase 12 terminal validation truth will still be missing. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md; .planning/v1.4-MILESTONE-AUDIT.md]

**Primary recommendation:** Plan Phase 16 as three narrow deliverables only: backfill `12-VERIFICATION.md`, backfill `13-VERIFICATION.md`, and reconcile all live-state docs and validation/status rows to those artifacts. [VERIFIED: .planning/ROADMAP.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical identity proof for app-facing run entry | API / Backend | Frontend Server (SSR) | The durable truth and public boundary live in `Scoria`, `Scoria.Runtime`, `Scoria.Identity`, and workflow persistence; UI state is only a consumer of that truth. [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex; lib/scoria/identity.ex; lib/scoria/workflows.ex] |
| Approval/audit/telemetry identity propagation proof | API / Backend | — | The verified seam is the workflow/runtime/MCP/SRE path, not the browser, and the target tests exercise those backend modules directly. [VERIFIED: test/scoria/workflows/runtime_test.exs; test/scoria/workflows/runtime_telemetry_test.exs; test/scoria/mcp/executor_telemetry_test.exs; test/scoria/sre/telemetry_test.exs] |
| Public start/resume/inspect contract proof | API / Backend | Frontend Server (SSR) | Requirement closure belongs to the public runtime facade and its DTOs; LiveView evidence is supporting proof for operator-visible alignment. [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex; test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs; test/scoria/runtime_view_test.exs] |
| Manual operator-evidence walkthrough | Frontend Server (SSR) | API / Backend | The acceptance script must inspect the workflow LiveView, but it is validating projections of backend truth rather than creating new truth. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; lib/scoria_web/live/workflow_live/show.ex] |
| Canonical verification artifact placement | Static / Docs | — | The required evidence chain is phase-local markdown in the original phase directories. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] |
| Milestone-state reconciliation | Static / Docs | — | The drift is in planning/state artifacts such as `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, and validation/status docs. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/STATE.md; .planning/v1.4-MILESTONE-AUDIT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ExUnit` | bundled with Elixir `1.19.5` in this environment [VERIFIED: mix --version] | Primary automated proof runner for targeted and full-suite verification. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md] | All current identity/runtime proof lanes are already authored as ExUnit tests, so Phase 16 should reuse them instead of inventing new harnesses. [VERIFIED: test/scoria_test.exs; test/scoria/identity_test.exs; test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs] |
| `ecto_sql` | `3.13.5` in `mix.lock` [VERIFIED: mix.lock] | Test DB transaction and sandbox-backed workflow truth. [VERIFIED: config/test.exs; lib/scoria/workflows.ex] | Identity/runtime proof depends on durable row writes and reads, so DB-backed verification is the canonical seam. [VERIFIED: test/scoria/workflows_test.exs; test/scoria/runtime_integration_test.exs] |
| `phoenix_live_view` | `1.1.30` in `mix.lock` [VERIFIED: mix.lock] | Operator-visible workflow proof and public-runtime alignment checks. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; test/scoria/runtime_integration_test.exs] | The only manual lane left in scope is operator evidence readability, which is rendered through LiveView. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; lib/scoria_web/live/workflow_live/show.ex] |
| `repo-local verification artifacts` | phase-local markdown [VERIFIED: .planning/phases/07-seismograph/07-VERIFICATION.md; shell session] | Canonical closeout evidence chain. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] | The audit gap exists specifically because these artifacts are missing for Phases 12 and 13. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Phoenix.LiveViewTest` | bundled with repo Phoenix stack [VERIFIED: mix.lock; test/scoria/runtime_integration_test.exs] | Automated operator-page alignment proof around approval pause and resume. [VERIFIED: test/scoria/runtime_integration_test.exs] | Use for the Phase 13 runtime smoke lane and for reducing manual operator inspection scope. [VERIFIED: test/scoria/runtime_integration_test.exs; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] |
| `Scoria.Identity` | repo-local module [VERIFIED: lib/scoria/identity.ex] | Canonical identity entrypoint under test. [VERIFIED: lib/scoria/identity.ex; test/scoria/identity_test.exs] | Use whenever Phase 16 maps a proof lane back to `IDEN-01` or `IDEN-02`. [VERIFIED: .planning/REQUIREMENTS.md; test/scoria/identity_test.exs] |
| `Scoria` + `Scoria.Runtime` | repo-local modules [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex] | Canonical public runtime seam under test. [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex] | Use whenever Phase 16 maps a proof lane back to `IDEN-03` or `RUNT-*`. [VERIFIED: .planning/REQUIREMENTS.md; test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs; test/scoria/runtime_view_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Canonical phase-local verification files [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] | A Phase 16-only verification note [VERIFIED: context] | This would leave the original phases without their required evidence chain and keep the audit finding fundamentally unresolved. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md] |
| Targeted proof lanes plus one closeout full suite [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] | Full `mix test` as the only evidence [VERIFIED: context] | A full suite alone does not map requirements to seams and cannot close the orphaned verification matrix cleanly. [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md; .planning/v1.4-MILESTONE-AUDIT.md] |
| Updating validation/status rows to terminal truth [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] | Leaving old pending rows with a new summary note [VERIFIED: context] | The milestone would still contain contradictory current-state records. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/STATE.md] |

**Installation:** No new Hex dependency is required for Phase 16; the work is evidence-writing, test execution, and planning-doc reconciliation on the current stack. [VERIFIED: mix.exs; mix.lock; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

Phase 16 verification and reconciliation flow [VERIFIED: context + repo]:

```text
Existing repo code/tests
        |
        v
Targeted identity lanes
  - identity normalization
  - workflow/approval propagation
  - telemetry/audit propagation
        |
        +--------------------------+
        |                          |
        v                          v
Bounded manual operator      Targeted public runtime lanes
evidence walkthrough         - start via Scoria
through workflow LiveView    - resume by exact run_id
                             - inspect DTOs/session grouping
        |                          |
        +-------------+------------+
                      |
                      v
Canonical phase-local verification files
  - 12-VERIFICATION.md
  - 13-VERIFICATION.md
                      |
                      v
Validation/state reconciliation
  - 12-VALIDATION.md terminal truth
  - ROADMAP.md progress/status
  - REQUIREMENTS.md traceability
  - STATE.md + related current-status notes
                      |
                      v
Historical audit remains unchanged as dated gap snapshot
```

### Recommended Project Structure
```text
.planning/
├── phases/
│   ├── 12-canonical-runtime-identity/
│   │   ├── 12-VALIDATION.md
│   │   └── 12-VERIFICATION.md        # create in Phase 16
│   ├── 13-public-runtime-api-and-session-lifecycle/
│   │   ├── 13-VALIDATION.md
│   │   └── 13-VERIFICATION.md        # create in Phase 16
│   └── 16-re-verify-keystone-identity-and-runtime-api/
│       ├── 16-CONTEXT.md
│       └── 16-RESEARCH.md
├── ROADMAP.md
├── REQUIREMENTS.md
└── STATE.md
```

### Pattern 1: Backfill Verification Into The Original Phase Directory
**What:** Write the missing canonical verification artifact into the original phase directory, then let the re-verification phase summarize or link to it. [VERIFIED: .planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-CONTEXT.md; .planning/phases/07-seismograph/07-VERIFICATION.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]  
**When to use:** Any backfill phase where the code already shipped but the verification chain is broken. [VERIFIED: .planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-CONTEXT.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]  
**Example:**
```markdown
---
phase: 12-canonical-runtime-identity
status: passed
verified_on: 2026-05-16
verified_by_phase: 16-re-verify-keystone-identity-and-runtime-api
---
```

### Pattern 2: Requirement-To-Command Verification Matrix
**What:** Each canonical verification file should map every requirement to the exact command or manual script that proves it. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md; .planning/phases/07-seismograph/07-VERIFICATION.md]  
**When to use:** Especially for backfill phases where summaries and green suites already exist but requirement closure is still orphaned. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md]  
**Example:**
```markdown
| Requirement | Proof seam | Evidence |
|-------------|------------|----------|
| `RUNT-02` | exact durable resume through `Scoria.resume_run/2` | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs` |
```

### Pattern 3: Terminal-Truth Validation Cleanup
**What:** Update stale validation task rows once the rerun is complete so validation status reflects present truth rather than historical pre-closeout state. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md; .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md]  
**When to use:** Any time a phase is Nyquist-compliant in structure but still carries pending execution rows after work shipped. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md]  
**Example:**
```markdown
| 12-03-01 | 03 | 3 | IDEN-02 | ... | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test ...` | ✅ | ✅ green |
```

### Anti-Patterns to Avoid
- **Phase-16-only evidence:** Do not let Phase 16 become the only place where proof lives. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **Summary-driven closure:** Do not infer requirement completion from `*-SUMMARY.md` prose alone. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md]
- **Historical audit rewrites:** Do not edit `.planning/v1.4-MILESTONE-AUDIT.md` to make the gap disappear retroactively. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
- **Unbounded manual check:** Do not leave the Phase 12 operator evidence lane as a vague human reminder; it must become a short script with expected observations. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Canonical verification structure | A brand-new Phase 16-specific evidence format | The existing `07-VERIFICATION.md` shape plus phase-local verification files for 12 and 13 [VERIFIED: .planning/phases/07-seismograph/07-VERIFICATION.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] | The repo already has a working precedent for backfilled canonical verification. [VERIFIED: .planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-01-SUMMARY.md; .planning/phases/07-seismograph/07-VERIFICATION.md] |
| New proof harnesses | Fresh ad hoc scripts for identity/runtime semantics | The existing targeted ExUnit lanes already named in `12-VALIDATION.md`, `13-VALIDATION.md`, and plan summaries [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md; .planning/phases/12-canonical-runtime-identity/12-01-SUMMARY.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-04-SUMMARY.md] | The code seams under test are already stable and directly aligned to the requirements. [VERIFIED: test/scoria/identity_test.exs; test/scoria/runtime_integration_test.exs; test/scoria/runtime_view_test.exs] |
| State reconciliation logic | Implicit “it is obviously done now” updates | Explicit edits to each stale planning/state surface listed by the audit and Phase 16 context [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] | This phase exists because implicit completion left contradictory artifacts behind. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/STATE.md] |

**Key insight:** The hard part is not proving the runtime works; the hard part is restoring the repo’s evidence chain and current-state truth without creating a second, competing source of closure. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating green validation as equivalent to canonical verification
**What goes wrong:** The phase looks “done” in conversation, but requirements remain orphaned because the canonical `*-VERIFICATION.md` layer is still missing. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md]  
**Why it happens:** Plan summaries and validation docs already contain green-looking evidence, so it is tempting to stop there. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-01-SUMMARY.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-04-SUMMARY.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md]  
**How to avoid:** Treat the verification file as the closure artifact and write it first-class in the original phase directory. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]  
**Warning signs:** A plan proposes only Phase 16 summaries or only status-doc edits. [VERIFIED: context]

### Pitfall 2: Reconciling only `ROADMAP.md`
**What goes wrong:** One visible status surface flips to completed while `REQUIREMENTS.md`, `STATE.md`, validation rows, and current bookkeeping notes still say pending. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/STATE.md; .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md]  
**Why it happens:** `ROADMAP.md` is the loudest progress surface, but it is not the only live truth surface. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]  
**How to avoid:** Build a fixed reconciliation checklist from the audit and context, then clear every item. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]  
**Warning signs:** `ROADMAP.md` shows completion while requirement traceability or validation rows remain pending. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md]

### Pitfall 3: Letting the manual operator check stay fuzzy
**What goes wrong:** Phase 12 still cannot close cleanly because the one manual acceptance seam has no bounded script or expected observations. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md]  
**Why it happens:** The repo already has automated tests for persistence and telemetry, so manual evidence feels secondary. [VERIFIED: test/scoria/workflows_test.exs; test/scoria/workflows/runtime_telemetry_test.exs; test/scoria/mcp/executor_telemetry_test.exs]  
**How to avoid:** Convert the manual row into a short operator walkthrough that names exact setup, route, and observations. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]  
**Warning signs:** “Open the page and make sure it looks right” style language. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md]

### Pitfall 4: Reopening Phase 12 and 13 product decisions
**What goes wrong:** The verification phase expands into redesign, new API semantics, or adoption-surface work that belongs to later phases. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]  
**Why it happens:** Verification touches the same files and tests as the original feature work, which can invite “while we are here” changes. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-CONTEXT.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]  
**How to avoid:** Keep proof lanes constrained to already-shipped seams and keep docs edits restricted to chronology and current-state truth. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]  
**Warning signs:** Proposed tasks that modify runtime semantics, new public APIs, or Phase 17/18 deliverables. [VERIFIED: context]

## Code Examples

Verified repo-local proof seams:

### Public Runtime Resume Proof
```elixir
# Source: test/scoria/runtime_integration_test.exs
assert {:ok, resumed} =
         Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

assert resumed.run_id == started.run_id
```
[VERIFIED: test/scoria/runtime_integration_test.exs]

### Curated Public Inspection DTO Proof
```elixir
# Source: test/scoria/runtime_view_test.exs
assert {:ok, %RunSummary{} = summary} = Runtime.get_run(run.id)
assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(run.id)
refute Enum.any?(Map.values(detail), &match?(%Scoria.Workflows.Run{}, &1))
```
[VERIFIED: test/scoria/runtime_view_test.exs]

### Canonical Identity Normalization Proof
```elixir
# Source: test/scoria/identity_test.exs
identity =
  Identity.from_conn_assigns(%{
    current_actor: %{id: "actor-3"},
    current_tenant: %{id: "tenant-3"},
    session_id: "session-3"
  })
```
[VERIFIED: test/scoria/identity_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Summary-only and validation-only closeout for Phases 12 and 13 [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-01-SUMMARY.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-04-SUMMARY.md] | Canonical phase-local verification is required to close requirements and milestone state cleanly [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md; .planning/v1.4-MILESTONE-AUDIT.md] | Gap identified on 2026-05-16 in the milestone audit [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md] | Phase 16 should formalize the missing evidence layer instead of adding more summary prose. [VERIFIED: context] |
| Phase 12 validation table still marked pending [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md] | Terminal-truth validation rows must reflect the rerun outcome [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] | Required by Phase 16 on 2026-05-16 [VERIFIED: context] | Planner must include explicit validation-doc edits, not only command reruns. [VERIFIED: context + audit] |
| Milestone live-state surfaces disagree about whether Phase 12 and 13 are done [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/STATE.md] | Current-state artifacts should all align to the canonical verification files while leaving dated audits unchanged [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] | Drift documented on 2026-05-16 [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md] | Phase 16 planning must treat doc reconciliation as a first-class deliverable, not cleanup. [VERIFIED: audit + context] |

**Deprecated/outdated:**
- Treating Phase 12 or 13 summaries as sufficient milestone closure evidence is outdated in this repo’s workflow because the audit now requires canonical verification artifacts for normal closeout. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `PROJECT.md` is a live-state reconciliation target for Phase 16 because its `Key Decisions` table still uses current-tense `— Pending` markers for already-executed Keystone activation/scope decisions. [RESOLVED] | `## Open Questions (RESOLVED)` [VERIFIED: .planning/PROJECT.md] | If omitted, Phase 16 would leave one current-tense milestone surface falsely signaling unresolved Keystone activation/scope status. [VERIFIED: .planning/PROJECT.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] |
| A2 | This research should be considered fresh through 2026-06-15 unless additional milestone-state edits land first. [ASSUMED] | `## Metadata` [VERIFIED: file section] | Planner may rely on stale state-drift findings if other agents edit the planning surface before execution. [VERIFIED: repo workflow context] |

## Open Questions (RESOLVED)

1. **Which live-state surfaces beyond `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, and `12-VALIDATION.md` should Phase 16 update if they still carry present-tense falsehoods?** [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md]
   - Resolution: `PROJECT.md` is in scope for Phase 16 because its `Key Decisions` table still uses present-tense `— Pending` markers for Keystone activation and milestone scope decisions even though the milestone is active and Phases 12 through 15 already executed. [VERIFIED: .planning/PROJECT.md; .planning/ROADMAP.md; .planning/STATE.md]
   - Planning impact: the reconciliation plan must update `PROJECT.md` alongside `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md`, while still leaving historical audits untouched. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md; .planning/v1.4-MILESTONE-AUDIT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | All targeted and full-suite verification commands [VERIFIED: validation docs] | ✓ [VERIFIED: shell session] | `Mix 1.19.5` [VERIFIED: mix --version] | — |
| `elixir` / OTP | Running the repo test suite [VERIFIED: repo stack] | ✓ [VERIFIED: shell session] | `Elixir 1.19.5`, `Erlang/OTP 28` [VERIFIED: mix --version] | — |
| PostgreSQL test DB | Durable workflow/runtime verification lanes [VERIFIED: config/test.exs; tests] | ✓ [VERIFIED: pg_isready] | `psql 14.17`; `localhost:55432` accepts connections [VERIFIED: psql --version; pg_isready -h localhost -p 55432] | No practical fallback for the targeted integration lanes. [VERIFIED: config/test.exs; test suite shape] |

**Missing dependencies with no fallback:**
- None detected for the current machine. [VERIFIED: shell session]

**Missing dependencies with fallback:**
- None. [VERIFIED: shell session]

## Validation Architecture

Validation is enabled by default because `.planning/config.json` is absent in this repo, so there is no explicit `workflow.nyquist_validation: false` override. [VERIFIED: shell session]

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `ExUnit` with `Phoenix.LiveViewTest` for integration/operator alignment lanes [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md; test/scoria/runtime_integration_test.exs] |
| Config file | `config/test.exs` for DB-backed test configuration [VERIFIED: config/test.exs] |
| Quick run command | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/identity_test.exs test/scoria/workflows_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_view_test.exs` [VERIFIED: existing validation docs and current seam coverage] |
| Full suite command | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| `IDEN-01` | Canonical identity normalizes once and persists on run creation. [VERIFIED: requirements + tests] | unit + integration [VERIFIED: 12-VALIDATION.md] | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/identity_test.exs test/scoria/workflows_test.exs` [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; test files] | ✅ [VERIFIED: shell session] |
| `IDEN-02` | Approval, runtime, MCP, telemetry, and audit seams preserve root identity consistently. [VERIFIED: requirements + tests] | integration [VERIFIED: 12-VALIDATION.md] | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/workflows/integration_test.exs test/scoria/sre/audit_outbox_test.exs test/scoria/workflows/runtime_telemetry_test.exs test/scoria/mcp/executor_telemetry_test.exs test/scoria/sre/telemetry_test.exs` [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; test files] | ✅ [VERIFIED: shell session] |
| `IDEN-03` | Public runtime preserves same-session continuity while resume stays exact to `run_id`. [VERIFIED: requirements + tests] | integration [VERIFIED: 13-VALIDATION.md] | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/workflows/integration_test.exs` [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md] | ✅ [VERIFIED: shell session] |
| `RUNT-01` | Public `Scoria` API starts runs through the documented facade. [VERIFIED: requirements + tests] | unit + integration [VERIFIED: 13-VALIDATION.md] | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs` [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md] | ✅ [VERIFIED: shell session] |
| `RUNT-02` | Public `Scoria` API resumes approval-paused runs through the same surface. [VERIFIED: requirements + tests] | integration [VERIFIED: 13-VALIDATION.md] | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/workflows/integration_test.exs` [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md] | ✅ [VERIFIED: shell session] |
| `RUNT-03` | Public inspection returns curated DTOs and session grouping helpers. [VERIFIED: requirements + tests] | unit [VERIFIED: 13-VALIDATION.md] | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_view_test.exs test/scoria/runtime_test.exs` [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md] | ✅ [VERIFIED: shell session] |

### Sampling Rate
- **Per task commit:** `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/identity_test.exs test/scoria/workflows_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_view_test.exs` [VERIFIED: recommended from current seam set]
- **Per wave merge:** `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` [VERIFIED: validation docs]
- **Phase gate:** Full suite green before `/gsd-verify-work`, with `12-VERIFICATION.md`, `13-VERIFICATION.md`, and `12-VALIDATION.md` updated in the same closeout. [VERIFIED: context + validation docs]

### Wave 0 Gaps
- None for code-level tests; all required identity/runtime proof files already exist. [VERIFIED: test/scoria_test.exs; test/scoria/identity_test.exs; test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs; test/scoria/runtime_view_test.exs; test/scoria/workflows/runtime_telemetry_test.exs; test/scoria/mcp/executor_telemetry_test.exs; test/scoria/sre/telemetry_test.exs]
- The remaining gap is documentation/evidence structure: `12-VERIFICATION.md` and `13-VERIFICATION.md` do not exist yet, and `12-VALIDATION.md` still has pending rows plus one manual-only acceptance lane. [VERIFIED: shell session; .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; .planning/v1.4-MILESTONE-AUDIT.md]

## Security Domain

Security enforcement is treated as enabled because there is no repo config explicitly disabling it. [VERIFIED: shell session]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Phase 16 does not design authentication; it verifies runtime identity propagation and public API closure only. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] |
| V3 Session Management | yes [VERIFIED: requirements] | `session_id` remains host-owned continuity context while `run_id` remains exact resume truth. [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md; test/scoria/runtime_integration_test.exs] |
| V4 Access Control | yes [VERIFIED: approval/operator evidence scope] | Workflow-owned approval and audit seams remain the control point for operator actions. [VERIFIED: lib/scoria/workflows.ex; test/scoria/workflows_test.exs] |
| V5 Input Validation | yes [VERIFIED: public runtime boundary] | `Scoria.Identity.normalize/1` and `Scoria.Runtime.Params` define the public boundary normalization path under test. [VERIFIED: lib/scoria/identity.ex; lib/scoria/runtime/params.ex] |
| V6 Cryptography | no [VERIFIED: phase scope] | No cryptographic design work is introduced in this verification/backfill phase. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Resuming the wrong run via `session_id` inference [VERIFIED: Phase 13 context] | Tampering / Elevation of Privilege | Keep `resume_run/2` exact to `run_id` and verify that seam directly in public-runtime integration tests. [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md; test/scoria/runtime_integration_test.exs] |
| Identity drift between run truth and approval/audit evidence [VERIFIED: Phase 12 scope] | Repudiation / Information Disclosure | Re-run approval/runtime/audit identity lanes and the manual operator-evidence walkthrough before closing `IDEN-02`. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md; test/scoria/workflows/runtime_test.exs; test/scoria/sre/audit_outbox_test.exs] |
| False status reporting in milestone artifacts [VERIFIED: audit] | Repudiation | Reconcile every live-state surface to the canonical verification files while leaving the dated audit immutable. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md` - locked scope, artifact placement, proof bar, and reconciliation breadth. [VERIFIED: file]
- `.planning/v1.4-MILESTONE-AUDIT.md` - exact gap inventory, orphaned requirements, and state-drift evidence. [VERIFIED: file]
- `.planning/phases/12-canonical-runtime-identity/12-VALIDATION.md` - targeted Phase 12 proof lanes and the remaining manual-only check. [VERIFIED: file]
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md` - targeted Phase 13 proof lanes and full-suite closeout precedent. [VERIFIED: file]
- `lib/scoria.ex`, `lib/scoria/runtime.ex`, `lib/scoria/identity.ex`, `lib/scoria/runtime/run_summary.ex`, `lib/scoria/runtime/run_detail.ex` - current shipped public/runtime/identity seams. [VERIFIED: files]
- `test/scoria/identity_test.exs`, `test/scoria/runtime_test.exs`, `test/scoria/runtime_integration_test.exs`, `test/scoria/runtime_view_test.exs`, `test/scoria/workflows/runtime_telemetry_test.exs`, `test/scoria/mcp/executor_telemetry_test.exs`, `test/scoria/sre/telemetry_test.exs` - current proof seams already present in the repo. [VERIFIED: files]
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/PROJECT.md` - current live-state surfaces and drift evidence. [VERIFIED: files]
- `config/test.exs`, `mix.exs`, `mix.lock`, `mix --version`, `pg_isready -h localhost -p 55432`, `psql --version` - environment and stack verification. [VERIFIED: file + shell session]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: research process]

### Tertiary (LOW confidence)
- None. [VERIFIED: research process]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the verification stack is entirely repo-local and environment-probed in this session. [VERIFIED: mix.lock; config/test.exs; shell session]
- Architecture: HIGH - the phase scope and canonical artifact placement are locked explicitly in Phase 16 context and supported by the Phase 11 precedent. [VERIFIED: .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md; .planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-CONTEXT.md]
- Pitfalls: HIGH - the concrete failure modes are already recorded in the milestone audit and stale planning artifacts. [VERIFIED: .planning/v1.4-MILESTONE-AUDIT.md; .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md]

**Research date:** 2026-05-16 [VERIFIED: shell session]
**Valid until:** 2026-06-15 for repo-local planning truth unless additional milestone-state edits land first. [ASSUMED]
