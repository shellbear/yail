defmodule Yail.Session.Track do
  @enforce_keys [:uri, :name, :artist, :preview]
  defstruct uri: "",
            name: "",
            artist: "",
            preview: ""
end
