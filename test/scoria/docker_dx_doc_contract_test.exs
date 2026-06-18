defmodule Scoria.DockerDxDocContractTest do
  use ExUnit.Case, async: true

  @doc_path "docs/docker_dev_dx.md"

  test "pins Docker and native dev loop reader tokens" do
    docs = docker_dx_docs()

    for fragment <- [
          "make up",
          "make dev",
          "make nuke",
          "ANTHROPIC_API_KEY"
        ] do
      assert_doc_contains!(docs, fragment, "Docker/native dev-DX contract")
    end

    assert_any_doc_fragment!(docs, ["4799", "http://localhost:4799/scoria"], "native URL")
    assert_any_doc_fragment!(docs, ["direnv", "1Password"], "process-scoped secrets setup")
  end

  test "pins cache-table reader strings" do
    docs = docker_dx_docs()

    for fragment <- [
          "mix deps.get",
          "mix deps.compile",
          "app compile only"
        ] do
      assert_doc_contains!(docs, fragment, "Docker cache-table contract")
    end
  end

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

  defp assert_any_doc_fragment!(docs, fragments, contract) do
    assert Enum.any?(fragments, &String.contains?(docs, &1)),
           """
           DOCS-03 lost the #{contract} fragment set #{inspect(fragments)} in #{@doc_path}.
           Restore the Docker/native dev-DX contract, or update this guard with Phase 34 rationale.
           """
  end
end
