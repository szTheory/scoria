defmodule Mix.Tasks.Scoria.InstallCheckTest do
  use ExUnit.Case, async: false

  alias Scoria.TestSupport.HostInstallFixtures

  @tmp_dir "test/tmp/install_check"

  setup do
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end

  test "mix scoria.install --check returns tri-state exits and stable trailers" do
    assert_check_result(:compliant, 0, "SCORIA_CHECK_RESULT status=compliant exit_code=0")
    assert_check_result(:drift, 1, "SCORIA_CHECK_RESULT status=drift exit_code=1")
    assert_check_result(:manual_review, 1, "SCORIA_CHECK_RESULT status=manual_review exit_code=1")
    assert_check_result(:error, 2, "SCORIA_CHECK_RESULT status=error exit_code=2")
  end

  test "mix scoria.install --check renders remediation payload parity for human and json" do
    fixture = HostInstallFixtures.build!(:manual_review, tmp_parent: @tmp_dir)

    {human_output, human_exit} =
      System.cmd("mix", ["scoria.install", "--check"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: HostInstallFixtures.subprocess_mix_env(fixture.repo_root)
      )

    assert human_exit == 1
    assert human_output =~ "reason_code: missing_ownership_markers"
    assert human_output =~ "verify_command: mix scoria.install --check"
    assert human_output =~ "SCORIA_CHECK_RESULT status=manual_review exit_code=1"

    {json_output, json_exit} =
      System.cmd("mix", ["scoria.install", "--check", "--format", "json"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: HostInstallFixtures.subprocess_mix_env(fixture.repo_root)
      )

    assert json_exit == 1
    assert json_output =~ "\"reason_code\": \"missing_ownership_markers\""
    assert json_output =~ "\"steps\": ["
    assert json_output =~ "\"verify_command\": \"mix scoria.install --check\""
    assert json_output =~ "SCORIA_CHECK_RESULT status=manual_review exit_code=1"

    assert_remediation_contract!(human_output, json_output)
  end

  test "mix scoria.install --check remediation output avoids operator panic artifacts" do
    fixture = HostInstallFixtures.build!(:manual_review, tmp_parent: @tmp_dir)

    {output, exit_code} =
      System.cmd("mix", ["scoria.install", "--check"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: HostInstallFixtures.subprocess_mix_env(fixture.repo_root)
      )

    assert exit_code == 1
    refute output =~ "** ("
    refute output =~ "undefinedFunctionError"
    refute output =~ "(CompileError)"
  end

  test "mix scoria.install --dry-run and --check bodies match for compliant host" do
    fixture = HostInstallFixtures.build!(:compliant, tmp_parent: @tmp_dir)
    env = HostInstallFixtures.subprocess_mix_env(fixture.repo_root)

    {dry_run_output, dry_run_exit} =
      System.cmd("mix", ["scoria.install", "--dry-run"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: env
      )

    {check_output, check_exit} =
      System.cmd("mix", ["scoria.install", "--check"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: env
      )

    assert dry_run_exit == 0
    assert check_exit == 0

    assert normalize_plan_body(dry_run_output) == normalize_plan_body(check_output)
  end

  test "mix scoria.install --check optional_surface_absent reports skipped and creates no tailwind files" do
    fixture = HostInstallFixtures.build!(:optional_surface_absent, tmp_parent: @tmp_dir)

    {output, exit_code} =
      System.cmd("mix", ["scoria.install", "--check"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: HostInstallFixtures.subprocess_mix_env(fixture.repo_root)
      )

    assert exit_code == 0
    assert output =~ "skipped:"
    assert output =~ "SCORIA_CHECK_RESULT status=compliant exit_code=0"
    refute File.exists?(Path.join(fixture.root, "tailwind.config.js"))
    refute File.exists?(Path.join(fixture.root, "assets/tailwind.config.js"))
  end

  test "mix scoria.install --check ignores tampered manifest fingerprints for tri-state" do
    fixture = HostInstallFixtures.build!(:compliant, tmp_parent: @tmp_dir)
    env = HostInstallFixtures.subprocess_mix_env(fixture.repo_root)
    manifest_path = Path.join(fixture.root, ".scoria/install/manifest.json")

    {baseline_output, baseline_exit} =
      System.cmd("mix", ["scoria.install", "--check"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: env
      )

    assert baseline_exit == 0
    assert baseline_output =~ "SCORIA_CHECK_RESULT status=compliant exit_code=0"

    {_apply_output, apply_exit} =
      System.cmd("mix", ["scoria.install"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: env
      )

    assert apply_exit == 0
    assert File.exists?(manifest_path)

    tamper_manifest_fingerprints!(manifest_path, "deadbeef")

    {tampered_output, tampered_exit} =
      System.cmd("mix", ["scoria.install", "--check", "--format", "json"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: env
      )

    assert tampered_exit == baseline_exit
    assert tampered_output =~ "SCORIA_CHECK_RESULT status=compliant exit_code=0"

    payload = decode_check_json!(tampered_output)
    assert payload["manifest"]["present"] == true
    assert payload["manifest"]["check_role"] == "informational"

    Enum.each(payload["entries"], fn entry ->
      assert entry["fingerprint"] != "deadbeef"

      if Map.has_key?(entry, "manifest_fingerprint") do
        assert entry["manifest_fingerprint"] == "deadbeef"
      end
    end)
  end

  test "mix scoria.install --check compliant host without manifest is exit 0" do
    fixture = HostInstallFixtures.build!(:compliant, tmp_parent: @tmp_dir)
    env = HostInstallFixtures.subprocess_mix_env(fixture.repo_root)
    manifest_path = Path.join(fixture.root, ".scoria/install/manifest.json")
    File.rm(manifest_path)

    {output, exit_code} =
      System.cmd("mix", ["scoria.install", "--check"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: env
      )

    assert exit_code == 0
    assert output =~ "Install manifest not found"
    assert output =~ "live host surfaces only"
    assert output =~ "SCORIA_CHECK_RESULT status=compliant exit_code=0"
  end

  test "mix scoria.install --check blocks non_root_browser_only with manual_review and zero writes" do
    fixture = HostInstallFixtures.build!(:non_root_browser_only, tmp_parent: @tmp_dir)
    before = HostInstallFixtures.snapshot_host_files(fixture)

    {output, exit_code} =
      System.cmd("mix", ["scoria.install"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: HostInstallFixtures.subprocess_mix_env(fixture.repo_root)
      )

    after_snapshot = HostInstallFixtures.snapshot_host_files(fixture)

    assert exit_code == 1
    assert output =~ "SCORIA_CHECK_RESULT status=manual_review exit_code=1"
    assert after_snapshot.router == before.router
    assert after_snapshot.runtime_config == before.runtime_config
    assert after_snapshot.migration_files == before.migration_files
  end

  defp assert_check_result(fixture_kind, expected_exit, trailer) do
    fixture = HostInstallFixtures.build!(fixture_kind, tmp_parent: @tmp_dir)

    {output, exit_code} =
      System.cmd("mix", ["scoria.install", "--check"],
        cd: fixture.root,
        stderr_to_stdout: true,
        env: HostInstallFixtures.subprocess_mix_env(fixture.repo_root)
      )

    assert exit_code == expected_exit
    assert output =~ trailer
  end

  defp assert_remediation_contract!(human_output, json_output) do
    assert human_output =~ "summary: Router is unmanaged because ownership markers are missing."
    assert human_output =~ "scoria:router:start"
    refute String.trim(human_output) == ""

    payload = decode_check_json!(json_output)
    router_entry = Enum.find(payload["entries"], &(&1["surface"] == "router"))

    assert router_entry
    remediation = router_entry["remediation"]

    assert remediation["summary"] =~ "ownership markers are missing"
    assert length(remediation["steps"]) >= 1
    assert Enum.all?(remediation["steps"], &String.contains?(human_output, &1))
    assert Enum.any?(remediation["steps"], &String.contains?(&1, "scoria:router:start"))
    assert remediation["verify_command"] == "mix scoria.install --check"
  end

  defp decode_check_json!(output) do
    json_body =
      output
      |> String.split("SCORIA_CHECK_RESULT")
      |> hd()
      |> String.trim()

    Jason.decode!(json_body)
  end

  defp normalize_plan_body(output) do
    output
    |> extract_plan_section()
    |> String.replace(~r/mode: (dry_run|check)/, "mode: preview")
    |> String.replace(
      ~r/Install manifest (not found|present)[^\n]*/,
      "Install manifest context."
    )
    |> String.split("SCORIA_CHECK_RESULT")
    |> hd()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp tamper_manifest_fingerprints!(manifest_path, fingerprint) do
    manifest =
      manifest_path
      |> File.read!()
      |> Jason.decode!()

    tampered_entries =
      manifest["entries"]
      |> Enum.map(fn {id, entry} ->
        {id, Map.put(entry, "fingerprint", fingerprint)}
      end)
      |> Enum.into(%{})

    manifest
    |> Map.put("entries", tampered_entries)
    |> Jason.encode!(pretty: true)
    |> then(&File.write!(manifest_path, &1))
  end

  defp extract_plan_section(output) do
    case String.split(output, "Scoria install plan", parts: 2) do
      [_prefix, rest] -> "Scoria install plan" <> rest
      _ -> output
    end
  end
end
