defmodule ScoriaWeb.ApprovalsLiveTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end
end

defmodule ScoriaWeb.ApprovalsLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_scoria_approvals_key",
    signing_salt: "scoria_approvals_salt"
  )

  plug(ScoriaWeb.ApprovalsLiveTest.Router)
end

defmodule ScoriaWeb.ApprovalsLiveTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows
  alias Scoria.Workflows.Runtime
  alias Scoria.Workflows.RemoteApprovalProjection

  @endpoint ScoriaWeb.ApprovalsLiveTest.Endpoint

  defmodule ApprovalHandlers do
    def wait_for_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "test_tool",
         arguments: %{"env" => "prod"},
         reason: "Requires approval",
         actor_id: "operator-live",
         tenant_id: "tenant-live",
         trace_id: "trace-#{run.id}"
       }}
    end

    def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "status" => "approved"}}
  end

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.ApprovalsLiveTest.Endpoint,
      secret_key_base:
        "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    Application.put_env(:scoria, :workflow_runtime_handlers, %{
      "approval" => {ApprovalHandlers, :succeed}
    })

    start_supervised!(ScoriaWeb.ApprovalsLiveTest.Endpoint)
    :ok
  end

  defp session_conn(session \\ %{}) do
    session =
      %{"tenant_id" => "tenant-live", "actor_id" => "operator-live"}
      |> Map.merge(session)

    build_conn()
    |> Plug.Test.init_test_session(session)
    |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.ApprovalsLiveTest.Endpoint)
  end

  defp pending_approval(opts \\ []) do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        tenant_id: Keyword.get(opts, :tenant_id, "tenant-live")
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    {:ok, approval} =
      Runtime.execute_step(step.id, handler: {ApprovalHandlers, :wait_for_approval})

    %{run: run, step: step, approval: approval}
  end

  test "renders empty inbox when no approvals are pending" do
    {:ok, _view, html} = live(session_conn(), "/scoria/approvals")

    assert html =~ "Approvals"
    assert html =~ "Requests that need a person to decide before Scoria continues."
    assert html =~ "Requests appear here when Scoria needs a person to approve or deny an action."
    refute html =~ "Operator-gated"
    refute html =~ "workflow-owned decision"
    refute html =~ "side-effecting"

    assert html =~
             ~s(<table class="scoria-table" id="approvals" aria-label="Pending approval queue">)

    refute html =~ ~s(role="group" aria-label="Row density")
    refute html =~ "phx-value-density"
    refute html =~ "scoria-table--compact"
    refute html =~ "scoria-table--comfortable"
    assert html =~ "No approvals waiting"
    refute html =~ "<h2>Approval inbox</h2>"
    refute html =~ ~s(<p class="scoria-eyebrow">approvals</p>)
    refute html =~ "Approval request"
  end

  test "approvals source uses shared table, drawer, and final modal contracts" do
    live_source = File.read!("lib/scoria_web/live/approvals_live/index.ex")
    inbox_source = File.read!("lib/scoria_web/components/approval_inbox_component.ex")

    assert live_source =~ "<.drawer"
    assert live_source =~ "<.modal"
    assert live_source =~ "ApprovalCopy.approve_label"
    assert live_source =~ "ApprovalCopy.reject_label"
    assert live_source =~ "Keep reviewing"
    assert inbox_source =~ "<.table"
    assert inbox_source =~ ~s(id="approvals")
    assert inbox_source =~ ~s("Pending approval queue")
    assert inbox_source =~ ~s(label="Request")
    assert inbox_source =~ ~s(label="Policy")
    assert inbox_source =~ ~s(label="Requested by")
    assert inbox_source =~ ~s(label="Waiting")
    assert inbox_source =~ ~s(label="Run")
    refute inbox_source =~ "<:eyebrow>approvals</:eyebrow>"
    refute inbox_source =~ "<:title>Approval inbox</:title>"
    refute inbox_source =~ ~s(label="Status")
    refute inbox_source =~ ~s(label="Consequence")
    refute inbox_source =~ ~s(label="Context")
    refute live_source =~ "set_density"
    refute live_source =~ "approval_table_density"
    refute inbox_source =~ "on_density_change"

    # D-10: the pending inbox stays PubSub-reload driven with assign-based lookups
    # — it must never be migrated to stream/3 (decided history is capped +
    # load-more instead, per D-10's own explicit scoping).
    refute live_source =~ "Phoenix.LiveView.stream("
    refute live_source =~ "stream(socket, :approval_inbox"
    refute inbox_source =~ "phx-update=\"stream\""

    # D-20: decided-at/decider are sourced from the decision AuditOutboxEvent
    # (inserted_at/actor_ref), batch-loaded by the visible id-set for the
    # history table — never from updated_at or get_approval_lineage!'s
    # requesting actor.
    assert live_source =~ "defp approval_decision_event(approval)"
    assert live_source =~ "defp decision_events_by_approval_id("
    assert live_source =~ "event.actor_ref"
    assert live_source =~ "event.inserted_at"

    for forbidden <- [
          "stone-",
          "gray-",
          "emerald-",
          "amber-",
          "rose-",
          "red-",
          "blue-",
          "bg-black"
        ] do
      refute live_source =~ forbidden
      refute inbox_source =~ forbidden
    end
  end

  test "HITL approval request renders modal and handles approve" do
    %{run: run, step: step, approval: approval} = pending_approval()

    {:ok, view, _html} =
      live(
        session_conn(%{"actor_id" => "operator-live", "tenant_id" => "tenant-live"}),
        "/scoria/approvals?runtime=#{run.id}"
      )

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    html = render(view)
    assert html =~ "test_tool approval"
    assert html =~ "test_tool"
    assert html =~ "Requires approval"
    assert html =~ "Approve request"
    assert html =~ "Deny request"
    refute html =~ "audit evidence"
    assert html =~ "Identifiers"
    assert html =~ "Request payload"
    refute html =~ ~r/<details[^>]*class="[^"]*scoria-raw-evidence[^"]*"[^>]*open/
    assert html =~ ~s(data-raw-evidence-copy)
    assert html =~ ~s(aria-label="Copy request payload")
    assert html =~ "View run details"
    refute html =~ "Expected effect"
    refute html =~ "Decision required"
    refute html =~ "arguments_preview"

    render_click(view, "approve", %{})

    eventually(fn -> not (render(view) =~ "test_tool approval") end)

    updated_approval = Repo.get!(Scoria.Observe.Approval, approval.id)
    assert updated_approval.status == "approved"
    assert Workflows.get_run!(run.id).status == "completed"
    assert Workflows.get_step!(step.id).status == "completed"

    approved_event =
      Repo.get_by!(AuditOutboxEvent,
        workflow_run_id: run.id,
        event_type: "approval.approved",
        trace_id: "trace-#{run.id}"
      )

    assert approved_event.actor_ref == "operator-live"
    assert approved_event.redacted_refs["approval_id"] == approval.id
  end

  test "HITL approval request handles reject" do
    %{run: run, step: step, approval: approval} = pending_approval()

    {:ok, view, _html} =
      live(
        session_conn(%{"actor_id" => "operator-live", "tenant_id" => "tenant-live"}),
        "/scoria/approvals?runtime=#{run.id}"
      )

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    render_click(view, "reject", %{})

    eventually(fn -> Repo.get!(Scoria.Observe.Approval, approval.id).status == "rejected" end)
    assert Workflows.get_run!(run.id).status == "waiting_for_approval"
    assert Workflows.get_step!(step.id).status == "waiting_for_approval"

    rejected_event =
      Repo.get_by!(AuditOutboxEvent,
        workflow_run_id: run.id,
        event_type: "approval.rejected",
        trace_id: "trace-#{run.id}"
      )

    assert rejected_event.actor_ref == "operator-live"
    assert rejected_event.redacted_refs["approval_id"] == approval.id
  end

  test "HITL modal dismiss closes without approving" do
    workflow_run_id = Ecto.UUID.generate()
    {:ok, view, _html} = live(session_conn(), "/scoria/approvals?runtime=#{workflow_run_id}")

    projection = %{
      id: Ecto.UUID.generate(),
      tool_name: "dismiss_tool",
      reason: "Review later",
      arguments_preview: %{"env" => "staging"},
      workflow_run_id: workflow_run_id,
      status: "pending"
    }

    send(view.pid, {:hitl_request, projection})
    assert render(view) =~ "dismiss_tool approval"

    html =
      view
      |> element("button[phx-value-decision='approve']")
      |> render_click()

    assert html =~ "Keep reviewing"

    render_click(view, "dismiss_approval", %{})

    refute render(view) =~ "dismiss_tool approval"
  end

  test "approval_decided clears active modal" do
    workflow_run_id = Ecto.UUID.generate()
    {:ok, view, _html} = live(session_conn(), "/scoria/approvals?runtime=#{workflow_run_id}")
    approval_id = Ecto.UUID.generate()

    send(
      view.pid,
      {:hitl_request,
       %{
         id: approval_id,
         tool_name: "sync_tool",
         workflow_run_id: workflow_run_id,
         status: "pending"
       }}
    )

    assert render(view) =~ "sync_tool approval"

    send(view.pid, {:approval_decided, approval_id, "approved"})

    refute render(view) =~ "sync_tool approval"
  end

  test "select_approval opens the modal for a chosen inbox row" do
    %{approval: approval} = pending_approval()

    {:ok, view, _html} = live(session_conn(), "/scoria/approvals")

    html = render(view)
    assert html =~ "test_tool"
    refute html =~ "test_tool approval"

    render_click(view, "select_approval", %{"id" => approval.id})
    assert render(view) =~ "test_tool approval"
    assert render(view) =~ "test_tool"
  end

  test "plain inbox does not auto-open a pending approval" do
    pending_approval()

    {:ok, _view, html} = live(session_conn(), "/scoria/approvals")

    assert html =~ "test_tool"
    assert html =~ "Inspect approval"
    refute html =~ "Approval request"
  end

  test "unfocused HITL approval request highlights inbox row without opening drawer" do
    {:ok, view, _html} = live(session_conn(), "/scoria/approvals")
    %{approval: approval} = pending_approval()

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    html = render(view)
    assert html =~ "test_tool"
    assert html =~ ~s(data-highlight="true")
    refute html =~ "Approval request"
  end

  test "unrelated hitl_request broadcast preserves the payload details stable DOM id" do
    %{run: run, approval: approval} = pending_approval()

    {:ok, view, _html} =
      live(
        session_conn(%{"actor_id" => "operator-live", "tenant_id" => "tenant-live"}),
        "/scoria/approvals?runtime=#{run.id}"
      )

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    html_before = render(view)
    payload_id = "approval-raw-#{approval.id}"
    assert html_before =~ ~s(id="#{payload_id}")

    # D-14: an unrelated approval's broadcast (a different run — does not match
    # this LiveView's runtime focus) reloads the inbox but must NOT reassign
    # @active_approval. The payload <details> keeps its stable per-approval DOM
    # id so LiveView patches the existing node in place instead of tearing it
    # down, which is what preserves a user-opened <details> in the real
    # browser. The native open/closed state itself is invisible to
    # LiveViewTest's server-rendered HTML (no phx event drives it) — this test
    # asserts the server-renderable half (stable id + unchanged active
    # approval); the JS-observable half is the Tier 2 Playwright lane
    # (priv/dev/e2e).
    unrelated_projection = %{
      id: Ecto.UUID.generate(),
      tool_name: "unrelated_tool",
      workflow_run_id: Ecto.UUID.generate(),
      status: "pending"
    }

    send(view.pid, {:hitl_request, unrelated_projection})

    html_after = render(view)
    assert html_after =~ ~s(id="#{payload_id}")
    assert html_after =~ "test_tool approval"
    refute html_after =~ "unrelated_tool approval"
  end

  test "stale approval decision surfaces friendly flash" do
    %{run: run, approval: approval} = pending_approval()

    {:ok, view, _html} =
      live(
        session_conn(%{"actor_id" => "operator-live", "tenant_id" => "tenant-live"}),
        "/scoria/approvals?runtime=#{run.id}"
      )

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    assert {:ok, _} = Workflows.approve(approval.id, "approved", %{actor_id: "other-operator"})
    send(view.pid, {:approval_decided, approval.id, "approved"})
    send(view.pid, {:hitl_request, projection})
    render_click(view, "approve", %{})

    # UAT-2/UAT-3: the error branch surfaces BOTH a fail-tone toast and a
    # fail-tone flash banner, end-to-end (put_flash + put_toast → flash_group/toast).
    html = render(view)
    assert html =~ "already decided by another operator"
    assert html =~ "scoria-flash--fail"
    assert html =~ ~s(role="alert")
    assert html =~ "scoria-toast--fail"
    # Flash carries a tone icon so status is never communicated by color alone (a11y).
    assert html =~ "<svg"
  end

  test "focused runtime highlights non-matching inbox approval without replacing modal" do
    session_a = "session-focus-a"

    {:ok, run_a} =
      Workflows.create_run(%{
        root_role_id: "executor",
        tenant_id: "tenant-live",
        session_id: session_a
      })

    {:ok, step_a} =
      Workflows.create_step(run_a.id, %{
        sequence: 1,
        kind: "approval_gate",
        role_id: "critic",
        status: "running"
      })

    {:ok, approval_a} =
      Workflows.mark_waiting_for_approval(run_a.id, step_a.id, %{
        tool_name: "run_a_tool",
        arguments: %{"env" => "prod"},
        reason: "Needs approval"
      })

    {:ok, run_b} =
      Workflows.create_run(%{
        root_role_id: "executor",
        tenant_id: "tenant-live",
        session_id: "session-focus-b"
      })

    {:ok, step_b} =
      Workflows.create_step(run_b.id, %{
        sequence: 1,
        kind: "approval_gate",
        role_id: "critic",
        status: "running"
      })

    {:ok, approval_b} =
      Workflows.mark_waiting_for_approval(run_b.id, step_b.id, %{
        tool_name: "run_b_tool",
        arguments: %{"env" => "staging"},
        reason: "Needs approval"
      })

    projection_a = RemoteApprovalProjection.get_approval_lineage!(approval_a.id)
    projection_b = RemoteApprovalProjection.get_approval_lineage!(approval_b.id)

    {:ok, view, _html} = live(session_conn(), "/scoria/approvals?runtime=#{session_a}")

    drain_pubsub_messages()

    send(view.pid, {:hitl_request, projection_a})
    assert render(view) =~ "run_a_tool approval"
    assert render(view) =~ "run_a_tool"

    send(view.pid, {:hitl_request, projection_b})

    html = render(view)
    assert html =~ "run_a_tool"
    assert html =~ "run_a_tool approval"
    assert html =~ "run_b_tool"
    assert html =~ ~s(data-highlight="true")
  end

  test "matching focus opens modal for same workflow run" do
    run_id = Ecto.UUID.generate()

    {:ok, view, _html} = live(session_conn(), "/scoria/approvals?runtime=#{run_id}")

    send(
      view.pid,
      {:hitl_request,
       %{
         id: Ecto.UUID.generate(),
         tool_name: "focused_tool",
         workflow_run_id: run_id,
         status: "pending"
       }}
    )

    assert render(view) =~ "focused_tool"
    assert render(view) =~ "focused_tool approval"
  end

  test "approvals inbox boots and renders the toast region shell" do
    {:ok, _view, html} = live(session_conn(), "/scoria/approvals")

    # UAT-1: the modified screen mounts cleanly and the toast-region wiring is present.
    assert html =~ "scoria-toast-region"
    assert html =~ "Approvals"
    assert html =~ ~s(id="approvals" aria-label="Pending approval queue")
    refute html =~ "<h2>Approval inbox</h2>"
  end

  test "approve decision renders a pass-tone toast with granted copy" do
    %{run: run, approval: approval} = pending_approval()

    {:ok, view, _html} =
      live(
        session_conn(%{"actor_id" => "operator-live", "tenant_id" => "tenant-live"}),
        "/scoria/approvals?runtime=#{run.id}"
      )

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    render_click(view, "approve", %{})

    # UAT-2 (server-renderable half): tone, copy, role, dismiss control, and the
    # phx-mounted auto-dismiss directive all render. The actual timed hide/fade is
    # JS-driven and is asserted by the Tier 2 Playwright lane (priv/dev/e2e).
    eventually(fn -> render(view) =~ "scoria-toast--pass" end)
    html = render(view)
    assert html =~ "scoria-toast--pass"
    assert html =~ "Approval granted."
    assert html =~ ~s(role="status")
    assert html =~ "phx-mounted"
    assert html =~ ~s(aria-label="Dismiss")
    refute html =~ "scoria-toast--warn"
  end

  test "reject decision renders a warn-tone toast with paused copy" do
    %{run: run, approval: approval} = pending_approval()

    {:ok, view, _html} =
      live(
        session_conn(%{"actor_id" => "operator-live", "tenant_id" => "tenant-live"}),
        "/scoria/approvals?runtime=#{run.id}"
      )

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    render_click(view, "reject", %{})

    # UAT-2: a rejection keeps the workflow paused, so it must NOT report the green
    # pass toast — the tone-by-decision distinction is safety-relevant (WR-03).
    eventually(fn -> render(view) =~ "scoria-toast--warn" end)
    html = render(view)
    assert html =~ "scoria-toast--warn"
    assert html =~ "Approval denied - run is still waiting for approval."
    refute html =~ "scoria-toast--pass"
  end

  # RAIL-01, D-05 (plan 56.1-05 Task 3): `maybe_resume_approval/3` calls
  # `Resume.resume_run/1` AFTER `Workflows.approve/3` has already committed
  # the decision. A run halted by a per-run rail falls through
  # `Workflows.resume_run/1`'s catch-all as `{:error, :not_resumable}` --
  # the decision WAS recorded, only the resume did not happen. Before this
  # fix the generic `approval_error_message/2` fallback rendered "Could not
  # record approved approval decision", telling the operator their approval
  # failed when it did not.
  test "approving a decision on a run halted by a per-run rail shows an accurate info-tone toast, not a false failure" do
    %{run: run, step: step, approval: approval} = pending_approval()

    envelope = %{
      "status" => "run_halted",
      "reason_code" => "max_steps_exceeded",
      "rail" => "max_steps",
      "limit" => 1,
      "observed" => 1,
      "attempted" => 2,
      "run_id" => run.id,
      "step_id" => step.id,
      "halted_at" => DateTime.to_iso8601(DateTime.utc_now()),
      "site" => "workflow_runtime_step"
    }

    assert {:ok, %Scoria.Workflows.Run{status: "halted"}} =
             Workflows.halt_run(run.id, step.id, envelope)

    # D-05: halting a run never modifies its pending Approval rows.
    assert Workflows.get_approval!(approval.id).status == "pending"

    # RAIL-01 D-18/D-01: a halted run's own dashboard rendering must not
    # raise, and it renders with the failure tone (asserted separately in
    # eval_vocabulary_test.exs's tone/1 unit test). This LiveView mount
    # succeeding, below, is the end-to-end proof for the approvals surface.
    {:ok, view, _html} =
      live(
        session_conn(%{"actor_id" => "operator-live", "tenant_id" => "tenant-live"}),
        "/scoria/approvals?runtime=#{run.id}"
      )

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    render_click(view, "approve", %{})

    eventually(fn -> render(view) =~ "scoria-toast--info" end)
    html = render(view)

    assert html =~ "scoria-toast--info"

    assert html =~
             "Approval decision recorded. This run was halted by a per-run rail and cannot be resumed."

    refute html =~ "Could not record"
    refute html =~ "Approval granted."
    refute html =~ "scoria-toast--fail"

    # The decision itself WAS recorded despite the run staying halted.
    assert Workflows.get_approval!(approval.id).status == "approved"
  end

  # D-21: fixtures MUST route decided rows through approve/3 (not Repo.update_all)
  # so the real path emits the decision audit event and the history surface is
  # exercised honestly.
  defp decide_approval(approval, status, actor_id \\ "ops-lead") do
    {:ok, updated} = Workflows.approve(approval.id, status, %{actor_id: actor_id})
    updated
  end

  describe "Pending|Decided URL scope (D-17)" do
    test "decided scope renders the Decision column, hides Waiting, and reads View decision" do
      %{approval: approval} = pending_approval()
      decide_approval(approval, "approved")

      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?scope=decided")

      assert html =~ ~s(aria-label="Decided approval history")
      assert html =~ "Decision"
      assert html =~ "View decision"
      refute html =~ "Waiting"
      refute html =~ "Inspect approval"
    end

    test "pending scope stays the default and keeps the original table contract" do
      {:ok, _view, html} = live(session_conn(), "/scoria/approvals")

      assert html =~ ~s(aria-label="Pending approval queue")
      assert html =~ "Waiting"
      refute html =~ "View decision"
    end

    test "decided outcome filter maps the Denied display word to the rejected schema status" do
      %{approval: approved} = pending_approval()
      decide_approval(approved, "approved")

      %{approval: rejected} = pending_approval()
      decide_approval(rejected, "rejected")

      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?scope=decided&outcome=denied")

      # D-24d: the query facet excludes the approved row (badge tone :pass) and
      # keeps only the denied row (badge tone :fail) — asserted on the RENDERED
      # badge class attribute (not a bare substring), since the compiled
      # stylesheet always defines .scoria-badge--pass/--fail rules in <style>
      # regardless of which rows are present.
      assert html =~ "scoria-badge scoria-badge--fail"
      refute html =~ "scoria-badge scoria-badge--pass"
    end

    test "decided outcome filter for approved excludes denied rows" do
      %{approval: approved} = pending_approval()
      decide_approval(approved, "approved")

      %{approval: rejected} = pending_approval()
      decide_approval(rejected, "rejected")

      {:ok, _view, html} =
        live(session_conn(), "/scoria/approvals?scope=decided&outcome=approved")

      assert html =~ "scoria-badge scoria-badge--pass"
      refute html =~ "scoria-badge scoria-badge--fail"
    end

    test "an unrecognized scope/outcome falls back to the safe pending default" do
      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?scope=bogus&outcome=bogus")

      assert html =~ ~s(aria-label="Pending approval queue")
    end
  end

  describe "?approval=<id> deep-link (D-09, T-39-07-I)" do
    test "opens the drawer directly on mount from the URL" do
      %{approval: approval} = pending_approval()

      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?approval=#{approval.id}")

      assert html =~ "test_tool approval"
    end

    test "resolves a decided approval even from a pending-scope URL" do
      %{approval: approval} = pending_approval()
      decide_approval(approval, "approved")

      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?approval=#{approval.id}")

      assert html =~ "test_tool approval"
    end

    test "never opens an approval belonging to another tenant" do
      %{approval: approval} = pending_approval(tenant_id: "tenant-other")

      {:ok, _view, html} =
        live(
          session_conn(%{"tenant_id" => "tenant-live"}),
          "/scoria/approvals?approval=#{approval.id}"
        )

      refute html =~ "test_tool approval"
    end

    test "an unresolvable id renders the plain inbox without crashing" do
      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?approval=not-a-uuid")

      assert html =~ "Approvals"
    end

    test "selecting an approval patches the URL to a deep-linkable ?approval=<id>" do
      %{approval: approval} = pending_approval()

      {:ok, view, _html} = live(session_conn(), "/scoria/approvals")

      render_click(view, "select_approval", %{"id" => approval.id})

      assert_patch(view, "/scoria/approvals?approval=#{approval.id}")
    end

    test "dismissing the drawer patches the approval param away" do
      %{approval: approval} = pending_approval()

      {:ok, view, _html} = live(session_conn(), "/scoria/approvals?approval=#{approval.id}")

      render_click(view, "dismiss_approval", %{})

      assert_patch(view, "/scoria/approvals")
    end
  end

  describe "decided read-only receipt (D-19, D-20, D-27)" do
    test "a decided approval's drawer shows a read-only receipt with no Approve/Deny buttons" do
      %{approval: approval} = pending_approval()
      decide_approval(approval, "approved", "ops-lead-1")

      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?approval=#{approval.id}")

      assert html =~ "Approved by ops-lead-1"
      assert html =~ "Start a new request"
      refute html =~ "Approve request"
      refute html =~ "Deny request"
      refute html =~ ~s(aria-label="Approval actions")
    end

    test "attribution comes from the decision event's actor, not the request event" do
      %{approval: approval} = pending_approval()
      decide_approval(approval, "rejected", "ops-lead-99")

      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?approval=#{approval.id}")

      # request actor is "operator-live" (per the wait_for_approval fixture);
      # the receipt must attribute to the DECIDER (ops-lead-99), never the
      # requester.
      assert html =~ "Denied by ops-lead-99"
      refute html =~ "Denied by operator-live"
    end

    test "the decided history row shows the same audit-sourced receipt" do
      %{approval: approval} = pending_approval()
      decide_approval(approval, "approved", "ops-lead-2")

      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?scope=decided")

      assert html =~ "Approved by ops-lead-2"
    end

    test "an expired row with no audit event renders no fabricated time or actor" do
      %{approval: approval} = pending_approval()

      # D-21: this deliberately bypasses approve/3 to reproduce the real
      # no-producer expiry state (no decision audit event, no updated_at
      # bump) so the honest "time unavailable" fallback path is exercised.
      Repo.get!(Scoria.Observe.Approval, approval.id)
      |> Ecto.Changeset.change(status: "expired")
      |> Repo.update!()

      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?scope=decided&outcome=expired")

      assert html =~ "Decided · time unavailable"
      refute html =~ "Expired by"
    end

    test "the drawer for an expired approval with no audit event also renders no fabrication" do
      %{approval: approval} = pending_approval()

      Repo.get!(Scoria.Observe.Approval, approval.id)
      |> Ecto.Changeset.change(status: "expired")
      |> Repo.update!()

      {:ok, _view, html} = live(session_conn(), "/scoria/approvals?approval=#{approval.id}")

      assert html =~ "Decided · time unavailable"
      refute html =~ "Expired by"
    end
  end

  defp drain_pubsub_messages do
    receive do
      _ -> drain_pubsub_messages()
    after
      0 -> :ok
    end
  end
end
