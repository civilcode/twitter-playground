defmodule Web.TweetsChannel do
  use Phoenix.Channel
  require Logger

  def join("tweets", message, socket) do
    Logger.debug("> join #{inspect(message)} socket: #{inspect socket}")
    send(self(), {:after_join, message})

    {:ok, socket}
  end

  def handle_info({:after_join, _msg}, socket) do
    latest_tweets = Twitter.Timeline.tweets
    push(socket, "refresh_list", %{tweets: latest_tweets})

    {:noreply, socket}
  end

  def terminate(reason, socket) do
    Logger.debug("> leave #{inspect(reason)} socket: #{inspect socket}")
    :ok
  end
end
