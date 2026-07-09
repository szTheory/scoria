defmodule Scoria.VerificationSuitesTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationSuites

  test "suite contract defines command, env, prerequisites, and exclusions for every suite" do
    suite_ids = VerificationSuites.ids()

    assert suite_ids == [
             :release_preview,
             :adoption,
             :runtime_to_handoff,
             :semantic_fast_path,
             :knowledge,
             :connector,
             :support_copilot_gallery
           ]

    for suite <- VerificationSuites.all() do
      assert is_atom(suite.id)
      assert is_binary(suite.name)
      assert is_binary(suite.command)
      assert is_binary(suite.ci_command)
      assert suite.env in [:dev, :test]
      assert is_list(suite.prerequisites)
      assert is_list(suite.exclusions)
    end
  end

  test "closeout chain stays pinned to release-preview, adoption, and runtime-to-handoff" do
    assert VerificationSuites.closeout_order() == [
             :release_preview,
             :adoption,
             :runtime_to_handoff
           ]

    assert VerificationSuites.closeout_chain() ==
             """
             mix scoria.release_preview
             mix test.adoption
             mix test.runtime_to_handoff
             """
             |> String.trim()
  end

  test "default and runtime-to-handoff suites share the same optional setup exclusions" do
    expected_sentence =
      "This verification suite does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup."

    assert VerificationSuites.boundary_sentence(:adoption) == expected_sentence
    assert VerificationSuites.boundary_sentence(:runtime_to_handoff) == expected_sentence
    assert VerificationSuites.boundary_sentence(:release_preview) == nil
  end

  test "connector suite stays advisory outside closeout order" do
    refute :connector in VerificationSuites.closeout_order()
    assert VerificationSuites.command(:connector) == "mix test.connector"
    assert VerificationSuites.prerequisites(:connector) == ["mix test.adoption"]
  end

  test "support copilot gallery suite stays advisory outside closeout order" do
    refute :support_copilot_gallery in VerificationSuites.closeout_order()
    assert VerificationSuites.command(:support_copilot_gallery) == "mix scoria.test.support_copilot"
    assert VerificationSuites.prerequisites(:support_copilot_gallery) == ["mix test.adoption"]
  end
end
