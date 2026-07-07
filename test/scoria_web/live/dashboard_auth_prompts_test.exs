defmodule ScoriaWeb.DashboardAuthPromptsTest.Router do
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

defmodule ScoriaWeb.DashboardAuthPromptsTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_dashboard_auth_prompts_key",
    signing_salt: "dashboard_auth_prompts_salt"
  )

  plug(ScoriaWeb.DashboardAuthPromptsTest.Router)
end

defmodule ScoriaWeb.DashboardAuthPromptsTest do
  use Scoria.IntegrationCase

  import Ecto.Query
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Eval
  alias Scoria.Eval.EvalRun
  alias Scoria.Observe.Approval
  alias Scoria.PromptRegistry
  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.Repo
  alias Scoria.Workflows

  @endpoint ScoriaWeb.DashboardAuthPromptsTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.DashboardAuthPromptsTest.Endpoint,
      secret_key_base: "dP22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1AuthPromptKey0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "446789123"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.DashboardAuthPromptsTest.Endpoint)
    :ok
  end

  test "prompt index uses assigned dashboard scope despite tenant query hints" do
    unique = unique_suffix()
    tenant_a = "dashboard-prompt-index-a-#{unique}"
    tenant_b = "dashboard-prompt-index-b-#{unique}"

    {:ok, template} =
      PromptRegistry.create_draft_template(%{
        system_message: "Tenant scoped catalog system #{unique}",
        user_template: "Tenant scoped catalog user #{unique}"
      })

    {:ok, _view, html} = live(scoped_conn(tenant_a), "/scoria/prompts?tenant=#{tenant_b}")

    assert html =~ "Prompt Registry"
    assert html =~ template.entity_id
    refute html =~ tenant_b
  end

  test "release workbench excludes foreign eval runs and pending approval for same prompt" do
    unique = unique_suffix()
    tenant_a = "dashboard-prompt-release-a-#{unique}"
    tenant_b = "dashboard-prompt-release-b-#{unique}"

    %{active: active, draft: draft} = seed_prompt_pair!(unique)

    seed_completed_eval_run!(tenant_a, active,
      unique: unique,
      dataset_version: "tenant-a-active-dataset-#{unique}"
    )

    seed_completed_eval_run!(tenant_a, draft,
      unique: unique,
      dataset_version: "tenant-a-draft-dataset-#{unique}"
    )

    tenant_b_active_run =
      seed_completed_eval_run!(tenant_b, active,
        unique: unique,
        dataset_version: "tenant-b-active-dataset-#{unique}"
      )

    tenant_b_draft_run =
      seed_completed_eval_run!(tenant_b, draft,
        unique: unique,
        dataset_version: "tenant-b-draft-dataset-#{unique}"
      )

    make_latest!(tenant_b_active_run, 60)
    make_latest!(tenant_b_draft_run, 61)

    seed_prompt_release_approval!(tenant_b, "tenant-b-actor-#{unique}", draft.id,
      unique: unique,
      reason: "tenant B release approval marker #{unique}"
    )

    {:ok, _view, html} =
      live(scoped_conn(tenant_a), "/scoria/prompts/#{draft.id}/release?tenant=#{tenant_b}")

    assert html =~ "tenant-a-active-dataset-#{unique}"
    assert html =~ "tenant-a-draft-dataset-#{unique}"
    refute html =~ "tenant-b-active-dataset-#{unique}"
    refute html =~ "tenant-b-draft-dataset-#{unique}"

    assert html =~ "Request Release"
    refute html =~ "Reject Release"
    refute html =~ "Approve Prompt Release"
  end

  test "same-tenant prompt release approval remains actionable" do
    unique = unique_suffix()
    tenant_a = "dashboard-prompt-approval-a-#{unique}"

    %{draft: draft} = seed_prompt_pair!(unique)

    seed_prompt_release_approval!(tenant_a, "tenant-a-requester-#{unique}", draft.id,
      unique: unique,
      reason: "tenant A release approval marker #{unique}"
    )

    {:ok, _view, html} = live(scoped_conn(tenant_a), "/scoria/prompts/#{draft.id}/release")

    assert html =~ "Reject Release"
    assert html =~ "Approve Prompt Release"
  end

  test "release request action persists assigned tenant and actor context" do
    unique = unique_suffix()
    tenant_a = "dashboard-prompt-action-a-#{unique}"
    actor_a = "dashboard-prompt-actor-a-#{unique}"

    %{draft: draft} = seed_prompt_pair!(unique)

    seed_completed_eval_run!(tenant_a, draft,
      unique: unique,
      dataset_version: "tenant-a-action-dataset-#{unique}"
    )

    {:ok, view, _html} =
      live(scoped_conn(tenant_a, actor_a), "/scoria/prompts/#{draft.id}/release")

    view |> element("button", "Request Release") |> render_click()

    approval = fetch_prompt_release_approval!(draft.id)

    assert approval.tenant_id == tenant_a
    refute approval.tenant_id == "system"
    assert approval.actor_id == actor_a
  end

  test "forged release request event is rejected when eval evidence is incomplete" do
    unique = unique_suffix()
    tenant_a = "dashboard-prompt-forged-request-a-#{unique}"
    actor_a = "dashboard-prompt-forged-request-actor-a-#{unique}"

    %{draft: draft} = seed_prompt_pair!(unique)
    before_count = prompt_release_approval_count(draft.id)

    {:ok, view, _html} =
      live(scoped_conn(tenant_a, actor_a), "/scoria/prompts/#{draft.id}/release")

    html = render_click(view, "request_release", %{})

    assert html =~ "Release requires completed matching eval evidence."
    assert prompt_release_approval_count(draft.id) == before_count
  end

  test "forged approval event is rejected when eval evidence is incomplete" do
    unique = unique_suffix()
    tenant_a = "dashboard-prompt-forged-approve-a-#{unique}"
    actor_a = "dashboard-prompt-forged-approve-actor-a-#{unique}"

    %{draft: draft} = seed_prompt_pair!(unique)

    approval =
      seed_prompt_release_approval!(tenant_a, actor_a, draft.id,
        unique: unique,
        reason: "tenant A forged approval marker #{unique}"
      )

    {:ok, view, _html} =
      live(scoped_conn(tenant_a, actor_a), "/scoria/prompts/#{draft.id}/release")

    html = render_click(view, "approve_release", %{})

    assert html =~ "Release requires completed matching eval evidence."
    assert Repo.get!(PromptTemplate, draft.id).status == "draft"
    assert Repo.get!(Approval, approval.id).status == "pending"
  end

  test "approval promotes the draft as the only current active prompt version" do
    unique = unique_suffix()
    tenant_a = "dashboard-prompt-promote-a-#{unique}"
    actor_a = "dashboard-prompt-promote-actor-a-#{unique}"
    dataset_version = "tenant-a-prompt-release-dataset-#{unique}"

    %{active: active, draft: draft} = seed_prompt_pair!(unique)

    seed_completed_eval_run!(tenant_a, active,
      unique: unique,
      dataset_version: dataset_version,
      dataset_name: "Prompt active dataset #{unique}"
    )

    seed_completed_eval_run!(tenant_a, draft,
      unique: unique,
      dataset_version: dataset_version,
      dataset_name: "Prompt draft dataset #{unique}"
    )

    approval =
      seed_prompt_release_approval!(tenant_a, actor_a, draft.id,
        unique: unique,
        reason: "tenant A promotion approval marker #{unique}"
      )

    {:ok, view, _html} =
      live(scoped_conn(tenant_a, actor_a), "/scoria/prompts/#{draft.id}/release")

    view |> element("button", "Approve Prompt Release") |> render_click()
    view |> element("button", "Confirm Approval") |> render_click()

    updated_draft = Repo.get!(PromptTemplate, draft.id)
    demoted_active = Repo.get!(PromptTemplate, active.id)

    assert updated_draft.status == "active"
    assert updated_draft.is_current
    assert demoted_active.status == "archived"
    refute demoted_active.is_current
    assert Repo.get!(Approval, approval.id).status == "approved"

    active_current_versions =
      Repo.all(
        from(prompt in PromptTemplate,
          where:
            prompt.entity_id == ^draft.entity_id and prompt.status == "active" and
              prompt.is_current
        )
      )

    assert Enum.map(active_current_versions, & &1.id) == [draft.id]
  end

  test "missing dashboard scope halts before prompt release evidence assigns are populated" do
    assert {:halt, halted_socket} =
             ScoriaWeb.DashboardScope.on_mount(
               :default,
               %{"tenant" => "tenant-from-query"},
               %{},
               scope_socket()
             )

    assert halted_socket.assigns.flash["error"] ==
             "This Scoria dashboard is not available for this session."

    refute Map.has_key?(halted_socket.assigns, :draft_run)
    refute Map.has_key?(halted_socket.assigns, :active_run)
    refute Map.has_key?(halted_socket.assigns, :pending_approval)
  end

  defp scoped_conn(tenant_id, actor_id \\ "prompt-operator") do
    build_conn()
    |> Plug.Test.init_test_session(%{"tenant_id" => tenant_id, "actor_id" => actor_id})
    |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
  end

  defp seed_prompt_pair!(unique) do
    entity_id = Ecto.UUID.generate()

    {:ok, active_draft} =
      PromptRegistry.create_draft_template(%{
        entity_id: entity_id,
        system_message: "Active system #{unique}",
        user_template: "Active user #{unique}"
      })

    {:ok, active} = PromptRegistry.transition_status(active_draft, "active")

    {:ok, draft} =
      PromptRegistry.create_draft_template(%{
        entity_id: entity_id,
        version: active.version + 1,
        system_message: "Draft system #{unique}",
        user_template: "Draft user #{unique}"
      })

    %{active: active, draft: draft}
  end

  defp seed_completed_eval_run!(tenant_id, prompt, opts) do
    unique = Keyword.fetch!(opts, :unique)
    dataset_version = Keyword.fetch!(opts, :dataset_version)
    dataset_name = Keyword.get(opts, :dataset_name, "Prompt dataset #{dataset_version}")

    {:ok, dataset} =
      Eval.create_dataset(%{
        name: dataset_name,
        version: dataset_version,
        state: :sealed
      })

    {:ok, spec} =
      Eval.create_eval_spec(%{
        name: "Prompt spec #{dataset_version}",
        dataset_id: dataset.id,
        dataset_version: dataset.version,
        eval_mode: :offline_replay,
        subject: %{
          subject_kind: :prompt_template,
          prompt_entity_id: prompt.entity_id,
          prompt_template_id: prompt.id,
          prompt_version: prompt.version
        },
        scorers: [
          %{
            metric_key: "accuracy-#{unique}",
            scorer_kind: :exact_match,
            weight: 1.0
          }
        ],
        threshold_policy: %{
          pass_rate_gte: 0.8,
          mean_score_gte: 0.8,
          max_latency_ms: 100
        }
      })

    {:ok, run} =
      Eval.create_eval_run(%{
        eval_spec_id: spec.id,
        runner_mode: :offline_replay,
        tenant_id: tenant_id,
        prompt_template_id: prompt.id,
        prompt_version: prompt.version
      })

    {:ok, completed_run} =
      Eval.complete_eval_run(run, %{
        total_items: 10,
        passed_items: 10,
        failed_items: 0,
        avg_latency_ms: 90,
        total_cost_usd: Decimal.new("0.09")
      })

    completed_run
  end

  defp make_latest!(%EvalRun{} = run, seconds_offset) do
    inserted_at =
      DateTime.utc_now()
      |> DateTime.add(seconds_offset, :second)
      |> DateTime.truncate(:microsecond)

    {1, _} =
      Repo.update_all(
        from(eval_run in EvalRun, where: eval_run.id == ^run.id),
        set: [inserted_at: inserted_at]
      )

    Repo.get!(EvalRun, run.id)
  end

  defp seed_prompt_release_approval!(tenant_id, actor_id, template_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    reason = Keyword.fetch!(opts, :reason)

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "operator",
        tenant_id: tenant_id,
        actor_id: actor_id,
        session_id: "prompt-release-session-#{unique}"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool_call",
        status: "running",
        role_id: "operator"
      })

    {:ok, approval} =
      Workflows.request_remote_approval(run.id, step.id, %{
        tool_name: "prompt_release",
        arguments: %{"template_id" => template_id},
        reason: reason
      })

    approval
  end

  defp fetch_prompt_release_approval!(template_id) do
    Repo.one!(
      from(approval in Approval,
        where:
          approval.tool_name == "prompt_release" and
            fragment("?->>'template_id' = ?", approval.arguments, ^template_id),
        order_by: [desc: approval.inserted_at],
        limit: 1
      )
    )
  end

  defp prompt_release_approval_count(template_id) do
    Repo.aggregate(
      from(approval in Approval,
        where:
          approval.tool_name == "prompt_release" and
            fragment("?->>'template_id' = ?", approval.arguments, ^template_id)
      ),
      :count
    )
  end

  defp scope_socket do
    %Phoenix.LiveView.Socket{
      assigns: %{__changed__: %{}, flash: %{}},
      view: ScoriaWeb.PromptLive.ReleaseWorkbenchLive
    }
  end

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string()
  end
end
