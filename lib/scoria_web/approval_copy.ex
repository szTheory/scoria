defmodule ScoriaWeb.ApprovalCopy do
  @moduledoc """
  Operator-facing copy for approval requests.

  This module keeps approval language consistent across the inbox, drawer, and
  confirmation modal while keeping raw runtime fields secondary.
  """

  @seed_keys ~w(seed_kind seed_key seed_version)

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

  def detail(nil), do: "Approval required by tool policy."
  def detail(approval), do: field(approval, :reason) || "Approval required by tool policy."

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
      "send_customer_update" -> "Send update"
      _ -> "Approve request"
    end
  end

  def reject_label(_approval), do: "Deny request"

  def decision_title("approve", approval), do: approve_label(approval)
  def decision_title("reject", _approval), do: "Deny request"
  def decision_title(_decision, _approval), do: "Review approval"

  def decision_badge("approve"), do: "Run can continue"
  def decision_badge("reject"), do: "Run waits for approval"
  def decision_badge(_decision), do: "Decision pending"

  def decision_copy("approve", approval) do
    "Approving records your decision for #{title(approval)}. Scoria then tries to continue the same run."
  end

  def decision_copy("reject", approval) do
    "Denying records your decision for #{title(approval)}. The run stays waiting for approval until the app retries or requests a new approval."
  end

  def decision_copy(_decision, _approval),
    do: "Review the evidence before recording a durable approval decision."

  def request_rows(nil), do: []

  def request_rows(approval) do
    [
      {"Request", title(approval)},
      {"Target", target(approval)},
      {"Policy reason", detail(approval)},
      {"Expected effect", impact(approval)}
    ]
    |> reject_blank_rows()
  end

  def evidence_rows(nil), do: []

  def evidence_rows(approval) do
    [
      {"Requested by", requested_by(approval)},
      {"Connector", connector_label(approval)},
      {"Policy", policy(approval)},
      {"Session", field(approval, :session_id)},
      {"Status", field(approval, :status)}
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

  defp present?(value), do: is_binary(value) and value != ""
end
