# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :api_auth,
  ecto_repos: [ApiAuth.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :api_auth, ApiAuthWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: ApiAuthWeb.ErrorHTML, json: ApiAuthWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ApiAuth.PubSub,
  live_view: [signing_salt: "YaEPE0/4"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :api_auth, :pow,
  user: ApiAuth.Users.User,
  repo: ApiAuth.Repo,
  cache_store_backend: ApiAuthWeb.Pow.RedisCache

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
