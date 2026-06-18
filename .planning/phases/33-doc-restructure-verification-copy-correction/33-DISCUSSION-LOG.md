# Phase 33: Doc restructure + verification-copy correction - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 33-doc-restructure-verification-copy-correction
**Areas discussed:** Document IA and emphasis, Verification-copy sweep boundary, Replacement wording pattern, Adjacent docs outside named grep set, Prompt/brand/voice synthesis

---

## Document IA and emphasis

| Option | Description | Selected |
|--------|-------------|----------|
| Guided reference narrative | Persona/JTBD -> TL;DR -> mental model -> standalone task sections -> appendix. Best fit for top-to-bottom read while keeping commands fast to find. | yes |
| Task-card runbook | Start/inspect/debug/clean/secure cards. Very scannable, but weaker at teaching the invariant. | |
| Architecture-first standard | Invariants before commands. Strong portable spec, but slower first success. | |
| Troubleshooting-first manual | Symptoms -> diagnosis -> fix. Good for stale-instance incidents, but too failure-heavy as the whole IA. | |

**User's choice:** User selected all areas and requested subagent-backed one-shot recommendations.
**Notes:** Recommendation locks guided reference narrative, with troubleshooting and stale-instance hygiene as a first-class section, not the whole doc.

---

## Verification-copy sweep boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Active/current sweep only | Fix current docs/planning instructions, preserve archives. Needs path-aware verification. | |
| Blanket `.planning` rewrite | Produces simple zero-hit grep, but mutates historical records and audit evidence. | |
| Hybrid active sweep + archive allowlist inventory | Fix active instructions, preserve archived history, and make exclusions explicit for future guards. | yes |

**User's choice:** User selected all areas and delegated final recommendation.
**Notes:** Recommendation preserves `.planning/milestones/**` and old audit artifacts. Current active planning instructions and handoff notes are fair game.

---

## Replacement wording pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Docker-first | Best for Scoria repo dashboard and multi-repo fleet JTBD. Wrong if blindly applied to native harness or separate example app. | |
| Native-first | Best for host Mix iteration, screenshots, and Playwright. Weaker as the fleet default. | |
| Context-specific Docker/native wording | Docker-first for Scoria dashboard, native-first for host harnesses, qualified exceptions for separate example apps. | yes |

**User's choice:** User selected all areas and delegated final recommendation.
**Notes:** Recommendation locks context-specific wording with canonical snippets for README/general docs, operator docs, maintainer screenshots/e2e, and GSD prose.

---

## Adjacent docs outside named grep set

| Option | Description | Selected |
|--------|-------------|----------|
| Named grep set only | Lowest scope, but leaves known docs drift in `docs/uat_automation.md` and less explicit gallery copy. | |
| Include `docs/uat_automation.md`; clarify `docs/support_copilot_gallery.md` narrowly | Fixes Phase 29 deferred docs drift while preserving gallery-app startup truth. | yes |
| Include all adjacent docs plus example app README/seeds/mix-task docs | Max consistency, but may over-edit unless code-adjacent dev-harness copy is treated as Phase 33 scope. | partial |

**User's choice:** User selected all areas and delegated final recommendation.
**Notes:** Recommendation includes `docs/uat_automation.md`, qualifies `docs/support_copilot_gallery.md`, and includes user-facing dev-harness task docs/defaults because Phase 29 explicitly deferred them to Phase 33. Generated assets and Docker internals remain untouched.

---

## Prompt/brand/voice synthesis

| Option | Description | Selected |
|--------|-------------|----------|
| Brandbook canonical | Use `brandbook/` for current voice, microcopy, docs and accessibility rules. Treat prompts as supporting DNA. | yes |
| Prompt-era brand research canonical | Use older prompt research as the main voice authority. Useful but superseded by the shipped brandbook. | |
| Generic developer docs style | Use external style guides only. Helpful as backup, but less specific than Scoria's own voice. | |

**User's choice:** User asked to consider prompts where applicable and prefer newer brandbook over old prompt info.
**Notes:** Recommendation locks `brandbook/brand-book.md` as canonical: calm, exact, useful; copy-pasteable commands; no hype; meaningful links; no color-only status if rendered docs are touched.

---

## Claude's Discretion

- Exact wording, section titles, and command comments are left to implementation as long as the locked decisions in CONTEXT.md hold.
- Planner may split the doc rewrite and copy sweep into multiple plans if needed.
- Planner may choose the precise tests from the recommended verification set based on files touched.

## Deferred Ideas

- Phase 34 drift-guard tests.
- Sibling-repo fleet convergence.
- Fleet-wide nuke target.
- Release publish and post-publish smoke.
- CI cache-key mislabel cleanup.
