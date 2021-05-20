defmodule YailWeb.RoomPlug do
  alias Phoenix.Controller
  alias Yail.Session.Session

  def init(options) do
    options
  end

  def call(%{:path_params => %{"room_id" => room_id}} = conn, _opts) do
    case Session.get(room_id) do
      nil -> Controller.redirect(conn, to: "/not_found")
      _ -> conn
    end
  end

  def call(conn, _opts) do
    conn
  end
end
