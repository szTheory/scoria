# Phase 36: Vanguard Milestone-State Reconciliation - Patterns

**Date:** 2026-05-21
**Status:** Complete

## Purpose

Map the files Phase 36 is likely to modify to the closest existing analogs in the repo so planning and execution can reuse proven reconciliation patterns instead of inventing new document behavior.

## Primary Pattern Family

### Pattern: Phase-local proof, top-level projection

**What it is**
- Canonical verification lives in the original phase directory.
- Milestone and root planning surfaces summarize and project from that truth.
- Historical audits remain unchanged as dated gap snapshots.

**Best analogs**
- `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-CONTEXT.md`
- `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-02-SUMMARY.md`
- `.planning/phases/35-vanguard-verification-backfill/35-01-SUMMARY.md`
- `.planning/phases/35-vanguard-verification-backfill/35-02-SUMMARY.md`
- `.planning/phases/35-vanguard-verification-backfill/35-03-SUMMARY.md`

**How to reuse it**
- Keep detailed proof only in `30-VERIFICATION.md` through `34-VERIFICATION.md`.
- Use milestone/root docs to express current state and point down to proof.
- Preserve audit chronology by superseding, not mutating, `.planning/v1.8-MILESTONE-AUDIT.md`.

## File Mapping

| Target file | Role | Closest analog | Reuse pattern |
|-------------|------|----------------|---------------|
| `.planning/ROADMAP.md` | Root phase ledger and progress table | `.planning/ROADMAP.md` current structure plus Phase 11 closeout summary behavior | Update checkbox state, phase details, and progress rows together so headings and tables agree |
| `.planning/milestones/v1.8-ROADMAP.md` | Milestone-local phase ledger | `.planning/ROADMAP.md` structure, but scoped to one milestone | Mirror active Vanguard truth here first, then project upward to root roadmap |
| `.planning/REQUIREMENTS.md` | Root requirement summary / active truth | `.planning/milestones/v1.8-REQUIREMENTS.md` traceability table | Use milestone-local requirement truth as source, then align root traceability / active requirement framing |
| `.planning/milestones/v1.8-REQUIREMENTS.md` | Canonical Vanguard requirement surface | Existing file structure | Mark Vanguard requirement status consistently with restored verification chain and closure-ready posture |
| `.planning/STATE.md` | Current runtime/planning status summary | Existing `STATE.md` headings plus Phase 11 “aligned shipped baseline” outcome | Update Current Focus, Current Position, Progress, and last activity together; do not leave stale Phase 33 / v1.7 narrative |
| `.planning/PROJECT.md` | Product thesis plus current milestone narrative | Existing `PROJECT.md` current milestone and context sections | Keep product shape stable; only update Active/Current Milestone state and context to reflect closure-ready Vanguard truth |
| `.planning/MILESTONES.md` | Milestone ledger and public milestone summaries | Existing `MILESTONES.md` sections for shipped milestones | Vanguard should move toward a post-reconciliation but pre-archival stance; do not copy shipped milestone wording prematurely |
| `.planning/MILESTONE-ARC.md` | Strategic milestone arc and active milestone narrative | Existing `MILESTONE-ARC.md` Active Milestone / Recommendation sections | Update stale v1.7-active narrative and recommended-next narrative without rewriting the broader north-star material |

## Concrete Analog Notes

### 1. `11-02-SUMMARY.md` is the strongest closeout analog

Why:
- It explicitly states that the planning surface now treats a milestone as shipped everywhere that disagreed.
- It preserves the audit as a historical checkpoint instead of mutating it.

Reuse:
- Phrase reconciliation as alignment of planning/status surfaces to restored proof truth.
- Keep the audit immutable.

### 2. `35-03-SUMMARY.md` is the strongest handoff analog

Why:
- It ends with “Phase 35 is execution-complete... remaining milestone-surface reconciliation can proceed in Phase 36.”
- It clearly separates proof restoration from milestone-state bookkeeping.

Reuse:
- Phase 36 actions should assume proof is done and only fix the state surfaces.

### 3. Existing roadmap / milestone-roadmap structures must be updated in lockstep

Why:
- They both use the same basic shape: phases list, phase details, progress table.
- Drift currently exists because one was updated without the other.

Reuse:
- Every phase-status change in one roadmap should have a corresponding update in the other.
- Progress tables must be treated as first-class truth, not an afterthought.

### 4. Existing requirements files use traceability tables as the main truth surface

Why:
- Both the root and milestone-local requirements docs express status via traceability/status tables.

Reuse:
- Align statuses using the restored verification chain.
- Prefer explicit requirement -> phase -> status rows over prose-only claims.

## Execution Patterns to Preserve

### Pattern: Current-truth body plus terse dated supersession note

**Use for**
- `ROADMAP.md`
- `REQUIREMENTS.md`
- `STATE.md`
- `PROJECT.md`
- `MILESTONES.md`
- `MILESTONE-ARC.md`

**Do**
- make the main body read as current truth
- add a short note that the file was reconciled after Phase 35 restored the verification chain on 2026-05-21
- link to `.planning/v1.8-MILESTONE-AUDIT.md` and the relevant `*-VERIFICATION.md` files where useful

**Do not**
- turn every file into a forensic timeline
- imply these statuses were always true historically

### Pattern: Light proof pointers only

**Use for**
- root and milestone-local docs

**Do**
- point to the canonical verification artifact per phase where status closure is claimed

**Do not**
- copy full `MIX_ENV=test mix test ...` command lanes into root docs
- duplicate exact backfill chronology paragraphs from verification files

## Read-First Recommendations for Execution

Before touching:
- `.planning/ROADMAP.md`
  read:
  - `.planning/milestones/v1.8-ROADMAP.md`
  - `.planning/phases/35-vanguard-verification-backfill/35-03-SUMMARY.md`
  - `.planning/phases/30-oban-infrastructure-and-queue-segregation/30-VERIFICATION.md`
  - `.planning/phases/34-real-time-operator-dashboards/34-VERIFICATION.md`

- `.planning/REQUIREMENTS.md`
  read:
  - `.planning/milestones/v1.8-REQUIREMENTS.md`
  - `.planning/phases/30-oban-infrastructure-and-queue-segregation/30-VERIFICATION.md`
  - `.planning/phases/34-real-time-operator-dashboards/34-VERIFICATION.md`

- `.planning/STATE.md`
  read:
  - `.planning/PROJECT.md`
  - `.planning/MILESTONES.md`
  - `.planning/MILESTONE-ARC.md`
  - `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-02-SUMMARY.md`

- `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/MILESTONE-ARC.md`
  read:
  - one another
  - `.planning/v1.8-MILESTONE-AUDIT.md`
  - `.planning/phases/35-vanguard-verification-backfill/35-03-SUMMARY.md`

## Footguns

- Updating phase headings but not progress tables
- Marking Vanguard shipped in one file and closure-ready in another
- Updating root docs before deciding milestone-local truth
- Leaving `STATE.md` and `MILESTONE-ARC.md` stale because they are prose-heavy
- Using vague actions like “align roadmap” instead of naming exact rows/sections that change

## Recommendation

Phase 36 planning should treat this as a docs-state reconciliation package with explicit analog reuse from:
- Phase 11 for milestone-state closeout posture
- Phase 35 for proof-source ownership and chronology discipline
- existing roadmap/requirements/state file structures for mechanical update patterns

## PATTERN MAPPING COMPLETE
