defmodule YailWeb.PageController do
  use YailWeb, :controller

  def login(conn, _params) do
    render(conn, "login.html")
  end
end
