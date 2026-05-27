# Thread: Warning Ratchet Follow-up (`WARN-03`)

**Opened:** 2026-05-27  
**Status:** active (v2.6 next milestone — confirmed 2026-05-27 assessment)  
**Owner:** scoria-maintainers  
**Priority:** highest — v2.6 Warning Ratchet

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

## Proposed Follow-up Scope (v2.6)

- Implement `WARN-03` as staged warning ratchet beyond canonical lanes.
- Add executable baseline-expiry enforcement to reduce policy drift.
- Keep canonical lane chain (`release_preview -> adoption -> runtime_to_handoff`) unchanged.

## Staged Ratchet Decisions (assessment 2026-05-27)

1. **Inventory first:** `mix compile --warnings-as-errors` + `mix test --warnings-as-errors`; classify by area.
2. **Ratchet order:** high-signal dirs first (`lib/`, adoption lane files) — avoid all-at-once full-suite gate.
3. **CI policy:** fail on expired rows in `.planning/WARNING-BASELINE.md` before requiring full-suite WAE green.
4. **Non-goals for v2.6:** Hex publish, README shipped-state, semantic CI gate, connector docs (defer to v2.7+).

## Risks To Watch

- Overly strict ratchet can create noisy failures with low signal.
- Leaving baseline expiry manual can silently weaken warning policy trust.
- Coupling this too tightly with installer work could dilute milestone focus.
