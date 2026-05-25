# Phase 48: Host-app install contract and consumer proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 48-host-app-install-contract-and-consumer-proof
**Areas discussed:** installer contract, consumer proof shape, default-lane proof depth, optional-surface denial story

---

## Installer contract

| Option | Description | Selected |
|--------|-------------|----------|
| Harden the current explicit patcher | Keep `mix scoria.install` as the one-command installer, but tighten idempotency, duplicate prevention, fallback/manual guidance, and mutation truth | ✓ |
| Manual-first instructions only | Replace installer mutation with explicit manual steps and docs | |
| Igniter-style semantic codemods | Rebuild installer around a richer semantic patching framework | |
| Migration helper abstraction | Replace copied host migrations with a library-owned migration contract | |

**User's choice:** Discuss all and provide one coherent recommendation set.
**Notes:** Recommendation is to keep the current one-command installer shape because it best matches Scoria's Phoenix-first embedded product posture and the milestone's boring-adopter goal. The main hardening focus is mutation truth and fallback behavior, not expanding installer scope.

---

## Consumer proof shape

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh generated Phoenix app in CI | Build proof directly from `mix phx.new` and run the full adoption steps in a temp app | |
| Checked-in minimal host harness | Keep a permanent host app fixture in the repo | |
| Hybrid generated-host harness | Start from a fresh Phoenix app, apply a tiny bounded Scoria patch, then run bounded install/migrate/route assertions | ✓ |
| Embedded sample-app helper approach | Use a reusable embedded-app helper abstraction rather than raw generator flow | |

**User's choice:** Discuss all and provide one coherent recommendation set.
**Notes:** Recommendation is the hybrid generated-host harness. It is closer to the real public install path than a checked-in dummy app, but avoids turning the host proof into a giant second application.

---

## Default-lane proof depth

| Option | Description | Selected |
|--------|-------------|----------|
| Monolithic end-to-end lane | Prove everything in one giant host-app integration path | |
| Split host-app smoke and runtime proof | Keep separate install and runtime lanes with no canonical wrapper | |
| Layered proof under one canonical command | One human-facing verifier composed of focused installer, host-app, migration, runtime, and operator-evidence seams | ✓ |
| High-fidelity generated-host lane only for nightly/release | Keep the strongest host proof outside the primary canonical lane | |

**User's choice:** Discuss all and provide one coherent recommendation set.
**Notes:** Recommendation is one canonical default-lane command implemented as layered focused proofs. This preserves support truth for adopters while keeping CI and failure triage bounded.

---

## Optional-surface denial story

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal skip note only | Short installer output with limited optional-surface explanation | |
| Next-steps plus optional appendix | Slightly expanded output with default lane first and optional follow-ups after | |
| Explicit lane inventory | Compact installed/skipped/optional sections with lane boundaries named directly | ✓ |
| Strong denial/fallback guidance everywhere | Highly explicit warnings and denial language across installer and docs | |

**User's choice:** Discuss all and provide one coherent recommendation set.
**Notes:** Recommendation is the explicit lane inventory, plus one sentence of denial/fallback wording for skipped surfaces. This is the best balance between user-friendly output and support truth.

---

## the agent's Discretion

- Exact implementation mechanism for installer hardening.
- Exact generated-host harness structure and helper naming.
- Exact composition of the canonical default-lane verifier.
- Exact wording of the lane-inventory output, shortdocs, and companion docs.

## Deferred Ideas

- Full Igniter migration for Scoria installers/upgraders.
- Library-owned migration helper/version contract instead of copied host migrations.
- Large permanent sample host app in the repo.
- Final cross-lane wording convergence across installer, README, and every verification guide; reserved for Phase 49.
