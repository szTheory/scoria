defmodule Mix.Tasks.Scoria.HexConsumer.RefreshBaselineFixture do
  @moduledoc false
  use Mix.Task

  alias Scoria.HexConsumerContract

  @shortdoc "Maintainer-only refresh of committed v0.1.0 baseline hex unpack fixture"
  @baseline_tag "v0.1.0"
  @fixture_rel "test/fixtures/hex_consumer/scoria-0.1.0-unpack"
  @stamp_rel "test/fixtures/hex_consumer/.scoria-hex-baseline.stamp"
  @build_suffix "-build"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("loadpaths")

    repo_root = File.cwd!()
    fixture_dir = Path.expand(@fixture_rel, repo_root)
    build_dir = fixture_dir <> @build_suffix
    worktree_dir = Path.join(System.tmp_dir!(), "scoria-hex-baseline-refresh")

    Mix.shell().info("==> Refreshing baseline fixture from #{@baseline_tag}")

    File.rm_rf!(worktree_dir)
    File.rm_rf!(build_dir)
    File.rm_rf!(fixture_dir)

    {output, status} =
      System.cmd("git", ["worktree", "add", "--detach", worktree_dir, @baseline_tag],
        cd: repo_root,
        stderr_to_stdout: true
      )

    if status != 0 do
      Mix.raise("git worktree add failed:\n#{output}")
    end

    try do
      {build_output, build_status} =
        System.cmd(
          "mix",
          ["hex.build", "--unpack", "--output", build_dir],
          cd: worktree_dir,
          stderr_to_stdout: true
        )

      if build_status != 0 do
        Mix.raise("hex.build --unpack failed:\n#{build_output}")
      end

      unpack_root = HexConsumerContract.unpack_root!(build_dir)
      File.mkdir_p!(Path.dirname(fixture_dir))
      File.cp_r!(unpack_root, fixture_dir)

      fingerprint = HexConsumerContract.baseline_package_fingerprint()
      git_sha = HexConsumerContract.baseline_git_sha()
      stamp_path = Path.expand(@stamp_rel, repo_root)
      File.write!(stamp_path, "#{fingerprint}\n#{git_sha}\n")

      Mix.shell().info("==> Baseline fixture refreshed at #{fixture_dir}")
      Mix.shell().info("    fingerprint=#{fingerprint}")
      Mix.shell().info("    git_sha=#{git_sha}")
    after
      System.cmd("git", ["worktree", "remove", "--force", worktree_dir],
        cd: repo_root,
        stderr_to_stdout: true
      )

      File.rm_rf!(build_dir)
    end
  end
end
