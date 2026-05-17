defmodule Scoria.Workflows.Runtime do
  @moduledoc """
  Executes bounded workflow steps under supervision and persists stable outcomes.
  """

  alias Decimal, as: D
  alias Scoria.Identity
  alias Scoria.SRE.BudgetEngine
  alias Scoria.SRE.BreakerRegistry
  alias Scoria.SRE.Telemetry
  alias Scoria.Workflows

  @default_timeout 5_000

  def execute_step(step_id, opts \\ []) do
    with {:ok, _claimed} <- Workflows.claim_step(step_id) do
      step = Workflows.get_step!(step_id)
      run = Workflows.get_run!(step.run_id)
      timeout = Keyword.get(opts, :timeout, @default_timeout)
      handler = resolve_handler(step, opts)
      budget_context = runtime_context(run, Keyword.get(opts, :budget_context, %{}))
      breaker_context = build_breaker_context(step, run, Keyword.get(opts, :breaker_context, %{}))

      case reserve_budget(step, run, budget_context) do
        {:error, envelope} ->
          emit_budget_rejection(step, run, budget_context, envelope)
          Workflows.fail_step(step.id, normalize_budget_envelope(envelope))

        {:ok, reservation_context} ->
          case BreakerRegistry.run(breaker_context, fn -> execute_handler(handler, step, run, timeout) end) do
            {:ok, {:completed, result, duration_ms}} ->
              reconcile_budget(reservation_context, budget_context, result, "completed")
              emit_runtime_telemetry(step, run, budget_context, "completed", duration_ms, result)
              Workflows.complete_step(step.id, attach_budget_evidence(normalize_payload(result), reservation_context))

            {:ok, {:waiting_for_approval, approval_attrs, duration_ms}} ->
              reconcile_budget(reservation_context, budget_context, %{}, "waiting_for_approval")
              emit_runtime_telemetry(step, run, budget_context, "waiting_for_approval", duration_ms, %{})
              Workflows.mark_waiting_for_approval(run.id, step.id, Map.new(approval_attrs))

            {:ok, {:handoff, handoff_attrs, duration_ms}} ->
              reconcile_budget(reservation_context, budget_context, %{}, "handoff")
              emit_runtime_telemetry(step, run, budget_context, "handoff", duration_ms, %{})
              handle_handoff(run, step, Map.new(handoff_attrs))

            {:error, {:handler_error, reason, duration_ms}} ->
              reconcile_budget(reservation_context, budget_context, %{}, "handler_error")
              emit_runtime_telemetry(step, run, budget_context, "handler_error", duration_ms, %{})
              Workflows.fail_step(step.id, attach_budget_evidence(%{"reason" => inspect(reason)}, reservation_context))

            {:ok, {:other, other, duration_ms}} ->
              reconcile_budget(reservation_context, budget_context, other, "completed")
              emit_runtime_telemetry(step, run, budget_context, "completed", duration_ms, other)

              Workflows.complete_step(
                step.id,
                attach_budget_evidence(normalize_payload(other), reservation_context),
                run_status: "running"
              )

            {:error, {:timeout, duration_ms}} ->
              reconcile_budget(reservation_context, budget_context, %{}, "timeout")
              emit_runtime_telemetry(step, run, budget_context, "timeout", duration_ms, %{})
              Workflows.fail_step(step.id, attach_budget_evidence(%{"reason" => "timeout"}, reservation_context))

            {:error, {:execution_failed, reason, duration_ms}} ->
              reconcile_budget(reservation_context, budget_context, %{}, "execution_failed")
              emit_runtime_telemetry(step, run, budget_context, "execution_failed", duration_ms, %{})
              Workflows.fail_step(step.id, attach_budget_evidence(%{"reason" => inspect(reason)}, reservation_context))

            {:error, %{status: :breaker_open} = envelope} ->
              reconcile_breaker_open_budget(reservation_context, envelope)
              emit_runtime_breaker_open(step, run, budget_context, envelope)
              Workflows.fail_step(step.id, attach_budget_evidence(normalize_budget_envelope(envelope), reservation_context))
          end
      end
    end
  end

  defp execute_handler(handler, step, run, timeout) do
    started_at = System.monotonic_time()

    task =
      Task.Supervisor.async_nolink(Scoria.Workflow.TaskSupervisor, fn ->
        invoke_handler(handler, step, run)
      end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, {:ok, result}} -> {:ok, {:completed, result, elapsed_ms(started_at)}}
      {:ok, {:waiting_for_approval, approval_attrs}} -> {:ok, {:waiting_for_approval, approval_attrs, elapsed_ms(started_at)}}
      {:ok, {:handoff, handoff_attrs}} -> {:ok, {:handoff, handoff_attrs, elapsed_ms(started_at)}}
      {:ok, {:error, reason}} -> {:error, {:handler_error, reason, elapsed_ms(started_at)}}
      {:ok, other} -> {:ok, {:other, other, elapsed_ms(started_at)}}
      nil -> {:error, {:timeout, elapsed_ms(started_at)}}
      {:exit, reason} -> {:error, {:execution_failed, reason, elapsed_ms(started_at)}}
    end
  end

  defp reserve_budget(step, run, budget_context) do
    if budget_required?(budget_context) do
      identity = runtime_identity(run, budget_context)

      BudgetEngine.reserve_step(%{
        tenant_id: identity.tenant_id,
        actor_id: identity.actor_id,
        run_id: run.id,
        step_id: step.id,
        step_sequence: step.sequence,
        trace_id: Map.get(budget_context, :trace_id),
        resource: budget_resource(budget_context, "workflow_steps"),
        reason_code: Map.get(budget_context, :reason_code, "workflow_step"),
        estimated_units: estimated_units(budget_context),
        integration_kind: Map.get(budget_context, :integration_kind, "workflow"),
        provider_ref: Map.get(budget_context, :provider_ref),
        tool_ref: Map.get(budget_context, :tool_ref),
        metadata:
          budget_context
          |> Map.get(:metadata, %{})
          |> Map.put_new("workflow_step_count", step.sequence)
          |> Map.put_new("consecutive_failures", Map.get(run.error_envelope || %{}, "consecutive_failures", 0))
      })
    else
      {:ok, nil}
    end
  end

  defp reconcile_budget(nil, _budget_context, _result, _outcome), do: :ok

  defp reconcile_budget(%{reservation: reservation}, budget_context, result, outcome) do
    BudgetEngine.reconcile_usage(reservation, %{
      actual_units: actual_units(budget_context, result, outcome),
      metadata: %{"outcome" => outcome}
    })
  end

  defp reconcile_breaker_open_budget(nil, _envelope), do: :ok

  defp reconcile_breaker_open_budget(reservation_context, envelope) do
    BudgetEngine.reconcile_breaker_open(
      reservation_context,
      Map.take(envelope, [:breaker_key, :reason_code, :status])
    )
  end

  defp handle_handoff(run, step, attrs) do
    delegated_role_id = Map.fetch!(attrs, "delegated_role_id")
    projected_context = Map.get(attrs, "projected_context", %{})

    if Enum.any?(Map.keys(projected_context), &(&1 in ["transcript", "provider_session", "secrets", "socket_state"])) do
      Workflows.fail_step(step.id, %{"reason" => "unsafe_projected_context"})
    else
      {:ok, _handoff} =
        Workflows.create_handoff(step, %{
          delegated_role_id: delegated_role_id,
          capability_tags: List.wrap(Map.get(attrs, "capability_tags", [])),
          handoff_input: Map.get(attrs, "handoff_input", %{}),
          result_summary: %{},
          status: "pending"
        })

      {:ok, _child_step} =
        Workflows.create_step(run.id, %{
          parent_step_id: step.id,
          sequence: Workflows.next_step_sequence(run.id),
          kind: "handoff",
          role_id: delegated_role_id,
          status: "queued",
          handoff_input: Map.get(attrs, "handoff_input", %{}),
          projected_context: projected_context
        })

      Workflows.complete_step(step.id, %{"handoff" => delegated_role_id}, run_status: "running")
    end
  end

  defp resolve_handler(step, opts) do
    cond do
      handler = Keyword.get(opts, :handler) ->
        handler

      is_map_keyword = Keyword.get(opts, :handlers) ->
        Map.fetch!(is_map_keyword, step.kind)

      true ->
        handlers = Application.get_env(:scoria, :workflow_runtime_handlers, %{})
        Map.fetch!(handlers, step.kind)
    end
  end

  defp invoke_handler({module, function}, step, run), do: apply(module, function, [step, run])
  defp invoke_handler({module, function, extra_args}, step, run), do: apply(module, function, [step, run | List.wrap(extra_args)])
  defp invoke_handler(handler, step, _run) when is_function(handler, 1), do: handler.(step)
  defp invoke_handler(handler, step, run) when is_function(handler, 2), do: handler.(step, run)

  defp build_breaker_context(step, run, breaker_context) do
    breaker_context
    |> Map.new()
    |> Map.put_new(:run_id, run.id)
    |> Map.put_new(:trace_id, step.id)
  end

  defp normalize_payload(%{} = payload), do: payload
  defp normalize_payload(payload), do: %{"result" => payload}

  defp attach_budget_evidence(envelope, nil), do: envelope

  defp attach_budget_evidence(envelope, %{reservation: reservation}) do
    Map.put(envelope, "budget_reservation_id", reservation.id)
  end

  defp normalize_budget_envelope(envelope) do
    envelope
    |> Enum.into(%{}, fn {key, value} -> {to_string(key), normalize_budget_value(value)} end)
  end

  defp normalize_budget_value(%D{} = value), do: D.to_string(value)
  defp normalize_budget_value(value), do: value

  defp budget_required?(budget_context) do
    Map.get(budget_context, :estimated_cost_usd) ||
      Map.get(budget_context, :estimated_tokens) ||
      Map.get(budget_context, :sensitive_tool) ||
      Map.get(budget_context, :estimated_units)
  end

  defp budget_resource(budget_context, default) do
    cond do
      Map.get(budget_context, :resource) -> Map.get(budget_context, :resource)
      Map.get(budget_context, :estimated_cost_usd) -> "cost_usd"
      Map.get(budget_context, :estimated_tokens) -> "token_in"
      Map.get(budget_context, :sensitive_tool) -> "tool_calls"
      true -> default
    end
  end

  defp estimated_units(budget_context) do
    cond do
      Map.get(budget_context, :estimated_units) -> Map.get(budget_context, :estimated_units)
      Map.get(budget_context, :estimated_cost_usd) -> Map.get(budget_context, :estimated_cost_usd)
      Map.get(budget_context, :estimated_tokens) -> Map.get(budget_context, :estimated_tokens)
      Map.get(budget_context, :sensitive_tool) -> 1
      true -> 1
    end
  end

  defp actual_units(_budget_context, _result, outcome) when outcome in ["timeout", "execution_failed", "handler_error"], do: 0

  defp actual_units(budget_context, result, _outcome) do
    cond do
      is_map(result) && Map.has_key?(result, :actual_units) -> Map.fetch!(result, :actual_units)
      is_map(result) && Map.has_key?(result, "actual_units") -> Map.fetch!(result, "actual_units")
      is_map(result) && Map.has_key?(result, :actual_cost_usd) -> Map.fetch!(result, :actual_cost_usd)
      is_map(result) && Map.has_key?(result, "actual_cost_usd") -> Map.fetch!(result, "actual_cost_usd")
      true -> estimated_units(budget_context)
    end
  end

  defp emit_runtime_telemetry(step, run, budget_context, outcome, duration_ms, result) do
    attrs =
      base_runtime_attrs(step, run, budget_context, outcome)
      |> Map.put(:duration_ms, duration_ms)
      |> Map.put(:success, outcome in ["completed", "waiting_for_approval", "handoff"])

    Telemetry.emit_latency(attrs)
    Telemetry.emit_tool_reliability(attrs)
    maybe_emit_budget(attrs, budget_context, outcome, result)
  end

  defp emit_runtime_breaker_open(step, run, budget_context, envelope) do
    attrs =
      base_runtime_attrs(step, run, budget_context, "breaker_open")
      |> Map.merge(%{
        breaker_key: Map.get(envelope, :breaker_key),
        state: "open",
        threshold: 1,
        trip_count: 1,
        duration_ms: 0,
        success: false
      })

    Telemetry.emit_latency(attrs)
    Telemetry.emit_tool_reliability(attrs)
    Telemetry.emit_breaker_state(attrs)
    maybe_emit_budget(attrs, budget_context, "breaker_open", %{})
  end

  defp emit_budget_rejection(step, run, budget_context, envelope) do
    attrs =
      base_runtime_attrs(step, run, budget_context, Map.get(envelope, :reason_code, "budget_rejected"))
      |> Map.put(:success, false)

    maybe_emit_budget(attrs, budget_context, "budget_rejected", %{})
  end

  defp base_runtime_attrs(step, run, budget_context, outcome) do
    budget_context = runtime_context(run, budget_context)
    identity = runtime_identity(run, budget_context)

    %{
      actor_id: identity.actor_id,
      tenant_id: identity.tenant_id || "system",
      session_id: identity.session_id,
      subject_kind: "workflow_step",
      policy_key: Map.get(budget_context, :policy_key, "workflow:#{step.kind}"),
      reason_code: outcome,
      trace_id: Map.get(budget_context, :trace_id, step.id),
      run_id: run.id,
      tool_name: step.kind,
      integration_kind: Map.get(budget_context, :integration_kind, "workflow"),
      provider: Map.get(budget_context, :provider),
      model: Map.get(budget_context, :model)
    }
  end

  defp runtime_context(run, attrs) do
    attrs = Map.new(attrs)
    identity = runtime_identity(run, attrs)
    runtime_defaults = run_runtime_defaults(run)

    attrs
    |> maybe_put_runtime_field(:provider, runtime_defaults.provider)
    |> maybe_put_runtime_field(:model, runtime_defaults.model)
    |> maybe_put_runtime_field(:policy_key, runtime_defaults.policy_key)
    |> maybe_put_runtime_field(:prompt_ref, runtime_defaults.prompt_ref)
    |> maybe_put_runtime_field(:prompt_version, runtime_defaults.prompt_version)
    |> maybe_put_runtime_field(:prompt_policy, runtime_defaults.prompt_policy)
    |> Map.put(:actor_id, identity.actor_id)
    |> Map.put(:tenant_id, identity.tenant_id)
    |> Map.put(:session_id, identity.session_id)
    |> Map.put(:identity, Identity.to_map(identity))
  end

  defp runtime_identity(run, attrs) do
    root_identity =
      Identity.normalize(%{
        actor_id: run.actor_id,
        tenant_id: run.tenant_id,
        session_id: run.session_id,
        metadata: run.metadata
      })

    overlay_identity = Identity.normalize(attrs)

    %Identity{
      root_identity
      | actor_id: root_identity.actor_id || overlay_identity.actor_id,
        tenant_id: root_identity.tenant_id || overlay_identity.tenant_id,
        session_id: root_identity.session_id || overlay_identity.session_id
    }
  end

  defp maybe_emit_budget(attrs, budget_context, outcome, result) do
    if budget_required?(budget_context) do
      actual = actual_units(budget_context, result, outcome)
      estimated = estimated_units(budget_context)
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

  defp elapsed_ms(started_at) do
    System.monotonic_time()
    |> Kernel.-(started_at)
    |> System.convert_time_unit(:native, :millisecond)
  end

  defp run_runtime_defaults(run) do
    metadata = Map.get(run.metadata || %{}, "runtime", %{})

    %{
      provider: Map.get(metadata, "provider"),
      model: Map.get(metadata, "model"),
      policy_key: Map.get(metadata, "policy_key"),
      prompt_ref: Map.get(metadata, "prompt_ref"),
      prompt_version: Map.get(metadata, "prompt_version"),
      prompt_policy: Map.get(metadata, "prompt_policy")
    }
  end

  defp maybe_put_runtime_field(attrs, _key, nil), do: attrs

  defp maybe_put_runtime_field(attrs, key, value) do
    Map.put_new(attrs, key, value)
  end
end
