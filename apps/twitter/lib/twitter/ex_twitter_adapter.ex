defmodule Twitter.ExTwitterAdapter do
  # TODO: add behaviour
  alias Twitter.{Tweet, TweetDeletion}

  @spec fetch_user_timeline() :: [Tweet.t]
  def fetch_user_timeline do
    ExTwitter.user_timeline
    |> parse_tweets
    |> Enum.reverse
  end

  def get_user_stream(_opts \\ []) do
    ExTwitter.stream_user(with: :user, receive_messages: true)
  end

  def parse_tweets(tweets) do
    Enum.map(tweets, &parse_tweet/1)
  end

  def parse_tweet(%ExTwitter.Model.Tweet{id: id, text: text}) do
    %Tweet{id: id, text: text}
  end

  def parse_tweet(%ExTwitter.Model.DeletedTweet{status: %{id: id}}) do
    %TweetDeletion{tweet_id: id}
  end
end
