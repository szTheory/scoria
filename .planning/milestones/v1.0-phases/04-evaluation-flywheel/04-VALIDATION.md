# Phase 4 Validation: Evaluation Flywheel

## Phase Goal
Close the loop from production to CI by enabling operators to promote traces to tests and run evaluations directly from the UI.

---

## Success Criteria Mapping & Verification

### 1. Operator can promote a failed production trace into a versioned dataset via a single click in the LiveView UI.
* **Covered By Plans:** 04-01 (Database & Context), 04-03 (LiveView UI)
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria/eval_test.exs` — Asserts that `update_dataset/2` and `promote_trace_to_dataset/2` immutably snapshot datasets and accurately transform traces into `ai_dataset_items`.
  * **Automated:** `mix test test/scoria_web/live/dataset_live/promote_component_test.exs` — Asserts the `ScoriaWeb.DatasetLive.PromoteComponent` form correctly mounts, submits, and calls the `Scoria.Eval` context to perform promotion.

### 2. Operator can execute deterministic or LLM-as-judge evaluations on datasets.
* **Covered By Plans:** 04-02 (ExUnit & Mix Tasks)
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/support/eval_case_test.exs` — Asserts `Scoria.EvalCase` injects Tribunal dependencies and ExUnit macros successfully, enabling deterministic dataset evaluation writing.
  * **Automated:** `mix test test/mix/tasks/scoria.eval_test.exs` — Asserts the `mix scoria.eval` Mix task starts the app, fetches datasets, invokes Tribunal, and completes safely.

### 3. Evals can be configured with baseline thresholds to prevent nondeterministic CI failures (e.g., requires >95% success).
* **Covered By Plans:** 04-01 (Schemas), 04-02 (Mix Task)
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria/eval_test.exs` — Asserts `EvalSpec` (rubric) schemas and context validate and store baseline thresholds correctly.
  * **Automated:** `mix test test/mix/tasks/scoria.eval_test.exs` — Asserts that execution via the LLM-as-judge task correctly respects threshold validations and accurately reports CI failure if conditions fall under the required threshold (e.g., < 95%).

---

## Nyquist Compliance Checklist
- [x] **Truth:** "Dataset modifications create new immutable versions." -> Verified via `eval_test.exs`.
- [x] **Truth:** "Evaluation specs (rubrics) can be stored and versioned." -> Verified via `eval_test.exs` and `test/scoria_web/live/eval_spec_live/index_test.exs`.
- [x] **Truth:** "Operator can execute ExUnit tests utilizing Tribunal for evaluations." -> Verified via `eval_case_test.exs`.
- [x] **Truth:** "Operator can run a mix task to execute LLM-as-judge benchmarks." -> Verified via `scoria.eval_test.exs`.
- [x] **Truth:** "Operator can promote a failed trace into a versioned dataset via the UI." -> Verified via `promote_component_test.exs`.
- [x] **Truth:** "Operator can view and edit evaluation rubrics via LiveView." -> Verified via `test/scoria_web/live/eval_spec_live/index_test.exs`.
