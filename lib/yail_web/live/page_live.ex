defmodule YailWeb.PageLive do
  @moduledoc """
  This WebView is the main control page.

  It controlls the music player, and lets users add music to the queue.
  """

  use YailWeb, :live_view
  alias Yail.Session.Playback
  alias Yail.Session.Session
  require Logger

  @playback_update_interval :timer.seconds(1)

  @impl true
  def mount(
        %{"room_id" => room_id},
        session,
        socket
      ) do
    if connected?(socket) do
      Process.send_after(self(), :update, 0)
      :timer.send_interval(@playback_update_interval, self(), :update)
    end

    assigns = %{
      room_id: room_id,
      is_admin: session["room_id"] == room_id,
      is_playing: false,
      playback: nil,
      query: "",
      results: []
    }

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("play", _params, socket) do
    socket =
      case Spotify.Player.play(get_credentials(socket)) do
        :ok -> assign(socket, :is_playing, true)
        {:ok, %{"error" => %{"message" => message}}} -> put_flash(socket, :error, message)
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("pause", _params, socket) do
    socket =
      case Spotify.Player.pause(get_credentials(socket)) do
        :ok -> assign(socket, :is_playing, false)
        {:ok, %{"error" => %{"message" => message}}} -> put_flash(socket, :error, message)
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("next", _params, socket) do
    socket =
      case Spotify.Player.skip_to_next(get_credentials(socket)) do
        :ok -> socket
        {:ok, %{"error" => %{"message" => message}}} -> put_flash(socket, :error, message)
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("previous", _params, socket) do
    socket =
      case Spotify.Player.skip_to_previous(get_credentials(socket)) do
        :ok -> socket
        {:ok, %{"error" => %{"message" => message}}} -> put_flash(socket, :error, message)
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"q" => "spotify:track:" <> track_id}, socket) do
    socket =
      case Spotify.Track.get_track(get_credentials(socket), track_id) do
        {:ok, %{"error" => %{"message" => message}}} ->
          put_flash(socket, :error, message)

        {:ok, track} ->
          images = track.album["images"]
          image = Enum.find(images, &(&1["height"] == 64)) || hd(images)

          assign(socket, :results, [
            %{
              :artist => hd(track.artists)["name"],
              :preview => image["url"],
              :name => track.name,
              :uri => track.uri
            }
          ])

        {:error, reason} ->
          Logger.error("Failed to fetch track: #{reason}")
          socket

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"q" => "spotify:album:" <> album_id}, socket) do
    socket =
      case Spotify.Album.get_album(get_credentials(socket), album_id) do
        {:ok, %{"error" => %{"message" => message}}} ->
          put_flash(socket, :error, message)

        {:ok, album} ->
          images = album.images
          image = Enum.find(images, &(&1["height"] == 64)) || hd(images)

          items =
            album.tracks.items
            |> Enum.map(
              &%{
                artist: hd(&1.artists)["name"],
                preview: image["url"],
                name: &1.name,
                uri: &1.uri
              }
            )

          assign(socket, :results, items)

        {:error, reason} ->
          Logger.error("Failed to fetch album: #{reason}")
          socket

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"q" => ""}, socket) do
    socket =
      assign(socket, %{
        query: "",
        results: []
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    socket =
      socket
      |> search(query, :track)
      |> assign(:query, query)

    {:noreply, socket}
  end

  @impl true
  def handle_event("add", %{"uri" => uri}, socket) do
    socket =
      case Spotify.Player.play(get_credentials(socket), uris: [uri]) do
        :ok ->
          Logger.info("Playing: #{uri}")
          socket

        {:ok, %{"error" => %{"message" => message}}} ->
          put_flash(socket, :error, message)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:update, socket) do
    socket =
      case Spotify.Player.get_current_playback(get_credentials(socket)) do
        {:ok, %{"error" => %{"status" => 401}}} ->
          socket
          |> put_flash(:warn, "Token expired")
          |> redirect(to: "/auth/spotify")

        {:ok, playback} ->
          case playback.item do
            nil ->
              assign(socket, :is_playing, playback.is_playing)

            {:ok, %{"error" => %{"message" => message}}} ->
              put_flash(socket, :error, message)

            item ->
              images = item.album["images"]
              image = Enum.find(images, &(&1["height"] == 300)) || hd(images)

              assign(socket, %{
                is_playing: playback.is_playing,
                playback: %Playback{
                  track_name: item.name,
                  artist: hd(item.artists)["name"],
                  track_image: image["url"]
                }
              })
          end

        {:error, reason} ->
          Logger.error("Failed to fetch playback: #{reason}")
          socket

        :ok ->
          assign(socket, %{
            is_playing: false,
            playback: nil
          })
      end

    {:noreply, socket}
  end

  @spec search(
          atom
          | %{
              :assigns =>
                atom | %{:access_token => any, :refresh_token => any, optional(any) => any},
              optional(any) => any
            },
          any,
          :track
        ) ::
          atom
          | %{
              :assigns =>
                atom | %{:access_token => any, :refresh_token => any, optional(any) => any},
              optional(any) => any
            }

  def search(socket, query, :track) do
    credentials = get_credentials(socket)

    socket =
      case Spotify.Search.query(credentials, q: query, type: "track") do
        {:ok, %{"error" => %{"message" => message}}} ->
          put_flash(socket, :error, message)

        {:ok, %{:items => items}} ->
          items =
            items
            |> Enum.filter(&(&1.type == "track"))
            |> Enum.map(fn item ->
              images = item.album["images"]
              image = Enum.find(images, &(&1["height"] == 64)) || hd(images)

              %{
                artist: hd(item.artists)["name"],
                preview: image["url"],
                name: item.name,
                uri: item.uri
              }
            end)

          assign(socket, :results, items)

        {:error, reason} ->
          Logger.error("Failed to search song: #{reason}")
          socket
      end

    socket
  end

  def get_credentials(socket) do
    room_id = socket.assigns.room_id
    %{:access_token => access_token, :refresh_token => refresh_token} = Session.get(room_id)

    %Spotify.Credentials{
      access_token: access_token,
      refresh_token: refresh_token
    }
  end
end
