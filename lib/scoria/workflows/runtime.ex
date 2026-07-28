defmodule Scoria.Workflows.Runtime.StepFailureSignal do
  @moduledoc """
  Internal control-flow exception (D-03c) -- never surfaced to a host.

  `execute_step/2` wraps its whole outcome dispatch in one step-level parent
  span via `Scoria.Observe.span/4` (D-03c). `span/4` only marks a span
  `status_code: "ERROR"` when its `fun` genuinely raises/throws/exits --
  but a workflow handler's raise is ALREADY contained by
  `execute_handler/6`'s supervised `Task.Supervisor.async_nolink` boundary
  and converted into a controlled `{:error, {:execution_failed, ...}}`
  tuple long before it would reach `span/4`. Without this signal, the step
  span would always read "OK", even for a step that failed (SC#3).

  `execute_step/2` deliberately RAISES this struct (carrying the exact,
  already-computed `Workflows.fail_step/2` return value) for every branch
  that fails the step. `span/4`'s `rescue` clause catches it, marks the
  span ERROR with a real duration, and reraises it unchanged -- which
  `execute_step/2`'s own outer `rescue e in StepFailureSignal ->` clause
  then catches, returning `e.return_value` verbatim. The net effect: the
  step span is ERROR-marked and `execute_step/2`'s return value is
  byte-for-byte identical to what it was before this plan (T-53-12) --
  this struct never reaches any caller outside `execute_step/2`'s own
  frame, and unrelated exceptions (a genuine bug in `Workflows.*`, a DB
  error) are untouched by the typed rescue and propagate exactly as they
  did before this plan.
  """
  defexception [:return_value]

  @impl true
  def message(_exception), do: "internal step-failure signal (never surfaced outside execute_step/2)"
end

defmodule Scoria.Workflows.Runtime do
  @moduledoc """
  Executes bounded workflow steps under supervision and persists stable outcomes.
  """

  alias Decimal, as: D
  alias Scoria.Identity
  alias Scoria.Knowledge.Embedder
  alias Scoria.MCP.Classification
  alias Scoria.Observe
  alias Scoria.Observe.Guardrail
  alias Scoria.Observe.SpanKind
  alias Scoria.Runtime.Params
  alias Scoria.SemanticCache
  alias Scoria.SemanticCache.Compatibility
  alias Scoria.SemanticCache.Eligibility
  alias Scoria.SemanticCache.Invalidation
  alias Scoria.SRE.BudgetEngine
  alias Scoria.SRE.BreakerRegistry
  alias Scoria.SRE.Telemetry
  alias Scoria.Workflows
  alias Scoria.Workflows.Rails
  alias Scoria.Workflows.Runtime.StepFailureSignal

  @default_timeout 5_000
  @step_span_name "workflow_step"

  def prepare_semantic_fast_path(workflow_attrs) when is_map(workflow_attrs) do
    metadata = Map.get(workflow_attrs, :metadata, %{})
    runtime = Map.get(metadata, "runtime", %{})
    semantic_cache = Map.get(runtime, "semantic_cache")

    if is_map(semantic_cache) do
      query_text = semantic_query_text(metadata)
      prompt_policy = Map.get(runtime, "prompt_policy", %{})

      if is_nil(query_text) or String.trim(query_text) == "" do
          {:continue, put_semantic_cache_state(workflow_attrs, %{
             "eligibility_status" => "bypass",
             "eligibility_reason_code" => "query_text_missing",
             "lookup_status" => "bypass",
             "query_text" => query_text
           })}
      else
        facts = %{
          tenant_id: Map.get(workflow_attrs, :tenant_id),
          actor_id: Map.get(workflow_attrs, :actor_id),
          semantic_cache: semantic_cache,
          prompt_policy: prompt_policy,
          policy_key: Map.get(runtime, "policy_key"),
          prompt_ref: Map.get(runtime, "prompt_ref"),
          prompt_version: Map.get(runtime, "prompt_version"),
          provider: Map.get(runtime, "provider"),
          model: Map.get(runtime, "model"),
          personalized_tool: Map.get(semantic_cache, "personalized_tool"),
          write_side_step_present: Map.get(semantic_cache, "write_side_step_present")
        }

        case Eligibility.evaluate(facts) do
          {:bypass, reason_code} ->
            {:continue, put_semantic_cache_state(workflow_attrs, %{
               "eligibility_status" => "bypass",
               "eligibility_reason_code" => Atom.to_string(reason_code),
               "lookup_status" => "bypass",
               "query_text" => query_text
             })}

          {eligibility_status, attrs} when eligibility_status in [:eligible, :eligible_actor_scoped] ->
            lookup_attrs =
              attrs
              |> Map.put(:query_text, query_text)
              |> Map.put(:prompt_version, Map.get(runtime, "prompt_version"))
              |> Map.put(:policy_fingerprint, Compatibility.policy_fingerprint(prompt_policy))
              |> maybe_put_source_fingerprint(semantic_cache)
              |> maybe_put_query_embedding(query_text)

            case SemanticCache.lookup(lookup_attrs) do
              {:hit, entry} ->
                {:hit,
                 put_semantic_cache_state(workflow_attrs, %{
                   "eligibility_status" => Atom.to_string(eligibility_status),
                   "lookup_status" => "hit",
                   "entry_id" => entry.id,
                   "origin_run_id" => entry.origin_run_id,
                   "candidate_status" => entry.status,
                   "query_text" => query_text,
                   "scope_kind" => entry.scope_kind,
                   "scope_reason" => entry.scope_reason,
                   "tenant_id" => entry.tenant_id,
                   "actor_id" => entry.actor_id
                 }),
                 entry}

              {:reject, reason_code, entry} ->
                updated_entry =
                  case reason_code do
                    "entry_stale" ->
                      case Invalidation.mark_stale(entry, "freshness_window_elapsed", %{"phase" => "45"}) do
                        {:ok, stale_entry} -> stale_entry
                        _ -> entry
                      end

                    reason when reason in ["prompt_version_mismatch", "policy_mismatch", "source_fingerprint_mismatch"] ->
                      case Invalidation.invalidate_entry(entry, reason, %{"phase" => "45"}) do
                        {:ok, invalidated_entry} -> invalidated_entry
                        _ -> entry
                      end

                    _ ->
                      entry
                  end

                {:continue,
                 put_semantic_cache_state(workflow_attrs, %{
                   "eligibility_status" => Atom.to_string(eligibility_status),
                   "lookup_status" => "reject",
                   "lookup_reason_code" => reason_code,
                   "candidate_entry_id" => entry.id,
                   "candidate_status" => updated_entry.status,
                   "query_text" => query_text,
                   "scope_kind" => updated_entry.scope_kind,
                   "scope_reason" => updated_entry.scope_reason,
                   "tenant_id" => updated_entry.tenant_id,
                   "actor_id" => updated_entry.actor_id,
                   "lane_key" => attrs.lane_key,
                   "lane_module" => attrs.lane_module
                 })}

              :miss ->
                {:continue,
                 put_semantic_cache_state(workflow_attrs, %{
                   "eligibility_status" => Atom.to_string(eligibility_status),
                   "lookup_status" => "miss",
                   "query_text" => query_text,
                   "scope_kind" => Atom.to_string(attrs.scope_kind),
                   "scope_reason" => attrs.scope_reason,
                   "tenant_id" => attrs.tenant_id,
                   "actor_id" => attrs.actor_id,
                   "lane_key" => attrs.lane_key,
                   "lane_module" => attrs.lane_module
                 })}
            end
          end
      end
    else
      {:continue, workflow_attrs}
    end
  end

  def complete_semantic_fast_path_hit(run, entry) do
    with {:ok, step} <- ensure_semantic_hit_step(run),
         {:ok, _reuse} <-
           SemanticCache.record_reuse(entry, %{
             workflow_run_id: run.id,
             reason_code: "semantic_cache_hit",
             metadata: %{"origin_run_id" => entry.origin_run_id}
           }),
         {:ok, _completed_step} <- Workflows.complete_step(step.id, semantic_hit_result(entry)) do
      {:ok, Workflows.get_run!(run.id)}
    end
  end

  def execute_step(step_id, opts \\ []) do
    with {:ok, _claimed} <- Workflows.claim_step(step_id) do
      step = Workflows.get_step!(step_id)
      run = Workflows.get_run!(step.run_id)
      timeout = Keyword.get(opts, :timeout, @default_timeout)
      handler = resolve_handler(step, opts)
      budget_context = runtime_context(run, Keyword.get(opts, :budget_context, %{}))
      breaker_context = build_breaker_context(step, run, Keyword.get(opts, :breaker_context, %{}))

      # Step-level parent span (D-03c): a run IS a trace (D-03a), the step
      # span roots directly under it (`parent_id: nil`), and its freshly
      # minted id is threaded to every child (G2/G3/G4's guardrail spans,
      # and the handler's own trace context) as their `parent_id`. Minted
      # here -- BEFORE the span opens -- so it is available to thread, per
      # `span/4`'s own-id semantics (D-R2).
      trace_id = Observe.trace_id_for_run(run)
      step_span_id = Ecto.UUID.generate()
      span_kind = SpanKind.normalize(step.kind)

      span_opts = %{
        trace_id: trace_id,
        parent_id: nil,
        span_id: step_span_id,
        tenant_id: run.tenant_id,
        workflow_run_id: run.id,
        session_id: run.session_id
      }

      # Per-run rail admission (RAIL-01, D-08): after `claim_step/1` succeeds
      # and `run` is loaded, BEFORE `span_opts`' `:attributes` could be built
      # -- `Observe.span/4` reads `opts[:attributes]` at emit time with no
      # API to add them from inside the body, so the check must precede it.
      # On `{:ok, _}` nothing changes: no `:attributes` key is added, zero
      # span overhead. On `:denied`, the trip (not the check) happens inside
      # the span body, as the FIRST statement -- `halt_run/3` then
      # `raise StepFailureSignal` so this exact span is still ERROR-marked
      # (mirrors `fail_step_and_signal/2`).
      body_fun =
        case Rails.admit_step(run.id) do
          {:ok, _count} ->
            fn ->
              execute_step_body(
                step,
                run,
                handler,
                timeout,
                opts,
                budget_context,
                breaker_context,
                trace_id,
                step_span_id
              )
            end

          :denied ->
            envelope = rail_denied_envelope(run, step)

            fn ->
              Workflows.halt_run(run.id, step.id, envelope)
              raise StepFailureSignal, return_value: {:error, envelope}
            end
        end

      try do
        Observe.span(span_kind, @step_span_name, span_opts, body_fun)
      rescue
        e in StepFailureSignal -> e.return_value
      end
    end
  end

  # Task 1 covers only `max_steps` -- `max_active_ms`'s check order (D-08:
  # max_active_ms -> max_steps -> max_tool_calls) and its own denial site
  # land in a later 56.1 plan; the reason_code/rail here are deliberately
  # fixed rather than parameterized.
  defp rail_denied_envelope(run, step) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    %{
      "status" => "run_halted",
      "reason_code" => "max_steps_exceeded",
      "rail" => "max_steps",
      "limit" => run.rail_max_steps,
      "observed" => run.rail_steps,
      "attempted" => (run.rail_steps || 0) + 1,
      "run_id" => run.id,
      "step_id" => step.id,
      "halted_at" => DateTime.to_iso8601(now),
      "site" => "workflow_runtime_step"
    }
  end

  # Every outcome branch's side effects (reconcile_budget/emit_runtime_telemetry/
  # Workflows.complete_step|fail_step|mark_waiting_for_approval) are untouched
  # from the pre-Phase-53 implementation -- the only change is that branches
  # which fail the step now raise `StepFailureSignal` (carrying the exact
  # already-computed return value) instead of returning it directly, so the
  # wrapping `span/4` call in `execute_step/2` marks the step span ERROR
  # (SC#3) while `execute_step/2`'s own rescue restores the identical return
  # value (T-53-12, zero contract change). G2/G3/G4's guardrail spans are the
  # new observability side effect this plan adds.
  defp execute_step_body(
         step,
         run,
         handler,
         timeout,
         opts,
         budget_context,
         breaker_context,
         trace_id,
         step_span_id
       ) do
    case reserve_budget(step, run, budget_context) do
      {:error, envelope} ->
        emit_budget_rejection(step, run, budget_context, envelope)
        emit_g3_budget_block(run, trace_id, step_span_id)
        fail_step_and_signal(step, normalize_budget_envelope(envelope))

      {:ok, reservation_context} ->
        case replay_execution(run, step, handler, timeout, opts, breaker_context, trace_id, step_span_id) do
          {:ok, {:completed, result, duration_ms}} ->
            normalized_result =
              result
              |> normalize_payload()
              |> maybe_attach_semantic_writeback(run, step)

            reconcile_budget(reservation_context, budget_context, normalized_result, "completed")
            emit_runtime_telemetry(step, run, budget_context, "completed", duration_ms, normalized_result)

            Workflows.complete_step(
              step.id,
              attach_budget_evidence(normalized_result, reservation_context)
            )

          {:ok, {:waiting_for_approval, approval_attrs, duration_ms}} ->
            reconcile_budget(reservation_context, budget_context, %{}, "waiting_for_approval")

            emit_runtime_telemetry(
              step,
              run,
              budget_context,
              "waiting_for_approval",
              duration_ms,
              %{}
            )

            emit_g2_approval_escalate(run, trace_id, step_span_id)

            Workflows.mark_waiting_for_approval(run.id, step.id, Map.new(approval_attrs))

          {:ok, {:handoff, handoff_attrs, duration_ms}} ->
            reconcile_budget(reservation_context, budget_context, %{}, "handoff")
            emit_runtime_telemetry(step, run, budget_context, "handoff", duration_ms, %{})
            handle_handoff(run, step, Map.new(handoff_attrs))

          {:error, {:replay_blocked, envelope, duration_ms}} ->
            reconcile_budget(reservation_context, budget_context, %{}, "handler_error")
            emit_runtime_telemetry(step, run, budget_context, "handler_error", duration_ms, %{})
            fail_step_and_signal(step, envelope)

          {:error, {:handler_error, envelope, duration_ms}} when is_map(envelope) ->
            reconcile_budget(reservation_context, budget_context, %{}, "handler_error")
            emit_runtime_telemetry(step, run, budget_context, "handler_error", duration_ms, %{})

            fail_step_and_signal(
              step,
              attach_budget_evidence(normalize_payload(envelope), reservation_context)
            )

          {:error, {:handler_error, reason, duration_ms}} ->
            reconcile_budget(reservation_context, budget_context, %{}, "handler_error")
            emit_runtime_telemetry(step, run, budget_context, "handler_error", duration_ms, %{})

            fail_step_and_signal(
              step,
              attach_budget_evidence(%{"reason" => inspect(reason)}, reservation_context)
            )

          {:ok, {:other, other, duration_ms}} ->
            reconcile_budget(reservation_context, budget_context, other, "completed")
            emit_runtime_telemetry(step, run, budget_context, "completed", duration_ms, other)

            Workflows.complete_step(
              step.id,
              attach_budget_evidence(normalize_payload(other), reservation_context),
              run_status: "running"
            )

          {:error, {:timeout, envelope, duration_ms}} when is_map(envelope) ->
            reconcile_budget(reservation_context, budget_context, %{}, "timeout")
            emit_runtime_telemetry(step, run, budget_context, "timeout", duration_ms, %{})

            fail_step_and_signal(
              step,
              attach_budget_evidence(normalize_payload(envelope), reservation_context)
            )

          {:error, {:timeout, duration_ms}} ->
            reconcile_budget(reservation_context, budget_context, %{}, "timeout")
            emit_runtime_telemetry(step, run, budget_context, "timeout", duration_ms, %{})

            fail_step_and_signal(
              step,
              attach_budget_evidence(%{"reason" => "timeout"}, reservation_context)
            )

          {:error, {:execution_failed, envelope, duration_ms}} when is_map(envelope) ->
            reconcile_budget(reservation_context, budget_context, %{}, "execution_failed")

            emit_runtime_telemetry(
              step,
              run,
              budget_context,
              "execution_failed",
              duration_ms,
              %{}
            )

            fail_step_and_signal(
              step,
              attach_budget_evidence(normalize_payload(envelope), reservation_context)
            )

          {:error, {:execution_failed, reason, duration_ms}} ->
            reconcile_budget(reservation_context, budget_context, %{}, "execution_failed")

            emit_runtime_telemetry(
              step,
              run,
              budget_context,
              "execution_failed",
              duration_ms,
              %{}
            )

            fail_step_and_signal(
              step,
              attach_budget_evidence(%{"reason" => inspect(reason)}, reservation_context)
            )

          {:error, %{status: :breaker_open} = envelope} ->
            reconcile_breaker_open_budget(reservation_context, envelope)
            emit_runtime_breaker_open(step, run, budget_context, envelope)
            emit_g4_breaker_block(run, trace_id, step_span_id, envelope)

            fail_step_and_signal(
              step,
              attach_budget_evidence(normalize_budget_envelope(envelope), reservation_context)
            )
        end
    end
  end

  # Performs the step's failure side effect (unchanged from the
  # pre-Phase-53 `Workflows.fail_step/2` call) and then raises
  # `StepFailureSignal` carrying that EXACT return value, so `span/4`
  # marks the wrapping step span ERROR (SC#3) while `execute_step/2`'s
  # outer rescue restores the identical return value (T-53-12).
  defp fail_step_and_signal(step, envelope) do
    result = Workflows.fail_step(step.id, envelope)
    raise StepFailureSignal, return_value: result
  end

  # G2 (MANDATORY, D-05b): the waiting_for_approval outcome escalates to a
  # human. Parented to the step span; `status_code` is always "OK" on the
  # guardrail span itself (D-05e) -- escalating is a successful evaluation,
  # not a span error.
  defp emit_g2_approval_escalate(run, trace_id, step_span_id) do
    Guardrail.emit(%{
      name: "approval_gate",
      decision: "escalate",
      reason_code: :approval_required,
      trace_id: trace_id,
      parent_id: step_span_id,
      tenant_id: run.tenant_id,
      workflow_run_id: run.id,
      session_id: run.session_id
    })
  end

  # G3 (discretionary, shipped): a budget-rejected step never reaches
  # `replay_execution/8`, so it is parented to the step span the same as
  # every other gate in this plan (the step span already opened before
  # `reserve_budget/3` runs, D-03c).
  defp emit_g3_budget_block(run, trace_id, step_span_id) do
    Guardrail.emit(%{
      name: "budget_gate",
      decision: "block",
      reason_code: :budget_rejected,
      trace_id: trace_id,
      parent_id: step_span_id,
      tenant_id: run.tenant_id,
      workflow_run_id: run.id,
      session_id: run.session_id
    })
  end

  # G4 (discretionary, shipped): reads the breaker envelope's own
  # `reason_code` ("breaker_open", `breaker_registry.ex`'s `open_envelope/1`)
  # rather than re-deriving a second copy (D-05j -- do not double-count the
  # breaker; this instruments the workflow runtime's actual enforcement
  # point, not `Scoria.Observe.CircuitBreaker`).
  defp emit_g4_breaker_block(run, trace_id, step_span_id, envelope) do
    Guardrail.emit(%{
      name: "breaker_gate",
      decision: "block",
      reason_code: Map.get(envelope, :reason_code, "breaker_open"),
      trace_id: trace_id,
      parent_id: step_span_id,
      tenant_id: run.tenant_id,
      workflow_run_id: run.id,
      session_id: run.session_id
    })
  end

  defp replay_execution(
         %{execution_mode: "replay"} = run,
         step,
         handler,
         timeout,
         opts,
         breaker_context,
         trace_id,
         parent_id
       ) do
    seam = Keyword.get(opts, :replay_seam) || default_replay_seam(run, step)
    source_evidence = Keyword.get(opts, :replay_source_evidence, %{})
    approval_context = Keyword.get(opts, :replay_approval_context, %{})
    override_context = Keyword.get(opts, :replay_override_context, run.replay_overrides || %{})

    case Scoria.Workflows.ReplayDisposition.resolve(
           run,
           seam,
           source_evidence,
           approval_context,
           override_context
         ) do
      {:historical_stub, evidence} ->
        result =
          Map.get(source_evidence, :result) ||
            Map.get(source_evidence, "result") ||
            %{"status" => :historical_stub}

        {:ok, {:completed, replay_result_payload(result, evidence, "historical_stub"), 0}}

      {:blocked, evidence} ->
        {:error, {:replay_blocked, replay_blocked_envelope(evidence), 0}}

      {:execute_live, evidence} ->
        case BreakerRegistry.run(breaker_context, fn ->
               execute_handler(handler, step, run, timeout, trace_id, parent_id)
             end) do
          {:ok, {:completed, result, duration_ms}} ->
            {:ok,
             {:completed, replay_result_payload(result, evidence, "replay_live"), duration_ms}}

          {:ok, {:waiting_for_approval, approval_attrs, duration_ms}} ->
            {:ok,
             {:waiting_for_approval, replay_waiting_approval_attrs(approval_attrs, evidence),
              duration_ms}}

          {:ok, {:handoff, handoff_attrs, duration_ms}} ->
            {:ok, {:handoff, handoff_attrs, duration_ms}}

          {:error, {:handler_error, reason, duration_ms}} ->
            {:error,
             {:handler_error, replay_failure_envelope(reason, evidence, "replay_live"),
              duration_ms}}

          {:error, {:timeout, duration_ms}} ->
            {:error,
             {:timeout, replay_failure_envelope("timeout", evidence, "replay_live"), duration_ms}}

          {:error, {:execution_failed, reason, duration_ms}} ->
            {:error,
             {:execution_failed, replay_failure_envelope(reason, evidence, "replay_live"),
              duration_ms}}

          other ->
            other
        end
    end
  end

  defp replay_execution(run, step, handler, timeout, _opts, breaker_context, trace_id, parent_id) do
    BreakerRegistry.run(breaker_context, fn ->
      execute_handler(handler, step, run, timeout, trace_id, parent_id)
    end)
  end

  # Site 5 (D-05, "the worst"): this is the single, named, documented origin
  # of the total step-granularity replay bypass a caller gets when it
  # passes NO `:replay_seam` opt. Before this plan that bypass was an
  # anonymous inline literal (`%{local_classification: :pure}`) with no
  # telemetry -- silent and untraceable. This helper is NOT a widening of
  # what the bypass permits: `local_classification: :pure` is carried
  # EXACTLY as before (load-bearing -- `ReplayDisposition.pure_local?/1`,
  # clause 3, short-circuits to `:execute_live` on that value before clause
  # 7's `effectful_or_remote?/1` is ever evaluated; substituting any other
  # value here would flip every currently-replaying workflow step to
  # `:blocked`). It ADDS `tool_classification:
  # Classification.unclassified_default/0` alongside the unchanged `:pure`
  # value, and emits exactly one `[:scoria, :class, :unclassified]` event
  # (`site: :workflow_runtime_step`) so this bypass is now inspectable
  # rather than silent (D-05).
  #
  # This is a STEP-GRANULARITY REPLAY DEFAULT, not a tool-classification
  # refusal point: there is no tool module here to classify (a workflow
  # step is a bare handler function), so `require_tool_classification`
  # (D-03, scoped to `MCP.Executor` resolution only) is deliberately NOT
  # consulted or extended to this site -- inventing a step-level refusal
  # here would halt workflow replay for a reason no adopter opted into.
  defp default_replay_seam(run, step) do
    emit_workflow_runtime_step_unclassified(run, step)

    %{
      local_classification: :pure,
      tool_classification: Classification.unclassified_default()
    }
  end

  defp emit_workflow_runtime_step_unclassified(run, step) do
    try do
      :telemetry.execute(
        [:scoria, :class, :unclassified],
        %{},
        %{site: :workflow_runtime_step, run_id: run.id, step_id: step.id}
      )
    rescue
      _ -> :ok
    end
  end

  defp replay_blocked_envelope(evidence) do
    %{
      "status" => "replay_blocked",
      "replay_disposition" => Atom.to_string(evidence.replay_disposition),
      "replay_reason_code" => evidence.replay_reason_code,
      "source_run_id" => evidence.source_run_id,
      "source_checkpoint_id" => evidence.source_checkpoint_id,
      "source_step_id" => evidence.source_step_id,
      "source_approval_id" => evidence.source_approval_id,
      "source_audit_outbox_event_id" => evidence.source_audit_outbox_event_id,
      "args_fingerprint" => evidence.args_fingerprint,
      "subject_ref" => evidence.subject_ref,
      "required_scopes" => evidence.required_scopes,
      "policy_key" => evidence.policy_key,
      "executed_live" => evidence.executed_live,
      "replay_scope" => "replay_default"
    }
  end

  defp execute_handler(handler, step, run, timeout, trace_id, parent_id) do
    started_at = System.monotonic_time()
    handler_run = decorate_run_with_trace_context(run, trace_id, parent_id, step.id)

    task =
      Task.Supervisor.async_nolink(Scoria.Workflow.TaskSupervisor, fn ->
        invoke_handler(handler, step, handler_run)
      end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, {:ok, result}} ->
        {:ok, {:completed, result, elapsed_ms(started_at)}}

      {:ok, {:waiting_for_approval, approval_attrs}} ->
        {:ok, {:waiting_for_approval, approval_attrs, elapsed_ms(started_at)}}

      {:ok, {:handoff, handoff_attrs}} ->
        {:ok, {:handoff, handoff_attrs, elapsed_ms(started_at)}}

      {:ok, {:error, reason}} ->
        {:error, {:handler_error, reason, elapsed_ms(started_at)}}

      {:ok, other} ->
        {:ok, {:other, other, elapsed_ms(started_at)}}

      nil ->
        {:error, {:timeout, elapsed_ms(started_at)}}

      {:exit, reason} ->
        {:error, {:execution_failed, reason, elapsed_ms(started_at)}}
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
          |> Map.put_new(
            "consecutive_failures",
            Map.get(run.error_envelope || %{}, "consecutive_failures", 0)
          )
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
    delegated_kind = Map.get(attrs, "delegated_kind", "handoff")
    projected_context = Map.get(attrs, "projected_context", %{})

    case Params.validate_projected_context(projected_context) do
      :ok ->
        {:ok, _handoff} =
          Workflows.create_handoff(step, %{
            delegated_role_id: delegated_role_id,
            delegated_kind: delegated_kind,
            capability_tags: List.wrap(Map.get(attrs, "capability_tags", [])),
            handoff_input: Map.get(attrs, "handoff_input", %{}),
            result_summary: %{},
            status: "pending"
          })

        {:ok, _child_step} =
          Workflows.create_step(run.id, %{
            parent_step_id: step.id,
            sequence: Workflows.next_step_sequence(run.id),
            kind: delegated_kind,
            role_id: delegated_role_id,
            status: "queued",
            handoff_input: Map.get(attrs, "handoff_input", %{}),
            projected_context: projected_context
          })

        Workflows.complete_step(step.id, %{"handoff" => delegated_role_id}, run_status: "running")

      {:error, :unsafe_projected_context} ->
        Workflows.fail_step(step.id, %{
          "reason" => "unsafe_projected_context",
          "contract" => "bounded_handoff_projected_context",
          "message" => "bounded handoff projected_context must stay narrow and host-controlled"
        })

      {:error, :invalid_projected_context} ->
        Workflows.fail_step(step.id, %{
          "reason" => "invalid_projected_context",
          "contract" => "bounded_handoff_projected_context",
          "message" => "bounded handoff projected_context must be a map"
        })
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

  # Threads `trace_id`/the step span's own id (D-03b) into the ephemeral,
  # never-persisted copy of `run` handed to the handler -- the ONLY
  # backward-compatible carrier available, since every handler shape
  # (`{module, function}`, `{module, function, extra_args}`, `fun/1`,
  # `fun/2`) already receives `run` and none can be given a new positional
  # arg without breaking every host handler's existing arity contract.
  # `run.metadata["runtime"]` is the SAME extension point
  # `run_runtime_defaults/1` already reads for provider/model/policy_key
  # (an established ad hoc pattern).
  #
  # RAIL-01 (56.1-CONTEXT.md D-10): also carries `"run_id"` and `"step_id"`
  # alongside `"trace_id"`/`"parent_id"` -- this is the fix for the fact
  # that `max_tool_calls` enforced only at `MCP.Executor.execute/4` would
  # fire only if a host hand-threaded a key Scoria never populated and
  # never documented. A host handler wanting to call
  # `Scoria.MCP.Executor.execute/4` reads `run_id` and `step_id` from
  # `run.metadata["runtime"]` and forwards them into whatever tool context
  # it builds -- Scoria will not infer one, and the residual gap for a
  # handler that does not forward them is measured honestly by
  # `[:scoria, :run, :rail, :skipped]` rather than papered over. This
  # decorated copy is NEVER persisted back to the database -- it exists
  # only for the duration of the Task-isolated handler invocation.
  defp decorate_run_with_trace_context(run, trace_id, parent_id, step_id) do
    metadata = run.metadata || %{}
    runtime = Map.get(metadata, "runtime", %{})

    updated_runtime =
      runtime
      |> Map.put("trace_id", trace_id)
      |> Map.put("parent_id", parent_id)
      |> Map.put("run_id", run.id)
      |> Map.put("step_id", step_id)

    %{run | metadata: Map.put(metadata, "runtime", updated_runtime)}
  end

  defp invoke_handler({module, function}, step, run), do: apply(module, function, [step, run])

  defp invoke_handler({module, function, extra_args}, step, run),
    do: apply(module, function, [step, run | List.wrap(extra_args)])

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

  defp replay_result_payload(result, evidence, replay_scope) do
    normalize_payload(result)
    |> Map.merge(replay_payload_fields(evidence, replay_scope))
  end

  defp replay_waiting_approval_attrs(attrs, evidence) do
    Map.new(attrs)
    |> Map.merge(replay_approval_fields(evidence, "replay_live"))
    |> Map.put(:replay_scope, "replay_live")
    |> Map.put(:executed_live, evidence.executed_live)
  end

  defp replay_failure_envelope(reason, evidence, replay_scope) do
    %{"reason" => inspect(reason)}
    |> Map.merge(replay_payload_fields(evidence, replay_scope))
  end

  defp replay_payload_fields(evidence, replay_scope) do
    %{
      "replay_disposition" => Atom.to_string(evidence.replay_disposition),
      "replay_reason_code" => evidence.replay_reason_code,
      "source_run_id" => evidence.source_run_id,
      "source_checkpoint_id" => evidence.source_checkpoint_id,
      "source_step_id" => evidence.source_step_id,
      "source_approval_id" => evidence.source_approval_id,
      "source_audit_outbox_event_id" => evidence.source_audit_outbox_event_id,
      "args_fingerprint" => evidence.args_fingerprint,
      "subject_ref" => evidence.subject_ref,
      "required_scopes" => evidence.required_scopes,
      "policy_key" => evidence.policy_key,
      "executed_live" => evidence.executed_live,
      "replay_scope" => replay_scope,
      "replay_idempotency_key" => evidence.replay_idempotency_key
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp replay_approval_fields(evidence, replay_scope) do
    %{
      replay_disposition: Atom.to_string(evidence.replay_disposition),
      replay_reason_code: evidence.replay_reason_code,
      source_run_id: evidence.source_run_id,
      source_checkpoint_id: evidence.source_checkpoint_id,
      source_step_id: evidence.source_step_id,
      source_approval_id: evidence.source_approval_id,
      source_audit_outbox_event_id: evidence.source_audit_outbox_event_id,
      args_fingerprint: evidence.args_fingerprint,
      subject_ref: evidence.subject_ref,
      required_scopes: evidence.required_scopes,
      policy_key: evidence.policy_key,
      executed_live: evidence.executed_live,
      replay_scope: replay_scope,
      replay_idempotency_key: evidence.replay_idempotency_key
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

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

  defp actual_units(_budget_context, _result, outcome)
       when outcome in ["timeout", "execution_failed", "handler_error"], do: 0

  defp actual_units(budget_context, result, _outcome) do
    cond do
      is_map(result) && Map.has_key?(result, :actual_units) ->
        Map.fetch!(result, :actual_units)

      is_map(result) && Map.has_key?(result, "actual_units") ->
        Map.fetch!(result, "actual_units")

      is_map(result) && Map.has_key?(result, :actual_cost_usd) ->
        Map.fetch!(result, :actual_cost_usd)

      is_map(result) && Map.has_key?(result, "actual_cost_usd") ->
        Map.fetch!(result, "actual_cost_usd")

      true ->
        estimated_units(budget_context)
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
      base_runtime_attrs(
        step,
        run,
        budget_context,
        Map.get(envelope, :reason_code, "budget_rejected")
      )
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

  defp numeric_ratio(actual, estimated)
       when is_number(actual) and is_number(estimated) and estimated != 0,
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
      prompt_policy: Map.get(metadata, "prompt_policy"),
      semantic_cache: Map.get(metadata, "semantic_cache")
    }
  end

  defp maybe_attach_semantic_writeback(result_envelope, run, step) do
    case semantic_writeback_context(run) do
      %{lookup_status: "miss", eligibility_status: status} = semantic_ctx
      when status in ["eligible", "eligible_actor_scoped"] ->
        case semantic_writeback_reason(result_envelope) do
          nil ->
            with {:ok, %{entry: entry}} <-
                   SemanticCache.admit(
                     semantic_cache_entry_attrs(run, semantic_ctx, result_envelope, step, "active")
                   ) do
              Map.put(result_envelope, "semantic_cache", %{
                "status" => "admitted",
                "entry_id" => entry.id,
                "origin_run_id" => run.id
              })
            else
              _ -> result_envelope
            end

          reason_code ->
            with {:ok, %{entry: entry}} <-
                   SemanticCache.record_writeback_rejection(
                     semantic_cache_entry_attrs(
                       run,
                       semantic_ctx,
                       result_envelope,
                       step,
                       "writeback_rejected",
                       reason_code
                     )
                   ) do
              Map.put(result_envelope, "semantic_cache", %{
                "status" => "writeback_rejected",
                "entry_id" => entry.id,
                "reason_code" => reason_code
              })
            else
              _ ->
                Map.put(result_envelope, "semantic_cache", %{
                  "status" => "writeback_rejected",
                  "reason_code" => reason_code
                })
            end
        end

      _ ->
        result_envelope
    end
  end

  defp semantic_writeback_context(run) do
    run
    |> run_runtime_defaults()
    |> Map.get(:semantic_cache, %{})
    |> case do
      %{} = semantic_cache ->
        %{
          lookup_status: Map.get(semantic_cache, "lookup_status"),
          eligibility_status: Map.get(semantic_cache, "eligibility_status"),
          query_text: Map.get(semantic_cache, "query_text"),
          lane_key: Map.get(semantic_cache, "lane_key"),
          lane_module: Map.get(semantic_cache, "lane_module"),
          scope_kind: Map.get(semantic_cache, "scope_kind"),
          scope_reason: Map.get(semantic_cache, "scope_reason"),
          tenant_id: Map.get(semantic_cache, "tenant_id"),
          actor_id: Map.get(semantic_cache, "actor_id"),
          source_fingerprint: semantic_cache_source_fingerprint(semantic_cache)
        }

      _ ->
        %{}
    end
  end

  defp semantic_writeback_reason(result_envelope) do
    result_envelope
    |> Map.get("semantic_cache", %{})
    |> case do
      %{"writeback_rejected" => reason_code} when is_binary(reason_code) -> reason_code
      %{"writeback_rejected" => reason_code} when is_atom(reason_code) -> Atom.to_string(reason_code)
      _ -> nil
    end
  end

  defp semantic_cache_entry_attrs(run, semantic_ctx, result_envelope, _step, status, reason_code \\ nil) do
    runtime_defaults = run_runtime_defaults(run)
    policy_fingerprint = Compatibility.policy_fingerprint(runtime_defaults.prompt_policy || %{})
    source_fingerprint = Compatibility.source_fingerprint_for_retrieval_run(Map.get(result_envelope, "retrieval_run_id"))
    query_text = semantic_ctx.query_text
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    %{
      tenant_id: semantic_ctx.tenant_id || run.tenant_id,
      actor_id: semantic_actor_id(semantic_ctx),
      scope_kind: semantic_ctx.scope_kind || "tenant_shared",
      scope_reason: semantic_ctx.scope_reason || "lane_default",
      lane_key: semantic_ctx.lane_key,
      lane_module: semantic_ctx.lane_module,
      policy_key: runtime_defaults.policy_key,
      prompt_ref: runtime_defaults.prompt_ref,
      prompt_version: runtime_defaults.prompt_version,
      provider: runtime_defaults.provider,
      model: runtime_defaults.model,
      query_text: query_text,
      query_embedding: query_text && Embedder.Deterministic.embed_query(query_text),
      answer_payload: semantic_answer_payload(result_envelope),
      evidence_refs: semantic_evidence_refs(result_envelope),
      policy_fingerprint: policy_fingerprint,
      source_fingerprint: source_fingerprint || semantic_ctx.source_fingerprint,
      origin_run_id: run.id,
      origin_span_id: Map.get(result_envelope, "span_id"),
      origin_retrieval_run_id: Map.get(result_envelope, "retrieval_run_id"),
      status: status,
      expires_at: if(status == "active", do: DateTime.add(now, 900, :second), else: nil),
      state_reason_code: if(status == "writeback_rejected", do: reason_code, else: nil),
      metadata: semantic_metadata(result_envelope, reason_code),
      reason_code: reason_code
    }
  end

  defp semantic_answer_payload(%{"output" => output}) when is_map(output), do: output
  defp semantic_answer_payload(%{"output" => output}) when is_binary(output), do: %{"answer" => output}
  defp semantic_answer_payload(result_envelope), do: Map.drop(result_envelope, ["semantic_cache"])

  defp semantic_evidence_refs(result_envelope) do
    Map.get(result_envelope, "evidence_refs", %{})
  end

  defp semantic_metadata(result_envelope, nil), do: %{"step_result_keys" => Map.keys(result_envelope)}

  defp semantic_metadata(result_envelope, reason_code) do
    %{
      "step_result_keys" => Map.keys(result_envelope),
      "writeback_rejected" => reason_code
    }
  end

  defp semantic_actor_id(%{scope_kind: "actor_scoped", actor_id: actor_id}), do: actor_id
  defp semantic_actor_id(%{scope_kind: :actor_scoped, actor_id: actor_id}), do: actor_id
  defp semantic_actor_id(_semantic_ctx), do: nil

  defp ensure_semantic_hit_step(run) do
    case Workflows.list_run_steps(run.id) do
      [step | _] ->
        {:ok, step}

      [] ->
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "semantic_cache_hit",
          role_id: run.root_role_id,
          status: "queued",
          projected_context: %{}
        })
    end
  end

  defp semantic_hit_result(entry) do
    %{
      "status" => "cached",
      "output" => entry.answer_payload,
      "semantic_cache" => %{
        "status" => "hit",
        "entry_id" => entry.id,
        "origin_run_id" => entry.origin_run_id,
        "scope_kind" => entry.scope_kind
      }
    }
  end

  defp put_semantic_cache_state(workflow_attrs, state) do
    metadata = Map.get(workflow_attrs, :metadata, %{})
    runtime = Map.get(metadata, "runtime", %{})
    semantic_cache = Map.get(runtime, "semantic_cache", %{})
    updated_runtime = Map.put(runtime, "semantic_cache", Map.merge(semantic_cache, state))

    Map.put(workflow_attrs, :metadata, Map.put(metadata, "runtime", updated_runtime))
  end

  defp semantic_query_text(metadata) do
    payload = Map.get(metadata, "payload")

    cond do
      is_binary(payload) ->
        payload

      is_map(payload) ->
        Map.get(payload, "query") ||
          Map.get(payload, :query) ||
          Map.get(payload, "question") ||
          Map.get(payload, :question) ||
          Map.get(payload, "input") ||
          Map.get(payload, :input)

      true ->
        nil
    end
  end

  defp maybe_put_query_embedding(attrs, query_text) when is_binary(query_text),
    do: Map.put(attrs, :query_embedding, Embedder.Deterministic.embed_query(query_text))

  defp maybe_put_query_embedding(attrs, _query_text), do: attrs

  defp maybe_put_source_fingerprint(attrs, semantic_cache) do
    case semantic_cache_source_fingerprint(semantic_cache) do
      nil -> attrs
      source_fingerprint -> Map.put(attrs, :source_fingerprint, source_fingerprint)
    end
  end

  defp semantic_cache_source_fingerprint(%{} = semantic_cache) do
    metadata = Map.get(semantic_cache, "metadata", %{})

    Map.get(semantic_cache, "source_fingerprint") ||
      Map.get(metadata, "source_fingerprint")
  end

  defp semantic_cache_source_fingerprint(_semantic_cache), do: nil

  defp maybe_put_runtime_field(attrs, _key, nil), do: attrs

  defp maybe_put_runtime_field(attrs, key, value) do
    Map.put_new(attrs, key, value)
  end
end
