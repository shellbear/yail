import Config

if config_env() in [:dev, :test] do
  Envy.auto_load()
end

### Optional params
port = String.to_integer(System.get_env("PORT", "4000"))
callback_url = System.get_env("CALLBACK_URL", "http://127.0.0.1:#{port}/auth/spotify/callback")

### Mandatory params
spotify_client_id = System.get_env("SPOTIFY_CLIENT_ID")
spotify_secret_key = System.get_env("SPOTIFY_CLIENT_SECRET")

if !spotify_client_id do
  raise "SPOTIFY_CLIENT_ID configuration option is required."
end

if !spotify_secret_key do
  raise "SPOTIFY_CLIENT_SECRET configuration option is required."
end

config :spotify_ex,
  client_id: spotify_client_id,
  secret_key: spotify_secret_key,
  callback_url: callback_url,
  scopes: ["user-read-playback-state", "user-modify-playback-state", "user-read-private"]

config :yail, YailWeb.Endpoint, http: [port: port]
