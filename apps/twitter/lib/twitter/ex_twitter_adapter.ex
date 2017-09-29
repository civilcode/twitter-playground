defmodule Twitter.ExTwitterAdapter do
  @behaviour Twitter.Adapter

  alias Twitter.{Tweet, TweetDeletion}

  @spec fetch_user_timeline() :: [Tweet.t]
  def fetch_user_timeline do
    ExTwitter.user_timeline
    |> parse_tweets
    |> Enum.reverse
  end

  @spec get_user_stream() :: Stream.t
  def get_user_stream do
    ExTwitter.stream_user(with: :user, receive_messages: true)
    |> filter_stream
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

  def filter_stream(stream) do
    stream
    |> Stream.filter(&valid_message?/1)
    |> Stream.map(&parse_tweet/1)
  end

  defp valid_message?(%ExTwitter.Model.Tweet{}), do: true
  defp valid_message?(%ExTwitter.Model.DeletedTweet{}), do: true
  defp valid_message?(_), do: false
end
