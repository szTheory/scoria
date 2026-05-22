# Phase 24: Trace-to-Dataset Curation via LiveView - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/eval/dataset.ex` | model | CRUD | `lib/scoria/prompt_registry/prompt_template.ex` | exact |
| `lib/scoria/eval/dataset_item.ex` | model | CRUD | `lib/scoria/prompt_registry/prompt_template.ex` | role-match |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | component | request-response | `lib/scoria_web/live/prompt_live/index.ex` | role-match |
| `lib/scoria_web/components/workflow_detail_panel_component.ex` | component | request-response | (self) | exact |
| `priv/repo/migrations/...add_state_and_trace_to_datasets.exs` | migration | CRUD | (standard Ecto migration) | exact |

## Pattern Assignments

### `lib/scoria/eval/dataset.ex` (model, CRUD)

**Analog:** `lib/scoria/prompt_registry/prompt_template.ex`

**State / Versioning Schema Pattern** (lines 7-12):
```elixir
  schema "ai_prompt_templates" do
    field :entity_id, :binary_id
    field :version, :integer, default: 1
    field :is_current, :boolean, default: true
    field :status, :string, default: "draft" # Analogous to :state as Ecto.Enum
```

**Changeset Validation Pattern** (lines 20-33):
```elixir
  def changeset(prompt_template, attrs) do
    prompt_template
    |> cast(attrs, [
      :entity_id,
      :version,
      :is_current,
      :status,
      # ...
    ])
    |> validate_required([:entity_id, :version, :is_current, :status])
    |> validate_inclusion(:status, ~w(draft active archived)) # To be replaced with Ecto.Enum validation
    |> unique_constraint([:entity_id, :version])
  end
```

---

### `lib/scoria/eval/dataset_item.ex` (model, CRUD)

**Analog:** `lib/scoria/prompt_registry/prompt_template.ex`

**JSONB Fields Pattern** (lines 13-14):
```elixir
    field :system_message, :string
    field :few_shot_examples, :map # Analogous to :input and :expected_output
```

---

### `lib/scoria_web/live/dataset_live/promote_component.ex` (component, request-response)

**Analog:** `lib/scoria_web/live/prompt_live/index.ex`

**Form Structure Pattern** (lines 62-83):
```elixir
          <.form for={@form} phx-change="validate" phx-submit="save">
            <div>
              <label>System Message</label>
              <textarea name={@form[:system_message].name} rows="5"><%= @form[:system_message].value %></textarea>
              <%= for error <- Keyword.get_values(@form.errors || [], :system_message) do %>
                <span class="error"><%= translate_error(error) %></span>
              <% end %>
            </div>
            
            <button type="submit" phx-disable-with="Saving...">Save Template</button>
            <button type="button" phx-click="cancel_edit">Cancel</button>
          </.form>
```

---

### `lib/scoria_web/components/workflow_detail_panel_component.ex` (component, request-response)

**Analog:** Self

**UI Structure Pattern** (lines 11-28):
```elixir
        <dl class="mt-4 space-y-2 text-sm">
          <div>
            <dt class="font-medium text-stone-600">Role</dt>
            <dd><%= @step.role_id %></dd>
          </div>
          <div>
            <dt class="font-medium text-stone-600">Kind</dt>
            <dd><%= @step.kind %></dd>
          </div>
          <!-- New action section should be added here for "Promote to Dataset" -->
```

## Shared Patterns

### Validation / Immutability
**Source:** `phase_24_dataset_mutability_recommendation.md`
**Apply to:** `Dataset` and `DatasetItem` models
```elixir
defp validate_immutable_if_sealed(changeset) do
  if changeset.data.state == :sealed do
    add_error(changeset, :state, "cannot be modified once sealed")
  else
    changeset
  end
end
```

## No Analog Found

None. All files have clear analogs or self-references.

## Metadata

**Analog search scope:** `lib/scoria/eval`, `lib/scoria/prompt_registry`, `lib/scoria_web/live`
**Files scanned:** 5
**Pattern extraction date:** 2024-05-18
