defmodule ScoriaWeb.Layouts do
  @moduledoc """
  Root layout for the embedded Scoria dashboard.

  Scoria owns this layout (wired via the `scoria_dashboard` macro's `live_session`), so the
  dashboard renders a complete, self-contained HTML document — its own `<head>`, its own
  inlined stylesheet + client bundle, its own LiveSocket — independent of the host app's
  layout and asset pipeline.
  """
  use Phoenix.Component

  embed_templates("layouts/*")
end
