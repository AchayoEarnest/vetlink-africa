defmodule Vetlink.Messaging do
  @moduledoc """
  Owner <-> vet chat. A conversation only exists once an owner has booked that vet,
  so vets cannot cold-message owners and strangers cannot message vets.
  """
  import Ecto.Query
  alias Vetlink.Repo
  alias Vetlink.Accounts.User
  alias Vetlink.Messaging.{Conversation, Message}

  @emergency ~r/(not breathing|can'?t breathe|difficulty breathing|poison|seizure|convuls|unconscious|collaps|heavy bleeding|bloat|can'?t urinate|can'?t stand|cannot stand|difficult birth)/i

  def emergency_hint?(body) when is_binary(body), do: Regex.match?(@emergency, body)
  def emergency_hint?(_), do: false

  @doc "Called when a booking is created. Safe to call repeatedly."
  def ensure_conversation(owner_id, vet_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert_all("conversations", [%{owner_id: owner_id, vet_id: vet_id, inserted_at: now, updated_at: now}],
      on_conflict: :nothing,
      conflict_target: [:owner_id, :vet_id]
    )

    :ok
  end

  def list_conversations(%User{id: id}) do
    from(c in Conversation,
      join: o in assoc(c, :owner),
      join: v in assoc(c, :vet),
      where: c.owner_id == ^id or c.vet_id == ^id,
      order_by: [desc: c.updated_at],
      select: %{id: c.id, owner_id: c.owner_id, vet_id: c.vet_id, owner_name: o.name, vet_name: v.name, updated_at: c.updated_at}
    )
    |> Repo.all()
  end

  @doc "Only the two participants may open a conversation. Everyone else gets :not_found."
  def fetch_member(%User{id: id}, conversation_id) do
    with {:ok, cid} <- to_int(conversation_id),
         %Conversation{} = c <- Repo.get(Conversation, cid),
         true <- c.owner_id == id or c.vet_id == id do
      {:ok, c}
    else
      _ -> {:error, :not_found}
    end
  end

  def list_messages(%Conversation{id: id}, limit \\ 200) do
    from(m in Message, where: m.conversation_id == ^id, order_by: [desc: m.id], limit: ^limit)
    |> Repo.all()
    |> Enum.reverse()
  end

  def send_message(%User{id: uid}, %Conversation{id: cid}, body) do
    Repo.transaction(fn ->
      case %Message{conversation_id: cid, sender_id: uid} |> Message.changeset(%{"body" => body}) |> Repo.insert() do
        {:ok, msg} ->
          now = DateTime.utc_now() |> DateTime.truncate(:second)
          Repo.update_all(from(c in Conversation, where: c.id == ^cid), set: [updated_at: now])
          msg

        {:error, cs} ->
          Repo.rollback(cs)
      end
    end)
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
