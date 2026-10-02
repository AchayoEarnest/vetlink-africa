defmodule VetlinkWeb.ConversationChannel do
  use Phoenix.Channel
  alias Vetlink.Messaging

  @impl true
  def join("conversation:" <> id, _params, socket) do
    case Messaging.fetch_member(socket.assigns.current_user, id) do
      {:ok, conversation} -> {:ok, assign(socket, :conversation, conversation)}
      {:error, _} -> {:error, %{reason: "not_found"}}
    end
  end

  @impl true
  def handle_in("new_message", %{"body" => body}, socket) do
    case VetlinkWeb.Chat.deliver(socket.assigns.current_user, socket.assigns.conversation, body) do
      {:ok, _msg} -> {:reply, :ok, socket}
      {:error, _} -> {:reply, {:error, %{reason: "invalid"}}, socket}
    end
  end

  def handle_in(_event, _payload, socket), do: {:reply, {:error, %{reason: "unknown"}}, socket}
end
