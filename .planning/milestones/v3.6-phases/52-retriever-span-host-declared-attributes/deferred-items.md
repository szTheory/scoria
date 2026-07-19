# Phase 52 — Deferred Items

Out-of-scope discoveries found during plan execution (Scope Boundary policy —
pre-existing failures in files not touched by the current plan are logged
here, not fixed inline).

## Found during 52-04

### 1. `Scoria.KnowledgeLaneContractTest` file-set drift (pre-existing, from 52-02)

- **Test:** `test/scoria/knowledge_lane_contract_test.exs:16` — "knowledge
  lane file set is stable and every file uses Scoria.KnowledgeCase"
- **Symptom:** `Mix.Tasks.Scoria.Test.Knowledge.knowledge_test_files/0` globs
  `test/scoria/knowledge/**/*_test.exs` and now picks up
  `test/scoria/knowledge/embedder_test.exs`, which isn't in the test's
  hardcoded `@expected_files` list.
- **Root cause:** `test/scoria/knowledge/embedder_test.exs` was added by
  plan 52-02 (commit `1a574d95`, "add failing test for
  Embedder.Deterministic.model_name/0") without updating
  `@expected_files` in `knowledge_lane_contract_test.exs`.
- **Why out of scope for 52-04:** `test/scoria/knowledge_lane_contract_test.exs`
  is not in this plan's `files_modified` (`lib/scoria/knowledge.ex`,
  `test/scoria/knowledge/retrieval_test.exs`), and the drift was introduced
  by an earlier plan's file addition, not by this plan's changes.
- **Suggested fix:** add `"test/scoria/knowledge/embedder_test.exs"` to
  `@expected_files` in `test/scoria/knowledge_lane_contract_test.exs`
  (alphabetically after `citation_formatter_test.exs`).

### 2. `Scoria.WarningInventory.CaptureParityTest` flaky failure (pre-existing, Phase 28)

- **Test:** `test/scoria/warning_inventory/capture_parity_test.exs:53` —
  "optimized compile-only capture catches high-signal unclassified warning
  (injected)"
- **Symptom:** intermittent — failed in one full-suite run, passed in
  another, with no 52-04 file changes between runs. Compile-warning-capture
  parity test unrelated to `Knowledge`/`Observe`/retrieval.
- **Root cause:** unrelated to this plan; predates Phase 52 (introduced in
  Phase 28, commit `bf15f105`/`d07093b4`). Consistent with the project's
  documented SEED-004 test-code determinism debt (async `IntegrationCase`,
  `Process.sleep` removal, flaky CI reruns) in `.planning/STATE.md`.
- **Why out of scope for 52-04:** not in this plan's `files_modified`; not
  caused by this plan's changes; already tracked as project-level debt.

## Found during 52-06

Full-suite `mix test` reproduced items #1 and #2 above (still present,
unmodified) plus two additional pre-existing failures — none touch
`test/scoria/observe/prompt_span_test.exs` (this plan's only file):

### 3. `Mix.Tasks.Scoria.InstallCheckTest` cross-test `test/tmp` race (pre-existing)

- **Test:** `test/mix/tasks/scoria.install_check_test.exs:27` — "mix
  scoria.install --check renders remediation payload parity for human and
  json"
- **Symptom:** `File.cd!/1` fails with `could not set current working
  directory to ".../test/tmp/install_check/manual_review-10766": no such
  file or directory` — another async test tore down/rotated a fixture
  directory under `test/tmp` mid-run.
- **Why out of scope for 52-06:** not in this plan's `files_modified`
  (`test/scoria/observe/prompt_span_test.exs`); a `test/tmp` concurrency
  race, consistent with the same SEED-004 test-code determinism debt as
  item #2.

### 4. `Scoria.WarningInventory.TmpPreflightTest` fixture-pollution race (pre-existing)

- **Test:** `test/scoria/warning_inventory/tmp_preflight_test.exs:33` —
  "ratchet check subprocess cleans test/tmp so inventory preflight passes
  afterward"
- **Symptom:** `ratchet check failed: test/tmp contains 1 entries; clean
  installer fixture pollution before running warning inventory` — a
  concurrently-running installer test left an entry in `test/tmp` when
  this subprocess-driven preflight ran.
- **Why out of scope for 52-06:** not in this plan's `files_modified`; same
  `test/tmp` cross-test concurrency class as item #3, unrelated to
  `Observe`/prompt-span work.
