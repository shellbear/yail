# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :yail, YailWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "doXoMoC2rHZcfPZjLSB2HPkWUHQ0RNW4zIvQlRFbc9fJ7JeNzTcS349qq67+HZwB",
  render_errors: [view: YailWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Yail.PubSub,
  live_view: [signing_salt: "8tOAMTwk"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# Apply git hooks config in development.
if Mix.env() != :prod do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      pre_commit: [
        tasks: [
          {:cmd, "mix clean"},
          {:cmd, "mix compile --warnings-as-errors"},
          {:cmd, "mix xref deprecated --abort-if-any"},
          {:cmd, "mix xref unreachable --abort-if-any"},
          {:cmd, "mix format"},
          {:cmd, "mix credo --strict"}
        ]
      ]
    ]
end
