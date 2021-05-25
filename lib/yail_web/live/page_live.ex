defmodule YailWeb.PageLive do
  @moduledoc """
  This WebView is the main control page.

  It controlls the music player, and lets users add music to the queue.
  """

  use YailWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias Yail.LiveMonitor
  alias Yail.Session.{Artist, Playback, Track}
  alias YailWeb.Presence

  require Logger

  @playback_update_interval :timer.seconds(1)

  def room(room_id), do: "room:#{room_id}"
  def views_count(room_id), do: length(Map.keys(Presence.list(room(room_id))))

  @impl true
  def mount(
        %{"room_id" => room_id},
        session,
        socket
      ) do
    if connected?(socket) do
      LiveMonitor.monitor(self(), __MODULE__, %{room_id: room_id, socket_id: socket.id})
      Presence.track(self(), room(room_id), socket.id, %{})
      YailWeb.Endpoint.subscribe(room(room_id))

      if session["room_id"] == room_id do
        send(self(), :update)
        :timer.send_interval(@playback_update_interval, self(), :update)
      end
    end

    assigns = %{
      room_id: room_id,
      is_admin: session["room_id"] == room_id,
      is_playing: false,
      playback: nil,
      query: "",
      views: views_count(room_id),
      results: []
    }

    {:ok, assign(socket, assigns)}
  end

  def unmount(_reason, %{room_id: room_id, socket_id: socket_id}) do
    Presence.untrack(self(), room_id, socket_id)
    :ok
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
          socket

        {:ok, %{"error" => %{"message" => message}}} ->
          put_flash(socket, :error, message)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, %{assigns: %{room_id: room_id}} = socket) do
    views = views_count(room_id)
    {:noreply, assign(socket, :views, views)}
  end

  @impl true
  def handle_info(%Broadcast{event: "update", payload: state}, socket) do
    {:noreply, assign(socket, state)}
  end

  @impl true
  def handle_info(:update, %{assigns: %{room_id: room_id}} = socket) do
    socket =
      case Spotify.Player.get_current_playback(get_credentials(socket)) do
        {:ok, %{"error" => %{"status" => 401}}} ->
          socket
          |> put_flash(:warn, "Token expired")
          |> redirect(to: "/auth/spotify")

        {:ok, %{"error" => %{"message" => message}}} ->
          put_flash(socket, :error, message)

        {:ok,
         %{
           is_playing: is_playing,
           item: %{
             uri: uri,
             name: name,
             album: %{"images" => images},
             artists: [%{"uri" => artist_uri, "name" => artist_name} | _]
           }
         }} ->
          image = Enum.find(images, &(&1["height"] == 300)) || hd(images)

          assign(socket, %{
            is_playing: is_playing,
            playback: %Playback{
              track: %Track{
                uri: uri,
                name: name,
                preview: image["url"]
              },
              artist: %Artist{
                uri: artist_uri,
                name: artist_name
              }
            }
          })

        :ok ->
          assign(socket, %{
            is_playing: false,
            playback: nil
          })

        {:ok, %{is_playing: is_playing}} ->
          assign(socket, :is_playing, is_playing)
      end

    state = Map.take(socket.assigns, [:is_playing, :playback, :views])
    YailWeb.Endpoint.broadcast!(room(room_id), "update", state)

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

  def get_credentials(%{assigns: %{room_id: room_id}}) do
    case Cachex.get(:yail, room_id) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token}} ->
        %Spotify.Credentials{
          access_token: access_token,
          refresh_token: refresh_token
        }

      _ ->
        nil
    end
  end
end
