# Phase 82: Docs truth + milestone closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 82-docs-truth-milestone-closeout
**Areas discussed:** Doc surface allocation, Drift guard home, adoption_surface_test pin scope, Milestone closeout ceremony

**User directive:** Discuss all four gray areas with subagent research; one-shot cohesive recommendations aligned to project vision, Elixir ecosystem idioms, szTheory DNA, and phoenix-ai-lib OSS trust patterns — user delegates all decisions.

---

## Doc surface allocation

| Option | Description | Selected |
|--------|-------------|----------|
| Full three-layer narrative in README | Adopters see PR tarball vs release registry table in README Verification | |
| Three-tier model (README + adoption_lanes adopter; operator maintainer) | Short adopter tarball sentence; full gate map in operator_verification only | ✓ |
| Split everything into HexDocs only | Move all CI topology off repo docs | |
| Duplicate operator table in adoption_lanes | Full PR vs release table in lane guide | |

**User's choice:** Research-backed one-shot — three-tier model (D-90–D-94)
**Notes:** Matches Oban/Req/Ecto README brevity; szTheory operator-first without adopter runbook noise; Phase 79–81 minimal prose stays; Phase 82 completes operator narrative only.

---

## Drift guard home

| Option | Description | Selected |
|--------|-------------|----------|
| Merge HexConsumerContract into AdopterDocContract | Single doc SSOT module | |
| Test-only inline pins (no lib helpers) | All anchors hardcoded in test files | |
| Hybrid trilogy + adopter_doc_surfaces/0 | HexConsumerContract mechanics + AdopterDocContract policy + VerificationLanes commands; SupportJourney-style surface map; ci_policy_contract for YAML | ✓ |
| New HexDocContract module | Third parallel contract module | |

**User's choice:** Hybrid trilogy + `adopter_doc_surfaces/0` (D-95–D-100)
**Notes:** Preserves 78 D-05 separation; SupportJourney macro pattern is established in-repo; ci_policy_contract owns workflow filenames per 81 discretion.

---

## adoption_surface_test pin scope

| Option | Description | Selected |
|--------|-------------|----------|
| Pin full operator gate map table in adoption_surface_test | Same anchors as ci_policy_contract in adopter test suite | |
| Minimal adopter anchor set (5 items) | README tarball vocab, adoption_lanes tarball note, operator link, AdopterDocContract refutes; gate map in ci_policy only | ✓ |
| Pin every HexConsumerContract function name across all docs | Maximum coverage, high brittleness | |
| Defer all pins to hex_consumer_contract_test only | Unit tests only, no cross-doc guards | |

**User's choice:** Minimal adopter anchor set (D-101–D-103)
**Notes:** ROADMAP criterion #3 requires adoption_surface_test guards — scoped to adopter surfaces only; post-publish command refute-only in README.

---

## Milestone closeout ceremony

| Option | Description | Selected |
|--------|-------------|----------|
| Audit file only | 82-VERIFICATION.md without archive or phase move | |
| Full closeout: DOCS-HEX-01 + audit + complete-milestone + v2.10-phases move | Three-plan wave 82-01/02/03; Nyquist documented not retroactive | ✓ |
| Retroactive Nyquist for phases 78–81 before archive | v2.5-level validation ceremony | |
| v2.9-style delete phase dirs without archive folder | Smallest disk footprint | |

**User's choice:** Full closeout three-plan wave (D-107–D-112)
**Notes:** Fixes REQUIREMENTS.md premature DOCS-HEX-01 Complete; v2.10-phases move follows v2.5 not v2.9 deletion pattern.

---

## Claude's Discretion

User explicitly requested one-shot perfect recommendations — all gray areas resolved via research synthesis without per-question interactive turns. Discretion items listed in CONTEXT.md D-116 block (fragment strings, test consolidation, audit score thresholds).

---

## Deferred Ideas

- Cross-minor registry upgrade docs
- Retroactive Nyquist 78–81
- Advisory hex_consumer lane
- Live Hex in PR CI
- Full handoff on registry path
