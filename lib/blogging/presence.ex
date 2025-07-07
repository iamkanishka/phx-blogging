defmodule Blogging.Presence do
  use Phoenix.Presence,
    otp_app: :blogging,
    pubsub_server: Blogging.PubSub
end
