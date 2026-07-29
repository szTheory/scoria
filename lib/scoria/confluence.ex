defmodule Scoria.Confluence do
  @moduledoc """
  Pure lethal-trifecta confluence classifier (D-03): a root-namespace,
  dependency-free leaf that decides whether private-data exposure,
  untrusted-content exposure, and exfiltration capability co-occur on one
  tainted path. Not `Scoria.MCP.Confluence` (the legs are not tool-scoped)
  and not `Scoria.Gate.Confluence`.

  Deliberately aliases nothing Scoria-side -- no `Scoria.Observe`, no
  `Scoria.Workflows`, no `Scoria.Trust`, no `Scoria.MCP`, no `Scoria.Repo`.
  Both operands this module ever needs (a leg-witness map built by the
  caller) arrive as a plain map argument, so no protocol dispatch is
  needed here (unlike Phase 55's `Trust.Tiered`, which existed only for
  foreign-struct dispatch). The caller (`Scoria.MCP.Executor`) already
  holds every edge this decision needs, so the module graph stays a DAG
  by construction.

  The popularized "lethal trifecta" coinage (Simon Willison) is
  attributed here in prose only, never in an API name -- mirroring the
  precedent at `Scoria.MCP.Classification`'s own moduledoc.

  ## Terminal clause deliberately diverges from `ReplayDisposition`

  `Scoria.Workflows.ReplayDisposition.resolve/5`'s terminal `cond` clause
  is `true -> {:execute_live, ...}` -- fail-OPEN. This module's terminal
  clause is the opposite shape: `{:unevaluable, evidence}` with
  `reason_code: :confluence_resolver_fallthrough`. It is unreachable by
  construction once every combination clause is implemented (a later plan
  adds the remaining six of the eight-value enum), and if it is ever
  reached, it MUST be visible without changing execution -- never
  silently `"none"`, and never `:escalate` either, because escalating on
  a resolver bug is itself the bricking cascade this phase exists to
  avoid. Do NOT "fix" this back to mirror `ReplayDisposition`'s
  fall-through; that would silently disable the entire gate on the
  fallback path.
  """

  alias Scoria.Confluence.Evidence

  @type combination :: String.t() | :unevaluable
  @type leg_witness :: %{optional(:source) => atom()} | nil

  @doc """
  Classifies one tainted-path input into `{combination, %Evidence{}}`.

  `input` is a map with keys `:private_data`, `:untrusted_content`,
  `:exfil` -- each either `nil` (leg unlit) or a witness map carrying at
  least `:source` -- plus optional `:action_class`, `:run_id`,
  `:step_id`, `:tool_ref`.

  This function implements exactly two clauses of the eventual
  eight-value combination ladder: the all-three-legs-lit clause (returns
  the string `"exfiltration_path"`), and the terminal fallback. A later
  plan fills the remaining six combination clauses -- do not stub them
  here with a catch-all that returns `"none"`.
  """
  @spec classify(map()) :: {combination(), Evidence.t()}
  def classify(input) when is_map(input) do
    private_data = Map.get(input, :private_data)
    untrusted_content = Map.get(input, :untrusted_content)
    exfil = Map.get(input, :exfil)

    cond do
      lit?(private_data) and lit?(untrusted_content) and lit?(exfil) ->
        {"exfiltration_path",
         build_evidence("exfiltration_path", input, private_data, untrusted_content, exfil,
           decision: "escalate"
         )}

      true ->
        {:unevaluable,
         build_evidence(:unevaluable, input, private_data, untrusted_content, exfil,
           reason_code: :confluence_resolver_fallthrough
         )}
    end
  end

  defp lit?(nil), do: false
  defp lit?(%{} = _witness), do: true
  defp lit?(_), do: false

  defp build_evidence(combination, input, private_data, untrusted_content, exfil, opts) do
    %Evidence{
      combination: combination,
      grade: weakest_grade(private_data, untrusted_content, exfil),
      decision: Keyword.get(opts, :decision),
      reason_code: Keyword.get(opts, :reason_code),
      private_data_source: witness_source(private_data),
      untrusted_content_source: witness_source(untrusted_content),
      exfil_source: witness_source(exfil),
      action_class: Map.get(input, :action_class),
      confluence_idempotency_key: build_idempotency_key(input),
      run_id: Map.get(input, :run_id),
      step_id: Map.get(input, :step_id),
      tool_ref: Map.get(input, :tool_ref)
    }
  end

  defp witness_source(nil), do: nil
  defp witness_source(%{} = witness), do: Map.get(witness, :source)

  # Weakest-evidence-wins grading, ranked weakest-first: any lit leg
  # witnessed by a weaker source grades the WHOLE disposition at that
  # weaker grade, regardless of how strong the other legs are -- a
  # boolean or flat mode enum cannot express this. Only `:declared`
  # witnesses are constructible by this plan's executor call site (a
  # single tool's own trifecta declaration); the other three sources
  # become reachable once a later plan's scanner-sourced legs land.
  defp weakest_grade(private_data, untrusted_content, exfil) do
    sources =
      [private_data, untrusted_content, exfil]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&Map.get(&1, :source))

    cond do
      :unclassified in sources -> "unclassified"
      :scanner_infra in sources -> "scanner_infra"
      :default_tier in sources -> "default_tier"
      sources != [] -> "declared"
      true -> nil
    end
  end

  # Recommendation, not a lock (per 57-CONTEXT.md "Claude's Discretion"):
  # mirrors `ReplayDisposition.replay_idempotency_key/2`'s shape. Absent
  # when there is no run/tool to correlate against.
  defp build_idempotency_key(input) do
    run_id = Map.get(input, :run_id)
    tool_ref = Map.get(input, :tool_ref)

    if is_nil(run_id) or is_nil(tool_ref) do
      nil
    else
      raw = Enum.join([to_string(run_id), to_string(tool_ref)], ":")
      "confluence:" <> Base.encode16(:crypto.hash(:sha256, raw), case: :lower)
    end
  end
end
