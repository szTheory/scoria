# Requirements: Scoria

**Defined:** 2026-05-29
**Milestone:** v2.10 Hex Consumer Proof & Upgrade Smoke
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## v2.10 Requirements

### Hex consumer proof

- [x] **HEX-CONSUMER-01**: Generated Phoenix host in `mix test.adoption` consumes Scoria via Hex-shaped dependency (`mix hex.build` tarball in PR CI), proving deps.get → install → migrate → route smoke → HOST-01 runtime overlay (approval/resume/evidence) → HOST-02 handoff overlay — without repo-root `path:` dep.
- [x] **HEX-UPGRADE-01**: Same generated host proves upgrade-safe install after version bump: pin published `0.1.0`, baseline overlay smokes + compliant `--check`, bump to current tarball, `--dry-run` / `--check` / apply / migrate, re-run overlay smokes with final compliant `--check`.
- [x] **HEX-REGISTRY-01**: `post-publish-smoke.yml` proves live Hex registry fetch plus install → migrate → overlay subset (release-blocking); documents real semver upgrade path when `0.1.x+1` publishes.

### Docs truth

- [x] **DOCS-HEX-01**: `Scoria.HexConsumerContract` SSOT pins Hex dep snippet and version; README, `docs/operator_verification.md`, and `docs/adoption_lanes.md` align; `adoption_surface_test` and `ci_policy_contract_test` drift-guard tarball consumer proof; `closeout_order/0` unchanged.

## Future Requirements

### Orchestrator live wiring (v2.11)

- **ORCH-LIVE-01**: Runtime→PubSub trace broadcast and HITL modal from real approvals.

### Gallery lane expansion (v2.12)

- **LANE-DEMO-01**: Semantic, knowledge, and connector journeys in demo gallery.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Net-new runtime capability families | v2.10 is adoption proof only; stay requirement-led |
| Widening `closeout_order/0` | Tarball consumer proof stays inside existing `:adoption` lane |
| Gallery/semantic/knowledge in hex proof | Default-lane hex proof only; optional lanes keep existing prerequisites |
| Wallaby/browser CI for hex host | LiveViewTest overlay smokes sufficient (v2.9 precedent) |
| Cross-minor Hex upgrade (`0.1` → `0.2`) | Defer until semver policy requires it |
| Separate advisory `mix scoria.test.hex_consumer` lane | Tarball proof in adoption closeout + registry in post-publish is sufficient |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HEX-CONSUMER-01 | 78, 79 | Complete |
| HEX-UPGRADE-01 | 80 | Complete |
| HEX-REGISTRY-01 | 81 | Complete |
| DOCS-HEX-01 | 78, 82 | Complete |

**Coverage:**
- v2.10 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-29*
*Last updated: 2026-05-30 after Phase 81 closeout*
