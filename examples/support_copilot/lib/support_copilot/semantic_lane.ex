defmodule SupportCopilot.SemanticLane do
  @moduledoc false

  use Scoria.SemanticLane,
    lane_key: "support_faq",
    default_scope: :tenant_shared,
    safe_read_only: true
end
