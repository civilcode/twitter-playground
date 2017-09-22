defmodule Twitter.TimelineTest do
  use ExUnit.Case

  setup do
    TwitterFakeAdapter.start_link()

    :ok
  end

  describe "initialization" do
    # TODO: fix doc string
    test "get the latest tweets for the user" do
      # TODO: have a generic Tweet model to be decoupled from ExTwitter
      tweet = %ExTwitter.Model.Tweet{text: "sample tweet text"}
      TwitterFakeAdapter.put_tweet(tweet)
      Twitter.Timeline.start_link(adapter: TwitterFakeAdapter)

      # TODO: return tweets
      texts = Twitter.Timeline.texts

      assert texts == ["sample tweet text"]
    end
  end

  describe "streaming" do
    setup do
      # TODO: Pass pubsub topic to start_link
      Twitter.Timeline.start_link(adapter: TwitterFakeAdapter)
      PubSub.start_link()
      PubSub.subscribe(self(), "twitter:timeline")

      :ok
    end

    test "receives a new tweet from the stream" do
      tweet = %ExTwitter.Model.Tweet{text: "new tweet"}
      TwitterFakeAdapter.stream_tweet(tweet)

      assert_receive {:new_tweet, ^tweet}, 100
    end

    test "ignores messages that are not tweets" do
      message = %ExTwitter.Model.User{}
      TwitterFakeAdapter.stream_tweet(message)

      refute_receive {:new_tweet, _}, 100
    end

    test "removes a deleted tweet" do
      tweets = [
        %ExTwitter.Model.Tweet{id: 1},
        %ExTwitter.Model.Tweet{id: 2}
      ]
      deleted_tweet = %ExTwitter.Model.DeletedTweet{status: %{id: 2}}
      Enum.each(tweets ++ [deleted_tweet], &TwitterFakeAdapter.stream_tweet/1)

      expected_tweets = [%ExTwitter.Model.Tweet{id: 1}]
      assert_receive {:all_tweets, ^expected_tweets}, 100
    end
  end
end
