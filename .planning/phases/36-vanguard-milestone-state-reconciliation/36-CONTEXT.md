# Phase 36: Vanguard Milestone-State Reconciliation - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile the live `v1.8 Vanguard` planning and milestone-state surfaces so they reflect the restored verification truth established in Phase 35.

This phase is about truth ownership, status alignment, proof-linking style, and closeout posture across:
- root `.planning/*` status surfaces
- milestone-local `v1.8` roadmap/requirements surfaces
- the restored phase-local verification chain for Phases 30 through 34

It does not re-run the milestone audit, archive the milestone, or rewrite historical audit findings as if they were always current. Those remain follow-on control steps after reconciliation.

</domain>

<decisions>
## Implementation Decisions

### Truth ownership and reconciliation direction
- **D-01:** The canonical proof layer for `v1.8 Vanguard` is the phase-local verification chain in:
  - `.planning/phases/30-oban-infrastructure-and-queue-segregation/30-VERIFICATION.md`
  - `.planning/phases/31-model-routing-and-resiliency-foundation/31-VERIFICATION.md`
  - `.planning/phases/32-multi-model-fallback-orchestration/32-VERIFICATION.md`
  - `.planning/phases/33-distributed-evaluation-fan-out/33-VERIFICATION.md`
  - `.planning/phases/34-real-time-operator-dashboards/34-VERIFICATION.md`
- **D-02:** The milestone-local `v1.8` artifacts:
  - `.planning/milestones/v1.8-ROADMAP.md`
  - `.planning/milestones/v1.8-REQUIREMENTS.md`
  should become the canonical milestone fact surface for `v1.8` once reconciled.
- **D-03:** Root planning/status files are reconciled projections of that verified truth, not an independent authority:
  - `.planning/ROADMAP.md`
  - `.planning/REQUIREMENTS.md`
  - `.planning/STATE.md`
  - `.planning/PROJECT.md`
  - `.planning/MILESTONES.md`
  - `.planning/MILESTONE-ARC.md`
- **D-04:** Historical audits remain immutable dated snapshots. Phase 36 must supersede stale status with fresh truth, not rewrite `.planning/v1.8-MILESTONE-AUDIT.md` as if its `gaps_found` result never happened.

### Closeout posture
- **D-05:** After reconciliation, `v1.8 Vanguard` should be marked `ready to close`, not already `shipped` or archived.
- **D-06:** The least-surprise control sequence is:
  - implementation and verification restored
  - milestone-state reconciled
  - fresh milestone audit run
  - milestone archived/completed
- **D-07:** The next explicit gate after Phase 36 should be a fresh `$gsd-audit-milestone v1.8`; only after that passes should `$gsd-complete-milestone v1.8` flip the milestone into shipped/archived state.

### Historical correction style
- **D-08:** Live milestone/state docs should read as current truth first, not as long forensic timelines.
- **D-09:** Reconciled live docs should include a terse dated supersession note that the surfaces were aligned after Phase 35 restored the canonical verification chain on 2026-05-21.
- **D-10:** Detailed chronology, gap narratives, and exact backfill provenance belong in the immutable audit, Phase 35 summaries, and phase-local verification artifacts rather than repeated throughout every top-level status document.
- **D-11:** Phase 36 should avoid both extremes:
  - no false timelessness that erases the reconciliation event
  - no over-historical noise that makes active status docs read like incident reports

### Proof reference style
- **D-12:** Top-level milestone/state docs should summarize current truth and include light canonical pointers to proof artifacts, but should not inline exact proof commands or duplicate verification-lane detail.
- **D-13:** Detailed proof density belongs only in:
  - `*-VERIFICATION.md`
  - `*-VALIDATION.md`
  - milestone audit / closeout artifacts
- **D-14:** The right top-level reference density is:
  - requirement/phase closure status
  - pointer to the canonical verification artifact
  - minimal wording needed for operator/developer confidence
  - no embedded command transcripts in normal status docs

### Ecosystem and architecture posture
- **D-15:** The reconciliation model should follow Scoria’s broader Phoenix/Ecto posture:
  - durable facts live closest to the domain seam that proves them
  - higher-level surfaces project and summarize those facts
  - UI/status readability should not compete with evidence ownership
- **D-16:** Strong external analogs for this choice are:
  - Phoenix contexts owning domain truth while web/UI layers project it
  - Kubernetes-style reconciliation from a canonical source into visible state
  - release-note and release-evidence separation in mature engineering ecosystems
- **D-17:** The main footguns to avoid are:
  - root status docs claiming stronger truth than phase-local proof
  - duplicated proof commands drifting across multiple docs
  - shipped/completed language before a fresh closeout audit exists
  - historical audit findings being silently overwritten rather than superseded

### Shift-left preference for GSD
- **D-18:** This preference should be shifted left into future GSD closeout/reconciliation assumptions:
  - verify in the original phase directory
  - treat milestone-local docs as the milestone truth surface
  - treat root docs as reconciled projections
  - preserve audits as immutable historical snapshots
  - use `closure-ready` as the post-reconciliation posture before archival
  - use light proof pointers in top-level docs and keep exact proof lanes phase-local
- **D-19:** Human interruption should stay reserved for materially impactful exceptions:
  - changing which layer is canonical
  - skipping the closure-ready state and marking a milestone shipped directly
  - broadening proof duplication into root docs
  - rewriting historical audit artifacts
- **D-20:** Phase 36 itself should not broaden into editing global GSD workflow/tooling code unless that work is explicitly added later; for this phase, the shift-left preference is a locked planning assumption and documentation standard.

### the agent's Discretion
- Exact wording of supersession notes, provided they stay short, dated, and link to immutable audit/backfill artifacts.
- Exact placement of proof pointers in root and milestone-local docs, provided they point to canonical verification artifacts without duplicating detailed proof lanes.
- Exact status vocabulary inside each file, provided the milestone ends this phase as `ready to close` rather than already archived/shipped.

</decisions>

<specifics>
## Specific Ideas

- The coherent Phase 36 shape is:
  - phase-local verification remains canonical
  - milestone-local `v1.8` docs become the milestone fact layer
  - root planning docs are synced projections
  - top-level docs stay easy to scan
  - exact proof stays one click away in canonical verification files
  - the repo says `ready to close`, then proves that with a fresh audit before archival
- Strong lessons from adjacent systems and successful engineering practice:
  - durable evidence should live where the behavior is proven, not in mutable headline docs
  - release/status summaries should be readable and link down to proof, not duplicate it
  - “feature complete” and “release/closeout complete” are different states and should stay different
- The right operator/DX outcome is:
  - newcomers can understand current milestone truth quickly
  - maintainers can trace every claim back to canonical proof
  - audits remain credible because historical gap snapshots are preserved
  - future reconciliation phases can follow one boring, repeatable pattern

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 36 scope and current drift
- `.planning/ROADMAP.md` - current root roadmap drift and Phase 36 goal statement.
- `.planning/REQUIREMENTS.md` - current root requirement status drift.
- `.planning/STATE.md` - stale active-phase/milestone state that Phase 36 must reconcile.
- `.planning/PROJECT.md` - current milestone framing and product-shape constraints.
- `.planning/MILESTONES.md` - milestone ledger that must align to reconciled truth.
- `.planning/MILESTONE-ARC.md` - strategic milestone ledger and current stale active-milestone framing.
- `.planning/milestones/v1.8-ROADMAP.md` - milestone-local Vanguard roadmap truth surface to reconcile.
- `.planning/milestones/v1.8-REQUIREMENTS.md` - milestone-local Vanguard requirement truth surface to reconcile.
- `.planning/v1.8-MILESTONE-AUDIT.md` - immutable historical gap snapshot identifying the drift and the missing proof chain as of 2026-05-21.

### Prior Scoria precedent
- `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-CONTEXT.md` - prior rule that missing verification is restored in the original phase directory and milestone state is then aligned without rewriting the historical audit.
- `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-02-SUMMARY.md` - prior shipped-state reconciliation precedent.
- `.planning/phases/35-vanguard-verification-backfill/35-01-SUMMARY.md` - Phase 30/31 verification backfill precedent.
- `.planning/phases/35-vanguard-verification-backfill/35-02-SUMMARY.md` - Phase 32/33 verification backfill precedent.
- `.planning/phases/35-vanguard-verification-backfill/35-03-SUMMARY.md` - Phase 34 verification backfill precedent and explicit handoff into Phase 36.

### Canonical proof chain for Vanguard
- `.planning/phases/30-oban-infrastructure-and-queue-segregation/30-VERIFICATION.md`
- `.planning/phases/31-model-routing-and-resiliency-foundation/31-VERIFICATION.md`
- `.planning/phases/32-multi-model-fallback-orchestration/32-VERIFICATION.md`
- `.planning/phases/33-distributed-evaluation-fan-out/33-VERIFICATION.md`
- `.planning/phases/34-real-time-operator-dashboards/34-VERIFICATION.md`

### Product and methodology guidance
- `.planning/METHODOLOGY.md` - decisive-defaults lens and interruption policy.
- `prompts/scoria-gsd-kickoff.md` - batteries-included Phoenix AI ops vision.
- `prompts/sztheory-elixir-dna.md` - Ecto-native durable truth and operator-first DX posture.
- `prompts/phoenix-ai-lib-deep-research.md` - embedded Phoenix AI ops/control-plane product lessons.
- `prompts/scoria-brand-book-deep-research.md` - evidence-first, operator-grade, calm control-plane posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The restored `30-VERIFICATION.md` through `34-VERIFICATION.md` files already provide the exact canonical proof artifacts Phase 36 should project upward from.
- The Phase 11 context and summaries already provide a working precedent for milestone-state reconciliation after backfilled verification.
- The milestone-local `v1.8` roadmap and requirements files already provide the right intermediate truth surface between phase-local proof and root planning docs.

### Established Patterns
- Scoria repeatedly prefers durable truth near the domain seam and treats higher-level surfaces as projections over that truth.
- Prior closeout work keeps historical audits immutable and supersedes them with fresh proof rather than mutating them into current truth.
- The repo already distinguishes detailed proof artifacts from summary/status artifacts; Phase 36 should reinforce that separation rather than flatten it.

### Integration Points
- Reconciliation must update all root and milestone-local planning surfaces that currently disagree with the restored Phase 30-34 verification chain.
- Requirement status, phase status, active milestone status, and milestone-arc narrative must all align to one coherent `closure-ready` posture.
- Proof pointers in root/milestone docs should terminate at the canonical phase-local verification artifacts, not at duplicated command lists.

</code_context>

<deferred>
## Deferred Ideas

- Hard-coding these reconciliation defaults into shared GSD workflow/tooling implementations. The preference is locked here, but changing global workflow code is outside Phase 36 unless explicitly added as separate work.
- Any broader redesign of planning artifact taxonomy beyond what is needed to reconcile `v1.8 Vanguard`.

</deferred>

---

*Phase: 36-vanguard-milestone-state-reconciliation*
*Context gathered: 2026-05-21*
