defmodule Scoria.Workflows.ApprovalWriteInvariantGuardTest do
  use ExUnit.Case, async: false

  @moduledoc """
  D-20: decided-at/decider integrity for the approval decision-history surface.

  Two concerns, one file (they are the same invariant from two angles):

  1. `Workflows.list_decided_approvals/1` (the bounded decided-history projection)
     scopes to the three terminal statuses, orders by the cheap `updated_at`/`id`
     proxy sort, and honors the outcome sub-filter (Approved/Denied/Expired).
  2. A warning-grade source-scan guard asserting no runtime path writes an approval
     row after it leaves `pending` — the query's `updated_at` proxy sort (and any
     future denormalized `decided_at`) is only trustworthy if nothing re-writes a
     decided row.
  """

  import Ecto.Query, only: [from: 2]

  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.Workflows

  # Source-scan scope for the D-20 write-invariant guard below.
  @scan_paths Path.wildcard("lib/scoria/**/*.ex") ++ Path.wildcard("priv/repo/**/*.exs")

  # The write-invariant: an approval row must never be written after it leaves the
  # `pending` state. Verified against HEAD, exactly two `Approval.changeset(...)`
  # call sites terminate in an update (a third terminates in `insert!`, which is
  # the row's creation and is not a concern here):
  #   1. workflows.ex:471 — the creation-time second `Approval.changeset |> update!`
  #      that backfills `audit_outbox_event_id` right after insert; the row is
  #      still "pending" at that point (not yet decided) — allow-listed.
  #   2. workflows.ex:964 — the single decision write inside `approve/3` that
  #      performs the pending -> decided transition itself — allow-listed (this
  #      IS the sanctioned decision writer the rest of the system relies on).
  # Any OTHER `Approval.changeset(...) |> update!/update(` call site is a
  # violation of the decided-at write invariant this guard protects.
  #
  # NOTE (56.1-01): these line numbers drift whenever code is inserted above
  # them in workflows.ex (most recently by RAIL-01's six terminality guards,
  # G1-G6). Re-verify with `grep -n "Approval.changeset" lib/scoria/workflows.ex`
  # after any edit that adds/removes lines above these two call sites.
  @allowed_approval_updates MapSet.new([
                              {"lib/scoria/workflows.ex", 471},
                              {"lib/scoria/workflows.ex", 964}
                            ])

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "list_decided_approvals/1 (bounded projection)" do
    test "scopes to approved/rejected/expired only, excluding pending" do
      tenant_id = unique_tenant_id()

      insert_approval!(tenant_id, "pending")
      approved_id = insert_approval!(tenant_id, "approved")
      rejected_id = insert_approval!(tenant_id, "rejected")
      expired_id = insert_approval!(tenant_id, "expired")

      results = Workflows.list_decided_approvals(%{tenant_id: tenant_id})
      result_ids = Enum.map(results, & &1.id) |> MapSet.new()

      assert result_ids == MapSet.new([approved_id, rejected_id, expired_id])
      assert Enum.all?(results, &(&1.status in ["approved", "rejected", "expired"]))
    end

    test "orders desc updated_at then desc id as a proxy sort" do
      tenant_id = unique_tenant_id()

      oldest_id = insert_approval!(tenant_id, "approved")
      set_updated_at!(oldest_id, ~U[2026-07-01 10:00:00.000000Z])

      middle_id = insert_approval!(tenant_id, "rejected")
      set_updated_at!(middle_id, ~U[2026-07-01 10:05:00.000000Z])

      newest_id = insert_approval!(tenant_id, "expired")
      set_updated_at!(newest_id, ~U[2026-07-01 10:10:00.000000Z])

      assert Workflows.list_decided_approvals(%{tenant_id: tenant_id}) |> Enum.map(& &1.id) ==
               [newest_id, middle_id, oldest_id]
    end

    test "the outcome sub-filter narrows results (reuses the existing status filter field)" do
      tenant_id = unique_tenant_id()

      insert_approval!(tenant_id, "approved")
      rejected_id = insert_approval!(tenant_id, "rejected")
      insert_approval!(tenant_id, "expired")

      assert [%{id: ^rejected_id, status: "rejected"}] =
               Workflows.list_decided_approvals(%{tenant_id: tenant_id, status: "rejected"})
    end

    test "is bounded and accepts an optional limit for capped + load-more" do
      tenant_id = unique_tenant_id()

      for _ <- 1..3, do: insert_approval!(tenant_id, "approved")

      assert length(Workflows.list_decided_approvals(%{tenant_id: tenant_id, limit: 2})) == 2
    end
  end

  describe "approval write-invariant guard (D-20, warning-grade source scan)" do
    test "every Approval.changeset(...) call site that terminates in an update is allow-listed" do
      offenders =
        for path <- @scan_paths,
            lines = code_lines(path),
            {line, line_number} <- Enum.with_index(lines, 1),
            Regex.match?(~r/Approval\.changeset\(/, line),
            classify_approval_write(lines, line_number) == :update,
            not MapSet.member?(@allowed_approval_updates, {path, line_number}) do
          "#{path}:#{line_number}"
        end

      assert offenders == [],
             """
             D-20 write-invariant guard: found an Approval row write not on the allow-list.
             Decided-at/decider integrity depends on nothing writing an approval row after
             it leaves `pending`. If this is a legitimate new writer, review it carefully and
             add it to @allowed_approval_updates (with a comment explaining why the row is
             still "pending" at that point); otherwise route the write through
             `Workflows.approve/3` instead of writing the row directly.
             Offenders:
             #{Enum.join(offenders, "\n")}
             """
    end

    test "no update_all call site references the Approval schema (the removed seed shape)" do
      # Proximity-scoped (not whole-file): a file is flagged only when an
      # `update_all(` call site's own nearby lines reference the Approval
      # schema -- e.g. `Repo.update_all(from(a in Approval, ...), set: ...)`.
      # A whole-file check would false-positive on any OTHER schema's
      # legitimate `update_all` (e.g. RAIL-01's `halt_run/3` cancelling
      # sibling `Step` rows) merely because the same file also happens to
      # reference `Approval` elsewhere (e.g. `mark_waiting_for_approval/3`).
      offenders =
        for path <- @scan_paths,
            lines = code_lines(path),
            {line, line_number} <- Enum.with_index(lines, 1),
            Regex.match?(~r/\bupdate_all\(/, line),
            approval_scoped_update_all?(lines, line_number) do
          "#{path}:#{line_number}"
        end

      assert offenders == [],
             """
             D-20 write-invariant guard: found update_all(...) whose own call site references
             the Approval schema — this is the fragile shape dev_seed.exs used to have
             (Repo.update_all(set: [status: "expired"])), which bypasses the decision audit
             event and the updated_at bump. Route decided/expired writes through
             `Workflows.approve(id, status)` instead (D-21).
             Offenders:
             #{Enum.join(offenders, "\n")}
             """
    end
  end

  # Strips whole-line comments before scanning so the guard's own doc comments
  # (which quote the very patterns it looks for) never self-trigger a false
  # positive.
  defp code_lines(path) do
    path
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(fn line ->
      if String.trim(line) |> String.starts_with?("#"), do: "", else: line
    end)
  end

  # Looks ahead from an `Approval.changeset(` line for the pipe call that
  # terminates the changeset pipeline, classifying it as the row's creation
  # (:insert) or a write to an existing row (:update). Warning-grade: a bounded
  # lookahead over literal `repo.`/`Repo.` call text, not full AST analysis.
  defp classify_approval_write(lines, start_line_number) do
    lines
    |> Enum.slice(start_line_number, 8)
    |> Enum.find_value(:unknown, fn line ->
      cond do
        Regex.match?(~r/\b(repo|Repo)\.insert!?\(/, line) -> :insert
        Regex.match?(~r/\b(repo|Repo)\.update!?\(/, line) -> :update
        true -> nil
      end
    end)
  end

  # Looks at a bounded window around an `update_all(` call site for a literal
  # reference to the Approval schema (`from(a in Approval, ...)` or
  # `Scoria.Observe.Approval`) -- a real `Repo.update_all(from(a in Approval,
  # ...), ...)` shape always has its `Approval` reference within a couple of
  # lines of the `update_all(` call, so this window catches the offending
  # shape without flagging an unrelated schema's `update_all` elsewhere in
  # the same file.
  defp approval_scoped_update_all?(lines, line_number) do
    window_start = max(line_number - 6, 1)
    window_end = min(line_number + 2, length(lines))

    lines
    |> Enum.slice((window_start - 1)..(window_end - 1))
    |> Enum.join("\n")
    |> then(&Regex.match?(~r/Scoria\.Observe\.Approval\b|\bin\s+Approval[,\)\s]/, &1))
  end

  defp unique_tenant_id, do: "tenant-decided-#{System.unique_integer([:positive])}"

  defp insert_approval!(tenant_id, status) do
    %Approval{}
    |> Approval.changeset(%{tool_name: "issue_refund", status: status, tenant_id: tenant_id})
    |> Repo.insert!()
    |> Map.fetch!(:id)
  end

  defp set_updated_at!(approval_id, updated_at) do
    {1, _} =
      Repo.update_all(
        from(approval in Approval, where: approval.id == ^approval_id),
        set: [updated_at: updated_at]
      )

    :ok
  end
end
