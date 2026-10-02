import Config

config :argon2_elixir, t_cost: 1, m_cost: 8

config :vetlink, Vetlink.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: String.to_integer(System.get_env("DB_PORT", "5433")),
  database: "vetlink_test#{System.get_env("MIX_TEST_PARTITION")}",
  types: Vetlink.PostgresTypes,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :vetlink, VetlinkWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key-base-test-secret-key-base-test-secret-key-base-0123456789ab",
  server: false

config :vetlink, :cors_origins, ["http://localhost:3000"]
config :vetlink, :storage_dir, Path.join(System.tmp_dir!(), "vetlink_test_uploads")
config :vetlink, :max_upload_bytes, 1_000
config :logger, level: :warning
