defmodule VetlinkWeb.UserSocket do
  use Phoenix.Socket

  channel "conversation:*", VetlinkWeb.ConversationChannel

  @impl true
  def connect(%{"token" => token}, socket, _info) do
    with {:ok, user_id} <- VetlinkWeb.Token.verify(token),
         %{} = user <- Vetlink.Accounts.get_user(user_id) do
      {:ok, assign(socket, :current_user, user)}
    else
      _ -> :error
    end
  end

  def connect(_params, _socket, _info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
