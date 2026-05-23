defmodule Scoria.MCP.Executor do
  @moduledoc """
  Executes MCP tools in an isolated Task with strict timeouts.
  Emits telemetry events for auditing.
  """

  alias Scoria.SRE.BudgetEngine
  alias Scoria.SRE.BreakerRegistry
  alias Scoria.SRE
  alias Scoria.SRE.Telemetry
  alias Scoria.Workflows.ReplayDisposition
  alias Scoria.Workflows.Run

  @doc """
  Executes a tool module with the given arguments and context.
  """
  def execute(tool_module, args, context, timeout \\ 5000) do
    context = canonical_context(context || %{})

    case replay_gate(tool_module, args, context) do
      {:continue, context} ->
        execute_live(tool_module, args, context, timeout)

      other ->
        other
    end
  end

  defp execute_live(tool_module, args, context, timeout) do

    with {:ok, access_context} <- maybe_capture_sensitive_mcp_access(tool_module, args, context),
         {:ok, reservation_context} <- reserve_budget(tool_module, args, access_context),
         {:ok, execution_context} <- ensure_policy_sensitive_invocation(tool_module, args, access_context, reservation_context) do
      metadata =
        access_context
        |> Map.merge(%{tool: tool_module, args: args})
        |> attach_budget_metadata(execution_context)
        |> Map.put_new(:tool_ref, inspect(tool_module))

      breaker_context =
        access_context
        |> Map.put_new(:tool_ref, inspect(tool_module))

      case BreakerRegistry.run(breaker_context, fn ->
             execute_tool(tool_module, args, access_context, timeout, metadata)
           end) do
        {:ok, {:completed, result, duration}} ->
          reconcile_budget(execution_context, access_context, result, "completed")
          emit_sre_telemetry(tool_module, access_context, "completed", duration, result)
          :telemetry.execute([:scoria, :tool, :completed], %{duration: duration}, metadata)
          result

        {:error, {:timeout, duration}} ->
          reconcile_budget(execution_context, access_context, %{}, "timeout")
          emit_sre_telemetry(tool_module, access_context, "timeout", duration, %{})
          :telemetry.execute([:scoria, :tool, :timeout], %{duration: duration}, metadata)
          {:error, :timeout}

        {:error, {:execution_failed, duration, reason}} ->
          reconcile_budget(execution_context, access_context, %{}, "execution_failed")
          emit_sre_telemetry(tool_module, access_context, "execution_failed", duration, %{})
          :telemetry.execute([:scoria, :tool, :failed], %{duration: duration}, Map.put(metadata, :reason, reason))
          {:error, :execution_failed}

        {:error, %{status: :breaker_open} = envelope} ->
          reconcile_budget(execution_context, access_context, %{}, "breaker_open")
          emit_breaker_open_telemetry(tool_module, access_context, envelope)
          :telemetry.execute([:scoria, :tool, :failed], %{duration: 0}, Map.put(metadata, :reason, :breaker_open))
          {:error, envelope}
      end
    else
        {:error, envelope} ->
          emit_access_denied_telemetry(tool_module, context, envelope)
          {:error, envelope}
    end
  end

  defp replay_gate(tool_module, _args, context) do
    case load_replay_run(context) do
      %Run{execution_mode: "replay"} = run ->
        seam = build_replay_seam(tool_module, context)
        source_evidence = Map.get(context, :source_evidence, %{})
        approval_context = Map.get(context, :approval_context, %{})
        override_context = Map.get(context, :override_context, run.replay_overrides || %{})

        case ReplayDisposition.resolve(run, seam, source_evidence, approval_context, override_context) do
          {:historical_stub, evidence} ->
            record_replay_audit(context, tool_module, evidence, "tool.replay.stubbed")

            {:ok,
             %{
               status: :historical_stub,
               replay_disposition: :historical_stub,
               replay_reason_code: evidence.replay_reason_code,
               result: Map.get(source_evidence, :result) || Map.get(source_evidence, "result")
             }}

          {:blocked, evidence} ->
            audit_id = record_replay_audit(context, tool_module, evidence, "tool.replay.blocked")

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
               audit_outbox_event_id: audit_id
             }}

          {:execute_live, evidence} ->
            {:continue,
             context
             |> Map.put(:replay_disposition, evidence.replay_disposition)
             |> Map.put(:replay_reason_code, evidence.replay_reason_code)
             |> Map.put(:replay_idempotency_key, evidence.replay_idempotency_key)
             |> Map.put(:source_run_id, evidence.source_run_id)
             |> Map.put(:source_checkpoint_id, evidence.source_checkpoint_id)
             |> Map.put(:source_step_id, evidence.source_step_id)
             |> Map.put(:source_approval_id, evidence.source_approval_id)
             |> Map.put(:source_audit_outbox_event_id, evidence.source_audit_outbox_event_id)
             |> Map.put(:args_fingerprint, evidence.args_fingerprint)
             |> Map.put(:executed_live, true)}
        end

      _ ->
        {:continue, context}
    end
  end

  defp load_replay_run(context) do
    case Map.get(context, :run) do
      %Run{} = run -> run
      _ -> nil
    end
  end

  defp build_replay_seam(tool_module, context) do
    %{
      local_classification: Map.get(context, :local_classification, :write),
      tool_id: Map.get(context, :tool_id, inspect(tool_module)),
      action_class: Map.get(context, :action_class, "write"),
      risk_level: Map.get(context, :risk_level, "high"),
      approval_sensitive: Map.get(context, :approval_sensitive, Map.get(context, :policy_sensitive, false)),
      args_fingerprint: Map.get(context, :args_fingerprint),
      subject_ref: Map.get(context, :subject_ref),
      required_scopes: Map.get(context, :required_scopes, []),
      grant_state: Map.get(context, :grant_state),
      policy_key: Map.get(context, :policy_key),
      authority_expanding: Map.get(context, :authority_expanding),
      remote_hint: Map.get(context, :remote_hint)
    }
  end

  defp record_replay_audit(context, tool_module, evidence, event_type) do
    case SRE.create_audit_outbox_event(%{
           tenant_id: Map.get(context, :tenant_id, "system"),
           actor_id: Map.get(context, :actor_id),
           workflow_run_id: Map.get(context, :run_id),
           step_id: Map.get(context, :step_id),
           trace_id: Map.get(context, :trace_id),
           event_type: event_type,
           policy_class: "replay_execution",
           policy_key: evidence.policy_key,
           tool_ref: inspect(tool_module),
           replay_disposition: evidence.replay_disposition,
           replay_reason_code: evidence.replay_reason_code,
           source_run_id: evidence.source_run_id,
           source_checkpoint_id: evidence.source_checkpoint_id,
           source_step_id: evidence.source_step_id,
           source_approval_id: evidence.source_approval_id,
           source_audit_outbox_event_id: evidence.source_audit_outbox_event_id,
           args_fingerprint: evidence.args_fingerprint,
           executed_live: false
         }) do
      {:ok, event} -> event.id
      _ -> nil
    end
  end

  defp execute_tool(tool_module, args, context, timeout, metadata) do
    :telemetry.execute([:scoria, :tool, :started], %{system_time: System.system_time()}, metadata)

    start_time = System.monotonic_time()

    task = Task.Supervisor.async_nolink(Scoria.MCP.TaskSupervisor, fn ->
      tool_module.execute(args, context)
    end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> {:ok, {:completed, result, System.monotonic_time() - start_time}}
      nil -> {:error, {:timeout, System.monotonic_time() - start_time}}
      {:exit, reason} -> {:error, {:execution_failed, System.monotonic_time() - start_time, reason}}
    end
  end

  defp reserve_budget(tool_module, args, context) do
    if budget_required?(context) do
      identity = context_identity(context)

      BudgetEngine.reserve_step(%{
        tenant_id: identity.tenant_id,
        actor_id: identity.actor_id,
        run_id: Map.get(context, :run_id),
        step_id: Map.get(context, :step_id),
        trace_id: Map.get(context, :trace_id),
        resource: budget_resource(context),
        reason_code: Map.get(context, :reason_code, "mcp.execute"),
        estimated_units: estimated_units(context),
        integration_kind: Map.get(context, :integration_kind, "tool"),
        tool_ref: inspect(tool_module),
        audit_envelope: policy_sensitive_audit_envelope(tool_module, args, context),
        metadata:
          context
          |> Map.get(:metadata, %{})
          |> Map.put_new("tool_hash", Integer.to_string(:erlang.phash2({tool_module, args})))
      })
    else
      {:ok, nil}
    end
  end

  defp reconcile_budget(nil, _context, _result, _outcome), do: :ok
  defp reconcile_budget(%{audit_outbox_event: _audit_outbox_event}, _context, _result, _outcome), do: :ok

  defp reconcile_budget(%{reservation: reservation}, _context, _result, "breaker_open") do
    BudgetEngine.reconcile_breaker_open(reservation)
  end

  defp reconcile_budget(%{reservation: reservation}, context, result, outcome) do
    BudgetEngine.reconcile_usage(reservation, %{
      actual_units: actual_units(context, result, outcome),
      metadata: %{"outcome" => outcome}
    })
  end

  defp attach_budget_metadata(metadata, nil), do: metadata
  defp attach_budget_metadata(metadata, %{audit_outbox_event: audit_outbox_event}), do: Map.put(metadata, :audit_outbox_event_id, audit_outbox_event.id)
  defp attach_budget_metadata(metadata, %{reservation: reservation}), do: Map.put(metadata, :budget_reservation_id, reservation.id)

  defp budget_required?(context) do
    Map.get(context, :estimated_cost_usd) ||
      Map.get(context, :estimated_tokens) ||
      Map.get(context, :estimated_units) ||
      Map.get(context, :sensitive_tool)
  end

  defp budget_resource(context) do
    cond do
      Map.get(context, :resource) -> Map.get(context, :resource)
      Map.get(context, :estimated_cost_usd) -> "cost_usd"
      Map.get(context, :estimated_tokens) -> "token_in"
      true -> "tool_calls"
    end
  end

  defp estimated_units(context) do
    cond do
      Map.get(context, :estimated_units) -> Map.get(context, :estimated_units)
      Map.get(context, :estimated_cost_usd) -> Map.get(context, :estimated_cost_usd)
      Map.get(context, :estimated_tokens) -> Map.get(context, :estimated_tokens)
      true -> 1
    end
  end

  defp actual_units(_context, _result, outcome) when outcome in ["timeout", "execution_failed"], do: 0

  defp actual_units(context, {:ok, result}, outcome), do: actual_units(context, result, outcome)

  defp actual_units(context, result, _outcome) do
    cond do
      is_map(result) && Map.has_key?(result, :actual_units) -> Map.fetch!(result, :actual_units)
      is_map(result) && Map.has_key?(result, "actual_units") -> Map.fetch!(result, "actual_units")
      is_map(result) && Map.has_key?(result, :actual_cost_usd) -> Map.fetch!(result, :actual_cost_usd)
      is_map(result) && Map.has_key?(result, "actual_cost_usd") -> Map.fetch!(result, "actual_cost_usd")
      true -> estimated_units(context)
    end
  end

  defp maybe_capture_sensitive_mcp_access(tool_module, args, context) do
    if Map.get(context, :sensitive_mcp_access) do
      decision = Map.get(context, :access_decision, "granted")
      identity = context_identity(context)

      with {:ok, audit_outbox_event} <-
             SRE.create_audit_outbox_event(%{
               tenant_id: identity.tenant_id,
               actor_id: identity.actor_id,
               workflow_run_id: Map.get(context, :run_id),
               step_id: Map.get(context, :step_id),
               trace_id: Map.get(context, :trace_id),
               event_type: "mcp.access.#{decision}",
               policy_class: "sensitive_mcp_access",
               access_decision: decision,
               access_reason: Map.get(context, :access_reason),
               policy_key: Map.get(context, :policy_key),
               tool_ref: inspect(tool_module),
               args: args,
               metadata: %{
                 "integration_kind" => Map.get(context, :integration_kind, "remote_mcp"),
                 "mcp_endpoint" => Map.get(context, :mcp_endpoint) || Map.get(context, :endpoint)
               }
             }) do
        case decision do
          "denied" ->
            {:error,
             %{
               status: :access_denied,
               reason_code: Map.get(context, :access_reason, "policy_denied"),
               audit_outbox_event_id: audit_outbox_event.id,
               trace_id: Map.get(context, :trace_id),
               policy_key: Map.get(context, :policy_key)
             }}

          _ ->
            {:ok, context}
        end
      end
    else
      {:ok, context}
    end
  end

  defp ensure_policy_sensitive_invocation(tool_module, args, context, nil) do
    if policy_sensitive_invocation?(context) do
      case SRE.create_audit_outbox_event(policy_sensitive_audit_envelope(tool_module, args, context)) do
        {:ok, audit_outbox_event} -> {:ok, %{audit_outbox_event: audit_outbox_event}}
        {:error, value} -> {:error, value}
      end
    else
      {:ok, nil}
    end
  end

  defp ensure_policy_sensitive_invocation(_tool_module, _args, _context, reservation_context),
    do: {:ok, reservation_context}

  defp policy_sensitive_invocation?(context) do
    Map.get(context, :policy_sensitive) || Map.get(context, :sensitive_tool)
  end

  defp policy_sensitive_audit_envelope(tool_module, args, context) do
    if policy_sensitive_invocation?(context) do
      identity = context_identity(context)

      %{
        tenant_id: identity.tenant_id,
        actor_id: identity.actor_id,
        workflow_run_id: Map.get(context, :run_id),
        step_id: Map.get(context, :step_id),
        trace_id: Map.get(context, :trace_id),
        event_type: "tool.invocation",
        policy_class: "policy_sensitive",
        dedupe_key: Map.get(context, :replay_idempotency_key),
        policy_key: Map.get(context, :policy_key),
        tool_ref: inspect(tool_module),
        args: args,
        replay_disposition: Map.get(context, :replay_disposition),
        replay_reason_code: Map.get(context, :replay_reason_code),
        source_run_id: Map.get(context, :source_run_id),
        source_checkpoint_id: Map.get(context, :source_checkpoint_id),
        source_step_id: Map.get(context, :source_step_id),
        source_approval_id: Map.get(context, :source_approval_id),
        source_audit_outbox_event_id: Map.get(context, :source_audit_outbox_event_id),
        args_fingerprint: Map.get(context, :args_fingerprint),
        executed_live: Map.get(context, :executed_live, false),
        replay_idempotency_key: Map.get(context, :replay_idempotency_key),
        metadata: %{
          "integration_kind" => Map.get(context, :integration_kind, "tool"),
          "tool_target" => Map.get(context, :tool_target),
          "breaker_target" => Map.get(context, :breaker_target)
        }
      }
    end
  end

  defp emit_sre_telemetry(tool_module, context, outcome, duration_native, result) do
    attrs =
      base_attrs(tool_module, context, outcome)
      |> Map.put(:duration_ms, System.convert_time_unit(duration_native, :native, :millisecond))
      |> Map.put(:success, outcome == "completed")

    Telemetry.emit_latency(attrs)
    Telemetry.emit_tool_reliability(attrs)
    maybe_emit_budget(attrs, context, outcome, result)
  end

  defp emit_breaker_open_telemetry(tool_module, context, envelope) do
    attrs =
      base_attrs(tool_module, context, "breaker_open")
      |> Map.merge(%{
        duration_ms: 0,
        success: false,
        breaker_key: Map.get(envelope, :breaker_key),
        state: "open",
        threshold: 1,
        trip_count: 1
      })

    Telemetry.emit_latency(attrs)
    Telemetry.emit_tool_reliability(attrs)
    Telemetry.emit_breaker_state(attrs)
    maybe_emit_budget(attrs, context, "breaker_open", %{})
  end

  defp emit_access_denied_telemetry(tool_module, context, %{status: :access_denied}) do
    attrs =
      base_attrs(tool_module, context, "access_denied")
      |> Map.put(:duration_ms, 0)
      |> Map.put(:success, false)

    Telemetry.emit_latency(attrs)
    Telemetry.emit_tool_reliability(attrs)
    maybe_emit_budget(attrs, context, "access_denied", %{})
  end

  defp emit_access_denied_telemetry(_tool_module, _context, _envelope), do: :ok

  defp base_attrs(tool_module, context, outcome) do
    context = canonical_context(context)
    identity = context_identity(context)

    %{
      actor_id: identity.actor_id,
      tenant_id: identity.tenant_id || "system",
      session_id: identity.session_id,
      subject_kind: "mcp_tool",
      policy_key: Map.get(context, :policy_key, inspect(tool_module)),
      reason_code: outcome,
      trace_id: Map.get(context, :trace_id),
      run_id: Map.get(context, :run_id),
      tool_name: tool_name(tool_module),
      integration_kind: Map.get(context, :integration_kind, "tool"),
      provider: Map.get(context, :provider),
      model: Map.get(context, :model)
    }
  end

  defp canonical_context(context) do
    context = Map.new(context)
    identity = Scoria.Identity.normalize(context)
    runtime = runtime_context(context)

    context
    |> maybe_put_runtime_field(:provider, Map.get(runtime, :provider))
    |> maybe_put_runtime_field(:model, Map.get(runtime, :model))
    |> maybe_put_runtime_field(:policy_key, Map.get(runtime, :policy_key))
    |> maybe_put_runtime_field(:prompt_ref, Map.get(runtime, :prompt_ref))
    |> maybe_put_runtime_field(:prompt_version, Map.get(runtime, :prompt_version))
    |> maybe_put_runtime_field(:prompt_policy, Map.get(runtime, :prompt_policy))
    |> Map.put(:actor_id, identity.actor_id)
    |> Map.put(:tenant_id, identity.tenant_id)
    |> Map.put(:session_id, identity.session_id)
    |> Map.put(:identity, Scoria.Identity.to_map(identity))
  end

  defp context_identity(context) do
    context
    |> Map.get(:identity, %{})
    |> Scoria.Identity.normalize()
  end

  defp tool_name(tool_module) do
    if function_exported?(tool_module, :name, 0), do: tool_module.name(), else: inspect(tool_module)
  end

  defp maybe_emit_budget(attrs, context, outcome, result) do
    if budget_required?(context) do
      actual = actual_units(context, result, outcome)
      estimated = estimated_units(context)
      burn_rate = numeric_ratio(actual, estimated)

      Telemetry.emit_cost(Map.put(attrs, :cost_usd, actual))

      Telemetry.emit_budget_burn(
        attrs
        |> Map.put(:burn_rate, burn_rate)
        |> Map.put(:budget_remaining, budget_remaining(actual, estimated))
        |> Map.put(:threshold, estimated)
      )
    end
  end

  defp numeric_ratio(actual, estimated) when is_number(actual) and is_number(estimated) and estimated != 0,
    do: actual / estimated

  defp numeric_ratio(_actual, _estimated), do: 0

  defp budget_remaining(actual, estimated) when is_number(actual) and is_number(estimated),
    do: max(estimated - actual, 0)

  defp budget_remaining(_actual, estimated), do: estimated || 0

  defp maybe_put_runtime_field(context, _key, nil), do: context

  defp maybe_put_runtime_field(context, key, value) do
    Map.put_new(context, key, value)
  end

  defp runtime_context(context) do
    runtime =
      Map.get(context, :runtime) ||
        Map.get(context, "runtime") ||
        Map.get(context, :runtime_defaults) ||
        Map.get(context, "runtime_defaults") ||
        %{}

    runtime = Map.new(runtime)

    %{
      provider: Map.get(runtime, :provider) || Map.get(runtime, "provider"),
      model: Map.get(runtime, :model) || Map.get(runtime, "model"),
      policy_key: Map.get(runtime, :policy_key) || Map.get(runtime, "policy_key"),
      prompt_ref: Map.get(runtime, :prompt_ref) || Map.get(runtime, "prompt_ref"),
      prompt_version: Map.get(runtime, :prompt_version) || Map.get(runtime, "prompt_version"),
      prompt_policy: Map.get(runtime, :prompt_policy) || Map.get(runtime, "prompt_policy")
    }
  end
end
