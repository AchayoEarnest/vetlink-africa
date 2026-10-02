defmodule VetlinkWeb.AuthController do
  use VetlinkWeb, :controller
  alias Vetlink.Accounts

  def register(conn, params) do
    with {:ok, user} <- Accounts.register(params) do
      conn |> put_status(:created) |> json(%{token: VetlinkWeb.Token.sign(user), user: user_json(user)})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    with {:ok, user} <- Accounts.authenticate(email, password) do
      json(conn, %{token: VetlinkWeb.Token.sign(user), user: user_json(user)})
    end
  end

  def login(_conn, _), do: {:error, :bad_request}

  def me(conn, _), do: json(conn, %{user: user_json(conn.assigns.current_user)})

  def user_json(u), do: %{id: u.id, name: u.name, email: u.email, role: u.role, county: u.county}
end
