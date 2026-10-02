defmodule VetlinkWeb.RecordController do
  use VetlinkWeb, :controller
  alias Vetlink.Animals

  def index(conn, %{"animal_id" => id}) do
    with {:ok, animal, _access} <- Animals.fetch_accessible(conn.assigns.current_user, id) do
      json(conn, %{data: Enum.map(Animals.list_records(animal), &record_json/1)})
    end
  end

  def create(conn, %{"animal_id" => id} = params) do
    user = conn.assigns.current_user

    with {:ok, animal, access} <- Animals.fetch_accessible(user, id),
         {:ok, record} <- Animals.add_record(user, animal, access, params) do
      conn |> put_status(:created) |> json(%{data: record_json(record)})
    end
  end

  defp record_json(r) do
    Map.take(r, [:id, :kind, :title, :notes, :occurred_on, :follow_up_on, :author_role, :verified_author, :inserted_at])
  end
end
