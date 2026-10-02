defmodule Vetlink.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :animal_id, references(:animals, on_delete: :delete_all), null: false
      add :uploader_id, references(:users, on_delete: :nilify_all)
      add :uploader_role, :string, null: false
      add :kind, :string, null: false
      add :original_name, :string, null: false
      add :content_type, :string, null: false
      add :byte_size, :integer, null: false
      add :storage_key, :string, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:documents, [:animal_id])
    create unique_index(:documents, [:storage_key])
  end
end
