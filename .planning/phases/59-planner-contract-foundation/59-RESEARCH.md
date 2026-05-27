# Phase 59 Research: Planner Contract Foundation

## Objective

Plan Phase 59 so `mix scoria.install` gains a no-write planning/check contract that is deterministic, actionable, and safe for CI/operator workflows, while keeping apply-path rewrites out of scope until Phase 60.

## Scope And Requirement Mapping

Phase 59 is the contract foundation for:

- `INST-03`: deterministic ordered mutation planning via `mix scoria.install --dry-run` with zero host writes
- `INST-04`: actionable `mix scoria.install --check` diagnostics with stable non-zero semantics on drift/unsafe states
- `INST-05`: per-surface classification as `create`, `update`, `no-op`, or `manual-review` with rationale and target paths

Guardrail: do not collapse this into the full planner-driven apply rewrite (`INST-06/07` in Phase 60).

## Current Code Touchpoints To Reuse

Primary existing touchpoints:

- `lib/mix/tasks/scoria.install.ex`
  - `run/1`: current command entrypoint
  - `do_run/3`: current surface orchestration
  - `inject_router/1`, `maybe_inject_tailwind/1`, `copy_core_migrations/1`, `inject_runtime_config/1`: mutating operations that should be split from new pure analyzers
  - `inject_dashboard_mount/1`, `browser_scope_index/1`: reusable router-shape detection primitives
  - `print_summary/1` + `status_line/*`: existing operator-friendly messaging patterns to preserve in spirit
- `test/mix/tasks/scoria.install_test.exs`
  - Strong idempotency and truthfulness baseline for router/tailwind/migrations/runtime config
  - Existing temp-host harness is a good base for no-write and classification contract tests
- `lib/mix/tasks/scoria.pgvector.bootstrap.ex`
  - Good precedent for actionable "Next steps" diagnostic wording and operator guidance
- `docs/operator_verification.md` and `docs/adoption_lanes.md`
  - Canonical command and lane contract references that should remain coherent when adding `--dry-run`/`--check`

Supporting planning constraints:

- `.planning/REQUIREMENTS.md` maps `INST-03/04/05` to this phase
- `.planning/ROADMAP.md` confirms Phase 59 is planner/check contract only
- `.planning/STATE.md` emphasizes preserving v2.4 reliability/lane contracts while landing v2.5
- `.planning/phases/59-planner-contract-foundation/59-CONTEXT.md` provides explicit decisions (single planner artifact, pure planner, tri-state check semantics, deterministic classification precedence)

## Recommended Architecture Choices

1. Build one canonical planner artifact used by both `--dry-run` and `--check`.
2. Keep planner logic pure and side-effect free (read/classify only).
3. Keep existing apply mutators intact for now; do not force apply to consume planner yet (Phase 60 concern).
4. Extract per-surface analyzers from current mutators so classification and rationale can be produced without writes.
5. Keep CLI and output simple: human default output + stable JSON mode from the same planner artifact.

## Deterministic Planner Contract Shape

Use a single structured planner result with explicit schema version and ordered entries.

Suggested shape (illustrative, not binding naming):

```elixir
%{
  schema_version: 1,
  planner_version: "phase59",
  mode: :dry_run | :check,
  surfaces: [
    %{
      id: "router:lib/my_app_web/router.ex:dashboard_mount",
      order: 10,
      surface: :router,
      target_path: "lib/my_app_web/router.ex",
      classification: :create | :update | :no_op | :manual_review,
      rationale: "Root browser scope found; dashboard mount missing",
      evidence: %{anchors_checked: [...], ownership: :managed | :unknown},
      remediation: ["Add scoria_dashboard manually inside browser scope"]
    }
  ],
  summary: %{create: 0, update: 0, no_op: 0, manual_review: 0}
}
```

Determinism requirements:

- Stable surface ordering (explicit ordered list, not map traversal)
- Stable entry IDs derived from deterministic fields only
- No volatile fields in contract output (timestamps/random IDs)
- Explicit path resolution precedence for router/tailwind/config discovery

## Classification Precedence And Safety Rules

Adopt explicit precedence to avoid contradictory outcomes:

1. Discover surface target(s) with deterministic path precedence.
2. Validate structural anchors required for safe mutation.
3. Determine ownership/manageability confidence.
4. Compare desired state against current state.
5. Classify as `create`/`update`/`no-op` when confidence is sufficient.
6. Fall back to `manual-review` when ambiguity, conflict, or unsupported topology is detected.

Precedence rule: `manual-review` wins whenever safe automated intent cannot be proven.

Surface-specific guidance for planning:

- `router`
  - `no-op` when import and dashboard mount already present
  - `update` when root browser scope anchor is unambiguous and mount/import missing
  - `manual-review` when no safe browser scope insertion point or ambiguous topology
- `tailwind`
  - `no-op` when glob already present
  - `no-op` (intentional skip) when no Tailwind config exists
  - `update` when content anchor is recognized and glob missing
  - `manual-review` when config exists but anchor shape is unsupported
- `migrations`
  - `create` when canonical core migration files are missing
  - `no-op` when all required core files already present
  - `manual-review` when drift/conflict signals are present (for example unexpected basename/content mismatch checks)
- `runtime_config`
  - `no-op` when managed Scoria runtime block is already present
  - `update` when config file exists and managed block can be safely inserted
  - `manual-review` when conflicting/unowned Scoria runtime blocks make safe mutation uncertain

## `--check` Exit Semantics And Diagnostics

Recommended check result model aligned with least-surprise CLI behavior:

- Exit `0`: compliant/safe (`no-op` only, plus explicitly intentional skips)
- Exit `1`: non-compliant or unsafe host state (any `create`, `update`, or `manual-review`)
- Exit `2`: execution/tooling failure (unexpected runtime errors, unreadable filesystem state, parser failures)

Diagnostic contract expectations:

- Always print actionable per-surface rationale
- Provide concrete next-step commands for likely remediations
- Include one stable machine trailer line for CI parsing, e.g.
  - `SCORIA_CHECK_RESULT status=<compliant|drift|manual_review|error> exit_code=<n>`

Important implementation planning detail:

- `System.halt/1` may be needed for explicit exit codes, but tests should still be able to validate behavior safely (likely via command-level integration tests using `System.cmd/3` rather than only direct task invocation).

## Output Contract Recommendations

Human-first default output should remain calm and grouped, with deterministic section order:

1. Overall outcome
2. Would change (`create`/`update`)
3. Already aligned (`no-op`)
4. Intentionally skipped
5. Manual review required
6. Next steps

Machine output:

- Add `--format json` for stable structured consumption
- Keep schema-versioned contract and avoid human-only phrasing in JSON fields
- Preserve predictable field set to minimize CI parser churn

## Test Strategy For Planning

Use layered coverage to protect determinism and no-write guarantees:

- Unit-level analyzer tests (per surface)
  - classify states from fixture content without writing files
  - verify precedence (`manual-review` fallback correctness)
- Task contract tests (`test/mix/tasks/scoria.install_test.exs` expansion)
  - `--dry-run` writes nothing (before/after file snapshots)
  - deterministic output order across repeated runs
  - per-surface classification and rationale presence
- Exit semantics integration tests
  - invoke check mode in subprocess and assert exit `0/1/2`
  - assert stable trailer line format for CI parsing
- Regression safety
  - keep existing apply/idempotency tests green
  - ensure default lane contract (`mix test.adoption`) is unaffected

## Risk Areas To Plan Around

- Router topology ambiguity (multiple scopes/pipelines or nonstandard shapes) causing unsafe auto-patch assumptions
- False confidence in ownership for runtime config and router sections
- Hidden write regressions if planner code accidentally calls mutators
- Non-deterministic plan ordering if relying on map iteration or uncontrolled filesystem ordering
- Scope creep into apply-path unification (Phase 60 work)

Risk mitigation patterns:

- Explicit conservative fallback to `manual-review`
- Strict planner/apply boundary in module design
- Determinism assertions in tests (same input -> same ordered plan)
- Keep Phase 59 contract-focused and avoid patch executor replacement

## Sequencing Recommendations (Phase 59 Only)

1. Define planner/check contract schema and deterministic ordering rules.
2. Add pure discovery + per-surface analyzers (no writes).
3. Wire CLI option parsing (`--dry-run`, `--check`, optional `--format json`) and planner invocation.
4. Implement check status aggregation and stable exit semantics/trailer output.
5. Expand tests for no-write, deterministic plan, classification rationale, and exit codes.
6. Update installer-facing docs only as needed to reflect new preview/check command contracts.

## Validation Architecture

Validation for Nyquist generation should combine contract truth, behavior truth, and safety truth:

- **Contract validation**
  - Verify planner artifact includes required keys (`surface`, `target_path`, `classification`, `rationale`, stable `id`)
  - Verify ordered plan entries remain stable across identical runs
- **No-write validation**
  - Execute `mix scoria.install --dry-run` on representative host fixtures
  - Assert byte-identical host files before/after
- **Check semantics validation**
  - Exercise compliant, drift, manual-review, and error scenarios
  - Assert exact exit code mapping (`0/1/2`) and stable trailer line
- **Classification validation**
  - Assert precedence and fallback behavior per surface topology
  - Validate rationale/remediation presence for every non-`no-op` classification
- **Regression validation**
  - Keep existing installer apply/idempotency tests passing
  - Keep canonical adoption lane (`mix test.adoption`) green to guard reliability-contract regressions

Evidence outputs Nyquist can consume:

- deterministic planner JSON fixtures
- subprocess exit-code assertions for `--check`
- before/after filesystem snapshots proving no-write dry-run behavior
- per-surface matrix tests documenting classification precedence outcomes

## Explicit Out-Of-Scope For This Phase

- Forcing apply mode to execute from planner artifact (`INST-06`, Phase 60)
- Full manifest-aware drift-safe apply rewrite (`INST-07`, Phase 60)
- Broad installer engine replacement beyond planner/check contract scaffolding

