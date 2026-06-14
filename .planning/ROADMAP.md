# Roadmap: Scoria

**Last updated:** 2026-06-14 (v3.0 Control Room shipped + archived)

## Milestones

- ✅ **v3.0 Control Room** — Phases 11–17 (dashboard design-system / IA / motion / proof) — SHIPPED 2026-06-14 — [archive](milestones/v3.0-ROADMAP.md)
- ✅ **v2.17 Vesicle** — Phases 18–22 (brand system, interjected) — SHIPPED 2026-06-11 — [archive](milestones/v2.17-ROADMAP.md)
- ✅ **v2.16 ReqLLM Peer Bump** — Phases 08–10 + 10.1 (shipped 2026-05-30) — [archive](milestones/v2.16-ROADMAP.md)
- ✅ **v2.15 Connector Adoption Lane** — Phases 05–07 + 07.1 (shipped 2026-05-30) — [archive](milestones/v2.15-ROADMAP.md)
- ✅ **v2.14 Maintenance Release** — `0.1.1` prep (shipped 2026-05-30)
- ✅ **v2.13 Adopter Docs Truth** — MAINTAINERS split, Hex metadata (shipped 2026-05-30)
- ✅ **v2.12 Adoption Confidence & Reference Demo** — Phases 02–04 (shipped 2026-05-30)
- 📋 **v3.1 CI/CD Velocity** — next milestone (SEED-003 CI/CD efficiency overhaul) — planned

## Phases

<details>
<summary>✅ v3.0 Control Room (Phases 11–17) — SHIPPED 2026-06-14</summary>

UI/IA/DX milestone. No net-new backend capability families. Expose components → delete leaked classes → consolidate → orient → polish → prove. Sequenced for compounding reuse: primitives before screens, least-iterated screens before high-traffic, motion/responsive/theme last before the proof sweep.

- [x] Phase 11: Evaluation engine + seed depth (5/5 plans) — completed 2026-06-04
- [x] Phase 12: Design-system component layer (5/5 plans) — completed 2026-06-04
- [x] Phase 13: Orientation spine (IA) (8/8 plans) — completed 2026-06-12
- [x] Phase 14: Least-iterated screens polish (6/6 plans) — completed 2026-06-12
- [x] Phase 15: High-traffic screens + evidence adapters (5/5 plans) — completed 2026-06-13
- [x] Phase 16: Motion + responsive + theme parity (6/6 plans) — completed 2026-06-13
- [x] Phase 17: Consistency sweep + proof (3/3 plans) — completed 2026-06-13

Full details: `.planning/milestones/v3.0-ROADMAP.md`. Closed with `gaps_found` audit accepted — 10 verification-doc gaps recorded as Known Gaps in MILESTONES.md.

</details>

<details>
<summary>✅ v2.17 Vesicle (Phases 18–22) — SHIPPED 2026-06-11</summary>

- [x] Phase 18: Pressure-test audit + decision lock — gate #1 approved 2026-06-11 (tagline override "AI ops for Phoenix apps."; propagation: not-required) — completed 2026-06-11
- [x] Phase 19: Logo divergence + user choice — gate #2 (2 rounds): TV-1 "Span rail" mark + LK-B "Mark-as-o" fused lockup locked — completed 2026-06-11
- [x] Phase 20: Logo convergence — full variant set — 8 root variants, user confirmed "ship it" — completed 2026-06-11
- [x] Phase 21: Tokens + brand book + standalone HTML — tokens.json/css, brand-book.md 543 lines, 7 examples, index.html 55 KB — completed 2026-06-11
- [x] Phase 22: Integration + final quality gate — quality-gate.mjs 8/8 PASS, 458 KB, mix test 632 green, DS-06 untouched — completed 2026-06-11

Full details: `.planning/milestones/v2.17-ROADMAP.md`

</details>

<details>
<summary>✅ v2.16 ReqLLM Peer Bump (Phases 08–10 + 10.1) — SHIPPED 2026-05-30</summary>

- [x] Phase 08: Bump ReqLLM constraint and lockfile — completed 2026-05-30
- [x] Phase 09: Compatibility fixes and test verification — completed 2026-05-30
- [x] Phase 10: CI lane verification and closeout — completed 2026-05-30
- [x] Phase 10.1: VERIFICATION gap closeout (INSERTED) — 1/1 plan — completed 2026-05-30

Full details: `.planning/milestones/v2.16-ROADMAP.md`

</details>

<details>
<summary>✅ v2.15 Connector Adoption Lane (Phases 05–07 + 07.1) — SHIPPED 2026-05-30</summary>

- [x] Phase 05: Lane contract + Mix task — completed 2026-05-30
- [x] Phase 06: Integration proof + SupportJourney alignment — completed 2026-05-30
- [x] Phase 07: Docs, drift guards, CI wiring — completed 2026-05-30
- [x] Phase 07.1: VERIFICATION gap closeout (INSERTED) — 1/1 plan — completed 2026-05-30

Full details: `.planning/milestones/v2.15-ROADMAP.md`

</details>

### 📋 v3.1 CI/CD Velocity (Next — planned)

Next milestone, seeded by **SEED-003 (CI/CD efficiency overhaul — cut CI wall-clock)**. Not yet scoped into phases. Start with `/gsd:new-milestone`.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 11. Evaluation engine + seed depth | v3.0 | 5/5 | Complete | 2026-06-04 |
| 12. Design-system component layer | v3.0 | 5/5 | Complete | 2026-06-04 |
| 13. Orientation spine (IA) | v3.0 | 8/8 | Complete | 2026-06-12 |
| 14. Least-iterated screens polish | v3.0 | 6/6 | Complete | 2026-06-12 |
| 15. High-traffic screens + evidence adapters | v3.0 | 5/5 | Complete | 2026-06-13 |
| 16. Motion + responsive + theme parity | v3.0 | 6/6 | Complete | 2026-06-13 |
| 17. Consistency sweep + proof | v3.0 | 3/3 | Complete | 2026-06-13 |
| 18. Pressure-test audit + decision lock | v2.17 | 2/2 | Complete | 2026-06-11 |
| 19. Logo divergence + user choice | v2.17 | 3/3 | Complete | 2026-06-11 |
| 20. Logo convergence — full variant set | v2.17 | 2/2 | Complete | 2026-06-11 |
| 21. Tokens + brand book + standalone HTML | v2.17 | 3/3 | Complete | 2026-06-11 |
| 22. Integration + final quality gate | v2.17 | 2/2 | Complete | 2026-06-11 |
| 08 | v2.16 | — | Complete | 2026-05-30 |
| 09 | v2.16 | — | Complete | 2026-05-30 |
| 10 | v2.16 | — | Complete | 2026-05-30 |
| 10.1 | v2.16 | 1/1 | Complete | 2026-05-30 |

## Previous milestone archive

See `.planning/MILESTONES.md` for full closeout history.
