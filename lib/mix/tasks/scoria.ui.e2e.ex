defmodule Mix.Tasks.Scoria.Ui.E2e do
  @shortdoc "Runs the dashboard e2e assertion lane (Playwright) against a running dev server"

  @moduledoc """
  Runs the real-browser e2e assertion lane for the Scoria dashboard.

  This is the Tier 2 complement to the server-rendered LiveView tests: it asserts
  the truths a `Phoenix.LiveViewTest` (Floki, no JS engine) cannot reach —
  client-side JS execution (`JS.hide` auto-dismiss), CSS layout, and async
  re-render in a live browser. Specs live in `priv/dev/e2e/*.spec.mjs` and are
  picked up automatically (the lane is `testDir`-driven), so a future phase adds
  a spec file with no new mix task.

  Like `mix scoria.ui.shots`, this task does **not** start the Elixir app or boot
  a web server — the Node/Playwright process drives an already-running dev server.

  ## Usage

      mix scoria.ui.e2e [--base-url http://localhost:4000/scoria]

  ## Prerequisites

    * `Node.js >= 18` on `PATH`.
    * The e2e deps + Chromium installed:

          npm --prefix priv/dev ci
          npx --prefix priv/dev playwright install --with-deps chromium

    * The dev server running with seed data applied:

          mix dev.setup
          mix phx.server

  Then, in a second shell:

      mix scoria.ui.e2e

  ## Notes

    * Spec files are dev-only and excluded from the Hex package (`priv/dev` is not
      in `mix.exs` `files:`).
    * `dev_seed.exs` creates exactly one pending approval for tenant `acme-corp`;
      the toast specs are written around that (see `priv/dev/e2e/uat.spec.mjs`).
  """

  use Mix.Task

  @switches [base_url: :string, url: :string]

  @impl Mix.Task
  def run(args) do
    {opts, _, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    if is_nil(System.find_executable("node")) do
      Mix.raise("""
      Cannot find the `node` executable. Install Node.js >= 18 and ensure it
      is on your PATH, then re-run:

          mix scoria.ui.e2e
      """)
    end

    if is_nil(System.find_executable("npx")) do
      Mix.raise("Cannot find `npx` (ships with Node.js >= 18). Install Node.js and re-run.")
    end

    base_url = opts[:base_url] || opts[:url] || "http://localhost:4000/scoria"
    priv_dev = Path.join([File.cwd!(), "priv", "dev"])

    Mix.shell().info("[scoria.ui.e2e] Running Playwright e2e against #{base_url} ...")

    # Discrete args list — never a shell command string (T-11-04 injection mitigation).
    # Run from priv/dev so @playwright/test resolves from priv/dev/node_modules; the
    # config's testDir is relative to the config file (priv/dev/e2e).
    cmd_args = ["playwright", "test", "--config", "e2e/playwright.config.mjs"]

    case System.cmd("npx", cmd_args,
           cd: priv_dev,
           env: [{"PLAYWRIGHT_BASE_URL", base_url}],
           stderr_to_stdout: true,
           into: IO.stream()
         ) do
      {_, 0} ->
        Mix.shell().info("[scoria.ui.e2e] Done. Report: priv/dev/e2e/playwright-report/index.html")
        :ok

      {_, code} ->
        Mix.raise("playwright e2e exited with code #{code}")
    end
  end
end
