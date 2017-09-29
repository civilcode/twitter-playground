defmodule Twitter.TimelineTest do
  use ExUnit.Case, async: false

  alias Twitter.{FakeAdapter, Timeline}

  setup do
    {:ok, pid} = FakeAdapter.start_link()

    on_exit fn ->
      assert_down(pid)
    end

    :ok
  end

  describe "initializing the timeline" do
    test "initializes the state with existing user's tweets" do
      # TODO: have a generic Tweet model to be decoupled from ExTwitter
      tweet = %ExTwitter.Model.Tweet{text: "sample tweet text"}
      FakeAdapter.put_tweet(tweet)

      {:ok, pid} = Timeline.start_link(adapter: FakeAdapter)

      # TODO: return tweets
      texts = Timeline.texts

      assert texts == ["sample tweet text"]

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
      {:ok, pid} = Timeline.start_link(adapter: FakeAdapter, topic: topic)

      on_exit fn ->
        assert_down(pid)
      end

      :ok
    end

    test "publishes a new tweet" do
      tweet = %ExTwitter.Model.Tweet{text: "new tweet"}
      FakeAdapter.stream_tweet(tweet)
      assert_receive {:new_tweet, ^tweet}, 100
    end

    test "does not publish non-tweets messages received from the adapter" do
      message = %ExTwitter.Model.User{}
      FakeAdapter.stream_tweet(message)
      refute_receive {:new_tweet, _}, 100
    end

    test "publishes full list of tweets upon reception of a deleted tweet form the adapter" do
      tweets = [
        %ExTwitter.Model.Tweet{id: 1},
        %ExTwitter.Model.Tweet{id: 2}
      ]
      deleted_tweet = %ExTwitter.Model.DeletedTweet{status: %{id: 2}}

      Enum.each(tweets ++ [deleted_tweet], &FakeAdapter.stream_tweet/1)

      expected_tweets = [%ExTwitter.Model.Tweet{id: 1}]
      assert_receive {:all_tweets, ^expected_tweets}, 100
    end
  end

  # As suggested here: https://elixirforum.com/t/how-to-stop-otp-processes-started-in-exunit-setup-callback/3794/5
  defp assert_down(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end
