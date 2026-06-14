---
phase: 17
slug: consistency-sweep-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `mix.exs` / `test/test_helper.exs` |
| **Quick run command** | `mix test test/scoria_web/ds06_drift_guard_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~varies (full suite) |

---

## Sampling Rate

- **After every task commit:** Run the relevant quick check (`mix test test/scoria_web/ds06_drift_guard_test.exs` for raw-color claims; `mix docs` for catalog tasks)
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green; committed proof artifacts must exist on disk
- **Max feedback latency:** seconds-to-minutes (deterministic checks); the LLM critique pass is non-deterministic audit-trail only

---

## Per-Task Verification Map

> See `17-RESEARCH.md` → `## Validation Architecture` for the falsifiable, re-runnable check per requirement. Populated by the planner against the locked decisions (D-04 deterministic P1 checklist, D-13 DS-06 citation, `mix docs` rendering, committed-artifact existence). LLM rubric scores (D-03) are audit-trail, NOT the falsifiable proof.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {N}-NN-NN | NN | N | PROOF-01 | — | N/A (no new attack surface) | exec-proof | `mix test test/scoria_web/ds06_drift_guard_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Existing infrastructure covers all phase requirements (ExUnit + DS-06 guard + `mix docs` already wired). No new test framework needed.

*This is a proof/documentation phase — most validation is artifact-existence + citation of existing executable guards rather than net-new tests.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| LLM rubric-score delta (baseline → final) | PROOF-01 | Non-deterministic vision critique (±1–2 between runs); needs ReqLLM API key | Re-run `mix scoria.ui.shots --critique`; compare per-screen JSON to baseline. Audit-trail only — the deterministic P1 checklist is the falsifiable proof. |
| Before/after contact sheet visual | PROOF-02 | Rendered images are gitignored/regenerable | Run the committed generator with `--before priv/shots/2026-06-04 --after <final-dir>`; eyeball the grid against `contact_sheet_index.md` notes. |

*Deterministic proof for each requirement (P1 checklist re-verify, `mix docs` render, DS-06 `mix test`, committed-artifact existence) requires no API key and is the basis for sign-off.*

---

## Validation Sign-Off

- [ ] PROOF-01: deterministic 11-P1 resolution checklist re-verifiable by code review + `mix test`; raw-color-zero cites `ds06_drift_guard_test.exs` + empty `ds06_baseline.txt`
- [ ] PROOF-02: committed contact-sheet generator + `contact_sheet_index.md` exist; generator re-runs via `--before/--after`
- [ ] PROOF-03: `mix docs` renders the `ui.ex` component catalog; `docs/MAINTAINERS.md` has catalog entry-point + harness usage
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter once planner maps tasks

**Approval:** pending
