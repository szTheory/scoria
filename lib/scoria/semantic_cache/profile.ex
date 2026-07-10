defmodule Scoria.SemanticCache.Profile do
  @moduledoc """
  `Scoria.SemanticCache.Profile` defines an opt-in semantic cache profile for
  safe read-only answer reuse.

  Use a profile after the default runtime capability is already working and the
  host app can name a narrow class of work that is safe to reuse. The host owns
  that safety decision; Scoria records the profile, compatibility checks, and
  reviewer-visible cache outcome.

  See `guides/capabilities/semantic-cache.md` for the full capability guide.
  Semantic cache is not a knowledge base: it reuses compatible answers for safe
  read-only work, while the optional knowledge base owns retrieval, citations,
  and grounding.

  New public setup should use `cache_key:`, `profile:`, and
  `Scoria.SemanticCache.Profile`. The stored `lane_key` and the
  `Scoria.SemanticLane` wrapper remain 0.1.x compatibility vocabulary.
  """

  @type scope_kind :: :tenant_shared | :actor_scoped

  @callback lane_key() :: String.t()
  @callback default_scope() :: scope_kind()
  @callback safe_read_only?() :: boolean()
  @callback metadata() :: map()

  defmacro __using__(opts) do
    cache_key = Keyword.fetch!(opts, :cache_key)
    default_scope = Keyword.get(opts, :default_scope, :tenant_shared)
    safe_read_only = Keyword.get(opts, :safe_read_only, true)
    metadata = Keyword.get(opts, :metadata, %{})

    metadata_ast =
      case metadata do
        {:%{}, _, _} -> metadata
        _ -> Macro.escape(metadata)
      end

    quote do
      @behaviour Scoria.SemanticCache.Profile

      @impl true
      def lane_key, do: unquote(cache_key)

      @impl true
      def default_scope, do: unquote(default_scope)

      @impl true
      def safe_read_only?, do: unquote(safe_read_only)

      @impl true
      def metadata, do: unquote(metadata_ast)
    end
  end

  def describe(module) when is_atom(module) do
    cond do
      not Code.ensure_loaded?(module) ->
        {:error, :invalid_semantic_cache_lane}

      not function_exported?(module, :lane_key, 0) ->
        {:error, :invalid_semantic_cache_lane}

      not function_exported?(module, :default_scope, 0) ->
        {:error, :invalid_semantic_cache_lane}

      not function_exported?(module, :safe_read_only?, 0) ->
        {:error, :invalid_semantic_cache_lane}

      true ->
        normalize_description(module)
    end
  end

  def describe(_module), do: {:error, :invalid_semantic_cache_lane}

  defp normalize_description(module) do
    with lane_key when is_binary(lane_key) and lane_key != "" <- module.lane_key(),
         scope when scope in [:tenant_shared, :actor_scoped] <- module.default_scope(),
         safe_read_only when is_boolean(safe_read_only) <- module.safe_read_only?() do
      module_name = Atom.to_string(module)

      {:ok,
       %{
         profile: module,
         profile_module: module_name,
         cache_key: lane_key,
         lane: module,
         lane_key: lane_key,
         lane_module: module_name,
         default_scope: scope,
         safe_read_only: safe_read_only,
         metadata: normalize_metadata(module_metadata(module))
       }}
    else
      _ -> {:error, :invalid_semantic_cache_lane}
    end
  end

  defp module_metadata(module) do
    if function_exported?(module, :metadata, 0), do: module.metadata(), else: %{}
  end

  defp normalize_metadata(metadata) when is_map(metadata), do: Map.new(metadata)
  defp normalize_metadata(_metadata), do: %{}
end
