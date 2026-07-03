# Phase 39: Component Groups And Operator Flows - Pattern Map

**Mapped:** 2026-07-03
**Files analyzed:** 22 (2 new copy modules-family, 4 new guards, ~16 modified)
**Analogs found:** 22 / 22 (every new symbol maps to a live in-repo analog — this is an adoption phase)
**Line numbers verified against HEAD** (context was gathered 2026-07-02; drift noted in "Line-Number Drift" section)

> This is a **page-flow adoption phase**. Almost nothing here is invented — each new symbol is a
> rename/extension of an existing pattern. The executor's job is to **mirror the established
> convention**, not design a new one. Every "analog" below is a real file:line the executor copies from.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria_web/ui.ex` → **new `page_header/1`** | component (function comp) | request-response (render) | `page_section/1` `ui.ex:193` + Phoenix `<.header>` | exact (rename of `.scoria-pagehead` markup) |
| `lib/scoria_web/ui.ex` → **`status_label/1` additive upgrade** | component (pure fn) | transform | `status_label/1` `ui.ex:52-58` (self) + `tone/1` `ui.ex:21-49` | exact (extend clauses) |
| `lib/scoria_web/copy.ex` **`ScoriaWeb.Copy`** (NEW) | utility (strings-only) | transform | `approval_copy.ex` (whole module) | role-match (data-only subset) |
| `lib/scoria_web/incident_copy.ex` (NEW) | utility (copy branching on data) | transform | `approval_copy.ex` (template) | exact-template |
| `lib/scoria_web/dataset_copy.ex` (NEW) | utility | transform | `approval_copy.ex` | exact-template |
| `lib/scoria_web/review_copy.ex` (NEW) | utility | transform | `approval_copy.ex` | exact-template |
| `lib/scoria_web/connector_copy.ex` (NEW) | utility | transform | `approval_copy.ex` | exact-template |
| `lib/scoria_web/approval_copy.ex` (MODIFY) | utility (copy SSOT) | transform | self (`title/1`,`impact/1`,`decision_*`) | exact (extend) |
| `lib/scoria/workflows/remote_approval_projection.ex` → **`list_decided_approvals/1`** (NEW fn) | service (projection/query) | CRUD (read) | `list_pending_approvals/1` `projection.ex:16-25` | exact |
| `lib/scoria_web/live/approvals_live/index.ex` → **`approval_decision_event/1`** (NEW fn) | service (query in LV) | CRUD (read) | `approval_request_event/1` `index.ex:341-352` | exact |
| `lib/scoria_web/live/approvals_live/index.ex` (drawer redesign + scope + deep-link) | controller (LiveView) | event-driven + request-response | self (`render/1` `index.ex:118`, `handle_params`) | exact (in-place) |
| `lib/scoria_web/components/approval_inbox_component.ex` (Decision column + outcome filter) | component | request-response | self (`<.table id="approvals">` ~16) + `dataset_live` `:filter` slot | role-match |
| `lib/scoria_web/live/review_queue_live.ex` (filter socket→URL; raw status) | controller (LiveView) | event-driven | `dataset_live` URL-encoded selection + `handle_params` | role-match |
| `lib/scoria_web/live/incidents_live/index.ex` (`stream/3` the `<ul>`) | controller (LiveView) | streaming (list) | self `<ul class="scoria-selectable-list">` `index.ex:105-121` | exact (add `phx-update`) |
| `lib/scoria_web/live/dataset_live/index.ex` (page_header, redundant hdr, `.id`-version) | controller (LiveView) | CRUD | self `index.ex:62-98` | exact |
| `lib/scoria_web/live/connectors_live/index.ex` (status_label, IDs→evidence) | controller (LiveView) | CRUD | self `index.ex:63,78,83,86` | exact |
| `lib/scoria_web/live/prompt_live/index.ex` (`entity_id` demotion) | controller (LiveView) | CRUD | self `index.ex:99,140` | exact |
| `lib/scoria_web/live/eval_spec_live/index.ex` (drop `(EvalSpecs)`) | controller (LiveView) | CRUD | self `index.ex:71` | exact |
| `lib/scoria_web/live/workflow_live/index.ex` (pagehead→`page_header`) | controller (LiveView) | CRUD | self `index.ex:31` | exact |
| `lib/scoria_web/live/coming_soon_live.ex` (sanctioned not-found header) | controller (LiveView) | request-response | `stub_page/1` `ui.ex:489` | role-match |
| `lib/scoria_web/live/orchestrator_live.ex` (Home `page_header`) | controller (LiveView) | request-response | self `orchestrator_live.ex:94-95` | exact |
| `assets/css/04-components.css` (delete/strip approval alarm chrome) | config (stylesheet) | n/a | `.scoria-pagehead*` `css:1161` (reuse) | exact |
| `priv/repo/dev_seed.exs` (route decided/expired via `approve/3`) | migration/fixture | batch | `Workflows.approve/3` (real decision path) | role-match |
| `test/scoria_web/*_guard_test.exs` (D-05/D-11/D-20/D-26, 4 NEW) | test (source-scan guard) | batch (File.read! + regex) | `ui_drift_guard_test.exs` + `ds06_drift_guard_test.exs` | exact-template |

---

## Pattern Assignments

### `page_header/1` — NEW in `lib/scoria_web/ui.ex` (D-01)

**Analogs (two, deliberately fused):**
1. **`page_section/1`** (`ui.ex:193-214`) — the structural template: a `<section>` with a `__header` div
   holding a heading block + an `:actions` slot rendered in a right-aligned action div. Copy this shape
   but emit an **`<h1>`** (not `<h2>`) and use `.scoria-pagehead*` classes.
2. **Phoenix `core_components` `<.header>`** — the `:actions` slot **name** to mirror for adopter familiarity.

**The markup to promote (hand-rolled, copy-pasted across 8 pages).** `review_queue_live.ex:52-56` is the
richest existing instance — it is the one page that already uses the **`--with-actions`** modifier + a
ghost "Back to dashboard" link, so it is the exemplar for the `slot :actions` (0..1) convention:
```
lib/scoria_web/live/review_queue_live.ex:52
  <div class="scoria-pagehead">
    <div class="scoria-pagehead__title scoria-pagehead__title--with-actions">
      ...<h1>...</h1>... (ghost "Back to dashboard" action)
      <p class="scoria-pagehead__description">...
```
Simplest instance (title + description, no actions) — `dataset_live/index.ex:62-67`:
```
    <div class="scoria-pagehead">
      <div class="scoria-pagehead__title">
        <h1>Dataset Builder</h1>
      </div>
      <p>Curate production traces into eval datasets and baseline approval requests.</p>
    </div>
```

**Attr/slot shape to write** (per D-01 — `title` is an **attr, not a slot**, so IDs/module names
structurally cannot leak into the `<h1>`, mechanically enforcing D-23/D-26; mirror `page_section/1`'s
`slot :actions` conditional-render idiom `ui.ex:207`):
```elixir
attr(:title, :string, required: true)   # renders the page's ONLY <h1> — plain string, NOT a slot
attr(:class, :string, default: nil)
attr(:rest, :global)
slot(:summary)                            # one-line operator orientation <p>
slot(:actions)                            # 0..1 header action (primary OR ghost nav link)
```

**CSS to reuse (zero new tokens/classes)** — `assets/css/04-components.css:1161-1175`:
`.scoria-pagehead`, `.scoria-pagehead__title`, `.scoria-pagehead__title--with-actions`,
`.scoria-pagehead__description`. Do NOT add classes.

**Migrate all callers in the same plan as the D-05 guard** (else the guard is red on arrival):
`orchestrator_live.ex:94`, `review_queue_live.ex:52`, `incidents_live/index.ex:56`,
`dataset_live/index.ex:62`, `approvals_live/index.ex:121`, `connectors_live/index.ex:63`,
`workflow_live/index.ex:31`, `eval_spec_live/index.ex:70` (bare `<h1>`, no pagehead div),
`coming_soon_live.ex:29` (+ the `.scoria-stub` not-found branch, see D-03 note below).

---

### `status_label/1` additive upgrade — `lib/scoria_web/ui.ex:52-58` (D-24a) ⚠

**Analog: the function itself** (`ui.ex:52-58`) and its sibling `tone/1` (`ui.ex:21-49`, which shows the
curated-`case`-above-fallback idiom to mirror):
```elixir
def status_label(status) when is_atom(status), do: status |> Atom.to_string() |> status_label()

def status_label(status) when is_binary(status) do
  status |> String.replace("_", " ") |> String.capitalize()
end

def status_label(_), do: "Unknown"
```

**Upgrade shape:** insert **curated binary clauses ABOVE** the generic `String.replace` binary clause
(pattern: mirror `tone/1`'s `case status do s when s in ~w(...) -> ...` structure `ui.ex:23-47`).
⚠ **MUST keep the generic `String.replace` clause AND `status_label(_) -> "Unknown"`** — this fn is the
atom fallback inside `evidence_text/1` (`ui.ex:~1376`) and is called across ≥6 disjoint domains
(approval, eval pass/fail/regressed, severity, run, prompt, promotion, object header via `object_header/1`
`ui.ex:441`). A closed allow-list raises `FunctionClauseError` inside `render/1` → **500s the page** on
any unseen status. **Do NOT curate `"rejected"` here** — "Denied" is approval-domain only (D-24d,
lives in `ApprovalCopy.decision_outcome/1`).

---

### `ScoriaWeb.Copy` (NEW) + per-domain copy modules (D-24b/c)

**Analog / template: `lib/scoria_web/approval_copy.ex`** (whole module, 314 lines). It is already the
"orientation vs evidence" split (`title/1`, `impact/1`, `target/1` = orientation; `evidence_rows/1`,
`raw_arguments/1` = evidence) and is **pure functions returning strings/keyword-data, zero `~H`** — copy
this discipline exactly.

**`ScoriaWeb.Copy` (strings-only, renders NOTHING):** owns canonical action-verb set + status-label map +
`empty_title/1`/`empty_cta/1`/`error_line/1`/`loading_label/1`. Mirror the flat `def foo(x), do: "string"`
clause style of `approval_copy.ex:11-64`. **Hard line: `Copy` = data, `UI.empty_state/1`/`skeleton/1` = the
renderers that receive those strings** (per D-24b). Follow `approval_copy.ex`'s `field/1`,`present?/1`,
`blank?/1`,`compact_join/1` helper conventions (`approval_copy.ex:237-313`) for safe field access.

**Per-domain modules — `IncidentCopy`/`DatasetCopy`/`ReviewCopy`/`ConnectorCopy`** (only where copy
branches on record data). Template each on `approval_copy.ex`'s `case field(x, :tool_name) do` dispatch
(`approval_copy.ex:13-64`, `108-134`). Example the executor mirrors — `ApprovalCopy.impact/1`
(`approval_copy.ex:106-134`):
```elixir
def impact(approval) do
  case field(approval, :tool_name) do
    "issue_refund" ->
      amount = money_amount(argument(approval, "amount_cents"))
      approve_copy = if amount, do: "Approving issues a #{amount} refund.", else: "Approving issues the refund."
      approve_copy <> " Denying leaves the run waiting for approval."
    ...
    _ -> "Approving lets the run continue. Denying leaves the run waiting for approval."
  end
end
```
`ConnectorCopy` specifically feeds the `connectors_live:78` fix (raw `runtime.status` → labelled).

---

### `ApprovalCopy` extensions + dedup (D-16, D-24d, D-27)

**Analog: the module's own existing clause families.**
- `status_line/1` / `eyebrow/1` — mirror `decision_badge/1` (`approval_copy.ex:182-184`) 3-clause shape.
- `decision_outcome/1` (produces **"Denied"**, D-24d) — mirror `reject_label/1` (`approval_copy.ex:176`).
- `impact_lead/1` (reused by the D-15 confirm modal + drawer consequence) — extract the lead clause of
  `impact/1` (`approval_copy.ex:110-120`, the `"Approving issues a #{amount} refund."` sentence).
- decided-receipt helpers (D-18/D-27) — past-tense agentful: `"Approved by {actor} · {time}"`; **`Expired`
  renders WITHOUT fabricated `· {time}`/actor** unless a real `approval.expired` audit event exists.

**DELETE — the raw status-atom evidence row** (`approval_copy.ex:215`, verified exact):
```elixir
def evidence_rows(approval) do
  [
    {"Requested by", requested_by(approval)},
    {"Connector", connector_label(approval)},
    {"Policy", policy(approval)},
    {"Session", field(approval, :session_id)},
    {"Status", field(approval, :status)}      # <-- DELETE THIS ROW (D-16/D-23: duplicates badge, leaks raw atom)
  ]
  |> reject_blank_rows()
end
```

---

### `Workflows.list_decided_approvals/1` — NEW in `remote_approval_projection.ex` (D-20)

**Analog: `list_pending_approvals/1`** (`remote_approval_projection.ex:16-25`, verified exact):
```elixir
def list_pending_approvals(filters \\ %{}) do
  filters = normalize_filters(filters)
  Approval
  |> where([approval], approval.status == "pending")
  |> apply_filters(filters)
  |> order_by([approval], desc: approval.inserted_at, desc: approval.id)
  |> Repo.all()
  |> Enum.map(&project_approval/1)
end
```
**New fn shape (mirror exactly, swap the `where`):** `where([a], a.status in ["approved","rejected","expired"])`,
`order_by: [desc: :updated_at, desc: :id]` (cheap query-level proxy sort only), **bounded** (capped +
load-more per D-10), reuse `apply_filters/1` + `project_approval/1` unchanged. Reuse the existing
`@filter_fields`/`normalize_filters` (`:12,88-105`) for the outcome sub-filter.

**Data caveat (D-20):** decided-at/decider SSOT is the **audit event, not `updated_at`**. The query's
`updated_at` sort is a proxy only; the *displayed* decider/time comes from `approval_decision_event/1`.
`get_approval_lineage!/1` (`:27-31`) hydrates any status into the drawer but exposes the *requesting*
actor — the receipt must read the decider from the decision event, not lineage.

---

### `approval_decision_event/1` — NEW in `approvals_live/index.ex` (D-20)

**Analog: `approval_request_event/1`** (`index.ex:341-352`, verified exact):
```elixir
defp approval_request_event(approval) do
  AuditOutboxEvent
  |> where([event], event.workflow_run_id == ^approval.workflow_run_id and
                    event.event_type == "approval.requested")
  |> where([event], fragment("?->>? = ?", event.redacted_refs, "approval_id", ^approval.id))
  |> order_by([event], desc: event.inserted_at)
  |> limit(1)
  |> Repo.one()
end
```
**New fn shape:** identical query, swap `event_type == "approval.requested"` for the decision event type
(`"approval.approved"`/`"approval.rejected"`/`"approval.expired"`, i.e. `"approval.<status>"` — confirm
exact strings against `lib/scoria/workflows.ex` audit-event write ~683-720). Read `inserted_at` (decided-at)
and `actor_ref` (decider) from the returned row. **Batch-load by the visible id-set to avoid N+1** (D-20) —
prefer a `where [e], fragment(... approval_id ...) in ^ids` + `Repo.all` variant for the history table rather
than one query per row. Missing event → render **"Decided · time unavailable"**, never "unknown".

---

### Approval drawer decision-first redesign — `approvals_live/index.ex` (D-12..D-16, D-27)

**Analog: the current `render/1` drawer subtree** (`index.ex:141-219`) — you are restructuring it in place,
not rebuilding the `drawer/1` primitive (no `drawer/1` change).

Current top→bottom order to **re-sequence** (decision-first per D-12):
```
index.ex:141  <.drawer id="approval-detail-drawer" show={@active_approval != nil} on_dismiss="dismiss_approval">
index.ex:147    <p class="scoria-approval-summary__label">Review before Scoria continues this run.</p>   # DELETE (D-13 de-alarm)
index.ex:148    <p class="scoria-approval-summary__effect">{ApprovalCopy.impact(@active_approval)}</p>
index.ex:154-166  action buttons (Deny · Approve, phx-click="open_decision_modal")                        # move UP under consequence (D-12)
index.ex:175    <.evidence_rows rows={ApprovalCopy.request_rows(@active_approval)} />
index.ex:177    <.evidence_rows rows={ApprovalCopy.evidence_rows(@active_approval)} />
index.ex:188    <details class="scoria-approval-details"> ... tech-grid rows ...                            # DELETE grid; refactor to TWO <details> (D-14)
index.ex:211    <.raw_evidence ... value={ApprovalCopy.raw_arguments(...)} />                               # set open={false} (D-14)
```

**D-14 two collapsed disclosures — reuse existing primitives, no bespoke CSS:**
- **(i) "Identifiers"** — `<.id>` (`ui.ex:276`, gives the copyable log-grep affordance) + `<.time>`
  (`ui.ex:304`) rows for approval/run/session/trace id + requested-at. This is why IDs cannot fold into
  the JSON `<pre>` — `raw_evidence/1` renders a single `<pre>` and can't host copy controls.
- **(ii) "Request payload"** — `<.raw_evidence open={false} value={ApprovalCopy.raw_arguments(@active_approval)} />`
  (`raw_evidence/1` attrs: `ui.ex:1005-1010`, native `<details>` — keyboard/SR/reduced-motion safe).

**D-14 open-state-loss mitigation:** give the payload details a **stable per-approval DOM id**
`id={"approval-raw-#{@active_approval.id}"}` so a *different* approval mounts a fresh collapsed node.
Add a `LiveViewTest` regression asserting an unrelated `{:hitl_request}` broadcast (`index.ex:69-83`)
leaves an open `<details>` intact.

**D-16 dedup (the FLOW-03 "no duplicated decision copy" target):** collapse ~6 status emissions to one
`ApprovalCopy.status_line/1` badge in the drawer header; remove the drawer audit line (`index.ex:170-172`);
replace the generic "Approval request" eyebrow with `ApprovalCopy.eyebrow/1`.

**D-27 ⚠ SAFETY — honest receipt.** The decided receipt asserts only the **recorded decision**, never
side-effect/run success. The hazard is structural in `record_approval_decision/1` (`index.ex:283-314`,
verified): `Workflows.approve` runs, *then* `maybe_resume_approval/3` (`index.ex:316-328`) — if resume
fails, the row is **already** decided:
```elixir
with {:ok, updated_approval} <- Workflows.approve(approval.id, status, attrs),
     {:ok, updated_socket} <- maybe_resume_approval(socket, updated_approval, status) do
  ...
else
  {:error, reason} -> ... put_flash(:error, approval_error_message(status, reason)) ...
end
```
Receipt copy states the decision only + links to the run (`workflow_run_id`) for execution truth. Applies
to the decided-drawer state (D-19) and the history row.

**D-19 decided read-only state — reuse the SAME `drawer/1`.** Emit the action `<section>` (`index.ex:145`)
+ confirm modal (`index.ex:220`) ONLY when pending, gated by a **positive whitelist** predicate
`decided?(%{status: s}), do: s in ~w(approved rejected expired)` (fails safe; mirrors server guard
`index.ex:354-360`). Buttons structurally not emitted when decided.

---

### Approvals Pending|Decided scope + `?approval=<id>` deep-link (D-09, D-17)

**Analog: `dataset_live/index.ex`** — the URL-encoded-selection exemplar (it URL-encodes the promotion
drawer/selection via `push_patch`+`handle_params`, NOT sort). **Approvals is already one `<.table>`**
(`approval_inbox_component.ex:16`), so Pending|Decided is a same-primitive `:filter`-slot scope, not a
second idiom (mirror the `table/1` `:filter` slot usage in `review_queue_live.ex:118` /
`dataset_live/index.ex:82-98`).

**Migrate `@active_approval` from socket-only to URL** `?approval=<id>` (`push_patch`+`handle_params`) so the
open drawer is deep-linkable/reconnect-safe. **Keep ephemeral state in assigns:** the `:decision_modal`
toggle (`index.ex:108-114`), toasts, and `:highlighted_approval_id` (`index.ex:79`).
**Do NOT stream the pending inbox** (D-10) — it is PubSub-reload driven (`handle_info` `index.ex:59-86`,
`reload_inbox` ~256) with assign-based `Enum.find` lookups (`select_approval` `index.ex:101-106`,
`seed_focused_active_approval` ~273-281) that streaming breaks.

---

### `stream/3` the incidents `<ul>` (D-10)

**Analog: the caller-owned list itself** (`incidents_live/index.ex:105-121`, verified) — mount-only load,
no PubSub, so it's the ONE safe stream target. Add `phx-update="stream"` + a per-`<li>` id, zero `table/1`
change:
```
lib/scoria_web/live/incidents_live/index.ex:105
  <ul class="scoria-selectable-list" aria-label="Tenant incidents">
    <li :for={incident <- @incidents}>
      <.selectable_card href={...} tone={severity_tone(incident.severity)}>
```
Convert `@incidents` to `stream(socket, :incidents, ...)`, iterate `:for={{id, incident} <- @streams.incidents}`,
put `id={id}` on the `<li>`, and `phx-update="stream"` on the `<ul>`.

---

### Microcopy offender fixes (D-23) — verified line-by-line

| File:line (verified) | Current (offending) | Fix |
|---|---|---|
| `eval_spec_live/index.ex:71` | `<h1>Evaluation Rubrics (EvalSpecs)</h1>` | drop `(EvalSpecs)` module name; route through `page_header/1` |
| `prompt_live/index.ex:99` | `Edit Template: <%= @edit_template.entity_id %>` (`:title` slot) | human name in title, `entity_id` → labelled ID evidence |
| `prompt_live/index.ex:140` | `<:col label="Prompt"><%= template.entity_id %></:col>` | human name cell; ID as `<.id>` evidence |
| `connectors_live/index.ex:78` | `<.badge tone={tone(runtime.status)} label={runtime.status} />` (**raw status string** — context said `:79`) | `label={status_label(runtime.status)}` (or `ConnectorCopy`) — this is the D-26 allow-list catch |
| `connectors_live/index.ex:83` | `runtime.current_run_id` as primary cell (context said `:82`) | lead with status; run_id as `<.id>` evidence |
| `connectors_live/index.ex:86` | `runtime.host_session_id` as primary cell (context said `:85`) | session_id as evidence |
| `review_queue_live.ex:130` | `<%= row.sample_reason || row.status %>` (raw status atom) | label map via `status_label/1` / `ReviewCopy` |
| `dataset_live/index.ex:98` | `<.id value={"v#{dataset.version}"} title="Dataset version" />` (copyable-ID primitive misused for a version) | plain version label, not `<.id>` |
| `dataset_live/index.ex:62-67` (**D-04**) | `<h1>Dataset Builder</h1>` + region `<:title>Datasets</:title>` `:82` | semantic redundancy → drop region title, render flush/untitled |

---

### Warning-grade source-scan guards (D-05/D-11/D-20/D-26) — 4 NEW

**Analog: `ui_drift_guard_test.exs`** (the minimal `File.read!` + `Path.wildcard` + `Regex.match?` per-file
offender-collection style) and **`ds06_drift_guard_test.exs`** (the richer ratchet/excluded-files/allow-list
+ descriptive-failure style). Copy `ui_drift_guard_test.exs:19-40` as the skeleton:
```elixir
test "no re-introduced ... in lib/scoria_web" do
  offenders =
    "lib/scoria_web/**/*.ex"
    |> Path.wildcard()
    |> Enum.flat_map(fn path ->
      source = File.read!(path)
      for name <- @forbidden, Regex.match?(~r/\bdefp?\s+#{name}\b/, source), do: "#{path}: ..."
    end)
  assert offenders == [], "...descriptive message..."
end
```
Mirror `ds06`'s `@excluded ~w(...)` (`ds06:34`) for the D-05 scope-exclusion (`lib/scoria_web/ui.ex` +
dialog-scoped files) and its allow-list assertion style (`ds06` "ui.ex zero" test `:96-107`) for D-26's
approved-label-fn allow-list (`status_label`, `state_label`, `delegated_status_label`, `ApprovalCopy.*`,
`*Copy.*`).
- **D-05 single-header:** exactly one `<h1>` literal per page module, inside a sanctioned header; region-`:title`≠`<h1>` is warning-grade over static literals only.
- **D-11 scan-convention:** filter/scope state not held only in socket assigns (target: `review_queue`); must NOT red-flag `dataset_live` sort.
- **D-20 write-invariant:** assert no runtime path writes an approval row after it leaves `pending` (or a `@doc` contract on `approve/3`) — decided-at integrity depends on it. The codebase has the fragile shape: a 2nd `Approval.changeset |> update!` at creation (`workflows.ex:~430`) and `update_all` in seeds.
- **D-26 copy-guard** `test/scoria_web/copy_guard_test.exs`: no schema/module names in headings; no opaque IDs in `<h1>/<h2>/:title/:eyebrow`; status only via the allow-list of label fns (catches `connectors_live:78`).

---

### `dev_seed.exs` decided/expired fixtures (D-21)

**Analog: `Workflows.approve/3`** (the real decision path — emits the audit event + bumps `updated_at`).
Replace `priv/repo/dev_seed.exs:~271-304` `Repo.update_all(set: [status: "expired"])` with
`approve(id, "expired")` / `approve(id, <status>)` so fixtures exercise the real history surface (decider +
time). **No fabricated history in the UI** — until a production expiry producer exists, either seed `expired`
via `approve/3` or render `Expired` with no time/actor.

---

### `04-components.css` — delete/strip approval alarm chrome (D-12/D-13/D-14)

Reuse `.scoria-pagehead*` (`css:1161-1175`) for `page_header/1` (no new classes). Then:
- **DELETE** `.scoria-approval-summary__label` (uppercase warn banner, per D-13) — `css:~841-857`.
- **STRIP the sticky-top** from `.scoria-approval-actions` (`position:sticky;top:0`+gradient, per D-12) —
  `css:~865-877`. Optionally re-add as `position:sticky;bottom:0` sticky-footer (Claude's discretion).
- **DELETE** `.scoria-approval-details` tech-grid (per D-14) — `css:~886-943`.

---

## Shared Patterns

### Source-scan drift-guard idiom
**Source:** `test/scoria_web/ui_drift_guard_test.exs:19-40` + `test/scoria_web/ds06_drift_guard_test.exs:39-131`.
**Apply to:** all 4 new guards (D-05/D-11/D-20/D-26). `Path.wildcard` + `File.read!` + `Regex`, collect
offenders, `assert offenders == []` with a descriptive fix message; use `@excluded`/allow-list lists.

### Copy-module discipline (data, never render)
**Source:** `lib/scoria_web/approval_copy.ex` (pure fns, `field/1`/`present?/1`/`blank?/1`/`compact_join/1`
helpers `:237-313`, `case field(x, :tool_name)` dispatch `:13-64`).
**Apply to:** `ScoriaWeb.Copy` + `Incident/Dataset/Review/Connector` copy. `Copy` = strings; `UI` = render.

### Semantic component vocabulary (tone/badge/id/time)
**Source:** `lib/scoria_web/ui.ex` — `tone/1` `:21-49`, `badge/1` `:68`, `id/1` `:276`, `time/1` `:304`.
**Apply to:** every status (via `status_label/1`+`badge/1`, never color-only, never raw atom), every opaque
ID (via `<.id>` with "Copy" affordance), every timestamp (via `<.time>`). This is the D-22/D-23 demotion mechanism.

### URL-state vs assigns split
**Source:** `dataset_live/index.ex` (`push_patch`+`handle_params` for selection) vs `approvals_live/index.ex`
ephemeral assigns (`:decision_modal` `:108-114`, `:highlighted_approval_id` `:79`).
**Apply to:** `review_queue` filter→URL, `?approval=<id>` deep-link (shareable→URL); confirm-modal toggle,
toasts, live-highlight (ephemeral→assigns).

### Projection query shape
**Source:** `remote_approval_projection.ex:16-40` (`where` → `apply_filters` → `order_by` → `Repo.all` →
`Enum.map(&project_approval/1)`).
**Apply to:** `list_decided_approvals/1` (reuse `apply_filters`/`project_approval`/`normalize_filters`).

---

## No Analog Found

None. Every new symbol in Phase 39 maps to an in-repo analog — this is an adoption phase composing the
LOCKED Phase 36/37/38 vocabulary. The closest thing to "new" is the **decided-receipt copy** and the
**Pending|Decided outcome sub-filter**, and both reuse existing primitives (`ApprovalCopy` clause families,
`table/1` `:filter` slot). Nothing here should fall back to abstract RESEARCH.md patterns (there is no
RESEARCH.md — CONTEXT.md is research-backed).

---

## Line-Number Drift (context gathered 2026-07-02; verified against HEAD 2026-07-03)

**Verified exact (no drift):**
- `approval_copy.ex:215` raw `{"Status", field(approval, :status)}` row ✓
- `remote_approval_projection.ex:16` `list_pending_approvals/1`, `:27` `get_approval_lineage!/1` ✓
- `approvals_live/index.ex:341` `approval_request_event/1`, `:147` `.scoria-approval-summary__label`,
  `:283-314` decision path, `:316-328` `maybe_resume_approval/3`, `:354-360` guard, `:108-114` modal ✓
- `ui.ex:52-58` `status_label/1`, `:193` `page_section/1`, `:437` `object_header/1`, `:489` `stub_page/1`,
  `:704` `drawer/1`, `:276` `id/1`, `:304` `time/1`, `:1016` `raw_evidence/1`, `:1083` `evidence_section/1`,
  `:1199` `table/1` ✓
- `eval_spec_live/index.ex:71`, `prompt_live/index.ex:99` & `:140`, `review_queue_live.ex:130`,
  `dataset_live/index.ex:98` offenders ✓
- `orchestrator_live.ex:94-95` Home pagehead+`<h1>` ✓

**Minor drift (±1-2 lines — executor should grep, not trust the exact number):**
- **`connectors_live/index.ex`**: context D-23 cites `:79`/`:82`/`:85`; actual is `:78` (`label={runtime.status}`),
  `:83` (`runtime.current_run_id`), `:86` (`runtime.host_session_id`). Same offenders, shifted +1/-2.
- **`ApprovalCopy.evidence_rows/1`**: context said the raw-status row is at "~215" (via `evidence_rows/1`
  "~215") — the fn *starts* at `:209`, the offending row is at exactly `:215`. Consistent.

**Material drift (flag for D-03 executor):**
- **`coming_soon_live.ex:40`**: context D-03 describes the bespoke not-found `<h1>` as "nested in a
  redundant `.scoria-pagehead` div". Actual: the not-found `<h1>Capability not found</h1>` at `:40` is
  nested in a hand-inlined **`.scoria-stub`** block (a duplicate of `stub_page/1`), NOT `.scoria-pagehead`.
  There IS a separate `.scoria-pagehead` at `:29` in a *different* render branch. So `coming_soon_live` has
  TWO hand-rolled header shapes to reconcile: the `:29` pagehead branch → `page_header/1`, and the `:40`
  `.scoria-stub` not-found branch → either `stub_page/1` (`ui.ex:489`) or a sanctioned page-level not-found
  header (D-03). Do not assume a single `.scoria-pagehead`-nested `<h1>`.

**Not independently opened (trusted from context, plausible):** `ui.ex:~1376` `evidence_text/1`,
`ui.ex:~441` `object_header/1` status_label call (the `object_header/1` body at `:437-480` confirms it
calls `status_label(assigns.status)` at `:441` ✓), `workflows.ex` writers (~393/~430/~679) and audit-event
write (~683-720), `04-components.css` approval-chrome line ranges (~841-943).

---

## Metadata

**Analog search scope:** `lib/scoria_web/{ui.ex,approval_copy.ex}`, `lib/scoria_web/live/**`,
`lib/scoria_web/components/approval_inbox_component.ex`, `lib/scoria/workflows/remote_approval_projection.ex`,
`test/scoria_web/{ui_drift_guard,ds06_drift_guard}_test.exs`, `assets/css/04-components.css`.
**Files scanned/opened:** ~14 read in full or targeted; grep-mapped ~20.
**Pattern extraction date:** 2026-07-03
**No source files modified** (read-only); only this PATTERNS.md written.
