defmodule Scoria.Workflows.RemoteApprovalProjectionTest do
  use ExUnit.Case, async: false

  alias Scoria.Repo
  alias Scoria.Observe.Approval
  alias Scoria.SRE
  alias Scoria.Workflows
  alias Scoria.Workflows.RemoteApprovalProjection
  alias Scoria.Workflows.Run
  alias ScoriaWeb.ApprovalCopy

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

  defp insert_confluence_approval(attrs) do
    insert_approval(
      Map.merge(%{status: "pending", tool_name: "send_reply", blocker_kind: "confluence"}, attrs)
    )
  end

  # `ai_approvals.workflow_run_id` carries a real foreign key to
  # `ai_workflow_runs` (unlike `blocker_audit_outbox_event_id`, which
  # deliberately carries none) -- a bare `Ecto.UUID.generate()` violates it.
  defp new_run_id! do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
    run.id
  end

  # Plan 57-11 Task 2: writes a REAL audit outbox row through the actual
  # write path (`SRE.create_audit_outbox_event/1`) rather than inserting the
  # schema struct directly, so the persisted metadata's string-keyed shape
  # matches what a genuine escalation produces. `SRE.build_audit_metadata/1`
  # is a DROP-LIST over the whole envelope (mirroring
  # `Executor.record_confluence_audit/5`) -- the evidence fields are merged
  # at the envelope's TOP LEVEL, never nested under a `metadata:` key,
  # otherwise they survive the drop-list as one extra `"metadata"` key
  # instead of becoming the top-level metadata keys the projection reads.
  defp confluence_audit_event!(workflow_run_id, metadata) do
    envelope =
      %{
        event_type: "tool.confluence.escalated",
        workflow_run_id: workflow_run_id
      }
      |> Map.merge(metadata)

    {:ok, event} = SRE.create_audit_outbox_event(envelope)

    event
  end

  # Plan 57-11 Task 2 (D-51): counts `[:scoria, :repo, :query]` telemetry
  # events scoped to the `ai_audit_outbox_events` table, proving the no-N+1
  # property rather than asserting it in prose. Attach AFTER building
  # fixtures so the fixtures' own inserts are never counted.
  defp attach_audit_query_counter! do
    test_pid = self()
    handler_id = "confluence-evidence-query-count-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:scoria, :repo, :query],
      fn _event, _measurements, metadata, _config ->
        if metadata[:source] == "ai_audit_outbox_events" do
          send(test_pid, :ai_audit_outbox_events_query)
        end
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
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

  # Plan 57-11 Task 2 (D-40, D-48, GATE-02, GATE-03): the confluence evidence
  # read added to `get_approval_lineage!/1` by Task 1, exercised here through
  # `list_pending_approvals/1` so both reviewer entry points are covered.
  describe "confluence evidence projection (D-40, D-48)" do
    test "a confluence approval back-linked to a real audit row projects combination, grade and leg sources as atoms" do
      workflow_run_id = new_run_id!()

      event =
        confluence_audit_event!(workflow_run_id, %{
          "combination" => "exfiltration_path",
          "grade" => "declared",
          "private_data_source" => "declared",
          "untrusted_content_source" => "declared",
          "exfil_source" => "declared"
        })

      approval =
        insert_confluence_approval(%{
          workflow_run_id: workflow_run_id,
          blocker_audit_outbox_event_id: event.id
        })

      assert [result] =
               RemoteApprovalProjection.list_pending_approvals(%{
                 workflow_run_id: workflow_run_id
               })

      assert result.id == approval.id
      assert result.combination == "exfiltration_path"
      assert result.grade == "declared"
      assert result.private_data_source == :declared
      assert result.untrusted_content_source == :declared
      assert result.exfil_source == :declared
    end

    test "a nil back-link projects all five evidence keys as nil and renders without raising" do
      workflow_run_id = new_run_id!()

      insert_confluence_approval(%{workflow_run_id: workflow_run_id})

      assert [result] =
               RemoteApprovalProjection.list_pending_approvals(%{
                 workflow_run_id: workflow_run_id
               })

      assert result.combination == nil
      assert result.grade == nil
      assert result.private_data_source == nil
      assert result.untrusted_content_source == nil
      assert result.exfil_source == nil
      assert is_list(ApprovalCopy.request_rows(result))
    end

    test "a back-link pointing at no existing audit row behaves identically to the nil case" do
      workflow_run_id = new_run_id!()

      insert_confluence_approval(%{
        workflow_run_id: workflow_run_id,
        blocker_audit_outbox_event_id: Ecto.UUID.generate()
      })

      assert [result] =
               RemoteApprovalProjection.list_pending_approvals(%{
                 workflow_run_id: workflow_run_id
               })

      assert result.combination == nil
      assert result.grade == nil
      assert result.private_data_source == nil
      assert result.untrusted_content_source == nil
      assert result.exfil_source == nil
      assert is_list(ApprovalCopy.request_rows(result))
    end

    test "a back-link pointing at an audit row belonging to a different workflow run projects all five evidence keys as nil" do
      workflow_run_id = new_run_id!()
      other_workflow_run_id = new_run_id!()

      event =
        confluence_audit_event!(other_workflow_run_id, %{
          "combination" => "exfiltration_path",
          "grade" => "declared",
          "private_data_source" => "declared",
          "untrusted_content_source" => "declared",
          "exfil_source" => "declared"
        })

      insert_confluence_approval(%{
        workflow_run_id: workflow_run_id,
        blocker_audit_outbox_event_id: event.id
      })

      assert [result] =
               RemoteApprovalProjection.list_pending_approvals(%{
                 workflow_run_id: workflow_run_id
               })

      assert result.combination == nil
      assert result.grade == nil
      assert result.private_data_source == nil
      assert result.untrusted_content_source == nil
      assert result.exfil_source == nil
    end

    test "an audit row carrying an unrecognized leg-source string projects that leg as :unknown and never raises" do
      workflow_run_id = new_run_id!()

      event =
        confluence_audit_event!(workflow_run_id, %{
          "combination" => "exfiltration_path",
          "grade" => "declared",
          "private_data_source" => "some_future_source_kind",
          "untrusted_content_source" => "declared",
          "exfil_source" => "declared"
        })

      insert_confluence_approval(%{
        workflow_run_id: workflow_run_id,
        blocker_audit_outbox_event_id: event.id
      })

      assert [result] =
               RemoteApprovalProjection.list_pending_approvals(%{
                 workflow_run_id: workflow_run_id
               })

      assert result.private_data_source == :unknown

      rows = ApprovalCopy.request_rows(result)
      assert {"Private data evidence", "Unknown source"} in rows
    end

    test "a non-confluence approval projects all five evidence keys as nil and its request_rows/1 output is unchanged" do
      workflow_run_id = new_run_id!()

      insert_pending_approval(%{
        workflow_run_id: workflow_run_id,
        arguments: %{"env" => "prod"}
      })

      assert [result] =
               RemoteApprovalProjection.list_pending_approvals(%{
                 workflow_run_id: workflow_run_id
               })

      assert result.combination == nil
      assert result.grade == nil
      assert result.private_data_source == nil
      assert result.untrusted_content_source == nil
      assert result.exfil_source == nil

      rows = ApprovalCopy.request_rows(result)
      assert rows == [{"Target", "Run action"}, {"Policy reason", "Tool policy requires review."}]
    end
  end

  # Plan 57-11 Task 2 (D-51): proves the no-N+1 property by counting the
  # actual `[:scoria, :repo, :query]` telemetry for the audit outbox table,
  # rather than asserting it in prose.
  describe "confluence evidence batch query (D-51 no N+1)" do
    test "a page of several confluence approvals issues exactly one query against ai_audit_outbox_events" do
      tenant_id = "tenant-confluence-batch-#{System.unique_integer([:positive])}"

      for _ <- 1..3 do
        workflow_run_id = new_run_id!()

        event =
          confluence_audit_event!(workflow_run_id, %{
            "combination" => "exfiltration_path",
            "grade" => "declared"
          })

        insert_confluence_approval(%{
          tenant_id: tenant_id,
          workflow_run_id: workflow_run_id,
          blocker_audit_outbox_event_id: event.id
        })
      end

      attach_audit_query_counter!()

      RemoteApprovalProjection.list_pending_approvals(%{tenant_id: tenant_id})

      assert_received :ai_audit_outbox_events_query
      refute_received :ai_audit_outbox_events_query
    end

    test "a page with only non-confluence approvals issues zero queries against ai_audit_outbox_events" do
      tenant_id = "tenant-confluence-batch-none-#{System.unique_integer([:positive])}"

      insert_pending_approval(%{tenant_id: tenant_id})
      insert_pending_approval(%{tenant_id: tenant_id})

      attach_audit_query_counter!()

      RemoteApprovalProjection.list_pending_approvals(%{tenant_id: tenant_id})

      refute_received :ai_audit_outbox_events_query
    end
  end
end
