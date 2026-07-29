defmodule Mix.Tasks.Scoria.ReleasePreviewTest do
  use ExUnit.Case, async: true

  alias Scoria.AiDocContract

  @packaged_ai_docs AiDocContract.packaged_ai_doc_paths()
  @repo_only_ai_docs AiDocContract.repo_only_ai_doc_paths()
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
    "guides/capabilities/llm-and-tool-adapters.md",
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
                             @packaged_ai_docs,
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
    assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :generated_docs_output_dir, 0)
    assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :docs_task_args, 0)
    assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :clean_generated_docs_output!, 1)
    assert Mix.Task.get("scoria.release_preview")

    required_paths = Mix.Tasks.Scoria.ReleasePreview.required_package_paths()
    assert required_paths == @expected_required_paths

    assert Mix.Tasks.Scoria.ReleasePreview.release_preview_output_dir() ==
             "tmp/scoria-release-preview"

    assert Mix.Tasks.Scoria.ReleasePreview.generated_docs_output_dir() == "doc"

    assert "CHANGELOG.md" in required_paths
    assert "lib/scoria.ex" in required_paths

    assert "priv/repo/migrations/20260511000100_create_workflow_tables.exs" in required_paths

    assert "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs" in required_paths

    for path <- @packaged_ai_docs ++ @canonical_guides ++ @compatibility_stub_paths ++ @docs_brand_assets do
      assert path in @expected_required_paths
    end

    for path <- @repo_only_ai_docs ++ @dev_only_docs do
      refute path in required_paths
    end

    refute "test/scoria/adoption_surface_test.exs" in required_paths
  end

  test "release preview runs ExDoc with warnings as errors" do
    assert Mix.Tasks.Scoria.ReleasePreview.docs_task_args() == ["--warnings-as-errors"]

    source = File.read!("lib/mix/tasks/scoria.release_preview.ex")
    assert source =~ ~s|Mix.Task.run("docs", docs_task_args())|
    refute source =~ ~s|Mix.Task.run("docs")|
  end

  test "maintainer docs document raw docs WAE as diagnostic only" do
    maintainer_docs = File.read!("guides/maintainers.md")
    troubleshooting_docs = File.read!("guides/troubleshooting.md")
    reviewer_docs = File.read!("guides/reviewer-verification.md")
    ci_verify = File.read!(".github/workflows/ci-verify.yml")

    assert maintainer_docs =~ "MIX_ENV=dev mix docs --warnings-as-errors"
    assert troubleshooting_docs =~ "MIX_ENV=dev mix docs --warnings-as-errors"
    assert reviewer_docs =~ "warnings-as-errors"
    assert reviewer_docs =~ "MIX_ENV=dev mix docs --warnings-as-errors"

    assert ci_verify =~ "MIX_ENV=dev mix scoria.release_preview"
    refute ci_verify =~ "mix docs --warnings-as-errors"
  end

  test "release preview intentionally requires shared AI docs but excludes the Gemini bridge" do
    required_paths = Mix.Tasks.Scoria.ReleasePreview.required_package_paths()

    assert AiDocContract.root_llms_path() in required_paths
    assert AiDocContract.root_agents_path() in required_paths
    refute AiDocContract.gemini_bridge_path() in required_paths
  end

  test "generated docs cleanup removes stale ExDoc fingerprint assets before rebuilding" do
    output_dir =
      Path.join([
        System.tmp_dir!(),
        "scoria-release-preview-doc-cleanup-#{System.unique_integer([:positive])}"
      ])

    stale_search_index = Path.join([output_dir, "dist", "search_data-STALE.js"])
    File.mkdir_p!(Path.dirname(stale_search_index))
    File.write!(stale_search_index, "docs/semantic_fast_path.md")

    try do
      assert File.regular?(stale_search_index)

      assert :ok = Mix.Tasks.Scoria.ReleasePreview.clean_generated_docs_output!(output_dir)

      refute File.exists?(output_dir)
    after
      File.rm_rf!(output_dir)
    end
  end
end
