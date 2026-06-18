---
phase: 32
slug: secrets-pattern-key-rotation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-18
---

# Phase 32 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix 1.19.5 plus targeted shell assertions for docs/examples |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~15-90 seconds for the policy test; full suite depends on local DB/cache state |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted static assertions from `32-RESEARCH.md`.
- **After every plan wave:** Run `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs`.
- **Before `/gsd:verify-work`:** Run the phase static acceptance checks and confirm SEC-02 maintainer attestation is recorded.
- **Max feedback latency:** one task; no phase closeout without the SEC-02 human checkpoint.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | SEC-01 | T-32-01 / T-32-03 | Examples contain only secret references/comments; no real provider key or long-lived shell export is introduced. | static shell | `test -f .envrc.example && test -f .env.op.example && grep -qxF '.envrc' .gitignore && grep -qxF '.env.op' .gitignore && ! grep -nE '^ANTHROPIC_API_KEY=' .env.example` | yes | pending |
| 32-01-02 | 01 | 1 | SEC-01 | T-32-02 / T-32-04 | Docker DX docs teach process-scoped `op run --env-file` for critique only and avoid unsafe 1Password/direnv footguns. | static shell | `grep -q '^## Secrets (ANTHROPIC_API_KEY)' docs/docker_dev_dx.md && grep -q 'op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique' docs/docker_dev_dx.md && grep -q 'op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique' docs/docker_dev_dx.md` | yes | pending |
| 32-02-01 | 02 | 2 | SEC-02 | T-32-05 | Rotation is recorded as redacted maintainer attestation only; no secret value, prefix, suffix, screenshot, or token material is stored. | human checkpoint + static artifact check | `grep -q 'SEC-02:' .planning/phases/32-secrets-pattern-key-rotation/32-02-SUMMARY.md && grep -q 'Maintainer attested' .planning/phases/32-secrets-pattern-key-rotation/32-02-SUMMARY.md && grep -q 'No secret value, prefix, suffix, screenshot, or token material is stored in this repository.' .planning/phases/32-secrets-pattern-key-rotation/32-02-SUMMARY.md && ! grep -nE 'sk-ant-[A-Za-z0-9_-]+' .planning/phases/32-secrets-pattern-key-rotation/32-02-SUMMARY.md .planning/phases/32-secrets-pattern-key-rotation/32-VERIFICATION.md` | post-execution | pending |

---

## Static Acceptance Checks

Run these against only the touched safe files. Do not inspect `.env`, shell history, logs, screenshots, process environments, or other likely secret-bearing sources.

```bash
test -f .envrc.example
test -f .env.op.example

grep -qxF '.env' .gitignore
grep -qxF '.envrc' .gitignore
grep -qxF '.env.op' .gitignore

grep -qxF 'ANTHROPIC_API_KEY=op://Private/scoria-dev/ANTHROPIC_API_KEY' .env.op.example
grep -q 'SCORIA_OP_ENV_FILE' .envrc.example
grep -q 'watch_file "$SCORIA_OP_ENV_FILE"' .envrc.example
grep -q 'has op' .envrc.example

! grep -nE '^ANTHROPIC_API_KEY=' .env.example
grep -q 'op://Private/scoria-dev/ANTHROPIC_API_KEY' .env.example

grep -q '^## Secrets (ANTHROPIC_API_KEY)' docs/docker_dev_dx.md
grep -q 'op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique' docs/docker_dev_dx.md
grep -q 'op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique' docs/docker_dev_dx.md

! grep -n -- '--no-masking' .envrc.example .env.op.example .env.example docs/docker_dev_dx.md
! grep -nE 'direnv_load|op read|op inject|export ANTHROPIC_API_KEY' .envrc.example docs/docker_dev_dx.md
! grep -nE 'ANTHROPIC_API_KEY=sk-ant-|ANTHROPIC_API_KEY=.*sk-ant-' .env.example .envrc.example .env.op.example docs/docker_dev_dx.md
```

---

## Wave 0 Requirements

Existing infrastructure covers this phase. No new framework, fixture, or harness is required before implementation.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Previously on-disk `ANTHROPIC_API_KEY` is rotated or revoked in the Anthropic Console. | SEC-02 | Provider-side key state is outside the repository and cannot be proven by source files. | Maintainer records a redacted attestation in the phase summary/verification with maintainer handle, UTC date, affected environment label, private evidence class, and the statement that no secret value, prefix, suffix, screenshot, or token material was recorded in the repo. |

---

## Validation Sign-Off

- [x] All anticipated tasks have automated checks or an explicit human checkpoint.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is bounded to one task.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-18
