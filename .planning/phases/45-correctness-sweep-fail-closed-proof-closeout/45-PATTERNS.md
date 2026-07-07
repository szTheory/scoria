# Phase 45: Correctness sweep + fail-closed proof & closeout - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 23
**Analogs found:** 23 / 23

Scope came from `45-CONTEXT.md`, `45-RESEARCH.md`, and `45-VALIDATION.md`. No root `AGENTS.md` or repo-local `.codex/skills` / `.agents/skills` instructions were present; vendored example `AGENTS.md` files were ignored.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/knowledge/backends/pgvector.ex` | service/backend | request-response retrieval, transform | `lib/scoria/knowledge/backends/pgvector.ex`; `lib/scoria/semantic_cache/lookup.ex` | exact + role-match |
| `lib/scoria/knowledge/grounding.ex` | utility/scorer | transform, validation | `lib/scoria/knowledge/grounding.ex`; `lib/scoria/eval/scorers/exact_match.ex` | exact |
| `lib/scoria/knowledge/chunker.ex` | utility | file-I/O, transform | `lib/scoria/knowledge/chunker.ex`; `test/scoria/knowledge/pgvector_test.exs` | exact |
| `lib/scoria/knowledge.ex` | service/context | CRUD, request-response | `lib/scoria/knowledge.ex`; `lib/scoria/knowledge/scope.ex` | exact |
| `lib/scoria/eval/verdict.ex` | service/policy | transform | `lib/scoria/eval/verdict.ex`; `.planning/phases/42-eval-fails-closed/42-PATTERNS.md` | exact |
| `lib/scoria/eval/runner.ex` | service/runner | batch | `lib/scoria/eval/runner.ex`; `lib/scoria/mcp/executor.ex` | exact + timing analog |
| `lib/scoria/eval/judge_runner.ex` | service/runner | request-response | `lib/scoria/eval/judge_runner.ex`; `test/scoria/eval/judge_runner_test.exs` | exact |
| `lib/scoria/eval/online_scoring.ex` | service/runner | event-driven, request-response | `lib/scoria/eval/online_scoring.ex`; `lib/scoria/eval/judge_runner.ex` | exact |
| `lib/scoria/eval.ex` | service/context | CRUD, batch aggregation | `lib/scoria/eval.ex` | exact |
| `test/scoria/knowledge/pgvector_test.exs` | test | request-response retrieval | `test/scoria/knowledge/pgvector_test.exs`; `test/scoria/knowledge/tenant_isolation_test.exs` | exact |
| `test/scoria/knowledge/retrieval_test.exs` | test | request-response retrieval | `test/scoria/knowledge/retrieval_test.exs` | exact |
| `test/scoria/knowledge/grounding_test.exs` | test | transform, CRUD proof | `test/scoria/knowledge/grounding_test.exs`; `test/scoria/eval/scorers/exact_match_test.exs` | exact |
| `test/scoria/knowledge_test.exs` | test | CRUD, file-I/O proof | `test/scoria/knowledge_test.exs`; `test/scoria/knowledge/pgvector_test.exs` | exact |
| `test/scoria/eval/verdict_test.exs` | test | transform | `test/scoria/eval/verdict_test.exs` | exact |
| `test/scoria/eval/offline_runner_test.exs` | test | batch | `test/scoria/eval/offline_runner_test.exs` | exact |
| `test/scoria/eval/judge_runner_test.exs` | test | request-response | `test/scoria/eval/judge_runner_test.exs` | exact |
| `test/scoria/eval/online_scoring_test.exs` | test | event-driven | `test/scoria/eval/online_scoring_test.exs` | exact |
| `test/scoria/scope_doctrine_contract_test.exs` | test | batch/source-doc contract | `test/scoria/adoption_surface_test.exs`; `test/scoria/docker_dx_doc_contract_test.exs` | role-match |
| `README.md` | docs | batch documentation | `README.md`; `docs/adoption_lanes.md` | exact |
| `docs/adoption_lanes.md` | docs | batch documentation | `docs/adoption_lanes.md`; Phase 43/44 docs patterns | exact |
| `docs/operator_verification.md` | docs | batch documentation | `docs/operator_verification.md`; Phase 43/44 proof wording | exact |
| `.planning/PROJECT.md` | docs/planning | batch doctrine SSOT | `.planning/PROJECT.md` | exact |
| `.planning/phases/45-correctness-sweep-fail-closed-proof-closeout/45-VERIFICATION.md` | docs/proof | batch closeout rationale | `.planning/phases/42-eval-fails-closed/42-VERIFICATION.md` | role-match |

## Pattern Assignments

### `lib/scoria/knowledge/backends/pgvector.ex` (service/backend, request-response retrieval)

**Analogs:** current pgvector backend, semantic cache vector query, pgvector dependency macro.

**Imports pattern** (`lib/scoria/knowledge/backends/pgvector.ex`, lines 1-7):
```elixir
defmodule Scoria.Knowledge.Backends.Pgvector do
  import Ecto.Query, warn: false
  import Pgvector.Ecto.Query

  alias Scoria.Knowledge.Chunk
  alias Scoria.Knowledge.Scope
  alias Scoria.Repo
```

**Current retrieval query to preserve and repair** (`lib/scoria/knowledge/backends/pgvector.ex`, lines 19-45):
```elixir
def similar_chunks(query_embedding, opts \\ []) do
  scope = Scope.from_opts!(opts)
  limit = Keyword.get(opts, :limit, 5)
  filters = Keyword.get(opts, :filters, %{})
  source_id = Map.get(filters, :source_id) || Map.get(filters, "source_id")

  Chunk
  |> Scope.visible_to(scope)
  |> maybe_filter_source(source_id)
  |> order_by([chunk], asc: cosine_distance(chunk.embedding, ^Pgvector.new(query_embedding)))
  |> limit(^limit)
  |> Repo.all()
  |> Enum.with_index(1)
```

**Replace fake score path** (`lib/scoria/knowledge/backends/pgvector.ex`, lines 65-70):
```elixir
defp score_chunk(nil, _query_embedding), do: 0.0

defp score_chunk(embedding, query_embedding) do
  query_sum = Enum.sum(query_embedding)
  embedding_sum = embedding |> Pgvector.to_list() |> Enum.sum()
  1.0 / (1.0 + abs(embedding_sum - query_sum))
end
```

Planner should remove this private component-sum path from the active result flow. Copy the DB metric source instead.

**DB cosine operator source** (`deps/pgvector/lib/pgvector/ecto/query.ex`, lines 25-31):
```elixir
defmacro cosine_distance(left, right) do
  quote do
    fragment("(? <=> ?)", unquote(left), unquote(right))
  end
end
```

**Nil-embedding filter and order style** (`lib/scoria/semantic_cache/lookup.ex`, lines 71-80):
```elixir
attrs
|> base_query()
|> where([entry], not is_nil(entry.query_embedding))
|> where([entry], cosine_distance(entry.query_embedding, ^Pgvector.new(query_embedding)) <= ^@semantic_distance_threshold)
|> order_by([entry], asc: cosine_distance(entry.query_embedding, ^Pgvector.new(query_embedding)))
|> order_by([entry], desc: entry.updated_at)
```

Apply the same shape to chunks: tenant visibility first, source filter second, `not is_nil(chunk.embedding)` before ranking, and project a DB-derived `score = 1 - cosine_distance(...)` so ranking and persisted score share one metric.

### `lib/scoria/knowledge.ex` (service/context, CRUD/request-response)

**Analog:** current context persistence and validation flow.

**Retrieval run and latency precedent** (`lib/scoria/knowledge.ex`, lines 200-240):
```elixir
def retrieve(query_text, opts \\ []) do
  scope = Scope.from_opts!(opts)
  opts = Keyword.put(opts, :scope, scope)
  backend = Keyword.get(opts, :backend, Pgvector)
  limit = Keyword.get(opts, :limit, 5)
  filters = Keyword.get(opts, :filters, %{})
  started_at = System.monotonic_time(:millisecond)

  ...
  create_retrieval_run(%{
    query_text: query_text,
    backend: inspect(backend),
    top_k: limit,
    filters: filters,
    scope: scope,
    status: "completed",
    latency_ms: System.monotonic_time(:millisecond) - started_at
  })
```

**Atomic retrieval-result validation** (`lib/scoria/knowledge.ex`, lines 141-169 and 338-395):
```elixir
Multi.new()
|> Multi.run(:run, fn repo, _changes ->
  case repo.get(RetrievalRun, run_id) do
    nil -> {:error, :retrieval_run_not_found}
    %RetrievalRun{} = run -> {:ok, run}
  end
end)
|> Multi.run(:validated_results, fn repo, %{run: run} ->
  validate_retrieval_results(repo, run, results)
end)
|> Multi.run(:results, fn repo, %{run: run, validated_results: validated_results} ->
  ...
end)
|> Repo.transaction()
```

Use this for FIX-01 end-to-end proof: backend-projected cosine score should pass through `append_retrieval_results/2` unchanged, while invalid vector work should fail before persisted result rows exist.

### `lib/scoria/knowledge/grounding.ex` (utility/scorer, transform)

**Analog:** current deterministic scorer shape plus ExactMatch strict key handling.

**Current citation-presence score shape** (`lib/scoria/knowledge/grounding.ex`, lines 5-11):
```elixir
def score_citation_presence(%{citations: citations}) when is_list(citations) do
  score = if citations == [], do: 0.0, else: 1.0
  status = if score == 1.0, do: "passed", else: "failed"
  %{status: status, score: score, details: %{count: length(citations)}}
end

def score_citation_presence(_payload), do: %{status: "failed", score: 0.0, details: %{count: 0}}
```

**String/atom key fetch precedent** (`lib/scoria/eval/scorers/exact_match.ex`, lines 105-118):
```elixir
defp fetch(attrs, key) when is_map(attrs) or is_list(attrs) do
  attrs
  |> Enum.find(fn {candidate, _value} -> key_matches?(candidate, key) end)
  |> case do
    {_candidate, value} -> value
    nil -> nil
  end
end

defp key_matches?(candidate, key) do
  candidate == key or to_string(candidate) == to_string(key)
end
```

Add only the minimal `expected_answerable` / `answerable` label path. Missing label keeps the current empty-citations failure. Details should include `count` and `expected_answerable` when present.

### `lib/scoria/knowledge/chunker.ex` (utility, file-I/O transform)

**Analog:** current default chunker and repeat-ingest digest tests.

**Current no-op overlap path to remove** (`lib/scoria/knowledge/chunker.ex`, lines 8-35):
```elixir
def chunk(source, opts) do
  body = Map.get(source, :body) || Map.get(source, "body") || ""
  source_digest = Map.get(source, :digest) || Map.get(source, "digest") || ""
  overlap = Keyword.get(opts, :overlap, 24)

  body
  |> split_sections()
  |> Enum.map_reduce(0, fn %{heading_path: heading_path, text: text}, offset ->
    chunk = %{start_offset: offset, end_offset: offset + String.length(text)}
    next_offset = max(chunk.end_offset - overlap, chunk.end_offset)
    {chunk, next_offset}
  end)
```

Replace `next_offset` with `chunk.end_offset` and remove the `overlap` read. Do not add warning/raise behavior for `overlap:` in this phase.

**Digest/offset proof style** (`test/scoria/knowledge/pgvector_test.exs`, lines 13-39):
```elixir
test "ingest_source/2 uses chunker: and produces start_offset values for repeat ingest stability" do
  ...
  chunks = Knowledge.list_source_chunks(source.id, scope: @scope)
  assert Enum.all?(chunks, &is_integer(&1.start_offset))
  ...
  assert Enum.map(chunks, & &1.chunk_digest) == Enum.map(rerun_chunks, & &1.chunk_digest)
end
```

### `lib/scoria/eval/verdict.ex` (service/policy, transform)

**Analog:** existing Phase 42 fail-closed verdict spine.

**Fail-closed compute shape** (`lib/scoria/eval/verdict.ex`, lines 8-27):
```elixir
def compute(scores, threshold_policy) when is_list(scores) do
  scored = Enum.filter(scores, &item_scored?/1)

  cond do
    scores == [] -> :inconclusive
    scored == [] -> :inconclusive
    Enum.any?(scores, &(not item_scored?(&1))) and not_scored_tolerance(threshold_policy) == nil ->
      :inconclusive
    passes_policy?(scored, threshold_policy) -> :passed
    true -> :failed
  end
end
```

**Latency parsing bug site to repair** (`lib/scoria/eval/verdict.ex`, lines 51-70):
```elixir
defp latency_ms(score) do
  score
  |> fetch(:metadata)
  |> case do
    metadata when is_map(metadata) -> fetch(metadata, :latency_ms) || 0
    _ -> 0
  end
  |> case do
    value when is_integer(value) -> value
    value when is_binary(value) -> parse_integer(value)
    _ -> 0
  end
end
```

For FIX-04, keep unconfigured latency permissive, but when `max_latency_ms` is configured every scored item must have parseable latency. Missing/invalid latency under that policy returns `:inconclusive`, not `0`.

### `lib/scoria/eval/runner.ex` (service/runner, batch)

**Analog:** existing offline runner plus shared timing pattern.

**Runner completion shape** (`lib/scoria/eval/runner.ex`, lines 10-34):
```elixir
with :ok <- validate_dataset(dataset, eval_spec),
     {:ok, eval_run} <- create_eval_run(eval_spec, dataset, attrs),
     {:ok, eval_run, scores} <- record_scores(eval_run, dataset, eval_spec, attrs),
     {:ok, completed_run} <-
       Eval.complete_eval_run(eval_run, %{
         status: "completed",
         duration_ms: 0,
         threshold_verdict: eval_spec.threshold_policy |> then(&Verdict.compute(scores, &1)) |> Atom.to_string()
       }) do
  {:ok, %{eval_run: completed_run, scores: scores}}
end
```

Replace hardcoded `duration_ms: 0` with a measured run duration. Wrap scorer execution with monotonic timing and put the measured score latency into metadata.

**Score metadata sink** (`lib/scoria/eval/runner.ex`, lines 196-216):
```elixir
defp base_score_attrs(dataset_item, eval_run, eval_spec, attrs, scorer_kind) do
  %{
    dataset_item_id: dataset_item.id,
    scorer_kind: scorer_kind,
    judge_model: fetch(attrs, :judge_model) || fetch!(attrs, :model),
    rubric_version: "eval-spec-v#{eval_spec.version}",
    evidence_refs: %{"fixture_key" => eval_run.fixture_key},
    metadata: %{"latency_ms" => 0, "cost_usd" => "0.0"}
  }
end
```

Keep this metadata key. Change only its value source.

### `lib/scoria/eval/judge_runner.ex` (service/runner, request-response)

**Analog:** injected module seam and score attr construction.

**Injected no-live-LLM seam** (`lib/scoria/eval/judge_runner.ex`, lines 70-78):
```elixir
orchestrator_module =
  fetch(attrs, :orchestrator_module) ||
    Application.get_env(:scoria, :orchestrator_module, Scoria.Orchestrator)

opts =
  if rlm = fetch(attrs, :req_llm_module),
    do: [req_llm_module: rlm],
    else: []
```

**Judge score metadata sink** (`lib/scoria/eval/judge_runner.ex`, lines 119-134):
```elixir
case orchestrator_module.generate_object(model_spec, prompt, judge_schema(), opts) do
  {:ok, response} ->
    verdict = extract_object(response)
    score_attrs = %{
      dataset_item_id: dataset_item.id,
      status: Map.get(verdict, "status", "failed"),
      score: Map.get(verdict, "score", 0.0),
      metadata: %{"cost_usd" => "0.0", "latency_ms" => 0}
    }
```

Measure the `generate_object/4` call using the shared monotonic helper and persist that measured latency. Tests must keep using stub modules, not provider credentials.

### `lib/scoria/eval/online_scoring.ex` (service/runner, event-driven)

**Analog:** deterministic score path plus judge handoff.

**Deterministic-score attrs needing measured latency** (`lib/scoria/eval/online_scoring.ex`, lines 253-275):
```elixir
score_attrs =
  Enum.map(dataset_items, fn dataset_item ->
    %{
      dataset_item_id: dataset_item.id,
      scorer_kind: "deterministic_rule",
      status: "failed",
      score: 0.0,
      metadata: %{
        "candidate_id" => candidate.id,
        "negative_signal" => signal,
        "latency_ms" => 0,
        "cost_usd" => "0.0"
      }
    }
  end)
```

**Online completion shape** (`lib/scoria/eval/online_scoring.ex`, lines 279-300):
```elixir
defp maybe_run_judge(eval_run, eval_spec, _dataset, _target, deterministic_scores, true) do
  with {:ok, updated_run, scores} <- Eval.replace_eval_scores(eval_run, deterministic_scores),
       {:ok, completed_run} <-
         Eval.complete_eval_run(updated_run, %{
           status: "completed",
           duration_ms: 0,
           threshold_verdict: threshold_verdict(scores, eval_spec.threshold_policy)
         }) do
    {:ok, %{eval_run: completed_run, scores: scores}}
  end
end
```

Change both deterministic-score latency and terminal `duration_ms` to measured values. Clean traces that go to `JudgeRunner.run_existing/2` should rely on the judge timing path.

### `lib/scoria/eval.ex` (service/context, CRUD/batch aggregation)

**Analog:** existing score persistence and aggregate rollup.

**Persistence transaction** (`lib/scoria/eval.ex`, lines 892-908):
```elixir
defp persist_eval_scores(%EvalRun{} = eval_run, score_attrs_list, opts) do
  replace? = Keyword.get(opts, :replace?, false)

  Ecto.Multi.new()
  |> maybe_delete_scores(eval_run.id, replace?)
  |> Ecto.Multi.run(:scores, fn repo, _changes ->
    insert_scores(repo, eval_run, score_attrs_list)
  end)
  |> Ecto.Multi.update(:eval_run, fn %{scores: scores} ->
    aggregate_attrs = aggregate_score_attrs(eval_run, scores)
    EvalRun.changeset(eval_run, aggregate_attrs)
  end)
  |> Repo.transaction()
end
```

**Aggregate metadata extraction** (`lib/scoria/eval.ex`, lines 976-1003):
```elixir
defp aggregate_score_attrs(eval_run, scores) do
  total_items = length(scores)
  passed_items = Enum.count(scores, &(&1.status == "passed"))
  failed_items = Enum.count(scores, &(&1.status == "failed"))
  avg_latency_ms = average_integer(Enum.map(scores, &extract_latency_ms/1))
  total_cost_usd = decimal_sum(Enum.map(scores, &extract_cost_usd/1))
  ...
end

defp extract_latency_ms(score) do
  score.metadata
  |> Map.get("latency_ms", Map.get(score.metadata, :latency_ms))
end
```

Keep aggregation nil-tolerant for observability, but do not let `Verdict` default configured missing latency to zero.

### Eval timing helper pattern (applies to runner, judge runner, online scoring)

**Analog:** `Scoria.MCP.Executor`.

**Monotonic timing** (`lib/scoria/mcp/executor.ex`, lines 193-205):
```elixir
start_time = System.monotonic_time()

task = Task.Supervisor.async_nolink(Scoria.MCP.TaskSupervisor, fn ->
  tool_module.execute(args, context)
end)

case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
  {:ok, result} -> {:ok, {:completed, result, System.monotonic_time() - start_time}}
  nil -> {:error, {:timeout, System.monotonic_time() - start_time}}
  {:exit, reason} -> {:error, {:execution_failed, System.monotonic_time() - start_time, reason}}
end
```

**Native-to-millisecond conversion** (`lib/scoria/mcp/executor.ex`, lines 389-397):
```elixir
attrs =
  base_attrs(tool_module, context, outcome)
  |> Map.put(:duration_ms, System.convert_time_unit(duration_native, :native, :millisecond))
  |> Map.put(:success, outcome == "completed")

Telemetry.emit_latency(attrs)
```

Copy this style for Phase 45. Prefer one small private helper if it avoids duplicating fragile timing code across three eval modules.

### Knowledge tests (pgvector, retrieval, grounding, chunker)

**Knowledge case setup** (`test/support/knowledge_case.exs`, lines 1-27):
```elixir
defmodule Scoria.KnowledgeCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :knowledge
      alias Scoria.Repo
      import Ecto.Query
      import Scoria.KnowledgeCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Mix.Tasks.Scoria.Pgvector.Bootstrap.ensure_pgvector!()
    :ok
  end
end
```

**Pgvector tenant/ranking fixture shape** (`test/scoria/knowledge/pgvector_test.exs`, lines 67-80):
```elixir
tenant_a_chunk = insert_chunk!(tenant_a_source, "tenant-a", @scope, [0.1, 0.1, 0.1])
tenant_b_chunk = insert_chunk!(tenant_b_source, "tenant-b", @tenant_b_scope, [0.9, 0.9, 0.9])

assert {:ok, results} = Pgvector.similar_chunks([0.9, 0.9, 0.9], scope: @scope, limit: 5)

assert Enum.map(results, & &1.chunk_id) == [tenant_a_chunk.id]
refute Enum.any?(results, &(&1.chunk_id == tenant_b_chunk.id))
```

Add exact-match/orthogonal/nil-embedding/dimension behavior here. Keep tenant filtering assertions in the same tests so score projection cannot weaken Phase 43 isolation.

**Backend spy for persistence path** (`test/scoria/knowledge/retrieval_test.exs`, lines 12-23 and 73-83):
```elixir
defmodule BackendSpy do
  def similar_chunks(query_embedding, opts) do
    send(self(), {:backend_opts, query_embedding, opts})
    {:ok, []}
  end
end

assert_receive {:backend_opts, [0.1, 0.2, 0.3], opts}
assert %Scoria.Knowledge.Scope{tenant_id: "tenant-a", actor_id: "actor-a"} = opts[:scope]
```

Extend this suite for persisted score equality through `Knowledge.retrieve/2`.

**Grounding fail-closed style** (`test/scoria/knowledge/grounding_test.exs`, lines 52-72):
```elixir
result = Grounding.score_citation_validity(%{citations: [anchor]})

assert result.status == "failed"
assert result.score == 0.0
assert result.details == %{invalid: 1, total: 1}
```

Add the answerability matrix in this file: answerable/cited pass, answerable/empty fail, unanswerable/empty pass, unanswerable/cited fail, string-key label support, missing-label legacy fail.

### Eval tests (verdict, offline, judge, online)

**Eval case setup** (`test/support/eval_case.ex`, lines 1-25):
```elixir
defmodule Scoria.EvalCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Scoria.EvalCase
      import Tribunal
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    :ok
  end
end
```

**Verdict test policy shape** (`test/scoria/eval/verdict_test.exs`, lines 38-45 and 89-95):
```elixir
scores = [
  score(status: "passed", score: 1.0, metadata: %{"latency_ms" => 25}),
  score(status: "passed", score: 0.9, metadata: %{"latency_ms" => "35"})
]

assert Verdict.compute(scores, policy()) == :passed

defp policy do
  %{pass_rate_gte: 1.0, mean_score_gte: 0.9, max_latency_ms: 50}
end
```

Add over-threshold and missing/invalid latency tests here. A policy with `max_latency_ms` must return `:inconclusive` for missing or unparsable latency.

**Offline runner fixture** (`test/scoria/eval/offline_runner_test.exs`, lines 94-145):
```elixir
{:ok, dataset} = Eval.create_dataset(%{name: "offline-replay-dataset", items: [...]})
{:ok, dataset} = Eval.seal_dataset(dataset)
{:ok, eval_spec} = Eval.create_eval_spec(%{threshold_policy: %{max_latency_ms: 100}})
{:ok, dataset, eval_spec}
```

Extend assertions to verify `score.metadata["latency_ms"]` is present and parseable, and `result.eval_run.duration_ms` is measured rather than hardcoded.

**Judge stub seam** (`test/scoria/eval/judge_runner_test.exs`, lines 8-21):
```elixir
defmodule ReqLLMStub do
  def generate_object(model_spec, prompt, _schema, _opts) do
    send(self(), {:req_llm_called, model_spec, prompt})

    {:ok, %{object: %{"score" => 1.0, "status" => "passed", "explanation" => "Stubbed judge marked the sealed expectation as correct", "evidence_refs" => %{"judge" => "stub"}}}}
  end
end
```

Add a deterministic timing seam by options or helper injection; do not add `Process.sleep/1` or live provider calls.

**Online orchestrator stub and persisted-score assertions** (`test/scoria/eval/online_scoring_test.exs`, lines 21-35 and 162-183):
```elixir
defmodule OrchestratorStub do
  def generate_object(model_spec, prompt, schema, opts) do
    send(self(), {:orchestrator_called, model_spec, prompt, schema, opts})
    {:ok, %{object: %{"score" => 1.0, "status" => "passed", "explanation" => "Stubbed judge verdict", "evidence_refs" => %{"judge" => "stub"}}}}
  end
end

scores = Repo.all(from(score in Score, where: score.eval_run_id == ^eval_run.id))
assert [%Score{} = score] = scores
assert score.metadata["negative_signal"] == negative_signal
```

Extend these assertions for measured deterministic-rule latency and completed run duration.

### Docs and source/doc contract tests

**Doc contract test pattern** (`test/scoria/adoption_surface_test.exs`, lines 359-392):
```elixir
test "dashboard auth seam docs teach host-owned scope without Scoria-owned authorization" do
  lane_guide = File.read!(@lane_guide)
  operator_guide = File.read!(@operator_guide)
  maintainer_guide = File.read!(@maintainer_guide)

  for content <- [lane_guide, operator_guide] do
    assert content =~ "The host app authenticates the operator and asserts dashboard tenant scope."
    assert content =~ "Query params do not choose tenants for the dashboard."
    assert content =~ "Authorization remains delegated to the host; Scoria does not introduce a role model."
  end
end
```

**Source-scan helper pattern** (`test/scoria/docker_dx_doc_contract_test.exs`, lines 112-184):
```elixir
defp docker_dx_docs do
  File.read!(@doc_path)
end

defp assert_doc_contains!(docs, fragment, contract) do
  assert String.contains?(docs, fragment),
         """
         DOCS-03 lost the #{contract} fragment #{inspect(fragment)} in #{@doc_path}.
         Restore the Docker/native dev-DX contract, or update this guard with Phase 34 rationale.
         """
end
```

Use the same style for `test/scoria/scope_doctrine_contract_test.exs`: read `.planning/PROJECT.md`, `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`, and the Phase 45 closeout artifact if created. Assert the P1-P6 doctrine and the four narrow cross-link themes exist. Add a source scan for fake-score/fake-latency leftovers in active `lib/` code.

**PROJECT doctrine SSOT** (`.planning/PROJECT.md`, lines 365 and 408-414):
```markdown
- **Scope doctrine (build-vs-delegate SSOT, from the 2026-07-03 eval-posture audit)**: *Scoria owns the verb (record, gate, surface, reconstruct); the host owns the noun (identity, business truth, policy value, end-user).* **P1** durable record, not business truth ... **P6** prefer BEAM-native primitives ...
```

```markdown
| 2026-07-03 eval-posture audit validated Scoria's direction ... and codified the 6-principle scope doctrine (see Constraints) as the build-vs-delegate SSOT | ... |
| v3.4 (SEED-006) is **fix + prove only** - no Hex publish ... |
| v3.4 fixes fail CLOSED and isolate by tenant by **mirroring proven in-repo patterns** ... |
```

**Existing docs wording to extend narrowly:**

`README.md`, lines 218-227:
````markdown
Optional knowledge lane:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```

Retrieval and citations in this lane are tenant-scoped; the host supplies tenant/actor identity, and missing tenant scope fails closed instead of broadening a query.
````

`docs/adoption_lanes.md`, lines 142-161:
```markdown
### 4. Optional knowledge lane

Add this only when you are intentionally validating retrieval, citations, and grounding.
...
The host app supplies tenant/actor identity for this lane. Scoria enforces that scope at storage, retrieval, citation, and grounding boundaries; metadata filters can narrow results inside a tenant but are not security proof.
```

`docs/operator_verification.md`, lines 210-222:
````markdown
## Optional knowledge lane

Only after the default lane is proven should you expand into the knowledge-backed path:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```

For maintainer proof, `mix test.knowledge --warnings-as-errors` verifies missing-tenant raises, cross-tenant retrieval exclusion, actor-scoped narrowing, and citation scope evidence.
````

Add only short doctrine cross-links. Do not add a full owns-vs-delegates table, UI scope receipt, tenant switcher, or authz model.

### `.planning/phases/45-correctness-sweep-fail-closed-proof-closeout/45-VERIFICATION.md` (docs/proof, closeout rationale)

**Analog:** Phase 42 verification report.

**Observable truths table** (`.planning/phases/42-eval-fails-closed/42-VERIFICATION.md`, lines 21-29):
```markdown
| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Offline/judge eval executes or replays real subject output ... | VERIFIED | ... |
...
**Score:** 31/31 must-haves verified, including 5 roadmap success criteria ...
```

**Prohibition checks** (`.planning/phases/42-eval-fails-closed/42-VERIFICATION.md`, lines 109-121):
```markdown
| Prohibition | Status | Evidence |
|---|---|---|
| Empty or all-not-scored score sets must never pass. | VERIFIED | ... |
| Missing measurement must not become `0.0`; `not_scored` means `score: nil`. | VERIFIED | ... |
```

For Phase 45, use this shape to prove FIX-01..04 and DOC-01. Include explicit prohibition rows for component-sum retrieval scores, nil-embedding fake zero, hardcoded scorer latency zero, and chunker overlap no-op.

## Shared Patterns

### Fail-Closed Scope And Visibility

**Source:** `lib/scoria/knowledge/scope.ex`, lines 21-30 and 78-117.
**Apply to:** pgvector score query, retrieval persistence tests, docs wording.

```elixir
%__MODULE__{
  tenant_id: required_id!(Map.get(attrs, :tenant_id), :tenant_id),
  actor_id: optional_id(Map.get(attrs, :actor_id)),
  scope_kind: scope_kind!(Map.get(attrs, :scope_kind, "tenant_shared"))
}
|> validate!()
```

```elixir
query = where(query, [row], row.tenant_id == ^scope.tenant_id)

if present?(scope.actor_id) do
  where(query, [row], row.scope_kind == "tenant_shared" or (row.scope_kind == "actor_scoped" and row.actor_id == ^scope.actor_id))
else
  where(query, [row], row.scope_kind == "tenant_shared")
end
```

### No Fake Measurements

**Source:** `lib/scoria/eval/verdict.ex`, `lib/scoria/eval.ex`, Phase 42 verification.
**Apply to:** all eval runners, verdict policy, proof docs.

Unknown or missing evidence should stay missing or become `:inconclusive`; it must not become `0`, `0.0`, or `"passed"`. Aggregation can skip missing latency for observability, but a configured `max_latency_ms` gate must fail closed on missing parseable latency.

### Monotonic Timing

**Source:** `lib/scoria/mcp/executor.ex`, lines 196-205 and 389-397.
**Apply to:** `Runner`, `JudgeRunner`, `OnlineScoring`.

Use `System.monotonic_time()` in native units around the work, then `System.convert_time_unit(duration_native, :native, :millisecond)` for persisted metadata. Avoid `DateTime.utc_now()` deltas and test sleeps.

### No Live LLM Calls In Tests

**Source:** `test/scoria/eval/judge_runner_test.exs`, lines 8-21; `test/scoria/eval/online_scoring_test.exs`, lines 21-35.
**Apply to:** judge and online latency proof.

Use local stub modules that send messages and return deterministic judge objects. Do not require provider keys in CI.

### Docs Contract Guards

**Source:** `test/scoria/adoption_surface_test.exs`, lines 359-392; `test/scoria/docker_dx_doc_contract_test.exs`, lines 112-184.
**Apply to:** `test/scoria/scope_doctrine_contract_test.exs`.

Contract tests should read docs as strings, assert required fragments, and refute misleading forbidden fragments. Keep failure messages actionable and tied to the phase requirement.

### Knowledge Lane Test Inclusion

**Source:** `test/scoria/knowledge_lane_contract_test.exs`, lines 6-37; `test/support/knowledge_case.exs`, lines 8-27.
**Apply to:** all knowledge tests.

Knowledge tests use `Scoria.KnowledgeCase` and are excluded from the default suite unless the knowledge lane is selected. Verification commands should use `mix test.knowledge --warnings-as-errors` or include knowledge tests explicitly.

## No Analog Found

None. The new DOC-01 contract test has role-match analogs in existing doc contract/source-scan tests, and every correctness fix has an in-repo implementation and test pattern.

## Metadata

**Analog search scope:** `lib/scoria/knowledge`, `lib/scoria/eval`, `lib/scoria/semantic_cache`, `lib/scoria/mcp`, `test/scoria`, `test/support`, `docs`, `README.md`, `.planning/PROJECT.md`, prior phase pattern and verification artifacts.
**Files scanned:** 40+ paths via `rg`, `wc -l`, and line-numbered reads.
**Pattern extraction date:** 2026-07-07
**Primary phase inputs:** `.planning/phases/45-correctness-sweep-fail-closed-proof-closeout/45-CONTEXT.md`, `.planning/phases/45-correctness-sweep-fail-closed-proof-closeout/45-RESEARCH.md`, `.planning/phases/45-correctness-sweep-fail-closed-proof-closeout/45-VALIDATION.md`.
