# Phase 24 Validation: Trace-to-Dataset Curation via LiveView

## Phase Goal
Operators can seamlessly promote real production traces into durable, baseline datasets for future testing.

---

## Requirement Mapping & Verification

### DATA-01. Operators can curate real production traces from Scoria's observability layer into durable `Dataset` records via the embedded LiveView UI.
* **Covered By Plans:** 24-03
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria_web/live/dataset_live/promote_component_test.exs` - asserts the promote modal renders properly and saves trace data to a selected dataset.
  * **Automated:** `mix compile` / `mix test` covering the `workflow_detail_panel_component.ex` rendering the "Promote to Dataset" action.

### DATA-02. Datasets natively capture structured inputs, baseline expected outputs, and multi-turn context to support accurate offline recreation.
* **Covered By Plans:** 24-01, 24-02
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria/eval/dataset_item_test.exs` - asserts multi-turn input context is captured natively as JSONB, and enforces insertions are rejected if the dataset is `:sealed`.
  * **Automated:** `mix test test/scoria/eval/dataset_test.exs` - asserts dataset structures are defined and state modifications are blocked once `:sealed`.

---

## Nyquist Compliance Checklist
- [ ] **DATA-01:** Operators can promote traces via LiveView UI.
- [ ] **DATA-02:** Datasets store structured, multi-turn runtime context.
- [ ] **DATA-02:** Datasets enforce immutability (`:sealed`) correctly.