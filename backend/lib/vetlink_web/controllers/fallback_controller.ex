defmodule VetlinkWeb.FallbackController do
  use Phoenix.Controller, formats: [:json]

  def call(conn, {:error, %Ecto.Changeset{} = cs}) do
    errors = Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, k -> opts |> Keyword.get(String.to_existing_atom(k), k) |> to_string() end)
    end)

    conn |> put_status(:unprocessable_entity) |> json(%{errors: errors})
  end

  def call(conn, {:error, :not_found}), do: conn |> put_status(:not_found) |> json(%{error: "Not found"})
  def call(conn, {:error, :unauthorized}), do: conn |> put_status(:unauthorized) |> json(%{error: "Email or password is incorrect"})
  def call(conn, {:error, :forbidden}), do: conn |> put_status(:forbidden) |> json(%{error: "You are not allowed to do that"})
  def call(conn, {:error, :conflict}), do: conn |> put_status(:conflict) |> json(%{error: "That is not possible for this appointment right now"})
  def call(conn, {:error, :too_large}), do: conn |> put_status(:request_entity_too_large) |> json(%{error: "That file is too large. The limit is 10 MB."})
  def call(conn, {:error, :unsupported_type}), do: conn |> put_status(:unsupported_media_type) |> json(%{error: "Only PDF, JPEG, PNG or WebP files are allowed."})
  def call(conn, {:error, :bad_request}), do: conn |> put_status(:bad_request) |> json(%{error: "Check the request and try again"})
  def call(conn, {:error, _other}), do: conn |> put_status(:internal_server_error) |> json(%{error: "Something went wrong. Try again."})
end
