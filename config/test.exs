use Mix.Config

config :twitter,
  enable_workers: false,
  adapter: Twitter.FakeAdapter
