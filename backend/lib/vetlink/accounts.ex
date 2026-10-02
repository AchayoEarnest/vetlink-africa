defmodule Vetlink.Accounts do
  import Ecto.Query
  alias Vetlink.Repo
  alias Vetlink.Accounts.User
  alias Vetlink.Vets.VetProfile

  def get_user(id), do: Repo.get(User, id)

  def register(attrs) do
    Repo.transaction(fn ->
      with {:ok, user} <- %User{} |> User.registration_changeset(attrs) |> Repo.insert(),
           :ok <- maybe_create_vet_profile(user) do
        user
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  # Vets always start as "pending". Only an admin process may mark them verified.
  defp maybe_create_vet_profile(%User{role: "vet", id: id}) do
    case Repo.insert(VetProfile.create_changeset(%VetProfile{}, %{user_id: id})) do
      {:ok, _} -> :ok
      {:error, cs} -> {:error, cs}
    end
  end

  defp maybe_create_vet_profile(_), do: :ok

  def authenticate(email, password) when is_binary(email) and is_binary(password) do
    user = Repo.one(from u in User, where: u.email == ^String.downcase(email))

    cond do
      user && Argon2.verify_pass(password, user.password_hash) -> {:ok, user}
      user -> {:error, :unauthorized}
      true ->
        Argon2.no_user_verify()
        {:error, :unauthorized}
    end
  end

  def authenticate(_, _), do: {:error, :unauthorized}
end
