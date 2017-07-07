defmodule Twitter.Stream do
  use GenServer

  alias ExTwitter.Model.Tweet

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
    listen_to_stream_filter(adapter)

    {:noreply, state}
  end

  def handle_call(:list, _from, %{tweets: tweets} = state) do
    {:reply, tweets, state}
  end

  def handle_call({:push, tweet}, _from, %{tweets: tweets} = state) do
    new_tweets = [tweet | tweets]
    new_state = Map.put(state, :tweets, new_tweets)

    PubSub.publish("twitter:stream", {:new_tweet, tweet})

    {:reply, :ok, new_state}
  end

  defp listen_to_stream_filter(adapter) do
    stream = self()

    spawn(fn ->
      inbound_stream = adapter.get_filtered_stream()
      for message <- inbound_stream do
        IO.puts("Received #{inspect(message)}")
        handle_message(stream, message)
      end
    end)
  end

  defp handle_message(stream, %Tweet{} = tweet) do
    GenServer.call(stream, {:push, tweet})
    {:ok, stream}
  end

  defp handle_message(_stream, message) do
    {:error, {:unknown_message, message}}
  end
end
