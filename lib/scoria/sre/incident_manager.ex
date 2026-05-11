defmodule Scoria.SRE.IncidentManager do
  @moduledoc """
  Routes alert envelopes into durable incidents, alert rows, and append-only
  incident events.
  """

  import Ecto.Query, warn: false

  alias Decimal, as: D
  alias Ecto.Multi
  alias Scoria.Repo
  alias Scoria.SRE.{AlertEvent, Incident, IncidentEvent}

  def record_alert_event(envelope) when is_map(envelope) do
    envelope = normalize_envelope(envelope)

    Multi.new()
    |> Multi.run(:incident, fn repo, _changes ->
      {:ok, get_or_create_incident(repo, envelope)}
    end)
    |> Multi.run(:alert_event, fn repo, %{incident: {incident, status}} ->
      {:ok, create_alert_event(repo, incident, status, envelope)}
    end)
    |> Multi.run(:incident_event, fn repo, %{incident: {incident, _status}, alert_event: alert_event} ->
      {:ok, append_incident_event_record(repo, incident, alert_event, envelope)}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{incident: {incident, _status}, alert_event: alert_event, incident_event: incident_event}} ->
        {:ok, %{incident: incident, alert_event: alert_event, incident_event: incident_event}}

      {:error, _operation, value, _changes} ->
        {:error, value}
    end
  end

  def open_incident(attrs) when is_map(attrs) do
    attrs = normalize_envelope(attrs)

    Multi.new()
    |> Multi.run(:incident, fn repo, _changes ->
      {:ok, get_or_create_incident(repo, attrs)}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{incident: {incident, _status}}} -> {:ok, incident}
      {:error, _operation, value, _changes} -> {:error, value}
    end
  end

  def append_incident_event(%Incident{} = incident, attrs) when is_map(attrs) do
    attrs = normalize_envelope(attrs)

    Multi.new()
    |> Multi.run(:incident_event, fn repo, _changes ->
      {:ok, append_standalone_incident_event(repo, incident, attrs)}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{incident_event: incident_event}} -> {:ok, incident_event}
      {:error, _operation, value, _changes} -> {:error, value}
    end
  end

  defp get_or_create_incident(repo, envelope) do
    incident_key = incident_key(envelope)
    tenant_id = Map.fetch!(envelope, :tenant_id)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    route = route(envelope)

    case repo.get_by(Incident, tenant_id: tenant_id, incident_key: incident_key) do
      nil ->
        attrs =
          %{
            tenant_id: tenant_id,
            incident_key: incident_key,
            severity: route.severity,
            status: "open",
            summary: summary(envelope),
            routing_class: route.routing_class,
            dedupe_key: incident_key,
            first_seen_at: now,
            last_seen_at: now,
            workflow_run_id: Map.get(envelope, :workflow_run_id),
            trace_id: Map.get(envelope, :trace_id),
            evidence_summary: evidence_summary(envelope),
            metadata: incident_metadata(envelope)
          }

        incident =
          %Incident{}
          |> Incident.changeset(attrs)
          |> repo.insert!()

        {incident, :new}

      %Incident{} = incident ->
        updated_incident =
          incident
          |> Incident.changeset(%{
            last_seen_at: now,
            severity: max_severity(incident.severity, route.severity),
            routing_class: max_routing_class(incident.routing_class, route.routing_class),
            workflow_run_id: Map.get(envelope, :workflow_run_id, incident.workflow_run_id),
            trace_id: Map.get(envelope, :trace_id, incident.trace_id),
            evidence_summary: merge_maps(incident.evidence_summary, evidence_summary(envelope)),
            metadata: merge_maps(incident.metadata, incident_metadata(envelope))
          })
          |> repo.update!()

        {updated_incident, :deduped}
    end
  end

  defp create_alert_event(repo, incident, status, envelope) do
    %AlertEvent{}
    |> AlertEvent.changeset(%{
      tenant_id: incident.tenant_id,
      incident_id: incident.id,
      incident_key: incident.incident_key,
      reason_code: Map.fetch!(envelope, :reason_code),
      severity: route(envelope).severity,
      status: if(status == :new, do: "new", else: "deduped"),
      measured_value: decimal_value(Map.get(envelope, :measured_value, 0)),
      threshold_value: decimal_value(Map.get(envelope, :threshold_value, 0)),
      scorer_version_ref: Map.get(envelope, :scorer_version),
      baseline_version_ref: Map.get(envelope, :baseline_version),
      workflow_run_id: Map.get(envelope, :workflow_run_id),
      trace_id: Map.get(envelope, :trace_id),
      evidence_refs: evidence_summary(envelope),
      metadata: alert_metadata(envelope)
    })
    |> repo.insert!()
  end

  defp append_incident_event_record(repo, incident, alert_event, envelope) do
    %IncidentEvent{}
    |> IncidentEvent.changeset(%{
      tenant_id: incident.tenant_id,
      incident_id: incident.id,
      alert_event_id: alert_event.id,
      incident_key: incident.incident_key,
      event_type: "alert_linked",
      reason_code: Map.fetch!(envelope, :reason_code),
      actor_ref: Map.get(envelope, :actor_ref),
      workflow_run_id: Map.get(envelope, :workflow_run_id),
      trace_id: Map.get(envelope, :trace_id),
      evidence_refs: evidence_summary(envelope),
      metadata: alert_metadata(envelope)
    })
    |> repo.insert!()
  end

  defp append_standalone_incident_event(repo, incident, attrs) do
    %IncidentEvent{}
    |> IncidentEvent.changeset(%{
      tenant_id: incident.tenant_id,
      incident_id: incident.id,
      incident_key: incident.incident_key,
      event_type: Map.get(attrs, :event_type, "note_added"),
      reason_code: Map.get(attrs, :reason_code, "incident_event"),
      actor_ref: Map.get(attrs, :actor_ref),
      workflow_run_id: Map.get(attrs, :workflow_run_id, incident.workflow_run_id),
      trace_id: Map.get(attrs, :trace_id, incident.trace_id),
      evidence_refs: evidence_summary(attrs),
      metadata: alert_metadata(attrs)
    })
    |> repo.insert!()
  end

  defp normalize_envelope(envelope) do
    envelope
    |> Enum.into(%{}, fn {key, value} -> {normalize_key(key), value} end)
    |> Map.put_new(:tenant_id, "system")
    |> Map.put_new(:subject_kind, "workflow")
    |> Map.put_new(:window_bucket, "global")
  end

  @envelope_keys %{
    "actor_ref" => :actor_ref,
    "baseline_version" => :baseline_version,
    "fast_burn" => :fast_burn,
    "incident_key" => :incident_key,
    "measured_value" => :measured_value,
    "policy_key" => :policy_key,
    "reason_code" => :reason_code,
    "routing_class" => :routing_class,
    "scorer_version" => :scorer_version,
    "severity" => :severity,
    "subject_kind" => :subject_kind,
    "summary" => :summary,
    "tenant_id" => :tenant_id,
    "threshold_value" => :threshold_value,
    "trace_id" => :trace_id,
    "window_bucket" => :window_bucket,
    "workflow_run_id" => :workflow_run_id
  }

  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key), do: Map.get(@envelope_keys, key, key)

  defp incident_key(envelope) do
    Map.get_lazy(envelope, :incident_key, fn ->
      [
        Map.get(envelope, :tenant_id, "system"),
        Map.get(envelope, :subject_kind, "workflow"),
        Map.get(envelope, :policy_key, "policy"),
        Map.fetch!(envelope, :reason_code),
        Map.get(envelope, :window_bucket, "global")
      ]
      |> Enum.join(":")
    end)
  end

  defp route(envelope) do
    reason_code = Map.get(envelope, :reason_code)
    fast_burn = Map.get(envelope, :fast_burn, false)
    breaker_trip = reason_code in ["breaker_open", "breaker_trip"]
    baseline_regression = reason_code in ["ci_baseline_dip", "quality_regression", "cost_regression"]

    cond do
      breaker_trip or fast_burn ->
        %{severity: "critical", routing_class: "page"}

      baseline_regression ->
        %{severity: "warning", routing_class: "review"}

      Map.get(envelope, :severity) in ["critical", :critical] ->
        %{severity: "critical", routing_class: Map.get(envelope, :routing_class, "page")}

      true ->
        %{severity: "warning", routing_class: Map.get(envelope, :routing_class, "review")}
    end
  end

  defp summary(envelope) do
    Map.get(envelope, :summary) ||
      "#{Map.get(envelope, :policy_key, "policy")} #{Map.get(envelope, :reason_code, "alert")}"
  end

  defp evidence_summary(envelope) do
    %{
      "policy_key" => Map.get(envelope, :policy_key),
      "trace_id" => Map.get(envelope, :trace_id),
      "workflow_run_id" => Map.get(envelope, :workflow_run_id),
      "scorer_version" => Map.get(envelope, :scorer_version),
      "baseline_version" => Map.get(envelope, :baseline_version)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end

  defp incident_metadata(envelope) do
    %{
      "reason_code" => Map.get(envelope, :reason_code),
      "severity" => route(envelope).severity,
      "routing_class" => route(envelope).routing_class
    }
    |> Map.merge(
      envelope
      |> Map.take([:policy_key, :subject_kind, :window_bucket, :scorer_version, :baseline_version])
      |> Enum.into(%{}, fn {key, value} -> {to_string(key), value} end)
    )
  end

  defp alert_metadata(envelope) do
    envelope
    |> Map.take([
      :policy_key,
      :subject_kind,
      :window_bucket,
      :routing_class,
      :severity,
      :scorer_version,
      :baseline_version
    ])
    |> Enum.into(%{}, fn {key, value} -> {to_string(key), value} end)
  end

  defp decimal_value(%D{} = value), do: value
  defp decimal_value(value) when is_integer(value), do: D.new(value)
  defp decimal_value(value) when is_float(value), do: D.from_float(value)
  defp decimal_value(value) when is_binary(value), do: D.new(value)
  defp decimal_value(nil), do: D.new(0)

  defp max_severity("critical", _other), do: "critical"
  defp max_severity(_current, "critical"), do: "critical"
  defp max_severity(current, _other) when current in ["warning", "info"], do: current
  defp max_severity(_current, other), do: other

  defp max_routing_class("page", _other), do: "page"
  defp max_routing_class(_current, "page"), do: "page"
  defp max_routing_class(current, _other) when is_binary(current), do: current
  defp max_routing_class(_current, other), do: other

  defp merge_maps(left, right) do
    Map.merge(left || %{}, right || %{})
  end
end
