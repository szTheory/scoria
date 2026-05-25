# Phase 44: Semantic cache contract and persistence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 44-semantic-cache-contract-and-persistence
**Areas discussed:** Eligibility API, Partition Scope, Persisted Truth

---

## Eligibility API

| Option | Description | Selected |
|--------|-------------|----------|
| Runtime opt-in per call | `Scoria.start_run(..., semantic_cache: [eligible?: true])` style flag at each call site | |
| Prompt-policy-driven classification | Cacheability implied from prompt policy metadata such as `cache_mode` or equivalent | |
| Explicit lane/module registration | Host app passes an explicit semantic lane/module registered as a safe read-only contract | ✓ |
| Handler/tool annotations only | Tool or handler metadata alone decides cacheability | |

**User's choice:** One-shot recommendation set delegated to the agent; locked recommendation is explicit lane/module registration as the primary contract.
**Notes:** Prompt policy and tool metadata remain subordinate narrowing/veto signals. Hidden middleware-style enablement was rejected as too surprising for Scoria’s support-truth posture.

---

## Partition Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Tenant-only shared answers | Every eligible answer is reusable across the tenant | |
| Always tenant-plus-actor scope | Every reusable answer is actor-specific | |
| Lane-classified fixed scope enum | Host app chooses tenant-shared or actor-scoped per lane | |
| Policy-key-derived scope | Policy/default keys define the reuse audience | |
| Hybrid tenant-rooted scope with actor escalation | Root all rows in tenant scope, escalate to actor scope only when personalization evidence requires it | ✓ |

**User's choice:** One-shot recommendation set delegated to the agent; locked recommendation is hybrid tenant-rooted scope with explicit actor escalation when required.
**Notes:** `tenant_id` is mandatory on every read/write. `session_id` stays out of the partition model. Policy/prompt/source metadata remain compatibility fences, not the primary namespace.

---

## Persisted Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated single rich entry table | One mutable semantic cache table stores all current state and lifecycle fields | |
| Dedicated entry table + append-only event table | Current reusable entry state in one table, lifecycle lineage in a second append-only table | ✓ |
| Overload existing retrieval tables | Reuse retrieval rows/tables to store reusable answer truth | |
| Piggyback on workflow metadata or compacted memories | Cache truth stored indirectly inside existing run/memory records | |

**User's choice:** One-shot recommendation set delegated to the agent; locked recommendation is a dedicated entry table plus append-only entry events table.
**Notes:** Misses and bypasses stay primarily in runtime/workflow evidence for now. Exact-first lookup and conservative indexes remain the default posture.

---

## the agent's Discretion

- Final naming for lane behaviour modules and helper namespaces.
- Exact schema field names and index names that preserve the locked contract.
- Exact TTL defaults, embedding model selection, and threshold values within the conservative exact-first posture.

## Deferred Ideas

- Rich compatibility evaluator and invalidation engine in Phase 45.
- Operator evidence projection and verification lanes in Phase 46.
- ANN tuning, external cache backends, and broader analytics beyond milestone proof.
