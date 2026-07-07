---
phase: 44
slug: dashboard-auth-seam
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-07
---

# Phase 44 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix LiveView test helpers. |
| **Config file** | `mix.exs`, `config/test.exs`, and `test/support/**/*.ex`. |
| **Quick run command** | `mix test test/scoria_web/router_test.exs test/scoria_web/dashboard_scope_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~10-90 seconds depending on whether the full suite or only targeted dashboard tests run. |

Baseline checked during research: `mix test test/scoria_web/router_test.exs --warnings-as-errors` returned 5 tests, 0 failures.

---

## Sampling Rate

- **After every task commit:** Run the quick command once `test/scoria_web/dashboard_scope_test.exs` exists, plus any existing test file touched by the task.
- **After every plan wave:** Run `mix test test/scoria_web/live --warnings-as-errors` and every targeted dashboard auth test introduced by the wave.
- **Before `/gsd:verify-work`:** Run `mix test --warnings-as-errors`; the source guard must also be green.
- **Max feedback latency:** 90 seconds for targeted checks; use the full suite at wave boundaries and closeout.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-W0-01 | TBD | 0 | AUTH-01 | T-44-02 | Bare `scoria_dashboard "/scoria"` compiles, host `on_mount` single/list hooks compile, host hooks run before `DashboardScope`, and `DashboardNav` remains in the chain. | router/unit | `mix test test/scoria_web/router_test.exs --warnings-as-errors` | Yes - new cases required | pending |
| 44-W0-02 | TBD | 0 | AUTH-02 | T-44-01 / T-44-03 | Dashboard scope resolver accepts valid host-asserted scope, rejects nil/blank/malformed scope, and never reads params or defaults. | unit | `mix test test/scoria_web/dashboard_scope_test.exs --warnings-as-errors` | No - Wave 0 | pending |
| 44-W0-03 | TBD | 0 | AUTH-03 | T-44-01 / T-44-04 | Mounting as tenant A with `?tenant=tenant-b` renders only tenant A data or an empty/not-found state, including object detail pages. | LiveView integration | `mix test test/scoria_web/live --warnings-as-errors` | Partial - new cases required | pending |
| 44-W0-04 | TBD | 0 | AUTH-03 | T-44-03 | Dashboard code forbids `params["tenant"]`, `session["tenant_id"] || "default"`, and suspicious `|| "default"` tenant fallbacks. | source guard | `mix test test/scoria_web/dashboard_scope_source_guard_test.exs --warnings-as-errors` | No - Wave 0 | pending |

*Status values: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `test/scoria_web/dashboard_scope_test.exs` - resolver and on-mount gate behavior for AUTH-02.
- [ ] `test/scoria_web/dashboard_scope_source_guard_test.exs` - static regression guard for AUTH-03 tenant spoof/default fallback paths.
- [ ] Additional cases in `test/scoria_web/router_test.exs` - hook pass-through and hook order for AUTH-01.
- [ ] Cross-tenant LiveView fixtures/tests for dashboard pages that read tenant-owned rows.
- [ ] Tenant-qualified object/detail route cases where the object ID exists only for another tenant.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Public documentation makes authz delegation clear without promising in-lib RBAC. | AUTH-02 | Copy and product-positioning intent need human review; source checks can only confirm strings/paths. | Review docs for the statement that the host authenticates and authorizes operators, Scoria consumes host-asserted dashboard scope, and query params do not choose tenants. |

All tenant source, fail-closed resolver, hook ordering, cross-tenant spoof, PubSub tenant, and object detail isolation behaviors must have automated verification.

---

## Threat References

| Threat Ref | Threat | Required Proof |
|------------|--------|----------------|
| T-44-01 | Query-param tenant spoofing / IDOR. | LiveView tests mount with tenant A session and `?tenant=tenant-b`; rendered data and PubSub topics use tenant A only. |
| T-44-02 | Host auth hook omitted or ordered after Scoria hooks. | Router tests prove host hooks are prepended and `DashboardNav` remains appended by Scoria. |
| T-44-03 | Missing tenant silently falls back to global/default data. | Resolver unit tests fail closed for nil/blank tenant and source guard rejects default fallbacks. |
| T-44-04 | Detail route reads by object ID without tenant qualification. | Integration tests prove B-only object IDs are not visible from tenant A scope. |

---

## Validation Sign-Off

- [ ] All tasks have automated verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing test references.
- [ ] No watch-mode flags.
- [ ] Feedback latency stays under 90 seconds for targeted checks.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 tests exist and pass.

**Approval:** pending
