defmodule YailWeb.Presence do
  use Phoenix.Presence,
    otp_app: :yail,
    pubsub_server: Yail.PubSub
end
