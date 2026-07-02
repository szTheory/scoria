defmodule ScoriaWeb.DevLabBoundaryTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Boundary and coverage guard for the dev-only Component Lab (`dev/lab/`).

  This test is PURE `File.read!/1` + `Regex` reading source files as plain
  text. It must NEVER `alias`/`import`/dot-call any module defined under
  `dev/` — `test/`'s `elixirc_paths` (`mix.exs`, `elixirc_paths(:test) =
  ["lib", "test/support"]`) does not include `dev/`, so any such reference
  would be a `mix test` compile failure. Mirrors the proven text-scan
  structure of `test/scoria_web/ds06_drift_guard_test.exs`.

  ## Why the "no `lib/` -> `DevLab.` reference" scan (assertion 4 below) is
  the SOLE enforcement mechanism for the D-21 boundary

  `elixirc_paths(:dev) = ["lib", "dev"]` (see `mix.exs`). That means a
  `lib/some_module.ex -> DevLab.Fixtures` reference COMPILES FINE under a
  maintainer's everyday `mix phx.server` (`:dev` env) — `dev/` is on the
  compile path there, so the call resolves. The same reference only fails
  to compile under `:test` (`dev/` absent from `elixirc_paths(:test)`) or
  for an adopter building this library as a Hex dependency (`dev/` never
  ships). A maintainer who introduces such a reference would see their
  local dev server keep working normally — the drift would be silent until
  CI (or an adopter build) hit it. This test's zero-reference scan is
  therefore the ONE check that fires exactly where the violation is both
  present and observable, and is the sole structural guarantee that fixture
  data never becomes a hidden runtime dependency (D-21).

  ## Guard #7 honesty caveat

  The inventory-ID cross-reference assertion below (guard #7) is a coverage
  FLOOR, not a render guarantee: it proves each canonical `PRIM-*`/`GROUP-*`
  inventory ID from `36-inventory.json` appears as a literal string
  somewhere under `dev/lab/**/*.ex`, not that the corresponding primitive or
  group actually renders correctly for every D-11 state. The complementary
  manual walkthrough lives in `37-VALIDATION.md` and must not be deleted by
  a future phase just because this automated floor passes.
  """

  @canonical_states ~w(normal long_text empty dense disabled selected loading warning danger error)

  @scenario_names ~w(
    approval_requested approval_denied
    incident_opened incident_escalated
    review_candidate_flagged review_queue_empty
    dataset_promoted dataset_empty
    workflow_waiting_for_approval workflow_failed_step
    connector_degraded connector_scope_blocked
    prompt_release_blocked prompt_registry_empty
    eval_regression_detected
  )

  test "public dashboard macro (lib/scoria_web/router.ex) never mounts the lab (T-37-01, D-01/D-03)" do
    source = File.read!("lib/scoria_web/router.ex")

    refute source =~ "/_lab",
           "lib/scoria_web/router.ex must not reference the dev-only component lab route segment"
  end

  test "dashboard nav and command palette never link the lab (D-05)" do
    nav_source = File.read!("lib/scoria_web/dashboard_nav.ex")
    layouts_source = File.read!("lib/scoria_web/components/layouts.ex")

    refute nav_source =~ "/_lab",
           "lib/scoria_web/dashboard_nav.ex must not link the dev-only component lab"

    refute layouts_source =~ "/_lab",
           "lib/scoria_web/components/layouts.ex must not link the dev-only component lab"
  end

  test "package.files (mix.exs) never ships dev/, priv/dev/, or priv/shots/ (T-37-02, D-02)" do
    # Region-scoped on purpose: only the `package/0` `files:` list, NOT the
    # whole mix.exs file. `elixirc_paths(:dev)` on line ~59 legitimately
    # contains the substring "dev" (`defp elixirc_paths(:dev), do: ["lib",
    # "dev"]`) — scanning the whole file for "dev" would false-positive on
    # that line, which is correct/required code, not a packaging leak.
    source = File.read!("mix.exs")

    files_region =
      case Regex.run(~r/defp package do.*?files:\s*\[(.*?)\]/s, source) do
        [_, region] ->
          region

        nil ->
          flunk("mix.exs: could not locate package/0's files: [...] list for a region-scoped scan")
      end

    refute files_region =~ ~r/"dev"/,
           "mix.exs package.files must not include the dev/ directory (D-01/D-02)"

    refute files_region =~ ~r/"priv\/dev"/,
           "mix.exs package.files must not include priv/dev/ (D-01/D-02)"

    refute files_region =~ ~r/"priv\/shots"/,
           "mix.exs package.files must not include priv/shots/ (D-01/D-02)"
  end

  test "no component-catalog dependency is added to mix.exs deps (D-04)" do
    source = File.read!("mix.exs")

    for forbidden <- ~w(phoenix_storybook phx_live_storybook surface_catalogue surface) do
      refute source =~ ~r/:#{forbidden}\b/,
             "mix.exs must not add the #{forbidden} dependency (D-04 — no component-catalog library in Phase 37)"
    end
  end

  test "lib/ never references DevLab.-prefixed dev-only lab modules (T-37-03, D-21 — SOLE enforcement)" do
    violations =
      for path <- Path.wildcard("lib/**/*.{ex,heex}"),
          source = File.read!(path),
          source =~ ~r/DevLab\./ or source =~ ~r/Code\.ensure_loaded\?\(DevLab/ do
        path
      end

    assert violations == [],
           """
           D-21 boundary violated: the following lib/ files reference the dev-only
           DevLab.* lab/fixture namespace. lib/ compiles under every Mix env
           (including as a Hex dependency for adopters), so fixture/lab data must
           never become a runtime dependency:
           #{Enum.join(violations, "\n")}
           """
  end

  test "no dev/lab/fixtures* source references priv/fixtures/ (D-17 boundary)" do
    violations =
      for path <- Path.wildcard("dev/lab/fixtures*"),
          source = File.read!(path),
          source =~ "priv/fixtures/" do
        path
      end

    assert violations == [],
           """
           D-17 boundary violated: bulky JSON fixture payloads must live under
           priv/dev/lab_fixtures/ (dev-only, never shipped to Hex) — never under
           priv/fixtures/, which mix.exs package/0 ships to adopters:
           #{Enum.join(violations, "\n")}
           """
  end

  test "all ten D-11 canonical states are present in dev/lab source (D-32)" do
    source = "dev/lab/**/*.ex" |> Path.wildcard() |> Enum.map_join("\n", &File.read!/1)

    missing = Enum.reject(@canonical_states, &(source =~ &1))

    assert missing == [],
           "dev/lab/**/*.ex is missing these canonical D-11 state names: #{Enum.join(missing, ", ")}"
  end

  test "all fifteen D-20/D-19 fixture scenario names are present in dev/lab source (FIXT-01, D-32)" do
    source = "dev/lab/**/*.ex" |> Path.wildcard() |> Enum.map_join("\n", &File.read!/1)

    missing = Enum.reject(@scenario_names, &(source =~ &1))

    assert missing == [],
           "dev/lab/**/*.ex is missing these D-20/D-19 fixture scenario names: #{Enum.join(missing, ", ")}"
  end

  test "guard #7: every canonical PRIM-*/GROUP-* inventory ID is referenced under dev/lab/** (D-08/D-32)" do
    inventory =
      ".planning/phases/36-baseline-and-inventory/36-inventory.json"
      |> File.read!()
      |> Jason.decode!()

    canonical_ids =
      inventory["rows"]
      |> Enum.filter(fn row ->
        row["status"] == "canonical" and
          (String.starts_with?(row["id"], "PRIM-") or String.starts_with?(row["id"], "GROUP-"))
      end)
      |> Enum.map(& &1["id"])

    lab_source = "dev/lab/**/*.ex" |> Path.wildcard() |> Enum.map_join("\n", &File.read!/1)

    missing = Enum.reject(canonical_ids, &(lab_source =~ &1))

    assert missing == [],
           """
           Guard #7 coverage-floor failure: these canonical PRIM-*/GROUP-* inventory
           IDs from 36-inventory.json do not appear as a literal string anywhere
           under dev/lab/**/*.ex:
           #{Enum.join(missing, ", ")}
             This is a coverage FLOOR only (string presence), not proof every
             primitive/group actually renders every state — see 37-VALIDATION.md
             for the complementary manual walkthrough.
           """
  end
end
