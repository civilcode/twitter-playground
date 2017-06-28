defmodule Web.TweetsChannel do
  use Phoenix.Channel

  def join("tweets", message, socket) do
    send(self, {:after_join, message})

    {:ok, socket}
  end

  def handle_info({:after_join, _msg}, socket) do
    push socket, "refresh_list", %{tweets: Twitter.Timeline.tweets}
    {:noreply, socket}
  end

  def terminate(reason, socket) do
    IO.inspect "> leave #{inspect(reason)} socket: #{inspect socket}"
    :ok
  end
end
