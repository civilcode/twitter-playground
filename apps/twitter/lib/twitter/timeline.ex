defmodule Twitter.Timeline do
  use GenServer
  require Logger

  alias Twitter.{Tweet, TweetDeletion}

  # Public interface

  def start_link(opts \\ []) do
    adapter = Application.get_env(:twitter, :adapter)
    topic = Keyword.get(opts, :topic, "twitter:timeline")
    options = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [adapter, topic], options)
  end

  def init([adapter, topic]) do
    # Defer initialization to prevent timeout
    GenServer.cast(self(), :init)

    {:ok, %{adapter: adapter, tweets: [], topic: topic}}
  end

  @doc """
  Returns the tweets, the first one being the most recent one.
  """
  @spec tweets :: [Tweet.t]
  def tweets do
    GenServer.call(__MODULE__, :list)
  end

  # Server Callbacks

  def handle_cast(:init, %{adapter: adapter} = state) do
    listen_to_user_stream(adapter)
    latest_tweets = adapter.fetch_user_timeline()
    new_state = %{state | tweets: latest_tweets}
    Logger.debug("Initial state: #{inspect(new_state)}")

    {:noreply, new_state}
  end

  def handle_call(:list, _from, %{tweets: tweets} = state) do
    {:reply, tweets, state}
  end

  def handle_call({:push, tweet}, _from, %{tweets: tweets} = state) do
    PubSub.publish(state.topic, {:new_tweet, tweet})

    {:reply, :ok, %{state | tweets: [tweet | tweets]}}
  end

  def handle_call({:remove, tweet_id}, _from, %{tweets: tweets} = state) do
    new_tweets = Enum.filter(tweets, &(&1.id != tweet_id))
    PubSub.publish(state.topic, {:all_tweets, new_tweets})

    {:reply, :ok, %{state | tweets: new_tweets}}
  end

  defp listen_to_user_stream(adapter) do
    timeline = self()

    Task.start_link(fn ->
      stream = adapter.get_user_stream()
      for message <- stream do
        Logger.debug("Received #{inspect(message)}")
        process_message(timeline, message)
      end
    end)
  end

  defp process_message(timeline, %Tweet{} = tweet) do
    GenServer.call(timeline, {:push, tweet})
    {:ok, timeline}
  end

  defp process_message(timeline, %TweetDeletion{tweet_id: tweet_id}) do
    GenServer.call(timeline, {:remove, tweet_id})
    {:ok, timeline}
  end

  defp process_message(_timeline, message) do
    {:error, {:unknown_message, message}}
  end
end
