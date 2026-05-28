# Roadmap: Scoria

## Milestones

- ◆ **v2.7 OSS Release + Docs Truth** — Active (this file)
- ✅ **v2.6 Warning Ratchet** — Archived: `.planning/milestones/v2.6-ROADMAP.md` (shipped 2026-05-28)
- ✅ **v2.5 Installer Safety & Upgrade Confidence** — Archived: `.planning/milestones/v2.5-ROADMAP.md` (shipped 2026-05-27)
- ✅ **v2.4 Adoption Reliability Contract** — Archived: `.planning/milestones/v2.4-ROADMAP.md` (shipped 2026-05-27)

## v2.7 Scope

**Goal:** Docs truth first, then first Hex publish at `0.1.0` / `v0.1.0` — without weakening v2.4 lane contracts, v2.5 installer truth, or v2.6 CI gates.

**Requirements mapped:** 5 / 5

| Phase | Name | Goal | Requirements |
|------:|------|------|--------------|
| 70 | 3/3 | Complete   | 2026-05-28 |
| 71 | Release Infrastructure | CHANGELOG, release-please, publish workflow prep, v2.6 attestation | HEX-01, HEX-02 |
| 72 | Hex Publish Closeout | `mix hex.publish`, tag, README/package_surface flip, milestone audit | HEX-01, HEX-02 |

**Sequencing rule:** Phase 70 merges before Phase 72 publish — never ship HexDocs with stale v2.1 narrative.

## Phases

- [x] Phase 70: Docs Truth Foundation (0/3 plans) (completed 2026-05-28)
- [ ] Phase 71: Release Infrastructure (0/? plans)
- [ ] Phase 72: Hex Publish Closeout (0/? plans)

## Phase Details

### Phase 70: Docs Truth Foundation

**Goal:** Align README and support docs with v2.5+ shipped capability using capability-based truth (not milestone codenames); commit install_contract maintainer lane; document semantic local-only boundary.

**Requirements:** DOCS-03, DOCS-04, INST-DX-01

**Depends on:** v2.6 shipped baseline (lane contracts, installer SSOT, CI topology)

**Success criteria:**

1. README shipped banner lists capabilities (default runtime, bounded handoff, semantic fast path, optional knowledge, upgrade-safe install) — no `Scoria is shipped through vX.Y` milestone codenames.
2. README Install section documents `--check` / `--dry-run` upgrade path with link to operator verification installer modes.
3. `adoption_surface_test` asserts capability nouns and refutes milestone-banner pattern; maintainer-only commands absent from README.
4. `mix scoria.test.install_contract` committed with `mix.exs` preferred_envs; adoption lane file list excludes deep installer contract tests; operator verification documents maintainer command.
5. CI gate map includes explicit "not in PR CI" row for `mix test.semantic_fast_path` and one-line planning-milestone vs Hex semver explanation.

**Non-goals:** Hex publish, README Hex dep flip, release-please workflows, CI topology changes.

---

### Phase 71: Release Infrastructure

**Goal:** Prepare szTheory-standard release automation and maintainer runbook without publishing to Hex yet.

**Requirements:** HEX-01, HEX-02 (prep portions)

**Depends on:** Phase 70 merged (docs truth on main)

**Success criteria:**

1. `CHANGELOG.md` exists with milestone-vs-semver preamble and `[0.1.0]` section summarizing capability through v2.6.
2. `release-please-config.json`, manifest baseline, and `.github/workflows/release-please.yml` added; publish job mirrors PR CI test topology (policy + full test job steps).
3. Manual recovery `hex-publish.yml` documented; `HEX_API_KEY` setup noted in operator verification maintainer section.
4. Hex name availability recorded (`scoria` on hex.pm); `.tool-versions` aligned with CI OTP 27 / Elixir 1.19.
5. v2.6 remote CI green attestation recorded (69-02-04 carryover) or explicit gate-zero waiver in phase verification.

**Non-goals:** `mix hex.publish` to production registry, README Hex badge, package_surface_test flip.

---

### Phase 72: Hex Publish Closeout

**Goal:** Publish `0.1.0` on Hex at git tag `v0.1.0` with coordinated adopter-facing flip and milestone closeout.

**Requirements:** HEX-01, HEX-02 (closeout portions)

**Depends on:** Phase 71 merged; release-please Release PR reviewed

**Success criteria:**

1. `https://hex.pm/packages/scoria` shows `0.1.0`; git tag `v0.1.0` and GitHub Release exist with CHANGELOG body.
2. README primary install is `{:scoria, "~> 0.1"}` with GitHub tag fallback; Hex badge added.
3. `package_surface_test` asserts Hex-first install story (flip from pre-publish GitHub-only guard).
4. `mix scoria.release_preview` and full CI green on publish commit; HexDocs `source_ref` links resolve.
5. v2.7 milestone audit artifact written; REQUIREMENTS traceability marked complete; `release-as: "0.1.0"` pin removed post-publish if used.

**Non-goals:** SEM-CI-01, knowledge WAE in CI, new runtime features, semver `2.7.0`.

## Non-Goals (v2.7)

- SEM-CI-01 semantic lane in PR CI (document local command only in Phase 70).
- Knowledge WAE in default CI closeout.
- New runtime capability families or connector guide expansion.
- Package-family Hex decomposition.
- Broad README restructure beyond capability banner + install upgrade paragraph.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | --------- |
| 70. Docs Truth Foundation | v2.7 | 0/? | Not started | — |
| 71. Release Infrastructure | v2.7 | 0/? | Not started | — |
| 72. Hex Publish Closeout | v2.7 | 0/? | Not started | — |

## Traceability

See `.planning/REQUIREMENTS.md` for requirement checkboxes and phase mapping.
