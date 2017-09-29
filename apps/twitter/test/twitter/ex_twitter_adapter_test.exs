defmodule Twitter.ExTwitterAdapterTest do
  use ExUnit.Case, async: false

  alias Twitter.{Tweet, TweetDeletion, ExTwitterAdapter}

  test "converts a ExTwitter.Model.Tweet to Tweet" do
    ex_twitter_tweet = %ExTwitter.Model.Tweet{id: ":id:", text: ":text:"}

    tweet = ExTwitterAdapter.parse_tweet(ex_twitter_tweet)

    assert tweet == %Tweet{id: ":id:", text: ":text:"}
  end

  test "converts a ExTwitter.Model.DeletedTweet to TweetDeletion" do
    ex_twitter_deleted_tweet = %ExTwitter.Model.DeletedTweet{status: %{id: ":id:"}}

    tweet_deletion = ExTwitterAdapter.parse_tweet(ex_twitter_deleted_tweet)

    assert tweet_deletion == %TweetDeletion{tweet_id: ":id:"}
  end

  test "filters a stream of tweets" do
    unwanted_messages = [
      %ExTwitter.Model.User{},
      {:friends, %{friends: [3720341, 5444392, 16573941]}}
    ]
    wanted_message = [
      %ExTwitter.Model.Tweet{},
      %ExTwitter.Model.DeletedTweet{status: %{id: ":id:"}},
    ]
    stream = Stream.cycle(unwanted_messages ++ wanted_message)

    tweets_stream = ExTwitterAdapter.filter_stream(stream)

    [first, second] = Enum.take(tweets_stream, 2)
    assert %Tweet{} = first
    assert %TweetDeletion{} = second
  end
end
