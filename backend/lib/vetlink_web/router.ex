defmodule VetlinkWeb.Router do
  use VetlinkWeb, :router

  pipeline :api, do: plug(:accepts, ["json"])
  pipeline :authenticated, do: plug(VetlinkWeb.Plugs.Auth)

  scope "/api", VetlinkWeb do
    pipe_through :api

    get "/health", HealthController, :show
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    get "/vets/nearby", VetController, :nearby
  end

  scope "/api", VetlinkWeb do
    pipe_through [:api, :authenticated]

    get "/me", AuthController, :me
    resources "/animals", AnimalController, only: [:index, :create, :show]
    post "/animals/:animal_id/shares", AnimalController, :share
    get "/animals/:animal_id/records", RecordController, :index
    post "/animals/:animal_id/records", RecordController, :create
    get "/vets/me", VetController, :show_me
    put "/vets/me", VetController, :update_me
    get "/bookings", BookingController, :index
    post "/bookings", BookingController, :create
    patch "/bookings/:id", BookingController, :update
    get "/animals/:animal_id/documents", DocumentController, :index
    post "/animals/:animal_id/documents", DocumentController, :create
    get "/documents/:id/download", DocumentController, :download
    delete "/documents/:id", DocumentController, :delete
    get "/conversations", ConversationController, :index
    get "/conversations/:id/messages", ConversationController, :messages
    post "/conversations/:id/messages", ConversationController, :send_message
  end
end
