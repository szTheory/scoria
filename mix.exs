defmodule Scoria.MixProject do
  use Mix.Project

  @version "0.1.2"
  @source_url "https://github.com/szTheory/scoria"
  @hexdocs_url "https://scoria.hexdocs.pm"
  @release_docs_url "#{@hexdocs_url}/#{@version}"

  def project do
    [
      app: :scoria,
      version: @version,
      description: description(),
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      package: package(),
      source_url: @source_url,
      homepage_url: @hexdocs_url,
      test_load_filters: [
        fn path ->
          String.ends_with?(path, "_test.exs") and not excluded_test_path?(path)
        end
      ],
      test_ignore_filters: [&excluded_test_path?/1]
    ]
  end

  def cli do
    [
      preferred_envs: [
        "scoria.test.adoption": :test,
        "test.adoption": :test,
        "scoria.test.runtime_to_handoff": :test,
        "test.runtime_to_handoff": :test,
        "scoria.test.semantic_fast_path": :test,
        "test.semantic_fast_path": :test,
        "scoria.test.knowledge": :test,
        "test.knowledge": :test,
        "scoria.warning_inventory": :test,
        "scoria.warning_inventory.check_baseline": :test,
        "scoria.test.ci_trust": :test,
        "test.ci_trust": :test,
        "scoria.test.install_contract": :test,
        "test.install_contract": :test,
        "scoria.test.support_copilot": :test,
        "test.support_copilot": :test,
        "scoria.test.connector": :test,
        "test.connector": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  # `dev/` holds the dev-only host harness (DevEndpoint/DevRouter) that serves
  # the dashboard via `mix phx.server`. It is excluded from the Hex package
  # (see `package/0` files) so adopters never receive it.
  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(_), do: ["lib"]

  # Host-app overlay templates and hex unpack fixtures must not compile in the root suite.
  defp excluded_test_path?(path) do
    String.starts_with?(path, "test/fixtures/") or
      String.contains?(path, "host_app_proof/overlay/test/")
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Scoria.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tribunal, "~> 1.3"},
      {:cloak, "~> 1.1"},
      {:cloak_ecto, "~> 1.3"},
      {:ecto_sql, "~> 3.10"},
      {:oban, "~> 2.19"},
      {:postgrex, ">= 0.0.0"},
      {:pgvector, "~> 0.3.0"},
      {:hammer, "~> 7.3"},
      {:fuse, "~> 2.5"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.14"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_ecto, "~> 4.4"},
      {:req, "~> 0.5"},
      {:req_llm, "~> 1.13"},
      {:tiktoken, "~> 0.4.2"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      # Dev-only web server + live reload for the dev harness endpoint (dev/).
      # Scoria is a library — adopters bring their own server — so these are
      # never shipped to Hex (only: :dev). Bandit backs the DevEndpoint.
      {:bandit, "~> 1.5", only: :dev},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  defp aliases do
    [
      "assets.build": ["scoria.assets.build"],
      "assets.deploy": ["scoria.assets.build"],
      # Dev harness convenience: create+migrate (core+knowledge order)+seed the
      # dev DB in one step. Used by the Docker entrypoint and fresh local setup.
      "dev.setup": ["scoria.dev.db", "run priv/repo/dev_seed.exs"],
      ci: ["scoria.ci"]
    ]
  end

  defp description do
    "Phoenix-native AI ops: LLM traces, evals, prompt versions, replay, tool governance, and MCP workflows. Ecto-backed, LiveView-included."
  end

  def docs_source_ref do
    release_ref = "v#{@version}"

    case System.get_env("SCORIA_DOCS_SOURCE_REF") do
      ref when is_binary(ref) and ref != "" ->
        ref

      _ ->
        if git_exact_ref?(release_ref), do: release_ref, else: "main"
    end
  end

  defp docs do
    [
      main: "getting-started",
      source_url: @source_url,
      source_ref: docs_source_ref(),
      homepage_url: @hexdocs_url,
      extra_section: "Guides",
      formatters: ["html", "markdown"],
      logo: "brandbook/logo-mark.svg",
      favicon: "brandbook/favicon.svg",
      extras: docs_extras(),
      groups_for_extras: docs_extra_groups(),
      groups_for_modules: docs_module_groups(),
      filter_modules: &docs_public_module?/2,
      skip_code_autolink_to: &docs_skip_code_autolink_to?/1,
      redirects: docs_redirects()
    ]
  end

  defp docs_extras do
    [
      "README.md",
      "CHANGELOG.md",
      "LICENSE",
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
  end

  defp docs_extra_groups do
    [
      "Start Here": [
        "README.md",
        "guides/getting-started.md",
        "guides/golden-path.md",
        "guides/jtbd-and-user-flows.md",
        "guides/ownership-boundary.md",
        "guides/cheatsheet.cheatmd"
      ],
      Capabilities: [
        "guides/capabilities/default-runtime.md",
        "guides/capabilities/bounded-handoffs.md",
        "guides/capabilities/semantic-cache.md",
        "guides/capabilities/connectors-and-mcp.md",
        "guides/capabilities/support-copilot-gallery.md"
      ],
      "Operate & Verify": [
        "guides/reviewer-verification.md",
        "guides/troubleshooting.md"
      ],
      "Compare & Decide": [
        "guides/scoria-vs-external-llm-ops.md"
      ],
      Reference: [
        "guides/reference/glossary.md"
      ],
      Maintainers: [
        "guides/maintainers.md",
        "CHANGELOG.md",
        "LICENSE"
      ]
    ]
  end

  defp docs_module_groups do
    [
      "Start Here": [
        Scoria,
        Scoria.Identity
      ],
      "Install & Verify": [
        ScoriaWeb.Router,
        Scoria.VerificationSuites
      ],
      "Runtime & Workflows": [
        Scoria.Runtime,
        Scoria.Runtime.RunSummary,
        Scoria.Runtime.RunDetail,
        Scoria.PromptPolicy
      ],
      "Reviewer Dashboard": [
        ScoriaWeb.DashboardScope,
        ScoriaWeb.ReviewerSurface,
        Scoria.Observe.ReviewerBroadcast
      ],
      "Eval & Release Proof": [
        Scoria.Eval,
        Scoria.PromptRegistry
      ],
      "Knowledge & Semantic Cache": [
        Scoria.Knowledge,
        Scoria.SemanticCache,
        Scoria.SemanticCache.Profile
      ],
      "Connectors & MCP": [
        Scoria.Connectors,
        Scoria.Connectors.Auth,
        Scoria.MCP.Tool,
        Scoria.Req.Steps
      ],
      "Governance, Observe & SRE": [
        Scoria.SRE,
        Scoria.SRE.AlertSink,
        Scoria.SRE.AuditSink
      ],
      "Compatibility Aliases": [
        Scoria.SemanticLane,
        Scoria.VerificationLanes,
        ScoriaWeb.OperatorSurface,
        Scoria.Observe.OperatorBroadcast
      ]
    ]
  end

  defp docs_redirects do
    %{
      "adoption_lanes" => "jtbd-and-user-flows",
      "phoenix_runtime_example" => "golden-path",
      "bounded_handoffs" => "bounded-handoffs",
      "semantic_fast_path" => "semantic-cache",
      "operator_verification" => "reviewer-verification",
      "connector_adoption" => "connectors-and-mcp",
      "support_copilot_gallery" => "support-copilot-gallery",
      "scoria_vs_external_llm_ops" => "scoria-vs-external-llm-ops",
      "MAINTAINERS" => "maintainers"
    }
  end

  defp docs_public_modules do
    MapSet.new([
      Scoria,
      Scoria.Identity,
      Scoria.Runtime,
      Scoria.Runtime.RunSummary,
      Scoria.Runtime.RunDetail,
      Scoria.PromptPolicy,
      ScoriaWeb.Router,
      ScoriaWeb.DashboardScope,
      ScoriaWeb.ReviewerSurface,
      Scoria.Observe.ReviewerBroadcast,
      Scoria.VerificationSuites,
      Scoria.SemanticCache.Profile,
      Scoria.SemanticCache,
      Scoria.Knowledge,
      Scoria.Connectors,
      Scoria.Connectors.Auth,
      Scoria.MCP.Tool,
      Scoria.Req.Steps,
      Scoria.Eval,
      Scoria.PromptRegistry,
      Scoria.SRE,
      Scoria.SRE.AlertSink,
      Scoria.SRE.AuditSink,
      Scoria.SemanticLane,
      Scoria.VerificationLanes,
      ScoriaWeb.OperatorSurface,
      Scoria.Observe.OperatorBroadcast
    ])
  end

  defp docs_public_module?(module, _metadata), do: MapSet.member?(docs_public_modules(), module)

  defp docs_skip_code_autolink_to?(term) when is_binary(term) do
    String.starts_with?(term, [
      "mix ",
      "MIX_ENV=",
      "SCORIA_DB_PORT=",
      "SCORIA_DB_PASSWORD=",
      "SCORIA_CHECK_RESULT"
    ]) or term in docs_code_autolink_skips()
  end

  defp docs_skip_code_autolink_to?(_term), do: false

  defp docs_code_autolink_skips do
    [
      "Scoria.AdopterDocContract.comparison_guide_path/0",
      "Scoria.HexConsumerContract",
      "Scoria.SupportJourney",
      "Scoria.VerificationSuites.closeout_order/0",
      "ScoriaWeb.DashboardScope.Resolver",
      "ScoriaWeb.UI"
    ]
  end

  defp package do
    [
      name: "scoria",
      files: [
        "lib",
        # Explicit priv/ subdirectory inclusions — the bare priv glob was replaced
        # to prevent dev-only harness tooling from shipping to adopters (supply-chain
        # control, T-11-06 / D-01 / D-02).
        "priv/fixtures",
        "priv/host_app_proof",
        # priv/repo: migrations ship to adopters; dev_seed.exs is excluded by
        # listing only the migration subdirs (not the whole dir).
        # Open question #2 resolution: dev_seed.exs is a maintainer dev tool, not
        # a runtime artifact — adopters do not need it in the package.
        "priv/repo/migrations",
        "priv/repo/knowledge_migrations",
        "priv/static",
        # priv/dev intentionally excluded — shots.mjs (screenshots) and e2e/ (the
        # Playwright assertion lane) are dev-only harness tooling, not for adopters
        # (D-01: zero Hex footprint for browser automation tooling). Do NOT add a
        # priv/dev entry here — it would ship Playwright specs + node tooling.
        # priv/shots intentionally excluded — screenshot captures are transient
        # dev-only artifacts; only gap_register.md is committed (per .gitignore rules).
        "mix.exs",
        ".formatter.exs",
        "CHANGELOG.md",
        "README.md",
        "LICENSE",
        "llms.txt",
        "AGENTS.md",
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
        "guides/maintainers.md",
        "docs/glossary.md",
        "docs/adoption_lanes.md",
        "docs/scoria_vs_external_llm_ops.md",
        "docs/phoenix_runtime_example.md",
        "docs/bounded_handoffs.md",
        "docs/semantic_fast_path.md",
        "docs/operator_verification.md",
        "docs/connector_adoption.md",
        "docs/support_copilot_gallery.md",
        "docs/MAINTAINERS.md",
        "brandbook/logo-primary.svg",
        "brandbook/logo-primary-light.svg",
        "brandbook/logo-mark.svg",
        "brandbook/favicon.svg"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Documentation" => @hexdocs_url,
        "Release Docs" => @release_docs_url,
        "Changelog" => "https://hex.pm/packages/scoria/changelog"
      },
      tags: ~w(elixir phoenix ai llm mcp observability liveview workflows approvals)
    ]
  end

  defp git_exact_ref?(ref) do
    case System.cmd("git", ["tag", "--points-at", "HEAD"], stderr_to_stdout: true) do
      {tags, 0} -> ref in String.split(tags)
      _ -> false
    end
  rescue
    _ -> false
  end
end
