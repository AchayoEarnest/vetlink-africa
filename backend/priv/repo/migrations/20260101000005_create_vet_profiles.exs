defmodule Vetlink.Repo.Migrations.CreateVetProfiles do
  use Ecto.Migration

  def up do
    create table(:vet_profiles) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :clinic_name, :string
      add :specialty, :string
      add :species, {:array, :string}, null: false, default: []
      add :services, {:array, :string}, null: false, default: []
      add :home_visits, :boolean, null: false, default: false
      add :emergency, :boolean, null: false, default: false
      add :registration_number, :string
      add :verification_status, :string, null: false, default: "pending"
      add :verified_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    execute "SELECT AddGeometryColumn('vet_profiles', 'location', 4326, 'POINT', 2)"
    create unique_index(:vet_profiles, [:user_id])
    create constraint(:vet_profiles, :valid_status, check: "verification_status in ('pending','verified','rejected','suspended')")
    execute "CREATE INDEX vet_profiles_location_gix ON vet_profiles USING GIST ((location::geography))"
  end

  def down do
    drop table(:vet_profiles)
  end
end
