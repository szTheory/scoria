defmodule ScoriaWeb.SingleHeaderRenderedGuardTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end
end

defmodule ScoriaWeb.SingleHeaderRenderedGuardTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_single_header_rendered_guard_key",
    signing_salt: "single_header_rendered_guard_salt"
  )

  plug(ScoriaWeb.SingleHeaderRenderedGuardTest.Router)
end

defmodule ScoriaWeb.SingleHeaderRenderedGuardTest.ErrorView do
  # File-scoped stub (mirrors the already-namespaced Router/Endpoint above).
  # A bare `ScoriaWeb.ErrorView` here collides with the identical definition in
  # review_queue_live_test.exs under Elixir's parallel test compiler
  # ("cannot define module ScoriaWeb.ErrorView because it is currently being
  # defined in ..."). Namespacing keeps this endpoint's error stub self-contained.
  def render(_template, assigns), do: inspect(assigns)
end

defmodule ScoriaWeb.SingleHeaderRenderedGuardTest do
  use ExUnit.Case, async: false

  @moduledoc """
  D-06 / GAP-A rendered-DOM guard (PROOF-03's 8th named regression).

  `single_header_guard_test.exs` is a pure `File.read!/1` + `Regex` source scan
  (see its assertion 3 moduledoc, `single_header_guard_test.exs:28-30`), and it
  self-declares that it **cannot** verify the semantic-redundancy /
  dynamic-interpolated-title case: a region `page_section`/`panel` `:title`
  slot that restates the page's own `<h1>` once real data is interpolated
  (`{...}` HEEx expressions are explicitly skipped by that guard's
  `region_title_literals/1`). This module closes that deferral by rendering
  each routed page for real via `Phoenix.LiveViewTest.live/2`, parsing the
  actual output HTML with `Floki`, and comparing the *rendered* page title
  text against the *rendered* text of every region title in the DOM — no
  string literal ever has to be typed twice, and a dynamic/interpolated title
  is exercised exactly like a static one because both are just text nodes by
  the time the page has rendered.

  ## Selectors (verified against `lib/scoria_web/ui.ex`, Assumption A2)

  - Page title: `page_header/1` renders `<h1>{@title}</h1>` inside a
    `div.scoria-pagehead__title` wrapper (`ui.ex` around line 258-264).
  - Region titles: `panel/1` renders `<h2>{render_slot(@title)}</h2>` inside a
    `div.scoria-panel__header` wrapper only when a `:title` slot is given
    (`ui.ex` around line 191-197); `page_section/1` renders the same `<h2>`
    shape inside `div.scoria-page-section__header` (`ui.ex` around line
    222-231). Both selectors are scoped to their own header wrapper `<div>` so
    unrelated `<h2>`s elsewhere on the page (there are none in the covered
    routes today, but this keeps the guard structurally honest) are excluded.

  ## Covered routes

  The nine static/index live routes that render without a specific record ID
  or heavy fixture setup (`lib/scoria_web/router.ex:37-49`): `/`, `/approvals`,
  `/reviews`, `/datasets`, `/workflows`, `/connectors`, `/incidents`,
  `/eval_specs`, `/prompts`. All nine route through `page_header/1` for their
  page title (verified against each LiveView's `render/1`), so the page-title
  selector above applies uniformly.

  ## Documented param-route skips (honesty caveat, mirrors
  `dev_lab_boundary_test.exs`'s "Guard #7 honesty caveat")

  - `/workflows/:id`, `/incidents/:id`, `/prompts/:id/release` — these object
    pages render `object_header/1`, not `page_header/1`. `object_header/1` has
    no `:title` slot or free-text title attr at all (`ui.ex` around line
    494-537) — it renders a parent breadcrumb, object type badge, and a
    copyable ID instead of a page-outline heading string. There is
    structurally no "page title text" to compare a region title against on
    these pages, so the restatement check this guard proves is inapplicable
    to them. They are skipped for that reason, not for fixture-cost reasons.
  - `/coming/:screen` — `ComingSoonLive` renders either `stub_page/1` (known
    screen) or `page_header/1` (unknown/not-found screen), but never pairs
    either with a `panel/1` or `page_section/1` region `:title` slot
    (`lib/scoria_web/live/coming_soon_live.ex`) — there is no region title in
    this LiveView's rendered output at all, so there is nothing for this guard
    to compare. It is also a dynamic param route (multiple allowlisted
    screens, `DashboardNav.stub_screen/1`) rather than a single static path,
    which would require enumerating every screen slug to cover exhaustively.
    Skipped for the same "no comparable surface" reason as the object pages
    above, not merely because it takes a param.

  This guard is a coverage FLOOR for the nine covered routes, not a claim that
  every route in the router has been exercised — see the skip list above for
  the precise, reasoned boundary.
  """

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint ScoriaWeb.SingleHeaderRenderedGuardTest.Endpoint

  # {path, expected rendered <h1> page title text}
  @routes [
    {"/scoria", "Home"},
    {"/scoria/approvals", "Approvals"},
    {"/scoria/reviews", "Review Queue"},
    {"/scoria/datasets", "Dataset Builder"},
    {"/scoria/workflows", "Runs"},
    {"/scoria/connectors", "Connectors"},
    {"/scoria/incidents", "Incidents"},
    {"/scoria/eval_specs", "Evaluation Rubrics"},
    {"/scoria/prompts", "Prompt Registry"}
  ]

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.SingleHeaderRenderedGuardTest.Endpoint,
      secret_key_base:
        "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    start_supervised!(ScoriaWeb.SingleHeaderRenderedGuardTest.Endpoint)

    :ok
  end

  for {path, expected_title} <- @routes do
    test "#{path}: no rendered region title restates the rendered page title (#{inspect(expected_title)})" do
      path = unquote(path)
      expected_title = unquote(expected_title)

      {:ok, _view, html} = live(test_conn(), path)
      doc = Floki.parse_document!(html)

      page_title = page_title_text(doc)

      assert page_title == expected_title,
             "#{path}: rendered page_header/1 <h1> text #{inspect(page_title)} did not match the expected #{inspect(expected_title)} -- selector may have drifted from ui.ex (Assumption A2)"

      region_titles = region_title_texts(doc)

      offenders =
        Enum.filter(region_titles, fn region_title ->
          normalize(region_title) == normalize(page_title)
        end)

      assert offenders == [],
             """
             D-06/PROOF-03 rendered-DOM guard: #{path} renders a region title that
             restates the page's own rendered title #{inspect(page_title)}:
             #{Enum.map_join(offenders, "\n", &"  #{inspect(&1)}")}
               Fix: drop the redundant region :title (render the region flush/untitled)
               or give it a distinct, region-specific name.
             """
    end
  end

  defp test_conn do
    Phoenix.ConnTest.build_conn()
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.SingleHeaderRenderedGuardTest.Endpoint)
  end

  defp page_title_text(doc) do
    doc
    |> Floki.find(".scoria-pagehead__title h1")
    |> List.first()
    |> case do
      nil -> nil
      node -> node |> Floki.text() |> String.trim()
    end
  end

  defp region_title_texts(doc) do
    doc
    |> Floki.find(".scoria-panel__header h2, .scoria-page-section__header h2")
    |> Enum.map(&(&1 |> Floki.text() |> String.trim()))
  end

  defp normalize(text), do: text |> String.trim() |> String.downcase()
end
