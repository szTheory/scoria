# Phase 13 Discussion Log — Orientation spine (IA)

**Date:** 2026-06-11
**Mode:** Advisor (research-backed) — 4 gray areas selected by user, 4 parallel gsd-advisor-researcher agents, calibration `minimal_decisive`. User locked all four recommendations as a coherent set in one pass.

---

## Area 1: Status Home vs the "/" route

**Options compared:** (A) Status Home takes "/", Live Ops moves to /live_ops; (B) separate /home linked from nav; (C) status-first "/" — orientation layered above the existing live stream, one screen, no new route.

**Selection: C.** A fails IA-02 (taxes the on-call operator +1 click per visit); B is the clicked-past-forever welcome page.

**Named-tool lessons:** Phoenix LiveDashboard (home = live status, zero marketing copy — the embedded-lib idiom); Sentry (home = the attention queue); Oban Web (direct-to-queue works only for single-domain tools); Grafana/SRE practice (vanity dashboards are the documented anti-pattern); Langfuse (metrics-first home that users click past — the footgun); LangSmith/Helicone (direct-to-evidence but no "what needs me" rollup); Linear (remember-last-screen is off-idiom for an embedded lib). Embedded-library copy norm: one identity sentence is the ceiling; paragraphs belong in README/HexDocs.

**Locked shape:** identity line → needs-attention strip (actionable counts only, collapse on all-clear) → live run stream. Nav: Live Ops → Home.

## Area 2: ⌘K palette scope + keyboard shortcuts

**Options compared:** client-filtered vanilla hook over a server-rendered command list vs server-filtered LiveComponent (live_select pattern).

**Selection: client-filtered hook.** Zero per-keystroke latency (the remote/VPN on-call test), zero new deps, matches the scoria.js hook idiom. Server-filtering deferred until CMDK-SEARCH (DB-backed object search) lands.

**Named-tool lessons:** Oban Web (added a visible help affordance after shortcut-only discoverability failed — ship the ⌘K hint visibly); GitHub (sunset its ⌘K palette: a palette that duplicates nav poorly goes unused); Linear (the success case — instant filtering, g-chords); live_select (server round-trips are for genuinely dynamic options only).

**Locked shape:** sections Recent(5, localStorage)/Navigate(nav SSOT incl. stubs)/Actions(3 static); chords g h/a/r/i/c/q/e/p + ⌘K + ? overlay; structural host-scoping; no approve/escalate keys in v1; full a11y dialog semantics.

## Area 3: Configure group + stub placement

**Contested placements compared:** Connectors move vs stay (moved — tempo axis stays honest, Configure gets a real anchor; health-check habit preserved via cross-link); Cost Ledger Improve vs Configure (Improve — a ledger is read on days-tempo, not set once); stubs badged-in-place vs separate cluster vs hidden (badged in place — "reads as complete" requirement; separate cluster = roadmap ghetto; hidden fails outright).

**Named-tool lessons:** Grafana Connections vs Explore + bidirectional cross-links (the same-noun rule); Sentry Settings vs Issues; PostHog (clickable badged unreleased products as demand signal); the long-lived coming-soon tab that never ships (trust erosion); OSS angle — stubs with tracking issues read as roadmap confidence.

**Locked layout:** Operate: Home, Approvals, Runs, Incidents · Improve: Review Queue, Eval Workbench, Prompt Registry, +3 stubs (Replay Playground, Cost Ledger, Feedback Inbox) · Configure: Connectors, +2 stubs (MCP Gateway, Tool Registry). One shared stub LiveView at /coming/:screen. Dataset Builder excluded (Phase 14 builds it for real).

**Approved stub microcopy examples:**

> **Cost Ledger** — Soon
> Cost Ledger will reconcile model spend per run, tenant, and prompt version — traced from span evidence, not estimated.
> **What works today:** token and model usage is recorded on every run's spans. Open a run in Runs to inspect per-span usage; eval campaign cost appears in Eval Workbench.
> Track progress: scoria#<issue>.

> **Replay Playground** — Soon
> Replay Playground will let you branch a run from any checkpoint, swap the prompt or model, and compare replayed evidence against the original side by side.
> **What works today:** replay works from a run's evidence page — open a run in Runs and choose Replay. Unsafe external effects are blocked or stubbed by default; provenance stays explicit.
> Track progress: scoria#<issue>.

## Area 4: Breadcrumbs + quality-loop threading

**Options compared:** identity-row header + contextual next-step verbs + provenance line vs persistent loop rail/stepper.

**Selection: identity-row + verbs.** Stepper rejected: the loop is non-linear (operators enter anywhere), per-object "current stage" is ambiguous, no trusted operator tool draws it, and it eats space on the dense trace explorer.

**Named-tool lessons:** Sentry (slim crumb above a dominant identity header); GitHub (no trail — identity > path); Datadog (related telemetry as flat links, never graph-viz); LangSmith ("source run" as one sentence — exactly Scoria's existing replay strip); Grafana (full trails only make sense at 3-4 levels deep); Linear (middle-truncated IDs, crumbs in page header).

**Locked shape:** `<.object_header>` (crumb on object pages only, identity row, conditional provenance line with standardized grammar generalizing show.ex's existing replay strip); next-step verb matrix per object page; `?from={noun}:{id}` origin param → dismissible return chip.

---

## Coherence pass (orchestrator synthesis)

- Home rename ripples: nav label Live Ops → Home; chord `g l` → `g h`.
- Palette Navigate section reads the same `DashboardNav.groups/0` the stubs join — one SSOT.
- Home's attention strip carries the Connectors cross-link required by the same-noun rule.
- `object_header` hosts crumbs, provenance, AND the return chip — one component, three IA-03/IA-05 jobs.
- Dataset Builder 5-vs-6 discrepancy resolved: not a stub (Phase 14 SCREEN-02 builds the real index).

## Deferred (captured, not acted on)

CMDK-SEARCH, IA-LENS (both already in REQUIREMENTS.md deferrals), j/k row navigation + row-context action keys, custom keybindings.
