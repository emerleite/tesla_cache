defmodule TeslaCache.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # To be compatible prior to 1.5
    import Supervisor.Spec, warn: false
    # List all child processes to be supervised
    children = [
      # {TeslaCachex.Worker, arg},
      {Cachex, name: :tesla_cache_cachex}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TeslaCache.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
