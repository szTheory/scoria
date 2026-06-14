---
phase: 11-evaluation-engine-seed-depth
plan: "01"
subsystem: database
tags: [ecto, seed, postgres, eval, workflows, connectors, incidents, prompt-registry]

# Dependency graph
requires: []
provides:
  - "priv/repo/dev_seed.exs — idempotent seed populating all 9 dashboard screens"
  - "SupportJourney spine: tenant_id/session_id/connector_key as identity source"
  - "≥4 workflow runs (completed, in_progress, handoff, pending_approval)"
  - "≥2 incidents (warning/open, critical/resolved) via IncidentManager"
  - "≥2 connectors (billing/healthy, knowledge-base/degraded) with health_state mix"
  - "≥2 eval specs + 1 completed eval run with score via sealed datasets"
  - "≥3 review candidates (all pending so list_review_queue(%{}) returns ≥3)"
  - "≥2 prompt templates (1 active, 1 draft) + pending release workflow"
  - "Migration 20260523000300 repaired with add_if_not_exists (ai_online_score_candidates created)"
affects:
  - "11-02-harness — needs populated screens before screenshot capture"
  - "11-03-baseline — depends on seeded data for meaningful LLM critiques"
  - "11-04-docs — seed usage documented in MAINTAINERS.md"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SupportJourney spine guard comment: # SupportJourney spine — do not inline these values"
    - "try/rescue per domain block — one broken lane does not abort the whole seed"
    - "Repo.get_by + conditional insert for idempotent non-run entity seeding"
    - "RunSummary.run_id (not .id) from Scoria.start_run/2 return value"

key-files:
  created:
    - "priv/repo/dev_seed.exs"
  modified:
    - "priv/repo/migrations/20260523000300_expand_ai_scores_and_create_online_score_candidates.exs"

key-decisions:
  - "Scoria.start_run/2 returns RunSummary with run_id field, not a Run struct with id — use .run_id when referencing the run for incident/review linking"
  - "list_review_queue(%{}) applies default review_status: pending filter — all 3 seeded candidates must have review_status: pending to satisfy the ≥3 acceptance criterion"
  - "Incidents seeded via IncidentManager.open_incident/1 deduplicated by incident_key (the field IncidentManager stores as dedupe_key), not by the passed dedupe_key attribute"
  - "Migration 20260523000300 had add/remove not add_if_not_exists/remove_if_exists — repaired as Rule 1 bug fix since deleted interim migrations had already applied those columns"

requirements-completed: [EVAL-04]

# Metrics
duration: 90min
completed: 2026-06-04
---

# Phase 11 Plan 01: Seed Depth Summary

**Idempotent dev_seed.exs populating all 9 dashboard screens via SupportJourney spine with IncidentManager, sealed eval datasets, and Ecto-guarded review candidates**

## Performance

- **Duration:** ~90 min
- **Started:** 2026-06-04T07:49:00Z
- **Completed:** 2026-06-04T08:15:00Z
- **Tasks:** 2 (Task 1: core seed + incidents/connectors; Task 2: eval/review/prompt)
- **Files modified:** 2 (dev_seed.exs created, migration repaired)

## Accomplishments

- Created `priv/repo/dev_seed.exs` covering all 9 dashboard screens — runs twice in a row, exits 0 both times, no record doubling
- Spine identity guard comment `# SupportJourney spine — do not inline these values` present exactly once; all identities sourced from `SupportJourney.tenant_id/0`, `session_id/0`, `connector_key/0`
- Repaired migration `20260523000300` that was blocking `ai_online_score_candidates` table creation due to duplicate columns from deleted interim migrations
- All acceptance criteria verified: review queue returns ≥3, eval specs ≥2, seal_dataset present, no `"acme-corp"` literals outside comments, degraded connector seeded

## Task Commits

Each task was committed atomically:

1. **Migration repair (Rule 1 auto-fix)** - `4bca7c9` (fix)
2. **Task 1 + 2: dev_seed.exs** - `4db0c73` (feat)

## Files Created/Modified

- `/Users/jon/projects/scoria/priv/repo/dev_seed.exs` — New idempotent seed script covering all 9 dashboard screens. Organized as domain blocks (Runs, Incidents, Connectors, Eval, Review Queue, Prompt Registry) each wrapped in try/rescue. Closes EVAL-04.
- `/Users/jon/projects/scoria/priv/repo/migrations/20260523000300_expand_ai_scores_and_create_online_score_candidates.exs` — Repaired to use `add_if_not_exists`/`remove_if_exists` and a PL/pgSQL DO block for the reasoning/details backfill that handles missing columns gracefully.

## Decisions Made

- Used `Repo.get_by(Incident, incident_key: ...)` not `dedupe_key:` for idempotency guard — `IncidentManager.open_incident/1` sets `dedupe_key = incident_key` internally, not the passed `dedupe_key` field
- All 3 review candidates seeded with `review_status: "pending"` so `list_review_queue(%{})` returns all 3 (the function applies a default `review_status: "pending"` filter that cannot be disabled by passing `%{}`)
- Prompt release workflow guarded via `Repo.one(from a in Approval, where: ... and fragment("?->>'template_id' = ?", a.arguments, ^draft_template.id), limit: 1)` to avoid creating duplicate release workflows per draft template
- `Scoria.start_run/2` returns `%Scoria.Runtime.RunSummary{}` with field `run_id` (not `id`) — updated incident seeding to use `completed_run.run_id`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Migration 20260523000300 failed with duplicate_column on existing dev databases**
- **Found during:** Task 1 (attempting to run dev_seed.exs, which requires the ai_online_score_candidates table)
- **Issue:** `alter table(:ai_scores) do add(:status, ...)` raised `ERROR 42701 duplicate_column` because a now-deleted interim migration had already applied those columns. The table `ai_online_score_candidates` was never created (migration never completed).
- **Fix:** Replaced all `add/remove` with `add_if_not_exists/remove_if_exists` in the ai_scores alter block; wrapped the reasoning/details backfill in a PL/pgSQL DO block that checks column existence; used `create_if_not_exists` for all indexes and the candidates table.
- **Files modified:** `priv/repo/migrations/20260523000300_expand_ai_scores_and_create_online_score_candidates.exs`
- **Verification:** `mix ecto.migrate` ran successfully, `ai_online_score_candidates` table created.
- **Committed in:** `4bca7c9`

**2. [Rule 1 - Bug] Scoria.start_run/2 returns RunSummary (not Run) — .id access failed**
- **Found during:** Task 1 (incidents block failed with `KeyError: key :id not found in: %RunSummary{}`)
- **Issue:** Plan assumed `Scoria.start_run/2` returns `{:ok, %Run{id: ...}}` but it actually returns `{:ok, %Scoria.Runtime.RunSummary{run_id: ...}}`. The incident seeding code called `completed_run.id` which raised a KeyError.
- **Fix:** Changed `completed_run.id` to `completed_run.run_id` in the workflow_run_id field of incident creation.
- **Files modified:** `priv/repo/dev_seed.exs`
- **Verification:** Incidents domain block now succeeds; both incidents show in `IncidentsLive`.
- **Committed in:** `4db0c73`

**3. [Rule 1 - Bug] Incident idempotency guard used wrong field for Repo.get_by**
- **Found during:** Task 1 (discovered while fixing the RunSummary issue)
- **Issue:** Used `Repo.get_by(Incident, dedupe_key: "seed-incident-...")` but `IncidentManager.open_incident/1` stores `dedupe_key = incident_key` (the computed or passed `incident_key`), not the passed `dedupe_key` attribute.
- **Fix:** Changed guard to use `incident_key:` field which is what IncidentManager actually indexes on.
- **Files modified:** `priv/repo/dev_seed.exs`
- **Verification:** Re-seeding correctly skips already-created incidents.
- **Committed in:** `4db0c73`

**4. [Rule 1 - Bug] list_review_queue(%{}) applies default review_status: "pending" filter — only 1/3 candidates returned**
- **Found during:** Task 2 (acceptance criterion check: `length(list_review_queue(%{}))` returned 1, not ≥3)
- **Issue:** `ReviewQueue.normalize_filters/1` merges incoming filters with `@default_filters = %{review_status: "pending"}`, so passing `%{}` applies the pending filter. Candidates 2 and 3 were seeded with `in_review` and `approved` review_status.
- **Fix:** Changed all 3 candidates to `review_status: "pending"`. Added repair logic for already-seeded records with wrong review_status.
- **Files modified:** `priv/repo/dev_seed.exs`
- **Verification:** `Scoria.Eval.list_review_queue(%{})` returns 3.
- **Committed in:** `4db0c73`

---

**Total deviations:** 4 auto-fixed (4 Rule 1 bugs)
**Impact on plan:** All auto-fixes necessary for correctness. The migration repair unblocked the Review Queue seed. The RunSummary fix corrected an API assumption mismatch. No scope creep.

## Issues Encountered

- `ai_online_score_candidates` table did not exist due to failed migration — resolved by repairing the migration
- Prompt release workflow guard initially used `Repo.get_by` with exact-map match on metadata (not supported in Postgres JSON), replaced with Ecto `fragment/2` query on arguments JSON field

## Known Stubs

None — all seeded entities have real data, no placeholder values.

## Threat Flags

None — seed script contains only synthetic "Acme" SupportJourney data and stable dedupe keys. No real tenant PII, no secrets, no API keys (satisfies T-11-01).

## Self-Check: PASSED

- `priv/repo/dev_seed.exs` exists: FOUND
- `priv/repo/migrations/20260523000300_expand_ai_scores_and_create_online_score_candidates.exs` modified: FOUND
- Commits exist: `4bca7c9` (migration fix) and `4db0c73` (seed file) both in `git log --oneline -5`
- `mix test --warnings-as-errors` passes: VERIFIED (exit 0)
- `mix run priv/repo/dev_seed.exs` twice: VERIFIED (both exit 0, no doubling)

## Next Phase Readiness

- All 9 dashboard screens have populated seed data — Plan 02 (harness) and Plan 03 (baseline capture) can proceed
- `priv/repo/dev_seed.exs` is idempotent and safe for repeated runs by developers
- The degraded connector and pending approval are in place for Plan 03's overlay state matrix capture

---
*Phase: 11-evaluation-engine-seed-depth*
*Completed: 2026-06-04*
