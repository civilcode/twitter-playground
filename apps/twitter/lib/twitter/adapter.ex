defmodule Twitter.Adapter do
  alias Twitter.Tweet

  @doc """
  Returns a list of existing tweets in reverse order (most recent one first).
  """
  @callback fetch_user_timeline() :: [Tweet.t]

  @doc """
  Returns a stream of new tweets or tweet deletions.
  """
  @callback get_user_stream() :: Stream.t
end
