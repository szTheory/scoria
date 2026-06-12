defmodule ScoriaWeb.DashboardNavTest do
  use ExUnit.Case, async: true

  alias ScoriaWeb.DashboardNav

  test "groups are Operate, Improve, Configure in locked order" do
    assert DashboardNav.groups() |> Enum.map(& &1.label) == ["Operate", "Improve", "Configure"]
  end

  test "Operate contains Home, Approvals, Runs, and Incidents" do
    operate = DashboardNav.groups() |> Enum.find(&(&1.label == "Operate"))

    assert Enum.map(operate.items, & &1.label) == ["Home", "Approvals", "Runs", "Incidents"]
  end

  test "Configure owns connectors and tool stubs" do
    configure = DashboardNav.groups() |> Enum.find(&(&1.label == "Configure"))

    assert Enum.map(configure.items, & &1.label) == ["Connectors", "MCP Gateway", "Tool Registry"]
  end

  test "a noun appears in only one nav group and Connectors is only Configure" do
    labels =
      DashboardNav.groups()
      |> Enum.flat_map(& &1.items)
      |> Enum.map(& &1.label)

    assert Enum.count(labels, &(&1 == "Connectors")) == 1
    assert length(labels) == length(Enum.uniq(labels))
  end

  test "five reserved stubs are clickable coming-soon screens" do
    stubs = DashboardNav.stub_screens()

    assert Enum.map(stubs, & &1.stub_slug) == [
             "replay-playground",
             "cost-ledger",
             "feedback-inbox",
             "mcp-gateway",
             "tool-registry"
           ]

    assert Enum.all?(stubs, & &1.soon?)
    assert Enum.all?(stubs, &String.starts_with?(&1.path, "/coming/"))
  end

  test "stub_screen and stub_key_for_slug use the allowlisted metadata" do
    assert %{label: "Cost Ledger", key: :cost_ledger} = DashboardNav.stub_screen("cost-ledger")
    assert DashboardNav.stub_key_for_slug("cost-ledger") == :cost_ledger
    assert DashboardNav.stub_screen("dataset-builder") == nil
  end

  test "aliases are present for palette filtering" do
    items = DashboardNav.groups() |> Enum.flat_map(& &1.items)

    assert %{aliases: aliases} = Enum.find(items, &(&1.label == "Runs"))
    assert "runs" in aliases

    assert %{aliases: aliases} = Enum.find(items, &(&1.label == "Review Queue"))
    assert "review" in aliases

    assert %{aliases: aliases} = Enum.find(items, &(&1.label == "Tool Registry"))
    assert "tools" in aliases
  end

  test "command_sections derives navigate rows and actions from the nav source of truth" do
    sections = DashboardNav.command_sections("/scoria")

    assert Enum.map(sections, & &1.label) == ["Recent", "Navigate", "Actions"]

    navigate = Enum.find(sections, &(&1.label == "Navigate"))
    actions = Enum.find(sections, &(&1.label == "Actions"))
    nav_labels = DashboardNav.groups() |> Enum.flat_map(& &1.items) |> Enum.map(& &1.label)

    assert Enum.map(navigate.rows, & &1.label) == nav_labels

    assert %{label: "Runs", path: "/scoria/workflows", aliases: aliases, kbd: "g r"} =
             Enum.find(navigate.rows, &(&1.label == "Runs"))

    assert "traces" in aliases

    assert %{label: "Replay Playground", path: "/scoria/coming/replay-playground", soon?: true} =
             Enum.find(navigate.rows, &(&1.label == "Replay Playground"))

    assert Enum.map(actions.rows, & &1.label) == [
             "Toggle theme",
             "Keyboard shortcuts",
             "Copy current page URL"
           ]

    assert Enum.map(actions.rows, & &1.action) == [
             "toggle-theme",
             "show-shortcuts",
             "copy-url"
           ]
  end

  test "active keys cover workflow index and coming-soon screens" do
    assert DashboardNav.active_key(ScoriaWeb.WorkflowLive.Index, %{}) == :runs

    assert DashboardNav.active_key(ScoriaWeb.ComingSoonLive, %{"screen" => "cost-ledger"}) ==
             :cost_ledger

    assert DashboardNav.active_key(ScoriaWeb.ComingSoonLive, %{"screen" => "not-real"}) == nil
  end
end
