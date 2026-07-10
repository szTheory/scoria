# Reviewer Verification Compatibility

Compatibility note: this old `docs/operator_verification.md` source path is kept so copied GitHub links from 0.1.x documentation still land somewhere useful. The current guide name is **Reviewer Verification**, and the canonical source is [`guides/reviewer-verification.md`](../guides/reviewer-verification.md).

Use `guides/reviewer-verification.md` for the maintained verification suite: default runtime proof, reviewer trace inspection, dashboard scope proof, optional capability checks, and maintainer release-preview proof.

## Scope doctrine compatibility notes

Dashboard proof follows the scope doctrine: authorization remains delegated to the host while Scoria ships the seam and records trusted scope.

Eval proof follows the scope doctrine: Scoria owns scorer execution, score latency, and release gates; the host owns prompts, business truth, policy values, and end-user semantics.

Knowledge proof follows the scope doctrine: Scoria owns retrieval filtering, citation validation, and persisted evidence; the host supplies tenant/actor identity.

For maintainer proof, `mix test.knowledge --warnings-as-errors` verifies missing-tenant raises, cross-tenant retrieval exclusion, actor-scoped narrowing, and citation scope evidence.

Knowledge schema changes use the separate `KnowledgeMigrationRepo` path, record versions in `schema_migrations_knowledge`, and live under `priv/repo/knowledge_migrations/` rather than the default host migration path.

Phase 45 closeout proof remains the historical repair reference for these scope-doctrine checks.

This page is a compatibility source stub only. Do not treat it as the ExDoc canonical source or add it to ExDoc extras; the canonical guide ladder lives under `guides/`.

Older text may call this "operator verification." That phrase is preserved here only as compatibility context for copied links and 0.1.x references. New public documentation should say reviewer verification.
