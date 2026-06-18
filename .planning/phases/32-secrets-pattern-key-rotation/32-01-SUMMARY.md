---
phase: 32-secrets-pattern-key-rotation
plan: 01
subsystem: infra
tags: [secrets, docker-dx, direnv, onepassword]

requires:
  - phase: 31-dockerfile-caching-audit-doc
    provides: "Layer-cache section placement in docs/docker_dev_dx.md"
provides:
  - "Safe committed direnv and 1Password secret-reference examples"
  - "Gitignore coverage for real local .envrc and .env.op files"
  - "Comment-only Anthropic guidance in .env.example"
  - "Docker DX Secrets section for process-scoped critique commands"
affects: [phase-32, phase-33, phase-34, docker-dev-dx]

tech-stack:
  added: []
  patterns:
    - "Process-scoped op run --env-file secret resolution"
    - "direnv exports only SCORIA_OP_ENV_FILE, not provider keys"

key-files:
  created:
    - .envrc.example
    - .env.op.example
  modified:
    - .env.example
    - .gitignore
    - docs/docker_dev_dx.md

key-decisions:
  - "Kept ANTHROPIC_API_KEY as the runtime variable name."
  - "Kept real key resolution out of the long-lived shell."

patterns-established:
  - "Committed examples may contain 1Password secret references, not plaintext keys."
  - "Secret-consuming commands run under op run --env-file."

requirements-completed: [SEC-01]

duration: 18 min
completed: 2026-06-18
status: complete
---

# Phase 32 Plan 01: SEC-01 Safe Secrets Pattern Summary

**Process-scoped 1Password secret-reference pattern for the screenshot critique key, with safe examples, gitignore coverage, and Docker DX docs**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-18T13:30:00Z
- **Completed:** 2026-06-18T13:48:28Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `.envrc.example` that exports only `SCORIA_OP_ENV_FILE`, watches `.env.op`, and warns when the 1Password CLI is missing.
- Added `.env.op.example` with the safe `op://Private/scoria-dev/ANTHROPIC_API_KEY` secret reference example.
- Replaced the live Anthropic assignment in `.env.example` with comment-only 1Password guidance.
- Added `.envrc` and `.env.op` beside `.env` in `.gitignore`.
- Added `## Secrets (ANTHROPIC_API_KEY)` to `docs/docker_dev_dx.md` after the layer-cache section and before adoption guidance.

## Task Commits

1. **Task 1: Add safe secret-reference examples and gitignore entries** - `4a3a558` (`feat(32-01): add safe 1Password secret examples`)
2. **Task 2: Add the Docker DX Secrets section** - `f6d2683` (`docs(32-01): add Docker DX secrets section`)

## Files Created/Modified

- `.envrc.example` - direnv local config example; points at `.env.op` without resolving provider keys into the shell.
- `.env.op.example` - dotenv-format 1Password secret-reference example.
- `.env.example` - non-secret comments for the Anthropic critique pass.
- `.gitignore` - ignores `.envrc` and `.env.op`.
- `docs/docker_dev_dx.md` - documents first-time setup, process-scoped Docker/native critique commands, mechanics, and footguns.

## Decisions Made

None beyond the locked Phase 32 context. The implementation followed D-01 through D-11 and D-16 through D-18.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion.

## Issues Encountered

- The unguarded local policy command `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` passed once earlier in the run (`46 tests, 0 failures`) but later hit local Postgres connection saturation from already-running dev servers (`too_many_connections`) during application startup.
- The CI-equivalent policy-lane command with the documented no-Postgres environment, `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs`, passed with `46 tests, 0 failures`.

## Verification

Targeted static checks were run only against touched safe files. `.env`, shell history, logs, screenshots, process environments, and other likely secret-bearing sources were not read.

### Task 1 Static Gate

```bash
bash -lc 'set -euo pipefail
test -f .envrc.example
test -f .env.op.example
grep -qxF ".env" .gitignore
grep -qxF ".envrc" .gitignore
grep -qxF ".env.op" .gitignore
grep -qxF "ANTHROPIC_API_KEY=op://Private/scoria-dev/ANTHROPIC_API_KEY" .env.op.example
grep -q "export SCORIA_OP_ENV_FILE=\"${SCORIA_OP_ENV_FILE:-.env.op}\"" .envrc.example
grep -q "watch_file \"$SCORIA_OP_ENV_FILE\"" .envrc.example
grep -q "has op" .envrc.example
grep -q "log_error" .envrc.example
if grep -v "^[[:space:]]*#" .env.example | grep -qE "^[[:space:]]*ANTHROPIC_API_KEY="; then echo ".env.example has a live Anthropic assignment"; exit 1; fi
grep -q "op://Private/scoria-dev/ANTHROPIC_API_KEY" .env.example
! grep -n -- "--no-masking" .envrc.example .env.op.example .env.example docs/docker_dev_dx.md
! grep -nE "direnv_load|op read|op inject|export ANTHROPIC_API_KEY" .envrc.example docs/docker_dev_dx.md
! grep -nE "ANTHROPIC_API_KEY=sk-ant-|ANTHROPIC_API_KEY=.*sk-ant-" .env.example .envrc.example .env.op.example docs/docker_dev_dx.md'
```

Result: PASSED.

### Task 2 Static Gate

```bash
bash -lc 'set -euo pipefail
awk "/^### Layer-cache invalidation/{layer=NR} /^## Secrets \\(ANTHROPIC_API_KEY\\)/{secrets=NR} /^## Adopting this in another repo/{adopt=NR} END{exit !(layer && secrets && adopt && layer < secrets && secrets < adopt)}" docs/docker_dev_dx.md
grep -q "^## Secrets (ANTHROPIC_API_KEY)" docs/docker_dev_dx.md
grep -q "^### First-time setup" docs/docker_dev_dx.md
grep -q "^### Run the critique pass" docs/docker_dev_dx.md
grep -q "^### How it works" docs/docker_dev_dx.md
grep -q "^### Footguns" docs/docker_dev_dx.md
grep -q "The dashboard and normal dev server do not need this key. The screenshot critique pass does." docs/docker_dev_dx.md
grep -q "op run --env-file \"${SCORIA_OP_ENV_FILE:-.env.op}\" -- docker compose --profile shots run --rm critique" docs/docker_dev_dx.md
grep -q "op run --env-file \"${SCORIA_OP_ENV_FILE:-.env.op}\" -- mix scoria.ui.shots --critique" docs/docker_dev_dx.md
grep -q "secret reference" docs/docker_dev_dx.md
grep -q "plaintext key" docs/docker_dev_dx.md
! grep -n -- "--no-masking" .envrc.example .env.op.example .env.example docs/docker_dev_dx.md
! grep -nE "direnv_load|op read|op inject|export ANTHROPIC_API_KEY" .envrc.example docs/docker_dev_dx.md
! grep -nE "ANTHROPIC_API_KEY=sk-ant-|ANTHROPIC_API_KEY=.*sk-ant-" .env.example .envrc.example .env.op.example docs/docker_dev_dx.md'
```

Result: PASSED.

### Protected File Check

```bash
git diff --quiet -- compose.yml Makefile lib/scoria/ui_critique.ex lib/mix/tasks/scoria.ui.shots.ex
```

Result: PASSED. Those files were unchanged.

### Policy Lane

```bash
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs
```

Result: PASSED - `46 tests, 0 failures`.

## User Setup Required

None for this plan. Operators who want to run the critique pass should follow the new `docs/docker_dev_dx.md` Secrets section.

## Next Phase Readiness

SEC-01 is complete. SEC-02 remains blocked until `32-02-PLAN.md` records redacted maintainer attestation that the previously on-disk Anthropic key was rotated or revoked.

## Self-Check: PASSED

- Key files created exist on disk.
- Task commits exist for `32-01`.
- Static acceptance gates passed.
- CI-equivalent policy-lane test passed.
- No likely secret-bearing source was inspected.

---
*Phase: 32-secrets-pattern-key-rotation*
*Completed: 2026-06-18*
