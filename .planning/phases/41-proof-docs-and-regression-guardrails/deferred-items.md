# Deferred Items — Phase 41

Out-of-scope discoveries logged per the executor SCOPE BOUNDARY rule: only auto-fix issues
directly caused by the current task's changes. These are pre-existing failures unrelated to
Plan 04's file scope (`priv/dev/shots.mjs`, `priv/dev/contact_sheet.mjs`,
`priv/shots/contact_sheet_index.md`, `priv/dev/e2e/drawer_focus.spec.mjs`'s D-13 block only).

## 41-04: Pre-existing `mix scoria.ui.e2e` failures observed during Task 3's D-04 verify run

While verifying the D-13 collector's disposition (Task 3), the full e2e lane was run
(`mix scoria.ui.e2e`, 2026-07-04) to observe real behavior. 6 unrelated tests failed; none
touch this plan's files or the D-13 collector itself (which passed with zero warnings —
see 41-04-SUMMARY.md):

| Spec | Test | Failure |
|------|------|---------|
| `command_palette.spec.mjs:76` | keyboard shortcuts overlay opens, closes, traps focus, and ignores editable fields | `#scoria-shortcuts` not visible after pressing `?` |
| `drawer_focus.spec.mjs:214` | CR-01: Escape while the decision modal is stacked over the drawer cancels ONLY the modal | `#approval-detail-drawer` not visible — drawer never opened for this test |
| `modal_focus.spec.mjs:106` | trap: Tab from the last focusable wraps to the first, Shift+Tab from the first wraps to the last | Shift+Tab landed on `e2e-focusable-0-...` instead of the expected last-focusable id |
| `phase16_parity.spec.mjs:503` | MOTION-04: Home/shell theme toggle flips data-theme and page stays ready | Theme toggle button never became visible/stable within 30s |
| `phase16_parity.spec.mjs:526` | MOTION-04: Workflows table screen theme toggle flips and page stays ready | Same as above |
| `phase16_parity.spec.mjs:544` | MOTION-04: Workflow detail (evidence screen) theme toggle flips and page stays ready | Same as above |

159 other tests passed (1.6m run). Not fixed here — none are caused by this plan's edits and
all are in files outside Plan 04's `files_modified` scope. Candidates for a future phase's
e2e-harness flake/regression sweep (see 41-RESEARCH.md's Section B note: "e2e-harness
flakes").

## Wave-1 post-merge gate: pre-existing `mix test` (ExUnit) failures (2026-07-04)

The Wave-1 post-merge full-suite gate (`mix test`, 937 tests) surfaced 3 ExUnit failures.
One was a genuine Wave-1 regression and was **fixed in-lane** (commit `f6e3e0c6`): the new
`single_header_rendered_guard_test.exs` (41-02) defined a bare `ScoriaWeb.ErrorView`
that collided with the identical stub in `review_queue_live_test.exs` under Elixir's
parallel test compiler, producing a non-deterministic `CompileError` on subset runs;
resolved by namespacing it to `ScoriaWeb.SingleHeaderRenderedGuardTest.ErrorView`.

The remaining 3 are pre-existing and unrelated to any Phase 41 file scope — logged here per
the SCOPE BOUNDARY rule, candidates for a future flake/regression sweep:

| Test | Location | Cause | Disposition |
|------|----------|-------|-------------|
| `Scoria.CiPolicyContractTest` planning-ledgers | `test/scoria/ci_policy_contract_test.exs:692` | `assert roadmap =~ "v2.15"` — roadmap is now `v3.3`; stale assertion | Already tracked as Phase 40 D-21 deferred item |
| `Scoria.WarningInventory.CaptureParityTest` compile-only capture | `test/scoria/warning_inventory/capture_parity_test.exs:53` | Warning-inventory ratchet's compile-only offender capture is full-suite-order-sensitive; **passes deterministically in isolation** (`2 tests, 0 failures`, verified twice). Not touched by Phase 41. | Flake — future warning-inventory harness hardening |
| `Scoria.SupportCopilotGalleryTest` advisory-adoption | `test/scoria/support_copilot_gallery_test.exs:8` | Shells out to `examples/support_copilot`'s suite; `Scoria.Workflows.Reconciler` async tasks race the Ecto SQL sandbox → `DBConnection.ConnectionError` owner-exit + `assert html =~ "Approval inbox"`. Entirely within the untouched `examples/support_copilot` subtree. | Flake/environmental — future example-project sandbox-ownership fix |
