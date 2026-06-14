---
status: complete
phase: 13-orientation-spine-ia
source: [13-01-SUMMARY.md, 13-02-SUMMARY.md, 13-03-SUMMARY.md, 13-04-SUMMARY.md, 13-05-SUMMARY.md, 13-06-SUMMARY.md, 13-07-SUMMARY.md, 13-08-SUMMARY.md]
started: 2026-06-13T19:05:02Z
updated: 2026-06-14T00:00:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

<!--
Verification is now automation-backed (0 human UAT required going forward):
- ExUnit LiveView suite covers every affordance (workflow_live_test, incidents_live_test,
  review_queue_live_test, prompt_live/release_workbench_live_test, dataset_live/promote_component_test,
  eval_spec_live/index_test, orchestrator_live_test).
- Browser e2e: priv/dev/e2e/command_palette.spec.mjs (Tests 4/5) and the new
  priv/dev/e2e/ia_orientation.spec.mjs (Tests 1,7,8,9,10,11 — seeded ingress/egress click-path at
  the bare URL, guarding the dev_router tenant default + dev_seed). Both run in CI via
  `mix scoria.ui.e2e`, gated by ci-gate on every PR/main.
-->


## Tests

### 1. Dashboard Home loads and orients
expected: Visit /scoria. Title is "Home", identity line shows, attention cards appear only for nonzero actionable counts (else all-clear copy), and the live trace stream renders (or day-zero empty state).
result: pass
note: User confirmed Home title, identity line, "Nothing needs attention. 0 approvals pending, 0 open incidents." all-clear copy, and day-zero trace empty state. Separately flagged a theme FOUC (dark flash before light) + request for a dark/light/system picker — captured as deferred todo .planning/todos/pending/theme-fouc-system-picker.md (not a Test 1 failure).

### 2. Three-group sidebar navigation
expected: Sidebar is grouped into Operate / Improve / Configure. "Home" is present (was "Live Ops"). "Connectors" appears exactly once, under Configure.
result: pass

### 3. Reserved-capability "Soon" stubs
expected: Five nav items show a "Soon" badge. Clicking one opens an honest coming-soon page with future-tense copy and "What works today" links — no fake data or fabricated numbers. An unknown stub URL shows a generic not-found page without echoing the raw slug.
result: pass

### 4. Command palette (Ctrl/Cmd+K)
expected: Press Ctrl/Cmd+K — a command palette opens with the search input focused. Typing filters rows live (no page reload/network round-trip). Arrow keys move selection, Enter navigates to the chosen destination, Escape closes it and restores focus to where you were.
result: pass

### 5. Keyboard shortcuts overlay and g-chords
expected: Press "?" — a keyboard shortcuts overlay opens (and traps focus). Pressing a g-chord (e.g. g then h) navigates to the locked destination. Shortcuts are ignored while typing in an input.
result: pass

### 6. Object headers on run and prompt pages
expected: Open a workflow run page and a prompt release page. Each shows a shared object header with a breadcrumb, a status pill, and a copyable object ID displayed middle-truncated (prefix...suffix) while copying the full ID.
result: pass

### 7. Return context chip from origin
expected: Reach an object page by following a link from another object (e.g. "Open run" from an incident). A return chip back to the origin appears on the destination header. Arriving with no/unknown origin shows no chip and no error.
result: pass

### 8. Replay provenance line
expected: On a run that was replayed, the header shows a provenance line like "Replayed from run ... via checkpoint ... - {date}".
result: pass
note: User confirmed in browser. Now also automated — priv/dev/e2e/ia_orientation.spec.mjs "Replay run renders the provenance strip" + ExUnit workflow_live_test.exs replay-provenance test.

### 9. Incident ingress threading
expected: On an incident that has an associated run, "Open run" and "Open trace at failing span" links appear and carry you into the run/trace evidence (with return context).
result: pass
note: Covered by automation — ia_orientation.spec.mjs "Incident ingress → Open run → return chip" (real-browser, seeded) + ExUnit incidents_live_test.exs "selected incident renders context-preserving run and trace next-step links".

### 10. Review queue threading
expected: A review-queue item's detail shows "Open run" (not "Open workflow") and the promotion verb (rendered as "Promote in Dataset Builder"). Following "Open run" carries from=review context.
result: pass
note: Covered by automation — ia_orientation.spec.mjs "Review queue ingress renders Open run + promote verb" + ExUnit review_queue_live_test.exs deep-links test (asserts "Open run", not "Open workflow", from=review).

### 11. Quality-loop egress verbs
expected: Run page shows next-step verbs (Replay run, Promote in Dataset Builder, and Open incident / Open prompt when backed by data). Prompt release shows "View eval results" / "View baseline runs". Dataset rows show "Open source run". Eval results show "Open prompt release" / "Open regressed runs". Verbs only appear when real records back them.
result: pass
note: Covered by automation — ia_orientation.spec.mjs (run egress verbs; eval→prompt-release→eval/baseline links) + ExUnit workflow_live_test.exs / release_workbench_live_test.exs / promote_component_test.exs / eval_spec_live/index_test.exs.

## Summary

total: 11
passed: 11
issues: 0
pending: 0
skipped: 0
blocked: 0

## Verification mode

Tests 1–8 confirmed interactively during this session; Tests 7–11 are now also (or solely)
backed by automation so no human UAT is required going forward:
- **ExUnit LiveView suite** covers every affordance at the server-render level.
- **Browser e2e** (`priv/dev/e2e/ia_orientation.spec.mjs` + `command_palette.spec.mjs`) drives the
  seeded ingress/egress click-path through the real LiveView socket at the bare URL, guarding the
  dev_router tenant default + `dev_seed.exs`. Runs in CI via `mix scoria.ui.e2e`, gated by ci-gate.

## Gaps

[none yet]
