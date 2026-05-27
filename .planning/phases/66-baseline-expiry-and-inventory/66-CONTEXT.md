# Phase 66: Baseline Expiry And Inventory - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn `.planning/WARNING-BASELINE.md` from prose policy into **executable CI truth** (WARN-03) and ship a **reproducible, classified full-suite warning inventory** (WARN-04) that feeds Phase 67's high-signal ratchet.

This phase delivers **policy enforcement + measurement infrastructure only** — not warning fixes, not full-suite WAE green, not CI closeout reorder beyond adding the new gates.

Out of scope: clearing warning clusters (Phase 67), full-suite WAE in CI (Phase 68), milestone closeout wiring docs (Phase 69), installer changes, new runtime capabilities, broad LiveView refactors.

</domain>

<decisions>
## Implementation Decisions

### Baseline expiry enforcement (Gray area 1 — WARN-03)

- **D-01:** **`Scoria.WarningBaseline` + `mix scoria.warning_baseline.check`** is the SSOT for expiry enforcement. CI calls the Mix task in one line — no shell awk/grep on markdown as the primary implementation.
- **D-02:** Parse **only** rows under `## Accepted Warning Debt` until the next `##` heading. Never scan `## Resolved During …` or prose links for ISO dates.
- **D-03:** **Expiry semantics:** `Expires` is `YYYY-MM-DD` calendar date in **UTC**. Row is valid through end of expiry day; fail when `Date.utc_today() > expires`. Document this in task header output.
- **D-04:** **Strict policy rows:** accepted-debt rows with blank `Owner` or `Expires` fail the check (WARN-02 integrity), not treated as unexpired.
- **D-05:** **Exit UX:** non-zero exit with table of expired rows (Surface, Expires, Owner, days overdue) and three remediation bullets: fix debt, move to Resolved, or re-baseline with new owner+expiry+reason in same PR.
- **D-06:** Support **`--file`** (default `.planning/WARNING-BASELINE.md`) and **`--date YYYY-MM-DD`** for deterministic ExUnit (never rely on TZ for policy).
- **D-07:** Module API: `Scoria.WarningBaseline.load/1`, `accepted_rows/1`, `expired_rows/1`, `invalid_rows/1`.
- **D-08:** Do **not** add baseline check to `VerificationLanes.closeout_order/0` — this is maintainer policy, not adopter proof lane.

### CI gate placement (Gray area 2)

- **D-09:** Split CI into **`policy` job (no Postgres)** + **`test` job (Postgres, `needs: policy`)** in Phase 66 — not deferred to Phase 69.
- **D-10:** **`policy` job order:** (1) `mix scoria.warning_baseline.check`, (2) setup-beam + cache + deps, (3) `mix compile --warnings-as-errors`, (4) lane-contract WAE tests (`verification_lanes_test.exs`, `adoption_surface_test.exs`).
- **D-11:** **`test` job order unchanged for closeout:** `release_preview` → `ecto.create/migrate` → `test.adoption` → `test.runtime_to_handoff` → `mix test` → `mix test.knowledge`. Full-suite WAE slot reserved after `runtime_to_handoff` in Phase 68/69 — do not add in Phase 66.
- **D-12:** **Hard fail only** — no warn-only transition for WARN-03 (roadmap requires executable enforcement).
- **D-13:** Add CI contract test (extend `verification_lanes_test.exs` or sibling) asserting `ci.yml` contains `mix scoria.warning_baseline.check` before compile WAE and preserves closeout substring order.

### Inventory command contract (Gray area 3 — WARN-04)

- **D-14:** Ship **`mix scoria.warning_inventory`** as the documented maintainer path for WARN-04 reproducibility (not shell-only pipeline).
- **D-15:** **Capture mode, not gate mode:** run `MIX_ENV=test mix do compile --force + test` **without** `--warnings-as-errors` so inventory collects all warnings even when suite has failures. WAE remains Phase 67+ ratchet gates.
- **D-16:** **Flags:** `--format json|md|table` (default `table`), `--write`, `--since <git-ref>`, `--scope full|high_signal` (default **`full`**), `--include-runtime` (off by default), `--quiet`.
- **D-17:** **`--write` artifacts:**
  - `.planning/warning-inventory.baseline.json` — cluster **counts only** + metadata (schema_version, git_sha, generated_at) — committed, machine-diffable.
  - `.planning/WARNING-INVENTORY.md` — human summary + Phase 67 ratchet queue table — committed.
  - Full per-warning array → `tmp/warning-inventory/latest.json` (gitignored) to avoid merge churn.
- **D-18:** **Preflight DX** (like `mix scoria.release_preview` sections): assert `MIX_ENV=test`; warn/fail if `test/tmp/` pollution detected (installer fixture noise dominates inventory); note pgvector prerequisite for knowledge-cluster accuracy.
- **D-19:** **`--scope high_signal`** is maintainer shortcut only (lib/, adoption files, targeted LiveView paths) — WARN-04 closure and Phase 67 ordering use **`full`** scope only.
- **D-20:** Add `preferred_envs: ["scoria.warning_inventory": :test]` in `mix.exs`.

### Inventory classification taxonomy (Gray area 4)

- **D-21:** **Hybrid registry** — stable `cluster_id` atoms in code (`Scoria.WarningInventory.Cluster` or equivalent); regex + path heuristics inside `match/1`, not as primary identity. Directory-only bucketing is not top-level taxonomy.
- **D-22:** **Inventory row fields:** `cluster_id`, `compiler_kind`, `signal_kind` (`:compile_warning` | `:ex_unit` | `:runtime_log`), `file`, `line`, `message`, `path_area`, `lane_ids`, `in_adoption_lane`, `in_closeout`, `baseline_surface`, `ratchet_tier`, optional `owner`/`expires` from baseline join.
- **D-23:** **`ratchet_tier` order for Phase 67:** `:p0_compile_lib` → `:p1_closeout_lane_contract` → `:p2_adoption_lane_files` → `:p3_high_signal_tests` → `:p4_baselined_deferred` → `:p5_out_of_scope`. Inventory summary sorts by this.
- **D-24:** **Initial cluster registry (7 + sentinel):**
  1. `:knowledge_migration_redefine`
  2. `:test_unused_binding`
  3. `:test_dead_default_args`
  4. `:host_proof_generated_compile`
  5. `:host_overlay_test_path`
  6. `:liveview_async_teardown` (often runtime/sandbox — `--include-runtime`; maps to baseline row expiring 2026-06-30)
  7. `:unclassified_compile` — forces registry update; inventory task fails or warns if count > 0 without owner
  8. `:canonical_surface_clean` — sentinel/guardrail for WARN-05 (zero rows in p0/p1), not a debt cluster
- **D-25:** **Lane attribution** is secondary: derive from `Mix.Tasks.Scoria.Test.Adoption.adoption_test_files/0` and `Scoria.VerificationLanes` — do not use lane as sole taxonomy axis.
- **D-26:** **Do not classify** Logger `[warning]` / HTTP retry lines / SQL `severity: "warning"` as compiler warnings — prevents false inflation (ESLint/Notion baseline lesson).
- **D-27:** **Ratchet on cluster counts**, not `(file, line)` — line numbers drift; dedupe by `(cluster_id, file, message_fingerprint)`.

### Phase learnings artifact (Gray area 5)

- **D-28:** **Do not create `66-LEARNINGS.md` in discuss or plan.** Execute closeout runs `/gsd-extract-learnings 66` then merges **Carried Forward** block from assessment thread.
- **D-29:** **CONTEXT carries forward pointer only:** link `.planning/threads/2026-05-27-milestone-assessment-learnings.md`; do not restate graduation candidates A/B/C as D-xx decisions here.
- **D-30:** **At execute closeout, `66-LEARNINGS.md` includes:**
  - **Carried Forward:** Candidates A + C (installer trust; surprise-reduction done-ness) with `Source:` assessment thread.
  - **Earned this phase:** Candidate B (executable baseline expiry) once `66-VERIFICATION.md` proves WARN-03.
  - Phase-native decisions/lessons from inventory surprises (extract output).
- **D-31:** Close assessment thread routing note when `66-LEARNINGS.md` lands.

### Cross-cutting architecture

- **D-32:** **`Scoria.WarningBaseline` and `Scoria.WarningInventory` share parsing context** where sensible (baseline surface join) but remain separate modules — expiry is cheap/fast; inventory is heavy.
- **D-33:** **Pattern parity:** mirror `Scoria.VerificationLanes` / `Scoria.Install.Contract` / `mix scoria.release_preview` — code SSOT, mix task for humans, CI grep contract test for drift.
- **D-34:** **Unit tests use fixture stderr snippets** — no full-suite run in classifier unit tests; one optional integration smoke tagged separately.
- **D-35:** Document maintainer commands in `docs/operator_verification.md` **minimal subsection** ("Warning baseline and inventory") — 2–3 sentences + command list; no multi-file doc sweep (Phase 61 pattern).

### Claude's Discretion

- Exact module file layout under `lib/scoria/warning_baseline.ex` and `lib/scoria/warning_inventory/`.
- Whether `mix scoria.warning_baseline.check` and inventory share a single `mix scoria.warning.*` namespace doc in `@moduledoc`.
- JSON schema_version bump policy for inventory baseline file.
- Exact preflight behavior when `test/tmp/` exists (fail vs warn-with-continue).
- CI contract test placement (`verification_lanes_test.exs` vs dedicated file).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Warning policy and milestone scope
- `.planning/WARNING-BASELINE.md` — accepted debt registry (WARN-02); expiry source for WARN-03
- `.planning/REQUIREMENTS.md` — WARN-03, WARN-04 definitions and out-of-scope boundaries
- `.planning/ROADMAP.md` — Phase 66 success criteria; phases 67–69 staged ratchet sequence
- `.planning/STATE.md` — current evidence (compile WAE pass, full-suite WAE fail, baseline expiry 2026-06-07)
- `.planning/threads/2026-05-27-warning-ratchet-followup.md` — inventory-first, fail expired before full WAE green
- `.planning/threads/2026-05-27-milestone-assessment-learnings.md` — graduation candidates A/B/C routing for `66-LEARNINGS.md`

### Lane and maintainer-task patterns (reuse, do not reinvent)
- `lib/scoria/verification_lanes.ex` — lane SSOT; closeout order; CI command strings
- `lib/mix/tasks/scoria.release_preview.ex` — maintainer mix task DX pattern (sections, preflight, fail messages)
- `lib/mix/tasks/test.adoption.ex` — `adoption_test_files/0` for lane attribution
- `test/scoria/verification_lanes_test.exs` — CI order contract grep tests
- `.github/workflows/ci.yml` — current single-job layout to split into policy + test

### Prior phase boundaries
- `.planning/milestones/v2.5-phases/61-proof-and-stability-closeout/61-CONTEXT.md` — D-22 closeout chain; WARN-03 deferred to v2.6; optional full-suite smoke via baseline
- `.planning/milestones/v2.4-phases/57-warning-and-ci-trust/57-01-SUMMARY.md` — WARNING-BASELINE.md creation precedent

### Product and engineering DNA
- `prompts/sztheory-elixir-dna.md` — operator-first DX, robust CI, mix install/task patterns
- `prompts/scoria-gsd-kickoff.md` — eval/baseline CI gate loop; evidence-based operator trust
- `prompts/phoenix-ai-lib-deep-research.md` §3 — production trace → eval → baseline → CI gate loop (inventory feeds ratchet like eval platforms)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.VerificationLanes` — `closeout_order/0`, `ci_command/1`, lane ids for inventory attribution
- `Mix.Tasks.Scoria.Test.Adoption.adoption_test_files/0` — adoption lane file list for `:p2_adoption_lane_files` tier
- `Mix.Tasks.Scoria.ReleasePreview` — sectioned output, `Mix.raise` with remediation lists
- `test/scoria/verification_lanes_test.exs` — pattern for asserting CI YAML contains required commands in order

### Established Patterns
- **Markdown policy + code enforcement:** `.planning/WARNING-BASELINE.md` human-editable; code validates (same split as lane docs vs `VerificationLanes`)
- **Maintainer mix tasks under `mix scoria.*`:** not adopter closeout lanes; documented in operator docs
- **Staged CI gates:** compile WAE → lane-contract WAE → closeout lanes → broad test (Oban/Ecto lint-before-proof pattern)

### Integration Points
- `.github/workflows/ci.yml` — add `policy` job; wire `needs: policy` on `test` job
- `mix.exs` — `preferred_envs` for inventory task
- `docs/operator_verification.md` — minimal new subsection for maintainer commands
- Phase 67 reads `.planning/warning-inventory.baseline.json` + `WARNING-INVENTORY.md` for ratchet queue

### Known warning clusters (inventory seed evidence)
- Knowledge migration redefines (`priv/repo/knowledge_migrations/`, bootstrap compatibility tests)
- Unused vars / dead default args in `test/scoria_web/live/`
- Host-proof compile noise (`test/support/scoria/host_app_proof/`, install proof tests)
- LiveView async teardown — baselined until 2026-06-30; often runtime not compiler WAE

</code_context>

<specifics>
## Specific Ideas

- **Industry pattern:** Calendar expiry is always a **meta-gate** (Rust `bestbefore`, ESLint ratchet `REPORT-ONLY-UNTIL`, TS baseline count files) — not native to `allow`/`nolint`/Credo. Scoria implements meta-gate the Elixir way: Mix task + CI one-liner.
- **Cross-ecosystem lesson (right):** Oban/Ecto/Phoenix put cheap policy + compile WAE before DB-heavy work; Tokio uses `needs: basics`; Braintrust/Langfuse wire baseline comparison into CI gates — inventory is Scoria's "baseline comparison" for warnings.
- **Cross-ecosystem lesson (footgun):** Full JSON warning dumps in git (ESLint/Notion) cause merge hell — commit cluster counts only; Credo's grouped categories + Dialyzer stable tags inform hybrid registry design.
- **Operator voice:** Expiry failure message should read like Scoria brand — calm, exact, remediation steps (Field Engineer tone from brand book).
- **ROADMAP housekeeping:** Phase headers use em dash (`Phase 66 —`) but GSD SDK expects colon (`Phase 66:`). Fix during Phase 66 plan/execute so `init.phase-op` resolves phase metadata.

</specifics>

<deferred>
## Deferred Ideas

- Full-suite `mix test --warnings-as-errors` CI gate — Phase 68 (WARN-07)
- CI-03 milestone closeout documentation bundle — Phase 69
- Auto-fix clusters / `mix scoria.warning_inventory --fix` — out of scope; Phase 67 fixes warnings in code
- Duplicate baseline rows into `VerificationLanes` — defer unless WARN-04 needs generated policy docs from code
- Semantic or knowledge lane WAE in default closeout — optional wedge; not v2.6
- ROADMAP format fix alone — do alongside CI/workflow edits in Phase 66 execute

None — discussion stayed within phase scope beyond noted housekeeping.

</deferred>

---

*Phase: 66-baseline-expiry-and-inventory*
*Context gathered: 2026-05-27*
