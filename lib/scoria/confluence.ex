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

  ## `classify/1` is now TOTAL over the three-bit leg vector (D-05)

  `classify/1` resolves every one of the eight possible leg-lit
  combinations to a named clause of the closed `combinations/0` string
  enum. The terminal `cond` clause below is therefore unreachable by
  construction, kept only as the deliberate divergence documented next.

  ## Terminal clause deliberately diverges from `ReplayDisposition`

  `Scoria.Workflows.ReplayDisposition.resolve/5`'s terminal `cond` clause
  is `true -> {:execute_live, ...}` -- fail-OPEN. This module's terminal
  clause is the opposite shape: `{:unevaluable, evidence}` with
  `reason_code: :confluence_resolver_fallthrough`. It is unreachable by
  construction now that every combination clause is implemented, and if
  it is ever reached, it MUST be visible without changing execution --
  never silently `"none"`, and never `:escalate` either, because
  escalating on a resolver bug is itself the bricking cascade this phase
  exists to avoid. Do NOT "fix" this back to mirror `ReplayDisposition`'s
  fall-through; that would silently disable the entire gate on the
  fallback path.
  """

  require Logger

  alias Scoria.Confluence.Evidence

  @type combination :: String.t() | :unevaluable
  @type leg_witness :: %{optional(:source) => atom(), optional(:reason_code) => atom()} | nil

  # -- combinations (D-05) -------------------------------------------------

  @combinations ~w(
    none
    private_data
    untrusted_content
    exfil_capable
    private_data_and_untrusted_content
    private_data_to_egress
    untrusted_content_to_egress
    exfiltration_path
  )

  @doc """
  Returns the closed 8-value STRING combination enum (D-05), total over
  the three-bit leg vector. Strings, not atoms -- these values land on a
  span, matching `Trust.tiers/0` and `Classification.action_classes/0`.
  """
  @spec combinations() :: [String.t()]
  def combinations, do: @combinations

  @doc """
  Normalizes `value` to a member of `combinations/0`, failing closed to
  `"none"` plus a `Logger.warning` plus a fallback telemetry emit for any
  unrecognized input, mirroring `Trust.fallback/1`'s shape (D-05). Never
  raises.
  """
  @spec normalize_combination(term()) :: String.t()
  def normalize_combination(value) when value in @combinations, do: value

  def normalize_combination(value) do
    Logger.warning(
      "Unrecognized Scoria.Confluence combination #{inspect(value)}, defaulting to \"none\""
    )

    try do
      :telemetry.execute([:scoria, :confluence, :fallback], %{}, %{value: value})
    rescue
      _ -> :ok
    end

    "none"
  end

  # -- reason codes (D-09) --------------------------------------------------

  @reason_codes ~w(
    unclassified_default
    approval_pending
    approval_granted
    approval_denied
    confluence_rejected
    scanner_malformed
    unknown
    confluence_resolver_fallthrough
  )a

  @doc """
  Returns the DOMAIN-OWNED closed `reason_code` enum (D-09). Deliberately
  does NOT widen `Scoria.Observe.Semconv.guardrail_reason_codes/0` --
  that enum is pinned by an exact-equality test and the "not invented"
  invariant. This is the sanctioned escape hatch, mirroring
  `Scoria.Trust.Verdict.reason_codes/0`'s exact shape.
  """
  @spec reason_codes() :: [atom()]
  def reason_codes, do: @reason_codes

  @doc """
  Normalizes `value` to a member of `reason_codes/0`, falling back to
  `:unknown` for anything unrecognized (D-09) -- mirrors
  `Scoria.Trust.Verdict.normalize_reason_code/1`'s two-clause shape.
  Never raises.
  """
  @spec normalize_reason_code(term()) :: atom()
  def normalize_reason_code(value) when value in @reason_codes, do: value
  def normalize_reason_code(_value), do: :unknown

  # -- classify/1 -----------------------------------------------------------

  @doc """
  Classifies one tainted-path input into `{combination, %Evidence{}}`.

  `input` is a map with keys `:private_data`, `:untrusted_content`,
  `:exfil` -- each either `nil` (leg unlit) or a witness map carrying at
  least `:source` (and optionally `:reason_code`) -- plus optional
  `:action_class`, `:run_id`, `:step_id`, `:tool_ref`.

  TOTAL over the three-bit leg vector (D-05): every one of the eight
  possible inputs resolves to a named clause. The terminal fallback below
  is unreachable by construction; see the moduledoc's divergence note.
  """
  @spec classify(map()) :: {combination(), Evidence.t()}
  def classify(input) when is_map(input) do
    private_data = Map.get(input, :private_data)
    untrusted_content = Map.get(input, :untrusted_content)
    exfil = Map.get(input, :exfil)

    p = lit?(private_data)
    u = lit?(untrusted_content)
    e = lit?(exfil)

    cond do
      p and u and e ->
        {"exfiltration_path",
         build_evidence("exfiltration_path", input, private_data, untrusted_content, exfil)}

      p and u ->
        {"private_data_and_untrusted_content",
         build_evidence(
           "private_data_and_untrusted_content",
           input,
           private_data,
           untrusted_content,
           exfil
         )}

      p and e ->
        {"private_data_to_egress",
         build_evidence("private_data_to_egress", input, private_data, untrusted_content, exfil)}

      u and e ->
        {"untrusted_content_to_egress",
         build_evidence(
           "untrusted_content_to_egress",
           input,
           private_data,
           untrusted_content,
           exfil
         )}

      p ->
        {"private_data", build_evidence("private_data", input, private_data, untrusted_content, exfil)}

      u ->
        {"untrusted_content",
         build_evidence("untrusted_content", input, private_data, untrusted_content, exfil)}

      e ->
        {"exfil_capable", build_evidence("exfil_capable", input, private_data, untrusted_content, exfil)}

      not p and not u and not e ->
        {"none", build_evidence("none", input, private_data, untrusted_content, exfil)}

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

  defp build_evidence(combination, input, private_data, untrusted_content, exfil, opts \\ []) do
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
  # boolean or flat mode enum cannot express this. Promoted to the public
  # `grades/0`/`grade/1` pair in Task 2, which also corrects an
  # unrecognized-source fail-closed default this private helper does not
  # yet have.
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
