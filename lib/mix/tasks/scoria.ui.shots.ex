defmodule Mix.Tasks.Scoria.Ui.Shots do
  @shortdoc "Captures dashboard screenshots across the state matrix"

  @moduledoc """
  Captures dashboard screenshots across the state matrix and (optionally)
  critiques them using the 9-dimension AI rubric.

  ## Usage

      mix scoria.ui.shots [options]

  ## Options

    * `--critique`        — Run the critique pass after capturing screenshots.
                           Requires `ANTHROPIC_API_KEY` to be set. Writes
                           per-screen findings JSON alongside the PNGs.
    * `--url`             — Base URL for the local dev server
                           (default: `http://localhost:4000/scoria`).
    * `--tenant-empty`    — Tenant slug for the empty-state captures
                           (default: `empty-tenant`).
    * `--tenant-seeded`   — Tenant slug for the populated-state captures
                           (default: `acme-corp`).
    * `--release-id`      — UUID of the seeded draft prompt template to navigate
                           to the release workbench. If omitted, the script
                           follows the first release link on the /prompts list.

  ## Prerequisites

    * `Node.js >= 18` installed and on `PATH`.
    * `Playwright` + Chromium installed:

          npm install -g playwright && npx playwright install chromium

    * The dev server must be running with seed data applied:

          mix run priv/repo/dev_seed.exs
          mix phx.server

  ## Screenshot pass

  The screenshot pass shells out to `priv/dev/shots.mjs` via Node.js. It does
  **not** start the Elixir application — the Node/Playwright process drives the
  running dev server directly. Outputs land in `priv/shots/{date}/`.

  ## Critique pass (`--critique`)

  Starts the Elixir app (to access ReqLLM), then calls
  `Scoria.UICritique.critique_screen/3` on each screen's canonical state
  (populated × desktop × dark) and writes a findings JSON file alongside
  the PNG. This pass does NOT aggregate the gap register — that step is
  handled by `mix scoria.ui.audit` in Plan 05.
  """

  use Mix.Task

  @screens ~w(live_ops approvals workflows incidents connectors reviews eval_specs prompts prompt_release)

  @switches [
    critique: :boolean,
    tenant_empty: :string,
    tenant_seeded: :string,
    url: :string,
    release_id: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    out_dir =
      Path.join([File.cwd!(), "priv", "shots", Date.to_iso8601(Date.utc_today())])

    File.mkdir_p!(out_dir)

    # Screenshot pass — always runs; does NOT start the Elixir app (Node only)
    run_screenshot_pass(opts, out_dir)

    # Critique pass — only with --critique flag; starts the app for ReqLLM
    if opts[:critique] do
      run_critique_pass(opts, out_dir)
    end
  end

  # ---------------------------------------------------------------------------
  # Screenshot pass
  # ---------------------------------------------------------------------------

  defp run_screenshot_pass(opts, out_dir) do
    node_exe = System.find_executable("node")

    if is_nil(node_exe) do
      Mix.raise("""
      Cannot find the `node` executable. Install Node.js >= 18 and ensure it
      is on your PATH, then re-run:

          mix scoria.ui.shots
      """)
    end

    script_path = Path.join([File.cwd!(), "priv", "dev", "shots.mjs"])
    base_url = opts[:url] || "http://localhost:4000/scoria"
    tenant_empty = opts[:tenant_empty] || "empty-tenant"
    tenant_seeded = opts[:tenant_seeded] || "acme-corp"

    # Count approximate total: 9 screens, each with 2 themes × 2 viewports = 4 baseline
    # shots per presence state; 5 tenant-scoped screens add 4 empty shots each.
    Mix.shell().info(
      "[scoria.ui.shots] Capturing #{length(@screens)} screens × multiple states..."
    )

    # Build discrete args list — NEVER a shell command string (T-11-04 shell injection mitigation)
    args =
      [
        script_path,
        "--base-url",
        base_url,
        "--tenant-empty",
        tenant_empty,
        "--tenant-seeded",
        tenant_seeded,
        "--out-dir",
        out_dir
      ] ++ if(opts[:release_id], do: ["--release-id", opts[:release_id]], else: [])

    case System.cmd("node", args, stderr_to_stdout: true, into: IO.stream()) do
      {_, 0} ->
        :ok

      {_, code} ->
        Mix.raise("shots.mjs exited with code #{code}")
    end

    Mix.shell().info(
      "[scoria.ui.shots] Done. Screenshots captured. Gap register: priv/shots/gap_register.md"
    )
  end

  # ---------------------------------------------------------------------------
  # Critique pass
  # ---------------------------------------------------------------------------

  defp run_critique_pass(opts, out_dir) do
    # Start the Elixir application — ReqLLM needs it for config/env
    Mix.Task.run("app.start")

    base_url = opts[:url] || "http://localhost:4000/scoria"
    _ = base_url

    Mix.shell().info("[scoria.ui.shots] Running critique pass (9 screens × canonical state)...")
    Mix.shell().info(
      "  Dimensions: brand-fit / consistency / hierarchy / affordance / a11y / responsive / motion / microcopy / density"
    )

    for screen <- @screens do
      png_path = Path.join([out_dir, screen, "populated_dark_desktop.png"])

      if File.exists?(png_path) do
        Mix.shell().info("  → #{screen} (critique)")

        findings = Scoria.UICritique.critique_screen(png_path, screen, [])

        json_path = Path.join([out_dir, screen, "populated_dark_desktop.json"])
        File.write!(json_path, Jason.encode!(findings, pretty: true))
        Mix.shell().info("  ✓ populated_dark_desktop.json")
      else
        Mix.shell().info(
          "  ! #{screen}: populated_dark_desktop.png not found — run the screenshot pass first"
        )
      end
    end

    Mix.shell().info("[scoria.ui.shots] Critique pass complete.")
  end
end
