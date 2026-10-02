defmodule Vetlink.AnimalsTest do
  use Vetlink.DataCase
  alias Vetlink.{Accounts, Animals, Vets}

  defp user(role, n) do
    {:ok, u} = Accounts.register(%{"name" => "User #{n}", "email" => "u#{n}@example.com", "password" => "password-1234", "role" => role})
    u
  end

  setup do
    owner = user("owner", 1)
    {:ok, animal} = Animals.create_animal(owner, %{"name" => "Max", "species" => "dog"})
    %{owner: owner, animal: animal}
  end

  test "strangers cannot see another owner's animal", %{animal: a} do
    other = user("owner", 2)
    assert {:error, :not_found} = Animals.fetch_accessible(other, a.id)
  end

  test "owners cannot write professional record kinds", %{owner: o, animal: a} do
    attrs = %{"kind" => "diagnosis", "title" => "Self-diagnosis", "occurred_on" => "2026-10-01"}
    assert {:error, :forbidden} = Animals.add_record(o, a, :owner, attrs)
  end

  test "unverified vets cannot add professional records even with access", %{owner: o, animal: a} do
    vet = user("vet", 3)
    :ok = Animals.share_with_vet(a, vet.id)
    {:ok, a2, :vet} = Animals.fetch_accessible(vet, a.id)
    attrs = %{"kind" => "consultation", "title" => "Exam", "occurred_on" => "2026-10-01"}
    assert {:error, :forbidden} = Animals.add_record(vet, a2, :vet, attrs)
    _ = o
  end

  test "verified vets with access add verified records", %{animal: a} do
    vet = user("vet", 4)
    {:ok, _} = vet.id |> Vets.get_profile_by_user() |> Vets.mark_verified()
    :ok = Animals.share_with_vet(a, vet.id)
    {:ok, a2, :vet} = Animals.fetch_accessible(vet, a.id)
    attrs = %{"kind" => "consultation", "title" => "Exam", "occurred_on" => "2026-10-01"}
    assert {:ok, r} = Animals.add_record(vet, a2, :vet, attrs)
    assert r.verified_author and r.author_role == "vet"
  end

  test "nobody can self-register as admin" do
    assert {:error, cs} = Accounts.register(%{"name" => "X", "email" => "x@example.com", "password" => "password-1234", "role" => "admin"})
    assert %{role: _} = Ecto.Changeset.traverse_errors(cs, fn {m, _} -> m end)
  end
end
