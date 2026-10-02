defmodule Vetlink.MessagingTest do
  use Vetlink.DataCase
  alias Vetlink.{Accounts, Animals, Bookings, Messaging, Vets}

  defp user(role, n) do
    {:ok, u} = Accounts.register(%{"name" => "User #{n}", "email" => "m#{n}@example.com", "password" => "password-1234", "role" => role})
    u
  end

  setup do
    owner = user("owner", 1)
    vet = user("vet", 2)
    {:ok, _} = vet.id |> Vets.get_profile_by_user() |> Vets.mark_verified()
    {:ok, animal} = Animals.create_animal(owner, %{"name" => "Max", "species" => "dog"})
    when_ = DateTime.utc_now() |> DateTime.add(86_400, :second) |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    {:ok, _} = Bookings.create_booking(owner, %{"vet_id" => vet.id, "animal_id" => animal.id, "service" => "physical", "scheduled_at" => when_})
    [conv] = Messaging.list_conversations(owner)
    %{owner: owner, vet: vet, conv_id: conv.id}
  end

  test "booking creates a conversation both sides can see", %{owner: o, vet: v, conv_id: id} do
    assert [%{id: ^id}] = Messaging.list_conversations(o)
    assert [%{id: ^id}] = Messaging.list_conversations(v)
  end

  test "both participants can send and read messages", %{owner: o, vet: v, conv_id: id} do
    {:ok, c} = Messaging.fetch_member(o, id)
    assert {:ok, _} = Messaging.send_message(o, c, "  Max keeps scratching his ears.  ")
    {:ok, c2} = Messaging.fetch_member(v, id)
    assert {:ok, _} = Messaging.send_message(v, c2, "Bring him in this week.")
    assert [%{body: "Max keeps scratching his ears."}, %{body: "Bring him in this week."}] = Messaging.list_messages(c)
  end

  test "strangers cannot open the conversation", %{conv_id: id} do
    stranger = user("owner", 3)
    assert {:error, :not_found} = Messaging.fetch_member(stranger, id)
  end

  test "empty and oversized messages are rejected", %{owner: o, conv_id: id} do
    {:ok, c} = Messaging.fetch_member(o, id)
    assert {:error, %Ecto.Changeset{}} = Messaging.send_message(o, c, "   ")
    assert {:error, %Ecto.Changeset{}} = Messaging.send_message(o, c, String.duplicate("a", 4001))
  end

  test "emergency wording is flagged" do
    assert Messaging.emergency_hint?("my cow cannot stand and she is bloated")
    assert Messaging.emergency_hint?("he can't breathe")
    refute Messaging.emergency_hint?("just booking a check-up")
  end
end
