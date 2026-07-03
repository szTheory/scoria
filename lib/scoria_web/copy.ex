defmodule ScoriaWeb.Copy do
  @moduledoc """
  Strings-only operator copy.

  `ScoriaWeb.Copy` returns strings / keyword data ONLY and renders nothing —
  zero `~H`. It owns the canonical D-25 action-verb set, the D-25 status-label
  map, and the empty/error/loading copy strings (`empty_title/1`,
  `empty_cta/1`, `error_line/1`, `loading_label/1`).

  Hard line (D-24b): `Copy` is data, `ScoriaWeb.UI.empty_state/1` and
  `skeleton/1` stay the renderers that receive these strings.

  Per-domain copy that branches on record data (a `case`/`cond` on
  `status`/`tool_name`/`kind`) lives in the sibling per-domain modules
  (`IncidentCopy`, `DatasetCopy`, `ReviewCopy`, `ConnectorCopy`), each
  templated on `ScoriaWeb.ApprovalCopy` (D-24c).

  Voice: calm + exact + useful (brandbook §6). Never emits a banned word
  ("magic", "seamless", "Nothing here").
  """

  @action_verbs [
    approve: "Approve",
    deny: "Deny",
    promote: "Promote",
    add_manually: "Add manually",
    resolve: "Resolve",
    open: "Open",
    select: "Select",
    review: "Review",
    dismiss: "Dismiss",
    grant: "Grant",
    revoke: "Revoke",
    open_trace: "Open trace",
    retry: "Retry",
    pin: "Pin",
    compare: "Compare",
    edit: "Edit",
    run: "Run"
  ]

  @status_labels [
    {"pending", "Pending"},
    {"approved", "Approved"},
    {"expired", "Expired"},
    {"passed", "Passed"},
    {"failed", "Failed"},
    {"regressed", "Regressed"},
    {"running", "Running"},
    {"promoted", "Promoted"},
    {"draft", "Draft"},
    {"published", "Published"},
    {"connected", "Connected"},
    {"disconnected", "Disconnected"},
    {"idle", "Idle"}
  ]

  @doc "The full canonical D-25 action-verb keyword list."
  def action_verbs, do: @action_verbs

  @doc "The full canonical D-25 status-label vocabulary (excludes approval-domain 'Denied', D-24d)."
  def status_vocabulary, do: @status_labels

  @doc """
  Operator label for a D-25 action-verb key.

  Falls back to a humanized transform of the key for anything not curated
  (never raises — safe for unseen keys).
  """
  def action_verb(key) when is_atom(key) do
    Keyword.get(@action_verbs, key) || humanize(Atom.to_string(key))
  end

  def action_verb(key) when is_binary(key) do
    key
    |> String.to_atom()
    |> action_verb()
  end

  @doc """
  Operator label for a status value (D-25 canonical vocabulary).

  ADDITIVE-style lookup with a safe generic fallback — never raises on an
  unseen status. Does NOT curate `"rejected"` — "Denied" is approval-domain
  only (D-24d, `ApprovalCopy.decision_outcome/1`).
  """
  def status_label(nil), do: "Unknown"

  def status_label(status) when is_atom(status), do: status |> Atom.to_string() |> status_label()

  def status_label(status) when is_binary(status) do
    case List.keyfind(@status_labels, status, 0) do
      {_status, label} -> label
      nil -> humanize(status)
    end
  end

  def status_label(_status), do: "Unknown"

  @doc "Empty-state title for a domain/context key. Says what's missing, in domain nouns."
  def empty_title(:incidents), do: "No incidents match this view"
  def empty_title(:datasets), do: "No datasets match this view"
  def empty_title(:reviews), do: "No candidates need review"
  def empty_title(:connectors), do: "No runtimes connected"
  def empty_title(:approvals), do: "No approvals waiting"
  def empty_title(:runs), do: "No runs recorded yet"
  def empty_title(:evals), do: "No eval datasets yet"
  def empty_title(_domain), do: "No matches for these filters"

  @doc "Empty-state next-action copy for a domain/context key."
  def empty_cta(:incidents),
    do: "Incidents appear here once a connector or workflow reports one."

  def empty_cta(:datasets), do: "Promote a production trace to start a regression suite."
  def empty_cta(:reviews), do: "Review candidates appear here once a run needs a decision."

  def empty_cta(:connectors),
    do: "Runtime activity appears here once a host session connects for this tenant."

  def empty_cta(:approvals),
    do: "Approval requests appear here once a tool call needs a decision."

  def empty_cta(:runs), do: "Runs appear here once a workflow executes for this tenant."
  def empty_cta(:evals), do: "Promote a production trace to start a regression suite."
  def empty_cta(_domain), do: "Adjust your filters or check back once new data arrives."

  @doc "Error line for a failure reason key. Says what happened, not a vague apology."
  def error_line(:connection),
    do: "Could not reach the server. Check the connection and try again."

  def error_line(:not_found), do: "This record no longer exists or was removed."

  def error_line(:stale),
    do: "This record changed since it loaded. Refresh to see the latest state."

  def error_line(:unauthorized), do: "You don't have access to this action."
  def error_line(_reason), do: "Something interrupted this request. Try again."

  @doc "Loading label for a domain/context key."
  def loading_label(:incidents), do: "Loading incidents…"
  def loading_label(:datasets), do: "Loading datasets…"
  def loading_label(:reviews), do: "Loading review candidates…"
  def loading_label(:connectors), do: "Loading runtime and connector posture…"
  def loading_label(:approvals), do: "Loading approval requests…"
  def loading_label(:runs), do: "Loading runs…"
  def loading_label(:evals), do: "Loading eval datasets…"
  def loading_label(_domain), do: "Loading…"

  defp humanize(value) when is_binary(value) do
    value |> String.replace("_", " ") |> String.capitalize()
  end
end
