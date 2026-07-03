# Phase 39: Component Groups And Operator Flows - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

> **Research-backed + red-team-hardened, one-shot decisions.** All five gray areas were first
> resolved through five parallel deep-research passes (idiom + lessons-from-other-libs + UI/UX/JTBD
> + brand + a11y/perf lenses), then **adversarially red-teamed** by five more agents whose only job
> was to find where those decisions were wrong against the actual code. The red-team pass produced
> material deltas — the decisions below are the **hardened** locked spec. Each is a concrete choice
> a downstream agent can act on without re-asking the user. See **The Coherence Spine** first, it is
> load-bearing. Decisions that changed in the red-team pass are marked **(revised)**; safety-critical
> ones are marked **⚠ SAFETY**.

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
add a page-scaffold framework, or invent new tone/size/state vocabularies. **There is no `board`
primitive** — urgency/triage is expressed as table columns + badges + filter facets, never swimlanes.

**Out of scope (deferred — do NOT pull in):**
- Formal keyboard/focus-trap/restore proof, WCAG 2.2 AA sweep, motion/reduced-motion proof,
  responsive 320–1440 proof (`A11Y-01/02`, `MOTION-01`, `RESP-01`) → **Phase 40**. Build accessibly
  now (native `<details>`, labelled actions, status-not-color-only) but do not pull the sweep forward.
- Hardened drift guards, maintainer docs, screenshot proof, final gap register (`PROOF-01/02/03`)
  → **Phase 41**. This phase adds *lightweight, warning-grade* source-scan guards only.
- Changing core approval semantics to allow approving a denied request in place (`REQUIREMENTS.md`
  out-of-scope) — explicitly forbidden.
- Building a production expiry producer (TTL sweeper/Oban worker) — out of scope; Phase 39 only
  renders the `expired` outcome honestly if/when rows exist (see D-21).
- Audit export/CSV, retention/TTL policy, per-field argument-diff history, cross-tenant history.
- Any change to the public `scoria_dashboard/2` macro, Hex `package.files`, or `.scoria-root` scoping.

</domain>

<decisions>
## Implementation Decisions

Requirements FLOW-01..04 and COPY-01 and the five Phase 39 success criteria are the locked spec.
The decisions below resolve *how* to implement them.

### The Coherence Spine (read first — the whole phase hangs off this)

The five areas are one system, not five features. The spine (as hardened by the red-team pass):

1. A single thin **`page_header/1`** owns each page's one page-outline `<h1>` (Area 1). The app
   shell renders `page_title` only in `<span>`s (verified — `layouts/app.html.heex`), so the page
   `<h1>` genuinely is the document's only one; dialog-scoped headings (drawer/modal/palette) are
   exempt. Every other area sits *below* the header and never restates it.
2. **Guided conventions over the locked primitives** (Area 2), not a macro/CRUD framework. Every
   scan page assembles the same section order; **shareable state** (filters, scope, selection) lives
   in the URL, **ephemeral UI state** (open toggles, toasts, live-highlight) stays in assigns.
3. **Approvals is a `table/1`, both Pending and Decided** (Area 2 + 4). One `table/1` with the
   `Waiting` column swapped for a `Decision` column and an outcome filter *is* the history surface —
   no board, no second idiom, no second page.
4. **One `drawer/1` in two states (pending vs decided)** is the bridge between the decision-first
   approval drawer (Area 3) and decision history (Area 4). Decided approvals reuse the same drawer
   read-only; the action region is simply **not emitted** when decided, so the UI is structurally
   unable to imply reversal. **The decided receipt asserts only the recorded decision — never that
   the tool side-effect or run continuation succeeded** (⚠ SAFETY, D-27).
5. A **hybrid copy layer** (Area 5) — an **additive** `status_label/1` (curated clauses above a
   retained generic fallback, never a closed set), a strings-only `ScoriaWeb.Copy`, and per-domain
   copy modules only where copy branches on data — feeds operator-first strings into headers (Area 1),
   scan columns (Area 2), drawer (Area 3), and history (Area 4).

Cross-cutting invariants: **do not** change locked Phase 36/37/38 primitive vocabulary (no `board`,
no `table/1` internals change unless an explicit guarded upgrade is scoped); keep
`ds06_drift_guard_test.exs` (raw-palette zero) and `token_contrast_guard_test.exs` green; **no** new
macro framework, **no** new Hex runtime dependency, **no** public-macro/`.scoria-root` change; no
fabricated data; new guards are warning-grade this phase (Phase 41 hardens).

### Area 1 — Page-orientation scaffold (FLOW-01 · Criterion 1)

**Finding:** a page-head convention already ships as hand-rolled `.scoria-pagehead*` markup
(`04-components.css` ~1161), copy-pasted across the 8 index pages + `orchestrator_live` Home. The
shell emits **no** competing `<h1>` (verified: `layouts/app.html.heex` renders `page_title` only in
`<span>`s; `root.html.heex` sets `<.live_title>` = `<title>`, not a heading). The work is to promote
the convention into one thin component + a guard.

- **D-01 (revised):** Add one **thin `page_header/1`** to `ScoriaWeb.UI`: `attr :title` — a plain
  string that renders the page's ONLY `<h1>` (kept as an attr, **not** a slot, so IDs/module-names
  structurally cannot leak into the `<h1>`, mechanically enforcing D-23/D-26); `slot :summary`
  (one-line operator orientation `<p>`); `slot :actions` (**0..1 header action — a primary action
  *or* a ghost/secondary nav link**, e.g. `review_queue`'s existing "Back to dashboard" ghost link).
  Reuse `.scoria-pagehead*` incl. the existing `.scoria-pagehead__title--with-actions` modifier — **no
  new tokens/classes**. Mirrors Phoenix `core_components`' `<.header>` (slot likewise named `:actions`),
  diverging deliberately on `attr :title` and a single-action convention for the brand's single-path goal.
- **D-02:** **Reject** a monolithic `page/1` god-scaffold (owns data region + empty/loading/error;
  un-idiomatic; fights the 8 heterogeneous pages) **and reject** a Backpex/LiveAdmin CRUD-config
  scaffold (pages mirror backend structure — the anti-goal). Keep **per-page composition** of function
  components. **Gap owned here:** empty/loading/error live at the *data region* (D-08), but a **page-level
  error / not-found** state (a real 404, e.g. `coming_soon_live` "capability not found", or a detail
  page whose object is missing) is not a data-region `empty_state` — it gets a sanctioned page-level
  header (D-03) + `empty_state`-style body, never forced into a table `:empty` slot.
- **D-03 (revised):** **Single-header rule:** every page has exactly one **page-outline** orientation
  header — `page_header/1` (index/list), `object_header/1` (object/detail), `stub_page/1` (reserved
  capability), **and a page-level not-found header** for the "capability/object not found" state
  (currently hand-rolled at `coming_soon_live.ex:40` with a bespoke `<h1>` nested in a redundant
  `.scoria-pagehead` div — reconcile into a sanctioned path, do not leave a bare `<h1>`). **Headings
  inside dialog subtrees (drawer/modal/command-palette/notebook, all `role="dialog"`) are exempt** —
  they form their own a11y subtree and are not page-outline competitors. No raw `<h1>` in page bodies
  outside these sanctioned headers. **Precondition:** migrate the 8 index pages + `orchestrator_live`
  Home off hand-rolled `.scoria-pagehead` markup **in the same plan** as the D-05 guard, or the guard
  is red on arrival.
- **D-04 (revised):** **Anti-redundant rule:** region headers (`page_section`/`panel` `:title`) render
  `<h2>` naming a *region* and must **not restate the page** — including the **semantic** case where a
  single-region page's `<h1>` already implies the region (`dataset_live` `<h1>`"Dataset Builder" +
  region `<:title>`"Datasets" are not string-equal but are semantically redundant → drop the region
  title, render flush/untitled). Because the judgment is semantic, its enforcement is human-reviewed /
  warning-grade, not hard string-equality (see D-05).
- **D-05 (revised):** **Guard** (Phase-38 source-scan style — `File.read!` + regex per
  `ui_drift_guard_test.exs`), scoped to **page LiveViews only, excluding `lib/scoria_web/ui.ex` and
  dialog-scoped component files**: (a) assert **exactly one `<h1>` literal** per page module; (b)
  assert it is emitted inside a sanctioned header. The "region `:title` ≠ page `<h1>`" check is
  **warning-grade over static string literals only** (dynamic/interpolated titles are unverifiable by
  source-scan, and the semantic case per D-04 is not a string match); the true rendered-DOM assertion
  is promoted to a `LiveViewTest` render in Phase-41 `PROOF-03`.

### Area 2 — Cross-page scan/section conventions (FLOW-02 · Criterion 2)

**Finding:** `table/1` already owns `:filter`/`:action`/`:empty`/`:mobile_summary` + sort +
pagination. **Approvals is already a `table/1`** (`approval_inbox_component.ex:16`), not a board.
The real inconsistency is: `review_queue` holds its filter in **socket assigns** (lost on
reconnect/back) while other pages URL-encode deep-link/selection state; ad-hoc empty states; no page
uses `stream/3`. **Correction:** sort is implemented everywhere via `table/1`'s `phx-click`
`on_sort` → a `handle_event` that reassigns socket state (incl. `dataset_live` — it is **not** a
URL-sort exemplar; it URL-encodes the *promotion drawer / selection*, not sort).

- **D-06:** Adopt a **guided convention over the locked primitives**, not a rigid macro framework
  and not freeform. One canonical section order for every scan page: **page_header → optional
  `overview_stats` → toolbar → data region → per-item primary action** (`overview_stats` only when a
  count implies an action). **`board` is excluded** — no board primitive exists; triage urgency is
  table columns/badges + filter facets, not swimlanes.
- **D-07 (revised):** **Table vs list decision rule** — *table* when rows share a fixed comparable
  column set the operator scans/sorts (homogeneous); *list/card* when items are heterogeneous and the
  act is "open this one." **Frozen per-page map:** **approvals = table** (pending rows are maximally
  homogeneous — one status, fixed columns, one Approve/Deny action; already implemented as `table/1`);
  incidents = **list** (`selectable_card`, newest-first, "open the pressing one"); reviews / datasets /
  connectors / prompts / eval = **table**; workflow detail = **object/detail** (`object_header` +
  panels). Document *why* incidents-as-list is correct (JTBD) so it doesn't read as drift; note a
  revisit-to-table-with-facets trigger if per-tenant incident volume grows large. **Approvals Pending
  and Decided are the SAME `table/1`** (swap `Waiting`→`Decision` column, add the outcome filter) —
  this IS the Area-4 bridge and keeps `/approvals` to one scan idiom.
- **D-08 (revised):** **One canonical empty/error/loading per data region, rendered at the region:**
  *empty* = `empty_state/1` with a next action (table `:empty` slot or list container); *error* =
  inline `scoria-flash--fail` + retry, plain language; *loading* = `skeleton/1` **only** for
  async-assigned regions — every index queries **synchronously in mount** today, so first paint shows
  real data and needs no spinner (CONFIRMED). **Upgrade trigger:** if a mount query becomes slow, move
  it to `start_async` + `skeleton/1` rather than blocking mount. **Page-level error/not-found** (D-02)
  is a page-level state, never a data-region `empty_state`.
- **D-09 (revised):** **Shareable scan state lives in the URL** via `push_patch`+`handle_params` —
  filter facets (enum only), the `Pending|Decided` scope segment, the outcome sub-filter, **and the
  deep-link selection `?approval=<id>` that opens the drawer** (today `@active_approval` is socket-only
  and not deep-linkable/reconnect-safe — fix it). **Ephemeral UI state stays in assigns:** the
  two-step confirm-modal toggle, the `toasts` list, and the PubSub live-highlight id. **Sort policy —
  choose one and make the D-11 guard match:** **(A, recommended, matches LiveDashboard/Oban Web)**
  migrate sort to the URL by having `table/1`'s `on_sort` emit `push_patch`; scope expands to
  `dataset_live` + every `on_sort` table. **(B)** keep sort in assigns as a per-session view pref and
  **exclude sort from the guard.** Either way, migrate `review_queue`'s socket-held **filter** to URL
  params. Free-text filters must **debounce** before `push_patch`; never place record payloads in the
  URL.
- **D-10 (revised):** Apply `stream/3` **only where it fits, with no `table/1` change:** (1) the
  **incidents `<ul>`** — caller-owned markup, no PubSub, mount-only load → add `phx-update="stream"` +
  per-`<li>` id, zero primitive change; (2) **decided-approvals history** — prefer **capped +
  "load more"** (the locked `table/1` detects empty via `@rows == []` and has no `phx-update="stream"`
  / per-row id, so streaming it would force a primitive change), or scope an explicit guarded `table/1`
  stream-support upgrade. **Do NOT stream the pending approvals inbox:** it is PubSub-reload driven
  (`index.ex:59-83,253-259`) with three assign-based `Enum.find` lookups (`:101-106`, `:273-281`,
  focus-match) that streams break, and a pending queue is self-bounding (deciding clears the row).
- **D-11 (revised):** **Guard** asserts scan pages follow the section order/primitives and that
  **filter/scope state** is not held only in socket assigns (migration target: `review_queue`). **Sort**
  is guarded only under D-09 option (A); under (B) sort is explicitly exempt. The guard must **not**
  red-flag `dataset_live` under whichever sort policy is locked. Warning-grade allow-list now; Phase-41
  hardens. **Toolbar is a convention, not a component** — realized via the `table/1` `:filter` slot on
  table pages and a plain flex row on the incidents list (building a toolbar component to serve one
  list page would manufacture the two-ways-to-do-one-thing drift this milestone fights).

### Area 3 — Approval drawer decision-first redesign (FLOW-03 · Criterion 3)

**Finding (verified):** the drawer opens as an alarm (uppercase letter-spaced warn banner
`.scoria-approval-summary__label`), the action bar is `position:sticky;top:0` with a warn gradient
*above* the consequence, it stacks three disclosures (`evidence_rows` + bespoke
`.scoria-approval-details` tech-grid + `raw_evidence` `open={true}` = wall-of-JSON), and the decision
sentence appears in ~6 places.

- **D-12 (revised):** **Pending-drawer information hierarchy (decision-first), top→bottom:** (1)
  header eyebrow + title (`ApprovalCopy`); (2) **single** status badge; (3) plain-language
  **consequence** (`ApprovalCopy.impact/1`); (4) **actions Deny · Approve, in reading flow** directly
  under the consequence; (5) always-visible "What you're approving" facts (`evidence_section` +
  `evidence_rows`); (6) **collapsed** disclosures (D-14); (7) view-run link. **Strip the existing
  sticky-top `.scoria-approval-actions`** (`04-components.css:865-877`; `position:sticky;top:0` +
  gradient — the alarm-adjacent pattern the redesign rejects). With the payload collapsed on open,
  actions sit ~4 short lines down = above the fold, no scroll-to-decide. **Recommended:** make the
  action bar `position:sticky;bottom:0` (a sticky *footer*, GitHub-merge-box style — distinct from the
  rejected sticky-top, feasible without touching `drawer/1`) so the decision stays reachable after the
  operator deliberately expands the payload.
- **D-13:** **De-alarm:** delete the uppercase warn banner (`.scoria-approval-summary__label`,
  `index.ex:147`). State status **once** via a `badge`. **Salience moves into the exact-magnitude
  consequence line + the confirm gate, not red chrome** (brand §6.5: "approval is part of the
  workflow, not an alarm"). Scale weight by the concrete number in copy (e.g. "$10,000.00 refund"),
  not by alarm styling — this also answers tone-by-consequence without new vocabulary.
- **D-14 (revised):** **Progressive disclosure = native `<details>`/`<summary>`** (keyboard/SR/
  reduced-motion safe, zero ARIA, minimizes Phase-40 debt), but **two** collapsed disclosures, not
  one: **(i) "Identifiers"** — `approval id` / `run id` / `session id` / `trace id` / requested-at via
  `id/1` (+ copy affordance) + `time/1` (generic classes, no bespoke CSS); **(ii) "Request payload"**
  — the JSON via `raw_evidence/1` `open={false}`. Rationale: `raw_evidence` renders a single `<pre>`
  and **cannot** host the copyable `id/1` rows — folding IDs into the JSON `pre` would destroy the
  "Copy run id / trace id" log-grep affordance (a Phase-38 copy control). **Delete the bespoke
  `.scoria-approval-details` tech-grid** as planned. **Open-state-loss trap:** the drawer receives live
  PubSub; an *unrelated* broadcast reloads `@approval_inbox` but not `@active_approval`, so
  change-tracking leaves the open `<details>` intact — **but** any reassignment of `@active_approval`
  while the drawer is open (the focused-runtime auto-seed path, or a future "live decided receipt")
  will collapse it. Mitigate with a **stable per-approval DOM id** (`id={"approval-raw-#{@active_approval.id}"}`)
  so a *different* approval always mounts a fresh correctly-collapsed node, plus a `LiveViewTest`
  regression asserting an unrelated `{:hitl_request}` leaves the open state intact. (`phx-update="ignore"`
  is **not** a reliable fix — it can't protect the container's own `open` attr.)
- **D-15 (revised):** **Keep the two-step confirm `modal` for BOTH approve and deny** (asymmetric
  confirm would falsely signal "approve is the safe one" when approve is the irreversible side-effect)
  and **keep no-auto-focus on the action** (the modal's X carries `autofocus`, so initial focus lands
  on dismiss — the correct safe default). **But make the modal earn its friction:** replace the
  restate-the-title `decision_copy("approve", …)` with the **concrete irreversible effect + magnitude**
  (reuse `impact/1`'s lead clause, e.g. "This issues a $10,000.00 refund to cust_889. Scoria records
  the decision, then continues the run.") — a bare restate trains a rubber-stamp reflex. **Reconsider
  Deny = `--danger` (red):** denying is the *safe, reversible hold* (the run stays waiting); Approve is
  the irreversible action — coloring Deny red inverts the risk gradient. Render **Deny as
  secondary/neutral** and let the Approve confirm modal carry the "irreversible" weight; if the locked
  tone vocabulary can't express a middle tone this phase, at minimum document the rationale so red-on-
  deny isn't mistaken for a considered signal.
- **D-16 (revised):** **Copy dedup — `ApprovalCopy` is the SSOT.** Collapse the ~6 duplicate
  decision-status emissions to **one** canonical `ApprovalCopy.status_line/1` badge in the drawer
  header. Remove the drawer audit line (`index.ex:170-172`) — keep audit reassurance only in the
  confirm modal (necessary point-of-commit redundancy, not harmful duplication). Trim the page-head
  subtitle to orientation only; replace the generic "Approval request" eyebrow with tool context
  (`ApprovalCopy.eyebrow/1`); `impact/1` stays the single consequence source. **Also delete the raw
  status-atom row** `{"Status", field(approval, :status)}` in `ApprovalCopy.evidence_rows/1`
  (`approval_copy.ex:215`) — it duplicates the badge and leaks a raw atom (violates D-23/D-25).
- **D-27 (new · ⚠ SAFETY):** **The decided receipt asserts only the *recorded decision*, never the
  side-effect or run continuation.** `Workflows.approve/3` sets `status="approved"` and *then* runs
  `maybe_resume_approval/3`; if resume fails (`index.ex:319-327`) the row is **already** `approved`.
  A naive "Approved by {actor} · {time}" receipt would present a stuck/failed run as a clean success —
  a real mis-decision vector on a refund surface. The receipt copy states the decision only and links
  to the run (`workflow_run_id`) for execution truth; optionally surface run/execution state from the
  run record (`executed_live`) if cheap. Applies to the decided-drawer state (Area 4, D-19) and the
  history row.

### Area 4 — Decision-history surface (FLOW-04 · Criterion 4 · RISK-APPROVAL-HISTORY)

**Finding (reported from code):** `Scoria.Observe.Approval` has terminal-complete statuses
`~w(pending approved rejected expired)` — **no status/column migration needed for approved/rejected.**
Decision provenance (decider + time) is written **transactionally** into an `AuditOutboxEvent`
(`approval.<status>`, `actor_ref`, `inserted_at`) in the same `Repo.transaction` as the decision, so
attribution is reliable (no eventual-consistency gap) for approve/deny. **Two real hazards surfaced:**
`updated_at`-as-decided-at is safe today only *by accident* (the decision path is guarded and nothing
re-writes a decided row — but that invariant is unguarded), and **`expired` is broken** (no production
producer; seeds use `update_all` which neither bumps `updated_at` nor emits an audit event).

- **D-17:** **IA = single `/approvals` page with a `Pending | Decided` URL-param scope segment**
  (default **Pending**), plus an outcome sub-filter (**All / Approved / Denied / Expired**) inside
  Decided via `table/1`'s `:filter` slot. **Reject** a separate route and inline-recent-as-primary.
  Because approvals is a `table/1` in **both** scopes (D-07), the segment is a true same-primitive
  filter (matching the GitHub Open/Closed, Stripe, PagerDuty precedents), **not** a board→table mode
  switch; the row→drawer gesture is identical in both scopes.
- **D-18 (revised):** **Terminality rules:** no decision affordances in Decided scope (no Approve/Deny,
  no modal wiring); row action = **"View decision"**; badge tone map (approved → `:pass`, denied/
  expired → `:fail`, already in `ui.ex`); the decided column set swaps `Waiting` for **Decision (badge
  + who/when)**. **Past-tense agentful copy** — "Approved by {actor} · {time}", "Denied by {actor} ·
  {time}". **`Expired` renders WITHOUT a fabricated `· {time}` or actor** unless a real
  `approval.expired` audit event exists (seed/lazy expiry has neither — see D-21). A legitimate
  re-decision offers **"Start a new request"** routing to the origin run — never a re-approve.
- **D-19 (revised):** **Reuse the SAME `drawer/1` in a decided read-only receipt state.** Use a
  **positive/whitelist predicate** `decided?(%{status: s}), do: s in ~w(approved rejected expired)` —
  matching `list_decided_approvals/1` (D-20) and failing safe (a future non-terminal status like
  `cancelled` won't auto-render as a misleading receipt). Render the action `<section>` + confirm modal
  only when **pending**; render the read-only receipt only for the terminal set. Structurally cannot
  imply reversal (buttons not emitted, mirrors the server guard `index.ex:354-360`). Receipt copy per
  D-27.
- **D-20 (revised):** **Data plan — decided-at/decider SSOT is the audit event, not `updated_at`.**
  Add `Workflows.list_decided_approvals/1` (context/projection scope: `status in ["approved","rejected",
  "expired"]`, `order_by: [desc: :updated_at, desc: :id]` as a cheap query-level proxy sort only,
  bounded — capped + load-more per D-10). For the **displayed** decided-at and decider, source from the
  **decision `AuditOutboxEvent`** (`inserted_at`, `actor_ref`) — the append-only immutable record —
  via a new `approval_decision_event/1` mirroring `approval_request_event/1` (`index.ex:341`);
  **batch-load** by the visible id-set to avoid N+1. Note `get_approval_lineage!/1` hydrates any status
  into the drawer but exposes the *requesting* actor, not the decider — the drawer receipt must read
  decider from the decision event. Missing event → render **"Decided · time unavailable"**, never
  "unknown". **Defer** denormalized `decided_by`/`decided_at` columns. **Guard the invariant:** add a
  source-scan assertion (or a `@doc` contract on `approve/3`) that no runtime path writes an approval
  row after it leaves `pending` — decided-at integrity depends on it, and the codebase already contains
  the fragile shape (a second `Approval.changeset |> update!` at creation; `update_all` in seeds).
- **D-21 (revised):** **Fixtures must route decided/expired rows through `approve(id, <status>)`**, NOT
  `Repo.update_all(set: [status: …])` — only the real path emits the audit event and bumps `updated_at`,
  so only it exercises the real history surface (decider + time). Until a production expiry producer
  exists, either seed `expired` via `approve(id,"expired")` or render `Expired` with no time/actor and
  consider gating the Expired sub-filter behind "has any expired row with an audit event." **No
  fabricated history in the UI.** Flag the decided/expired fixtures for the Phase 37 lab / seed data.

### Area 5 — Operator-first microcopy (COPY-01 · Criterion 5)

**Finding (load-bearing framing):** per `brandbook/brand-book.md` §1/§6, Scoria's audience is
Phoenix/SRE engineers and its voice keeps real domain nouns (trace, span, run, baseline, policy,
connector) and defines them. Operator-first ≠ sanitizing technical vocabulary.

- **D-22:** **Framing:** lead with **job + consequence** using **real domain nouns**; demote **only**
  opaque identifiers, raw payloads, raw status atoms, and schema/module names to labelled evidence.
  Voice: **calm + exact + useful** (§6); avoid the banned words ("magic", "seamless", "Nothing here").
- **D-23 (revised):** **Demotion rule:** a technical token appears in *orientation* only if it's a
  word-bank domain noun or human label; opaque IDs / schema field names / module names / raw status
  atoms render as *evidence* via `id/1` (+ "Copy <thing>"), `time/1`, `raw_evidence/1`, or labelled
  metadata rows. **Fix the offenders:** `eval_spec_live/index.ex:71` `(EvalSpecs)` in the title →
  drop the module name; `prompt_live/index.ex:99,140` `entity_id` as title/column → human name +
  labelled ID evidence; `connectors_live/index.ex:82,85` `run_id`/`session_id` as primary cell → lead
  with status, IDs as evidence; **`connectors_live/index.ex:79` `label={runtime.status}` raw status
  string → route through `status_label/1` + badge** (6th offender caught in red-team);
  `review_queue_live.ex:130` raw status atom → label map; `dataset_live/index.ex:98` `.id` misused for
  a version → version label.
- **D-24 (revised):** **Mechanism = hybrid, scaled by justification** (NOT gettext; NOT 7 cloned
  modules):
  (a) **Upgrade `ScoriaWeb.UI.status_label/1` ADDITIVELY** — add curated operator-label clauses
  **above the retained generic fallback** (`String.replace("_"," ") |> capitalize` binary clause +
  `status_label(_) -> "Unknown"`). ⚠ It must **never** become a closed allow-list: `status_label/1`
  is the atom fallback inside `evidence_text/1` (`ui.ex:1376`) and is called across ≥6 disjoint
  domains (approval, eval pass/fail/regressed, severity low/…/critical, run, prompt, promotion, object
  header) — a closed set raises `FunctionClauseError` inside `render/1` and **500s the page** on any
  unseen status. Do **not** curate `"rejected"` here (see (d)).
  (b) Add one **narrow `ScoriaWeb.Copy`** returning **strings/keyword data only — zero `~H`, renders
  nothing** — owning the canonical action-verb set, the status-label map, and empty/error/loading copy
  *strings* (`empty_title/1`, `empty_cta/1`, `error_line/1`, `loading_label/1`). `UI.empty_state/1`/
  `skeleton/1` stay the renderers and receive those strings (hard line: `Copy` = data, `UI` = render).
  (c) Add per-domain copy modules **only where copy branches on record data** (a `case/cond` on
  `tool_name`/`status`/`kind`, or reuse across inbox+drawer+row) — realistically `IncidentCopy`,
  `DatasetCopy`, `ReviewCopy`, `ConnectorCopy` — with **`ApprovalCopy` as the template**. Static
  prompt/eval strings stay inline; the D-26 guard prevents branching domains from inlining.
  (d) **"Denied" lives in the approval domain (`ApprovalCopy`), not the global map** — the global
  `status_label/1` titlecases `"rejected" → "Rejected"`; the operator word "Denied" is produced only by
  `ApprovalCopy` (`decision_outcome/1`), reused by the drawer status line (D-16) and the decided
  receipt (D-18). One home, no double-source. (A global `rejected → "Denied"` would mislabel a rejected
  *review/promotion* and collide with D-16/D-18.)
- **D-25 (revised):** **Canonical vocabulary** (in `ScoriaWeb.Copy`, except "Denied" per D-24d):
  action verbs — Approve/Deny, Promote/Add manually, Resolve/Open, Select/Review/Dismiss, Grant/Revoke,
  Open trace/Retry, Pin/Compare/Edit, Run/Compare; status labels — Pending, Approved, Expired, Passed,
  Failed, Regressed, Running, Promoted, Draft, Published, Connected, Disconnected, Idle (**"Denied" is
  approval-domain only**). Status is never color-only (enforced by `badge/1`).
- **D-26 (revised):** **Copy guard** `test/scoria_web/copy_guard_test.exs` (Phase-38 source-scan,
  explicit-offender / warning-grade): (a) no schema/module names in headings; (b) no opaque IDs
  (`entity_id`/`*_run_id`/`*_session_id`) interpolated into `<h1>/<h2>/:title/:eyebrow`; (c) status
  renders only via an **allow-list of approved label fns** — `status_label`, `state_label`
  (`dataset_live` legitimately uses its own), `delegated_status_label`, `ApprovalCopy.*`, `*Copy.*` —
  never a raw atom (catches `connectors_live:79`). Assert known offenders fixed + no *new* literal
  offender patterns; do not attempt semantic proof over dynamic assigns (Phase 41 hardens).

### Adopter / i18n non-goal (D-24 rationale, recorded so it isn't re-litigated)

Operator copy is centralized in `Copy`/`*Copy` and is **not** adopter-overridable or localizable this
phase. Precedent: Phoenix LiveDashboard and Oban Web are English-hardcoded embedded libs with no copy
override; the console teaches Scoria's *own* domain vocabulary, so gettext wouldn't even serve override
without adopters translating Scoria's nouns. If a real requirement appears, a future `config :scoria,
:copy` seam is a localized change *because* copy is already centralized — do not re-scatter strings
inline to "make it flexible."

### Claude's Discretion

Downstream agents choose: exact new function/CSS/module names; sticky-bottom vs in-flow-only action
bar (D-12 recommends sticky-bottom); D-09 sort policy (A) vs (B); capped-recent + load-more vs a scoped
`table/1` stream upgrade for decided history; whether decider identity is batch-loaded per row or
resolved only in the drawer; precise per-domain copy-module boundaries; test-file placement — as long
as **D-01..D-27, the Coherence Spine, and the cross-cutting invariants hold**. Prefer boring, minimal
additions over new abstraction layers. Do not expand the tone/size/state vocabularies locked in
Phases 36/37/38.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase & Milestone Scope
- `.planning/ROADMAP.md` — Phase 39 goal + 5 success criteria; Phase 40/41 boundaries.
- `.planning/REQUIREMENTS.md` — FLOW-01..04, COPY-01 + the out-of-scope line forbidding in-place reversal.
- `.planning/PROJECT.md` — v3.3 intent ("under-adopted, not under-built"; pages serve intent, not backend structure).
- `.planning/STATE.md` — current phase position and deferred items.
- `.planning/phases/36-baseline-and-inventory/36-CONTEXT.md` + `36-INVENTORY.md` + `36-inventory.json` — inventory, risk register (`RISK-APPROVAL-HISTORY` = Phase 39).
- `.planning/phases/37-dev-component-lab-and-stress-fixtures/37-CONTEXT.md` — Component Lab / stress fixtures (decided + expired approval fixtures needed here, D-21).
- `.planning/phases/38-foundations-and-primitive-controls/38-CONTEXT.md` — the LOCKED primitive vocabulary this phase composes.

### Brand & Token Source of Truth
- `brandbook/brand-book.md` — **canonical** voice/UI (newer than the deep-research prompt; WINS on conflict). §1 audience, §2 states, §6 voice + word bank + "approval is not an alarm", §7/§9 status-not-color-only, §11.3 "never a magic score".
- `brandbook/tokens.json` / `brandbook/tokens.css` / `brandbook/README.md` — semantic token SSOT.

### Runtime UI, Pages, Copy, Data (the surface Phase 39 edits)
- `lib/scoria_web/components/layouts/app.html.heex` — app shell; renders `page_title` only in `<span>`s (no competing `<h1>` — the single-header premise, F1). `root.html.heex` — `<.live_title>`.
- `lib/scoria_web/ui.ex` — add `page_header/1` near `page_section/1` (~193); reuse `object_header/1` (~437), `stub_page/1` (~489), `table/1` (~1199), `drawer/1` (~704), `raw_evidence/1` (~1016), `evidence_section/1` (~1083), `id/1` (~276), `time/1` (~304), `badge/1` (~68), `overview_stats/1` (~249), `empty_state/1` (~623), `skeleton/1` (~813); **upgrade `status_label/1` (~52) ADDITIVELY** (keep the generic fallback — it backstops `evidence_text/1` ~1376 and `object_header/1` ~441); tone map (~23-38).
- `assets/css/04-components.css` — `.scoria-pagehead*` (~1161, reuse); `.scoria-approval-summary__label` (~841-857, delete), `.scoria-approval-actions` sticky-top (~865-877, strip sticky), `.scoria-approval-details` tech-grid (~886-943, delete/fold).
- `lib/scoria_web/approval_copy.ex` — copy SSOT template; extend with `status_line/1`, `eyebrow/1`, `decision_outcome/1` ("Denied"), `impact_lead/1`, decided-receipt helpers; **remove the raw `{"Status", …}` row** (`evidence_rows/1` ~215).
- `lib/scoria_web/live/approvals_live/index.ex` — inbox + drawer + `open_decision_modal` (~108-115) + `:not_pending`/`StaleEntryError` guard (~354-360) + `approval_request_event/1` (~341, mirror as `approval_decision_event/1`) + **approve-then-resume ordering** (~283-327, D-27).
- `lib/scoria_web/components/approval_inbox_component.ex` — approvals is already `<.table id="approvals">` (~16).
- `lib/scoria/observe/approval.ex` — schema; statuses `~w(pending approved rejected expired)` (~5); `optimistic_lock(:lock_version)` (~104). No migration.
- `lib/scoria/workflows.ex` — the **three** approval-row writers (`insert!` ~393, second `changeset|>update!` ~430, decision write ~679); `approve/3` guard (~665) drops decider identity; the audit-event write (~683-720) is the decided-at/decider SSOT.
- `lib/scoria/workflows/remote_approval_projection.ex` — `list_pending_approvals/1` hardcodes pending (~16); `get_approval_lineage!/1` hydrates any status (~27) but carries the *requesting* actor. Add `list_decided_approvals/1`.
- `priv/repo/dev_seed.exs` — `update_all(set: [status: "expired"])` (~271-304) — the broken expiry fixture path (D-21).
- `lib/scoria/sre.ex` — `AuditOutboxEvent.actor_ref` (~277).
- Scan pages to normalize: `dataset_live/index.ex` (sort via `handle_event`+assign ~44-53; redundant header ~64,82; `.id`-for-version ~98; `state_label/1` ~102,330), `review_queue_live.ex` (socket-held filter ~31-33,95-119; raw status ~130), `incidents_live/index.ex` (list `<ul>` ~105-121, stream target), `connectors_live/index.ex` (~79,82,85), `prompt_live/index.ex` (~99,140), `eval_spec_live/index.ex` (~71), `coming_soon_live.ex` (bespoke not-found `<h1>` ~40), `orchestrator_live.ex` (Home `<h1>` ~95).

### Tests / Guards (keep green; add lightweight new guards)
- `test/scoria_web/ds06_drift_guard_test.exs`, `token_contrast_guard_test.exs` — keep green.
- `test/scoria_web/ui_component_test.exs` + `ui_drift_guard_test.exs` — the source-scan style to model the D-05 single-header, D-11 scan-convention, D-20 invariant, and D-26 copy guards on.
- `dev/` lab routes + `priv/dev/e2e/` — browser proof surface to reuse.

### External Precedent
- Phoenix `core_components.ex` `<.header>` (`:actions` slot) — the thin-header idiom.
- Phoenix LiveDashboard, Oban Web — URL-param filters + `stream/3` + status facets (same-layout segments).
- Backpex / LiveAdmin / Kaffy — CRUD-config scaffolds; the anti-pattern to AVOID.
- GitHub PR merge box / Open-Closed, Vercel deploy approvals, PagerDuty, Argo CD, Stripe — HITL decision-first + open/closed history precedents (all same-layout both segments).
- `https://www.w3.org/WAI/WCAG22/Understanding/` — build-accessibly intent (full sweep is Phase 40).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`table/1` already owns** `:filter`/`:action`/`:empty`/`:mobile_summary` + sort + pagination; **approvals already IS a `table/1`** — Area 2 is convention, not new primitives, and there is no board.
- **`.scoria-pagehead*` CSS already exists** — `page_header/1` is a rename of copy-pasted markup, zero new CSS. The shell emits no competing `<h1>`.
- **`drawer/1` + `evidence_section`/`evidence_rows` + `raw_evidence` (native `<details>`) + `id/1`/`time/1`** support the two-tier decision-first hierarchy with no `drawer/1` change.
- **`ApprovalCopy`** already splits orientation vs evidence rows — the template to generalize (D-24) and the dedup SSOT (D-16); "Denied" lives here (D-24d).
- **Approval statuses are terminal-complete** and decider/time are transactionally recorded in the **audit outbox** — history (Area 4) needs a query scope + an event lookup, not a migration.
- **`status_label/1` already has a safe generic fallback** — the D-24 upgrade is additive; do not remove the fallback (it backstops `evidence_text/1` and 6 domains against a page-500).

### Established Patterns
- Token-first CSS via `.scoria-root`; raw-palette drift is a guarded zero (DS-06) — stays zero.
- Small composable `attr`/`slot` function components — not god-components.
- Phase-38 **source-scan drift guards** — the enforcement pattern to reuse (D-05/D-11/D-20/D-26).
- Every index queries synchronously in `mount` → no loading spinner window (D-08).
- Approvals inbox is **PubSub-reload driven** with assign-based `Enum.find` lookups → do not stream it (D-10).

### Integration Points
- Add `page_header/1` + additively upgrade `status_label/1` in `ui.ex`; reuse `.scoria-pagehead*`, delete `.scoria-approval-summary__label`, strip `.scoria-approval-actions` sticky, delete `.scoria-approval-details`.
- Extend `ApprovalCopy`; add strings-only `ScoriaWeb.Copy` + `Incident/Dataset/Review/Connector` copy modules.
- Add `Workflows.list_decided_approvals/1` + `approval_decision_event/1` in the context/projection (not the LiveView); decided-at/decider from the audit event.
- Migrate `review_queue` filter to URL params; add `?approval=<id>` drawer deep-link; stream the incidents `<ul>`; capped+load-more for decided history.
- New warning-grade source-scan guards alongside `ds06_drift_guard_test.exs`; prove flows against `dev/` lab + `priv/dev/e2e/`.

</code_context>

<specifics>
## Specific Ideas

- **The one failure chain to break** (red-team): operator opens a $10k refund → reads a calm consequence → clicks Approve → clicks through a redundant confirm reflexively → resume silently fails → history later shows a clean "Approved." Broken by D-13 (magnitude salience) + D-15 (confirm earns friction) + D-27 (honest receipt) + D-12 (decision-first placement).
- **The 6-place decision-copy duplication** (D-16) is the concrete FLOW-03 "no duplicated decision copy" target; **plus** the raw status-atom row in `evidence_rows` (D-16/D-23).
- **The microcopy offenders** (D-23): `eval_spec (EvalSpecs)`, `prompt entity_id`, `connectors run_id/session_id`, **`connectors runtime.status`**, `review raw status atom`, `dataset .id-for-version`.
- **The `dataset_live` redundant header** (D-04) is the concrete FLOW-01 target (semantic, not literal).
- **Decision-history segmentation** = `Pending | Decided` on one `table/1`; outcome is a sub-filter of Decided.
- **"Denied" in copy (ApprovalCopy), `"rejected"` in schema** (D-24d/D-25).
- **`expired` is not produced in prod** — render it honestly (no fabricated time/actor) until a producer exists (D-18/D-21).

</specifics>

<deferred>
## Deferred Ideas

- Formal keyboard/focus-trap/restore proof, WCAG 2.2 AA sweep, motion/reduced-motion proof, responsive 320–1440 proof — **Phase 40**.
- Hardened drift guards, maintainer convention docs, screenshot proof, final gap register — **Phase 41**.
- Changing approval semantics to allow in-place approval of a denied request — **forbidden**.
- A production expiry producer (TTL sweeper / Oban worker) — future; Phase 39 only renders `expired` honestly.
- Denormalized `decided_by`/`decided_at` columns (only if drawer/history audit-lookup perf later demands, or if `expired` must carry a timestamp without an audit join) — future.
- Audit export/CSV, retention/TTL, per-field argument-diff history, full-text history search, cross-tenant history, re-open/appeal workflow — future.
- gettext / i18n / adopter copy-override (`config :scoria, :copy` seam) — deferred until a real requirement appears.
- PhoenixStorybook (`STORYBOOK-01`), screenshot-diff CI (`VISUAL-CI-01`) — deferred/later.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 39-Component Groups And Operator Flows*
*Context gathered: 2026-07-02 (red-team-hardened same day)*
