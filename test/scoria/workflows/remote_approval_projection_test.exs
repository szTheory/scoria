defmodule Scoria.Workflows.RemoteApprovalProjectionTest do
  use ExUnit.Case, async: false

  alias Scoria.Repo
  alias Scoria.Observe.Approval
  alias Scoria.Workflows
  alias Scoria.Workflows.RemoteApprovalProjection
  alias Scoria.Workflows.Run

  # D-51: the SAME page-size attribute `list_decided_approvals/1` already
  # uses (`@decided_default_limit`) -- pending and decided must not invent
  # two different pagination shapes.
  @default_page_size 50

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  defp insert_pending_approval(attrs) do
    insert_approval(Map.merge(%{status: "pending", tool_name: "publish"}, attrs))
  end

  defp insert_decided_approval(attrs) do
    insert_approval(Map.merge(%{status: "approved", tool_name: "publish"}, attrs))
  end

  # `Approval.changeset/2` doesn't cast `:inserted_at`/`:updated_at`, so a
  # deterministic ordering test needs `Ecto.Changeset.change/2` to set an
  # explicit timestamp rather than relying on insert-order microsecond luck.
  defp insert_approval(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    attrs =
      attrs
      |> Map.put_new(:inserted_at, now)
      |> Map.put_new(:updated_at, now)

    %Approval{}
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert!()
  end

  test "project_approval redacts secrets in arguments_preview and exposes connector_label" do
    approval =
      Repo.insert!(Approval.changeset(%Approval{}, %{
        tool_name: "publish",
        status: "pending",
        arguments: %{"api_key" => "sk-secret-value", "env" => "prod"},
        connector_label: "Stripe Connector"
      }))

    assert %{
             arguments_preview: arguments_preview,
             connector_label: "Stripe Connector"
           } = Workflows.get_remote_approval_lineage!(approval.id)

    refute Map.has_key?(Workflows.get_remote_approval_lineage!(approval.id), :arguments)
    refute inspect(arguments_preview) =~ "sk-secret-value"
    assert arguments_preview["api_key"] == "[REDACTED]"
    assert arguments_preview["env"] == "prod"
  end

  test "list_pending_approvals/1 exposes replay-safe inbox evidence directly from the projection" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        execution_mode: "replay",
        source_run_id: Ecto.UUID.generate(),
        source_checkpoint_id: Ecto.UUID.generate(),
        actor_id: "operator",
        tenant_id: "tenant-replay",
        session_id: "session-replay"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval_gate",
        role_id: "critic",
        status: "running"
      })

    source_approval_id = Ecto.UUID.generate()

    assert {:ok, approval} =
             Workflows.request_remote_approval(run.id, step.id, %{
               tool_name: "publish",
               local_tool_name: "publish",
               arguments: %{"value" => 1},
               requested_scopes: ["deploy:write"],
               subject_ref: "env:prod",
               args_fingerprint: "args-sha-1",
               policy_key: "deploy.publish",
               source_step_id: Ecto.UUID.generate(),
               source_approval_id: source_approval_id,
               source_audit_outbox_event_id: Ecto.UUID.generate()
             })

    assert [
             %{
               id: approval_id,
               workflow_run_id: workflow_run_id,
               replay_allowed: false,
               replay_disposition: "blocked",
               replay_scope: "replay_live",
               source_run_id: source_run_id,
               source_checkpoint_id: source_checkpoint_id,
               source_approval_id: projected_source_approval_id,
               required_scopes: ["deploy:write"],
               policy_key: "deploy.publish",
               executed_live: false
             }
           ] = Workflows.list_pending_remote_approvals(%{tenant_id: "tenant-replay"})

    assert approval_id == approval.id
    assert workflow_run_id == run.id
    assert source_run_id == run.source_run_id
    assert source_checkpoint_id == run.source_checkpoint_id
    assert projected_source_approval_id == source_approval_id
  end

  test "get_approval_lineage!/1 keeps replay scope and source lineage explicit without boolean inference" do
    source_run_id = Ecto.UUID.generate()
    source_checkpoint_id = Ecto.UUID.generate()

    historical_run =
      Repo.insert!(Run.changeset(%Run{}, %{
        root_role_id: "source",
        status: "running",
        started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      }))

    historical =
      Repo.insert!(Approval.changeset(%Approval{}, %{
        tool_name: "publish",
        status: "approved",
        workflow_run_id: historical_run.id,
        source_run_id: source_run_id,
        source_checkpoint_id: source_checkpoint_id
      }))

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        execution_mode: "replay",
        source_run_id: source_run_id,
        source_checkpoint_id: source_checkpoint_id,
        actor_id: "operator",
        tenant_id: "tenant-lineage",
        session_id: "session-lineage"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval_gate",
        role_id: "critic",
        status: "running"
      })

    {:ok, approval} =
      Workflows.request_remote_approval(run.id, step.id, %{
        tool_name: "publish",
        local_tool_name: "publish",
        source_approval_id: historical.id
      })

    assert %{
             id: approval_id,
             replay_scope: "replay_live",
             replay_allowed: false,
             replay_disposition: "blocked",
             replay_reason_code: "fresh_replay_approval_required",
             source_run_id: ^source_run_id,
             source_checkpoint_id: ^source_checkpoint_id,
             source_approval_id: projected_source_approval_id,
             executed_live: false
           } = Workflows.get_remote_approval_lineage!(approval.id)

    assert approval_id == approval.id
    assert projected_source_approval_id == historical.id
  end

  test "dataset baseline promotion approvals project tool_name, target details, and replay lineage" do
    {:ok, dataset} = Scoria.Eval.create_dataset(%{name: "Release QA", version: "7"})
    {:ok, _sealed} = Scoria.Eval.seal_dataset(dataset)

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        execution_mode: "replay",
        source_run_id: Ecto.UUID.generate(),
        source_checkpoint_id: Ecto.UUID.generate(),
        actor_id: "operator",
        tenant_id: "tenant-baseline",
        session_id: "session-baseline"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval_gate",
        role_id: "critic",
        status: "running"
      })

    assert {:ok, approval} =
             Workflows.request_baseline_promotion(%{
               dataset_id: dataset.id,
               workflow_run_id: run.id,
               workflow_step_id: step.id,
               source_variant: "replay",
               provenance: %{
                 "execution_mode" => "replay",
                 "source_run_id" => run.source_run_id,
                 "source_checkpoint_id" => run.source_checkpoint_id
               },
               checkpoint_output: %{"projected_context" => %{"tool" => "publish"}},
               safety: %{"replay_scope" => "replay_live"},
               promotion_snapshot: %{"recorded_outcome" => %{"kind" => "result"}}
             })

    assert [
             %{
               id: approval_id,
               tool_name: "dataset_baseline_promotion",
               replay_disposition: "blocked",
               replay_reason_code: "fresh_replay_approval_required",
               baseline_target: %{
                 dataset_id: dataset_id,
                 dataset_name: "Release QA",
                 dataset_version: "7",
                 source_variant: "replay"
               }
             }
           ] = Workflows.list_pending_approvals(%{tenant_id: "tenant-baseline", tool_name: "dataset_baseline_promotion"})

    assert approval_id == approval.id
    assert dataset_id == dataset.id

    assert %{
             tool_name: "dataset_baseline_promotion",
             replay_scope: "replay_live",
             source_run_id: source_run_id,
             source_checkpoint_id: source_checkpoint_id
           } = Workflows.get_approval_lineage!(approval.id)

    assert source_run_id == run.source_run_id
    assert source_checkpoint_id == run.source_checkpoint_id
  end

  describe "list_pending_approvals/1 cap (D-51)" do
    test "returns at most the default page size when more pending approvals exist" do
      tenant_id = "tenant-pending-cap-#{System.unique_integer([:positive])}"

      for _ <- 1..(@default_page_size + 5) do
        insert_pending_approval(%{tenant_id: tenant_id})
      end

      results = RemoteApprovalProjection.list_pending_approvals(%{tenant_id: tenant_id})

      assert length(results) == @default_page_size
    end

    test "an explicit limit overrides the default, exactly as list_decided_approvals/1 allows" do
      tenant_id = "tenant-pending-explicit-limit-#{System.unique_integer([:positive])}"

      for _ <- 1..10 do
        insert_pending_approval(%{tenant_id: tenant_id})
      end

      results =
        RemoteApprovalProjection.list_pending_approvals(%{tenant_id: tenant_id, limit: 3})

      assert length(results) == 3
    end

    test "filter and ordering behavior is unchanged against a small fixture" do
      tenant_id = "tenant-pending-order-#{System.unique_integer([:positive])}"
      other_tenant_id = "tenant-pending-order-other-#{System.unique_integer([:positive])}"

      older =
        insert_pending_approval(%{
          tenant_id: tenant_id,
          tool_name: "issue_refund",
          inserted_at: ~U[2026-01-01 00:00:00.000000Z]
        })

      insert_pending_approval(%{tenant_id: other_tenant_id})

      newer =
        insert_pending_approval(%{
          tenant_id: tenant_id,
          tool_name: "issue_refund",
          inserted_at: ~U[2026-01-02 00:00:00.000000Z]
        })

      results =
        RemoteApprovalProjection.list_pending_approvals(%{
          tenant_id: tenant_id,
          tool_name: "issue_refund"
        })

      assert Enum.map(results, & &1.id) == [newer.id, older.id]
    end

    test "list_decided_approvals/1 returns the same results as before the change for an identical fixture" do
      tenant_id = "tenant-decided-unaffected-#{System.unique_integer([:positive])}"

      older =
        insert_decided_approval(%{
          tenant_id: tenant_id,
          updated_at: ~U[2026-01-01 00:00:00.000000Z]
        })

      newer =
        insert_decided_approval(%{
          tenant_id: tenant_id,
          updated_at: ~U[2026-01-02 00:00:00.000000Z]
        })

      results = RemoteApprovalProjection.list_decided_approvals(%{tenant_id: tenant_id})

      assert Enum.map(results, & &1.id) == [newer.id, older.id]
      assert length(RemoteApprovalProjection.list_decided_approvals(%{tenant_id: tenant_id, limit: 1})) ==
               1
    end
  end
end
