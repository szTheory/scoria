# Scoria

## What This Is

Scoria is a Phoenix-native AI application quality layer for Elixir teams. It gives existing Phoenix apps trace-first observability, durable workflow state, knowledge grounding, approvals, operator-visible evidence, and a public runtime surface without forcing teams into a hosted agent platform shape.

The product boundary stays embedded and Ecto/Telemetry-native: Scoria should feel like a library and dashboard surface that fits into a normal Phoenix application, not a separate runtime people have to work around.

## Core Value

Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## Current Milestone: v3.0 Control Room

**Goal:** Take the embedded `/scoria` operator dashboard to "insane polish" — a tightened, fully-adopted design system, a clear persona/JTBD information architecture, brand-tied motion, full light/dark parity, and seed data that exercises every screen — proven by a committed screenshot+critique evaluation loop.

**Core finding driving the milestone:** Scoria's design system is under-*adopted*, not under-built. The token-first CSS already defines tables, drawers, modals, span rails, and disciplined motion, but `lib/scoria_web/ui.ex` never exposed them as components — so ~22/25 view files leaked raw Tailwind (`stone-*/rose-*/...`), worst in the least-iterated screens. The work: expose components → delete leaked classes → consolidate → orient → polish → prove.

**Personas (one shared evidence model, persona-weighted surfacing — nothing role-gated):**
- **On-Call Operator** — watch live runtime, clear approvals, triage incidents, confirm connector health.
- **AI Quality Engineer** — triage flagged traces → promote to dataset → run evals → gate a prompt release.
- **Integrator / Admin** — wire connectors/MCP/tools, set governance policy, watch spend.

**Target features:**
- Committed dev-only screenshot + LLM-critique harness (`mix scoria.ui.shots`) + 9-dimension audit rubric.
- Seed-data depth so Reviews / Incidents / Eval Workbench / Prompt Registry render at their most useful.
- Design-system component layer in `ui.ex` (table+affordances, drawer/modal shells, form controls, unified evidence notebook shell, skeleton, toast) + executable raw-color drift guard.
- Orientation spine: third nav axis (Operate / Improve / Configure), Status-Home landing, real breadcrumbs, `⌘K` command palette, keyboard shortcuts, cross-screen quality-loop threading, honest stub screens for reserved brand names (Dataset Builder, Cost Ledger, Replay Playground, MCP Gateway, Tool Registry, Feedback Inbox).
- Per-screen polish (least-iterated first), restrained brand-tied motion, mobile-first responsive, full light/dark parity.

**Key context:** Keep the custom token-first scoped CSS architecture (no Tailwind/BEM switch); `ui.ex` is the enforced token gateway. UI-only milestone — reserved-name screens with no backend ship as honest "coming soon" stubs, never fake data. Plan: `/Users/jon/.claude/plans/another-ui-pass-so-elegant-garden.md`.

## Latest Shipped Milestone: v2.17 Vesicle (2026-06-11)

**Goal:** Ship a pressure-tested, repo-canonical Scoria brand system in `brandbook/` — audited brand book, locked design tokens, user-chosen programmatically generated logo system, and a professional standalone HTML brand book — wired into README, dashboard favicon/mark, and Hex/GitHub/HexDocs copy.

**Delivered:** brandbook/ canonical brand system (pressure-test.md 1,311 lines, 14 sections; TV-1 "Span rail" mark + LK-B "Mark-as-o" fused lockup chosen across 2 gallery rounds; 8-variant logo set; tokens.json/tokens.css 4-source consistency; brand-book.md 543-line canonical rewrite; standalone index.html 55 KB; 7 examples; 458 KB total); integration (README picture header, dashboard TV-1 mark + data-URI favicon, mix.exs + GitHub descriptions); tagline locked "AI ops for Phoenix apps." (user override at gate #1); mix test 632 green, DS-06 untouched. BRAND-09 conditional did not fire (propagation: not-required). quality-gate.mjs 8/8 PASS.

**Why it mattered:** The AI-generated brand book seed had never been pressure-tested and no logo or collateral existed. v2.17 closed this gap before v3.0 phases 13–17 so the new navigation spine, screen polish, and motion work all ship under a tested brand identity.

## Previous Shipped: v2.16 ReqLLM Peer Bump (2026-05-30)

**Goal:** Keep Scoria's LLM orchestration peer current on Hex without widening product scope.

**Delivered:** ReqLLM `~> 1.13` (1.13.0 locked); integration slice (17 tests) + `mix scoria.test.ci_trust` (43 tests) green. Phase 10.1 closed retroactive VERIFICATION process gap — milestone audit `passed`, `requirements_process: 4/4`.

**Why it mattered:** LLM orchestration peer stays current on Hex without product scope creep or CI regression.

## Previous Shipped: v2.15 Connector Adoption Lane (2026-05-30)

**Goal:** Named connector adoption proof lane with docs/CI/drift-guard parity to semantic and knowledge lanes.

**Delivered:** `mix test.connector`, VerificationLanes `:connector` entry, SupportJourney integration proof, PR CI WAE. Phase 07.1 closed retroactive VERIFICATION/SUMMARY process gap — milestone audit `passed`, `requirements_process: 6/6`.

**Why it mattered:** Connector adoption now has the same executable lane contract, docs truth, and CI posture as semantic and knowledge — without widening closeout order.

## Release Queue

- **Publish `0.1.1`:** merge release-please PR #3 when CI green → registry semver upgrade smoke

## Latest Shipped Milestone: v2.11 Orchestrator Live Wiring

**Goal:** Wire runtime→PubSub trace broadcast and HITL approval modal from real approvals (ORCH-LIVE-01).

**Delivered:**
- `OperatorBroadcast` tenant PubSub fan-out from telemetry with redact→broadcast→buffer ordering.
- HITL modal and inbox from real `Workflows.mark_waiting_for_approval/3` / approve/reject paths.
- `OrchestratorLive` DB hydrate, incremental trace merge, token coalesce, producer-path integration tests.
- Phase 01.1 hardening: delta/hydrate redaction, approval E2E, public `emit_span_delta/1`.

**Why it mattered:** Operators see live traces and real approval pauses without hollow LiveView test paths — closes the post-Hex operator UX gap.

## Previous Shipped: v2.10 Hex Consumer Proof & Upgrade Smoke

**Goal:** Close the post-Hex adopter-trust gap — prove packaged artifact installs, upgrades, and matches v2.9 overlay depth.

**Delivered:**
- Tarball consumer proof in merge-blocking `mix test.adoption`.
- Content-revision upgrade smoke (`0.1.0` fixture → HEAD).
- Blocking post-publish registry attest via `mix scoria.post_publish_smoke`.
- `adopter_doc_surfaces/0` + executable drift guards (DOCS-HEX-01).

**Why it mattered:** Adopters and maintainers share one SSOT for Hex dep shapes, CI topology, and doc pins before orchestrator live wiring.

## Previous Shipped: v2.9 Adoption Journey & Reference Demo

**Goal:** Battle-test Scoria through a realistic support-copilot domain with shared journey fixtures, extended host-proof overlay, and a human-clickable gallery — without weakening v2.4–v2.8 lane contracts.

**Delivered:**
- `Scoria.SupportJourney` fixture SSOT + multi-surface source contract drift guards.
- Merge-blocking host-proof overlay (resume + handoff smokes).
- `examples/support_copilot/` gallery with advisory `mix scoria.test.support_copilot` lane.
- CI contract for gallery-after-knowledge ordering; `closeout_order/0` unchanged.

**Why it mattered:** Adopters get a realistic domain story with executable overlay proof, clickable gallery, and doc↔fixture alignment before Hex consumer proof (v2.10).

## Latest Shipped Release Milestone: v2.7 OSS Release + Docs Truth

**Goal:** Docs truth, then Hex `0.1.0` / `v0.1.0` — without weakening v2.4–v2.6 contracts.

**Delivered:** DOCS-03/04, INST-DX-01, HEX-01/02, Hex-primary README, `package_surface_test` flip.

## Current State

- **Phase 15 complete (2026-06-13, v3.0 Control Room):** High-traffic control-room screens now use shared table/drawer/modal/notebook primitives across Live Ops, Workflows, Approvals, and Connectors; remaining evidence adapters are thin notebook/evidence adapters; DS-06 raw-palette baseline is zero. SCREEN-03 and SCREEN-04 are complete. Next: Phase 16 motion + responsive + theme parity.
- **v2.17 Vesicle shipped (2026-06-11):** Brand system complete — pressure-test.md (1,311 lines), TV-1 mark + LK-B lockup chosen by user (2 rounds), 8-variant logo set, brandbook/ (458 KB, zero binaries), README picture header, dashboard TV-1 mark + data-URI favicon, mix.exs/GitHub descriptions, quality-gate.mjs 8/8 PASS, mix test 632 green, DS-06 untouched. Archived in `.planning/milestones/v2.17-*`.
- **Phase 12 complete (2026-06-04, v3.0 Control Room):** Design-system component layer — `ui.ex` now exposes table/drawer/modal/field/form_section/notebook/skeleton/toast contracts, `flash_group` routes through semantic tokens, and the DS-06 raw-color drift guard runs unconditionally in `mix test` (baseline `test/support/ds06_baseline.txt`, `ui.ex` at zero raw palette). Known polish debt deferred to Phases 14–16 (toast overlap CR-01, drawer positioning WR-03, dialog `aria-labelledby` WR-02) — see `12-REVIEW.md`.
- **v2.16 shipped (2026-05-30):** ReqLLM peer bump to `~> 1.13` (1.13.0); archived in `.planning/milestones/v2.16-*`.
- **v2.15 shipped (2026-05-30):** Connector adoption lane — `mix test.connector`, PR CI WAE after knowledge, drift guards; archived in `.planning/milestones/v2.15-*`.
- **v2.12 shipped (2026-05-30):** Adoption confidence reference demo — SupportJourney.Handlers SSOT, gallery optional lane journeys, orchestrator producer smoke, MAINTAINERS.md split; Hex `0.1.1` prepared.
- **v2.11 shipped (2026-05-30):** ORCH-LIVE-01 complete — orchestrator live trace broadcast and HITL from real runtime/workflow paths; phases 01 + 01.1 in `.planning/milestones/v2.11-phases/`.
- **v2.10 shipped (2026-05-30):** Hex consumer proof milestone archived — phases 78–82 in `.planning/milestones/v2.10-phases/`; audit at `v2.10-MILESTONE-AUDIT.md`.
- **Phase 81 (v2.10):** Post-publish registry gate — `mix scoria.post_publish_smoke` proves live Hex install with exact version pins; blocking `post-publish-attest` wired in release-please and hex-publish workflows.
- **Phase 79 complete (2026-05-29):** Merge-blocking tarball consumer proof runs full v2.9 overlay depth (handoff → route → runtime) via `mix hex.build` unpack dep; operator triage, `SCORIA_PRESERVE_HOST`, and CI failure snapshot artifact wired.
- **Hex:** `0.1.1` prepared locally; `0.1.0` live at https://hex.pm/packages/scoria (tag `v0.1.0`, 2026-05-29).
- Phase 73 CI hardening complete (2026-05-29): semantic lane + knowledge WAE + inventory baseline check in `ci-verify.yml`; operator gate map updated.
- Phase 72 Hex publish closeout complete (2026-05-29): README Hex-primary; release-please without `release-as` pin.
- CI policy→test topology: `warning_baseline.check` → `warning_inventory.check_baseline` → compile WAE → lane-contract WAE (policy); closeout lanes → semantic WAE → ratchet hygiene → full-suite WAE → knowledge WAE (test).
- Warning inventory and ratchet maintainer paths (`mix scoria.warning_inventory`, `mix scoria.warning_ratchet.*`) classify and clear debt by surface; baseline ledger empty (`"clusters": {}`).
- Full-suite `mix test --warnings-as-errors` is green locally; `mix scoria.test.ci_trust` bundles Phase 69 contract verification.
- Installer preview/check/apply truth from v2.5 remains SSOT; canonical lane order unchanged.
- Milestone archives: `.planning/milestones/v2.6-ROADMAP.md`, `v2.6-REQUIREMENTS.md`, `v2.6-MILESTONE-AUDIT.md`.

**Preserve:** v2.4 `VerificationLanes.closeout_order/0`, v2.5 installer truth, v2.6 warning-ratchet gates, v2.7 Hex adopter flip, v2.8 CI topology, v2.9 SupportJourney + gallery advisory lane.

## Requirements

### Validated

- ✓ Canonical actor, tenant, and session identity are explicit public runtime nouns. — `v1.4 Keystone`
- ✓ Developers can start, resume, and inspect app-facing runs through the public `Scoria` runtime surface. — `v1.4 Keystone`
- ✓ Provider/model/prompt-policy defaults are installable through one documented application-facing surface. — `v1.4 Keystone`
- ✓ Adoption docs and verification flows align to executable proof lanes instead of prose-only guidance. — `v1.4 Keystone`
- ✓ Remote MCP connectors can be registered through a Phoenix-native Scoria boundary with boring defaults for discovery, auth, and capability refresh. — `v1.5 Switchyard`
- ✓ Remote connector invocation preserves Scoria identity, tool policy, approval, and audit evidence without turning Scoria into a hosted connector platform. — `v1.5 Switchyard`
- ✓ Operators can inspect connector health, granted scopes, approvals, and remote invocation evidence through the embedded dashboard surface. — `v1.5 Switchyard`
- ✓ Scoria ships a small curated connector/profile layer that improves DX for common remote-tool adoption paths without widening the core product boundary. — `v1.5 Switchyard`
- ✓ Multi-model runtime calls automatically degrade through breaker-aware fallback chains instead of failing at the first unhealthy model. — `v1.8 Vanguard`
- ✓ Large evaluation campaigns can fan out durably across many runtime targets through Oban-backed coordinator and worker flows. — `v1.8 Vanguard`
- ✓ Operators can inspect model health, fallback usage, and campaign progress through the embedded dashboard surface. — `v1.8 Vanguard`
- ✓ Operators can branch replay runs from durable checkpoint truth without mutating source history. — `v1.9 Crucible`
- ✓ Replay defaults preserve operator trust by blocking or stubbing unsafe external effects while keeping provenance explicit. — `v1.9 Crucible`
- ✓ Operators can compare replay vs original evidence and promote frozen workflow-source snapshots into draft datasets. — `v1.9 Crucible`
- ✓ Production traces can be scored asynchronously and surfaced in an operator review queue with workflow/runtime deep links. — `v1.9 Crucible`
- ✓ Draft promotion candidates remain reviewable and sealed baselines stay approval-gated instead of auto-mutating release truth. — `v1.9 Crucible`
- ✓ Developers can start a bounded delegated run through `Scoria.start_handoff_run/3` with inspectable projected context and operator-visible delegated lineage. — post-`v1.9` repo-local current truth, 2026-05-24
- ✓ Developers can enable semantic fast-path evaluation only for explicitly safe read-only runtime lanes. — `v2.1 Tenant-scoped semantic fast path`
- ✓ Scoria refuses semantic reuse for write-side, approval-sensitive, or personalized-tool-backed flows unless they are explicitly classified as safe. — `v2.1 Tenant-scoped semantic fast path`
- ✓ Semantic cache lookups stay tenant-partitioned and compatibility-aware across prompt, policy, and source truth. — `v2.1 Tenant-scoped semantic fast path`
- ✓ Operators can inspect semantic cache hit, miss, reject, stale, and invalidation evidence through runtime and workflow surfaces. — `v2.1 Tenant-scoped semantic fast path`
- ✓ Scoria ships a named semantic proof lane that verifies partitioning, fallback, invalidation, and operator-evidence behavior together. — `v2.1 Tenant-scoped semantic fast path`
- ✓ Maintainers can build publish-facing docs locally through `mix docs`, with Hex metadata, source links, and docs extras aligned to the real public package surface. — `v2.2 OSS adopter onramp`
- ✓ Maintainers can preview the package artifact before first Hex publish and confirm the shipped file inventory includes required runtime code, migrations, README, and adoption guides. — `v2.2 OSS adopter onramp`
- ✓ A Phoenix host app can run `mix scoria.install` once to mount the dashboard, copy core migrations, and inject baseline runtime defaults without duplicate or misleading mutations. — `v2.2 OSS adopter onramp`
- ✓ The default Phoenix lane installs cleanly when Tailwind or optional knowledge surfaces are absent, and the installer states the skipped or optional steps explicitly. — `v2.2 OSS adopter onramp`
- ✓ A fresh Phoenix consumer app can prove dependency fetch, install, migration, and `/scoria` route visibility through the public adoption path. — `v2.2 OSS adopter onramp`
- ✓ That same consumer proof path can start one durable run through `Scoria.start_run/2`, read it back through the public runtime facade, and inspect operator evidence without enabling optional knowledge or semantic lanes. — `v2.2 OSS adopter onramp`
- ✓ README, operator verification, and installer output now describe the same lane ordering and prerequisite boundaries for default, bounded-handoff, semantic fast path, and optional knowledge surfaces. — `v2.2 OSS adopter onramp`
- ✓ Scoria now names one canonical verification command per lane and documents denial or fallback behavior when optional prerequisites are missing. — `v2.2 OSS adopter onramp`
- ✓ Phoenix developers can follow one example that starts with the default runtime lane and escalates into `Scoria.start_handoff_run/3` without new public API assumptions. — Phase 52 `runtime-to-handoff-example-contract`
- ✓ The example makes bounded projected context, rejection behavior, and operator-visible delegated lineage understandable from adopter-facing docs or sample code. — Phase 52 `runtime-to-handoff-example-contract`
- ✓ Operators can inspect default runs, delegated lineage, projected-context summaries, and delegated outcome through curated runtime and workflow evidence surfaces. — Phase 53 `operator-evidence-and-lane-guidance`
- ✓ README and adopter/operator guides now state when to stay on the default runtime lane versus when to escalate into bounded handoff. — Phase 53 `operator-evidence-and-lane-guidance`
- ✓ The runtime-to-handoff path is backed by an executable proof lane that remains independent of optional semantic or knowledge setup. — Phase 54 `executable-proof-and-closeout-truth`
- ✓ Canonical lane contract source now defines release-preview, adoption, runtime-to-handoff, semantic fast-path, and optional knowledge lanes with one command/env/prerequisite/exclusion schema. — `v2.4 Adoption Reliability Contract`
- ✓ Adoption/support drift tests now consume lane-contract command and boundary nouns, and unsupported alias regressions remain blocked. — `v2.4 Adoption Reliability Contract`
- ✓ Release-preview/docs warning policy now runs warning-clean with remaining debt tracked in a scoped owner+expiry baseline ledger. — `v2.4 Adoption Reliability Contract`
- ✓ CI now enforces warning gates and canonical lane ordering for release-preview, adoption, and runtime-to-handoff proofs. — `v2.4 Adoption Reliability Contract`
- ✓ Installer contract remains idempotent while supporting root browser scopes that use list-form `pipe_through`. — `v2.4 Adoption Reliability Contract`
- ✓ Installer `--dry-run` now uses a deterministic planner contract that reports per-surface classification and rationale without host writes. — Phase 59 `planner-contract-foundation`
- ✓ Installer `--check` now uses deterministic tri-state semantics (`0/1/2`) and emits one stable machine trailer line for CI parsing. — Phase 59 `planner-contract-foundation`
- ✓ Planner/check coverage now includes subprocess status/trailer assertions and no-write regression checks that keep v2.4 lane guardrails green. — Phase 59 `planner-contract-foundation`
- ✓ Maintainer can run `mix scoria.install --dry-run` for a deterministic no-write mutation plan with per-surface classification. — `v2.5 Installer Safety & Upgrade Confidence`
- ✓ Maintainer can run `mix scoria.install --check` with stable `0/1/2` exits and `SCORIA_CHECK_RESULT` trailer semantics. — `v2.5 Installer Safety & Upgrade Confidence`
- ✓ Installer apply mode executes planner-led mutations with manifest-aware drift preflight and explicit manual-review blocking. — `v2.5 Installer Safety & Upgrade Confidence`
- ✓ Installer output stays truthful and idempotent across preview/check/apply with operator-ordered summaries and contract SSOT. — `v2.5 Installer Safety & Upgrade Confidence`
- ✓ CI fails when `.planning/WARNING-BASELINE.md` contains expired or invalid accepted debt rows. — Phase 66 `baseline-expiry-and-inventory`
- ✓ Maintainer can reproduce a classified full-suite warning inventory by surface/area. — Phase 66 `baseline-expiry-and-inventory`
- ✓ Canonical compile and lane-contract surfaces remain warning-clean under warnings-as-errors. — Phase 67 `high-signal-warning-ratchet`
- ✓ High-signal test surfaces pass under warnings-as-errors without new accepted debt. — Phase 67 `high-signal-warning-ratchet` (WARN-06)
- ✓ Full `mix test --warnings-as-errors` passes in CI with baseline ledger closed. — Phase 68 `full-suite-warning-closure` (WARN-07)
- ✓ CI preserves canonical closeout order with Postgres-free policy job first and full-suite WAE after closeout lanes. — `v2.6` Phase 69 (CI-03)
- ✓ README and support docs use capability-based shipped truth with upgrade-safe install guidance; `adoption_surface_test` guards via `AdopterDocContract`. — Phase 70 (DOCS-03)
- ✓ Maintainer docs clarify semantic lane local-only (not PR CI) and planning-milestone vs Hex semver namespaces. — Phase 70 (DOCS-04)
- ✓ `mix scoria.test.install_contract` runs deep installer contract proofs as maintainer-only task with adoption-lane boundary tests. — Phase 70 (INST-DX-01)
- ✓ First Hex publish at `0.1.0` with git tag `v0.1.0`; release automation runs same test topology as PR CI before publish. — `v2.7` (HEX-01)
- ✓ CHANGELOG, GitHub release, Hex badge, and README install flip to Hex-primary with GitHub tag fallback. — `v2.7` (HEX-02)
- ✓ Semantic fast-path WAE in PR CI after closeout lanes without widening `closeout_order/0`. — `v2.8` (SEM-CI-01)
- ✓ `mix test.knowledge --warnings-as-errors` runs in CI after full-suite WAE. — `v2.8` (CI-KNOW-01)
- ✓ `mix scoria.warning_inventory.check_baseline` enforces empty inventory clusters in CI policy job. — `v2.8` (CI-INV-01)
- ✓ `Scoria.SupportJourney` exposes shared adoption journey identities, handler contracts, seeds, and doc fragments as fixture SSOT. — `v2.9` (JOURN-01)
- ✓ Source contract tests pin `SupportJourney` fragments across overlay, gallery, and adopter docs (multi-surface drift guards). — `v2.9` (JOURN-02, DOCS-GALL-01)
- ✓ Generated-host overlay proves resume and bounded handoff using `SupportJourney` identities. — `v2.9` (HOST-01, HOST-02)
- ✓ `examples/support_copilot/` gallery demonstrates support-copilot domain with LiveView journey tests. — `v2.9` (GALL-01, GALL-02)
- ✓ Advisory `mix scoria.test.support_copilot` runs gallery proof outside `closeout_order/0`; CI ordering contract enforced. — `v2.9` (CI-GALL-01)
- ✓ Generated Phoenix host in `mix test.adoption` consumes Scoria via Hex-shaped tarball dependency and proves full overlay depth (handoff + route + runtime smokes). — Phase 79 (HEX-CONSUMER-01)
- ✓ Same host proves upgrade-safe install after simulated version bump (`--dry-run` / `--check` / apply / migrate). — `v2.10` (HEX-UPGRADE-01)
- ✓ Post-publish workflow proves live Hex fetch + install/migrate/overlay subset; release-blocking upgrade on real semver bump. — `v2.10` (HEX-REGISTRY-01)
- ✓ README, operator verification, and drift guards stay aligned via `HexConsumerContract` / `AdopterDocContract`. — `v2.10` (DOCS-HEX-01)
- ✓ Runtime span events fan out to tenant-scoped PubSub; OrchestratorLive merges live trace deltas and HITL approval pauses from real workflow paths (not test `send/2`). — `v2.11` (ORCH-LIVE-01)
- ✓ Shared `Scoria.SupportJourney.Handlers` used by host overlay and gallery with no duplicated handler logic. — `v2.12` (DEMO-01)
- ✓ Gallery optional lane journeys (semantic, knowledge, connector) with LiveView tests via advisory `mix scoria.test.support_copilot`. — `v2.12` (LANE-01–03)
- ✓ Gallery producer-path orchestrator smoke and honest gallery docs with SupportJourney drift guards. — `v2.12` (ORCH-01, DOCS-01–02)
- ✓ Adopter vs maintainer docs split (`docs/MAINTAINERS.md`); Hex metadata and connector_adoption in package extras. — `v2.13` (DOCS-03, DOCS-04)
- ✓ Maintenance release `0.1.1` prepared with adopter-readable CHANGELOG and release-please manifest. — `v2.14` (HEX-03)
- ✓ Named connector adoption lane `mix test.connector` with VerificationLanes entry, SupportJourney proof, docs truth, and PR CI WAE. — `v2.15` (CONN-LANE-01–03, CONN-DOCS-01–02, CONN-CI-01)
- ✓ ReqLLM peer dependency bumped to `~> 1.13` (1.13.0); orchestrator, judge runner, compaction worker, and observe adapter verified — `v2.16` (DEPS-01–04)
- ✓ Brand book pressure-tested (1,311 lines, 14 sections, 15-dim scorecard, 52-pairing WCAG table, 0 FAIL), decisions locked with user approval, `propagation: not-required` machine-readable verdict. — `v2.17 Vesicle` (BRAND-01, BRAND-02)
- ✓ User chose logo direction from ≥6 programmatic SVG options (2 rounds: TV-1 "Span rail" mark + LK-B "Mark-as-o" fused lockup); all LOGO-01..07 constraints verified. — `v2.17 Vesicle` (BRAND-03)
- ✓ 8-variant logo set (primary dark/light, mark, monochrome, subtitle, integrated logotype, favicon, social card) with clear-space/min-size spec and optical-correction pass. — `v2.17 Vesicle` (BRAND-04)
- ✓ Self-contained `brandbook/` with tokens.json/css (4-source hex consistency), 543-line canonical brand-book.md, 7 SVG examples, standalone index.html (file:// offline, zero network refs) — 458 KB, zero binaries. — `v2.17 Vesicle` (BRAND-05, BRAND-06)
- ✓ Brand live on real surfaces: README picture-element header, dashboard TV-1 mark + data-URI favicon, mix.exs/GitHub descriptions; quality-gate.mjs 8/8 PASS; mix test 632 green; DS-06 byte-identical (BRAND-09 did not fire). — `v2.17 Vesicle` (BRAND-07, BRAND-08)

### Active

_v3.0 Control Room — resumed 2026-06-11 after v2.17 Vesicle interjection (REQUIREMENTS.md current); Phases 11–15 complete; next step: `/gsd:discuss-phase 16`._

- [ ] Operators get a committed dev-only screenshot + LLM-critique evaluation loop and seed data that exercises every dashboard screen.
- [ ] The design system is fully adopted: shared `ui.ex` components replace hand-rolled markup, with zero raw-palette class leakage enforced by a drift guard.
- [ ] A newcomer dropped on the dashboard immediately understands what Scoria does and how to reach their job; power users keep a zero-click path (Status Home, third nav axis, breadcrumbs, command palette, cross-screen threading).
- [ ] Every screen reaches a consistent high-polish bar in both light and dark themes, with restrained brand-tied motion and mobile-first responsive behavior.
- [ ] Reserved brand-name screens read as complete in the IA via honest "coming soon" stubs (no fake data).

_(Release 0.1.1 publish via release-please remains pending, tracked in Release Queue.)_

### Out of Scope

- Full package-family decomposition into multiple Hex libraries — valuable later, but too wide for the first boring adopter closeout.
- Hosted demo environments or managed onboarding services — gallery is local `examples/` only; no hosted onboarding.
- Adding gallery tests to `mix test.adoption` closeout chain — gallery stays advisory via `mix scoria.test.support_copilot`.
- Broad bounded-handoff example expansion beyond one runtime-to-handoff path — too wide until one canonical example proves useful.
- External semantic cache backends or ANN tuning controls — adjacent capability expansion, not the highest-leverage adoption closure.
- Folding optional knowledge or semantic verification into the default adoption lane — would weaken the clear prerequisite boundary that this milestone is trying to strengthen.
- Net-new runtime capability families — feature-strong; v2.10 is adoption proof only.
- Widening `VerificationLanes.closeout_order/0` for hex proof — tarball consumer proof stays inside existing adoption lane.
- Wallaby/browser CI for hex consumer host — LiveViewTest overlay smokes only.
- A broad installer engine rewrite beyond plan/check + drift-safe apply — too wide for the next milestone's leverage target.
- Connector adoption guides without explicit embedded-boundary framing — risks hosted-connector-platform drift; defer or keep narrow after v2.7.
- Combining `WARN-03` with Hex publish, semantic CI gate, or connector docs in one milestone — dilutes focus; sequence v2.6 then v2.7.
- Combining maintainer-trust work with broad capability expansion in one milestone — dilutes focus; sequence narrowly.

<details>
<summary>v2.8 CI Hardening & Post-Ship Hygiene (shipped 2026-05-29)</summary>

**Delivered:** SEM-CI-01, CI-KNOW-01, CI-INV-01; post-publish smoke fix; operator gate map update.

</details>

<details>
<summary>v2.7 OSS Release + Docs Truth (shipped 2026-05-29)</summary>

**Delivered:** DOCS-03/04, INST-DX-01, HEX-01/02, Hex-primary README, `package_surface_test` flip, `0.1.0` on Hex.

</details>

<details>
<summary>v2.6 Warning Ratchet (shipped 2026-05-28)</summary>

**Goal:** Close full-suite warning debt with staged warnings-as-errors ratchet and executable baseline-expiry policy.

**Delivered:**
- Executable `mix scoria.warning_baseline.check` in CI policy job (WARN-03).
- Classified warning inventory path and maintainer ratchet tasks (WARN-04, WARN-06).
- Green compile, lane-contract, high-signal, and full-suite WAE (WARN-05, WARN-06, WARN-07).
- CI gate map and contract-tested policy→test topology without reordering closeout lanes (CI-03).

**Why it mattered:** Maintainer trust now matches executable CI truth — warning debt cannot silently expire or regress past canonical lanes.

</details>

## Context

- **Latest shipped:** v2.17 Vesicle (brand system) — archived 2026-06-11.
- v2.16 ReqLLM peer bump (`~> 1.13`) — archived 2026-05-30.
- v2.15 connector adoption lane (`mix test.connector`) — archived 2026-05-30.
- v2.12–v2.14 shipped 2026-05-30; v2.13/v2.14 bundled with v2.12 closeout pass.
- Hex `0.1.1` prepared locally; `0.1.0` live at https://hex.pm/packages/scoria — publish via release-please.
- CI: policy job (baseline → inventory baseline → compile WAE → lane-contract) → test job (closeout → semantic WAE → ratchet hygiene → full WAE → knowledge WAE → connector WAE → advisory gallery).
- `Scoria.SupportJourney` + `examples/support_copilot/` gallery; advisory `mix scoria.test.support_copilot` outside closeout.
- Archives: `.planning/milestones/v2.17-*`, `v2.16-*`, `v2.15-*`, `v2.11-*`, `v2.10-*`, `v2.9-*`, `v2.8-*`, `v2.7-*`, `v2.6-*`

## Constraints

- **Product shape**: Stay embedded and Phoenix-first — Scoria must remain a library plus dashboard surface, not a hosted connector platform.
- **Runtime boundary**: Keep package and docs concerns inside Mix tasks, tests, and CI lanes instead of pulling Mix project metadata into runtime behavior.
- **DX**: Keep installation and verification boring for a normal Phoenix app path; only ask the user for materially impactful security or blast-radius choices.
- **Support truth**: Default-lane docs, installer output, and proof commands must agree on prerequisites and order of adoption.
- **Optionality**: Default-lane proof must not require pgvector, retrieval, grounding, or semantic fast-path setup.
- **Shift-left defaults**: Push low-impact milestone decisions left inside Scoria and future GSD flows; reserve interruptions for materially consequential product or blast-radius choices.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| `v1.5` focuses on remote connector productization, not release ops | Connector breadth is the next missing adoption boundary after Keystone; release discipline can layer cleanly afterward | — Resolved |
| Remote connector support is stateless-first by default | This yields real value without forcing stateful session complexity or multi-node surprises into the default milestone path | — Resolved |
| Operator/audit visibility is the primary user-facing outcome | Scoria's differentiator is evidence and governance, not merely "can connect a tool" breadth | — Resolved |
| Browser/code-exec stays out of scope for `v1.5` | It introduces a separate privileged-execution risk class before connector policy and evidence are proven boring | — Resolved |
| `v1.9` should prioritize replayable debugging and online scoring over semantic caching or broad handoff productization | It compounds existing trace/eval/operator surfaces with less platform-drift risk and a clearer Phoenix-first value proposition | — Resolved |
| Online scoring must never auto-mutate sealed baseline datasets | Observed production behavior is not reviewed ground truth; operator trust depends on keeping those lanes separate | — Resolved |
| Post-`v1.9` public handoff work should stay narrow and ship together with docs/install/verification alignment | The real adopter value was a bounded `Scoria` lane with inspectable projected context, not broader orchestration surface area or support-truth drift | — Resolved |
| `v2.0 Relay` should formalize current bounded handoff truth before Scoria opens another net-new capability milestone | The implementation wedge already exists; the remaining risk is proof and support-truth drift, not raw feature absence | — Resolved |
| `v2.1` semantic caching stays Scoria-owned, tenant-partitioned, and evidence-first instead of relying on provider prompt caches or invisible global reuse | Latency wins are only acceptable if partitioning, invalidation, and operator truth remain inspectable | — Resolved |
| Post-`v2.1` milestone selection should prioritize OSS adopter readiness over adjacent capability expansion | The repo is already feature-strong; the main remaining leverage is making package/install/proof surfaces boring for a serious Phoenix adopter | — Resolved |
| `v2.2` should close the OSS adopter onramp before Scoria reopens broader capability expansion | Publishability, install truth, consumer proof, and support truth are now part of the product surface, not ancillary release chores | — Resolved |
| `v2.3` should clarify the runtime-to-handoff adoption path before adding new capability families | The default onramp was executable in `v2.2`; the next likely support risk was lane escalation and bounded-handoff comprehension | — Resolved |
| `v2.4` should prioritize adoption reliability contracts over net-new capability expansion | Existing lanes already deliver value; highest leverage is keeping docs, CI, warnings, and installer behavior in lock-step truth | — Resolved |
| Next milestone should preserve v2.4 reliability contracts while selecting one focused expansion axis | Reliability contract closure is now shipped; follow-up scope should be narrow and requirement-led | ✓ Good — v2.6 WARN-03 selected |
| Next milestone should prioritize installer safety + upgrade confidence (`INST-03`, `INST-04`) before warning ratchet work | Host-app mutation surprise remains the highest adopter-trust risk after v2.4, and installer contracts are the narrowest high-leverage wedge | ✓ Good — shipped v2.5 |
| `WARN-03` should execute immediately after installer safety milestone closeout | Warning debt remains important, but installer plan/apply + drift contracts are a bigger first-order adoption risk reducer | ✓ Good — shipped v2.6 |
| No new runtime families until `WARN-03` and v2.7 OSS/docs closeout | Repo is ~84% done for embedded scope; highest leverage is warning trust + Hex/docs truth, not capability expansion | ✓ Good — v2.7/v2.8 shipped |
| Milestone sequencing: v2.6 WARN-03 → v2.7 Hex/docs-truth → v2.8 CI hardening | Confirmed by milestone next-step assessment 2026-05-27 | ✓ Good — sequence complete |
| Deferred CI lanes (semantic, knowledge, inventory) land in v2.8 without widening closeout order | Keeps v2.4 lane contract intact while closing maintainer trust gap | ✓ Good — shipped v2.8 |
| v2.9 adopts phased hybrid demo: overlay (merge-blocking) + gallery (advisory) with `SupportJourney` SSOT | Closes adoption confidence gap before real adopters without hosted demo scope creep | ✓ Good — shipped v2.9 |
| v2.10 closes Hex consumer proof with tarball in adoption closeout + registry post-publish gate | Path dep in merge-blocking CI misleads post-Hex adopters; tarball proves packaged artifact | ✓ Good — shipped v2.10 |
| v2.11 closes orchestrator live wiring with producer-path integration proof | Post-Hex adopters need operator UX without hollow LiveView test paths | ✓ Good — shipped v2.11 |
| Phase 01.1 inserted after audit for ORCH-LIVE-01 hardening | Audit found redaction, approval E2E, and token coalesce gaps | ✓ Good — shipped 01.1 |
| Check-time manifest fingerprints are live-host-only; apply-time freshness gate uses stored manifest | Honest operator contract avoids misleading stored-fingerprint merge at check | ✓ Good — shipped Phase 63 |
| v2.15 connector lane as PR WAE after knowledge, not in closeout | Parity with semantic/knowledge lanes; preserve v2.4 closeout contract | ✓ Good — shipped v2.15 |
| v2.16 minimal ReqLLM-only peer bump; no optional szTheory deps | User chose narrow dependency hygiene scope; Tribunal already current | ✓ Good — shipped v2.16 |
| Phase 10.1 inserted after audit for v2.16 VERIFICATION gap | Phases 08–10 shipped without GSD execute artifacts; retroactive ledgers | ✓ Good — shipped 10.1 |
| v2.17 Vesicle interjected before v3.0 phases 13–17 | Brand book never pressure-tested, no logo/collateral exists; clean phase boundary; planning versions decoupled from Hex semver keeps archive chronology aligned | ✓ Good — shipped v2.17 |
| `brandbook/` is canonical brand source; dashboard CSS updated only on material audit failures | Avoids thrash to freshly shipped v3.0 token gateway + DS-06 ratchet | ✓ Good — shipped v2.17; BRAND-09 did not fire |

## Milestone History

- `v1.0 MVP`: Core observability, MCP governance, operator UX, and evaluation flywheel.
- `v1.1 Caldera`: Durable agent workflows, recovery, and handoffs.
- `v1.2 Corpus`: RAG primitives, citations, grounding, and evidence projection.
- `v1.3 Seismograph`: SRE budgets, breakers, telemetry, audit export, incident delivery, and milestone closeout verification.
- `v1.4 Keystone`: Canonical runtime identity, public runtime API, install defaults, adoption docs, verification backfills, and executable adoption guards.
- `v1.5 Switchyard`: Remote MCP connector registration, stateless-first invocation, operator evidence UX, and curated profiles.
- `v1.6 Flightpath`: Ecto-backed prompt registry, LiveView dataset curation, regression integration, and release gates.
- `v1.7 Outrider`: MCP SSE boundary, asynchronous session compaction engine, and external runtime observability UX.
- `v1.8 Vanguard`: Multi-model fallback orchestration, distributed evaluation fan-out, real-time operator dashboards, and reconciled shipped-state planning truth.
- `v1.9 Crucible`: Replayable debugging, replay-safe execution, workflow-source dataset promotion, and online scoring review queues.
- `v2.0 Relay`: Explicit bounded handoff contract truth, delegated evidence visibility, canonical adoption proof, and clean closeout verification.
- `v2.1 Tenant-scoped semantic fast path`: Tenant-partitioned semantic reuse, compatibility-aware invalidation, operator-visible semantic evidence, and a named semantic proof lane.
- `v2.2 OSS adopter onramp`: Publish-facing package truth, generated-host adoption proof, and canonical lane-based support closure.
- `v2.3 Runtime-to-handoff adoption example`: Default-to-handoff adopter example, operator evidence alignment, canonical runtime-to-handoff proof lane, and closeout ledger.
- `v2.4 Adoption Reliability Contract`: Canonical lane contract source, drift-proof docs checks, warning-policy enforcement, CI lane-order trust, and installer list-form hardening.
- `v2.5 Installer Safety & Upgrade Confidence`: Planner/check no-write contracts, manifest-aware drift-safe apply, installer contract SSOT, Nyquist closeout, and adoption discoverability parity.
- `v2.6 Warning Ratchet`: Executable baseline expiry, classified inventory, staged high-signal ratchet, full-suite WAE in CI, CI-03 gate map and contract tests.
- `v2.7 OSS Release + Docs Truth`: Capability-based docs truth, release-please bootstrap, Hex `0.1.0` publish, README Hex-primary flip.
- `v2.8 CI Hardening & Post-Ship Hygiene`: Semantic/knowledge WAE and inventory baseline gate in PR CI; post-publish smoke fix.
- `v2.9 Adoption Journey & Reference Demo`: SupportJourney SSOT, host-proof overlay expansion, support copilot gallery, advisory CI lane, multi-surface drift guards.
- `v2.10 Hex Consumer Proof & Upgrade Smoke`: Tarball consumer proof, upgrade smoke, registry attest, DOCS-HEX-01 drift guards.
- `v2.11 Orchestrator Live Wiring`: ORCH-LIVE-01 live trace + HITL from runtime; Phase 01.1 hardening slice.
- `v2.15 Connector Adoption Lane`: Named `mix test.connector` lane, SupportJourney proof, docs/CI/drift guards; Phase 07.1 process closeout.
- `v2.17 Vesicle`: Brand system — pressure-tested brand book, programmatically generated logo system (TV-1 mark + LK-B lockup chosen by user), 8-variant logo set, canonical brandbook/ (tokens, brand book, examples, standalone HTML), README/dashboard/Hex integration; quality-gate.mjs 8/8 PASS; BRAND-09 conditional did not fire.
- `v2.16 ReqLLM Peer Bump`: ReqLLM `~> 1.13` peer bump with integration + CI trust verification; Phase 10.1 process closeout.

## Archived Planning Notes

<details>
<summary>Pre-ship v2.11 framing</summary>

`v2.11` wired orchestrator live trace broadcast and HITL from real runtime/workflow events. Phase 01.1 inserted after audit for redaction, approval E2E, and token coalesce hardening. Archived in `.planning/milestones/v2.11-ROADMAP.md`, `.planning/milestones/v2.11-REQUIREMENTS.md`, and `.planning/milestones/v2.11-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>Pre-ship v2.9 framing</summary>

`v2.9` battle-tested adoption through support-copilot domain: overlay merge-blocking, gallery advisory, `SupportJourney` spine. Archived in `.planning/milestones/v2.9-ROADMAP.md`, `.planning/milestones/v2.9-REQUIREMENTS.md`, and `.planning/milestones/v2.9-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>Pre-ship v2.8 framing</summary>

`v2.8` closed deferred SEM-CI-01, CI-KNOW-01, and CI-INV-01 without widening `closeout_order/0`. Archived in `.planning/milestones/v2.8-ROADMAP.md`, `.planning/milestones/v2.8-REQUIREMENTS.md`, and `.planning/milestones/v2.8-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>Pre-ship v2.6 framing</summary>

`v2.6` closed warning debt with policy→test CI topology, inventory/ratchet maintainer paths, and full-suite WAE without changing closeout lane order. Archived in `.planning/milestones/v2.6-ROADMAP.md`, `.planning/milestones/v2.6-REQUIREMENTS.md`, and `.planning/milestones/v2.6-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>Pre-ship v2.5 framing</summary>

`v2.5` focused on installer mutation confidence: no-write planner/check, manifest-aware drift classification, truthful idempotent apply, and audit gap closure (Nyquist, manifest fingerprint, adoption discoverability). Archived in `.planning/milestones/v2.5-ROADMAP.md`, `.planning/milestones/v2.5-REQUIREMENTS.md`, and `.planning/milestones/v2.5-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>Pre-ship v2.2 framing</summary>

`v2.2` focused on turning Scoria's post-`v2.1` repo truth into a public adoption story: publishable Hex metadata, a real docs-build lane, a truthful installer contract, fresh-host proof, and lane-based support wording. That milestone is now shipped and archived in `.planning/milestones/v2.2-ROADMAP.md` and `.planning/milestones/v2.2-REQUIREMENTS.md`.

</details>

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-13 — Phase 15 complete; v3.0 Control Room continues with Phase 16 motion + responsive + theme parity (next: /gsd:discuss-phase 16)*
