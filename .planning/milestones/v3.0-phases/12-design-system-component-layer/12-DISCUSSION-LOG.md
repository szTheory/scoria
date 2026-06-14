# Phase 12: Design-System Component Layer - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 12-design-system-component-layer
**Areas discussed:** Guard activation & migration scope, Evidence notebook conversion scope, Component adoption / API proof, Toast & skeleton wiring
**Mode:** advisor (calibration tier `minimal_decisive`, 4 parallel research agents on sonnet)

---

## Context

The `12-UI-SPEC.md` design contract (approved) locks all visual/interaction/copy decisions. Discussion focused only on scope and sequencing, which the UI-SPEC does not resolve. A key reconciliation surfaced during research: the **roadmap distributes the raw-palette sweep and evidence-adapter conversion across Phases 14, 15, and 17** — which corrected one research agent's false premise that DS-06 forces a full repo-wide sweep within Phase 12.

---

## GA1 — Guard activation & migration scope

| Option | Description | Selected |
|--------|-------------|----------|
| Ratchet baseline | Commit `path:count` baseline; guard fails only on new/grown violations; sweep deferred to 14/15/17 | ✓ |
| Mechanical full sweep now | Replace all ~498 lines / 623 occurrences across 23 files in Phase 12 | |

**User's choice:** Ratchet baseline (locked all-as-recommended).
**Notes:** Reconciles success-criterion #5 — guard exists & enforces (can't regress/grow), `ui.ex` gateway clean now, codebase reaches zero in Phase 17.

## GA2 — Evidence notebook conversion scope

| Option | Description | Selected |
|--------|-------------|----------|
| Shell only + 1 proof adapter | Build `<.notebook>` shell in P12; convert one thinnest evidence component as API proof; defer the 13-component conversion to Phase 15 | ✓ |
| Convert all 7/13 now | Wrap every evidence component in P12 | |

**User's choice:** Shell only + 1 proof adapter.
**Notes:** Roadmap assigns the 13-component evidence-adapter conversion to Phase 15. "Convert all now" was premised on a full P12 sweep the roadmap doesn't require — rejected after ground-truthing the roadmap.

## GA3 — Component adoption / API proof

| Option | Description | Selected |
|--------|-------------|----------|
| No screen migration in P12 | Prove APIs via `render_component`/LiveViewTest unit tests + DS-05 real paths; all screen conversion stays in 14/15 | ✓ |
| Migrate 2-3 thin first-consumer screens | Pull some screen proof forward to harden APIs before lock | |

**User's choice:** No screen migration in P12 (roadmap-disciplined).
**Notes:** `ui.ex` is internal app code, not a shipped Hex lib, so late API tweaks in Phase 14 are cheap — no API-freeze pressure justifies pulling screen work forward. This was flagged as the one area with a genuine live tradeoff.

## GA4 — Toast & skeleton wiring

| Option | Description | Selected |
|--------|-------------|----------|
| Server-assign list + one real path | `@toasts` + `put_toast/2` mirroring `put_flash`; `JS.hide` auto-dismiss; wire one real toast + one real skeleton | ✓ |
| `push_event` + JS hook | Client-driven toast lifecycle | |

**User's choice:** Server-assign list + one real path.
**Notes:** JS-hook path is invisible to LiveViewTest (hooks no-op in test env) → false-green risk under LiveViewTest-only CI. Server-assign is fully assertable via `render(view) =~ ...`.

---

## Claude's Discretion

- Internal HEEx structure of each component, helper naming, test organization.
- Which specific thinnest evidence component to convert as the notebook proof adapter.
- Which real action(s) get the toast + skeleton wiring.

## Deferred Ideas

- Full raw-palette sweep (all 23 files) → Phases 14/15/17.
- 13 evidence components → adapters → Phase 15.
- Screen migrations onto shared components → Phases 14/15.
- Motion / responsive / theme-parity audit → Phase 16.
- Final audit loop, contact sheets, `docs/MAINTAINERS.md` → Phase 17.
