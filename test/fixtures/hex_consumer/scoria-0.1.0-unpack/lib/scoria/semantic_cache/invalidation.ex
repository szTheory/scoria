defmodule Scoria.SemanticCache.Invalidation do
  @moduledoc """
  Transactional stale and invalidation state transitions for semantic-cache entries.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Scoria.Repo
  alias Scoria.SemanticCache.Entry
  alias Scoria.SemanticCache.EntryEvent

  @invalid_reason_codes ~w(
    prompt_version_mismatch
    policy_mismatch
    source_fingerprint_mismatch
    operator_revoked
  )

  def mark_stale(%Entry{} = entry, reason_code, metadata \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Multi.new()
    |> Multi.update(:entry, Entry.changeset(entry, %{status: "stale", state_reason_code: reason_code}))
    |> Multi.insert(:event, fn %{entry: updated_entry} ->
      event_changeset(updated_entry, "stale", reason_code, now, metadata)
    end)
    |> transact_single()
  end

  def invalidate_entry(%Entry{} = entry, reason_code, metadata \\ %{}) when reason_code in @invalid_reason_codes do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Multi.new()
    |> Multi.update(
      :entry,
      Entry.changeset(entry, %{
        status: "invalidated",
        state_reason_code: reason_code,
        invalidated_at: now
      })
    )
    |> Multi.insert(:event, fn %{entry: updated_entry} ->
      event_changeset(updated_entry, "invalidated", reason_code, now, metadata)
    end)
    |> transact_single()
  end

  def invalidate_by_prompt(attrs) do
    attrs = Map.new(attrs)

    invalidate_many(
      from(
        entry in Entry,
        where:
          entry.tenant_id == ^Map.fetch!(attrs, :tenant_id) and
            entry.lane_key == ^Map.fetch!(attrs, :lane_key) and
            entry.prompt_ref == ^Map.fetch!(attrs, :prompt_ref) and
            entry.prompt_version != ^Map.fetch!(attrs, :prompt_version)
      ),
      "prompt_version_mismatch",
      Map.get(attrs, :metadata, %{})
    )
  end

  def invalidate_by_policy(attrs) do
    attrs = Map.new(attrs)

    invalidate_many(
      from(
        entry in Entry,
        where:
          entry.tenant_id == ^Map.fetch!(attrs, :tenant_id) and
            entry.lane_key == ^Map.fetch!(attrs, :lane_key) and
            entry.policy_fingerprint == ^Map.fetch!(attrs, :policy_fingerprint)
      ),
      "policy_mismatch",
      Map.get(attrs, :metadata, %{})
    )
  end

  def invalidate_by_source(attrs) do
    attrs = Map.new(attrs)

    invalidate_many(
      from(
        entry in Entry,
        where:
          entry.tenant_id == ^Map.fetch!(attrs, :tenant_id) and
            entry.lane_key == ^Map.fetch!(attrs, :lane_key) and
            entry.source_fingerprint == ^Map.fetch!(attrs, :source_fingerprint)
      ),
      "source_fingerprint_mismatch",
      Map.get(attrs, :metadata, %{})
    )
  end

  def revoke_entry(%Entry{} = entry, metadata \\ %{}), do: invalidate_entry(entry, "operator_revoked", metadata)

  defp invalidate_many(query, reason_code, metadata) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    active_query = from(entry in query, where: entry.status in ["active", "stale"])

    Multi.new()
    |> Multi.run(:entries, fn repo, _changes ->
      {:ok, repo.all(active_query)}
    end)
    |> Multi.run(:update_entries, fn repo, %{entries: entries} ->
      ids = Enum.map(entries, & &1.id)

      if ids == [] do
        {:ok, {0, nil}}
      else
        {:ok,
         repo.update_all(
           from(entry in Entry, where: entry.id in ^ids),
           set: [status: "invalidated", state_reason_code: reason_code, invalidated_at: now]
         )}
      end
    end)
    |> Multi.run(:events, fn repo, %{entries: entries} ->
      insert_events(repo, entries, "invalidated", reason_code, now, metadata)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{entries: entries, update_entries: {count, _}}} -> {:ok, %{entries: entries, count: count}}
      {:error, _op, reason, _changes} -> {:error, reason}
    end
  end

  defp insert_events(_repo, [], _kind, _reason_code, _now, _metadata), do: {:ok, 0}

  defp insert_events(repo, entries, event_kind, reason_code, now, metadata) do
    rows =
      Enum.map(entries, fn entry ->
        %{
          id: Ecto.UUID.generate(),
          entry_id: entry.id,
          event_kind: event_kind,
          reason_code: reason_code,
          workflow_run_id: nil,
          span_id: nil,
          metadata: metadata,
          inserted_at: now,
          updated_at: now
        }
      end)

    case repo.insert_all(EntryEvent, rows) do
      {count, _} -> {:ok, count}
    end
  end

  defp event_changeset(entry, event_kind, reason_code, now, metadata) do
    EntryEvent.changeset(%EntryEvent{}, %{
      entry_id: entry.id,
      event_kind: event_kind,
      reason_code: reason_code,
      metadata: Map.put_new(metadata, "transitioned_at", DateTime.to_iso8601(now))
    })
  end

  defp transact_single(multi) do
    multi
    |> Repo.transaction()
    |> case do
      {:ok, %{entry: entry}} -> {:ok, entry}
      {:error, _op, reason, _changes} -> {:error, reason}
    end
  end
end
