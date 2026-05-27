# Scoria v2.3 Runtime-to-handoff adoption example Roadmap

**Status:** Active
**Started:** 2026-05-27
**Latest shipped milestone:** `v2.2 OSS adopter onramp` on 2026-05-26
**Historical roadmap:** `.planning/milestones/v2.2-ROADMAP.md`
**Historical requirements:** `.planning/milestones/v2.2-REQUIREMENTS.md`
**Goal:** Give Phoenix adopters one executable, support-truthful path from a default Scoria run into a bounded handoff with inspectable projected context and operator evidence.

## Phases

- [x] **Phase 52: Runtime-to-handoff example contract** - Define and build the narrow adopter-facing path from `Scoria.start_run/2` into `Scoria.start_handoff_run/3`. (completed 2026-05-27)
- [x] **Phase 53: Operator evidence and lane guidance** - Make the delegated lineage and projected-context evidence easy to inspect and explain when adopters should escalate lanes. (completed 2026-05-27)
- [ ] **Phase 54: Executable proof and closeout truth** - Back the example with a bounded proof lane and align support surfaces to the verified command.

## Phase Details

### Phase 52: Runtime-to-handoff example contract

**Goal**: Define and build the narrow adopter-facing path from `Scoria.start_run/2` into `Scoria.start_handoff_run/3`.
**Depends on**: None
**Requirements**: EXMP-01, EXMP-02
**Success Criteria**:

  1. The example starts from the default runtime lane and uses existing public APIs unless a blocking gap is discovered.
  2. The example shows how and why the host app escalates to a bounded delegated run.
  3. Projected context is presented as a bounded, safe-by-default handoff payload rather than hidden runtime state.
  4. Rejected or excluded projected-context inputs are documented or demonstrated with truthful behavior.

**Plans**: 3 plans

- [x] `52-01-PLAN.md` — Inspect current runtime, handoff, docs, and test-support seams to choose the smallest adopter-facing example shape.
- [x] `52-02-PLAN.md` — Implement the runtime-to-handoff example path using the existing public runtime facade.
- [x] `52-03-PLAN.md` — Document projected-context safety, rejection behavior, and the host-app ownership boundary for the example.

### Phase 53: Operator evidence and lane guidance

**Goal**: Make the delegated lineage and projected-context evidence easy to inspect and explain when adopters should escalate lanes.
**Depends on**: Phase 52
**Requirements**: EVID-01, DOCS-01
**Success Criteria**:

  1. Operator-facing surfaces expose the default run, delegated lineage, projected-context summary, and delegated outcome for the example path.
  2. The adoption docs explain the decision point between staying on the default runtime lane and escalating into bounded handoff.
  3. The example avoids implying that bounded handoff is required for first adoption.
  4. Support wording remains consistent with the `v2.2` lane hierarchy.

**Plans**: 3 plans

- [ ] `53-01-PLAN.md` — Verify and, if needed, tighten operator evidence projection for the runtime-to-handoff example.
- [ ] `53-02-PLAN.md` — Align README, operator verification, and adopter-guide wording around the default-to-handoff decision point.
- [ ] `53-03-PLAN.md` — Add source or docs drift checks that keep the example lane wording consistent with runtime truth.

### Phase 54: Executable proof and closeout truth

**Goal**: Back the example with a bounded proof lane and align support surfaces to the verified command.
**Depends on**: Phase 53
**Requirements**: DOCS-02, PROOF-01, PROOF-02
**Success Criteria**:

  1. A bounded test or Mix task proves the runtime-to-handoff example end to end.
  2. The proof lane verifies optional semantic fast-path, knowledge, retrieval, and hosted onboarding setup are not hidden prerequisites.
  3. README, operator verification, and any example docs name the same canonical command for the runtime-to-handoff path.
  4. Milestone closeout re-runs the existing package/adoption proof chain or records why a narrower chain is sufficient.

**Plans**: 3 plans

- [ ] `54-01-PLAN.md` — Add the bounded executable proof lane for the runtime-to-handoff example.
- [ ] `54-02-PLAN.md` — Align public support surfaces to the new proof command and prerequisite boundaries.
- [ ] `54-03-PLAN.md` — Run closeout verification and write the milestone verification ledger.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 52. Runtime-to-handoff example contract | 3/3 | Complete    | 2026-05-27 |
| 53. Operator evidence and lane guidance | 3/3 | Complete    | 2026-05-27 |
| 54. Executable proof and closeout truth | 0/3 | Blocked on Phase 53 | — |

## Milestone Notes

### Key Decisions

- `v2.3` activates the adoption-example candidate from `.planning/MILESTONE-ARC.md`.
- The milestone is scoped to one runtime-to-handoff path, not a broad example catalog.
- Existing public APIs remain the intended surface unless planning discovers a real blocker.
- The example must be executable truth; docs-only proof is insufficient for closeout.

### Explicit Non-Goals

- Hosted onboarding, package-family decomposition, external semantic cache backends, and advanced ANN tuning remain deferred.
- Optional knowledge and semantic setup must not become prerequisites for the runtime-to-handoff proof.
