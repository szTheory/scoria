---
gsd_state_version: 1.0
milestone: v3.3
milestone_name: window is idle — collision-avoidance)
status: verifying
stopped_at: Phase 40 context gathered
last_updated: "2026-07-03T15:45:12.385Z"
last_activity: 2026-07-03 — Phase 39 complete, transitioned to Phase 40
progress:
  total_phases: 6
  completed_phases: 4
  total_plans: 19
  completed_plans: 19
  percent: 67
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-20 for v3.3 Design System Stress Test)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 39 — component-groups-and-operator-flows

## Current Position

Phase: 40 — Accessibility, Motion, And Responsive Proof
Plan: Not started
Status: Phase complete — ready for verification
Last activity: 2026-07-03 — Phase 39 complete, transitioned to Phase 40

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
- [Phase ?]: 38-03: audit-and-lock plan -- all 7 remaining Criterion 2 primitives (links/badges/timestamps/metadata-rows/panels/drawers/modals/forms/tables/lists) were already coherent; zero lib/scoria_web/ui.ex changes, 12 new regression-guard tests added instead
- [Phase 39]: 39-01: page_header/1's :actions wrapper carries no class attribute (not even unstyled), satisfying zero-new-CSS-class literally while still applying the existing .scoria-pagehead__title--with-actions modifier.
- [Phase 39]: 39-01: status_label/1 curates exactly the D-25 vocabulary (13 statuses) above the retained generic fallback; does NOT curate rejected->Denied (D-24d stays approval-domain-only, ApprovalCopy.decision_outcome/1).
- [Phase 39-02]: ScoriaWeb.Copy.status_label/1 independently curates the D-25 vocabulary rather than delegating to ScoriaWeb.UI.status_label/1 (Plan 01) -- keeps Copy a dependency-free leaf module within this plan's copy.ex-only file scope.
- [Phase 39-02]: Each per-domain copy module pairs a raw-value operator-label function (the literal offender fix, e.g. ConnectorCopy.runtime_status_label/1, ReviewCopy.status_label/1) with a record-branching orientation/1 function, satisfying D-24c in one module; wiring into the actual LiveView offenders is deferred to Plans 04/05.
- [Phase 39]: 39-03: decision_receipt/3 reuses decision_outcome/1 internally so "Denied" (D-24d) has exactly one literal source; expired receipts may show a real audit-event time but never a fabricated actor.
- [Phase 39]: 39-03: the D-20 write-invariant guard allow-lists exactly two Approval.changeset(...) update! call sites by {file,line} (creation-time audit_outbox_event_id backfill; the decision write inside approve/3), verified via a full-repo grep.
- [Phase ?]: 39-04: prompt_live has no name field on PromptTemplate (verified schema/migration/dev_seed) — led title/column with the domain noun 'Prompt' + <.id> evidence for entity_id instead of fabricating a name or adding a schema column.
- [Phase ?]: 39-04: coming_soon_live not-found branch uses page_header/1 + empty_state/1 rather than stub_page/1, since stub_page's Soon badge/works_today fields misrepresent a missing (not future) capability.
- [Phase 39-05]: Widened the connectors D-23 status-badge fix to health_state and last_refresh_status (same offender class as the named runtime.status), per T-39-05-I's plural 'connectors/review columns' disposition.
- [Phase 39-05]: No D-08 error/retry split added to incidents_live: OperatorSurface.list_tenant_incidents/1 already rescues internally to [] outside this plan's files_modified scope, so a LiveView-level rescue would be dead code.
- [Phase ?]: 39-06: Deny buttons (drawer + confirm modal) switch from scoria-button--danger to neutral scoria-button--ghost since the locked button vocabulary has no dedicated middle tone; risk-gradient rationale documented in code comments.
- [Phase ?]: 39-06: decided?/1 positive-whitelist predicate (approved/rejected/expired, fails safe) gates the action section + confirm modal so reversal affordances are structurally absent once decided; full decided-receipt (decider/time) wiring deferred to Plan 07 per this plan's stated scope.
- [Phase 39]: 39-07: decider_ref/1 sources event.metadata["metadata"]["decision_actor_id"] first, falling back to actor_ref, since Workflows.approve/3 writes actor_ref from immutable root identity (the requester), not the deciding operator. — Reading bare actor_ref per the plan's literal D-20 instruction would have silently misattributed every decision to the requester -- fixed within approvals_live/index.ex alone, no workflows.ex change.
- [Phase 39]: 39-07: runtime-focused PubSub auto-open stays a one-shot assign-based seed (runtime_seeded? flag), not migrated to the URL -- only the operator-initiated ?approval=<id> selection became a URL param per D-09's scope.
- [Phase ?]: 39-08: single_header_guard_test.exs excludes dataset_live/promote_component.ex (dialog-scoped, rendered inside dataset_live/index.ex's <.drawer>) alongside ui.ex, since the plan's named drawer/modal/palette/notebook filename fragments don't literally match this file's name
- [Phase ?]: 39-08: scan_convention_guard_test.exs scopes D-11 to the plan task's literal instruction (filter/scope-not-socket-only + sort exemption) rather than the broader CONTEXT.md D-11 section-order restatement
- [Phase ?]: 39-08: Fixed incidents_live/index.ex + show.ex to route incident.severity through IncidentCopy.severity_label/1 instead of a raw atom (Rule 1, required for the new D-26 copy guard to be green on arrival) -- caught the same offender class as the connectors runtime.status fix from Plan 05

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
| Trust/security P0 | SEED-006: eval fail-open, knowledge cross-tenant leak, dashboard auth bypass — **GATES next Hex release** | Deferred | 2026-07-03 eval-posture audit |
| Docs & positioning | SEED-005: terminology sense-aware rename, scope-doctrine/positioning, ExDoc grouping, glossary, curated llms.txt | Deferred | 2026-07-03 audit |
| Observability | SEED-007: OTel-GenAI/OpenInference trace foundation | Deferred | 2026-07-03 audit |
| Eval depth | SEED-008: real scorers, judge calibration, regression comparison | Deferred | 2026-07-03 audit |
| RAG depth | SEED-009: precision/NDCG/abstention/staleness + faithfulness/rerank hooks | Deferred | 2026-07-03 audit |
| Agent security | SEED-010: lethal-trifecta governance (⭐ flagship differentiator) | Deferred | 2026-07-03 audit |
| Privacy/feedback | SEED-011: retention/purge, PII masking hook, human-feedback flywheel | Deferred | 2026-07-03 audit |

> **Ordered roadmap + dependencies** for SEED-005…011 live in `ROADMAP.md` `## Backlog` (999.1–999.7); "why" index in `.planning/seeds/README.md`. Stray per-plan timing rows that previously polluted this table were removed 2026-07-03 (canonical per-plan metrics live in the phase manifests).
| Phase 39 P06 | ~20min | 3 tasks | 5 files |
| Phase 39 P07 | ~50min | 2 tasks | 3 files |
| Phase 39 P08 | 48min | 3 tasks | 8 files |

## Session Continuity

Last session: 2026-07-03T15:45:12.380Z
Stopped at: Phase 40 context gathered
Resume file: .planning/phases/40-accessibility-motion-and-responsive-proof/40-CONTEXT.md
