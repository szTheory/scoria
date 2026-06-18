---
phase: 33-doc-restructure-verification-copy-correction
plan: 02
subsystem: docs
tags: [docs, uat, screenshots, support-copilot, dev-dx]

# Dependency graph
requires:
  - phase: 29-makefile-hardening
    provides: "Native make dev URL on localhost:4799"
  - phase: 33-doc-restructure-verification-copy-correction
    provides: "Docker DX reference wording for Docker and native local development"
provides:
  - "Active maintainer and UAT docs corrected to make dev and localhost:4799/scoria"
  - "Support-copilot gallery docs qualified as a separate examples/support_copilot app on port 4010"
  - "Plaintext Anthropic key example removed from maintainer screenshot critique setup"
affects: [phase-33, docs-drift, support-copilot-gallery]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scoria repo dashboard docs use make dev / localhost:4799 for host harnesses"
    - "Gallery app docs keep localhost:4010 only when explicitly scoped to examples/support_copilot"

key-files:
  created:
    - .planning/phases/33-doc-restructure-verification-copy-correction/33-02-SUMMARY.md
  modified:
    - docs/MAINTAINERS.md
    - docs/uat_automation.md
    - README.md
    - docs/operator_verification.md
    - docs/support_copilot_gallery.md

key-decisions:
  - "Kept support-copilot gallery startup as mix phx.server because it is a separate example Phoenix app."
  - "Moved maintainer critique guidance to process-scoped op run wording instead of a plaintext key example."

patterns-established:
  - "Port 4010 docs must say gallery app or gallery-local operator surface."
  - "Scoria host harness docs should include the explicit localhost:4799/scoria URL."

requirements-completed: [DOCS-01]

# Metrics
duration: 12min
completed: 2026-06-18
status: complete
---

# Phase 33 Plan 02: Active Docs Dev-Start Correction Summary

**Maintainer, UAT, README, operator, and gallery docs now separate Scoria native 4799 startup from the support-copilot gallery app on 4010**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-06-18T17:11:00Z
- **Completed:** 2026-06-18T17:23:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Updated maintainer screenshot workflow to start the Scoria dashboard with `make dev` and capture with `mix scoria.ui.shots --url http://localhost:4799/scoria`.
- Updated browser UAT local-run guidance to use `make dev` and `mix scoria.ui.e2e --base-url http://localhost:4799/scoria`.
- Qualified README, operator verification, and gallery docs so `mix phx.server` / `localhost:4010` are explicitly the separate `examples/support_copilot` gallery app.
- Replaced maintainer plaintext Anthropic key setup with process-scoped `op run --env-file` critique guidance.

## Task Commits

Each task was committed atomically:

1. **Task 1: Correct maintainer screenshot and UAT local-run docs** - `78639c1` (docs)
2. **Task 2: Qualify support-copilot gallery docs without changing its app command** - `370acda` (docs)

**Plan metadata:** committed separately with this SUMMARY.

## Files Created/Modified

- `docs/MAINTAINERS.md` - Native screenshot and critique copy now uses `make dev` / `localhost:4799`.
- `docs/uat_automation.md` - Real-browser UAT local-run instructions now use `make dev` / `localhost:4799`.
- `README.md` - Gallery quickstart now says it starts the separate `examples/support_copilot` app and lists 4010 URLs.
- `docs/operator_verification.md` - Advisory gallery section now qualifies 4010 as gallery-local.
- `docs/support_copilot_gallery.md` - Gallery app quickstart now names host chat and gallery-local operator URLs.
- `.planning/phases/33-doc-restructure-verification-copy-correction/33-02-SUMMARY.md` - This completion record.

## Decisions Made

- Preserved `mix phx.server` for support-copilot gallery startup because `examples/support_copilot` is a separate Phoenix app configured on port 4010.
- Removed the maintainer guide's plaintext `ANTHROPIC_API_KEY` shell example because Phase 32 established process-scoped 1Password secret references.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Replaced plaintext critique key setup in maintainer docs**
- **Found during:** Task 1 (Correct maintainer screenshot and UAT local-run docs)
- **Issue:** `docs/MAINTAINERS.md` still showed a live `export ANTHROPIC_API_KEY="sk-ant-..."` example, which contradicted the Phase 32 process-scoped secret pattern and T-33-06.
- **Fix:** Replaced it with `op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique --url http://localhost:4799/scoria` and linked to the Docker DX Secrets section.
- **Files modified:** `docs/MAINTAINERS.md`
- **Verification:** Task 1 acceptance gate and policy-lane contract test passed.
- **Committed in:** `78639c1`

---

**Total deviations:** 1 auto-fixed missing-critical doc safety issue.
**Impact on plan:** No scope expansion; the fix kept active docs aligned with Phase 32 security guidance.

## Issues Encountered

None. Both task gates passed after the planned edits.

## Verification

Task 1 gate:

```bash
rg -n "make dev" docs/MAINTAINERS.md docs/uat_automation.md
rg -n "mix scoria\\.ui\\.shots --url http://localhost:4799/scoria" docs/MAINTAINERS.md
rg -n "mix scoria\\.ui\\.e2e --base-url http://localhost:4799/scoria" docs/uat_automation.md
! rg -n "PORT=4010|localhost:4010|mix phx\\.server" docs/uat_automation.md
! rg -n "localhost:4000" docs/operator_verification.md docs/MAINTAINERS.md README.md
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs
```

Result: PASSED - `56 tests, 0 failures`.

Task 2 gate:

```bash
rg -n "examples/support_copilot" README.md docs/operator_verification.md docs/support_copilot_gallery.md
rg -n "http://localhost:4010/|http://localhost:4010/scoria" docs/support_copilot_gallery.md
! rg -n "localhost:4000" docs/operator_verification.md docs/MAINTAINERS.md README.md
! rg -n "PORT=4010|localhost:4010|localhost:4000|mix phx\\.server" docs/uat_automation.md
! rg -n "localhost:4000" docs/support_copilot_gallery.md
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/support_journey_source_test.exs
```

Result: PASSED - `10 tests, 0 failures`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 33-03 can update the source-adjacent screenshot/e2e defaults to match the active docs: `make dev` and `http://localhost:4799/scoria`.

## Self-Check: PASSED

- `33-02-SUMMARY.md` exists.
- Active docs no longer point Scoria repo dashboard startup at stale 4000/4010 guidance.
- Gallery 4010 references are explicitly scoped to `examples/support_copilot`.
- Task commits exist for `33-02`.

---
*Phase: 33-doc-restructure-verification-copy-correction*
*Completed: 2026-06-18*
