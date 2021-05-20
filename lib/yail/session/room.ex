defmodule Yail.Session.Room do
  alias Yail.Session.Room

  @enforce_keys [:id, :access_token, :refresh_token]
  defstruct id: "",
            tracks: [],
            access_token: "",
            refresh_token: ""

  def new(conn) do
    %{"spotify_access_token" => access_token, "spotify_refresh_token" => refresh_token} =
      Plug.Conn.get_session(conn)

    %Room{
      id: Nanoid.generate(),
      access_token: access_token,
      refresh_token: refresh_token
    }
  end

  def new(access_token, refresh_token) do
    %Room{
      id: Nanoid.generate(),
      access_token: access_token,
      refresh_token: refresh_token
    }
  end

  def update(room, conn) do
    %{"spotify_access_token" => access_token, "spotify_refresh_token" => refresh_token} =
      Plug.Conn.get_session(conn)

    %Room{
      room
      | access_token: access_token,
        refresh_token: refresh_token
    }
  end
end
