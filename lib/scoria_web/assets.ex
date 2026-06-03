defmodule ScoriaWeb.Assets do
  @moduledoc """
  Compile-time-embedded, self-contained dashboard assets.

  The compiled CSS/JS bundles (built by `mix scoria.assets.build` into
  `priv/static/scoria/`) are read at COMPILE TIME and baked into this module. The Scoria
  root layout inlines them into a `<style>` / `<script>` tag, so the dashboard is fully
  styled and interactive under any mount path with no dependency on the host's asset
  pipeline (the Phoenix LiveDashboard / Oban Web self-contained model).

  Inlining (vs hashed asset routes) keeps the library independent of the host's mount path
  and `Plug.Static` configuration. For a LiveView dashboard full page loads are rare
  (navigation is via live patches), so the one-time inline cost is acceptable.
  """

  css_path =
    [__DIR__, "..", "..", "priv", "static", "scoria", "app.css"] |> Path.join() |> Path.expand()

  js_path =
    [__DIR__, "..", "..", "priv", "static", "scoria", "app.js"] |> Path.join() |> Path.expand()

  @external_resource css_path
  @external_resource js_path

  @css (if File.exists?(css_path), do: File.read!(css_path), else: "")
  @js (if File.exists?(js_path), do: File.read!(js_path), else: "")
  @css_hash Base.encode16(:crypto.hash(:md5, @css), case: :lower)
  @js_hash Base.encode16(:crypto.hash(:md5, @js), case: :lower)

  @doc "Compiled dashboard stylesheet (inlined into the root layout)."
  def css, do: @css

  @doc "Compiled dashboard client bundle (inlined into the root layout)."
  def js, do: @js

  @doc "Content hash of the compiled CSS (for cache keys / smoke checks)."
  def css_hash, do: @css_hash

  @doc "Content hash of the compiled JS (for cache keys / smoke checks)."
  def js_hash, do: @js_hash

  @doc "True when the compiled bundle is present (i.e. `mix scoria.assets.build` has run)."
  def built?, do: @css != "" and @js != ""
end
