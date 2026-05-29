defmodule Scoria.SRE.BudgetEngine do
  @moduledoc """
  Budget reservation and loop-guard decisions for workflow and MCP execution.
  """

  import Ecto.Query, warn: false

  alias Decimal, as: D
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.{BudgetPolicy, BudgetReservation}

  @default_window_ms :timer.minutes(1)
  @cost_precision 1_000

  defmodule RateLimiter do
    @moduledoc false
    use Hammer, backend: :ets
  end

  def reserve_step(attrs) when is_map(attrs) do
    attrs = normalize_attrs(attrs)

    with :ok <- ensure_rate_limiter_started(),
         {:ok, policy} <- load_policy(attrs),
         :ok <- evaluate_workflow_step_guard(policy, attrs),
         :ok <- evaluate_consecutive_failure_guard(policy, attrs),
         :ok <- evaluate_repeated_tool_guard(policy, attrs),
         {:ok, usage} <- reserve_window_usage(policy, attrs),
         {:ok, reservation} <- persist_reservation(attrs, policy, usage),
         warnings <- build_warnings(policy, usage) do
      {:ok,
       %{
         reservation: reservation,
         policy: policy,
         usage: usage,
         warnings: warnings
       }}
    else
      {:error, %{status: _status} = envelope} -> {:error, envelope}
      {:error, reason} -> {:error, build_envelope(:budget_error, "budget_engine_failed", %{details: inspect(reason)})}
    end
  end

  def reconcile_usage(%BudgetReservation{} = reservation, attrs) when is_map(attrs) do
    attrs =
      attrs
      |> Map.new()
      |> Map.update(:metadata, %{}, &stringify_map_keys(Map.new(&1)))

    actual_units = normalize_decimal(Map.get(attrs, :actual_units, reservation.actual_units || reservation.estimated_units || 0))
    estimated_units = normalize_decimal(reservation.estimated_units || 0)

    reconciliation_status =
      cond do
        Map.has_key?(attrs, :reconciliation_status) ->
          Map.fetch!(attrs, :reconciliation_status)

        D.compare(actual_units, estimated_units) == :gt ->
          "overage"

        true ->
          "matched"
      end

    metadata =
      reservation.metadata
      |> Map.new()
      |> Map.merge(Map.get(attrs, :metadata, %{}))
      |> Map.put("actual_units", D.to_string(actual_units))

    SRE.reconcile_usage(reservation, %{
      actual_units: actual_units,
      reconciliation_status: reconciliation_status,
      metadata: metadata
    })
  end

  def reconcile_usage(%{reservation: %BudgetReservation{} = reservation}, attrs), do: reconcile_usage(reservation, attrs)

  def reconcile_breaker_open(reservation_or_context, metadata \\ %{}) do
    reconcile_usage(reservation_or_context, %{
      actual_units: D.new(0),
      reconciliation_status: "matched",
      metadata:
        metadata
        |> Map.new()
        |> stringify_map_keys()
        |> Map.put("outcome", "breaker_open")
    })
  end

  defp load_policy(attrs) do
    tenant_id = Map.fetch!(attrs, :tenant_id)
    resource_kind = Map.fetch!(attrs, :resource_kind)

    query =
      BudgetPolicy
      |> where([policy], policy.tenant_id == ^tenant_id and policy.resource_kind == ^resource_kind)
      |> where([policy], policy.status == "active")
      |> maybe_filter_policy_key(Map.get(attrs, :policy_key))
      |> maybe_filter_scope_key(Map.get(attrs, :scope_key))
      |> order_by([policy], desc: policy.inserted_at)
      |> limit(1)

    case Repo.one(query) do
      %BudgetPolicy{} = policy ->
        {:ok, policy}

      nil ->
        {:error,
         build_envelope(:budget_error, "budget_policy_not_found", %{
           tenant_id: tenant_id,
           resource_kind: resource_kind
         })}
    end
  end

  defp maybe_filter_policy_key(query, nil), do: query
  defp maybe_filter_policy_key(query, policy_key), do: where(query, [policy], policy.policy_key == ^policy_key)

  defp maybe_filter_scope_key(query, nil), do: query
  defp maybe_filter_scope_key(query, scope_key), do: where(query, [policy], policy.scope_key == ^scope_key)

  defp evaluate_workflow_step_guard(%BudgetPolicy{max_workflow_steps: nil}, _attrs), do: :ok

  defp evaluate_workflow_step_guard(%BudgetPolicy{max_workflow_steps: cap}, attrs) do
    current_steps =
      attrs
      |> Map.get(:metadata, %{})
      |> Map.get("workflow_step_count")
      |> fallback_integer(Map.get(attrs, :step_sequence))

    if is_integer(current_steps) and current_steps >= cap do
      {:error,
       build_envelope(:loop_guard_tripped, "max_workflow_steps_exceeded", %{
         guard: :max_workflow_steps,
         observed: current_steps,
         limit: cap
       })}
    else
      :ok
    end
  end

  defp evaluate_consecutive_failure_guard(%BudgetPolicy{max_consecutive_failures: nil}, _attrs), do: :ok

  defp evaluate_consecutive_failure_guard(%BudgetPolicy{max_consecutive_failures: cap}, attrs) do
    consecutive_failures =
      attrs
      |> Map.get(:metadata, %{})
      |> Map.get("consecutive_failures")
      |> fallback_integer(0)

    if consecutive_failures >= cap do
      {:error,
       build_envelope(:loop_guard_tripped, "consecutive_failures_exceeded", %{
         guard: :consecutive_failures,
         observed: consecutive_failures,
         limit: cap
       })}
    else
      :ok
    end
  end

  defp evaluate_repeated_tool_guard(%BudgetPolicy{max_repeated_tool_calls: nil}, _attrs), do: :ok

  defp evaluate_repeated_tool_guard(%BudgetPolicy{max_repeated_tool_calls: cap}, attrs) do
    tool_hash = attrs |> Map.get(:metadata, %{}) |> Map.get("tool_hash")

    if is_binary(tool_hash) do
      key = repeated_tool_key(attrs, tool_hash)

      case RateLimiter.hit(key, @default_window_ms, cap, 1) do
        {:allow, _count} ->
          :ok

        {:deny, retry_after_ms} ->
          {:error,
           build_envelope(:loop_guard_tripped, "repeated_tool_hash_exceeded", %{
             guard: :repeated_tool_hash,
             retry_after_ms: retry_after_ms,
             tool_hash: tool_hash,
             limit: cap
           })}
      end
    else
      :ok
    end
  end

  defp reserve_window_usage(policy, attrs) do
    scale = window_ms(attrs, policy)
    estimated_units = Map.fetch!(attrs, :estimated_units)
    increment = scaled_units(estimated_units, attrs.resource_kind)
    trip_limit = scaled_limit(policy.trip_threshold, attrs.resource_kind)
    warn_limit = scaled_limit(policy.warn_threshold, attrs.resource_kind)
    key = usage_key(attrs, policy)

    case RateLimiter.hit(key, scale, trip_limit, increment) do
      {:allow, current_count} ->
        {:ok, %{count: current_count, warn_limit: warn_limit, trip_limit: trip_limit, scale: scale}}

      {:deny, retry_after_ms} ->
        {:error,
         build_envelope(:budget_tripped, "trip_threshold_exceeded", %{
           guard: :trip_threshold,
           retry_after_ms: retry_after_ms,
           trip_limit: policy.trip_threshold,
           estimated_units: estimated_units
         })}
    end
  end

  defp persist_reservation(attrs, policy, usage) do
    reservation_attrs =
      attrs
      |> Map.take([:tenant_id, :policy_key, :scope_key, :resource_kind, :estimated_units, :reason_code, :trace_id, :audit_envelope])
      |> Map.merge(%{
        workflow_run_id: Map.get(attrs, :run_id),
        provider_ref: Map.get(attrs, :provider_ref),
        tool_ref: Map.get(attrs, :tool_ref),
        policy_id: policy.id,
        policy_key: policy.policy_key,
        scope_key: policy.scope_key,
        metadata:
          attrs
          |> Map.get(:metadata, %{})
          |> Map.put("actor_id", Map.get(attrs, :actor_id))
          |> Map.put("step_id", Map.get(attrs, :step_id))
          |> Map.put("integration_kind", Map.get(attrs, :integration_kind))
          |> Map.put("window_count", usage.count)
          |> Map.put("window_scale_ms", usage.scale)
      })

    SRE.reserve_usage(reservation_attrs)
  end

  defp build_warnings(policy, usage) do
    if usage.count >= usage.warn_limit and usage.warn_limit < usage.trip_limit do
      [
        %{
          guard: :warn_threshold,
          reason_code: "warn_threshold_reached",
          threshold: policy.warn_threshold
        }
      ]
    else
      []
    end
  end

  defp window_ms(attrs, policy) do
    attrs
    |> Map.get(:metadata, %{})
    |> Map.get("window_ms")
    |> fallback_integer(policy.metadata["window_ms"] || @default_window_ms)
  end

  defp usage_key(attrs, policy) do
    [
      "budget",
      attrs.tenant_id,
      attrs.resource_kind,
      policy.policy_key,
      Map.get(attrs, :actor_id)
    ]
    |> Enum.map(&to_string/1)
    |> Enum.join(":")
  end

  defp repeated_tool_key(attrs, tool_hash) do
    [
      "tool-guard",
      attrs.tenant_id,
      Map.get(attrs, :run_id),
      tool_hash
    ]
    |> Enum.map(&to_string/1)
    |> Enum.join(":")
  end

  defp scaled_limit(nil, resource_kind), do: scaled_units(0, resource_kind)
  defp scaled_limit(value, resource_kind), do: scaled_units(value, resource_kind)

  defp scaled_units(value, "cost_usd") do
    value
    |> normalize_decimal()
    |> D.mult(D.new(@cost_precision))
    |> D.round(0, :ceiling)
    |> D.to_integer()
    |> max(1)
  end

  defp scaled_units(value, _resource_kind) when is_integer(value), do: max(value, 1)

  defp scaled_units(value, _resource_kind) do
    value
    |> normalize_decimal()
    |> D.round(0, :ceiling)
    |> D.to_integer()
    |> max(1)
  end

  defp normalize_attrs(attrs) do
    metadata = attrs |> Map.get(:metadata, %{}) |> Map.new()

    attrs
    |> Map.new()
    |> Map.put(:metadata, stringify_map_keys(metadata))
    |> Map.put_new(:resource_kind, normalize_resource(Map.get(attrs, :resource) || Map.get(attrs, "resource"), attrs))
    |> Map.update!(:estimated_units, &normalize_decimal/1)
  end

  defp normalize_resource(nil, attrs) do
    cond do
      Map.has_key?(attrs, :estimated_cost_usd) or Map.has_key?(attrs, "estimated_cost_usd") -> "cost_usd"
      Map.has_key?(attrs, :estimated_tokens) or Map.has_key?(attrs, "estimated_tokens") -> "token_in"
      Map.get(attrs, :sensitive_tool) || Map.get(attrs, "sensitive_tool") -> "tool_calls"
      true -> "workflow_steps"
    end
  end

  defp normalize_resource(resource, _attrs) when is_atom(resource), do: Atom.to_string(resource)
  defp normalize_resource(resource, _attrs), do: resource

  defp normalize_decimal(%D{} = value), do: value
  defp normalize_decimal(value) when is_integer(value), do: D.new(value)
  defp normalize_decimal(value) when is_float(value), do: D.from_float(value)
  defp normalize_decimal(value) when is_binary(value), do: D.new(value)
  defp normalize_decimal(nil), do: D.new(0)

  defp build_envelope(status, reason_code, details) do
    details =
      details
      |> Map.new()
      |> Enum.into(%{}, fn {key, value} -> {key, stringify_decimal(value)} end)

    Map.merge(details, %{status: status, reason_code: reason_code})
  end

  defp stringify_decimal(%D{} = value), do: D.to_string(value)
  defp stringify_decimal(value), do: value

  defp fallback_integer(value, _fallback) when is_integer(value), do: value
  defp fallback_integer(nil, fallback), do: fallback
  defp fallback_integer(value, _fallback) when is_binary(value), do: String.to_integer(value)
  defp fallback_integer(_value, fallback), do: fallback

  defp stringify_map_keys(map) do
    Enum.into(map, %{}, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp ensure_rate_limiter_started do
    key = {__MODULE__, :rate_limiter_pid}

    case :persistent_term.get(key, nil) do
      pid when is_pid(pid) ->
        if Process.alive?(pid) do
          :ok
        else
          start_rate_limiter(key)
        end

      _ ->
        start_rate_limiter(key)
    end
  end

  defp start_rate_limiter(key) do
    try do
      case RateLimiter.start_link([]) do
        {:ok, pid} ->
          :persistent_term.put(key, pid)
          :ok

        {:error, {:already_started, pid}} ->
          :persistent_term.put(key, pid)
          :ok

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      ArgumentError ->
        result =
          case Process.whereis(RateLimiter) do
            pid when is_pid(pid) ->
              :persistent_term.put(key, pid)
              :ok

            _ ->
              :ok
          end

        result
    end
  end
end
