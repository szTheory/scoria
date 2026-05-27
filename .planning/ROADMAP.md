# Roadmap: Scoria

## Milestones

- ✅ **v2.4 Adoption Reliability Contract** — Archived roadmap: `.planning/milestones/v2.4-ROADMAP.md` (shipped 2026-05-27)
- ◆ **v2.5 Installer Safety & Upgrade Confidence** — Active roadmap (this file)

## v2.5 Scope

**Goal:** Make installer mutations predictable, inspectable, and drift-safe before applying host-app writes.

**Requirements mapped:** 6 / 6

| Phase | Name | Goal | Requirements |
|------:|------|------|--------------|
| 59 | 2/2 | Complete    | 2026-05-27 |
| 60 | 2/2 | Complete    | 2026-05-27 |
| 61 | 3/3 | Complete    | 2026-05-27 |
| 62 | 3/3 | Complete    | 2026-05-27 |
| 63 | Manifest Check Fingerprint Hardening | Pending | INST-07 (integration hardening) |

## Phase Details

### Phase 59: Planner Contract Foundation

**Goal:** Establish one installer planning engine for preview/check semantics before any write-path changes.

**Success criteria:**

1. `mix scoria.install --dry-run` emits a deterministic ordered mutation plan with no host writes.
2. `mix scoria.install --check` returns actionable compatibility/drift diagnostics with stable non-zero semantics on unsafe states.
3. Installer output classifies each target surface as `create`, `update`, `no-op`, or `manual-review` with rationale.

### Phase 60: Drift Classification And Safe Apply

**Goal:** Make upgrade drift explicit and enforce planner-led apply behavior.

**Success criteria:**

1. Manifest-aware drift detection covers managed router, config, and migration surfaces.
2. Unsafe drift paths do not silently overwrite host files; installer surfaces manual remediation guidance.
3. Apply mode executes the same planned mutations produced by preview/check modes.

### Phase 61: Proof And Stability Closeout

**Goal:** Lock confidence by verifying output truth, idempotency, and guardrail stability.

**Success criteria:**

1. Preview/check/apply summaries remain truthful and consistent for installed, skipped, and manual-review paths.
2. Installer contract tests cover planner/apply equivalence and drift-report behavior across representative host shapes.
3. Existing lane contract, warning policy, and CI order guarantees remain green after installer-safety changes.

### Phase 62: Nyquist & Traceability Closeout

**Goal:** Close Nyquist validation gaps and restore traceability parity across phases 59–61 before milestone archive.

**Depends on:** Phase 61

**Gap Closure:** Closes v2.5 audit tech debt for stale `VALIDATION.md` rows (phases 59, 61), missing `requirements-completed` SUMMARY frontmatter (phases 60–61), and milestone ledger parity after audit corrections.

**Success criteria:**

1. Phases 59 and 61 have Nyquist-compliant `VALIDATION.md` artifacts with task rows matching passed verification.
2. Phase 60–61 SUMMARY files include `requirements-completed` frontmatter aligned to VERIFICATION evidence.
3. REQUIREMENTS.md traceability and phase artifacts agree on v2.5 closure state.

### Phase 63: Manifest Check Fingerprint Hardening

**Goal:** Close the partial manifest integration gap by documenting and optionally hardening check-time fingerprint semantics.

**Depends on:** Phase 62

**Requirements:** INST-07 (integration hardening — requirement already satisfied; closes audit integration partial)

**Gap Closure:** Closes v2.5 audit integration gap `manifest-check-fingerprint` and underdocumented manifest fingerprint role at check vs apply time.

**Success criteria:**

1. Check-time vs apply-time manifest fingerprint behavior is documented for operators and maintainers.
2. Planner check path uses stored manifest fingerprints where appropriate, or documents an explicit live-host-only contract with rationale.
3. Targeted tests cover the chosen check-time fingerprint contract without regressing apply-time freshness gates.

## Non-Goals (v2.5)

- No full warning-ratchet execution (`WARN-03` remains the immediate next milestone).
- No broad installer architecture rewrite beyond planner/check + drift-safe apply contracts.
- No new runtime capability families during this milestone.
