# Phase 25: CI/CD Regression & Evaluation Framework - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 17
**Analogs found:** 15 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/eval.ex` | service | CRUD | `lib/scoria/eval.ex` | exact |
| `lib/scoria/eval/eval_spec.ex` | model | CRUD | `lib/scoria/eval/eval_spec.ex` | exact |
| `lib/scoria/eval/eval_run.ex` | model | CRUD | `lib/scoria/knowledge/retrieval_run.ex` | role-match |
| `lib/scoria/eval/score.ex` | model | CRUD | `lib/scoria/knowledge/grounding_score.ex` | role-match |
| `lib/scoria/eval/runner.ex` | service | batch | `lib/scoria/eval.ex` | flow-match |
| `lib/scoria/eval/fixture_key.ex` | utility | transform | `lib/scoria/prompt_registry.ex` | partial |
| `lib/scoria/eval/refresh.ex` | service | file-I/O | `lib/scoria/eval.ex` | partial |
| `lib/mix/tasks/scoria.eval.ex` | config | batch | `lib/mix/tasks/scoria.eval.ex` | exact |
| `lib/mix/tasks/scoria.eval.refresh.ex` | config | file-I/O | `lib/mix/tasks/scoria.pgvector.bootstrap.ex` | role-match |
| `test/support/eval_case.ex` | test | request-response | `test/support/eval_case.ex` | exact |
| `test/mix/tasks/scoria.eval_test.exs` | test | batch | `test/mix/tasks/scoria.eval_test.exs` | exact |
| `test/scoria/eval/offline_runner_test.exs` | test | batch | `test/scoria/eval_test.exs` | flow-match |
| `test/scoria/eval/eval_run_persistence_test.exs` | test | CRUD | `test/scoria/eval_test.exs` | flow-match |
| `test/scoria/eval/replay_contract_test.exs` | test | file-I/O | `test/scoria/eval_test.exs` | partial |
| `priv/repo/migrations/*_converge_eval_persistence.exs` | migration | transform | `priv/repo/migrations/20260510174619_create_eval_tables.exs` | role-match |
| `mix.exs` | config | request-response | `mix.exs` | exact |
| `test/fixtures/eval/**` | test | file-I/O | none | none |

## Pattern Assignments

### `lib/scoria/eval.ex` (service, CRUD)

**Analog:** `lib/scoria/eval.ex`

**Imports + context alias pattern** (`lib/scoria/eval.ex:6-11`):
```elixir
import Ecto.Query, warn: false
alias Scoria.Repo

alias Scoria.Eval.Dataset
alias Scoria.Eval.DatasetItem
alias Scoria.Eval.EvalSpec
```

**Multi-backed create pattern** (`lib/scoria/eval.ex:29-57`):
```elixir
def create_dataset(attrs \\ %{}) do
  {items, dataset_attrs} = Map.pop(attrs, :items, [])

  attrs_with_defaults =
    dataset_attrs
    |> Map.put_new(:version, "1")

  Ecto.Multi.new()
  |> Ecto.Multi.insert(:dataset, Dataset.changeset(%Dataset{}, attrs_with_defaults))
  |> Ecto.Multi.run(:items, fn repo, %{dataset: dataset} ->
    items_results =
      Enum.map(items, fn item_attrs ->
        item_attrs_with_fk = Map.put(item_attrs, :dataset_id, dataset.id)
        %DatasetItem{}
        |> DatasetItem.changeset(item_attrs_with_fk, dataset.state)
        |> repo.insert()
      end)

    case Enum.find(items_results, fn {status, _} -> status == :error end) do
      nil -> {:ok, Enum.map(items_results, fn {:ok, item} -> item end)}
      {:error, changeset} -> {:error, changeset}
    end
  end)
  |> Repo.transaction()
  |> case do
    {:ok, %{dataset: dataset}} -> {:ok, dataset}
    {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
  end
end
```

**Immutable versioning pattern** (`lib/scoria/eval.ex:145-166`):
```elixir
def update_eval_spec(%EvalSpec{} = old_spec, attrs) do
  new_version = old_spec.version + 1
  old_spec_changeset = Ecto.Changeset.change(old_spec, is_current: false)

  base_struct = %EvalSpec{
    entity_id: old_spec.entity_id,
    name: old_spec.name,
    description: old_spec.description,
    rubric: old_spec.rubric,
    version: new_version,
    is_current: true
  }

  Ecto.Multi.new()
  |> Ecto.Multi.update(:deprecate_old, old_spec_changeset)
  |> Ecto.Multi.insert(:new_spec, EvalSpec.changeset(base_struct, attrs))
  |> Repo.transaction()
end
```

Use this file as the primary context/service pattern for:
- adding `EvalRun` creation and score persistence
- converging old/new eval storage behind one public API
- returning `{:ok, value}` / `{:error, changeset}` consistently

---

### `lib/scoria/eval/eval_spec.ex` (model, CRUD)

**Analog:** `lib/scoria/eval/eval_spec.ex`

**Versioned schema pattern** (`lib/scoria/eval/eval_spec.ex:5-20`):
```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
schema "ai_eval_specs" do
  field :entity_id, :binary_id
  field :version, :integer, default: 1
  field :is_current, :boolean, default: true
  field :name, :string
  field :description, :string
  field :rubric, :map

  timestamps(type: :utc_datetime_usec)
end
```

**Changeset pattern** (`lib/scoria/eval/eval_spec.ex:21-27`):
```elixir
def changeset(eval_spec, attrs) do
  eval_spec
  |> cast(attrs, [:entity_id, :version, :is_current, :name, :description, :rubric])
  |> validate_required([:entity_id, :version, :is_current, :name, :rubric])
  |> unique_constraint([:entity_id, :version])
end
```

Planner note: keep the `binary_id` + `version` + `is_current` shape, but Phase 25 should replace the untyped `rubric` map with explicit fields or typed embeds. There is no local embed analog in this repo.

---

### `lib/scoria/eval/eval_run.ex` (model, CRUD)

**Analog:** `lib/scoria/knowledge/retrieval_run.ex`

**Run header schema pattern** (`lib/scoria/knowledge/retrieval_run.ex:5-24`):
```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id

schema "ai_retrieval_runs" do
  field :query_text, :string
  field :backend, :string
  field :retriever, :string
  field :top_k, :integer, default: 5
  field :filters, :map, default: %{}
  field :trace_id, :binary_id
  field :span_id, :binary_id
  field :status, :string, default: "pending"
  field :latency_ms, :integer
  field :metadata, :map, default: %{}

  has_many :results, Scoria.Knowledge.RetrievalResult
  has_many :grounding_scores, Scoria.Knowledge.GroundingScore
end
```

**Current eval-run association baseline** (`lib/scoria/eval/eval_run.ex:7-27`):
```elixir
schema "ai_eval_runs" do
  field :status, :string, default: "pending"
  field :duration_ms, :integer

  belongs_to :dataset, Scoria.Eval.Dataset
  belongs_to :eval_spec, Scoria.Eval.EvalSpec

  has_many :scores, Scoria.Eval.Score

  timestamps(type: :utc_datetime_usec)
end

def changeset(eval_run, attrs) do
  eval_run
  |> cast(attrs, [:status, :duration_ms, :dataset_id, :eval_spec_id])
  |> validate_required([:status, :dataset_id, :eval_spec_id])
  |> validate_inclusion(:status, ["pending", "running", "completed", "failed"])
  |> foreign_key_constraint(:dataset_id)
  |> foreign_key_constraint(:eval_spec_id)
end
```

Copy the `RetrievalRun` style for additional explicit header fields such as runner mode, provider/model, provenance, aggregate counts, and metadata. Keep the existing eval associations.

---

### `lib/scoria/eval/score.ex` (model, CRUD)

**Analog:** `lib/scoria/knowledge/grounding_score.ex`

**Evidence row schema pattern** (`lib/scoria/knowledge/grounding_score.ex:8-45`):
```elixir
schema "ai_grounding_scores" do
  field :scorer_kind, :string
  field :rubric_version, :string
  field :model, :string
  field :prompt_version, :string
  field :score, :float
  field :status, :string, default: "passed"
  field :reasoning, :string
  field :details, :map, default: %{}
  field :evidence_refs, :map, default: %{}
  field :metadata, :map, default: %{}

  belongs_to :retrieval_run, Scoria.Knowledge.RetrievalRun
  belongs_to :citation, Scoria.Knowledge.Citation
end

def changeset(score, attrs) do
  score
  |> cast(attrs, [
    :retrieval_run_id,
    :citation_id,
    :scorer_kind,
    :rubric_version,
    :model,
    :prompt_version,
    :score,
    :status,
    :reasoning,
    :details,
    :evidence_refs,
    :metadata
  ])
  |> validate_required([:scorer_kind, :rubric_version, :score, :status])
end
```

**Current eval-score baseline** (`lib/scoria/eval/score.ex:7-25`):
```elixir
schema "ai_scores" do
  field :score, :float
  field :reasoning, :string
  field :details, :map

  belongs_to :eval_run, Scoria.Eval.EvalRun
  belongs_to :dataset_item, Scoria.Eval.DatasetItem
end
```

Planner note: use the `GroundingScore` explicit evidence fields as the model for Phase 25 score rows, but rename away from `reasoning` if the plan wants concise explanation fields instead of raw judge reasoning.

---

### `lib/scoria/eval/runner.ex` (service, batch)

**Analog:** `lib/scoria/eval.ex`

**Dataset-item iteration seam** (`lib/scoria/eval.ex:72-86`):
```elixir
def add_dataset_item(dataset_id, attrs) do
  dataset = get_dataset!(dataset_id)

  attrs_with_fk = Map.put(attrs, :dataset_id, dataset.id)

  %DatasetItem{}
  |> DatasetItem.changeset(attrs_with_fk, dataset.state)
  |> Repo.insert()
end

def list_dataset_items(dataset_id) do
  Repo.all(from i in DatasetItem, where: i.dataset_id == ^dataset_id)
end
```

**Trace-to-dataset shaping pattern** (`lib/scoria/eval.ex:92-110`):
```elixir
item_attrs = %{
  input: %{
    "trace_id" => trace.id,
    "session_id" => trace.session_id,
    "attributes" => trace.attributes || %{}
  },
  expected_output: %{},
  metadata: %{
    "promoted_from_trace" => true,
    "span_count" => length(spans)
  }
}
```

Planner note: `Runner` will be a new module, but the local pattern is still “context function pulls rows, builds explicit per-item maps, persists through Ecto.” There is no existing local offline-eval service analog.

---

### `lib/scoria/eval/fixture_key.ex` (utility, transform)

**Analog:** `lib/scoria/prompt_registry.ex`

**Deterministic identity/defaulting pattern** (`lib/scoria/prompt_registry.ex:27-47`):
```elixir
entity_id = Map.get(attrs, :entity_id) || Map.get(attrs, "entity_id") || Ecto.UUID.generate()

attrs_with_defaults =
  attrs
  |> Map.put(:entity_id, entity_id)
  |> Map.put(:version, 1)
  |> Map.put(:status, "draft")
  |> Map.put(:is_current, true)
  |> Map.put(:estimated_tokens, estimated_tokens)
```

**Immutable carry-forward pattern** (`lib/scoria/prompt_registry.ex:57-76`):
```elixir
base_attrs = Map.take(old_template, [:entity_id, :system_message, :few_shot_examples, :user_template])

temp_changeset = PromptTemplate.changeset(struct(PromptTemplate, base_attrs), attrs)
merged_struct = Ecto.Changeset.apply_changes(temp_changeset)
```

Use this shape for a pure key builder that derives fixture identity from immutable inputs only: prompt version, dataset version, eval spec version, and provider/model.

---

### `lib/scoria/eval/refresh.ex` (service, file-I/O)

**Analog:** `lib/scoria/eval.ex`

**Context-owned orchestration pattern** (`lib/scoria/eval.ex:29-57`):
```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:dataset, Dataset.changeset(%Dataset{}, attrs_with_defaults))
|> Ecto.Multi.run(:items, fn repo, %{dataset: dataset} -> ... end)
|> Repo.transaction()
```

There is no strong local file-I/O service analog. Keep refresh orchestration in a context/service module, and leave command-line UX to the Mix task layer.

---

### `lib/mix/tasks/scoria.eval.ex` (task, batch)

**Analog:** `lib/mix/tasks/scoria.eval.ex`

**Current task baseline** (`lib/mix/tasks/scoria.eval.ex:1-29`):
```elixir
defmodule Mix.Tasks.Scoria.Eval do
  @shortdoc "Runs LLM-as-judge evaluations for a dataset"
  @moduledoc """
  Runs LLM-as-judge evaluations over dataset items.

  ## Options
    * `--dataset` - The UUID of the dataset to evaluate
  """
  use Mix.Task

  def run(args) do
    Mix.Task.run("app.start")
    {opts, _, _} = OptionParser.parse(args, switches: [dataset: :string])
    dataset_id = Keyword.get(opts, :dataset)

    if is_nil(dataset_id) do
      Mix.raise("Missing --dataset option")
    end

    IO.puts("Starting evaluation for dataset #{dataset_id}")
  end
end
```

**Explicit secondary-lane wrapper pattern** (`lib/mix/tasks/scoria.test.knowledge.ex:7-20`):
```elixir
def run(args) do
  Mix.Task.run("loadpaths")
  Mix.Task.reenable("app.start")
  System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")

  Mix.Tasks.Scoria.Pgvector.Bootstrap.configure_runtime_env()
  Mix.Task.run("app.start")

  Mix.Task.reenable("test")
  Mix.Task.run("test", args)
end
```

Keep `mix scoria.eval` as the explicit live lane. If it needs richer flags, follow the existing `OptionParser` + `Mix.raise` pattern, not a custom CLI layer.

---

### `lib/mix/tasks/scoria.eval.refresh.ex` (task, file-I/O)

**Analog:** `lib/mix/tasks/scoria.pgvector.bootstrap.ex`

**Switch parsing + runtime bootstrap** (`lib/mix/tasks/scoria.pgvector.bootstrap.ex:11-23`):
```elixir
def run(args) do
  {opts, _argv, _invalid} = OptionParser.parse(args, switches: @switches)
  configure_runtime_env()
  Mix.Task.run("app.start")

  compose_file = Keyword.get(opts, :compose_file, @default_compose_file)

  case opts[:check] do
    true -> check_current_database!()
    _ -> provision_or_fail!(compose_file)
  end
end
```

**Operator-facing error/help text** (`lib/mix/tasks/scoria.pgvector.bootstrap.ex:40-49`):
```elixir
raise """
pgvector prerequisite failed: #{message}

Next step:
  mix scoria.pgvector.bootstrap
  export SCORIA_DB_PORT=#{@default_port}
  MIX_ENV=test mix test test/scoria/knowledge_test.exs
"""
```

**Success/info messaging** (`lib/mix/tasks/scoria.pgvector.bootstrap.ex:69-89`):
```elixir
Mix.shell().info("Starting pgvector service via #{compose_file}")

case System.cmd("docker", ["compose", "-f", compose_file, "up", "-d"], stderr_to_stdout: true) do
  {output, 0} ->
    Mix.shell().info(output)
  {output, status} ->
    Mix.raise("docker compose failed (#{status}):\n#{output}")
end
```

Use this as the direct pattern for a clearly mutating maintainer-only refresh task.

---

### `test/support/eval_case.ex` (test support, request-response)

**Analog:** `test/support/eval_case.ex`

**Case template + imports pattern** (`test/support/eval_case.ex:7-14`):
```elixir
use ExUnit.CaseTemplate

using do
  quote do
    import Scoria.EvalCase
    import Tribunal
  end
end
```

**Sandbox setup pattern** (`test/support/eval_case.ex:16-24`):
```elixir
setup tags do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)

  unless tags[:async] do
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
  end

  :ok
end
```

Planner note: extend this file rather than introducing a second eval test helper. This is the right seam for replay-only defaults and shared eval tags.

---

### `test/mix/tasks/scoria.eval_test.exs` (test, batch)

**Analog:** `test/mix/tasks/scoria.eval_test.exs`

**CaptureIO smoke-test pattern** (`test/mix/tasks/scoria.eval_test.exs:1-15`):
```elixir
defmodule Mix.Tasks.Scoria.EvalTest do
  use Scoria.EvalCase, async: false

  import ExUnit.CaptureIO

  test "runs safely and parses dataset arg" do
    output = capture_io(fn ->
      Mix.Tasks.Scoria.Eval.run(["--dataset", "00000000-0000-0000-0000-000000000000"])
    end)

    assert output =~ "Starting evaluation"
  end
end
```

Keep task tests as direct `run/1` invocations with stdout capture.

---

### `test/scoria/eval/offline_runner_test.exs` and `test/scoria/eval/eval_run_persistence_test.exs` (tests)

**Analog:** `test/scoria/eval_test.exs`

**Shared setup pattern** (`test/scoria/eval_test.exs:1-13`):
```elixir
defmodule Scoria.EvalTest do
  use ExUnit.Case

  alias Scoria.Repo
  alias Scoria.Eval

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end
end
```

**Context assertion style** (`test/scoria/eval_test.exs:19-53`):
```elixir
assert {:ok, %Dataset{} = dataset} = Eval.create_dataset(@valid_dataset_attrs)
items = Eval.list_dataset_items(dataset.id)
assert length(items) == 1

assert {:error, changeset} = Eval.add_dataset_item(dataset.id, @valid_item_attrs)
assert {"cannot add or modify items in a sealed dataset", _} = changeset.errors[:dataset_id]
```

**Immutable update assertion style** (`test/scoria/eval_test.exs:91-103`):
```elixir
assert {:ok, %EvalSpec{} = new_spec} = Eval.update_eval_spec(spec, update_attrs)
assert new_spec.version == 2
assert new_spec.is_current == true

old_spec = Repo.get(EvalSpec, spec.id)
assert old_spec.is_current == false
```

Use this shape for new runner/persistence tests: create rows through the public context, assert durable state, then assert failure conditions.

---

### `priv/repo/migrations/*_converge_eval_persistence.exs` (migration, transform)

**Analog:** `priv/repo/migrations/20260510174619_create_eval_tables.exs`

**Binary-ID + relation pattern** (`priv/repo/migrations/20260510174619_create_eval_tables.exs:31-71`):
```elixir
create table(:ai_eval_specs, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :entity_id, :binary_id, null: false
  add :version, :integer, null: false, default: 1
  add :is_current, :boolean, null: false, default: true
  add :name, :string, null: false
  add :description, :text
  add :rubric, :map, null: false
end

create table(:ai_eval_runs, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :dataset_id, references(:ai_datasets, on_delete: :nothing, type: :binary_id), null: false
  add :eval_spec_id, references(:ai_eval_specs, on_delete: :nothing, type: :binary_id), null: false
  add :status, :string, null: false, default: "pending"
  add :duration_ms, :integer
end

create table(:ai_scores, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :eval_run_id, references(:ai_eval_runs, on_delete: :delete_all, type: :binary_id), null: false
  add :dataset_item_id, references(:ai_dataset_items, on_delete: :delete_all, type: :binary_id), null: false
  add :score, :float, null: false
  add :reasoning, :text
  add :details, :map
end
```

**Canonical dataset-lineage pattern** (`priv/repo/migrations/20260518220533_create_ai_eval_datasets.exs:4-29`):
```elixir
create table(:ai_eval_datasets) do
  add :name, :string, null: false
  add :version, :string, null: false
  add :description, :string
  add :tags, {:array, :string}, default: []
  add :state, :string, default: "open", null: false
end

create table(:ai_eval_dataset_items) do
  add :dataset_id, references(:ai_eval_datasets, on_delete: :delete_all), null: false
  add :source_trace_id, :string
  add :input, :map, null: false
  add :expected_output, :map
  add :metadata, :map, default: %{}
end
```

Phase 25 migration work should copy the old eval-table relation/index style, but point all canonical references at the new `ai_eval_datasets` lineage.

---

### `mix.exs` (config)

**Analog:** `mix.exs`

**Dependency declaration pattern** (`mix.exs` current deps block):
```elixir
defp deps do
  [
    {:tribunal, "~> 1.3"},
    {:cloak, "~> 1.1"},
    {:cloak_ecto, "~> 1.3"},
    {:ecto_sql, "~> 3.10"},
    {:oban, "~> 2.19"},
    {:postgrex, ">= 0.0.0"},
    {:pgvector, "~> 0.3.0"},
    {:hammer, "~> 7.3"},
    {:fuse, "~> 2.5"},
    {:jason, "~> 1.4"},
    {:plug, "~> 1.14"},
    {:phoenix, "~> 1.7"},
    {:phoenix_live_view, "~> 1.0"},
    {:phoenix_html, "~> 4.1"},
    {:phoenix_ecto, "~> 4.4"},
    {:tiktoken, "~> 0.4.2"},
    {:floki, ">= 0.30.0", only: :test},
    {:lazy_html, ">= 0.1.0", only: :test}
  ]
end
```

Planner note: Phase 25 research explicitly points to adding `req_llm`, `req`, `req_cassette`, and `bypass` in the same flat tuple style.

## Shared Patterns

### Immutable versioned rows
**Sources:** `lib/scoria/eval.ex:145-166`, `lib/scoria/prompt_registry.ex:53-80`
**Apply to:** `EvalSpec`, any future versioned fixture-manifest row, and any canonicalized baseline references.

```elixir
new_version = old_spec.version + 1
old_spec_changeset = Ecto.Changeset.change(old_spec, is_current: false)

Ecto.Multi.new()
|> Ecto.Multi.update(:deprecate_old, old_spec_changeset)
|> Ecto.Multi.insert(:new_spec, EvalSpec.changeset(base_struct, attrs))
|> Repo.transaction()
```

### Run header + evidence row split
**Sources:** `lib/scoria/knowledge/retrieval_run.ex:8-24`, `lib/scoria/knowledge/grounding_score.ex:8-45`
**Apply to:** `EvalRun` and `Score`.

```elixir
schema "ai_retrieval_runs" do
  field :status, :string, default: "pending"
  field :latency_ms, :integer
  field :metadata, :map, default: %{}
  has_many :grounding_scores, Scoria.Knowledge.GroundingScore
end

schema "ai_grounding_scores" do
  field :scorer_kind, :string
  field :rubric_version, :string
  field :model, :string
  field :score, :float
  field :evidence_refs, :map, default: %{}
end
```

### Explicit task lanes
**Sources:** `lib/mix/tasks/scoria.eval.ex:14-29`, `lib/mix/tasks/scoria.test.knowledge.ex:7-20`, `lib/mix/tasks/scoria.pgvector.bootstrap.ex:11-23`
**Apply to:** `mix scoria.eval`, `mix scoria.eval.refresh`.

```elixir
Mix.Task.run("loadpaths")
Mix.Task.reenable("app.start")
Mix.Task.run("app.start")
{opts, _, _} = OptionParser.parse(args, switches: @switches)
```

### Shared eval test seam
**Source:** `test/support/eval_case.ex:7-24`
**Apply to:** all eval runner and mix-task tests.

```elixir
use ExUnit.CaseTemplate

using do
  quote do
    import Scoria.EvalCase
    import Tribunal
  end
end
```

### CI default lane remains `mix test`
**Source:** `.github/workflows/ci.yml:63-75`
**Apply to:** planner assumptions; do not move offline evals out of the ordinary test lane.

```yaml
- name: Prepare database
  run: |
    mix ecto.create
    mix ecto.migrate

- name: Run tests
  run: mix test
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/fixtures/eval/**` | test | file-I/O | No committed cassette/fixture directory exists yet in the repo. |
| typed `embedded_schema` modules for `EvalSpec` policy fields | model | transform | No local `embedded_schema` or `embeds_*` usage exists in `lib/` or `test/`; planner should use RESEARCH.md guidance here. |

## Metadata

**Analog search scope:** `lib/scoria/**`, `lib/mix/tasks/**`, `test/**`, `priv/repo/migrations/**`, `.github/workflows/ci.yml`, `mix.exs`
**Files scanned:** 22
**Pattern extraction date:** 2026-05-19
