---
phase: 46-operator-evidence-and-verification
plan: 01
subsystem: runtime
tags: [semantic-cache, operator-evidence, runtime, dto]
requires:
  - phase: 45-compatibility-and-invalidation-engine
    provides: semantic cache compatibility and invalidation truth
provides:
  - Shared semantic evidence DTO on runtime detail
  - Curated provenance, lifecycle, and candidate-refusal projection
affects: [runtime, operator-surfaces, workflow-ui]
requirements-completed: [EVID-01]
completed: 2026-05-25
one_liner: Added the shared semantic evidence DTO so runtime detail carries semantic provenance and fallback truth directly.
---

# Plan 46-01 Summary

## Outcome

Extended the canonical runtime detail DTO with a shared semantic evidence contract assembled from runtime metadata, semantic cache entries, and append-only entry events.

## Changes

- added `semantic_evidence` to `Scoria.Runtime.RunDetail` enforce keys, struct, and type
- updated `Scoria.Runtime.get_run_detail!/1` to pass a curated semantic evidence payload into `RunDetail.from_run_tree/2`
- assembled summary, candidate, compatibility, provenance, lifecycle, events, and raw metadata groups from runtime semantic metadata plus durable semantic entry/event truth
- expanded `test/scoria/runtime/semantic_fast_path_test.exs` to assert hit, bypass, admitted-miss, and rejected-candidate projection on the runtime detail DTO

## Verification

- `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs --trace`
