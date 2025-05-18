defmodule Pair.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PairWeb.Telemetry,
      Pair.Repo,
      {DNSCluster, query: Application.get_env(:pair, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:pair, Oban)},
      {Phoenix.PubSub, name: Pair.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Pair.Finch},
      # Start a worker by calling: Pair.Worker.start_link(arg)
      # {Pair.Worker, arg},
      # Start to serve requests, typically the last entry
      PairWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pair.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PairWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
