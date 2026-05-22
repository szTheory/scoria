---
status: complete
mode: shift-left
phase: 19-remote-connector-boundary-and-auth-discovery
source:
  - 19-01-PLAN.md
  - 19-02-PLAN.md
  - 19-03-PLAN.md
started: 2026-05-17T00:00:00Z
updated: 2026-05-22T09:28:30Z
human_steps_required: 0
automation_deferred: []
---

## Current Test

[testing complete]

## Automation Map

- Test 1 uses the `19-01-*` validation rows to prove the durable nouns, encrypted grant secrets, and explicit job infrastructure exist before any connector service logic runs.
- Test 2 uses the `19-02-*` validation rows to prove the thin Scoria-owned boundary persists connector truth transactionally and moves discovery/capability refresh off the request path.
- Test 3 uses the `19-03-*` validation rows to prove Scoria-owned auth start/callback routes, OAuth+PKCE grant completion, post-auth refresh triggers, and preserved deferrals to Phases 20-22.

## Tests

### 1. Durable connector/grant/capability truth is explicit and encrypted where required
expected: Connector registration truth, grant truth, and current capability snapshot truth should each live in separate Ecto-backed rows, with encrypted-at-rest secret fields and operator-visible non-secret metadata for scope, expiry, and refresh state.
result: pass
evidence:
  - `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-VALIDATION.md` rows `19-01-01` through `19-01-03`
  - `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-VERIFICATION.md`
  - `lib/scoria/connectors/connector.ex`
  - `lib/scoria/connectors/grant.ex`
  - `lib/scoria/connectors/capability_snapshot.ex`
  - `lib/scoria/vault.ex`
  - `test/scoria/connectors/schema_test.exs`

### 2. Connector registration and discovery stay behind the Scoria-owned boundary
expected: A host app should register and sync remote connectors through `Scoria.Connectors`, with params normalization at the edge, transactional service writes, and explicit durable discovery/capability refresh jobs that do not leak transport concerns into ordinary request or UI code.
result: pass
evidence:
  - `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-VALIDATION.md` rows `19-02-01` through `19-02-03`
  - `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-VERIFICATION.md`
  - `lib/scoria/connectors.ex`
  - `lib/scoria/connectors/params.ex`
  - `lib/scoria/connectors/discovery.ex`
  - `lib/scoria/connectors/discovery_job.ex`
  - `test/scoria/connectors_test.exs`
  - `test/scoria/connectors/discovery_job_test.exs`

### 3. Auth flow completes through Scoria routes with durable grant truth and explicit post-auth refresh
expected: The primary browser-redirect OAuth+PKCE flow should start and complete through Scoria-owned Phoenix routes, persist encrypted grant secrets with visible expiry/scope metadata, trigger post-auth capability refresh explicitly, redact auth evidence, and still leave stable local tool identity, dual-plane policy, approvals UX, and full operator evidence UX deferred to Phases 20-22.
result: pass
evidence:
  - `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-VALIDATION.md` rows `19-03-01` through `19-03-03`
  - `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-VERIFICATION.md`
  - `lib/scoria_web/router.ex`
  - `lib/scoria_web/controllers/connector_auth_controller.ex`
  - `lib/scoria/connectors/auth.ex`
  - `lib/scoria/connectors/grant_refresh.ex`
  - `test/scoria/connectors/auth_test.exs`
  - `test/scoria/connectors/integration_test.exs`
  - `test/scoria_web/router_test.exs`

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

- Focused proof lane completed on 2026-05-22:
  - `MIX_ENV=test mix test test/scoria/connectors/schema_test.exs test/scoria/connectors_test.exs test/scoria/connectors/auth_test.exs test/scoria/connectors/discovery_job_test.exs test/scoria/connectors/integration_test.exs test/scoria_web/router_test.exs`
  - Result: `27 tests, 0 failures`
- Phase 20-22 concerns remain intentionally deferred and should not be scored as Phase 19 gaps:
  - stable local tool identity
  - dual-plane policy enforcement
  - approvals UX
  - full operator evidence UX
