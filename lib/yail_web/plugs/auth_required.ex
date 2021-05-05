defmodule YailWeb.AuthRequiredPlug do
  require Logger

  def init(options) do
    options
  end

  def call(conn, _opts) do
    case conn.assigns[:is_authenticated] do
      true -> conn
      _ -> Phoenix.Controller.redirect(conn, to: "/login")
    end
  end
end
