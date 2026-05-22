# Phase 23: Ecto-backed Prompt Registry & Lifecycle - Pattern Map

**Mapped:** 2026-05-18
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/prompt_registry/prompt_template.ex` | model | CRUD | `lib/scoria/eval/eval_spec.ex` | exact (versioning) |
| `lib/scoria/prompt_registry.ex` | context | CRUD | `lib/scoria/eval.ex` | exact (immutable updates) |
| `priv/repo/migrations/[timestamp]_create_prompt_templates.exs` | migration | schema | `priv/repo/migrations/20260510174619_create_eval_tables.exs` | exact |
| `lib/scoria/prompt_registry/tokenizer.ex` | utility | transform | `lib/scoria/observe/redactor.ex` | role-match |

## Pattern Assignments

### `lib/scoria/prompt_registry/prompt_template.ex` (model, CRUD)

**Analog 1:** `lib/scoria/eval/eval_spec.ex` (Versioning Pattern)
**Analog 2:** `lib/scoria/sre/budget_policy.ex` (Status Validation Pattern)

**Imports & Schema pattern** (from `eval_spec.ex` lines 1-14):
```elixir
defmodule Scoria.PromptRegistry.PromptTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_prompt_templates" do
    field :entity_id, :binary_id
    field :version, :integer, default: 1
    field :is_current, :boolean, default: true
    # Add status for lifecycle, and maps for struct templates
    field :status, :string, default: "draft"
    field :system_message, :string
    field :few_shot_examples, :map, default: %{}
    field :user_template, :string

    timestamps(type: :utc_datetime_usec)
  end
```

**Status validation pattern** (from `budget_policy.ex` lines 5, 41):
```elixir
  @statuses ~w(draft active archived)

  def changeset(template, attrs) do
    template
    |> cast(attrs, [:entity_id, :version, :is_current, :status, :system_message, :few_shot_examples, :user_template])
    |> validate_required([:entity_id, :version, :is_current, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:entity_id, :version])
  end
```

---

### `lib/scoria/prompt_registry.ex` (context, CRUD)

**Analog:** `lib/scoria/eval.ex`

**Immutable update pattern** (from `eval.ex` lines 167-190):
```elixir
  @doc """
  Updates a prompt template immutably.
  """
  def update_prompt_template(%PromptTemplate{} = old_template, attrs) do
    new_version = old_template.version + 1

    old_template_changeset = Ecto.Changeset.change(old_template, is_current: false)

    base_struct = %PromptTemplate{
      entity_id: old_template.entity_id,
      system_message: old_template.system_message,
      few_shot_examples: old_template.few_shot_examples,
      user_template: old_template.user_template,
      version: new_version,
      is_current: true
    }

    Ecto.Multi.new()
    |> Ecto.Multi.update(:deprecate_old, old_template_changeset)
    |> Ecto.Multi.insert(:new_template, PromptTemplate.changeset(base_struct, attrs))
    |> Repo.transaction()
    |> case do
      {:ok, %{new_template: new_template}} -> {:ok, new_template}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end
```

---

### `priv/repo/migrations/[timestamp]_create_prompt_templates.exs` (migration)

**Analog:** `priv/repo/migrations/20260510174619_create_eval_tables.exs`

**Immutable table pattern** (from lines 31-44):
```elixir
    create table(:ai_prompt_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_id, :binary_id, null: false
      add :version, :integer, null: false, default: 1
      add :is_current, :boolean, null: false, default: true
      add :status, :string, null: false, default: "draft"
      add :system_message, :text
      add :few_shot_examples, :map
      add :user_template, :text
      
      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_prompt_templates, [:entity_id, :version], unique: true)
    create index(:ai_prompt_templates, [:entity_id])
```

---

### `lib/scoria/prompt_registry/tokenizer.ex` (utility, transform)

**Analog:** `lib/scoria/observe/redactor.ex`

**Stateless utility module pattern** (from `redactor.ex` lines 1-13):
```elixir
defmodule Scoria.PromptRegistry.Tokenizer do
  @moduledoc """
  Utility for estimating token counts of prompt templates before saving.
  Relies on a Tiktoken port or external tokenizer dependency.
  """

  @doc """
  Estimates token usage for a given map of prompt sections.
  """
  def estimate_tokens(prompt_map) do
    # Implementation using Tiktoken dependency
  end
end
```

## Shared Patterns

### Entity Versioning
**Source:** `Scoria.Eval.EvalSpec`
**Apply to:** `PromptTemplate` model
Versioning logic uses a combined `entity_id` and `version` index to track immutability while soft-deprecating older versions by toggling `is_current: false`.

## Metadata

**Analog search scope:** `lib/scoria`, `priv/repo/migrations`
**Files scanned:** 34 Ecto Schemas, Contexts
**Pattern extraction date:** 2026-05-18