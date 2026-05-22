# Phase 24: Trace-to-Dataset Curation via LiveView - Research

**Researched:** 2024-05-18
**Domain:** Elixir/Ecto Persistence, Phoenix LiveView Curation UI, Evaluation Datasets
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Ecto-Backed Relational Datasets (Approach A):** Use Ecto (`Scoria.Eval.Dataset`, `Scoria.Eval.DatasetItem`) backed by PostgreSQL to store datasets. Individual test cases will utilize `JSONB` for `input`, `expected_output`, and `metadata` payloads.
- **Open / Sealed Mutability Model:** Datasets exist in either an `:open` state (mutable, like a shopping cart for curation) or a `:sealed` state (strictly immutable for CI EvalRuns).
- **Direct LiveView Integration:** Traces will feature a "Promote to Dataset" button that opens a LiveComponent (`ScoriaWeb.DatasetLive.PromoteComponent`) for curation and redaction.
- **Strictly standard Phoenix and Ecto:** Do not use the Ash framework (from `GEMINI.md`).

### the agent's Discretion
- Specific redaction patterns in the LiveView modal UI before saving.

### Deferred Ideas (OUT OF SCOPE)
- Event-sourced datasets (abandoned for being over-engineered).
- Local filesystem storage / JSONL saving from LiveView (abandoned due to 12-factor deployment conflicts).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | Operator can view a production trace in the LiveView dashboard and click to save it as a dataset. | Implement `ScoriaWeb.DatasetLive.PromoteComponent` and embed an action button in the trace explorer component. Ecto models will handle the persistence. |
| DATA-02 | The resulting dataset successfully retains the multi-turn context and expected output formats natively. | `DatasetItem` stores `input` as JSONB. The input shape MUST exactly match the `args` accepted by `Scoria.Runtime.run/2` to preserve context without a translation layer. |
</phase_requirements>

## Summary

This phase implements the "Trace → Annotation → Dataset" portion of the evaluation flywheel for Scoria. The core challenge is balancing operator ergonomics during trace curation with strict CI reproducibility guarantees. Based on the ecosystem analysis (LangSmith, Braintrust, Langfuse), Scoria will use an Ecto-backed relational architecture featuring an "Open / Sealed" state machine.

An operator uses the LiveView trace explorer to add production traces to an `:open` dataset, which acts as a mutable curation workspace. Once the dataset is finalized, the operator clicks "Seal Dataset", freezing it cryptographically (or at the database layer via Ecto changesets) so that evaluation CI runs have a strict, unchanging baseline.

**Primary recommendation:** Use Ecto schemas with an `Ecto.Enum` state field (`:open` / `:sealed`), restricting `DatasetItem` insertions and updates to datasets that are `:open`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Curation UI & Redaction | Frontend Server (LiveView) | Browser | LiveView manages the "shopping cart" flow for dataset items and operator-driven payload redaction prior to save. |
| Dataset State Management | API / Backend (Ecto) | Database | `Ecto.Changeset` validations enforce the open/sealed state constraints before hitting PostgreSQL. |
| Multi-turn Context Storage | Database (PostgreSQL) | API / Backend | JSONB columns natively store the exact multi-turn argument shape used by `Scoria.Runtime.run/2`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto.Enum | ~> 3.10 | Dataset State Machine | Idiomatic Elixir approach for managing `:open` vs `:sealed` states without external dependencies. |
| PostgreSQL JSONB | ~> 15.0 | Flexible Test Payloads | Allows `input` and `expected_output` fields to perfectly match the Scoria runtime argument schema. |
| Phoenix.LiveComponent | ~> 0.20 | Promote Modal | Enables inline trace curation without losing the context of the underlying trace explorer page. |

## Architecture Patterns

### System Architecture Diagram

```
[Operator Browser] 
       │ (Clicks "Promote to Dataset")
       ▼
[LiveView: Trace Explorer] 
       │ (Opens Modal, Extracts trace `messages` array)
       ▼
[LiveView: Promote Component]
       │ (Operator edits JSON, applies redactions, defines expectations)
       ▼
[Ecto: DatasetItem Changeset]
       │ (Validates that parent Dataset state == :open)
       ▼
[PostgreSQL: scoria_eval_dataset_items]
```

### Pattern 1: Open / Sealed Dataset Immutability
**What:** Preventing data drift in CI by freezing datasets.
**When to use:** Whenever storing evaluation sets for CI runners.
**Example:**
```elixir
defp validate_immutable_if_sealed(changeset) do
  if changeset.data.state == :sealed do
    add_error(changeset, :state, "cannot be modified once sealed")
  else
    changeset
  end
end
```

### Pattern 2: Context Preservation via Exact Argument Matching
**What:** Storing the JSONB `input` of the test case in the exact shape required by the runtime.
**When to use:** Designing the Ecto schema for `DatasetItem`.
**Example:** The `input` field must contain the exact multi-turn `messages` array rather than a flattened string, so Phase 25 can pipe the dataset directly into `Scoria.Runtime.run/2` without any translation layer.

### Anti-Patterns to Avoid
- **Writing to `.jsonl` files from a web request:** Banned. Heroku/Fly.io ephemeral filesystems will wipe the datasets on restart. Datasets must live in Ecto/Postgres.
- **Strictly Immutable Datasets on Creation:** Banned. Creating a new dataset version for every single trace added destroys the UI curation experience. Use the `:open` state for batching additions.
- **PII Leakage:** Banned. Extracting raw traces into datasets without an explicit operator redaction step in the LiveView modal introduces PII into CI.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dataset State Locking | Custom GenServer locks | `Ecto.Enum` + Changesets | Ecto changesets gracefully handle the `:sealed` validation constraint at the persistence boundary. |
| Schema translation | Mapping `DatasetItem` to test inputs | Direct JSONB pass-through | Storing the exact runtime arguments as JSONB eliminates brittle mapping code. |

## Common Pitfalls

### Pitfall 1: Dataset Drift in CI
**What goes wrong:** A CI pipeline passes on Monday but fails on Tuesday against the same dataset ID, despite no code changes.
**Why it happens:** Operators mutated the dataset by adding or changing traces after it was already used as a baseline.
**How to avoid:** Enforce the `:sealed` state. Once a dataset is sealed, the LiveView UI must disable all editing and item additions. An `EvalRun` must only accept `:sealed` datasets.
**Warning signs:** Operators complaining about missing traces, or CI runs with varying test counts under the same version.

## Code Examples

### Ecto Schema for Dataset Validation
```elixir
def changeset(dataset, attrs) do
  dataset
  |> cast(attrs, [:name, :state, :version])
  |> validate_required([:name, :state, :version])
  |> validate_immutable_if_sealed()
end

defp validate_immutable_if_sealed(changeset) do
  if changeset.data.state == :sealed do
    add_error(changeset, :state, "cannot be modified once sealed")
  else
    changeset
  end
end
```

### Validating DatasetItem Insertions
```elixir
def changeset(item, attrs, dataset_state \\ :open) do
  item
  |> cast(attrs, [:input, :expected_output, :trace_id, :dataset_id])
  |> validate_dataset_open(dataset_state)
end

defp validate_dataset_open(changeset, :sealed) do
  add_error(changeset, :dataset_id, "cannot add or modify items in a sealed dataset")
end
defp validate_dataset_open(changeset, _), do: changeset
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Flat Prompt Strings | Multi-turn Context Objects | GPT-3.5+ Era | Datasets must natively store JSON lists of messages rather than a single prompt string. |
| Always Mutable DB | Versioned/Sealed Datasets | Modern ML Ops | Eliminates "it worked yesterday" CI flakes by guaranteeing immutable baselines. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | DATA-01 / DATA-02 are satisfied by a LiveView modal extracting trace context into Ecto JSONB models | Phase Requirements | If the exact args cannot be successfully serialized into JSONB, execution in Phase 25 will require a brittle mapping layer. |
| A2 | No external external PII redaction service is required, just UI redaction | Constraints | Operators may manually leak PII if auto-redaction logic isn't robust. |

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified beyond the existing PostgreSQL and Elixir runtime).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | Trace can be promoted to a Dataset | integration | `mix test test/scoria_web/live/dataset_live/promote_component_test.exs` | ❌ Wave 0 |
| DATA-02 | DatasetItem insertions rejected if Dataset is `:sealed` | unit | `mix test test/scoria/eval/dataset_item_test.exs` | ❌ Wave 0 |
| DATA-02 | Dataset state update rejected if already `:sealed` | unit | `mix test test/scoria/eval/dataset_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test` (on changed files)
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scoria/eval/dataset_test.exs` — Covers Ecto immutability logic.
- [ ] `test/scoria/eval/dataset_item_test.exs` — Covers dataset_id validation logic.
- [ ] `test/scoria_web/live/dataset_live/promote_component_test.exs` — Covers LiveView form and promotion flow.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Standard LiveView mount auth |
| V3 Session Management | yes | Standard Phoenix sessions |
| V4 Access Control | yes | Ensure operators can only promote traces they have access to |
| V5 Input Validation | yes | Ecto Changesets for `input` JSONB and state changes |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII Leakage into CI | Information Disclosure | Explicit operator redaction in LiveView modal before saving to Ecto |
| Cross-Site Scripting (XSS) in UI | Spoofing | Phoenix HTML engine auto-escapes trace payloads in the Trace Explorer |

## Sources

### Primary (HIGH confidence)
- `.planning/research/phase_24_decisions.md` - Context on evaluation flywheels and relational dataset decisions.
- `.planning/research/phase_24_dataset_mutability_recommendation.md` - Implementation details for the `:open` vs `:sealed` state model.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows the project's Ecto/Phoenix-native philosophy.
- Architecture: HIGH - Fully detailed in existing decision documents.
- Pitfalls: HIGH - Addresses common AI evaluation lifecycle pain points.

**Research date:** 2024-05-18
**Valid until:** 2024-11-18
