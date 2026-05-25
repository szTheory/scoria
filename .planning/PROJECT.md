# Scoria

## What This Is

Scoria is a Phoenix-native AI application quality layer for Elixir teams. It gives existing Phoenix apps trace-first observability, durable workflow state, knowledge grounding, approvals, operator-visible evidence, and a public runtime surface without forcing teams into a hosted agent platform shape.

The product boundary stays embedded and Ecto/Telemetry-native: Scoria should feel like a library and dashboard surface that fits into a normal Phoenix application, not a separate runtime people have to work around.

## Core Value

Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## Current State

- Scoria shipped `v2.0 Relay` on 2026-05-25 with a fresh green full-suite `mix test` baseline.
- `v2.1 Tenant-scoped semantic fast path` is now active.
- The current milestone focuses on safe semantic answer reuse that stays tenant-partitioned, provenance-aware, and operator-visible.

## Current Milestone: v2.1 Tenant-scoped semantic fast path

**Goal:** Add a tenant-scoped semantic fast path for explicitly safe read-only runtime lanes without weakening operator trust, provenance, or Phoenix-first support truth.

**Target features:**
- bounded tenant-scoped semantic cache lookup and write-back for safe read-only classes of work
- prompt/version/source-aware invalidation and freshness handling
- explicit fallback to the normal runtime path on miss, stale, or ineligible requests
- operator-visible cache diagnostics and verification proof

**Why now:** After `v2.0 Relay` closed the bounded handoff support-truth wedge on 2026-05-25, the highest-priority next bet is a latency/cost optimization that compounds the existing trace, replay, scoring, and operator evidence loop without widening the product boundary.

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

### Active

- [ ] `FAST-01`: Developer can enable semantic fast-path evaluation only for explicitly safe read-only runtime lanes.
- [ ] `SAFE-01`: Scoria refuses to cache or reuse answers from write-side, approval-sensitive, or personalized-tool-backed flows unless they are explicitly classified as safe.
- [ ] `FAST-02`: Semantic cache lookups are always partitioned by `tenant_id`, with stricter actor or policy scoping when compatibility requires it.
- [ ] `LOOK-01`: Scoria reuses a cached answer only when semantic similarity, prompt compatibility, policy compatibility, and source compatibility all pass.
- [ ] `LOOK-02`: Cache miss, stale, or rejected outcomes fall through to the normal execution path without changing workflow truth.
- [ ] `INVD-01`: Cache entries invalidate when prompt version, source fingerprint, or policy compatibility changes.
- [ ] `INVD-02`: Developers and operators can distinguish active, stale, and invalidated cache entries with explicit reasons.
- [ ] `EVID-01`: Operators can inspect cache hit, miss, stale, and rejection outcomes with provenance and partitioning context in Scoria runtime or workflow surfaces.
- [ ] `PROOF-01`: Scoria ships a checked verification lane that proves semantic fast-path partitioning, fallback semantics, and invalidation behavior.

### Candidate Next Requirements

- `ADPT-03`: Scoria ships stronger bounded-handoff examples only if `v2.0 Relay` verification proves the current public lane still creates real adopter confusion. — contingent candidate

### Out of Scope

- Full hosted connector marketplace or broker behavior — would drift Scoria away from its embedded Phoenix product shape.
- First-party browser/code-exec productization — adds a separate privileged-execution risk class before connector policy and evidence are proven boring.
- Deep external runtime interoperability — valuable, but not ahead of making remote connector governance unsurprising in ordinary Phoenix apps.
- Automatic mutation of sealed baseline datasets from online scoring — would collapse the distinction between observed behavior and reviewed ground truth.
- Broad multi-agent orchestration/platform behavior — valuable, but wider than the next operator-loop milestone and more likely to create product-shape drift.

## Latest Shipped Milestone: v2.0 Relay

**Goal:** Turn the already-implemented bounded handoff lane into milestone-quality shipped truth with narrow scope, explicit support truth, and canonical verification.

**Delivered:**
- Public `Scoria.start_handoff_run/3` contract is explicit, narrow, and same-run rooted.
- Projected-context safety and delegated-lineage visibility are durable and inspectable.
- Adoption docs, source examples, `mix test.adoption`, and closeout records now prove the default handoff lane without optional-feature drift.

**Why it mattered:** The implementation wedge already existed in the repo, so formalizing and verifying it removed support-truth ambiguity before the next net-new capability bet.

## Context

- Scoria shipped `v2.0 Relay` on 2026-05-25 and opened `v2.1 Tenant-scoped semantic fast path` on 2026-05-25.
- `v1.9 Crucible` closed the replay -> score -> promote operator loop with canonical verification across Phases 37 through 40.
- `v2.0 Relay` converted the repo-local bounded handoff wedge into archived shipped truth and closed the earlier full-suite closeout exception with a fresh green baseline.
- `v2.1` treats semantic caching as Scoria-owned durable state, not as provider prompt caching or an invisible middleware trick.
- The repo has durable workflow truth, approval lineage, telemetry, audit seams, and a complete remote connector boundary.
- Repo-local research and seed context reinforce the same design direction: remain embedded, keep transport separate from LiveView, treat policy and approvals as durable records, and avoid AWS-shaped platform drift.
- After `v2.0 Relay`, semantic fast paths became the active next milestone because they compound the existing trust loop without widening the hosted-runtime surface.

## Constraints

- **Product shape**: Stay embedded and Phoenix-first — Scoria must remain a library plus dashboard surface, not a hosted connector platform.
- **State truth**: Keep auth, grants, approvals, and evidence durable in Ecto — operator trust depends on inspectable records rather than process-local state.
- **Security**: Default to least-privilege scopes, redaction, and approval on remote writes / exec / scope escalation.
- **DX**: Keep installation and verification boring for a normal Phoenix app path; only ask the user for materially impactful security or blast-radius choices.
- **Replay safety**: Replay must create new runs with explicit provenance and safe defaults; original run history is immutable.
- **Eval integrity**: Online scores are annotations, not release truth; sealed datasets remain immutable until explicitly promoted.
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
| `v2.1` semantic caching stays Scoria-owned, tenant-partitioned, and evidence-first instead of relying on provider prompt caches or invisible global reuse | Latency wins are only acceptable if partitioning, invalidation, and operator truth remain inspectable | — Active |

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

<details>
<summary>Archived pre-v2.0 milestone context</summary>

`v1.9 Crucible` targeted replay branches as durable new runs rooted in checkpoint truth, replay-safe execution defaults for external-write and approval-sensitive seams, operator-visible replay provenance with draft dataset promotion, and asynchronous online scoring with a review queue plus explicit promotion boundaries.

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
*Last updated: 2026-05-25 after opening v2.1 Tenant-scoped semantic fast path*
