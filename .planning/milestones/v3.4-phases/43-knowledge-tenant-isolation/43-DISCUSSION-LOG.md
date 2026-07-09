# Phase 43: Knowledge tenant isolation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-04
**Phase:** 43-knowledge-tenant-isolation
**Areas discussed:** Scope contract, Schema and migration rollout, Fail-closed enforcement, Audit evidence propagation, Proof, docs, and operator DX

---

## Scope Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit `scope:` option | Preserve current opts-based API, normalize through one Knowledge scope helper, keep Plug/Conn out of core. | yes |
| Scope as first argument | Very visible and Phoenix-context-like, but larger public API churn. | |
| Top-level keyword opts only | Smallest patch, but repeats validation and weakens the named contract. | |
| Implicit process/Repo tenant | Low call-site noise, but hidden and fragile in async jobs/tests. | |

**User's choice:** User selected all areas for researched one-shot recommendations.
**Notes:** Research recommended explicit `scope:` plus shorthand `tenant_id`/`actor_id`/`scope_kind` normalization. Missing or conflicting scope raises.

---

## Schema and Migration Rollout

| Option | Description | Selected |
|--------|-------------|----------|
| Additive knowledge migration with quarantined legacy rows | Upgrade-safe, preserves separate knowledge migration source, requires explicit backfill for historical data. | yes |
| Nullable forever | Lowest migration pressure, but keeps weak invariants. | |
| Recreate and reingest | Clean schema, but bad Hex-adopter DX and expensive embeddings. | |
| Per-tenant prefixes/partitions | Stronger physical isolation, but too operationally heavy for Scoria default. | |

**User's choice:** User selected all areas for researched one-shot recommendations.
**Notes:** Do not mutate the original knowledge migration or main no-op migration shell. Do not invent a default tenant for legacy rows.

---

## Fail-Closed Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Scope helper plus leaf Ecto filters | Public boundary and backend/result/citation leaves all validate tenant scope. | yes |
| Repo `prepare_query` auto-injection | Broad but hidden, and awkward for optional library-owned knowledge paths. | |
| Postgres RLS primary enforcement | Strong database defence-in-depth, but too much deployment/session plumbing for Phase 43. | |

**User's choice:** User selected all areas for researched one-shot recommendations.
**Notes:** `Pgvector`, `Scrypath`, `list_source_chunks`, result insertion, and citation insertion all need their own tenant-aware checks.

---

## Audit Evidence Propagation

| Option | Description | Selected |
|--------|-------------|----------|
| Duplicated first-class audit columns | Retrieval runs/results/citations carry tenant and actor evidence directly. | yes |
| Join back to source/chunk only | Less duplication, but weaker operator proof and more fragile audit queries. | |
| Metadata-only evidence | Small migration, but easy to miss and poor for tests/UI. | |

**User's choice:** User selected all areas for researched one-shot recommendations.
**Notes:** Operator-visible proof should say Tenant/Scope/Actor, not backend namespace/HNSW/SQL internals.

---

## Proof, Docs, and Operator DX

| Option | Description | Selected |
|--------|-------------|----------|
| Focused knowledge lane plus existing evidence UI | Add deterministic tests and small docs/UI evidence updates without new route. | yes |
| Postgres RLS proof | Useful later, but not the primary phase proof. | |
| Backend namespace proof | Adapter-only and insufficient for pgvector/Ecto audit rows. | |
| New Knowledge dashboard | More UI than this P0 fix needs. | |

**User's choice:** User selected all areas for researched one-shot recommendations.
**Notes:** Add `tenant_isolation_test.exs`, update the knowledge lane contract, update optional knowledge docs, and only extend existing citation/retrieval evidence surfaces if UI is touched.

---

## Claude's Discretion

- Exact helper name and function names for Knowledge scope normalization.
- Whether not-null hardening lands in the same migration or a follow-up after explicit legacy backfill/quarantine proof.
- Exact evidence component placement if existing UI components differ.

## Deferred Ideas

- Postgres RLS as later defence-in-depth.
- Per-tenant prefixes/partitions or dedicated vector collections for host-specific regulated/large deployments.
- New Knowledge Home/global scope UI beyond existing evidence surfaces.
- Backend-native namespace adapters as future backend details.
- Reviewed but not folded: `ci-policy-job-cache-key-mislabel.md`, `docker-dx-fleet-hardening.md`, `2026-06-20-add-approval-decision-history.md`.
