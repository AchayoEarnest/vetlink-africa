defmodule Vetlink.BookingsTest do
  use Vetlink.DataCase
  alias Vetlink.{Accounts, Animals, Bookings, Vets}

  defp user(role, n) do
    {:ok, u} = Accounts.register(%{"name" => "User #{n}", "email" => "b#{n}@example.com", "password" => "password-1234", "role" => role})
    u
  end

  defp verified_vet(n) do
    vet = user("vet", n)
    {:ok, _} = vet.id |> Vets.get_profile_by_user() |> Vets.mark_verified()
    vet
  end

  defp future, do: DateTime.utc_now() |> DateTime.add(86_400, :second) |> DateTime.truncate(:second) |> DateTime.to_iso8601()

  setup do
    owner = user("owner", 1)
    {:ok, animal} = Animals.create_animal(owner, %{"name" => "Bella", "species" => "cattle"})
    vet = verified_vet(2)
    %{owner: owner, animal: animal, vet: vet}
  end

  defp attrs(vet, animal), do: %{"vet_id" => vet.id, "animal_id" => animal.id, "service" => "farm_visit", "scheduled_at" => future()}

  test "booking a verified vet shares the animal with them", %{owner: o, animal: a, vet: v} do
    assert {:ok, b} = Bookings.create_booking(o, attrs(v, a))
    assert b.status == "requested"
    assert {:ok, _, :vet} = Animals.fetch_accessible(v, a.id)
  end

  test "cannot book an unverified vet", %{owner: o, animal: a} do
    pending = user("vet", 3)
    assert {:error, :not_found} = Bookings.create_booking(o, attrs(pending, a))
  end

  test "cannot book for someone else's animal", %{animal: a, vet: v} do
    stranger = user("owner", 4)
    assert {:error, :not_found} = Bookings.create_booking(stranger, attrs(v, a))
  end

  test "past dates are rejected", %{owner: o, animal: a, vet: v} do
    past = DateTime.utc_now() |> DateTime.add(-86_400, :second) |> DateTime.to_iso8601()
    assert {:error, %Ecto.Changeset{}} = Bookings.create_booking(o, Map.put(attrs(v, a), "scheduled_at", past))
  end

  test "only the vet can confirm; the owner can cancel", %{owner: o, animal: a, vet: v} do
    {:ok, b} = Bookings.create_booking(o, attrs(v, a))
    assert {:error, :forbidden} = Bookings.transition(o, b.id, "confirm")
    assert {:ok, %{status: "confirmed"}} = Bookings.transition(v, b.id, "confirm")
    assert {:ok, %{status: "cancelled"}} = Bookings.transition(o, b.id, "cancel")
  end

  test "completed appointments cannot be cancelled", %{owner: o, animal: a, vet: v} do
    {:ok, b} = Bookings.create_booking(o, attrs(v, a))
    {:ok, _} = Bookings.transition(v, b.id, "confirm")
    {:ok, _} = Bookings.transition(v, b.id, "start")
    {:ok, _} = Bookings.transition(v, b.id, "complete")
    assert {:error, :conflict} = Bookings.transition(o, b.id, "cancel")
  end

  test "strangers cannot see or change a booking", %{owner: o, animal: a, vet: v} do
    {:ok, b} = Bookings.create_booking(o, attrs(v, a))
    stranger = user("owner", 5)
    assert {:error, :not_found} = Bookings.transition(stranger, b.id, "cancel")
  end
end
