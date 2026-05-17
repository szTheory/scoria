# Phase 17: Re-verify Keystone Defaults and Adoption Surface - Pattern Map

**Mapped:** 2026-05-16
**Files analyzed:** 12
**Analogs found:** 9 / 9 anticipated files

## Planning Patterns

### PLAN.md structure

Use the neighboring re-verification execute plans directly for Phase 17 plan authoring.

**Frontmatter pattern** from `16-01-PLAN.md`, `16-02-PLAN.md`, and `16-03-PLAN.md`:

```md
---
phase: 17-re-verify-keystone-defaults-and-adoption-surface
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/14-policy-defaults-and-install-ergonomics/14-VERIFICATION.md
requirements:
  - POLY-01
must_haves:
  truths:
    - "..."
  artifacts:
    - path: "..."
      provides: "..."
  key_links:
    - from: "..."
      to: "..."
      via: "..."
      pattern: "..."
---
```

**Body section order** from neighboring Keystone plans:

```md
<objective>...</objective>
<execution_context>...</execution_context>
<context>...</context>
<tasks>...</tasks>
<threat_model>...</threat_model>
<verification>...</verification>
<success_criteria>...</success_criteria>
<output>...</output>
```

### Phase 17 plan granularity

Copy the roadmap split from [ROADMAP.md](/Users/jon/projects/scoria/.planning/ROADMAP.md:94). Phase 17 is already defined as three narrow plans:

- `17-01`: backfill Phase 14 verification
- `17-02`: backfill Phase 15 verification
- `17-03`: reconcile defaults and adoption traceability

Each plan should keep the same neighboring pattern:

- 1-3 tasks only
- one proof/reconciliation seam per task
- explicit `files_modified`
- targeted verification commands
- a short `done` condition tied to `POLY-*` or `ADOP-*`

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VERIFICATION.md` | config | transform | `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md` | exact-structure |
| `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VERIFICATION.md` | config | transform | `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md` | exact-structure |
| `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md` | config | transform | `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md` | exact |
| `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md` | config | transform | `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md` | exact |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` | exact |
| `.planning/PROJECT.md` | config | transform | `.planning/PROJECT.md` | exact |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` | exact |
| `.planning/MILESTONES.md` | config | transform | `.planning/MILESTONES.md` | exact |

## Pattern Assignments

### `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VERIFICATION.md`

**Primary analog:** `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md`

**Supporting analogs:** `.planning/phases/07-seismograph/07-VERIFICATION.md`, `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md`

**Apply to this file**
- Keep the chronology-aware verification report structure: frontmatter with `status`, `verified_on`, and `verified_by_phase`, then requirements coverage, test evidence, evidence-chain notes, and residual risks.
- Pull the exact proof commands from `14-VALIDATION.md` into the canonical report and map them directly to `POLY-01`, `POLY-02`, and `POLY-03`.
- Record one fresh full `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` pass as secondary regression evidence, not the primary proof source.
- Add one bounded manual install-to-run observation note that ties install, migrate, test, `start_run`, `get_run`, `/scoria`, and `/scoria/workflows/:run_id` into the same durable evidence chain.

### `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VERIFICATION.md`

**Primary analog:** `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md`

**Supporting analogs:** `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md`, `.planning/phases/07-seismograph/07-VERIFICATION.md`

**Apply to this file**
- Use the same report skeleton as the other backfilled verification files.
- Make the core body a requirement-to-command matrix for `ADOP-01` through `ADOP-04`, with runtime integration tests as the behavioral anchor and README/docs assertions as secondary semantic evidence.
- Preserve the distinction between behavioral proof and wording checks in the evidence notes.
- Add one bounded manual operator walkthrough note for the `/scoria/workflows/:run_id` evidence lane, tied to a concrete `run_id` observation rather than a screenshot or vague approval.

### `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md`

**Primary analog:** `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md`

**Supporting analog:** `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md`

**Apply to this file**
- Preserve the existing per-task verification matrix because it already names the right seams and commands.
- Update frontmatter and terminal lines from planned/executed truth to post-verification truth once the backfill is complete.
- Keep the manual section, but tighten it into a numbered acceptance script with expected observations and a final recorded note.
- Do not leave pending markers or future-tense closure wording once `14-VERIFICATION.md` exists.

### `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md`

**Primary analog:** `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md`

**Apply to this file**
- Preserve the current matrix and compile/content checks because they already encode the shipped proof lanes.
- Convert the file from execution-era validation to terminal-truth validation by adding the backfill chronology and removing any ambiguity that this still awaits canonical closeout.
- Expand the manual section from “no manual-only validation” to the bounded operator walkthrough now required by Phase 17’s context.

### `.planning/ROADMAP.md`

**Primary analog:** `.planning/ROADMAP.md`

**Apply to this file**
- Update the Phase 14 and 15 progress/checkmark status in place after canonical verification exists; do not invent a parallel closeout section.
- Keep Phase 17 represented as the backfill phase that restored the evidence chain and reconciled current truth.
- Update the Phase 17 progress row from pending to planned/executed/complete only when the phase’s own plans and reconciliation close.

### `.planning/REQUIREMENTS.md`

**Primary analog:** `.planning/REQUIREMENTS.md`

**Apply to this file**
- Flip `POLY-01`, `POLY-02`, `POLY-03`, and `ADOP-01` through `ADOP-04` from pending to verified status only after the canonical phase-local verification files exist.
- Keep traceability rows pointing to Phase 17 as the verification backfill phase if that is how the repo records chronology, but ensure the evidence chain clearly lands in the original Phase 14 and 15 directories.

### `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/MILESTONES.md`

**Primary analogs:** the files themselves plus the reconciliation style used in Phase 16.

**Apply to these files**
- Keep edits terse and current-truth oriented.
- Promote the new Phase 14 and 15 verification artifacts into the milestone evidence chain and remove present-tense statements that still imply defaults/adoption are unverified.
- Do not rewrite historical shipped-milestone prose outside the current-truth sections.

## Concrete Source Seams

### Phase 14 proof seams

- `test/scoria/prompt_policy_test.exs`
- `test/scoria/runtime/defaults_test.exs`
- `test/scoria/runtime_test.exs`
- `test/scoria/runtime_integration_test.exs`
- `test/mix/tasks/scoria.install_test.exs`
- `test/mix/tasks/scoria.install_route_smoke_test.exs`
- `test/scoria/bootstrap/migration_lane_compatibility_test.exs`
- `test/mix/tasks/scoria.test_knowledge_test.exs`
- `docs/operator_verification.md`

### Phase 15 proof seams

- `README.md`
- `docs/phoenix_runtime_example.md`
- `docs/operator_verification.md`
- `lib/scoria.ex`
- `lib/scoria/runtime.ex`
- `lib/scoria/identity.ex`
- `lib/scoria/prompt_policy.ex`
- `test/scoria/runtime_integration_test.exs`
- `test/mix/tasks/scoria.install_test.exs`
- `test/mix/tasks/scoria.install_route_smoke_test.exs`
- `test/scoria/bootstrap/migration_lane_compatibility_test.exs`

## Anti-Patterns to Avoid

- Do not create a Phase 17-only verification artifact that competes with `14-VERIFICATION.md` or `15-VERIFICATION.md`.
- Do not treat full-suite green or `rg` matches alone as sufficient for requirement closure.
- Do not update current-truth surfaces before the canonical phase-local verification artifacts exist.
- Do not mutate dated milestone audits or old summary files to erase the original gap.
