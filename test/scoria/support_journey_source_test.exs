defmodule Scoria.SupportJourneySourceTest do
  use ExUnit.Case, async: true

  alias Scoria.SupportJourney

  for {path, fragments} <- SupportJourney.adopter_doc_surfaces() do
    test "adopter doc #{path} stays aligned with SupportJourney fixture SSOT" do
      content = File.read!(unquote(path))

      for fragment <- unquote(Macro.escape(fragments)) do
        assert content =~ fragment,
               "expected #{unquote(path)} to contain fragment #{inspect(fragment)}"
      end
    end
  end

  test "ticket and persona fixtures load from priv" do
    ticket = SupportJourney.ticket_fixture()
    persona = SupportJourney.persona_fixture()

    assert ticket["id"] == "TKT-1042"
    assert ticket["subject"] =~ "Duplicate charge"
    assert persona["tenant_id"] == SupportJourney.tenant_id()
    assert persona["persona"] == "Support Ops Lead"
  end

  test "handoff input references ticket fixture" do
    input = SupportJourney.handoff_input()

    assert input["ticket_id"] == SupportJourney.ticket_fixture()["id"]
    assert input["brief"] =~ "TKT-1042"
  end

  test "dev seed tops up approval fixtures instead of appending on every run" do
    seed_source = File.read!("priv/repo/dev_seed.exs")

    assert seed_source =~ ~s(approval_seed_version = "2026-06-approval-run-v2")
    assert seed_source =~ ~s("seed_kind" => "approval_inbox_demo")
    assert seed_source =~ ~s("seed_version" => approval_seed_version)
    assert seed_source =~ "existing_seed_keys"
    assert seed_source =~ "missing_approval_specs"

    assert seed_source =~
             "Scoria.Workflows.complete_step(step.id, pre_step.result, run_status: \"running\")"

    refute seed_source =~ "for _ <- 1..5 do"
  end
end
