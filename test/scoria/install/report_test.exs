defmodule Scoria.Install.ReportTest do
  use ExUnit.Case, async: true

  alias Scoria.Install.Contract
  alias Scoria.Install.Report

  test "optional_surface_absent no_op projects to skipped" do
    entry = %{
      classification: :no_op,
      drift: %{reason_code: "optional_surface_absent"}
    }

    assert Contract.project_entry(:no_op, "optional_surface_absent", :check) == :skipped

    summary = Report.project_operator_summary([entry], :check)
    assert summary.skipped == 1
    assert summary.already_present == 0
  end

  test "create in dry_run projects to would_change" do
    entry = %{classification: :create, drift: %{reason_code: "missing_managed_region"}}

    assert Contract.project_entry(:create, "missing_managed_region", :dry_run) == :would_change

    summary = Report.project_operator_summary([entry], :dry_run)
    assert summary.would_change == 1
  end

  test "manual_review never maps to would_change or already_present" do
    entry = %{classification: :manual_review, drift: %{reason_code: "missing_ownership_markers"}}

    assert Contract.project_entry(:manual_review, "missing_ownership_markers", :check) ==
             :manual_review

    summary = Report.project_operator_summary([entry], :check)
    assert summary.manual_review == 1
    assert summary.would_change == 0
    assert summary.already_present == 0
  end

  test "render_json includes summary_operator and schema_version 1.0" do
    plan = %{
      schema_version: 1,
      mode: :dry_run,
      entries: [
        %{
          order: 1,
          surface: :tailwind,
          target_path: "n/a",
          classification: :no_op,
          rationale: "optional",
          drift: %{reason_code: "optional_surface_absent"}
        }
      ],
      summary: %{create: 0, update: 0, no_op: 1, manual_review: 0}
    }

    json = Report.render_json(plan, :dry_run)
    payload = Jason.decode!(json)

    assert payload["schema_version"] == "1.0"
    assert payload["summary"] == %{"create" => 0, "no_op" => 1, "update" => 0, "manual_review" => 0}

    assert payload["summary_operator"] == %{
             "already_present" => 0,
             "manual_review" => 0,
             "skipped" => 1,
             "would_change" => 0
           }
  end

  test "render_human prints operator summary keys in contract order" do
    plan = %{
      entries: [
        %{
          order: 1,
          surface: :tailwind,
          target_path: "n/a",
          classification: :manual_review,
          rationale: "review",
          drift: %{reason_code: "missing_ownership_markers"},
          remediation: %{}
        },
        %{
          order: 2,
          surface: :router,
          target_path: "lib/app_web/router.ex",
          classification: :no_op,
          rationale: "optional",
          drift: %{reason_code: "optional_surface_absent"},
          remediation: %{}
        },
        %{
          order: 3,
          surface: :router,
          target_path: "lib/app_web/router.ex",
          classification: :no_op,
          rationale: "present",
          drift: %{reason_code: "managed_region_present"},
          remediation: %{}
        },
        %{
          order: 4,
          surface: :router,
          target_path: "lib/app_web/router.ex",
          classification: :create,
          rationale: "missing",
          drift: %{reason_code: "missing_managed_region"},
          remediation: %{}
        }
      ],
      summary: %{create: 1, update: 0, no_op: 2, manual_review: 1}
    }

    human = Report.render_human(plan, :dry_run)

    assert human =~ "Operator summary:"
    assert_index_order(human, "would_change:", "already_present:")
    assert_index_order(human, "already_present:", "skipped:")
    assert_index_order(human, "skipped:", "manual_review:")
  end

  test "render_json includes additive manifest map with role metadata" do
    plan = %{
      schema_version: 1,
      mode: :check,
      manifest_state: :present,
      manifest_path: "/tmp/host/.scoria/install/manifest.json",
      entries: [],
      summary: %{create: 0, update: 0, no_op: 0, manual_review: 0}
    }

    payload = Jason.decode!(Report.render_json(plan, :check))

    assert payload["manifest"] == %{
             "apply_role" => "freshness_baseline",
             "check_role" => "informational",
             "path" => "/tmp/host/.scoria/install/manifest.json",
             "present" => true,
             "schema_version" => 1
           }
  end

  test "render_json includes manifest_fingerprint on entry when present" do
    plan = %{
      schema_version: 1,
      mode: :check,
      manifest_state: :absent,
      manifest_path: ".scoria/install/manifest.json",
      entries: [
        %{
          order: 1,
          surface: :router,
          target_path: "lib/app_web/router.ex",
          classification: :no_op,
          rationale: "ok",
          fingerprint: "live-hash",
          manifest_fingerprint: "stored-hash",
          drift: %{reason_code: "managed_region_present"},
          remediation: %{}
        }
      ],
      summary: %{create: 0, update: 0, no_op: 1, manual_review: 0}
    }

    [entry] = Jason.decode!(Report.render_json(plan, :check))["entries"]

    assert entry["fingerprint"] == "live-hash"
    assert entry["manifest_fingerprint"] == "stored-hash"
  end

  test "render_human prints manifest context lines for absent and present states" do
    absent_plan = %{
      manifest_state: :absent,
      manifest_path: ".scoria/install/manifest.json",
      entries: [],
      summary: %{create: 0, update: 0, no_op: 0, manual_review: 0}
    }

    assert Report.render_human(absent_plan, :check) =~ "Install manifest not found"

    present_plan = %{
      manifest_state: :present,
      manifest_path: "/app/.scoria/install/manifest.json",
      entries: [],
      summary: %{create: 0, update: 0, no_op: 0, manual_review: 0}
    }

    human = Report.render_human(present_plan, :check)

    assert human =~ "Install manifest present at /app/.scoria/install/manifest.json"
    assert human =~ "informational snapshot only"
  end

  defp assert_index_order(text, left, right) do
    assert String.split(text, left) |> length() > 1, "expected #{left} in output"
    assert String.split(text, right) |> length() > 1, "expected #{right} in output"
    assert :binary.match(text, left) < :binary.match(text, right)
  end
end
