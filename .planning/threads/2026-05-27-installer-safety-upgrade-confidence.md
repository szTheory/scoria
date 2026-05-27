# Thread: Installer Safety And Upgrade Confidence

**Opened:** 2026-05-27  
**Status:** open  
**Owner:** scoria-maintainers  
**Priority:** highest next milestone

## Why This Thread Exists

Scoria now has a reliable install baseline, but host-app mutation trust still lacks first-class plan/apply safety. The next milestone should close this gap before broader reliability work.

## Current Evidence

- Installer currently mutates router, Tailwind, migrations, and runtime config directly with no dry-run/check path.
- Route and idempotency coverage is strong for supported happy-path forms.
- Known open requirement IDs for this wedge are `INST-03` and `INST-04`.

## Open Investigations

1. What is the minimum `--check` contract that gives actionable plan output without widening scope into a full installer rewrite?
2. Which installer mutations require manifest ownership markers versus structural diffing?
3. What is the safest fallback behavior when drift is detected in host-managed files?
4. Which host-app topologies should be in milestone proof coverage beyond current list-form browser scope support?

## Proposed Milestone Acceptance Slice

- `INST-03`: first-class `--dry-run` / `--check` plan semantics (human-readable + machine-readable summary).
- `INST-04`: manifest-backed drift detection and upgrade-safe apply behavior for router/config/migrations.

## Risks To Watch

- False-positive drift reports that block legitimate upgrades.
- Partial-apply behavior if plan/apply boundaries are not explicit.
- Scope creep into a general-purpose installer engine.

## Next Hand-off Notes

- Keep this milestone strictly installer-safety focused.
- Preserve lane-contract and canonical closeout command contracts unchanged while this work lands.
