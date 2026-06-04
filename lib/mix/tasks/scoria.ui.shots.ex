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
  the PNG. After the per-screen loop completes, aggregates the findings
  into `priv/shots/gap_register.md` (the stable top-level baseline path).
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

    render_gap_register(out_dir, @screens)
  end

  # ---------------------------------------------------------------------------
  # Gap register rendering
  # ---------------------------------------------------------------------------

  # Aggregates per-screen findings JSON (already written by the critique pass)
  # into a ranked gap register at priv/shots/gap_register.md.
  #
  # Receives out_dir (the date-stamped directory used by the critique pass) as
  # a parameter — does NOT recompute it via Date.utc_today().
  #
  # The OUTPUT file is written to the top-level priv/shots/ directory (NOT
  # inside out_dir) so the committed baseline path is stable across runs.
  defp render_gap_register(out_dir, screens) do
    # Extract the date component from out_dir for the heading
    date_str = Path.basename(out_dir)

    # Read each screen's populated_dark_desktop.json; skip missing files
    screen_findings =
      Enum.flat_map(screens, fn screen ->
        json_path = Path.join([out_dir, screen, "populated_dark_desktop.json"])

        if File.exists?(json_path) do
          case Jason.decode(File.read!(json_path)) do
            {:ok, findings} -> [{screen, findings}]

            {:error, _} ->
              Mix.shell().info("  ! #{screen}: could not parse populated_dark_desktop.json — skipping")
              []
          end
        else
          Mix.shell().info("  ! #{screen}: populated_dark_desktop.json not found — skipping")
          []
        end
      end)

    screens_audited = length(screen_findings)

    # Flatten all {screen, dimension, score, findings_list} entries
    all_entries =
      Enum.flat_map(screen_findings, fn {screen, findings_map} ->
        Enum.flat_map(findings_map, fn {dimension, dim_data} ->
          case dim_data do
            %{"score" => score, "findings" => findings_list}
            when is_integer(score) and is_list(findings_list) ->
              [{screen, dimension, score, findings_list}]

            _ ->
              []
          end
        end)
      end)

    p0_count = Enum.count(all_entries, fn {_, _, score, _} -> score == 1 end)
    p1_count = Enum.count(all_entries, fn {_, _, score, _} -> score == 2 end)
    passing_count = Enum.count(all_entries, fn {_, _, score, _} -> score >= 3 end)

    # Ranked Findings: sort worst-first (score ascending), then screen + dimension
    ranked_entries =
      all_entries
      |> Enum.filter(fn {_, _, score, _} -> score <= 2 end)
      |> Enum.sort_by(fn {screen, dimension, score, _} -> {score, screen, dimension} end)

    ranked_section =
      if ranked_entries == [] do
        "No gaps found in this dimension.\n"
      else
        Enum.map_join(ranked_entries, "\n", fn {screen, dimension, score, findings_list} ->
          findings_text =
            if findings_list == [] do
              "> No gaps found in this dimension."
            else
              Enum.map_join(findings_list, "\n", fn finding -> "> #{finding}" end)
            end

          "### #{screen} — #{dimension}: #{score}/5\n#{findings_text}"
        end)
      end

    # Fix Backlog: P0 rows (score 1) before P1 rows (score 2)
    backlog_entries =
      all_entries
      |> Enum.filter(fn {_, _, score, _} -> score <= 2 end)
      |> Enum.sort_by(fn {screen, dimension, score, _} -> {score, screen, dimension} end)

    backlog_rows =
      Enum.map_join(backlog_entries, "\n", fn {screen, dimension, score, findings_list} ->
        priority = if score == 1, do: "P0", else: "P1"
        action = findings_list |> List.first("Review and fix") |> String.slice(0, 80)
        "| #{priority} | #{screen} | #{dimension} | #{action} |"
      end)

    markdown = """
    # Design-System Gap Register — Baseline #{date_str}

    ## Summary
    - Screens audited: #{screens_audited}
    - P0 issues (score 1): #{p0_count}
    - P1 issues (score 2): #{p1_count}
    - Passing (score ≥ 3): #{passing_count}

    ## Ranked Findings (worst first)

    #{ranked_section}

    ## Fix Backlog (prioritized)
    | Priority | Screen | Dimension | Action |
    |----------|--------|-----------|--------|
    #{backlog_rows}
    """

    out_path = Path.join([File.cwd!(), "priv", "shots", "gap_register.md"])
    File.mkdir_p!(Path.dirname(out_path))
    File.write!(out_path, markdown)
    Mix.shell().info("==> Wrote priv/shots/gap_register.md")
  end
end
