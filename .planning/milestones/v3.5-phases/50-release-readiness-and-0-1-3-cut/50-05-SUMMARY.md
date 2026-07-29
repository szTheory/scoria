---
phase: 50-release-readiness-and-0-1-3-cut
plan: 05
subsystem: testing
tags: [phoenix, liveview, dashboard-scope, ci-gap-closure, rel-04]

requires:
  - phase: 46-49
    provides: ScoriaWeb.DashboardScope, dashboard LiveViews (OrchestratorLive, ComingSoonLive), and their test suites (introduced before the LiveView 1.1.30 bump in the v3.5 milestone)
provides:
  - DashboardScope.on_mount/4 no longer bare-halts on missing/unauthorized scope; it redirects (still fails closed) so LiveView 1.1.30's raise_halt_without_redirect! guard does not fire
  - Fixed trusted-scope session seeding in the three Bucket-G-affected test files, matching the working dataset_live/index_test.exs pattern
  - Fixed two silently-too-short (<64 byte) Endpoint secret_key_base values in coming_soon_live_test.exs and orchestrator_live_sre_test.exs
affects: [50-06, 50-07, 50-08, 50-09, 50-10, 50-11, ci-verify-lane]

tech-stack:
  added: []
  patterns:
    - "DashboardScope on_mount fail-closed branches must redirect, never bare-halt, under LiveView 1.1.30+"
    - "Dashboard LiveView tests asserting a render must seed a trusted tenant scope in test_conn/0 (tenant_id + actor_id), mirroring dataset_live/index_test.exs"

key-files:
  created: []
  modified:
    - lib/scoria_web/dashboard_scope.ex
    - test/scoria_web/single_header_rendered_guard_test.exs
    - test/scoria_web/live/coming_soon_live_test.exs
    - test/scoria_web/live/orchestrator_live_sre_test.exs

key-decisions:
  - "Redirect target for the missing/unauthorized-scope fail-closed branch is root '/' (a generic, non-dashboard host-owned target) rather than any Scoria-internal route, matching the host-owns-auth boundary (D-18)."
  - "Kept the unavailable flash message on the redirect (put_unavailable_flash then redirect), preserving the existing dashboard_scope_test.exs assertions on socket.assigns.flash[\"error\"] which are checked via direct on_mount/4 calls (not through a real LiveView mount, so they were unaffected by the 1.1.30 raise in the first place)."

patterns-established: []

requirements-completed: [REL-04]

coverage:
  - id: D1
    description: "DashboardScope.on_mount/4 fails closed via redirect (not a bare halt) on :missing_scope/:unauthorized, satisfying LiveView 1.1.30's raise_halt_without_redirect! guard while still refusing to render without a trusted tenant scope"
    requirement: "REL-04"
    verification:
      - kind: unit
        ref: "test/scoria_web/dashboard_scope_test.exs (unaffected assertions re-verified: on_mount/4 describe block)"
        status: pass
      - kind: integration
        ref: "test/scoria_web/single_header_rendered_guard_test.exs (all 9 route cases)"
        status: pass
    human_judgment: false
  - id: D2
    description: "single_header_rendered_guard_test.exs, coming_soon_live_test.exs, and orchestrator_live_sre_test.exs all exit 0 (14 previously-failing Bucket-G cases green)"
    requirement: "REL-04"
    verification:
      - kind: integration
        ref: "mix test test/scoria_web/single_header_rendered_guard_test.exs test/scoria_web/live/coming_soon_live_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-11
status: complete
---

# Phase 50 Plan 05: DashboardScope bare-halt regression (Bucket G) Summary

**DashboardScope.on_mount/4 now redirects instead of bare-halting on missing/unauthorized scope, closing all 14 LiveView 1.1.30 `raise_halt_without_redirect!` failures.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-11T13:47:58Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments
- Fixed the latent fail-closed regression in `lib/scoria_web/dashboard_scope.ex`: the `{:error, :unauthorized | :missing_scope}` branch of `on_mount/4` now calls `put_unavailable_flash(socket) |> redirect(to: "/")` instead of returning a bare `{:halt, socket}`, which Phoenix LiveView 1.1.30 hard-rejects via `raise_halt_without_redirect!/1`. The contract "fails closed when no trusted tenant scope is asserted" (moduledoc, D-18) is preserved — redirecting away from the dashboard is still failing closed.
- Seeded a trusted tenant scope (`tenant_id` + `actor_id`) in the `test_conn/0` builders of the three affected test files (`single_header_rendered_guard_test.exs`, `coming_soon_live_test.exs`) and the two inline conn builders in `orchestrator_live_sre_test.exs`, mirroring the already-working `dataset_live/index_test.exs` pattern. This lets the dashboard render assertions actually exercise a resolved scope instead of hitting the missing-scope fail-closed path.
- Uncovered and fixed a second, previously-masked bug: `coming_soon_live_test.exs` (62-byte key) and `orchestrator_live_sre_test.exs` (63-byte key) had Endpoint `secret_key_base` values below Plug's 64-byte minimum for cookie session signing. Before this fix, the dashboard_scope bare-halt crash always fired first, so this defect never got exercised; once mount stopped short-circuiting, the cookie-session `ArgumentError` surfaced on every request. Extended both keys well past 64 bytes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix the DashboardScope bare-halt regression and supply scope in the affected test conns** - `69e660a9` (fix)

**Plan metadata:** (this commit)

## Files Created/Modified
- `lib/scoria_web/dashboard_scope.ex` - `on_mount/4` missing/unauthorized branch now redirects (fails closed via redirect, not bare halt)
- `test/scoria_web/single_header_rendered_guard_test.exs` - `test_conn/0` seeds trusted tenant scope
- `test/scoria_web/live/coming_soon_live_test.exs` - `test_conn/0` seeds trusted tenant scope; Endpoint `secret_key_base` extended to >64 bytes
- `test/scoria_web/live/orchestrator_live_sre_test.exs` - both inline conn builders seed trusted tenant scope; Endpoint `secret_key_base` extended to >64 bytes

## Decisions Made
- Redirect target for the fail-closed branch is root `"/"` — a generic, non-dashboard, host-owned target — consistent with the host-owns-auth boundary (D-18) and mirroring the existing `{:redirect, to}` branch's shape.
- Preserved the unavailable flash message on the redirect path so `dashboard_scope_test.exs`'s direct `on_mount/4` assertions (which call the function directly, not through a real LiveView mount, and were therefore never affected by the LiveView 1.1.30 raise) continue to pass unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Extended too-short Endpoint secret_key_base in coming_soon_live_test.exs and orchestrator_live_sre_test.exs**
- **Found during:** Task 1 verification — after fixing the bare-halt regression and seeding scope, both files still failed with `(ArgumentError) cookie store expects conn.secret_key_base to be at least 64 bytes`, raised from `Plug.Session.COOKIE.derive/3` during response send.
- **Issue:** `coming_soon_live_test.exs`'s Endpoint used a 62-byte `secret_key_base`; `orchestrator_live_sre_test.exs`'s used 63 bytes. Both are below Plug's cookie-store minimum. This defect was previously invisible because the dashboard_scope bare-halt crash always fired first (before any response was sent), fully masking it. Diagnosed by temporarily defining a local `ScoriaWeb.ErrorView` stub to unmask the underlying exception (Phoenix's `render_errors` was itself failing to find `ScoriaWeb.ErrorView` when these 3 files are run in isolation, since that bare module is only defined in `review_queue_live_test.exs` elsewhere in the suite — a red herring; the real defect was the short key). The temporary stub was reverted after diagnosis; it is not part of the shipped fix.
- **Fix:** Extended both `secret_key_base` values well past 64 bytes by appending descriptive suffixes (`ComingSoonExtraKeyMaterial0123456789`, `OrchestratorSreExtraKeyMaterial0123456789`), matching the style already used by `single_header_rendered_guard_test.exs`'s key (93 bytes) and `dashboard_auth_approvals_test.exs`'s key.
- **Files modified:** `test/scoria_web/live/coming_soon_live_test.exs`, `test/scoria_web/live/orchestrator_live_sre_test.exs`
- **Verification:** `mix test` on all three named files: 14 tests, 0 failures.
- **Committed in:** `69e660a9` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — blocking bug uncovered only after the primary fix was applied)
**Impact on plan:** Necessary for the plan's own acceptance bar (the three named test files exiting 0); no scope creep — both edits are within the plan's declared `files_modified` list.

## Issues Encountered
- Diagnosing the second (secret_key_base) bug required distinguishing it from a red-herring "no ErrorView module" failure that only appears when running these 3 test files in isolation (rather than as part of the full suite, where a bare `ScoriaWeb.ErrorView` defined in an unrelated test file happens to be loaded). Confirmed via a temporary local ErrorView stub, then reverted once the real exception (`secret_key_base` too short) was visible.
- Verified via full-suite `mix test` run (1127 tests, 3 doctests) that the 17 remaining failures are all pre-existing and belong to Buckets A–F per `50-CI-GAP-INVENTORY.md` (docs-source alignment, package/publish surface, UI component contracts, dev-lab boundary guard, support-copilot gallery, warning inventory) — none touch DashboardScope, the three named test files, or anything modified by this plan. Those are tracked by plans 50-06 through 50-11.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Bucket G (14 identical `raise_halt_without_redirect!` failures) is fully closed; REL-04's DashboardScope regression is resolved.
- Buckets A–F remain open and are scoped to plans 50-06 through 50-11 per the CI gap inventory; no additional work from those buckets was pulled into this plan.

## Self-Check: PASSED
- FOUND: lib/scoria_web/dashboard_scope.ex
- FOUND: test/scoria_web/single_header_rendered_guard_test.exs
- FOUND: test/scoria_web/live/coming_soon_live_test.exs
- FOUND: test/scoria_web/live/orchestrator_live_sre_test.exs
- FOUND commit: 69e660a9
