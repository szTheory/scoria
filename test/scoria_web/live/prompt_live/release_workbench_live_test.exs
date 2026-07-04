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
      secret_key_base:
        "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
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
    {:ok, draft} =
      PromptRegistry.create_draft_template(%{
        system_message: "Active system",
        user_template: "Active user"
      })

    {:ok, active} = PromptRegistry.transition_status(draft, "active")

    # Create a new draft
    {:ok, draft2} =
      PromptRegistry.create_draft_template(%{
        entity_id: active.entity_id,
        version: active.version + 1,
        system_message: "Draft system",
        user_template: "Draft user"
      })

    # Create dataset and eval spec
    {:ok, dataset} = Eval.create_dataset(%{name: "Test Dataset", state: :sealed})

    {:ok, spec} =
      Eval.create_eval_spec(%{
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
      conn:
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_private(
          :phoenix_endpoint,
          ScoriaWeb.PromptLive.ReleaseWorkbenchLiveTest.Endpoint
        )
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

      render_async(view)
    end

    test "renders prompt object header with registry crumb, copyable ID, and eval origin chip", %{
      conn: conn,
      draft: draft
    } do
      {:ok, view, html} = live(conn, "/scoria/prompts/#{draft.id}/release?from=eval:eval_9")

      assert html =~ "scoria-object-header"
      assert html =~ "Prompt Registry"
      assert html =~ "Prompt"
      assert html =~ ~s(data-copy="#{draft.id}")
      assert html =~ "Draft blocked"
      assert html =~ "← Back to eval eval_9"

      render_async(view)
    end

    test "release workbench recomputes origin context on route-param updates", %{
      conn: conn,
      draft: draft
    } do
      {:ok, view, html} = live(conn, "/scoria/prompts/#{draft.id}/release")

      refute html =~ "← Back to eval eval_9"

      html = render_patch(view, "/scoria/prompts/#{draft.id}/release?from=eval:eval_9")
      assert html =~ "← Back to eval eval_9"

      render_async(view)
    end

    test "release workbench renders flat eval and baseline-run next-step verbs", %{
      conn: conn,
      draft: draft,
      active: active,
      spec: spec
    } do
      {:ok, active_run} =
        Eval.create_eval_run(%{
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

      {:ok, draft_run} =
        Eval.create_eval_run(%{
          eval_spec_id: spec.id,
          runner_mode: "offline_replay",
          prompt_template_id: draft.id,
          prompt_version: draft.version
        })

      Eval.complete_eval_run(draft_run, %{
        total_items: 10,
        passed_items: 9,
        failed_items: 1,
        avg_latency_ms: 90,
        total_cost_usd: Decimal.new("0.09")
      })

      {:ok, view, html} = live(conn, "/scoria/prompts/#{draft.id}/release")
      eval_results_href = html |> link_href("View eval results") |> URI.decode_www_form()
      baseline_runs_href = html |> link_href("View baseline runs") |> URI.decode_www_form()

      assert html =~ "View eval results"
      assert html =~ "View baseline runs"

      assert eval_results_href ==
               "/scoria/eval_specs?prompt_template_id=#{draft.id}&from=prompt:#{draft.id}#eval-run-#{draft_run.id}"

      assert baseline_runs_href ==
               "/scoria/eval_specs?prompt_template_id=#{active.id}&from=prompt:#{draft.id}#eval-run-#{active_run.id}"

      html_downcase = String.downcase(html)
      refute html_downcase =~ "stepper"
      refute html_downcase =~ "wizard"
      refute html_downcase =~ "current step"

      render_async(view)
    end
  end

  describe "Task 2: Implement Approval Rail & CTA Interactions" do
    test "Approval CTA is disabled if prerequisites are missing", %{conn: conn, draft: draft} do
      {:ok, view, _html} = live(conn, "/scoria/prompts/#{draft.id}/release")
      assert has_element?(view, "button[disabled]", "Request Release")

      render_async(view)
    end

    test "Clicking Approve Prompt Release triggers approval and updates UI", %{
      conn: conn,
      draft: draft,
      active: active,
      spec: spec
    } do
      # Create complete aligned EvalRuns
      {:ok, active_run} =
        Eval.create_eval_run(%{
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

      {:ok, draft_run} =
        Eval.create_eval_run(%{
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

      render_async(view)
    end

    test "Reject CTA records a rejection and remains on the page", %{conn: conn, draft: draft} do
      alias Scoria.Workflows.PromptRelease
      {:ok, _} = PromptRelease.start_release_workflow(draft.id, "admin-1")

      {:ok, view, _html} = live(conn, "/scoria/prompts/#{draft.id}/release")

      view |> element("button", "Reject Release") |> render_click()
      assert render(view) =~ "Reject this release candidate?"

      view |> element("button", "Reject release candidate") |> render_click()
      assert render(view) =~ "Prompt Release Rejected."

      render_async(view)
    end
  end

  describe "WR-04: mount/2 assigns a safe :origin_context default" do
    test "render/1 does not depend on handle_params/3 having run first", %{draft: draft} do
      session = %{"actor_id" => "op-1", "tenant_id" => "default"}

      {:ok, socket} =
        ScoriaWeb.PromptLive.ReleaseWorkbenchLive.mount(
          %{"id" => draft.id},
          session,
          %Phoenix.LiveView.Socket{}
        )

      rendered = ScoriaWeb.PromptLive.ReleaseWorkbenchLive.render(socket.assigns)
      assert %Phoenix.LiveView.Rendered{} = rendered

      # `render/1` returning a %Phoenix.LiveView.Rendered{} struct alone proves
      # nothing here (RESEARCH A1 pitfall): the `dynamic` field is a lazily
      # evaluated closure, so an unassigned @origin_context KeyError is only
      # raised once the tree is actually forced to iodata/HTML — exactly what
      # Phoenix.LiveViewTest.render/1 does under the hood via
      # Phoenix.HTML.Safe.to_iodata/1. Force it here so this test genuinely
      # fails on pre-fix source instead of false-passing like a bare
      # %Rendered{} match would.
      assert is_binary(Phoenix.HTML.Safe.to_iodata(rendered) |> IO.iodata_to_binary())
    end
  end

  defp link_href(html, label) do
    html
    |> Floki.parse_document!()
    |> Floki.find("a")
    |> Enum.find(fn link -> link |> Floki.text() |> String.trim() == label end)
    |> Floki.attribute("href")
    |> List.first()
  end
end
