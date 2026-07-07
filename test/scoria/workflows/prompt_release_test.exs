defmodule Scoria.Workflows.PromptReleaseTest do
  use ExUnit.Case, async: false
  import Ecto.Query

  alias Scoria.Workflows
  alias Scoria.Workflows.PromptRelease
  alias Scoria.Observe.Approval
  alias Scoria.PromptRegistry
  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.SRE
  alias Scoria.Repo

  @valid_template_attrs %{
    entity_id: Ecto.UUID.generate(),
    system_message: "System prompt",
    user_template: "User prompt",
    few_shot_examples: %{"examples" => []}
  }

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, run} =
      Workflows.create_run(%{
        tenant_id: "tenant-1",
        actor_id: "user-1",
        root_role_id: "executor"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool_call",
        status: "running",
        role_id: "executor"
      })

    {:ok, template} = PromptRegistry.create_draft_template(@valid_template_attrs)

    %{run: run, step: step, template: template}
  end

  describe "request_remote_approval/3" do
    test "marks a run step as waiting for approval", %{run: run, step: step, template: template} do
      {:ok, _step_or_approval} =
        PromptRelease.request_remote_approval(run.id, step.id, %{
          tool_name: "prompt_release",
          arguments: %{"template_id" => template.id}
        })

      run = Workflows.get_run!(run.id)
      assert run.status == "waiting_for_approval"

      step = Workflows.get_step!(step.id)
      assert step.status == "waiting_for_approval"

      approval = Repo.one!(from(a in Approval, where: a.workflow_run_id == ^run.id))
      assert approval.tool_name == "prompt_release"
      assert approval.arguments["template_id"] == template.id
    end
  end

  describe "approve/3" do
    setup %{run: run, step: step, template: template} do
      {:ok, _} =
        PromptRelease.request_remote_approval(run.id, step.id, %{
          tool_name: "prompt_release",
          arguments: %{"template_id" => template.id}
        })

      approval = Repo.one!(from(a in Approval, where: a.workflow_run_id == ^run.id))
      %{approval: approval}
    end

    test "with status 'approved' promotes the draft and records an audit event", %{
      approval: approval,
      template: template
    } do
      assert template.status == "draft"

      {:ok, updated_approval} =
        PromptRelease.approve(approval.id, "approved", %{actor_id: "admin-1"})

      assert updated_approval.status == "approved"

      # Verify template was promoted
      updated_template = PromptRegistry.get_prompt_template!(template.id)
      assert updated_template.status == "active"

      # Verify audit event
      events = Repo.all(SRE.AuditOutboxEvent)
      assert length(events) > 0
      event = Enum.find(events, &(&1.event_type == "approval.approved"))
      assert event
      assert event.metadata["decision"] == "approved"
      assert event.metadata["metadata"]["decision_actor_id"] == "admin-1"
    end

    test "with status 'approved' demotes prior active versions", %{run: run, step: step} do
      entity_id = Ecto.UUID.generate()

      {:ok, active_draft} =
        PromptRegistry.create_draft_template(%{
          entity_id: entity_id,
          version: 1,
          system_message: "Prior active system",
          user_template: "Prior active user"
        })

      {:ok, active} = PromptRegistry.transition_status(active_draft, "active")

      {:ok, draft} =
        PromptRegistry.create_draft_template(%{
          entity_id: entity_id,
          version: 2,
          system_message: "Release system",
          user_template: "Release user"
        })

      {:ok, _} =
        PromptRelease.request_remote_approval(run.id, step.id, %{
          tool_name: "prompt_release",
          arguments: %{"template_id" => draft.id}
        })

      approval =
        Repo.one!(
          from(a in Approval,
            where:
              a.workflow_run_id == ^run.id and
                fragment("?->>'template_id' = ?", a.arguments, ^draft.id)
          )
        )

      {:ok, updated_approval} =
        PromptRelease.approve(approval.id, "approved", %{actor_id: "admin-1"})

      assert updated_approval.status == "approved"

      updated_draft = PromptRegistry.get_prompt_template!(draft.id)
      demoted_active = PromptRegistry.get_prompt_template!(active.id)

      assert updated_draft.status == "active"
      assert updated_draft.is_current
      assert demoted_active.status == "archived"
      refute demoted_active.is_current

      active_current_versions =
        Repo.all(
          from(prompt in PromptTemplate,
            where:
              prompt.entity_id == ^entity_id and prompt.status == "active" and
                prompt.is_current
          )
        )

      assert Enum.map(active_current_versions, & &1.id) == [draft.id]
    end

    test "with status 'rejected' leaves the draft but records a rejection audit event", %{
      approval: approval,
      template: template
    } do
      assert template.status == "draft"

      {:ok, updated_approval} =
        PromptRelease.approve(approval.id, "rejected", %{actor_id: "admin-1"})

      assert updated_approval.status == "rejected"

      # Verify template was NOT promoted
      updated_template = PromptRegistry.get_prompt_template!(template.id)
      assert updated_template.status == "draft"

      # Verify audit event
      events = Repo.all(SRE.AuditOutboxEvent)
      assert length(events) > 0
      event = Enum.find(events, &(&1.event_type == "approval.rejected"))
      assert event
      assert event.metadata["decision"] == "rejected"
      assert event.metadata["metadata"]["decision_actor_id"] == "admin-1"
    end
  end
end
