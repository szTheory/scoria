---
phase: 44-dashboard-auth-seam
reviewed: 2026-07-07T20:42:55Z
depth: standard
files_reviewed: 37
files_reviewed_list:
  - docs/MAINTAINERS.md
  - docs/adoption_lanes.md
  - docs/operator_verification.md
  - lib/scoria/eval.ex
  - lib/scoria/workflows/prompt_release.ex
  - lib/scoria_web/dashboard_scope.ex
  - lib/scoria_web/live/approvals_live/index.ex
  - lib/scoria_web/live/connectors_live/index.ex
  - lib/scoria_web/live/dataset_live/index.ex
  - lib/scoria_web/live/eval_spec_live/index.ex
  - lib/scoria_web/live/incidents_live/index.ex
  - lib/scoria_web/live/incidents_live/show.ex
  - lib/scoria_web/live/orchestrator_live.ex
  - lib/scoria_web/live/prompt_live/release_workbench_live.ex
  - lib/scoria_web/live/review_queue_live.ex
  - lib/scoria_web/live/workflow_live/index.ex
  - lib/scoria_web/live/workflow_live/show.ex
  - lib/scoria_web/operator_surface.ex
  - lib/scoria_web/router.ex
  - test/scoria/adoption_surface_test.exs
  - test/scoria_web/dashboard_scope_source_guard_test.exs
  - test/scoria_web/dashboard_scope_test.exs
  - test/scoria_web/live/approvals_live_integration_test.exs
  - test/scoria_web/live/approvals_live_test.exs
  - test/scoria_web/live/dashboard_auth_approvals_test.exs
  - test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs
  - test/scoria_web/live/dashboard_auth_prompts_test.exs
  - test/scoria_web/live/dashboard_auth_quality_data_test.exs
  - test/scoria_web/live/dashboard_auth_workflows_test.exs
  - test/scoria_web/live/dataset_live/index_test.exs
  - test/scoria_web/live/eval_spec_live/index_test.exs
  - test/scoria_web/live/orchestrator_live_test.exs
  - test/scoria_web/live/prompt_live/release_workbench_live_test.exs
  - test/scoria_web/live/prompt_live_test.exs
  - test/scoria_web/live/review_queue_live_test.exs
  - test/scoria_web/live/workflow_live_test.exs
  - test/scoria_web/router_test.exs
findings:
  critical: 3
  warning: 0
  info: 0
  total: 3
status: issues_found
---

# Phase 44: Code Review Report

**Reviewed:** 2026-07-07T20:42:55Z
**Depth:** standard
**Files Reviewed:** 37
**Status:** issues_found

## Summary

Reviewed the Phase 44 dashboard-auth changes across the listed docs, LiveViews, router/scope helpers, operator surface, prompt release workflow, and focused tests. I found three blocker issues: one release gate can be bypassed with forged LiveView events, one connector drawer path leaks cross-tenant connector details, and prompt approval violates the single-active-version release invariant.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: BLOCKER - Prompt release approval gate is enforced only by disabled buttons

**File:** `lib/scoria_web/live/prompt_live/release_workbench_live.ex:107`

**Issue:** `handle_event("request_release", ...)` and `handle_event("approve_release", ...)` perform the release workflow side effects without re-checking the same `can_approve?/4` predicate used to disable the rendered buttons. LiveView events are client-sent, so an operator can forge `request_release` while the UI button is disabled, create a pending approval without completed/matching eval evidence, then forge `approve_release` and activate the draft. The test coverage currently checks for a disabled button, but does not prove the server rejects the event.

**Fix:** Re-check the release readiness predicate inside both event handlers before creating or approving a release request. Add a regression test that calls the events while the CTA is disabled and asserts no approval is created and the draft remains inactive.

```elixir
def handle_event("request_release", _params, socket) do
  if release_ready?(socket) do
    # existing workflow request path
  else
    {:noreply,
     assign(socket, :rejection_notice, "Release requires completed matching eval evidence.")}
  end
end

def handle_event("approve_release", _params, socket) do
  if release_ready?(socket) do
    # existing approval path
  else
    {:noreply,
     socket
     |> assign(:show_approve_modal, false)
     |> assign(:rejection_notice, "Release requires completed matching eval evidence.")}
  end
end

defp release_ready?(socket) do
  can_approve?(
    socket.assigns.draft,
    socket.assigns.draft_run,
    socket.assigns.active,
    socket.assigns.active_run
  )
end
```

### CR-02: BLOCKER - Connector drawer accepts arbitrary connector ids outside tenant scope

**File:** `lib/scoria_web/live/connectors_live/index.ex:59`

**Issue:** `handle_event("open_connector_drawer", %{"id" => connector_id}, socket)` trusts the client-supplied id and calls `OperatorSurface.connector_drawer(connector_id)`. That surface delegates to `Connectors.get_connector_drawer/1`, which fetches the connector by id without applying the assigned tenant. The fleet list is tenant-filtered, but a forged LiveView event can request a connector from another tenant and expose drawer details such as label, key, endpoint, auth summary, grants, and capability snapshot. This contradicts the Phase 44 goal that dashboard authority comes from the assigned host scope, not client parameters.

**Fix:** Make the drawer lookup tenant-scoped and return `nil` or an error state when the id does not belong to the socket tenant. Add a regression test that mounts the dashboard as tenant A, sends `open_connector_drawer` with a tenant B connector id, and asserts tenant B connector details are not rendered.

```elixir
def handle_event("open_connector_drawer", %{"id" => connector_id}, socket) do
  drawer = OperatorSurface.connector_drawer(socket.assigns.tenant_id, connector_id)

  {:noreply,
   socket
   |> assign(:connector_drawer, drawer)
   |> assign(:runtime_drawer, nil)}
end
```

Implement the corresponding `OperatorSurface.connector_drawer/2` and connector query with `where: connector.id == ^connector_id and connector.tenant_id == ^tenant_id`.

### CR-03: BLOCKER - Prompt approval leaves multiple active prompt versions

**File:** `lib/scoria/workflows/prompt_release.ex:93`

**Issue:** After an approval is marked approved, `PromptRelease.approve/3` fetches the approved prompt template and calls `PromptRegistry.transition_status(template, "active")`. It does not demote or archive the current active template for the same `entity_id`, and it does not clear `is_current` on older versions. The release workbench UI says approval will activate the draft and demote the current active version, but the workflow can leave multiple active/current versions for the same prompt entity, making production prompt selection ambiguous.

**Fix:** Promote prompts through a single context function that archives or deactivates all other active/current templates for the same `entity_id` before activating the approved draft. Add a database constraint if the project supports a partial unique index for active/current rows, and add a test proving exactly one active/current version remains after approval.

```elixir
Repo.transaction(fn ->
  template = PromptRegistry.get_prompt_template!(template_id)

  from(p in PromptTemplate,
    where: p.entity_id == ^template.entity_id and p.id != ^template.id
  )
  |> Repo.update_all(set: [status: "archived", is_current: false])

  template
  |> Ecto.Changeset.change(status: "active", is_current: true)
  |> Repo.update!()
end)
```

---

_Reviewed: 2026-07-07T20:42:55Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
