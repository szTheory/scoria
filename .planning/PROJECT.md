# Scoria

## What This Is

Scoria is a Phoenix-native AI application quality layer for Elixir teams. It gives existing Phoenix apps trace-first observability, durable workflow state, knowledge grounding, approvals, operator-visible evidence, and a public runtime surface without forcing teams into a hosted agent platform shape.

The product boundary stays embedded and Ecto/Telemetry-native: Scoria should feel like a library and dashboard surface that fits into a normal Phoenix application, not a separate runtime people have to work around.

## Core Value

Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## Current Milestone: v2.6 Warning Ratchet

**Goal:** Close full-suite warning debt with staged warnings-as-errors ratchet and executable baseline-expiry policy so maintainer trust matches canonical lane truth.

**Target features:**
- Executable CI check that fails on expired rows in `.planning/WARNING-BASELINE.md`
- Reproducible warning inventory classified by surface/area
- Staged high-signal ratchet (`lib/`, canonical lane tests) before full-suite `mix test --warnings-as-errors`
- CI full-suite WAE gate without changing closeout lane order

## Current State

- Scoria shipped `v2.5 Installer Safety & Upgrade Confidence` on 2026-05-27.
- Installer preview/check/apply now share one planner artifact: `--dry-run` and `--check` are no-write, tri-state exits are stable, and apply enforces manifest-aware drift preflight.
- `Scoria.Install.Contract` is the operator-output SSOT; mode equivalence and B-cycle idempotency proofs guard preview/check/apply alignment.
- Check-time vs apply-time manifest fingerprint roles are documented and tested; adoption discoverability meta-tests match `adoption_test_files/0`.
- Milestone Nyquist coverage is 5/5 compliant for phases 59–63; v2.5 audit archived at `.planning/milestones/v2.5-MILESTONE-AUDIT.md`.
- Canonical lane truth remains in `Scoria.VerificationLanes`; closeout chain unchanged: `mix scoria.release_preview`, `mix test.adoption`, `mix test.runtime_to_handoff`.
- Warning baseline debt is tracked with owner+expiry; Phase 66 shipped executable WARN-03 enforcement and WARN-04 inventory infrastructure.
- CI now runs `mix scoria.warning_baseline.check` in a Postgres-free policy job before compile WAE and closeout lanes.

## Next Milestone Goals

**Queued (v2.7):** OSS Release + Docs Truth — first Hex publish, README/shipped-state honesty (update `adoption_surface_test` assertions together), preserve lane contracts.

**Preserve:** v2.4 lane contracts, CI closeout order, and v2.5 installer planner/check/apply truth across docs, tests, and CI.

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

### Active

- [ ] **WARN-06**: High-signal test surfaces pass under warnings-as-errors without new accepted debt.
- [ ] **WARN-07**: Full `mix test --warnings-as-errors` passes in CI (or remaining debt is re-baselined with owner+expiry).
- [ ] **CI-03**: CI preserves canonical closeout order while enforcing baseline-expiry and staged WAE gates.

### Out of Scope

- Full package-family decomposition into multiple Hex libraries — valuable later, but too wide for the first boring adopter closeout.
- Hosted demo environments or managed onboarding services — would widen the product boundary before the embedded install story is fully proven.
- Broad bounded-handoff example expansion beyond one runtime-to-handoff path — too wide until one canonical example proves useful.
- External semantic cache backends or ANN tuning controls — adjacent capability expansion, not the highest-leverage adoption closure.
- Folding optional knowledge or semantic verification into the default adoption lane — would weaken the clear prerequisite boundary that this milestone is trying to strengthen.
- Net-new runtime capability families until `WARN-03` and v2.7 OSS/docs closeout — feature-strong; remaining leverage is adoption and maintainer trust, not breadth.
- A broad installer engine rewrite beyond plan/check + drift-safe apply — too wide for the next milestone's leverage target.
- Connector adoption guides without explicit embedded-boundary framing — risks hosted-connector-platform drift; defer or keep narrow after v2.7.
- Combining `WARN-03` with Hex publish, semantic CI gate, or connector docs in one milestone — dilutes focus; sequence v2.6 then v2.7.

## Latest Shipped Milestone: v2.5 Installer Safety & Upgrade Confidence

**Goal:** Make host-app installer mutations predictable, inspectable, and drift-safe before applying writes.

**Delivered:**
- Planner-driven `--dry-run` and `--check` with deterministic no-write surfaces and stable tri-state exit semantics.
- Manifest-aware drift detection and planner-led apply preflight gates for managed router/config/migration surfaces.
- `Scoria.Install.Contract` SSOT, mode equivalence proofs, and B-cycle idempotency across preview/check/apply.
- Nyquist and traceability closeout for phases 59–63; adoption discoverability meta-tests aligned with lane file list.

**Why it mattered:** Adopters can inspect and trust installer mutations before apply, closing the highest remaining host-app surprise risk after v2.4 reliability contracts.

## Context

- Scoria shipped `v2.5 Installer Safety & Upgrade Confidence` on 2026-05-27 (~63k LOC Elixir across `lib/` and `test/`).
- The canonical closeout chain remains `mix scoria.release_preview`, `mix test.adoption`, and `mix test.runtime_to_handoff`.
- Optional semantic and knowledge lanes remain explicit extensions, not default-lane prerequisites.
- Warning baseline expiry (`2026-06-07`) makes `WARN-03` the immediate next milestone.
- Next milestone planning starts from the archived v2.5 installer-safety baseline.
- README/support wording still carries one drift risk ("shipped through v2.1") that should be corrected in the upcoming docs-truth pass.

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
| `WARN-03` should execute immediately after installer safety milestone closeout | Warning debt remains important, but installer plan/apply + drift contracts are a bigger first-order adoption risk reducer | — Active (v2.6 next) |
| No new runtime families until `WARN-03` and v2.7 OSS/docs closeout | Repo is ~84% done for embedded scope; highest leverage is warning trust + Hex/docs truth, not capability expansion | — Active |
| Milestone sequencing: v2.6 WARN-03 → v2.7 Hex/docs-truth → optional semantic CI / connector guide | Confirmed by milestone next-step assessment 2026-05-27 | — Active |
| Check-time manifest fingerprints are live-host-only; apply-time freshness gate uses stored manifest | Honest operator contract avoids misleading stored-fingerprint merge at check | ✓ Good — shipped Phase 63 |

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

## Archived Planning Notes

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
*Last updated: 2026-05-27 — Phase 66 baseline expiry and inventory complete*
