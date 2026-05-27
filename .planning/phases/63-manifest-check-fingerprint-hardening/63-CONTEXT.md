# Phase 63: Manifest Check Fingerprint Hardening - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v2.5 audit integration gap `manifest-check-fingerprint` by making check-time vs apply-time fingerprint semantics explicit, honest in code, and discoverable for operators and maintainers.

This phase documents and lightly hardens the existing live-host check contract. It does **not** introduce manifest-baseline drift at check time, change tri-state exit semantics, or rewrite installer architecture.

</domain>

<decisions>
## Implementation Decisions

### Check-time fingerprint contract (Gray area 1)
- **D-01:** `--check` and `--dry-run` always reflect **current host truth** against **current Scoria package desired state**. Classifications, drift reason codes, and trailer exits derive from live surface analyzers only.
- **D-02:** `.scoria/install/manifest.json` is **not** a check-time drift baseline. Stored manifest fingerprints do not influence check classification or exit codes.
- **D-03:** Reject manifest-baseline check (compare live vs last-applied hash) and hybrid blocking advisory — full-file hash baselines create false positives on formatting edits and package upgrades; Phase 59 already rejected hash-only ownership for the same reason.

### Hardening depth (Gray area 2)
- **D-04:** **Document + minimal honest code fix** — remove the misleading `Map.put_new(:fingerprint, manifest_entry[:fingerprint])` path that suggests manifest merge but never runs. Do **not** switch to `Map.put/3` (would corrupt plan fingerprints and break apply freshness).
- **D-05:** Keep `Manifest.load/1` in planner **only** for informational metadata attachment (manifest presence, optional `manifest_fingerprint` field on entries) — not for classification or fingerprint override on plan entries used by check/apply gates.
- **D-06:** `Manifest.validate_freshness/2` remains apply-time only: compares **plan entry live fingerprint (at build)** vs **disk at apply moment**. Document that it does not read stored manifest file for the gate.

### Missing / first-run manifest (Gray area 3)
- **D-07:** Absent manifest is **informational only** — no exit-code effect, no `manual_review` escalation solely because manifest is missing.
- **D-08:** Fresh host `--check` may exit `1` for **ownership markers** or **pending migrations** — that is correct and unrelated to manifest absence.
- **D-09:** Compliant host with markers present but no manifest file must remain **compliant exit 0** (preserve B-cycle and legacy manual-setup paths).
- **D-10:** Add planner evidence field `manifest_state: :absent | :present` for reporting; must not alter tri-state mapping.

### Documentation audience (Gray area 4)
- **D-11:** **Split documentation** (Phase 61 layered pattern):
  - Operators: new `### Check vs apply drift detection` subsection in `docs/operator_verification.md` — what happened / why / what next; calm copy; "do not edit manifest by hand"
  - Command surface: brief `## Apply freshness` in `lib/mix/tasks/scoria.install.ex` `@moduledoc` with pointer to operator guide
  - Maintainers: `@moduledoc` on `Scoria.Install.Manifest` and `Scoria.Install.Planner` describing check vs apply roles
  - Optional one-liner cross-link in `docs/adoption_lanes.md`
- **D-12:** Do **not** add fingerprint semantics to README (v2.4 doc-drift lesson). Do **not** create a new top-level doc file.
- **D-13:** Extend `test/scoria/adoption_surface_test.exs` pins for new operator-guide phrases (D-29 pattern).

### Check output shape (Gray area 5)
- **D-14:** **Additive non-breaking output** — no trailer or tri-state exit changes; remediation payload remains shared human/JSON truth.
- **D-15:** JSON: add optional top-level `manifest` map (`present`, `path`, `schema_version`, `check_role: "informational"`, `apply_role: "freshness_baseline"`). Add optional per-entry `manifest_fingerprint` when stored manifest entry exists. Keep existing `fingerprint` as live-observed hash — do not rename.
- **D-16:** Human: one calm manifest context line when manifest present (and optional absent line — pick one and pin in tests). Same line in dry-run and check to preserve D-11 mode equivalence.
- **D-17:** Reject rich per-entry `manifest_fingerprint` vs `live_fingerprint` drift blocks in default check output — that belongs at apply block time, not check UX.

### Test contract (cross-cutting)
- **D-18:** New tests must prove: tampered manifest fingerprints do not change check classification/exit; absent manifest does not alter tri-state; post-apply manifest write unchanged.
- **D-19:** Preserve existing stale-apply test (`blocks stale planner fingerprints before writes`) and mode equivalence (dry-run ≡ check body) without regression.

### Claude's Discretion
- Exact human copy for manifest absent/present lines (within brand calm-exact tone).
- Whether to bump JSON `schema_version` minor string to `"1.1"` with additive-only note vs stay at `"1.0"` with documented additive fields.
- Whether `Contract` module gets explicit manifest metadata key constants.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase contracts
- `.planning/ROADMAP.md` — Phase 63 scope and success criteria
- `.planning/REQUIREMENTS.md` — INST-07 integration partial; Phase 63 gap row
- `.planning/v2.5-MILESTONE-AUDIT.md` — `manifest-check-fingerprint` integration gap evidence
- `.planning/phases/60-drift-classification-and-safe-apply/60-CONTEXT.md` — D-10 apply freshness gate, ownership model
- `.planning/phases/59-planner-contract-foundation/59-CONTEXT.md` — tri-state check, D-11 mode equivalence
- `.planning/phases/61-proof-and-stability-closeout/61-CONTEXT.md` — doc layering pattern (D-27/D-29)

### Project vision and standards
- `prompts/scoria-gsd-kickoff.md` — batteries-included install, Phoenix-native boundary
- `prompts/sztheory-elixir-dna.md` — zero-config onboarding, operator-first DX, idempotent install
- `prompts/scoria-brand-book-deep-research.md` — calm exact operator copy, evidence-first, drift/warning semantics
- `prompts/phoenix-ai-lib-deep-research.md` — installable happy path, decomposable architecture, CI gates

### Implementation surfaces
- `lib/scoria/install/planner.ex` — planner build, annotate_entries, normalize_contract_fields
- `lib/scoria/install/manifest.ex` — load/write, validate_freshness, manifest path
- `lib/scoria/install/apply_executor.ex` — apply freshness gate, persist_manifest!
- `lib/scoria/install/report.ex` — check_result, human/JSON rendering, trailer
- `lib/scoria/install/contract.ex` — trailer prefix, schema_version, operator summary keys
- `lib/mix/tasks/scoria.install.ex` — CLI modes and mix help

### Verification harness
- `test/mix/tasks/scoria.install_test.exs` — stale fingerprint block, B-cycle idempotency
- `test/mix/tasks/scoria.install_check_test.exs` — tri-state trailer matrix
- `test/scoria/install/mode_equivalence_test.exs` — dry-run ≡ check body
- `test/scoria/adoption_surface_test.exs` — operator guide drift guards

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Install.Planner.build/4`: single artifact for dry-run, check, apply; surface analyzers already emit authoritative live `:fingerprint`.
- `Scoria.Install.Report`: human/JSON rendering and stable trailer — extend with manifest metadata line/object only.
- `Scoria.Install.Contract`: operator summary keys and schema_version — extend additively for manifest metadata constants if needed.
- `Scoria.Install.Manifest`: load/write/validate_freshness already separate concerns — document roles, don't conflate.

### Established Patterns
- Check exit derives from entry `classification` only (`Report.check_result/1`) — preserve.
- `Map.put_new` on planner fields means surface analyzer output wins — dead manifest fingerprint branch is the audit gap.
- Apply blocks stale plans via `Manifest.validate_freshness/2` before writes — independent of check contract.
- Phase 61 adoption_surface_test pins prevent operator doc drift — reuse for new subsection.

### Integration Points
- `Mix.Tasks.Scoria.Install` — mix help pointer to operator guide subsection.
- `docs/operator_verification.md` — primary operator-facing install/check/apply workflow doc.
- `docs/adoption_lanes.md` — optional cross-link only.

</code_context>

<specifics>
## Specific Ideas

### Coherent recommendation bundle (research synthesis)

One integrated design closes the audit gap without behavior churn:

| Mode | Question answered | Fingerprint source | Manifest role |
|------|-------------------|-------------------|---------------|
| `--check` / `--dry-run` | "Is my host converged with current Scoria now?" | Live surface analyzers | Informational only (presence + last-applied snapshot in output) |
| Apply (preflight) | "Did disk change since this plan was built?" | Plan entry fingerprint vs live disk | Gate input — not stored manifest file |
| Post-apply | "What did Scoria last write?" | Live fingerprints persisted | Written to `.scoria/install/manifest.json` |

### Ecosystem alignment
- **Elixir idioms:** Igniter/Oban/Phoenix installers use live filesystem reconciliation, not persisted install state at check time. Scoria's `--check` with CI trailer is ahead of ecosystem norms — don't dilute with a second drift semantics layer.
- **Cross-ecosystem lessons:** Ansible `--check` and Terraform `plan` compare desired config to **live** state; state files inform apply/audit, not silent load-then-ignore paths. Terraform plan-before-apply freshness maps to Scoria's apply gate.
- **Footguns avoided:** Manifest-baseline check (ArgoCD/Terraform stale-state alert fatigue); `put` instead of removing dead merge (breaks D-10); missing-manifest manual_review (false-positive CI on greenfield/compliant hosts).

### Operator copy intent (calm, evidence-first)
- When manifest absent: "Install manifest not found — check inspected live host surfaces only. First successful apply writes `.scoria/install/manifest.json`."
- When apply blocks on stale: "Apply performed zero writes. Re-run `--dry-run` and `--check`, remediate drift, then apply without editing managed files between check and apply."

</specifics>

<deferred>
## Deferred Ideas

- **Manifest-baseline check drift** ("host modified since last apply" even when classifiers say `no_op`) — new product semantics; belongs in future milestone (sealed-plan / WARN territory), not v2.5 gap closure.
- **Rich JSON drift blocks** with explicit hash diff per entry in default check output — apply-time gate territory; defer unless check-time manifest comparison is implemented separately.
- **Rename `fingerprint` to `observed_fingerprint`** in JSON — breaking change; defer unless major schema version bump is justified.

</deferred>

---

*Phase: 63-manifest-check-fingerprint-hardening*
*Context gathered: 2026-05-27*
