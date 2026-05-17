# Phase 16: Re-verify Keystone Identity and Runtime API - Context

**Gathered:** 2026-05-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Backfill the missing verification chain for Keystone identity and public runtime work, then reconcile the milestone planning surface so executed Phase 12 and 13 work no longer appears pending.

This phase is about proving and recording already-shipped behavior. It does not reopen the product-shape decisions from Phases 12 and 13, and it does not pull broader defaults/adoption hardening from Phases 17 and 18 into scope.

</domain>

<decisions>
## Implementation Decisions

### Phase 12 proof bar
- **D-01:** Phase 12 should be treated as unverified until Phase 16 reruns the current-code targeted identity lanes, completes the bounded manual operator-evidence walkthrough, and writes a canonical `12-VERIFICATION.md`.
- **D-02:** The Phase 12 proof bar should be strict but proportional: rerun the Phase 12 identity/propagation lanes plus one downstream Phase 13 runtime smoke lane to prove the public runtime still honors canonical identity.
- **D-03:** `12-VALIDATION.md` must be brought to terminal truth as part of this phase. Pending task rows cannot remain after verification closes.
- **D-04:** The manual-only operator evidence check is required closure evidence, not optional polish. It should be converted into a bounded acceptance script with explicit expected observations.

### Verification artifact placement
- **D-05:** Canonical backfilled proof must live in `.planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md` and `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md`, not only in Phase 16 artifacts.
- **D-06:** Phase 16 may add a small link-first summary of the re-verification pass, but that summary must point back to the canonical phase-local verification files rather than duplicating them as a second source of truth.
- **D-07:** Backfilled verification files must make chronology explicit with current verification date plus clear attribution that the proof was backfilled by Phase 16, preserving the historical audit trail instead of pretending those files existed earlier.

### State reconciliation breadth
- **D-08:** Phase 16 must reconcile every live milestone-state surface that still implies Phase 12 or 13 work is pending, not just `ROADMAP.md` and `REQUIREMENTS.md`.
- **D-09:** Live-state reconciliation includes `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, relevant progress markers, stale validation status/task rows, and bookkeeping notes whose present-tense meaning is now false.
- **D-10:** Historical audit artifacts such as `.planning/v1.4-MILESTONE-AUDIT.md` remain immutable dated snapshots. Phase 16 corrects current truth around them; it does not rewrite them.

### Runtime proof scope for Phase 13
- **D-11:** Phase 13 re-verification should record targeted runtime lanes as the primary acceptance evidence for `IDEN-03`, `RUNT-01`, `RUNT-02`, and `RUNT-03`.
- **D-12:** Phase 13 should also record one fresh full `MIX_ENV=test mix test` closeout pass as secondary regression hygiene, clearly framed as a confidence pass rather than the requirement proof itself.
- **D-13:** `13-VERIFICATION.md` should use a requirement-to-command matrix that maps each requirement to the public runtime seam and the exact test command that proves it.

### GSD shift-left defaults
- **D-14:** Missing `*-VERIFICATION.md` artifacts, stale validation status rows, and orphaned requirement traceability should be treated as workflow defects that GSD prevents by default rather than choices the user must repeatedly weigh in on.
- **D-15:** Backfill/reconciliation phases should default to canonical phase-local verification artifacts plus a small re-verification summary, targeted proof lanes plus one closeout full-suite pass, and explicit separation between live-state docs and historical audit snapshots.
- **D-16:** User interruption should be reserved for genuinely product-shaping decisions. Naming, artifact placement, requirement metadata, and evidence formatting conventions should be shifted left into GSD defaults unless they materially change product shape or milestone scope.

### the agent's Discretion
- Exact wording and frontmatter fields used to mark verification chronology, provided they clearly distinguish current verification truth from historical gap snapshots.
- Exact acceptance-script format for the bounded manual operator-evidence check, provided it is short, reproducible, and produces explicit observations.
- Exact grouping of targeted Phase 12 and Phase 13 verification commands, provided requirement traceability stays direct and the public-runtime contract remains explicit.

</decisions>

<specifics>
## Specific Ideas

- Phase 16 should follow the same core precedent as Phase 11: restore the missing canonical verification artifact in the original phase directory, then reconcile milestone state around it.
- Scoria should keep feeling like a boring, trustworthy Phoenix library: explicit contract tests, durable Ecto truth, operator-visible evidence, and one coherent planning surface.
- The public runtime proof should continue to emphasize `Scoria` as the host-app entrypoint, `run_id` as exact resume truth, and `session_id` as continuity/grouping context only.
- “Shift this preference left within GSD” applies here: artifact placement, verification scaffolding, requirement metadata, and live-state reconciliation should become defaults instead of repeated discussion points.
- Keep append-only history. Old audits should remain useful forensic snapshots, not be scrubbed into present-tense truth.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone intent and live state
- `.planning/PROJECT.md` - Keystone milestone boundary, embedded Phoenix-first product posture, and current product thesis.
- `.planning/REQUIREMENTS.md` - `IDEN-01` through `RUNT-03` requirement ownership and current traceability state.
- `.planning/STATE.md` - current milestone notes, especially the existing bookkeeping reconciliation todo.
- `.planning/ROADMAP.md` - Phase 16 goal and plan breakdown, plus the stale Phase 12/13 progress state this phase must correct.

### Current gap evidence
- `.planning/v1.4-MILESTONE-AUDIT.md` - the authoritative dated snapshot of the missing verification chain and stale milestone-state surfaces.
- `.planning/phases/12-canonical-runtime-identity/12-VALIDATION.md` - Phase 12’s unresolved pending task rows and manual-only operator evidence gap.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md` - Phase 13’s validation contract and current green task rows.

### Prior phase decisions and shipped proof
- `.planning/phases/12-canonical-runtime-identity/12-CONTEXT.md` - locked identity decisions that Phase 16 must verify rather than reopen.
- `.planning/phases/12-canonical-runtime-identity/12-RESEARCH.md` - Phase 12’s intended proof seams and anti-patterns.
- `.planning/phases/12-canonical-runtime-identity/12-01-SUMMARY.md` - canonical identity envelope and run-root persistence outcomes.
- `.planning/phases/12-canonical-runtime-identity/12-02-SUMMARY.md` - approval/runtime/MCP identity propagation outcomes.
- `.planning/phases/12-canonical-runtime-identity/12-03-SUMMARY.md` - telemetry and audit identity alignment outcomes.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md` - locked public runtime and session-lifecycle decisions.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-RESEARCH.md` - Phase 13 public-runtime proof strategy and seam definitions.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-01-SUMMARY.md` - `Scoria` facade outcome.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-02-SUMMARY.md` - explicit start/resume contract outcome.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-03-SUMMARY.md` - curated run summary/detail projection outcome.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-04-SUMMARY.md` - end-to-end public runtime continuity and operator-alignment outcome.

### Precedent for re-verification shape
- `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-CONTEXT.md` - prior decision that missing canonical verification should be written back into the original phase directory.
- `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-01-SUMMARY.md` - executed precedent for backfilling a canonical verification artifact.
- `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-02-SUMMARY.md` - executed precedent for reconciling all disagreeing live milestone-state surfaces.
- `.planning/phases/07-seismograph/07-VERIFICATION.md` - concrete example of the desired canonical verification artifact shape.

### Product and ecosystem guidance
- `prompts/scoria-gsd-kickoff.md` - Scoria’s runtime, governance, and operator-grade product vision.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops product-shape lessons, especially trace-first evidence and boring observability defaults.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, operator-first, Ecto-native architectural rules.
- `prompts/scoria-brand-book-deep-research.md` - evidence-first, operator-grade tone that Phase 16 verification artifacts should preserve.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/phases/07-seismograph/07-VERIFICATION.md`: the best local model for a canonical verification file with requirement coverage, exact commands, and evidence-chain notes.
- `.planning/phases/12-canonical-runtime-identity/12-VALIDATION.md`: already defines the intended identity proof commands and the one manual check that needs bounded closure rather than reinvention.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md`: already defines the targeted runtime lanes and provides the correct matrix shape for `RUNT-*` closure.
- `.planning/phases/12-canonical-runtime-identity/*-SUMMARY.md` and `.planning/phases/13-public-runtime-api-and-session-lifecycle/*-SUMMARY.md`: already capture shipped outcomes that verification should map to, avoiding guesswork.

### Established Patterns
- Scoria treats phase-local verification artifacts as canonical truth, while later phases summarize and reconcile around them.
- The repo already favors explicit durable truth over inferred prose: requirements, validation, and summaries all exist as separate layers and should be reconciled rather than collapsed.
- Historical audits remain useful snapshots and should not be rewritten into present-tense status docs.
- Verification should be seam-specific first, then supported by a broader green suite as secondary confidence.

### Integration Points
- Create and populate `.planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md`.
- Create and populate `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md`.
- Update `.planning/phases/12-canonical-runtime-identity/12-VALIDATION.md` so task rows and manual-check status reflect terminal truth.
- Reconcile `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md` to the new canonical verification artifacts.
- If Phase 16 emits its own summary or verification note, keep it link-first and chronology-aware rather than duplicative.

</code_context>

<deferred>
## Deferred Ideas

- Pulling Phase 17 defaults/adoption re-verification work into Phase 16.
- Pulling Phase 18 executable docs/operator harness guards into Phase 16 as a blocking requirement.
- Broad archival rewriting of historical milestone audits or older notes to erase the fact that verification drift existed.
- Any reopening of the product-shape decisions from Phases 12 and 13; those are already locked and only need proof plus state reconciliation here.

</deferred>

---

*Phase: 16-re-verify-keystone-identity-and-runtime-api*
*Context gathered: 2026-05-16*
