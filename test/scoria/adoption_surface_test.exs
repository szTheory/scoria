defmodule Scoria.AdoptionSurfaceTest do
  use ExUnit.Case, async: true

  @readme "README.md"
  @lane_guide "docs/adoption_lanes.md"
  @phoenix_example "docs/phoenix_runtime_example.md"
  @handoff_guide "docs/bounded_handoffs.md"
  @gap_ledger "docs/bounded_handoffs.md"
  @semantic_guide "docs/semantic_fast_path.md"
  @operator_guide "docs/operator_verification.md"
  @scoria_doctest "test/scoria_test.exs"
  @identity_doctest "test/scoria/identity_doctest_test.exs"

  test "README documents the shipped lane model and canonical lane hierarchy" do
    content = File.read!(@readme)

    assert content =~ "Scoria is shipped through `v2.1 Tenant-scoped semantic fast path`"
    assert content =~ "Who This Is For"
    assert content =~ "Choose Your Lane"
    assert content =~ "Lane selection guide"
    assert content =~ "identity -> start -> inspect -> resume"
    assert content =~ "Scoria.start_run"
    assert content =~ "Scoria.start_handoff_run"
    assert content =~ "Scoria.SemanticLane"
    assert content =~ "semantic_cache: [lane: MyApp.AI.AccountFaqLane]"
    assert content =~ "Scoria.get_run_detail"
    assert content =~ "delegated_handoffs"
    assert content =~ "Scoria.resume_run"
    assert content =~ "session_id"
    assert content =~ "run_id"
    assert content =~ "/scoria/workflows/:run_id"
    assert content =~ "Tailwind is optional for the install task."
    assert content =~ "mix scoria.install"
    assert content =~ "mix ecto.migrate"
    assert content =~ "mix test.adoption"
    assert content =~ "SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path"
    assert content =~ "mix test.knowledge"
    assert content =~ "local proof-only timeout"
    assert content =~ "suite-wide timeout changes"
    assert content =~ "broader repo-health context"
    assert content =~ "Optional knowledge lane"
    assert content =~ "docs/adoption_lanes.md"
    assert content =~ "docs/semantic_fast_path.md"
    refute content =~ "mix scoria.test.knowledge"
    refute content =~ "Scoria is shipped through `v1.9 Crucible`"
    assert File.read!(@scoria_doctest) =~ "doctest Scoria"
    assert File.read!(@identity_doctest) =~ "doctest Scoria.Identity"
  end

  test "lane selection guide documents the adoption order and optional boundaries" do
    content = File.read!(@lane_guide)

    assert content =~ "Default runtime lane"
    assert content =~ "Bounded handoff lane"
    assert content =~ "Semantic fast-path lane"
    assert content =~ "Optional knowledge lane"
    assert content =~ "identity -> start -> inspect -> resume"
    assert content =~ "Scoria.start_handoff_run/3"
    assert content =~ "use Scoria.SemanticLane"
    assert content =~ "mix test.adoption"
    assert content =~ "mix test.semantic_fast_path"
    assert content =~ "mix test.knowledge"
    refute content =~ "mix scoria.test.knowledge"
    assert content =~ "This lane is explicitly optional."
    assert content =~ "Start narrow. Expand only when the current lane already feels boring."
  end

  test "bounded handoff guide documents the narrow public delegation lane" do
    content = File.read!(@handoff_guide)

    assert content =~ "identity -> start -> inspect -> resume"
    assert content =~ "Scoria.start_handoff_run"
    assert content =~ "Scoria.get_run_detail"
    assert content =~ "delegated_handoffs"
    assert content =~ "root_role_id"
    assert content =~ "delegated_kind"
    assert content =~ "handoff_input"
    assert content =~ "projected_context"
    assert content =~ "projected_context: %{}"
    assert content =~ "queued child step"
    assert content =~ "same durable run"
    assert content =~ "Delegated Evidence"
    assert content =~ "No remaining adopter-facing gap"
    assert content =~ "deferred follow-up"
    assert content =~ "mix test.adoption"
    assert content =~ "separate verifier lane"
    assert content =~ "Broad runtime-state keys are rejected explicitly"
    assert content =~ "transcript"
    assert content =~ "provider_session"
    assert content =~ "session"
    assert content =~ "secrets"
    assert content =~ "socket_state"
    assert content =~ "/scoria/workflows/:run_id"
    refute content =~ "implicit payload projection"
  end

  test "semantic fast-path guide documents the conservative reuse contract" do
    content = File.read!(@semantic_guide)

    assert content =~ "Use it only after the default runtime lane already works"
    assert content =~ "use Scoria.SemanticLane"
    assert content =~ "default_scope: :tenant_shared"
    assert content =~ "default_scope: :actor_scoped"
    assert content =~ "safe_read_only: true"
    assert content =~ "semantic_cache: [lane: MyApp.AI.AccountFaqLane]"
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
    assert content =~ "mix test.semantic_fast_path"
    assert content =~ "mix test.knowledge"
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

    assert content =~ "mix scoria.release_preview"
    assert content =~ "mix scoria.install"
    assert content =~ "mix ecto.migrate"
    assert content =~ "mix test"
    assert content =~ "mix test.adoption"
    assert content =~ "mix test.semantic_fast_path"
    assert content =~ "mix test.knowledge"
    assert content =~ "SCORIA_DB_PORT=55432"
    assert content =~ "canonical default-lane verifier"
    assert content =~ "fresh-host install/migrate/route/runtime smoke"
    assert content =~ "local proof-only timeout"
    assert content =~ "suite-wide timeout change"
    assert content =~ "canonical `v2.1` troubleshooting lane"
    assert content =~ "broader repo-health context"
    assert content =~ "Scoria.start_run"
    assert content =~ "Scoria.get_run"
    assert content =~ "list_runs_for_session"
    assert content =~ "/scoria/workflows/:run_id"
    assert content =~ "Optional knowledge lane"
    assert content =~ "repository closeout, the canonical proof chain is exactly"
    assert content =~ "mix scoria.release_preview\nmix test.adoption"
    assert content =~ "CI should run this lane in `MIX_ENV=dev` because ExDoc stays a dev-only tool"
    assert content =~
             "You do not need pgvector, knowledge tables, retrieval, grounding, semantic-fast-path setup, or `mix test.knowledge` to prove the core lane."

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

    refute Regex.match?(
             ~r/mix scoria\.release_preview\s+mix test\s*\n(?!\.adoption)/,
             content
           )

    refute Regex.match?(~r/```bash\s+mix test\.adoption --trace\s+```/, content)
    refute content =~ "mix scoria.test.knowledge"
    refute content =~ "pgvector, retrieval, or semantic caching before Scoria is usable"
  end

  test "public modules expose compiled moduledocs on current Elixir" do
    for mod <- [Scoria, Scoria.Runtime, Scoria.Identity, Scoria.PromptPolicy] do
      assert {:docs_v1, _, :elixir, _, moduledoc, _, _} = Code.fetch_docs(mod)

      assert moduledoc not in [nil, :none], "#{inspect(mod)} is missing moduledoc"

      moduledoc_text =
        case moduledoc do
          %{"en" => text} -> text
          text when is_binary(text) -> text
        end

      assert is_binary(moduledoc_text)
      assert String.trim(moduledoc_text) != ""
    end
  end
end
