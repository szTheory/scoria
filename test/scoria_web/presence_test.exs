defmodule ScoriaWeb.PresenceTest do
  use ExUnit.Case, async: true

  test "Presence module starts successfully under supervisor" do
    assert Process.whereis(ScoriaWeb.Presence) != nil
  end
end
