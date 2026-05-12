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
end
