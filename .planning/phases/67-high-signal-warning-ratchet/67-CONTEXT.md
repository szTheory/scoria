# Phase 67: High-Signal Warning Ratchet - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Clear compiler and test warnings on **high-signal surfaces** so maintainer trust matches canonical lane truth, **without** turning on full-suite `mix test --warnings-as-errors` in CI.

Delivers **WARN-05** (compile + lane-contract WAE hold/regression) and **WARN-06** (inventory-prioritized `test/scoria/`, adoption-lane files, targeted LiveView compile warnings pass under WAE).

**In scope:** Code fixes, cluster registry growth, `Scoria.WarningRatchet` SSOT paths, committed inventory artifacts, maintainer verification commands, honest deferred-debt documentation for tiers left baselined.

**Out of scope:** Full-suite WAE in CI (Phase 68 / WARN-07), CI-03 closeout documentation bundle (Phase 69), installer planner/apply changes, broad LiveView refactors beyond inventory-targeted compile warnings, auto-fix Mix tasks.

</domain>

<decisions>
## Implementation Decisions

### Ratchet scope — fix vs defer (Gray area 1)

- **D-01:** **Hold p0 + p1** — no regression on `mix compile --warnings-as-errors` or policy-job lane-contract WAE (`verification_lanes_test.exs`, `adoption_surface_test.exs`). Treat as verify-first in plan 67-01.
- **D-02:** **Fix p3 in Phase 67** — `:test_unused_binding`, `:test_dead_default_args` in `test/scoria/` and inventory-targeted `test/scoria_web/live/` must reach **zero cluster rows** under full inventory `--scope full`.
- **D-03:** **Defer p2 fixes; guard architecture** — do not gate `mix test.adoption --warnings-as-errors` in CI in Phase 67. Keep overlay in `priv/host_app_proof/overlay/test/` (never under `test/support/.../overlay/test/`). Keep `generator.ex` / `runner.ex` warning-clean (they are compiled support). Add regression guard if overlay reappears under `test/support/`.
- **D-04:** **Keep p4 baselined unless inventory proves compile WAE** — `:liveview_async_teardown` stays on baseline until **2026-06-30** unless it appears as `:compile_warning` (unlikely). `:knowledge_migration_redefine` addressed via migration test architecture (see D-10), not a new long-lived baseline row.
- **D-05:** **p5 = zero in high-signal scope** — no `:unclassified_compile` in WARN-06 paths; classify or fix, do not cap via `WARNING-BASELINE.md` for taxonomy lag.
- **D-06:** **Explicit Phase 67 queue artifact** — after `--write`, `WARNING-INVENTORY.md` lists **fixed** vs **deferred** clusters with owner/expiry for p2/p4 remainder so Phase 68 does not re-litigate scope.

### Unclassified warnings policy (Gray area 2)

- **D-07:** **Zero `:unclassified_compile` in high-signal scope** (`test/scoria/`, adoption lane files, targeted `test/scoria_web/live/`). Fix in code or add `Cluster.match/1` rule + fixture in same PR.
- **D-08:** **Do not baseline unclassified caps** — `WARNING-BASELINE.md` rows are for **surface-level** deferred debt (full-suite audit, LiveView teardown), not per-message taxonomy lag.
- **D-09:** **Reorder policy for unclassified in WARN-06 paths** — treat `:unclassified_compile` under `test/scoria/` / targeted live paths as **p3-equivalent for gating** even if `ratchet_tier/1` still maps unknown compile warnings to `:p5_out_of_scope` globally; enforcement uses path-filtered inventory, not tier alone.
- **D-10:** **Ship `mix scoria.warning_inventory --fail-on-unclassified` with `--scope high_signal`** (or equivalent check in `mix scoria.warning_ratchet.check`) for maintainer/phase verification; optional policy-job hook only for postgres-free paths if any remain after fixes.

**Current examples (fix, do not baseline):**

| Symptom | Action |
|---------|--------|
| Unused import in MCP tests | Remove import or add `:test_unused_import` cluster |
| Undefined `PageController` in install fixture | Fix fixture compile or add `:install_fixture_undefined_ref` cluster |
| Dead default args in eval/review_queue* | Fix under `:test_dead_default_args` (already classified) |

### Knowledge migration redefines (Gray area 3)

- **D-11:** **Phase 67 fix: migrate-once + scoped compile isolation** in `Scoria.TestSupport.Migrations`:
  - `ensure_knowledge_migrated!/0` with process-level gate (`:persistent_term` or equivalent) so per-test `setup` does not re-run migrator.
  - Scoped `Code.put_compiler_option(:ignore_module_conflict, true)` **only** inside `migrate_knowledge!/0`, restored in `after` — never in `config/test.exs` globally.
  - Keep explicit double-call only in `migration_lane_compatibility_test.exs` (documented).
- **D-12:** **Defer structural DDL-in-lib refactor (Option A1)** to Phase 68 unless a second knowledge migration ships in 67.
- **D-13:** **Success:** `:knowledge_migration_redefine` cluster count → **0** in committed `warning-inventory.baseline.json`; semantic/knowledge paths pass under maintainer WAE command (D-18).

### Host-proof / adoption-lane noise (Gray area 4)

- **D-14:** **Fix at source, not suppress** — no blanket `@compile` on overlay templates; no baselining subprocess-only `phx.new` noise.
- **D-15:** **Compiled-in-repo rule:** `test/support/scoria/host_app_proof/{generator,runner}.ex` must stay WAE-clean; `priv/host_app_proof/overlay/test/` is maintained like Phoenix generator templates.
- **D-16:** **Adoption WAE is maintainer command in 67**, not CI policy job — `MIX_ENV=test mix test.adoption --warnings-as-errors` documented after p3 adoption-test blockers clear; expect current failures from in-repo adoption tests (unused import, undefined refs), not host-proof paths when `test/tmp/` is clean.

### CI enforcement for WARN-06 (Gray area 5)

- **D-17:** **Do not expand Postgres-free `policy` job** with DB-backed WARN-06 path lists — violates Phase 66 D-09 and contributor surprise (Oban/Ecto pattern: cheap policy → DB integration job).
- **D-18:** **Add `Scoria.WarningRatchet` SSOT** — `high_signal_wae_paths/0` composed from `WarningInventory.ratchet_tier/1`, `Mix.Tasks.Scoria.Test.Adoption.adoption_test_files/0`, and targeted LiveView globs; thin `mix scoria.warning_ratchet.check` (or `.test`) for verification. **No** raw `warning-inventory.baseline.json` path derivation (JSON is cluster counts only, D-17 Phase 66).
- **D-19:** **Phase 67 proves WARN-06 via maintainer + phase verification** using SSOT paths; extend `ci_policy_contract_test` to assert SSOT is documented and non-empty — not necessarily that `ci.yml` runs full list yet.
- **D-20:** **Phase 68 early:** add `test` job step **after** `test.runtime_to_handoff`, **before** `mix test`, running `mix scoria.warning_ratchet.test --warnings-as-errors` (same SSOT). Phase 68 replaces with full `mix test --warnings-as-errors` when green (WARN-07). Phase 69 documents gate order (CI-03).

### Plan shape / execution waves (Gray area 6)

- **D-21:** **Five plans, tier-ordered vertical slices** (not one plan per tier, not one per cluster):

| Plan | Name | Scope |
|------|------|--------|
| **67-00** | `inventory-queue-refresh` | `--write` artifacts; zero unclassified high-signal; `67-VALIDATION.md` sketch |
| **67-01** | `warn-05-canonical-surface-guard` | p0+p1 verify/fix |
| **67-02** | `warn-06-adoption-host-proof-slice` | p2 guard + in-repo adoption test WAE blockers |
| **67-03** | `warn-06-scoria-unit-test-slice` | `test/scoria/` p3 (excl. live) |
| **67-04** | `warn-06-liveview-test-slice` | `test/scoria_web/live/` p3 clusters |

- **D-22:** **Serial waves:** 67-00 → 67-01 → 67-02 → 67-03 → 67-04; optional 67-03 ∥ 67-04 only if inventory shows zero file overlap.
- **D-23:** **Every fix plan ends with** `MIX_ENV=test mix scoria.warning_inventory --write --scope full` (or explicit “no cluster change” note) + `mix scoria.warning_baseline.check`.
- **D-24:** **Per-plan verify uses scoped WAE**, never full-suite `mix test --warnings-as-errors` as plan gate.

### Cross-cutting architecture & DX

- **D-25:** **Industry pattern stack (coherent):** calendar expiry meta-gate (WARN-03) → compile WAE → contract tests → staged path WAE (67) → closeout lanes unchanged → full-suite WAE (68). Inventory cluster-count JSON = Braintrust/Langfuse-style baseline comparison; avoid per-line JSON in git.
- **D-26:** **Operator voice on failure messages** — remediation bullets like `warning_baseline.check` / `release_preview` (Field Engineer tone from brand research).
- **D-27:** **Preflight:** empty `test/tmp/` before inventory `--write`; document in `docs/operator_verification.md` subsection.
- **D-28:** **Fix `ratchet_tier` gap:** document that p1 is CI-enforced via explicit file list, not cluster mapping; optional follow-up to map contract-test warnings to `:p1_closeout_lane_contract` in inventory (Claude's discretion in execute).

### Claude's Discretion

- Exact `WarningRatchet` module API and Mix task naming (`warning_ratchet.check` vs `.test`).
- New cluster atoms (`:test_unused_import`, `:install_fixture_undefined_ref`) vs inline fixes only.
- Whether 67-02 includes a grep/contract test for overlay path regression vs extending `adoption_surface_test`.
- CI contract test placement for `WarningRatchet` path list drift.
- Whether to bump inventory `schema_version` when baseline JSON cluster counts change materially.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Warning policy and milestone scope
- `.planning/WARNING-BASELINE.md` — accepted debt registry; p4 expiry dates
- `.planning/REQUIREMENTS.md` — WARN-05, WARN-06 definitions
- `.planning/ROADMAP.md` — Phase 67 success criteria; phases 68–69 sequence
- `.planning/STATE.md` — milestone evidence (compile WAE pass, full-suite fail)
- `.planning/threads/2026-05-27-warning-ratchet-followup.md` — inventory-first, staged ratchet order

### Phase 66 decisions (inventory + CI split)
- `.planning/phases/66-baseline-expiry-and-inventory/66-CONTEXT.md` — D-23 tier order, D-24 clusters, D-27 dedupe, policy job layout
- `.planning/phases/66-baseline-expiry-and-inventory/66-VERIFICATION.md` — WARN-03/04 complete evidence

### Code SSOT (reuse, do not reinvent)
- `lib/scoria/warning_inventory.ex` — classify, `ratchet_tier/1`, `join_baseline/2`
- `lib/scoria/warning_inventory/cluster.ex` — hybrid registry
- `lib/scoria/warning_baseline.ex` — expiry semantics
- `lib/scoria/verification_lanes.ex` — closeout order (unchanged)
- `lib/mix/tasks/scoria.warning_inventory.ex` — capture mode, `--write` artifacts
- `lib/mix/tasks/scoria.warning_baseline.check.ex` — policy meta-gate
- `lib/scoria/test_support/migrations.ex` — knowledge migrator (D-11 target)
- `lib/mix/tasks/test.adoption.ex` — `adoption_test_files/0`
- `test/support/scoria/host_app_proof/generator.ex` — host proof templates
- `priv/host_app_proof/overlay/test/` — overlay smokes (not in elixirc_paths)
- `.github/workflows/ci.yml` — policy vs test job split
- `test/scoria/ci_policy_contract_test.exs` — CI ordering contracts
- `docs/operator_verification.md` — maintainer commands

### Product and engineering DNA
- `prompts/sztheory-elixir-dna.md` — operator-first DX, robust CI, composable install
- `prompts/scoria-gsd-kickoff.md` — trace/eval/baseline CI gate loop
- `prompts/phoenix-ai-lib-deep-research.md` §3 — production trace → eval → baseline → CI gate
- `prompts/scoria-brand-book-deep-research.md` — Field Engineer remediation tone

### Prior installer / proof phases
- `.planning/milestones/v2.5-phases/61-proof-and-stability-closeout/61-CONTEXT.md` — closeout chain, staged CI
- Phase 60 host-proof overlay relocation (priv not test/support overlay)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.WarningInventory` + `mix scoria.warning_inventory` — queue SSOT; `--write` produces `.planning/warning-inventory.baseline.json` + `WARNING-INVENTORY.md`
- `Scoria.WarningBaseline` + `mix scoria.warning_baseline.check` — expiry before ratchet work
- `Scoria.VerificationLanes` + `ci_policy_contract_test` — policy job order enforcement
- `Mix.Tasks.Scoria.Test.Adoption.adoption_test_files/0` — adoption path list for ratchet SSOT
- `Scoria.TestSupport.Migrations` — knowledge lane migrator (D-11)

### Established Patterns
- Markdown policy + code enforcement (baseline, lanes, inventory)
- Policy job (no Postgres) vs test job (closeout + broad suite)
- Cluster-count ratchet, not per-line git JSON
- Capture-mode inventory vs WAE gates

### Integration Points
- New: `lib/scoria/warning_ratchet.ex` + `mix scoria.warning_ratchet.*`
- `docs/operator_verification.md` — WARN-06 maintainer commands
- Phase 68: `ci.yml` test job staged WAE slot after `runtime_to_handoff`

### Evidence snapshot (2026-05-27)
- `mix compile --warnings-as-errors` — passes
- Inventory (full, clean `test/tmp/`): `test_unused_binding`, `knowledge_migration_redefine`, `unclassified_compile` — no host-proof clusters when overlay stays in `priv/`
- `mix test.adoption --warnings-as-errors` — fails on in-repo adoption/semantic tests, not host-proof paths

</code_context>

<specifics>
## Specific Ideas

- **Eval-platform loop:** Treat `warning-inventory.baseline.json` like Braintrust/Langfuse baseline comparison — Phase 67 shrinks cluster counts; Phase 68 gates on full suite or honest re-baseline.
- **Oban/Ecto CI lesson:** Policy = lint/meta/compile/contract; integration = Postgres + closeout — never run DB tests in policy job.
- **ESLint/TS footgun avoided:** No per-warning baseline caps for unclassified; registry atoms are the allowlist for warning *kinds*.
- **Rust `ignore_module_conflict`:** Scoped only at migrator boundary, never global in test config.
- **Host-proof lesson (Phase 60):** Overlay in `priv/` — subprocess warnings stay out of parent WAE unless architecture regresses.
- **szTheory DNA:** Maintainer commands are calm, exact, remediation-first — match `release_preview` / `warning_baseline.check` UX.

</specifics>

<deferred>
## Deferred Ideas

- Full-suite `mix test --warnings-as-errors` in CI — Phase 68 (WARN-07)
- `mix scoria.warning_ratchet.test` in `test` job CI step — Phase 68 early (after closeout, before broad `mix test`)
- CI-03 documentation + full gate contract bundle — Phase 69
- DDL-in-lib knowledge migration refactor — Phase 68 if second migration lands
- `mix scoria.warning_inventory --fix` auto-fix — out of scope
- Baselining `:host_proof_*` or `:unclassified_compile` counts — rejected for Phase 67
- Global `elixirc_options: [warnings_as_errors: true]` in `mix.exs` test env — defer to WARN-07
- Map `:p1_closeout_lane_contract` in `ratchet_tier/1` — optional hygiene, not blocking 67

</deferred>

---

*Phase: 67-high-signal-warning-ratchet*
*Context gathered: 2026-05-27*
