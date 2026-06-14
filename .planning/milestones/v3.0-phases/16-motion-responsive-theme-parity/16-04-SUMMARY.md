---
phase: 16-motion-responsive-theme-parity
plan: 04
subsystem: ui/liveview
tags: [responsive, mobile, table, mobile-summary, empty-state, brand-voice, a11y]
requires: ["16-02", "16-03"]
provides: [runs-mobile-summary, review-queue-mobile-summary, connectors-mobile-summary, dataset-mobile-summary]
affects:
  - lib/scoria_web/live/workflow_live/index.ex
  - lib/scoria_web/live/review_queue_live.ex
  - lib/scoria_web/live/connectors_live/index.ex
  - lib/scoria_web/live/dataset_live/index.ex
tech-stack-added: []
tech-stack-patterns: [mobile-summary-slot-adoption, heex-typed-slot-usage, domain-empty-state-copy]
key-files-created: []
key-files-modified:
  - lib/scoria_web/live/workflow_live/index.ex
  - lib/scoria_web/live/review_queue_live.ex
  - lib/scoria_web/live/connectors_live/index.ex
  - lib/scoria_web/live/dataset_live/index.ex
decisions:
  - "connector-fleet scan table gets mobile_summary; dense runtime-presence table left on honest overflow per D-10"
  - "connector meta scalar uses auth_provenance.status (no last_seen_at on connector structs) — most useful auth status scalar available"
  - "review queue mobile_summary uses review_run_path helper to build Open run link, matching the detail-rail CTA"
metrics:
  duration: "~8 min"
  completed: "2026-06-13T07:15:00Z"
  tasks: 2
  files: 4
---

# Phase 16 Plan 04: Mobile Summaries for Scan Tables Summary

`<:mobile_summary>` slot adopted on all four scan-heavy object tables — Runs, Review Queue, Connectors, Dataset Builder — wiring the 16-02 opt-in slot contract into per-domain terse summaries with status badges, one key scalar, and a domain-verb primary action; plus brand-voice domain empty-state headings on all touched screens.

## Tasks Completed

| Task | Description | Commit | Key Files |
|------|-------------|--------|-----------|
| 1 | Mobile summaries for Runs + Review Queue | ff3f960 | lib/scoria_web/live/workflow_live/index.ex, lib/scoria_web/live/review_queue_live.ex |
| 2 | Mobile summaries for Connectors + Dataset Builder | 5005595 | lib/scoria_web/live/connectors_live/index.ex, lib/scoria_web/live/dataset_live/index.ex |

## What Was Built

**`lib/scoria_web/live/workflow_live/index.ex` — Runs table:**
- Added `<:mobile_summary :let={run}>` slot with: run ID in `font-mono`, `<.badge>` carrying tone + `status_label` text (not color alone), `started_at` timestamp scalar, and `Open trace` link to the workflow detail page.
- Updated `<:empty>` heading from `"No runs yet"` to `"No runs match this view"` with brand-voice body `"Adjust your filters or check back when data is available."`.

**`lib/scoria_web/live/review_queue_live.ex` — Review Queue table:**
- Added `<:mobile_summary :let={row}>` slot with: candidate rationale label, `<.badge>` with severity tone + `status_label` text, promotion state scalar via `promotion_label/1`, and `Open run` anchor using `review_run_path/2`.
- Updated `<:empty>` heading from `"No flagged traces for this filter set"` to `"No review candidates match this view"` with brand-voice body.
- Line-74 `scoria-page-split` class from plan 16-03 preserved unchanged.

**`lib/scoria_web/live/connectors_live/index.ex` — Connector fleet scan table:**
- Added `<:mobile_summary :let={connector}>` slot on the `connector-fleet` table only: connector label in `font-semibold`, `<.badge>` with health_state tone + text, auth provenance status scalar, and `Inspect connector` button via `phx-click="open_connector_drawer"`.
- Updated connector-fleet `<:empty>` heading from `"No connectors registered"` to `"No connectors match this view"` with brand-voice body.
- Dense `runtime-presence` table left on honest overflow (no mobile_summary) per D-10.

**`lib/scoria_web/live/dataset_live/index.ex` — Dataset Builder table:**
- Added `<:mobile_summary :let={dataset}>` slot with: dataset name + version (mono), `<.badge>` with state tone + `state_label` text, item count scalar, and `Open dataset` link via `patch=`.
- Updated `<:empty>` heading from `"No datasets yet"` to `"No datasets match this view"` with brand-voice body.

All status badges use `<.badge tone={...} label={...}>` pattern — tone + visible text, never color alone (D-24). All new copy follows D-35 brand voice: calm, exact, useful, operator evidence verbs (`Open trace`, `Open run`, `Inspect connector`, `Open dataset`), no hype or decorative-motion language. No raw palette colors introduced (DS-06).

## Acceptance Criteria Verification

- [x] `workflow_live/index.ex` uses `mobile_summary` slot with `Open trace` action
- [x] `review_queue_live.ex` uses `mobile_summary` slot with `Open run` action
- [x] `connectors_live/index.ex` uses `mobile_summary` slot (connector-fleet only) with `Inspect connector` action
- [x] `dataset_live/index.ex` uses `mobile_summary` slot with `Open dataset` action
- [x] Each summary status uses `<.badge>` with tone + visible label text
- [x] `workflow_live/index.ex` `<:empty>` heading is `No runs match this view`
- [x] `review_queue_live.ex` `<:empty>` heading is `No review candidates match this view`
- [x] `connectors_live/index.ex` `<:empty>` heading is `No connectors match this view`
- [x] `dataset_live/index.ex` `<:empty>` heading is `No datasets match this view`
- [x] `mix compile --warnings-as-errors` clean
- [x] `mix test test/scoria_web/ds06_drift_guard_test.exs` — 3 tests, 0 failures

## Deviations from Plan

**1. [Rule 1 - Deviation] Connector meta scalar: auth_provenance.status used instead of last_seen_at**
- **Found during:** Task 2 — Connector struct fields analysis
- **Issue:** Connector structs from `OperatorSurface.connector_fleet/1` have no `last_seen_at` field (that field exists on runtime structs, not connector structs).
- **Fix:** Used `connector.auth_provenance.status` as the key scalar — it is the most informative single field available on connector rows and already rendered in the desktop `:col` definitions.
- **Files modified:** lib/scoria_web/live/connectors_live/index.ex

## Threat Flags

No new attack surface. All mobile summary content is rendered via HEEx interpolation inside `<:mobile_summary>` slots — auto-escaping applies; no `Phoenix.HTML.raw` used. No new routes, auth paths, or data flows introduced. T-16-03 mitigated.

## Known Stubs

None. All mobile summaries render real row data from the same assigns already used by the desktop `:col` definitions. Empty-state copy is static brand-voice text. No hardcoded placeholders.

## Self-Check: PASSED

Files confirmed:
- `lib/scoria_web/live/workflow_live/index.ex` — contains `mobile_summary`, `No runs match this view`, `Open trace`
- `lib/scoria_web/live/review_queue_live.ex` — contains `mobile_summary`, `No review candidates match this view`, `Open run`
- `lib/scoria_web/live/connectors_live/index.ex` — contains `mobile_summary`, `No connectors match this view`, `Inspect connector`
- `lib/scoria_web/live/dataset_live/index.ex` — contains `mobile_summary`, `No datasets match this view`, `Open dataset`

Commits confirmed:
- `ff3f960` — feat(16-04): mobile summaries and domain empty-state copy for Runs + Review Queue
- `5005595` — feat(16-04): mobile summaries and domain empty-state copy for Connectors + Dataset Builder
