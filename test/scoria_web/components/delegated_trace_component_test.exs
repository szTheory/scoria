defmodule ScoriaWeb.DelegatedTraceComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias ScoriaWeb.DelegatedEvidenceComponent
  alias ScoriaWeb.DelegatedTraceComponent

  @delegated_handoffs [
    %{
      parent_role_id: "planner",
      delegated_role_id: "critic",
      delegated_kind: "review",
      parent_step_id: "parent-1",
      child_step_id: "child-1",
      child_status: "running",
      status: "running",
      capability_tags: ["policy"],
      handoff_input: %{"brief" => "Review the draft answer"},
      projected_context: %{"task" => "review", "draft_answer" => "hello"}
    }
  ]

  test "renders delegated trace labels and scoped context copy" do
    assigns = %{delegated_handoffs: @delegated_handoffs}

    html =
      rendered_to_string(~H"""
      <DelegatedTraceComponent.render delegated_handoffs={@delegated_handoffs} />
      """)

    assert html =~ ~s(id="delegated-trace")
    assert html =~ "Delegated Trace"
    assert html =~ "Inspect Delegated Trace"
    assert html =~ ~s(href="#delegated-trace")
    assert html =~ "Scoped Context Preview"
    assert html =~ "scoped context"
    assert html =~ "draft_answer"
  end

  test "legacy DelegatedEvidenceComponent delegates to delegated trace rendering" do
    assigns = %{delegated_handoffs: @delegated_handoffs}

    html =
      rendered_to_string(~H"""
      <DelegatedEvidenceComponent.render delegated_handoffs={@delegated_handoffs} />
      """)

    assert html =~ ~s(id="delegated-trace")
    assert html =~ "Delegated Trace"
    assert html =~ "Inspect Delegated Trace"
  end
end
