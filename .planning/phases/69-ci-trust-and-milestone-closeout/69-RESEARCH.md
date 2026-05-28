# Phase 69: CI Trust And Milestone Closeout — Research

**Researched:** 2026-05-27  
**Domain:** CI trust documentation, maintainer ratchet hygiene, v2.6 milestone audit ceremony  
**Confidence:** HIGH (Phase 68 shipped CI; CONTEXT locks D-01…D-30; live codebase inspected)

<user_constraints>
## User Constraints (from 69-CONTEXT.md)

### Locked Decisions
- **No new CI gates** — documentation + traceability + maintainer hygiene only
- Three serial plans: 69-00 docs → 69-01 ratchet hygiene → 69-02 milestone closeout
- Thin prose map + fat executable contract (ci.yml, VerificationLanes, contract tests)
- Rewrite CI-03 requirement text (drop “staged WAE”); sync REQUIREMENTS / PROJECT / ROADMAP
- Medium v2.6 milestone audit after 69-VERIFICATION.md passes
- WR-01 symmetry for `warning_ratchet.test`; WR-02 subprocess integration test
- Defer inventory JSON CI diff and knowledge WAE in CI to v2.7

### Deferred (OUT OF SCOPE)
- Hex publish, README docs-truth (v2.7)
- `/gsd-complete-milestone v2.6` execution (follow 69-02; user may run separately)
- `gsd-integration-checker` unless new cross-job coupling without contract tests
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Plans |
|----|-------------|-------|
| CI-03 | CI preserves canonical closeout order; policy job (baseline + compile WAE + lane-contract WAE) before Postgres test job; full-suite WAE after closeout lanes; documented maintainer trust | 69-00, 69-02 |
</phase_requirements>

---

## 1. Executive Summary

Phase 69 closes **CI-03** and **v2.6 milestone traceability** without changing CI topology. Phase 68 already shipped policy→test jobs, full-suite WAE, and contract tests. Phase 69 makes trust **explicit**: operator CI gate map, aligned requirement prose, optional ratchet.test tmp symmetry (68-REVIEW carryover), and `v2.6-MILESTONE-AUDIT.md` after verification.

**Primary recommendation:** Execute CONTEXT plan shape (69-00 → 69-01 → 69-02). Treat `ci_policy_contract_test.exs` and `Scoria.VerificationLanes` as SSOT; prose only explains topology and local parity.

**Current CI topology (unchanged):**

| Job | Steps (order) |
|-----|----------------|
| **policy** (no Postgres) | `warning_baseline.check` → deps → `compile --warnings-as-errors` → lane-contract WAE |
| **test** (`needs: policy`, pgvector :55432) | `release_preview` (dev) → ecto → `test.adoption` → `test.runtime_to_handoff` → `mix test --warnings-as-errors` → `mix test.knowledge` |

Ratchet commands remain **maintainer-only** (WARN-06); not in CI after 68-03.

---

## 2. Documentation Bundle (CI-03)

### 2.1 Operator doc extension

`docs/operator_verification.md` already has WARN-05, WARN-06, WARN-07 sections. Phase 69 adds **`### CI gate map (maintainers)`** (D-02) covering:

- Two-job diagram: `policy` → `test`
- Intent per job (fail cheap vs canonical closeout)
- Local parity: `SCORIA_DB_PORT=55432`, `MIX_ENV=dev` for `release_preview`
- Ratchet = maintainer-only; full WAE = production gate
- Failure diagnosis bullets (Field Engineer tone, D-29)

**Anti-pattern:** New `docs/ci.md` duplicates SSOT (D-05 rejected).

### 2.2 ci.yml comments

Add 5–8 line workflow header + one-line intent per job (D-03). No step reordering unless contract tests fail (unexpected).

### 2.3 README

Keep existing CI badge; add ≤2 lines linking to operator CI gate map section (D-04).

### 2.4 Contract test anchor (D-06)

Extend `Scoria.CiPolicyContractTest` with assertion that `docs/operator_verification.md` contains stable anchor (e.g. `"CI gate map"` or `"policy` job"). Pattern matches WARN-06 ratchet doc assertions — **do not** assert full prose bodies.

### 2.5 REQUIREMENTS rewrite (D-08)

Locked CI-03 text (replace “staged WAE”):

> **CI-03**: CI preserves canonical closeout order (`release_preview` → `adoption` → `runtime_to_handoff`) in the Postgres test job, runs a Postgres-free policy job first (baseline expiry, `mix compile --warnings-as-errors`, lane-contract WAE), and enforces full-suite `mix test --warnings-as-errors` after closeout lanes and before `mix test.knowledge`.

Sync `PROJECT.md` checkbox prose; update `ROADMAP.md` Phase 69 goal to “Document CI trust + close v2.6 traceability” (D-09).

---

## 3. Maintainer Hygiene (68-REVIEW Carryover)

### WR-01 — `warning_ratchet.test` tmp asymmetry

**Issue (68-REVIEW):** `Mix.Tasks.Scoria.WarningRatchet.Test` calls `cleanup_transient_tmp!/0` only **before** run. Install-check paths create `test/tmp/install_check/*` during WAE run. Follow-on `warning_inventory` can fail `ensure_clean_tmp!/0`.

**Remediation (D-18):** Mirror `warning_ratchet.check`:

```elixir
WarningInventory.ensure_clean_tmp!()
try do
  # existing test run
after
  WarningInventory.cleanup_transient_tmp!()
end
```

Remove redundant pre-only cleanup or keep pre+cleanup for symmetry.

### WR-02 — neutered integration test

**Issue:** `tmp_preflight_test.exs` calls `WarningRatchet.Check.run/1` inside ExUnit; `nested_ex_unit?/0` skips capture → test passes in ~0.05s without exercising tmp chain.

**Remediation options (CONTEXT discretion):**

| Option | Pros | Cons |
|--------|------|------|
| **Subprocess** `System.cmd("mix", ["scoria.warning_ratchet.check"], env: [{"MIX_ENV", "test"}])` | Real capture path | Slower; needs clean env |
| **Unit test cleanup only** | Fast, deterministic | Does not prove full capture |
| **Stub ExUnit.Server** | In-process | Brittle |

**Recommendation:** Subprocess for integration test; keep existing unit tests for `ensure_clean_tmp!/0` / `cleanup_transient_tmp!/0`.

---

## 4. Milestone Closeout Ceremony

### 4.1 Order (D-20)

1. Execute 69-00, 69-01, 69-02 plans  
2. `69-VERIFICATION.md` passed  
3. Mark CI-03 + WARN-03…07 in REQUIREMENTS / PROJECT  
4. Write `.planning/milestones/v2.6-MILESTONE-AUDIT.md`  
5. User runs `/gsd-complete-milestone v2.6` (optional same session, D-21)  
6. Archive `.planning/threads/2026-05-27-warning-ratchet-followup.md`  
7. Do **not** flip PROJECT Current Milestone to v2.7 before audit (D-21)

### 4.2 Audit template (D-11–D-15)

Follow `v2.5-MILESTONE-AUDIT.md` structure:

- Frontmatter scores (target: requirements 6/6, phases 4/4, integration = CI order + policy gates)
- Scope: phases 66–69, WARN-03…CI-03
- 3-source requirement matrix with FAIL on orphans
- **CI closeout contract** section: policy→test, step order, contract test pointers
- Nyquist rollup from 66–69 `*-VALIDATION.md`
- Tech debt rollup (non-blocking)
- Audit-time re-proof commands (D-14)

### 4.3 Human CI confirmation (D-19)

68-VERIFICATION noted branch ahead of origin. `69-VERIFICATION.md` must record remote GitHub Actions green on next push (manual checkbox).

---

## 5. Patterns and SSOT

| Artifact | Role |
|----------|------|
| `.github/workflows/ci.yml` | Executable CI order |
| `lib/scoria/verification_lanes.ex` | `closeout_order/0`, `ci_command/1` |
| `test/scoria/ci_policy_contract_test.exs` | Gate order + doc anchors |
| `test/scoria/verification_lanes_test.exs` | Lane contract |
| `docs/operator_verification.md` | Maintainer narrative |

**Eval-platform coherence (D-28):** CI = production regression gate; baseline/inventory = policy layer — document loop without importing eval-vendor CI bulk.

---

## 6. Risks

| Risk | Mitigation |
|------|------------|
| Prose drifts from ci.yml | Contract tests + anchor assertion in operator doc |
| Reintroducing ratchet CI step | Explicit contract test refutes ratchet in workflow |
| Premature v2.7 narrative | PROJECT milestone flip deferred until audit |
| Subprocess integration test flaky | `async: false`, tmp cleanup in setup/on_exit |

---

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix test) |
| **Quick run** | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs test/scoria/warning_inventory/` |
| **CI-03 contract proof** | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` |
| **Policy meta-gate** | `mix scoria.warning_baseline.check` |
| **Audit re-proof (D-14)** | baseline.check + compile WAE + contract tests above |
| **Doc-only tasks** | grep/read for section anchors; no new runtime gates |

Nyquist: Automated verify on code tasks; manual-only for remote CI green confirmation and milestone archive ceremony steps.

---

## RESEARCH COMPLETE
