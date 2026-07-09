defmodule ScoriaWeb.ReplayTraceNotebookComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias ScoriaWeb.ReplayEvidenceNotebookComponent
  alias ScoriaWeb.ReplayTraceNotebookComponent

  test "renders replay trace notebook labels and empty comparison state" do
    assigns = %{
      step: nil,
      checkpoint: nil,
      comparison: %{},
      selected_source_variant: "original",
      selected_comparison_entry: %{}
    }

    html =
      rendered_to_string(~H"""
      <ReplayTraceNotebookComponent.render
        step={@step}
        checkpoint={@checkpoint}
        comparison={@comparison}
        selected_source_variant={@selected_source_variant}
        selected_comparison_entry={@selected_comparison_entry}
      />
      """)

    assert html =~ ~s(id="replay-trace-notebook")
    assert html =~ "Replay trace notebook"
    assert html =~ "No Replay Comparison Available"
  end

  test "legacy ReplayEvidenceNotebookComponent delegates to replay trace rendering" do
    assigns = %{
      step: nil,
      checkpoint: nil,
      comparison: %{},
      selected_source_variant: "original",
      selected_comparison_entry: %{}
    }

    html =
      rendered_to_string(~H"""
      <ReplayEvidenceNotebookComponent.render
        step={@step}
        checkpoint={@checkpoint}
        comparison={@comparison}
        selected_source_variant={@selected_source_variant}
        selected_comparison_entry={@selected_comparison_entry}
      />
      """)

    assert html =~ ~s(id="replay-trace-notebook")
    assert html =~ "Replay trace notebook"
  end
end
