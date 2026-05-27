# Phase 61: Proof And Stability Closeout - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Close `INST-08` by proving installer output truth and idempotency across `--dry-run`, `--check`, and default apply on representative host shapes, without changing planner/apply semantics from phases 59–60.

Also regression-gate v2.4 lane contract, scoped warning policy, and CI closeout order so installer-safety work does not erode adoption reliability.

Out of scope: new installer capabilities, planner engine rewrite, `WARN-03` full-suite ratchet, additional `phx.new` hosts per edge case, or reordering the maintainer closeout chain.

</domain>

<decisions>
## Implementation Decisions

### Host topology proof matrix (Hybrid A + minimal B)
- **D-01:** Use a **shared fixture harness** (`Scoria.TestSupport.HostInstallFixtures` or equivalent) as the single source for subprocess installer hosts; refactor `install_check_test.exs` and `install_test.exs` to consume it (no third parallel fixture builder).
- **D-02:** Required fixture classes: `:compliant`, `:drift`, `:manual_review`, `:error`, `:root_list_form_browser`, `:non_root_browser_only`.
- **D-03:** Keep **one** generated Phoenix host proof (`host_app_consumer_proof_test.exs` via `phx.new --no-assets`); do not multiply `phx.new` runs for Phase 61.
- **D-04:** Add **one** explicit tailwind-absent subprocess assertion (`optional_surface_absent` → operator `skipped`, no file created); do not build a full surface Cartesian matrix.
- **D-05:** Do not expand auto-apply to undocumented router topologies; non-root-only browser remains `manual_review` with zero writes (already product truth).

### Summary truth contract (B + selective machine hardening)
- **D-06:** **Planner atoms stay canonical:** `create | update | no_op | manual_review` on entries and `plan.summary` (INST-05/06/07 compatibility).
- **D-07:** Add a **single projection layer** in `Scoria.Install.Report` (not duplicated in tests/docs) mapping planner truth to operator vocabulary:
  - `no_op` + `drift.reason_code: "optional_surface_absent"` → **skipped**
  - `no_op` + managed-region current / migrations present → **already_present**
  - `create` / `update` in preview modes → **would_change** (human); post-converge check → **already_present** where applicable
  - `manual_review` → **manual_review** (unchanged)
- **D-08:** Human summary uses **operator-ordered counts:** `would_change`, `already_present`, `skipped`, `manual_review` (plus optional one-line outcome derived from projection).
- **D-09:** JSON output adds **`summary_operator`** (additive); normalize `schema_version` to string `"1.0"`; required planner keys unchanged; consumers ignore unknown keys (Terraform-style minor bumps).
- **D-10:** **Freeze automation surface:** `SCORIA_CHECK_RESULT status=<compliant|drift|manual_review|error> exit_code=<0|1|2>` and tri-state mapping unchanged; tests assert exact trailer lines per fixture class.
- **D-11:** Cross-mode truth: same fixture → identical `entries` and `summary` between `Planner.build(..., :dry_run)` and `:check`; subprocess `--dry-run` vs `--check` normalized bodies equal (trailer stripped).
- **D-12:** Do not golden-file full CLI logs; pin reason codes, exit codes, trailers, and selective substrings only.

### Proof harness placement (Layered C)
- **D-13:** **Adoption lane** (`mix test.adoption`) remains the adopter-facing merge gate; extend it only with the **thin INST-08 slice** (mode equivalence, B-cycle idempotency, operator summary pins)—not an exhaustive drift grid.
- **D-14:** **Deep installer proof** lives in normal `test/` (same files or `@tag :install_deep`); full host-shape matrix and extended equivalence grids run under `mix test`, not adoption.
- **D-15:** Optional maintainer helper `mix test.install_contract` (install + planner tests only) is allowed for local DX; it must **not** appear in `VerificationLanes.closeout_order/0`.
- **D-16:** Do not add a fourth closeout lane or Phoenix-style separate installer Mix project in Phase 61.

### Idempotency proof depth (B + A tail + selective C)
- **D-17:** **Primary integration proof** on an **owned** fixture host (markers present, patchable root browser scope): `--dry-run` → `--check` → apply → `--check` → apply.
- **D-18:** Assertions: no writes on dry-run/check; first apply mutates only expected surfaces; post-apply check → `status=compliant exit_code=0`; second apply → snapshot unchanged + all entries `no_op` / operator **already_present**.
- **D-19:** Embed **apply→apply** convergence as the final step of D-17 (Molecule-style second converge), not a standalone-only test.
- **D-20:** **Selective per-surface subprocess cases** only where B does not cover: tailwind absent, migration copy-once, non-root browser subprocess mirror (if not fully covered by shared fixture table).
- **D-21:** Use subprocess `System.cmd("mix", …)` for exit/`System.halt` truth; unique `test/tmp/installer/fixture-*` dirs per test; exclude `.scoria/install/manifest.json` from byte snapshots (assert content separately if needed).

### Guardrail stability scope (B required; C non-blocking)
- **D-22:** Phase 61 **guardrail pass** = v2.4 executable closeout chain (Option B), not full-suite warning ratchet:
  1. `MIX_ENV=test mix compile --warnings-as-errors`
  2. `mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`
  3. `MIX_ENV=dev mix scoria.release_preview`
  4. `mix ecto.create && mix ecto.migrate` (test env)
  5. `mix test.adoption`
  6. `mix test.runtime_to_handoff`
- **D-23:** `mix test` and `mix test.knowledge` may be recorded as **optional smoke** in `61-VERIFICATION.md`; failures classified via `.planning/WARNING-BASELINE.md` do **not** block Phase 61 unless they occur inside adoption or runtime_to_handoff file lists.
- **D-24:** Do not require `mix test --warnings-as-errors` on the full suite in Phase 61 (`WARN-03` remains next milestone).

### Docs and support alignment (A + minimal C)
- **D-25:** Introduce **`Scoria.Install.Contract`** (parallel to `Scoria.VerificationLanes`) as code SSOT for commands, classification labels, trailer prefix, and default `verify_command`.
- **D-26:** Add **`@moduledoc` on `Mix.Tasks.Scoria.Install`** (Ecto-style): three modes, no-write guarantee for `--dry-run`/`--check`, exit/trailer table, pointer to operator guide.
- **D-27:** **Minimal prose only** in `docs/operator_verification.md` — new subsection **“Installer verification modes (upgrade-safe)”** (dry-run → check → remediate → apply; `--check` never writes; `manual_review` never silent overwrite).
- **D-28:** **One cross-reference** in `docs/adoption_lanes.md` under default runtime lane proof (2–3 sentences + link); do **not** run a phase-54-style multi-file doc sweep.
- **D-29:** Extend `adoption_surface_test.exs` with **narrow pins** for new operator subsection markers and `--check`; README/phoenix example/handoffs unchanged unless pins fail.

### Claude's Discretion
- Exact module name/path for shared fixtures and `Install.Contract` field naming.
- Whether `summary_operator` ships in the same plan as human projection or as a follow-on commit within Phase 61.
- Use of `@tag :install_deep` vs dedicated `test/install_contract/` directory for off-lane tests.
- Optional grouped human sections (would-change / already-present / skipped / manual-review) beyond summary counts—only if they match shipped `Report.render_human/2` without scope creep.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement contracts
- `.planning/ROADMAP.md` — Phase 61 scope and success criteria
- `.planning/REQUIREMENTS.md` — `INST-08` requirement contract
- `.planning/STATE.md` — milestone status, WARN-03 deferral, baseline expiry
- `.planning/phases/59-planner-contract-foundation/59-CONTEXT.md` — planner/check decisions
- `.planning/phases/60-drift-classification-and-safe-apply/60-CONTEXT.md` — drift/apply safety decisions
- `.planning/phases/60-drift-classification-and-safe-apply/60-VERIFICATION.md` — Phase 60 proof baseline
- `.planning/threads/2026-05-27-installer-safety-upgrade-confidence.md` — installer risks and host-topology questions
- `.planning/WARNING-BASELINE.md` — accepted debt; WARN-03 boundary

### Project vision and DX principles
- `prompts/scoria-gsd-kickoff.md` — Phoenix-native ops layer; `mix scoria.install` as adoption entry
- `prompts/sztheory-elixir-dna.md` — batteries-included, operator-first, zero-config install tasks
- `prompts/scoria-brand-book-deep-research.md` — calm, exact, evidence-first operator microcopy
- `prompts/phoenix-ai-lib-deep-research.md` — plan/check/apply and production-debugging patterns

### Installer implementation and proof surfaces
- `lib/mix/tasks/scoria.install.ex` — CLI modes (add `@moduledoc` + contract alignment)
- `lib/scoria/install/planner.ex` — canonical planner artifact
- `lib/scoria/install/report.ex` — human/JSON render + trailer (projection layer lands here)
- `lib/scoria/install/apply_executor.ex` — planner-led apply execution
- `lib/scoria/install/manifest.ex` — fingerprint freshness gate
- `lib/scoria/verification_lanes.ex` — closeout order (must remain unchanged)
- `lib/mix/tasks/test.adoption.ex` — adoption lane file list

### Verification harness
- `test/mix/tasks/scoria.install_test.exs` — subprocess install + B-cycle idempotency
- `test/mix/tasks/scoria.install_check_test.exs` — tri-state + remediation parity
- `test/mix/tasks/scoria.install_route_smoke_test.exs` — router topology compile smoke
- `test/scoria/install/planner_test.exs` — planner unit contract
- `test/scoria/host_app_consumer_proof_test.exs` — single generated host e2e
- `test/scoria/verification_lanes_test.exs` — lane + CI order contract
- `test/scoria/adoption_surface_test.exs` — docs/support truth pins
- `test/support/scoria/host_app_proof/generator.ex` — generated host harness
- `priv/host_app_proof/overlay/test/` — overlay templates (not compiled in repo root)
- `.github/workflows/ci.yml` — CI closeout order reference

### Operator-facing docs (minimal touch)
- `docs/operator_verification.md` — installer modes subsection (D-27)
- `docs/adoption_lanes.md` — cross-reference only (D-28)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Install.Planner.build/4` and surface analyzers: deterministic entries for mode-equivalence tests
- `Scoria.Install.Report`: single place to add operator projection + `summary_operator`
- `install_check_test.exs` fixture builder: refactor target for shared fixtures
- `scoria.install_test.exs`: `snapshot_host_files/1`, `subprocess_mix_env/0`, owned-host helpers for B-cycle
- `HostAppProof.Generator` + `Runner`: keep as sole expensive integration
- `Scoria.VerificationLanes`: frozen closeout chain for guardrail regression

### Established Patterns
- Subprocess `mix scoria.install` for exit codes; in-process planner/executor for fast matrix cells
- Igniter-style split: fast fixture graph + one real host proof (not N× `phx.new`)
- Terraform/kubectl lesson: stable machine trailer + semantic plan body; no full-log goldens
- Molecule lesson: second converge (apply→apply) proves idempotency
- Phase 60: remediation human/JSON parity tests are the template for INST-08 extensions

### Integration Points
- `mix test.adoption` file list — add only thin contract tests
- `adoption_surface_test.exs` — pin new operator doc fragments
- CI job `test` — deep cases run here after closeout lanes
- Future `Scoria.Install.Contract` imported by Report, tests, and doc pins

</code_context>

<specifics>
## Specific Ideas

### Ecosystem lessons applied
- **Terraform / kubectl:** One plan artifact, stable exit codes, additive JSON versioning; second plan empty after converge.
- **Ansible Molecule:** Idempotence = second run reports no changes; embed in B-cycle tail.
- **Igniter / Phoenix installer:** Fast in-memory/fixture tests + one real generated project; avoid combinatorial `phx.new`.
- **ESLint / Mix:** Separate human vs machine channels; quiet when nothing to do; do not parse stack traces as contract.
- **Elixir OSS norm:** ExUnit tags or focused `mix test.*` for slow paths; adoption lane stays the product promise.

### Coherent operator story (end-to-end)
1. First install: `mix scoria.install` → `mix ecto.migrate` → `mix test.adoption`
2. Upgrade: `mix scoria.install --dry-run` → read plan → `mix scoria.install --check` → remediate → `mix scoria.install`
3. CI/automation: parse `SCORIA_CHECK_RESULT`; never rely on prose alone
4. Blocked: `manual_review` means zero writes and explicit steps + `mix scoria.install --check` to verify

### Anti-patterns explicitly rejected
- N× `phx.new` matrix per router variant
- Full CLI output golden files
- Widening auto-apply to pass topology tests
- Fourth closeout lane or full-suite WAE as Phase 61 gate
- Phase-54-scale doc sweep across README/handoffs/examples

</specifics>

<deferred>
## Deferred Ideas

- Saved plan-file workflow (`--write-plan` / `--apply-plan`) — remains deferred from Phase 60
- `--allow-partial` apply override — remains deferred until strict default is proven in production use
- Full JSON Schema publication under `priv/schemas/` — defer until external consumers exist
- Post-apply plan re-render in the same apply run — defer; post-apply `--check` is source of truth
- `WARN-03` full-suite warning ratchet — immediate next milestone after v2.5
- Exhaustive Phoenix router grammar fuzzing — out of installer contract scope

</deferred>

---

*Phase: 61-proof-and-stability-closeout*
*Context gathered: 2026-05-27*
