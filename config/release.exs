import Config

secret_key_base = System.get_env("SECRET_KEY_BASE")
base_url = System.get_env("BASE_URL") || Application.get_env(:yail, :base_url)

if !Application.get_env(:yail, :secret_key_base) do
  case secret_key_base do
    nil -> raise "SECRET_KEY_BASE configuration option is required."
    key when byte_size(key) < 64 -> raise "SECRET_KEY_BASE must be at least 64 bytes long."
  end
end

if !base_url do
  raise "BASE_URL configuration option is required."
end

base_url = URI.parse(base_url)

if base_url.scheme not in ["http", "https"] do
  raise "BASE_URL must start with `http` or `https`. Currently configured as `#{System.get_env("BASE_URL")}`"
end

config :yail, YailWeb.Endpoint,
  server: true,
  check_origin: [URI.to_string(base_url)],
  url: [host: base_url.host, scheme: base_url.scheme, port: base_url.port],
  secret_key_base: secret_key_base
