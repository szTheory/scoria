defmodule Scoria.AdoptionSurfaceTest do
  use ExUnit.Case, async: true

  @readme "README.md"
  @phoenix_example "docs/phoenix_runtime_example.md"
  @handoff_guide "docs/bounded_handoffs.md"
  @gap_ledger "docs/bounded_handoffs.md"
  @operator_guide "docs/operator_verification.md"
  @scoria_doctest "test/scoria_test.exs"
  @identity_doctest "test/scoria/identity_doctest_test.exs"

  test "README documents the runtime-first adoption lane and optional knowledge lane" do
    content = File.read!(@readme)

    assert content =~ "identity -> start -> inspect -> resume"
    assert content =~ "Scoria.start_run"
    assert content =~ "Scoria.start_handoff_run"
    assert content =~ "Scoria.get_run_detail"
    assert content =~ "delegated_handoffs"
    assert content =~ "Scoria.resume_run"
    assert content =~ "session_id"
    assert content =~ "run_id"
    assert content =~ "/scoria/workflows/:run_id"
    assert content =~ "Optional knowledge lane"
    assert File.read!(@scoria_doctest) =~ "doctest Scoria"
    assert File.read!(@identity_doctest) =~ "doctest Scoria.Identity"
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
    assert content =~ "Broad runtime-state keys are rejected explicitly"
    assert content =~ "transcript"
    assert content =~ "provider_session"
    assert content =~ "session"
    assert content =~ "secrets"
    assert content =~ "socket_state"
    assert content =~ "/scoria/workflows/:run_id"
    refute content =~ "implicit payload projection"
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

  test "operator verification guide documents the core automated lane without knowledge requirements" do
    content = File.read!(@operator_guide)

    assert content =~ "mix scoria.install"
    assert content =~ "mix ecto.migrate"
    assert content =~ "mix test"
    assert content =~ "mix test.adoption"
    assert content =~ "mix test.semantic_fast_path"
    assert content =~ "SCORIA_DB_PORT=55432"
    assert content =~ "canonical ADPT-02 proof lane"
    assert content =~ "canonical `v2.1` troubleshooting lane"
    assert content =~ "broader repo-health context"
    assert content =~ "Scoria.start_run"
    assert content =~ "Scoria.get_run"
    assert content =~ "list_runs_for_session"
    assert content =~ "/scoria/workflows/:run_id"
    assert content =~ "Optional knowledge lane"
    assert content =~ "mix scoria.test.knowledge"
    assert content =~ "bypass"
    assert content =~ "miss"
    assert content =~ "reject"
    assert content =~ "hit"
    assert content =~ "active"
    assert content =~ "stale"
    assert content =~ "invalidated"
    assert content =~ "writeback_rejected"
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
