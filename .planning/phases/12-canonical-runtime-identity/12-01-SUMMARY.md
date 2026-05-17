---
phase: 12
plan: 01
subsystem: canonical-identity
tags: [identity, workflows, mcp]
completed: 2026-05-13
---

# Phase 12 Plan 01 Summary

**Scoria now has a single canonical runtime identity envelope, and workflow runs persist root actor, tenant, and session identity as first-class truth instead of ad hoc metadata.**

## Accomplishments
- Added `Scoria.Identity` as the shared `%Scoria.Identity{}` contract with normalization helpers for plain attrs, Plug assigns, session maps, and mount-derived identity.
- Updated the public `Scoria` entrypoint and MCP router seam to normalize caller identity through the shared contract before runtime execution.
- Added `actor_id` and `tenant_id` columns to `ai_workflow_runs`, updated run persistence, and snapshot canonical identity into initial workflow checkpoint and event metadata.
- Added focused regression coverage for identity normalization and workflow-run persistence.

## Verification
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/identity_test.exs`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs`

