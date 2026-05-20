{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Application.ensure_all_started(:scoria)
Code.require_file("support/knowledge_case.exs", __DIR__)
try do
  Scoria.TestSupport.Migrations.migrate_core!()
rescue
  e ->
    IO.puts("Warning: Core migrations failed, continuing anyway: #{inspect(e)}")
end
Application.put_env(:phoenix_live_view, :html_parser, Floki)

ExUnit.start(
  exclude:
    if(System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true", do: [], else: [knowledge: true])
)

Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, :manual)
