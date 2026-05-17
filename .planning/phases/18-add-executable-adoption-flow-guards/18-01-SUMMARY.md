---
phase: 18
plan: 01
subsystem: readme-and-public-surface-guards
completed: 2026-05-17
---

# Phase 18 Plan 01 Summary

**The README/public facade hardening pass now has executable pure-surface guards without turning the full adoption narrative into the spec.**

## Accomplishments
- Added pure doctest examples to `Scoria` and `Scoria.Identity` so canonical identity and facade argument shapes compile under ExUnit.
- Added [`test/scoria/identity_doctest_test.exs`](/Users/jon/projects/scoria/test/scoria/identity_doctest_test.exs) and tightened [`test/scoria/adoption_surface_test.exs`](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs) to assert both semantic anchors and the existence of the executable snippet sources.
- Kept stateful adoption proof in runtime/integration seams instead of README-wide doctests or prose snapshots.
