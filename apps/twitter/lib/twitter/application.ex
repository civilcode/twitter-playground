defmodule Twitter.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    PubSub.start_link()

    # Define workers and child supervisors to be supervised
    children = twitter_workers()

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Twitter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp twitter_workers do
    if Application.get_env(:twitter, :enable_workers, false) do
      [worker(Twitter.Timeline, [])]
    else
      []
    end
  end
end
