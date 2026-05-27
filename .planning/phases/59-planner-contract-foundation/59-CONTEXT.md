# Phase 59: Planner Contract Foundation - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Define and ship a no-write installer planner/check contract for `mix scoria.install` that classifies each managed surface as `create`, `update`, `no-op`, or `manual-review`, emits deterministic output, and returns stable `--check` exit semantics.

This phase does not include a broad installer rewrite or full planner-driven apply executor replacement (that continues in Phase 60).

</domain>

<decisions>
## Implementation Decisions

### Planner contract shape
- **D-01:** Introduce one canonical planner artifact as the truth source for `--dry-run` and `--check` (and future apply reuse), rather than branching behavior inside mutating functions.
- **D-02:** Planner logic is pure and side-effect-free: classify and summarize only; no host writes in `--dry-run` or `--check`.
- **D-03:** Planner artifact must include deterministic ordered mutations with `surface`, `target_path`, `classification`, `rationale`, structured `evidence`, and stable `id`.
- **D-04:** Keep Phase 59 scope narrow by extracting analyzers from the existing installer task and deferring full executor unification to Phase 60.

### Check exit semantics
- **D-05:** `mix scoria.install --check` uses least-surprise tri-state semantics:
  - `0` = safe/compliant
  - `1` = unsafe/manual-review required
  - `2` = execution/tooling error
- **D-06:** Unsafe host state is treated as a domain result (not a crash), with explicit status wording and remediation guidance.
- **D-07:** Output includes a stable machine trailer line for CI parsing, e.g. `SCORIA_CHECK_RESULT status=<...> exit_code=<...>`.

### Requirement staging across waves
- **D-14:** Wave 1 (`59-01`) delivers only `INST-03` and `INST-05` planner foundations; it does not claim `INST-04` completion.
- **D-15:** Wave 2 (`59-02`) is the point where `INST-04` is implemented and verified through explicit `--check` status/exit semantics.

### Deterministic classification rules
- **D-08:** Use a hybrid classifier: structural probes + ownership markers + evidence ledger, with conservative fallback to `manual-review`.
- **D-09:** Classification precedence is explicit and deterministic: discover targets -> validate anchors -> ownership check -> desired-state check -> safe create/update eligibility -> manual-review fallback.
- **D-10:** Surface-level defaults:
  - Router: update only when root browser scope anchor is unambiguous; otherwise manual-review.
  - Tailwind: no-op when intentionally absent; update only when content anchor is clear.
  - Migrations: create when missing canonical core migration files; manual-review on basename hash drift.
  - Runtime config: update only for managed/recognized Scoria block; manual-review on conflicting unowned blocks.

### Output and developer ergonomics
- **D-11:** Use dual output modes from one planner artifact:
  - Human-first grouped text (default)
  - Stable JSON contract via `--format json`
- **D-12:** Human output order is deterministic and calm: outcome -> changed/would-change -> already present -> skipped intentionally -> manual review -> next steps -> optional lanes.
- **D-13:** Keep terminology and tone evidence-based and operator-friendly ("what happened", "why", "what to do next"), aligned with Scoria brand and docs style.

### Claude's Discretion
- Exact module names and file layout for planner internals.
- Exact JSON key naming as long as schema versioning and stability are preserved.
- Level of patch preview detail included in planner output by default vs verbose mode.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement truth
- `.planning/ROADMAP.md` — Phase 59 scope and success criteria.
- `.planning/REQUIREMENTS.md` — `INST-03`, `INST-04`, `INST-05` requirement contracts.
- `.planning/STATE.md` — Current milestone status and constraints.
- `.planning/threads/2026-05-27-installer-safety-upgrade-confidence.md` — scope guardrails, risks, and open investigations.

### Existing installer and lane behavior
- `lib/mix/tasks/scoria.install.ex` — current installer implementation and output behavior.
- `test/mix/tasks/scoria.install_test.exs` — existing installer contract tests and idempotency expectations.
- `lib/mix/tasks/scoria.pgvector.bootstrap.ex` — current Mix-task style for actionable failure guidance.
- `docs/operator_verification.md` — canonical installer/adoption proof lane expectations.
- `docs/adoption_lanes.md` — lane boundary and support-truth constraints.

### Project architecture and DX principles
- `prompts/sztheory-elixir-dna.md` — batteries-included, composable, operator-first standards.
- `prompts/scoria-gsd-kickoff.md` — Scoria project vision and integration expectations.
- `prompts/scoria-brand-book-deep-research.md` — voice/tone and evidence-first UX guidance.
- `prompts/phoenix-ai-lib-deep-research.md` — ecosystem and architecture tradeoff research.

### External ecosystem references (research basis)
- [Elixir OptionParser](https://hexdocs.pm/elixir/main/OptionParser.html) — idiomatic CLI parsing.
- [Mix.Task](https://hexdocs.pm/mix/Mix.Task.html) — task orchestration and exit behavior.
- [Terraform plan/apply model](https://developer.hashicorp.com/terraform/cli/commands/plan) — plan/apply determinism lessons.
- [kubectl diff](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_diff/) — check-style exit semantics.
- [ESLint CLI](https://eslint.org/docs/latest/use/command-line-interface) — human+machine output conventions.
- [Igniter](https://hexdocs.pm/igniter/readme.html) — Elixir project patching and safe mutation patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Scoria.Install.do_run/3`: existing surface orchestration entry point that can be split into plan-first and apply steps.
- `status_line/4` and `print_summary/1`: existing summary rendering patterns that can be adapted to planner-derived statuses.
- `inject_dashboard_mount/1` and scope helpers: router-shape analysis primitives reusable for non-mutating classification.

### Established Patterns
- Installer currently enforces idempotency semantics (`installed` vs `already_present`) across router, tailwind, migrations, and config.
- Existing tests already assert no duplicate mutations and truthful status lines; these are strong anchors for planner contract tests.
- Mix tasks in this repo favor explicit operator guidance when prerequisites fail (`scoria.pgvector.bootstrap` pattern).

### Integration Points
- `mix scoria.install` CLI surface remains canonical for adopters and docs.
- `test/mix/tasks/scoria.install_test.exs` is the core contract harness to expand for `--dry-run`, `--check`, deterministic classifications, and exit code behavior.
- `docs/operator_verification.md` and adoption lane docs need to remain aligned with planner/check output contracts.

</code_context>

<specifics>
## Specific Ideas

- Adopt "plan/check truth first, apply later" architecture so Phase 60 can consume the same artifact without re-litigating semantics.
- Prefer principle-of-least-surprise defaults: conservative `manual-review` on ambiguity, never hidden writes in check paths.
- Emphasize great DX in both local and CI workflows by pairing calm human summaries with stable machine-readable output.

</specifics>

<deferred>
## Deferred Ideas

- Saved plan-file workflows (`plan.out` style) were considered but deferred as too heavy for Phase 59.
- Full AST/codemod engine adoption across all installer surfaces was considered but deferred to avoid scope creep.
- Broad warning-ratchet (`WARN-03`) remains queued next milestone and out of Phase 59 scope.

</deferred>

---

*Phase: 59-planner-contract-foundation*
*Context gathered: 2026-05-27*
