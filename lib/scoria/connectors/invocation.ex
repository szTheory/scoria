defmodule Scoria.Connectors.Invocation do
  @moduledoc """
  Replay-aware connector invocation that gates remote tool execution before
  reaching the MCP executor.
  """

  alias Scoria.MCP.Classification
  alias Scoria.MCP.Executor
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.Workflows
  alias Scoria.Workflows.ReplayDisposition
  alias Scoria.Workflows.Run

  @type replay_blocked :: {:error, map()}
  @type invocation_result :: {:ok, map()} | replay_blocked | term()

  @spec invoke(module(), map(), map(), keyword()) :: invocation_result()
  def invoke(tool_module, args, context, opts \\ []) do
    context = normalize_map(context)
    # Site 4 (D-05): resolved BEFORE `build_seam/2` and therefore before
    # `replay_resolution/5` below -- a connector-routed tool's replay
    # decision is made from THIS seam, so the classification must exist
    # before that decision is computed, not merely before the executor is
    # reached. Routes through the same `Classification.resolve/2` the
    # executor uses (single implementation, two entry points); if `context`
    # already carries a resolved `%Classification{}` this is a no-op and no
    # telemetry fires a second time -- `Executor.execute/4`'s own
    # `resolve_classification/2` reuses it unchanged below.
    context = resolve_tool_classification(tool_module, context)
    run = load_run(Map.get(context, :run) || Map.get(context, :run_id))
    seam = build_seam(context, opts)
    source_evidence = normalize_map(Map.get(context, :source_evidence, %{}))
    approval_context = normalize_map(Map.get(context, :approval_context, %{}))
    override_context = override_context(run, context)

    case replay_resolution(run, seam, source_evidence, approval_context, override_context) do
      {:historical_stub, evidence} ->
        evidence = record_replay_seam(run, context, "connector.replay.stubbed", evidence)

        {:ok,
         %{
           status: :historical_stub,
           replay_disposition: :historical_stub,
           replay_reason_code: evidence.replay_reason_code,
           result: Map.get(source_evidence, :result) || Map.get(source_evidence, "result"),
           evidence: evidence
         }}

      {:blocked, evidence} ->
        evidence = record_replay_seam(run, context, "connector.replay.blocked", evidence)
        replay_blocked_response(evidence)

      {:execute_live, evidence} ->
        live_context = attach_replay_context(context, run, evidence)
        result = Executor.execute(tool_module, args, live_context, Keyword.get(opts, :timeout, 5_000))
        normalize_live_result(result, evidence)
    end
  end

  defp replay_resolution(nil, _seam, _source_evidence, _approval_context, _override_context),
    do: {:execute_live, %{replay_disposition: :execute_live, replay_reason_code: "live_run", executed_live: true}}

  defp replay_resolution(%Run{execution_mode: "replay"} = run, seam, source_evidence, approval_context, override_context),
    do: ReplayDisposition.resolve(run, seam, source_evidence, approval_context, override_context)

  defp replay_resolution(_run, _seam, _source_evidence, _approval_context, _override_context),
    do: {:execute_live, %{replay_disposition: :execute_live, replay_reason_code: "live_run", executed_live: true}}

  defp build_seam(context, opts) do
    defaults = Keyword.get(opts, :seam, %{})

    defaults
    |> Map.new()
    |> Map.put_new(:tool_id, Map.get(context, :tool_id) || Map.get(context, :tool_ref))
    # D-05/D-03: a new, parallel seam entry only -- the four pre-existing
    # `Map.put_new` lines directly below (action_class, risk_level,
    # approval_sensitive, local_classification) stay byte-identical.
    # `ReplayDisposition` never reads this key, so adding it cannot change
    # any disposition; it exists so the resolved classification survives
    # onto the seam a host may inspect.
    |> Map.put_new(:tool_classification, Map.get(context, :tool_classification))
    |> Map.put_new(:action_class, Map.get(context, :action_class, "read"))
    |> Map.put_new(:risk_level, Map.get(context, :risk_level, "low"))
    |> Map.put_new(:approval_sensitive, Map.get(context, :approval_sensitive, false))
    |> Map.put_new(:local_classification, Map.get(context, :local_classification, :read))
    |> Map.put_new(:args_fingerprint, Map.get(context, :args_fingerprint))
    |> Map.put_new(:subject_ref, Map.get(context, :subject_ref))
    |> Map.put_new(:required_scopes, Map.get(context, :required_scopes, []))
    |> Map.put_new(:grant_state, Map.get(context, :grant_state))
    |> Map.put_new(:policy_key, Map.get(context, :policy_key))
    |> Map.put_new(:authority_expanding, Map.get(context, :authority_expanding))
    |> Map.put_new(:remote_hint, Map.get(context, :remote_hint))
  end

  # Mirrors `Executor.resolve_classification/2`'s idempotence guard exactly
  # (match on the STRUCT, not mere key presence, per plan 56-03 Task 2): a
  # context already carrying a `%Classification{}` under `:tool_classification`
  # is returned unchanged with no second telemetry emission. Otherwise
  # resolves via the SAME `Classification.tool_declaration/1` +
  # `Classification.resolve/2` the executor uses -- no duplicated resolution
  # logic, only a duplicated telemetry-emission wrapper carrying this site's
  # own `site: :connector_invocation` discriminator.
  defp resolve_tool_classification(tool_module, context) do
    case Map.get(context, :tool_classification) do
      %Classification{} ->
        context

      _ ->
        declaration = Classification.tool_declaration(tool_module)
        resolved = Classification.resolve(declaration, context)
        maybe_emit_unclassified(declaration, tool_module, context)
        Map.put(context, :tool_classification, resolved)
    end
  end

  defp maybe_emit_unclassified(:none, tool_module, context) do
    try do
      :telemetry.execute(
        [:scoria, :class, :unclassified],
        %{},
        %{
          tool: tool_module,
          tool_ref: inspect(tool_module),
          trace_id: Map.get(context, :trace_id),
          step_id: Map.get(context, :step_id),
          site: :connector_invocation
        }
      )
    rescue
      _ -> :ok
    end
  end

  defp maybe_emit_unclassified({:ok, _declared}, _tool_module, _context), do: :ok

  defp attach_replay_context(context, %Run{execution_mode: "replay"} = run, evidence) do
    context
    |> Map.put(:run, run)
    |> Map.put(:replay_disposition, evidence.replay_disposition)
    |> Map.put(:replay_reason_code, evidence.replay_reason_code)
    |> Map.put(:replay_idempotency_key, evidence.replay_idempotency_key)
    |> Map.put(:source_run_id, evidence.source_run_id)
    |> Map.put(:source_checkpoint_id, evidence.source_checkpoint_id)
    |> Map.put(:source_step_id, evidence.source_step_id)
    |> Map.put(:source_approval_id, evidence.source_approval_id)
    |> Map.put(:source_audit_outbox_event_id, evidence.source_audit_outbox_event_id)
    |> Map.put(:args_fingerprint, evidence.args_fingerprint)
    |> Map.put(:policy_key, evidence.policy_key)
    |> Map.put(:executed_live, true)
  end

  defp attach_replay_context(context, _run, _evidence), do: context

  defp normalize_live_result({:ok, result}, evidence) do
    {:ok,
     %{
       status: :execute_live,
       replay_disposition: :execute_live,
       replay_reason_code: evidence.replay_reason_code,
       replay_idempotency_key: evidence.replay_idempotency_key,
       result: result
     }}
  end

  defp normalize_live_result(other, _evidence), do: other

  defp replay_blocked_response(evidence) do
    {:error,
     %{
       status: :replay_blocked,
       replay_disposition: :blocked,
       replay_reason_code: evidence.replay_reason_code,
       source_run_id: evidence.source_run_id,
       source_checkpoint_id: evidence.source_checkpoint_id,
       source_step_id: evidence.source_step_id,
       source_approval_id: evidence.source_approval_id,
       source_audit_outbox_event_id: evidence.source_audit_outbox_event_id,
       workflow_event_id: Map.get(evidence, :workflow_event_id),
       audit_outbox_event_id: Map.get(evidence, :audit_outbox_event_id)
     }}
  end

  defp record_replay_seam(%Run{} = run, context, event_type, evidence) do
    workflow_event_id =
      case maybe_append_workflow_event(context, event_type, evidence) do
        {:ok, event} -> event.id
        _ -> nil
      end

    audit_outbox_event_id =
      case SRE.create_audit_outbox_event(%{
             tenant_id: Map.get(context, :tenant_id) || run.tenant_id || "system",
             actor_id: Map.get(context, :actor_id) || run.actor_id,
             workflow_run_id: run.id,
             step_id: Map.get(context, :step_id),
             trace_id: Map.get(context, :trace_id),
             event_type: event_type,
             policy_class: "replay_execution",
             policy_key: evidence.policy_key,
             replay_disposition: evidence.replay_disposition,
             replay_reason_code: evidence.replay_reason_code,
             source_run_id: evidence.source_run_id,
             source_checkpoint_id: evidence.source_checkpoint_id,
             source_step_id: evidence.source_step_id,
             source_approval_id: evidence.source_approval_id,
             source_audit_outbox_event_id: evidence.source_audit_outbox_event_id,
             args_fingerprint: evidence.args_fingerprint,
             executed_live: false,
             metadata: %{"workflow_event_id" => workflow_event_id}
           }) do
        {:ok, event} -> event.id
        _ -> nil
      end

    Map.merge(evidence, %{workflow_event_id: workflow_event_id, audit_outbox_event_id: audit_outbox_event_id})
  end

  defp record_replay_seam(_run, _context, _event_type, evidence), do: evidence

  defp maybe_append_workflow_event(%{run_id: run_id, step_id: step_id}, event_type, evidence)
       when is_binary(run_id) and is_binary(step_id) do
    Workflows.append_event(run_id, step_id, %{
      event_type: event_type,
      payload: %{
        replay_disposition: evidence.replay_disposition,
        replay_reason_code: evidence.replay_reason_code,
        args_fingerprint: evidence.args_fingerprint
      },
      replay_disposition: Atom.to_string(evidence.replay_disposition),
      replay_reason_code: evidence.replay_reason_code
    })
  end

  defp maybe_append_workflow_event(_context, _event_type, _evidence), do: {:ok, nil}

  defp override_context(%Run{} = run, context) do
    Map.get(context, :override_context) ||
      Map.get(context, "override_context") ||
      Map.get(run.replay_overrides || %{}, "live_tool_allowlist", [])
      |> then(&%{live_tool_allowlist: &1})
  end

  defp override_context(_run, context) do
    Map.get(context, :override_context) || Map.get(context, "override_context") || %{}
  end

  defp load_run(%Run{} = run), do: run
  defp load_run(run_id) when is_binary(run_id), do: Repo.get(Run, run_id)
  defp load_run(_), do: nil

  defp normalize_map(%_{} = value), do: value |> Map.from_struct() |> normalize_map()
  defp normalize_map(value) when is_map(value), do: Map.new(value)
  defp normalize_map(_), do: %{}
end
