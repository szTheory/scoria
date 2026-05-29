defmodule Scoria.Knowledge.Embedder do
  @callback embed_chunks([map()], keyword()) :: [[float()]]

  defmodule Deterministic do
    @behaviour Scoria.Knowledge.Embedder

    @impl true
    def embed_chunks(chunks, _opts) do
      Enum.map(chunks, &vectorize(&1.body))
    end

    def embed_query(text, _opts \\ []) do
      vectorize(text)
    end

    defp vectorize(text) do
      bytes = :crypto.hash(:sha256, text || "") |> :binary.bin_to_list()

      bytes
      |> Enum.chunk_every(10)
      |> Enum.take(3)
      |> Enum.map(fn chunk ->
        Enum.sum(chunk) / max(length(chunk) * 255, 1)
      end)
    end
  end
end
