---
phase: 18
plan: 03
subsystem: adoption-acceptance-harness
completed: 2026-05-17
---

# Phase 18 Plan 03 Summary

**Scoria now exposes one named adoption acceptance lane while keeping the same guards first-class under the default `mix test` suite.**

## Accomplishments
- Added [`mix test.adoption`](/Users/jon/projects/scoria/lib/mix/tasks/test.adoption.ex) with a test-backed bounded file list in [`test/mix/tasks/test.adoption_test.exs`](/Users/jon/projects/scoria/test/mix/tasks/test.adoption_test.exs).
- Switched [`.github/workflows/ci.yml`](/Users/jon/projects/scoria/.github/workflows/ci.yml) to the named lane and aligned [`docs/operator_verification.md`](/Users/jon/projects/scoria/docs/operator_verification.md) plus [`lib/mix/tasks/scoria.install.ex`](/Users/jon/projects/scoria/lib/mix/tasks/scoria.install.ex) to the same maintainer/operator story.
- Kept the knowledge lane explicitly optional and separate from the default adoption proof.
