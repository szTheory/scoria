defmodule ScoriaWeb.ReviewerSurfaceTest do
  use Scoria.IntegrationCase

  alias Scoria.Repo
  alias Scoria.SRE.Incident
  alias Scoria.Workflows
  alias ScoriaWeb.OperatorSurface
  alias ScoriaWeb.ReviewerSurface

  @liveview_paths [
    "lib/scoria_web/live/orchestrator_live.ex",
    "lib/scoria_web/live/workflow_live/index.ex",
    "lib/scoria_web/live/workflow_live/show.ex",
    "lib/scoria_web/live/connectors_live/index.ex",
    "lib/scoria_web/live/incidents_live/index.ex",
    "lib/scoria_web/live/incidents_live/show.ex",
    "lib/scoria_web/live/dataset_live/index.ex"
  ]

  test "reviewer surface exposes tenant-scoped workflow reads with legacy parity" do
    unique = unique_suffix()
    tenant_a = "reviewer-surface-a-#{unique}"
    tenant_b = "reviewer-surface-b-#{unique}"

    {:ok, run_a} =
      Workflows.create_run(%{
        root_role_id: "reviewer-surface",
        tenant_id: tenant_a,
        session_id: "tenant-a-session-#{unique}"
      })

    {:ok, run_b} =
      Workflows.create_run(%{
        root_role_id: "reviewer-surface",
        tenant_id: tenant_b,
        session_id: "tenant-b-session-#{unique}"
      })

    reviewer_ids = ReviewerSurface.list_tenant_runs(tenant_a) |> Enum.map(& &1.id)
    legacy_ids = OperatorSurface.list_tenant_runs(tenant_a) |> Enum.map(& &1.id)

    assert run_a.id in reviewer_ids
    refute run_b.id in reviewer_ids
    assert reviewer_ids == legacy_ids

    run_a_id = run_a.id

    assert %{run: %{id: ^run_a_id}} = ReviewerSurface.fetch_tenant_run_detail(tenant_a, run_a.id)
    assert ReviewerSurface.fetch_tenant_run_detail(tenant_a, run_b.id) == nil
    assert ReviewerSurface.fetch_tenant_run_detail(tenant_a, "not-a-uuid") == nil

    assert normalize_run_detail(OperatorSurface.fetch_tenant_run_detail(tenant_a, run_a.id)) ==
             normalize_run_detail(ReviewerSurface.fetch_tenant_run_detail(tenant_a, run_a.id))
  end

  test "reviewer surface exposes tenant-scoped incident reads with legacy parity" do
    unique = unique_suffix()
    tenant_a = "reviewer-incident-a-#{unique}"
    tenant_b = "reviewer-incident-b-#{unique}"
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    incident_a = seed_incident!(tenant_a, unique, now)
    incident_b = seed_incident!(tenant_b, "#{unique}-foreign", now)

    reviewer_incidents = ReviewerSurface.list_tenant_incidents(tenant_a)
    legacy_incidents = OperatorSurface.list_tenant_incidents(tenant_a)

    assert Enum.map(reviewer_incidents, & &1.id) == Enum.map(legacy_incidents, & &1.id)
    assert Enum.any?(reviewer_incidents, &(&1.id == incident_a.id))
    refute Enum.any?(reviewer_incidents, &(&1.id == incident_b.id))

    assert ReviewerSurface.fetch_tenant_incident(tenant_a, incident_a.id).id == incident_a.id
    assert ReviewerSurface.fetch_tenant_incident(tenant_a, incident_b.id) == nil

    assert OperatorSurface.fetch_tenant_incident(tenant_a, incident_a.id).id ==
             ReviewerSurface.fetch_tenant_incident(tenant_a, incident_a.id).id
  end

  test "compact trace badges are callable through both public names" do
    trace_id = "trace-reviewer-#{unique_suffix()}"
    run_id = Ecto.UUID.generate()

    assert OperatorSurface.compact_trace_badges(trace_id, run_id) ==
             ReviewerSurface.compact_trace_badges(trace_id, run_id)
  end

  test "legacy operator surface delegates to reviewer surface without query implementation" do
    source = File.read!("lib/scoria_web/operator_surface.ex")

    assert source =~ "ScoriaWeb.ReviewerSurface"
    refute source =~ "import Ecto.Query"
    refute source =~ "alias Scoria.Repo"

    for function <- [
          "list_tenant_runs",
          "fetch_tenant_run_detail",
          "fetch_tenant_incident",
          "compact_trace_badges"
        ] do
      assert source =~ "defdelegate #{function}"
    end
  end

  test "dashboard LiveViews use reviewer surface as their read model" do
    for path <- @liveview_paths do
      source = File.read!(path)

      assert source =~ "ReviewerSurface", "expected #{path} to reference ReviewerSurface"
      refute source =~ "OperatorSurface", "expected #{path} not to reference OperatorSurface"
    end
  end

  defp seed_incident!(tenant_id, unique, now) do
    %Incident{}
    |> Incident.changeset(%{
      tenant_id: tenant_id,
      incident_key: "reviewer-surface-incident-#{unique}",
      severity: "warning",
      status: "open",
      summary: "Reviewer surface incident #{unique}",
      routing_class: "review",
      dedupe_key: Ecto.UUID.generate(),
      first_seen_at: now,
      last_seen_at: now,
      workflow_run_id: Ecto.UUID.generate(),
      trace_id: "trace-reviewer-incident-#{unique}"
    })
    |> Repo.insert!()
  end

  defp normalize_run_detail(nil), do: nil

  defp normalize_run_detail(%{run: run, detail: detail, linked_incident: linked_incident}) do
    %{
      run_id: run.id,
      detail_run_id: detail.summary.run_id,
      linked_incident_id: linked_incident && linked_incident.id
    }
  end

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string()
  end
end
