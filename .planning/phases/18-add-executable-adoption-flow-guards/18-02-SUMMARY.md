---
phase: 18
plan: 02
subsystem: phoenix-example-source-guard
completed: 2026-05-17
---

# Phase 18 Plan 02 Summary

**The canonical Phoenix adoption guide is now tied to checked example truth instead of drifting as prose-only documentation.**

## Accomplishments
- Added [`test/support/scoria/adoption_example.ex`](/Users/jon/projects/scoria/test/support/scoria/adoption_example.ex) as the shared source for the controller identity, readback, resume, same-session, and operator-route contract.
- Reused that shared source in [`test/scoria/runtime_integration_test.exs`](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs) and added [`test/scoria/phoenix_example_source_test.exs`](/Users/jon/projects/scoria/test/scoria/phoenix_example_source_test.exs) so the guide stays aligned with checked runtime truth.
- Preserved the docs-first Phoenix narrative while making its stable code shapes executable at the right seam.
