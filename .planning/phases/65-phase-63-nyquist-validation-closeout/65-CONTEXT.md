# Phase 65: Phase 63 Nyquist Validation Closeout - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Sign off Phase 63's draft Nyquist validation ledger so milestone Nyquist coverage reaches **5/5 compliant phases (59–63)** before v2.5 archive.

This phase is **artifact-only ledger reconciliation** — Phase 63 implementation already passed (`63-VERIFICATION.md`, 42 tests green). No product code, test file, or installer behavior changes.

</domain>

<decisions>
## Implementation Decisions

### Evidence reconciliation (Gray area 1)
- **D-01:** **Artifact-only reconciliation** from existing `63-VERIFICATION.md` evidence — follow Phase 62 precedent exactly. Do not re-run the full Phase 63 test suite at closeout unless implementation changed after verification.
- **D-02:** Continuous CI and canonical adoption/installer lanes (`Scoria.VerificationLanes`) remain the live proof engine; Nyquist closeout updates the planning ledger to mirror already-captured evidence — principle of least surprise for GSD gap-closure phases.
- **D-03:** Optional **non-blocking structural garnish**: run the three planner/report `rg` invariant commands (~5 seconds) only if closeout happens long after verification; integration test truth stays delegated to `63-VERIFICATION.md` and CI.
- **D-04:** Do **not** invoke `/gsd-validate-phase 63` in generate-tests mode — that skill may propose redundant tests contrary to Phase 62 research. Direct ledger edit from VERIFICATION evidence is correct when verification already passed.

### Wave 0 resolution (Gray area 2)
- **D-05:** Set `wave_0_complete: true` — existing infrastructure fully covers Phase 63. The `❌ W0` markers on tasks 63-01-01 and 63-01-02 are **ledger false positives** (rg-based verify strings, not missing test files).
- **D-06:** Fix per-task **File Exists** to `✅` for all rows. For 63-01-01: rg against existing `planner.ex` is immediate structural proof. For 63-01-02: align automated command to PLAN verify block — `MIX_ENV=test mix test test/scoria/install/mode_equivalence_test.exs` (not bare `rg 'manifest_state'`).
- **D-07:** Expand Wave 0 section with **checked inventory** (Phase 61 pattern, not new task rows):
  - `test/support/scoria/host_install_fixtures.ex`
  - `test/scoria/install/mode_equivalence_test.exs`
  - `test/scoria/install/report_test.exs`
  - `test/mix/tasks/scoria.install_check_test.exs`
- **D-08:** Do **not** create new Wave 0 infrastructure or Wave 0 task rows in the Per-Task Map — reconcile, don't re-implement.

### Milestone artifact scope (Gray area 3)
- **D-09:** **Full traceability bundle** (Phase 62 Plan 03 pattern), executed in order:
  1. Reconcile `63-VALIDATION.md`
  2. Update `v2.5-MILESTONE-AUDIT.md` Nyquist frontmatter and § Nyquist Coverage (5/5 compliant)
  3. Mark `REQUIREMENTS.md` gap row `Phase 63 Nyquist validation ledger | Phase 65 | Complete`
  4. Create `65-VERIFICATION.md` with grep evidence matrix
  5. Create `65-VALIDATION.md` with Phase 65's own Nyquist sign-off
- **D-10:** **Minimal trailing updates** to `PROJECT.md` / `STATE.md` only after `65-VERIFICATION.md` exists — one bullet that Phase 65 Nyquist closeout is complete and milestone Nyquist is 5/5. Do **not** set `ready_for_archive`, do **not** close Phase 64 gap row, do **not** claim v2.5 archived.
- **D-11:** Phase 64 ledger drift (REQUIREMENTS row, `64-VALIDATION.md`, audit adoption integration) is **explicitly out of scope** — flag for follow-up but do not fix in Phase 65.

### Phase 65 closure artifact (Gray area 4)
- **D-12:** Create dedicated **`65-VERIFICATION.md`** as Phase 65 closure artifact — mirrors Phase 62 meta-closeout pattern. Phase 63 VERIFICATION proves the feature; Phase 65 VERIFICATION proves the Nyquist ledger was reconciled to that truth.
- **D-13:** Do **not** extend or mutate `63-VERIFICATION.md` after its `status: passed` — different claims, different timestamps, different archive slot.
- **D-14:** `65-VERIFICATION.md` uses **grep matrix referencing upstream artifacts** — do not duplicate the 42-test output block from `63-VERIFICATION.md`. One authoritative evidence source per fact; downstream artifacts reference + grep-verify.
- **D-15:** Create **`65-VALIDATION.md`** for Phase 65's own Nyquist ledger (~3–5 grep-only tasks mirroring 62-VALIDATION structure).

### Cross-cutting execution constraints
- **D-16:** Append **Validation Audit** section to `63-VALIDATION.md` crediting Phase 65 reconciliation date and source artifact (`63-VERIFICATION.md`) — Phase 59/61/62 pattern prevents rubber-stamping appearance.
- **D-17:** All 10 Phase 63 per-task rows → `✅ green`; frontmatter `status: approved`, `nyquist_compliant: true`, `wave_0_complete: true`; sign-off checkboxes complete.
- **D-18:** Milestone audit Nyquist update: `compliant_phases: [59, 60, 61, 62, 63]`, `partial_phases: []`, `overall: compliant`; remove Phase 63 Nyquist tech_debt bullet.

### Claude's Discretion
- Exact Validation Audit prose in `63-VALIDATION.md` (within calm-exact brand tone).
- Whether optional rg garnish runs at execute time (non-blocking either way).
- Exact task IDs in `65-VALIDATION.md` (structure follows 62-VALIDATION grep-only pattern).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 65 scope and precedent
- `.planning/ROADMAP.md` — Phase 65 goal and success criteria (5/5 Nyquist compliant)
- `.planning/REQUIREMENTS.md` — gap row `Phase 63 Nyquist validation ledger | Phase 65 | Pending`
- `.planning/v2.5-MILESTONE-AUDIT.md` — Nyquist Coverage table (currently 4/5 partial)

### Phase 62 closeout precedent (primary template)
- `.planning/phases/62-nyquist-and-traceability-closeout/62-RESEARCH.md` — "Do not add new tests. Reconcile artifacts only."
- `.planning/phases/62-nyquist-and-traceability-closeout/62-01-PLAN.md` — Nyquist reconciliation for phases 59/61
- `.planning/phases/62-nyquist-and-traceability-closeout/62-03-PLAN.md` — REQUIREMENTS + audit bundle update
- `.planning/phases/62-nyquist-and-traceability-closeout/62-VERIFICATION.md` — grep-based meta-closeout evidence
- `.planning/phases/62-nyquist-and-traceability-closeout/62-VALIDATION.md` — artifact-only Nyquist ledger pattern

### Phase 63 upstream truth (reconcile target)
- `.planning/phases/63-manifest-check-fingerprint-hardening/63-VERIFICATION.md` — implementation verification (passed, authoritative)
- `.planning/phases/63-manifest-check-fingerprint-hardening/63-VALIDATION.md` — draft ledger to sign off
- `.planning/phases/63-manifest-check-fingerprint-hardening/63-01-PLAN.md` — task 63-01-02 verify block (mode_equivalence_test)
- `.planning/phases/63-manifest-check-fingerprint-hardening/63-CONTEXT.md` — Phase 63 scope boundary (no behavior changes)

### Project vision and standards
- `prompts/sztheory-elixir-dna.md` — operator-first DX, evidence-first, zero redundant work
- `prompts/scoria-brand-book-deep-research.md` — calm exact copy, drift/warning semantics, evidence-first operator trust
- `prompts/phoenix-ai-lib-deep-research.md` — CI gates, adoption proof lanes, installable happy path
- `prompts/scoria-gsd-kickoff.md` — batteries-included install, Phoenix-native boundary

### Verification harness (Wave 0 inventory reference)
- `test/support/scoria/host_install_fixtures.ex` — subprocess host fixtures
- `test/scoria/install/mode_equivalence_test.exs` — dry-run/check parity + manifest_state
- `test/scoria/install/report_test.exs` — report projection tests
- `test/mix/tasks/scoria.install_check_test.exs` — tri-state + manifest tamper cases
- `lib/scoria/verification_lanes.ex` — canonical lane SSOT (continuous CI proof)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 62 closeout playbook: grep verification matrix, Validation Audit sections, REQUIREMENTS + audit bundle updates — copy structure, not re-invent process.
- `63-VERIFICATION.md`: 42-test evidence block and ROADMAP criteria table — source of truth for row reconciliation.
- Phase 61/59 VALIDATION.md signed-off examples: frontmatter pattern, per-task green rows, audit trail appendices.

### Established Patterns
- **Implementation truth:** `*-VERIFICATION.md` with `status: passed` + reproducible commands.
- **Execution sampling ledger:** `*-VALIDATION.md` with Nyquist frontmatter and per-task verify map.
- **Meta-closeout truth:** separate phase VERIFICATION (62, 65) referencing upstream artifacts by grep — no duplicate test output.
- **Milestone aggregate:** audit Nyquist table derived from phase VALIDATION frontmatter — must update together with REQUIREMENTS gap row.

### Integration Points
- `v2.5-MILESTONE-AUDIT.md` Nyquist frontmatter and § Nyquist Coverage — updated in same commit as 63-VALIDATION sign-off.
- `REQUIREMENTS.md` gap-closure table — Phase 65 row marks Complete.
- `PROJECT.md` / `STATE.md` — minimal trailing note only; lag verified ledger updates.

</code_context>

<specifics>
## Specific Ideas

### Coherent recommendation bundle (research synthesis)

One integrated closeout design — all four gray areas move together:

| Step | Artifact | Action |
|------|----------|--------|
| 1 | `63-VALIDATION.md` | Reconcile 10 rows green from VERIFICATION; fix W0 false positives; align 63-01-02 to mode_equivalence_test; set frontmatter approved/compliant |
| 2 | `v2.5-MILESTONE-AUDIT.md` | Nyquist 5/5 compliant; remove Phase 63 tech_debt bullet |
| 3 | `REQUIREMENTS.md` | Phase 65 gap row → Complete |
| 4 | `65-VERIFICATION.md` | Grep matrix linking steps 1–3; scope: artifact-only |
| 5 | `65-VALIDATION.md` | Phase 65 own Nyquist sign-off (~3–5 grep tasks) |
| 6 | `PROJECT.md` / `STATE.md` | One bullet: Phase 65 complete, Nyquist 5/5 — no archive claims |

### Ecosystem alignment
- **Elixir OSS norm:** CI green on `main` is execution truth; planning ledgers mirror it at closeout — not a second proof pass (Phoenix, Ecto, Oban, Igniter pattern).
- **Cross-ecosystem:** Terraform/Ansible separate check-time gates from audit reconciliation; closeout updates records, doesn't re-execute full proof unless system changed.
- **Scoria adoption contract:** `VerificationLanes` SSOT + CI lane chain = continuous evidence; Nyquist VALIDATION = maintainer attestation that sampling ledger matches that evidence.

### Footguns avoided
- Re-running 42 tests at closeout (wasteful; env drift can false-block unrelated to ledger hygiene).
- Treating `❌ W0` as "create infrastructure" when rg checks target existing source files.
- Updating VALIDATION but leaving audit at 4/5 (next agent re-plans done work).
- Mutating passed `63-VERIFICATION.md` (blurs implementation vs meta-closeout boundaries).
- Claiming milestone archive ready while Phase 64 gap row still Pending.

### Grep acceptance matrix (define in 65-VERIFICATION.md)

```bash
grep 'nyquist_compliant: true' .planning/phases/63-manifest-check-fingerprint-hardening/63-VALIDATION.md
grep 'wave_0_complete: true' .planning/phases/63-manifest-check-fingerprint-hardening/63-VALIDATION.md
grep -c '✅ green' .planning/phases/63-manifest-check-fingerprint-hardening/63-VALIDATION.md  # expects ≥10
grep 'compliant_phases: \[59, 60, 61, 62, 63\]' .planning/v2.5-MILESTONE-AUDIT.md
grep 'Phase 63 Nyquist validation ledger | Phase 65 | Complete' .planning/REQUIREMENTS.md
grep 'status: passed' .planning/phases/65-phase-63-nyquist-validation-closeout/65-VERIFICATION.md
```

</specifics>

<deferred>
## Deferred Ideas

- **Phase 64 Nyquist ledger sign-off** — `64-VALIDATION.md` still draft; separate gap-closure scope, not Phase 65.
- **Phase 64 REQUIREMENTS row + audit adoption integration update** — ledger drift exists; fix in Phase 64 follow-up or pre-archive sweep, not Phase 65.
- **Milestone archive (`/gsd-complete-milestone v2.5`)** — defer until gap table shows both Phase 64 and Phase 65 Complete, then re-run milestone audit.
- **Full test suite re-run at closeout** — only warranted when implementation changes post-verification, not for ledger hygiene.

</deferred>

---

*Phase: 65-phase-63-nyquist-validation-closeout*
*Context gathered: 2026-05-27*
