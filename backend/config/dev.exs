import Config

config :vetlink, Vetlink.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: String.to_integer(System.get_env("DB_PORT", "5433")),
  database: "vetlink_dev",
  types: Vetlink.PostgresTypes,
  pool_size: 10,
  show_sensitive_data_on_connection_error: true

config :vetlink, VetlinkWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  debug_errors: true,
  secret_key_base: "dev-only-secret-key-base-change-me-dev-only-secret-key-base-change-me-0123456789"

config :vetlink, :cors_origins, ["http://localhost:3000"]
config :vetlink, :storage_dir, Path.expand("../priv/uploads", __DIR__)
config :logger, level: :debug
