defmodule VetlinkWeb.ConversationController do
  use VetlinkWeb, :controller
  alias Vetlink.Messaging

  def index(conn, _) do
    json(conn, %{data: Messaging.list_conversations(conn.assigns.current_user)})
  end

  def messages(conn, %{"id" => id}) do
    with {:ok, conversation} <- Messaging.fetch_member(conn.assigns.current_user, id) do
      json(conn, %{data: conversation |> Messaging.list_messages() |> Enum.map(&VetlinkWeb.Chat.json/1)})
    end
  end

  def send_message(conn, %{"id" => id, "body" => body}) do
    user = conn.assigns.current_user

    with {:ok, conversation} <- Messaging.fetch_member(user, id),
         {:ok, msg} <- VetlinkWeb.Chat.deliver(user, conversation, body) do
      conn |> put_status(:created) |> json(%{data: VetlinkWeb.Chat.json(msg)})
    end
  end

  def send_message(_conn, _), do: {:error, :bad_request}
end
