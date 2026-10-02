defmodule VetlinkWeb.Chat do
  alias Vetlink.Messaging

  def json(m) do
    %{id: m.id, conversation_id: m.conversation_id, sender_id: m.sender_id, body: m.body,
      inserted_at: m.inserted_at, urgent_hint: Messaging.emergency_hint?(m.body)}
  end

  @doc "Save a message and push it to everyone connected to the conversation."
  def deliver(user, conversation, body) do
    with {:ok, msg} <- Messaging.send_message(user, conversation, body) do
      VetlinkWeb.Endpoint.broadcast!("conversation:#{conversation.id}", "new_message", json(msg))
      {:ok, msg}
    end
  end
end
