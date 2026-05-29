defmodule Scoria.Repo.Migrations.CreateAiObservabilityTables do
  use Ecto.Migration

  def change do
    create table(:ai_traces, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, :string
      add :attributes, :map, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_traces, [:session_id])
    create index(:ai_traces, [:attributes], using: "GIN")

    create table(:ai_spans, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :trace_id, references(:ai_traces, type: :binary_id, on_delete: :delete_all), null: false
      add :parent_id, :binary_id
      add :name, :string, null: false
      add :span_kind, :string
      add :status_code, :string
      add :start_time, :utc_datetime_usec, null: false
      add :end_time, :utc_datetime_usec
      add :attributes, :map, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_spans, [:trace_id])
    create index(:ai_spans, [:parent_id])
    create index(:ai_spans, [:name])
    create index(:ai_spans, [:span_kind])
    create index(:ai_spans, [:status_code])
    create index(:ai_spans, [:start_time])
    create index(:ai_spans, [:end_time])
    create index(:ai_spans, [:attributes], using: "GIN")

    create table(:ai_span_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :span_id, references(:ai_spans, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :time, :utc_datetime_usec, null: false
      add :attributes, :map, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_span_events, [:span_id])
    create index(:ai_span_events, [:name])
    create index(:ai_span_events, [:time])
    create index(:ai_span_events, [:attributes], using: "GIN")
  end
end
