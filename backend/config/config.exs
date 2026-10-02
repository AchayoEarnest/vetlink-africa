import Config

config :vetlink, ecto_repos: [Vetlink.Repo], generators: [timestamp_type: :utc_datetime]

config :vetlink, VetlinkWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [json: VetlinkWeb.ErrorJSON], layout: false],
  pubsub_server: Vetlink.PubSub

config :logger, :console, format: "$time $metadata[$level] $message\n", metadata: [:request_id]
config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
