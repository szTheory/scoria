defmodule Scoria.VerificationLanes do
  @moduledoc """
  Canonical verification lane contract for adopter-facing and maintainer-facing proofs.

  Each lane maps one command contract to its environment, prerequisites, and explicit
  exclusions so docs, tests, and CI can share one source of truth.
  """

  @no_optional_setup_exclusions [
    "semantic fast-path setup",
    "knowledge/pgvector bootstrap",
    "retrieval setup",
    "hosted onboarding setup"
  ]

  @lanes [
    %{
      id: :release_preview,
      name: "Release preview lane",
      command: "mix scoria.release_preview",
      ci_command: "MIX_ENV=dev mix scoria.release_preview",
      env: :dev,
      prerequisites: [],
      exclusions: []
    },
    %{
      id: :adoption,
      name: "Default runtime lane",
      command: "mix test.adoption",
      ci_command: "mix test.adoption",
      env: :test,
      prerequisites: ["mix scoria.install", "mix ecto.migrate"],
      exclusions: @no_optional_setup_exclusions
    },
    %{
      id: :runtime_to_handoff,
      name: "Runtime-to-handoff lane",
      command: "mix test.runtime_to_handoff",
      ci_command: "mix test.runtime_to_handoff",
      env: :test,
      prerequisites: ["mix test.adoption"],
      exclusions: @no_optional_setup_exclusions
    },
    %{
      id: :semantic_fast_path,
      name: "Semantic fast-path lane",
      command:
        "SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path",
      ci_command: "mix test.semantic_fast_path",
      env: :test,
      prerequisites: ["mix test.adoption"],
      exclusions: ["full optional knowledge lane"]
    },
    %{
      id: :knowledge,
      name: "Optional knowledge lane",
      command: "mix test.knowledge",
      ci_command: "mix test.knowledge",
      env: :test,
      prerequisites: ["mix scoria.pgvector.bootstrap"],
      exclusions: []
    },
    %{
      id: :support_copilot_gallery,
      name: "Support copilot gallery lane",
      command: "mix scoria.test.support_copilot",
      ci_command: "mix scoria.test.support_copilot",
      env: :test,
      prerequisites: ["mix test.adoption"],
      exclusions: @no_optional_setup_exclusions ++ ["merge-blocking closeout"]
    }
  ]
  @lane_by_id Map.new(@lanes, &{&1.id, &1})
  @closeout_order [:release_preview, :adoption, :runtime_to_handoff]

  def all, do: @lanes

  def ids, do: Enum.map(@lanes, & &1.id)

  def fetch!(id), do: Map.fetch!(@lane_by_id, id)

  def command(id), do: fetch!(id).command

  def ci_command(id), do: fetch!(id).ci_command

  def env(id), do: fetch!(id).env

  def prerequisites(id), do: fetch!(id).prerequisites

  def exclusions(id), do: fetch!(id).exclusions

  def closeout_order, do: @closeout_order

  def closeout_chain do
    @closeout_order
    |> Enum.map(&command/1)
    |> Enum.join("\n")
  end

  def boundary_sentence(id) do
    case exclusions(id) do
      [] ->
        nil

      exclusions ->
        "This lane does not require #{format_exclusions(exclusions)}."
    end
  end

  defp format_exclusions([single]), do: single
  defp format_exclusions([first, second]), do: "#{first} or #{second}"

  defp format_exclusions(exclusions) do
    {head, [tail]} = Enum.split(exclusions, -1)
    "#{Enum.join(head, ", ")}, or #{tail}"
  end
end
