defmodule VetlinkWeb.AnimalController do
  use VetlinkWeb, :controller
  alias Vetlink.Animals

  def index(conn, _), do: json(conn, %{data: Enum.map(Animals.list_animals(conn.assigns.current_user), &animal_json/1)})

  def create(conn, params) do
    with {:ok, animal} <- Animals.create_animal(conn.assigns.current_user, params) do
      conn |> put_status(:created) |> json(%{data: animal_json(animal)})
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, animal, access} <- Animals.fetch_accessible(conn.assigns.current_user, id) do
      json(conn, %{data: animal_json(animal), access: access})
    end
  end

  def share(conn, %{"animal_id" => id, "vet_id" => vet_id}) do
    with {:ok, animal, :owner} <- Animals.fetch_accessible(conn.assigns.current_user, id),
         :ok <- Animals.share_with_vet(animal, vet_id) do
      send_resp(conn, :no_content, "")
    else
      {:ok, _animal, :vet} -> {:error, :forbidden}
      other -> other
    end
  end

  def animal_json(a) do
    Map.take(a, [:id, :name, :species, :breed, :sex, :date_of_birth, :weight_kg, :colour, :identification, :microchip, :allergies, :county])
  end
end
