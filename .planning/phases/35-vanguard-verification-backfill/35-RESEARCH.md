# Phase 35: Vanguard Verification Backfill - Research

**Researched:** 2026-05-21
**Requirement focus:** `EVAL-01`, `EVAL-02`, `EVAL-03`, `ORCH-01`, `ORCH-02`, `ORCH-03`, `OBS-01`, `OBS-02`

## Planning Answer

What needs to be true to plan this phase well:

- Phase 35 is a verification-chain backfill and validation-normalization phase, not a new runtime feature phase. The correct outputs are canonical phase-local docs in the existing Phase 30 through Phase 34 directories.
- The milestone audit already identifies the required closure scope precisely: create `30-VERIFICATION.md` through `34-VERIFICATION.md`, create `33-VALIDATION.md`, and remove the requirement-orphan state for all v1.8 requirements.
- Phase 35 should stay phase-local. Broad roadmap, requirements, project, and milestone-state reconciliation belongs to Phase 36 and should not be pulled into this phase except where a phase-local validation doc must be corrected to support truthful verification.
- Existing proof is strong enough that planning should center on evidence synthesis and terminal-truth normalization, not on inventing new tests. The audit already records a passing targeted lane spanning phases 30 through 34.
- The main planning risk is false verification: copying summary prose forward without tying each requirement to exact commands, durable artifacts, and chronology-aware backfill language.

## Current Implementation Reality

### The missing chain is documentary, not functional

- `.planning/v1.8-MILESTONE-AUDIT.md` reports `gaps_found`, but also records that the cross-phase proof lanes for phases 30 through 34 passed locally.
- Phases 30, 31, 32, and 34 already have `*-VALIDATION.md` artifacts, but none of phases 30 through 34 has a canonical `*-VERIFICATION.md`.
- Phase 33 has three implementation summaries, but no `33-VALIDATION.md` and no `33-VERIFICATION.md`.
- Phase 34 additionally has a stale validation-environment assumption: its commands use `SCORIA_DB_PORT=55432`, while the audit says the current checkout validates against the compiled repo config on port `5432`.

### The requirement-orphan problem is traceability, not missing implementation

- `EVAL-01` and `EVAL-03` are implemented by Phase 30 and already have focused validation commands in `30-VALIDATION.md`.
- `ORCH-02` and `ORCH-03` are implemented by Phase 31 and already have focused validation scenarios in `31-VALIDATION.md`.
- `ORCH-01` is implemented by Phase 32 and already has focused validation scenarios in `32-VALIDATION.md`.
- `EVAL-02` is implemented across the three Phase 33 plans, and the summaries already record `requirements-completed: [EVAL-02]`.
- `OBS-01` and `OBS-02` are implemented across the three Phase 34 plans, and the summaries already record `requirements-completed: [OBS-01, OBS-02]`.

## Recommended Architecture

### 1. Treat each original phase directory as the canonical proof boundary

Write the missing verification reports directly into:

- `.planning/phases/30-oban-infrastructure-and-queue-segregation/30-VERIFICATION.md`
- `.planning/phases/31-model-routing-and-resiliency-foundation/31-VERIFICATION.md`
- `.planning/phases/32-multi-model-fallback-orchestration/32-VERIFICATION.md`
- `.planning/phases/33-distributed-evaluation-fan-out/33-VERIFICATION.md`
- `.planning/phases/34-real-time-operator-dashboards/34-VERIFICATION.md`

This matches the repo's established backfill pattern from Phase 16, where the restoring phase writes canonical proof into the original implementation phase directories instead of centralizing proof inside the backfill phase.

### 2. Normalize validation artifacts only where they block truthful closeout

- Phases 30 through 32 likely need light normalization so their validation docs reflect terminal truth, explicit requirement closure, and current proof commands rather than planning-era prose.
- Phase 33 needs a new `33-VALIDATION.md` built in the modern Nyquist format, using the already-landed implementation and targeted proof lanes from the audit plus Phase 33 summaries.
- Phase 34 likely needs a surgical validation update so its environment assumptions and approval wording match the current repo-supported proof path before `34-VERIFICATION.md` cites it as canonical evidence.

### 3. Keep milestone-state reconciliation out of scope

Do not use Phase 35 to reconcile:

- `.planning/ROADMAP.md`
- `.planning/milestones/v1.8-ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/milestones/v1.8-REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `.planning/MILESTONES.md`
- `.planning/MILESTONE-ARC.md`

Those drift fixes are explicitly reserved by Phase 36. Phase 35 should only do the minimum phase-local evidence work required so Phase 36 can reconcile live state against a truthful verification chain.

## Existing Code And Doc Patterns To Reuse

- `.planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-01-PLAN.md`
- `.planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-02-PLAN.md`
- `.planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-03-PLAN.md`
  - Backfill-plan shape for phase-local verification restoration and scoped reconciliation boundaries.
- `.planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-VERIFICATION.md`
  - Chronology-aware backfill language for a verification-restoration phase.
- `.planning/phases/18-add-executable-adoption-flow-guards/18-VERIFICATION.md`
  - Lightweight canonical verification-report format with `Goal Achievement`, `Verification Evidence`, `UAT Summary`, and `Residual Risks`.
- `.planning/phases/22-curated-connector-profiles-and-boring-adoption-path/22-VERIFICATION.md`
  - Plan-checker output style for what a passing plan package looks like.
- `.planning/phases/34-real-time-operator-dashboards/34-VALIDATION.md`
  - Modern Nyquist validation template with frontmatter, per-task verification map, and sign-off structure.
- `.planning/phases/33-distributed-evaluation-fan-out/33-01-SUMMARY.md` through `33-03-SUMMARY.md`
  - Requirement, command, and chronology evidence for Phase 33 backfill.
- `.planning/phases/34-real-time-operator-dashboards/34-01-SUMMARY.md` through `34-03-SUMMARY.md`
  - Requirement, command, and chronology evidence for Phase 34 backfill.

## Recommended Plan Split

1. Phase 30 and Phase 31 backfill:
   create `30-VERIFICATION.md` and `31-VERIFICATION.md`, normalize any blocking validation wording, and map `EVAL-01`, `EVAL-03`, `ORCH-02`, and `ORCH-03` to exact targeted proof.
2. Phase 32 and Phase 33 backfill:
   create `32-VERIFICATION.md`, create `33-VALIDATION.md`, create `33-VERIFICATION.md`, and tie `ORCH-01` plus `EVAL-02` to exact proof lanes and summary-backed chronology.
3. Phase 34 backfill:
   normalize `34-VALIDATION.md` to the supported environment, create `34-VERIFICATION.md`, and record the final dashboard proof lane for `OBS-01` and `OBS-02`.

This split keeps each plan bounded and lines up with the real artifact risk:

- Plans 1 and 2 handle the older or missing verification docs.
- Plan 3 handles the freshest but still environment-sensitive dashboard proof lane.

## Verification Implications

- The milestone audit's targeted passing lane is the best cross-phase closure command for this phase:
  - `MIX_ENV=test mix test test/scoria/oban_config_test.exs test/scoria/workflows/batch_enqueue_test.exs test/scoria/observe/circuit_breaker_test.exs test/scoria/observe/circuit_breaker_manager_test.exs test/scoria/req/steps/circuit_breaker_test.exs test/scoria/req/steps/resiliency_test.exs test/scoria/req/steps_test.exs test/scoria/orchestrator_test.exs test/scoria/compaction/summarize_worker_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/eval_campaign_persistence_test.exs test/scoria/eval/eval_run_persistence_test.exs test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/eval/dashboard_projection_test.exs test/scoria_web/live/orchestrator_live_test.exs`
- Phase-local verification docs should cite smaller requirement-specific commands first, then cite the stitched cross-phase lane as secondary integrated proof.
- Because this phase edits planning artifacts, grep-based checks should be first-class verification, especially for:
  - requirement ids
  - exact verification commands
  - `verified_on` chronology
  - `verified_by_phase: 35-vanguard-verification-backfill` or equivalent chronology notes
  - removal of stale `⬜ pending`, unsupported env vars, or planned-tense approval lines

## Risks And Constraints

### Main risks

- Copying old validation wording directly into verification reports can preserve stale environment assumptions or planned-tense language.
- Pulling live-state reconciliation into this phase will blur the phase boundary and collide with Phase 36.
- Treating broad full-suite success as primary proof will weaken requirement-level traceability compared with the original implementation seams.
- Overwriting historical audit snapshots would destroy the chronology the backfill phase is supposed to preserve.

### Scope constraints

- Keep edits localized to Phase 30 through 34 directories plus Phase 35 planning inputs.
- Preserve `.planning/v1.8-MILESTONE-AUDIT.md` as a historical pre-backfill gap snapshot.
- Use exact requirement ids in every verification artifact.
- Use the current repo-supported test environment in commands; do not perpetuate `SCORIA_DB_PORT=55432` where the audit says it is no longer valid.

## Suggested Planner Rules

- Every plan should produce artifacts in the original phase directory, not in the Phase 35 directory.
- Every task should state exact file targets and exact grep or test verification commands.
- Every plan should include a threat model focused on false verification, chronology drift, and stale-state propagation.
- No plan should update global roadmap, milestone, or requirements bookkeeping unless the edit is strictly phase-local and required to make a validation doc truthful.

## Sources

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/milestones/v1.8-ROADMAP.md`
- `.planning/milestones/v1.8-REQUIREMENTS.md`
- `.planning/v1.8-MILESTONE-AUDIT.md`
- `.planning/phases/30-oban-infrastructure-and-queue-segregation/30-VALIDATION.md`
- `.planning/phases/31-model-routing-and-resiliency-foundation/31-VALIDATION.md`
- `.planning/phases/32-multi-model-fallback-orchestration/32-VALIDATION.md`
- `.planning/phases/33-distributed-evaluation-fan-out/33-01-SUMMARY.md`
- `.planning/phases/33-distributed-evaluation-fan-out/33-02-SUMMARY.md`
- `.planning/phases/33-distributed-evaluation-fan-out/33-03-SUMMARY.md`
- `.planning/phases/34-real-time-operator-dashboards/34-01-SUMMARY.md`
- `.planning/phases/34-real-time-operator-dashboards/34-02-SUMMARY.md`
- `.planning/phases/34-real-time-operator-dashboards/34-03-SUMMARY.md`
- `.planning/phases/34-real-time-operator-dashboards/34-VALIDATION.md`
- `.planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-01-PLAN.md`
- `.planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-02-PLAN.md`
- `.planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-03-PLAN.md`
- `.planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-VERIFICATION.md`
