# Phase 60 Research: Drift Classification And Safe Apply

## Objective

Plan Phase 60 so apply mode becomes planner-led, drift-aware, and safe-by-default: preview/check/apply must share one mutation truth (`INST-06`), and managed surfaces must block unsafe overwrite with explicit remediation (`INST-07`).

## Scope And Requirement Mapping

- `INST-06`: Apply executes the same canonical planner artifact used by `--dry-run` and `--check`; no ad-hoc write path.
- `INST-07`: Router/runtime/tailwind use marker-aware managed ownership; migrations use structural file-set ownership; unsafe drift becomes `manual_review` with remediation.
- Locked constraints to preserve:
  - Hybrid ownership model (marker regions + structural migration sets).
  - Strict default safety gate (any `manual_review` blocks all writes).
  - Stable exit semantics (`0` success/compliant, `1` blocked/manual-review, `2` execution error).
  - Stable `SCORIA_CHECK_RESULT ...` trailer remains non-breaking.

## Current Code Touchpoints To Reuse

- `lib/scoria/install/planner.ex`
  - Keep as canonical plan builder, deterministic ordering, stable IDs, and summary aggregation.
- `lib/scoria/install/surface/router.ex`, `runtime_config.ex`, `tailwind.ex`, `migrations.ex`
  - Reuse existing analyzers and evidence shape as the base for deeper ownership/drift classification.
- `lib/scoria/install/report.ex`
  - Reuse human/JSON dual-render pipeline and trailer contract; extend with shared remediation payload rendering.
- `lib/mix/tasks/scoria.install.ex`
  - Replace direct mutator apply path (`do_run/3`) with planner-led executor; keep CLI mode parsing and reporting flow.
- `test/mix/tasks/scoria.install_test.exs`, `scoria.install_check_test.exs`
  - Extend current idempotency/no-write/exit fixtures into planner-to-apply equivalence and drift-blocking coverage.

## Recommended Architecture Choices

1. Keep one canonical plan schema and add typed apply operations per entry (no second mutation model).
2. Add a versioned install manifest keyed by planner entry ID to persist ownership/drift baseline.
3. Extend each surface analyzer to return both classification and ownership/drift evidence.
4. Introduce an apply executor that consumes plan entries in deterministic order (`order`, then stable `id`).
5. Run an apply preflight gate (freshness + no-blockers) before any file writes.
6. Keep human and JSON reporting backed by one remediation payload contract.

## Drift Classification Strategy

Use existing `create | update | no_op | manual_review` classification, but add explicit drift reasoning and ownership confidence:

- **Router / Runtime config / Tailwind (marker-owned managed regions)**
  - Managed markers present and payload unchanged -> `no_op`.
  - Managed markers present and payload differs but patchable -> `update` with drift reason.
  - Markers missing, conflicting host-owned block, or unsupported topology -> `manual_review`.
  - Missing markers are never auto-takeover.
- **Migrations (structural file-set ownership)**
  - Compare required canonical basenames vs observed basenames.
  - No missing required files -> `no_op`.
  - Missing required files only -> `create`.
  - Conflicts/ambiguous structural drift -> `manual_review`.
- **Manifest linkage**
  - Every entry stores ownership mode, manifest key, observed fingerprint, and drift reason code.
  - Drift decision is explicit from evidence, not inferred only from final classification.

## Apply Safety Gate + Exit Semantics

Apply path should enforce a two-step gate:

1. **Plan freshness gate**
   - Recompute current surface fingerprints and compare to plan/manifest snapshot.
   - Any stale mismatch -> block as `manual_review` (exit `1`), zero writes.
2. **Blocking classification gate**
   - If any entry is `manual_review`, apply performs zero writes and exits `1`.

Then execute typed operations only when gate passes. Exit rules:

- `0`: apply completed or already compliant (`no_op` only).
- `1`: blocked by drift/manual-review/freshness mismatch.
- `2`: execution/tooling failure during apply/reporting.

## Planner-to-Apply Contract

Treat planner output as executable contract, not advisory text.

- Add per-entry operation metadata (example categories: `patch_region`, `append_block`, `copy_missing_files`, `skip`).
- Ensure each operation is deterministic and derived only from planner evidence.
- Apply executor must consume the same entry list from planner artifact used by `--dry-run`/`--check`.
- Ordering contract: sort by `order`, then stable `id`; never by map iteration or filesystem incidental order.
- Apply performs no custom branch logic outside operation dispatch and safety gate checks.

## Remediation/Reporting Contract

Every blocking entry must include canonical remediation payload:

- `reason_code` (stable machine key).
- `summary` (single-line human reason).
- `steps` (ordered, concrete remediation actions).
- `verify_command` (one command to re-check success).

Reporting rules:

- `Report.render_human/2` and `Report.render_json/2` both render from the same payload.
- Keep existing trailer line stable: `SCORIA_CHECK_RESULT status=<...> exit_code=<...>`.
- Optional additive line may summarize blocker count/reason codes, without breaking existing parsers.

## Test Strategy For Planning

- **Planner/apply equivalence**
  - Assert apply executes only operations present in planner artifact.
  - Assert deterministic operation order for repeated identical inputs.
- **Blocked apply zero-write guarantee**
  - For any `manual_review` scenario, snapshot files before/after apply and assert byte-identical.
- **Manifest-aware drift matrices**
  - Router/runtime/tailwind marker present/missing/conflicting permutations.
  - Migration required-file present/missing/conflict permutations.
- **Exit and reporting semantics**
  - Subprocess assertions for apply exit `0/1/2` and stable trailer compatibility.
  - Assert remediation payload appears in both human and JSON modes.
- **Regression safety**
  - Preserve existing no-write (`--dry-run`, `--check`) and installer idempotency tests.

## Risk Areas To Plan Around

- Marker insertion format churn causing false drift positives across hosts.
- Overly permissive ownership adoption accidentally overwriting host-authored config.
- Plan freshness race (files changed after plan creation but before apply).
- Divergence between human report text and JSON machine payload.
- Scope creep into Phase 61 proof/stability closure while implementing Phase 60 contracts.

## Sequencing Recommendations (Phase 60 Only)

1. Extend plan schema with operation + ownership/drift + remediation fields (versioned, deterministic).
2. Introduce manifest read/write contract and baseline persistence per planner entry.
3. Upgrade surface analyzers to emit ownership/drift evidence and reason codes.
4. Implement apply preflight gate (freshness + `manual_review` blocker scan).
5. Implement planner-led operation executor and remove direct ad-hoc apply mutations.
6. Extend report renderer for shared remediation payload (human + JSON).
7. Add integration tests for equivalence, blocking semantics, and exit/report stability.

## Validation Architecture (required)

Validation should produce evidence across four layers:

- **Contract validation**
  - Planner artifact includes stable IDs, operation type, ownership mode, drift reason, remediation payload.
  - Deterministic ordering remains stable over repeated runs.
- **Safety validation**
  - Blocked apply writes nothing when any entry is `manual_review` or plan freshness fails.
  - Missing ownership markers classify as `manual_review`, never auto-adopt.
- **Behavior validation**
  - Apply mutates only the surfaces and operation types previewed by planner.
  - Exit semantics hold (`0/1/2`) for compliant, blocked, and execution-failure scenarios.
- **Reporting validation**
  - Human and JSON outputs expose the same remediation truth.
  - Existing trailer contract remains parse-stable for CI.

## Explicit Out-Of-Scope For This Phase

- Full warning-ratchet work (`WARN-03`).
- Broad installer engine rewrite beyond planner-led apply + manifest-aware drift safety.
- Sealed plan file workflow (`--write-plan` / `--apply-plan`) unless explicitly pulled into a follow-up.
- Partial-apply override modes that weaken strict safe default behavior.
