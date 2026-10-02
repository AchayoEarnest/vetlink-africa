defmodule VetlinkWeb.VetController do
  use VetlinkWeb, :controller
  alias Vetlink.Vets

  def nearby(conn, %{"lat" => lat, "lng" => lng} = params) do
    with {lat, ""} <- Float.parse(lat),
         {lng, ""} <- Float.parse(lng),
         true <- lat >= -90 and lat <= 90 and lng >= -180 and lng <= 180 do
      radius = params |> Map.get("radius_km", "20") |> Float.parse() |> then(fn {r, _} -> min(max(r, 1.0), 200.0); _ -> 20.0 end)

      opts = [species: params["species"], emergency: params["emergency"] == "true", home_visits: params["home_visits"] == "true"]

      data =
        Vets.nearby(lat, lng, radius, opts)
        |> Enum.map(fn %{profile: p, name: name, distance_km: d} ->
          {plng, plat} = p.location.coordinates

          %{id: p.user_id, name: name, clinic: p.clinic_name, specialty: p.specialty, species: p.species,
            services: p.services, home_visits: p.home_visits, emergency: p.emergency,
            verified: true, distance_km: Float.round(d, 1),
            # Rounded to about 100 m so a mobile vet's exact base is not published.
            lat: Float.round(plat, 3), lng: Float.round(plng, 3)}
        end)

      json(conn, %{data: data})
    else
      _ -> {:error, :bad_request}
    end
  end

  def nearby(_conn, _), do: {:error, :bad_request}

  def show_me(conn, _) do
    with {:ok, profile} <- my_profile(conn.assigns.current_user) do
      json(conn, %{data: profile_json(profile)})
    end
  end

  def update_me(conn, params) do
    with {:ok, profile} <- my_profile(conn.assigns.current_user),
         {:ok, profile} <- Vets.update_profile(profile, params) do
      json(conn, %{data: profile_json(profile)})
    end
  end

  defp my_profile(%{role: "vet", id: id}) do
    case Vets.get_profile_by_user(id) do
      nil -> {:error, :not_found}
      profile -> {:ok, profile}
    end
  end

  defp my_profile(_), do: {:error, :forbidden}

  defp profile_json(p) do
    {lat, lng} =
      case p.location do
        %Geo.Point{coordinates: {lng, lat}} -> {lat, lng}
        _ -> {nil, nil}
      end

    %{clinic_name: p.clinic_name, specialty: p.specialty, species: p.species, services: p.services,
      home_visits: p.home_visits, emergency: p.emergency, registration_number: p.registration_number,
      verification_status: p.verification_status, lat: lat, lng: lng}
  end
end
