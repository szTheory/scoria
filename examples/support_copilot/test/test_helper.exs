ExUnit.start()

{:ok, _} = Application.ensure_all_started(:scoria)

Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, :manual)
