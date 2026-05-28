# Phase 72: Hex Publish Closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 72-hex-publish-closeout
**Areas discussed:** Post-flip README install block, GitHub fallback presentation, Publish job hardening, Post-publish verification surface, Plan wave split, Locked decision audit

---

## Post-flip README install block

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Minimal deps-only (Ecto pattern) | Single deps block, no next steps | |
| (b) Deps + 3-line next steps + Verification link | Hex dep, deps.get → install → migrate, link to mix test.adoption | ✓ |
| (c) Full quickstart inside Install | Duplicate runtime API samples in Install | |

**User's choice:** (b) — research-backed default; user requested one-shot recommendations across all areas.
**Notes:** Preserves szTheory `mix scoria.install` DNA vs pure registry minimalism. Quickstart stays separate per brand book.

---

## GitHub fallback presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Inline commented line in deps block | `# Fork or pinned patch only: {:scoria, github: ...}` | ✓ |
| `### Bleeding edge` subsection | Second heading + second code block | |
| Footnote to operator guide only | No github line in README | |
| `<details>` collapsible block | Secondary path in expandable UI | |

**User's choice:** Inline commented line (D-72-27).
**Notes:** Matches locked D-72-13 intent; Scrypath/szTheory Hex-only primary; avoids co-equal dual-path confusion.

---

## Publish job hardening (GitHub Environment)

| Option | Description | Selected |
|--------|-------------|----------|
| Secrets-only, Release PR = human gate (oarlock/sigra) | No Environment on 0.1.0 | ✓ |
| Environment `hex-publish` + required reviewers (lockspire/mailglass) | Approval after CI green | Deferred post-0.1.0 |
| workflow_dispatch primary | Manual publish path | Rejected (D-72-03) |

**User's choice:** Secrets-only for 0.1.0; document optional Environment in operator guide (D-72-32/33).
**Notes:** Environment does not fix README-before-registry race; triple-gating adds friction on first ship.

---

## Post-publish verification surface

| Option | Description | Selected |
|--------|-------------|----------|
| Expand operator_verification.md only | Evergreen procedure + evidence | |
| 72-VERIFICATION.md ledger only | Phase evidence, no reusable checklist | |
| Both: ledger for proof, thin operator appendix | D-72-20 + D-72-34 | ✓ |

**User's choice:** Both (asymmetric weight).
**Notes:** URLs/SHAs in ledger only; ~15–25 line operator subsection for repeatable registry/docs/deps.get checks.

---

## Plan wave split

| Option | Description | Selected |
|--------|-------------|----------|
| 2-plan | Blockers+publish vs flip+audit | |
| 3-plan | Middle plan bundles merge+publish+verify+flip risk | |
| 4-plan | blockers → publish → flip → audit | ✓ |
| 5-plan | Extra split at merge gate | |

**User's choice:** 4 plans (72-01 through 72-04), matching Phase 71 precedent.
**Notes:** README.md forbidden in 72-01/72-02 files_modified; 72-03 blocked until hex.pm 0.1.0 live.

---

## Locked decision audit

| Option | Description | Selected |
|--------|-------------|----------|
| All D-72-01–21 sound as-is | No revisions | |
| Revise D-72-07 + add D-72-22–25 | Both workflows + contract test co-flips | ✓ |

**User's choice:** Revise D-72-07 (both workflows); add D-72-22–25; extend D-72-06 for docs/0.
**Notes:** No materially wrong locked decisions; gaps were enablement completeness and test suite alignment.

---

## Claude's Discretion

Remaining after update: exact prose polish within D-72-26–31; optional D-72-25 name re-check; badge ordering.

## Deferred Ideas

- GitHub Environment approval on publish — post-0.1.0 optional hardening (documented, not implemented).
- `MAINTAINING.md` extract — only if operator Hex section exceeds ~120 lines.
