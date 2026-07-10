defmodule Scoria.SemanticCache do
  @moduledoc """
  `Scoria.SemanticCache` is the public context for tenant-scoped semantic cache
  lookup, admission, reuse evidence, and invalidation.

  Use it only for explicitly safe read-only work after the default runtime path
  is green. The host app owns identity, tenant scope, policy values, and the
  decision that a profile is safe to reuse; Scoria owns compatibility checks,
  lifecycle state, and reviewer trace evidence for `hit`, `miss`, `bypass`, and
  `reject` outcomes.

  See `guides/capabilities/semantic-cache.md` for setup, profile vocabulary,
  verification, and troubleshooting. Semantic cache is not a knowledge base:
  it reuses compatible answers, while the optional knowledge base owns
  retrieval, citations, and grounding.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Scoria.Repo
  alias Scoria.SemanticCache.{Compatibility, Entry, EntryEvent, Invalidation, Lookup}

  @active_status "active"
  @known_attr_keys %{
    "actor_id" => :actor_id,
    "answer_payload" => :answer_payload,
    "evidence_refs" => :evidence_refs,
    "expires_at" => :expires_at,
    "hit_count" => :hit_count,
    "invalidated_at" => :invalidated_at,
    "lane_key" => :lane_key,
    "lane_module" => :lane_module,
    "last_hit_at" => :last_hit_at,
    "metadata" => :metadata,
    "model" => :model,
    "origin_retrieval_run_id" => :origin_retrieval_run_id,
    "origin_run_id" => :origin_run_id,
    "origin_span_id" => :origin_span_id,
    "policy_key" => :policy_key,
    "policy_fingerprint" => :policy_fingerprint,
    "prompt_ref" => :prompt_ref,
    "prompt_version" => :prompt_version,
    "provider" => :provider,
    "query_embedding" => :query_embedding,
    "query_text" => :query_text,
    "reason_code" => :reason_code,
    "scope_kind" => :scope_kind,
    "scope_reason" => :scope_reason,
    "source_fingerprint" => :source_fingerprint,
    "span_id" => :span_id,
    "status" => :status,
    "state_reason_code" => :state_reason_code,
    "tenant_id" => :tenant_id,
    "workflow_run_id" => :workflow_run_id
  }

  def lookup(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_attrs(attrs)

    with :ok <- require_tenant(attrs),
         :ok <- require_lane(attrs),
         :ok <- require_query_text(attrs) do
      Lookup.lookup(attrs)
    end
  end

  def admit(attrs) when is_map(attrs) or is_list(attrs) do
    attrs =
      attrs
      |> normalize_attrs()
      |> Map.put_new(:status, @active_status)
      |> Map.put_new(:scope_kind, "tenant_shared")
      |> Map.put_new(:scope_reason, "lane_default")
      |> Map.put_new(:answer_payload, %{})
      |> Map.put_new(:evidence_refs, %{})
      |> maybe_put_policy_fingerprint()
      |> Map.put_new(:metadata, %{})

    Multi.new()
    |> Multi.insert(:entry, Entry.changeset(%Entry{}, attrs))
    |> Multi.insert(:event, fn %{entry: entry} ->
      EntryEvent.changeset(%EntryEvent{}, %{
        entry_id: entry.id,
        event_kind: "admitted",
        reason_code: Map.get(attrs, :reason_code, "admitted"),
        workflow_run_id: Map.get(attrs, :origin_run_id),
        span_id: Map.get(attrs, :origin_span_id),
        metadata: %{"scope_kind" => entry.scope_kind, "scope_reason" => entry.scope_reason}
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{entry: entry, event: event}} -> {:ok, %{entry: entry, event: event}}
      {:error, _op, reason, _changes} -> {:error, reason}
    end
  end

  def record_reuse(%Entry{} = entry, attrs \\ %{}) do
    attrs = normalize_attrs(attrs)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Multi.new()
    |> Multi.update(:entry, Entry.changeset(entry, %{hit_count: entry.hit_count + 1, last_hit_at: now}))
    |> Multi.insert(:event, fn %{entry: updated_entry} ->
      EntryEvent.changeset(%EntryEvent{}, %{
        entry_id: updated_entry.id,
        event_kind: "reused",
        reason_code: Map.get(attrs, :reason_code, "cache_hit"),
        workflow_run_id: Map.get(attrs, :workflow_run_id),
        span_id: Map.get(attrs, :span_id),
        metadata: Map.get(attrs, :metadata, %{})
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{entry: updated_entry, event: event}} -> {:ok, %{entry: updated_entry, event: event}}
      {:error, _op, reason, _changes} -> {:error, reason}
    end
  end

  def record_writeback_rejection(%Entry{} = entry, attrs) do
    attrs = normalize_attrs(attrs)

    Multi.new()
    |> Multi.update(
      :entry,
      Entry.changeset(entry, %{
        status: "writeback_rejected",
        state_reason_code: Map.get(attrs, :reason_code, "writeback_rejected")
      })
    )
    |> Multi.insert(:event, fn %{entry: updated_entry} ->
      EntryEvent.changeset(%EntryEvent{}, %{
        entry_id: updated_entry.id,
        event_kind: "writeback_rejected",
        reason_code: Map.get(attrs, :reason_code, "writeback_rejected"),
        workflow_run_id: Map.get(attrs, :workflow_run_id),
        span_id: Map.get(attrs, :span_id),
        metadata: Map.get(attrs, :metadata, %{})
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{entry: updated_entry, event: event}} -> {:ok, %{entry: updated_entry, event: event}}
      {:error, _op, reason, _changes} -> {:error, reason}
    end
  end

  def record_writeback_rejection(attrs) when is_map(attrs) or is_list(attrs) do
    attrs =
      attrs
      |> normalize_attrs()
      |> Map.put(:status, "writeback_rejected")
      |> Map.put_new(:scope_kind, "tenant_shared")
      |> Map.put_new(:scope_reason, "writeback_rejected")
      |> Map.put_new(:answer_payload, %{})
      |> Map.put_new(:evidence_refs, %{})
      |> Map.put_new(:state_reason_code, Map.get(attrs, :reason_code))
      |> maybe_put_policy_fingerprint()
      |> Map.put_new(:metadata, %{})

    Multi.new()
    |> Multi.insert(:entry, Entry.changeset(%Entry{}, attrs))
    |> Multi.insert(:event, fn %{entry: entry} ->
      EntryEvent.changeset(%EntryEvent{}, %{
        entry_id: entry.id,
        event_kind: "writeback_rejected",
        reason_code: Map.get(attrs, :reason_code, "writeback_rejected"),
        workflow_run_id: Map.get(attrs, :origin_run_id) || Map.get(attrs, :workflow_run_id),
        span_id: Map.get(attrs, :origin_span_id) || Map.get(attrs, :span_id),
        metadata: Map.get(attrs, :metadata, %{})
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{entry: entry, event: event}} -> {:ok, %{entry: entry, event: event}}
      {:error, _op, reason, _changes} -> {:error, reason}
    end
  end

  def list_events(entry_id) do
    EntryEvent
    |> where([event], event.entry_id == ^entry_id)
    |> order_by([event], asc: event.inserted_at, asc: event.id)
    |> Repo.all()
  end

  def mark_stale(%Entry{} = entry, reason_code, metadata \\ %{}),
    do: Invalidation.mark_stale(entry, reason_code, metadata)

  def invalidate_entry(%Entry{} = entry, reason_code, metadata \\ %{}),
    do: Invalidation.invalidate_entry(entry, reason_code, metadata)

  def invalidate_by_prompt(attrs), do: Invalidation.invalidate_by_prompt(attrs)
  def invalidate_by_policy(attrs), do: Invalidation.invalidate_by_policy(attrs)
  def invalidate_by_source(attrs), do: Invalidation.invalidate_by_source(attrs)
  def revoke_entry(%Entry{} = entry, metadata \\ %{}), do: Invalidation.revoke_entry(entry, metadata)

  defp require_tenant(%{tenant_id: tenant_id}) when is_binary(tenant_id) and tenant_id != "", do: :ok
  defp require_tenant(_attrs), do: {:bypass, :tenant_scope_missing}

  defp require_lane(%{lane_key: lane_key}) when is_binary(lane_key) and lane_key != "", do: :ok
  defp require_lane(_attrs), do: {:bypass, :lane_not_registered}

  defp require_query_text(%{query_text: query_text}) when is_binary(query_text) and query_text != "", do: :ok
  defp require_query_text(_attrs), do: {:bypass, :query_text_missing}

  defp maybe_put_policy_fingerprint(attrs) do
    cond do
      Map.has_key?(attrs, :policy_fingerprint) ->
        attrs

      prompt_policy = Map.get(attrs, :prompt_policy) ->
        Map.put(attrs, :policy_fingerprint, Compatibility.policy_fingerprint(prompt_policy))

      true ->
        attrs
    end
  end

  defp normalize_attrs(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_attrs()
  defp normalize_attrs(attrs) when is_list(attrs), do: attrs |> Enum.into(%{}) |> normalize_attrs()
  defp normalize_attrs(attrs) when is_map(attrs), do: Map.new(attrs, &normalize_pair/1)
  defp normalize_attrs(_attrs), do: %{}

  defp normalize_pair({key, value}) when is_binary(key), do: {Map.get(@known_attr_keys, key, key), value}
  defp normalize_pair({key, value}), do: {key, value}
end
