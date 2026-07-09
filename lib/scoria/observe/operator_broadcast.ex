defmodule Scoria.Observe.OperatorBroadcast do
  @moduledoc """
  Legacy 0.1.x compatibility wrapper for `Scoria.Observe.ReviewerBroadcast`.

  Use `Scoria.Observe.ReviewerBroadcast` for final reviewer trace broadcast
  vocabulary.
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
