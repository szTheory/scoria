# Phase 36: Baseline And Inventory - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-20
**Phase:** 36-Baseline And Inventory
**Areas discussed:** Inventory artifact shape, Classification rules, Baseline proof boundary, Risk coverage

---

## Inventory Artifact Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Single human-readable inventory doc | Easy to review and idiomatic for docs, but weak as a future guardrail. | |
| Structured machine-readable index | Strong guardrail for later phases, but poor standalone maintainer DX and easy to overfit. | |
| Human-readable inventory plus structured companion index | Prose owns rationale; structured index owns canonical IDs and machine-checkable fields. | ✓ |

**User's choice:** Discuss and consider all; produce one perfect recommendation with research, subagents, prompt-corpus context, ecosystem lessons, and decisive defaults.

**Notes:** Research favored a paired artifact family. This balances HexDocs/Phoenix-style readable guidance with Storybook/design-system-style structured component/state metadata. The key footgun is duplicate truth, so the context locks prose vs index ownership.

---

## Classification Rules

| Option | Description | Selected |
|--------|-------------|----------|
| Layer + Status taxonomy | Separates what an item is from what should happen to it; spans components, pages, hooks, fixtures, tests, docs, and one-offs. | ✓ |
| Lifecycle-only taxonomy | Familiar for public design systems but hides duplication and missing abstractions. | |
| Reuse-signal taxonomy | Useful discovery heuristic but risks over-abstracting page-specific workflows. | |
| Strict Phoenix ownership taxonomy | Good implementation lens but too provider-centric if used alone. | |

**User's choice:** Discuss and consider all; emphasize idiomatic Elixir/Phoenix/Plug/Ecto, DX, least surprise, and strong architecture.

**Notes:** The selected taxonomy uses `layer` plus `status`, with mandatory evidence and next-action fields. Phoenix ownership remains an evidence dimension: function components with `attr`/`slot` contracts are preferred for primitives; JS hooks stay limited to browser interop.

---

## Baseline Proof Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Git evidence only | Proves commit separation but not current behavior. | |
| Tests only | Idiomatic Phoenix proof but does not prove cleanup was committed separately. | |
| Snapshot/screenshots only | Useful visual reference but brittle as a hard gate. | |
| Layered lightweight baseline proof | Git provenance plus existing tests/DS-06 plus advisory screenshots; no UI implementation. | ✓ |

**User's choice:** Discuss and consider all; produce coherent recommendations that move toward the project goals without unnecessary user decisions.

**Notes:** The selected proof boundary keeps Phase 36 from becoming a UI-fix phase. It proves baseline truth through git history and existing proof surfaces, while recording visual/UI concerns for later phases.

---

## Risk Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Flat known-risk list | Fast but weak ownership and closeout traceability. | |
| Risk register with owner/phase/evidence | Strong accountability but detached from local inventory context if used alone. | |
| Per-inventory item risk annotations | Local context but noisy for cross-cutting risks. | |
| Hybrid register plus per-item risk refs | Central risk truth with local cross-links and stable IDs. | ✓ |

**User's choice:** Fold UI todos where applicable and consider UX/JTBD/persona/flows, design pillars, SRE/DevOps proof, and user psychology.

**Notes:** The selected model creates stable risk IDs and per-item `risk_refs`. The two UI todos are folded as known risks: approval toast legibility maps to Phase 38; approval decision history maps to Phase 39.

---

## Claude's Discretion

- Exact artifact filenames and structured index format may be chosen during planning, as long as the phase produces a human-readable inventory and a structured companion index.
- Research/planning agents should ask the user again only if a decision changes product shape, policy/security boundary, durable truth, tenant blast radius, or materially different operator/adopter workflow.

## Deferred Ideas

- PhoenixStorybook evaluation is deferred until after the dev-only component lab proves insufficient.
- Screenshot-diff CI is deferred unless Phase 41 finds the harness deterministic enough.
- Approval toast legibility fix belongs to Phase 38.
- Approval decision history belongs to Phase 39.
- CI cache-key cleanup and sibling Docker fleet hardening remain outside v3.3 UI inventory scope.
