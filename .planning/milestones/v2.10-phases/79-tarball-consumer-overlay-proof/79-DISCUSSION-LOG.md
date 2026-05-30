# Phase 79: Tarball consumer overlay proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 79-tarball consumer overlay proof
**Areas discussed:** CI timeout & runtime budget, proof step assertions, failure diagnostics, HEX-CONSUMER-01 completion ceremony

---

## CI timeout & runtime budget

| Option | Description | Selected |
|--------|-------------|----------|
| Keep 180_000 | v2.9 full overlay precedent; ~56s route + ~5–10s for two more smokes in one subprocess | ✓ |
| Bump to 300_000 | Gallery lane precedent; more headroom | |
| Bump to 420_000 | Maximum safety | |
| Per-step Runner timeouts | Pinpoint slow mix step | |

**User's choice:** Research-backed recommendation — keep 180_000; escalate to 240_000 only after documented CI >120s twice (D-34–D-38)
**Notes:** User requested subagent research + ecosystem idioms; rejected per-step timeouts and separate ExUnit cases per overlay.

---

## Proof step assertions

| Option | Description | Selected |
|--------|-------------|----------|
| Exact ordered list (derived from host.overlay_tests) | install ++ overlay atoms; single SSOT with generator sort | ✓ |
| Hardcoded 7-tuple | Explicit readability; duplicate filenames | |
| Subset / `in` assertions | Looser contract | |
| Separate ExUnit test per overlay | Multiple phx.new hosts | |

**User's choice:** Derived exact `==` (D-32); switch to `run_full_proof!/1` (D-30)
**Notes:** Matches Phase 78 route-only assertion style; closes HEX-CONSUMER-01 overlay depth.

---

## Failure diagnostics

| Option | Description | Selected |
|--------|-------------|----------|
| Enhanced Runner raise only | Always-on triage block | ✓ (layer 1) |
| SCORIA_PRESERVE_HOST=1 | Phoenix autoremove?: false | ✓ (layer 2) |
| tmp/scoria-host-proof-last-failure snapshot | Repo-local CI artifact path | ✓ (layer 3) |
| GHA upload-artifact on failure | CI triage | ✓ (layer 4) |
| Always preserve host | Disk / hygiene risk | |

**User's choice:** Layered P0–P2 stack (D-39–D-44)
**Notes:** Phase 79 adds sandbox/LiveView overlays — preserve + snapshot needed beyond raises alone.

---

## HEX-CONSUMER-01 completion + README

| Option | Description | Selected |
|--------|-------------|----------|
| Same PR: VERIFICATION + REQUIREMENTS + ROADMAP + STATE | Requirement-owning phase ceremony | ✓ |
| VERIFICATION only | Insufficient for milestone flip | |
| README D-24 one-liner in 79 | Adopter trust when tarball merge-blocking | ✓ |
| Defer README to 82 | Lower drift risk | |
| adoption_surface pins in 79 | Early narrative guard | |

**User's choice:** Ceremony bundle D-45–D-48; README one-liner optional not gate; no adoption_surface/ci_policy pins in 79
**Notes:** Fix premature REQUIREMENTS Complete from Phase 78 summaries.

---

## Claude's Discretion

- `Runner.expected_steps/1` helper extraction
- `MANIFEST.txt` field details
- Minimal operator_verification debug paragraph timing

## Deferred Ideas

- Upgrade smoke, registry proof, full doc sweep — Phases 80–82
- Per-overlay ExUnit tests — rejected (one-host-per-run)
