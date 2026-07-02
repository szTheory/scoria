---
gsd_state_version: 1.0
milestone: v3.3
milestone_name: Design System Stress Test
status: executing
stopped_at: Phase 38 context gathered
last_updated: "2026-07-02T23:18:22.867Z"
last_activity: 2026-07-02
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 11
  completed_plans: 10
  percent: 33
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-20 for v3.3 Design System Stress Test)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 38 — foundations-and-primitive-controls

## Current Position

Phase: 38 (foundations-and-primitive-controls) — EXECUTING
Plan: 3 of 3
Status: Ready to execute
Last activity: 2026-07-02

## Performance Metrics

- **Latest Shipped:** `v3.2 Drydock` (2026-06-19) — 15 plans, 7 phases. Audit `passed`; Hex `0.1.2` live and post-publish smoke green.
- **Previous Shipped:** `v3.1 CI/CD Velocity` (2026-06-17) — 9 plans, 6 phases, 13 tasks. Audit `passed`; PR CI 77m→7m38s MEASURED.

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- v3.2: `make nuke` uses ONLY `docker compose down -v` — no `docker system/volume prune`; no interactive TTY prompt; named-scope warning is the safety signal.
- v3.2: `PORT ?= 4799` baked into `make dev` (static, stable for shots-native harness; overridable via `PORT=XXXX make dev`; no `config/dev.exs` change).
- v3.2: Stream B (Phase 35) is fully independent of Stream A (Phases 29–34) — can execute in parallel.
- v3.2: `VerificationLanes.closeout_order/0` and `CI / ci-gate` required-check name stay byte-stable; new tests run in existing policy lane only; no CI topology changes.
- v3.2: Parallelism within Stream A: Phases 30, 31, 32 can all run after Phase 29 (no inter-dependencies); Phase 33 depends on 29–32; Phase 34 depends on 33.
- [Phase ?]: Route list derived live from mix phx.routes ScoriaWeb.DevRouter.
- [Phase 32]: Maintainer szTheory accepted no Anthropic key rotation required because `.env` was local ignored plaintext with no Git history; SEC-02 closeout records no token material.
- [Phase 34]: Created dedicated DOCS-03 ExUnit contract that reads only docs/docker_dev_dx.md via File.read!(@doc_path). — Keeps the docs drift guard file-read-only and safe under mix test --no-start.
- [Phase 34]: Used two-layer stale URL guard for fixed localhost/loopback 4000 browser-start drift while allowing qualified Docker-internal mechanics. — Matches Phase 34 D-17 through D-19 without banning legitimate container, Traefik, service-target, or ephemeral fallback references.
- [Phase 34]: Kept post-publish smoke to the narrow `5432:5432` / `SCORIA_DB_PORT: 5432` fix and extended the existing FLAKE-01 scanner with an exact `post-publish-smoke.yml:smoke` key guard.
- [Phase 34]: Kept Docker DX doc-token ownership in `Scoria.DockerDxDocContractTest`; `ci_policy_contract_test.exs` now retains only the `.env.example` instance example guard for that surface.
- [Phase 34]: Appended `test/scoria/docker_dx_doc_contract_test.exs` to the existing policy-lane `mix test --no-start --warnings-as-errors` file list only.
- [Phase 34]: Left `CI / ci-gate`, `ci.yml`, workflow topology, job names, services, matrices, needs, and `Scoria.VerificationLanes.closeout_order/0` unchanged while completing DOCS-03 lane wiring.
- [Phase 35]: README remains Hex-primary; the commented GitHub fallback is fork/pinned-patch guidance, not a release-candidate tag contract.
- [Phase 35]: `registry_upgrade_pair("0.1.2")` uses previous live Hex release `0.1.0` instead of patch-minus-one arithmetic.
- [Phase 35]: Release PR #3 merge authority was latest head `d0eecbb66c19f85d25a77cbae9ce2fd91ca50f11` with `CI / ci-gate` success before release-pr-automerge merged commit `26eb9a5e686fe4957196dfa5c6654121bda65c03`.
- [Phase 35]: Post-merge Release Please cancellation was classified as uncertain publish recovery because GitHub release `v0.1.2` existed but Hex did not list `0.1.2`; existing `hex-publish.yml` recovery published exact `tag=v0.1.2` / `release_version=0.1.2`.
- [Phase 35]: After Hex listed `0.1.2`, recovery stayed smoke-only; final post-publish smoke run `27834739958` proved fresh install and live-lineage upgrade `0.1.0 -> 0.1.2`.
- [Phase 36]: Phase 36 inventory remains repository-local Markdown plus JSON; no runtime lab, packages, PhoenixStorybook, or source edits.
- [Phase 36]: 36-inventory.json is canonical for row IDs, statuses, owners, evidence, and risk references.
- [Phase 36]: v3.0 proof gaps are tracked as RISK-V30-PROOF instead of treated as automatic regressions.
- [Phase 36]: Source-scan reconciliation is encoded directly in 36-inventory.json rows and documented_exclusions.
- [Phase 36]: Phase 37+ is gated on both inventory artifacts parsing and containing required risk IDs plus complete layer/status coverage.
- [Phase 36]: Generated/vendor/report-heavy inputs are excluded only with explicit source, reason, and reviewed_by_phase fields.
- [Phase 37]: Used DevLab.* module namespace (not ScoriaWeb.DevLabFixtures) per Claude's Discretion; states_for/2 is a fully structural deep-transform so adding a scenario stays O(1); DevLab.Fixtures.inventory_id/1 is the single coverage-anchor map for all 46 canonical PRIM-*/GROUP-* IDs; DS-06 dev/lab/** extension is an additive standalone test, not folded into the lib/ ratchet-baseline file.
- [Phase 37]: 37-02: Every Primitives specimen's tone routes through DevLab.Sections.States.state_tone/1 via a new with_lab_state/1 helper (embeds the D-11 state atom into the fixture map); toast_tone/1 clamps state_tone/1's :brand output to :info since <.toast> excludes :brand/:trace. Drawer/modal specimens open only for the :normal row (avoids ten stacked full-viewport overlays); the other nine rows defer to the Overlays IA section (D-10). signal_strip has no canonical inventory ID (status duplicated) so overview_stats covers 'signal summaries' instead.
- [Phase 37]: 37-03: Groups feeds each band from ONE base domain-noun scenario per group via states_for/2 (matching Plan 02's Primitives convention); browsing BOTH the normal and empty/error scenario per domain is the Fixtures section's job instead. IncidentEvidenceComponent's deeply-nested evidence shape (no graceful nil-default path) required a full deterministic literal-filler adapter, unlike the other four groups. ApprovalInboxComponent's hardcoded internal table id repeats across all ten stacked state rows — documented as a known, out-of-scope (lib/) limitation rather than worked around.
- [Phase 37]: 37-04: Viewports reuses Plan 02 dense table specimen verbatim; Overlays dense-approvals probe builds 8 deterministic literal rows from the two existing approval scenarios rather than touching fixtures.ex; long-unbroken-evidence probe reuses approval_requested policy_name; command palette rows forward-reference /scoria/_lab/<section> (Plan 05 route); mobile nav probe reuses real ScoriaWeb.Layouts.nav_groups/0 data; both open drawer/modal specimens share the on_dismiss=lab-noop-dismiss convention Plan 02 established.
- [Phase 37]: 37-05: Run lab proof primary command patches to /scoria/_lab/states (canonical proof/vocabulary overview) since D-27 does not specify concrete behavior; Open fixture matrix patches to /scoria/_lab/fixtures per plan instruction. Both header commands render as <.link patch=...> styled with existing scoria-button classes rather than a new primitive. item is passed only to primitives/1, groups/1, fixtures_view/1 per each section's actual attr() contract. lab-noop-dismiss handle_event added, resolving the crash risk flagged by 37-02/37-04.
- [Phase ?]: 37-06: theme coverage proven via the shared root.html.heex localStorage pre-paint mechanism (no theme-toggle control exists on the lab's bare root-layout route); Overlays dismiss probe targets the modal close button since its full-viewport scrim blocks clicks on the drawer beneath it; copy-control probe runs on Fixtures instead of Overlays for the same reason; fixed a Rule-1 invalid p-in-p nesting bug in dev/lab/sections/foundations.ex that collapsed the D-14 reduced-motion signal.
- [Phase 38]: Phase 38-01: priv/static/scoria/app.css (compile-time-inlined via ScoriaWeb.Assets @external_resource) must be regenerated via mix scoria.assets.build whenever assets/css/*.css changes -- not automatic on mix compile.
- [Phase 38]: Phase 38-01: flash banners repointed to the same new opaque --scoria-toast-<tone>-bg tokens as toasts (D-03 fallback); confirmed no floating .scoria-flash exists in lib/scoria_web/components/layouts.
- [Phase 38]: 38-02: split Task 1/2's overlapping ui.ex + ui_component_test.exs edits into separate atomic commits by temporarily reverting/reapplying later-task hunks; .scoria-id aria-label derived from @value (displayed/truncated) not @copy (full ID) per plan instruction

### Pending Todos

- UI follow-up: make approval rejection toasts legible over dense approvals UI — mapped to v3.3 Phase 38.
- UI follow-up: add approval decision history for approved/denied/expired requests — mapped to v3.3 Phase 39.
- Post-v3.2: SEED-004 test-code determinism (async `IntegrationCase`, `Process.sleep` removal) — leading candidate for next milestone.
- Post-v3.2: FLEET-01 sibling-repo convergence (rulestead/parapet) — `docker-dx-fleet-hardening` todo.
- Post-ship cleanup: `ci-policy-job-cache-key-mislabel` (carried from v3.1 close).

### Blockers/Concerns

None at milestone start.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Test determinism | SEED-004: async IntegrationCase, remove Process.sleep, raise shard count | Deferred | v3.1 close |
| Fleet convergence | FLEET-01: migrate sibling repos onto shared Traefik + unpublished-DB standard | Deferred | v3.2 scope decision |
| Fleet targets | FLEET-02: `make nuke-all` fleet-wide teardown (high blast radius) | Deferred | v3.2 out-of-scope |
| v3.0 gaps | Phase 13/14 verification-doc gaps (functional: 0 unsatisfied; 10 partials are proof-only) | Deferred | v3.0 close |
| Release | Publish 0.1.1 → superseded by 0.1.2 in Phase 35 | Absorbed into REL-01 | v3.2 REL |
| Phase 30 P01 | 319 | 2 tasks | 2 files |
| Phase 32 P01 | 18 min | 2 tasks | 5 files |
| Phase 32 P02 | 10 min | 1 task | 4 files |
| Phase 33 P01 | 18min | 2 tasks | 1 files |
| Phase 33 P02 | 12min | 2 tasks | 5 files |
| Phase 33 P03 | 14min | 3 tasks | 9 files |
| Phase 33 P04 | 28min | 3 tasks | 11 files |
| Phase 34 P01 | 3 min | 2 tasks | 1 files |
| Phase 34 P02 | 4 min | 2 tasks | 2 files |
| Phase 34 P03 | 2 min | 1 tasks | 1 files |
| Phase 35 P01 | 14 min | 2 tasks | 3 files |
| Phase 35 P02 | 30 min | 3 tasks | 18 files |
| Phase 35 P03 | 48 min | 3 tasks | 6 files |
| Phase 36 PP01 | 5 min | 2 tasks | 3 files |
| Phase 36 PP02 | 9min | 2 tasks | 3 files |
| Phase 37 P01 | 21min | 3 tasks | 6 files |
| Phase 37 P02 | 35min | 2 tasks | 2 files |
| Phase 37 P03 | ~30min | 2 tasks | 2 files |
| Phase 37 P04 | ~15min | 2 tasks | 2 files |
| Phase 37 P05 | 25min | 2 tasks | 2 files |
| Phase 37 P06 | 55min | 2 tasks | 3 files |
| Phase 38 P01 | 32min | 3 tasks | 5 files |
| Phase 38 P02 | 20min | 3 tasks | 4 files |

## Session Continuity

Last session: 2026-07-02T23:15:44.618Z
Stopped at: Phase 38 context gathered
Resume file: None
