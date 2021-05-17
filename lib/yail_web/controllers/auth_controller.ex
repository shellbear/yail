defmodule YailWeb.AuthController do
  use YailWeb, :controller
  require Logger

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> delete_resp_cookie("spotify_access_token")
    |> delete_resp_cookie("spotify_refresh_token")
    |> redirect(to: "/")
  end

  def authorize(conn, _params) do
    redirect(conn, external: Spotify.Authorization.url())
  end

  def callback(conn, params) do
    case Spotify.Authentication.authenticate(conn, params) do
      {:ok, conn} ->
        redirect(conn, to: "/")

      {:error, reason, conn} ->
        conn
        |> put_flash(:error, "Error: #{reason}")
        |> redirect(to: "/")
    end
  end
end
