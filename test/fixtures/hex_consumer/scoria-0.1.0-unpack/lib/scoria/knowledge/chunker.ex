defmodule Scoria.Knowledge.Chunker do
  @callback chunk(Scoria.Knowledge.Source.t() | map(), keyword()) :: [map()]

  defmodule Default do
    @behaviour Scoria.Knowledge.Chunker

    @impl true
    def chunk(source, opts) do
      body = Map.get(source, :body) || Map.get(source, "body") || ""
      source_digest = Map.get(source, :digest) || Map.get(source, "digest") || ""
      overlap = Keyword.get(opts, :overlap, 24)

      body
      |> split_sections()
      |> Enum.map_reduce(0, fn %{heading_path: heading_path, text: text}, offset ->
        chunk = %{
          body: text,
          heading_path: heading_path,
          start_offset: offset,
          end_offset: offset + String.length(text),
          token_count: count_tokens(text)
        }

        chunk =
          Map.put(
            chunk,
            :chunk_digest,
            "#{source_digest}:#{chunk.start_offset}:#{chunk.end_offset}"
          )

        next_offset = max(chunk.end_offset - overlap, chunk.end_offset)
        {chunk, next_offset}
      end)
      |> elem(0)
      |> Enum.reject(&(String.trim(&1.body) == ""))
    end

    defp split_sections(body) do
      body
      |> String.split(~r/\n{2,}/, trim: true)
      |> Enum.map_reduce([], fn paragraph, headings ->
        line = String.trim(paragraph)

        if String.starts_with?(line, "#") do
          heading = line |> String.trim_leading("#") |> String.trim()
          {%{heading_path: headings ++ [heading], text: line}, headings ++ [heading]}
        else
          {%{heading_path: headings, text: line}, headings}
        end
      end)
      |> elem(0)
    end

    defp count_tokens(text) do
      text
      |> String.split(~r/\s+/, trim: true)
      |> length()
    end
  end
end
