defmodule YailWeb.AuthRedirect do
  alias Phoenix.Controller

  def init(options) do
    options
  end

  def call(conn, _opts) do
    case conn.assigns[:is_authenticated] do
      true -> Controller.redirect(conn, to: "/home")
      _ -> conn
    end
  end
end
