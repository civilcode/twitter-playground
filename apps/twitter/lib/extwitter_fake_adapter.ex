  defmodule ExTwitterFakeAdapter do
    # Public interface

    def start_link(_opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
    end

    def init(:ok) do
      {:ok, queue} = BlockingQueue.start_link(:infinity)

      {:ok, %{queue: queue, tweets: []}}
    end

    def set_initial_tweets(tweets) do
      GenServer.call(__MODULE__, {:set_tweets, List.wrap(tweets)})
    end

    def fetch_user_timeline do
      GenServer.call(__MODULE__, :tweets)
    end

    def get_user_stream do
      GenServer.call(__MODULE__, :get_stream)
    end

    def simulate_incoming_message(tweet) do
      GenServer.call(__MODULE__, {:push_tweet, tweet})
    end

    # Server Callbacks

    def handle_call(:tweets, _from, %{tweets: tweets} = state) do
      {:reply, tweets, state}
    end

    def handle_call(:get_stream, _from, %{queue: pid} = state) do
      stream = BlockingQueue.pop_stream(pid)

      {:reply, stream, state}
    end

    def handle_call({:set_tweets, tweets}, _from, state) do
      {:reply, tweets, %{state | tweets: tweets}}
    end

    def handle_call({:push_tweet, tweet}, _from, %{queue: pid} = state) do
      BlockingQueue.push(pid, tweet)

      {:reply, :ok, state}
    end
  end
