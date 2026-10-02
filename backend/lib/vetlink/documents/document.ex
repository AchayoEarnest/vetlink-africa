defmodule Vetlink.Documents.Document do
  use Ecto.Schema
  import Ecto.Changeset

  @kinds ~w(vaccination_card lab_report prescription xray image certificate other)
  def kinds, do: @kinds

  schema "documents" do
    belongs_to :animal, Vetlink.Animals.Animal
    belongs_to :uploader, Vetlink.Accounts.User
    field :uploader_role, :string
    field :kind, :string
    field :original_name, :string
    field :content_type, :string
    field :byte_size, :integer
    field :storage_key, :string
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(doc, attrs) do
    doc |> cast(attrs, [:kind]) |> validate_required([:kind]) |> validate_inclusion(:kind, @kinds)
  end
end
