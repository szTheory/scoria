# Phase 6: Advanced RAG, Citations & Knowledge Grounding - Pattern Map

**Mapped:** 2026-05-11
**Files analyzed:** 14
**Analogs found:** 11 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `priv/repo/migrations/*_create_knowledge_tables.exs` | migration | storage | `priv/repo/migrations/20260510174619_create_eval_tables.exs` | exact |
| `lib/scoria/knowledge.ex` | context | request-response | `lib/scoria/eval.ex` | exact |
| `lib/scoria/knowledge/source.ex` | schema | storage | `lib/scoria/eval/dataset.ex` | role-match |
| `lib/scoria/knowledge/chunk.ex` | schema | storage | `lib/scoria/repo/span.ex` | exact |
| `lib/scoria/knowledge/citation.ex` | schema | storage | `lib/scoria/eval/score.ex` | role-match |
| `lib/scoria/knowledge/retrieval_run.ex` | schema | storage | `lib/scoria/workflows/run.ex` | role-match |
| `lib/scoria/knowledge/retrieval_result.ex` | schema | storage | `lib/scoria/workflows/step.ex` | role-match |
| `lib/scoria/knowledge/grounding_score.ex` | schema | storage | `lib/scoria/eval/score.ex` | exact |
| `lib/scoria/knowledge/backends/pgvector.ex` | backend | storage-query | No close analog | N/A |
| `lib/scoria/knowledge/retrievers/scrypath.ex` | adapter | integration | `lib/scoria/observe/adapters/jido.ex` | role-match |
| `lib/scoria/knowledge/citation_formatter.ex` | pure module | transform | No close analog | N/A |
| `lib/scoria/knowledge/grounding.ex` | service | scoring | `lib/scoria/eval.ex` | role-match |
| `lib/scoria_web/components/citation_evidence_component.ex` | component | projection | `lib/scoria_web/components/trace_tree_component.ex` | exact |
| `lib/scoria_web/live/orchestrator_live.ex` | liveview | projection | `lib/scoria_web/live/orchestrator_live.ex` | exact |

## Pattern Assignments

### Ecto Context Pattern

**Analog:** `lib/scoria/eval.ex`

- Use a single public context module with explicit list/get/create/update functions.
- Use `Ecto.Multi` for immutable versioning and multi-row writes.
- Return `{:ok, struct}` / `{:error, changeset}` consistently.

### Ecto Schema Pattern

**Analogs:** `lib/scoria/repo/trace.ex`, `lib/scoria/repo/span.ex`, `lib/scoria/eval/*.ex`

- All new schemas should use:

```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
```

- Changesets should use explicit `cast/3` and `validate_required/2`.
- Use additive metadata maps instead of wide speculative columns.

### Migration Pattern

**Analog:** `priv/repo/migrations/20260510174619_create_eval_tables.exs`

- Additive migration with binary IDs and explicit indexes.
- Use `references(..., type: :binary_id)` consistently.
- Prefer one focused migration that declares the whole phase-6 knowledge foundation.

### Runtime / Retrieval Record Pattern

**Analogs:** `lib/scoria/workflows.ex`, `lib/scoria/workflows/run.ex`, `lib/scoria/workflows/step.ex`

- Retrieval runs/results should be explicit persisted nouns rather than transient tuples.
- Keep context writes atomic when a retrieval run and its ranked results are recorded together.

### LiveView Projection Pattern

**Analogs:** `lib/scoria_web/live/orchestrator_live.ex`, `lib/scoria_web/components/trace_tree_component.ex`

- Subscribe only when connected.
- Keep heavy evidence payloads out of initial mount assigns.
- Use `assign_async/3` or streaming for detail panels.
- Keep the trace selection as the operator's primary mental model.

### Installer Pattern

**Analog:** `lib/mix/tasks/scoria.install.ex`

- Modify existing router/tailwind injection helpers rather than adding a second install entrypoint.
- Keep route additions idempotent by checking existing content before writing.

## No Close Analog

| File | Why No Analog Exists | Planning Consequence |
|------|----------------------|----------------------|
| `lib/scoria/knowledge/backends/pgvector.ex` | Repo has no current vector-query module. | Planner should specify exact function contracts and tests rather than saying "follow existing pattern". |
| `lib/scoria/knowledge/citation_formatter.ex` | Repo has no current machine-readable citation renderer. | Keep it pure and heavily unit-tested. |
| `lib/scoria/knowledge/grounding.ex` | Existing eval context manages records, not evidence validation logic. | Separate scoring algorithms from persistence helpers. |

## Key Reuse Notes

- Reuse immutable versioning ideas from `Scoria.Eval` for rubric and scorer-version handling.
- Reuse trace/span metadata patterns for retrieval provenance rather than inventing a second event vocabulary.
- Reuse workflow context discipline for multi-step persistence boundaries such as ingest, reindex, and retrieval logging.

## Metadata

**Analog search scope:** `lib/**/*.ex`, `priv/repo/migrations/*.exs`, `test/**/*.exs`
**Files scanned:** 30+
