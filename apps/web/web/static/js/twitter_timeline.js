let TwitterTimeline = {
  init(socket, tweets_container) {
    // Now that you are connected, you can join channels with a topic:
    this.channel = socket.channel("tweets", {})
    this.container = $(tweets_container)
    this.tweets = $(tweets_container).find(".tweets")

    this.channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })

    this.channel.onError(e => console.log("something went wrong", e))
    this.channel.onClose(e => console.log("channel closed", e))

    this.channel.on("refresh_list", msg => {
      this._refreshAll(msg.tweets)
    })

    this.channel.on("new_tweet", tweet => {
      this._appendTweet(tweet)
    })
  },

  _refreshAll(tweets) {
    this.tweets.empty()
    for(var tweet of tweets) {
      this.tweets.prepend($('<li>').text(tweet.text))
  }
    this.container.scrollTop(this.container[0].scrollHeight)
  },

  _appendTweet(tweet) {
    this.tweets.append($('<li>').text(tweet.text))
    this.container.scrollTop(this.container[0].scrollHeight)
  }
}

export default TwitterTimeline
