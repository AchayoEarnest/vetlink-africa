defmodule Vetlink.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    belongs_to :conversation, Vetlink.Messaging.Conversation
    belongs_to :sender, Vetlink.Accounts.User
    field :body, :string
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body])
    |> update_change(:body, &String.trim/1)
    |> validate_required([:body])
    |> validate_length(:body, min: 1, max: 4000)
  end
end
