defmodule Vetlink.DocumentsTest do
  use Vetlink.DataCase
  alias Vetlink.{Accounts, Animals, Documents, Vets}

  @pdf "%PDF-1.4 test file"
  @png <<0x89, "PNG", 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3>>

  defp user(role, n) do
    {:ok, u} = Accounts.register(%{"name" => "User #{n}", "email" => "d#{n}@example.com", "password" => "password-1234", "role" => role})
    u
  end

  defp upload(bytes, name \\ "card.pdf") do
    path = Path.join(System.tmp_dir!(), "vl_#{System.unique_integer([:positive])}")
    File.write!(path, bytes)
    on_exit(fn -> File.rm(path) end)
    %Plug.Upload{path: path, filename: name, content_type: "application/octet-stream"}
  end

  setup do
    owner = user("owner", 1)
    {:ok, animal} = Animals.create_animal(owner, %{"name" => "Max", "species" => "dog"})
    %{owner: owner, animal: animal}
  end

  test "owner can upload a PDF and read it back", %{owner: o, animal: a} do
    assert {:ok, doc} = Documents.create_document(o, a, :owner, upload(@pdf), %{"kind" => "vaccination_card"})
    assert doc.content_type == "application/pdf"
    assert {:ok, @pdf} = Documents.read(doc)
  end

  test "file type is decided by content, not by name", %{owner: o, animal: a} do
    assert {:ok, %{content_type: "image/png"}} = Documents.create_document(o, a, :owner, upload(@png, "scan.pdf"), %{"kind" => "image"})
    assert {:error, :unsupported_type} = Documents.create_document(o, a, :owner, upload("MZ not a pdf", "report.pdf"), %{"kind" => "lab_report"})
    assert {:error, :unsupported_type} = Documents.create_document(o, a, :owner, upload("<script>alert(1)</script>", "x.png"), %{"kind" => "image"})
  end

  test "oversized and empty files are rejected", %{owner: o, animal: a} do
    big = "%PDF-" <> String.duplicate("a", 2_000)
    assert {:error, :too_large} = Documents.create_document(o, a, :owner, upload(big), %{"kind" => "other"})
    assert {:error, :too_large} = Documents.create_document(o, a, :owner, upload(""), %{"kind" => "other"})
  end

  test "unknown kinds are rejected", %{owner: o, animal: a} do
    assert {:error, %Ecto.Changeset{}} = Documents.create_document(o, a, :owner, upload(@pdf), %{"kind" => "malware"})
  end

  test "file names are sanitised", %{owner: o, animal: a} do
    {:ok, doc} = Documents.create_document(o, a, :owner, upload(@pdf, "../../etc/pa<ss>wd.pdf"), %{"kind" => "other"})
    refute doc.original_name =~ "/"
    refute doc.original_name =~ "<"
  end

  test "strangers cannot fetch a document", %{owner: o, animal: a} do
    {:ok, doc} = Documents.create_document(o, a, :owner, upload(@pdf), %{"kind" => "other"})
    assert {:error, :not_found} = Documents.fetch_document(user("owner", 2), doc.id)
  end

  test "unverified vets cannot upload; verified vets with access can", %{owner: o, animal: a} do
    vet = user("vet", 3)
    :ok = Animals.share_with_vet(a, vet.id)
    {:ok, a2, :vet} = Animals.fetch_accessible(vet, a.id)
    assert {:error, :forbidden} = Documents.create_document(vet, a2, :vet, upload(@pdf), %{"kind" => "lab_report"})

    {:ok, _} = vet.id |> Vets.get_profile_by_user() |> Vets.mark_verified()
    assert {:ok, %{uploader_role: "vet"}} = Documents.create_document(vet, a2, :vet, upload(@pdf), %{"kind" => "lab_report"})
    _ = o
  end

  test "owner can delete a vet's document; a vet cannot delete the owner's", %{owner: o, animal: a} do
    vet = user("vet", 4)
    {:ok, _} = vet.id |> Vets.get_profile_by_user() |> Vets.mark_verified()
    :ok = Animals.share_with_vet(a, vet.id)

    {:ok, owner_doc} = Documents.create_document(o, a, :owner, upload(@pdf), %{"kind" => "other"})
    {:ok, vet_doc} = Documents.create_document(vet, a, :vet, upload(@pdf), %{"kind" => "lab_report"})

    assert {:error, :forbidden} = Documents.delete_document(vet, owner_doc, :vet)
    assert {:ok, _} = Documents.delete_document(o, vet_doc, :owner)
  end
end
