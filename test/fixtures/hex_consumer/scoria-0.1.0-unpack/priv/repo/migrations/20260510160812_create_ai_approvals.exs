defmodule Scoria.Repo.Migrations.CreateAiApprovals do
  use Ecto.Migration

  def change do
    create table(:ai_approvals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tool_name, :string, null: false
      add :arguments, :map, default: %{}
      add :status, :string, default: "pending"
      add :session_id, :string
      add :run_id, :string

      timestamps(type: :utc_datetime_usec)
    end
  end
end
