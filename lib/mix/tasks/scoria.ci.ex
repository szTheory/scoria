defmodule Mix.Tasks.Scoria.Ci do
  @moduledoc """
  Reproduces the merge gate locally and exits non-zero on any failure.

  `mix ci` runs every merge-gating lane and aggregates all results before
  exiting — it never silently skips a gate.

  ## Exit codes

  | Result                            | Exit code |
  |-----------------------------------|-----------|
  | All preamble + lane steps passed  | 0         |
  | Any step failed                   | 1         |
  | pgvector preflight failed         | 1         |
  | Unknown flag supplied             | non-zero  |

  ## Local-vs-CI asymmetry (D-C2/D-C3)

  `mix ci` runs a preamble that CI's `policy` job does NOT:

  * `mix deps.unlock --check-unused` — orphan lock entries
  * `mix deps.get --check-locked` — lock out of sync with mix.exs
  * `mix format --check-formatted` — format drift (scoped via .formatter.exs; does not touch vendored deps)
  * `mix compile --warnings-as-errors` — compile gate

  This is a deliberate strict superset: more safety locally, never less.
  CI symmetry (adding format/deps-lock to the `policy` job) is a deferred
  follow-up — editing contract-guarded workflow at milestone closeout is
  scope creep. The asymmetry is documented here as the canonical reference.

  ## Lane set

  The gating lane set is derived from `Scoria.VerificationLanes` (the SSOT):

      closeout_order() ++ [:semantic_fast_path, :knowledge, :connector]

  `:support_copilot_gallery` is excluded — its `exclusions` list contains
  `"merge-blocking closeout"`, meaning it is an advisory lane that does not
  gate merge.

  ## Opt-out: --skip-optional

  `mix ci --skip-optional` (or env `SCORIA_CI_SKIP_OPTIONAL=1`) skips the
  preflight and the optional/Docker-dependent lanes (`:knowledge`,
  `:semantic_fast_path`, `:connector`), prints which lanes were skipped, and
  stamps:

      RESULT: PARTIAL (knowledge, semantic_fast_path, connector skipped — NOT a merge-gate pass)

  then exits non-zero unconditionally. It can never be mistaken for a clean
  gate or wired into a pre-push hook as authoritative.
  """

  use Mix.Task

  alias Scoria.VerificationLanes

  @shortdoc "Reproduces the merge gate locally; exits non-zero on any failure"

  @switches [skip_optional: :boolean]

  @optional_lane_ids [:knowledge, :semantic_fast_path, :connector]

  @preamble_steps [
    {"mix deps.unlock --check-unused", "deps.unlock --check-unused"},
    {"mix deps.get --check-locked", "deps.get --check-locked"},
    {"mix format --check-formatted", "format --check-formatted"},
    {"mix compile --warnings-as-errors", "compile --warnings-as-errors"}
  ]

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("mix ci: unknown option(s): #{inspect(invalid)}")
    end

    if argv != [] do
      Mix.raise("mix ci: unexpected arguments: #{inspect(argv)}")
    end

    skip_optional =
      opts[:skip_optional] || System.get_env("SCORIA_CI_SKIP_OPTIONAL") == "1"

    if skip_optional do
      run_skip_optional()
    else
      run_full()
    end
  end

  # ---------------------------------------------------------------------------
  # Full merge-gate run (default)
  # ---------------------------------------------------------------------------

  defp run_full do
    Mix.shell().info("==> mix ci: running merge gate preamble")

    preamble_results = run_preamble()

    Mix.shell().info("==> mix ci: running preflight pgvector probe")

    case run_preflight() do
      :ok ->
        Mix.shell().info("==> mix ci: preflight passed — running gating lanes")
        lane_results = run_lanes(gating_lane_ids())
        print_summary(preamble_results ++ lane_results)
        aggregate_and_halt(preamble_results ++ lane_results)

      {:error, :preflight_failed} ->
        # Preflight printed its own actionable block; now hard-fail
        System.halt(1)
    end
  end

  # ---------------------------------------------------------------------------
  # Skip-optional path (D-B3)
  # ---------------------------------------------------------------------------

  defp run_skip_optional do
    skipped = @optional_lane_ids |> Enum.map(&Atom.to_string/1) |> Enum.join(", ")

    Mix.shell().info("""
    ==> mix ci --skip-optional: skipping #{skipped}
    """)

    remaining_ids = gating_lane_ids() -- @optional_lane_ids

    Mix.shell().info("==> mix ci: running merge gate preamble")
    preamble_results = run_preamble()

    Mix.shell().info("==> mix ci: running non-optional gating lanes")
    lane_results = run_lanes(remaining_ids)

    print_summary(preamble_results ++ lane_results)

    Mix.shell().info(
      "RESULT: PARTIAL (knowledge, semantic_fast_path, connector skipped — NOT a merge-gate pass)"
    )

    System.halt(1)
  end

  # ---------------------------------------------------------------------------
  # Preamble
  # ---------------------------------------------------------------------------

  defp run_preamble do
    Enum.map(@preamble_steps, fn {cmd, label} ->
      Mix.shell().info("==> [preamble] #{label}")
      {_io, status} = System.cmd("sh", ["-c", cmd], into: IO.stream(), stderr_to_stdout: true)
      {label, status}
    end)
  end

  # ---------------------------------------------------------------------------
  # pgvector preflight (D-B1/D-B2)
  # ---------------------------------------------------------------------------

  defp run_preflight do
    {_io, status} =
      System.cmd("sh", ["-c", "mix scoria.pgvector.bootstrap --check"],
        into: IO.stream(),
        stderr_to_stdout: true
      )

    if status == 0 do
      :ok
    else
      Mix.shell().error("""
      mix ci: merge-gate lanes require a pgvector-capable Postgres, but none is reachable
        at localhost:55432 (vector extension not found / connection refused).
      These lanes gate merge and cannot be skipped silently — a green here must match CI.
      Next step:
        mix scoria.pgvector.bootstrap   # starts pgvector Postgres on :55432
        mix ci                          # re-run the full merge gate
      No Docker / docs-only change? Run a PARTIAL check (exits non-zero, NOT a gate pass):
        mix ci --skip-optional
      """)

      {:error, :preflight_failed}
    end
  end

  # ---------------------------------------------------------------------------
  # Lane execution
  # ---------------------------------------------------------------------------

  defp gating_lane_ids do
    full_set = VerificationLanes.closeout_order() ++ [:semantic_fast_path, :knowledge, :connector]
    Enum.reject(full_set, &("merge-blocking closeout" in VerificationLanes.exclusions(&1)))
  end

  defp run_lanes(lane_ids) do
    Enum.map(lane_ids, fn id ->
      cmd = VerificationLanes.command(id)
      Mix.shell().info("==> [lane: #{id}] #{cmd}")
      {_io, status} = System.cmd("sh", ["-c", cmd], into: IO.stream(), stderr_to_stdout: true)
      {Atom.to_string(id), status}
    end)
  end

  # ---------------------------------------------------------------------------
  # Aggregation and reporting
  # ---------------------------------------------------------------------------

  defp print_summary(results) do
    Mix.shell().info("\n==> mix ci: results\n")

    Enum.each(results, fn {label, status} ->
      verdict = if status == 0, do: "PASS", else: "FAIL (exit #{status})"
      Mix.shell().info("  #{verdict}  #{label}")
    end)

    Mix.shell().info("")
  end

  defp aggregate_and_halt(results) do
    if Enum.any?(results, fn {_label, status} -> status != 0 end) do
      Mix.shell().error("==> mix ci: FAILED — one or more steps did not pass")
      System.halt(1)
    else
      Mix.shell().info("==> mix ci: all steps passed — merge gate GREEN")
    end
  end
end
