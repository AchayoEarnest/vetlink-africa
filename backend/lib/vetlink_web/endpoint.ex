defmodule VetlinkWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :vetlink

  socket "/socket", VetlinkWeb.UserSocket, websocket: true, longpoll: false

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug CORSPlug, origin: &__MODULE__.cors_origins/0

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    length: 12_000_000

  plug VetlinkWeb.Router

  def cors_origins, do: Application.get_env(:vetlink, :cors_origins, [])
end
