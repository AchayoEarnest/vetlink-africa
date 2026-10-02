defmodule Vetlink.Repo.Migrations.CreateMessaging do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :owner_id, references(:users, on_delete: :delete_all), null: false
      add :vet_id, references(:users, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:conversations, [:owner_id, :vet_id])
    create index(:conversations, [:vet_id])

    create table(:messages) do
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :sender_id, references(:users, on_delete: :nilify_all)
      add :body, :text, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:messages, [:conversation_id, :id])
  end
end
