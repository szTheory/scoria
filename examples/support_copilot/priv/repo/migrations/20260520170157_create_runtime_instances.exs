defmodule Scoria.Repo.Migrations.CreateRuntimeInstances do
  use Ecto.Migration

  def change do
    create table(:runtime_instances, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, :string, null: false
      add :host_session_id, :string
      add :current_run_id, :string
      add :first_seen_at, :utc_datetime, null: false
      add :last_seen_at, :utc_datetime, null: false
      add :terminal_offline_reason, :string
      add :transport_kind, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:runtime_instances, [:tenant_id])
    create index(:runtime_instances, [:host_session_id])
  end
end
