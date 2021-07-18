defmodule Yail.Session.Session do
  use GenServer

  @period :timer.seconds(1)

  alias Yail.Session.{Artist, Playback, Track}

  require Logger

  def room(room_id), do: "room:#{room_id}"

  @impl true
  def init(_) do
    Process.send_after(self(), :poll, @period)
    {:ok, %{}}
  end

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def handle_call({:add, room_id}, _from, rooms) do
    rooms = Map.put(rooms, room_id, %{})
    {:reply, rooms, rooms}
  end

  @impl true
  def handle_call({:remove, room_id}, _from, rooms) do
    rooms = Map.delete(rooms, room_id)
    {:reply, rooms, rooms}
  end

  @impl true
  def handle_call({:get, room_id}, _from, rooms) do
    room =
      case Map.get(rooms, room_id) do
        nil -> %{}
        room -> room
      end

    {:reply, rooms, room}
  end

  @spec get_credentials(any) :: nil | %Spotify.Credentials{access_token: any, refresh_token: any}
  def get_credentials(room_id) do
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

  def udpate_room(room_id) do
    case get_credentials(room_id) do
      creds when not is_nil(creds) ->
        case Spotify.Player.get_current_playback(creds) do
          {:ok, %{"error" => %{"status" => 401}}} ->
            {:error, "expired token"}

          {:ok, %{"error" => %{"message" => message}}} ->
            {:error, message}

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

            {:ok,
             %{
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
             }}

          :ok ->
            {:ok,
             %{
               is_playing: false,
               playback: nil
             }}

          {:ok, %{is_playing: is_playing}} ->
            {:ok, %{is_playing: is_playing}}
        end

      _ ->
        Logger.warn("Failed to obtain room #{room_id} credentials")
    end
  end

  @impl true
  def handle_info(:poll, rooms) when rooms == %{} do
    Process.send_after(self(), :poll, @period)
    {:noreply, %{}}
  end

  @impl true
  def handle_info(:poll, rooms) do
    rooms =
      rooms
      |> Map.keys()
      |> Task.async_stream(fn room_id ->
        {:ok, room} = udpate_room(room_id)
        state = Map.take(room, [:is_playing, :playback, :views])
        YailWeb.Endpoint.broadcast!(room(room_id), "update", state)
        Logger.debug("Updated room #{room_id}")

        {room_id, room}
      end)
      |> Enum.into(%{}, fn {:ok, result} -> result end)

    Process.send_after(self(), :poll, @period)
    {:noreply, rooms}
  end
end
