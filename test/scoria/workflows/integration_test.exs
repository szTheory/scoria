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
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
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
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    ensure_audit_outbox_table!()

    Application.put_env(:scoria, :workflow_runtime_handlers, %{"approval" => {Handlers, :succeed}})

    start_supervised!(Scoria.Workflows.Reconciler)
    start_supervised!(Scoria.WorkflowsIntegrationTest.Endpoint)
    :ok
  end

  test "a run that pauses for approval can be resumed exactly from stored state" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

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
        actor_id: "operator-integration",
        tenant_id: "tenant-integration",
        trace_id: "trace-#{run.id}"
      })

    {:ok, _run} = Resume.resume_run(run.id, handlers: %{"approval" => {Handlers, :succeed}})
    Process.sleep(20)

    assert Workflows.get_run!(run.id).status == "completed"
    assert Workflows.get_step!(step.id).status == "completed"

    approved_event =
      Repo.get_by!(AuditOutboxEvent,
        workflow_run_id: run.id,
        event_type: "approval.approved",
        trace_id: "trace-#{run.id}"
      )

    assert approved_event.actor_ref == "operator-integration"
    assert approved_event.redacted_refs["approval_id"] == approval.id
    assert approved_event.redacted_refs["decision"] == "approved"
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
    Process.sleep(20)

    checkpoints_after_retry = Workflows.list_run_checkpoints(run.id)

    assert Workflows.get_step!(step.id).status == "completed"

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
    Process.sleep(20)

    assert render(view) =~ "completed"
    assert render(view) =~ "step_completed"
  end

  defp ensure_audit_outbox_table! do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_audit_outbox_events (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      event_type varchar NOT NULL,
      policy_class varchar NOT NULL,
      sink_status varchar NOT NULL DEFAULT 'pending',
      dedupe_key varchar NOT NULL,
      payload_hash varchar NOT NULL,
      pending_at timestamp(6) without time zone NOT NULL,
      sent_at timestamp(6) without time zone NULL,
      attempt_count integer NOT NULL DEFAULT 0,
      actor_ref varchar NULL,
      workflow_run_id uuid NULL,
      step_id uuid NULL,
      trace_id varchar NULL,
      redacted_refs jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("""
    CREATE UNIQUE INDEX IF NOT EXISTS ai_audit_outbox_events_tenant_id_dedupe_key_index
    ON ai_audit_outbox_events (tenant_id, dedupe_key)
    """)
  end
end
