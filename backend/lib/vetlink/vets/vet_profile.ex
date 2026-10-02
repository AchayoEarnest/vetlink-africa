defmodule Vetlink.Vets.VetProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vet_profiles" do
    belongs_to :user, Vetlink.Accounts.User
    field :clinic_name, :string
    field :specialty, :string
    field :species, {:array, :string}, default: []
    field :services, {:array, :string}, default: []
    field :home_visits, :boolean, default: false
    field :emergency, :boolean, default: false
    field :registration_number, :string
    field :verification_status, :string, default: "pending"
    field :verified_at, :utc_datetime
    field :location, Geo.PostGIS.Geometry
    field :lat, :float, virtual: true
    field :lng, :float, virtual: true
    timestamps(type: :utc_datetime)
  end

  def create_changeset(profile, attrs) do
    profile |> cast(attrs, [:user_id]) |> validate_required([:user_id]) |> unique_constraint(:user_id)
  end

  # verification_status is deliberately NOT castable here.
  def update_changeset(profile, attrs) do
    profile
    |> cast(attrs, [:clinic_name, :specialty, :species, :services, :home_visits, :emergency, :registration_number, :lat, :lng])
    |> validate_number(:lat, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:lng, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> put_location()
  end

  def verify_changeset(profile) do
    change(profile, verification_status: "verified", verified_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp put_location(cs) do
    lat = get_change(cs, :lat)
    lng = get_change(cs, :lng)

    if lat && lng,
      do: put_change(cs, :location, %Geo.Point{coordinates: {lng, lat}, srid: 4326}),
      else: cs
  end
end
