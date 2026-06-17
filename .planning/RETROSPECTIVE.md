# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v3.1 — CI/CD Velocity

**Shipped:** 2026-06-17
**Phases:** 6 (23–28) | **Plans:** 9 | **Tasks:** 13

### What Was Built
An infra/docs-only CI overhaul (SEED-003) that cut PR CI critical path from ~77 min (one serial `verify / test` job) to **7m38s MEASURED** (run 27709716751) without weakening the merge bar. Sequenced lowest-risk → highest-payoff: build-once artifact job + env-scoped cache keys (23) → knowledge lane `--only knowledge` (24) → serial→parallel lane fan-out behind one `verify-summary` with topology docs in lockstep (25) → 4-way `--partitions 4` sharding (26) → Postgres host-port flake fix + zero-retry policy (27) → `mix ci` DX alias + velocity closeout (28).

### What Worked
- **Contract-first invariants made parallelization safe.** Because `Scoria.VerificationLanes.closeout_order/0` and the byte-order lane tests only asserted YAML order (not serial execution), heavy lanes could fan out without touching the merge bar — the contract suite (51/0) was the safety net at every phase.
- **Derived (not hardcoded) fan-in completeness.** `verify-summary.needs` is checked by a subset-assertion that derives the parallel lane set from the YAML, so a future unwired lane fails CI rather than silently skipping the gate. This is the single highest-leverage guard in the milestone.
- **Sequencing by risk/payoff.** Cache/build-once foundation first, then the biggest single win (knowledge scope), kept each phase's blast radius small and its win measurable.
- **Live measurement, not projection.** VELO-01 was closed against a real green run (27709716751), not an estimate — and the milestone audit could lean on that same run to retire Phase 26's `human_needed` live-shard item.

### What Was Inefficient
- **Documentation lag created a false-gap signal.** Phase 25's requirements (PAR-01/02/03, DX-02) were verified SATISFIED but their REQUIREMENTS.md checkboxes/traceability stayed "Pending," and the ROADMAP left Phases 25 & 26 unchecked — so the milestone *looked* incomplete until the audit reconciled VERIFICATION.md against the trackers. Flip requirement state at phase close, not at milestone close.
- **SUMMARY frontmatter `requirements-completed` was missing on 5 of 9 plans**, which made the `milestone.complete` accomplishment extractor emit `One-liner:` placeholders — the generated MILESTONES entry had to be merged by hand against the pre-written rich entry.

### Patterns Established
- **Parallel CI topology with a single stable fan-in:** `policy → build → { parallel lanes } → verify-summary`, with `ci-gate` depending only on the fan-in so the required-check name (`CI / ci-gate`) stays byte-stable and branch protection never needs editing.
- **Build-once artifact sharing:** one WAE compile under `MIX_ENV=test`, tarred `_build/test`+`deps` uploaded with `if-no-files-found: error`, restored by every downstream lane.
- **Zero-retry-default flake policy:** fix the root cause (ephemeral host-port bind) rather than mask with blanket retries; pin the policy with contract guards.

### Key Lessons
- Reconcile requirement trackers (REQUIREMENTS.md + ROADMAP checkboxes) at *phase* close — a passed VERIFICATION.md is the source of truth, and letting trackers lag manufactures phantom milestone gaps.
- Populate `requirements-completed` in SUMMARY frontmatter every plan, or the milestone-close tooling produces garbage accomplishments.
- For infra milestones, Nyquist `nyquist_compliant: false` across the board is acceptable when the behavioral surface IS the contract test suite — record it as posture in the audit, don't treat it as a blocker.

### Cost Observations
- Model mix: predominantly opus (orchestration + verification-heavy milestone).
- Notable: per-phase VERIFICATION.md discipline (every phase verified during execute) made the milestone audit cheap — it aggregated existing passes + one integration check rather than re-verifying from scratch.

## Milestone: v2.16 — ReqLLM Peer Bump

**Shipped:** 2026-05-30
**Phases:** 4 (08–10 + 10.1 inserted) | **Plans:** 1 formal

### What Was Built
- ReqLLM peer dependency bumped from `~> 1.11` to `~> 1.13` (1.13.0 locked in `mix.lock`).
- Integration verification: orchestrator, judge runner, compaction worker, observe adapter, OrchestratorLive producer path.
- `mix scoria.test.ci_trust` green (43 tests) — no new warning debt from transitive lock updates.
- CHANGELOG `[Unreleased]` entry for peer bump.
- Phase 10.1 retroactive VERIFICATION ledgers — milestone audit re-run to `passed`.

### What Worked
- Minimal scope kept milestone focused — dependency hygiene only, no product expansion.
- Integration test slice (17 tests) gave fast confidence after lockfile update.
- Phase 10.1 decimal closeout pattern (established in v2.15) closed process gate without code changes.

### What Was Inefficient
- Phases 08–10 shipped without GSD execute artifacts; required 10.1 insertion and retroactive ledgers (repeat of v2.15 pattern).
- No dedicated SummarizeWorker unit test — compile + orchestrator path coverage only.

### Patterns Established
- Thin dependency-bump milestones: audit-time test commands as automated gates in retroactive VERIFICATION.
- Decimal phase for process-only closeout when implementation ships ahead of GSD artifacts.

### Key Lessons
1. Run milestone audit before marking complete; retroactive VERIFICATION is cheaper than orphan REQ detection at archive time.
2. Lockfile transitive updates (decimal, jsv, llm_db, plug, telemetry) need CI trust bundle verification, not just compile.
3. Repeat the 10.1 pattern proactively for thin milestones to avoid double closeout passes.

### Cost Observations
- Model mix: not tracked
- Notable: Same-day implementation + process closeout; thin milestone with zero product code in 10.1

---

## Milestone: v2.15 — Connector Adoption Lane

**Shipped:** 2026-05-30
**Phases:** 4 (05–07 + 07.1 inserted) | **Plans:** 1 formal

### What Was Built
- Named `mix test.connector` lane in `VerificationLanes` with advisory exclusion from `closeout_order/0`.
- `Mix.Tasks.Scoria.Test.Connector` bounded four-file test subset with lane contract tests.
- `Scoria.Connectors.AdoptionLaneTest` proving register → fleet → operator drawer via `SupportJourney` fixtures.
- Docs/drift guards pinning connector lane in `adoption_lanes.md`, `connector_adoption.md`, and SSOT tests.
- PR CI WAE: connector lane after knowledge, before advisory gallery.
- Phase 07.1 retroactive VERIFICATION ledgers — milestone audit re-run to `passed`.

### What Worked
- Retroactive validate-phase + inserted 07.1 closed process gate without reopening shipped code.
- Bounded test slice (73 tests) gave fast re-audit confidence after VERIFICATION gap.
- Connector lane followed semantic/knowledge CI posture pattern — predictable adopter story.

### What Was Inefficient
- Phases 05–07 shipped without GSD execute artifacts; required 07.1 insertion and retroactive ledgers.
- Partial milestone close (`84c1f3a`) updated MILESTONES/STATE before archival finished — required full `/gsd-complete-milestone` pass.

### Patterns Established
- Optional escalation lanes: PR WAE after knowledge, explicit exclusion from `closeout_order/0`.
- Integration proof in core repo via `AdoptionLaneTest`; gallery connector journey stays advisory.
- Process gate: all REQ-IDs must appear in phase VERIFICATION frontmatter before milestone close.

### Key Lessons
1. Run milestone audit before partial close; retroactive VERIFICATION is cheaper than orphan REQ detection at archive time.
2. Named connector lane with drift guards prevents embedded-boundary doc drift toward hosted-platform framing.
3. Insert decimal phases for process-only closeout when implementation shipped ahead of GSD artifacts.

### Cost Observations
- Model mix: not tracked
- Notable: Implementation + process closeout same calendar day; 19 commits in ~43 minutes of active work

---

## Milestone: v2.11 — Orchestrator Live Wiring

**Shipped:** 2026-05-30
**Phases:** 2 | **Plans:** 6

### What Was Built
- Tenant-scoped trace delta fan-out from telemetry via `OperatorBroadcast` and `TraceProjection`.
- HITL projection fan-out, hybrid approval modal/inbox UX, incremental trace merge, and per-span LLM token previews on `OrchestratorLive`.
- DB hydrate on reconnect, producer-path integration tests (`Runtime.start_run`, no `send/2`), semantic lane pin.
- Redaction defense-in-depth on delta telemetry and DB hydrate; approve/reject integration proof on producer path.
- Public `Telemetry.emit_span_delta/1` and token coalesce E2E with timer cancel on span complete.

### What Worked
- Milestone audit before close caught trust gaps; Phase 01.1 inserted as hardening slice without new REQ-ID.
- Producer-path integration tests (`Runtime.start_run`) replaced hollow LiveView `send/2` patterns — durable ORCH-LIVE-01 proof.
- Redact → broadcast → buffer ordering preserved across span stop and delta paths (D-118, D-133, D-134).

### What Was Inefficient
- Phase 01.1 shipped without Nyquist VALIDATION.md — discovery-only verification; retroactive `/gsd-validate-phase 01.1` optional.
- Two-phase delivery (01 + 01.1) for one requirement — justified by audit gap closure but added planning overhead.

### Patterns Established
- `OperatorBroadcast` as sole Observe-layer tenant PubSub fan-out module.
- `TraceProjection` never exposes raw attributes — `attributes_preview` capped.
- `emit_span_delta/1` as the only supported delta emit API for adapters and integration tests.
- Integration tests must use producer path; semantic fast-path lane pins orchestrator integration test.

### Key Lessons
1. Run milestone audit before archive; insert decimal phases for hardening rather than shipping with audit gaps.
2. Close HOLLOW_PROP with integration tests on the real producer path, not LiveView test doubles.
3. Defense-in-depth redaction on both live telemetry egress and DB hydrate reconnect paths.

### Cost Observations
- Model mix: not tracked
- Notable: Phase 01 + 01.1 completed same calendar day after v2.10 ship

---

## Milestone: v2.9 — Adoption Journey & Reference Demo

**Shipped:** 2026-05-29
**Phases:** 6 | **Plans:** 3 formal + PR #4 bulk delivery

### What Was Built
- `Scoria.SupportJourney` SSOT with shared identities, seeds, handler contracts, and doc fragments.
- Extended merge-blocking host-proof overlay (resume + handoff smokes).
- `examples/support_copilot/` reference gallery with advisory CI lane `mix scoria.test.support_copilot`.
- Multi-surface adopter doc drift guards and CI ordering contract for gallery-after-knowledge.

### What Worked
- Phased hybrid model: overlay merge-blocking, gallery advisory — preserved v2.4–v2.8 lane contracts.
- Milestone audit → inserted closure phases (77.1, 77.2) closed gaps without reopening shipped code.
- `SupportJourney` as spine prevented identity/fragment drift across overlay, gallery, and docs.

### What Was Inefficient
- Phases 74–77 shipped without planning artifacts; retroactive VERIFICATION ledgers required phase 77.2.
- Large PR #4 mixed feature delivery with planning contract fixes.

### Patterns Established
- `adopter_doc_surfaces/0` maps doc paths to scoped fragment lists for parameterized drift tests.
- Advisory gallery lane ordering asserted via `ci_policy_contract_test` + `VerificationLanes.ci_command/1` SSOT.

### Key Lessons
1. Run milestone audit before archive; insert decimal phases for audit gaps rather than accepting partials.
2. Commit-driven delivery works for feature phases when contract tests are SSOT; still budget retroactive ledgers.
3. Gallery remains outside closeout — local pgvector prerequisite is acceptable for advisory lane.

### Cost Observations
- Model mix: not tracked
- Notable: PR #4 merge + 2 inserted phases (77.1, 77.2) same day as audit re-run

---

## Milestone: v2.8 — CI Hardening & Post-Ship Hygiene

**Shipped:** 2026-05-29
**Phases:** 1 | **Plans:** 0 (commit closeout)

### What Was Built
- Semantic fast-path WAE in PR CI after closeout lanes (SEM-CI-01).
- Knowledge WAE lane (`mix test.knowledge --warnings-as-errors`) in CI (CI-KNOW-01).
- Warning inventory baseline policy gate in CI policy job (CI-INV-01).
- Post-publish smoke workflow checkout fix and operator gate map update.

### What Worked
- Thin commit closeout for a single hygiene phase avoided planning overhead for three well-scoped CI requirements.
- Contract tests (`ci_policy_contract_test`, `verification_lanes_test`, `baseline_check_test`) provided closeout evidence without a formal phase directory.
- Deferring SEM-CI-01/CI-KNOW-01 to v2.8 kept v2.7 focused on Hex publish.

### What Was Inefficient
- No Phase 73 planning directory — evidence scattered across commits and CI contracts.
- Three follow-up test stabilization commits after primary closeout (`6cd6118`, `0e95f52`, `4450cd1`).

### Patterns Established
- Optional lanes (semantic, knowledge) stay after closeout/full WAE — never in `closeout_order/0`.
- Inventory baseline gate belongs in policy job alongside baseline expiry for cheap failure-left.

### Key Lessons
1. Commit-driven closeout works for single-phase CI hygiene when contract tests are the SSOT.
2. Milestone audit before archive catches planning-artifact gaps without blocking functional ship.

### Cost Observations
- Model mix: not tracked in this repo-local closeout
- Notable: 5 commits over ~9 hours including post-closeout test fixes

---

## Milestone: v2.6 — Warning Ratchet

**Shipped:** 2026-05-28
**Phases:** 4 | **Plans:** 15

### What Was Built
- Executable baseline expiry (`mix scoria.warning_baseline.check`) in a Postgres-free CI policy job.
- Classified warning inventory and maintainer ratchet paths before full-suite WAE flip.
- Green full-suite `mix test --warnings-as-errors` with empty baseline ledger.
- CI gate map and contract tests documenting policy→test topology without reordering closeout lanes.

### What Worked
- Staged ratchet (compile → high-signal → full suite) avoided noisy all-at-once CI failures.
- `mix scoria.test.ci_trust` automated Phase 69 verification and reduced ceremony UAT to three handoff checks.
- Policy/test job split shifted cheap failures left before Postgres allocation.

### What Was Inefficient
- Phase 69 Nyquist validation ledger lagged behind VERIFICATION until closeout.
- Remote CI attestation depended on branch protection model while local main was many commits ahead of origin.

### Patterns Established
- Keep CI topology SSOT in contract tests + `Scoria.VerificationLanes`, narrative in operator docs only.
- Use `mix scoria.milestone.archive_thread` for repeatable planning-thread closeout metadata.

### Key Lessons
1. Inventory-first ratchet beats flipping full-suite WAE before cluster attribution exists.
2. Maintainer-only ratchet tasks stay out of CI policy job; full WAE belongs after closeout lanes.

### Cost Observations
- Model mix: not tracked in this repo-local closeout
- Notable: tmp_preflight integration test (~283s) is the long pole for `mix scoria.test.ci_trust`

---

## Milestone: v2.3 — Runtime-to-handoff adoption example

**Shipped:** 2026-05-27
**Phases:** 3 | **Plans:** 9 | **Sessions:** 9

### What Was Built
- One adopter-facing default-run-to-bounded-handoff path using public `Scoria` APIs.
- Curated delegated evidence surfaces and docs that clarify default-lane vs handoff escalation.
- Canonical runtime-to-handoff proof lane (`mix test.runtime_to_handoff`) wired through docs, CI, and closeout ledger.

### What Worked
- Phase summaries and verification ledgers made requirement cross-checking fast at audit time.
- Source-fragment drift tests prevented support wording from diverging from executable behavior.

### What Was Inefficient
- Milestone archival initially preserved stale unchecked plan/requirement checkboxes and required manual cleanup.
- Validation ledgers were left partially stale, forcing a Nyquist debt note at closeout.

### Patterns Established
- Use one canonical verifier command per lane and enforce it across README, guides, tests, and CI.
- Keep host-vs-Scoria ownership language explicit in docs and pin it with source-aware assertions.

### Key Lessons
1. A milestone audit should run before archive commands so contradictions are fixed before records are frozen.
2. Archive automation should normalize shipped checkboxes from traceability truth, not from transient checklist state.

### Cost Observations
- Model mix: not tracked in this repo-local closeout
- Sessions: 9 plan sessions represented in milestone summaries
- Notable: thin, phase-scoped verification commands kept closeout reruns fast and deterministic

---

## Milestone: v2.4 — Adoption Reliability Contract

**Shipped:** 2026-05-27
**Phases:** 4 | **Plans:** 6 | **Sessions:** 6

### What Was Built
- Canonical lane contract source for command/env/prerequisite/exclusion truth across release-preview, adoption, runtime-to-handoff, semantic fast-path, and knowledge lanes.
- Executable docs/support drift guards tied to lane-contract commands and boundary wording.
- Warning-trust baseline closure with docs warnings-as-errors plus owner/expiry debt ledger.
- CI lane-order and warning-gate enforcement before broad suite execution.
- Installer browser-scope hardening for list-form `pipe_through` variants with idempotent behavior preserved.

### What Worked
- Shared lane-contract nouns made docs, tests, and CI updates mechanically consistent.
- Canonical lane commands remained fast to verify through bounded test surfaces.
- Backfilled phase summaries/verification/validation quickly restored audit determinism.

### What Was Inefficient
- Running archive automation before verification backfill created a temporary stale milestone entry.
- Closeout metadata required manual normalization after phase artifacts were reconstructed.

### Patterns Established
- Keep lane contracts source-driven and imported by every drift-sensitive surface.
- Treat warning baseline ownership/expiry as a first-class milestone outcome.
- Archive phase artifacts only after verification tables and requirement checkboxes are reconciled.

### Key Lessons
1. Milestone closeout should enforce "audit pass first, archive second" to avoid stale historical records.
2. Canonical closeout ordering is best guarded in both CI workflow YAML and test assertions.

### Cost Observations
- Model mix: not tracked in this repo-local closeout
- Sessions: 6 plan summaries captured for v2.4
- Notable: bounded lane contracts kept verification time low while still enforcing cross-surface truth

---

## Milestone: v2.5 — Installer Safety & Upgrade Confidence

**Shipped:** 2026-05-27
**Phases:** 7 | **Plans:** 16 | **Sessions:** 16

### What Was Built
- Planner-driven `mix scoria.install --dry-run` and `--check` with deterministic no-write surfaces and stable tri-state exits.
- Manifest-aware drift detection and planner-led apply preflight for managed router/config/migration surfaces.
- `Scoria.Install.Contract` SSOT with mode equivalence, B-cycle idempotency, and operator-ordered summaries.
- Nyquist/traceability closeout (phases 59–63), manifest fingerprint documentation, and adoption discoverability parity.

### What Worked
- Gap-closure phases (62–65) closed audit debt without expanding installer runtime scope.
- Subprocess-backed install tests and `HostInstallFixtures` kept planner/apply proofs deterministic.
- Fixing UAT frontmatter to `status: complete` cleared milestone-close artifact audits immediately.

### What Was Inefficient
- `status: resolved` on UAT files still counted as open gaps until frontmatter matched audit expectations.
- Gap-closure table in REQUIREMENTS lagged phase completion (Phase 64 Pending while shipped).

### Patterns Established
- Treat installer planner artifact as SSOT across dry-run, check, and apply; never merge misleading stored fingerprints at check time.
- Run `audit-open` before milestone close; UAT files must use `status: complete`.

### Key Lessons
1. Milestone-close artifact audits are strict about frontmatter vocabulary — align status tokens with tooling, not human semantics.
2. Installer safety closes host-mutation surprise; warning ratchet (`WARN-03`) is now the highest-leverage follow-up.

### Cost Observations
- Model mix: not tracked in this repo-local closeout
- Sessions: 16 plan summaries captured for v2.5
- Notable: artifact-only closeout phases (62, 65) kept archive prep fast without redundant test runs

---

## Milestone: v3.0 — Control Room

**Shipped:** 2026-06-14
**Phases:** 7 (11–17) | **Plans:** 38 | **Tasks:** 65

### What Was Built
- Committed dev-only `mix scoria.ui.shots` screenshot harness (Playwright state-matrix) + decoupled ReqLLM 9-dimension critique, and an idempotent `dev_seed.exs` exercising all 9 dashboard screens.
- `ui.ex` design-system component layer (table/drawer/modal/field/form_section/notebook/skeleton/toast + semantic flash_group) as the enforced token gateway, with a build-failing DS-06 raw-palette drift guard (verified zero across `lib/scoria_web/`).
- Orientation spine: three-group nav with route-aware active state, Status Home, object-aware breadcrumbs, ⌘K command palette + keyboard shortcuts, cross-screen quality-loop threading, and 5 honest "coming soon" reserved-name stubs.
- Full screen conversion (Phases 14–15): all 13 screen modules on shared components at zero raw-palette leakage; real Dataset Builder `/datasets` index; 13 evidence components as thin notebook adapters.
- Motion + responsive + light/dark WCAG-AA parity (22/22 Playwright parity smoke); final proof: baseline→final rubric delta, raw-color-zero assertion, before/after contact-sheet generator, `docs/MAINTAINERS.md` catalog.

### What Worked
- Sequencing for compounding reuse — primitives (12) before screens, least-iterated (14) before high-traffic (15), motion/parity (16) last before the proof sweep (17) — meant each phase deleted markup the previous one made obsolete.
- The DS-06 ratchet turned "stop the raw-palette leak" from a one-time cleanup into a permanent, build-enforced invariant; the count reaching a verified zero is the milestone's hardest proof point.
- The Phase 11 screenshot+critique loop established the falsifiable bar that every later phase re-ran against — "expose components → delete classes → prove" held end to end.
- Closing `gaps_found` with documented Known Gaps (rather than reopening shipped phases) kept an already-merged UI milestone from stalling on verification ceremony.

### What Was Inefficient
- Phases 13 (IA-01..06) and 14 (SCREEN-01..02) shipped with `VALIDATION.md` but no `VERIFICATION.md` — 8 of the 10 partials are this single missing-artifact pattern, the recurring "implementation ships ahead of GSD verification ledgers" theme from v2.15/v2.16, now in a UI milestone.
- One real one-line portability bug (`review_queue_live.ex:58` hardcoded `/scoria`) slipped past phase verification because there was no verification pass to catch it — only the milestone audit's integration check surfaced it.
- The proof sweep (PROOF-01/02) was constrained by environment: no `ANTHROPIC_API_KEY` for the final LLM re-score (deterministic checklist substituted) and an approvals modal scrim halted the contact-sheet harness at 2/9 paired screens.
- v3.0 was interleaved on the timeline with the v2.17 Vesicle brand interjection, making git-range stats noisy at close.

### Patterns Established
- Build-failing drift guard (DS-06) as the SSOT enforcement mechanism for a design-system invariant — ratchet baseline committed, runs unconditionally in `mix test`.
- "Honest stub" pattern: reserved-name capabilities appear in the IA via a shared `ComingSoonLive` allowlist with future-tense copy and zero fabricated data.
- Thin notebook-shell evidence adapters — one unified shell, many adapters, no duplicated layout logic.
- Accepting documented Known Gaps at milestone close when 0 requirements are functionally unsatisfied and all partials are verification-doc/proof artifacts.

### Key Lessons
1. A build-enforced guard (DS-06) is worth more than a one-time cleanup: it converts a quality win into a property the codebase cannot regress.
2. The recurring missing-`VERIFICATION.md` gap now also bites UI milestones — run `/gsd:verify-work` per phase before close, or the milestone audit's integration check becomes the only verification (and catches real bugs like the hardcoded mount path late).
3. Proof steps that depend on external services (LLM critique) or fragile browser harnesses (modal scrims) need a deterministic fallback designed in — the 11-item resolution checklist was the right call when the API key was absent.

### Cost Observations
- Model mix: not tracked
- Notable: 7 phases / 38 plans / 65 tasks delivered across ~10 calendar days (2026-06-04 → 2026-06-13), interleaved with the v2.17 brand interjection; worktree-based executor merges used in Phase 17.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v3.0 | not tracked | 7 | First large UI/IA/DX milestone; build-failing DS-06 design-system drift guard; closed `gaps_found` with documented Known Gaps (verification-doc partials, 0 unsatisfied) |
| v2.15 | 1 | 4 | Named connector adoption lane with PR CI WAE; 07.1 retroactive VERIFICATION closeout |
| v2.11 | 2 | 2 | Producer-path orchestrator live wiring + 01.1 hardening after audit |
| v2.4 | 6 | 4 | Added canonical lane-contract source and enforced warning/lane-order reliability contracts across docs/tests/CI/installer |
| v2.3 | 9 | 3 | Added canonical runtime-to-handoff proof lane and aligned docs/tests/CI to one support-truth contract |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v3.0 | DS-06 drift guard (raw-palette zero) + 22/22 Playwright light/dark parity smoke + `ui_component_test` | requirement audit 18/28 satisfied, 10 partial (verification-doc/proof), 0 unsatisfied | none |
| v2.5 | adoption lane (77 tests) + installer contract suites + `verification_lanes_test` green at closeout | requirement audit 6/6 (`INST-03`–`INST-08`) | none |
| v2.4 | canonical closeout chain green (`release_preview`, `test.adoption`, `test.runtime_to_handoff`) plus contract suites | requirement audit 10/10 | none |
| v2.3 | `mix test.adoption` + `mix test.runtime_to_handoff` green at closeout | requirement audit 7/7 | none |

### Top Lessons (Verified Across Milestones)

1. Canonical lane naming plus drift tests is the fastest way to keep support truth honest.
2. Closeout is safer when archive artifacts are normalized immediately rather than treated as immutable snapshots.
3. Build-failing drift guards (DS-06 raw-palette) make a quality win permanent — preferred over one-time cleanups.
4. The "implementation ships ahead of VERIFICATION.md" gap recurs across milestone types (v2.15, v2.16, v3.0) — run `/gsd:verify-work` per phase before close, or the milestone audit becomes the only verification pass.

---

## Milestone Next-Step Assessment (2026-05-27)

**Type:** planning / product assessment (not a shipped milestone)

### Findings

- Scoria is **feature-strong** (~84% done for embedded Phoenix AI-ops scope) but **README understates shipped state** (v2.1 anchors enforced by drift tests until v2.7).
- Highest-leverage next work is **maintainer trust** (`WARN-03`), then **adopter friction** (Hex + docs-truth), not new runtime families.
- Planning artifacts had drift (`MILESTONE-ARC` through v2.2, stale installer thread); reconciled in this pass.

### Confirmed Sequencing

1. **v2.6** Warning Ratchet (`WARN-03`)
2. **v2.7** OSS Release + Docs Truth
3. Optional: semantic CI, connector guide, LiveView teardown hygiene

### Key Lesson

Adoption-trust phase: prove the build is as boring as the lane contracts claim before declaring OSS "done enough."
