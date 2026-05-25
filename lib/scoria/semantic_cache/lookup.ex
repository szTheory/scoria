defmodule Scoria.SemanticCache.Lookup do
  @moduledoc """
  Exact-text-first semantic lookup with conservative compatibility checks.
  """

  import Ecto.Query, warn: false
  import Pgvector.Ecto.Query

  alias Scoria.Repo
  alias Scoria.SemanticCache.Compatibility
  alias Scoria.SemanticCache.Entry

  @semantic_distance_threshold 0.10
  @rankable_statuses ~w(active stale invalidated)
  @known_attr_keys ~w(
    actor_id
    lane_key
    policy_fingerprint
    prompt_version
    query_embedding
    query_text
    source_fingerprint
    tenant_id
  )a

  def lookup(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_attrs(attrs)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    attrs
    |> exact_query()
    |> Repo.all()
    |> resolve_candidates(attrs, now)
    |> case do
      :miss ->
        semantic_lookup(attrs, now)

      result ->
        result
    end
  end

  defp semantic_lookup(%{query_embedding: query_embedding} = attrs, now) when is_list(query_embedding) do
    attrs
    |> semantic_query(query_embedding)
    |> Repo.all()
    |> resolve_candidates(attrs, now)
  end

  defp semantic_lookup(_attrs, _now), do: :miss

  defp resolve_candidates([], _attrs, _now), do: :miss

  defp resolve_candidates(entries, attrs, now) do
    Enum.reduce_while(entries, :miss, fn entry, _acc ->
      case Compatibility.check_candidate(entry, attrs, now) do
        :ok -> {:halt, {:hit, entry}}
        {:reject, reason_code} -> {:halt, {:reject, reason_code, entry}}
      end
    end)
  end

  defp exact_query(attrs) do
    attrs
    |> base_query()
    |> where([entry], entry.query_text == ^Map.fetch!(attrs, :query_text))
    |> order_by([entry], desc: fragment("CASE WHEN ? = 'actor_scoped' THEN 1 ELSE 0 END", entry.scope_kind))
    |> order_by([entry], desc: entry.updated_at)
  end

  defp semantic_query(attrs, query_embedding) do
    attrs
    |> base_query()
    |> where([entry], not is_nil(entry.query_embedding))
    |> where(
      [entry],
      cosine_distance(entry.query_embedding, ^Pgvector.new(query_embedding)) <= ^@semantic_distance_threshold
    )
    |> order_by([entry], asc: cosine_distance(entry.query_embedding, ^Pgvector.new(query_embedding)))
    |> order_by([entry], desc: entry.updated_at)
  end

  defp base_query(attrs) do
    tenant_id = Map.fetch!(attrs, :tenant_id)
    lane_key = Map.fetch!(attrs, :lane_key)
    actor_id = Map.get(attrs, :actor_id)

    Entry
    |> where([entry], entry.tenant_id == ^tenant_id and entry.lane_key == ^lane_key)
    |> where([entry], entry.status in ^@rankable_statuses)
    |> maybe_scope_filter(actor_id)
  end

  defp maybe_scope_filter(query, nil) do
    where(query, [entry], entry.scope_kind == "tenant_shared")
  end

  defp maybe_scope_filter(query, actor_id) do
    where(
      query,
      [entry],
      entry.scope_kind == "tenant_shared" or
        (entry.scope_kind == "actor_scoped" and entry.actor_id == ^actor_id)
    )
  end

  defp normalize_attrs(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_attrs()
  defp normalize_attrs(attrs) when is_list(attrs), do: attrs |> Enum.into(%{}) |> normalize_attrs()
  defp normalize_attrs(attrs) when is_map(attrs), do: Map.new(attrs, &normalize_pair/1)
  defp normalize_attrs(_attrs), do: %{}

  defp normalize_pair({key, value}) when is_binary(key) do
    atom_key =
      key
      |> String.to_existing_atom()
      |> then(fn existing_key -> if existing_key in @known_attr_keys, do: existing_key, else: key end)

    {atom_key, value}
  rescue
    ArgumentError -> {key, value}
  end

  defp normalize_pair({key, value}), do: {key, value}
end
