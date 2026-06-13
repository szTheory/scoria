defmodule ScoriaWeb.CitationEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:evidence, :map, required: true)

  def render(assigns) do
    assigns =
      assigns
      |> assign(:query_text, evidence_value(assigns.evidence, :query_text, ""))
      |> assign(:freshness, evidence_value(assigns.evidence, :freshness, "unknown"))
      |> assign(:citations, evidence_value(assigns.evidence, :citations, []))
      |> assign(:ranked_chunks, evidence_value(assigns.evidence, :ranked_chunks, []))
      |> assign(:unsupported_claims, evidence_value(assigns.evidence, :unsupported_claims, []))

    ~H"""
    <.notebook
      id="citation-evidence-notebook"
      title="side-by-side citation review"
      eyebrow="retrieval evidence"
      selected_tab="retrieval"
    >
      <:tab key="retrieval" label="Retrieval">
        <div class="grid gap-4 lg:grid-cols-2">
          <.evidence_section
            title="Answer + citation anchors"
            badge={to_string(@freshness)}
            tone={tone(@freshness)}
          >
            <.evidence_rows rows={[{"Query", @query_text}, {"freshness", @freshness}]} />

            <div class="mt-3 space-y-3">
              <.evidence_section
                :for={citation <- @citations}
                title={citation_value(citation, :label, "citation")}
                description={citation_value(citation, :title, "untitled citation")}
              >
                <.evidence_rows rows={[{"locator", citation_value(citation, :locator, "unknown")}]} />
              </.evidence_section>
            </div>
          </.evidence_section>

          <.evidence_section
            title="Evidence and unsupported claims"
            badge={unsupported_badge(@unsupported_claims)}
            tone={unsupported_tone(@unsupported_claims)}
          >
            <div class="space-y-3">
              <.evidence_section
                :for={chunk <- @ranked_chunks}
                title={"rank #{chunk_value(chunk, :rank, "unknown")}"}
                description={"score #{chunk_value(chunk, :score, "unknown")}"}
              >
                <.evidence_rows rows={[{"Body", chunk_value(chunk, :body, "")}]} />
              </.evidence_section>
            </div>

            <.evidence_rows rows={[{"unsupported", Enum.join(@unsupported_claims, ", ")}]} class="mt-3" />
          </.evidence_section>
        </div>
      </:tab>
    </.notebook>
    """
  end

  defp evidence_value(evidence, key, default) when is_map(evidence) do
    cond do
      Map.has_key?(evidence, key) -> Map.get(evidence, key)
      Map.has_key?(evidence, to_string(key)) -> Map.get(evidence, to_string(key))
      true -> default
    end
  end

  defp evidence_value(_evidence, _key, default), do: default

  defp citation_value(citation, key, default), do: map_value(citation, key, default)
  defp chunk_value(chunk, key, default), do: map_value(chunk, key, default)

  defp map_value(map, key, default) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, to_string(key)) -> Map.get(map, to_string(key))
      true -> default
    end
  end

  defp map_value(_map, _key, default), do: default

  defp unsupported_badge([]), do: "supported"
  defp unsupported_badge(_claims), do: "unsupported"

  defp unsupported_tone([]), do: :pass
  defp unsupported_tone(_claims), do: :warn
end
