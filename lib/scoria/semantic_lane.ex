defmodule Scoria.SemanticLane do
  @moduledoc """
  Legacy 0.1.x compatibility wrapper for `Scoria.SemanticCache.Profile`.

  Use `Scoria.SemanticCache.Profile` with `cache_key:` for final semantic cache
  vocabulary. This module keeps `lane_key:` and `describe/1` accepted for
  existing callers.
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
