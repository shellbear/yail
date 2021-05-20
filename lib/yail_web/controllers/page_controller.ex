defmodule YailWeb.PageController do
  use YailWeb, :controller

  alias Yail.Session.{
    Room,
    Session
  }

  def new(conn, _params) do
    room =
      case get_session(conn, :room_id) do
        nil ->
          Room.new(conn)

        id ->
          case Session.get(id) do
            nil -> Room.new(conn)
            room -> room
          end
      end

    Session.put(room.id, room)

    conn
    |> put_session(:room_id, room.id)
    |> redirect(to: "/#{room.id}")
  end

  def login(conn, _params) do
    render(conn, "login.html")
  end

  def not_found(conn, _params) do
    render(conn, "not_found.html")
  end
end
