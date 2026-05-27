# Roadmap: Scoria

## Milestones

- ✅ **v2.4 Adoption Reliability Contract** — Archived roadmap: `.planning/milestones/v2.4-ROADMAP.md` (shipped 2026-05-27)
- ◆ **v2.5 Installer Safety & Upgrade Confidence** — Active roadmap (this file)

## v2.5 Scope

**Goal:** Make installer mutations predictable, inspectable, and drift-safe before applying host-app writes.

**Requirements mapped:** 6 / 6

| Phase | Name | Goal | Requirements |
|------:|------|------|--------------|
| 59 | Planner Contract Foundation | Ship no-write planner/check contract truth with deterministic classification and exit behavior | INST-03, INST-04, INST-05 |
| 60 | Drift Classification And Safe Apply | Add manifest-aware drift detection and ensure apply uses planner truth instead of ad-hoc mutations | INST-06, INST-07 |
| 61 | Proof And Stability Closeout | Prove idempotent, truthful output behavior across preview/check/apply while preserving v2.4 reliability guardrails | INST-08 |

## Phase Details

### Phase 59 — Planner Contract Foundation

**Goal:** Establish one installer planning engine for preview/check semantics before any write-path changes.

**Success criteria:**

1. `mix scoria.install --dry-run` emits a deterministic ordered mutation plan with no host writes.
2. `mix scoria.install --check` returns actionable compatibility/drift diagnostics with stable non-zero semantics on unsafe states.
3. Installer output classifies each target surface as `create`, `update`, `no-op`, or `manual-review` with rationale.

### Phase 60 — Drift Classification And Safe Apply

**Goal:** Make upgrade drift explicit and enforce planner-led apply behavior.

**Success criteria:**

1. Manifest-aware drift detection covers managed router, config, and migration surfaces.
2. Unsafe drift paths do not silently overwrite host files; installer surfaces manual remediation guidance.
3. Apply mode executes the same planned mutations produced by preview/check modes.

### Phase 61 — Proof And Stability Closeout

**Goal:** Lock confidence by verifying output truth, idempotency, and guardrail stability.

**Success criteria:**

1. Preview/check/apply summaries remain truthful and consistent for installed, skipped, and manual-review paths.
2. Installer contract tests cover planner/apply equivalence and drift-report behavior across representative host shapes.
3. Existing lane contract, warning policy, and CI order guarantees remain green after installer-safety changes.

## Non-Goals (v2.5)

- No full warning-ratchet execution (`WARN-03` remains the immediate next milestone).
- No broad installer architecture rewrite beyond planner/check + drift-safe apply contracts.
- No new runtime capability families during this milestone.
