# Roadmap: Scoria

**Milestone:** v2.10 Hex Consumer Proof & Upgrade Smoke
**Last updated:** 2026-05-29

## Overview

Close the post-Hex publish adopter-trust gap: merge-blocking `mix test.adoption` must prove the **packaged artifact** (tarball), not repo `path:`. Post-publish smoke must prove **live registry** resolution. Docs and drift guards stay aligned via `HexConsumerContract`.

**Requirements:** 4 | **Phases:** 5 (78–82) | **Coverage:** 100%

## Phases

### Phase 78: Hex consumer contract foundation

**Goal:** Introduce `HexConsumerContract` SSOT and parameterize `HostAppProof.Generator` for tarball deps.

**Requirements:** HEX-CONSUMER-01 (partial), DOCS-HEX-01 (partial)

**Success criteria:**
1. `Scoria.HexConsumerContract` exposes version-pinned Hex dep snippet and tarball dep builder used by tests.
2. `HostAppProof.Generator` supports `:hex_tarball` dep mode via `mix hex.build` (no repo-root path default).
3. `host_app_consumer_proof_test` asserts Hex-shaped dep and removes repo-root path assertion.
4. `package_surface_test` tarball version matches `HexConsumerContract` constraint.

**Plans:** TBD via `/gsd-plan-phase 78`

---

### Phase 79: Tarball consumer overlay proof

**Goal:** Merge-blocking adoption lane proves full overlay depth from tarball artifact.

**Requirements:** HEX-CONSUMER-01

**Success criteria:**
1. Generated host runs route + runtime (HOST-01) + handoff (HOST-02) overlay smokes via tarball dep.
2. Proof steps match v2.9 overlay chain inside `mix test.adoption` closeout.
3. `VerificationLanes.closeout_order/0` unchanged; no new closeout lane added.
4. CI timeout and sandbox patterns from v2.9 preserved (no new flake regressions).

**Plans:** TBD via `/gsd-plan-phase 79`

---

### Phase 80: Upgrade smoke in adoption lane

**Goal:** Prove upgrade-safe install from published `0.1.0` baseline to current tarball.

**Requirements:** HEX-UPGRADE-01

**Success criteria:**
1. Generated host installs at pinned `0.1.0` (Hex or frozen tarball), passes baseline overlay smokes and compliant `--check`.
2. Bump to current `mix hex.build` tarball runs `--dry-run` → `--check` → apply → migrate → compliant `--check`.
3. Overlay smokes pass after upgrade without host regeneration.
4. Migration ordering bugs on existing schema are caught (not greenfield-only).

**Plans:** TBD via `/gsd-plan-phase 80`

---

### Phase 81: Post-publish registry gate

**Goal:** Extend release workflow beyond deps.get+compile to full consumer + upgrade truth on live Hex.

**Requirements:** HEX-REGISTRY-01

**Success criteria:**
1. `post-publish-smoke.yml` runs install → migrate → overlay subset against live `{:scoria, "~> 0.1", hex: :scoria}` after index wait.
2. Release workflow is blocking for publish attestation (replaces compile-only smoke).
3. Real semver upgrade step documented for when `0.1.x+1` publishes (FROM previous → TO just-published).
4. Operator gate map updated for v2.10 CI topology.

**Plans:** TBD via `/gsd-plan-phase 81`

---

### Phase 82: Docs truth + milestone closeout

**Goal:** Align adopter docs and drift guards; verify 100% requirement coverage.

**Requirements:** DOCS-HEX-01

**Success criteria:**
1. README Verification section states adoption proves Hex-shaped tarball artifact.
2. `docs/operator_verification.md` documents tarball CI vs registry post-publish smoke and upgrade sequence.
3. `adoption_surface_test` and `ci_policy_contract_test` guard new operator/README anchors.
4. Milestone audit passes; requirements traceability complete; v2.10 archived to `.planning/milestones/`.

**Plans:** TBD via `/gsd-plan-phase 82`

---

## Phase map

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 78 | Hex consumer contract foundation | HEX-CONSUMER-01†, DOCS-HEX-01† | Pending |
| 79 | Tarball consumer overlay proof | HEX-CONSUMER-01 | Pending |
| 80 | Upgrade smoke in adoption lane | HEX-UPGRADE-01 | Pending |
| 81 | Post-publish registry gate | HEX-REGISTRY-01 | Pending |
| 82 | Docs truth + milestone closeout | DOCS-HEX-01 | Pending |

† partial

## Completed milestones

- ✅ **v2.9 Adoption Journey & Reference Demo** — Phases 74–77.2 (shipped 2026-05-29) — `.planning/milestones/v2.9-*`
- ✅ **v2.8 CI Hardening & Post-Ship Hygiene** — Phase 73 — `.planning/milestones/v2.8-*`
- ✅ **v2.7 OSS Release + Docs Truth** — Phases 70–72 — `.planning/milestones/v2.7-*`
- ✅ **v2.6 Warning Ratchet** — Phases 66–69 — `.planning/milestones/v2.6-*`

## Next milestone queue

- **v2.11:** Orchestrator live wiring (ORCH-LIVE-01)
- **v2.12:** Optional lane journeys in gallery (LANE-DEMO-01)
