defmodule Scoria.SemanticLane do
  @moduledoc """
  Legacy 0.1.x compatibility wrapper for `Scoria.SemanticCache.Profile`.

  0.1.x compatibility migration note: new code should
  `use Scoria.SemanticCache.Profile` with `cache_key:` and the semantic cache
  vocabulary. This wrapper keeps older `use Scoria.SemanticLane, lane_key: ...`
  modules and `describe/1` calls working while adopters migrate.

  The wrapper is visible in the Compatibility Aliases reference group and does
  not emit runtime deprecation warnings. See `guides/reference/glossary.md` for
  the 0.1.x compatibility aliases and the final public vocabulary.
  """

  @type scope_kind :: :tenant_shared | :actor_scoped

  @callback lane_key() :: String.t()
  @callback default_scope() :: scope_kind()
  @callback safe_read_only?() :: boolean()
  @callback metadata() :: map()

  defmacro __using__(opts) do
    lane_key = Keyword.fetch!(opts, :lane_key)
    profile_opts = opts |> Keyword.delete(:lane_key) |> Keyword.put(:cache_key, lane_key)

    quote do
      use Scoria.SemanticCache.Profile, unquote(profile_opts)
    end
  end

  defdelegate describe(module), to: Scoria.SemanticCache.Profile
end
