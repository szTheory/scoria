defmodule Scoria.KnowledgeLaneContractTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes

  @expected_files [
    "test/scoria/knowledge/citation_formatter_test.exs",
    "test/scoria/knowledge/grounding_test.exs",
    "test/scoria/knowledge/pgvector_test.exs",
    "test/scoria/knowledge/retrieval_test.exs",
    "test/scoria/knowledge/scrypath_test.exs",
    "test/scoria/knowledge/tenant_isolation_test.exs",
    "test/scoria/knowledge/trust_test.exs",
    "test/scoria/knowledge_test.exs"
  ]

  test "knowledge lane file set is stable and every file uses Scoria.KnowledgeCase" do
    Mix.Task.load_all()

    assert function_exported?(Mix.Tasks.Scoria.Test.Knowledge, :knowledge_test_files, 0)

    actual = Mix.Tasks.Scoria.Test.Knowledge.knowledge_test_files()

    assert actual == @expected_files,
           "Knowledge file set changed — update @expected_files if intentional"

    for path <- actual do
      content = File.read!(path)

      assert content =~ "use Scoria.KnowledgeCase",
             "#{path} must use Scoria.KnowledgeCase to carry the :knowledge tag"
    end
  end

  test "knowledge lane command is discoverable and prerequisites reference pgvector" do
    assert VerificationLanes.command(:knowledge) == "mix test.knowledge"
    assert "mix scoria.pgvector.bootstrap" in VerificationLanes.prerequisites(:knowledge)
  end
end
