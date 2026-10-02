defmodule Vetlink.VetsTest do
  use Vetlink.DataCase
  alias Vetlink.{Accounts, Vets}

  defp vet(n, lat, lng, opts \\ []) do
    {:ok, u} = Accounts.register(%{"name" => "Vet #{n}", "email" => "v#{n}@example.com", "password" => "password-1234", "role" => "vet"})
    profile = Vets.get_profile_by_user(u.id)

    {:ok, profile} =
      Vets.update_profile(profile, %{"lat" => lat, "lng" => lng, "species" => ["cattle"], "emergency" => Keyword.get(opts, :emergency, false)})

    if Keyword.get(opts, :verified, true), do: {:ok, _} = Vets.mark_verified(profile)
    u
  end

  # Kakamega town centre
  @lat 0.2827
  @lng 34.7519

  test "returns verified vets inside the radius, nearest first" do
    far = vet(1, 0.40, 34.90)
    near = vet(2, 0.29, 34.76)
    _nairobi = vet(3, -1.286, 36.82)

    ids = Vets.nearby(@lat, @lng, 50) |> Enum.map(& &1.profile.user_id)
    assert ids == [near.id, far.id]
  end

  test "never returns unverified vets" do
    _pending = vet(4, 0.29, 34.76, verified: false)
    assert Vets.nearby(@lat, @lng, 50) == []
  end

  test "filters by emergency service" do
    _a = vet(5, 0.29, 34.76)
    b = vet(6, 0.30, 34.77, emergency: true)
    assert [%{profile: %{user_id: id}}] = Vets.nearby(@lat, @lng, 50, emergency: true)
    assert id == b.id
  end

  test "filters by species" do
    _a = vet(7, 0.29, 34.76)
    assert [_] = Vets.nearby(@lat, @lng, 50, species: "cattle")
    assert [] = Vets.nearby(@lat, @lng, 50, species: "dog")
  end
end
