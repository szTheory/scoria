# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v2.5 | 16 | 7 | Shipped planner/check no-write contracts, manifest-aware drift-safe apply, and installer contract SSOT with Nyquist closeout |
| v2.4 | 6 | 4 | Added canonical lane-contract source and enforced warning/lane-order reliability contracts across docs/tests/CI/installer |
| v2.3 | 9 | 3 | Added canonical runtime-to-handoff proof lane and aligned docs/tests/CI to one support-truth contract |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v2.5 | adoption lane (77 tests) + installer contract suites + `verification_lanes_test` green at closeout | requirement audit 6/6 (`INST-03`–`INST-08`) | none |
| v2.4 | canonical closeout chain green (`release_preview`, `test.adoption`, `test.runtime_to_handoff`) plus contract suites | requirement audit 10/10 | none |
| v2.3 | `mix test.adoption` + `mix test.runtime_to_handoff` green at closeout | requirement audit 7/7 | none |

### Top Lessons (Verified Across Milestones)

1. Canonical lane naming plus drift tests is the fastest way to keep support truth honest.
2. Closeout is safer when archive artifacts are normalized immediately rather than treated as immutable snapshots.

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
