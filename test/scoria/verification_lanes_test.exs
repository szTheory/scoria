defmodule Scoria.VerificationLanesTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes

  test "lane contract defines command, env, prerequisites, and exclusions for every lane" do
    lane_ids = VerificationLanes.ids()

    assert lane_ids == [
             :release_preview,
             :adoption,
             :runtime_to_handoff,
             :semantic_fast_path,
             :knowledge
           ]

    for lane <- VerificationLanes.all() do
      assert is_atom(lane.id)
      assert is_binary(lane.name)
      assert is_binary(lane.command)
      assert is_binary(lane.ci_command)
      assert lane.env in [:dev, :test]
      assert is_list(lane.prerequisites)
      assert is_list(lane.exclusions)
    end
  end

  test "closeout chain stays pinned to release-preview, adoption, and runtime-to-handoff" do
    assert VerificationLanes.closeout_order() == [
             :release_preview,
             :adoption,
             :runtime_to_handoff
           ]

    assert VerificationLanes.closeout_chain() ==
             """
             mix scoria.release_preview
             mix test.adoption
             mix test.runtime_to_handoff
             """
             |> String.trim()
  end

  test "default and runtime-to-handoff lanes share the same optional setup exclusions" do
    expected_sentence =
      "This lane does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup."

    assert VerificationLanes.boundary_sentence(:adoption) == expected_sentence
    assert VerificationLanes.boundary_sentence(:runtime_to_handoff) == expected_sentence
    assert VerificationLanes.boundary_sentence(:release_preview) == nil
  end

  test "ci lane ordering follows the canonical closeout chain" do
    ci_workflow = File.read!(".github/workflows/ci-verify.yml")
    release_preview = VerificationLanes.ci_command(:release_preview)
    adoption = VerificationLanes.ci_command(:adoption)
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    assert ci_workflow =~ release_preview
    assert ci_workflow =~ adoption
    assert ci_workflow =~ runtime_to_handoff

    assert index_of(ci_workflow, release_preview) < index_of(ci_workflow, adoption)
    assert index_of(ci_workflow, adoption) < index_of(ci_workflow, runtime_to_handoff)
  end

  defp index_of(content, needle) do
    case :binary.match(content, needle) do
      {index, _length} -> index
      :nomatch -> flunk("Expected to find #{inspect(needle)} in content")
    end
  end
end
