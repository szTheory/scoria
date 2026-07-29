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

  ## Weakest-evidence grading (D-29) and the config surface (D-31..D-34)

  `grade/1` grades a classification by the WEAKEST evidence backing its
  lit legs (`grades/0`'s fixed weakest-first order), `decide/2` maps a
  grade plus a resolved configuration to a disposition, and
  `resolve_config/1` resolves that configuration live from a tighten-only
  per-call rung, a may-loosen application-environment rung, and the
  shipped defaults. The shipped default ENFORCES only for the `declared`
  grade (D-31) -- the three absence-of-evidence cascades stay
  telemetry-only under shipped defaults, matching the `ReleaseGate`
  doctrine GATE-04 names: positive evidence enforces, absence of evidence
  is inspectable but never blocking on its own.

  ## What "replayable" means for this gate (D-43, D-44)

  A confluence decision is REPLAYABLE because it is RECONSTRUCTABLE from
  persisted evidence -- the audit outbox row (`audit_metadata/1`'s output),
  the per-run `confluence_legs` accumulator, and the approval row together
  -- never because an approved escalation is a REUSABLE grant a later
  replay can pass through on. Phase 57 adds NOTHING to
  `Scoria.Workflows.ReplayDisposition` -- no disposition value, no replay
  reason code, no replay scope -- so a historical stub never re-executes
  the tool and therefore never reaches this gate, and a live re-execution
  during replay (reachable only through the `live_override_approved` path)
  evaluates this gate AFRESH, exactly like any other live call, scoped to
  its OWN run id. A human approval is a historical decision recorded in
  event history, not a standing exfiltration grant to be re-spent.
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

  # -- weakest-evidence grading (D-29, D-30) -------------------------------

  @grades ~w(unclassified scanner_infra default_tier declared)
  @grade_rank %{"unclassified" => 0, "scanner_infra" => 1, "default_tier" => 2, "declared" => 3}

  @doc """
  Returns the four grades in their fixed WEAKEST-FIRST order (D-29).
  """
  @spec grades() :: [String.t()]
  def grades, do: @grades

  @doc """
  Returns the grade of the WEAKEST evidence backing the LIT legs of
  `legs` (a map with `:private_data`, `:untrusted_content`, `:exfil`
  witness entries -- the same shape `classify/1` accepts), first-
  applicable wins in `grades/0`'s fixed weakest-first order, so exactly
  one grade is recorded per evaluation and the decision is
  deterministically replayable (D-29).

  An unrecognized or absent witness `:source` value fails closed to the
  WEAKEST grade (`"unclassified"`), never the strongest (`"declared"`) --
  a garbage or foreign source must never be presented to the enforcement
  ladder as strong evidence (D-30). Returns `nil` when no leg is lit.
  """
  @spec grade(map()) :: String.t() | nil
  def grade(legs) when is_map(legs) do
    categories =
      [:private_data, :untrusted_content, :exfil]
      |> Enum.map(&Map.get(legs, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&Map.get(&1, :source))
      |> Enum.map(&grade_for_source/1)

    case categories do
      [] -> nil
      _ -> Enum.min_by(categories, &Map.fetch!(@grade_rank, &1))
    end
  end

  defp grade_for_source(:unclassified), do: "unclassified"
  defp grade_for_source(:scanner_infra), do: "scanner_infra"
  defp grade_for_source(:default_tier), do: "default_tier"
  defp grade_for_source(:declared), do: "declared"
  # Fail-closed (D-30): a witness carrying an unrecognized or absent
  # `:source` must never be treated as strong ("declared") evidence --
  # absence of trustworthy evidence must never be presented to the
  # enforcement ladder as presence of it.
  defp grade_for_source(_other), do: "unclassified"

  # -- disposition (D-31, D-32) --------------------------------------------

  @decisions ~w(allow block escalate)

  @doc """
  Maps `grade` (a member of `grades/0`) plus `config` (a resolved
  configuration map, as returned by `resolve_config/1`) to one of the
  three dispositions `"allow"`, `"escalate"` or `"block"` -- reusing
  `Semconv.guardrail_decisions/0`'s three values verbatim as the
  vocabulary WITHOUT calling into `Semconv` (D-03 forbids the edge; the
  three strings are hand-written here). `"warn"` is rejected -- Scoria has
  no caller-warning channel at the executor return; telemetry is the
  warning.

  `config[:enforcement] == :observe` is the incident kill switch: every
  grade resolves to `"allow"` regardless of its own configured value or
  `:strict`. Otherwise the `"declared"` grade always consults
  `config[:declared]` (shipped `:escalate`, D-31). For the three weak
  grades, `config[:strict] == true` forces `"escalate"` unconditionally
  (SC#4's opt-in extending enforcement to the ungated grades); otherwise
  each weak grade consults its own configured value (shipped `:allow`).
  """
  @spec decide(String.t(), map()) :: String.t()
  def decide(grade, config) when grade in @grades and is_map(config) do
    cond do
      Map.get(config, :enforcement) == :observe ->
        "allow"

      grade == "declared" ->
        normalize_decision(Map.get(config, :declared, :escalate))

      Map.get(config, :strict) == true ->
        "escalate"

      true ->
        normalize_decision(Map.get(config, grade_config_key(grade), :allow))
    end
  end

  defp grade_config_key("unclassified"), do: :unclassified
  defp grade_config_key("scanner_infra"), do: :scanner_infra
  defp grade_config_key("default_tier"), do: :default_tier

  defp normalize_decision(value) when value in [:allow, :block, :escalate], do: Atom.to_string(value)
  defp normalize_decision(value) when value in @decisions, do: value
  defp normalize_decision(_other), do: "allow"

  # -- configuration surface (D-31..D-34) ----------------------------------

  @shipped_config %{
    enforcement: :enforce,
    declared: :escalate,
    unclassified: :allow,
    scanner_infra: :allow,
    default_tier: :allow,
    strict: false,
    unattributed: :allow
  }

  @config_keys Map.keys(@shipped_config)
  @decision_keys ~w(declared unclassified scanner_infra default_tier unattributed)a
  @warned_table :scoria_confluence_warned_keys

  @doc """
  Resolves the host-facing configuration surface (D-32) live from
  `context` (a map that may carry a `:confluence` key with a per-call
  override) and `config :scoria, Scoria.Confluence` (application
  environment), over the shipped defaults.

  Precedence (D-33): per-call `context[:confluence]` is TIGHTEN-ONLY --
  it is only honored when it represents a STRICTER value than whatever
  the application-environment rung already resolved. Application
  environment sits below it and MAY loosen OR tighten relative to the
  shipped default -- an operator who cannot turn a security control down
  during an incident turns it off permanently, so application environment
  is a full override at its own rung (deliberately unlike the per-call
  rung, which is request-adjacent). Shipped defaults sit at the bottom.

  A malformed value at either rung falls back to whatever the next rung
  down resolved (ultimately the shipped default), logs once via an ETS
  log-once guard, and never raises -- refusing every tool call on a
  configuration typo is itself the brick this function exists to avoid.

  Resolved live on every call; the caller is responsible for snapshotting
  the resolved grade and decision onto persisted evidence so replay reads
  the recorded decision and never re-resolves configuration (D-33).
  """
  @spec resolve_config(map()) :: map()
  def resolve_config(context \\ %{}) when is_map(context) do
    app_env = normalize_config_source(Application.get_env(:scoria, __MODULE__, []))
    per_call = normalize_config_source(Map.get(context, :confluence, %{}))

    Enum.reduce(@config_keys, %{}, fn key, acc ->
      default = Map.fetch!(@shipped_config, key)
      after_app = resolve_app_rung(key, app_env, default)
      final = resolve_per_call_rung(key, per_call, after_app)
      Map.put(acc, key, final)
    end)
  end

  @doc """
  Validates `config :scoria, Scoria.Confluence` in isolation, without any
  per-call input. Returns `:ok` or `{:unknown_grade, key}` for the first
  unrecognized key found.

  NEVER raises and must NEVER be called from `Application.start/2` -- a
  boot crash takes the entire host application down (D-34); a
  misconfigured app env is logged once and refuses the next run creation
  (`Scoria.Runtime.Params.start/2`), never the boot. A malformed VALUE for
  a recognized key is a separate, silent-fallback concern handled by
  `resolve_config/1` at the hot path -- refusing every tool call on a
  configuration typo is itself the brick.
  """
  @spec validate_app_env() :: :ok | {:unknown_grade, atom()}
  def validate_app_env do
    app_env = normalize_config_source(Application.get_env(:scoria, __MODULE__, []))

    app_env
    |> Map.keys()
    |> Enum.find(&(&1 not in @config_keys))
    |> case do
      nil -> :ok
      key -> warn_unknown_key(key)
    end
  rescue
    _exception -> :ok
  end

  defp resolve_app_rung(key, app_env, default) do
    case Map.get(app_env, key) do
      nil ->
        default

      raw ->
        if valid_config_value?(key, raw) do
          raw
        else
          warn_invalid_value(key, raw, default)
          default
        end
    end
  end

  defp resolve_per_call_rung(key, per_call, resolved) do
    case Map.get(per_call, key) do
      nil ->
        resolved

      raw ->
        if valid_config_value?(key, raw) and tighter?(key, raw, resolved) do
          raw
        else
          resolved
        end
    end
  end

  defp valid_config_value?(:strict, value), do: is_boolean(value)
  defp valid_config_value?(:enforcement, value), do: value in [:enforce, :observe]
  defp valid_config_value?(key, value) when key in @decision_keys, do: value in [:allow, :escalate, :block]
  defp valid_config_value?(_key, _value), do: false

  defp tighter?(:strict, new, old), do: new == true and old != true
  defp tighter?(:enforcement, new, old), do: enforcement_rank(new) > enforcement_rank(old)
  defp tighter?(key, new, old) when key in @decision_keys, do: decision_rank(new) > decision_rank(old)
  defp tighter?(_key, _new, _old), do: false

  defp enforcement_rank(:observe), do: 0
  defp enforcement_rank(:enforce), do: 1
  defp enforcement_rank(_other), do: -1

  defp decision_rank(:allow), do: 0
  defp decision_rank(:escalate), do: 1
  defp decision_rank(:block), do: 2
  defp decision_rank(_other), do: -1

  defp normalize_config_source(value) when is_list(value), do: Enum.into(value, %{})
  defp normalize_config_source(value) when is_map(value), do: value
  defp normalize_config_source(_value), do: %{}

  defp warn_invalid_value(key, raw, default) do
    if first_warning_for_key?({:invalid_value, key}) do
      Logger.warning(
        "Scoria.Confluence: invalid config :scoria, Scoria.Confluence for #{inspect(key)}: " <>
          "#{inspect(raw)} -- falling back to #{inspect(default)}"
      )
    end

    :ok
  end

  defp warn_unknown_key(key) do
    if first_warning_for_key?({:unknown_key, key}) do
      Logger.warning(
        "Scoria.Confluence: unknown config key #{inspect(key)} in config :scoria, Scoria.Confluence"
      )
    end

    {:unknown_grade, key}
  end

  defp first_warning_for_key?(key) do
    ensure_warned_table()
    :ets.insert_new(@warned_table, {key, true})
  end

  defp ensure_warned_table do
    case :ets.whereis(@warned_table) do
      :undefined -> :ets.new(@warned_table, [:named_table, :set, :public, read_concurrency: true])
      _table -> :ok
    end
  end

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
    computed_grade = grade(%{private_data: private_data, untrusted_content: untrusted_content, exfil: exfil})

    %Evidence{
      combination: combination,
      grade: computed_grade,
      decision: Keyword.get(opts, :decision),
      reason_code:
        Keyword.get(opts, :reason_code) ||
          leg_reason_code(computed_grade, private_data, untrusted_content, exfil),
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

  # Surfaces the culprit leg's own `:reason_code` onto the evidence when
  # that leg's `:source` is the very category that determined the overall
  # grade -- e.g. an untrusted-content leg carrying
  # `%{source: :scanner_infra, reason_code: :scanner_malformed}` surfaces
  # `:scanner_malformed` on the evidence exactly when `"scanner_infra"` is
  # the resolved grade (D-30's cascade four). Never picks a reason code
  # from a leg that did NOT contribute the winning grade.
  defp leg_reason_code(nil, _private_data, _untrusted_content, _exfil), do: nil

  defp leg_reason_code(computed_grade, private_data, untrusted_content, exfil) do
    [private_data, untrusted_content, exfil]
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(fn witness -> grade_for_source(Map.get(witness, :source)) == computed_grade end)
    |> Enum.find_value(fn witness -> Map.get(witness, :reason_code) end)
    |> case do
      nil -> nil
      code -> normalize_reason_code(code)
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

  # -- audit_metadata/1 (D-39, plan 57-07) ---------------------------------

  @audit_metadata_keys [
    {:combination, "combination"},
    {:grade, "grade"},
    {:decision, "decision"},
    {:reason_code, "reason_code"},
    {:private_data_source, "private_data_source"},
    {:untrusted_content_source, "untrusted_content_source"},
    {:exfil_source, "exfil_source"},
    {:action_class, "action_class"},
    {:confluence_idempotency_key, "confluence_idempotency_key"},
    {:tool_ref, "tool_ref"}
  ]

  @doc """
  Projects `evidence` onto EXACTLY the closed confluence audit key set --
  the combination, the grade, the decision, the reason code, the three leg
  sources, the action class, the confluence idempotency key and the tool
  reference -- and nothing else (D-39).

  Structured like `Semconv.confluence_attributes/1`: a reduce over a
  hand-written fixed key list, reading ONLY the named fields off `evidence`
  and skipping a `nil` value entirely (never defaulted, never put). This is
  an OUTPUT, never a spread: an extra field attached to `evidence` (via
  `Map.put/3`, bypassing the struct's own closed field set) is simply never
  read, so it can never appear in the result -- no raw tool arguments, no
  free-text content, no scanner output can ride along, regardless of what
  is attached to the input.

  The caller (`Scoria.MCP.Executor`) passes this map's OUTPUT directly as
  the audit envelope's `metadata:` key handed to
  `SRE.create_audit_outbox_event/1` -- `SRE.build_audit_metadata/1` is a
  DROP-LIST, not an allowlist, so this is the ONE place the closed set is
  defined; nothing upstream of it may assemble metadata inline.
  """
  @spec audit_metadata(Evidence.t()) :: map()
  def audit_metadata(%Evidence{} = evidence) do
    Enum.reduce(@audit_metadata_keys, %{}, fn {field, key}, acc ->
      case Map.get(evidence, field) do
        nil -> acc
        value -> Map.put(acc, key, audit_metadata_value(value))
      end
    end)
  end

  defp audit_metadata_value(value) when is_atom(value) and not is_boolean(value),
    do: Atom.to_string(value)

  defp audit_metadata_value(value), do: value
end
