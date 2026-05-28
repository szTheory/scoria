# Phase 69: CI Trust And Milestone Closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 69-ci-trust-and-milestone-closeout
**Areas discussed:** CI-03 documentation bundle, REQUIREMENTS language, milestone audit depth, optional CI hygiene, milestone ship ceremony (all five gray areas, user-requested full research pass)

---

## CI-03 documentation bundle

| Option | Description | Selected |
|--------|-------------|----------|
| Inline ci.yml comments only | Co-located truth; no adopter-facing doc | Partial (D-03) |
| Dedicated docs/ci.md | Full maintainer CI reference | |
| README CI encyclopedia | Landing-page discoverability | |
| Extend operator_verification + minimal ci.yml + README link | Thin prose, fat executable contract | ✓ (D-01–D-07) |
| Executable-only (no prose) | Zero drift | Rejected |

**User's choice:** Subagent synthesis + user “create context” — adopt “thin prose map + fat executable contract” without further prompts.

**Notes:** WARN-06 doc anchor pattern in `ci_policy_contract_test` is precedent for optional CI gate map anchor.

---

## REQUIREMENTS / PROJECT language

| Option | Description | Selected |
|--------|-------------|----------|
| A — Rewrite CI-03 (policy + full WAE, drop “staged”) | Matches Phase 68 shipped CI | ✓ (D-08–D-10) |
| B — Keep “staged” = policy prelude | Technically accurate but confuses post-68 readers | |
| C — Split CI-03a/CI-03b | High audit granularity, overlaps WARN-* | |

**User's choice:** Option A — locked CI-03 wording in CONTEXT D-08.

**Notes:** ROADMAP Phase 69 goal and PROJECT milestone bullets still say “staged ratchet” until Phase 69 sync tasks run.

---

## Milestone audit depth

| Option | Description | Selected |
|--------|-------------|----------|
| Full v2.5 audit | Integration checker, E2E flow matrix, Nyquist deep dive | |
| Light traceability only | Checkbox + links | |
| Medium CI-attested audit | VERIFICATION rollup + CI contract section + audit-time commands | ✓ (D-11–D-15) |

**User's choice:** Medium audit; skip integration checker unless new coupling added.

---

## Optional CI hygiene

| Option | Description | Selected |
|--------|-------------|----------|
| Inventory JSON CI diff | clusters must stay {} | Deferred v2.7 (D-16) |
| knowledge WAE in CI | Optional lane strictness | Deferred v2.7 (D-17) |
| WR-01 / WR-02 ratchet hygiene | Maintainer tmp + integration test | ✓ Phase 69 (D-18) |
| Docs-only Phase 69 | CI-03 + traceability | ✓ core (69-00, 69-02) |

**User's choice:** Docs-first + WR hygiene; no new CI gates.

---

## Milestone ship ceremony

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal checkbox | ROADMAP + PROJECT flip only | Rejected |
| Full v2.5-style archive | Audit → complete-milestone → thread → tag | ✓ (D-20–D-23) |

**User's choice:** Audit before PROJECT v2.7 flip; complete-milestone after 69-VERIFICATION passed.

---

## Claude's Discretion

- Anchor test string and plan split 69-00 vs 69-01 for WR fixes
- Whether complete-milestone runs in same session as 69-02

## Deferred Ideas

- See CONTEXT.md `<deferred>` — v2.7 CI hygiene, Hex/docs, adoption discoverability drift
