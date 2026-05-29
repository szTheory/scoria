defmodule Scoria.Repo.Migrations.AddCanonicalIdentityToApprovals do
  use Ecto.Migration

  def change do
    alter table(:ai_approvals) do
      add_if_not_exists :actor_id, :string
      add_if_not_exists :tenant_id, :string
    end

    create_if_not_exists index(:ai_approvals, [:actor_id])
    create_if_not_exists index(:ai_approvals, [:tenant_id])
    create_if_not_exists index(:ai_approvals, [:tenant_id, :actor_id])
    create_if_not_exists index(:ai_approvals, [:session_id])
  end
end
