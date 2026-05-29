defmodule Scoria.SemanticCache.Compatibility do
  @moduledoc """
  Compatibility helpers for conservative semantic-cache reuse.
  """

  import Ecto.Query, warn: false

  alias Scoria.Knowledge.RetrievalResult
  alias Scoria.Knowledge.Source
  alias Scoria.PromptPolicy
  alias Scoria.Repo
  alias Scoria.SemanticCache.Entry

  @policy_snapshot_keys ~w(policy_key tools_allowed grounding_required approval_required metadata)a
  @reject_codes ~w(
    prompt_version_mismatch
    policy_mismatch
    source_fingerprint_mismatch
    scope_mismatch
    entry_stale
    entry_invalidated
  )

  def policy_fingerprint(policy) do
    policy
    |> PromptPolicy.normalize()
    |> PromptPolicy.to_map()
    |> Map.take(@policy_snapshot_keys)
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  def source_fingerprint_for_retrieval_run(nil), do: nil

  def source_fingerprint_for_retrieval_run(retrieval_run_id) when is_binary(retrieval_run_id) do
    RetrievalResult
    |> join(:inner, [result], source in Source, on: source.id == result.source_id)
    |> where([result, _source], result.retrieval_run_id == ^retrieval_run_id)
    |> order_by([result, source], asc: result.rank, asc: source.id)
    |> select([result, source], {source.id, source.version, source.digest})
    |> Repo.all()
    |> case do
      [] ->
        nil

      tokens ->
        tokens
        |> Enum.map(fn {source_id, version, digest} -> "#{source_id}:#{version}:#{digest}" end)
        |> :erlang.term_to_binary()
        |> then(&:crypto.hash(:sha256, &1))
        |> Base.encode16(case: :lower)
    end
  end

  def check_candidate(%Entry{} = entry, attrs, now \\ DateTime.utc_now()) do
    cond do
      entry.status == "invalidated" or not is_nil(entry.invalidated_at) ->
        {:reject, "entry_invalidated"}

      entry.status == "stale" or expired?(entry, now) ->
        {:reject, "entry_stale"}

      mismatch?(entry.prompt_version, Map.get(attrs, :prompt_version)) ->
        {:reject, "prompt_version_mismatch"}

      mismatch?(entry.policy_fingerprint, Map.get(attrs, :policy_fingerprint)) ->
        {:reject, "policy_mismatch"}

      mismatch?(entry.source_fingerprint, Map.get(attrs, :source_fingerprint)) ->
        {:reject, "source_fingerprint_mismatch"}

      scope_mismatch?(entry, attrs) ->
        {:reject, "scope_mismatch"}

      true ->
        :ok
    end
  end

  def reject_code?(code), do: code in @reject_codes

  defp expired?(%Entry{expires_at: nil}, _now), do: false
  defp expired?(%Entry{expires_at: expires_at}, now), do: DateTime.compare(expires_at, now) != :gt

  defp mismatch?(_entry_value, nil), do: false
  defp mismatch?(nil, _lookup_value), do: true
  defp mismatch?(entry_value, lookup_value), do: entry_value != lookup_value

  defp scope_mismatch?(%Entry{scope_kind: "actor_scoped", actor_id: actor_id}, attrs) do
    actor_id != Map.get(attrs, :actor_id)
  end

  defp scope_mismatch?(_entry, _attrs), do: false
end
