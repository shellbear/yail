defmodule Yail.Session.Track do
  @enforce_keys [:uri, :name, :preview]
  defstruct uri: "",
            name: "",
            preview: "",
            artist: ""
end
