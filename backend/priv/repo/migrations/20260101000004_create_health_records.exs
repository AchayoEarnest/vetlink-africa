defmodule Vetlink.Repo.Migrations.CreateHealthRecords do
  use Ecto.Migration

  def change do
    create table(:health_records) do
      add :animal_id, references(:animals, on_delete: :delete_all), null: false
      add :author_id, references(:users, on_delete: :nilify_all)
      add :author_role, :string, null: false
      add :verified_author, :boolean, null: false, default: false
      add :kind, :string, null: false
      add :title, :string, null: false
      add :notes, :text
      add :occurred_on, :date, null: false
      add :follow_up_on, :date
      timestamps(type: :utc_datetime)
    end

    create index(:health_records, [:animal_id, :occurred_on])
  end
end
