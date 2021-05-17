import Config

secret_key_base = System.get_env("SECRET_KEY_BASE")

if !Application.get_env(:yail, :secret_key_base) do
  case secret_key_base do
    nil -> raise "SECRET_KEY_BASE configuration option is required."
    key when byte_size(key) < 64 -> raise "SECRET_KEY_BASE must be at least 64 bytes long."
  end
end

config :yail, YailWeb.Endpoint, secret_key_base: secret_key_base
