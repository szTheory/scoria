---
phase: 40-online-scoring-review-queue
plan: 01
subsystem: database
tags: [ecto, postgres, evals, online-scoring, review-queue]
requires:
  - phase: 25-ci-cd-regression-and-evaluation-framework
    provides: typed eval spec/run persistence and canonical eval dataset lineage
  - phase: 33-distributed-evaluation-fan-out
    provides: durable campaign worker execution path
provides:
  - richer `ai_scores` evidence persistence for online scoring
  - durable `ai_online_score_candidates` queue substrate with lineage and dedupe
  - fresh-database bootstrap alignment for typed eval persistence
affects: [phase-40-02, phase-40-03, evals, review-queue]
tech-stack:
  added: []
  patterns: [compatibility-normalized score persistence, durable review candidate rows, partial unique dedupe indexes]
key-files:
  created: [lib/scoria/eval/online_score_candidate.ex, priv/repo/migrations/20260523000300_expand_ai_scores_and_create_online_score_candidates.exs, .planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-01-SUMMARY.md]
  modified: [lib/scoria/eval.ex, lib/scoria/eval/campaign_enqueuer.ex, lib/scoria/eval/judge_runner.ex, lib/scoria/eval/score.ex, priv/repo/migrations/20260519000000_converge_eval_persistence.exs, test/scoria/eval/campaign_worker_test.exs]
key-decisions:
  - "Kept `reasoning` and `details` as compatibility fields while promoting `explanation`, `metadata`, and scorer provenance to the canonical score contract."
  - "Made candidate dedupe enforce one active row per tenant and sampled trace window through a partial unique index on `review_status`."
  - "Repaired the Phase 25 convergence migration instead of papering over schema drift in tests so fresh databases match the current eval code contract."
patterns-established:
  - "Score writes normalize legacy and new evidence keys before `Score.changeset/2` validation."
  - "Review candidates persist trace/workflow lineage and review defaults before any sampler or worker fan-out exists."
requirements-completed: [SCOR-01, SCOR-02]
duration: 66m
completed: 2026-05-23
---

# Phase 40 Plan 01: Online Scoring Storage Summary

**Expanded eval score evidence persistence and added a durable online review-candidate queue contract with trace/workflow lineage and active-row dedupe.**

## Performance

- **Duration:** 66 min
- **Started:** 2026-05-23T19:17:00Z
- **Completed:** 2026-05-23T20:31:00Z
- **Tasks:** 1
- **Files modified:** 8

## Accomplishments
- Expanded `ai_scores` and `Scoria.Eval.Score` so online-scoring rows now persist scorer kind/version, status, explanation, judge model, rubric version, evidence refs, and metadata without dropping compatibility fields.
- Added `Scoria.Eval.OnlineScoreCandidate` plus `ai_online_score_candidates` for durable queue truth, explicit review defaults, trace/workflow lineage, and partial-index dedupe.
- Repaired the fresh-database eval bootstrap path so current `EvalSpec`, `EvalRun`, and worker code now run cleanly from migrations instead of depending on stale local schema state.

## Task Commits

1. **Task 1: Reconcile score evidence storage and candidate durability** - `fff5281` (test), `4be7a70` (feat)

## Files Created/Modified
- `lib/scoria/eval/score.ex` - expands the score schema and normalizes legacy/new evidence attrs.
- `lib/scoria/eval/online_score_candidate.ex` - defines the durable review-candidate schema and dedupe constraint.
- `lib/scoria/eval.ex` - normalizes richer score attrs before persistence.
- `priv/repo/migrations/20260523000300_expand_ai_scores_and_create_online_score_candidates.exs` - adds new score columns and creates the candidate table/indexes.
- `test/scoria/eval/campaign_worker_test.exs` - covers richer score evidence persistence and candidate durability through the owned worker smoke lane.
- `lib/scoria/eval/campaign_enqueuer.ex` - fixes string-keyed spec subject access during campaign eval-run creation.
- `lib/scoria/eval/judge_runner.ex` - fixes string-keyed scorer/threshold access in the judge path.
- `priv/repo/migrations/20260519000000_converge_eval_persistence.exs` - restores the typed eval spec/run contract on fresh database bootstrap.

## Decisions Made
- Preserved the legacy `reasoning`/`details` columns as compatibility mirrors instead of renaming them away in this slice, because later plans only need additive evidence fields and current callers already exist.
- Stored candidate review state as `status` plus `review_status` so queue lifecycle and operator triage state can diverge cleanly in later slices.
- Fixed the migration history rather than loosening the tests, because Phase 40 depends on durable schema truth and later plans would inherit the same bootstrap failure.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Fresh database bootstrap was missing the typed eval spec/run contract**
- **Found during:** Task 1 verification
- **Issue:** `ai_eval_specs` and `ai_eval_runs` from the clean migration path did not match the current code’s typed Phase 25 contract, which blocked `campaign_worker_test.exs` before the new Phase 40 persistence could run.
- **Fix:** Extended `priv/repo/migrations/20260519000000_converge_eval_persistence.exs` to add the typed spec columns, expanded run header fields, and relax the legacy `rubric` requirement for fresh databases.
- **Files modified:** `priv/repo/migrations/20260519000000_converge_eval_persistence.exs`
- **Verification:** `MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate && mix test test/scoria/eval/campaign_worker_test.exs`
- **Committed in:** `4be7a70`

**2. [Rule 3 - Blocking issue] Worker eval helpers assumed atom-keyed spec payloads after Ecto reload**
- **Found during:** Task 1 verification
- **Issue:** `create_eval_run/1`, `CampaignEnqueuer`, and `JudgeRunner` read `subject`, `scorers`, and `threshold_policy` with atom-key access after those embeds were reloaded as string-keyed maps.
- **Fix:** Normalized those accesses through existing fetch helpers in `lib/scoria/eval.ex`, `lib/scoria/eval/campaign_enqueuer.ex`, and `lib/scoria/eval/judge_runner.ex`.
- **Files modified:** `lib/scoria/eval.ex`, `lib/scoria/eval/campaign_enqueuer.ex`, `lib/scoria/eval/judge_runner.ex`
- **Verification:** `mix test test/scoria/eval/campaign_worker_test.exs`
- **Committed in:** `4be7a70`

---

**Total deviations:** 2 auto-fixed (2 Rule 3)
**Impact on plan:** All deviations were required for correctness and verification. No architecture change and no scope expansion beyond the owned eval persistence path.

## Issues Encountered

- The local `MIX_ENV=test` database had to be reset during verification because prior migration attempts left it in a stale state while the repo’s migration history was being repaired.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase `40-02` can now build the sampler/enqueue flow against a durable candidate table with explicit lineage and dedupe semantics.
- Phase `40-03` can append deterministic and judge-backed score evidence onto the richer `ai_scores` contract without another schema migration.

## Self-Check: PASSED

- Verified summary file exists at `.planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-01-SUMMARY.md`.
- Verified commit `fff5281` exists in git history.
- Verified commit `4be7a70` exists in git history.

---
*Phase: 40-online-scoring-review-queue*
*Completed: 2026-05-23*
