defmodule Scoria.Knowledge.EmbedderTest do
  use ExUnit.Case, async: true

  alias Scoria.Knowledge.Embedder

  defmodule NoModelName do
    @behaviour Scoria.Knowledge.Embedder

    @impl true
    def embed_chunks(chunks, _opts), do: Enum.map(chunks, fn _ -> [0.0] end)
  end

  describe "Deterministic.model_name/0" do
    test "returns a stable non-empty binary literal" do
      assert Embedder.Deterministic.model_name() == "scoria.deterministic.sha256.v1"
      assert is_binary(Embedder.Deterministic.model_name())
      assert Embedder.Deterministic.model_name() != ""
    end

    test "is exported (an optional callback the Deterministic embedder implements)" do
      # Ensure the module is loaded first — function_exported?/3 reports false for a
      # not-yet-loaded module, which makes this assertion order-dependent across the
      # full suite (passes in isolation, flaky when run after other test files).
      assert Code.ensure_loaded?(Embedder.Deterministic)
      assert function_exported?(Embedder.Deterministic, :model_name, 0)
    end
  end

  describe "guarded fall-through for host embedders lacking model_name/0" do
    test "function_exported?/3 returns false without raising UndefinedFunctionError" do
      assert Code.ensure_loaded?(NoModelName)
      refute function_exported?(NoModelName, :model_name, 0)
    end
  end
end
