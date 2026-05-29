defmodule Scoria.SRE do
  @moduledoc """
  Public Phase 7 context boundary for runtime governance, alerts, incidents,
  and audit export.

  Later Seismograph plans can fill in persistence and runtime enforcement behind
  these entrypoints without widening the rest of the codebase's call sites.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Scoria.Observe.Redactor
  alias Scoria.Repo
  alias Scoria.SRE.{AlertEvent, AlertSink, AuditOutboxEvent, AuditSink, Incident, IncidentEvent}
  alias Scoria.SRE.{BreakerTrip, BudgetPolicy, BudgetReservation, IncidentManager}

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
    |> maybe_insert_reservation_audit(attrs)
    |> Repo.transaction()
    |> case do
      {:ok, %{reservation: reservation} = changes} ->
        maybe_emit_audit_telemetry(changes[:audit_outbox_event])
        {:ok, reservation}

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
    IncidentManager.record_alert_event(envelope)
  end

  def open_incident(attrs), do: IncidentManager.open_incident(attrs)

  def append_incident_event(incident, attrs), do: IncidentManager.append_incident_event(incident, attrs)

  def create_audit_outbox_event(envelope) when is_map(envelope) do
    normalized = normalize_audit_envelope(envelope)

    Repo.transaction(fn repo ->
      changeset =
        %AuditOutboxEvent{}
        |> AuditOutboxEvent.changeset(normalized)

      case repo.insert(changeset) do
        {:ok, audit_outbox_event} -> audit_outbox_event
        {:error, changeset} -> repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, audit_outbox_event} ->
        emit_audit_outbox_telemetry(audit_outbox_event)
        {:ok, audit_outbox_event}

      {:error, %Ecto.Changeset{} = changeset} ->
        case get_existing_audit_outbox_event(normalized, changeset) do
          %AuditOutboxEvent{} = audit_outbox_event -> {:ok, audit_outbox_event}
          nil -> {:error, changeset}
        end

      {:error, value} ->
        {:error, value}
    end
  end

  def deliver_notification(target, envelope),
    do: not_implemented(:deliver_notification, %{target: target, envelope: envelope})

  def remote_invocation_evidence(_run_id), do: %{approvals: []}

  def insert_audit_outbox_event(repo, envelope) when is_map(envelope) do
    changeset =
      %AuditOutboxEvent{}
      |> AuditOutboxEvent.changeset(normalize_audit_envelope(envelope))

    case repo.insert(changeset) do
      {:ok, audit_outbox_event} -> audit_outbox_event
      {:error, failed_changeset} -> repo.rollback(failed_changeset)
    end
  end

  def emit_audit_outbox_telemetry(%AuditOutboxEvent{} = audit_outbox_event) do
    :telemetry.execute(
      [:scoria, :sre, :audit_outbox, :created],
      %{count: 1},
      %{
        event_type: audit_outbox_event.event_type,
        policy_class: audit_outbox_event.policy_class,
        tenant_id: audit_outbox_event.tenant_id,
        trace_id: audit_outbox_event.trace_id,
        workflow_run_id: audit_outbox_event.workflow_run_id,
        step_id: audit_outbox_event.step_id
      }
    )

    :ok
  end

  def audit_sink do
    resolve_sink!(:sre_audit_sink, AuditSink, AuditSink.Noop)
  end

  def alert_sink do
    resolve_sink!(:sre_alert_sink, AlertSink, AlertSink.Noop)
  end

  def get_incident!(id), do: Repo.get!(Incident, id)

  def get_incident_event!(id), do: Repo.get!(IncidentEvent, id)

  def get_alert_event!(id), do: Repo.get!(AlertEvent, id)

  def list_incident_events(incident_id) do
    IncidentEvent
    |> where([event], event.incident_id == ^incident_id)
    |> order_by([event], asc: event.inserted_at)
    |> Repo.all()
  end

  def list_alert_events(incident_id) do
    AlertEvent
    |> where([event], event.incident_id == ^incident_id)
    |> order_by([event], asc: event.inserted_at)
    |> Repo.all()
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

  defp maybe_insert_reservation_audit(multi, attrs) do
    case Map.get(attrs, :audit_envelope) || Map.get(attrs, "audit_envelope") do
      nil ->
        multi

      audit_envelope ->
        Multi.run(multi, :audit_outbox_event, fn repo, %{reservation: reservation} ->
          envelope =
            audit_envelope
            |> normalize_envelope()
            |> Map.put_new(:workflow_run_id, reservation.workflow_run_id)
            |> Map.put_new(:trace_id, reservation.trace_id)
            |> Map.update(:metadata, %{}, &Map.put(normalize_envelope(&1), "budget_reservation_id", reservation.id))

          {:ok, insert_audit_outbox_event(repo, envelope)}
        end)
    end
  end

  defp maybe_emit_audit_telemetry(nil), do: :ok
  defp maybe_emit_audit_telemetry(audit_outbox_event), do: emit_audit_outbox_telemetry(audit_outbox_event)

  defp normalize_audit_envelope(envelope) do
    redacted_refs = build_redacted_refs(envelope)
    metadata = build_audit_metadata(envelope)

    %{
      tenant_id: Map.get(envelope, :tenant_id) || Map.get(envelope, "tenant_id") || "system",
      event_type: Map.get(envelope, :event_type) || Map.fetch!(envelope, "event_type"),
      policy_class: Map.get(envelope, :policy_class) || Map.get(envelope, "policy_class") || "policy_sensitive",
      sink_status: Map.get(envelope, :sink_status) || Map.get(envelope, "sink_status") || "pending",
      dedupe_key:
        Map.get(envelope, :dedupe_key) ||
          Map.get(envelope, "dedupe_key") ||
          build_audit_dedupe_key(envelope),
      payload_hash: Map.get(envelope, :payload_hash) || Map.get(envelope, "payload_hash") || hash_payload(redacted_refs, metadata),
      pending_at:
        Map.get(envelope, :pending_at) || Map.get(envelope, "pending_at") ||
          DateTime.utc_now() |> DateTime.truncate(:microsecond),
      sent_at: Map.get(envelope, :sent_at) || Map.get(envelope, "sent_at"),
      attempt_count: Map.get(envelope, :attempt_count) || Map.get(envelope, "attempt_count") || 0,
      actor_ref: Map.get(envelope, :actor_ref) || Map.get(envelope, "actor_ref") || Map.get(envelope, :actor_id) || Map.get(envelope, "actor_id"),
      workflow_run_id: Map.get(envelope, :workflow_run_id) || Map.get(envelope, "workflow_run_id"),
      step_id: Map.get(envelope, :step_id) || Map.get(envelope, "step_id"),
      trace_id: Map.get(envelope, :trace_id) || Map.get(envelope, "trace_id"),
      redacted_refs: redacted_refs,
      metadata: metadata,
      replay_disposition: enum_string(Map.get(envelope, :replay_disposition) || Map.get(envelope, "replay_disposition")),
      replay_reason_code: Map.get(envelope, :replay_reason_code) || Map.get(envelope, "replay_reason_code"),
      source_run_id: Map.get(envelope, :source_run_id) || Map.get(envelope, "source_run_id"),
      source_checkpoint_id: Map.get(envelope, :source_checkpoint_id) || Map.get(envelope, "source_checkpoint_id"),
      source_step_id: Map.get(envelope, :source_step_id) || Map.get(envelope, "source_step_id"),
      source_approval_id: Map.get(envelope, :source_approval_id) || Map.get(envelope, "source_approval_id"),
      source_audit_outbox_event_id:
        Map.get(envelope, :source_audit_outbox_event_id) ||
          Map.get(envelope, "source_audit_outbox_event_id"),
      args_fingerprint: Map.get(envelope, :args_fingerprint) || Map.get(envelope, "args_fingerprint"),
      policy_key: Map.get(envelope, :policy_key) || Map.get(envelope, "policy_key"),
      executed_live: Map.get(envelope, :executed_live) || Map.get(envelope, "executed_live") || false,
      replay_idempotency_key:
        Map.get(envelope, :replay_idempotency_key) || Map.get(envelope, "replay_idempotency_key")
    }
  end

  defp get_existing_audit_outbox_event(envelope, changeset) do
    if unique_dedupe_error?(changeset) do
      Repo.get_by(AuditOutboxEvent,
        tenant_id: envelope.tenant_id,
        dedupe_key: envelope.dedupe_key
      )
    end
  end

  defp unique_dedupe_error?(changeset) do
    Enum.any?(changeset.errors, fn
      {:dedupe_key, {_message, metadata}} -> metadata[:constraint] == :unique
      _ -> false
    end)
  end

  defp enum_string(value) when is_atom(value), do: Atom.to_string(value)
  defp enum_string(value), do: value

  defp build_redacted_refs(envelope) do
    envelope
    |> normalize_envelope()
    |> Map.take([
      :approval_id,
      :alert_event_id,
      :args,
      :arguments,
      :tool_name,
      :tool_ref,
      :decision,
      :access_decision,
      :access_reason,
      :session_id,
      :policy_key,
      :reason,
      :reason_code,
      :run_id,
      :step_id,
      :target,
      "approval_id",
      "alert_event_id",
      "args",
      "arguments",
      "tool_name",
      "tool_ref",
      "decision",
      "access_decision",
      "access_reason",
      "session_id",
      "policy_key",
      "reason",
      "reason_code",
      "run_id",
      "step_id",
      "target"
    ])
    |> Enum.into(%{}, fn {key, value} -> {to_string(key), normalize_ref_value(value)} end)
    |> Redactor.redact()
    |> stringify_nested_keys()
  end

  defp build_audit_metadata(envelope) do
    envelope
    |> normalize_envelope()
    |> Map.drop([
      :actor_id,
      :actor_ref,
      :alert_event_id,
      :approval_id,
      :args,
      :arguments,
      :attempt_count,
      :dedupe_key,
      :event_type,
      :payload_hash,
      :pending_at,
      :policy_class,
      :raw_args,
      :redacted_refs,
      :sent_at,
      :sink_status,
      :step_id,
      :tenant_id,
      :trace_id,
      :workflow_run_id,
      :session_id,
      "actor_id",
      "actor_ref",
      "alert_event_id",
      "approval_id",
      "args",
      "arguments",
      "attempt_count",
      "dedupe_key",
      "event_type",
      "payload_hash",
      "pending_at",
      "policy_class",
      "raw_args",
      "redacted_refs",
      "sent_at",
      "sink_status",
      "step_id",
      "tenant_id",
      "trace_id",
      "workflow_run_id",
      "session_id"
    ])
    |> Enum.into(%{}, fn {key, value} -> {to_string(key), normalize_ref_value(value)} end)
    |> stringify_nested_keys()
  end

  defp build_audit_dedupe_key(envelope) do
    [
      Map.get(envelope, :event_type) || Map.get(envelope, "event_type"),
      Map.get(envelope, :tenant_id) || Map.get(envelope, "tenant_id"),
      Map.get(envelope, :approval_id) || Map.get(envelope, "approval_id"),
      Map.get(envelope, :trace_id) || Map.get(envelope, "trace_id"),
      Map.get(envelope, :access_decision) || Map.get(envelope, "access_decision")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(":")
  end

  defp hash_payload(redacted_refs, metadata) do
    payload =
      %{
        redacted_refs: redacted_refs,
        metadata: metadata
      }
      |> Jason.encode!()

    "sha256:" <> Base.encode16(:crypto.hash(:sha256, payload), case: :lower)
  end

  defp build_policy_snapshot(nil, snapshot), do: Map.new(snapshot || %{})

  defp build_policy_snapshot(policy, snapshot) do
    (snapshot || %{})
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

  defp normalize_ref_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp normalize_ref_value(value), do: value

  defp stringify_nested_keys(%_{} = value), do: value

  defp stringify_nested_keys(map) when is_map(map) do
    Enum.into(map, %{}, fn {key, value} -> {to_string(key), stringify_nested_keys(value)} end)
  end

  defp stringify_nested_keys(list) when is_list(list), do: Enum.map(list, &stringify_nested_keys/1)
  defp stringify_nested_keys(value), do: value

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
