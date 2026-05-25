# Scoria

## What This Is

Scoria is a Phoenix-native AI application quality layer for Elixir teams. It gives existing Phoenix apps trace-first observability, durable workflow state, knowledge grounding, approvals, operator-visible evidence, and a public runtime surface without forcing teams into a hosted agent platform shape.

The product boundary stays embedded and Ecto/Telemetry-native: Scoria should feel like a library and dashboard surface that fits into a normal Phoenix application, not a separate runtime people have to work around.

## Core Value

Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## Current State

- Scoria shipped `v2.1 Tenant-scoped semantic fast path` on 2026-05-25.
- The product now includes a tenant-partitioned semantic fast path for explicitly safe read-only runtime lanes, with durable compatibility/invalidation truth and operator-visible semantic evidence.
- Post-`v2.1` repo-local hardening improved the OSS adoption boundary: package metadata is now Hex-ready, `mix scoria.install` copies core migrations and tolerates missing Tailwind assets, and the named semantic proof lane now prepares the retrieval-backed tables it depends on.
- `v2.2 OSS adopter onramp` is now active and focuses on turning that reconciled repo truth into a publishable, consumer-proven Phoenix adoption story.

## Current Milestone: v2.2 OSS adopter onramp

**Goal:** Turn Scoria's reconciled post-`v2.1` repo state into a release-grade OSS adoption path that a normal Phoenix team can install, verify, and trust without maintainer folklore.

**Target features:**
- publishable Hex metadata and a real local docs-build lane
- a truthful default-lane installer contract for router wiring, copied migrations, and baseline runtime defaults
- a canonical consumer-app proof path for dependency -> install -> migrate -> runtime -> operator inspection
- lane-based docs and support truth that separate the default runtime lane from optional knowledge, semantic, and handoff surfaces

**Why now:** The repo is already feature-strong. The highest-leverage next step is making package, install, and proof surfaces boring for a serious Phoenix adopter before opening more runtime capability.

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

### Active

- [ ] `ADPT-03`: Maintainer can build Scoria's publish-facing docs locally through `mix docs`, with Hex metadata, source links, and docs extras aligned to the real public package surface.
- [ ] `ADPT-04`: Maintainer can preview the package artifact before first Hex publish and confirm the shipped file inventory includes required runtime code, migrations, README, and adoption guides.
- [ ] `INST-01`: A Phoenix host app can run `mix scoria.install` once to mount the dashboard, copy core migrations, and inject baseline runtime defaults without duplicate or misleading mutations.
- [ ] `INST-02`: The default Phoenix lane installs cleanly when Tailwind or optional knowledge surfaces are absent, and the installer states the skipped or optional steps explicitly.
- [ ] `PROOF-01`: A fresh Phoenix consumer app or equivalent host-app harness can prove dependency fetch, install, migration, and `/scoria` route visibility through the public adoption path.
- [ ] `PROOF-02`: That same consumer proof path can start one durable run through `Scoria.start_run/2`, read it back through the public runtime facade, and inspect operator evidence without enabling optional knowledge or semantic lanes.
- [ ] `DOCS-01`: README, operator verification, and installer output describe the same lane ordering and prerequisite boundaries for default, bounded-handoff, semantic fast-path, and optional knowledge surfaces.
- [ ] `DOCS-02`: Scoria names one canonical verification command per lane and documents denial or fallback behavior when optional prerequisites are missing.

### Out of Scope

- Full package-family decomposition into multiple Hex libraries — valuable later, but too wide for the first boring adopter closeout.
- Hosted demo environments or managed onboarding services — would widen the product boundary before the embedded install story is fully proven.
- Advanced bounded-handoff example expansion — defer unless real support evidence shows the shipped public lane is still confusing.
- External semantic cache backends or ANN tuning controls — adjacent capability expansion, not the highest-leverage adoption closure.
- Folding optional knowledge or semantic verification into the default adoption lane — would weaken the clear prerequisite boundary that this milestone is trying to strengthen.

## Latest Shipped Milestone: v2.1 Tenant-scoped semantic fast path

**Goal:** Add a tenant-scoped semantic fast path for explicitly safe read-only runtime lanes without weakening operator trust, provenance, or Phoenix-first support truth.

**Delivered:**
- Tenant-scoped semantic cache lookup and writeback for explicitly safe read-only runtime lanes now exists as durable Scoria-owned truth.
- Compatibility-aware lookup and invalidation semantics keep reuse conservative across prompt, policy, source, freshness, and scope changes.
- Runtime and workflow surfaces now expose operator-visible semantic evidence, and `mix test.semantic_fast_path` closes the support-proof loop.

**Why it mattered:** This adds a real latency and cost optimization without turning Scoria into invisible middleware. The fast path compounds the existing trace, replay, scoring, and operator evidence loop while staying tenant-partitioned, durable, and inspectable.

## Context

- Scoria shipped `v2.1 Tenant-scoped semantic fast path` on 2026-05-25.
- Post-ship adoption hardening tightened the real baseline on the same day: package metadata, installer behavior, and semantic proof setup are now more truthful than the archived `v2.1` closeout docs alone suggest.
- Official Hex publishing guidance expects truthful package metadata, a real docs build, and a concrete packaged file set; Scoria has started that work but has not closed it yet.
- The repo already has durable workflow truth, approval lineage, telemetry, audit seams, and a complete remote connector boundary.
- The next milestone should assume the highest-leverage gap is boring OSS adoption closure unless real adopter pressure proves external semantic-cache infrastructure is now more urgent.

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
| `v2.2` should close the OSS adopter onramp before Scoria reopens broader capability expansion | Publishability, install truth, consumer proof, and support truth are now part of the product surface, not ancillary release chores | — Pending |

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
*Last updated: 2026-05-25 after starting v2.2 OSS adopter onramp*
