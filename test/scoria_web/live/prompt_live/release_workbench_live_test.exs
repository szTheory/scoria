defmodule ScoriaWeb.PromptLive.ReleaseWorkbenchLiveTest.Router do
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

defmodule ScoriaWeb.PromptLive.ReleaseWorkbenchLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_scoria_key",
    signing_salt: "scoria_salt"
  )

  plug(ScoriaWeb.PromptLive.ReleaseWorkbenchLiveTest.Router)
end

defmodule ScoriaWeb.PromptLive.ReleaseWorkbenchLiveTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.PromptRegistry
  alias Scoria.Eval
  alias Scoria.Workflows.PromptRelease
  alias Scoria.Repo

  @endpoint ScoriaWeb.PromptLive.ReleaseWorkbenchLiveTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.PromptLive.ReleaseWorkbenchLiveTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    start_supervised!(ScoriaWeb.PromptLive.ReleaseWorkbenchLiveTest.Endpoint)

    # Create an active prompt
    {:ok, draft} = PromptRegistry.create_draft_template(%{
      system_message: "Active system",
      user_template: "Active user"
    })
    {:ok, active} = PromptRegistry.transition_status(draft, "active")

    # Create a new draft
    {:ok, draft2} = PromptRegistry.create_draft_template(%{
      entity_id: active.entity_id,
      version: active.version + 1,
      system_message: "Draft system",
      user_template: "Draft user"
    })

    # Create dataset and eval spec
    {:ok, dataset} = Eval.create_dataset(%{name: "Test Dataset", state: :sealed})
    {:ok, spec} = Eval.create_eval_spec(%{
      name: "Test Spec",
      dataset_id: dataset.id,
      dataset_version: dataset.version,
      eval_mode: :offline_replay,
      subject: %{
        subject_kind: :prompt_template,
        prompt_entity_id: draft2.entity_id,
        prompt_template_id: draft2.id,
        prompt_version: draft2.version
      },
      scorers: [
        %{
          metric_key: "accuracy",
          scorer_kind: :llm_judge,
          judge_prompt_template_id: Ecto.UUID.generate(),
          judge_prompt_version: 1,
          judge_provider: "openai",
          judge_model: "gpt-4o-mini",
          weight: 1.0
        }
      ],
      threshold_policy: %{
        pass_rate_gte: 0.8,
        mean_score_gte: 0.8,
        max_latency_ms: 100
      }
    })

    %{
      draft: draft2, 
      active: active, 
      dataset: dataset, 
      spec: spec,
      conn: build_conn() |> Plug.Test.init_test_session(%{}) |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.PromptLive.ReleaseWorkbenchLiveTest.Endpoint)
    }
  end

  describe "Task 1: Scaffold ReleaseWorkbenchLive Component" do
    test "mounts and renders comparison deck", %{conn: conn, draft: draft} do
      {:ok, view, _html} = live(conn, "/scoria/prompts/#{draft.id}/release")
      
      # Test 1 & 2
      assert render(view) =~ "Release Workbench"
      assert render(view) =~ "Draft Candidate"
      assert render(view) =~ "Active Baseline"

      # Test 3
      assert render(view) =~ "Draft blocked"
    end
  end

  describe "Task 2: Implement Approval Rail & CTA Interactions" do
    test "Approval CTA is disabled if prerequisites are missing", %{conn: conn, draft: draft} do
      {:ok, view, _html} = live(conn, "/scoria/prompts/#{draft.id}/release")
      assert has_element?(view, "button[disabled]", "Request Release")
    end

    test "Clicking Approve Prompt Release triggers approval and updates UI", %{conn: conn, draft: draft, active: active, dataset: dataset, spec: spec} do
      # Create complete aligned EvalRuns
      {:ok, active_run} = Eval.create_eval_run(%{
        eval_spec_id: spec.id,
        runner_mode: "offline_replay",
        prompt_template_id: active.id,
        prompt_version: active.version
      })
      Eval.complete_eval_run(active_run, %{
        total_items: 10,
        passed_items: 10,
        failed_items: 0,
        avg_latency_ms: 100,
        total_cost_usd: Decimal.new("0.10")
      })

      {:ok, draft_run} = Eval.create_eval_run(%{
        eval_spec_id: spec.id,
        runner_mode: "offline_replay",
        prompt_template_id: draft.id,
        prompt_version: draft.version
      })
      Eval.complete_eval_run(draft_run, %{
        total_items: 10,
        passed_items: 10,
        failed_items: 0,
        avg_latency_ms: 90,
        total_cost_usd: Decimal.new("0.09")
      })

      {:ok, view, _html} = live(conn, "/scoria/prompts/#{draft.id}/release")

      assert render(view) =~ "10 / 10"

      view |> element("button", "Request Release") |> render_click()

      view |> element("button", "Approve Prompt Release") |> render_click()
      assert render(view) =~ "Approve Release?"

      view |> element("button", "Confirm Approval") |> render_click()
      assert render(view) =~ "Prompt Release Approved."
      end

      test "Reject CTA records a rejection and remains on the page", %{conn: conn, draft: draft} do
      {:ok, view, _html} = live(conn, "/scoria/prompts/#{draft.id}/release")

      # We need an eval run for request release to be enabled in the view
      # Actually, wait, the test doesn't create eval runs for the Reject CTA test?
      # If it's disabled, request_release is disabled.
      # But wait, rejection is enabled even if runs are missing? Yes, in the view.
      # Let's just create an approval directly for the reject test so we don't have to setup runs.
      alias Scoria.Workflows.PromptRelease
      {:ok, _} = PromptRelease.start_release_workflow(draft.id, "admin-1")

      {:ok, view, _html} = live(conn, "/scoria/prompts/#{draft.id}/release")

      view |> element("button", "Reject Release") |> render_click()
      assert render(view) =~ "Reject this draft release?"

      view |> element("button", "Confirm Rejection") |> render_click()
      assert render(view) =~ "Prompt Release Rejected."
      end  end
end
