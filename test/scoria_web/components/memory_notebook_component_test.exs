defmodule ScoriaWeb.MemoryNotebookComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias ScoriaWeb.CitationEvidenceComponent
  alias ScoriaWeb.MemoryNotebookComponent

  @palette_regex ~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/

  test "retrieval, delegated, and memory adapters use shared notebook primitives" do
    adapter_paths = [
      "lib/scoria_web/components/citation_evidence_component.ex",
      "lib/scoria_web/components/delegated_evidence_component.ex",
      "lib/scoria_web/components/memory_notebook_component.ex"
    ]

    for path <- adapter_paths do
      source = File.read!(path)

      assert source =~ "import ScoriaWeb.UI"
      assert source =~ "<.notebook"
      refute source =~ @palette_regex
    end

    delegated_source = File.read!("lib/scoria_web/components/delegated_evidence_component.ex")
    assert delegated_source =~ "delegated_status_label"
  end

  test "citation adapter preserves retrieval evidence values inside a notebook" do
    html =
      render_component(&CitationEvidenceComponent.render/1,
        evidence: %{
          query_text: "How does Scoria ground an answer?",
          freshness: "fresh",
          citations: [
            %{label: "[1]", title: "Grounding handbook", locator: "section 2"}
          ],
          ranked_chunks: [
            %{rank: 1, score: "0.98", body: "Operators inspect ranked chunks."}
          ],
          unsupported_claims: ["missing source"]
        }
      )

    assert html =~ "scoria-notebook"
    assert html =~ "How does Scoria ground an answer?"
    assert html =~ "fresh"
    assert html =~ "[1]"
    assert html =~ "Grounding handbook"
    assert html =~ "section 2"
    assert html =~ "rank 1"
    assert html =~ "0.98"
    assert html =~ "Operators inspect ranked chunks."
    assert html =~ "missing source"
  end

  test "renders sequence ranges and summary text for a memory block" do
    memories = [
      %{
        start_sequence: 1,
        end_sequence: 10,
        summary_text: "Session started and user authenticated.",
        token_count: 150
      }
    ]

    html =
      render_component(&MemoryNotebookComponent.render/1,
        memories: memories,
        runtime_instance_id: "runtime-123"
      )

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

    html =
      render_component(&MemoryNotebookComponent.render/1,
        memories: memories,
        runtime_instance_id: "runtime-123"
      )

    assert html =~ ~r/href="\/scoria\?runtime=runtime-123"/
    assert html =~ ~r/href="\/scoria\?runtime=runtime-123&amp;sequence=11"/
  end
end
