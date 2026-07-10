defmodule Mix.Tasks.Scoria.ReleasePreviewTest do
  use ExUnit.Case, async: true

  test "the release preview lane is discoverable and carries the required inventory contract" do
    Mix.Task.load_all()

    expected_required_paths = [
      "README.md",
      "LICENSE",
      "mix.exs",
      "CHANGELOG.md",
      "lib/scoria.ex",
      "priv/repo/migrations/20260511000100_create_workflow_tables.exs",
      "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs",
      "docs/glossary.md",
      "docs/adoption_lanes.md",
      "docs/scoria_vs_external_llm_ops.md",
      "docs/phoenix_runtime_example.md",
      "docs/bounded_handoffs.md",
      "docs/semantic_fast_path.md",
      "docs/operator_verification.md",
      "docs/connector_adoption.md",
      "docs/support_copilot_gallery.md",
      "docs/MAINTAINERS.md"
    ]

    assert Code.ensure_loaded?(Mix.Tasks.Scoria.ReleasePreview)
    assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :run, 1)
    assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :required_package_paths, 0)
    assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :release_preview_output_dir, 0)
    assert Mix.Task.get("scoria.release_preview")
    assert Mix.Tasks.Scoria.ReleasePreview.required_package_paths() == expected_required_paths

    assert Mix.Tasks.Scoria.ReleasePreview.release_preview_output_dir() ==
             "tmp/scoria-release-preview"

    assert "CHANGELOG.md" in expected_required_paths
    assert "lib/scoria.ex" in expected_required_paths

    assert "priv/repo/migrations/20260511000100_create_workflow_tables.exs" in expected_required_paths

    assert "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs" in expected_required_paths

    assert "docs/glossary.md" in expected_required_paths
    assert "docs/adoption_lanes.md" in expected_required_paths
    assert "docs/scoria_vs_external_llm_ops.md" in expected_required_paths
    assert "docs/operator_verification.md" in expected_required_paths
    assert "docs/connector_adoption.md" in expected_required_paths
    assert "docs/support_copilot_gallery.md" in expected_required_paths
    assert "docs/MAINTAINERS.md" in expected_required_paths
    refute "test/scoria/adoption_surface_test.exs" in expected_required_paths
  end
end
