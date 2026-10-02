defmodule VetlinkWeb.DocumentController do
  use VetlinkWeb, :controller
  alias Vetlink.{Animals, Documents}

  def index(conn, %{"animal_id" => id}) do
    with {:ok, animal, _access} <- Animals.fetch_accessible(conn.assigns.current_user, id) do
      json(conn, %{data: animal |> Documents.list_documents() |> Enum.map(&doc_json/1)})
    end
  end

  def create(conn, %{"animal_id" => id, "file" => %Plug.Upload{} = upload} = params) do
    user = conn.assigns.current_user

    with {:ok, animal, access} <- Animals.fetch_accessible(user, id),
         {:ok, doc} <- Documents.create_document(user, animal, access, upload, params) do
      conn |> put_status(:created) |> json(%{data: doc_json(doc)})
    end
  end

  def create(_conn, _), do: {:error, :bad_request}

  # Files are only served through this authorised endpoint, never from a public URL.
  def download(conn, %{"id" => id}) do
    with {:ok, doc, _access} <- Documents.fetch_document(conn.assigns.current_user, id),
         {:ok, bin} <- Documents.read(doc) do
      conn
      |> put_resp_content_type(doc.content_type, nil)
      |> put_resp_header("content-disposition", ~s(attachment; filename="#{doc.original_name}"))
      |> put_resp_header("x-content-type-options", "nosniff")
      |> put_resp_header("cache-control", "private, no-store")
      |> send_resp(200, bin)
    else
      {:error, :enoent} -> {:error, :not_found}
      other -> other
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, doc, access} <- Documents.fetch_document(user, id),
         {:ok, _} <- Documents.delete_document(user, doc, access) do
      send_resp(conn, :no_content, "")
    end
  end

  defp doc_json(d), do: Map.take(d, [:id, :animal_id, :kind, :original_name, :content_type, :byte_size, :uploader_role, :inserted_at])
end
