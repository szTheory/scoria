defmodule Scoria.ScopeDoctrineContractTest do
  use ExUnit.Case, async: true

  @project ".planning/PROJECT.md"
  @readme "README.md"
  @adoption_lanes "docs/adoption_lanes.md"
  @operator_verification "docs/operator_verification.md"
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

  defp active_source(path) do
    path
    |> File.read!()
    |> String.split("\n")
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.join("\n")
  end
end
