# Milestones

## v3.4 Pre-1.0 Trust & Security Hardening (Shipped: 2026-07-09)

**Phases completed:** 4 phases, 24 plans, 61 tasks

**Key accomplishments:**

- Fail-closed eval verdict spine with honest not_scored persistence and amber inconclusive dashboard vocabulary
- Dataset promotion now freezes a hashable subject output from workflow step results, and SubjectOutput.resolve/2 fails closed for empty captures across offline and judge modes.
- A key-free exact-match scorer now compares real actual output against expected output with binary pass/fail results and explicit not_scored couldn't-run outcomes.
- Offline replay now scores frozen captured output through ExactMatch and fails closed for mismatches, empty captures, and unknown scorers.
- Judge runner now grades frozen captured output, skips empty captures as not_scored, and persists Verdict-derived run verdicts without live LLM dependencies.
- Online scoring now fails closed: deterministic scoring emits only real negative signals, and promotion requires non-empty real passes.
- Runtime ReleaseGate now blocks non-passing completed eval verdicts with passed-only allowlist semantics, online-run exclusion, ungated telemetry, and an indexed lookup.
- Fail-closed knowledge scope helper with actor-narrowed visibility and registered tenant isolation proof lane
- Tenant-scope storage columns, indexes, and schema validation for knowledge storage and retrieval audit rows
- Knowledge source/list/retrieval boundaries now fail closed on missing tenant scope and persist tenant audit evidence without trusting result payloads.
- Pgvector and Scrypath retrieval leaves now fail closed on missing tenant scope and cannot return foreign-tenant chunks through direct backend or retriever paths.
- Citation quote paths and grounding citation validity now require tenant scope, persist citation audit evidence, and are covered by the full optional knowledge proof lane.
- Phoenix-native dashboard auth seam with host hook pass-through and fail-closed tenant scope resolution
- Home, Connectors, and Incidents now use DashboardScope tenant authority, with spoof-shaped tests proving URL tenant hints cannot switch tenant data.
- Approvals dashboard reads, deep links, PubSub filtering, and decision audit context now consume host-asserted DashboardScope tenant data.
- Workflow dashboard list/detail tenant isolation using DashboardScope assigns and OperatorSurface tenant gates
- Tenant-scoped quality/data dashboard evidence for review candidates, eval runs, and dataset promotion hints
- Prompt release workbench now filters eval and approval evidence by host-asserted dashboard tenant while keeping prompt templates as global catalog metadata
- Dashboard auth seam documentation and source guards now lock host-owned scope authority for AUTH-01 through AUTH-03
- Pgvector retrieval now persists DB-projected raw cosine similarity instead of component-sum score evidence.
- Citation presence now respects explicit answerability labels, and the default chunker is locked as non-overlapping.
- Offline and judge eval paths now record measured score latency and fail closed when configured latency evidence is missing.
- Online scoring now records measured deterministic latency and measured completion duration without fabricating clean-trace pass rows.
- DOC-01 now has an executable doctrine/source contract plus a Phase 45 verification report covering every correctness repair.

---

## v3.3 Design System Stress Test (Shipped: 2026-07-04)

**Phases completed:** 7 phases (36–41.1), 30 plans, 74 tasks
**Timeline:** 2026-06-20 → 2026-07-04 (~15 days)
**Git range:** `d9097e80` → `03d299d4` — 220 files changed (code-only: 71 files, +7,007 / −606)
**Audit:** `passed` — 22/22 requirements satisfied across three sources, 7/7 phases verified, 6/6 integration seams wired, no broken flows. COPY-01 SSOT drift closed by inserted Phase 41.1. See `.planning/milestones/v3.3-MILESTONE-AUDIT.md`.
**Closeout:** `override_closeout` — all requirements met and all phases verified; override reflects only the acknowledged forward-backlog artifacts (3 todos + 10 dormant seeds) deferred at close. Known deferred items: 13 (see STATE.md → Deferred Items).

**Delivered:** Made the embedded `/scoria` operator UI internally coherent from foundations to proof — inventory + dev-only Component Lab, tightened primitives/tokens, JTBD-first operator flows with a decision-first approval drawer and decision-history surface, WCAG 2.2 AA + reduced-motion + 6-width responsive proof, and durable docs/screenshots/drift-guards — without regressing the prior cleanup or changing the public dashboard macro or Hex footprint.

**Key accomplishments:**

- Repository-local baseline inventory artifacts now preserve v3.3 starting truth, strict schema metadata, required risks, and starter rows without runtime/source edits.
- Source-reconciled design-system inventory with 86 canonical JSON rows, 236 documented exclusions, required risks, and a Phase 37+ implementation gate.
- Deterministic 15-scenario Component Lab fixture catalog with a generic 10-state structural derivation, an explicit lab-state-to-tone mapping, and a text-scan guard proving the lab stays out of the public macro, the Hex package, and `lib/`.
- Groups renders the real approval-inbox/workflow-tree/workflow-detail/connector-drawer/incident-evidence lib/ components across all 10 D-11 states via deterministic per-group prop adapters; Fixtures browses all 15 domain-noun scenarios grouped by domain with raw-payload evidence and the locked D-27 empty/error copy.
- Six D-13 viewport-simulator frames sharing one dense table specimen, plus exactly seven curated D-10 overlay/flow probes (dense-approvals-with-toast, mobile summary, drawer/modal, command palette, mobile nav, copy-control, long-evidence) reusing scoria.js hooks with zero new JS.
- Mounted `/scoria/_lab` in the dev-only router (module-scope `Phoenix.LiveView.Router` import, new scope textually separate from the public `scoria_dashboard/2` macro) and built `DevLab.LabLive` — the single param-driven LiveView rendering the D-07 IA shell with exact D-27 copy and dispatching to all seven Wave 1-2 section modules via a fixed compile-time param allowlist.
- Real-browser Playwright proof (`priv/dev/e2e/lab.spec.mjs`, 17 tests) that `/scoria/_lab` renders, persists theme, honors reduced motion, survives a six-width viewport scan, and exercises the Overlays focus/dismiss + dense-toast + copy-control probes — verified green against a live dev server, plus a new `docs/MAINTAINERS.md` "Component Lab" section explaining how to run, inspect, and extend it.
- Fixed transparent unreadable warning/error toasts (D-04) by adding opaque `--scoria-toast-<tone>-bg` tokens composited over the solid elevated surface, repointing toast/flash CSS at them, and locking the fix with a CSS-source guard plus a computed-style browser proof in both themes.
- Closed out ROADMAP Criterion 2's full primitive enumeration (links, badges, timestamps, metadata rows, panels, drawers, modals, forms, tables, lists) with two new regression-guard describe blocks in `ui_component_test.exs` — an audit-and-lock plan that found the codebase already coherent everywhere and added zero production code.
- Thin `page_header/1` (single-string-attr `<h1>`) and an additive `status_label/1` curated-vocabulary upgrade, both landed in `ScoriaWeb.UI` with zero new CSS classes and zero caller changes.
- Five new copy modules (`ScoriaWeb.Copy` + `IncidentCopy`/`DatasetCopy`/`ReviewCopy`/`ConnectorCopy`) delivering the D-25 canonical vocabulary and record-branching operator labels, zero `~H`, all templated on the existing `ApprovalCopy` discipline.
- Extended `ApprovalCopy` as the decision-copy SSOT with an honest D-27 receipt helper, added `Workflows.list_decided_approvals/1`, and routed dev-seed decided/expired fixtures through the real `approve/3` path guarded by a new write-invariant test.
- Migrated 5 LiveViews (orchestrator Home, workflow index, eval-spec index, prompt index, coming-soon) off hand-rolled `.scoria-pagehead`/`.scoria-stub` markup onto `page_header/1`/`stub_page/1`/`empty_state/1`, and fixed the eval-spec module-name suffix + prompt entity_id microcopy offenders.
- Migrated dataset/connectors/review_queue/incidents off hand-rolled page headers onto `page_header/1`, moved review_queue's filter to URL-held state with enum validation, streamed the incidents list, fixed the connectors/review/dataset D-23 microcopy offenders, and added a real D-08 load-error/empty split to the three pages whose data queries were previously unrescued or silently collapsed errors into "no rows".
- Restructured the approvals drawer into a decision-first, de-alarmed layout (single status badge, actions directly under the plain-language consequence, two native disclosures with a stable DOM id, and a magnitude-led confirm modal with neutral Deny), gated by a positive-whitelist `decided?/1` predicate so reversal affordances are structurally absent once an approval is decided.
- One `/approvals` `table/1` now serves Pending and Decided via a URL scope segment with a deep-linkable `?approval=<id>` drawer selection, and the drawer's decided state renders an audit-event-sourced "Approved/Denied by {actor} · {time}" receipt (correcting a discovered upstream attribution bug) instead of the forward-looking approve/deny copy.
- Three Phase-38-idiom source-scan drift guards (D-05 single-header, D-11 scan-convention, D-26 copy) plus 12 new Playwright specs proving FLOW-01/03/04 against the running dashboard — the copy guard caught and required fixing a real, previously-undetected raw-status-atom leak in the incidents severity badges.
- Dev-only `@axe-core/playwright@4.12.1` pin (exact + transitive `axe-core` override) plus two shared harness modules — a single axe-run builder that correctly threads the WCAG tag list and the `target-size` rule override, and a single `boxesIntersect(a,b)` geometry primitive — so no later Phase 40 spec re-pins, re-derives, or drifts on either.
- Two new sub-second, pure-Elixir ExUnit guards — a MOTION-01 tokenization/keyframe scan (5 assertions) and an A11Y-01/A11Y-02 structural-presence scan (8 assertions) — prove the already-green motion and accessibility baseline stays locked, modeled directly on the existing `ui_drift_guard_test.exs` idiom, with zero runtime source changes.
- `focus_wrap`/`push_focus`/`pop_focus` wiring closes the verified A11Y-01 keyboard-operability gap on `drawer/1` and `modal/1` — the $10k-refund approval decision drawer now traps and restores focus like the command palette already did, proven by two new fix-and-assert-atomic Playwright specs plus a non-throwing D-13 live-patch collector.
- Two-tier axe-core proof (A11Y-02): report-only full-lab baseline across all 7 dev-lab sections in both themes surfaced one genuine contrast defect, which was fixed at the token SSOT (repointing --scoria-text-subtle off pumice-500); the curated assert-zero scan then passed clean on all 7 seeded real pages in both themes (14/14).
- RESP-01 proven across 6 widths on 4 anchor pages (Home/Workflows/Approvals/Incidents) via a new tiered D-16(1)-(7) Playwright catalog, MOTION-01 proven via a dedicated reduced_motion.spec.mjs (incl. the infinite skeleton), and shots.mjs widened to the 6-width matrix — with one real 24px WCAG 2.5.8 target-size defect found and fixed along the way.
- Fixed the two CRASH-class LiveView bugs from Phases 39/40 (CR-01 dismiss_candidate, WR-04 origin_context KeyError) plus the D-18 table-scroll aria-label, each locked by a red-to-green regression test.
- New `async: false` Floki-over-rendered-HTML guard renders all 9 static/index dashboard routes via `Phoenix.LiveViewTest.live/2` and asserts no `panel`/`page_section` region title restates the page's own `page_header/1` `<h1>` text — closing the dynamic/interpolated blind spot the existing static-literal source-scan guard (`single_header_guard_test.exs:28-30`) self-declares it cannot see.
- New `docs/design_system.md` (11 sections, Rule -> SSOT -> Guard -> Example) pairs every named dashboard design-system convention with the real, existing drift guard that enforces it, locked by a 1:1 clone of the docker-DX doc-contract precedent wired into the CI-gated policy lane — completing PROOF-02 as a matched pair with PROOF-03.
- Closed the two real screenshot-matrix gaps (D-14) by adding a toast-timing-safe `/_lab/overlays` capture to both screenshot scripts, regenerated the committed contact-sheet manifest against a real local run, and flipped the D-04 D-13 drawer live-patch collector to a throwing assertion after verifying it never warns.
- Authored the milestone-closing bookkeeping: `41-GAP-REGISTER.md`'s three-part fixed/deferred/surfaced-unfixed structure (mirroring the v3.0 `gaps_found` precedent) and this SUMMARY's D-19 verification-evidence manifest, which maps PROOF-01/02/03 to the real green artifacts Phases 36-41 produced and names all 9 confirmed pre-existing red tests (3 ExUnit + 6 Playwright) so no "suite green" claim in the milestone record is false.
- Closed the COPY-01 SSOT tech-debt item: UI.status_label/1 now delegates to Copy.status_label/1, and dataset_live/index.ex sources its empty-state title/state-label/version tokens from Copy/DatasetCopy — all byte-identical to the prior operator-visible copy.

---

## v3.2 Drydock (Shipped: 2026-06-19)

**Phases completed:** 7 phases (29–35), 15 plans
**Timeline:** 2026-06-18 → 2026-06-19
**Audit:** `passed` — 14/14 requirements satisfied, 7/7 phases verified, 1/1 integration edge wired, 4/4 flows green. See `.planning/milestones/v3.2-MILESTONE-AUDIT.md`.
**Tag:** `v3.2` annotated tag pending
**Known deferred items at close:** 5 (see STATE.md Deferred Items) — `SEED-004`, `FLEET-01`, `FLEET-02`, `ci-policy-job-cache-key-mislabel`, and `make-approval-toasts-legible`

**Delivered:** Makefile hardening (Phase 29) made `make dev` default to `4799`, added safe cleanup/fleet targets, and made `make` print help; launch banner + native-dev notice (Phase 30) derived the `/scoria` route list from the router and showed Traefik + native-dev guidance; Dockerfile caching audit/doc (Phase 31) proved CSS/HEEx-only edits do not force a refetch/recompile; secrets pattern + local key closeout (Phase 32) documented direnv + 1Password and closed the plaintext `.env` concern; docs restructure + verification-copy correction (Phase 33) rewrote `docs/docker_dev_dx.md` as the reference standard; Docker DX drift guard + CI guard extension (Phase 34) pinned the docs contract and extended CI policy coverage to `post-publish-smoke.yml`; and the maintenance release (Phase 35) shipped `0.1.2` to Hex with a green post-publish registry smoke and live upgrade proof.

**Key accomplishments:**

1. **Makefile hardening (Phase 29, DXCLI-01/02/03/04):** The Makefile became the single trustworthy entry point, with `PORT ?= 4799`, scope-safe `clean`/`nuke`, a fleet view, and generated help.
2. **Launch banner + native-dev notice (Phase 30, DXCLI-05):** The launch banner now derives the `/scoria` route list from `mix phx.routes ScoriaWeb.DevRouter` and shows the Traefik admin link plus native-dev guidance on separate lines.
3. **Dockerfile caching guarantee (Phase 31, CACHE-01):** CSS/HEEx-only edits were empirically proven not to refetch deps or trigger a full app recompile, and the cache invariant is documented in `Dockerfile.dev`.
4. **Secrets pattern and key closeout (Phase 32, SEC-01/02):** The repo now documents direnv + 1Password (`op run`) usage and closes the local plaintext key concern without claiming unnecessary rotation.
5. **Docs truth + drift guard (Phases 33–34, DOCS-01/02/03):** The canonical Docker dev-DX docs were rewritten for maintainer empathy and pinned by a dedicated policy-lane contract that rejects stale `localhost:4000` guidance.
6. **Maintenance release closeout (Phase 35, REL-01/02/03):** `0.1.2` shipped on Hex, the post-publish smoke passed, and the live upgrade proof exercised `0.1.0 -> 0.1.2`.

---

## v3.1 CI/CD Velocity (Shipped: 2026-06-17)

**Phases completed:** 6 phases (23–28), 9 plans, 13 tasks
**Timeline:** 2026-06-14 → 2026-06-17
**Audit:** `passed` — 13/13 requirements satisfied, 6/6 phases verified, 9/9 integration edges wired, contract suite green (51/0). See `.planning/milestones/v3.1-MILESTONE-AUDIT.md`.
**Tag:** `v3.1` annotated tag created locally on `main` — push is the user's call.
**Known deferred items at close:** 5 (see STATE.md Deferred Items) — SEED-003 (the seed that became this milestone), Phase 26 live-shard UAT/verification (satisfied GREEN by run 27709716751), and 2 post-ship todos (`ci-policy-job-cache-key-mislabel`, `docker-dx-fleet-hardening`).
**Velocity headline:** v3.1: PR CI serial-baseline critical-path 77m→**7m38s MEASURED** (Phases 23-28, warm-cache; baseline 27508317719 / measured 27709716751 commit 06cdc34 — VELO-01 MET; see `28-VELOCITY-PROOF.md` for full computation)

**Delivered:** Build-once job (Phase 23) compiling once and sharing `_build/test` + `deps` artifact
to downstream parallel jobs; knowledge lane scoped to `--only knowledge` (Phase 24, reclaims ~22min
when parallelized); full parallel fan-out topology `policy → build → { test, ratchet, knowledge,
connector, full-suite[×4 matrix] } → verify-summary` with a single stable fan-in (Phase 25); 4-way
`--partitions 4` full-suite sharding across isolated `scoria_test1..4` databases (Phase 26); flake
elimination — fixed Postgres host-port bind (Phase 27), removed TEMP e2e diagnostic step, added
zero-retry-default policy with 3 durable contract guards in `ci_policy_contract_test.exs` (42→45
tests); the `mix ci` DX alias (Phase 28); and the compile-only ratchet warning capture (Plan 28-03,
cutting the ratchet lane from ~19m07s to 1m46s, WARN-06 parity-guarded). Phases 24-28 (knowledge fix,
parallelization, sharding, flake elimination, DX alias, compile-only ratchet) were pushed to GitHub and
ran GREEN in run 27709716751 (commit 06cdc34, 2026-06-17) — the fully-parallelized topology is
MEASURED, not projected. VELO-01 MET: 7m38s critical path ≤ ~15m target.

**Key accomplishments:**

1. **Cache correctness + build-once (Phase 23, CACHE-01/02):** MIX_ENV-scoped cache keys (OS+OTP+Elixir+MIX_ENV+mix.lock) replace bare `runner.os-mix-` keys; a dedicated `build` job compiles once under `MIX_ENV=test` WAE and ships a tarred `_build/test`+`deps` artifact to every downstream job — zero recompile, proven in CI run 27514007418.
2. **Knowledge lane scope fix (Phase 24, KNOW-01):** knowledge lane runs `--only knowledge` (13 tests, 732 excluded) instead of the full suite, with the CI YAML and `mix test.knowledge --warnings-as-errors` contract string byte-unchanged.
3. **Lane parallelization + topology docs (Phase 25, PAR-01/02/03, DX-02):** the serial `verify / test` job fans out to parallel `needs:` jobs gated by one stable `if: always()` + skipped-as-failure `verify-summary`; the `CI / ci-gate` required-check name stays put and MAINTAINERS/operator_verification/README move in lockstep, contract-guarded.
4. **Full-suite partition sharding (Phase 26, SHARD-01):** `mix test --partitions 4` across a 4-runner matrix on isolated `scoria_test1..4` DBs, zero coverage loss (rem-completeness math + structural contract + `after_suite` zero-test guard); live 4-shard run confirmed GREEN in run 27709716751.
5. **Determinism + flake elimination (Phase 27, FLAKE-01/02/03):** replaced the ephemeral-range `55432:5432` Postgres host-port bind (root cause of run 27508317719) with `5432:5432` across all 5 gated job blocks, removed the leftover TEMP e2e diagnostic step, and documented a zero-retry-default retry-vs-fix policy — pinned by 3 durable contract guards (42→45 tests).
6. **DX `mix ci` alias + velocity closeout (Phase 28, DX-01, VELO-01):** SSOT-driven `Mix.Tasks.Scoria.Ci` reproduces the merge gate locally (run-all-aggregate, pgvector preflight, actionable PARTIAL opt-out, command strings sourced from `Scoria.VerificationLanes`); plus VELO-01 MEASURED at 7m38s critical path in run 27709716751.

---

## v3.0 Control Room (Shipped: 2026-06-14)

**Phases completed:** 7 phases (11–17), 38 plans, 65 tasks
**Timeline:** 2026-06-04 → 2026-06-13 (interleaved with the v2.17 Vesicle interjection)
**Audit:** `gaps_found` accepted at close — 18/28 requirements fully satisfied, 10 partial, 0 unsatisfied (see Known Gaps below and `.planning/milestones/v3.0-MILESTONE-AUDIT.md`).

**Delivered:** The embedded `/scoria` operator dashboard reached "insane polish" — a fully-adopted token-first design system (`ui.ex` is now the enforced component gateway, raw-palette count verified zero across `lib/scoria_web/` via the DS-06 drift guard), a persona/JTBD information architecture (3-group nav, Status Home, breadcrumbs, ⌘K palette, honest reserved-name stubs), brand-tied motion with full light/dark parity, and a committed dev-only screenshot + LLM-critique evaluation loop with seed data exercising every screen.

**Key accomplishments:**

1. **Evaluation loop + seed depth (Phase 11):** Committed dev-only `mix scoria.ui.shots` harness (Playwright state-matrix capture + decoupled ReqLLM 9-dimension critique) and an idempotent `dev_seed.exs` that populates all 9 dashboard screens — establishing the proof loop every later phase re-runs.
2. **Design-system component layer + drift guard (Phase 12):** `ui.ex` now exposes `table`/`drawer`/`modal`/`field`/`form_section`/`notebook`/`skeleton`/`toast` plus a semantic `flash_group`, all token-bound; the DS-06 ratchet guard fails the build on any raw palette class and runs unconditionally in `mix test`.
3. **Orientation spine / IA (Phase 13):** Three-group nav (Operate/Improve/Configure) with route-aware active state, a Status Home that orients newcomers without adding a click for power users, object-aware breadcrumbs, a ⌘K command palette + keyboard shortcuts, cross-screen quality-loop threading, and 5 honest "coming soon" reserved-capability stubs (no fabricated data).
4. **Full screen conversion (Phases 14–15):** Review Queue, Incidents, Eval Workbench, Prompt Registry/Release, plus high-traffic Live Ops, Workflows, Approvals, and Connectors all render through shared components at zero raw-palette leakage; a real Dataset Builder `/datasets` index converges the duplicated promote affordances; 13 evidence components collapse into thin notebook-shell adapters.
5. **Motion + responsive + theme parity (Phase 16):** Mobile-first shell + accessible off-canvas nav drawer, responsive tables with opt-in mobile summary cards, focus-visible/non-color-only-status hardening, and full light+dark WCAG-AA parity — mechanically proven by a 22/22 Playwright parity smoke.
6. **Consistency sweep + proof (Phase 17):** Final-audit report with a baseline→final rubric-delta table and a verified raw-color-zero assertion, a reusable before/after contact-sheet generator, and a `docs/MAINTAINERS.md` design-system catalog + harness usage entry-point.

### Known Gaps

Closed with `status: gaps_found` accepted as tech debt. **0 requirements unsatisfied**; the 10 partials below are documented and carried forward — none is a functional regression in the dev harness.

| REQ-ID | Phase | Reason partial |
|--------|-------|----------------|
| IA-01 | 13 | Verification doc missing — no `13-VERIFICATION.md`; functionally CONNECTED (integration check confirms 3-group nav SSOT + `aria-current` active state). |
| IA-02 | 13 | Verification doc missing — Status Home at `/` with async summary + 4 attention-card types CONNECTED. |
| IA-03 | 13 | Verification doc missing — `object_header/1` breadcrumbs with parent-path context CONNECTED. |
| IA-04 | 13 | Verification doc missing — ⌘K command palette wired to nav command sections CONNECTED. |
| IA-05 | 13 | Verification doc missing **plus** functional threading gap: incident→trace deep-link fragile (OrchestratorLive drops `?from=`, no `handle_params/3`, anchor relies on last-25 async hydration); dataset→eval edge has no explicit cross-screen affordance (sidebar/⌘K only). |
| IA-06 | 13 | Verification doc missing — 5 reserved-name stubs via `ComingSoonLive` allowlist CONNECTED. |
| SCREEN-01 | 14 | Verification doc missing — Review Queue/Incidents/Eval Workbench/Prompt Registry+Release use shared components at zero raw palette CONNECTED; note `review_queue_live.ex:58` hardcodes `/scoria` mount path (portability one-liner, WARNING-only in dev harness). |
| SCREEN-02 | 14 | Verification doc missing — Dataset Builder `/datasets` real route + promote drawer CONNECTED. |
| PROOF-01 | 17 | Final LLM critique not mechanically re-run (no `ANTHROPIC_API_KEY`); a deterministic 11-item P1 resolution checklist was substituted (each item mapped to resolving phase + re-verifiable code evidence). Raw-palette-zero claim independently VERIFIED. |
| PROOF-02 | 17 | Only 2 of 9 screens (live_ops, approvals) have paired before/after contact-sheet captures; remaining 7 baseline-only (Phase 17 harness halted by an approvals modal scrim intercepting pointer events). |

**Known deferred items at close:** 2 (see STATE.md Deferred Items) — SEED-003 CI/CD efficiency overhaul (becomes the next milestone, v3.1 CI/CD Velocity) and the `docker-dx-fleet-hardening` todo (future work). Both intentionally left in place, not resolved.

---

## v2.17 Vesicle — Brand System (Shipped: 2026-06-11)

**Phases completed:** 5 phases (18–22), 12 plans, 2 user gates + 1 ship-it checkpoint, 8 requirements (+ 1 conditional not-fired)

**Key accomplishments:**

- 14-section brand-book pressure-test (`brandbook/pressure-test.md`, 1,311 lines) with 15-dimension scorecard, 52-pairing WCAG contrast audit (0 FAIL), and suite-coherence assessment vs Threadline + szTheory DNA
- Gate #1 (Phase 18): user approved Decisions Locked section with tagline override to "AI ops for Phoenix apps." and `propagation: not-required` verdict; BRAND-09 conditional correctly did not fire
- Gate #2 (Phase 19, 2 rounds): TV-1 "Span rail" mark locked (round 1); LK-B "Mark-as-o" fused lockup locked (round 2, escape path fired as designed); 29 candidates programmatically generated and verified (verify-logos.mjs 19/19 PASS)
- 8-variant logo set (Phase 20): `logo-primary.svg`, `logo-primary-light.svg`, `logo-mark.svg`, `logo-monochrome.svg` (currentColor), `logo-lockup-subtitle.svg`, `logotype-integrated.svg`, `favicon.svg` (734 bytes, pixel-snapped), `social-card.svg` — optically corrected, user-confirmed "ship it"
- Canonical `brandbook/` (Phase 21): `tokens.json`/`tokens.css` (4-source hex consistency gate green), `brand-book.md` (543 lines), 7 SVG examples (25.7 KB), `index.html` (55 KB, file:// offline, zero network refs), `README.md` maintenance rules — 458 KB total, zero binaries
- Integration (Phase 22): README picture-element header, dashboard TV-1 mark + compile-time data-URI favicon (`ScoriaWeb.Assets.favicon_data_uri/0`), `mix.exs` + GitHub descriptions verbatim brand copy; `quality-gate.mjs` 8/8 PASS; mix test 632 green; DS-06 byte-identical; `test/support/ds06_baseline.txt` and `assets/css/02-tokens.css` untouched

**Known deferred at close:** Publish `0.1.1` via release-please (pre-existing release queue); BRAND-MOTION (v3.0 Phase 16 scope); BRAND-SITE (marketing landing page blueprint in brand book only). See `.planning/milestones/v2.17-MILESTONE-AUDIT.md`.

---

## v2.16 ReqLLM Peer Bump (Shipped: 2026-05-30)

**Phases completed:** 4 phases (08–10 + 10.1 inserted), 4 requirements, 1 plan

**Key accomplishments:**

- ReqLLM peer dependency bumped to `~> 1.13` (locked at 1.13.0)
- Orchestrator, judge runner, compaction worker, and observe adapter verified against bumped ReqLLM
- `mix scoria.test.ci_trust` green — no new warning debt from transitive lock updates
- CHANGELOG `[Unreleased]` notes peer bump
- Phase 10.1 retroactive VERIFICATION ledgers — milestone audit `passed`, `requirements_process: 4/4`

**Known deferred at close:** Publish `0.1.1` via release-please; ReqLLM streaming adapter (ECOS-02); SummarizeWorker dedicated unit test (see `.planning/milestones/v2.16-MILESTONE-AUDIT.md`).

---

## v2.15 Connector Adoption Lane (Shipped: 2026-05-30)

**Phases completed:** 4 phases (05–07 + 07.1 inserted), 6 requirements, 1 plan

**Key accomplishments:**

- Named `mix test.connector` lane in `VerificationLanes` (not in closeout order)
- `Mix.Tasks.Scoria.Test.Connector` bounded test bundle with SupportJourney integration proof
- Docs/drift guards in `adoption_lanes.md`, `connector_adoption.md`, README
- PR CI WAE: connector lane after knowledge, before advisory gallery
- Phase 07.1 retroactive VERIFICATION ledgers — milestone audit `passed`, `requirements_process: 6/6`

**Known deferred at close:** Publish `0.1.1` via release-please; local `mix test.connector` migrate ordering (see `.planning/milestones/v2.15-MILESTONE-AUDIT.md`).

---

## v2.14 Maintenance Release & Registry Upgrade Proof (Shipped: 2026-05-30)

**Phases completed:** Thin release prep (bundled with v2.12 closeout)

**Key accomplishments:**

- Version bumped to `0.1.1` in `mix.exs` and `.release-please-manifest.json`
- Adopter-readable CHANGELOG entry for `0.1.1`
- Release-please path ready for registry semver upgrade smoke (`0.1.0` → `0.1.1`)

**Known deferred at close:** Hex publish via release-please merge (manual release gate).

---

## v2.13 Adopter Docs Truth & Package Surface (Shipped: 2026-05-30)

**Phases completed:** Thin docs pass (bundled with v2.12 closeout)

**Key accomplishments:**

- README: Hex Docs badge, session keys for `/scoria`, deduped install, maintainer section at bottom
- Operator verification trimmed for adopters; maintainer content in `docs/MAINTAINERS.md`
- `mix.exs`: tags, HexDocs homepage, Documentation + Changelog links, CHANGELOG.md in docs extras
- `docs/connector_adoption.md` in Hex package/docs extras

---

## v2.12 Adoption Confidence & Reference Demo (Shipped: 2026-05-30)

**Phases completed:** 3 phases (02–04), 9 requirements

**Key accomplishments:**

- `Scoria.SupportJourney.Handlers` SSOT shared by overlay smokes and support copilot gallery
- Gallery optional lane journeys: semantic FAQ, knowledge refund policy, billing connector
- Gallery producer-path orchestrator smoke on `/scoria`
- `docs/MAINTAINERS.md` split from adopter operator guide; connector adoption in Hex package
- Version `0.1.1` prepared with adopter-readable CHANGELOG

**Known deferred at close:** Registry semver upgrade leg exercises on next Hex publish; v2.15 connector adoption lane queued.

---

## v2.11 Orchestrator Live Wiring (Shipped: 2026-05-30)

**Phases completed:** 2 phases, 6 plans, 22 tasks

**Key accomplishments:**

- Tenant-scoped trace delta fan-out from telemetry via OperatorBroadcast and TraceProjection, with redact-before-broadcast hook and adapter metadata enrichment
- Tenant-scoped HITL projection fan-out, hybrid approval modal/inbox UX, incremental trace merge, and per-span LLM token previews wired into OrchestratorLive
- Tenant-scoped trace DB hydrate on reconnect, Runtime.start_run integration tests without send/2, semantic lane pin, and adoption doc session contract close ORCH-LIVE-01
- Span-delta PubSub and DB hydrate paths now redact before broadcast/projection, with scrub_text for embedded secrets in streaming chunks
- Approve and reject HITL decisions proven on Runtime.start_run producer path via render_click, with modal cleared and secrets never in DOM
- Public emit_span_delta/1, timer cancel on span stop, and integration proof that coalesced token previews render on active LLM spans via the producer path

**Known deferred at close:** Phase 01.1 missing Nyquist VALIDATION.md (non-blocking); ReqLLM streaming adapter deferred to v2.12+; optional conversational `/gsd-verify-work` browser walkthrough. See `.planning/milestones/v2.11-MILESTONE-AUDIT.md`.

---

## v2.10 Hex Consumer Proof & Upgrade Smoke (Shipped: 2026-05-30)

**Phases completed:** 5 phases (78–82), 15 plans, 4 requirements

**Key accomplishments:**

- `HexConsumerContract` SSOT with fingerprinted unpack cache and tarball dep tuples.
- Merge-blocking tarball consumer full overlay in `mix test.adoption` (handoff → route → runtime).
- Content-revision upgrade smoke from committed `scoria-0.1.0-unpack` fixture to HEAD tarball.
- Blocking `mix scoria.post_publish_smoke` registry attest in release-please and hex-publish workflows.
- DOCS-HEX-01 drift guards: `adopter_doc_surfaces/0`, `adoption_surface_test`, `ci_policy_contract_test` gate map pins.

**Known deferred at close:** Registry semver upgrade leg latent until `0.1.1+` publishes; Nyquist missing for phases 78–82 (non-blocking); orchestrator live wiring → v2.11.

---

## v2.9 Adoption Journey & Reference Demo (Shipped: 2026-05-29)

**Phases completed:** 6 phases (74–77.2), 3 formal plans + PR #4 commit-driven delivery, 8 requirements

**Key accomplishments:**

- `Scoria.SupportJourney` fixture SSOT ships with package (`priv/fixtures/support_journey/`, source contract tests).
- Merge-blocking host-proof overlay proves resume and bounded handoff using shared journey identities.
- Committed `examples/support_copilot/` gallery with default-lane and handoff LiveView journey tests.
- Advisory `mix scoria.test.support_copilot` lane documented and excluded from `closeout_order/0`.
- Multi-surface drift guards pin README, operator verification, and gallery guide via `adopter_doc_surfaces/0`.
- CI contract test asserts gallery lane runs after knowledge WAE in `ci-verify.yml`.

**Known deferred items at close:** 2 queued in STATE.md (Hex consumer proof v2.10+, orchestrator live v2.11+). Residual tech debt: unused `lookup_support_ticket`, browser gallery smoke, optional Nyquist validation ledgers.

---

## v2.8 CI Hardening & Post-Ship Hygiene (Shipped: 2026-05-29)

**Phases completed:** 1 phase (thin commit closeout), 3 requirements

**Key accomplishments:**

- Semantic fast-path WAE in PR CI after closeout lanes without widening `closeout_order/0` (SEM-CI-01).
- `mix test.knowledge --warnings-as-errors` added to CI test job after full-suite WAE (CI-KNOW-01).
- `mix scoria.warning_inventory.check_baseline` in policy job with empty-clusters enforcement (CI-INV-01).
- Post-publish smoke workflow checkout fix; v2.7 smoke attestation closed at v2.8.
- Operator gate map and `docs/connector_adoption.md` updated for v2.8 CI topology.

**Known deferred items at close:** 0 (open-artifact audit clear at closeout). Phase 73 planning directory optional tech debt.

---

## v2.6 Warning Ratchet (Shipped: 2026-05-28)

**Phases completed:** 4 phases, 15 plans, 35 tasks

**Key accomplishments:**

- Executable WARN-03 baseline expiry enforcement via Scoria.WarningBaseline and mix scoria.warning_baseline.check.
- WARN-03 wired into GitHub Actions via policy/test job split with contract-tested ordering.
- WARN-04 maintainer inventory path with hybrid cluster classification and write artifacts for Phase 67.
- WARN-06 infrastructure: WarningRatchet path SSOT, scoped ratchet Mix tasks, and committed inventory with Phase 67 fix/defer queue
- WARN-05 compile and lane-contract WAE verified green; operator docs and CI policy contract guard WarningRatchet SSOT without expanding policy job scope
- Knowledge redefine cluster cleared via migrate-once migrator; host-proof overlay guarded under priv/; adoption-lane compile warnings fixed with inventory refresh
- Removed dead default args from review queue unit test; test/scoria non-live p3 inventory clusters at zero with ratchet check green
- LiveView p3 inventory clusters at zero; WARN-06 ratchet.test green with final inventory and Phase 67 verification evidence
- Shared test/tmp preflight and post-capture cleanup for ratchet.check, unified JSON inventory encoding for tuple dedupe_key rows, and cwd-memoized high-signal path membership.
- Staged high-signal WAE gate in CI test job after runtime_to_handoff, with gate-order contracts and operator docs mapping ratchet to adoption paths — without full-suite WAE until plan 68-03.
- p2 host-proof warning clusters verified at zero via full inventory and adoption/ratchet WAE closeout — no support or overlay code changes required before 68-03 full-suite attempt.
- WARN-07 closed: CI runs `mix test --warnings-as-errors` after closeout lanes; baseline ledger empty; LiveView render_async sweep and installer build isolation made full suite green.
- CI-03 documentation bundle ships maintainer CI gate map, commented ci.yml topology, README link, contract-test doc anchor, and planning prose aligned to Phase 68 executable CI — with zero step reorder.
- Symmetric `test/tmp` lifecycle in `warning_ratchet.test` and subprocess ratchet-check integration test restore maintainer ratchet→inventory trust from 68-REVIEW WR-01/WR-02.
- CI-03 verification ledger and v2.6 milestone audit; `mix scoria.test.ci_trust` local parity attestation at closeout.

**Known deferred items at close:** 0 (open-artifact audit clear at closeout)

---

## v2.5 Installer Safety & Upgrade Confidence (Shipped: 2026-05-27)

**Phases completed:** 7 phases, 16 plans, 17 tasks

**Key accomplishments:**

- `mix scoria.install --dry-run` now uses a deterministic pure planner contract that classifies router, tailwind, migrations, and runtime config without mutating host files.
- `mix scoria.install --check` now emits deterministic compatibility status with stable trailer output and enforced `0/1/2` exits while remaining no-write.
- Phases 59 and 61 VALIDATION ledgers now match passed VERIFICATION evidence with nyquist_compliant: true and all per-task rows green.
- Phase 60–61 SUMMARY files now carry `requirements-completed` frontmatter aligned to VERIFICATION evidence, matching the phase 59 traceability pattern.
- v2.5 traceability tech debt closed: REQUIREMENTS gap row Complete, audit Nyquist compliant, and Phase 62 VERIFICATION records artifact-only closeout evidence.
- Removed misleading manifest fingerprint merge and exposed honest manifest metadata on the planner artifact.
- Exposed manifest check vs apply roles in human, JSON, and mix help without changing tri-state semantics.
- Documented check vs apply fingerprint semantics for operators and locked them with integration tests.
- Adoption lane discoverability `expected_files` now mirrors `adoption_test_files/0`, closing v2.5 audit gap `adoption-lane-discoverability-drift`.
- Phase 63 Nyquist validation ledger reconciled — 10 green task rows, wave_0_complete, audit trail from 63-VERIFICATION.md
- Milestone Nyquist ledger 5/5 — REQUIREMENTS gap Complete, audit compliant, 65-VERIFICATION passed

---

## v2.4 Adoption Reliability Contract (Shipped: 2026-05-27)

**Phases completed:** 4 phases, 6 plans, 10 requirements

**Key accomplishments:**

- Added one canonical lane contract source (`Scoria.VerificationLanes`) for command, env, prerequisite, and exclusion truth across all verification lanes.
- Bound docs drift guards and lane task tests to canonical lane-contract nouns and boundary wording.
- Cleared release-preview warning debt while enforcing warnings-as-errors and introducing an owner+expiry warning baseline ledger.
- Enforced canonical closeout ordering and warning gates in CI (`release_preview -> adoption -> runtime_to_handoff`).
- Hardened installer browser-scope support for list-form `pipe_through` while preserving idempotent, truthful install behavior.

**Known deferred items at close:** 0 (open-artifact audit clear at closeout)

---

## v2.3 Runtime-to-handoff adoption example

**Shipped:** 2026-05-27

**Phases completed:** 3 phases, 9 plans, 20 tasks

**Key accomplishments:**

- Runtime-to-handoff example contract using the existing Scoria public facade, with projected-context safety boundaries and a passing docs/source baseline.
- Phoenix runtime guide and DB-backed tests now prove the public-facade path from a default Scoria run into a bounded handoff with curated delegated readback.
- Bounded handoff docs now pin host-owned projected-context selection, Scoria-owned validation/readback, and unsafe context rejection before durable delegated run creation.
- Delegated evidence now presents the approved default-lane empty-state contract while retaining curated pending-state and populated delegated lineage behavior.
- Adopter-facing docs now consistently describe default runtime as first adoption and bounded handoff as explicit same-run escalation, with unchanged public API boundaries.
- Phase 53 now has executable drift guards that fail when docs regress default-first lane wording, expose internals, or drop key public facade/readback fragments.
- Added an executable runtime-to-handoff verification lane with enforceable bounded-file and no-optional-prereq contracts.
- Aligned README, support guides, and drift tests on one canonical runtime-to-handoff command contract with explicit lane-boundary truth.
- Finalized closeout truth by aligning CI and operator command order, then capturing executed evidence for all Phase 54 requirements.

**Known deferred items at close:** 3 (Nyquist validation ledgers remain partial; see `.planning/milestones/v2.3-MILESTONE-AUDIT.md`)

---

## v2.1 Tenant-scoped semantic fast path

**Shipped:** 2026-05-25
**Phases:** 3 | **Plans:** 12 | **Tasks:** 28
**Theme:** Inspectable semantic caching for safe read-only lanes

### Delivered

Scoria now ships a tenant-scoped semantic fast path as durable, operator-visible truth: explicitly safe read-only lanes can reuse answers only when prompt, policy, source, freshness, and scope compatibility all pass, while misses, rejects, stale entries, and invalidations remain visible and fall back through the normal workflow path.

### Key Accomplishments

- Added durable semantic cache entry and event truth with explicit hit, miss, bypass, and writeback rejection outcomes.
- Established an explicit semantic-lane contract and conservative eligibility engine for safe read-only runtime work.
- Implemented exact-first plus compatibility-filtered semantic lookup with durable `active`, `stale`, `invalidated`, and `writeback_rejected` lifecycle states.
- Projected semantic provenance, compatibility, and fallback evidence into runtime detail, the runtime drawer, and the workflow notebook.
- Shipped `mix test.semantic_fast_path` as the canonical bounded proof lane and aligned operator docs/source assertions to the same semantic vocabulary.

**Known deferred items at close:** 0

---

## v2.0 Relay

**Shipped:** 2026-05-25
**Phases:** 4 | **Plans:** 11 | **Tasks:** 22
**Theme:** Bounded public handoff proof and clean closeout

### Delivered

Scoria now ships the bounded public handoff lane as explicit, milestone-quality truth: `Scoria.start_handoff_run/3` stays same-run rooted, projected context is narrow and reject-by-default for unsafe state, delegated lineage is inspectable in runtime and workflow surfaces, and the adoption lane plus full suite close on a green verification baseline.

### Key Accomplishments

- Locked the explicit bounded handoff contract with durable delegated kind, handoff input truth, and same-run lineage.
- Hardened recursive projected-context rejection so unsafe nested runtime/session state fails explicitly instead of slipping through.
- Added curated delegated evidence projection and workflow UI surfaces for inspectable lineage, status, and projected context.
- Re-aligned README, bounded handoff docs, checked source fragments, and operator wording around one runtime-first adoption story.
- Preserved `mix test.adoption` as the canonical bounded-handoff proof lane and recorded the Relay closeout ledger against it.
- Restored a fresh full-suite `mix test` pass before ship by fixing offline eval contract drift and sparse approval metadata crashes.

**Known deferred items at close:** 0

---

## v1.9 Crucible

**Shipped:** 2026-05-24
**Phases:** 4 | **Plans:** 18
**Theme:** Replayable debugging and online quality feedback

### Delivered

Scoria now ships a closed operator remediation loop: durable replay branches, replay-safe execution, replay comparison and dataset promotion from workflow evidence, plus asynchronous online scoring that routes reviewable candidates into an embedded operator queue.

### Key Accomplishments

- Added durable replay-branch lineage rooted in checkpoint truth without mutating source run history.
- Enforced replay-safe seam behavior with explicit blocked, historical-stub, and replay-live provenance across workflow, connector, and MCP boundaries.
- Shipped replay comparison UX and frozen workflow-source draft promotion through the existing LiveView operator surface.
- Added async sampled-trace online scoring with deterministic-first and optional judge-backed additive evidence.
- Built a dedicated operator review queue with workflow/runtime deep links, dismissal, draft promotion, and sealed-baseline approval flow.
- Restored the canonical proof chain for all four v1.9 phases and reconciled milestone-state planning surfaces to shipped truth.

**Known deferred items at close:** 3 (project-level full-suite failures outside the owned lanes, connector/compaction warnings, and LiveView async teardown noise)

---

## v1.8 Vanguard

**Shipped:** 2026-05-22
**Phases:** 7 | **Plans:** 19
**Theme:** Multi-model orchestration and distributed evaluations

### Delivered

Scoria now ships resilient multi-model routing with ETS-backed breaker truth, distributed evaluation campaign fan-out through Oban, and a real-time operator dashboard that makes fallback and campaign progress visible without leaving Phoenix.

### Key Accomplishments

- Established isolated `system`, `inference`, and `evals` queues plus batch enqueue primitives for high-volume background work.
- Added circuit breakers, bounded retries, and fallback-chain orchestration across summarization and judge flows.
- Built durable eval campaign, target, and run lineage with coordinator fan-out and worker rollups.
- Shipped tenant-scoped LiveView model-health and campaign dashboards with eval-run drill-in.
- Restored the full canonical v1.8 verification chain and closed the orphaned requirement gaps.
- Reconciled roadmap, state, project, milestone, and strategic-arc surfaces to shipped truth.

**Known deferred items at close:** 1 (Nyquist frontmatter normalization for Phases 30-32 if they re-enter audit scope)

---

## v1.7 Outrider

**Shipped:** 2026-05-20
**Phases:** 3 | **Plans:** 7
**Theme:** Advanced ecosystem integrations and future-bet runtime surfaces

### Delivered

Scoria now supports out-of-process multi-runtime integration capabilities (using MCP over HTTP/SSE) and an asynchronous memory compaction engine via Oban. This allows Scoria to orchestrate external runtimes, efficiently manage long-running session history without context bloat, and track agent presence visually via Phoenix LiveView.

### Key Accomplishments

- Established an HTTP/SSE boundary implementing the MCP Server specification.
- Built an asynchronous Oban-backed memory compaction worker tracking `compacted_memories`.
- Wired external agent health liveliness natively via Phoenix Presence.
- Shipped an updated LiveView Operator UX capable of memory time-travel and displaying agent connection statuses.

**Known deferred items at close:** 0

---

## v1.6 Flightpath

**Shipped:** 2026-05-19
**Phases:** 4 | **Plans:** 12
**Theme:** Release gates, prompt lifecycle, and evaluation operations

### Objectives

Provide a unified prompt lifecycle and evaluation operations suite. Operators should be able to turn traces into datasets, developers should be able to run offline VCR-backed ExUnit evals, and organizations should be able to enforce release gates before a prompt goes live.

### Scope

- **Ecto-backed Prompt Registry:** Immutable versioning and lifecycle for prompts.
- **Trace-to-Dataset Curation:** Elevate real traces into baseline datasets via the dashboard.
- **CI/CD Regression & Evals:** Integration with `mix test`, ExUnit, and VCR cassettes.
- **Release Gates:** Tie EvalRun evidence to Scoria's workflow primitives for operator approvals.

---

## v1.5 Switchyard

**Shipped:** 2026-05-18
**Phases:** 4 | **Plans:** 9
**Theme:** Tool and MCP connector productization

### Delivered

Scoria now productizes remote MCP connector adoption as an embedded Phoenix capability with stateless-first defaults, policy-backed tool scopes, workflow-owned approvals, and operator-grade audit visibility.

### Key Accomplishments

- Established the Scoria-owned remote connector boundary with durable connector records, boring discovery defaults, and auth/grant storage.
- Enforced dual-plane policy, stable local tool identity, and stateless-first invocation defaults.
- Extended Scoria's workflow-owned approval and evidence model into remote connector scenarios with operator-grade visibility.
- Shipped a curated connector profile layer with boring adoption paths.

**Known deferred items at close:** 0

---

## v1.4 Keystone

**Shipped:** 2026-05-17
**Phases:** 7 | **Plans:** 22
**Theme:** Embedded app defaults, identity, and public runtime surface

### Delivered

Scoria now ships a Phoenix-facing runtime surface with canonical actor, tenant, and session identity, a public `Scoria` lifecycle API, predictable defaults and install ergonomics, adoption docs aligned to real runtime behavior, and executable guardrails that keep the public integration story from drifting.

### Key Accomplishments

- Added one canonical runtime identity contract and propagated it across workflows, approvals, telemetry, and audit evidence.
- Promoted `Scoria` into the public runtime facade for start, resume, inspect, and session-aware run access.
- Added documented provider/model/prompt-policy defaults with identity-aware composition and boring install defaults.
- Rewrote the README, moduledocs, Phoenix example, and operator verification flow around the shipped public boundary.
- Backfilled the missing canonical verification chain for Phases 12 through 15 and reconciled live milestone-state artifacts.
- Added executable adoption guardrails, including the named `mix test.adoption` lane, to keep docs aligned with checked runtime truth.

**Known deferred items at close:** 3 (see STATE.md Deferred Items)

## v1.0 MVP

**Shipped:** 2026-05-10
**Phases:** 4 | **Plans:** 13

### Delivered

A Phoenix-native "AI Application Quality Layer" providing deep observability, continuous evaluation, and secure governance tailored for Elixir and Phoenix applications.

### Key Accomplishments

- Implemented Core Observability using Ecto and Telemetry
- Built MCP Gateway & Tool Governance with isolated OTP execution
- Created LiveView Operator UX with token coalescing and HITL approval modals
- Developed Evaluation Flywheel for promoting production traces to testing datasets

---

## v1.1 Caldera

**Shipped:** 2026-05-11
**Phases:** 1 | **Plans:** 4
**Theme:** Durable Agent Workflows & Handoffs

### Objectives

Build a lightweight, OTP-native agent loop capable of managing complex state machines, subagent handoffs, and durable pauses for long-running workflows or operator approval.

### Delivered

Scoria now ships a durable workflow layer with Ecto-backed checkpointing, root-owned delegated handoffs, supervised recovery semantics, and a trace-first workflow visualizer inside the dashboard surface.

### Scope

- **Durable Checkpoints:** Persist the `RunState` into Ecto natively so workflows can survive BEAM restarts, timeout limits, and operator approval delays.
- **Handoffs & Subagents:** First-class support for an agent to cleanly delegate to another `MyAI.Agent` with specialized tools.
- **Jido Integration (Optional):** Provide an adapter to map `Jido` v2 pure-functional decisions/directives into Scoria's observable trace and checkpoint engine.
- **LiveView Workflow Visualizer:** A visual representation of the agent graph/state machine in the admin dashboard.

### Key Accomplishments

- Added durable workflow tables and transactional lifecycle APIs.
- Added supervised runtime execution, exact resume, and retry-failed-step support.
- Added a workflow LiveView under the existing dashboard router surface.
- Added an optional Jido adapter boundary with full end-to-end lifecycle coverage.

---

## v1.2 Corpus

**Shipped:** 2026-05-11
**Phases:** 1 | **Plans:** 6
**Theme:** Advanced RAG, Citations & Knowledge Grounding

### Objectives

Provide batteries-included RAG primitives that natively integrate with the Scoria trace tree and Eval Workbench.

### Delivered

Scoria now ships a durable knowledge layer with pgvector-backed retrieval, provenance-preserving citations, deterministic grounding checks, and trace-first evidence projection inside the dashboard surface.

### Scope

- **Vector Index & Chunking Abstractions:** Clean behaviors for embedding models and chunking strategies.
- **pgvector Integration:** An out-of-the-box Ecto/pgvector adapter to store and query embeddings natively.
- **First-Class Citations:** Ensure the trace explicitly captures "Retrieval" spans, linking the model's generated output back to specific `Chunks` via `Citation` metadata.
- **Groundedness & Hallucination Scorers:** Deterministic and LLM-as-Judge scorers to verify outputs are factually grounded.
- **Scrypath Synergy (Optional):** First-class integration with `Scrypath` as a native retrieval engine. Scoria wraps Scrypath queries in `RETRIEVER` spans so they remain observable and evaluable without forcing external vector databases.

### Key Accomplishments

- Added explicit pgvector bootstrap and a shared knowledge test scaffold.
- Built durable corpus, retrieval, citation, and grounding schemas behind `Scoria.Knowledge`.
- Kept Scrypath optional behind a retrieval normalization boundary.
- Projected evidence and grounding signals into the existing operator surface with async loading.
- Added versioned deterministic-first evaluation for citations and grounding.

**Known deferred items at close:** 1 (see STATE.md Deferred Items)

---

## v1.3 Seismograph

**Shipped:** 2026-05-12
**Phases:** 5 | **Plans:** 20
**Theme:** SRE, Circuit Breakers & Ecosystem Synergy

### Objectives

Harden Scoria into a production-grade control plane with proactive governance, circuit breakers, and deep `szTheory` ecosystem integration.

### Scope

- **Circuit Breakers & Budgets:** Introduce configurable token and cost budgets per tenant/user that trip guardrails when exceeded.
- **Parapet SLO Integration:** Define SLOs for latency, cost, and eval pass rates for the upcoming `Parapet` SRE layer.
- **Threadline Audit Export:** Clean integration to export sensitive `ToolApproval` and MCP access events into immutable audit logs.
- **Automated Regression Alerts:** Automatically trigger incident workflows via `Chimeway`/`Mailglass` when a CI gate dips below the baseline.

### Delivered

Scoria now ships a durable SRE layer with explicit budget reservations and reconciliation, external-effect circuit breakers, runtime and incident telemetry, workflow-owned audit lineage, durable incident and delivery routing, and trace-first operator evidence inside the existing dashboard surface.

### Key Accomplishments

- Closed the breaker-open reservation gap at both workflow and MCP execution seams.
- Restored audited approval handling and durable delivery production on the real incident path.
- Wired live execution and incident lifecycle telemetry while keeping the knowledge lane explicit behind `mix test.knowledge`.
- Backfilled Phase 7 verification and aligned milestone-state artifacts so the repo has a normal validation -> verification -> shipped evidence chain.

**Known deferred items at close:** 1 (see STATE.md Deferred Items)
