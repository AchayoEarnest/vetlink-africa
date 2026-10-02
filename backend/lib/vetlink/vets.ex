defmodule Vetlink.Vets do
  import Ecto.Query
  alias Vetlink.Repo
  alias Vetlink.Vets.VetProfile

  def get_profile_by_user(user_id), do: Repo.get_by(VetProfile, user_id: user_id)

  def update_profile(%VetProfile{} = profile, attrs),
    do: profile |> VetProfile.update_changeset(attrs) |> Repo.update()

  def verified?(user_id) do
    Repo.exists?(from v in VetProfile, where: v.user_id == ^user_id and v.verification_status == "verified")
  end

  @doc "Admin-only. Call from a console, seed or future admin endpoint."
  def mark_verified(%VetProfile{} = profile), do: profile |> VetProfile.verify_changeset() |> Repo.update()

  @doc """
  Verified vets within `radius_km` of a point, nearest first.
  Options: :species, :emergency (boolean), :home_visits (boolean).
  """
  def nearby(lat, lng, radius_km, opts \\ []) do
    meters = radius_km * 1000.0

    base =
      from v in VetProfile,
        join: u in assoc(v, :user),
        where: v.verification_status == "verified" and not is_nil(v.location),
        where:
          fragment(
            "ST_DWithin(?::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)",
            v.location, ^lng, ^lat, ^meters
          ),
        select: %{
          profile: v,
          name: u.name,
          distance_km:
            fragment(
              "ST_Distance(?::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography) / 1000.0",
              v.location, ^lng, ^lat
            )
        },
        order_by:
          fragment(
            "ST_Distance(?::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)",
            v.location, ^lng, ^lat
          ),
        limit: 50

    base
    |> filter_species(opts[:species])
    |> filter_flag(:emergency, opts[:emergency])
    |> filter_flag(:home_visits, opts[:home_visits])
    |> Repo.all()
  end

  defp filter_species(q, nil), do: q
  defp filter_species(q, sp), do: from(v in q, where: ^sp in v.species)
  defp filter_flag(q, _f, nil), do: q
  defp filter_flag(q, :emergency, true), do: from(v in q, where: v.emergency == true)
  defp filter_flag(q, :home_visits, true), do: from(v in q, where: v.home_visits == true)
  defp filter_flag(q, _f, _), do: q
end
