# Phase 70: Docs Truth Foundation - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Align README and support docs with v2.5+ shipped capability using **capability-based truth** (not internal milestone codenames). Commit `mix scoria.test.install_contract` as a maintainer-only lane with adoption boundary tests. Document that the bounded semantic fast-path lane is **local/maintainer troubleshooting**, not a PR CI closeout step. Explain planning milestones (`v2.x`) vs Hex semver (`0.1.0`) once for maintainers in the CI gate map.

**Non-goals (unchanged):** Hex publish, README Hex dep flip, release-please workflows, CI topology changes, SEM-CI-01.

</domain>

<decisions>
## Implementation Decisions

### Shipped banner copy (DOCS-03)
- **D-01:** Replace both README milestone sentences (`Scoria is shipped through \`v2.1 …\``) with a **capability headline + five bullets** under the intro (before "Who This Is For").
- **D-02:** Headline pattern: lane-based Phoenix runtime; narrow public surface; **start with default runtime**, add lanes only when needed.
- **D-03:** Required capability bullets (nouns must appear in README and align with "Choose Your Lane"):
  - **Default runtime** — durable runs, approvals, operator evidence
  - **Bounded handoff** — narrow same-run delegation, projected context, visible lineage
  - **Semantic fast path** — opt-in, tenant-partitioned reuse for explicitly safe read-only work
  - **Optional knowledge** — pgvector retrieval/grounding when chosen
  - **Upgrade-safe install** — `mix scoria.install` with plan/check/apply paths
- **D-04:** Keep **proof commands out of the banner bullets**; `mix test.adoption` and lane verifiers stay in existing Verification / Choose Your Lane / Install sections.
- **D-05:** Collapse README `## Status` into a short **pre-Hex publish note** (Hex metadata ready; first publish `0.1.0` from tagged GitHub release). No milestone codenames, no duplicate capability list.
- **D-06:** Remove milestone vocabulary from adopter-facing semantic copy (`canonical v2.1 troubleshooting lane` → capability wording); maintainer operator guide may reference SEM-CI-01 deferral by name only in CI gate map.

### Milestone vs Hex semver (DOCS-04)
- **D-07:** **Primary (and Phase 70 only) adopter/maintainer explanation** lives at the end of `docs/operator_verification.md` § CI gate map (maintainers), as **Version namespaces** — two sentences:
  - Hex/git releases use semver (`0.1.0`, `v0.1.0`, `{:scoria, "~> 0.1"}`).
  - Planning milestones (`v2.x` in `.planning/`) are internal shipped-work tranches, **not** a second installable version axis.
- **D-08:** **Do not** add a README callout or banner about `v2.x` vs semver (deps snippet `tag: "v0.1.0"` is sufficient for adopters). Phase 71 CHANGELOG preamble becomes release SSOT; do not duplicate there in Phase 70.
- **D-09:** Never align Hex version to milestone numbers (no `2.7.0` on Hex).

### README Install upgrade path (DOCS-03 / ROADMAP #2)
- **D-10:** Add `### Upgrading or re-running install` under `## Install`, **after** Tailwind-optional paragraph, **before** `## Quickstart`.
- **D-11:** Four-step ordered list (no full code fence): `--dry-run` → `--check` → remediate `manual_review` → apply `mix scoria.install`.
- **D-12:** Three guardrail bullets: no-write modes; `manual_review` never silently overwritten; apply blocks if managed files drift between check and apply (re-run preview/check).
- **D-13:** Single deep link to `docs/operator_verification.md#installer-verification-modes-upgrade-safe` for `SCORIA_CHECK_RESULT`, exit codes, drift table — **SSOT stays operator guide + `mix help scoria.install`**.
- **D-14:** Do not duplicate trailer format, exit-code table, or `mix scoria.test.install_contract` in README Install.

### `adoption_surface_test` contract (DOCS-03 / ROADMAP #3)
- **D-15:** **Hybrid + SSOT module** — add `Scoria.AdopterDocContract` exporting noun lists and refute patterns; tests consume it (same pattern as `VerificationLanes`).
- **D-16:** Replace milestone banner assert with one test **"README shipped truth is capability-based"**: assert `shipped_capability_nouns/0` + `upgrade_safe_install_markers/0`; refute `milestone_banner_refutes/0`.
- **D-17:** Required positive strings (minimum):
  - `default runtime lane` (or `default runtime` in banner — test allows banner nouns from SSOT list)
  - `bounded handoff`
  - `semantic fast path`
  - `optional knowledge`
  - `mix scoria.install --check`
  - `mix scoria.install --dry-run`
- **D-18:** Refute on **README only**: `Scoria is shipped through`, `shipped through \`v\d+`, maintainer commands (`mix scoria.test.install_contract`, `mix test.install_contract`, `mix scoria.test.ci_trust`, `mix scoria.warning_ratchet`, `mix scoria.warning_inventory`, `mix scoria.warning_baseline`, `mix scoria.eval`, `mix scoria.milestone`, `mix scoria.test.knowledge`).
- **D-19:** Keep `VerificationLanes.command/1` asserts for adoption, runtime_to_handoff, semantic, knowledge in README; **maintainer command presence** stays in `ci_policy_contract_test.exs` (require `install_contract` in operator guide after docs land).
- **D-20:** Do not refute bare `mix test` or the maintainer **link** to `#ci-gate-map-maintainers`.

### Maintainer lane boundaries (INST-DX-01)
- **D-21:** **Adoption lane (12 files)** — unchanged WIP list in `Mix.Tasks.Scoria.Test.Adoption`: excludes `planner_test`, `report_test`, `mode_equivalence_test`, `install_check_test`, `verification_lanes_test`.
- **D-22:** **`mix scoria.test.install_contract` (5 files):** `report_test`, `mode_equivalence_test`, `scoria.install_test`, `scoria.install_check_test`, `planner_test`. Intentional **superset** overlap: `install_test` stays in both adoption (PR closeout behavior) and install_contract (maintainer bundle).
- **D-23:** Register **`scoria.test.install_contract` and `test.install_contract`** in `mix.exs` `cli/0` `preferred_envs` → `:test`.
- **D-24:** Document install_contract only in `docs/operator_verification.md` under **Installer contract proofs (maintainers)** — not README, not `adoption_lanes.md`, not `VerificationLanes`.
- **D-25:** Add `test/mix/tasks/test.install_contract_test.exs` — file list parity, both `Mix.Task.get/1`, refute `VerificationLanes` membership.
- **D-26:** Do **not** add install_contract to CI workflow or `closeout_order/0`.

### CI gate map additions (DOCS-04 / ROADMAP #5)
- **D-27:** Insert **Verification lanes in PR CI** matrix after numbered test-job list, before "Local parity".
- **D-28:** Semantic row: lane label **Semantic fast-path**; command `mix test.semantic_fast_path`; **In PR CI? = Not in PR CI**; Notes: local maintainer command, link to `#semantic-fast-path-troubleshooting-lane`, SEM-CI-01 deferred, semantic tests still run via full-suite WAE.
- **D-29:** **Version namespaces** line immediately under the table (D-07 text).
- **D-30:** Extend `ci_policy_contract_test.exs` to assert `Not in PR CI`, `mix test.semantic_fast_path`, and `Version namespaces` in gate map.
- **D-31:** Leave `.github/workflows/ci.yml` and `VerificationLanes.closeout_order/0` unchanged.

### Claude's Discretion
- Exact banner prose polish (keep meaning and nouns locked).
- Whether to add optional positive `upgrade-safe` substring assert beyond install markers.
- Trimming redundant API pins from `adoption_surface_test` if already covered by `*_example_source_test.exs` (only if zero coverage loss).
- `Scoria.AdopterDocContract` module location (`lib/scoria/` vs `test/support/`) — prefer `lib/scoria/` if used by policy tests too.

### Folded Todos
- None (no todo matches for phase 70).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 70 goal, success criteria, non-goals
- `.planning/REQUIREMENTS.md` — DOCS-03, DOCS-04, INST-DX-01
- `.planning/PROJECT.md` — v2.7 milestone intent, capability-based docs, preserve v2.4–v2.6 contracts
- `.planning/STATE.md` — deferred SEM-CI-01, WIP install_contract note

### Product vision and DX principles
- `prompts/sztheory-elixir-dna.md` — batteries-included composable, operator-first DX, zero-config install
- `prompts/phoenix-ai-lib-deep-research.md` — AI quality layer positioning; executable proof / CI gates; compose-don't-replace ecosystem
- `prompts/scoria-brand-book-deep-research.md` — README direct/scannable tone; capability vocabulary

### Executable SSOT (code)
- `lib/scoria/verification_lanes.ex` — lane commands, closeout order, boundary sentences
- `lib/mix/tasks/test.adoption.ex` — adoption file list
- `lib/mix/tasks/scoria.test.install_contract.ex` — install contract file list (commit in this phase)
- `.github/workflows/ci.yml` — PR CI topology (read-only this phase)

### Docs under change
- `README.md` — banner, Install upgrade subsection, Status collapse
- `docs/operator_verification.md` — CI gate map table, version namespaces, install_contract maintainer section
- `docs/semantic_fast_path.md` — remove milestone codename from verification wording
- `docs/adoption_lanes.md` — keep `--check` link to operator guide; no install_contract

### Tests
- `test/scoria/adoption_surface_test.exs` — adopter doc contract
- `test/scoria/ci_policy_contract_test.exs` — gate map + maintainer command presence
- `test/mix/tasks/test.adoption_test.exs` — adoption file list boundary
- `test/mix/tasks/test.install_contract_test.exs` — new

### v2.5 installer truth (behavior unchanged)
- `docs/operator_verification.md` § Installer verification modes — dry-run/check/apply SSOT
- `.planning/milestones/v2.5-phases/63-manifest-check-fingerprint-hardening/63-CONTEXT.md` — check reflects live host truth

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.VerificationLanes` — canonical lane commands and closeout chain for tests and docs
- `Mix.Tasks.Scoria.Test.Adoption` / `InstallContract` — lane file lists already split in WIP
- `test/scoria/ci_policy_contract_test.exs` — pattern for gate-map string contracts
- `test/scoria/adoption_surface_test.exs` — doc drift harness to extend, not replace

### Established Patterns
- Dual task registration: `mix scoria.test.*` + `mix test.*` with `preferred_envs` in `mix.exs` `cli/0`
- Doc SSOT: README teases + links; `operator_verification.md` holds maintainer/CI depth
- Policy job runs `adoption_surface_test` in lane-contract WAE; test job runs behavioral closeout lanes

### Integration Points
- README line 5 maintainer link → `#ci-gate-map-maintainers` (keep)
- `adoption_surface_test` operator-guide test already pins installer modes; extend for install_contract in operator doc only
- WIP uncommitted: `scoria.test.install_contract.ex`, adoption test file list trim — fold into Phase 70 execution

</code_context>

<specifics>
## Specific Ideas

- **Ecosystem alignment:** Oban/LiveView README pattern — capabilities and features, not internal milestone names; Hex version is the only consumer version axis (szTheory oarlock/sigra CHANGELOG split for releases).
- **Scoria differentiator:** Executable proof lanes belong in Verification sections; banner states **what** is shipped, not **which planning milestone** closed.
- **Installer footguns (v2.5):** README carries guardrails; operator guide keeps drift table and `SCORIA_CHECK_RESULT` — never two SSOTs.
- **Semantic lane clarity:** "Not in PR CI" as bounded lane ≠ "semantic untested" — Notes must mention full-suite WAE coverage.
- **LangChain/Python lesson avoided:** No "production-ready" overclaim; opt-in language for semantic and knowledge lanes.

</specifics>

<deferred>
## Deferred Ideas

- **SEM-CI-01** — semantic lane as explicit PR CI step (document deferral only; table row references it)
- **CHANGELOG milestone vs semver preamble** — Phase 71 (`HEX-01` prep)
- **README Hex badge + `package_surface_test` flip** — Phase 72
- **Trimming verbose handoff/gap-ledger asserts from `adoption_surface_test`** — optional hygiene if time permits; not required for Phase 70 acceptance

### Reviewed Todos (not folded)
- None surfaced by `todo.match-phase`.

</deferred>

---

*Phase: 70-docs-truth-foundation*
*Context gathered: 2026-05-28*
