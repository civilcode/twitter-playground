defmodule Twitter.TimelineTest do
  use ExUnit.Case

  setup do
    ExTwitterFakeAdapter.start_link()

    :ok
  end

  describe "initialization" do
    test "get the latest tweets for the user" do
      tweet = %ExTwitter.Model.Tweet{text: "sample tweet text"}
      ExTwitterFakeAdapter.set_initial_tweets(tweet)
      Twitter.Timeline.start_link(adapter: ExTwitterFakeAdapter)

      texts = Twitter.Timeline.texts

      assert texts == ["sample tweet text"]
    end
  end

  describe "streaming" do
    setup do
      Twitter.Timeline.start_link(adapter: ExTwitterFakeAdapter)

      :ok
    end

    test "receives a new tweet from the stream" do
      tweet = %ExTwitter.Model.Tweet{text: "new tweet"}
      ExTwitterFakeAdapter.simulate_incoming_message(tweet)
      :timer.sleep(100)

      tweets = Twitter.Timeline.tweets

      assert tweets == [tweet]
    end

    test "ignores messages that are not tweets" do
      message = %ExTwitter.Model.User{}
      ExTwitterFakeAdapter.simulate_incoming_message(message)
      :timer.sleep(100)

      tweets = Twitter.Timeline.tweets

      assert tweets == []
    end

    test "removes a deleted tweet" do
      [
        %ExTwitter.Model.Tweet{id: 1},
        %ExTwitter.Model.Tweet{id: 2},
        %ExTwitter.Model.DeletedTweet{status: %{id: 2}}
      ]
      |> Enum.each(&ExTwitterFakeAdapter.simulate_incoming_message/1)
      :timer.sleep(100)

      tweets = Twitter.Timeline.tweets

      assert tweets == [%ExTwitter.Model.Tweet{id: 1}]
    end
  end
end
