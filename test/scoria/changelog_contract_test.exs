defmodule Scoria.ChangelogContractTest do
  use ExUnit.Case, async: true

  alias Scoria.AdopterDocContract

  @changelog "CHANGELOG.md"
  @readme "README.md"

  test "CHANGELOG satisfies adopter release contract" do
    content = File.read!(@changelog)

    assert content =~ "Planning milestones vs Hex releases"

    for noun <- AdopterDocContract.shipped_capability_nouns() do
      assert String.contains?(String.downcase(content), String.downcase(noun)),
             "expected CHANGELOG to mention capability noun #{inspect(noun)}"
    end

    for refute <- AdopterDocContract.milestone_banner_refutes() do
      refute content =~ refute
    end

    refute content =~ "### Summary"
  end

  test "CHANGELOG has a single ordered Unreleased terminology migration note" do
    content = File.read!(@changelog)

    assert count_occurrences(content, "## [Unreleased]") == 1
    assert index_of!(content, "## [Unreleased]") < index_of!(content, "## [0.1.2]")

    unreleased = section!(content, "## [Unreleased]", "## [0.1.2]")

    assert unreleased =~ "### Changed"
    assert unreleased =~ "Pre-1.0 terminology migration"
    assert unreleased =~ "unreleased main-branch changes"
    assert unreleased =~ "Hex release remains `0.1.2` until Phase 50"
    assert unreleased =~ "no database migration"
    assert unreleased =~ "RAG/citation evidence"
    assert unreleased =~ "`evidence_refs` stay unchanged"
    assert unreleased =~ "legacy aliases remain accepted"

    for final <- [
          "reviewer",
          "trace",
          "verification suite",
          "scoped context",
          "semantic cache",
          "optional knowledge base"
        ] do
      assert unreleased =~ final
    end
  end

  test "README install section carries the terminology migration upgrade note" do
    readme = File.read!(@readme)

    install_index = index_of!(readme, "## Install")
    note_index = index_of!(readme, "Pre-1.0 terminology migration")
    upgrade_index = index_of!(readme, "### Upgrading or re-running install")

    assert install_index < note_index
    assert note_index < upgrade_index

    note = String.slice(readme, note_index, upgrade_index - note_index)

    assert note =~ "Hex release remains `0.1.2` until Phase 50"
    assert note =~ "unreleased main-branch terminology"
    assert note =~ "legacy aliases remain accepted"
    assert note =~ "RAG/citation evidence"
    assert note =~ "`evidence_refs` stay unchanged"
    assert note =~ "no database migration"
  end

  test "historical changelog notes are not treated as current migration copy" do
    content = File.read!(@changelog)

    assert content =~ "Historical main-branch notes"
    assert section!(content, "## [Unreleased]", "## [0.1.2]") =~
             "Historical sections below may retain old terminology as history."
  end

  defp count_occurrences(content, needle) do
    content
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end

  defp section!(content, start_marker, end_marker) do
    start_index = index_of!(content, start_marker)
    end_index = index_of!(content, end_marker)

    String.slice(content, start_index, end_index - start_index)
  end

  defp index_of!(content, needle) do
    case :binary.match(content, needle) do
      {index, _length} -> index
      :nomatch -> flunk("expected to find #{inspect(needle)}")
    end
  end
end
