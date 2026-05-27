# Phase 68: Full-Suite Warning Closure - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **WARN-07**: CI and local development run `mix test --warnings-as-errors` green, **or** remaining debt is explicitly re-baselined in `.planning/WARNING-BASELINE.md` with owner, reason, and renewed expiry — never silent drift.

Delivers the **staged → full** CI warning gate sequence reserved in Phase 67 (D-20), fixes maintainer-workflow blockers from 67-REVIEW before CI wiring, and closes the warning baseline ledger for v2.6.

**In scope:** CI test-job WAE steps, bounded code fixes for deferred p2/p4 clusters, `WARNING-BASELINE.md` + inventory artifact closeout, `ci_policy_contract_test` gate-order contracts, operator doc alignment, WR-01/WR-02 hygiene.

**Out of scope:** CI-03 documentation bundle and full milestone traceability (Phase 69), installer changes, new runtime capabilities, global `elixirc_options: [warnings_as_errors: true]` in `config/test.exs`, auto-fix inventory tasks, Hex publish (v2.7).

</domain>

<decisions>
## Implementation Decisions

### CI gate staging (Gray area 1)

- **D-01:** **Two-plan vertical slice (recommended execution shape):**
  - **68-01 — Staged WARN-06 CI gate:** Insert `mix scoria.warning_ratchet.test --warnings-as-errors` in the **test** job **after** `mix test.runtime_to_handoff`, **before** `mix test`. Keep plain `mix test` until full suite is green.
  - **68-02 — WARN-07 full flip:** Replace the ratchet step with `mix test --warnings-as-errors` when local full WAE is green and baseline ledger is updated. Consider `mix test.knowledge --warnings-as-errors` in the same plan if knowledge lane emits warnings under full capture.
- **D-02:** **Reject parallel allow-fail full WAE** — no `continue-on-error` on a shadow full-suite WAE job (contradicts Phase 66 D-12 hard-fail baseline policy and creates “red but green” maintainer distrust).
- **D-03:** **Reject direct flip without staged step** as the first CI change — full `mix test --warnings-as-errors` likely still fails on baselined debt; staged ratchet enforces high-signal paths (~421 tests) without blocking contributors on every warning class at once.
- **D-04:** **Canonical closeout order unchanged:** `release_preview` → `ecto.create/migrate` → `mix test.adoption` → `mix test.runtime_to_handoff` → **WAE gate(s)** → `mix test` → `mix test.knowledge`. Policy job still runs `warning_baseline.check` → compile WAE → lane-contract tests only (D-17).
- **D-05:** **Extend `ci_policy_contract_test`** in 68-01 to assert ratchet command appears after `runtime_to_handoff` and before broad `mix test`, and remains absent from the policy job section.
- **D-06:** **Pre-CI hygiene (68-00 or first task in 68-01):** Fix 67-REVIEW WR-01 (shared `test/tmp/` preflight/cleanup for ratchet tasks) and WR-02 (unify JSON encode path) before wiring ratchet into CI — prevents flaky inventory and maintainer false failures.

### Remaining debt — fix vs re-baseline (Gray area 2)

- **D-07:** **Hybrid fix-first (not “fix everything in one heroic pass”):**
  1. **p2 host-proof (`:host_proof_generated_compile`, `:host_overlay_test_path`):** Fix at source — subprocess isolation, `priv/host_app_proof/overlay/test/` architecture, green `mix test.adoption --warnings-as-errors`. **Do not** baseline subprocess `phx.new` noise (D-14).
  2. **p4 LiveView (`:liveview_async_teardown`):** Bounded code-fix sweep — `render_async/1` (or shared helper) at end of workflow/replay LiveView tests using `assign_async` / async UI paths; re-run inventory with `--include-runtime` to measure.
  3. **WARN-07 attempt:** `MIX_ENV=test mix test --warnings-as-errors` after p2 + bounded p4.
- **D-08:** **Reject global suppressions** — no blanket `@compile` on overlay templates, no global `xref: [exclude: ...]` for host-proof modules, no per-message caps in `WARNING-BASELINE.md` (D-08 Phase 67).
- **D-09:** **Scoped boundary only** — keep knowledge migrator `ignore_module_conflict` in `try/after` inside `migrate_knowledge!/0` (already shipped); treat as the Elixir analogue of Rust `allow` at a boundary, not repo-wide.
- **D-10:** **If LiveView teardown remains runtime-only after sweep:** Keep **one** Accepted row (surface: workflow/replay LiveView tests) with honest reason — not the full-suite umbrella. Renew expiry to **2026-07-31**, owner `scoria-web-runtime`, only if inventory still shows `:liveview_async_teardown` under `--include-runtime` and compile WAE is clean.
- **D-11:** **Delete the full-suite umbrella row** when `mix test --warnings-as-errors` passes — do **not** renew `full-suite (non-canonical)` as a catch-all (immortal-baseline footgun). If WARN-07 cannot green by **2026-06-07**, same PR must either fix code or re-baseline with **narrow** surface + evidence from `warning_inventory --write`, not vague “audit not rerun” prose.

### Adoption lane WAE in CI (Gray area 3)

- **D-12:** **Do not add a separate CI step** `mix test.adoption --warnings-as-errors` — it duplicates coverage already in `WarningRatchet.high_signal_wae_paths/0` (adoption files ⊆ ratchet).
- **D-13:** **Keep plain `mix test.adoption`** as the behavioral default-lane proof integrators run (`operator_verification.md`); warnings strictness is enforced by the **ratchet bridge** (68-01) then **full suite WAE** (68-02).
- **D-14:** **Document the mapping** in `docs/operator_verification.md`: CI enforces adoption-file warnings via `mix scoria.warning_ratchet.test --warnings-as-errors` (paths include `Mix.Tasks.Scoria.Test.Adoption.adoption_test_files/0`), not a second adoption invocation.
- **D-15:** **Maintainer command remains** `MIX_ENV=test mix test.adoption --warnings-as-errors` for adopter-parity debugging after p2 fixes — not a third CI step.

### Baseline ledger closeout (Gray area 4)

- **D-16:** **On full WARN-07 success:** Move both Accepted rows to `## Resolved During v2.6` with resolution dates; leave `## Accepted Warning Debt` empty (header + table structure only). Run `mix scoria.warning_inventory --write --scope full` with clean `test/tmp/`; commit `warning-inventory.baseline.json` with `"clusters": {}` as measurement corroboration.
- **D-17:** **On partial success (full WAE green except documented runtime teardown):** Resolve/remove full-suite row; keep **at most one** Accepted row for LiveView async teardown (D-10); inventory JSON non-empty **only** for clusters that truly remain.
- **D-18:** **Baseline closeout in the same PR as CI flip** for the **2026-06-07** full-suite expiry — policy job runs `warning_baseline.check` on every PR; expired rows block merge regardless of test-job work.
- **D-19:** **Reject per-cluster Accepted rows in markdown** (Option D) — cluster kinds belong in `WarningInventory.Cluster` registry + JSON counts, not duplicated prose rows that drift from `join_baseline/2`.
- **D-20:** **Do not add CI diff-on-JSON** in Phase 68 — JSON is eval-style measurement; WAE + markdown expiry are enforcement. Phase 69 documents the maintainer loop (CI-03).

### Plan shape / execution waves

- **D-21:** **Four plans, ordered:**

| Plan | Name | Scope |
|------|------|--------|
| **68-00** | `ratchet-ci-hygiene` | WR-01 tmp preflight/cleanup; WR-02 JSON encode; optional `high_signal_path?/1` memoization (IN-01) |
| **68-01** | `staged-ratchet-ci-gate` | Wire `warning_ratchet.test --warnings-as-errors` in `ci.yml`; extend `ci_policy_contract_test`; operator doc note |
| **68-02** | `p2-adoption-wae-debt` | Host-proof / adoption compile path fixes; green `mix test.adoption --warnings-as-errors` |
| **68-03** | `warn-07-full-wae-closeout` | Bounded LiveView teardown fixes; full `mix test --warnings-as-errors`; baseline ledger + inventory `--write`; swap CI to full WAE |

- **D-22:** **Serial waves:** 68-00 → 68-01 → 68-02 → 68-03. Do not merge 68-03 CI flip before local full WAE green.
- **D-23:** **Every plan touching warnings ends with** `mix scoria.warning_baseline.check` + scoped verification command (ratchet or full WAE), never inventory capture as the only gate.

### Cross-cutting architecture & DX

- **D-24:** **Industry loop (coherent with Phase 67 D-25):** calendar expiry (WARN-03) → compile WAE → lane contracts → closeout lanes (behavior) → staged path WAE (68-01) → full-suite WAE (68-02/03) → inventory snapshot. Matches Braintrust/Langfuse **baseline comparison → CI gate** from `prompts/phoenix-ai-lib-deep-research.md` and Scoria kickoff eval workbench vision.
- **D-25:** **Operator-first failure copy** — new CI steps and baseline remediation follow Field Engineer tone (`prompts/scoria-brand-book-deep-research.md`): evidence-based bullets (which command, which paths, what to run next), not “fix your warnings.”
- **D-26:** **Principle of least surprise for adopters:** CI mirrors `operator_verification.md` lane **commands**; WAE is an additional maintainer bar, not a rename of `mix test.adoption`.
- **D-27:** **Ecosystem pattern:** Oban/Ecto split — cheap policy job vs Postgres integration job; Scoria never runs ratchet in policy (D-17). Elixir idioms: fix warnings, scoped compiler options at boundaries, subprocess for generated host apps (Phoenix/Igniter pattern).
- **D-28:** **Anti-patterns rejected:** ESLint global ignore / Rust crate-wide `#![allow(...)]` / immortal umbrella baseline / allow-fail CI jobs / baselining `:unclassified_compile` counts.

### Claude's Discretion

- Whether 68-03 adds WAE to `mix test.knowledge` in the same CI step or a follow-up task.
- Exact `render_async` helper extraction vs per-test calls for LiveView teardown.
- Memoization strategy for `WarningRatchet.path_set/1` (IN-01).
- Whether 68-02 and 68-03 can merge if full WAE greens early during p2 work.
- DDL-in-lib knowledge migration refactor (67 D-12) — only if a second knowledge migration ships during 68; not required for WARN-07.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Warning policy and milestone scope
- `.planning/WARNING-BASELINE.md` — accepted debt registry; 2026-06-07 full-suite expiry pressure
- `.planning/WARNING-INVENTORY.md` — Phase 67 fixed vs deferred queue
- `.planning/REQUIREMENTS.md` — WARN-07 definition
- `.planning/ROADMAP.md` — Phase 68 success criteria; Phase 69 CI-03 sequence
- `.planning/STATE.md` — milestone evidence and operator next steps
- `.planning/threads/2026-05-27-warning-ratchet-followup.md` — staged ratchet intent

### Phase 67 decisions and review
- `.planning/phases/67-high-signal-warning-ratchet/67-CONTEXT.md` — D-14–D-20 CI staging, fix vs defer
- `.planning/phases/67-high-signal-warning-ratchet/67-REVIEW.md` — WR-01, WR-02 blockers before CI wiring
- `.planning/phases/67-high-signal-warning-ratchet/67-VERIFICATION.md` — WARN-06 closeout evidence
- `.planning/phases/66-baseline-expiry-and-inventory/66-CONTEXT.md` — policy vs test job, baseline parser rules

### Code SSOT
- `lib/scoria/warning_ratchet.ex` — high-signal WAE paths
- `lib/mix/tasks/scoria.warning_ratchet.{test,check}.ex` — maintainer + CI commands
- `lib/mix/tasks/scoria.warning_inventory.ex` — capture, preflight, `--write` artifacts
- `lib/scoria/warning_baseline.ex` — expiry enforcement
- `lib/scoria/verification_lanes.ex` — closeout order
- `lib/mix/tasks/test.adoption.ex` — adoption file list
- `.github/workflows/ci.yml` — policy + test jobs
- `test/scoria/ci_policy_contract_test.exs` — gate order contracts
- `docs/operator_verification.md` — adopter-facing lane commands

### Product and engineering DNA
- `prompts/sztheory-elixir-dna.md` — operator-first DX, robust CI
- `prompts/phoenix-ai-lib-deep-research.md` §3 — trace → eval → baseline → CI gate loop
- `prompts/scoria-gsd-kickoff.md` — eval workbench + CI regression gates vision
- `prompts/scoria-brand-book-deep-research.md` — Field Engineer remediation tone, evidence-over-intuition

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.WarningRatchet.high_signal_wae_paths/0` — CI staged gate SSOT (~421 tests green)
- `mix scoria.warning_ratchet.test` / `.check` — verification commands
- `mix scoria.warning_baseline.check` — policy job meta-gate (runs first)
- `Scoria.CiPolicyContractTest` — extend for ratchet placement
- `priv/host_app_proof/overlay/test/` + `host_app_proof_architecture_test.exs` — p2 architecture guard

### Established Patterns
- Policy (no Postgres) vs test (Postgres + closeout) job split
- Markdown baseline = human policy; JSON inventory = cluster counts; registry = warning kinds
- Plain lane commands for behavior; WAE as separate maintainer/CI strictness layer
- Inventory preflight rejects polluted `test/tmp/`

### Integration Points
- `.github/workflows/ci.yml` test job — insert WAE step after `runtime_to_handoff`
- `docs/operator_verification.md` — document CI↔ratchet mapping
- `.planning/WARNING-BASELINE.md` — Resolved During v2.6 section on success

### Evidence snapshot (2026-05-27)
- `mix scoria.warning_ratchet.test --warnings-as-errors` — passes (421 tests)
- `mix test.adoption --warnings-as-errors` — green for maintainers (67-02)
- Full `mix test --warnings-as-errors` — not re-verified this session; STATE.md lists remaining classes
- Inventory cluster JSON — `{}` after Phase 67 closeout; deferred items tracked in WARNING-INVENTORY.md prose queue

</code_context>

<specifics>
## Specific Ideas

- **Eval-platform coherence:** Treat Phase 68 as flipping the CI gate from “high-signal experiment baseline” to “production regression gate” — same loop as Braintrust/Langfuse, implemented as Elixir WAE + cluster inventory rather than a hosted eval UI.
- **Adopter trust:** Host teams run `mix test.adoption` and see the same step in CI; warning strictness is invisible to them until they opt into maintainer commands — least surprise.
- **No immortal debt:** The 2026-06-07 expiry is a forcing function — Phase 68 must resolve or honestly re-baseline in the merge PR, not slip to Phase 69.
- **Footgun avoided:** Parallel allow-fail full WAE would teach contributors to ignore red jobs; rejected.
- **szTheory DNA:** Robust CI, operator-first remediation copy, composable install boundaries preserved.

</specifics>

<deferred>
## Deferred Ideas

- CI-03 full gate documentation and REQUIREMENTS traceability bundle — Phase 69
- DDL-in-lib structural knowledge migration refactor — only if second migration ships
- `mix scoria.warning_inventory --fix` auto-fix — out of scope
- Global test env `warnings_as_errors` — defer unless 68-03 proves necessary
- Explicit `mix test.adoption --warnings-as-errors` CI step — rejected (duplicate of ratchet)
- CI diff-on-`warning-inventory.baseline.json` — Phase 69 optional hygiene
- Map `:p1_closeout_lane_contract` in `ratchet_tier/1` — optional, not blocking

</deferred>

---

*Phase: 68-full-suite-warning-closure*
*Context gathered: 2026-05-27*
