# Phase 13: Orientation spine (IA) - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Advisor-mode discussion — 4 research-backed gray areas, all recommendations user-approved as a coherent set

<domain>
## Phase Boundary

A newcomer dropped on the dashboard immediately understands what Scoria does and how to reach their job; a returning power user keeps a zero-click path; screens stop feeling like disjoint islands. Delivers: nav active-state fix, third nav group (Operate/Improve/Configure), Status Home, object-aware breadcrumbs, ⌘K command palette + keyboard shortcuts, quality-loop threading, honest "coming soon" stubs. Requirements IA-01..IA-06. UI-only — no net-new backend capabilities; stubs never show fake data.

</domain>

<decisions>
## Implementation Decisions

### Status Home (IA-02) — status-first "/", no new route
- **D-01:** OrchestratorLive STAYS mounted at "/" — no `/home`, no `/live_ops`, no route or `derive_base` changes. The nav item relabels **Live Ops → Home** (key can stay `:live_ops` or rename; planner's call, but `DashboardNav` view-map must stay consistent).
- **D-02:** Template restructures top-down: (1) **identity line** — one muted sentence under the page title: "Every AI run in this app, traced. Approve tools, triage incidents, and gate prompt releases from here." (2) **needs-attention strip** — cards ONLY for nonzero actionable states: pending approvals (count + oldest age), open incidents, degraded connectors, review-queue depth / failing eval gates; each card one click to its screen; counts and ages only — NO charts, NO sparklines. All-clear collapses to one line: "Nothing needs attention. 0 approvals pending, 0 open incidents." (3) **live run stream** — existing stream, full height, unchanged PubSub.
- **D-03:** Day-0 empty state doubles as onboarding: "No traces yet. Run your first chat response or MCP request to see the run tree."
- **D-04:** Counts load via `assign_async`-style non-blocking queries; badges refresh via existing PubSub where available. The attention strip is the orientation device — never a vanity dashboard (Grafana/Langfuse footgun, explicitly rejected).

### ⌘K palette + shortcuts (IA-04) — client-filtered vanilla hook, zero new deps
- **D-05:** Server renders the FULL command list (<30 items) into the DOM at mount; one vanilla JS hook in `assets/js/scoria.js` (CopyId/ThemeToggle precedent) handles open/filter/keyboard-nav. NO socket traffic while typing; NO new npm deps; NO LiveComponent round-trips (rejected: latency on remote ops access).
- **D-06:** Sections + ranking (empty query): 1. **Recent** (max 5 objects), 2. **Navigate** (all screens from `DashboardNav.groups/0` — palette reads the same SSOT; stubs included, labeled "Soon"), 3. **Actions** (static: Toggle theme, Keyboard shortcuts, Copy current page URL). Typing = case-insensitive substring on label + aliases ("runs" matches "workflows"); hide empty sections; no fuzzy-scoring library.
- **D-07:** Recency storage: localStorage key `scoria:recents:<mount-base>`, written by a tiny hook on object pages from data attributes; cap 8 stored / 5 shown. NO assigns, NO ETS, NO DB tables for UI state.
- **D-08:** Triggers + scoping: `⌘K`/`Ctrl+K` open, `Esc` close, `?` shortcuts overlay. Structural scoping — `scoria.js` loads only on the dashboard layout; hook adds/removes window listeners in mounted/destroyed; ignores events from input/textarea/contenteditable and `event.isComposing`; preventDefault only on owned keys. Never hijacks host-app pages.
- **D-09:** v1 chord map (g-then-letter, 1.5s timeout): `g h` Home, `g a` Approvals, `g r` Runs, `g i` Incidents, `g c` Connectors, `g q` Review Queue, `g e` Eval Workbench, `g p` Prompt Registry. NO global approve/deny/escalate keys in v1 (misfire hazard without focused-row context). Discoverability: visible `⌘K` kbd hint in the topbar + `?` overlay + kbd chips on palette rows (Oban Web lesson: shortcut-only discoverability fails).
- **D-10:** A11y: `role="dialog"` + `aria-modal`, focus trap, `role="listbox"`/`aria-activedescendant`, focus restored to invoker on close; open/close opacity-only ≤200ms, skipped under `prefers-reduced-motion`; rendered via a `ui.ex` component (DS-06). Empty-state microcopy: "No matches. The palette covers screens, recent objects, and actions — full object search lands in a later release."

### Nav groups + stubs (IA-01, IA-06) — Connectors moves to Configure; stubs badged in place
- **D-11:** Final 3-group layout (group order = persona tempo minutes/days/once-in-a-while; real screens first, stubs last):
  - **Operate:** Home, Approvals, Runs, Incidents
  - **Improve:** Review Queue, Eval Workbench, Prompt Registry, *Replay Playground* (Soon), *Cost Ledger* (Soon), *Feedback Inbox* (Soon)
  - **Configure:** Connectors (MOVED from Operate), *MCP Gateway* (Soon), *Tool Registry* (Soon)
- **D-12:** Cross-link rule: a noun appears in exactly ONE nav group; its other-tempo surface is an in-page link, never a second nav item. Concretely: Home's attention strip carries a connector-health card linking to Connectors ("3 connectors healthy — view"); the Connectors page links back to live evidence. Same rule when MCP Gateway/Tool Registry ship.
- **D-13:** Stub treatment: muted-opacity nav items with a TEXT badge "Soon" (never color-only), fully clickable, routed to ONE shared stub LiveView (`live("/coming/:screen", ...)`) registered in `@views` so active-state works. NOTE: `derive_base/2`/`strip_known_prefixes/1` in dashboard_nav.ex hardcode route suffixes — the stub route touches that.
- **D-14:** Stub page anatomy (ordered, nothing else): (1) screen name + Soon badge, (2) ONE sentence of what it WILL do in evidence verbs (no hype words), (3) **"What works today"** — existing path with deep links (replay works from a run's evidence page; span usage visible in Runs; eval campaign cost in Eval Workbench), (4) GitHub tracking-issue link. NO mock charts, NO placeholder rows, NO skeleton screens. Approved microcopy examples for Cost Ledger + Replay Playground are in 13-DISCUSSION-LOG.md — use that grammar for the other three.
- **D-15:** Dataset Builder is NOT a stub — Phase 14 builds its real index (SCREEN-02). It joins Improve then. The "5 stubs" list is final for this phase: Replay Playground, Cost Ledger, Feedback Inbox, MCP Gateway, Tool Registry.
- **D-16:** IA-01 active-state fix: `ScoriaWeb.WorkflowLive.Index` is missing from the `@views` map in dashboard_nav.ex (Runs nav never lights on the index screen) — fix as part of the nav work, and audit the map covers every routed view incl. the stub route.

### Breadcrumbs + quality-loop threading (IA-03, IA-05) — identity-row header + verbs, NOT a stepper
- **D-17:** New `ui.ex` component `<.object_header>`: index screens get NO crumb (page title only; sidebar is the orientation). Object screens (Run show, Prompt Release Workbench, future) get: **Line 1 crumb** `{Parent screen, linked} / {object id, plain}` — only parent clickable; IDs middle-truncated (`trc_01J8…QK4`) with full ID in `title` + copy button; renders in the page header, NOT a global top bar. **Line 2 identity row:** type badge (text: "Run") · mono ID + copy · status badge · key scalar (agent name, started-at). **Line 3 (conditional):** provenance line and/or origin chip.
- **D-18:** Persistent loop rail/stepper REJECTED — the quality loop is non-linear (operators enter anywhere); no trusted operator tool draws it; wizard rigidity + ambiguous "current step" state.
- **D-19:** Threading = consistent "next-step verbs" cluster per object page (evidence-verb word bank): Incident → Open run / Open trace at failing span; Run show → Replay run / Promote span to dataset (exists) / Open incident (if linked) / Open prompt; Review item → Open run / Promote to dataset; Dataset row → Open source run; Eval result → Open prompt release / Open regressed runs; Release Workbench → View eval results / View baseline runs.
- **D-20:** Provenance grammar standardized into the component: `{Verb-ed} from {noun} {id} via {noun} {id} — {date}` (e.g. "Promoted from run trc_01J8KQ… via review rev_204 — Jun 9"), links inline, no graph-viz. Generalizes the replay strip ALREADY shipping in `lib/scoria_web/live/workflow_live/show.ex:108-145` — reuse, don't reinvent.
- **D-21:** Origin context: query param `?from={noun}:{id}` (allowlisted nouns; unknown ignored silently), read in `handle_params`, rendered as a dismissible return chip "← Back to incident inc_42" beside the crumb. Never the only way back. Params over navigate-state: survives refresh, shareable, back-button correct.

### Claude's Discretion
- Exact component APIs/slot shapes for `object_header`, attention cards, palette, stub page; attention-strip card ordering; whether `:live_ops` key renames; chord-timeout implementation details; how aliases are declared in the nav SSOT.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### IA / UX research (this discussion's evidence base)
- `.planning/research/liveview-operator-ux.md` — prior operator-UX research
- `.planning/phases/13-orientation-spine-ia/13-DISCUSSION-LOG.md` — full 4-area research findings incl. named-tool lessons + approved stub microcopy

### Design system + brand (binding)
- `brandbook/brand-book.md` §6 (voice/microcopy — calm/exact/useful, evidence verbs), §7 (UI guidance — status never color-only, focus rules)
- `lib/scoria_web/ui.ex` — token-gateway components; ALL new UI goes through here (DS-06 drift guard enforces)
- `test/support/ds06_baseline.txt` — raw-color guard baseline (additions must not add raw palette classes)

### Code under change
- `lib/scoria_web/dashboard_nav.ex` — nav SSOT (groups, @views map incl. the WorkflowLive.Index gap, derive_base/strip_known_prefixes route-suffix coupling)
- `lib/scoria_web/router.ex` — routes; stub route lands here
- `lib/scoria_web/live/workflow_live/show.ex` (lines ~108-145) — existing replay provenance strip + "Promote to dataset" verb (the pattern to generalize)
- `assets/js/scoria.js` — hook home (CopyId/ThemeToggle precedents for hook + localStorage idioms)
- `.planning/REQUIREMENTS.md` — IA-01..06 + CMDK-SEARCH/IA-LENS deferrals

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DashboardNav.groups/0` — already task-tempo grouped (Operate/Improve); palette + stubs extend the same SSOT
- `WorkflowLive.Show` replay provenance strip — already implements the provenance-line pattern; generalize into `object_header`
- `ui.ex` Phase-12 components (table, drawer, modal, badge, toast, skeleton) — attention cards/stub pages compose from these
- `scoria.js` hook + localStorage patterns (ThemeToggle persistence)

### Established Patterns
- Token-first CSS, components bind semantic tokens only; DS-06 ratchet runs in `mix test`
- `on_mount` hook assigns `:scoria_nav` + `:scoria_base`; all nav paths resolve relative to mount prefix (embedded-lib constraint — palette/shortcut nav must do the same)
- Honest stubs, never fake data (locked project decision)

### Integration Points
- Attention-strip counts: existing contexts (Approvals, Incidents, Connectors health, Review queue) — read-only queries, no new capabilities
- PubSub: OrchestratorLive already subscribes to run events; reuse for badge freshness where cheap

</code_context>

<specifics>
## Specific Ideas

- Identity line, all-clear line, empty-state, and palette empty-state microcopy: exact strings in D-02/D-03/D-10 — use verbatim.
- Stub microcopy grammar (from approved examples): "**{Name}** — Soon / {One will-do sentence, evidence verbs} / **What works today:** {existing path with deep links} / Track progress: scoria#<issue>."
- Crumb example for Run show: `Runs / trc_01J8KQ…X4` with identity row `[Run] trc_01J8KQ…X4 ⧉ [Failed] support_agent · started 14:02 UTC`.

</specifics>

<deferred>
## Deferred Ideas

- CMDK-SEARCH (full-text object search in palette) — already deferred in REQUIREMENTS.md
- IA-LENS (remembered persona lens on Status Home) — already deferred
- Per-row `j/k` list navigation + row-context approve/deny shortcuts — future, after list keyboard-nav lands
- User-customizable keybindings — future
- Real screens behind the 5 stubs — future milestones (Dataset Builder real index = Phase 14)

</deferred>

---

*Phase: 13-orientation-spine-ia*
*Context gathered: 2026-06-11 via advisor-mode discussion (4 parallel research agents, recommendations locked as a set)*
