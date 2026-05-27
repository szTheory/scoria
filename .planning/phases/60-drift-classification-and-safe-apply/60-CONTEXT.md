# Phase 60: Drift Classification And Safe Apply - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Make installer upgrade drift explicit for managed router, runtime config, and migration surfaces, and enforce planner-led apply behavior so preview/check/apply truth stays aligned and idempotent.

This phase clarifies safe ownership, drift blocking, and apply execution contracts. It does not widen into a broad installer engine rewrite or warning-ratchet scope.

</domain>

<decisions>
## Implementation Decisions

### Drift ownership model
- **D-01:** Use a hybrid ownership model: marker-owned managed regions for mutable snippet surfaces (`router`, `runtime_config`, `tailwind`) plus structural ownership for migration file sets.
- **D-02:** Persist ownership/drift truth in a canonical install manifest keyed by planner entry IDs, including ownership mode and drift evidence.
- **D-03:** Absence of ownership markers on snippet surfaces is not auto-safe; classify as `manual_review` (or explicit adopt flow), never silent takeover.
- **D-04:** Migrations remain structural and file-set driven; drift evidence records required vs observed basenames rather than marker blocks.

### Apply safety gate
- **D-05:** Apply defaults to strict atomic safety: if any planner entry is `manual_review`, apply performs zero writes and exits with blocked status.
- **D-06:** Apply exit semantics are explicit and stable: `0` applied/compliant, `1` blocked by drift/manual review, `2` execution/tooling error.
- **D-07:** Principle of least surprise is mandatory: default mode is safe and deterministic, not best-effort partial mutation.

### Planner-to-apply contract
- **D-08:** Apply executes planner truth directly through typed operations, in deterministic planner order (`order`, then stable `id`).
- **D-09:** `--dry-run`, `--check`, and apply consume the same canonical planner artifact shape; apply must not branch into ad-hoc mutation logic.
- **D-10:** Before writes, apply validates plan freshness against current surface state/fingerprint and blocks on stale mismatch.

### Remediation and reporting contract
- **D-11:** Every blocking entry must include structured remediation payload (`reason_code`, summary, ordered steps, verification command) in planner/report output.
- **D-12:** Human and JSON reports render from the same canonical remediation payload so operator and CI truth cannot drift.
- **D-13:** Existing stable trailer contract remains non-breaking (`SCORIA_CHECK_RESULT ...`), with optional additive remediation summary line for richer automation.

### Claude's Discretion
- Exact manifest filename/location and internal schema field naming, as long as schema versioning and deterministic rendering remain stable.
- Exact typed operation enum naming for planner entries, as long as operation semantics remain explicit and testable.
- Whether optional power-user flags (e.g., sealed plan file mode, partial apply override) are introduced now or deferred after safe default path stabilization.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement contracts
- `.planning/ROADMAP.md` — Phase 60 scope and success criteria.
- `.planning/REQUIREMENTS.md` — `INST-06` and `INST-07` requirement contracts.
- `.planning/STATE.md` — active milestone status and constraints.
- `.planning/phases/59-planner-contract-foundation/59-CONTEXT.md` — locked planner/check decisions carried into phase 60.
- `.planning/threads/2026-05-27-installer-safety-upgrade-confidence.md` — installer safety risks and investigation prompts.

### Project architecture and product principles
- `prompts/scoria-gsd-kickoff.md` — project vision and Phoenix-native AI ops boundary.
- `prompts/sztheory-elixir-dna.md` — batteries-included but composable, operator-first Elixir standards.
- `prompts/scoria-brand-book-deep-research.md` — calm, exact, evidence-first operator UX/microcopy rules.
- `prompts/phoenix-ai-lib-deep-research.md` — ecosystem tradeoffs for planner/apply, eval/ops, and Phoenix-native developer UX.

### Installer contract implementation surfaces
- `lib/mix/tasks/scoria.install.ex` — current CLI modes and direct apply path to replace with planner-led executor truth.
- `lib/scoria/install/planner.ex` — canonical planner artifact and deterministic entry ordering.
- `lib/scoria/install/report.ex` — human/JSON report and stable check trailer contract.
- `lib/scoria/install/surface/router.ex` — router drift classification and patchability heuristics.
- `lib/scoria/install/surface/runtime_config.ex` — runtime config ownership/drift classification.
- `lib/scoria/install/surface/migrations.ex` — migration file-set classification.
- `lib/scoria/install/surface/tailwind.ex` — optional tailwind surface classification.

### Installer verification harness
- `test/mix/tasks/scoria.install_test.exs` — idempotency, no-write, routing patch behavior, and baseline installer truth tests.
- `test/mix/tasks/scoria.install_check_test.exs` — tri-state check semantics and stable trailer expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Install.Planner.build/4`: canonical deterministic plan artifact with stable IDs/order and per-surface entries.
- `Scoria.Install.Report`: existing dual human/JSON rendering and stable trailer utilities to extend with remediation payloads.
- Surface analyzers under `Scoria.Install.Surface.*`: already provide per-surface classification/rationale/evidence scaffolding for ownership-aware drift.

### Established Patterns
- Installer currently uses explicit per-surface status language and idempotent semantics (`installed` vs `already_present`), which should be preserved under planner-led apply.
- `--dry-run` and `--check` already rely on planner truth and no-write behavior, providing a stable foundation for apply contract unification.
- Conservative fallback posture is already present (`manual_review` on ambiguity), aligned with phase 60 safety goals.

### Integration Points
- `Mix.Tasks.Scoria.Install.run/1` is the canonical user entrypoint where planner-gated apply behavior must be enforced.
- `Report.check_result/1` and trailer output remain CI-critical; additions must be backward compatible.
- Installer test fixtures in `test/mix/tasks/scoria.install_test.exs` and `test/mix/tasks/scoria.install_check_test.exs` are the primary contract harness for planner/apply equivalence and drift blocking behavior.

</code_context>

<specifics>
## Specific Ideas

- Recommendations are intentionally one coherent set: hybrid ownership + strict atomic gate + planner-driven executor + structured remediation payload.
- Output and guidance should stay calm and exact: show what blocked apply, why it blocked, and exactly how to unblock plus verify.
- Developer ergonomics is a first-class objective: machine-stable outputs for CI and human-actionable remediation for operators without hidden behavior.

</specifics>

<deferred>
## Deferred Ideas

- Optional partial-apply override (`--allow-partial`) is deferred until the strict safe-default contract is proven stable.
- Sealed plan-file workflow (`--write-plan` / `--apply-plan`) is deferred to a follow-up once core planner-driven apply equivalence is landed.

</deferred>

---

*Phase: 60-drift-classification-and-safe-apply*
*Context gathered: 2026-05-27*
