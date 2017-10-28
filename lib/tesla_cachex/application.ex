defmodule TeslaCachex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false #To be compatible prior to 1.5 
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: TeslaCachex.Worker.start_link(arg)
      # {TeslaCachex.Worker, arg},
      worker(Cachex, [:tesla_cache, [], []]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TeslaCachex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
