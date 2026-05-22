# Scoria

## What This Is

Scoria is a Phoenix-native AI application quality layer for Elixir teams. It gives existing Phoenix apps trace-first observability, durable workflow state, knowledge grounding, approvals, operator-visible evidence, and a public runtime surface without forcing teams into a hosted agent platform shape.

The product boundary stays embedded and Ecto/Telemetry-native: Scoria should feel like a library and dashboard surface that fits into a normal Phoenix application, not a separate runtime people have to work around.

## Core Value

Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## Current State

- Scoria is shipped through `v1.8 Vanguard` as of 2026-05-22.
- `v1.8 Vanguard` added resilient multi-model fallback orchestration, distributed evaluation fan-out, real-time operator dashboards, and reconciled shipped-state planning surfaces.
- `v1.9 Crucible` is now active, focused on replayable debugging and online quality feedback.

## Next Milestone Goals

- Close the operator loop around traces by turning replay and online scoring into first-class, reviewable product surfaces.
- Keep the scope anchored to Phoenix-first adoption value, durable operator-visible truth, and boring verification.
- Defer broad multi-agent productization, semantic caching, and any automatic mutation of sealed eval truth until the replay/score loop is proven.

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

### Active

- [ ] Operator can branch a replay run from durable checkpoint truth without mutating the original run.
- [ ] Replay defaults preserve operator trust by blocking or stubbing unsafe external effects and keeping provenance explicit.
- [ ] Production traces can be scored asynchronously and routed into operator review and draft promotion queues without mutating sealed eval datasets.

### Out of Scope

- Full hosted connector marketplace or broker behavior — would drift Scoria away from its embedded Phoenix product shape.
- First-party browser/code-exec productization — adds a separate privileged-execution risk class before connector policy and evidence are proven boring.
- Deep external runtime interoperability — valuable, but not ahead of making remote connector governance unsurprising in ordinary Phoenix apps.
- Automatic mutation of sealed baseline datasets from online scoring — would collapse the distinction between observed behavior and reviewed ground truth.
- Broad multi-agent orchestration/platform behavior — valuable, but wider than the next operator-loop milestone and more likely to create product-shape drift.

## Current Milestone: v1.9 Crucible

**Goal:** Turn Scoria's existing trace, workflow, and eval substrate into a closed operator loop for replayable debugging, online scoring, and reviewable dataset promotion.

**Target features:**
- replay branches as durable new runs rooted in checkpoint truth
- replay-safe execution defaults for external-write and approval-sensitive seams
- replay provenance and draft dataset promotion in the LiveView operator surface
- asynchronous online scoring with a review queue and explicit promotion boundaries

**Why now:** Scoria already owns durable runs, trace-first UI, trace-to-dataset promotion, eval fan-out, and operator dashboards. Closing the replay -> score -> promote loop compounds those assets better than broader future-bet capabilities.

## Context

- Scoria is shipped through `v1.8 Vanguard` as of 2026-05-22.
- Phase 35 restored the canonical v1.8 verification chain on 2026-05-21.
- Phase 36 reconciled the live planning and milestone-state surfaces on 2026-05-22.
- `v1.8 Vanguard` shipped on 2026-05-22 with accepted closeout debt limited to Nyquist metadata normalization for Phases 30-32 if they re-enter audit scope.
- The repo has durable workflow truth, approval lineage, telemetry, audit seams, and a complete remote connector boundary.
- Repo-local research and seed context reinforce the same design direction: remain embedded, keep transport separate from LiveView, treat policy and approvals as durable records, and avoid AWS-shaped platform drift.
- Milestone discovery research on 2026-05-22 converged on replayable debugging plus online scoring as the most coherent next move because it compounds existing workflow, eval, and operator UX seams while preserving least surprise.
- The same research explicitly deferred broad multi-agent productization and semantic caching to later milestones unless they become the highest-priority adoption bets.

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
| `v1.9` should prioritize replayable debugging and online scoring over semantic caching or broad handoff productization | It compounds existing trace/eval/operator surfaces with less platform-drift risk and a clearer Phoenix-first value proposition | — Pending |
| Online scoring must never auto-mutate sealed baseline datasets | Observed production behavior is not reviewed ground truth; operator trust depends on keeping those lanes separate | — Pending |

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
*Last updated: 2026-05-22 after opening v1.9 Crucible*
