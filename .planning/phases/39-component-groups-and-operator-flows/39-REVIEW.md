---
phase: 39-component-groups-and-operator-flows
reviewed: 2026-07-03T00:00:00Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - lib/scoria_web/ui.ex
  - lib/scoria_web/copy.ex
  - lib/scoria_web/incident_copy.ex
  - lib/scoria_web/dataset_copy.ex
  - lib/scoria_web/review_copy.ex
  - lib/scoria_web/connector_copy.ex
  - lib/scoria_web/approval_copy.ex
  - lib/scoria/workflows.ex
  - lib/scoria/workflows/remote_approval_projection.ex
  - lib/scoria_web/components/approval_inbox_component.ex
  - lib/scoria_web/live/approvals_live/index.ex
  - lib/scoria_web/live/orchestrator_live.ex
  - lib/scoria_web/live/workflow_live/index.ex
  - lib/scoria_web/live/eval_spec_live/index.ex
  - lib/scoria_web/live/prompt_live/index.ex
  - lib/scoria_web/live/coming_soon_live.ex
  - lib/scoria_web/live/dataset_live/index.ex
  - lib/scoria_web/live/connectors_live/index.ex
  - lib/scoria_web/live/review_queue_live.ex
  - lib/scoria_web/live/incidents_live/index.ex
  - lib/scoria_web/live/incidents_live/show.ex
  - assets/css/04-components.css
  - priv/repo/dev_seed.exs
  - priv/dev/e2e/ia_orientation.spec.mjs
findings:
  critical: 1
  warning: 2
  info: 2
  total: 5
status: issues_found
---

# Phase 39: Code Review Report

**Reviewed:** 2026-07-03T00:00:00Z
**Depth:** standard
**Files Reviewed:** 23
**Status:** issues_found

## Summary

Phase 39 migrates dashboard pages to the shared `page_header/1`/`table/1`/`drawer/1`
component vocabulary, adds the copy modules (`ApprovalCopy`, `IncidentCopy`, etc.), a
Pending|Decided approval scope with an audit-sourced decision receipt, and a
decided-approval projection. The copy modules are uniformly defensive (every branch has a
safe `_ ->` fallback, `String.to_existing_atom` is always rescued, deep-link resolution is
UUID-validated and tenant-scoped — no IDOR). Most of the diff is presentation and is clean.

One real correctness defect stands out: the Review Queue `dismiss_candidate` handler uses a
`with` with no `else`, so any error/stale return from the dismiss write is returned verbatim
from `handle_event/3` and crashes the LiveView. A second, softer defect is that a successful
approval decision followed by a failed run-resume reports a misleading "could not record"
error and leaves the inbox/drawer stale.

## Critical Issues

### CR-01: `dismiss_candidate` `with` has no `else` — LiveView crashes on the error path

**File:** `lib/scoria_web/live/review_queue_live.ex:53-64`
**Issue:** The handler returns `{:noreply, socket}` only on the fully-successful branch:

```elixir
def handle_event("dismiss_candidate", _params, socket) do
  with %{} = candidate <- socket.assigns.selected_candidate,
       {:ok, updated} <- Eval.dismiss_review_candidate(candidate.id) do
    {:noreply, ...}
  end
end
```

`Eval.dismiss_review_candidate/1` → `ReviewQueue.dismiss_candidate/1` returns `{:error, changeset}`
on a failed `Repo.update` (its `error -> error` clause), and `selected_candidate` can be `nil`.
When either clause fails, the `with` returns the non-matching value (`{:error, changeset}` or
`nil`) directly from `handle_event/3`. Neither is a valid LiveView callback return, so the
LiveView process crashes instead of surfacing an error to the operator. This is reachable in
practice: a concurrent dismiss, a stale/optimistic-lock conflict, or any validation failure on
the candidate update lands on the error branch. (Separately, `ReviewQueue.dismiss_candidate/1`
does `Repo.get!/2`, which raises `Ecto.NoResultsError` if the candidate was already removed —
that also propagates uncaught.)
**Fix:** Add an `else` that keeps the callback contract and shows a notice:

```elixir
def handle_event("dismiss_candidate", _params, socket) do
  with %{} = candidate <- socket.assigns.selected_candidate,
       {:ok, updated} <- Eval.dismiss_review_candidate(candidate.id) do
    {:noreply,
     socket
     |> assign(:notice, "Candidate dismissed")
     |> assign(:selected_candidate, updated)
     |> assign(:selected_candidate_id, nil)
     |> refresh_queue()}
  else
    _ ->
      {:noreply, assign(socket, :notice, "Could not dismiss this candidate. Refresh and try again.")}
  end
end
```

## Warnings

### WR-01: Successful decision + failed resume reports a false "could not record" error and leaves the UI stale

**File:** `lib/scoria_web/live/approvals_live/index.ex:634-668`
**Issue:** In `record_approval_decision/2`, `Workflows.approve/3` persists the decision (and its
audit event) *first*, then `maybe_resume_approval/3` attempts `Resume.resume_run/1`. If resume
returns `{:error, reason}` (e.g. the run is not currently resumable), the `with/else` branch runs
`put_flash(:error, approval_error_message(status, reason))` + a `:fail` toast reading
`"Could not record #{status} approval decision: ..."`. That message is factually wrong — the
decision *was* recorded; only the resume failed. The else branch also returns the original
`socket` (no `reload_inbox`, no `push_patch` to clear `?approval=`), so the just-decided approval
keeps rendering as pending in the drawer/inbox until an unrelated PubSub reload arrives. This
blurs a safety-relevant distinction (was the durable decision written or not?).
**Fix:** Treat the write as the success boundary. On resume failure, keep the decision toast but
add a distinct advisory, and still reload/clear the selection:

```elixir
{:error, reason} ->
  updated_socket
  |> assign(:decision_modal, nil)
  |> put_toast(tone: :warn,
       message: "Decision recorded, but the run could not resume: #{resume_reason(reason)}.")
  |> push_patch(to: approvals_path(socket.assigns[:scoria_base] || "", patch_params(socket, %{})))
```

Reserve the `"Could not record ..."` message for the genuine `Workflows.approve/3` failure branch
only.

### WR-02: `has_more` off-by-one shows a "Load more" that returns no new rows

**File:** `lib/scoria_web/live/approvals_live/index.ex:234`
**Issue:** `has_more={@scope == "decided" and length(@approval_inbox) >= @decided_limit}`. When the
decided history contains exactly `@decided_limit` rows and no more, the count equals the limit, so
"Load more" renders. Clicking it bumps the limit and re-fetches, returns the same rows, and only
then hides the button — presenting an affordance that does nothing on first click. The standard
fix is to fetch `limit + 1` and derive `has_more` from the presence of the extra row.
**Fix:** Request `@decided_limit + 1` from `list_decided_approvals/1`, set
`has_more = fetched > @decided_limit`, and display only the first `@decided_limit` rows. Or, more
cheaply, compare against a separate total count rather than `>=` on the capped page length.

## Info

### IN-01: Currency computed via float division

**File:** `lib/scoria_web/approval_copy.ex:369-370`
**Issue:** `money_amount/1` formats money with `:erlang.float_to_binary(cents / 100, decimals: 2)`.
`decimals: 2` masks the rounding for display, but float arithmetic on money is a fragile pattern if
this helper is ever reused for anything beyond a display label.
**Fix:** Format from integer cents directly, e.g. `"$#{div(cents, 100)}.#{rem(cents, 100) |> Integer.to_string() |> String.pad_leading(2, "0")}"`, keeping the value exact.

### IN-02: `decision_receipts` assign is not reset when leaving the Decided scope

**File:** `lib/scoria_web/live/approvals_live/index.ex:413-419`
**Issue:** The pending-scope `reload_inbox/1` clause does not clear `:decision_receipts`, so stale
decided receipts linger in assigns after switching Decided → Pending. It is currently harmless
(the inbox component only reads `@decision_receipts` when `scope == "decided"`), but it is dead
state that will bite if the pending view ever starts consuming that map.
**Fix:** Assign `:decision_receipts, %{}` in the pending `reload_inbox/1` clause.

---

_Reviewed: 2026-07-03T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
