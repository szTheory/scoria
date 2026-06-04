# Phase 11: Evaluation engine + seed depth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 11-evaluation-engine-seed-depth
**Areas discussed:** Browser capture engine, Critique production, Seed data source, State-matrix navigation
**Mode:** Advisor (research-backed comparison tables) · calibration tier `minimal_decisive` · `NON_TECHNICAL_OWNER = false`

---

## Browser capture engine

| Option | Description | Selected |
|--------|-------------|----------|
| Playwright via System.cmd | Mix task shells out to checked-in `priv/dev/shots.mjs`; zero Hex footprint; preserves "no browser automation in CI / clean hex.audit"; Playwright handles sentinel-wait, viewport, theme eval, click, screenshot natively | ✓ |
| Wallaby (only: :dev, runtime: false) | Pure-Elixir toolchain, but adds a Hex dep visible in mix.lock/hex.audit, needs chromedriver, blurs the "no browser automation" contract | |

**User's choice:** Playwright via System.cmd (Recommended)
**Notes:** Research confirmed no browser-automation dep currently exists in mix.exs. The dev-only, zero-mix.exs-impact path is the decisive fit for a Hex-shipped package with a deliberate LiveViewTest-only CI posture.

---

## Critique production

| Option | Description | Selected |
|--------|-------------|----------|
| In-harness ReqLLM vision, gated step | Screenshots always capture deterministically; separate `--critique` step sends canonical screenshots (populated·desktop·dark, ~9 calls) through ReqLLM vision; findings JSON + gap_register.md committed for stable rubric-deltas | ✓ |
| Emit prompt+artifacts for out-of-band critique | Harness only screenshots + emits a critique prompt/template; rubric filled separately (human/external). Deterministic harness but weakens "mechanically capture AND critique" and relies on process discipline | |

**User's choice:** In-harness ReqLLM vision, gated step (Recommended)
**Notes:** Research confirmed ReqLLM 1.13 supports `ContentPart.image(binary, "image/png")`. Decoupling capture from critique and gating the LLM call to phase-milestone boundaries on a single canonical state per screen controls cost + non-determinism while keeping the rubric-delta signal meaningful across phases 12–17.

---

## Seed data source

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid: SupportJourney spine + additions | Reuse SupportJourney identities for Runs/Approvals/Connectors (one shared "Acme" story with the gallery); add eval specs, incidents, review candidates, release gates, degraded connectors only in dev_seed.exs; no drift-guard coupling | ✓ |
| Standalone independent seed | dev_seed.exs owns all constants, zero fixture coupling; but duplicates tenant_id/connector_key and risks two diverging "Acme" stories | |

**User's choice:** Hybrid: SupportJourney spine + additions (Recommended)
**Notes:** Research found `examples/support_copilot/priv/repo/dev_seed.exs` already uses SupportJourney as its spine — a working analog. `SupportJourneySourceTest` pins only doc-surface fragments, so additive dev-seed domains carry no drift-guard risk.

---

## State-matrix navigation

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest + JS dispatch + dual-tenant | Per-screen manifest names phx-click event + payload; harness dispatches post-load and re-awaits data-scoria-ready. Matches assigns-driven overlays. Empty vs populated = navigate twice with different ?tenant= (already wired); no DB reset | ✓ |
| Refactor overlays to live_action URL params | Pure URL-driven matrix, but requires refactoring 5+ assigns-driven overlay LiveViews before the harness exists — pre-phase scope creep belonging in Phase 12 | |

**User's choice:** Manifest + JS dispatch + dual-tenant (Recommended)
**Notes:** Research confirmed overlays are assigns-driven (`show_approve_modal`, `runtime_drawer`, `connector_drawer`) with no `live_action`/`push_patch`, and `tenant_id` already flows via `params["tenant"]` on every screen — making dual-tenant empty/populated capture a zero-friction config switch.

---

## Claude's Discretion

- Manifest file format (Elixir term vs YAML), output dir layout beyond the UI-SPEC path, `.gitignore` granularity, sentinel poll interval/timeout, Node↔Elixir error-propagation protocol.
- Vision model selection and `ANTHROPIC_API_KEY` key-absent ergonomics (default to latest capable Claude vision model).

## Deferred Ideas

- Migrate overlays to `live_action` URL params — Phase 12 design-system contract, if ever.
- Full 16-combo LLM critique (vs canonical single state per screen) — later, if per-state findings prove necessary.
- Consolidating `--scoria-space-3` (12px), `--scoria-space-9` (96px), `--scoria-fs-badge` (11px) — UI-SPEC-flagged DS gap-register candidates; audit findings here, changed (if at all) in later DS phases.
