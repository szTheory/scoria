defmodule Scoria.Eval.DatasetPromotionTest do
  use ExUnit.Case

  alias Scoria.Eval
  alias Scoria.Eval.DatasetPromotion
  alias Scoria.Repo
  alias Scoria.Workflows

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  test "promote_workflow_source captures the real workflow step output" do
    {:ok, dataset} = Eval.create_dataset(%{name: unique_name("Capture Dataset"), version: "1"})
    output = %{"answer" => "real step output", "nested" => %{"value" => 42}}
    {run, step} = workflow_step(%{"output" => output})

    attrs =
      promotion_attrs(dataset.id, run.id, step.id,
        checkpoint_output: %{},
        promotion_snapshot: %{"recorded_outcome" => %{}},
        expected_output: %{"answer" => "expected answer"}
      )

    assert {:ok, item} = Eval.promote_workflow_source(attrs)

    assert item.captured_output == output
    assert item.captured_output_sha256 == captured_output_sha256(output)
    assert item.captured_at
    refute item.captured_output == attrs.checkpoint_output
    refute item.captured_output == attrs.promotion_snapshot["recorded_outcome"]
  end

  test "promote_workflow_source leaves capture nil when step output is empty or absent" do
    {:ok, empty_dataset} =
      Eval.create_dataset(%{name: unique_name("Empty Capture Dataset"), version: "1"})

    {empty_run, empty_step} = workflow_step(%{"output" => %{}})

    assert {:ok, empty_item} =
             Eval.promote_workflow_source(
               promotion_attrs(empty_dataset.id, empty_run.id, empty_step.id)
             )

    assert empty_item.captured_output == nil
    assert empty_item.captured_output_sha256 == nil
    assert empty_item.captured_at == nil

    {:ok, absent_dataset} =
      Eval.create_dataset(%{name: unique_name("Absent Capture Dataset"), version: "1"})

    {absent_run, absent_step} = workflow_step(%{})

    assert {:ok, absent_item} =
             Eval.promote_workflow_source(
               promotion_attrs(absent_dataset.id, absent_run.id, absent_step.id)
             )

    assert absent_item.captured_output == nil
    assert absent_item.captured_output_sha256 == nil
    assert absent_item.captured_at == nil

    {:ok, missing_dataset} =
      Eval.create_dataset(%{name: unique_name("Missing Step Dataset"), version: "1"})

    {:ok, missing_run} = workflow_run()

    assert {:ok, missing_item} =
             Eval.promote_workflow_source(
               promotion_attrs(missing_dataset.id, missing_run.id, Ecto.UUID.generate())
             )

    assert missing_item.captured_output == nil
    assert missing_item.captured_output_sha256 == nil
    assert missing_item.captured_at == nil
  end

  test "capture source is not a promotion attribute key" do
    {:ok, dataset} =
      Eval.create_dataset(%{name: unique_name("Attr Contract Dataset"), version: "1"})

    {run, step} = workflow_step(%{"output" => %{"answer" => "real source"}})

    context =
      promotion_attrs(dataset.id, run.id, step.id)
      |> Map.delete(:dataset_id)

    attrs =
      DatasetPromotion.build_promotion_attrs(context, dataset.id, "notes", %{
        "answer" => "expected"
      })

    refute Map.has_key?(attrs, :captured_output)
    refute Map.has_key?(attrs, "captured_output")

    assert {:ok, preview} = DatasetPromotion.preview(attrs)
    assert preview.item_attrs["captured_output"] == %{"answer" => "real source"}

    assert_raise ArgumentError,
                 ~r/unexpected workflow promotion attributes: captured_output/,
                 fn ->
                   DatasetPromotion.preview(
                     Map.put(attrs, :captured_output, %{"answer" => "caller supplied"})
                   )
                 end
  end

  defp workflow_step(result_envelope) do
    {:ok, run} = workflow_run()

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "completed",
        result_envelope: result_envelope
      })

    {run, step}
  end

  defp workflow_run do
    Workflows.create_run(%{
      root_role_id: "executor",
      actor_id: "actor-#{System.unique_integer([:positive])}",
      tenant_id: "tenant-#{System.unique_integer([:positive])}",
      session_id: "session-#{System.unique_integer([:positive])}"
    })
  end

  defp promotion_attrs(dataset_id, workflow_run_id, workflow_step_id, overrides \\ []) do
    defaults = %{
      dataset_id: dataset_id,
      workflow_run_id: workflow_run_id,
      workflow_step_id: workflow_step_id,
      source_variant: "original",
      provenance: %{
        "source_run_id" => nil,
        "source_checkpoint_id" => nil,
        "execution_mode" => "live",
        "replay_disposition" => nil,
        "replay_reason_code" => nil
      },
      checkpoint_output: %{},
      safety: %{},
      promotion_snapshot: %{"recorded_outcome" => %{}},
      notes: "capture",
      expected_output: %{"answer" => "expected"}
    }

    Enum.into(overrides, defaults)
  end

  defp captured_output_sha256(captured_output) do
    captured_output
    |> canonical_json_value()
    |> Jason.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp canonical_json_value(%{} = value) do
    value
    |> Enum.map(fn {key, nested} -> {to_string(key), canonical_json_value(nested)} end)
    |> Enum.sort_by(fn {key, _nested} -> key end)
    |> Jason.OrderedObject.new()
  end

  defp canonical_json_value(value) when is_list(value),
    do: Enum.map(value, &canonical_json_value/1)

  defp canonical_json_value(value), do: value

  defp unique_name(prefix), do: "#{prefix} #{System.unique_integer([:positive])}"
end
