defmodule Scoria.VerificationLanesTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes
  alias Scoria.VerificationSuites

  test "legacy lane module delegates to verification suites" do
    source = File.read!("lib/scoria/verification_lanes.ex")

    assert source =~ "Scoria.VerificationSuites"
    refute source =~ "@lanes"

    assert VerificationLanes.all() == VerificationSuites.all()
    assert VerificationLanes.command(:adoption) == VerificationSuites.command(:adoption)
    assert VerificationLanes.closeout_chain() == VerificationSuites.closeout_chain()
  end

  test "lane contract defines command, env, prerequisites, and exclusions for every lane" do
    lane_ids = VerificationLanes.ids()

    assert lane_ids == [
             :release_preview,
             :adoption,
             :runtime_to_handoff,
             :semantic_fast_path,
             :knowledge,
             :connector,
             :support_copilot_gallery
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
      "This verification suite does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup."

    assert VerificationLanes.boundary_sentence(:adoption) == expected_sentence
    assert VerificationLanes.boundary_sentence(:runtime_to_handoff) == expected_sentence
    assert VerificationLanes.boundary_sentence(:release_preview) == nil
  end

  test "connector lane stays advisory outside closeout order" do
    refute :connector in VerificationLanes.closeout_order()
    assert VerificationLanes.command(:connector) == "mix test.connector"
    assert VerificationLanes.prerequisites(:connector) == ["mix test.adoption"]
  end

  test "support copilot gallery lane stays advisory outside closeout order" do
    refute :support_copilot_gallery in VerificationLanes.closeout_order()

    assert VerificationLanes.command(:support_copilot_gallery) ==
             "mix scoria.test.support_copilot"

    assert VerificationLanes.prerequisites(:support_copilot_gallery) == ["mix test.adoption"]
  end

  test "ci lane ordering follows the canonical closeout chain" do
    ci_workflow = File.read!(".github/workflows/ci-verify.yml")
    release_preview = VerificationLanes.ci_command(:release_preview)
    adoption = VerificationLanes.ci_command(:adoption)
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    # Extract the test: job body to scope intra-job step order assertions
    test_body =
      case :binary.match(ci_workflow, "\n  test:") do
        {start, _} ->
          slice = String.slice(ci_workflow, start, byte_size(ci_workflow))

          case :binary.match(slice, "\n  ratchet:") do
            {stop, _} -> String.slice(slice, 0, stop)
            :nomatch -> slice
          end

        :nomatch ->
          flunk("expected test: job in ci-verify.yml")
      end

    # Intra-test: step order (real sequential ordering — these are pinned)
    assert test_body =~ release_preview
    assert test_body =~ adoption
    assert test_body =~ runtime_to_handoff

    assert index_of(test_body, release_preview) < index_of(test_body, adoption)
    assert index_of(test_body, adoption) < index_of(test_body, runtime_to_handoff)

    semantic = "mix test.semantic_fast_path --warnings-as-errors"

    assert test_body =~ semantic
    assert index_of(test_body, runtime_to_handoff) < index_of(test_body, semantic)

    # Cross-job parallel-shape assertions (knowledge, connector, gallery are separate jobs)
    # knowledge is a parallel job with needs: build
    assert ci_workflow =~ "mix test.knowledge --warnings-as-errors"

    knowledge_body =
      case :binary.match(ci_workflow, "\n  knowledge:") do
        {start, _} ->
          slice = String.slice(ci_workflow, start, byte_size(ci_workflow))

          case :binary.match(slice, "\n  connector:") do
            {stop, _} -> String.slice(slice, 0, stop)
            :nomatch -> slice
          end

        :nomatch ->
          flunk("expected knowledge: job in ci-verify.yml")
      end

    assert knowledge_body =~ "needs: build"

    # connector is a parallel job with needs: build; gallery is a tail step inside connector
    connector = VerificationLanes.ci_command(:connector)
    gallery = VerificationLanes.ci_command(:support_copilot_gallery)

    connector_body =
      case :binary.match(ci_workflow, "\n  connector:") do
        {start, _} ->
          slice = String.slice(ci_workflow, start, byte_size(ci_workflow))

          case :binary.match(slice, "\n  verify-summary:") do
            {stop, _} -> String.slice(slice, 0, stop)
            :nomatch -> slice
          end

        :nomatch ->
          flunk("expected connector: job in ci-verify.yml")
      end

    assert connector_body =~ "needs: build"
    assert ci_workflow =~ connector
    assert index_of(connector_body, connector) < index_of(connector_body, gallery)

    # full-suite: matrix job carries the WAE step (moved out of test: job)
    assert ci_workflow =~ "mix test --warnings-as-errors --partitions 4"
  end

  defp index_of(content, needle) do
    case :binary.match(content, needle) do
      {index, _length} -> index
      :nomatch -> flunk("Expected to find #{inspect(needle)} in content")
    end
  end
end
