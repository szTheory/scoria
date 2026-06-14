defmodule ScoriaWeb.TraceTreeComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  @endpoint ScoriaWeb.OrchestratorLiveTest.Endpoint

  test "renders trace span data using a flat DOM structure" do
    spans = [
      %{id: "span-1", name: "llm_call", parent_id: nil},
      %{id: "span-2", name: "tool_call", parent_id: "span-1"}
    ]

    assigns = %{id: "trace-1", spans: spans}

    html = render_component(ScoriaWeb.TraceTreeComponent, assigns)

    # Should not have deep nesting, spans should be sibling rows
    assert html =~ ~s(class="trace-row )
    assert html =~ "llm_call"
    assert html =~ "tool_call"

    # Verify no deep nesting (this is a bit heuristic, but checking for flat structure)
    # We can parse with Floki or just check for rows
    [{_, _, children}] = Floki.parse_fragment!(html)

    assert Enum.count(children, fn
             {"div", attrs, _} ->
               Enum.any?(attrs, fn {k, v} -> k == "class" and String.contains?(v, "trace-row") end)

             _ ->
               false
           end) == 2
  end

  test "applies appropriate indentation style via dynamic CSS variable (--indent-level)" do
    spans = [
      %{id: "span-1", name: "root", depth: 0},
      %{id: "span-2", name: "child", depth: 1},
      %{id: "span-3", name: "grandchild", depth: 2}
    ]

    assigns = %{id: "trace-2", spans: spans}

    html = render_component(ScoriaWeb.TraceTreeComponent, assigns)

    assert html =~ ~s(style="--indent-level: 0")
    assert html =~ ~s(style="--indent-level: 1")
    assert html =~ ~s(style="--indent-level: 2")
  end

  test "token preview renders without raw palette utility classes" do
    html =
      render_component(ScoriaWeb.TraceTreeComponent,
        id: "trace-preview",
        spans: [%{id: "span-llm", name: "llm_call", span_kind: "LLM", depth: 0}],
        token_previews: %{"span-llm" => "streamed token"}
      )

    assert html =~ "token-preview"
    assert html =~ "streamed token"
    refute html =~ "emerald-"
    refute html =~ "gray-"
  end

  test "source stays tokenized while preserving lazy metadata targeting" do
    source = File.read!("lib/scoria_web/components/trace_tree_component.ex")

    assert source =~ "phx-target={@myself}"

    for forbidden <- ["stone-", "gray-", "emerald-", "amber-", "rose-", "red-", "blue-"] do
      refute source =~ forbidden
    end
  end
end
