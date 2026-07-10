defmodule Scoria.Observe.OperatorBroadcast do
  @moduledoc """
  Legacy 0.1.x compatibility wrapper for `Scoria.Observe.ReviewerBroadcast`.

  0.1.x compatibility migration note: new code should use
  `Scoria.Observe.ReviewerBroadcast` for tenant-scoped reviewer trace PubSub
  events. This module keeps the old operator broadcast name as a delegating
  alias for copied 0.1.x integrations while public docs and dashboard copy move
  to reviewer vocabulary.

  The wrapper does not add runtime deprecation warnings. See
  `guides/reference/glossary.md` for the compatibility alias map.
  """

  alias Scoria.Observe.ReviewerBroadcast

  defdelegate tenant_topic(tenant_id), to: ReviewerBroadcast
  defdelegate broadcast(tenant_id, message), to: ReviewerBroadcast
  defdelegate span_stopped(metadata), to: ReviewerBroadcast
  defdelegate span_delta(metadata), to: ReviewerBroadcast
  defdelegate hitl_request(tenant_id, projection_map), to: ReviewerBroadcast
  defdelegate approval_decided(tenant_id, approval_id, status), to: ReviewerBroadcast
  defdelegate reset_trace_seen!, to: ReviewerBroadcast
end
