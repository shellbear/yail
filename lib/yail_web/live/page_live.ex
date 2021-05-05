defmodule YailWeb.PageLive do
  @moduledoc """
  This WebView is the main control page.

  It controlls the music player, and lets users add music to the queue.
  """

  use YailWeb, :live_view
  require Logger

  @playback_update_interval :timer.seconds(1)

  @impl true
  def mount(
        _params,
        %{"spotify_access_token" => access_token, "spotify_refresh_token" => refresh_token} =
          _session,
        socket
      ) do
    if connected?(socket) do
      Process.send_after(self(), :update, 0)
      :timer.send_interval(@playback_update_interval, self(), :update)
    end

    Logger.debug("CONNECTED: #{connected?(socket)}")

    assigns = %{
      is_playing: false,
      track_name: "",
      track_image: "",
      refresh_token: refresh_token,
      access_token: access_token
    }

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("play", _params, socket) do
    socket =
      case Spotify.Player.play(get_credentials(socket)) do
        :ok -> assign(socket, :is_playing, true)
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("pause", _params, socket) do
    socket =
      case Spotify.Player.pause(get_credentials(socket)) do
        :ok -> assign(socket, :is_playing, false)
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("next", _params, socket) do
    Spotify.Player.skip_to_next(get_credentials(socket))

    {:noreply, socket}
  end

  @impl true
  def handle_event("previous", _params, socket) do
    Spotify.Player.skip_to_previous(get_credentials(socket))

    {:noreply, socket}
  end

  @impl true
  def handle_info(:update, socket) do
    Logger.info("Processing...")

    socket =
      case Spotify.Player.get_current_playback(get_credentials(socket)) do
        {:ok, playback} ->
          images = playback.item.album["images"]
          image = Enum.find(images, &(&1["height"] == 300)) || images[0]

          assign(socket, %{
            is_playing: playback.is_playing,
            track_name: playback.item.name,
            track_image: image["url"]
          })

        {:error, reason} ->
          Logger.error("Failed to fetch playback: #{reason}")
          socket

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def get_credentials(socket),
    do: %Spotify.Credentials{
      access_token: socket.assigns.access_token,
      refresh_token: socket.assigns.refresh_token
    }
end
