defmodule Twitter.Timeline do
  use GenServer

  alias ExTwitter.Model.{Tweet, DeletedTweet}

  # Public interface

  def start_link(opts \\ []) do
    options = Keyword.put_new(opts, :name, __MODULE__)
    adapter = Keyword.get(opts, :adapter, ExTwitterAdapter)
    GenServer.start_link(__MODULE__, adapter, options)
  end

  def init(adapter) do
    GenServer.cast(self(), :init)

    {:ok, %{adapter: adapter, tweets: []}}
  end

  @doc """
  Returns the tweets, the first one being the most recent one.
  """
  def tweets do
    GenServer.call(__MODULE__, :list)
  end

  @doc """
  Returns the texts, the first one being the most recent one.
  """
  def texts do
    Enum.map(tweets(), &(&1.text))
  end

  # Server Callbacks

  def handle_cast(:init, %{adapter: adapter} = state) do
    latest_tweets = fetch_latest_tweets(adapter)
    new_state = Map.put(state, :tweets, latest_tweets)

    listen_to_user_stream(adapter)

    {:noreply, new_state}
  end

  def handle_call(:list, _from, %{tweets: tweets} = state) do
    {:reply, tweets, state}
  end

  def handle_call({:push, tweet}, _from, %{tweets: tweets} = state) do
    new_tweets = [tweet | tweets]
    new_state = Map.put(state, :tweets, new_tweets)

    {:reply, :ok, new_state}
  end

  def handle_call({:remove, tweet_id}, _from, %{tweets: tweets} = state) do
    new_tweets = Enum.filter(tweets, &(&1.id != tweet_id))
    new_state = Map.put(state, :tweets, new_tweets)

    {:reply, :ok, new_state}
  end

  defp fetch_latest_tweets(adapter) do
    adapter.fetch_user_timeline()
  end

  defp listen_to_user_stream(adapter) do
    timeline = self()

    spawn(fn ->
      stream = adapter.get_user_stream()
      for message <- stream do
        # IO.puts("Received #{inspect(message)}")
        handle_message(timeline, message)
      end
    end)
  end

  defp handle_message(timeline, %Tweet{} = tweet) do
    GenServer.call(timeline, {:push, tweet})
    {:ok, timeline}
  end

  defp handle_message(timeline, %DeletedTweet{status: %{id: tweet_id}}) do
    GenServer.call(timeline, {:remove, tweet_id})
    {:ok, timeline}
  end

  defp handle_message(_timeline, message) do
    {:error, {:unknown_message, message}}
  end
end
