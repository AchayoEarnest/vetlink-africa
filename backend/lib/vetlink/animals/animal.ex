defmodule Vetlink.Animals.Animal do
  use Ecto.Schema
  import Ecto.Changeset

  @species ~w(dog cat cattle goat sheep poultry horse rabbit pig fish other)

  schema "animals" do
    belongs_to :owner, Vetlink.Accounts.User
    field :name, :string
    field :species, :string
    field :breed, :string
    field :sex, :string
    field :date_of_birth, :date
    field :weight_kg, :decimal
    field :colour, :string
    field :identification, :string
    field :microchip, :string
    field :allergies, :string
    field :county, :string
    timestamps(type: :utc_datetime)
  end

  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name, :species, :breed, :sex, :date_of_birth, :weight_kg, :colour, :identification, :microchip, :allergies, :county])
    |> validate_required([:name, :species])
    |> validate_inclusion(:species, @species)
    |> validate_inclusion(:sex, ~w(male female unknown), allow_nil: true)
    |> validate_number(:weight_kg, greater_than: 0)
  end
end
