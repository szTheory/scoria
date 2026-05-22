---
phase: 19
slug: remote-connector-boundary-and-auth-discovery
status: validated
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-17
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for remote connector boundary, auth discovery, durable grant storage, and explicit background refresh work.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` + `Phoenix.ConnTest` + `Phoenix.LiveViewTest` where needed + Oban worker tests + schema/service integration assertions |
| **Config file** | `config/test.exs` |
| **Quick run command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/schema_test.exs test/scoria/connectors_test.exs test/scoria/connectors/auth_test.exs test/scoria/connectors/discovery_job_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |
| **Estimated runtime** | ~30 seconds for focused task lanes; ~90 seconds for the full-suite regression lane |

---

## Sampling Rate

- **After every task commit:** run the task-local smoke lane mapped below.
  - `19-01` Task 1 smoke: `mix deps.get && SCORIA_DB_PORT=55432 MIX_ENV=test mix ecto.migrate`
  - `19-01` Task 2/3 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/schema_test.exs`
  - `19-02` Task 1/2 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors_test.exs`
  - `19-02` Task 3 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/discovery_job_test.exs`
  - `19-03` Task 1/2 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/auth_test.exs test/scoria_web/router_test.exs`
  - `19-03` Task 3 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/integration_test.exs test/scoria/connectors/discovery_job_test.exs`
- **After Wave 1:** rerun schema/dependency lane plus connector schema tests.
- **After Wave 2:** run the quick run command.
- **After Wave 3:** run auth + integration lanes, then `SCORIA_DB_PORT=55432 MIX_ENV=test mix test`.
- **Before `$gsd-verify-work`:** full suite must be green.
- **Max feedback latency:** 30 seconds for task-local lanes; 90 seconds for full closeout.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | `CONN-01`, `AUTH-02` | `T-19-01-02`, `T-19-01-03`, `T-19-01-05` | Durable job and encryption posture is explicit, app-owned, and free of hidden polling/custom crypto | config + migration | `mix deps.get && SCORIA_DB_PORT=55432 MIX_ENV=test mix ecto.migrate` | planned | ⬜ pending |
| 19-01-02 | 01 | 1 | `CONN-01`, `AUTH-02` | `T-19-01-01`, `T-19-01-02`, `T-19-01-04` | Connector, grant, and capability rows use column-first Ecto truth with isolated encrypted secret fields | schema | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/schema_test.exs` | planned | ⬜ pending |
| 19-01-03 | 01 | 1 | `AUTH-02` | `T-19-01-02`, `T-19-01-04` | Schema tests prove encryption, optimistic locking, and operator-visible non-secret metadata | schema | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/schema_test.exs` | planned | ⬜ pending |
| 19-02-01 | 02 | 2 | `CONN-01`, `CONN-02` | `T-19-02-01`, `T-19-02-04` | Thin public boundary and params seam keep transport concerns out of ordinary request/UI code | service | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors_test.exs` | planned | ⬜ pending |
| 19-02-02 | 02 | 2 | `CONN-01` | `T-19-02-02`, `T-19-02-03` | Registration persists durable connector truth transactionally and only then triggers explicit discovery work | service + audit | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors_test.exs test/scoria/sre/audit_outbox_test.exs` | planned | ⬜ pending |
| 19-02-03 | 02 | 2 | `CONN-02` | `T-19-02-03`, `T-19-02-05` | Discovery/capability refresh runs as durable deduped jobs with refresh/error state recording and no polling | job | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/discovery_job_test.exs` | planned | ⬜ pending |
| 19-03-01 | 03 | 3 | `AUTH-01`, `CONN-02` | `T-19-03-01`, `T-19-03-04` | Auth routes stay Scoria-owned, session-backed transient state stays ephemeral, and host apps do not hand-roll protocol plumbing | router + auth | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_web/router_test.exs test/scoria/connectors/auth_test.exs` | planned | ⬜ pending |
| 19-03-02 | 03 | 3 | `AUTH-01`, `AUTH-02` | `T-19-03-02`, `T-19-03-03`, `T-19-03-04` | OAuth+PKCE completion persists encrypted secrets, visible expiry/scope metadata, and redacted audit evidence | auth + audit | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/auth_test.exs test/scoria/sre/audit_outbox_test.exs` | planned | ⬜ pending |
| 19-03-03 | 03 | 3 | `CONN-02`, `AUTH-01`, `AUTH-02` | `T-19-03-05`, `T-19-03-06` | Integration proof covers auth flow, background refresh, and explicit absence of Phase 20-22 features | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/integration_test.exs test/scoria/connectors/discovery_job_test.exs test/scoria_web/router_test.exs` | planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave Coverage

| Wave | Plans | Coverage Goal | Automated Proof |
|------|-------|---------------|-----------------|
| 1 | `19-01` | Establish durable dependency, encryption, and schema truth before service logic depends on it | `mix deps.get && SCORIA_DB_PORT=55432 MIX_ENV=test mix ecto.migrate && SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/schema_test.exs` |
| 2 | `19-02` | Land the thin boundary, transactional registration, and explicit discovery jobs without request/UI leakage | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors_test.exs test/scoria/connectors/discovery_job_test.exs` |
| 3 | `19-03` | Close auth flow, post-auth refresh, and integration containment while preserving deferrals | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/auth_test.exs test/scoria/connectors/integration_test.exs test/scoria_web/router_test.exs && SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |

---

## Wave 0 Requirements

- [ ] Add `Oban` because the current supervised-task posture is not durable or inspectable enough for explicit connector discovery/auth refresh work.
- [ ] Add `CloakEcto` because the repo currently has no encrypted-at-rest primitive for connector grant secrets.
- [x] Preserve the existing Scoria-owned Phoenix boundary posture by mounting auth routes through Scoria routing rather than host-app controller code.
- [x] Preserve explicit deferrals to Phase 20-22 for stable local tool identity, dual-plane policy enforcement, approvals UX, and full operator evidence UX.

---

## Source Coverage Audit

| Source Type | Item | Covered By |
|-------------|------|------------|
| GOAL | Durable connector records and boring discovery defaults | `19-01`, `19-02` |
| GOAL | Auth/grant storage that fits a normal Phoenix app | `19-01`, `19-03` |
| REQ | `CONN-01` | `19-01`, `19-02` |
| REQ | `CONN-02` | `19-02`, `19-03` |
| REQ | `AUTH-01` | `19-03` |
| REQ | `AUTH-02` | `19-01`, `19-03` |
| RESEARCH | Separate connector/grant/capability nouns | `19-01` |
| RESEARCH | Registration persists truth first, then enqueues explicit discovery work | `19-02` |
| RESEARCH | OAuth+PKCE primary path, explicit callback boundary, encrypted secrets | `19-03` |
| RESEARCH | Verification lanes for schema/service, auth flow, background work, integration alignment | this file, `19-UAT.md`, `19-VERIFICATION.md` |
| CONTEXT | D-01 to D-08 connector/grant noun posture | `19-01`, `19-02` |
| CONTEXT | D-09 to D-13 explicit trigger-driven discovery and refresh | `19-02`, `19-03` |
| CONTEXT | D-14 to D-18 auth posture and host-app ownership split | `19-03` |
| CONTEXT | D-19 to D-22 encrypted durable grant model | `19-01`, `19-03` |
| CONTEXT | D-23 to D-25 boring Phoenix DX and no hosted magic | `19-02`, `19-03` |

No deferred idea from `19-CONTEXT.md` is planned in this phase.

---

## Validation Sign-Off

- [x] All tasks have automated verification commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Verification lanes cover schema/service, auth flow, background work, and integration alignment
- [x] No watch-mode flags
- [x] Feedback latency target remains under 90 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated for planning on 2026-05-17. Phase 19 execution should proceed only through the three plans above, with explicit Oban/encryption decisions, trigger-driven refresh work, Scoria-owned auth routing, and preserved deferrals to Phases 20-22.
