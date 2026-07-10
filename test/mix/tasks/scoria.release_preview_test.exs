defmodule Mix.Tasks.Scoria.ReleasePreviewTest do
  use ExUnit.Case, async: true

  @canonical_guides [
    "guides/getting-started.md",
    "guides/golden-path.md",
    "guides/jtbd-and-user-flows.md",
    "guides/ownership-boundary.md",
    "guides/capabilities/default-runtime.md",
    "guides/capabilities/bounded-handoffs.md",
    "guides/capabilities/semantic-cache.md",
    "guides/capabilities/connectors-and-mcp.md",
    "guides/capabilities/support-copilot-gallery.md",
    "guides/reviewer-verification.md",
    "guides/troubleshooting.md",
    "guides/scoria-vs-external-llm-ops.md",
    "guides/cheatsheet.cheatmd",
    "guides/reference/glossary.md",
    "guides/maintainers.md"
  ]
  @compatibility_stub_paths [
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
  @docs_brand_assets [
    "brandbook/logo-primary.svg",
    "brandbook/logo-primary-light.svg",
    "brandbook/logo-mark.svg",
    "brandbook/favicon.svg"
  ]
  @dev_only_docs [
    "docs/design_system.md",
    "docs/docker_dev_dx.md",
    "docs/uat_automation.md"
  ]
  @base_required_paths [
    "README.md",
    "LICENSE",
    "mix.exs",
    "CHANGELOG.md",
    "lib/scoria.ex",
    "priv/repo/migrations/20260511000100_create_workflow_tables.exs",
    "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs"
  ]
  @expected_required_paths Enum.concat([
                             @base_required_paths,
                             @canonical_guides,
                             @compatibility_stub_paths,
                             @docs_brand_assets
                           ])

  test "the release preview lane is discoverable and carries the required inventory contract" do
    Mix.Task.load_all()

    assert Code.ensure_loaded?(Mix.Tasks.Scoria.ReleasePreview)
    assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :run, 1)
    assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :required_package_paths, 0)
    assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :release_preview_output_dir, 0)
    assert Mix.Task.get("scoria.release_preview")

    required_paths = Mix.Tasks.Scoria.ReleasePreview.required_package_paths()
    assert required_paths == @expected_required_paths

    assert Mix.Tasks.Scoria.ReleasePreview.release_preview_output_dir() ==
             "tmp/scoria-release-preview"

    assert "CHANGELOG.md" in required_paths
    assert "lib/scoria.ex" in required_paths

    assert "priv/repo/migrations/20260511000100_create_workflow_tables.exs" in required_paths

    assert "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs" in required_paths

    for path <- @canonical_guides ++ @compatibility_stub_paths ++ @docs_brand_assets do
      assert path in @expected_required_paths
    end

    for path <- @dev_only_docs do
      refute path in required_paths
    end

    refute "test/scoria/adoption_surface_test.exs" in required_paths
  end
end
