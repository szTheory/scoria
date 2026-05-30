# Milestones

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
