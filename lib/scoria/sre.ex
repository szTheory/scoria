defmodule Scoria.SRE do
  @moduledoc """
  Public Phase 7 context boundary for runtime governance, alerts, incidents,
  and audit export.

  Later Seismograph plans can fill in persistence and runtime enforcement behind
  these entrypoints without widening the rest of the codebase's call sites.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Scoria.Repo
  alias Scoria.SRE.{AlertSink, AuditSink}
  alias Scoria.SRE.{BreakerTrip, BudgetPolicy, BudgetReservation}

  @type attrs :: map()

  def list_budget_policies do
    BudgetPolicy
    |> order_by([policy], asc: policy.inserted_at)
    |> Repo.all()
  end

  def get_budget_policy!(id), do: Repo.get!(BudgetPolicy, id)

  def create_budget_policy(attrs) do
    %BudgetPolicy{}
    |> BudgetPolicy.changeset(attrs)
    |> Repo.insert()
  end

  def update_budget_policy(%BudgetPolicy{} = policy, attrs) do
    policy
    |> BudgetPolicy.changeset(attrs)
    |> Repo.update()
  end

  def delete_budget_policy(%BudgetPolicy{} = policy), do: Repo.delete(policy)

  def reserve_usage(attrs) do
    Multi.new()
    |> Multi.run(:policy, fn _repo, _changes -> {:ok, load_policy(attrs)} end)
    |> Multi.insert(:reservation, fn %{policy: policy} ->
      attrs
      |> normalize_reservation_attrs(policy)
      |> then(&BudgetReservation.changeset(%BudgetReservation{}, &1))
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{reservation: reservation}} -> {:ok, reservation}
      {:error, _operation, value, _changes} -> {:error, value}
    end
  end

  def reconcile_usage(%BudgetReservation{} = reservation, attrs) do
    Multi.new()
    |> Multi.update(:reservation, fn _changes ->
      reservation
      |> BudgetReservation.changeset(%{
        actual_units: Map.get(attrs, :actual_units, reservation.actual_units),
        status: "reconciled",
        reconciliation_status: Map.get(attrs, :reconciliation_status, "matched"),
        metadata: merge_metadata(reservation.metadata, Map.get(attrs, :metadata, %{}))
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{reservation: updated}} -> {:ok, updated}
      {:error, _operation, value, _changes} -> {:error, value}
    end
  end

  def release_usage(%BudgetReservation{} = reservation, attrs \\ %{}) do
    Multi.new()
    |> Multi.update(:reservation, fn _changes ->
      reservation
      |> BudgetReservation.changeset(%{
        status: "released",
        reconciliation_status: Map.get(attrs, :reconciliation_status, "released"),
        release_reason: Map.get(attrs, :release_reason),
        metadata: merge_metadata(reservation.metadata, Map.get(attrs, :metadata, %{}))
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{reservation: updated}} -> {:ok, updated}
      {:error, _operation, value, _changes} -> {:error, value}
    end
  end

  def record_breaker_trip(attrs) do
    Multi.new()
    |> Multi.insert(:breaker_trip, BreakerTrip.changeset(%BreakerTrip{}, attrs))
    |> Repo.transaction()
    |> case do
      {:ok, %{breaker_trip: breaker_trip}} -> {:ok, breaker_trip}
      {:error, _operation, value, _changes} -> {:error, value}
    end
  end

  def record_alert_event(envelope) when is_map(envelope) do
    envelope
    |> normalize_envelope()
    |> alert_sink().publish()
  end

  def open_incident(attrs), do: not_implemented(:open_incident, attrs)

  def append_incident_event(incident, attrs),
    do: not_implemented(:append_incident_event, %{incident: incident, attrs: attrs})

  def create_audit_outbox_event(envelope) when is_map(envelope) do
    envelope
    |> normalize_envelope()
    |> audit_sink().publish()
  end

  def deliver_notification(target, envelope),
    do: not_implemented(:deliver_notification, %{target: target, envelope: envelope})

  def audit_sink do
    resolve_sink!(:sre_audit_sink, AuditSink, AuditSink.Noop)
  end

  def alert_sink do
    resolve_sink!(:sre_alert_sink, AlertSink, AlertSink.Noop)
  end

  defp normalize_envelope(envelope), do: Map.new(envelope)

  defp not_implemented(action, attrs) do
    {:error, %{action: action, status: :not_implemented, attrs: attrs}}
  end

  defp load_policy(attrs) do
    case Map.get(attrs, :policy_id) || Map.get(attrs, "policy_id") do
      nil -> nil
      policy_id -> Repo.get(BudgetPolicy, policy_id)
    end
  end

  defp normalize_reservation_attrs(attrs, policy) do
    attrs
    |> Map.new()
    |> Map.put_new(:status, "reserved")
    |> Map.put_new(:reconciliation_status, "pending")
    |> Map.put_new(:policy_id, policy && policy.id)
    |> Map.put_new(:policy_key, policy && policy.policy_key)
    |> Map.put_new(:scope_key, policy && policy.scope_key)
    |> Map.put_new(:resource_kind, policy && policy.resource_kind)
    |> Map.put(
      :policy_snapshot,
      build_policy_snapshot(
        policy,
        Map.get(attrs, :policy_snapshot) || Map.get(attrs, "policy_snapshot")
      )
    )
  end

  defp build_policy_snapshot(nil, snapshot), do: Map.new(snapshot || %{})

  defp build_policy_snapshot(policy, snapshot) do
    snapshot
    |> Map.new()
    |> Map.put_new("policy_id", policy.id)
    |> Map.put_new("policy_key", policy.policy_key)
    |> Map.put_new("scope_key", policy.scope_key)
    |> Map.put_new("resource_kind", policy.resource_kind)
    |> Map.put_new("warn_threshold", decimal_to_string(policy.warn_threshold))
    |> Map.put_new("trip_threshold", decimal_to_string(policy.trip_threshold))
    |> Map.put_new("max_workflow_steps", policy.max_workflow_steps)
    |> Map.put_new("max_repeated_tool_calls", policy.max_repeated_tool_calls)
    |> Map.put_new("max_consecutive_failures", policy.max_consecutive_failures)
  end

  defp decimal_to_string(nil), do: nil
  defp decimal_to_string(decimal), do: Decimal.to_string(decimal)

  defp merge_metadata(left, right) do
    Map.merge(Map.new(left || %{}), Map.new(right || %{}))
  end

  defp resolve_sink!(config_key, behaviour, default) do
    module = Application.get_env(:scoria, config_key, default)

    if implements_behaviour?(module, behaviour) do
      module
    else
      raise ArgumentError, "#{inspect(module)} does not implement #{inspect(behaviour)}"
    end
  end

  defp implements_behaviour?(module, behaviour) when is_atom(module) do
    Code.ensure_loaded?(module) and
      behaviour in List.wrap(module.module_info(:attributes)[:behaviour])
  end

  defp implements_behaviour?(_module, _behaviour), do: false
end
