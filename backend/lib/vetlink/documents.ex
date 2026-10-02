defmodule Vetlink.Documents do
  import Ecto.Query
  alias Vetlink.{Repo, Storage, Vets, Animals}
  alias Vetlink.Accounts.User
  alias Vetlink.Animals.Animal
  alias Vetlink.Documents.Document

  def max_bytes, do: Application.get_env(:vetlink, :max_upload_bytes, 10_000_000)

  def list_documents(%Animal{id: id}),
    do: Repo.all(from d in Document, where: d.animal_id == ^id, order_by: [desc: d.id])

  @doc """
  Owners may upload any kind of document. Vets need to be verified and have access to the animal.
  The file type is decided from the file's own bytes, never from its name or the browser's claim.
  """
  def create_document(%User{} = user, %Animal{} = animal, access, %Plug.Upload{} = upload, attrs) do
    with :ok <- may_upload(user, access),
         {:ok, %{size: size}} <- File.stat(upload.path),
         :ok <- check_size(size),
         {:ok, bin} <- File.read(upload.path),
         {:ok, type} <- sniff(bin) do
      key = "#{animal.id}/#{Ecto.UUID.generate()}"

      changeset =
        %Document{
          animal_id: animal.id, uploader_id: user.id, uploader_role: if(access == :owner, do: "owner", else: "vet"),
          original_name: safe_name(upload.filename), content_type: type, byte_size: size, storage_key: key
        }
        |> Document.changeset(attrs)

      if changeset.valid? do
        with :ok <- Storage.put(key, bin) do
          case Repo.insert(changeset) do
            {:ok, doc} -> {:ok, doc}
            {:error, cs} -> Storage.delete(key); {:error, cs}
          end
        end
      else
        {:error, %{changeset | action: :insert}}
      end
    end
  end

  def fetch_document(%User{} = user, id) do
    with {:ok, int} <- to_int(id),
         %Document{} = doc <- Repo.get(Document, int),
         {:ok, _animal, access} <- Animals.fetch_accessible(user, doc.animal_id) do
      {:ok, doc, access}
    else
      _ -> {:error, :not_found}
    end
  end

  def read(%Document{storage_key: key}), do: Storage.get(key)

  def delete_document(%User{id: uid}, %Document{} = doc, access) do
    if access == :owner or doc.uploader_id == uid do
      Storage.delete(doc.storage_key)
      Repo.delete(doc)
    else
      {:error, :forbidden}
    end
  end

  defp may_upload(_user, :owner), do: :ok
  defp may_upload(user, :vet), do: if(Vets.verified?(user.id), do: :ok, else: {:error, :forbidden})

  defp check_size(size), do: if(size > 0 and size <= max_bytes(), do: :ok, else: {:error, :too_large})

  # Magic-byte sniffing. Anything else (executables, HTML, scripts) is refused.
  defp sniff(<<"%PDF-", _::binary>>), do: {:ok, "application/pdf"}
  defp sniff(<<0xFF, 0xD8, 0xFF, _::binary>>), do: {:ok, "image/jpeg"}
  defp sniff(<<0x89, "PNG", 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: {:ok, "image/png"}
  defp sniff(<<"RIFF", _::binary-size(4), "WEBP", _::binary>>), do: {:ok, "image/webp"}
  defp sniff(_), do: {:error, :unsupported_type}

  defp safe_name(nil), do: "document"
  defp safe_name(name) do
    name |> Path.basename() |> String.replace(~r/[^\w.\- ]/u, "_") |> String.slice(0, 120) |> then(&if(&1 == "", do: "document", else: &1))
  end

  defp to_int(v) when is_integer(v), do: {:ok, v}
  defp to_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, ""} -> {:ok, n}
      _ -> :error
    end
  end
  defp to_int(_), do: :error
end
