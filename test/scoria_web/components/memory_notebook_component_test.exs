defmodule ScoriaWeb.MemoryNotebookComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias ScoriaWeb.MemoryNotebookComponent

  test "renders sequence ranges and summary text for a memory block" do
    memories = [
      %{
        start_sequence: 1,
        end_sequence: 10,
        summary_text: "Session started and user authenticated.",
        token_count: 150
      }
    ]

    html = render_component(&MemoryNotebookComponent.render/1, memories: memories, runtime_instance_id: "runtime-123")

    assert html =~ "Sequences 1 - 10"
    assert html =~ "Session started and user authenticated."
    assert html =~ "150"
    assert html =~ "archived raw tokens"
  end

  test "compaction block includes a reciprocal link to runtime presence context" do
    memories = [
      %{
        start_sequence: 11,
        end_sequence: 20,
        summary_text: "User queried data.",
        token_count: 200
      }
    ]

    html = render_component(&MemoryNotebookComponent.render/1, memories: memories, runtime_instance_id: "runtime-123")

    assert html =~ ~r/href="\/scoria\?runtime=runtime-123"/
    assert html =~ ~r/href="\/scoria\?runtime=runtime-123&amp;sequence=11"/
  end
end
