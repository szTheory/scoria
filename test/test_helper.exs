{:ok, _} = Application.ensure_all_started(:scoria)
Code.require_file("support/knowledge_case.exs", __DIR__)

Application.put_env(:phoenix_live_view, :html_parser, Floki)

ExUnit.start(
  exclude:
    if(System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true", do: [], else: [knowledge: true])
)

Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, :manual)
