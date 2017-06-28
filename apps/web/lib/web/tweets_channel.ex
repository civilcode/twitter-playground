defmodule Web.TweetsChannel do
  use Phoenix.Channel

  def join("tweets", message, socket) do
    send(self, {:after_join, message})

    {:ok, socket}
  end

  def handle_info({:after_join, msg}, socket) do
    push socket, "join", %{status: "connected", tweets: Twitter.Timeline.tweets}
    {:noreply, socket}
  end
end
