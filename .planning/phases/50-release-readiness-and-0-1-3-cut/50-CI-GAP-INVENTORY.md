# Phase 50 — CI Gap Inventory (REL-04 blocker)

**Captured:** 2026-07-11 during `/gsd-execute-phase 50`, after Wave 1 (REL-01/02/03) landed and the v3.5 milestone was pushed to `origin/main` (`2b0fa962..8f1c8d18`, 163 commits).

## Summary

Wave 1 succeeded and is green (REL-01 policy 58/0, REL-02 e2e 165/0, REL-03 docs release-preview clean). REL-04 (green release PR → `0.1.3` cut) is **blocked**: once the v3.5 work reached CI for the first time, the refreshed PR #12 (`chore(main): release 0.1.3`, head `0e54b551`) surfaced **~30 pre-existing test failures** across the `verify` lanes.

**Root cause:** the entire v3.5 milestone (Phases 46–49 — terminology migration, README/scope doctrine, ExDoc/guide-ladder restructure, AI-accessible docs) was committed **local-only and never ran through CI**. Failures accumulated (chiefly from the docs/guide restructure moving content out of `docs/*.md` into `guides/`) and were invisible until the push triggered CI. These are **not** introduced by Phase 50; they are Phase 46–49 verification debt exposed by the release. Phase 50's RESEARCH correctly scoped only the policy + e2e failures because the *original* PR #12 was built on the v3.4 base and genuinely only had those.

**Gate behavior:** `ci-gate` went RED → `Release PR Auto-Merge` did not fire → **nothing merged or published** (no `v0.1.3` tag, no Hex release). PR #12 remains OPEN + MERGEABLE.

## Per-lane failure counts (PR #12 head `0e54b551`, run 29137880790)

| Lane | Result |
|------|--------|
| `verify / test` | 70 tests, 4 failures |
| `verify / full-suite (1/4)` | 252 tests, 1 failure |
| `verify / full-suite (2/4)` | 388 tests, 4 failures |
| `verify / full-suite (3/4)` | 196 tests, 17 failures |
| `verify / full-suite (4/4)` | 289 tests, 8 failures |
| `verify / connector` | 8 tests, 5 failures |
| `verify / verify-summary` | fail (aggregates above) |
| `ci-gate` | fail (aggregates verify) |

`policy` and `e2e` lanes are GREEN (fixed by 50-01 / 50-02).

## Located failures (default `mix test` lane, reproduced locally)

Grouped by apparent root cause to seed gap planning. Locations are `file:line`.

### Bucket A — docs-source alignment (stale `docs/*.md` stub paths after Phase-48 restructure)
The `*_example_source_test.exs` / `support_journey_source_test.exs` tests read old `docs/*.md` paths that Phase 48 rewrote into thin compatibility stubs (real content moved to `guides/`). The asserted fragments (`Scoria.identity/1`, `Scoria.start_handoff_run/3`, `use Scoria.SemanticCache.Profile`, SupportJourney SSOT) no longer live at those paths. Likely fix: repoint each test to the canonical `guides/` path (verify the fragment set is present there) — confirm intent before editing.

- `test/scoria/phoenix_example_source_test.exs:8` — PhoenixExampleSourceTest (reads `docs/phoenix_runtime_example.md`)
- `test/scoria/handoff_example_source_test.exs:8` — HandoffExampleSourceTest (reads `docs/bounded_handoffs.md`)
- `test/scoria/semantic_fast_path_example_source_test.exs:6` — SemanticFastPathExampleSourceTest (reads `docs/semantic_fast_path.md`)
- `test/scoria/support_journey_source_test.exs:7` — SupportJourneySourceTest × 4: README.md, `docs/connector_adoption.md`, `docs/operator_verification.md`, `docs/support_copilot_gallery.md`

### Bucket B — package / publish surface
- `test/scoria/package_surface_test.exs:79` — PackageSurfaceTest "project metadata describes one publish surface"

### Bucket C — runtime / LiveView integration & rendered contracts
- `test/scoria/runtime_integration_test.exs:159` — RuntimeIntegrationTest "operator-visible workflow page stays aligned with the public runtime contract" (page renders "Workflow run not found" vs an expected seeded run id)
- `test/scoria_web/live/coming_soon_live_test.exs:60` — ComingSoonLiveTest "allowlisted stubs render honest coming-soon pages"
- `test/scoria_web/components/memory_notebook_component_test.exs:10` — MemoryNotebookComponentTest "retrieval, delegated, and memory adapters use shared notebook primitives"

### Bucket D — UI component / dev-lab contracts
- `test/scoria_web/ui_component_test.exs:286` — UIComponentTest "flush panel gutters use component variables…"
- `test/scoria_web/ui_component_test.exs:1289` — UIComponentTest "table/1 … keep density out of the public API"
- `test/scoria_web/dev_lab_boundary_test.exs:161` — DevLabBoundaryTest "guard #7: every canonical PRIM-*/GROUP-* inventory ID is referenced under dev/lab/**"

### Bucket E — SupportCopilot demo-app journeys
- `test/scoria/support_copilot_gallery_test.exs:8` — SupportCopilotGalleryTest "advisory adoption journey"
- `test/support_copilot_web/orchestrator_producer_test.exs:31` — OrchestratorProducerTest "approvals page shows approval from producer path"
- `test/support_copilot/journey_test.exs:110` — SupportCopilot.JourneyTest "knowledge lane seeds refund policy and surfaces grounded journey"

### Bucket F — warning inventory
- `test/scoria/warning_inventory/capture_parity_test.exs:53` — WarningInventory.CaptureParityTest "optimized compile-only capture catches high-signal unclassified warning (injected)"

### Full-suite / connector enumeration — COMPLETED (run 29137880790)

Pulled `gh run view 29137880790 --job <id> --log-failed` for every failing partition
(`test`, `full-suite 1–4`, `connector`). Per-partition top-level failures:
`fs1=1, fs2=4, fs3=17, fs4=8` → **30 unique full-suite failures**; `connector`'s 5–7 are
re-runs of the same tests under the connector tag (SupportJourney×4, OrchestratorProducer,
JourneyTest, SupportCopilotGallery) — **no additional unique tests**. `test` lane's 4 are the
Bucket A example-source tests (overlap fs2/fs4).

**Key finding — the default-lane subset (Buckets A–F above) missed ~15 failures, and 14 of
them collapse to ONE root cause.** New Bucket G below.

#### Bucket G — DashboardScope mount-halt regression (14 failures, 1 root cause) ⚠ NEW
Every one of these fails identically:
`** (ArgumentError) the hook {ScoriaWeb.DashboardScope, :default} for lifecycle event :mount
attempted to halt without redirecting.`
Root cause located: `lib/scoria_web/dashboard_scope.ex:144-145` — on `{:error, :unauthorized |
:missing_scope}`, `on_mount/4` returns `{:halt, put_unavailable_flash(socket)}` (a bare halt,
no redirect). Phoenix LiveView **1.1.30** (bumped in the v3.5 milestone) now hard-raises
`raise_halt_without_redirect!/1` on a mount hook that halts without redirecting. The tests
assert the pages render (`{:ok, _view, html} = live(...)`), so under the test conn the
`:default` resolver is returning `:missing_scope` (a required `@scope_keys` value is absent from
`test_conn()`/session) and then crashing on the bare halt. **One coherent fix** (repair the
`:default` scope resolution and/or the bare-halt branch + supply scope in the shared test conn)
turns all 14 green. Affected:
- `test/scoria_web/single_header_rendered_guard_test.exs:144` × 9 routes — SingleHeaderRenderedGuardTest for `/scoria`, `/scoria/datasets`, `/scoria/workflows`, `/scoria/approvals`, `/scoria/reviews`, `/scoria/connectors`, `/scoria/prompts`, `/scoria/eval_specs`, `/scoria/incidents`
- `test/scoria_web/live/orchestrator_live_sre_test.exs:82,192` × 2 — OrchestratorLiveSRETest (`live(conn, "/scoria")` trace-badge contracts)
- `test/scoria_web/live/coming_soon_live_test.exs:60,89,101` × 3 — ComingSoonLiveTest (allowlisted stubs `:60`, cost-ledger future-tense copy `:89`, unknown-stub-slug echo `:101`). NOTE: default-lane inventory only saw `:60`; the other two share the same DashboardScope crash.

#### Bucket C additions (seeded-run "Workflow run not found" cluster) ⚠ NEW
Two integration tests render the mobile-topbar title "Workflow run not found" instead of the
seeded run — a tenant-scoped seeded-run lookup mismatch (adjacent to REL-02's arity-3 tenant
seeding). Likely one shared fixture/seed fix:
- `test/scoria/runtime_integration_test.exs:159` — RuntimeIntegrationTest (already in default-lane Bucket C)
- `test/scoria/workflows/integration_test.exs:148` — Scoria.WorkflowsIntegrationTest "operator-visible LiveView state matches the durable recovery path" (`assert render(view) =~ "waiting_for_approval"`) — NEW
- `test/scoria_web/live/incidents_live_test.exs:219` — IncidentsLiveTest "incident detail route renders evidence" (`assert html =~ "Trace-first incident evidence"` — stale/relocated copy) — NEW

#### Bucket B — exact assertion
- `test/scoria/package_surface_test.exs:79,84` — `assert project[:homepage_url] == "https://hexdocs.pm/scoria"` but actual is `"https://scoria.hexdocs.pm"`. The HexDocs **subdomain** migration (REL-03 `@hexdocs_url`) updated `mix.exs` but not this "one publish surface" assertion. Fix: align the test to the subdomain SSOT (confirm subdomain is the intended canonical surface before editing).

#### Bucket F — reconcile against CI
- `test/scoria/warning_inventory/capture_parity_test.exs:53` was in the local `mix test` repro but did **NOT** fail in any partition of run 29137880790. Treat as verify-first: reproduce against the release head before spending effort; it may be local-env-only and require no change.

**Revised total:** ~30 full-suite failures, but only ~11 distinct root-cause clusters once
Bucket G collapses 14→1 and Bucket C's seeded-run cluster collapses 3→1.

## What is DONE and must not be redone
- REL-01 (policy lane) — `guides/maintainers.md` docs-contract constants + restored content; D-50-DEF-01 (ExDoc filtered-module docs gate) also fixed. Green.
- REL-02 (e2e lane) — `dev_seed.exs` arity-3 call sites + theme-toggle visible locators. Green.
- REL-03 (version/docs-truth polish) — workflow comments, `0.1.1`→`0.1.3` example, `@hexdocs_url` subdomain. Green.
- The 163-commit v3.5 push to `origin/main` (already landed).

## Resume path
1. `/gsd-plan-phase 50 --gaps` — plan gap-closure grouped by the buckets above.
2. `/gsd-execute-phase 50 --gaps-only` — execute the gap plans.
3. Push; Release Please refreshes PR #12; confirm `ci-gate` green.
4. Release Please merges/tags/publishes `0.1.3`; then finish 50-04 Task 3 (post-publish smoke + D-04 closeout).
