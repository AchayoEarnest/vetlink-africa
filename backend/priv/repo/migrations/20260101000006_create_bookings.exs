defmodule Vetlink.Repo.Migrations.CreateBookings do
  use Ecto.Migration

  def change do
    create table(:bookings) do
      add :owner_id, references(:users, on_delete: :delete_all), null: false
      add :vet_id, references(:users, on_delete: :delete_all), null: false
      add :animal_id, references(:animals, on_delete: :delete_all), null: false
      add :service, :string, null: false
      add :urgency, :string, null: false, default: "routine"
      add :scheduled_at, :utc_datetime, null: false
      add :status, :string, null: false, default: "requested"
      add :notes, :text
      timestamps(type: :utc_datetime)
    end

    create index(:bookings, [:owner_id, :scheduled_at])
    create index(:bookings, [:vet_id, :scheduled_at])
    create constraint(:bookings, :valid_status,
             check: "status in ('requested','confirmed','rescheduled','in_progress','completed','cancelled')")
  end
end
