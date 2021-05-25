defmodule YailWeb.Router do
  use YailWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {YailWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug YailWeb.AuthPlug
  end

  pipeline :room do
    plug YailWeb.RoomPlug
  end

  pipeline :auth_required do
    plug YailWeb.AuthRequiredPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: YailWeb.Telemetry
    end
  end

  scope "/", YailWeb do
    pipe_through [:browser, :auth_required]
    get "/", PageController, :new
    get "/reset", PageController, :reset
    get "/logout", AuthController, :delete
  end

  scope "/", YailWeb do
    pipe_through :browser

    get "/login", PageController, :login
    get "/not_found", PageController, :not_found

    pipe_through :room

    live "/:room_id", PageLive, :index
  end

  scope "/auth", YailWeb do
    pipe_through :browser

    get "/spotify", AuthController, :authorize
    get "/spotify/callback", AuthController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", YailWeb do
  #   pipe_through :api
  # end
end
