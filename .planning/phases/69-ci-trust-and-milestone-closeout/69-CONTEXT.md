# Phase 69: CI Trust And Milestone Closeout - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **CI-03** and **v2.6 milestone traceability** without changing canonical closeout order or adding new CI enforcement gates. Phase 68 already wired policy + test jobs and full-suite WAE; Phase 69 makes maintainer/adopter **trust** explicit: documented CI topology, requirements prose aligned with executable truth, optional ratchet maintainer hygiene, and v2.6 audit/archive ceremony.

**In scope:** CI-03 documentation bundle (`operator_verification.md` CI gate map, minimal `ci.yml` comments, README link, contract-test anchor); rewrite **CI-03** requirement text; sync `REQUIREMENTS.md` / `PROJECT.md` / `ROADMAP.md` checkboxes and stale “staged ratchet” language; WR-01/WR-02 ratchet tmp hygiene; `69-VERIFICATION.md`; `v2.6-MILESTONE-AUDIT.md`; thread archive; human confirmation of remote CI green.

**Out of scope:** New CI gates (inventory JSON diff, knowledge WAE in CI, ratchet CI step); Hex publish / README docs-truth (v2.7); installer or runtime capability changes; `/gsd-complete-milestone v2.6` execution (follow Phase 69 plans, then audit/complete as separate workflow steps).

</domain>

<decisions>
## Implementation Decisions

### CI-03 documentation bundle (Gray area 1)

- **D-01:** **“Thin prose map + fat executable contract.”** Executable SSOT: `.github/workflows/ci.yml`, `Scoria.VerificationLanes`, `test/scoria/ci_policy_contract_test.exs`, `test/scoria/verification_lanes_test.exs`. Prose explains topology, intent, local parity, failure diagnosis — never a second authoritative command list.
- **D-02:** **Primary doc surface:** Add `### CI gate map (maintainers)` to `docs/operator_verification.md` (after or integrated with existing WARN-07 section): two-job diagram (`policy` → `test`), intent per stage, local parity (`SCORIA_DB_PORT=55432`, `MIX_ENV=dev` for `release_preview`), explicit ratchet = maintainer-only (not CI).
- **D-03:** **Minimal `ci.yml` comments:** 5–8 line workflow header + one-line intent per job (“policy: fail cheap before Postgres”; “test: canonical closeout from VerificationLanes”).
- **D-04:** **README:** Keep CI badge; add at most two lines linking to operator CI gate map — no gate encyclopedia on landing page.
- **D-05:** **Reject `docs/ci.md`** unless future milestone adds matrix OTP, external secrets, or eval CI jobs.
- **D-06:** **Optional contract anchor:** Extend `ci_policy_contract_test.exs` to assert stable anchor in `operator_verification.md` (e.g. `CI gate map` or `policy` job section) — same pattern as WARN-06 ratchet doc assertions; do not assert full prose bodies.
- **D-07:** **Planning traceability table** in `69-VERIFICATION.md` maps CI-03 → contract test names → workflow jobs (maintainer-facing ledger, not Hex docs).

### REQUIREMENTS / PROJECT language (Gray area 2)

- **D-08:** **Rewrite CI-03 (Option A).** Drop “staged WAE” from CI-03; it trained contributors on the removed ratchet CI bridge. Locked wording:

  > **CI-03**: CI preserves canonical closeout order (`release_preview` → `adoption` → `runtime_to_handoff`) in the Postgres test job, runs a Postgres-free policy job first (baseline expiry, `mix compile --warnings-as-errors`, lane-contract WAE), and enforces full-suite `mix test --warnings-as-errors` after closeout lanes and before `mix test.knowledge`.

- **D-09:** **Sync artifacts in Phase 69:** Mark CI-03 `[x]` in `REQUIREMENTS.md` traceability; mark WARN-03…WARN-07 + CI-03 in `PROJECT.md`; update `ROADMAP.md` Phase 69 goal text to “Document CI trust + close v2.6 traceability” (not “wire staged gates”). Fix stale ROADMAP progress table (phases 66–68 status) before or during milestone archive.
- **D-10:** **Preserve “staged ratchet journey”** only in phase 67–68 artifacts (historical); do not reintroduce staged ratchet as live CI policy.

### Milestone audit depth (Gray area 3)

- **D-11:** **Medium “CI-attested” audit** — not full v2.5 installer integration ceremony, not checkbox-only closeout. Write `.planning/milestones/v2.6-MILESTONE-AUDIT.md` **after** Phase 69 implementation (`69-VERIFICATION.md` passed).
- **D-12:** **Required audit sections:** frontmatter scores; scope (phases 66–69, WARN-03…CI-03); evidence sources; phase VERIFICATION summary; 3-source requirement matrix with FAIL gate on orphans; **CI closeout contract** section (policy→test, step order, pointers to contract tests); Nyquist rollup from 66–69 `*-VALIDATION.md`; tech debt rollup (non-blocking only).
- **D-13:** **Skip `gsd-integration-checker`** — v2.6 is linear with SSOT in contract tests; re-run only if Phase 69 adds new cross-job coupling without contract test updates.
- **D-14:** **Audit-time minimal re-proof:**

  ```bash
  mix scoria.warning_baseline.check
  MIX_ENV=test mix compile --warnings-as-errors
  MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs
  ```

- **D-15:** **Target audit scores:** requirements 6/6; phases 4/4 verified; integration = CI order matches `closeout_order/0` + policy gates precede broad test; flows = baseline → WAE → full suite in CI.

### Optional CI hygiene (Gray area 4)

- **D-16:** **Defer inventory JSON CI diff** to v2.7 backlog or never — redundant with full WAE + empty baseline; conflicts with Phase 68 D-20 (JSON = measurement, not enforcement).
- **D-17:** **Defer `mix test.knowledge --warnings-as-errors` in CI** to v2.7 — optional lane; document maintainer command in operator CI section; add CI WAE only if knowledge lane regresses under WAE.
- **D-18:** **Include WR-01 + WR-02 in Phase 69** (plan `69-01` or tasks in `69-00`): `warning_ratchet.test` mirrors `check` tmp hygiene (`ensure_clean_tmp!` + `after` cleanup); restore meaningful integration coverage for ratchet→inventory chain (subprocess or targeted unit test — avoid brittle `ExUnit.Server` hacks).
- **D-19:** **Human verification:** `69-VERIFICATION.md` records confirmation of remote GitHub Actions green on next push (branch was ahead of origin during Phase 68 verification).

### Milestone ship ceremony (Gray area 5)

- **D-20:** **Order of operations:** Phase 69 execute → `69-VERIFICATION` passed → sync REQUIREMENTS/PROJECT → `v2.6-MILESTONE-AUDIT.md` → `/gsd-complete-milestone v2.6` → archive warning-ratchet thread → update `MILESTONE-ARC.md` / `RETROSPECTIVE.md` → tag `v2.6` (push tag only if user requests).
- **D-21:** **Do not flip `PROJECT.md` Current Milestone to v2.7** until audit exists and complete-milestone runs — prevents contradictory handoff (v2.7 in PROJECT while STATE still says “Execute Phase 69”).
- **D-22:** **Thread archive:** `.planning/threads/2026-05-27-warning-ratchet-followup.md` → `archived (superseded — shipped v2.6)` with Resolution (phases 66–69, WARN-03…CI-03) and v2.7 follow-up pointer.
- **D-23:** **Full archive package** via complete-milestone: `v2.6-ROADMAP.md`, `v2.6-REQUIREMENTS.md`, `MILESTONES.md` section, optional `milestones/v2.6-phases/{66,67,68,69}/` move (match v2.5 pattern).

### Plan shape / execution waves

- **D-24:** **Three plans, ordered:**

| Plan | Name | Scope |
|------|------|--------|
| **69-00** | `ci-trust-docs` | Operator CI gate map; `ci.yml` comments; README link; contract anchor; CI-03 + PROJECT/ROADMAP/REQUIREMENTS prose sync |
| **69-01** | `ratchet-maintainer-hygiene` | WR-01 tmp symmetry; WR-02 integration test fix |
| **69-02** | `milestone-closeout` | `69-VERIFICATION.md`; `v2.6-MILESTONE-AUDIT.md`; ROADMAP progress table fix; audit/complete-milestone readiness |

- **D-25:** **Serial waves:** 69-00 → 69-01 → 69-02. Audit file written in 69-02 after docs + hygiene land.

### Cross-cutting architecture & DX

- **D-26:** **Adopter least surprise:** CI runs plain lane commands (`mix test.adoption`, etc.); WAE is invisible strictness on full suite — not a renamed adopter command.
- **D-27:** **Maintainer least surprise:** One operator doc explains policy→test topology; ratchet remains local WARN-06 debugger; baseline markdown = policy; inventory JSON = snapshot after `--write`.
- **D-28:** **Eval-platform coherence:** CI = production regression gate; baseline/inventory = policy layer — same loop as Braintrust/Langfuse “baseline → CI gate” without importing eval-vendor CI doc bulk into build CI.
- **D-29:** **Operator-first failure copy** (Field Engineer tone): CI gate map bullets which command failed, what to run next — evidence-based, not “fix your warnings.”
- **D-30:** **Anti-patterns rejected:** new `docs/ci.md` duplication; README gate catalog; CI diff on JSON; knowledge WAE without demonstrated regression; flipping PROJECT to v2.7 before audit; re-adding ratchet CI step.

### Claude's Discretion

- Exact anchor string for contract test vs operator doc section title.
- Whether WR-01/WR-02 land in 69-00 vs dedicated 69-01 (recommend 69-01 if 69-00 is docs-only).
- Whether `gsd-complete-milestone v2.6` runs in same session as 69-02 or as explicit user follow-up after audit review.
- Optional phase directory move to `milestones/v2.6-phases/`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### CI-03 and milestone scope
- `.planning/REQUIREMENTS.md` — CI-03 definition; WARN-03…WARN-07 traceability
- `.planning/ROADMAP.md` — Phase 69 success criteria; v2.6 non-goals
- `.planning/PROJECT.md` — milestone goals; checkbox sync targets
- `.planning/STATE.md` — Phase 68 evidence; operator next steps
- `.planning/milestones/v2.5-MILESTONE-AUDIT.md` — audit template and ceremony pattern

### Phase 66–68 decisions and verification
- `.planning/phases/68-full-suite-warning-closure/68-CONTEXT.md` — CI staging decisions; D-20 Phase 69 docs deferral
- `.planning/phases/68-full-suite-warning-closure/68-VERIFICATION.md` — WARN-07 evidence; human CI confirmation gap
- `.planning/phases/67-high-signal-warning-ratchet/67-CONTEXT.md` — policy vs test job split
- `.planning/phases/66-baseline-expiry-and-inventory/66-CONTEXT.md` — baseline parser rules
- `.planning/threads/2026-05-27-warning-ratchet-followup.md` — execution scope; archive target

### Code SSOT
- `.github/workflows/ci.yml` — policy + test jobs
- `lib/scoria/verification_lanes.ex` — closeout order, `ci_command/1`
- `test/scoria/ci_policy_contract_test.exs` — gate order contracts
- `test/scoria/verification_lanes_test.exs` — lane contract
- `docs/operator_verification.md` — adopter/maintainer lanes; WARN-05–07
- `lib/mix/tasks/scoria.warning_ratchet.{test,check}.ex` — WR-01/WR-02 targets
- `lib/mix/tasks/scoria.warning_baseline.check.ex` — policy job meta-gate

### Product and engineering DNA
- `prompts/sztheory-elixir-dna.md` — operator-first DX, robust CI
- `prompts/phoenix-ai-lib-deep-research.md` §3 — trace → eval → baseline → CI gate loop
- `prompts/scoria-gsd-kickoff.md` — eval workbench + CI regression gates vision
- `prompts/scoria-brand-book-deep-research.md` — Field Engineer remediation tone

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.CiPolicyContractTest` — extend with operator-doc anchor assertion
- `Scoria.VerificationLanes` — SSOT for closeout commands and order
- `docs/operator_verification.md` — WARN-07 CI section exists; extend with gate map
- Phase 68 shipped `ci.yml` — no structural CI change expected unless audit finds drift

### Established Patterns
- Policy (no Postgres) vs test (Postgres + closeout) job split (Phase 66–68)
- Contract tests enforce YAML order; prose explains why
- Milestone audit → complete-milestone → thread archive (v2.5 precedent)
- REQUIREMENTS checkbox sync on phase/milestone closeout

### Integration Points
- `docs/operator_verification.md` — primary maintainer CI narrative
- `.planning/REQUIREMENTS.md` / `PROJECT.md` / `ROADMAP.md` — CI-03 traceability
- `.planning/milestones/v2.6-MILESTONE-AUDIT.md` — new artifact
- `.planning/threads/2026-05-27-warning-ratchet-followup.md` — archive on v2.6 ship

### Shipped CI topology (2026-05-27)
- **policy:** `warning_baseline.check` → `compile --warnings-as-errors` → lane-contract WAE
- **test:** `release_preview` (dev) → ecto → `test.adoption` → `test.runtime_to_handoff` → `mix test --warnings-as-errors` → `mix test.knowledge`
- Ratchet **not** in CI; full WAE is production gate

</code_context>

<specifics>
## Specific Ideas

- **User directive:** Research all five gray areas with subagents; deliver one coherent recommendation set without requiring further product decisions — captured above as locked D-01…D-30.
- **Phase 69 title:** “CI trust documentation + maintainer ratchet hygiene” — not “more CI gates.”
- **Braintrust/Langfuse lesson:** Separate build-trust CI from eval-product CI; Scoria CI-03 documents lane/WAE trust only.
- **Rust nextest lesson:** Machine-readable SSOT + short prose for caveats (dev MIX_ENV, pgvector port, policy job has no DB).
- **No premature v2.7 narrative:** Hex/README truth stays queued; ceremony closes warning ratchet only.

</specifics>

<deferred>
## Deferred Ideas

### v2.7 backlog
- CI diff on `warning-inventory.baseline.json` (`clusters: {}` guard)
- `mix test.knowledge --warnings-as-errors` in CI (document maintainer command in Phase 69)
- Hex publish + README/docs-truth (`adoption_surface_test` alignment)
- Adoption discoverability drift (`test.adoption_test.exs` vs `adoption_test_files/0`) — v2.5 audit carryover if still open
- 68-REVIEW IN-01–IN-03 (pgvector stub note, path cache polish)

### Reviewed todos (not folded)
- None — `todo.match-phase` returned no matches for Phase 69.

</deferred>

---

*Phase: 69-ci-trust-and-milestone-closeout*
*Context gathered: 2026-05-27*
