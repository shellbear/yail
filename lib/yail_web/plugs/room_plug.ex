defmodule YailWeb.RoomPlug do
  alias Phoenix.Controller

  def init(options) do
    options
  end

  def call(%{:path_params => %{"room_id" => room_id}} = conn, _opts) do
    case Cachex.get(:yail, room_id) do
      {:ok, room} when not is_nil(room) -> conn
      _ -> Controller.redirect(conn, to: "/not_found")
    end
  end

  def call(conn, _opts) do
    conn
  end
end
