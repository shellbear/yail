defmodule YailWeb.AuthPlug do
  require Logger
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _opts) do
    case fetch_cookies(conn) do
      %{
        cookies: %{
          "spotify_access_token" => access_token,
          "spotify_refresh_token" => refresh_token
        }
      } ->
        conn
        |> assign(:is_authenticated, true)
        |> put_session(:spotify_access_token, access_token)
        |> put_session(:spotify_refresh_token, refresh_token)
        |> Phoenix.Controller.put_flash(:info, "Authenticated")

      _ ->
        conn
    end
  end
end
