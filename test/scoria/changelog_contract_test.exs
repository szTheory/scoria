defmodule Scoria.ChangelogContractTest do
  use ExUnit.Case, async: true

  alias Scoria.AdopterDocContract

  @changelog "CHANGELOG.md"

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
end
