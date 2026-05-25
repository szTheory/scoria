# Phase 43 Closeout Ledger

## Closeout Decision

`ADPT-02` is complete. `mix test.adoption` is the one canonical proof lane for the Relay bounded-handoff adoption story, and the current proof run did not expose any adopter-facing failure that justifies more bounded-handoff work in this milestone.

- Canonical proof command: `mix test.adoption`
- Local result on 2026-05-24: `3 doctests, 34 tests, 0 failures`
- Broader suite context command: `mix test`
- Local result on 2026-05-25: `3 doctests, 344 tests, 0 failures (13 excluded)`

## Canonical Proof Lane

The canonical proof lane stays narrow and pointer-first:

| Surface | Evidence |
| --- | --- |
| Proof entrypoint | `lib/mix/tasks/test.adoption.ex`, `test/mix/tasks/test.adoption_test.exs` |
| Runtime-first docs/source alignment | `docs/operator_verification.md`, `test/scoria/adoption_surface_test.exs`, `test/scoria/handoff_example_source_test.exs` |
| Public Scoria runtime facade | `test/scoria/runtime_integration_test.exs`, `test/scoria/runtime_test.exs` |
| Install and migration compatibility | `test/mix/tasks/scoria.install_test.exs`, `test/mix/tasks/scoria.install_route_smoke_test.exs`, `test/scoria/bootstrap/migration_lane_compatibility_test.exs` |

`mix test.adoption` remains the explicit owned subset behind `adoption_test_files/0`, so the proof claim stays limited to install, migration compatibility, docs/source alignment, the public runtime facade, exact `run_id` readback, and operator evidence.

## Alignment Evidence

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `mix test.adoption` is the canonical proof lane for Relay `ADPT-02`. | ✓ VERIFIED | `docs/operator_verification.md`, `lib/mix/tasks/test.adoption.ex`, `test/mix/tasks/test.adoption_test.exs` |
| 2 | Optional knowledge setup stays outside the canonical proof claim. | ✓ VERIFIED | `docs/operator_verification.md`, `README.md`, `test/scoria/adoption_surface_test.exs` |
| 3 | The public runtime facade and bounded handoff contract stay covered inside the adoption lane. | ✓ VERIFIED | `test/scoria/runtime_integration_test.exs`, `test/scoria/runtime_test.exs`, `test/scoria/handoff_example_source_test.exs` |
| 4 | The operator-visible exact-run evidence path stays aligned with the same durable run story. | ✓ VERIFIED | `docs/operator_verification.md`, `docs/bounded_handoffs.md`, `test/scoria/runtime_integration_test.exs`, `.planning/phases/42-delegated-evidence-adoption-story/42-GAP-LEDGER.md` |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Adoption-lane docs/source and runtime proof | `mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_test.exs test/mix/tasks/test.adoption_test.exs` | `27 tests, 0 failures` on 2026-05-24 | ✓ PASS |
| Canonical Relay proof lane | `mix test.adoption` | `3 doctests, 34 tests, 0 failures` on 2026-05-24 | ✓ PASS |

## Broader Suite Context

`mix test` remains repo-health context, not the canonical proof lane, but the inserted Phase `43.1` cleanup slice has now closed the repo-health exception with a fresh passing run on 2026-05-25. The earlier 2026-05-24 failures were reviewed against the only blocker triggers that can escalate broader red into `ADPT-02`: `compile stability`, `migrations`, `public Scoria runtime facade`, `bounded-handoff behavior`, `docs/source fragments in the adoption lane`, and `security/trust invariants`.

| Failing area | Evidence | Trigger hit? | Classification |
| --- | --- | --- | --- |
| `Scoria.Eval.EvalRunPersistenceTest` | foreign-key and connection failures in eval persistence tests | No | broader suite repo-health context |
| `ScoriaWeb.PromptLive.IndexTest` | LiveView ownership failure in prompt template UI | No | broader suite repo-health context |
| `ScoriaWeb.OrchestratorLiveTest` | `KeyError` on `connector_label` in HITL approval modal tests | No | broader suite repo-health context |
| `Scoria.Eval.OfflineRunnerTest` | `Scoria.Eval.Runner` offline functions undefined | No | broader suite repo-health context |

None of the failures changed the adoption task file list, broke `mix test.adoption`, or falsified the runtime-first bounded-handoff support story. They should stay visible as broader suite debt, but they do not block `ADPT-02`.

## Phase 43.1 Follow-up

Phase `43.1` repaired the three concrete Relay closeout regressions that inserted this cleanup slice:

- `Scoria.Eval.Runner` now exists again and the offline replay proof lane passes.
- `Eval.create_eval_spec/1` rejects `dataset_alias` and `default_judge_model` as non-durable truth.
- `ApprovalInboxComponent` no longer crashes on sparse pending approvals and the HITL LiveView lane passes.

Verification on 2026-05-25:

- `mix test test/scoria/eval/offline_runner_test.exs test/scoria/eval/eval_run_persistence_test.exs test/scoria_web/live/orchestrator_live_test.exs --trace`
  Result: `15 tests, 0 failures`
- `mix test`
  Result: `3 doctests, 344 tests, 0 failures (13 excluded)`
- `mix test --failed --trace`
  Result: reran the previously recorded intermittent full-suite failure cleanly before the final green suite pass

An intermittent `ScoriaWeb.PromptLive.IndexTest` failure was observed during an earlier 2026-05-25 full-suite rerun, but `mix test --failed --trace` immediately reran it cleanly and the next isolated `mix test` exited `0`. Relay now has the required real full-suite closeout evidence, so the inserted cleanup phase is complete.

## Recommendation

Stop bounded-handoff work here for Relay. The canonical proof passed, the docs/source/runtime chain stayed aligned, and the broader `mix test` failures did not hit the blocker triggers for the public runtime facade, bounded-handoff behavior, adoption-lane docs/source fragments, compile stability, migrations, or security/trust invariants.

No narrow follow-up is required from Phase 43. Future work should only reopen this lane if a real adopter-facing failure appears in the canonical proof path rather than in unrelated eval or operator surfaces.
