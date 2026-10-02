defmodule Vetlink.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Vetlink.Repo
      import Vetlink.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Vetlink.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
