defmodule Vetlink.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  # "admin" can never be chosen at registration.
  @public_roles ~w(owner vet clinic organization)

  schema "users" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :role, :string, default: "owner"
    field :county, :string
    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :phone, :password, :role, :county])
    |> validate_required([:name, :email, :password])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
    |> validate_length(:password, min: 10, max: 128)
    |> validate_format(:phone, ~r/^(\+?254|0)[17]\d{8}$/, message: "must be a Kenyan phone number")
    |> validate_inclusion(:role, @public_roles)
    |> update_change(:email, &String.downcase/1)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(%{valid?: true, changes: %{password: pw}} = cs),
    do: put_change(cs, :password_hash, Argon2.hash_pwd_salt(pw))

  defp put_password_hash(cs), do: cs
end
