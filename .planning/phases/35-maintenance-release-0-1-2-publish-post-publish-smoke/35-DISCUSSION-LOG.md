# Phase 35: Maintenance release — 0.1.2 publish + post-publish smoke - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 35-Maintenance release — 0.1.2 publish + post-publish smoke
**Areas discussed:** Todo cross-reference, registry version path, Release PR CI repair, pre-merge verification, post-publish recovery, brand and UX applicability

---

## Todo Cross-reference

| Option | Description | Selected |
|--------|-------------|----------|
| Fold release-critical todos only | Fold only pending todos that directly block the `0.1.2` release. | |
| Fold all adjacent todos | Use the release phase to sweep nearby CI/Docker/UI cleanup. | |
| Fold none after review | Review pending todos, record disposition, and keep Phase 35 release-scoped. | ✓ |

**User's choice:** User said they followed recommendations and asked for a one-shot cohesive recommendation set.
**Notes:** Reviewed `ci-policy-job-cache-key-mislabel`, `docker-dx-fleet-hardening`, and `2026-06-18-make-approval-toasts-legible`. None should fold into Phase 35.

---

## Registry Version Path

| Option | Description | Selected |
|--------|-------------|----------|
| Publish `0.1.2` directly with previous-live-release upgrade smoke | Keep PR #3 as the release vehicle and prove `0.1.0 -> 0.1.2`, matching actual Hex state. | ✓ |
| Publish `0.1.2` and skip upgrade leg | Avoid missing `0.1.1`, but weaken REL-02 to fresh install only. | |
| Publish/restore `0.1.1` first | Create contiguous patch history, but risk wrong artifact/tag/manifest drift. | |
| Retarget Phase 35 to `0.1.1` | Avoid skipped patch semantics, but contradict the phase, requirements, and open PR. | |

**User's choice:** Delegated to recommendations.
**Notes:** Subagent research recommended direct `0.1.2` publish with registry lineage semantics. Hex live state on 2026-06-18 was `0.1.0` only. SemVer does not require contiguous patch publication, and Hex public package artifacts are durable enough that backfilling is riskier than encoding actual lineage.

---

## Release PR CI Repair

| Option | Description | Selected |
|--------|-------------|----------|
| Candidate-version README fallback | Make README fallback tag track `mix.exs` after Release Please bumps it. | |
| Latest-stable fallback | Keep README fallback pointing only at an already-published tag. | |
| Less version-coupled fallback contract | Keep Hex install as the active dep and test fallback shape without tying it to the release-candidate version. | ✓ |
| One-off manual PR patch | Patch PR #3 by hand to get this release out. | |

**User's choice:** Delegated to recommendations.
**Notes:** The current failure is a contract mismatch: Release Please bumps `mix.exs` to `0.1.2`, but the README commented fallback still references `v0.1.1`. The selected path preserves adopter ergonomics and avoids README churn or unpublished tag guidance.

---

## Pre-merge Verification

| Option | Description | Selected |
|--------|-------------|----------|
| Local full `mix ci` | Highest local confidence, but heavier and environment-sensitive. | |
| Local focused release/package gate | Fast proof of docs/package/contract surfaces, but not enough alone. | |
| Remote CI only plus local docs check | Low local friction, but too dependent on stale/skipped remote semantics. | |
| Staged verification | Local release proof plus latest-SHA remote `ci-gate`, publish workflow, and post-publish smoke. | ✓ |

**User's choice:** Delegated to recommendations.
**Notes:** Use `mix docs --warnings-as-errors`, `mix scoria.release_preview`, focused tests, latest-SHA `CI / ci-gate`, live Hex lookup, and post-publish smoke. Run full `mix ci` only if Phase 35 expands into runtime/DB/installer changes.

---

## Post-publish Recovery

| Option | Description | Selected |
|--------|-------------|----------|
| Rerun post-publish smoke only | Minimal blast radius when `0.1.2` is visible and the failure is transient. | ✓ |
| Run `hex-publish.yml` manual recovery | Use when publish completion is uncertain or the version is not visible. | ✓ |
| Stop, investigate, hold announcement | Use when exact install or upgrade fails against a visible release. | ✓ |
| Revert/retire and ship patch | Use only for confirmed bad artifact/security/invalid published content. | ✓ |

**User's choice:** Delegated to recommendations.
**Notes:** These options are a decision tree, not mutually exclusive preferences. The governing policy is classify state first and minimize Hex mutation.

---

## Brand and UX Applicability

| Option | Description | Selected |
|--------|-------------|----------|
| Include UI/visual design work | Treat release phase as an opportunity for UI polish. | |
| Apply brand only to release-facing text | Use brandbook voice for docs, release notes, failure text, and maintainer commands. | ✓ |
| Ignore brand prompts | Treat this as purely mechanical release work. | |

**User's choice:** User asked to consider UI/UX where applicable.
**Notes:** No product UI work is applicable. Brandbook guidance is applicable to release communication and DX: calm, exact, useful; no hype; evidence-first commands and failure messages.

## Claude's Discretion

- User explicitly delegated the final recommendation set.
- Exact helper/test names may be refined during planning.
- The representation of previous-live registry lineage may be a table, helper, or equivalent deterministic code pattern.

## Deferred Ideas

- `ci-policy-job-cache-key-mislabel` remains post-ship CI cleanup.
- `docker-dx-fleet-hardening` remains sibling-repo fleet convergence.
- `make-approval-toasts-legible` remains UI polish.
- Backfilling `0.1.1` is rejected for Phase 35.
- Release Please arbitrary README updates are rejected for this release.
