defmodule ScoriaWeb.WorkflowTreeComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  test "workflow tree renders nested steps and compact handoff markers" do
    html =
      render_component(&ScoriaWeb.WorkflowTreeComponent.workflow_tree/1,
        steps: [
          %{id: "1", role_id: "root", kind: "model", status: "running", depth: 0},
          %{id: "2", role_id: "critic", kind: "handoff", status: "queued", depth: 1}
        ],
        selected_step_id: "1"
      )

    assert html =~ "workflow-tree-row"
    assert html =~ "handoff"
    assert html =~ ~s(--indent-level: 1)
  end

  test "renders the lowercase-native scoria-span--llm rail class for the answer step vocab" do
    html =
      render_component(&ScoriaWeb.WorkflowTreeComponent.workflow_tree/1,
        steps: [
          %{id: "1", role_id: "root", kind: "answer", status: "running", depth: 0}
        ],
        selected_step_id: nil
      )

    assert html =~ "scoria-span--llm"
  end

  test "workflow tree source keeps selection behavior without raw palette classes" do
    source = File.read!("lib/scoria_web/components/workflow_tree_component.ex")

    assert source =~ ~s(phx-click="select_step")
    assert source =~ "workflow-tree-row"

    for forbidden <- ["stone-", "gray-", "emerald-", "amber-", "rose-", "red-", "blue-"] do
      refute source =~ forbidden
    end
  end
end
