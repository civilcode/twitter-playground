defmodule Twitter.TimelineTest do
  use ExUnit.Case, async: false

  alias Twitter.{Timeline, Tweet, TweetDeletion}

  setup do
    adapter = Application.get_env(:twitter, :adapter)
    {:ok, pid} = adapter.start_link()

    on_exit fn ->
      assert_down(pid)
    end

    [adapter: adapter]
  end

  describe "initializing the timeline" do
    test "initializes the state with existing user's tweets", %{adapter: adapter} do
      adapter.put_tweets([
        %Tweet{text: ":tweet-2:"},
        %Tweet{text: ":tweet-1:"}
      ])

      {:ok, pid} = Timeline.start_link()

      tweets = Timeline.tweets
      assert length(tweets) == 2

      first_tweet = List.first(tweets)
      assert %Tweet{text: ":tweet-2:"} = first_tweet

      on_exit fn ->
        assert_down(pid)
      end
    end
  end

  describe "publishing tweets" do
    setup do
      topic = "test:timeline"
      PubSub.start_link()
      PubSub.subscribe(self(), topic)
      {:ok, pid} = Timeline.start_link(topic: topic)

      on_exit fn ->
        assert_down(pid)
      end

      :ok
    end

    test "publishes a new tweet", %{adapter: adapter} do
      tweet = %Tweet{text: ":text:"}
      adapter.stream_tweet(tweet)
      assert_receive {:new_tweet, ^tweet}, 100
    end

    test "does not publish non-tweets messages received from the adapter", %{adapter: adapter} do
      message = %ExTwitter.Model.User{}
      adapter.stream_tweet(message)
      refute_receive {:new_tweet, _}, 100
    end

    test "publishes full list of tweets upon reception of a deleted tweet form the adapter",
      %{adapter: adapter}
    do
      tweets = [
        %Tweet{id: 1},
        %Tweet{id: 2}
      ]
      deleted_tweet = %TweetDeletion{tweet_id: 2}

      Enum.each(tweets ++ [deleted_tweet], &adapter.stream_tweet/1)

      expected_tweets = [%Tweet{id: 1}]
      assert_receive {:all_tweets, ^expected_tweets}, 100
    end
  end

  # As suggested here: https://elixirforum.com/t/how-to-stop-otp-processes-started-in-exunit-setup-callback/3794/5
  defp assert_down(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end
