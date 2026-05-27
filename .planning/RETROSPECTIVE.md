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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v2.3 | 9 | 3 | Added canonical runtime-to-handoff proof lane and aligned docs/tests/CI to one support-truth contract |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v2.3 | `mix test.adoption` + `mix test.runtime_to_handoff` green at closeout | requirement audit 7/7 | none |

### Top Lessons (Verified Across Milestones)

1. Canonical lane naming plus drift tests is the fastest way to keep support truth honest.
2. Closeout is safer when archive artifacts are normalized immediately rather than treated as immutable snapshots.
