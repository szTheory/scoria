# Phase 39: Component Groups And Operator Flows - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

> **Research-backed, one-shot decisions.** All five gray areas were resolved through five
> parallel deep-research passes (idiom + lessons-from-other-libs + UI/UX/JTBD + brand + a11y/perf
> lenses), grounded in the actual code and `brandbook/brand-book.md`. The decisions below are the
> locked spec; each is a concrete choice a downstream agent can act on without re-asking the user.
> They are deliberately mutually coherent — see **The Coherence Spine** first, it is load-bearing.

<domain>
## Phase Boundary

Phase 39 applies the Phase-38 primitive system to Scoria's **8 real operator pages** — approvals,
incidents, reviews, datasets, workflow detail, connectors, prompts, eval — so each page **serves
operator intent rather than backend structure**. In scope: (1) one clear orientation header per
page with a single obvious scan/action path and no redundant single-region headers (FLOW-01);
(2) consistent page-section / table-vs-list / empty-error-loading / toolbar-filter / detail
conventions across the 8 pages (FLOW-02); (3) a decision-first approval drawer with plain-language
consequences, actions near the summary, progressive disclosure for raw payload/metadata, and no
duplicated decision copy (FLOW-03); (4) a decision-history surface making approved/denied/expired
approvals discoverable without implying in-place reversal (FLOW-04); (5) operator-first microcopy
that keeps IDs/payloads/traces/audit terms as evidence, not orientation (COPY-01).

This is a **page-flow adoption phase**. It composes and lightly extends the LOCKED Phase 36/37/38
primitive vocabulary (`page_section`, `eyebrow`, `object_header`, `empty_state`, `drawer`, `table`,
`overview_stats`, `raw_evidence`, `badge`, `button`, tones); it does **not** rebuild primitives,
add a page-scaffold framework, or invent new tone/size/state vocabularies.

**Out of scope (deferred — do NOT pull in):**
- Formal keyboard/focus-trap/restore proof, WCAG 2.2 AA sweep, motion/reduced-motion proof,
  responsive 320–1440 proof (`A11Y-01/02`, `MOTION-01`, `RESP-01`) → **Phase 40**. Build accessibly
  now (native `<details>`, labelled actions, status-not-color-only) but do not pull the sweep forward.
- Hardened drift guards, maintainer docs, screenshot proof, final gap register (`PROOF-01/02/03`)
  → **Phase 41**. This phase adds *lightweight* source-scan guards only.
- Changing core approval semantics to allow approving a denied request in place (`REQUIREMENTS.md`
  out-of-scope) — explicitly forbidden.
- Audit export/CSV, retention/TTL policy, per-field argument-diff history, denormalized
  `decided_by`/`decided_at` columns, cross-tenant history — future work.
- Any change to the public `scoria_dashboard/2` macro, Hex `package.files`, or `.scoria-root` scoping.

</domain>

<decisions>
## Implementation Decisions

Requirements FLOW-01..04 and COPY-01 and the five Phase 39 success criteria are the locked spec.
The decisions below resolve *how* to implement them.

### The Coherence Spine (read first — the whole phase hangs off this)

The five areas are one system, not five features. The spine:

1. A single thin **`page_header/1`** owns each page's one `<h1>` (Area 1) — every other area's copy
   and sections sit *below* it and never restate it.
2. **Guided conventions over the locked primitives** (Area 2), not a macro/CRUD framework — pages
   stay heterogeneous but assemble the same section order, and **all scan state lives in the URL**.
3. **One `drawer/1` in two states (pending vs decided)** is the bridge between the decision-first
   approval drawer (Area 3) and decision history (Area 4): decided approvals reuse the same drawer
   read-only, structurally unable to imply reversal.
4. **Decision history is a `Pending | Decided` URL segment on `/approvals`** (Area 4), reusing the
   same table/badge/drawer + URL-param idiom as the other scan pages (Area 2).
5. A **hybrid copy layer** (Area 5) — `status_label/1` map + narrow `ScoriaWeb.Copy` + per-domain
   copy modules only where copy branches on data — feeds operator-first strings into the headers
   (Area 1), scan columns (Area 2), drawer (Area 3), and history (Area 4).

Cross-cutting invariants for every decision below: **do not** change locked Phase 36/37/38 primitive
vocabulary; keep `ds06_drift_guard_test.exs` (raw-palette zero) and `token_contrast_guard_test.exs`
green; **no** new macro framework, **no** new Hex runtime dependency, **no** public-macro/`.scoria-root`
change; no fabricated data.

### Area 1 — Page-orientation scaffold (FLOW-01 · Criterion 1)

**Finding:** a page-head convention already ships as hand-rolled markup — `.scoria-pagehead*` CSS
(`04-components.css` ~1161) is copy-pasted across ~8 LiveViews, each emitting exactly one `<h1>`.
The work is to promote the convention into one thin component + a guard, not to invent a scaffold.

- **D-01:** Add one **thin `page_header/1` function component** to `ScoriaWeb.UI`: `attr :title`
  (renders the page's ONLY `<h1>`), `slot :summary` (one-line operator orientation `<p>`), `slot
  :action` (0..1 single primary action). Reuse the existing `.scoria-pagehead*` CSS — **no new
  tokens or classes**. This is the Scoria twin of Phoenix `core_components`' `<.header>`.
- **D-02:** **Reject** a monolithic `page/1` god-scaffold that owns the data region and
  empty/loading/error slots (un-idiomatic; fights the 8 heterogeneous pages; empty/error/loading
  belong to the *data region*, not the page) **and reject** a Backpex/LiveAdmin-style CRUD-config
  scaffold (makes pages mirror backend structure — the exact anti-goal). Keep **per-page composition**.
- **D-03:** **Single-header rule:** every page has exactly one orientation header — `page_header/1`
  for index/list pages, `object_header/1` for object/detail pages (e.g. workflow detail),
  `stub_page/1` for reserved-capability pages. **No raw `<h1>` in page bodies.**
- **D-04:** **Anti-redundant rule:** region headers (`page_section`/`panel` `:title`) render `<h2>`
  describing a *region* and must **not** restate the page `<h1>` text; single-region pages render
  the region flush/untitled. Concretely fixes `dataset_live/index.ex` (drop the redundant
  `<:title>Datasets</:title>` / `<:eyebrow>Dataset Builder</:eyebrow>` that restate the page title).
- **D-05:** **Guard:** a Phase-38-style source-scan test asserts per page LiveView — exactly one
  `<h1>`, emitted only via `page_header`/`object_header`/`stub_page`, and no region `:title` equal
  to the page `<h1>` text.

### Area 2 — Cross-page scan/section conventions (FLOW-02 · Criterion 2)

**Finding:** the scan `table/1` already owns `:filter`/`:action`/`:empty`/`:mobile_summary` + sort +
pagination. The inconsistency is: 3 section idioms, **2 filter-state idioms** (`dataset` uses
URL-params/`push_patch`+`handle_params`; `review_queue` holds filter in socket assigns → lost on
reconnect/back), ad-hoc empty states, and no page uses `stream/3`.

- **D-06:** Adopt a **guided convention over the locked primitives**, not a rigid macro framework
  (no Backpex/LiveAdmin/Kaffy CRUD-config) and not freeform. One canonical section order for every
  scan page: **page_header → optional `overview_stats` → toolbar → data region → per-item primary
  action.** `overview_stats` only when a count implies an action ("3 waiting your decision").
- **D-07:** **Table vs list vs board decision rule** — *table* when rows share a fixed comparable
  column set the operator scans/sorts (homogeneous); *list/card* when items are heterogeneous and
  the act is "open this one"; *board* when it's a status/urgency triage queue. **Frozen per-page
  map:** approvals = **board**, incidents = **list** (`selectable_card`), reviews/datasets/
  connectors/prompts/eval = **table**, workflow detail = **object/detail** (`object_header` + panels).
  Document *why* the incidents-list and approvals-board are correct so they stop reading as drift.
- **D-08:** **One canonical empty/error/loading per data region, rendered at the region** (never a
  page-level dead end): *empty* = `empty_state/1` with a helpful next action (via table `:empty`
  slot or the list container); *error* = inline `scoria-flash--fail` + a retry affordance, plain
  language, no stack trace as primary copy; *loading* = `skeleton/1` **only** for regions populated
  by an async assign (`start_async`) — most index pages render synchronously and need no spinner.
- **D-09:** **All scan state (filter/sort/scope) lives in the URL** via `push_patch` + `handle_params`
  (the `dataset_live` gold-standard) — **migrate `review_queue`'s socket-held filter to URL params.**
  Add a thin shared **toolbar convention** fixing placement (filter/search left, primary action
  right); the filter *fields* stay per-page. Shareable, reconnect-safe, back-button-friendly.
- **D-10:** **Adopt `Phoenix.LiveView.stream/3`** for the unbounded data regions (approvals,
  incidents; decided-approvals history). Resolve rows in `mount`/`handle_params`, never in the
  template (avoid N+1).
- **D-11:** **Guard:** a source-scan drift guard asserts scan pages follow the section order /
  primitives and that no page holds filter/sort state only in socket assigns.

### Area 3 — Approval drawer decision-first redesign (FLOW-03 · Criterion 3)

**Finding (verified in `approvals_live/index.ex`):** the drawer opens as an *alarm* (uppercase
letter-spaced warn banner "REVIEW BEFORE SCORIA CONTINUES THIS RUN", `.scoria-approval-summary__label`),
stacks **three** disclosure mechanisms (`evidence_rows` + a bespoke `.scoria-approval-details`
tech-grid + `raw_evidence` opened with `open={true}` = wall-of-JSON before deciding), and states the
decision sentence in **~6 places**.

- **D-12:** **Pending-drawer information hierarchy (decision-first), top→bottom:** (1) header eyebrow
  + title (`ApprovalCopy`); (2) **single** status badge; (3) plain-language **consequence** line
  (`ApprovalCopy.impact/1`); (4) **actions Deny · Approve, in reading flow** directly under the
  consequence; (5) always-visible "What you're approving" decision facts (`evidence_section` +
  `evidence_rows`); (6) **collapsed** raw payload + IDs (`raw_evidence` `open={false}`); (7) view-run
  link. Uses only locked primitives — **no change to `drawer/1`**.
- **D-13:** **De-alarm:** delete the uppercase warn banner (`.scoria-approval-summary__label`,
  `index.ex:147`). State status **once** via a `badge`; tone lives only in that badge. Brand §6.5:
  "tool approval is part of the workflow, not an alarm" — decision-first ≠ louder.
- **D-14:** **Progressive disclosure = native `<details>`/`<summary>` via existing `raw_evidence/1`
  with `open={false}`.** Two-tier evidence: decision-relevant facts always visible; raw JSON /
  approval-run-session IDs / trace / timestamps collapsed into **ONE** disclosure. **Delete the
  bespoke `.scoria-approval-details` tech-grid** and fold its IDs into that disclosure. **No tabs**
  (`notebook`) and no bespoke JS — native `<details>` is keyboard/screen-reader/reduced-motion safe
  with zero ARIA, which also minimizes Phase-40 a11y debt.
- **D-15:** **Actions open the EXISTING two-step confirm `modal`** (`open_decision_modal`) — keep it
  as the mis-click defense for consequential actions; **no** native `confirm()`, **no** auto-focus on
  Approve. Deny = `--danger` (left), Approve = `--primary` (right).
- **D-16:** **Copy dedup — `ApprovalCopy` is the SSOT.** Collapse the ~6 duplicate decision-status
  emissions to **one** canonical `ApprovalCopy.status_line/1` badge in the drawer header. Remove the
  drawer audit line (`index.ex:170-172`) — keep audit reassurance only in the confirm modal
  (`ApprovalCopy.decision_copy`). Trim the page-head subtitle to orientation only. Replace the
  generic "Approval request" eyebrow with tool context (`ApprovalCopy.eyebrow/1`). `impact/1` stays
  the single consequence source (already reused by the inbox row).

### Area 4 — Decision-history surface (FLOW-04 · Criterion 4 · RISK-APPROVAL-HISTORY)

**Finding (reported from code, not guessed):** `Scoria.Observe.Approval` (table `ai_approvals`)
already has terminal-complete statuses `~w(pending approved rejected expired)` — **no migration
needed.** Decision provenance (who/when/decision) already lives in `AuditOutboxEvent`
("approval.approved|rejected|expired", `actor_ref`, `inserted_at`); `updated_at` is de-facto
decided-at. `RemoteApprovalProjection.list_pending_approvals/1` hardcodes `where status=="pending"`;
`get_approval_lineage!/1` already hydrates **any** status; the tone map already covers terminality.

- **D-17:** **IA = single `/approvals` page with a `Pending | Decided` URL-param scope segment**
  (default **Pending** = actionable inbox), plus an outcome sub-filter (**All / Approved / Denied /
  Expired**) inside Decided via `table/1`'s `:filter` slot. **Reject** a separate `/approvals/history`
  route (two hops, coherence drift) and **reject** an inline "recently decided" section as the primary
  surface (violates the single-primary-path goal; older items undiscoverable). Precedent: GitHub PR
  Open/Closed, PagerDuty open/resolved, Stripe status filter.
- **D-18:** **Terminality rules (make decided items read-only & non-reversible):** no decision
  affordances anywhere in Decided scope (no Approve/Deny, no modal wiring); row action = **"View
  decision"**; badge tone map (approved → `:pass`, denied/expired → `:fail`); **past-tense agentful
  copy** — "Approved by {actor} · {time}", "Denied by {actor} · {time}", "Expired · {time}"; the
  decided column set swaps the "Waiting" elapsed column for **Decision (badge + who/when)**. A
  legitimate re-decision offers **"Start a new request"** routing to the origin run — **never** a
  re-approve of the old record.
- **D-19:** **Reuse the SAME `drawer/1` in a decided read-only receipt state** via a predicate
  `decided?(a) = a.status != "pending"`: render the action `<section>` + confirm modal **only when
  pending**; render a read-only receipt (`badge` + decider + time + resolved-tense consequence) when
  decided. **One component, two states** — the FLOW-03↔FLOW-04 bridge. Because the buttons/modal are
  simply not emitted, the UI **cannot** imply in-place reversal (mirrors the existing server guard
  `index.ex:354-360` `:not_pending`/`StaleEntryError`).
- **D-20:** **Data plan (keep logic in the context, not the LiveView):** add
  `Workflows.list_decided_approvals/1` (projection scope: `status in ["approved","rejected",
  "expired"]`, order `updated_at desc, id desc`, bounded — capped + load-more or `stream/3`); add
  `approval_decision_event/1` mirroring `approval_request_event/1` for decider identity (batch-load
  audit events for the visible id set to avoid N+1, or defer decider name to the drawer); reuse
  `get_approval_lineage!/1` to hydrate any status into the drawer. **Defer** denormalized
  `decided_by`/`decided_at` columns.
- **D-21:** **Fixture need:** seeds/lab today create only *pending* approvals. Decided fixtures
  (approved/rejected/expired with matching audit events) are required for an honest history surface —
  **no fabricated history in the UI.** Flag for the Phase 37 lab / seed data.

### Area 5 — Operator-first microcopy (COPY-01 · Criterion 5)

**Finding (load-bearing framing):** per `brandbook/brand-book.md` §1, Scoria's audience is
Phoenix/SRE engineers and its voice is "technical but humane — uses real terms (trace, span, scorer,
baseline, policy) and defines them." So operator-first does **not** mean sanitizing away technical
vocabulary.

- **D-22:** **Framing:** lead with the **job + consequence** using **real domain nouns** (trace,
  run, baseline, policy, connector — the brand word bank); demote **only** opaque identifiers, raw
  payloads, raw status atoms, and schema/module names to labelled evidence. Voice formula: **calm +
  exact + useful** (brand §6). Avoid the brand's banned words ("magic", "seamless", "Something went
  wrong", "Nothing here", etc.).
- **D-23:** **ID/payload/trace demotion rule:** a technical token may appear in *orientation*
  (title/subtitle/primary cell) only if it's a word-bank domain noun or a human-authored label;
  opaque IDs / schema field names / module names / raw status atoms render as *evidence* via
  `id/1` (+ "Copy <thing>" name, D-12 of Phase 38), `time/1`, `raw_evidence/1`, or labelled metadata
  rows. **Fix the 5 cited offenders:** `eval_spec_live/index.ex:71` title `Evaluation Rubrics
  (EvalSpecs)` → drop the module name; `prompt_live/index.ex:99,140` `entity_id` as title/column →
  human name + labelled ID evidence; `connectors_live/index.ex:82,85` `run_id`/`session_id` as
  primary cell → lead with status, IDs as evidence; `review_queue_live.ex:130` raw status atom →
  explicit label map; `dataset_live/index.ex:98` `.id` misused for a version → use a version label.
- **D-24:** **Mechanism = hybrid, scaled by justification** (NOT gettext — zero existing usage,
  single-locale devtool, hides copy from unit tests; NOT 7 cloned empty modules): (a) **upgrade
  `ScoriaWeb.UI.status_label/1`** from generic titlecase to an **explicit operator label allow-list**
  (fixes the status-atom leak everywhere at once); (b) add one **narrow `ScoriaWeb.Copy`** module
  owning the canonical **action-verb set + status-label map + thin empty/error/loading scaffolding
  helpers**; (c) add per-domain copy modules **only where copy branches on record data** —
  `IncidentCopy`, `DatasetCopy`, `ReviewCopy`, `ConnectorCopy` — with **`ApprovalCopy` as the
  template**, mirroring its orientation-rows vs evidence-rows split; (d) keep truly-static
  prompt/eval strings inline.
- **D-25:** **Canonical vocabulary** (lives in `ScoriaWeb.Copy`): action verbs — Approve/Deny,
  Promote/Add manually, Resolve/Open, Select/Review/Dismiss, Grant/Revoke, Open trace/Retry,
  Pin/Compare/Edit, Run/Compare; status labels — Pending, Approved, **Denied**, Expired, Passed,
  Failed, Regressed, Running, Promoted, Draft, Published, Connected, Disconnected, Idle. Use
  **"Denied"** in operator copy even though the schema value stays `"rejected"`. Status is never
  color-only (already enforced by `badge/1`).
- **D-26:** **Copy guard:** add `test/scoria_web/copy_guard_test.exs` (Phase-38 source-scan style),
  three cheap assertions over the LiveViews/components — (a) no schema/module names in headings;
  (b) no opaque IDs (`entity_id`/`*_run_id`/`*_session_id`) interpolated into `<h1>/<h2>/:title/
  :eyebrow`; (c) status renders only via `status_label/1` + `badge`. Warning-grade allow-list now;
  Phase 41 `PROOF-03` hardens it.

### Claude's Discretion

Downstream agents choose: exact new function/CSS/module names; whether the toolbar is a distinct
component or the existing `table` `:filter` slot; capped-recent + load-more vs `stream/3` for the
decided list; whether decider identity is batch-loaded per row or deferred to the drawer; the precise
per-domain copy-module boundaries; and test-file placement — as long as **D-01..D-26 and the
Coherence Spine hold**. Prefer boring, minimal additions over new abstraction layers. Do not expand
the tone/size/state vocabularies locked in Phases 36/37/38.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase & Milestone Scope
- `.planning/ROADMAP.md` — Phase 39 goal + 5 success criteria; Phase 40/41 boundaries (what is deferred).
- `.planning/REQUIREMENTS.md` — FLOW-01, FLOW-02, FLOW-03, FLOW-04, COPY-01 (and the out-of-scope line forbidding in-place reversal).
- `.planning/PROJECT.md` — v3.3 Design System Stress Test intent ("under-adopted, not under-built"; pages serve intent, not backend structure).
- `.planning/STATE.md` — current phase position and deferred items.
- `.planning/phases/36-baseline-and-inventory/36-CONTEXT.md` + `36-INVENTORY.md` + `36-inventory.json` — locked inventory, design-system, risk register (`RISK-APPROVAL-HISTORY` = Phase 39).
- `.planning/phases/37-dev-component-lab-and-stress-fixtures/37-CONTEXT.md` — Component Lab boundary, stress/ugly-data fixtures (the intended proof surface; decided-approval fixtures needed here, D-21).
- `.planning/phases/38-foundations-and-primitive-controls/38-CONTEXT.md` — the LOCKED primitive vocabulary this phase composes (page_section, eyebrow, object_header, empty_state, drawer, table, overview_stats, raw_evidence, badge, button, `:md/:sm` scale, copy-control accessible names).

### Brand & Token Source of Truth
- `brandbook/brand-book.md` — **canonical** voice/UI/microcopy (newer than the deep-research prompt; it WINS on conflict). §1 audience/personality, §2 empty/error/success states, §6 voice formula + say-this-not-this + word bank + "approval is not an alarm", §7/§9 status-not-color-only, §11.3 "never a magic score".
- `brandbook/tokens.json` / `brandbook/tokens.css` / `brandbook/README.md` — semantic token SSOT.

### Runtime UI, Pages, Copy, Data (the surface Phase 39 edits)
- `lib/scoria_web/ui.ex` — primitive vocabulary. Add `page_header/1` near `page_section/1` (~193); reuse `object_header/1` (~437), `stub_page/1` (~489), `table/1` (~1199, `:filter`/`:action`/`:empty`/`:mobile_summary` + sort + pagination), `drawer/1` (~704), `raw_evidence/1` (~1016), `evidence_section/1` (~1083), `evidence_rows/1` (~1115), `badge/1` (~68), `overview_stats/1` (~249), `empty_state/1` (~623), `skeleton/1` (~813), `time/1` (~304), `id/1` (~276); **upgrade `status_label/1` (~52) to an explicit label map**; tone map (~23).
- `assets/css/04-components.css` — existing `.scoria-pagehead*` (~1161, reuse for `page_header`); `.scoria-approval-*` incl. `.scoria-approval-summary__label` (~841-857, delete) and `.scoria-approval-details` (~886-943, delete/fold).
- `lib/scoria_web/approval_copy.ex` — the copy SSOT template; extend with `status_line/1`, `eyebrow/1`, decided-state helpers (`decision_outcome/1`, `decided_by/1`, `decided_receipt/1`).
- `lib/scoria_web/live/approvals_live/index.ex` — inbox + drawer + approve/reject + `open_decision_modal` + `:not_pending`/`StaleEntryError` guard (~354-360); `approval_request_event/1` (~341, mirror as `approval_decision_event/1`).
- `lib/scoria_web/components/approval_inbox_component.ex` — inbox row (reuses `ApprovalCopy`).
- `lib/scoria/observe/approval.ex` — schema + terminal statuses `~w(pending approved rejected expired)` (no migration needed).
- `lib/scoria/workflows.ex` (`approve/3` ~662, drops decider identity → provenance in audit outbox) + `lib/scoria/workflows/remote_approval_projection.ex` (`list_pending_approvals/1` hardcodes pending; `get_approval_lineage!/1` hydrates any status) — add `list_decided_approvals/1`.
- Scan pages to normalize: `lib/scoria_web/live/dataset_live/index.ex` (gold-standard URL sort; redundant header to fix), `review_queue_live.ex` (socket-held filter → URL params), `incidents_live/index.ex` (list) + `show.ex`, `connectors_live/index.ex`, `prompt_live/index.ex`, `eval_spec_live/index.ex`, `workflow_live/index.ex` + `show.ex`.

### Tests / Guards (must stay green; add lightweight new guards)
- `test/scoria_web/ds06_drift_guard_test.exs` — raw-palette zero-drift (keep green).
- `test/scoria_web/token_contrast_guard_test.exs` — token contrast (keep green).
- `test/scoria_web/ui_component_test.exs` + the Phase-38 source-scan coherence guards — the style to model the new single-header (D-05), scan-convention (D-11), and copy (D-26) guards on.
- `dev/` lab routes + `priv/dev/e2e/` — deterministic browser proof surface to reuse.

### External Precedent (idiom + lessons)
- Phoenix `core_components.ex` `<.header>` — the thin-header idiom `page_header/1` mirrors.
- Phoenix LiveDashboard, Oban Web — URL-param filters (`push_patch`/`handle_params`) + `stream/3` + status facets; the guided-convention precedent.
- Backpex / LiveAdmin / Kaffy — CRUD-config scaffolds; the anti-pattern to AVOID (pages mirror schema).
- GitHub PR review / merge box, Vercel deploy approvals, PagerDuty, Argo CD, Stripe — HITL decision-first + open/closed history precedents.
- `https://www.w3.org/WAI/WCAG22/Understanding/` — build-accessibly intent (full sweep is Phase 40).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`table/1` already owns** `:filter`/`:action`/`:empty`/`:mobile_summary` slots + `on_sort`/`sort_by`/`sort_dir` + `on_page_change` — the canonical scan table exists; Area 2 is convention, not new primitives.
- **`.scoria-pagehead*` CSS already exists** — `page_header/1` (D-01) is a rename of copy-pasted markup, zero new CSS.
- **`drawer/1` + `evidence_section`/`evidence_rows` + `raw_evidence` (native `<details>`)** already support the decision-first hierarchy (D-12/D-14) with no `drawer/1` change.
- **`ApprovalCopy` already splits orientation-rows vs evidence-rows** (`request_rows` vs `evidence_rows`, ~178-235) — the template to generalize (D-24) and the SSOT for dedup (D-16).
- **Approval schema statuses are terminal-complete** and `get_approval_lineage!/1` already hydrates any status — decision history (Area 4) needs a query scope, not a migration.
- **`dataset_live` is the URL-param gold standard**; the tone map already covers terminality.

### Established Patterns
- Token-first CSS scoped through `.scoria-root`; raw-palette drift is a guarded verified zero (DS-06) — must stay zero.
- `attr`/`slot` function components are the reusable primitive shape; small-composable, not god-components.
- Phase-38 delivered **source-scan drift guards** — the enforcement pattern to reuse for D-05/D-11/D-26.
- Two-tier `:md/:sm` control scale, opaque toasts, converged `overview_stats/1` — all from Phase 38, reuse as-is.

### Integration Points
- Add `page_header/1` + upgrade `status_label/1` in `lib/scoria_web/ui.ex`; reuse `.scoria-pagehead*`, delete `.scoria-approval-summary__label` + `.scoria-approval-details` in `04-components.css`.
- Extend `ApprovalCopy`; add `ScoriaWeb.Copy` + `Incident/Dataset/Review/Connector` copy modules.
- Add `Workflows.list_decided_approvals/1` + `approval_decision_event/1` in the workflows context/projection (not the LiveView).
- Migrate `review_queue` filter to URL params; adopt `stream/3` for approvals/incidents/decided lists.
- New source-scan guards alongside `ds06_drift_guard_test.exs`; prove flows against `dev/` lab + `priv/dev/e2e/`.

</code_context>

<specifics>
## Specific Ideas

- **The 6-place decision-copy duplication** (D-16) is the concrete FLOW-03 "no duplicated decision
  copy" target: page-head subtitle, drawer eyebrow "Approval request", uppercase `__label` banner,
  drawer `__audit` line, confirm-modal `decision_copy` (keep), reject toast (keep). Collapse to one
  `status_line/1` badge + one `impact/1` consequence + audit reassurance only at point-of-action.
- **The 5 microcopy offenders** (D-23) are the concrete COPY-01 targets: `eval_spec (EvalSpecs)`,
  `prompt entity_id`, `connectors run_id/session_id`, `review raw status atom`, `dataset .id-for-version`.
- **The `dataset_live` redundant header** (D-04) is the concrete FLOW-01 "redundant single-region
  header" target.
- **Decision-history segmentation** = `Pending | Decided` (not 4 top-level tabs); outcome is a
  sub-filter *of* Decided.
- **"Denied" in copy, `"rejected"` in schema** — keep the operator/schema split (D-25).

</specifics>

<deferred>
## Deferred Ideas

- Formal keyboard/focus-trap/restore proof, WCAG 2.2 AA sweep, motion/reduced-motion proof, responsive 320–1440 proof — **Phase 40**.
- Hardened drift guards, maintainer convention docs (BEM/tokens/headers/copy/etc.), screenshot proof, final gap register — **Phase 41**.
- Changing approval semantics to allow in-place approval of a denied request — **explicitly out of scope (forbidden)**.
- Denormalized `decided_by`/`decided_at` columns on approvals (only if drawer audit-lookup perf later demands) — future.
- Audit export/CSV, retention/TTL policy, per-field argument-diff history, full-text history search, cross-tenant history, re-open/appeal workflow — future.
- gettext / i18n message catalog — deferred until a real localization requirement appears.
- PhoenixStorybook adoption (`STORYBOOK-01`), screenshot-diff CI (`VISUAL-CI-01`) — deferred/later.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 39-Component Groups And Operator Flows*
*Context gathered: 2026-07-02*
