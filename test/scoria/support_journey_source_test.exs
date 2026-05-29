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
end
