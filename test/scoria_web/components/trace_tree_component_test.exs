defmodule ScoriaWeb.TraceTreeComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias Scoria.Observe.TraceProjection

  @endpoint ScoriaWeb.OrchestratorLiveTest.Endpoint

  # Semconv.guardrail_keys/0's dotted attribute-key strings — mirrored here
  # (not aliased) so the test independently pins the wire shape the
  # component reads from `attributes_preview`, the way TraceProjection's
  # own tests pin the registry via a hand-written canary.
  @guardrail_name_key "scoria.guardrail.name"
  @guardrail_decision_key "scoria.guardrail.decision"
  @guardrail_reason_code_key "scoria.guardrail.reason_code"

  defp child_row_style(html, span_id) do
    document = Floki.parse_fragment!(html)

    {"div", attrs, _children} =
      document
      |> Floki.find("div.trace-row")
      |> Enum.find(fn row ->
        row
        |> Floki.find("[phx-value-span_id]")
        |> Floki.attribute("phx-value-span_id")
        |> Enum.member?(span_id)
      end)

    {_k, style} = Enum.find(attrs, fn {k, _v} -> k == "style" end)
    style
  end

  test "nesting is rendered: depths assigned by TraceProjection.with_depths/1 flow into --indent-level, consumed by a padding-left calc() rule" do
    spans =
      TraceProjection.with_depths([
        %{id: "parent", parent_id: nil, name: "root_call"},
        %{id: "child", parent_id: "parent", name: "child_call"}
      ])

    html = render_component(ScoriaWeb.TraceTreeComponent, id: "trace-nesting", spans: spans)

    parent_style = child_row_style(html, "parent")
    child_style = child_row_style(html, "child")

    assert parent_style =~ "--indent-level: 0"
    assert child_style =~ "--indent-level: 1"

    # --indent-level is consumed, not just set: the shared .scoria-span CSS
    # rule renders it as a padding-left calc() (D-07a). This is the one CSS
    # rule that must exist so the variable above is never dangling.
    css = File.read!("assets/css/04-components.css")
    assert css =~ "padding-left: calc(0.75rem + var(--indent-level, 0) * 1.25rem)"
  end

  test "depth 0 vs depth 1 differ on the parent vs child row" do
    spans =
      TraceProjection.with_depths([
        %{id: "parent", parent_id: nil, name: "root_call"},
        %{id: "child", parent_id: "parent", name: "child_call"}
      ])

    html = render_component(ScoriaWeb.TraceTreeComponent, id: "trace-depths", spans: spans)

    refute child_row_style(html, "parent") == child_row_style(html, "child")
  end

  describe "ERROR overlay (D-07b, WCAG 1.4.1)" do
    test "a span with status_code ERROR renders the overlay class and a visually-hidden label" do
      spans = [
        %{id: "span-err", name: "tool_call", parent_id: nil, depth: 0, status_code: "ERROR"}
      ]

      html = render_component(ScoriaWeb.TraceTreeComponent, id: "trace-error", spans: spans)

      assert html =~ "scoria-span--status-error"
      assert html =~ ~s(<span class="sr-only">Errored</span>)
    end

    test "a span with status_code OK renders neither the overlay class nor the label" do
      spans = [%{id: "span-ok", name: "tool_call", parent_id: nil, depth: 0, status_code: "OK"}]

      html = render_component(ScoriaWeb.TraceTreeComponent, id: "trace-ok", spans: spans)

      refute html =~ "scoria-span--status-error"
      refute html =~ "sr-only"
    end
  end

  describe "guardrail badge (D-07e, T-53-01)" do
    test "renders operator microcopy and never the raw reason_code enum value" do
      spans = [
        %{
          id: "span-guardrail",
          name: "release_check",
          parent_id: nil,
          depth: 0,
          span_kind: "guardrail",
          status_code: "OK",
          attributes_preview: %{
            @guardrail_name_key => "release_gate",
            @guardrail_decision_key => "block",
            @guardrail_reason_code_key => "unapproved_draft"
          }
        }
      ]

      html = render_component(ScoriaWeb.TraceTreeComponent, id: "trace-guardrail", spans: spans)

      assert html =~ "Blocked — prompt version is a draft, not released"
      refute html =~ "unapproved_draft"
    end

    test "a blocked guardrail span (status_code OK) renders the badge but NOT the error overlay (D-05e)" do
      spans = [
        %{
          id: "span-blocked",
          name: "release_check",
          parent_id: nil,
          depth: 0,
          span_kind: "guardrail",
          status_code: "OK",
          attributes_preview: %{
            @guardrail_name_key => "release_gate",
            @guardrail_decision_key => "block",
            @guardrail_reason_code_key => "unapproved_draft"
          }
        }
      ]

      html = render_component(ScoriaWeb.TraceTreeComponent, id: "trace-blocked", spans: spans)

      assert html =~ "Blocked — prompt version is a draft, not released"
      refute html =~ "scoria-span--status-error"
      refute html =~ "sr-only"
    end
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

  test "renders the lowercase-native scoria-span--llm rail class regardless of stored casing" do
    html =
      render_component(ScoriaWeb.TraceTreeComponent,
        id: "trace-casing",
        spans: [%{id: "span-llm", name: "llm_call", span_kind: "LLM", depth: 0}]
      )

    assert html =~ "scoria-span--llm"
    refute html =~ "scoria-span--LLM"
  end

  test "source stays tokenized while preserving lazy metadata targeting" do
    source = File.read!("lib/scoria_web/components/trace_tree_component.ex")

    assert source =~ "phx-target={@myself}"

    for forbidden <- ["stone-", "gray-", "emerald-", "amber-", "rose-", "red-", "blue-"] do
      refute source =~ forbidden
    end
  end
end
