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

  Like `mix scoria.ui.shots`, this task does **not** boot a web server — the
  Node/Playwright process drives an already-running dev server. It starts only
  Repo/PubSub locally to top up destructive e2e fixtures before Playwright runs,
  unless `--no-seed-approvals` is passed.

  ## Usage

      mix scoria.ui.e2e [--base-url http://localhost:4799/scoria] [--no-seed-approvals]

  ## Prerequisites

    * `Node.js >= 18` on `PATH`.
    * The e2e deps + Chromium installed:

          npm --prefix priv/dev ci
          npx --prefix priv/dev playwright install --with-deps chromium

    * The dev database created and migrated, and the dev server running:

          make dev

  Then, in a second shell:

      mix scoria.ui.e2e --base-url http://localhost:4799/scoria

  ## Notes

    * Spec files are dev-only and excluded from the Hex package (`priv/dev` is not
      in `mix.exs` `files:`).
    * The toast specs make destructive approval decisions. This task tops up
      pending approval fixtures for tenant `acme-corp` before Playwright runs so
      local and CI reruns are repeatable.
  """

  use Mix.Task

  import Ecto.Query, only: [from: 2]

  # Bumped from 5 (Phase 12) to 10 in Phase 40: drawer_focus.spec.mjs's D-13
  # live-patch collector adds one more destructive decision to the shared
  # tenant-scoped pool, and the full e2e lane runs multiple spec files
  # concurrently (Playwright's default worker parallelism) — uat.spec.mjs
  # (3 decisions), ia_orientation.spec.mjs (1 decision), and drawer_focus's
  # D-13 collector (up to 1 decision) all race over the same floor. A floor
  # of 5 left no safety margin, occasionally starving a concurrently-running
  # spec of a pending row mid-interaction.
  @pending_approval_floor 10
  @switches [base_url: :string, url: :string, seed_approvals: :boolean]

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

    base_url = opts[:base_url] || opts[:url] || "http://localhost:4799/scoria"
    priv_dev = Path.join([File.cwd!(), "priv", "dev"])

    if Keyword.get(opts, :seed_approvals, true) do
      ensure_pending_approval_fixtures!()
    end

    # Resolve a few seeded demo ids (dev_seed.exs) so specs that must land on a
    # specific object page stay deterministic without hardcoding UUIDs. Best-effort:
    # if the DB is unavailable the spec skips those checks rather than failing.
    demo_env = resolve_demo_env()

    Mix.shell().info("[scoria.ui.e2e] Running Playwright e2e against #{base_url} ...")

    # Discrete args list — never a shell command string (T-11-04 injection mitigation).
    # Run from priv/dev so @playwright/test resolves from priv/dev/node_modules; the
    # config's testDir is relative to the config file (priv/dev/e2e).
    cmd_args = ["playwright", "test", "--config", "e2e/playwright.config.mjs"]

    case System.cmd("npx", cmd_args,
           cd: priv_dev,
           env: [{"PLAYWRIGHT_BASE_URL", base_url} | demo_env],
           stderr_to_stdout: true,
           into: IO.stream()
         ) do
      {_, 0} ->
        Mix.shell().info(
          "[scoria.ui.e2e] Done. Report: priv/dev/e2e/playwright-report/index.html"
        )

        :ok

      {_, code} ->
        Mix.raise("playwright e2e exited with code #{code}")
    end
  end

  # Best-effort resolution of seeded demo ids exported to Playwright as env vars.
  # Specs read these (e.g. SCORIA_E2E_REPLAY_RUN_ID) to deep-link a specific object
  # page and skip gracefully when absent. Never fails the run — returns [] on error.
  defp resolve_demo_env do
    start_fixture_services!()
    tenant_id = Scoria.SupportJourney.tenant_id()

    replay_run_id =
      Scoria.Repo.one(
        from(r in Scoria.Workflows.Run,
          where: r.tenant_id == ^tenant_id and r.execution_mode == "replay",
          order_by: [desc: r.inserted_at],
          limit: 1,
          select: r.id
        )
      )

    case replay_run_id do
      nil ->
        []

      id ->
        Mix.shell().info("[scoria.ui.e2e] Seeded replay run id: #{id}")
        [{"SCORIA_E2E_REPLAY_RUN_ID", to_string(id)}]
    end
  rescue
    _ -> []
  end

  defp ensure_pending_approval_fixtures! do
    start_fixture_services!()

    tenant_id = Scoria.SupportJourney.tenant_id()

    existing =
      %{tenant_id: tenant_id}
      |> Scoria.Workflows.list_pending_remote_approvals()
      |> length()

    missing = max(@pending_approval_floor - existing, 0)

    if missing > 0 do
      for _ <- 1..missing do
        create_pending_approval_fixture!()
      end
    end

    available = existing + missing

    Mix.shell().info(
      "[scoria.ui.e2e] Pending approval fixtures ready: #{available} for tenant #{tenant_id}"
    )
  rescue
    error ->
      Mix.raise("""
      Could not prepare e2e approval fixtures: #{Exception.message(error)}

      Ensure the dev database is created and migrated, then re-run:

          make dev
          mix scoria.ui.e2e
      """)
  end

  defp start_fixture_services! do
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:phoenix_pubsub)

    start_repo!()
    start_pubsub!()
  end

  defp start_repo! do
    case Process.whereis(Scoria.Repo) do
      nil ->
        case Scoria.Repo.start_link() do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> raise "could not start Scoria.Repo: #{inspect(reason)}"
        end

      _pid ->
        :ok
    end
  end

  defp start_pubsub! do
    case Process.whereis(Scoria.PubSub) do
      nil ->
        case Phoenix.PubSub.Supervisor.start_link(name: Scoria.PubSub) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> raise "could not start Scoria.PubSub: #{inspect(reason)}"
        end

      _pid ->
        :ok
    end
  end

  defp create_pending_approval_fixture! do
    support = Scoria.SupportJourney
    workflows = Scoria.Workflows

    {:ok, approval_run} =
      workflows.create_run(%{
        root_role_id: "support_agent",
        tenant_id: support.tenant_id(),
        session_id: support.session_id()
      })

    {:ok, approval_step} =
      workflows.create_step(approval_run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "support_agent",
        status: "running"
      })

    {:ok, _approval} =
      workflows.mark_waiting_for_approval(approval_run.id, approval_step.id, %{
        tool_name: support.refund_approval_tool(),
        arguments: %{"ticket_id" => support.ticket_fixture()["id"]},
        reason: "Refund requires operator approval"
      })
  end
end
