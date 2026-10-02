defmodule Vetlink.Bookings.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  @services ~w(physical home_visit farm_visit online follow_up emergency)
  @urgencies ~w(routine soon urgent)

  schema "bookings" do
    belongs_to :owner, Vetlink.Accounts.User
    belongs_to :vet, Vetlink.Accounts.User
    belongs_to :animal, Vetlink.Animals.Animal
    field :service, :string
    field :urgency, :string, default: "routine"
    field :scheduled_at, :utc_datetime
    field :status, :string, default: "requested"
    field :notes, :string
    timestamps(type: :utc_datetime)
  end

  def create_changeset(booking, attrs) do
    booking
    |> cast(attrs, [:service, :urgency, :scheduled_at, :notes])
    |> validate_required([:service, :scheduled_at])
    |> validate_inclusion(:service, @services)
    |> validate_inclusion(:urgency, @urgencies)
    |> validate_length(:notes, max: 2000)
    |> validate_future()
  end

  def reschedule_changeset(booking, attrs) do
    booking |> cast(attrs, [:scheduled_at]) |> validate_required([:scheduled_at]) |> validate_future()
  end

  # Emergencies may be booked for "now"; everything else must be in the future.
  defp validate_future(cs) do
    at = get_field(cs, :scheduled_at)
    emergency? = get_field(cs, :service) == "emergency" or get_field(cs, :urgency) == "urgent"
    cutoff = DateTime.add(DateTime.utc_now(), if(emergency?, do: -3600, else: 0), :second)

    if at && DateTime.compare(at, cutoff) == :lt,
      do: add_error(cs, :scheduled_at, "must be in the future"),
      else: cs
  end
end
