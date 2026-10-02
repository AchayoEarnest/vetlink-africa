defmodule Vetlink.Messaging.Conversation do
  use Ecto.Schema

  schema "conversations" do
    belongs_to :owner, Vetlink.Accounts.User
    belongs_to :vet, Vetlink.Accounts.User
    has_many :messages, Vetlink.Messaging.Message
    timestamps(type: :utc_datetime)
  end
end
