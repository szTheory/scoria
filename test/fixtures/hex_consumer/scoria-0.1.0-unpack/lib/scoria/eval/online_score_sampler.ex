defmodule Scoria.Eval.OnlineScoreSampler do
  @moduledoc false

  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.Workflows.{Run, Step}

  @default_sample_reason "production_sample"
  @default_sampler_version "online-score-sampler@v1"

  def schedule_sample(attrs, opts \\ []) when is_map(attrs) do
    with {:ok, payload} <- normalize_payload(attrs),
         {:ok, %Trace{} = trace} <- fetch_trace(payload.trace_id),
         :ok <- validate_workflow_lineage(payload, trace),
         :ok <- ensure_production_trace(trace) do
      coordinator = Application.get_env(:scoria, :online_scoring_module, Scoria.Eval.OnlineScoring)
      caller = self()

      Task.start(fn ->
        allow_test_processes(opts, caller)
        _ = coordinator.enqueue_sampled_trace(payload, opts)
      end)

      {:ok, %{status: :scheduled, trace_id: payload.trace_id}}
    else
      {:ignored, reason} -> {:ok, %{status: :ignored, reason: reason}}
      {:error, _} = error -> error
    end
  end

  defp normalize_payload(attrs) do
    trace_id = fetch_attr!(attrs, :trace_id)
    tenant_id = fetch_attr!(attrs, :tenant_id)
    workflow_run_id = fetch_attr!(attrs, :workflow_run_id)
    workflow_step_id = fetch_attr!(attrs, :workflow_step_id)
    sample_window = fetch_attr!(attrs, :sample_window)

    scorer =
      attrs
      |> fetch_attr!(:scorer)
      |> normalize_map()

    evidence_refs =
      attrs
      |> fetch_attr(:evidence_refs, %{})
      |> normalize_map()

    promotion_snapshot =
      attrs
      |> fetch_attr(:promotion_snapshot, %{})
      |> normalize_map()

    sample_reason = fetch_attr(attrs, :sample_reason, @default_sample_reason)
    sampler_version = fetch_attr(attrs, :sampler_version, @default_sampler_version)
    dedupe_key = "#{tenant_id}:#{trace_id}:#{sample_window}"

    {:ok,
     %{
       trace_id: trace_id,
       tenant_id: tenant_id,
       workflow_run_id: workflow_run_id,
       workflow_step_id: workflow_step_id,
       dedupe_key: dedupe_key,
       scorer: scorer,
       evidence_refs: evidence_refs,
       promotion_snapshot: promotion_snapshot,
       sampling_metadata: %{
         "sample_reason" => sample_reason,
         "sample_window" => sample_window,
         "sampler_version" => sampler_version,
         "dedupe_key" => dedupe_key
       }
     }}
  rescue
    error in [ArgumentError] -> {:error, error}
  end

  defp fetch_trace(trace_id) do
    case Repo.get(Trace, trace_id) do
      %Trace{} = trace -> {:ok, trace}
      nil -> {:error, ArgumentError.exception("trace_id must reference a persisted trace")}
    end
  end

  defp validate_workflow_lineage(payload, %Trace{} = trace) do
    with %Run{} = run <- Repo.get(Run, payload.workflow_run_id),
         %Step{} = step <- Repo.get(Step, payload.workflow_step_id),
         true <- step.run_id == run.id,
         true <- run.session_id == trace.session_id,
         true <- run.tenant_id == payload.tenant_id do
      :ok
    else
      nil ->
        {:error, ArgumentError.exception("workflow lineage must reference persisted run and step rows")}

      false ->
        {:error,
         ArgumentError.exception(
           "workflow lineage must belong to the sampled trace session and tenant"
         )}
    end
  end

  defp ensure_production_trace(%Trace{} = trace) do
    env =
      trace.attributes
      |> normalize_map()
      |> Map.get("env")

    if env in ["prod", "production"], do: :ok, else: {:ignored, :ineligible_trace}
  end

  defp allow_test_processes(opts, caller) do
    repo = Keyword.get(opts, :sandbox_repo)

    owner =
      Keyword.get_lazy(opts, :sandbox_owner, fn ->
        Keyword.get(opts, :notify, caller)
      end)

    if repo && owner do
      Ecto.Adapters.SQL.Sandbox.allow(repo, owner, self())
    end
  rescue
    _ -> :ok
  end

  defp fetch_attr!(attrs, key) do
    case fetch_attr(attrs, key) do
      nil -> raise ArgumentError, "missing required online scoring attribute #{key}"
      value -> value
    end
  end

  defp fetch_attr(attrs, key, default \\ nil) when is_map(attrs) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key)) || default
  end

  defp normalize_map(nil), do: %{}

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {to_string(key), normalize_value(value)}
    end)
  end

  defp normalize_value(value) when is_map(value), do: normalize_map(value)
  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
  defp normalize_value(value), do: value
end
