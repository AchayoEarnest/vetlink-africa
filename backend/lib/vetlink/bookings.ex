defmodule Vetlink.Bookings do
  import Ecto.Query
  alias Vetlink.{Repo, Animals, Vets}
  alias Vetlink.Accounts.User
  alias Vetlink.Animals.Animal
  alias Vetlink.Bookings.Booking

  # action => {allowed from, who may do it, resulting status}
  # who: :vet, :owner, :either
  @transitions %{
    "confirm" => {~w(requested rescheduled), :vet, "confirmed"},
    "reschedule" => {~w(requested confirmed), :either, "rescheduled"},
    "start" => {~w(confirmed rescheduled), :vet, "in_progress"},
    "complete" => {~w(in_progress), :vet, "completed"},
    "cancel" => {~w(requested confirmed rescheduled), :either, "cancelled"}
  }

  @doc """
  An owner books a verified vet for one of their own animals.
  Booking also shares that animal with the vet so they can see its history.
  """
  def create_booking(%User{} = owner, attrs) do
    Repo.transaction(fn ->
      with {:ok, vet_id} <- to_int(attrs["vet_id"]),
           {:ok, animal_id} <- to_int(attrs["animal_id"]),
           {:ok, %Animal{} = animal, :owner} <- Animals.fetch_accessible(owner, animal_id),
           true <- Vets.verified?(vet_id) or {:error, :not_found},
           {:ok, booking} <-
             %Booking{owner_id: owner.id, vet_id: vet_id, animal_id: animal.id}
             |> Booking.create_changeset(attrs)
             |> Repo.insert(),
           :ok <- Animals.share_with_vet(animal, vet_id),
           :ok <- Vetlink.Messaging.ensure_conversation(owner.id, vet_id) do
        booking
      else
        {:ok, _animal, :vet} -> Repo.rollback(:forbidden)
        {:error, reason} -> Repo.rollback(reason)
        :error -> Repo.rollback(:bad_request)
      end
    end)
  end

  def list_for(%User{id: id, role: role}) do
    field = if role == "vet", do: :vet_id, else: :owner_id

    from(b in Booking,
      join: a in assoc(b, :animal),
      join: o in assoc(b, :owner),
      join: v in assoc(b, :vet),
      where: field(b, ^field) == ^id,
      order_by: [asc: b.scheduled_at],
      select: %{booking: b, animal_name: a.name, species: a.species, owner_name: o.name, vet_name: v.name}
    )
    |> Repo.all()
  end

  @doc "Apply a status transition. Strangers get :not_found; wrong role gets :forbidden; bad state gets :conflict."
  def transition(%User{} = user, booking_id, action, attrs \\ %{}) do
    with {:ok, id} <- to_int(booking_id),
         %Booking{} = booking <- Repo.get(Booking, id) || {:error, :not_found},
         {:ok, side} <- side(user, booking),
         {:ok, {from, who, to}} <- Map.fetch(@transitions, action) |> or_bad(),
         :ok <- check_who(who, side),
         :ok <- check_state(booking.status, from) do
      do_transition(booking, action, to, attrs)
    end
  end

  defp do_transition(booking, "reschedule", to, attrs) do
    booking |> Booking.reschedule_changeset(attrs) |> Ecto.Changeset.change(status: to) |> Repo.update()
  end

  defp do_transition(booking, _action, to, _attrs),
    do: booking |> Ecto.Changeset.change(status: to) |> Repo.update()

  defp side(%User{id: id}, %Booking{vet_id: id}), do: {:ok, :vet}
  defp side(%User{id: id}, %Booking{owner_id: id}), do: {:ok, :owner}
  defp side(_, _), do: {:error, :not_found}

  defp check_who(:either, _), do: :ok
  defp check_who(who, who), do: :ok
  defp check_who(_, _), do: {:error, :forbidden}

  defp check_state(status, allowed), do: if(status in allowed, do: :ok, else: {:error, :conflict})

  defp or_bad({:ok, v}), do: {:ok, v}
  defp or_bad(:error), do: {:error, :bad_request}

  defp to_int(v) when is_integer(v), do: {:ok, v}
  defp to_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, ""} -> {:ok, n}
      _ -> {:error, :bad_request}
    end
  end
  defp to_int(_), do: {:error, :bad_request}
end
