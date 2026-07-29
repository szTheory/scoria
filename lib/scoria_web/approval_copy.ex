defmodule ScoriaWeb.ApprovalCopy do
  @moduledoc """
  Operator-facing copy for approval requests.

  This module keeps approval language consistent across the inbox, drawer, and
  confirmation modal while keeping raw runtime fields secondary.
  """

  @seed_keys ~w(seed_kind seed_key seed_version)

  # -- D-48/D-49: confluence evidence copy -----------------------------------
  #
  # A confluence approval's request rows must show a human WHY they are being
  # asked to authorize an exfiltration: the named combination, which legs are
  # lit and where each came from, and how strong that evidence is. An approval
  # prompt with only a free-text reason is a consent-manufacturing machine,
  # not a human-in-the-loop control.
  #
  # Machine names use the `Scoria.Confluence.combinations/0` exfil spelling
  # (owned by the phase that owns the enum); human-facing strings use
  # "external egress" (GOVERN-01's own word). This split is deliberate — do
  # not unify them.
  @combination_labels %{
    "none" => "No trifecta legs observed",
    "private_data" => "Private data only",
    "untrusted_content" => "Untrusted content only",
    "exfil_capable" => "External egress capable only",
    "private_data_and_untrusted_content" => "Private data + untrusted content",
    "private_data_to_egress" => "Private data + external egress",
    "untrusted_content_to_egress" => "Untrusted content + external egress",
    "exfiltration_path" =>
      "Private data + untrusted content + external egress → exfiltration path"
  }

  @combination_tones %{
    "none" => :neutral,
    "private_data" => :neutral,
    "untrusted_content" => :neutral,
    "exfil_capable" => :neutral,
    "private_data_and_untrusted_content" => :warn,
    "private_data_to_egress" => :warn,
    "untrusted_content_to_egress" => :warn,
    "exfiltration_path" => :fail
  }

  # {evidence field key, human-facing leg label} -- deliberately mirrors
  # `Scoria.Confluence.Evidence{}`'s field names so a caller that eventually
  # persists the evidence onto the approval needs no translation layer here.
  @leg_specs [
    {:private_data_source, "Private data"},
    {:untrusted_content_source, "Untrusted content"},
    {:exfil_source, "External egress"}
  ]

  def title(nil), do: "Approval request"

  def title(approval) do
    case field(approval, :tool_name) do
      "issue_refund" ->
        case {money_amount(argument(approval, "amount_cents")), argument(approval, "ticket_id")} do
          {amount, ticket_id} when is_binary(amount) and is_binary(ticket_id) ->
            "Issue #{amount} refund"

          {amount, _ticket_id} when is_binary(amount) ->
            "Issue #{amount} refund"

          {_amount, ticket_id} when is_binary(ticket_id) ->
            "Issue refund for #{ticket_id}"

          _ ->
            "Issue refund"
        end

      "dataset_baseline_promotion" ->
        baseline = field(approval, :baseline_target) || %{}

        dataset =
          map_value(baseline, "dataset_name") || map_value(baseline, "dataset_id") || "dataset"

        case map_value(baseline, "dataset_version") do
          nil -> "Promote #{dataset}"
          version -> "Promote #{dataset} v#{version}"
        end

      "grant_connector_scope" ->
        connector = argument(approval, "connector") || connector_label(approval) || "connector"
        scope = argument(approval, "scope")

        if present?(scope) do
          "Grant #{connector} #{scope}"
        else
          "Grant connector scope"
        end

      "send_customer_update" ->
        ticket_id = argument(approval, "ticket_id")
        channel = argument(approval, "channel") || "customer"

        if present?(ticket_id) do
          "Send #{channel} update for #{ticket_id}"
        else
          "Send customer update"
        end

      tool_name ->
        tool_label(tool_name)
    end
  end

  def detail(nil), do: "Tool policy requires review."
  def detail(approval), do: field(approval, :reason) || "Tool policy requires review."

  def policy(approval) do
    field(approval, :policy_key) || "Tool policy"
  end

  def target(nil), do: "Target not recorded"

  def target(approval) do
    case field(approval, :tool_name) do
      "issue_refund" ->
        compact_join([
          argument(approval, "customer"),
          argument(approval, "ticket_id")
        ])
        |> empty_to("Customer refund")

      "dataset_baseline_promotion" ->
        baseline = field(approval, :baseline_target) || %{}

        compact_join([
          map_value(baseline, "dataset_name"),
          version_label(map_value(baseline, "dataset_version"))
        ])
        |> empty_to("Dataset baseline")

      "grant_connector_scope" ->
        compact_join([connector_label(approval), argument(approval, "scope")])
        |> empty_to("Connector scope")

      "send_customer_update" ->
        compact_join([argument(approval, "ticket_id"), argument(approval, "channel")])
        |> empty_to("Customer message")

      _ ->
        field(approval, :subject_ref) || connector_label(approval) || "Run action"
    end
  end

  def impact(nil), do: nil

  def impact(approval) do
    case field(approval, :tool_name) do
      "issue_refund" ->
        amount = money_amount(argument(approval, "amount_cents"))

        approve_copy =
          if amount do
            "Approving issues a #{amount} refund."
          else
            "Approving issues the refund."
          end

        approve_copy <> " Denying leaves the run waiting for approval."

      "dataset_baseline_promotion" ->
        "Approving changes the baseline used by regression gates. Denying leaves the promotion waiting for approval."

      "grant_connector_scope" ->
        "Approving grants the requested connector scope. Denying leaves the run waiting for approval."

      "send_customer_update" ->
        "Approving sends the customer update. Denying leaves the message unsent and the run waiting for approval."

      _ ->
        "Approving lets the run continue. Denying leaves the run waiting for approval."
    end
  end

  def requested_by(nil), do: "Requester not recorded"

  def requested_by(approval) do
    cond do
      present?(field(approval, :actor_id)) -> field(approval, :actor_id)
      present?(field(approval, :session_id)) -> "Session #{field(approval, :session_id)}"
      true -> "Requester not recorded"
    end
  end

  def context_detail(nil), do: nil

  def context_detail(approval) do
    connector = connector_label(approval)
    session = field(approval, :session_id)

    cond do
      present?(connector) and present?(session) -> "#{connector} - session #{session}"
      present?(connector) -> connector
      present?(session) and present?(field(approval, :actor_id)) -> "session #{session}"
      true -> nil
    end
  end

  def connector_label(approval) do
    field(approval, :connector_label) || connector_label_for_kind(field(approval, :blocker_kind))
  end

  def approve_label(nil), do: "Approve request"

  def approve_label(approval) do
    case field(approval, :tool_name) do
      "issue_refund" -> "Approve refund"
      "dataset_baseline_promotion" -> "Approve baseline"
      "grant_connector_scope" -> "Grant scope"
      "send_customer_update" -> send_customer_update_label(approval)
      _ -> "Approve request"
    end
  end

  def reject_label(_approval), do: "Deny request"

  def decision_title("approve", approval), do: approve_label(approval)
  def decision_title("reject", _approval), do: "Deny request"
  def decision_title("approve_run_scoped", approval), do: run_scoped_approve_label(approval)
  def decision_title(_decision, _approval), do: "Review approval"

  def decision_badge("approve"), do: "Run can continue"
  def decision_badge("reject"), do: "Run waits for approval"
  def decision_badge("approve_run_scoped"), do: "Run can continue"
  def decision_badge(_decision), do: "Decision pending"

  def decision_copy("approve", approval) do
    "Approving records your decision for #{title(approval)}. Scoria then tries to continue the same run."
  end

  def decision_copy("reject", approval) do
    "Denying records your decision for #{title(approval)}. The run stays waiting for approval until the app retries or requests a new approval."
  end

  def decision_copy("approve_run_scoped", approval), do: run_scoped_decision_copy(approval)

  def decision_copy(_decision, _approval),
    do: "Review the evidence before recording a durable approval decision."

  @doc """
  Reviewer-facing label for the D-50 bounded run-scoped approve action --
  a confluence-kind approval only. States the bound (this tool, this run)
  in the label itself, so the drawer never reads like a plain "Approve" a
  reviewer could mistake for a standing grant.
  """
  def run_scoped_approve_label(approval) do
    "Approve #{tool_name_label(approval)} for the rest of this run"
  end

  @doc """
  Reviewer-facing confirmation copy for the D-50 bounded run-scoped
  approve action. Names the tool and states plainly that the grant ends
  with this run -- it is not approve-once-exfil-forever (D-44): it cannot
  match a different run, a different tool, or a different evidence grade.
  """
  def run_scoped_decision_copy(approval) do
    "Approving grants #{tool_name_label(approval)} for the remainder of this run, at this evidence grade. The grant ends when this run ends -- it never applies to a different run, tool, or grade."
  end

  @doc """
  Single canonical decision-status string for the drawer/history badge (D-16 dedup).

  Delegates the "rejected" clause to `decision_outcome/1` so "Denied" has exactly
  one source (D-24d).
  """
  def status_line(approval) do
    case field(approval, :status) do
      "approved" -> "Approved"
      "rejected" -> decision_outcome(approval)
      "expired" -> "Expired"
      _ -> "Decision pending"
    end
  end

  @doc """
  Tool context for the drawer eyebrow, replacing the generic "Approval request" (D-16).
  """
  def eyebrow(nil), do: "Approval request"

  def eyebrow(approval) do
    case field(approval, :tool_name) do
      "issue_refund" -> "Refund approval"
      "dataset_baseline_promotion" -> "Baseline approval"
      "grant_connector_scope" -> "Connector approval"
      "send_customer_update" -> "Customer message approval"
      nil -> "Approval request"
      tool_name -> "#{tool_label(tool_name)} approval"
    end
  end

  @doc """
  The single home for the operator word "Denied" (D-24d) — never duplicate this
  mapping elsewhere (the global `status_label/1` titlecases "rejected" generically
  and must stay that way).
  """
  def decision_outcome(approval) do
    case field(approval, :status) do
      "approved" -> "Approved"
      "rejected" -> "Denied"
      "expired" -> "Expired"
      _ -> "Decision pending"
    end
  end

  @doc """
  The concrete, irreversible-effect lead clause reused by the confirm modal (D-15)
  and the drawer consequence line — the lead sentence of `impact/1` without the
  "Approving"/"Denying" framing.
  """
  def impact_lead(nil), do: nil

  def impact_lead(approval) do
    case field(approval, :tool_name) do
      "issue_refund" ->
        amount = money_amount(argument(approval, "amount_cents"))
        customer = argument(approval, "customer") || argument(approval, "ticket_id")

        case {amount, customer} do
          {amount, customer} when is_binary(amount) and is_binary(customer) ->
            "This issues a #{amount} refund to #{customer}."

          {amount, _customer} when is_binary(amount) ->
            "This issues a #{amount} refund."

          _ ->
            "This issues the refund."
        end

      "dataset_baseline_promotion" ->
        "This changes the baseline used by regression gates."

      "grant_connector_scope" ->
        "This grants the requested connector scope."

      "send_customer_update" ->
        "This sends the customer update."

      _ ->
        "This lets the run continue."
    end
  end

  @doc """
  ⚠ SAFETY (D-27): states the RECORDED DECISION only — never that the tool
  side-effect or run continuation succeeded. `decider`/`decided_at` are explicit
  arguments sourced by the caller from the decision `AuditOutboxEvent` (Plan 07);
  this function never invents values. "Expired" renders without a fabricated actor
  (no operator decides an expiry) and only shows a time when the caller supplies one
  from a real `approval.expired` audit event (D-18/D-21).
  """
  def decision_receipt("approved", decider, decided_at)
      when is_binary(decider) and not is_nil(decided_at) do
    "Approved by #{decider} · #{decided_at}"
  end

  def decision_receipt("rejected", decider, decided_at)
      when is_binary(decider) and not is_nil(decided_at) do
    "Denied by #{decider} · #{decided_at}"
  end

  def decision_receipt("expired", _decider, decided_at) when not is_nil(decided_at) do
    "Expired · #{decided_at}"
  end

  def decision_receipt(status, _decider, _decided_at)
      when status in ["approved", "rejected", "expired"] do
    decision_outcome(%{"status" => status})
  end

  def decision_receipt(_status, _decider, _decided_at), do: "Decision pending"

  @doc """
  Human-facing label for a `Scoria.Confluence` combination value (D-49).
  Falls back to a neutral generic label for any unrecognized value and never
  raises — an unknown combination must never crash the drawer.
  """
  def combination_label(combination) do
    Map.get(@combination_labels, combination, "Unrecognized combination")
  end

  @doc """
  Semantic tone (`:fail` | `:warn` | `:neutral`) for a `Scoria.Confluence`
  combination value (D-49). Falls back to `:neutral` for any unrecognized
  value and never raises.
  """
  def combination_tone(combination) do
    Map.get(@combination_tones, combination, :neutral)
  end

  def request_rows(nil), do: []

  def request_rows(approval) do
    [
      {"Target", target(approval)},
      {"Policy reason", detail(approval)}
    ]
    |> maybe_append_confluence_rows(approval)
    |> reject_blank_rows()
  end

  def evidence_rows(nil), do: []

  def evidence_rows(approval) do
    [
      {"Requested by", requested_by(approval)},
      {"Connector", connector_label(approval)},
      {"Policy", policy(approval)},
      {"Session", field(approval, :session_id)}
    ]
    |> reject_blank_rows()
  end

  def raw_arguments(approval) do
    approval
    |> field(:arguments_preview)
    |> case do
      arguments when is_map(arguments) ->
        arguments
        |> Map.drop(@seed_keys)
        |> inspect(pretty: true, limit: :infinity, printable_limit: :infinity)

      nil ->
        "No request payload recorded."

      other ->
        inspect(other, pretty: true, limit: :infinity, printable_limit: :infinity)
    end
  end

  def field(nil, _field), do: nil

  def field(approval, field) do
    Map.get(approval, field) || Map.get(approval, Atom.to_string(field))
  end

  def short_id(nil), do: "Not recorded"
  def short_id(id), do: id |> to_string() |> String.slice(0, 8)

  def argument(approval, key) do
    approval
    |> field(:arguments_preview)
    |> map_value(key)
  end

  def map_value(map, key) when is_map(map) do
    Map.get(map, key) || existing_atom_value(map, key)
  end

  def map_value(_map, _key), do: nil

  def money_amount(cents) when is_integer(cents),
    do: "$#{:erlang.float_to_binary(cents / 100, decimals: 2)}"

  def money_amount(cents) when is_binary(cents) do
    case Integer.parse(cents) do
      {amount, ""} -> money_amount(amount)
      _ -> nil
    end
  end

  def money_amount(_cents), do: nil

  defp existing_atom_value(map, key) do
    Map.get(map, String.to_existing_atom(key))
  rescue
    ArgumentError -> nil
  end

  defp connector_label_for_kind("connector"), do: "Connector approval"
  defp connector_label_for_kind(_kind), do: nil

  defp version_label(nil), do: nil
  defp version_label(version), do: "v#{version}"

  defp send_customer_update_label(approval) do
    case argument(approval, "channel") do
      "email" -> "Send email"
      "sms" -> "Send SMS"
      "chat" -> "Send chat reply"
      channel when is_binary(channel) and channel != "" -> "Send #{channel} update"
      _ -> "Send customer update"
    end
  end

  defp compact_join(values) do
    values
    |> Enum.filter(&present?/1)
    |> Enum.join(" - ")
  end

  defp empty_to("", fallback), do: fallback
  defp empty_to(nil, fallback), do: fallback
  defp empty_to(value, _fallback), do: value

  defp reject_blank_rows(rows) do
    Enum.reject(rows, fn {_label, value} -> blank?(value) end)
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_), do: false

  defp tool_label(nil), do: "Approval request"
  defp tool_label(tool), do: to_string(tool)

  defp tool_name_label(approval) do
    case field(approval, :tool_name) do
      nil -> "this tool"
      name -> to_string(name)
    end
  end

  defp present?(value), do: is_binary(value) and value != ""

  # D-48: a non-confluence approval's rows must stay byte-identical to their
  # pre-phase values -- only a `blocker_kind: "confluence"` approval gains
  # the combination/leg/grade rows.
  defp maybe_append_confluence_rows(rows, approval) do
    if field(approval, :blocker_kind) == "confluence" do
      rows ++ confluence_rows(approval)
    else
      rows
    end
  end

  defp confluence_rows(approval) do
    combination = field(approval, :combination)

    leg_rows =
      @leg_specs
      |> Enum.map(fn {key, label} ->
        case field(approval, key) do
          nil -> nil
          source -> {"#{label} evidence", witness_source_label(source)}
        end
      end)
      |> Enum.reject(&is_nil/1)

    [{"Combination", combination && combination_label(combination)}] ++
      leg_rows ++ [{"Evidence grade", grade_label(field(approval, :grade))}]
  end

  defp witness_source_label(:declared), do: "Declared by the tool"
  defp witness_source_label(:scanner_infra), do: "Observed by the content scanner"
  defp witness_source_label(:default_tier), do: "Default tier (no scanner installed)"
  defp witness_source_label(:unclassified), do: "Unclassified"
  defp witness_source_label(_other), do: "Unknown source"

  defp grade_label("declared"), do: "Declared"
  defp grade_label("scanner_infra"), do: "Scanner infrastructure"
  defp grade_label("default_tier"), do: "Default tier"
  defp grade_label("unclassified"), do: "Unclassified"
  defp grade_label(_other), do: nil
end
