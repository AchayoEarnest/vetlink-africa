defmodule Vetlink.Animals do
  import Ecto.Query
  alias Vetlink.{Repo, Vets}
  alias Vetlink.Accounts.User
  alias Vetlink.Animals.{Animal, HealthRecord}

  def list_animals(%User{id: id}),
    do: Repo.all(from a in Animal, where: a.owner_id == ^id, order_by: a.name)

  def create_animal(%User{id: id}, attrs) do
    %Animal{owner_id: id} |> Animal.changeset(attrs) |> Repo.insert()
  end

  @doc "Owners see their own animals. Vets see animals the owner shared with them. Nobody else sees anything."
  def fetch_accessible(%User{id: uid}, animal_id) do
    animal = Repo.get(Animal, animal_id)

    cond do
      is_nil(animal) -> {:error, :not_found}
      animal.owner_id == uid -> {:ok, animal, :owner}
      shared?(animal.id, uid) -> {:ok, animal, :vet}
      true -> {:error, :not_found}
    end
  end

  def share_with_vet(%Animal{} = animal, vet_id) do
    vet = Repo.get(User, vet_id)

    if vet && vet.role == "vet" do
      Repo.insert_all("animal_shares", [%{animal_id: animal.id, vet_id: vet.id, inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)}], on_conflict: :nothing)
      :ok
    else
      {:error, :not_found}
    end
  end

  defp shared?(animal_id, vet_id),
    do: Repo.exists?(from s in "animal_shares", where: s.animal_id == ^animal_id and s.vet_id == ^vet_id)

  def list_records(%Animal{id: id}),
    do: Repo.all(from r in HealthRecord, where: r.animal_id == ^id, order_by: [desc: r.occurred_on, desc: r.id])

  @doc """
  Owners can add owner-type entries. Professional entries need a *verified* vet
  with access to the animal, and are stamped as verified authors.
  """
  def add_record(%User{} = user, %Animal{} = animal, access, attrs) do
    changeset = HealthRecord.changeset(%HealthRecord{animal_id: animal.id, author_id: user.id}, attrs)
    kind = Ecto.Changeset.get_field(changeset, :kind)

    cond do
      access == :owner and kind in HealthRecord.owner_kinds() ->
        changeset |> stamp("owner", false) |> Repo.insert()

      access == :vet and kind in HealthRecord.professional_kinds() and Vets.verified?(user.id) ->
        changeset |> stamp("vet", true) |> Repo.insert()

      true ->
        {:error, :forbidden}
    end
  end

  defp stamp(cs, role, verified),
    do: Ecto.Changeset.change(cs, author_role: role, verified_author: verified)
end
