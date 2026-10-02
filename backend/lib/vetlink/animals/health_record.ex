defmodule Vetlink.Animals.HealthRecord do
  use Ecto.Schema
  import Ecto.Changeset

  @owner_kinds ~w(note vaccination weight feed medication document breeding mortality)
  @professional_kinds ~w(consultation diagnosis treatment lab_test surgery follow_up vaccination medication breeding)

  def owner_kinds, do: @owner_kinds
  def professional_kinds, do: @professional_kinds

  schema "health_records" do
    belongs_to :animal, Vetlink.Animals.Animal
    belongs_to :author, Vetlink.Accounts.User
    field :author_role, :string
    field :verified_author, :boolean, default: false
    field :kind, :string
    field :title, :string
    field :notes, :string
    field :occurred_on, :date
    field :follow_up_on, :date
    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:kind, :title, :notes, :occurred_on, :follow_up_on])
    |> validate_required([:kind, :title, :occurred_on])
    |> validate_length(:title, max: 160)
  end
end
