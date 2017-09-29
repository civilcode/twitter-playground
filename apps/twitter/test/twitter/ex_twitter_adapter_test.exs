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
end
