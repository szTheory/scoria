# Phase 78: Hex consumer contract foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 78-Hex consumer contract foundation
**Areas discussed:** HexConsumerContract API & visibility, Tarball dep shape, hex.build caching, Phase 78 vs 79 proof depth, DOCS-HEX-01 split, Generator dep_mode default

---

## HexConsumerContract API & visibility

| Option | Description | Selected |
|--------|-------------|----------|
| Public `lib/scoria/hex_consumer_contract.ex` | Mirror `AdopterDocContract`; shipped in tarball; SSOT for version, Hex snippet, tarball tuple | ✓ |
| `test/support` only | Zero public surface; matches Oban/Ecto pattern | |
| Merge into `AdopterDocContract` | Single god-module for all doc contracts | |

**User's choice:** Research all areas; accept unified recommendation (public lib module).
**Notes:** Version from `Application.spec(:scoria, :vsn)` only; `~> 0.1` as explicit policy constant. Guard tests tie mix.exs ↔ contract ↔ README.

---

## Tarball dep shape in generated hosts

| Option | Description | Selected |
|--------|-------------|----------|
| A: `{:scoria, path: unpack_root}` after `hex.build --unpack` | PR CI proves packaged artifact; Hex #515 precedent | ✓ |
| B: Literal `hex: :scoria` + env override | README-shaped mix.exs; needs `SCORIA_ARTIFACT_PATH` in CI | |
| C: `path:` to `.tar` file | Not supported by Mix path SCM | |

**User's choice:** Unified recommendation (Approach A for PR; live Hex dep in Phase 81).
**Notes:** "Hex-shaped" = two surfaces in one SSOT module. Reject repo-root `path:` in adoption.

---

## hex.build lifecycle & caching

| Option | Description | Selected |
|--------|-------------|----------|
| Fingerprint cache + setup_all + CI env reuse | `ensure_current_unpack_root!/0`; `SCORIA_HEX_UNPACK_ROOT` after release_preview | ✓ |
| Per-test hex.build | Hermetic but wasteful at Phase 80 | |
| Compile-time `@unpack_root` | Stale artifact under incremental compile | |
| Reuse release-preview only (no lazy build) | Breaks local `mix test.adoption` parity | |

**User's choice:** Three-layer cache recommendation.
**Notes:** Phase 80 baseline = committed `0.1.0` fixture, not CI rebuild.

---

## Phase 78 green bar vs Phase 79

| Option | Description | Selected |
|--------|-------------|----------|
| A: Full proof on tarball in 78 | Single vertical slice | |
| B: Infra only in 78; overlay in 79 | Risk path-dep green window | |
| C: Hybrid — route proof in 78, full overlay in 79 | Tracer bullet; v2.9 overlay already proven | ✓ |

**User's choice:** Hybrid C.
**Notes:** Implement real `run_route_proof!/1`. HEX-CONSUMER-01 partial in 78, complete in 79.

---

## DOCS-HEX-01 split (78 vs 82)

| Option | Description | Selected |
|--------|-------------|----------|
| A: Tests/SSOT only in 78 | Executable guards; prose in 82 | ✓ |
| B: Tests + one README sentence in 78 | Higher adopter discoverability mid-milestone | Optional late 78/early 79 |
| C: Defer all prose to 82 | Clean boundary; doc lag during 79–81 | |

**User's choice:** A (+ optional B after 79).
**Notes:** No `ci_policy_contract_test` topology pins until Phase 81/82 stable.

---

## Generator default dep_mode

| Option | Description | Selected |
|--------|-------------|----------|
| A: Opt-in `:hex_tarball`; default `:path` | Minimal 78 diff | |
| B: Default `:hex_tarball` | Complicates Phase 80 baseline vs current | |
| C: Required `dep_mode` (no default) | Least surprise; Phase 80 explicit baseline | ✓ |

**User's choice:** Required `dep_mode`.
**Notes:** `HostInstallFixtures` unchanged on `path:`. Only one `create_host!` caller today.

---

## Claude's Discretion

- `package_fingerprint/0` implementation detail
- Optional `SCORIA_ARTIFACT_PATH` local override
- Exact `run_route_proof!/1` filter mechanics

## Deferred Ideas

- Live registry proof — Phase 81
- Upgrade smoke — Phase 80
- Full doc drift guards — Phase 82
- Local Hex registry for PR CI — rejected
- `SCORIA_ARTIFACT_PATH` maintainer helper — optional future
