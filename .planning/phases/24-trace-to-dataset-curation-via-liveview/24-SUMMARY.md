# Phase 24: Trace-to-Dataset Curation via LiveView - Summary

**Goal**: Operators can seamlessly promote real production traces into durable, baseline datasets for future testing.

This phase is broken down into 3 execution plans, spanning 3 waves to ensure correct architectural dependencies.

## Execution Waves

### Wave 1: Ecto Data Layer
- **Plan**: `24-01-PLAN.md`
- **Focus**: `ai_eval_datasets` and `ai_eval_dataset_items` Ecto migrations and schemas.
- **Key Constraints**: Enforcing the `:open` vs `:sealed` immutability logic directly at the `DatasetItem` validation layer to prevent baseline data drift.

### Wave 2: Context Interface
- **Plan**: `24-02-PLAN.md`
- **Focus**: `Scoria.Eval` context functions for managing datasets.
- **Key Constraints**: The context boundary ensures the dataset state is accurately checked against the database before any new dataset items can be added, preventing race conditions or bypassed constraints.

### Wave 3: Operator UX (LiveView)
- **Plan**: `24-03-PLAN.md`
- **Focus**: Integration into the trace explorer (`ScoriaWeb.WorkflowDetailPanelComponent`) and the creation of `ScoriaWeb.DatasetLive.PromoteComponent`.
- **Key Constraints**: Forces operators to manually review and redact raw JSON multi-turn contexts to prevent PII leakage into CI datasets.

## Requirements Covered
- **DATA-01**: Addressed in Plan 24-03 via the LiveView promote modal.
- **DATA-02**: Addressed in Plans 24-01 and 24-02 via the JSONB `input` and `expected_output` schemas.
