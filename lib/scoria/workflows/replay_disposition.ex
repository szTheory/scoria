defmodule Scoria.Workflows.ReplayDisposition do
  @moduledoc """
  Resolves seam-level replay outcomes from local classification, source evidence,
  replay approval context, and replay overrides.
  """

  @type disposition :: :execute_live | :historical_stub | :blocked

  @exact_match_fields ~w(tool_id args_fingerprint subject_ref required_scopes grant_state policy_key)a
  @authority_expanding_markers ~w(scope escalation re-auth reauth)
  @effectful_classes Scoria.MCP.Classification.action_classes()

  @spec resolve(map(), map(), map(), map(), map()) :: {disposition(), map()}
  def resolve(run, seam, source_evidence, approval_context, override_context) do
    run = normalize_map(run)
    seam = normalize_map(seam)
    source_evidence = normalize_map(source_evidence)
    approval_context = normalize_map(approval_context)
    override_context = normalize_map(override_context)

    cond do
      replay_mode?(run) == false ->
        {:execute_live, evidence(:execute_live, "run_not_in_replay_mode", seam, source_evidence, true)}

      authority_expanding?(seam) ->
        {:blocked, evidence(:blocked, "authority_expanding_change", seam, source_evidence, false)}

      pure_local?(seam) ->
        {:execute_live, evidence(:execute_live, "local_safe_to_rerun", seam, source_evidence, true)}

      exact_source_match?(seam, source_evidence) ->
        {:historical_stub, evidence(:historical_stub, "exact_source_match", seam, source_evidence, false)}

      live_override_requested?(seam, override_context) and live_override_ready?(seam, approval_context) ->
        {:execute_live,
         evidence(
           :execute_live,
           "live_override_approved",
           seam,
           source_evidence,
           true,
           replay_idempotency_key(run, seam)
         )}

      live_override_requested?(seam, override_context) ->
        {:blocked,
         evidence(
           :blocked,
           "live_override_requires_policy_and_replay_approval",
           seam,
           source_evidence,
           false
         )}

      effectful_or_remote?(seam) ->
        {:blocked, evidence(:blocked, "missing_source_evidence", seam, source_evidence, false)}

      true ->
        {:execute_live, evidence(:execute_live, "local_safe_to_rerun", seam, source_evidence, true)}
    end
  end

  defp replay_mode?(run), do: Map.get(run, :execution_mode) == "replay"

  defp pure_local?(seam) do
    Map.get(seam, :local_classification) in [:pure, :local, :in_memory]
  end

  defp authority_expanding?(seam) do
    classification = Map.get(seam, :local_classification)
    authority_expanding = Map.get(seam, :authority_expanding)
    grant_state = Map.get(seam, :grant_state)

    classification in [:scope_escalation, :reauth, :re_auth, :authority_expanding] or
      grant_state in ["reauth_required", "scope_escalation_required"] or
      authority_expanding_text?(authority_expanding)
  end

  defp authority_expanding_text?(value) when is_binary(value) do
    normalized = String.downcase(value)
    Enum.any?(@authority_expanding_markers, &String.contains?(normalized, &1))
  end

  defp authority_expanding_text?(_), do: false

  defp effectful_or_remote?(seam) do
    approval_sensitive? = truthy?(Map.get(seam, :approval_sensitive))
    action_class = Map.get(seam, :action_class)
    risk_level = Map.get(seam, :risk_level)
    local_classification = Map.get(seam, :local_classification)

    approval_sensitive? or
      action_class in Enum.drop(@effectful_classes, 1) or
      risk_level in ["high", "destructive"] or
      local_classification in [:read, :remote_read, :write, :exec, :admin, :remote]
  end

  defp exact_source_match?(seam, source_evidence) do
    has_required_source_lineage?(source_evidence) and
      Enum.all?(@exact_match_fields, fn field ->
        canonical(Map.get(seam, field)) == canonical(Map.get(source_evidence, field))
      end)
  end

  defp has_required_source_lineage?(source_evidence) do
    Enum.all?(
      [:source_run_id, :source_checkpoint_id, :source_step_id, :source_audit_outbox_event_id],
      &(present?(Map.get(source_evidence, &1)))
    )
  end

  defp live_override_requested?(seam, override_context) do
    allowlist =
      Map.get(override_context, :live_tool_allowlist) ||
        Map.get(override_context, "live_tool_allowlist") ||
        []

    Map.get(seam, :tool_id) in allowlist
  end

  defp live_override_ready?(seam, approval_context) do
    policy_ok? = truthy?(Map.get(approval_context, :current_policy_ok?))
    replay_approved? = truthy?(Map.get(approval_context, :replay_approved?))

    policy_ok? and (not truthy?(Map.get(seam, :approval_sensitive)) or replay_approved?)
  end

  defp evidence(disposition, reason_code, seam, source_evidence, executed_live, replay_idempotency_key \\ nil) do
    %{
      replay_disposition: disposition,
      replay_reason_code: reason_code,
      source_run_id: Map.get(source_evidence, :source_run_id),
      source_checkpoint_id: Map.get(source_evidence, :source_checkpoint_id),
      source_step_id: Map.get(source_evidence, :source_step_id),
      source_approval_id: Map.get(source_evidence, :source_approval_id),
      source_audit_outbox_event_id: Map.get(source_evidence, :source_audit_outbox_event_id),
      args_fingerprint: Map.get(source_evidence, :args_fingerprint) || Map.get(seam, :args_fingerprint),
      subject_ref: Map.get(source_evidence, :subject_ref) || Map.get(seam, :subject_ref),
      required_scopes:
        Map.get(source_evidence, :required_scopes) || Map.get(seam, :required_scopes) || [],
      policy_key: Map.get(source_evidence, :policy_key) || Map.get(seam, :policy_key),
      executed_live: executed_live,
      replay_idempotency_key: replay_idempotency_key
    }
  end

  defp replay_idempotency_key(run, seam) do
    raw =
      [
        Map.get(run, :id),
        Map.get(seam, :tool_id),
        Map.get(seam, :args_fingerprint),
        Map.get(seam, :subject_ref),
        Map.get(seam, :policy_key)
      ]
      |> Enum.map(&to_string_or_empty/1)
      |> Enum.join(":")

    "replay:" <> Base.encode16(:crypto.hash(:sha256, raw), case: :lower)
  end

  defp normalize_map(%_{} = value), do: value |> Map.from_struct() |> normalize_map()
  defp normalize_map(value) when is_map(value), do: Map.new(value, fn {k, v} -> {normalize_key(k), v} end)
  defp normalize_map(_), do: %{}

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp normalize_key(key), do: key

  defp canonical(value) when is_list(value), do: Enum.map(value, &canonical/1)
  defp canonical(value) when is_map(value), do: value |> normalize_map() |> Enum.sort()
  defp canonical(value), do: value

  defp present?(value), do: not is_nil(value) and value != ""

  defp truthy?(value), do: value in [true, "true", 1, "1"]

  defp to_string_or_empty(nil), do: ""
  defp to_string_or_empty(value) when is_binary(value), do: value
  defp to_string_or_empty(value), do: inspect(value)
end
