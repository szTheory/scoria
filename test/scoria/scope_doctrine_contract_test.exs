defmodule Scoria.ScopeDoctrineContractTest do
  use ExUnit.Case, async: true

  @project ".planning/PROJECT.md"
  @readme "README.md"
  @adoption_lanes "docs/adoption_lanes.md"
  @operator_verification "docs/operator_verification.md"
  @scope_table_title "What Scoria owns vs what your app owns"
  @scope_table_headers [
    "Boundary",
    "Scoria owns",
    "Your Phoenix app owns",
    "Why this boundary exists",
    "Example / verification"
  ]
  @scope_table_rows [
    "Run records and traces",
    "Reviewer dashboard scope",
    "Governance gates",
    "Eval and release proof",
    "Knowledge retrieval and grounding"
  ]
  @host_owned_responsibilities [
    "authentication",
    "authorization",
    "tenant membership",
    "role values",
    "thresholds",
    "policy values",
    "escalation rules",
    "prompts",
    "success definitions",
    "expected outputs",
    "tenant/actor identity",
    "corpus",
    "business meaning",
    "end-user answer surface"
  ]
  @pgvector "lib/scoria/knowledge/backends/pgvector.ex"
  @chunker "lib/scoria/knowledge/chunker.ex"
  @eval_paths [
    "lib/scoria/eval/runner.ex",
    "lib/scoria/eval/judge_runner.ex",
    "lib/scoria/eval/online_scoring.ex"
  ]

  test "project records the scope doctrine SSOT and v3.4 key decisions" do
    project = File.read!(@project)

    assert project =~ "Scoria owns the verb"

    for marker <- ~w(P1 P2 P3 P4 P5 P6) do
      assert project =~ marker, "expected #{@project} to retain #{marker}"
    end

    assert project =~ "fix + prove only"
    assert project =~ "v3.4 fixes fail CLOSED and isolate by tenant"
  end

  test "adopter and operator docs cross-link the doctrine at eval, knowledge, dashboard, and closeout seams" do
    readme = File.read!(@readme)
    adoption_lanes = File.read!(@adoption_lanes)
    operator_verification = File.read!(@operator_verification)

    assert readme =~ "scope doctrine SSOT in `.planning/PROJECT.md ## Constraints`"

    assert adoption_lanes =~
             "Scope doctrine mechanism-vs-noun boundary: Scoria owns the dashboard scope seam and trusted scope record; the host owns authentication, authorization, membership policy, and role values."

    assert adoption_lanes =~
             "Scope doctrine mechanism-vs-noun boundary: Scoria owns retrieval filtering, citation validation, and persisted evidence; the host owns tenant/actor identity, business truth, and end-user semantics."

    assert operator_verification =~
             "Dashboard proof follows the scope doctrine: authorization remains delegated to the host while Scoria ships the seam and records trusted scope."

    assert operator_verification =~
             "Eval proof follows the scope doctrine: Scoria owns scorer execution, score latency, and release gates; the host owns prompts, business truth, policy values, and end-user semantics."

    assert operator_verification =~
             "Knowledge proof follows the scope doctrine: Scoria owns retrieval filtering, citation validation, and persisted evidence; the host supplies tenant/actor identity."

    assert operator_verification =~ "Phase 45 closeout proof"
  end

  test "knowledge tenant contract docs stay pinned to automated proof evidence" do
    readme = File.read!(@readme)
    adoption_lanes = File.read!(@adoption_lanes)
    operator_verification = File.read!(@operator_verification)

    assert readme =~
             "Retrieval and citations in this capability are tenant-scoped; the host supplies tenant/actor identity, and missing tenant scope fails closed instead of broadening a query."

    assert adoption_lanes =~
             "The host app supplies tenant/actor identity for this capability. Scoria enforces that scope at storage, retrieval, citation, and grounding boundaries; metadata filters can narrow results inside a tenant but are not security proof."

    assert operator_verification =~
             "For maintainer proof, `mix test.knowledge --warnings-as-errors` verifies missing-tenant raises, cross-tenant retrieval exclusion, actor-scoped narrowing, and citation scope evidence."

    assert operator_verification =~
             "Knowledge schema changes use the separate `KnowledgeMigrationRepo` path, record versions in `schema_migrations_knowledge`, and live under `priv/repo/knowledge_migrations/` rather than the default host migration path."
  end

  test "public docs expose adopter-readable owns-vs-delegates table" do
    {path, table_section} = public_scope_table_source!()

    assert table_section =~ @scope_table_title

    for header <- @scope_table_headers do
      assert table_section =~ header,
             "expected #{path} scope table to contain header #{inspect(header)}"
    end

    for row <- @scope_table_rows do
      assert table_section =~ row,
             "expected #{path} scope table to contain boundary row #{inspect(row)}"
    end

    for responsibility <- @host_owned_responsibilities do
      assert String.downcase(table_section) =~ responsibility,
             "expected #{path} scope table to assign #{inspect(responsibility)} to the host app"
    end

    refute Regex.match?(~r/(^|\|)\s*P[1-6]\b/m, table_section),
           "expected #{path} scope table to use adopter-readable row labels, not P1-P6 labels"
  end

  test "phase 45 repaired code paths reject fake measurement leftovers" do
    pgvector = active_source(@pgvector)
    chunker = active_source(@chunker)
    eval_sources = @eval_paths |> Enum.map(&active_source/1) |> Enum.join("\n")

    assert pgvector =~ "not is_nil(chunk.embedding)"
    assert pgvector =~ "cosine_distance(chunk.embedding"
    refute pgvector =~ "score_chunk"
    refute pgvector =~ "Enum.sum"

    assert chunker =~ "next_offset = chunk.end_offset"
    refute chunker =~ ":overlap"
    refute chunker =~ "max(chunk.end_offset"

    assert eval_sources =~ "Timing.measure"
    assert eval_sources =~ "Timing.elapsed_ms"
    refute Regex.match?(~r/latency_ms"\s*=>\s*0\b/, eval_sources)
    refute Regex.match?(~r/latency_ms:\s*0\b/, eval_sources)
    refute Regex.match?(~r/duration_ms:\s*0\b/, eval_sources)
  end

  defp public_scope_table_source! do
    [@readme, @adoption_lanes, @operator_verification]
    |> Enum.find_value(fn path ->
      content = File.read!(path)

      if String.contains?(content, @scope_table_title) do
        {path, section_from_title(content)}
      end
    end) ||
      flunk("expected README or stable adopter docs to contain #{@scope_table_title} table")
  end

  defp section_from_title(content) do
    [_before, rest] = String.split(content, @scope_table_title, parts: 2)
    section = @scope_table_title <> rest

    section
    |> String.split(~r/\n##\s+/, parts: 2)
    |> hd()
  end

  defp active_source(path) do
    path
    |> File.read!()
    |> String.split("\n")
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.join("\n")
  end
end
