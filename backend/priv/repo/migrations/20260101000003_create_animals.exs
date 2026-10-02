defmodule Vetlink.Repo.Migrations.CreateAnimals do
  use Ecto.Migration

  def change do
    create table(:animals) do
      add :owner_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :species, :string, null: false
      add :breed, :string
      add :sex, :string
      add :date_of_birth, :date
      add :weight_kg, :decimal
      add :colour, :string
      add :identification, :string
      add :microchip, :string
      add :allergies, :text
      add :county, :string
      timestamps(type: :utc_datetime)
    end

    create index(:animals, [:owner_id])

    create table(:animal_shares) do
      add :animal_id, references(:animals, on_delete: :delete_all), null: false
      add :vet_id, references(:users, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:animal_shares, [:animal_id, :vet_id])
    create index(:animal_shares, [:vet_id])
  end
end
