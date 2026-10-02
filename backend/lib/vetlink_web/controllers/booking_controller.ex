defmodule VetlinkWeb.BookingController do
  use VetlinkWeb, :controller
  alias Vetlink.Bookings

  def index(conn, _) do
    data = conn.assigns.current_user |> Bookings.list_for() |> Enum.map(&row_json/1)
    json(conn, %{data: data})
  end

  def create(conn, params) do
    with {:ok, booking} <- Bookings.create_booking(conn.assigns.current_user, params) do
      conn |> put_status(:created) |> json(%{data: booking_json(booking)})
    end
  end

  def update(conn, %{"id" => id, "action" => action} = params) do
    with {:ok, booking} <- Bookings.transition(conn.assigns.current_user, id, action, params) do
      json(conn, %{data: booking_json(booking)})
    end
  end

  def update(_conn, _), do: {:error, :bad_request}

  defp row_json(%{booking: b} = r) do
    Map.merge(booking_json(b), Map.take(r, [:animal_name, :species, :owner_name, :vet_name]))
  end

  defp booking_json(b) do
    Map.take(b, [:id, :animal_id, :vet_id, :owner_id, :service, :urgency, :scheduled_at, :status, :notes])
  end
end
