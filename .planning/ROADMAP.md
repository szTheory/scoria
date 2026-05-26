# Scoria v2.2 OSS adopter onramp Roadmap

**Status:** planned 2026-05-25
**Latest shipped milestone:** `v2.1 Tenant-scoped semantic fast path` on 2026-05-25
**Historical roadmap:** `.planning/milestones/v2.1-ROADMAP.md`
**Historical requirements:** `.planning/milestones/v2.1-REQUIREMENTS.md`
**Current milestone:** `v2.2 OSS adopter onramp`

## Phases

- [x] **Phase 47: Release packaging and docs truth** - Make the package surface publishable and locally provable before the first public Hex release.
- [x] **Phase 48: Host-app install contract and consumer proof** - Prove that a fresh Phoenix app can adopt the default lane through the public install and runtime path.
- [ ] **Phase 49: Support truth and adoption closeout** - Align docs, task output, and verification lanes to the shipped adoption order and close the milestone with bounded proof.
- [ ] **Phase 50: Release-preview CI truth and Phase 47 verification** - Restore a truthful CI-safe release-preview lane and close the missing Phase 47 verification gap.
- [ ] **Phase 51: Default-lane verifier hardening and support-truth re-closeout** - Make the canonical adoption verifier bounded and green again, then re-close Phase 49 with executable proof.

## Phase Details

### Phase 47: Release packaging and docs truth
**Goal**: Make the package surface publishable and locally provable before the first public Hex release.
**Depends on**: None
**Requirements**: ADPT-03, ADPT-04
**Success Criteria**:
  1. Maintainers can run `mix docs` successfully from repo state using the real publish-facing docs configuration.
  2. Hex metadata, source links, and docs extras align to the public package story Scoria intends to ship.
  3. Maintainers can preview the packaged artifact locally and verify required runtime code, migrations, README, and adoption guides are included.
  4. A bounded release-preview lane fails fast when docs build or package-inventory truth drifts.
**Plans**: 3 plans
- [x] `47-01-PLAN.md` — Add the real docs-build dependency and close any docs configuration drift blocking `mix docs`.
- [x] `47-02-PLAN.md` — Define and verify the package inventory Scoria must ship for the first public Hex release.
- [x] `47-03-PLAN.md` — Add a bounded release-preview verification lane covering docs build and package truth.

### Phase 48: Host-app install contract and consumer proof
**Goal**: Prove that a fresh Phoenix app can adopt the default lane through the public install and runtime path.
**Depends on**: Phase 47
**Requirements**: INST-01, INST-02, PROOF-01, PROOF-02
**Success Criteria**:
  1. `mix scoria.install` mounts the dashboard, copies core migrations, and injects defaults without duplicate or misleading mutations.
  2. The default lane remains installable when Tailwind or optional knowledge surfaces are absent, and skipped steps are explicit.
  3. A fresh Phoenix consumer app or equivalent host-app harness can prove dependency fetch, install, migrate, and `/scoria` route visibility.
  4. That same consumer proof can start one durable run, read it back through the public runtime facade, and inspect operator evidence without enabling optional lanes.
**Plans**: 4 plans
- [ ] `48-01-PLAN.md` — Harden and verify the installer contract against fresh-host mutations and idempotency expectations.
- [ ] `48-02-PLAN.md` — Build the canonical consumer-app fixture or equivalent host-app harness for dependency, install, migrate, and route proof.
- [ ] `48-03-PLAN.md` — Extend the consumer proof through `Scoria.start_run/2`, readback, and operator evidence inspection on the default lane.
- [ ] `48-04-PLAN.md` — Add bounded verification coverage proving optional knowledge and semantic surfaces are not hidden prerequisites for the default lane.

### Phase 49: Support truth and adoption closeout
**Goal**: Align docs, task output, and verification lanes to the shipped adoption order and close the milestone with bounded proof.
**Depends on**: Phase 48
**Requirements**: DOCS-01, DOCS-02
**Success Criteria**:
  1. README, operator verification, and installer output use the same lane ordering and prerequisite vocabulary.
  2. Each lane names one canonical verification command and explicitly states when a user is leaving the default adoption path.
  3. Missing optional prerequisites produce truthful denial or fallback guidance instead of silent failure or vague maintainer lore.
  4. The milestone closes on a bounded proof chain that points support questions at real green lanes.
**Plans**: 3 plans
- [ ] `49-01-PLAN.md` — Reconcile README, verification guides, and installer messaging around one default-lane adoption order.
- [ ] `49-02-PLAN.md` — Tighten lane-specific denial and fallback wording for bounded handoff, semantic fast path, and optional knowledge surfaces.
- [ ] `49-03-PLAN.md` — Finalize milestone closeout verification and support-truth checks around the shipped adoption story.

### Phase 50: Release-preview CI truth and Phase 47 verification
**Goal**: Restore a truthful CI-safe release-preview lane and close the missing Phase 47 verification gap.
**Depends on**: Phase 49
**Requirements**: ADPT-03, ADPT-04
**Gap Closure**: Closes v2.2 audit gaps for the broken `MIX_ENV=test mix scoria.release_preview` chain and missing Phase 47 verification evidence.
**Success Criteria**:
  1. `MIX_ENV=test mix scoria.release_preview` is either fully supported and green or the canonical closeout command is re-scoped so it no longer depends on dev-only tooling.
  2. The package/docs truth lane fails for real regressions instead of environment wiring drift.
  3. `47-VERIFICATION.md` exists and shows bounded proof for ADPT-03 and ADPT-04 in the corrected closeout lane.
  4. Milestone bookkeeping reflects the repaired verification state instead of stale summary-only completion.
**Plans**: 3 plans
- [ ] `50-01-PLAN.md` — Re-scope the release-preview CI step to the supported env and lock the maintainer command contract.
- [ ] `50-02-PLAN.md` — Re-run the bounded package/docs proofs and write `47-VERIFICATION.md`.
- [ ] `50-03-PLAN.md` — Repair requirements and roadmap bookkeeping for the now-verified packaging/docs phase.

### Phase 51: Default-lane verifier hardening and support-truth re-closeout
**Goal**: Make the canonical adoption verifier bounded and green again, then re-close Phase 49 with executable proof.
**Depends on**: Phase 50
**Requirements**: DOCS-01, DOCS-02
**Gap Closure**: Closes v2.2 audit gaps for the timed-out `MIX_ENV=test mix test.adoption` chain, support-truth drift, and missing Phase 49 verification evidence.
**Success Criteria**:
  1. The canonical default-lane verifier completes within its published timeout budget in the repo's supported test environment.
  2. Generated-host proof coverage remains functionally intact inside the advertised adoption command, not only in isolated runs.
  3. README, installer output, and verification guides name the same canonical commands and prerequisite boundaries after the verifier is stabilized.
  4. `49-VERIFICATION.md` exists and closes DOCS-01 and DOCS-02 with executable proof.
**Plans**: 0 plans

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 47. Release packaging and docs truth | 3/3 | Complete | 2026-05-25 |
| 48. Host-app install contract and consumer proof | 4/4 | Complete | 2026-05-25 |
| 49. Support truth and adoption closeout | 0/3 | Pending | — |
| 50. Release-preview CI truth and Phase 47 verification | 2/3 | In Progress | — |
| 51. Default-lane verifier hardening and support-truth re-closeout | 0/0 | Pending | — |

## Milestone Summary

### Key Decisions

- `v2.2` prioritizes OSS adopter readiness over adjacent capability expansion.
- Package metadata, docs buildability, install behavior, and consumer proof are treated as product surface, not release afterthoughts.
- The default Phoenix runtime lane stays the canonical adoption path; semantic fast path, bounded handoffs, and optional knowledge remain additive lanes with explicit prerequisites.
- Publish and release-preview concerns stay inside Mix-task, CI, and test-support seams rather than leaking into runtime behavior.

### Issues To Resolve

- The installer contract is closer to truthful, but Scoria still needs fresh-host consumer proof instead of only repo-internal confidence.
- Docs, verification guides, and task output must converge on one lane-based support story before the first public Hex release.
- The release-preview closeout lane must become CI-safe and re-establish Phase 47 verification instead of relying on summary-only completion.
- The canonical adoption verifier must be bounded enough to stay green in the default test lane before support-truth can be archived.

### Deferred Work

- Advanced bounded-handoff example expansion unless support evidence proves it is needed.
- Package-family decomposition into multiple Hex libraries.
- External semantic cache backends and ANN tuning controls.
