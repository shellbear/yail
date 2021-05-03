defmodule YailWeb.PageController do
  use YailWeb, :controller

  def login(conn, _params) do
    case conn.assigns[:is_authenticated] do
      true -> redirect(conn, to: "/")
      _ -> render(conn, "login.html")
    end
  end
end
