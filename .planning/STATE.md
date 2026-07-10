---
gsd_state_version: 1.0
milestone: v3.5
milestone_name: Documentation & Release Readiness — ACTIVE
status: planning
stopped_at: Phase 49 context gathered
last_updated: "2026-07-10T23:36:56.487Z"
last_activity: 2026-07-10
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 26
  completed_plans: 26
  percent: 60
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-07-09 after starting v3.5 milestone)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 49 — ai accessible docs and docs verification gate

## Current Position

Phase: 49
Plan: Not started
Status: Ready to plan
Last activity: 2026-07-10

## Performance Metrics

- **Latest Shipped:** `v3.4 Pre-1.0 Trust & Security Hardening` (2026-07-09) — 24 plans, 4 phases, 61 tasks. Audit `passed` (17/17 requirements, 4/4 phases); archived in `.planning/milestones/v3.4-*`.
- **Previous Shipped:** `v3.3 Design System Stress Test` (2026-07-04) — 30 plans, 7 phases, 74 tasks. Audit `passed` (22/22 requirements, 6/6 seams); tag `v3.3` local.
- **Previous Shipped:** `v3.2 Drydock` (2026-06-19) — 15 plans, 7 phases. Audit `passed`; Hex `0.1.2` live and post-publish smoke green.
- **Phase 42 P01:** 6 min — 3 tasks, 7 files, verification 14 tests green.
- **Phase 42 P02:** 7 min — 3 tasks, 6 files, verification 7 required tests green plus 11 eval promotion regression tests.
- **Phase 42 P03:** 8 min — 1 task, 2 files, verification 9 exact-match scorer tests green; full-suite residual failures logged in 42-03 summary.
- **Phase 42 P04:** 7 min — 2 tasks, 3 files, verification 26 focused eval tests green; not_scored score-nullability migration added.
- **Phase 42 P05:** 39 min — 2 tasks, 2 files, verification 15 focused eval tests green.
- **Phase 42 P06:** 11 min — 3 tasks, 3 files, verification 16 online/campaign tests and 15 related eval tests green.
- **Phase 42 P07:** 6 min — 3 tasks, 4 files, verification 10 release gate tests green plus migration rollback/reapply.
- **Phase 43:** 5 plans, 12 tasks — knowledge tenant isolation complete; full `mix test.knowledge --warnings-as-errors` green during closeout.
- **Phase 44:** 7 plans, 21 tasks — dashboard auth seam complete; focused dashboard-auth lane green during closeout.
- **Phase 45:** 5 plans, 11 tasks — correctness sweep + doctrine closeout complete; focused Phase 45 and scope-doctrine tests green during closeout.

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- v3.4: Phases 42 (eval) / 43 (knowledge) / 44 (dashboard) are independent subsystems — parallelizable; Phase 45 (correctness sweep + doctrine + closeout) depends on 42 + 43.
- v3.4: Fix + prove only — NO Hex publish. The honest `0.1.3` release cut belongs to SEED-005 / Backlog 999.2. `0.1.3` PR #12 stays held.
- v3.4: DOC-01 is confirm-and-cross-link (P1–P6 scope doctrine already recorded in PROJECT.md Constraints + Key Decisions at v3.3 close) — kept lightweight in Phase 45.
- [Phase 42-01]: `Scoria.Eval.Verdict` is the single fail-closed verdict spine; empty, all-unscored, and strict coverage violations return `:inconclusive`, and only persisted `"passed"` is the non-blocking release verdict string.
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
- [Phase ?]: priv/dev/package-lock.json stays uncommitted (gitignored per commit 7e1cde4b); package.json exact-pin + overrides.axe-core is the real D-05 reproducibility contract
- [Phase ?]: axe.mjs calls .options({rules}) before .withTags(WCAG_TAGS) -- AxeBuilder#options() replaces the whole option object while #withTags() only merges runOnly, so the reverse order would silently drop the tag filter
- [Phase 40]: 40-02: motion guard allow-lists scoria-skeleton-pulse and scoria-approval-pulse by animation NAME (not literal duration string) so a future duration edit on either D-20/D-21 exception can't silently defeat it; a dedicated test asserts both names are present to catch the false-RED-from-allow-listing-only-one risk.
- [Phase 40]: 40-02: a11y guard's dialog check asserts role=dialog + aria-modal=true pairing only (not phx-key=Escape presence), since the mobile-nav drawer and shortcuts overlay are JS-hook-driven with no phx-key attribute at all; and its filter-controls check is scoped to the <:filter> slot only, not the table's th phx-click sort trigger (not literally a button today) — asserting the stricter claim would false-RED the already-green baseline.
- [Phase 40]: 40-03: phx-remove={JS.pop_focus()} on the outer overlay shell (not wrapping on_dismiss) centralizes restore-on-close for drawer/modal without touching any existing on_dismiss string attribute -- keeps ui_component_test.exs literal-string assertions green.
- [Phase 40]: 40-03: removed modal/1's old bare autofocus in favor of phx-mounted={JS.focus_first()} on focus_wrap -- one canonical tab-in mechanism shared by modal/1 and drawer/1.
- [Phase 40]: 40-03: added JS.push_focus() at workflow_detail_panel_component.ex's promote-modal opener though that file wasn't in files_modified -- required so restore doesn't land on <body>.
- [Phase 40]: 40-03: dataset_live/index.ex's promote drawer has no local opener (cross-page URL-param driven) -- trap/tab-in still applies via ui.ex, restore-to-cross-page-trigger is an accepted, documented scope boundary.
- [Phase 40]: 40-03: D-13's live-patch collector uses a real cross-tab approval decision (no synthetic patch is reachable via the UI); bumped mix scoria.ui.e2e's pending-approval floor 5->10 to give the shared fixture pool headroom.
- [Phase ?]: 40-05: Anchor set for the D-15 ~4-page responsive scan is Home+Workflows (generalized phase16_parity baseline) + Approvals + Incidents; workflow-detail deliberately left out since its grid-split primitive is already exercised by Incidents and its drawer-occlusion risk belongs to drawer_focus.spec.mjs (D-11), not D-16.
- [Phase ?]: 40-05: Every new responsive_scan.spec.mjs / reduced_motion.spec.mjs assertion ships as a throwing expect() (not a warning-grade collector) because each was run live against a real dev server during authoring and found clean except one defect (fixed inline, .scoria-button--sm 24px floor) — per D-04 this is fix-and-assert-atomic, not new-and-uncertain.
- [Phase 40]: 40-04: Curated axe assert-zero allow-list = all 7 seeded real pages (Home, Workflows, Approvals, Incidents, Review Queue, Datasets, Connectors), both themes.
- [Phase 40]: 40-04: Fixed --scoria-text-subtle AA contrast failure via token SSOT — repointed the semantic alias per-theme to the nearest existing ramp step (dark->muted-warm, light->graphite-700); pumice-500 primitive untouched.
- [Phase 41]: WR-04: used direct-callback regression test (mount/2 + render/1 + Phoenix.HTML.Safe.to_iodata/1 forced evaluation), not the A1 source-scan fallback
- [Phase 41]: CR-01 notice literal: 'Could not dismiss this candidate. Refresh and try again.'
- [Phase 41]: D-18 aria-label copy: 'Scrollable table content'
- [Phase 41]: 41-02: New guard module is async: false (real LiveView render + DB) and kept separate from the async: true, no-DB single_header_guard_test.exs source-scan module rather than merging async settings.
- [Phase 41]: 41-02: Skipped /workflows/:id, /incidents/:id, /prompts/:id/release (object_header/1 has no :title slot) and /coming/:screen (ComingSoonLive never pairs a header with a region :title slot) -- documented as an honesty caveat, mirroring dev_lab_boundary_test.exs.
- [Phase 41]: 41-02: CSS selectors verified directly against lib/scoria_web/ui.ex before landing (Assumption A2): page title is .scoria-pagehead__title h1; region titles are .scoria-panel__header h2 and .scoria-page-section__header h2.
- [Phase 41]: 41-03: Guard-path regex in the doc contract scans for the test/..._test.exs substring anywhere in backtick-fenced text, not just backtick-anchored paths, since the doc cites guards both as bare filenames and full mix test invocations.
- [Phase 41]: 41-03: BEM/selectors section states plainly that no test enforces BEM structure directly -- convention, guarded only for palette leakage via ds06_drift_guard_test.exs -- per D-10.
- [Phase 41]: 41-03: Overlays section pairs a11y_structural_guard_test.exs (static role=dialog/aria-modal pairing) with modal_focus.spec.mjs/drawer_focus.spec.mjs (e2e trap+restore) since no single ExUnit test owns overlay focus behavior end-to-end.
- [Phase 41]: 41-04: lab_overlays SCREENS entry uses path '/_lab/overlays' (baseUrl already includes /scoria)
- [Phase 41]: 41-04: contact_sheet_index.md update is an additive Phase 41 addendum, not a rewrite of the historical v3.0 before/after record
- [Phase 41]: 41-04: D-13 drawer live-patch collector flipped to a throwing expect() after mix scoria.ui.e2e observed zero warnings (D-04 VERIFY-THEN-DEFER)
- [Phase 41-05]: Placed D-06 guard, PROOF-02 doc+contract, D-14/D-15 screenshot additions, and the D-04/D-13 collector flip in gap-register Section A (labeled as Phase 41's own lock-and-document deliverables) rather than laundering them as bare fixes.
- [Phase 41.1]: UI.status_label/1 delegates to Copy.status_label/1; Copy stays a dependency-free leaf (D1)
- [Phase 41.1]: Dataset empty-state CTA kept inline (no byte-identical Copy accessor exists, D2)
- [Phase 41.1]: DatasetCopy.orientation/1 intentionally left unwired on dataset index page (D3)
- [Phase 42-02]: Dataset promotion loads Scoria.Workflows.Step internally from existing workflow_step_id; captured_output is not a promotion attr key.
- [Phase 42-02]: SubjectOutput.resolve/2 is the shared frozen-capture contract for offline_replay and live_judge; nil or empty capture returns {:not_scored, :empty_capture}.
- [Phase 42-03]: ExactMatch.score/3 treats clean mismatches as failed/0.0 and couldn't-run inputs as {:not_scored, reason}. — Preserves the plan's sharp line between real negative signals and unscoreable inputs.
- [Phase 42-03]: ExactMatch string comparison normalizes Unicode NFC, trims, collapses internal whitespace, and remains case-sensitive unless case_insensitive is true. — Matches D-03 while avoiding fuzzy or semantic matching.
- [Phase 42-03]: ExactMatch whole-map matching is opt-in via match: "map" and canonicalizes atom/string keys recursively. — Keeps non-string default field comparisons fail-closed while supporting runner map comparison specs.
- [Phase 42-04]: Offline replay now extracts captured output by scorer field for ExactMatch, persists not_scored for empty/unknown scorer paths, and computes threshold_verdict through Scoria.Eval.Verdict. — Plan 42-04 replaced the hardcoded pass path while keeping live LLM usage opt-in only through injected seams.
- [Phase 42-05]: Judge Actual is JSON-encoded frozen captured_output from SubjectOutput.resolve(dataset_item, :live_judge), never expected_output["answer"].
- [Phase 42-05]: Empty or absent judge captures persist not_scored score evidence with reason empty_capture and skip the injected judge seam.
- [Phase 42-05]: Judge runner persists threshold_verdict from Verdict.compute/2; the local threshold_verdict/2 duplicate and latency helper were removed.
- [Phase 42]: 42-06: Clean online traces emit no deterministic base scores; only judge scores can produce positive online evidence. — Prevents reference-free deterministic checks from laundering clean production traces into golden labels.
- [Phase 42]: 42-06: Empty, failed, or not_scored online score sets remain needs_review and compute to inconclusive. — Keeps online scoring fail-closed and delegates threshold semantics to Scoria.Eval.Verdict.compute/2.
- [Phase 42]: ReleaseGate treats completed nil, unknown, failed, and inconclusive verdicts as blocking because only persisted string "passed" is allowed. — Preserves the 42-01 Verdict allowlist and avoids treating malformed completed eval evidence as ungated.
- [Phase 42]: ReleaseGate uses a left join to EvalCampaign so standalone and offline campaign eval runs count, while metadata source "online_scoring" runs are excluded. — Online scoring runs are review evidence, not offline release evidence; standalone legacy runs should remain compatible.
- [Phase 42]: No completed eval verdict remains default-open for adopter compatibility, emits [:scoria, :release_gate, :ungated] telemetry, and can be made strict with require_eval_verdict. — Keeps existing adopters from being bricked while making ungated prompts inspectable and opt-in blockable.
- [Phase 44-01]: scoria_dashboard/2 accepts only :on_mount and :scope_resolver for this seam; root_layout and Scoria hooks remain owned by Scoria. — This satisfies AUTH-01 without adding broad live_session option pass-through during a P0 security fix.
- [Phase 44-01]: The default dashboard scope resolver reads host session/socket assigns and ignores query params as tenant authority. — This closes the AUTH-02 spoof path while preserving bare macro compatibility.
- [Phase 44-01]: Custom resolver failures either fail closed with generic Scoria copy, redirect/halt under host control, or raise InvalidReturnError for malformed returns. — This keeps browser-facing failures generic and makes malformed resolver output loud in tests/development.
- [Phase 44-dashboard-auth-seam-03]: ApprovalsLive treats URL tenant/query values as UI hints only; tenant authority comes from DashboardScope assigns. — Closes the cross-tenant approvals spoof path by ensuring pending, decided, and deep-linked approvals use the authenticated dashboard scope rather than request hints.
- [Phase 44-dashboard-auth-seam-03]: Approval decision context uses assigned dashboard tenant and actor; no approval-lineage or hardcoded default tenant fallback remains. — Keeps approval decisions and audit outbox events aligned with the host-asserted tenant and actor.
- [Phase ?]: 44-04: Workflow list and detail reads use ScoriaWeb.DashboardScope assigns instead of params, session fallbacks, or default tenant derivation.
- [Phase ?]: 44-04: Workflow detail checks tenant visibility before runtime hydration, linked incident lookup, review candidate projection, remote evidence lookup, or PubSub subscription.
- [Phase ?]: 44-04: Review candidate deep links are tenant-gated in OperatorSurface before calling the existing Eval projection because the projected DTO omits tenant_id.
- [Phase 44-05]: Review Queue and Dataset Builder treat review candidate IDs as hints and reload them through Scoria.Eval.get_review_candidate_for_tenant/2. — Closes AUTH-03 IDOR risk by ensuring URL-provided candidate IDs cannot directly render tenant-owned evidence without tenant validation.
- [Phase 44-05]: Eval Workbench keeps eval specs as global catalog metadata while listing eval runs only through Scoria.Eval.list_eval_runs_for_tenant/1. — Preserves useful tenantless rubric metadata while filtering tenant-owned eval run and score evidence through DashboardScope tenant assigns.
- [Phase 44-05]: Dataset Builder validates workflow promotion run IDs through OperatorSurface.fetch_tenant_run_detail/2 before rendering promotion evidence. — Keeps workflow promotion deep links selector-only and prevents foreign run hydration under another tenant scope.
- [Phase 44-06]: PromptTemplate reads stay global catalog metadata; EvalRun and Approval evidence are tenant-filtered by DashboardScope tenant.
- [Phase 44-06]: Prompt release workflow requests require explicit tenant_id so release approval writes match dashboard scope.
- [Phase 44-06]: Plan path test/scoria_web/live/prompt_live/index_test.exs maps to current test/scoria_web/live/prompt_live_test.exs.
- [Phase 44]: 44-02: Home, Connectors, and Incidents now consume ScoriaWeb.DashboardScope tenant assigns before tenant-owned reads or PubSub subscriptions.
- [Phase 44]: 44-02: OrchestratorLive review_candidate_id deep links use Scoria.Eval.get_review_candidate_for_tenant/2 so URL object IDs cannot cross tenant scope.
- [Phase 47-02]: README now leads with embedded Phoenix positioning before capability and verification-suite vocabulary. — POS-01 front-door comprehension depends on product category before coined vocabulary.
- [Phase 47-02]: Public scope table uses adopter-readable ownership rows instead of P1-P6 public labels. — POS-03 needs host-owned responsibilities to be concrete for Phoenix adopters.
- [Phase 47-02]: README links to the Phase 47-03 comparison guide without creating or packaging that guide in 47-02. — The plan explicitly reserves comparison-guide creation and package-surface wiring for 47-03.
- [Phase 47]: Phase 47-03 comparison guide uses source-linked external LLM-ops posture and separates current Scoria claims from deferred feature seeds. — The guide must help adopters compare current Scoria against external LLM-ops platforms without implying deferred capabilities are already shipped.
- [Phase 48]: Wave 1 intentionally stops at RED package/ExDoc/release-preview contracts; later Phase 48 plans own guide/config implementation.
- [Phase 48]: Old docs/*.md paths are package compatibility stubs only; canonical docs contracts now point at guides/ paths and required brand assets.
- [Phase 48-02]: Plan 48-02 intentionally remains RED; canonical guide files, README links, and D-17 module guide links are implemented by later Phase 48 plans.
- [Phase 48-02]: Stable adopter-doc contracts now treat old docs/*.md paths as compatibility-only; canonical public truth points at guides/ paths.
- [Phase 48-02]: Public moduledoc tests use Code.fetch_docs/1 to verify compiled docs without adding doctest expectations for runtime, dashboard, DB, or LiveView examples.
- [Phase 48-03]: Start Here guides link to canonical guides/... paths even where later Phase 48 plans still own the target guide bodies.
- [Phase 48-03]: The first-run guide ladder keeps the default runtime capability before optional semantic cache, knowledge, or connector setup.
- [Phase 48-03]: The ownership-boundary guide carries the same public owns-vs-delegates table shape as README so scope doctrine stays executable.
- [Phase 48-04]: Capability guides keep the default runtime first and frame knowledge, semantic cache, and connectors as optional expansions.
- [Phase 48-04]: The semantic cache guide explicitly says it is not a knowledge base and treats lane_key only as stored 0.1.x compatibility vocabulary.
- [Phase 48-04]: The canonical glossary preserves evidence_refs and compatibility aliases without introducing trace_refs storage vocabulary.
- [Phase 48]: Reviewer verification is the canonical public name; operator verification remains compatibility wording only.
- [Phase 48]: Comparison guide preserves Phase 47 safe current claims, named peer source links, ceded strengths, and explicit not-current claims.
- [Phase 48]: Maintainer-only CI, release, warning, installer, and dev-tool commands stay in guides/maintainers.md rather than README or first-run adopter docs.
- [Phase 48]: README Docs navigation is grouped by the canonical Phase 48 guide ladder and now points at guides/... paths instead of old flat docs/*.md current navigation.
- [Phase 48]: README keeps current public guide names first while preserving old semantic-fast-path wording only as an explicit 0.1.x compatibility note for existing docs contracts.
- [Phase 48-08]: Kept runtime and DTO examples as prose/non-doctest documentation; only the existing pure facade and identity doctests remain executable doctest surfaces.
- [Phase 48-08]: Logged broad adoption-surface failures outside the 48-08 file set to deferred-items.md instead of widening this plan into later public-moduledoc and guide-fragment work.
- [Phase 48-09]: Kept capability/integration public moduledoc work documentation-only; no runtime behavior, schema, package, guide-body, or ExDoc config changes. — Plan 48-09 is a public docs polish task and the threat model accepts no dependency or runtime changes.
- [Phase 48-09]: Used canonical guide paths directly in capability moduledocs instead of old docs/*.md compatibility paths. — Phase 48 guide ladder decisions make guides/ the canonical public surface while docs/*.md remains compatibility-only.
- [Phase 48-09]: Treated broad adoption-surface verification as partial because remaining guide/DashboardScope failures are known later-plan items outside the 48-09 file set. — Scope boundary requires logging out-of-scope failures instead of widening this task into guide or dashboard module files.
- [Phase 48-11]: Old start, reference, runtime, and comparison source paths are compatibility bridges only; canonical public guide truth stays under guides/. — Plan 48-11 preserves copied docs/*.md links without duplicating canonical guide content or surfacing compatibility stubs as ExDoc sources.
- [Phase 48-11]: Compatibility pages use current guide names and paths first, with old names retained only to explain copied 0.1.x source links. — This preserves Phase 48 D-04 vocabulary while keeping old public source links useful.
- [Phase 48]: Dashboard/reviewer/verification-suite public moduledocs now use canonical guides links and state host-authenticated dashboard scope; query params are UI hints, not tenant authority.
- [Phase 48]: Plan 48-12 stayed documentation-only with no router, DashboardScope, PubSub, verification-suite data, package, or guide-body behavior changes.
- [Phase 48]: Broad adoption-surface guide-fragment and SRE.AlertSink failures remain deferred outside the 48-12 file set.
- [Phase 48]: [Phase 48-13]: Kept SRE and compatibility alias polishing documentation-only; no SRE runtime behavior, sink behavior, wrapper delegation, package config, guide body, or runtime deprecation attributes changed.
- [Phase 48]: [Phase 48-13]: Compatibility alias moduledocs retain exact legacy-wrapper wording for ExDoc contracts while naming final replacement modules and glossary migration notes.
- [Phase 48]: [Phase 48-13]: Broad adoption-surface guide-fragment failures remain out of scope for this plan and are logged in Phase 48 deferred-items.md.
- [Phase 48-14]: Old capability docs paths are compatibility pages only; canonical guide bodies stay under guides/capabilities/.
- [Phase 48-14]: Each compatibility page names the current guide first and mentions old names only as 0.1.x compatibility context.
- [Phase 48-14]: The plan did not touch dev-only docs or ExDoc/package configuration.
- [Phase 48]: [Phase 48-15]: Old reviewer verification and maintainer docs paths are compatibility stubs only; canonical guide bodies stay under guides/.
- [Phase 48]: [Phase 48-15]: Operator verification wording appears only as compatibility context; current public guide name is Reviewer Verification.
- [Phase 48-07]: ExDoc source links now default to main unless SCORIA_DOCS_SOURCE_REF is set or HEAD is exactly tagged as v0.1.2.
- [Phase 48-07]: Public ExDoc modules are filtered through a positive allowlist matching the Phase 48 public reference surface and compatibility aliases.
- [Phase 48-07]: Old docs/*.md paths remain packaged compatibility stubs but are excluded from ExDoc extras.

### Resolved And Deferred Work

- UI follow-up: make approval rejection toasts legible over dense approvals UI — completed in v3.3 Phase 38.
- UI follow-up: add approval decision history for approved/denied/expired requests — completed in v3.3 Phase 39; todo moved to completed at v3.4 closeout.
- Post-v3.1 cleanup: `ci-policy-job-cache-key-mislabel` — completed by policy `MIX_ENV: test` and cache-key contract; todo moved to completed at v3.4 closeout.
- Post-v3.2: SEED-004 test-code determinism (async `IntegrationCase`, `Process.sleep` removal) — leading candidate for next milestone.
- Post-v3.2: FLEET-01 sibling-repo convergence (rulestead/parapet) — `docker-dx-fleet-hardening` todo.

### Blockers/Concerns

None active.

- Phase 48 Plan 10 scope-doctrine issue resolved by restoring compatibility-stub fragments expected by `test/scoria/scope_doctrine_contract_test.exs`.
- Phase 48 Plan 10 generated-doc issue resolved by cleaning generated ExDoc output before release preview rebuilds `doc/`.

### Roadmap Evolution

- v3.4 roadmap created (2026-07-04): Phases 42–45 promoted SEED-006 from the backlog. 42 eval / 43 knowledge / 44 dashboard independent; 45 correctness sweep + closeout depends on 42 + 43. 17/17 requirements mapped.
- v3.4 completed and reconciled (2026-07-09): Phases 42–45, 24/24 plans, 17/17 requirements, audit `passed`; SEED-006 archived and removed from the forward backlog.
- v3.5 roadmap created (2026-07-09): Phases 46-50 promote SEED-005 from the backlog for terminology, README/scope doctrine, ExDoc/guide ladder, AI-accessible docs, and the clean `0.1.3` release cut. 18/18 requirements mapped.
- Phase 41.1 inserted after Phase 41: Wire orphaned ScoriaWeb.Copy/DatasetCopy into dataset page (COPY-01 SSOT) — surfaced by v3.3 milestone audit (URGENT)

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Test determinism | SEED-004: async IntegrationCase, remove Process.sleep, raise shard count | Deferred | v3.1 close |
| Fleet convergence | FLEET-01: migrate sibling repos onto shared Traefik + unpublished-DB standard | Deferred | v3.2 scope decision |
| Fleet targets | FLEET-02: `make nuke-all` fleet-wide teardown (high blast radius) | Deferred | v3.2 out-of-scope |
| v3.0 gaps | Phase 13/14 verification-doc gaps (functional: 0 unsatisfied; 10 partials are proof-only) | Deferred | v3.0 close |
| Release | Publish 0.1.1 → superseded by 0.1.2 in Phase 35 | Absorbed into REL-01 | v3.2 REL |
| Trust/security P0 | SEED-006: eval fail-open, knowledge cross-tenant leak, dashboard auth bypass — completed by v3.4 (Phases 42–45) | Completed | 2026-07-09 v3.4 close |
| Docs & positioning | SEED-005: terminology sense-aware rename, scope-doctrine/positioning, ExDoc grouping, glossary, curated llms.txt | Active in v3.5 | 2026-07-09 v3.5 start |
| Observability | SEED-007: OTel-GenAI/OpenInference trace foundation | Deferred | 2026-07-03 audit |
| Eval depth | SEED-008: real scorers, judge calibration, regression comparison | Deferred | 2026-07-03 audit |
| RAG depth | SEED-009: precision/NDCG/abstention/staleness + faithfulness/rerank hooks | Deferred | 2026-07-03 audit |
| Agent security | SEED-010: lethal-trifecta governance (⭐ flagship differentiator) | Deferred | 2026-07-03 audit |
| Privacy/feedback | SEED-011: retention/purge, PII masking hook, human-feedback flywheel | Deferred | 2026-07-03 audit |

> **Ordered roadmap + dependencies** for SEED-007…013 live in `ROADMAP.md` `## Backlog` (999.3–999.9); SEED-005 is active in v3.5. "Why" index in `.planning/seeds/README.md`.
| Phase 46 P01 | 4 min | 3 tasks | 11 files |
| Phase 46 P02 | 6 min | 1 tasks | 10 files |
| Phase 46 P03 | 4 min | 1 tasks | 5 files |
| Phase 46 P04 | 7 min | 1 tasks | 13 files |
| Phase 46 P05 | 2 min | 1 tasks | 3 files |
| Phase 46 P06 | 4 min | 2 tasks | 11 files |
| Phase 46 P07 | 14 min | 1 tasks | 14 files |
| Phase 46 P08 | 6 min | 1 tasks | 3 files |
| Phase 47 P02 | 5 min | 2 tasks | 3 files |
| Phase 47 P03 | 10m 33s | 3 tasks | 9 files |
| Phase 48 P01 | 5 min | 2 tasks | 2 files |
| Phase 48 P02 | 5m 29s | 2 tasks | 6 files |
| Phase 48 P03 | 5m 41s | 2 tasks | 5 files |
| Phase 48 P04 | 7m 19s | 2 tasks | 6 files |
| Phase 48 P05 | 8 min | 2 tasks | 5 files |
| Phase 48 P06 | 4m 52s | 1 tasks | 1 files |
| Phase 48 P08 | 5m 10s | 1 tasks | 7 files |
| Phase 48 P09 | 5 min | 1 tasks | 9 files |
| Phase 48 P11 | 4 min | 1 tasks | 5 files |
| Phase 48 P12 | 3m 05s | 2 tasks | 6 files |
| Phase 48 P13 | 28 min | 1 tasks | 8 files |
| Phase 48 P14 | 2m 7s | 1 tasks | 4 files |
| Phase 48 P15 | 1m 12s | 1 tasks | 2 files |
| Phase 48 P07 | 9m 15s | 3 tasks | 2 files |

### Acknowledged at v3.3 milestone close (2026-07-04)

13 open artifacts surfaced by the pre-close audit were **acknowledged as deferred** (not v3.3 gaps — all are forward-backlog seeds or out-of-scope todos). Closeout recorded as `override_closeout`; all 22 requirements met and all 7 phases verified.

| Category | Item | Status |
|----------|------|--------|
| todo | `add-approval-decision-history` (functionally delivered by FLOW-04 / Phase 39; file stale) | Completed at v3.4 closeout |
| todo | `ci-policy-job-cache-key-mislabel` (CI cache-key/env mismatch) | Completed at v3.4 closeout |
| todo | `docker-dx-fleet-hardening` (FLEET-01/02; out of scope) | Deferred |
| seed | SEED-003 CI/CD efficiency overhaul | Archived |
| seed | SEED-005 Documentation & positioning overhaul (v3.5 active) | Active |
| seed | SEED-006 Pre-1.0 Trust & Security Hardening — shipped in v3.4 | Archived |
| seed | SEED-007 Trace foundation OTel-GenAI/OpenInference (ROADMAP 999.3) | Deferred |
| seed | SEED-008 Trustworthy eval depth (ROADMAP 999.5) | Deferred |
| seed | SEED-009 Retrieval eval depth & seams (ROADMAP 999.6) | Deferred |
| seed | SEED-010 Lethal-trifecta governance ⭐ flagship (ROADMAP 999.4) | Deferred |
| seed | SEED-011 Privacy & feedback governance (ROADMAP 999.7) | Deferred |
| seed | SEED-012 Architecture-archetype awareness (ROADMAP 999.8) | Deferred |
| seed | SEED-013 Operator IA pivot / Control-Room v2 (ROADMAP 999.9) | Deferred |

## Session Continuity

Last session: 2026-07-10T23:36:56.482Z
Stopped at: Phase 49 context gathered
Resume file: .planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-CONTEXT.md

## Operator Next Steps

- Discuss or plan Phase 49: AI-accessible docs and docs verification gate.
