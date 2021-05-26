defmodule YailWeb.PageController do
  use YailWeb, :controller

  alias Yail.Session.Room

  def reset(conn, _params) do
    case get_session(conn, :room_id) do
      id -> Cachex.del(:yail, id)
    end

    room = Room.new(conn)
    Cachex.put(:yail, room.id, room)

    conn
    |> put_session(:room_id, room.id)
    |> redirect(to: "/#{room.id}")
  end

  def new(conn, _params) do
    room =
      case get_session(conn, :room_id) do
        nil ->
          Room.new(conn)

        id ->
          case Cachex.get(:yail, id) do
            {:ok, room} when not is_nil(room) -> room
            _ -> Room.new(conn)
          end
      end

    room = Room.update(room, conn)
    Cachex.put(:yail, room.id, room)

    conn
    |> put_session(:room_id, room.id)
    |> redirect(to: "/#{room.id}")
  end

  def landing(conn, _params) do
    render(conn, "landing.html")
  end

  def privacy(conn, _params) do
    render(conn, "privacy.html")
  end

  def login(conn, _params) do
    redirect(conn, to: "/auth/spotify")
  end

  def not_found(conn, _params) do
    render(conn, "not_found.html")
  end
end
