defmodule YailWeb.AuthRequiredPlug do
  alias Phoenix.Controller

  def init(options) do
    options
  end

  def call(conn, _opts) do
    case conn.assigns[:is_authenticated] do
      true -> conn
      _ -> Controller.redirect(conn, to: "/login")
    end
  end
end
