# Dataset Mutability Model Recommendation (Phase 24)

## Context & The Gray Area
Phase 24 introduces the ability for operators to curate production traces into "Datasets" via a LiveView UI. The core tension lies between the **ergonomics of active curation** (an operator spending an hour finding and adding 10 tricky traces to a dataset) and the **strict requirement for CI reproducibility** (an EvalRun needs to test against the exact same data tomorrow as it did today).

This document evaluates the mutability models, incorporates lessons from the AI Ops ecosystem, and provides a definitive, idiomatic recommendation for Scoria.

---

## 1. Evaluation of Approaches

### A. Lock on Use / Explicit Locking ("Open" vs "Sealed")
*Mutable/appendable until explicitly locked or used in an EvalRun, then frozen permanently.*
* **Pros:** Perfect balance. Operators get a frictionless "shopping cart" experience while curating. CI gets ironclad reproducibility guarantees.
* **Cons:** Introduces a state machine for Datasets. Requires UI friction to explain the state transition.
* **Verdict:** Highly aligned with operator workflows.

### B. Strict Immutability
*Every single item addition creates a new dataset version.*
* **Pros:** Mathematical purity. Perfect reproducibility.
* **Cons:** Terrible developer experience (DX). Adding 10 traces yields 10 versions. Clutters the UI, bloats the database, and creates confusion over which version is "the real one."
* **Verdict:** Too dogmatic; ruins the LiveView curation UX.

### C. Soft Immutability
*Can append to the latest version, but cannot modify/delete existing items.*
* **Pros:** Simpler than strict immutability.
* **Cons:** The "target" is still moving. A CI run on Monday might process 50 items, and on Tuesday 52 items, under the same Dataset ID. Reproducibility is compromised without complex point-in-time timestamp filtering.
* **Verdict:** Worst of both worlds.

### D. Always Mutable
*Datasets are always mutable; rely on `updated_at` timestamps for CI tracking.*
* **Pros:** Trivial to implement. No state management.
* **Cons:** Destroys trust in CI. "It worked yesterday, but today it fails" because someone tweaked an expected output or deleted a hard trace.
* **Verdict:** Disqualified for a professional-grade testing library.

---

## 2. Lessons from the Ecosystem

Mature tools in the space have grappled with this exact problem:
* **LangSmith:** Initially leaned heavily towards mutability, which made iterative curation easy but CI integration messy. They later had to introduce explicit versioning and tagging.
* **Braintrust:** Takes a very software-engineering approach. Datasets are versioned (like git commits). This provides great reproducibility but can feel heavy when just doing quick data collection.
* **Langfuse / Arize Phoenix:** Often rely on appending, but users frequently complain about "dataset drift" corrupting their historical evaluation metrics.

**The Lesson:** Curation is a human, messy, mutable process. Evaluation is a robotic, strict, immutable process. You cannot use the exact same state model for both without making one miserable.

---

## 3. Elixir, Ecto & Phoenix Idioms

* **Ecto State Machines:** Ecto is fantastic at explicit state transitions. Using an `Ecto.Enum` for a `:state` field (e.g., `:open`, `:sealed`) and enforcing immutability in `Changeset` logic is highly idiomatic.
* **LiveView & The "Shopping Cart" UX:** LiveView excels at managing transient, interactive state. An `:open` dataset acts exactly like an e-commerce shopping cart. You drop traces in, remove them, tweak them in real-time.
* **Explicit over Implicit:** Elixir prefers explicit actions. "Locking" a dataset before CI can use it is an explicit, understandable action that prevents surprises.

---

## 4. The One-Shot Perfect Recommendation

**We will implement the "Open / Sealed" Model (A refinement of Approach A).**

### The Core Rules:
1. **Creation:** A Dataset (or a new version of a Dataset) is created in the `:open` state.
2. **Curation:** While `:open`, operators can add, remove, and edit `DatasetItem`s freely via the LiveView UI.
3. **Sealing:** An operator clicks a button to "Seal" the dataset. Once `:sealed`, the dataset and its items become **strictly immutable** at the database layer (via Ecto Changeset validations and optionally PostgreSQL triggers).
4. **Execution:** `EvalRun`s (CI or local) can **only** be executed against `:sealed` datasets.
5. **Iteration:** If an operator needs to add a new trace to a sealed dataset, they click "Create New Version." This clones the sealed dataset into a new `:open` version (e.g., v2), where they can resume curation.

### Why this is the best path:
* **Principle of Least Surprise:** Developers know what "Sealed" means. No hidden data drift.
* **Operator Ergonomics:** The LiveView curation flow is completely frictionless.
* **CI Trust:** When an EvalRun fails, you are 100% certain it's a code regression, not a dataset drift issue.

---

## 5. Implementation Details

### Ecto Schemas

**`Scoria.Eval.Dataset`**
```elixir
schema "scoria_eval_datasets" do
  field :name, :string
  field :version, :integer, default: 1
  field :state, Ecto.Enum, values: [:open, :sealed], default: :open
  
  has_many :items, Scoria.Eval.DatasetItem
  timestamps()
end

def changeset(dataset, attrs) do
  dataset
  |> cast(attrs, [:name, :state])
  |> validate_required([:name, :state])
  |> validate_immutable_if_sealed()
end

defp validate_immutable_if_sealed(changeset) do
  # If the dataset was already sealed before this update, reject any changes
  # (Except perhaps soft-deletion/archiving, if supported later)
  if changeset.data.state == :sealed do
    add_error(changeset, :state, "cannot be modified once sealed")
  else
    changeset
  end
end
```

**`Scoria.Eval.DatasetItem`**
```elixir
schema "scoria_eval_dataset_items" do
  belongs_to :dataset, Scoria.Eval.Dataset
  field :trace_id, :string # Reference to the source production trace
  field :input, :map
  field :expected_output, :map
  
  timestamps()
end

def changeset(item, attrs, dataset_state \\ :open) do
  item
  |> cast(attrs, [:input, :expected_output, :trace_id])
  |> validate_dataset_open(dataset_state)
end

defp validate_dataset_open(changeset, :sealed) do
  add_error(changeset, :dataset_id, "cannot add or modify items in a sealed dataset")
end
defp validate_dataset_open(changeset, _), do: changeset
```

### LiveView UX

1. **Trace View ("Add to Dataset" Action):**
   * A dropdown shows a list of datasets.
   * It **only** displays datasets that are in the `:open` state, plus a "Create New Dataset" option. 
   * *Ergonomic touch:* If the user wants to add to a `:sealed` dataset, the UI offers a 1-click "Bump Version & Add" action that creates v+1 and adds the trace.

2. **Dataset Manager UI:**
   * **If `:open`:** Shows a prominent "Seal Dataset for CI" button. The UI clearly states: *"This dataset is currently a draft. Seal it to use it in Evaluation Runs."*
   * **If `:sealed`:** The UI becomes read-only. Editing controls are disabled. A "Create New Version" button replaces the "Seal" button.

3. **EvalRun Kickoff UI:**
   * When manually triggering an EvalRun from LiveView, the dataset selector only allows selection of `:sealed` datasets.

This architecture cleanly separates the messy human workflow from the strict machine workflow, playing perfectly to the strengths of both Ecto and Phoenix LiveView.
