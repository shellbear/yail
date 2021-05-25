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

if config_env() == :prod do
  secret_key_base =
    case System.get_env("SECRET_KEY_BASE") do
      nil -> raise "SECRET_KEY_BASE configuration option is required."
      key when byte_size(key) < 64 -> raise "SECRET_KEY_BASE must be at least 64 bytes long."
      key -> key
    end

  base_url =
    case System.get_env("BASE_URL") do
      nil ->
        raise "BASE_URL configuration option is required."

      base_url ->
        case URI.parse(base_url) do
          %{scheme: scheme} = url when scheme in ["http", "https"] ->
            url

          _ ->
            raise "BASE_URL must start with `http` or `https`. Currently configured as `#{System.get_env("BASE_URL")}`"
        end
    end

  config :yail, YailWeb.Endpoint,
    server: true,
    url: [host: base_url.host, scheme: base_url.scheme, port: base_url.port],
    secret_key_base: secret_key_base
end
