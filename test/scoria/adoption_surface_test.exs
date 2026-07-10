defmodule Scoria.AdoptionSurfaceTest do
  use ExUnit.Case, async: true
  alias Scoria.AdopterDocContract
  alias Scoria.HexConsumerContract
  alias Scoria.VerificationSuites

  for {path, fragments} <- HexConsumerContract.adopter_doc_surfaces() do
    test "adopter doc #{path} stays aligned with HexConsumerContract surface SSOT" do
      content = File.read!(unquote(path))

      for fragment <- unquote(Macro.escape(fragments)) do
        assert content =~ fragment,
               "expected #{unquote(path)} to contain fragment #{inspect(fragment)}"
      end
    end
  end

  @readme "README.md"
  @lane_guide AdopterDocContract.golden_path_guide_path()
  @jtbd_guide AdopterDocContract.jtbd_and_user_flows_guide_path()
  @ownership_guide AdopterDocContract.ownership_boundary_guide_path()
  @phoenix_example "guides/capabilities/default-runtime.md"
  @handoff_guide "guides/capabilities/bounded-handoffs.md"
  @gap_ledger "guides/capabilities/bounded-handoffs.md"
  @semantic_guide "guides/capabilities/semantic-cache.md"
  @operator_guide AdopterDocContract.reviewer_verification_guide_path()
  @comparison_guide AdopterDocContract.comparison_guide_path()
  @maintainer_guide "guides/maintainers.md"
  @glossary AdopterDocContract.glossary_guide_path()
  @scoria_doctest "test/scoria_test.exs"
  @identity_doctest "test/scoria/identity_doctest_test.exs"
  @release_preview_command VerificationSuites.command(:release_preview)
  @default_lane_command VerificationSuites.command(:adoption)
  @runtime_to_handoff_command VerificationSuites.command(:runtime_to_handoff)
  @semantic_fast_path_command VerificationSuites.command(:semantic_fast_path)
  @knowledge_lane_command VerificationSuites.command(:knowledge)
  @connector_lane_command VerificationSuites.command(:connector)
  @default_boundary_sentence VerificationSuites.boundary_sentence(:adoption)
  @closeout_chain VerificationSuites.closeout_chain()
  @prioritized_public_modules [
    Scoria,
    Scoria.Identity,
    Scoria.Runtime,
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
    Scoria.SRE.AuditSink
  ]
  @compatibility_public_modules [
    Scoria.SemanticLane,
    Scoria.VerificationLanes,
    ScoriaWeb.OperatorSurface,
    Scoria.Observe.OperatorBroadcast
  ]
  @internal_modules_refuted [
    Scoria.AdopterDocContract,
    Scoria.HexConsumerContract,
    Scoria.SupportJourney,
    Scoria.UICritique,
    Scoria.WarningInventory,
    Scoria.Workflows.Reconciler,
    ScoriaWeb.ApprovalsLive.Index
  ]
  @public_module_doc_contracts %{
    Scoria => ["guides/getting-started.md", "run_id", "session_id"],
    Scoria.Identity => ["guides/getting-started.md", "host-owned", "session_id"],
    Scoria.Runtime => ["guides/capabilities/default-runtime.md", "durable run", "run_id"],
    Scoria.PromptPolicy => ["guides/ownership-boundary.md", "host", "policy"],
    ScoriaWeb.Router => ["guides/getting-started.md", "scoria_dashboard", "host"],
    ScoriaWeb.DashboardScope => [
      "guides/ownership-boundary.md",
      "host-authenticated",
      "Query params do not choose tenants"
    ],
    ScoriaWeb.ReviewerSurface => ["guides/reviewer-verification.md", "reviewer"],
    Scoria.Observe.ReviewerBroadcast => ["guides/reviewer-verification.md", "reviewer"],
    Scoria.VerificationSuites => ["guides/reviewer-verification.md", "verification suite"],
    Scoria.SemanticCache.Profile => [
      "guides/capabilities/semantic-cache.md",
      "semantic cache"
    ],
    Scoria.SemanticCache => ["guides/capabilities/semantic-cache.md", "semantic cache"],
    Scoria.Knowledge => ["guides/capabilities/default-runtime.md", "optional knowledge base"],
    Scoria.Connectors => ["guides/capabilities/connectors-and-mcp.md", "remote connector"],
    Scoria.Connectors.Auth => ["guides/capabilities/connectors-and-mcp.md", "host"],
    Scoria.MCP.Tool => ["guides/capabilities/connectors-and-mcp.md", "MCP"],
    Scoria.Req.Steps => ["guides/capabilities/default-runtime.md", "Req"],
    Scoria.Eval => ["guides/reviewer-verification.md", "eval"],
    Scoria.PromptRegistry => ["guides/ownership-boundary.md", "prompt"],
    Scoria.SRE => ["guides/ownership-boundary.md", "governance"],
    Scoria.SRE.AlertSink => ["guides/ownership-boundary.md", "alert"],
    Scoria.SRE.AuditSink => ["guides/ownership-boundary.md", "audit"]
  }
  @compatibility_module_sources %{
    Scoria.SemanticLane => "lib/scoria/semantic_lane.ex",
    Scoria.VerificationLanes => "lib/scoria/verification_lanes.ex",
    ScoriaWeb.OperatorSurface => "lib/scoria_web/operator_surface.ex",
    Scoria.Observe.OperatorBroadcast => "lib/scoria/observe/operator_broadcast.ex"
  }
  @backend_guts_opening_refutes [
    "ecto schema",
    "database table",
    "background worker",
    "internal adapter",
    "implementation detail"
  ]

  test "README documents the shipped capability model and canonical verification suites" do
    content = File.read!(@readme)

    assert content =~ "Who This Is For"
    assert content =~ "Choose Your Capability"
    assert content =~ "Capability guide"
    assert content =~ "Glossary"
    assert content =~ "identity -> start -> inspect -> resume"
    assert content =~ "Scoria.start_run"
    assert content =~ "Scoria.start_handoff_run"
    assert content =~ "Scoria.SemanticCache.Profile"
    assert content =~ "semantic_cache: [profile: MyApp.AI.AccountFaqCache]"
    assert content =~ "ScoriaWeb.ReviewerSurface"
    assert content =~ "Scoria.Observe.ReviewerBroadcast"
    assert content =~ "Scoria.VerificationSuites"
    assert content =~ "Scoria.get_run_detail"
    assert content =~ "delegated_handoffs"
    assert content =~ "scoped_context:"
    assert content =~ "Scoria.resume_run"
    assert content =~ "session_id"
    assert content =~ "run_id"
    assert content =~ "/scoria/workflows/:run_id"
    assert content =~ "no host Tailwind, npm, or asset-pipeline work required"
    assert content =~ "mix scoria.install"
    assert content =~ "mix ecto.migrate"
    assert content =~ @default_lane_command
    assert content =~ @semantic_fast_path_command
    assert content =~ @knowledge_lane_command
    assert content =~ @connector_lane_command
    assert content =~ "local proof-only timeout"
    assert content =~ "suite-wide timeout changes"
    assert content =~ "broader repo-health context"
    assert content =~ "Optional knowledge base"
    assert content =~ @lane_guide
    assert content =~ @jtbd_guide
    assert content =~ @ownership_guide
    assert content =~ @phoenix_example
    assert content =~ @handoff_guide
    assert content =~ @semantic_guide
    assert content =~ @operator_guide
    assert content =~ "guides/capabilities/connectors-and-mcp.md"
    assert content =~ "guides/capabilities/support-copilot-gallery.md"
    assert content =~ @glossary
    refute content =~ "mix scoria.test.knowledge"
    refute content =~ "Scoria is shipped through `v1.9 Crucible`"
    assert File.read!(@scoria_doctest) =~ "doctest Scoria"
    assert File.read!(@identity_doctest) =~ "doctest Scoria.Identity"
  end

  test "README shipped truth is capability-based" do
    content = File.read!(@readme)
    lower = String.downcase(content)

    for noun <- AdopterDocContract.shipped_capability_nouns() do
      assert lower =~ String.downcase(noun),
             "expected README to mention capability noun #{inspect(noun)}"
    end

    for marker <- AdopterDocContract.upgrade_safe_install_markers() do
      assert content =~ marker,
             "expected README to include upgrade-safe marker #{inspect(marker)}"
    end

    for refute <-
          AdopterDocContract.milestone_banner_refutes() ++
            AdopterDocContract.readme_maintainer_command_refutes() do
      refute content =~ refute,
             "expected README not to contain #{inspect(refute)}"
    end
  end

  test "README explains embedded Phoenix positioning before capabilities and verification suites" do
    content = File.read!(@readme)

    intro_index = index_of!(content, AdopterDocContract.embedded_phoenix_intro_marker())

    for marker <- AdopterDocContract.readme_first_screen_precedes_markers() do
      assert intro_index < index_of!(content, marker),
             "expected README intro to appear before #{inspect(marker)}"
    end
  end

  test "README documents roles-not-headcount persona and surface boundaries" do
    content = File.read!(@readme)

    assert content =~
             "Scoria is for Phoenix teams where one engineer may need to ship prompts, inspect runs, approve risky tool calls, run evals, and debug incidents without adopting a separate hosted control plane."

    assert content =~ "Core:"
    assert content =~ "Adjacent:"
    assert content =~ "Not Scoria's surface:"
    assert content =~ "reviewer is a role"
  end

  test "README links to the stable external LLM-ops comparison guide" do
    content = File.read!(@readme)

    assert content =~ "Scoria vs external LLM-ops platforms"
    assert content =~ @comparison_guide
  end

  test "comparison guide documents safe current claims, peer posture, ceded strengths, and deferred seeds" do
    assert File.regular?(@comparison_guide),
           "expected #{@comparison_guide} to exist as the stable POS-04 guide"

    content = File.read!(@comparison_guide)

    assert content =~ "# #{AdopterDocContract.comparison_guide_title()}"
    assert content =~ "## What Scoria currently owns"
    assert content =~ "## Where external platforms may be stronger"
    assert content =~ "## Peer deployment posture and sources"
    assert content =~ "## Not current Scoria claims"
    assert content =~ @glossary

    for peer_name <- AdopterDocContract.comparison_required_peer_names() do
      assert content =~ peer_name,
             "expected comparison guide to name #{inspect(peer_name)}"
    end

    for source_link <- AdopterDocContract.comparison_peer_source_links() do
      assert content =~ source_link,
             "expected comparison guide to source-link #{inspect(source_link)}"
    end

    current_section =
      section_between!(
        content,
        "## What Scoria currently owns",
        "## What your Phoenix app still owns"
      )

    for current_claim <- AdopterDocContract.comparison_safe_current_claims() do
      assert current_section =~ current_claim,
             "expected current-Scoria section to contain #{inspect(current_claim)}"
    end

    for forbidden_claim <- AdopterDocContract.comparison_forbidden_current_claims() do
      refute current_section =~ forbidden_claim,
             "expected current-Scoria section not to claim #{inspect(forbidden_claim)}"
    end

    ceded_section =
      section_between!(
        content,
        "## Where external platforms may be stronger",
        "## Peer deployment posture and sources"
      )

    for ceded_strength <- AdopterDocContract.comparison_ceded_strengths() do
      assert ceded_section =~ ceded_strength,
             "expected ceded-strength section to contain #{inspect(ceded_strength)}"
    end

    deferred_section = section_after!(content, "## Not current Scoria claims")

    for deferred_claim <- AdopterDocContract.comparison_deferred_not_current_claims() do
      assert deferred_section =~ deferred_claim,
             "expected deferred section to contain #{inspect(deferred_claim)}"
    end

    refute content =~ "hosted-only"
    refute content =~ "all peers are SaaS"
  end

  test "README does not contain stale 0.1.1 release or GitHub fallback guidance" do
    content = File.read!(@readme)

    for refute <- AdopterDocContract.readme_stale_version_refutes() do
      refute content =~ refute,
             "expected README not to contain stale release guidance #{inspect(refute)}"
    end
  end

  test "glossary documents the final public vocabulary and evidence boundary" do
    content = File.read!(@glossary)

    assert content =~ "## Core terms"
    assert content =~ "## Legacy and industry equivalents"
    assert content =~ "reviewer"
    assert content =~ "trace"
    assert content =~ "verification suite"
    assert content =~ "scoped context"
    assert content =~ "semantic cache"
    assert content =~ "knowledge base"
    assert content =~ "operator"
    assert content =~ "RAG/citation evidence"
    assert content =~ "evidence_refs"
    assert content =~ "surface-sense evidence"
  end

  test "operator guide documents install_contract maintainer proofs" do
    operator_guide = File.read!(@operator_guide)
    readme = File.read!(@readme)

    assert operator_guide =~ "mix scoria.test.install_contract"
    refute readme =~ "mix scoria.test.install_contract"
  end

  test "capability guide documents the adoption order and optional boundaries" do
    content = File.read!(@lane_guide)

    assert content =~ "Default runtime capability"
    assert content =~ "Bounded handoff capability"
    assert content =~ "Semantic cache capability"
    assert content =~ "Optional knowledge base capability"
    assert content =~ "Remote connector capability"
    assert content =~ "identity -> start -> inspect -> resume"
    assert content =~ "Scoria.start_handoff_run/3"
    assert content =~ "use Scoria.SemanticCache.Profile"
    assert content =~ "semantic_cache: [profile: MyApp.AI.AccountFaqCache]"
    assert content =~ @default_lane_command
    assert content =~ @semantic_fast_path_command
    assert content =~ @knowledge_lane_command
    assert content =~ @connector_lane_command
    assert content =~ "connector_adoption.md"
    assert content =~ "embedded-boundary framing"
    refute content =~ "mix scoria.test.knowledge"
    assert content =~ "This capability is explicitly optional."

    assert content =~
             "Start narrow. Expand only when the current capability already feels boring."
  end

  test "phase 54 docs keep default-first capability wording with canonical runtime-to-handoff proof guidance" do
    readme = File.read!(@readme)
    lane_guide = File.read!(@lane_guide)
    operator_guide = File.read!(@operator_guide)
    phoenix_example = File.read!(@phoenix_example)
    handoff_guide = File.read!(@handoff_guide)

    for content <- [readme, lane_guide, operator_guide] do
      assert content =~ "Start with the default runtime capability"
      assert content =~ @runtime_to_handoff_command
      assert content =~ @default_lane_command
      assert content =~ @default_boundary_sentence
    end

    assert phoenix_example =~ "Scoria.get_run_detail/1"
    assert phoenix_example =~ "delegated = detail.delegated_handoffs"
    assert phoenix_example =~ @runtime_to_handoff_command
    assert phoenix_example =~ @default_lane_command

    assert handoff_guide =~ @runtime_to_handoff_command
    assert handoff_guide =~ "Scoria.get_run_detail/1"
    assert handoff_guide =~ "delegated_handoffs"

    for content <- [readme, lane_guide, operator_guide, phoenix_example, handoff_guide] do
      refute content =~ "mix test.handoff"
      refute content =~ "mix scoria.test.handoff"
      refute content =~ "workflow_steps"
      refute content =~ "workflow_handoffs"
      refute content =~ "Repo.all"
      refute content =~ "Scoria.Workflows.create_run"
    end
  end

  test "bounded handoff guide documents the narrow public delegation capability" do
    content = File.read!(@handoff_guide)

    assert content =~ "identity -> start -> inspect -> resume"
    assert content =~ "Scoria.start_handoff_run"
    assert content =~ "Scoria.get_run_detail"
    assert content =~ "delegated_handoffs"
    assert content =~ "root_role_id"
    assert content =~ "delegated_kind"
    assert content =~ "handoff_input"
    assert content =~ "scoped_context"
    assert content =~ "scoped_context: %{}"
    assert content =~ "queued child step"
    assert content =~ "same durable run"
    assert content =~ "Delegated Trace"
    assert content =~ "No remaining adopter-facing gap"
    assert content =~ "deferred follow-up"
    assert content =~ "Host and Scoria ownership boundary"

    assert content =~
             "The host app owns identity, escalation policy, prompt or draft selection, and scoped-context selection."

    assert content =~
             "Scoria owns durable run creation, scoped-context validation, queued delegated child creation, and curated readback through `Scoria.get_run_detail/1`."

    assert content =~ "{:error, :unsafe_projected_context}"
    assert content =~ "before creating a durable delegated run"
    assert content =~ @default_lane_command
    assert content =~ "one canonical verification suite"
    assert content =~ "Broad runtime-state keys are rejected explicitly"
    assert content =~ "transcript"
    assert content =~ "provider_session"
    assert content =~ "session"
    assert content =~ "secrets"
    assert content =~ "socket_state"
    assert content =~ "/scoria/workflows/:run_id"
    refute content =~ "implicit payload projection"
    refute content =~ "Scoria.Workflows.create_run"
    refute content =~ "Repo.all"
    refute content =~ "workflow_steps"
    refute content =~ "workflow_handoffs"
    refute Regex.match?(~r/\bcopy hidden transcript into\b/, content)
    refute content =~ "provider_session token"
  end

  test "semantic cache guide documents the conservative reuse contract" do
    content = File.read!(@semantic_guide)

    assert content =~ "Use it only after the default runtime capability already works"
    assert content =~ "use Scoria.SemanticCache.Profile"
    assert content =~ "cache_key: \"account_faq\""
    assert content =~ "default_scope: :tenant_shared"
    assert content =~ "default_scope: :actor_scoped"
    assert content =~ "safe_read_only: true"
    assert content =~ "semantic_cache: [profile: MyApp.AI.AccountFaqCache]"
    assert content =~ "tenant partitioning"
    assert content =~ "prompt compatibility"
    assert content =~ "policy compatibility"
    assert content =~ "source compatibility"
    assert content =~ "bypass"
    assert content =~ "miss"
    assert content =~ "reject"
    assert content =~ "hit"
    assert content =~ "active"
    assert content =~ "stale"
    assert content =~ "invalidated"
    assert content =~ "writeback_rejected"
    assert content =~ @semantic_fast_path_command
    assert content =~ @knowledge_lane_command
    assert content =~ "/scoria/workflows/:run_id"
    refute content =~ "mix scoria.test.knowledge"
  end

  test "Phoenix runtime example documents identity, readback, and approval resume" do
    content = File.read!(@phoenix_example)

    assert content =~ "identity -> start -> inspect -> resume"
    assert content =~ "Scoria.identity"
    assert content =~ "Scoria.start_run"
    assert content =~ "Scoria.get_run"
    assert content =~ "Scoria.get_run_detail"
    assert content =~ "delegated_handoffs"
    assert content =~ "Scoria.resume_run"
    assert content =~ "list_runs_for_session"
    assert content =~ "session_id"
    assert content =~ "run_id"
    assert content =~ "/scoria/workflows/:run_id"
    assert content =~ "approval"
  end

  test "phase gap ledger records the bounded handoff closeout decision explicitly" do
    content = File.read!(@gap_ledger)
    lower = String.downcase(content)

    assert lower =~ "no remaining adopter-facing gap"
    assert lower =~ "closeout"
    assert lower =~ "deferred follow-up"
    refute content =~ "TBD"
    refute lower =~ "maybe later"
  end

  test "operator verification guide documents the four-tier support hierarchy" do
    content = File.read!(@operator_guide)

    assert content =~ @release_preview_command
    assert content =~ "mix scoria.install"
    assert content =~ "mix ecto.migrate"
    assert content =~ "mix test"
    assert content =~ @default_lane_command
    assert content =~ @semantic_fast_path_command
    assert content =~ @knowledge_lane_command
    assert content =~ "SCORIA_DB_PORT=55432"
    assert content =~ "canonical default runtime verification suite"
    assert content =~ "fresh-host install/migrate/route/runtime smoke"
    assert content =~ "local proof-only timeout"
    assert content =~ "suite-wide timeout change"
    assert content =~ "canonical semantic cache troubleshooting verification suite"
    assert content =~ "broader repo-health context"
    assert content =~ "Scoria.start_run"
    assert content =~ "Scoria.get_run"
    assert content =~ "list_runs_for_session"
    assert content =~ "/scoria/workflows/:run_id"
    assert content =~ "Optional knowledge base"
    assert content =~ "repository closeout, the canonical proof chain is exactly"
    assert content =~ @closeout_chain
    assert content =~ @runtime_to_handoff_command

    assert content =~
             "CI should run this verification suite in `MIX_ENV=dev` because ExDoc stays a dev-only tool"

    assert content =~ @default_boundary_sentence

    assert content =~ "bypass"
    assert content =~ "miss"
    assert content =~ "reject"
    assert content =~ "hit"
    assert content =~ "active"
    assert content =~ "stale"
    assert content =~ "invalidated"
    assert content =~ "writeback_rejected"
    refute content =~ "MIX_ENV=test mix scoria.release_preview"

    refute Regex.match?(
             ~r/mix scoria\.release_preview\s+mix test\.semantic_fast_path/,
             content
           )

    refute Regex.match?(
             ~r/mix scoria\.release_preview\s+mix test\.knowledge/,
             content
           )

    refute content =~ "mix test.handoff"
    refute content =~ "mix scoria.test.handoff"

    refute Regex.match?(
             ~r/mix scoria\.release_preview\s+mix test\s*\n(?!\.adoption)/,
             content
           )

    refute Regex.match?(~r/```bash\s+mix test\.adoption --trace\s+```/, content)
    refute content =~ "mix scoria.test.knowledge"
    refute content =~ "pgvector, retrieval, or semantic caching before Scoria is usable"
  end

  test "operator verification guide documents upgrade-safe installer modes" do
    operator_guide = File.read!(@operator_guide)
    lane_guide = File.read!(@lane_guide)

    assert operator_guide =~ "Installer verification modes (upgrade-safe)"
    assert operator_guide =~ "mix scoria.install --dry-run"
    assert operator_guide =~ "mix scoria.install --check"
    assert operator_guide =~ "SCORIA_CHECK_RESULT"
    assert operator_guide =~ "never writes"
    assert operator_guide =~ "Check vs apply drift detection"
    assert operator_guide =~ "Live host surfaces only"

    assert lane_guide =~ @operator_guide
    assert lane_guide =~ "Check vs apply"
    assert lane_guide =~ "--check"
  end

  test "mix scoria.install task documents three modes and upgrade-safe verification" do
    assert {:docs_v1, _, :elixir, _, moduledoc, _, _} = Code.fetch_docs(Mix.Tasks.Scoria.Install)

    assert moduledoc not in [nil, :none]

    moduledoc_text =
      case moduledoc do
        %{"en" => text} -> text
        text when is_binary(text) -> text
      end

    assert moduledoc_text =~ "three verification modes"
    assert moduledoc_text =~ "--dry-run"
    assert moduledoc_text =~ "--check"
    assert moduledoc_text =~ "never writes host files"
    assert moduledoc_text =~ "SCORIA_CHECK_RESULT"
    assert moduledoc_text =~ "mix scoria.install --check"
    assert moduledoc_text =~ "docs/operator_verification.md"
  end

  test "dashboard auth seam docs teach host-owned scope without Scoria-owned authorization" do
    lane_guide = File.read!(@lane_guide)
    operator_guide = File.read!(@operator_guide)
    maintainer_guide = File.read!(@maintainer_guide)

    for content <- [lane_guide, operator_guide] do
      assert content =~
               "The host app authenticates the reviewer and asserts dashboard tenant scope."

      assert content =~ "scoria_dashboard \"/scoria\""
      assert content =~ "on_mount:"
      assert content =~ "scope_resolver:"
      assert content =~ "Query params do not choose tenants for the dashboard."

      assert content =~
               "Authorization remains delegated to the host; Scoria does not introduce a role model."

      assert content =~ "This Scoria dashboard is not available for this session."
    end

    assert lane_guide =~ "bare `scoria_dashboard \"/scoria\"` form still compiles"
    assert lane_guide =~ "session-backed default resolver"

    assert operator_guide =~ "mount the dashboard with host-authenticated scope"
    assert operator_guide =~ "tenant query hint does not change the asserted dashboard scope"

    assert maintainer_guide =~ "Phase 44 dashboard scope proof"

    assert maintainer_guide =~
             "Review Queue, Eval Workbench, Prompt Registry, and Workflow Index now mount through DashboardScope"

    refute maintainer_guide =~ "do not support `?tenant=` query-param switching"
    refute maintainer_guide =~ "they list all records globally"
  end

  test "D-17 public modules expose compiled non-empty moduledocs" do
    for mod <- @prioritized_public_modules do
      assert module_doc_text(mod) != "", "#{inspect(mod)} is missing moduledoc"
    end
  end

  test "D-17 public moduledocs link to canonical guides or final vocabulary" do
    for {mod, required_fragments} <- @public_module_doc_contracts do
      text = module_doc_text(mod)

      for fragment <- required_fragments do
        assert text =~ fragment,
               "expected #{inspect(mod)} moduledoc to contain #{inspect(fragment)}"
      end
    end
  end

  test "public entrypoint moduledocs do not lead with backend guts" do
    for mod <- @prioritized_public_modules do
      opening =
        mod
        |> module_doc_text()
        |> String.trim()
        |> String.split("\n\n", parts: 2)
        |> hd()
        |> String.downcase()

      for refute <- @backend_guts_opening_refutes do
        refute opening =~ refute,
               "expected #{inspect(mod)} opening paragraph not to lead with #{inspect(refute)}"
      end
    end
  end

  test "D-14 true internals are absent from the public moduledoc contract set" do
    public_set = @prioritized_public_modules ++ @compatibility_public_modules

    for mod <- @internal_modules_refuted do
      refute mod in public_set,
             "expected #{inspect(mod)} to stay out of the public moduledoc contract set"
    end
  end

  test "D-15 compatibility aliases are documented separately without runtime deprecation warnings" do
    for mod <- @compatibility_public_modules do
      text = module_doc_text(mod)

      assert text =~ "Legacy 0.1.x compatibility wrapper",
             "expected #{inspect(mod)} to be documented as a compatibility wrapper"

      source = File.read!(Map.fetch!(@compatibility_module_sources, mod))
      refute source =~ "@deprecated", "expected #{inspect(mod)} not to emit runtime deprecations"
    end
  end

  test "D-19 doctest-only contracts stay limited to pure examples" do
    doctest_sources =
      [@scoria_doctest, @identity_doctest]
      |> Enum.map(&File.read!/1)
      |> Enum.join("\n")

    for mod <- [
          Scoria.Runtime,
          ScoriaWeb.Router,
          ScoriaWeb.DashboardScope,
          ScoriaWeb.ReviewerSurface,
          Scoria.Eval,
          Scoria.Knowledge
        ] do
      refute doctest_sources =~ "doctest #{inspect(mod)}"
    end
  end

  defp module_doc_text(mod) do
    assert {:docs_v1, _, :elixir, _, moduledoc, _, _} = Code.fetch_docs(mod)

    assert moduledoc not in [nil, :none], "#{inspect(mod)} is missing moduledoc"

    case moduledoc do
      %{"en" => text} -> String.trim(text)
      text when is_binary(text) -> String.trim(text)
    end
  end

  defp index_of!(content, marker) do
    case :binary.match(content, marker) do
      {index, _length} -> index
      :nomatch -> flunk("expected content to contain #{inspect(marker)}")
    end
  end

  defp section_between!(content, start_marker, end_marker) do
    start_index = index_of!(content, start_marker)
    end_index = index_of!(content, end_marker)

    assert start_index < end_index,
           "expected #{inspect(start_marker)} to appear before #{inspect(end_marker)}"

    binary_part(content, start_index, end_index - start_index)
  end

  defp section_after!(content, start_marker) do
    start_index = index_of!(content, start_marker)
    binary_part(content, start_index, byte_size(content) - start_index)
  end
end
