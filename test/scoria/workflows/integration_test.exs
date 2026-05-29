defmodule Scoria.WorkflowsIntegrationTest.Router do
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

defmodule Scoria.WorkflowsIntegrationTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_integration_key",
    signing_salt: "integration_salt"
  )

  plug(Scoria.WorkflowsIntegrationTest.Router)
end

defmodule Scoria.WorkflowsIntegrationTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows.Run
  alias Scoria.Workflows
  alias Scoria.Workflows.{Resume, Runtime}

  @endpoint Scoria.WorkflowsIntegrationTest.Endpoint

  defmodule Handlers do
    def wait_for_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "publish",
         arguments: %{"env" => "prod"},
         reason: "Need approval",
         actor_id: "operator-integration",
         tenant_id: "tenant-integration",
         trace_id: "trace-#{run.id}"
       }}
    end

    def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "status" => "ok"}}
    def fail(_step, _run), do: {:error, :boom}
  end

  setup_all do
    Application.put_env(:scoria, Scoria.WorkflowsIntegrationTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "12344321"],
      debug_errors: true
    )

    :ok
  end

  setup do
    Application.put_env(:scoria, :workflow_runtime_handlers, %{"approval" => {Handlers, :succeed}})
    start_supervised!(Scoria.WorkflowsIntegrationTest.Endpoint)
    :ok
  end

  test "a run that pauses for approval can be resumed exactly from stored state" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "run-actor",
        tenant_id: "run-tenant",
        session_id: "run-session"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    {:ok, approval} = Runtime.execute_step(step.id, handler: {Handlers, :wait_for_approval})
    assert Workflows.get_run!(run.id).status == "waiting_for_approval"

    {:ok, _approval} =
      Workflows.approve(approval.id, "approved", %{
        actor_id: "decision-operator",
        tenant_id: "tenant-integration",
        trace_id: "trace-#{run.id}"
      })

    {:ok, _run} = Resume.resume_run(run.id, handlers: %{"approval" => {Handlers, :succeed}})

    eventually(fn -> Workflows.get_run!(run.id).status == "completed" end)
    assert Workflows.get_step!(step.id).status == "completed"

    approved_event =
      Repo.get_by!(AuditOutboxEvent,
        workflow_run_id: run.id,
        event_type: "approval.approved",
        trace_id: "trace-#{run.id}"
      )

    assert approved_event.actor_ref == "run-actor"
    assert approved_event.redacted_refs["approval_id"] == approval.id
    assert approved_event.redacted_refs["decision"] == "approved"
    assert approved_event.redacted_refs["session_id"] == "run-session"
    assert approved_event.metadata["metadata"]["decision_actor_id"] == "decision-operator"
  end

  test "a failed step can be retried without replaying already persisted side-effect boundaries" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "failing",
        role_id: "executor",
        status: "queued"
      })

    {:ok, _failed_step} = Runtime.execute_step(step.id, handler: {Handlers, :fail})
    checkpoints_before_retry = Workflows.list_run_checkpoints(run.id)
    {:ok, _run} = Resume.retry_failed_step(run.id, handlers: %{"failing" => {Handlers, :succeed}})

    eventually(fn -> Workflows.get_step!(step.id).status == "completed" end)

    checkpoints_after_retry = Workflows.list_run_checkpoints(run.id)

    assert Enum.count(Enum.filter(checkpoints_before_retry, &(&1.transition == "step_completed"))) ==
             0

    assert Enum.count(Enum.filter(checkpoints_after_retry, &(&1.transition == "step_completed"))) ==
             1
  end

  test "operator-visible LiveView state matches the durable recovery path" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{
        "actor_id" => "operator-integration",
        "tenant_id" => "tenant-integration"
      })
      |> Plug.Conn.put_private(:phoenix_endpoint, Scoria.WorkflowsIntegrationTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria/workflows/#{run.id}")

    {:ok, approval} = Runtime.execute_step(step.id, handler: {Handlers, :wait_for_approval})
    assert render(view) =~ "waiting_for_approval"

    {:ok, _approval} = Workflows.approve(approval.id, "approved")
    {:ok, _run} = Resume.resume_run(run.id, handlers: %{"approval" => {Handlers, :succeed}})

    eventually(fn -> render(view) =~ "completed" end)
    assert render(view) =~ "step_completed"
  end

  test "replay branch preserves the originally persisted live_tool_allowlist during execution" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        execution_mode: "replay",
        replay_overrides: %{"live_tool_allowlist" => ["publish"]}
      })

    persisted = Repo.get!(Run, run.id)

    assert {:error, changeset} =
             persisted
             |> Run.changeset(%{replay_overrides: %{"live_tool_allowlist" => ["publish", "delete"]}})
             |> Repo.update()

    assert {"live_tool_allowlist cannot expand after replay start", _} =
             Keyword.fetch!(changeset.errors, :replay_overrides)

    assert Repo.get!(Run, run.id).replay_overrides == %{"live_tool_allowlist" => ["publish"]}
  end

  test "replay runtime uses historical stub evidence without invoking the live handler" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        execution_mode: "replay",
        source_run_id: Ecto.UUID.generate(),
        source_checkpoint_id: Ecto.UUID.generate()
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    handler = fn _step, _run ->
      send(self(), :live_handler_called)
      {:ok, %{"status" => "live"}}
    end

    assert {:ok, _step} =
             Runtime.execute_step(step.id,
               handler: handler,
               replay_seam: %{
                 local_classification: :read,
                 tool_id: "repo.read",
                 action_class: "read",
                 risk_level: "low",
                 args_fingerprint: "same",
                 subject_ref: "repo:acme/scoria",
                 required_scopes: ["repo:read"],
                 grant_state: "active",
                 policy_key: "repo.read"
               },
               replay_source_evidence: %{
                 source_run_id: run.source_run_id,
                 source_checkpoint_id: run.source_checkpoint_id,
                 source_step_id: step.id,
                 source_audit_outbox_event_id: Ecto.UUID.generate(),
                 tool_id: "repo.read",
                 args_fingerprint: "same",
                 subject_ref: "repo:acme/scoria",
                 required_scopes: ["repo:read"],
                 grant_state: "active",
                 policy_key: "repo.read",
                 result: %{"status" => "stubbed"}
               }
             )

    refute_receive :live_handler_called
    assert Workflows.get_step!(step.id).result_envelope["status"] == "stubbed"
  end

  test "replay runtime blocks authority-expanding seams before handler execution" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        execution_mode: "replay"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    handler = fn _step, _run ->
      send(self(), :live_handler_called)
      {:ok, %{"status" => "live"}}
    end

    assert {:ok, _step} =
             Runtime.execute_step(step.id,
               handler: handler,
               replay_seam: %{
                 local_classification: :authority_expanding,
                 tool_id: "admin.grant",
                 action_class: "admin",
                 risk_level: "high",
                 authority_expanding: "re-auth",
                 grant_state: "reauth_required",
                 required_scopes: ["admin:write"],
                 policy_key: "admin.grant"
               }
             )

    refute_receive :live_handler_called
    assert Workflows.get_step!(step.id).status == "failed"
    assert Workflows.get_step!(step.id).error_envelope["status"] == "replay_blocked"
  end

end
