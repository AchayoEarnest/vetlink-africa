import Config

if config_env() == :prod do
  config :vetlink, Vetlink.Repo,
    url: System.fetch_env!("DATABASE_URL"),
    types: Vetlink.PostgresTypes,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :vetlink, VetlinkWeb.Endpoint,
    url: [host: System.fetch_env!("PHX_HOST"), port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
    check_origin: String.split(System.fetch_env!("CORS_ORIGINS"), ","),
    server: true

  config :vetlink, :storage_dir, System.get_env("STORAGE_DIR", "/var/lib/vetlink/uploads")
  config :vetlink, :cors_origins, String.split(System.fetch_env!("CORS_ORIGINS"), ",")
end
