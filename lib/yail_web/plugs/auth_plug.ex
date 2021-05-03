defmodule YailWeb.AuthPlug do
  require Logger
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _opts) do
    case fetch_cookies(conn) do
      %{cookies: %{"spotify_access_token" => _}} ->
        conn
        |> assign(:is_authenticated, true)
        |> Phoenix.Controller.put_flash(:info, "Authenticated")

      _ ->
        conn
    end
  end
end
