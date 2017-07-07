  defmodule ExTwitterAdapter do
    def fetch_user_timeline do
      ExTwitter.user_timeline
    end

    def get_user_stream(_opts \\ []) do
      ExTwitter.stream_user(with: :user, receive_messages: true)
    end

    def get_filtered_stream() do
      ExTwitter.stream_filter(track: "#failed")
    end
  end
