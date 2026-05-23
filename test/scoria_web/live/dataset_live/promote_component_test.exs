defmodule ScoriaWeb.DatasetLive.PromoteComponentTest.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
  end

  scope "/" do
    pipe_through :browser
  end
end

defmodule ScoriaWeb.DatasetLive.PromoteComponentTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug Plug.Session,
    store: :cookie,
    key: "_scoria_key",
    signing_salt: "scoria_salt"

  plug ScoriaWeb.DatasetLive.PromoteComponentTest.Router
end

defmodule ScoriaWeb.DatasetLive.PromoteComponentTest.DummyLive do
  use Phoenix.LiveView

  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:step, session["step"])
     |> assign(:promotion_context, session["promotion_context"])
     |> assign(:notice, nil)}
  end

  def handle_info({:promote_successful, payload}, socket) do
    {:noreply, assign(socket, :notice, "promote:#{payload.source_variant}:#{payload.dataset_name}:#{payload.dataset_version}")}
  end

  def handle_info({:baseline_promotion_requested, payload}, socket) do
    {:noreply, assign(socket, :notice, "baseline:#{payload.dataset_name}:#{payload.dataset_version}")}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div id="notice"><%= @notice %></div>
      <.live_component
        module={ScoriaWeb.DatasetLive.PromoteComponent}
        id="promote-component"
        step={@step}
        promotion_context={@promotion_context}
      />
    </div>
    """
  end
end

defmodule ScoriaWeb.DatasetLive.PromoteComponentTest do
  use Scoria.EvalCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Scoria.Eval
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.Workflows

  @endpoint ScoriaWeb.DatasetLive.PromoteComponentTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.DatasetLive.PromoteComponentTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.DatasetLive.PromoteComponentTest.Endpoint)
    :ok
  end

  test "promotes into an open dataset while keeping sealed baselines visible" do
    {:ok, open_dataset} = Eval.create_dataset(%{name: "Draft QA", version: "1.0"})
    {:ok, sealed_dataset} = Eval.create_dataset(%{name: "Release QA", version: "7"})
    {:ok, _sealed_dataset} = Eval.seal_dataset(sealed_dataset)

    {:ok, view, html} = mount_component(build_promotion_context("original"))

    assert html =~ "Promote Trace to Draft Dataset"
    assert html =~ "Sealed baseline"
    assert html =~ "Approval required"
    assert html =~ "Request baseline approval"

    view
    |> element("button[phx-click='select_open_dataset'][phx-value-dataset-id='#{open_dataset.id}']")
    |> render_click()

    form_data = %{
      "promotion" => %{
        "dataset_id" => "#{open_dataset.id}",
        "notes" => "operator note",
        "expected_output" => ~s({"result":"success"})
      }
    }

    render_submit(element(view, "form"), form_data)

    assert render(view) =~ "promote:original:Draft QA:1.0"

    [item] = Eval.list_dataset_items(open_dataset.id)
    assert item.metadata["promoted_from_workflow"] == true
    assert item.metadata["source_variant"] == "original"
    assert item.expected_output == %{"result" => "success"}
    assert item.input["notes"] == "operator note"
  end

  test "routes sealed baseline requests through explicit approval confirmation" do
    {:ok, sealed_dataset} = Eval.create_dataset(%{name: "Release QA", version: "7"})
    {:ok, _sealed_dataset} = Eval.seal_dataset(sealed_dataset)
    {:ok, run, step} = create_workflow_context("replay")

    {:ok, view, html} = mount_component(build_promotion_context("replay", run.id, step.id))

    assert html =~ "Sealed baseline"
    assert html =~ "Approval required"

    view
    |> element("button[phx-click='select_sealed_dataset'][phx-value-dataset-id='#{sealed_dataset.id}']")
    |> render_click()

    confirm_html = render(view)
    assert confirm_html =~ "Baseline Promotion Approval"
    assert confirm_html =~ "immutable until an explicit approval workflow records the decision"

    render_change(element(view, "form"), %{
      "promotion" => %{
        "dataset_id" => "",
        "notes" => "request approval",
        "expected_output" => ~s({"status":"review"})
      }
    })

    view
    |> element("button[phx-click='request_baseline_approval']")
    |> render_click()

    assert render(view) =~ "baseline:Release QA:7"

    approval =
      Repo.one!(
        from approval in Approval,
          where: approval.workflow_run_id == ^run.id and approval.tool_name == "dataset_baseline_promotion"
      )

    assert approval.arguments["dataset_name"] == "Release QA"
    assert approval.arguments["dataset_version"] == "7"
    assert approval.arguments["source_variant"] == "replay"
    assert approval.arguments["notes"] == "request approval"
    assert approval.arguments["expected_output"] == %{"status" => "review"}
    assert Eval.list_dataset_items(sealed_dataset.id) == []
  end

  test "keeps the modal state when a dataset seals between render and submit" do
    {:ok, open_dataset} = Eval.create_dataset(%{name: "Draft QA", version: "1.0"})

    {:ok, view, _html} = mount_component(build_promotion_context("original"))

    view
    |> element("button[phx-click='select_open_dataset'][phx-value-dataset-id='#{open_dataset.id}']")
    |> render_click()
    {:ok, _sealed} = Eval.seal_dataset(Eval.get_dataset!(open_dataset.id))

    html =
      render_submit(element(view, "form"), %{
        "promotion" => %{
          "dataset_id" => "#{open_dataset.id}",
          "notes" => "preserve this note",
          "expected_output" => ~s({"result":"retry"})
        }
      })

    assert html =~ "cannot add or modify items in a sealed dataset"
    assert html =~ "preserve this note"
    assert html =~ "&quot;result&quot;:&quot;retry&quot;"
    assert html =~ "Sealed baseline"
    assert html =~ "Draft QA"
  end

  defp mount_component(promotion_context) do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.DatasetLive.PromoteComponentTest.Endpoint)

    live_isolated(conn, ScoriaWeb.DatasetLive.PromoteComponentTest.DummyLive,
      session: %{
        "step" => %{id: promotion_context.workflow_step_id, projected_context: %{"foo" => "bar"}},
        "promotion_context" => promotion_context
      }
    )
  end

  defp build_promotion_context(source_variant, run_id \\ Ecto.UUID.generate(), step_id \\ Ecto.UUID.generate()) do
    %{
      workflow_run_id: run_id,
      workflow_step_id: step_id,
      source_variant: source_variant,
      provenance: %{
        workflow_run_id: run_id,
        workflow_step_id: step_id,
        source_variant: source_variant,
        execution_mode: if(source_variant == "replay", do: "replay", else: "live"),
        source_run_id: if(source_variant == "replay", do: Ecto.UUID.generate(), else: nil),
        source_checkpoint_id: if(source_variant == "replay", do: Ecto.UUID.generate(), else: nil)
      },
      checkpoint_output: %{
        projected_context: %{"foo" => "bar"},
        recorded_outcome: %{"kind" => "result", "value" => %{"foo" => "bar"}}
      },
      safety: %{
        replay_scope: if(source_variant == "replay", do: "replay_live", else: nil),
        replay_disposition: if(source_variant == "replay", do: "blocked", else: nil),
        replay_reason_code: if(source_variant == "replay", do: "fresh_replay_approval_required", else: nil)
      },
      promotion_snapshot: %{
        recorded_outcome: %{"kind" => "result", "value" => %{"foo" => "bar"}}
      },
      notes: "",
      expected_output: %{}
    }
  end

  defp create_workflow_context(execution_mode) do
    with {:ok, run} <-
           Workflows.create_run(%{
             root_role_id: "operator",
             execution_mode: execution_mode,
             source_run_id: if(execution_mode == "replay", do: Ecto.UUID.generate(), else: nil),
             source_checkpoint_id:
               if(execution_mode == "replay", do: Ecto.UUID.generate(), else: nil),
             actor_id: "operator-1",
             tenant_id: "tenant-1",
             session_id: "session-1"
           }),
         {:ok, step} <-
           Workflows.create_step(run.id, %{
             sequence: 1,
             kind: "tool_call",
             status: "running",
             role_id: "operator"
           }) do
      {:ok, run, step}
    end
  end
end
