# Phase 40: Online Scoring & Review Queue - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 18
**Analogs found:** 16 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `priv/repo/migrations/*_create_online_scoring_review_queue.exs` | migration | CRUD | `priv/repo/migrations/20260521000000_create_eval_campaigns_and_targets.exs` | role-match |
| `lib/scoria/eval/online_scoring.ex` | service | event-driven | `lib/scoria/eval/campaign_enqueuer.ex` | exact |
| `lib/scoria/eval/online_score_candidate.ex` | model | CRUD | `lib/scoria/eval/eval_campaign_target.ex` | role-match |
| `lib/scoria/eval/score.ex` | model | CRUD | `lib/scoria/eval/score.ex` | exact |
| `lib/scoria/eval/eval_run.ex` | model | CRUD | `lib/scoria/eval/eval_run.ex` | exact |
| `lib/scoria/eval/campaign_enqueuer.ex` | service | event-driven | `lib/scoria/eval/campaign_enqueuer.ex` | exact |
| `lib/scoria/eval/campaign_worker.ex` | worker | event-driven | `lib/scoria/eval/campaign_worker.ex` | exact |
| `lib/scoria/eval/judge_runner.ex` | service | transform | `lib/scoria/eval/judge_runner.ex` | exact |
| `lib/scoria/eval/review_queue.ex` | service | request-response | `lib/scoria/workflows/remote_approval_projection.ex` | exact |
| `lib/scoria_web/live/orchestrator_live.ex` | liveview | request-response | `lib/scoria_web/live/orchestrator_live.ex` | exact |
| `lib/scoria_web/live/review_queue_live.ex` | liveview | request-response | `lib/scoria_web/live/orchestrator_live.ex` | role-match |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | component | request-response | `lib/scoria_web/live/dataset_live/promote_component.ex` | exact |
| `test/scoria/eval/campaign_enqueue_test.exs` | test | event-driven | `test/scoria/eval/campaign_enqueue_test.exs` | exact |
| `test/scoria/eval/campaign_worker_test.exs` | test | event-driven | `test/scoria/eval/campaign_worker_test.exs` | exact |
| `test/scoria/eval/eval_run_persistence_test.exs` | test | CRUD | `test/scoria/eval/eval_run_persistence_test.exs` | exact |
| `test/scoria/eval/judge_runner_test.exs` | test | transform | `test/scoria/eval/judge_runner_test.exs` | exact |
| `test/scoria/workflows/remote_approval_projection_test.exs` | test | request-response | `test/scoria/workflows/remote_approval_projection_test.exs` | exact |
| `test/scoria_web/live/orchestrator_live_test.exs` | test | request-response | `test/scoria_web/live/orchestrator_live_test.exs` | exact |
| `test/scoria_web/live/dataset_live/promote_component_test.exs` | test | request-response | `test/scoria_web/live/dataset_live/promote_component_test.exs` | exact |

## Pattern Assignments

### `lib/scoria/eval/online_scoring.ex` (service, event-driven)

**Analog:** `lib/scoria/eval/campaign_enqueuer.ex`

**Imports + transaction boundary** (`lib/scoria/eval/campaign_enqueuer.ex:4-9`)
```elixir
alias Ecto.Changeset
alias Ecto.Multi
alias Scoria.Eval
alias Scoria.Eval.{CampaignWorker, EvalCampaign, EvalCampaignTarget, EvalRun, EvalSpec}
alias Scoria.Repo
alias Scoria.Workflows.BatchEnqueue
```

**Persist first, enqueue second** (`lib/scoria/eval/campaign_enqueuer.ex:35-64`)
```elixir
multi =
  Multi.new()
  |> Multi.insert(
    :campaign,
    EvalCampaign.changeset(
      %EvalCampaign{},
      campaign_attrs(attrs, tenant_id, eval_spec.id, normalized_targets)
    )
  )
  |> Multi.run(:targets, fn repo, %{campaign: campaign} ->
    insert_targets(repo, campaign, eval_spec.id, normalized_targets)
  end)
  |> Multi.run(:eval_runs, fn repo, %{campaign: campaign, targets: targets} ->
    insert_eval_runs(repo, campaign, eval_spec, targets)
  end)

with {:ok, %{campaign: campaign, targets: targets, eval_runs: eval_runs}} <-
       Repo.transaction(multi) do
  jobs = build_jobs(campaign, targets, eval_runs)
```

**Batch enqueue + rollup update** (`lib/scoria/eval/campaign_enqueuer.ex:64-94`)
```elixir
case BatchEnqueue.enqueue_all(jobs, batch_opts) do
  {:ok, enqueue_results} ->
    {:ok, campaign} =
      campaign
      |> Ecto.Changeset.change(%{
        status: "queued",
        total_targets: length(targets),
        queued_targets: length(targets),
        running_targets: 0,
        completed_targets: 0,
        failed_targets: 0,
        cancelled_targets: 0,
        last_progress_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      })
      |> Repo.update()
```

**Public seam to preserve** (`lib/scoria/eval.ex:246-250`)
```elixir
@doc """
Creates a campaign, child target rows, child eval runs, and batch-enqueues worker jobs.
"""
def create_and_enqueue_campaign(attrs, opts \\ []) when is_map(attrs) do
  CampaignEnqueuer.enqueue_campaign(attrs, opts)
end
```

**Apply to Phase 40:** `online_scoring.ex` should own candidate sampling and persistence, then call the existing enqueue path. Do not score inline and do not bypass `Ecto.Multi`.

---

### `lib/scoria/eval/online_score_candidate.ex` (model, CRUD)

**Analog:** `lib/scoria/eval/eval_campaign_target.ex`

**Schema posture** (`lib/scoria/eval/eval_campaign_target.ex:22-38`)
```elixir
schema "ai_eval_campaign_targets" do
  field(:tenant_id, :string)
  field(:provider, :string)
  field(:model, :string)
  field(:queue, :string)
  field(:priority, :integer)
  field(:status, :string, default: "pending")
  field(:metadata, :map, default: %{})
  field(:started_at, :utc_datetime_usec)
  field(:finished_at, :utc_datetime_usec)
  field(:last_error, :map, default: %{})
```

**Changeset contract** (`lib/scoria/eval/eval_campaign_target.ex:40-64`)
```elixir
target
|> cast(attrs, [
  :campaign_id,
  :eval_spec_id,
  :tenant_id,
  :provider,
  :model,
  :queue,
  :priority,
  :status,
  :metadata,
  :started_at,
  :finished_at,
  :last_error
])
|> validate_required([:campaign_id, :eval_spec_id, :tenant_id, :provider, :model, :status])
|> validate_inclusion(:status, @statuses)
|> validate_number(:priority, greater_than_or_equal_to: 0)
```

**Migration pattern** (`priv/repo/migrations/20260521000000_create_eval_campaigns_and_targets.exs:30-56`)
```elixir
create table(:ai_eval_campaign_targets, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :campaign_id, references(:ai_eval_campaigns, on_delete: :delete_all, type: :binary_id),
    null: false
  add :eval_spec_id, references(:ai_eval_specs, on_delete: :nothing, type: :binary_id),
    null: false
  add :tenant_id, :string, null: false
  add :provider, :string, null: false
  add :model, :string, null: false
  add :queue, :string
  add :priority, :integer
  add :status, :string, null: false, default: "pending"
  add :metadata, :map, null: false, default: %{}
  add :last_error, :map, null: false, default: %{}
```

**Apply to Phase 40:** candidate rows should look like runtime-owned durable queue rows: identity fields, `status`, provenance/score metadata in `:map`, timestamps, and explicit indexes for queue reads.

---

### `lib/scoria/eval/score.ex` and `lib/scoria/eval/eval_run.ex` (model, CRUD)

**Analogs:** `lib/scoria/eval/score.ex`, `lib/scoria/eval/eval_run.ex`, plus the callers/tests already expecting richer fields.

**Current `Score` schema is too narrow** (`lib/scoria/eval/score.ex:7-24`)
```elixir
schema "ai_scores" do
  field :score, :float
  field :reasoning, :string
  field :details, :map

  belongs_to :eval_run, Scoria.Eval.EvalRun
  belongs_to :dataset_item, Scoria.Eval.DatasetItem, type: :id
end
```

**Current callers already expect richer score attrs** (`lib/scoria/eval/judge_runner.ex:104-114`)
```elixir
score_attrs = %{
  dataset_item_id: dataset_item.id,
  scorer_kind: eval_spec.scorers |> List.first() |> Map.get(:scorer_kind) |> to_string(),
  status: Map.get(verdict, "status", "failed"),
  score: Map.get(verdict, "score", 0.0),
  explanation: Map.get(verdict, "explanation", "Judge verdict unavailable"),
  judge_model: fetch(attrs, :judge_model) || fetch!(attrs, :model),
  rubric_version: "eval-spec-v#{eval_spec.version}",
  evidence_refs: Map.get(verdict, "evidence_refs", %{}),
  metadata: %{"cost_usd" => "0.0", "latency_ms" => 0}
}
```

**`EvalRun` already carries campaign lineage and judge-model fields** (`lib/scoria/eval/eval_run.ex:7-38`)
```elixir
schema "ai_eval_runs" do
  field(:runner_mode, Ecto.Enum, values: [:offline_replay, :live_judge, :refresh_capture])
  field(:status, :string, default: "pending")
  field(:tenant_id, :string)
  field(:provider, :string)
  field(:model, :string)
  field(:judge_provider, :string)
  field(:judge_model, :string)
  field(:threshold_verdict, :string)
  belongs_to(:campaign, Scoria.Eval.EvalCampaign)
  belongs_to(:campaign_target, Scoria.Eval.EvalCampaignTarget)
  has_many(:scores, Scoria.Eval.Score)
```

**Persistence test that should be extended, not replaced** (`test/scoria/eval/eval_run_persistence_test.exs:51-64`)
```elixir
assert {:ok, eval_run, [%Score{}]} =
         Eval.record_eval_scores(eval_run, [
           %{
             dataset_item_id: dataset_item.id,
             scorer_kind: "llm_judge",
             status: "passed",
             score: 0.95,
             explanation: "Answer matches the sealed expected output",
             judge_model: "gpt-4o",
             rubric_version: "judge-rubric-v2",
             evidence_refs: %{"fixture_key" => "prompt-v3/dataset-v2026.05.19/spec-v1"},
             metadata: %{"latency_ms" => 42, "cost_usd" => "0.0004"}
           }
         ])
```

**Apply to Phase 40:** treat score-field expansion as a prerequisite. Persist scorer kind/version, judge model, sampling provenance, rationale, and evidence at the score boundary, because the rest of the code and tests already assume that shape.

---

### `lib/scoria/eval/campaign_worker.ex` and `lib/scoria/eval/judge_runner.ex` (worker/service, event-driven + transform)

**Analogs:** `lib/scoria/eval/campaign_worker.ex`, `lib/scoria/eval/judge_runner.ex`

**Oban worker uniqueness + required args** (`lib/scoria/eval/campaign_worker.ex:6-18`)
```elixir
use Oban.Worker,
  queue: :evals,
  unique: [
    period: 60,
    fields: [:worker, :args],
    keys: [:eval_run_id],
    states: [:available, :scheduled, :executing, :retryable]
  ]

@required_keys ~w(campaign_id campaign_target_id eval_run_id tenant_id eval_spec_id provider model)
```

**Perform/error flow** (`lib/scoria/eval/campaign_worker.ex:20-35`)
```elixir
with {:ok, context} <- Eval.load_campaign_execution(args),
     :ok <- maybe_mark_running(context),
     {:ok, result} <- Eval.execute_campaign_target(context),
     {:ok, _campaign} <- Eval.complete_campaign_target(context, result) do
  :ok
else
  {:error, reason} ->
    with {:ok, context} <- Eval.load_campaign_execution(args) do
      fatal? = Eval.fatal_campaign_failure?(reason)
      {:ok, _campaign} = Eval.fail_campaign_target(context, reason, fatal?: fatal?)
    end

    {:error, reason}
end
```

**Judge scoring contract** (`lib/scoria/eval/judge_runner.ex:60-79`)
```elixir
with {:ok, score_attrs} <-
       build_score_attrs(eval_run, eval_spec, dataset, attrs, model_spec, orchestrator_module, opts) do
  case Eval.replace_eval_scores(eval_run, score_attrs) do
    {:ok, updated_run, scores} -> {:ok, updated_run, scores}
    {:error, reason} -> {:error, reason}
  end
end
```

**Deterministic/judge seam to preserve** (`lib/scoria/eval/judge_runner.ex:96-123`)
```elixir
Enum.reduce_while(dataset_items, {:ok, []}, fn dataset_item, {:ok, acc} ->
  ...
  case orchestrator_module.generate_object(model_spec, prompt, judge_schema(), opts) do
    {:ok, response} ->
      verdict = extract_object(response)
      score_attrs = %{...}
      {:cont, {:ok, [score_attrs | acc]}}
```

**Apply to Phase 40:** keep the worker envelope thin and idempotent. Put deterministic-first scoring ahead of optional judge calls, but still persist via `replace_eval_scores/2` so worker replay stays safe.

---

### `lib/scoria/eval/review_queue.ex` (service, request-response)

**Analog:** `lib/scoria/workflows/remote_approval_projection.ex`

**Projection entrypoints** (`lib/scoria/workflows/remote_approval_projection.ex:13-28`)
```elixir
def list_pending_approvals(filters \\ %{}) do
  filters = normalize_filters(filters)

  Approval
  |> where([approval], approval.status == "pending")
  |> apply_filters(filters)
  |> order_by([approval], desc: approval.inserted_at, desc: approval.id)
  |> Repo.all()
  |> Enum.map(&project_approval/1)
end

def get_approval_lineage!(approval_id) do
  Approval
  |> Repo.get!(approval_id)
  |> project_approval()
end
```

**Filter reducer** (`lib/scoria/workflows/remote_approval_projection.ex:30-37`)
```elixir
defp apply_filters(query, filters) do
  Enum.reduce(@filter_fields, query, fn field, query ->
    case Map.get(filters, field) do
      nil -> query
      value -> where(query, [approval], field(approval, ^field) == ^value)
    end
  end)
end
```

**Projected row shape** (`lib/scoria/workflows/remote_approval_projection.ex:39-80`)
```elixir
%{
  id: approval.id,
  workflow_run_id: approval.workflow_run_id,
  step_id: approval.step_id,
  status: approval.status,
  tool_name: approval.tool_name,
  trace_id: approval.trace_id,
  replay_disposition: approval.replay_disposition,
  replay_reason_code: approval.replay_reason_code,
  replay_scope: approval.replay_scope,
  source_run_id: approval.source_run_id,
  source_checkpoint_id: approval.source_checkpoint_id,
  baseline_target: baseline_target,
  inserted_at: approval.inserted_at,
  updated_at: approval.updated_at
}
```

**Apply to Phase 40:** build the review queue as a projection module, not page-local joins. Return operator-ready rows with severity, scorer metadata, rationale, trace/workflow IDs, promotion state, and deep-link targets already computed.

---

### `lib/scoria_web/live/orchestrator_live.ex` or `lib/scoria_web/live/review_queue_live.ex` (liveview, request-response)

**Analog:** `lib/scoria_web/live/orchestrator_live.ex`

**Mount/subscription/assign posture** (`lib/scoria_web/live/orchestrator_live.ex:31-63`)
```elixir
def mount(_params, session, socket) do
  tenant_id = session["tenant_id"] || "default"

  if connected?(socket) do
    Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
    Phoenix.PubSub.subscribe(Scoria.PubSub, "mcp:runtimes:#{tenant_id}")
  end

  socket =
    socket
    |> assign(:page_title, "Scoria Dashboard")
    |> assign(:active_approval, nil)
    |> assign(:approval_inbox, [])
    |> assign(:incident_evidence, nil)
    |> assign(:replay_notice, nil)
    |> assign(:promote_notice, nil)

  {:ok, load_operator_surface(socket)}
end
```

**Lazy async load pattern** (`lib/scoria_web/live/orchestrator_live.ex:145-173`)
```elixir
def handle_event("load_retrieval_evidence", %{"id" => trace_id}, socket) do
  {:noreply,
   assign_async(socket, :retrieval_evidence, fn ->
     {:ok, %{retrieval_evidence: sample_evidence(trace_id)}}
   end)}
end

def handle_event("load_incident_evidence", params, socket) do
  ...
  |> assign_async(:incident_evidence, fn ->
    {:ok, %{incident_evidence: load_incident_projection(trace_id, run_id)}}
  end)}
end
```

**Operator-surface refresh helper** (`lib/scoria_web/live/orchestrator_live.ex:812-842`)
```elixir
defp load_operator_surface(socket) do
  tenant_id = socket.assigns.tenant_id
  ...
  socket
  |> assign(:approval_inbox, Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id}))
  |> assign(:connector_fleet, Connectors.list_connector_fleet(%{tenant_id: tenant_id}))
  |> assign(:runtimes, runtimes)
end
```

**Render structure to copy** (`lib/scoria_web/live/orchestrator_live.ex:193-275`)
```elixir
<div class="mb-6 grid gap-6 xl:grid-cols-[minmax(0,1.1fr)_minmax(18rem,0.9fr)]">
  <ApprovalInboxComponent.render approvals={@approval_inbox} />
  ...
</div>

<div id="traces-list" phx-update="stream" class="space-y-4">
  <div :for={{id, trace} <- @streams.traces} id={id} class="bg-white p-4 rounded shadow">
```

**Apply to Phase 40:** use the same LiveView shape for the review queue page or queue panel: top-level loader helper, async details panel, event-driven row actions, and persistent success/error notices.

---

### `lib/scoria_web/live/dataset_live/promote_component.ex` (component, request-response)

**Analog:** `lib/scoria_web/live/dataset_live/promote_component.ex`

**Update/load groups pattern** (`lib/scoria_web/live/dataset_live/promote_component.ex:10-29`)
```elixir
promotion_context = assigns[:promotion_context] || %{}
form_params = socket.assigns[:form_params] || initial_form_params(promotion_context)
{open_datasets, sealed_datasets} = load_dataset_groups()
selected_open_dataset_id = selected_open_dataset_id(form_params, open_datasets)
baseline_target_id = socket.assigns[:baseline_target_id]
baseline_target = find_dataset(sealed_datasets, baseline_target_id)
mode = if(socket.assigns[:mode] == :baseline_confirm and baseline_target, do: :baseline_confirm, else: :draft)
```

**Draft promotion submit path** (`lib/scoria_web/live/dataset_live/promote_component.ex:65-85`)
```elixir
with true <- changeset.valid?,
     {:ok, expected_output} <- decode_expected_output(get_field(changeset, :expected_output)),
     dataset_id when is_integer(dataset_id) <- get_field(changeset, :dataset_id),
     promotion_attrs <- build_promotion_attrs(socket.assigns.promotion_context, dataset_id, get_field(changeset, :notes), expected_output),
     {:ok, _item} <- Eval.promote_workflow_source(promotion_attrs) do
  dataset = Eval.get_dataset!(dataset_id)
  send(self(), {:promote_successful, %{source_variant: ..., dataset_name: dataset.name, dataset_version: dataset.version}})
```

**Approval-gated baseline path** (`lib/scoria_web/live/dataset_live/promote_component.ex:110-127`)
```elixir
with true <- changeset.valid?,
     %{} = dataset <- baseline_target,
     {:ok, expected_output} <- decode_expected_output(get_field(changeset, :expected_output)),
     request_attrs <- build_promotion_attrs(socket.assigns.promotion_context, dataset.id, get_field(changeset, :notes), expected_output),
     {:ok, _approval} <- Workflows.request_baseline_promotion(request_attrs) do
  send(self(), {:baseline_promotion_requested, %{dataset_name: dataset.name, dataset_version: dataset.version}})
```

**UI copy/state split** (`lib/scoria_web/live/dataset_live/promote_component.ex:221-353`)
```elixir
<%= if @mode == :baseline_confirm do %>
  <section class="rounded-2xl border border-amber-200 bg-amber-50 p-5">
    <p class="text-xs font-semibold uppercase tracking-[0.18em] text-amber-700">Approval required</p>
...
<button
  :if={@mode == :draft}
  type="submit"
  phx-disable-with="Promoting snapshot..."
  class="rounded-xl bg-blue-600 ..."
>
  Promote snapshot
</button>
```

**Apply to Phase 40:** reuse this exact promotion/approval split for review-queue actions. Open datasets go through `Eval`, sealed baselines go through `Workflows`, and the component keeps form state on failure.

---

### Tests for Phase 40 seams

**Async enqueue contract:** `test/scoria/eval/campaign_enqueue_test.exs`

**What to copy** (`test/scoria/eval/campaign_enqueue_test.exs:22-41`, `:79-91`, `:95-135`)
```elixir
assert {:ok, result} =
         Eval.create_and_enqueue_campaign(%{...}, chunk_size: 2)

assert %{"batch_0" => [job_1, job_2], "batch_1" => [job_3]} = result.enqueue_results

assert_enqueued(
  worker: CampaignWorker,
  queue: :evals,
  args: %{
    "campaign_id" => campaign.id,
    "campaign_target_id" => target.id,
    "eval_run_id" => eval_run.id,
    "tenant_id" => target.tenant_id,
    "eval_spec_id" => eval_spec.id
  }
)
```

Use this for sampling/enqueue tests: assert both durable candidate/campaign rows and the exact Oban args.

**Worker persistence and idempotency:** `test/scoria/eval/campaign_worker_test.exs`

**What to copy** (`test/scoria/eval/campaign_worker_test.exs:90-132`, `:134-164`, `:186-202`)
```elixir
assert :ok = CampaignWorker.perform(%Job{args: job.args})
assert [%Score{} = score] = Repo.all(from(score in Score, where: score.eval_run_id == ^eval_run.id))
assert score.status == "passed"
assert score.explanation == "Stubbed judge verdict"
assert score.evidence_refs["judge"] == "stub"

assert {:error, :transient_provider_failure} = CampaignWorker.perform(%Job{args: job_2.args})
assert campaign.status == "completed_partial"

assert :ok = CampaignWorker.perform(%Job{args: job.args})
assert :ok = CampaignWorker.perform(%Job{args: job.args})
assert Repo.aggregate(from(score in Score, where: score.eval_run_id == ^eval_run.id), :count) == 1
```

Use this for deterministic/judge score persistence, failure isolation, and retry-safe review-item generation.

**Score-schema persistence:** `test/scoria/eval/eval_run_persistence_test.exs`

**What to copy** (`test/scoria/eval/eval_run_persistence_test.exs:37-64`, `:95-105`)
```elixir
assert {:ok, eval_run, [%Score{}]} =
         Eval.record_eval_scores(eval_run, [%{..., scorer_kind: "llm_judge", status: "passed", explanation: "...", judge_model: "gpt-4o", evidence_refs: %{}, metadata: %{...}}])

assert persisted_score.scorer_kind == "llm_judge"
assert persisted_score.status == "passed"
assert persisted_score.explanation == "Answer matches the sealed expected output"
assert persisted_score.judge_model == "gpt-4o"
```

Use this as the baseline for expanding `Score` rather than inventing a new persistence test style.

**Judge-only seam:** `test/scoria/eval/judge_runner_test.exs`

**What to copy** (`test/scoria/eval/judge_runner_test.exs:23-45`)
```elixir
assert {:ok, result} =
         JudgeRunner.run_live(%{..., req_llm_module: ReqLLMStub})

assert_received {:req_llm_called, "openai:gpt-4o-mini", _prompt}
assert [score] = result.scores
assert score.scorer_kind == "llm_judge"
assert score.status == "passed"
assert score.judge_model == "gpt-4o-mini"
```

Use this for optional judge scoring only. Deterministic-first logic should get its own analogous persistence assertions in the worker tests.

**Projection seam:** `test/scoria/workflows/remote_approval_projection_test.exs`

**What to copy** (`test/scoria/workflows/remote_approval_projection_test.exs:15-72`, `:136-202`)
```elixir
assert [%{id: approval_id, workflow_run_id: workflow_run_id, replay_scope: "replay_live", source_run_id: source_run_id}] =
         Workflows.list_pending_remote_approvals(%{tenant_id: "tenant-replay"})

assert [%{tool_name: "dataset_baseline_promotion", baseline_target: %{dataset_name: "Release QA", source_variant: "replay"}}] =
         Workflows.list_pending_approvals(%{tenant_id: "tenant-baseline", tool_name: "dataset_baseline_promotion"})
```

Use this to lock queue-row projection fields, not raw schemas.

**LiveView/operator queue seam:** `test/scoria_web/live/orchestrator_live_test.exs`

**What to copy** (`test/scoria_web/live/orchestrator_live_test.exs:90-105`, `:129-167`, `:170-187`)
```elixir
send(view.pid, {:new_trace, trace})
assert render(view) =~ "trace-tree"

render_click(view, "load_incident_evidence", %{"id" => "trace-combined"})
render_async(view)
assert render(view) =~ "Composite health rollup"

render_click(view, "replay_retrieval", %{"id" => "trace-actions"})
render_click(view, "promote_retrieval", %{"id" => "trace-actions"})
assert render(view) =~ "replay_retrieval"
assert render(view) =~ "promote_retrieval"
```

Use this shape for queue-row interactions, lazy detail loading, and operator notices.

**Promotion component seam:** `test/scoria_web/live/dataset_live/promote_component_test.exs`

**What to copy** (`test/scoria_web/live/dataset_live/promote_component_test.exs:89-122`, `:124-168`, `:170-224`)
```elixir
assert html =~ "Sealed baseline"
assert html =~ "Approval required"

render_submit(element(view, "form"), %{"promotion" => %{"dataset_id" => "#{open_dataset.id}", "notes" => "operator note"}})
assert render(view) =~ "promote:original:Draft QA:1.0"

render_click(view, "request_baseline_approval")
assert render(view) =~ "baseline:Release QA:7"
assert Eval.list_dataset_items(sealed_dataset.id) == []
```

Use this for review-item promotion/approval actions. Keep the test style inside an isolated LiveView with notice messages from `handle_info/2`.

## Shared Patterns

### Async Sampling + Oban enqueue
**Source:** `lib/scoria/eval/campaign_enqueuer.ex:35-94`, `lib/scoria/eval/campaign_worker.ex:20-42`

Apply to all sampling/execution files:
```elixir
with {:ok, %{...}} <- Repo.transaction(multi) do
  jobs = build_jobs(...)
  case BatchEnqueue.enqueue_all(jobs, batch_opts) do
    {:ok, enqueue_results} -> ...
  end
end
```

```elixir
with {:ok, context} <- Eval.load_campaign_execution(args),
     :ok <- maybe_mark_running(context),
     {:ok, result} <- Eval.execute_campaign_target(context) do
  ...
end
```

### Projection reads, not UI joins
**Source:** `lib/scoria/workflows/remote_approval_projection.ex:13-80`

Apply to review queue listing and detail reads:
```elixir
query
|> apply_filters(filters)
|> order_by(...)
|> Repo.all()
|> Enum.map(&project_row/1)
```

### Promotion/approval split
**Source:** `lib/scoria/eval/dataset_promotion.ex:35-54`, `lib/scoria/workflows/dataset_promotion.ex:24-55`, `lib/scoria_web/live/dataset_live/promote_component.ex:65-127`

Apply to review-item actions:
```elixir
{:ok, _item} <- Eval.promote_workflow_source(promotion_attrs)
{:ok, _approval} <- Workflows.request_baseline_promotion(request_attrs)
```

### LiveView queue state
**Source:** `lib/scoria_web/live/orchestrator_live.ex:31-63`, `:145-173`, `:812-842`

Apply to queue UI:
```elixir
socket
|> assign(:page_title, ...)
|> assign(:notice, nil)
|> assign_async(:detail_panel, fn -> ... end)
```

### Score persistence warning
**Source:** `lib/scoria/eval/score.ex:7-24`, `lib/scoria/eval/judge_runner.ex:104-114`, `test/scoria/eval/eval_run_persistence_test.exs:51-64`

Apply to planning:
- Treat `Score` schema expansion as Wave 0 or an explicit prerequisite slice.
- Do not build the review queue on top of `reasoning/details` only; the rest of the code already expects `status`, `explanation`, `evidence_refs`, `metadata`, and scorer fields.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/scoria/eval/review_queue_item.ex` | model | CRUD | No existing persisted operator review-item table exists; closest analogs are campaign targets and approval projections, but neither is a direct review-queue row. |
| `lib/scoria_web/live/review_queue_live.ex` | liveview | request-response | No dedicated operator queue LiveView exists yet; the closest UI analog is `OrchestratorLive`, but it is dashboard-oriented rather than queue-specific. |

## Metadata

**Analog search scope:** `lib/scoria/eval`, `lib/scoria/workflows`, `lib/scoria_web/live`, `priv/repo/migrations`, `test/scoria/eval`, `test/scoria/workflows`, `test/scoria_web/live`
**Files scanned:** 24
**Pattern extraction date:** 2026-05-23
