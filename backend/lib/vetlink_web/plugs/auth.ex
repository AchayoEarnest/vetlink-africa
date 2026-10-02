defmodule VetlinkWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user_id} <- VetlinkWeb.Token.verify(token),
         %{} = user <- Vetlink.Accounts.get_user(user_id) do
      assign(conn, :current_user, user)
    else
      _ ->
        conn |> put_status(:unauthorized) |> json(%{error: "Sign in to continue"}) |> halt()
    end
  end
end
