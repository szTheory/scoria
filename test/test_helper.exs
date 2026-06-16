if System.get_env("SCORIA_LANE_CONTRACT_ONLY") == "true" do
  :ok
else
  {:ok, _} = Application.ensure_all_started(:scoria)
  Code.require_file("support/knowledge_case.exs", __DIR__)
  Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, :manual)
end

Application.put_env(:phoenix_live_view, :html_parser, Floki)

excluded_tags =
  []
  |> then(fn tags ->
    if System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true", do: tags, else: [{:knowledge, true} | tags]
  end)
  |> then(fn tags ->
    if System.get_env("SCORIA_TEST_INCLUDE_REGISTRY") == "true",
      do: tags,
      else: [{:registry_proof, true}, {:registry_upgrade, true} | tags]
  end)

ExUnit.start(exclude: excluded_tags)

# Layer 2 zero-test guard: fires only when SCORIA_TEST_INCLUDE_KNOWLEDGE=true
# (i.e., only during mix test.knowledge runs). Default mix test never trips this.
# Must be placed AFTER ExUnit.start/1 — after_suite reads from app env initialized by start.
if System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true" do
  ExUnit.after_suite(fn %{total: total} ->
    if total == 0 do
      IO.puts(:stderr, "[knowledge lane] after_suite: 0 tests executed — possible tag loss")
      exit({:shutdown, 1})
    end
  end)
end

# Partition zero-test guard: fires only during sharded CI runs (MIX_TEST_PARTITION set).
# ExUnit exits 0 on a 0-test partition ({:noop,_} path) — this guard closes that hole.
# Never fires in local or lane runs (MIX_TEST_PARTITION is absent outside full-suite: job).
if System.get_env("MIX_TEST_PARTITION") do
  ExUnit.after_suite(fn %{total: total} ->
    if total == 0 do
      IO.puts(:stderr, "[full-suite partition #{System.get_env("MIX_TEST_PARTITION")}] after_suite: 0 tests executed — possible partition misconfiguration")
      exit({:shutdown, 1})
    end
  end)
end
