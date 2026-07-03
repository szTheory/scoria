# Phase 39: Component Groups And Operator Flows - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-02
**Phase:** 39-Component Groups And Operator Flows
**Areas discussed:** Page-orientation scaffold, Cross-page scan conventions, Approval drawer decision-first, Decision-history surface, Operator-first microcopy

**Method:** The user asked for all 5 gray areas to be resolved in one shot via deep parallel
research (5 subagents, each covering idiom / lessons-from-other-libs / UI-UX-JTBD / brand / a11y-perf
lenses), grounded in the actual code, `brandbook/brand-book.md`, and `prompts/` research. The user
delegated the decision ("one-shot a perfect set of recommendations so I don't have to think"); each
area's recommendation was adopted as the locked decision. Options below are the alternatives the
research weighed.

---

## Page-orientation scaffold (FLOW-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Thin `page_header/1` + per-page composition + source-scan guard | Promote existing `.scoria-pagehead` convention into one thin component; mirrors Phoenix `<.header>` | ✓ |
| Monolithic `page/1` god-scaffold | One component owns title + data region + empty/loading/error slots | |
| Pure per-page composition + lint guard only | Leave hand-rolled markup, guard only | |

**User's choice:** Thin `page_header/1` (research recommendation).
**Notes:** Finding — a page-head convention already ships as copy-pasted markup; the god-scaffold and CRUD-config scaffolds were rejected as un-idiomatic and as forcing pages to mirror backend structure (the anti-goal). Single-header rule + anti-redundant-header guard fix the `dataset_live` redundancy.

---

## Cross-page scan conventions (FLOW-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Guided convention over locked primitives + drift guard | Documented section order + table/list/board rule + URL-param state; reuse `table`/`empty_state` | ✓ |
| Rigid shared framework (Backpex/LiveAdmin/Kaffy style) | One `scan_page` macro from per-page config | |
| Freeform primitives (current state) | Total per-page flexibility | |

**User's choice:** Guided convention (research recommendation).
**Notes:** Frozen per-page layout map (1 board, 1 list, 4 tables, 1 detail). Highest-leverage fix: move all scan state to URL params (`push_patch`/`handle_params`), migrating `review_queue`'s socket-held filter; adopt `stream/3` for unbounded lists.

---

## Approval drawer decision-first redesign (FLOW-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Decision-first hierarchy + native `<details>` disclosure + copy dedup | Title→badge→consequence→actions→facts→collapsed raw evidence; de-alarm; one status line | ✓ |
| `notebook/1` tabs for payload/metadata/trace | Tabbed evidence, one panel at a time | |
| Bespoke JS disclosure / everything-always-visible | Reinvent `<details>` or keep wall-of-JSON | |

**User's choice:** Decision-first hierarchy + native `<details>` (research recommendation).
**Notes:** De-alarm the uppercase warn banner; `raw_evidence` `open={false}`; delete the bespoke tech-grid; keep the existing two-step confirm modal. Collapse ~6 duplicate decision-copy emissions to one `ApprovalCopy.status_line/1` badge. Native `<details>` chosen partly to minimize Phase-40 a11y debt.

---

## Decision-history surface (FLOW-04)

| Option | Description | Selected |
|--------|-------------|----------|
| `Pending \| Decided` URL segment on `/approvals`, outcome sub-filter, same drawer read-only | One page, one hop, reuse table/badge/drawer | ✓ |
| Separate `/approvals/history` route | Clean separation, extra destination | |
| Inline "recently decided" section under inbox | Zero-nav, doesn't scale, weak discoverability | |

**User's choice:** `Pending | Decided` segment (research recommendation).
**Notes:** Schema is already terminal-complete (`pending/approved/rejected/expired`) — no migration. Provenance lives in the audit outbox. Same `drawer/1` in a `decided?` read-only receipt state = the FLOW-03↔FLOW-04 bridge; not emitting the buttons makes in-place reversal structurally impossible. Decided fixtures needed (Phase 37 lab/seeds); no fabricated history.

---

## Operator-first microcopy (COPY-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid: upgrade `status_label/1` map + narrow `ScoriaWeb.Copy` + per-domain modules only where copy branches | Scale `ApprovalCopy` by justification, not mechanically | ✓ |
| Per-domain copy module for all 7 pages | Clone `ApprovalCopy` ×7 | |
| One shared god copy module | Single 1000-line grab-bag | |
| gettext / message catalog | Idiomatic i18n, but zero usage + single-locale + untestable-as-code | |

**User's choice:** Hybrid, scaled by justification (research recommendation).
**Notes:** Load-bearing framing — operator-first ≠ hiding technical terms (brand audience is Phoenix/SRE engineers; keep real domain nouns, demote only opaque IDs/payloads/raw status/schema names). Fix 5 cited offenders; upgrade `status_label/1` to an explicit label map; add a lightweight `copy_guard_test.exs`.

---

## Claude's Discretion

Exact new function/CSS/module names; toolbar as component vs `table` `:filter` slot; capped-recent vs `stream/3` for decided list; batch-load vs defer decider identity; per-domain copy-module boundaries; test-file placement — bounded by D-01..D-26 and the Coherence Spine.

## Deferred Ideas

Phase 40 (a11y/motion/responsive proof), Phase 41 (hardened guards/docs/screenshots/gap register), in-place approval reversal (forbidden), denormalized `decided_by`/`decided_at`, audit export/retention/diff-history/search, gettext/i18n, PhoenixStorybook, screenshot-diff CI.
