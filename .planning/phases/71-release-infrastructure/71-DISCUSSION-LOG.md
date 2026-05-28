# Phase 71: Release Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 71-Release Infrastructure
**Areas discussed:** CHANGELOG narrative, Publish CI topology, release-please bootstrap, Gate-zero attestation, Maintainer runbook

---

## CHANGELOG [0.1.0] narrative

| Option | Description | Selected |
|--------|-------------|----------|
| Capability-only `### Added` | Five README nouns + maintainer CI bullet | ✓ |
| Milestone tranche `#### v2.x` headers in Added | Full ROADMAP mapping in consumer section | |
| Hybrid: capability Added + Roadmap traceability | Adopter story + maintainer table v2.1–v2.6 | ✓ (overall) |
| release-please commit dump for 0.1.0 | Oarlock first-ship automation | |
| Preamble-only + link to MILESTONES.md | Minimal | |

**User's choice:** Hybrid capability Added + Roadmap traceability; szTheory preamble; hand-written 0.1.0; no `### Summary`.
**Notes:** Research compared Oban/Phoenix/Keep a Changelog patterns; Phase 70 D-08 locks preamble here not README.

---

## Publish workflow CI topology

| Option | Description | Selected |
|--------|-------------|----------|
| Inline duplicate in release-please.yml | Copy policy+test steps | |
| `workflow_call` ci-verify.yml | Single SSOT; ci.yml + release workflows use it | ✓ |
| Composite action | Poor fit for two jobs + Postgres | |
| Gate on ci.yml green only | lattice_stripe pattern; lighter publish | |

**User's choice:** Reusable `ci-verify.yml`; extend ci triggers for release-please branches; extend ci_policy_contract_test.
**Notes:** Scoria CI-03 investment requires topology parity, not oarlock minimal `mix test`.

---

## release-please bootstrap

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest 0.0.0 + release-as 0.1.0 | oarlock/bootstrap gotchas | ✓ |
| Manifest 0.1.0 | Skips real first release | |
| bump-minor-pre-major true | sigra style | |
| bump-minor-pre-major false + bump-patch-for-minor-pre-major true | oarlock 0.x | ✓ |
| Remove release-as in Phase 71 | | |
| Remove release-as after Phase 72 publish | | ✓ |

**User's choice:** Full oarlock bootstrap + Scoria full CI verify; workflow permissions API; .tool-versions OTP 27 / Elixir 1.19; no sync_release_summary.
**Notes:** Phase 71 verifies Release PR opens at 0.1.0; merge deferred to Phase 72.

---

## Gate-zero remote CI attestation

| Option | Description | Selected |
|--------|-------------|----------|
| Block Phase 71 until origin/main green | Push 212 commits first | |
| Integration PR attestation + 71-VERIFICATION.md | Record URL/SHA on existing ci.yml | ✓ (preferred) |
| Explicit waiver with bounded defer to Phase 72 | If push/CI blocked | ✓ (fallback) |

**User's choice:** Staged hybrid — do not block prep on stale origin/main; prefer PR attestation; waiver only if blocked.
**Notes:** v2.6 audit passed locally; 69-02-04 carryover.

---

## Maintainer runbook & recovery

| Option | Description | Selected |
|--------|-------------|----------|
| operator_verification.md section only | Phase 70 SSOT pattern | ✓ |
| Dedicated RELEASE.md / MAINTAINING.md | sigra-scale split | |
| docs/hex_publish.md | Third SSOT | |
| Hybrid: operator section + README tease + YAML headers | | ✓ |

**User's choice:** "Hex release & recovery (maintainers)" after CI gate map; repo HEX_API_KEY; hex-publish workflow_dispatch recovery documented.
**Notes:** Default path Release Please; recovery when version not on Hex.

---

## Claude's Discretion

- publish-hex dry-run vs stub in Phase 71
- Optional CHANGELOG contract test
- bootstrap-release-pr-ci job if needed
- 69-VERIFICATION.md backfill vs contract test path fix

## Deferred Ideas

- README Hex flip, package_surface_test, actual hex.publish — Phase 72
- release-as pin removal — Phase 72 post-publish
