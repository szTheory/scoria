# Phase 4 Architectural Decisions: Evaluation Flywheel

Based on the `szTheory` Unix Philosophy for Elixir and deep ecosystem research (Braintrust, Langfuse, Tribunal), here is the one-shot, cohesive recommendation for the Phase 4 Evaluation Flywheel architecture.

## 1. Dataset Versioning: Immutable Snapshots

**Recommendation:** Datasets and their items must be treated as **Versioned and Immutable Snapshots**. 
Instead of mutating existing `ai_datasets` or `ai_dataset_items` in place, any change (adding a trace, editing an expected output via the UI) creates a new version (e.g., `support_refunds@v3`).

* **Pros:** 
  * **Absolute Determinism in CI:** A CI pipeline running against `support_refunds@v3` will never randomly fail because an operator edited an item in the UI halfway through the test run.
  * **Rollbacks & Auditability:** Perfect historical lineage from production trace -> dataset version -> eval run -> CI failure.
* **Cons:** Increases database row count.
* **Tradeoff Mitigations:** Implement soft-archiving for old dataset versions. Ecto and PostgreSQL handle millions of rows easily; storage is cheaper than debugging flaky CI pipelines.
* **Idiomatic Elixir:** Maps perfectly to Elixir's core philosophy of immutable data structures.
* **Lessons Learned:** Braintrust and Langfuse emphasize immutable experiment snapshots as the only way to establish reliable CI regression gates.

## 2. CI Integration: ExUnit Macros + Dedicated Mix Task (Hybrid)

**Recommendation:** Provide both **ExUnit Macros** (`MyAI.EvalCase`) for deterministic/fast checks AND a dedicated **Mix Task** (`mix scoria.eval`) for slow, LLM-as-judge suites.

* **Pros:** 
  * **Developer Ergonomics (DX):** Elixir devs *love* ExUnit. Being able to write `eval "refund test", dataset: "refunds@v1"` inside a standard `_test.exs` file provides the principle of least surprise.
  * **Isolation:** The `mix scoria.eval` task allows CI pipelines to separate fast unit tests from slow, API-dependent LLM-as-judge runs, preventing timeout footguns.
* **Cons:** Requires maintaining two execution entry points (ExUnit formatter vs. CLI output).
* **Idiomatic Elixir:** Tribunal already demonstrates this pattern beautifully. ExUnit is the gold standard; fighting it is an anti-pattern.
* **Lessons Learned:** Forcing all evals through an external API or standalone script breaks local developer workflows. Devs want to run `mix test path/to/eval_test.exs` on their laptop.

## 3. Rubric Storage: Database-Backed with Immutable Versions

**Recommendation:** Store Evaluation Specs/Rubrics as **Database-Backed (`ai_eval_specs`) with Immutable Versions**, but allow them to be seeded/bootstrapped from code.

* **Pros:**
  * **Operator-First UI:** Fits the "SaaS in a Box" DNA. A domain expert (support lead) can tweak the "Tone/Helpfulness" rubric directly in the LiveView dashboard when they see a failure, without needing a developer to merge a PR.
  * **Tied to Traces:** Rubric versions can be joined directly to `ai_scores` in Ecto, making it trivial to write LiveView queries showing how "Judge V1 vs Judge V2" scored the same trace.
* **Cons:** "DB-as-truth" can drift from the codebase if not managed.
* **Tradeoff Mitigations:** Implement an "Export to Code" or "Seed from Code" Mix task so developers can version-control the baseline rubrics, but the runtime always executes against the DB-stored version.
* **Lessons Learned:** Prompt and Rubric engineering is often done by non-engineers. Forcing PRs for prompt tweaks kills the flywheel velocity.
