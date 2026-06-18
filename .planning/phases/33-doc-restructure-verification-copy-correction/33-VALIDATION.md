---
phase: 33
slug: doc-restructure-verification-copy-correction
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-18
---

# Phase 33 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 33-RESEARCH.md "## Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix plus targeted `rg` static checks |
| **Config file** | `test/test_helper.exs`; `SCORIA_LANE_CONTRACT_ONLY=true` keeps policy-lane checks off the app boot path |
| **Quick run command** | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~15-90 seconds for the policy test; full suite depends on local DB/cache state |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted `rg` gate plus `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs`.
- **After every plan wave:** Run all Phase 33 active-doc, planning, and harness sweeps from 33-CONTEXT.md D-26 through D-28.
- **Before `/gsd:verify-work`:** Policy-lane docs contract is green and all active stale-copy hits are either corrected or explicitly classified as allowed implementation evidence / gallery-app copy.
- **Max feedback latency:** one task; no phase closeout with an unclassified stale dev-start hit.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | DOCS-02 | T-33-02 / T-33-03 | Docker DX docs keep scoped cleanup and process-scoped secrets guidance while adding the required reader-first IA. | static docs + policy lane | `rg -n "^## (Docker daily loop|Native dev server|Caching guarantees|Secrets|Stale instance hygiene)" docs/docker_dev_dx.md && SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | yes | pending |
| 33-02-01 | 02 | 1 | DOCS-01 | T-33-01 / T-33-04 | Active docs no longer send verifiers to the wrong Scoria dashboard URL; gallery-app URLs remain explicitly qualified. | static docs + policy lane | `rg -n "localhost:4000|mix phx\\.server" README.md docs/operator_verification.md docs/MAINTAINERS.md docs/uat_automation.md docs/support_copilot_gallery.md && SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | yes | pending |
| 33-03-01 | 03 | 2 | DOCS-01 | T-33-01 / T-33-04 | Active planning and harness copy uses `make up` / `make dev` plus `*.localhost` or `localhost:4799`, not stale `localhost:4000/scoria` browser-start instructions. | static planning/source sweep | `rg -n "mix phx\\.server|localhost:4000/scoria" .planning -g '!milestones/**' -g '!v*-MILESTONE-AUDIT.md' -g '!debug/**' -g '!memory/**' -g '!todos/completed/**' && rg -n "localhost:4000/scoria|mix phx\\.server" lib/mix/tasks/scoria.ui.*.ex priv/dev priv/repo/dev_seed.exs` | yes | pending |

---

## Static Acceptance Checks

Run these before phase verification. The `rg` commands may print allowed hits only when the plan summary classifies them as Docker-internal, CI self-test, implementation evidence, historical rationale, or the separate support-copilot gallery app.

```bash
rg -n "^## (Docker daily loop|Native dev server|Caching guarantees|Secrets|Stale instance hygiene)" docs/docker_dev_dx.md

rg -n "localhost:4000|mix phx\\.server" \
  README.md \
  docs/operator_verification.md \
  docs/MAINTAINERS.md \
  docs/uat_automation.md \
  docs/support_copilot_gallery.md

rg -n "PORT=4010|localhost:4010|localhost:4000|mix phx\\.server" \
  docs/uat_automation.md \
  docs/support_copilot_gallery.md

rg -n "mix phx\\.server|localhost:4000/scoria" .planning \
  -g '!milestones/**' \
  -g '!v*-MILESTONE-AUDIT.md' \
  -g '!debug/**' \
  -g '!memory/**' \
  -g '!todos/completed/**'

rg -n "localhost:4000/scoria|mix phx\\.server" \
  lib/mix/tasks/scoria.ui.*.ex \
  priv/dev \
  priv/repo/dev_seed.exs

make -n dev
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs
```

---

## Wave 0 Requirements

Existing infrastructure covers all Phase 33 requirements. No new test file, fixture, package, or framework is required before implementation. Phase 34 owns the dedicated Docker DX drift-guard test.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `docs/docker_dev_dx.md` reads as a top-to-bottom reference standard for a new contributor. | DOCS-02 | Information architecture and reader empathy are document qualities; the static checks only prove required anchors and canonical strings. | Read the first screen and the five required sections. Confirm each section has when to use it, commands, expected URL/output, footguns, and recovery. |
| Remaining stale-copy hits are truly allowed contexts. | DOCS-01 | A grep hit can be valid Docker-internal implementation evidence, CI self-test context, historical rationale, or gallery-app copy. | For every remaining `localhost:4000` or `mix phx.server` hit in active scope, record its classification in the plan summary before verification. |

---

## Validation Sign-Off

- [x] All anticipated tasks have automated checks or an explicit manual classification checkpoint.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is bounded to one task.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-18
