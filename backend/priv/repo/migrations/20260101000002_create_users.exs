defmodule Vetlink.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :citext, null: false
      add :phone, :string
      add :password_hash, :string, null: false
      add :role, :string, null: false, default: "owner"
      add :county, :string
      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create constraint(:users, :valid_role, check: "role in ('owner','vet','clinic','organization','admin')")
  end
end
