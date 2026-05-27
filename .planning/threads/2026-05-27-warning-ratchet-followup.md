# Thread: Warning Ratchet Follow-up (`WARN-03`)

**Opened:** 2026-05-27  
**Status:** queued-next  
**Owner:** scoria-maintainers  
**Priority:** immediate follow-up after installer-safety milestone

## Why This Thread Exists

v2.4 hardened canonical warning/CI trust, but full-suite warning ratchet remains open (`WARN-03`). This needs a dedicated follow-up milestone once installer plan/apply safety is closed.

## Current Evidence

- Canonical closeout lanes are warning-clean and CI-enforced in order.
- Baseline debt is tracked in `.planning/WARNING-BASELINE.md` with owner and expiry.
- Expiry for full-suite warning audit debt is near-term (`2026-06-07`).

## Open Investigations

1. Which full-suite warning surfaces should be ratcheted first to avoid a destabilizing all-at-once gate?
2. Should baseline expiry checks be executable in CI to avoid manual drift?
3. What staged policy best balances reliability pressure with contributor velocity?

## Proposed Follow-up Scope

- Implement `WARN-03` as staged warning ratchet beyond canonical lanes.
- Add executable baseline-expiry enforcement to reduce policy drift.
- Keep canonical lane chain (`release_preview -> adoption -> runtime_to_handoff`) unchanged.

## Risks To Watch

- Overly strict ratchet can create noisy failures with low signal.
- Leaving baseline expiry manual can silently weaken warning policy trust.
- Coupling this too tightly with installer work could dilute milestone focus.
