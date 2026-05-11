defmodule Scoria.SRE do
  @moduledoc """
  Public Phase 7 context boundary for runtime governance, alerts, incidents,
  and audit export.

  Later Seismograph plans can fill in persistence and runtime enforcement behind
  these entrypoints without widening the rest of the codebase's call sites.
  """

  alias Scoria.SRE.{AlertSink, AuditSink}

  @type attrs :: map()

  def create_budget_policy(attrs), do: not_implemented(:create_budget_policy, attrs)

  def reserve_usage(attrs), do: not_implemented(:reserve_usage, attrs)

  def reconcile_usage(reservation, attrs), do: not_implemented(:reconcile_usage, %{reservation: reservation, attrs: attrs})

  def record_breaker_trip(attrs), do: not_implemented(:record_breaker_trip, attrs)

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
