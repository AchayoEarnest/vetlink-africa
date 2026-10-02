defmodule Vetlink.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Vetlink.Repo,
      {Phoenix.PubSub, name: Vetlink.PubSub},
      VetlinkWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Vetlink.Supervisor)
  end
end
