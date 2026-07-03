# Deferred Items — Phase 39 (component-groups-and-operator-flows)

Logged during Plan 39-08 execution per the executor's scope-boundary rule
(out-of-scope discoveries are logged, not fixed).

## Pre-existing `mix scoria.ui.e2e` failures (unrelated to Phase 39)

Discovered while running the full e2e suite to verify Plan 39-08's new
Phase-39 flow-proof specs. Confirmed via `git log` that neither file was
touched by any Phase 39 plan (last touches: Phase 16 and Phase 33) — these
predate this phase and are out of Plan 39-08's declared scope
(`priv/dev/e2e/ia_orientation.spec.mjs` only).

| Test | File | Symptom | Status |
|------|------|---------|--------|
| `Phase 16 — MOTION-04: theme-toggle smoke › Home/shell: theme toggle flips data-theme and page stays ready` | `priv/dev/e2e/phase16_parity.spec.mjs:506` | `#scoria-theme-toggle, #scoria-theme-toggle-mobile` locator resolves to the mobile toggle but it never becomes visible/stable at the Playwright config's default viewport — click times out after 30s | Deferred |
| `Phase 16 — MOTION-04: theme-toggle smoke › Workflows table screen: theme toggle flips and page stays ready` | `priv/dev/e2e/phase16_parity.spec.mjs:529` | Same symptom as above | Deferred |
| `Phase 16 — MOTION-04: theme-toggle smoke › Workflow detail (evidence screen): theme toggle flips and page stays ready` | `priv/dev/e2e/phase16_parity.spec.mjs:547` | Same symptom as above | Deferred |

These 3 failures are consistent and reproducible across multiple full-suite
runs during this plan's execution, independent of the Phase 39 changes. A
`command_palette.spec.mjs` keyboard-shortcuts-overlay test also failed
intermittently in one run and passed cleanly in a re-run — flaky, not
investigated further (also untouched by any Phase 39 plan).

All 12 new Phase-39 flow-proof specs (`ia_orientation.spec.mjs` — FLOW-01
one-header-per-page ×9, FLOW-03 decision-first drawer, FLOW-04 Pending|Decided
scope + decided receipt + `?approval=<id>` deep-link) pass green, along with
the 1 pre-existing `ia_orientation.spec.mjs` test fixed in-scope during this
plan (see SUMMARY.md deviations).

## Pre-existing `mix test --warnings-as-errors` failures (unrelated to Phase 39)

Discovered while running the full ExUnit suite per Plan 39-08's verification
step. Confirmed via `git log` that none of these files were touched by any
Phase 39 plan (last touches predate this phase). Both `mix test` runs before
and after this plan's changes show the identical failure set on these two
files — the plan's own changes introduce zero new failures here.

| Test | File | Symptom | Status |
|------|------|---------|--------|
| `planning ledgers reflect shipped hex consumer and connector milestones` | `test/scoria/ci_policy_contract_test.exs` | Asserts `.planning/ROADMAP.md` contains the string `"v2.15"` (historical milestone reference); current `ROADMAP.md` only carries v3.3-era content — a docs-content drift from an earlier, unrelated `.planning/` cleanup pass, not a Phase 39 change | Deferred |
| `optimized compile-only capture catches high-signal unclassified warning (injected)` | `test/scoria/warning_inventory/capture_parity_test.exs` | Intermittent: failed once (compile-cache-dependent injected-warning detection), passed cleanly on immediate re-run with no code changes — flaky, not a real regression | Deferred |
| `support copilot gallery proves advisory adoption journey` (and its nested `examples/support_copilot` suite) | `test/scoria/support_copilot_gallery_test.exs` | The nested satellite app's background `Scoria.Workflows.Reconciler` task loses its sandboxed DB connection mid-test (`DBConnection.ConnectionError: owner exited`), causing a cascading HTML-content assertion failure; reproduced identically with no other processes competing for the DB, so this is a pre-existing test-isolation issue in the gallery's own async setup, not a Phase 39 files_modified regression | Deferred |

Both `test/scoria_web/live/incidents_live_test.exs` failures observed mid-plan
(before the test file was updated) were caused by this plan's own Rule 1 fix
(`incident.severity` → `IncidentCopy.severity_label(incident.severity)`) and
were fixed in-scope, not deferred — see SUMMARY.md.
